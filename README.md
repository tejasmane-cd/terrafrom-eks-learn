# Terraform EKS Learning Project

This repository is a learning-friendly Terraform project for creating Amazon EKS clusters with reusable modules and separate `dev` and `prod` environments.

Run Terraform from an environment folder, not from the repository root:

```bash
terraform -chdir=environments/dev plan
terraform -chdir=environments/prod plan
```

## Project Structure

```text
terrafrom-eks-learn/
├── bootstrap/
│   └── s3-backend/          # one-time example for the remote state bucket
├── modules/
│   ├── vpc/
│   └── eks/
└── environments/
    ├── dev/
    └── prod/
```

`modules/vpc` creates the VPC, public subnets, private subnets, Internet Gateway, NAT Gateway, DNS support, and Kubernetes subnet tags.

`modules/eks` creates the EKS cluster, managed node groups, EKS managed add-ons, and kubectl helper outputs.

`environments/dev` and `environments/prod` call those modules with different settings.

## Versions

This project pins versions tightly enough to be reproducible while allowing compatible patch updates:

| Component | Constraint or value |
| --- | --- |
| Terraform CLI | `>= 1.10.0, < 1.17.0` |
| AWS provider | `~> 6.61.0` |
| VPC module | `terraform-aws-modules/vpc/aws` `~> 5.21.0` |
| EKS module | `terraform-aws-modules/eks/aws` `~> 21.25.0` |
| Kubernetes | `1.36` |

Keep both committed `.terraform.lock.hcl` files in sync by running `terraform init` in both environments after intentional constraint changes. Do not use `terraform init -upgrade` unless you are deliberately reviewing a dependency update.

GitHub Actions pins Terraform CLI `1.16.0` inside the supported range.

## Remote State

Both environments use the S3 backend with native S3 lockfiles. DynamoDB locking is not used.

| Environment | State key |
| --- | --- |
| `dev` | `terrafrom-eks-learn/dev/terraform.tfstate` |
| `prod` | `terrafrom-eks-learn/prod/terraform.tfstate` |

The backend is intentionally partial: the repository owns the state key, encryption flag, and `use_lockfile = true`; you supply the real bucket and backend region during `terraform init`.

```bash
terraform -chdir=environments/dev init \
  -backend-config="bucket=<your-state-bucket>" \
  -backend-config="region=<state-bucket-region>"

terraform -chdir=environments/prod init \
  -backend-config="bucket=<your-state-bucket>" \
  -backend-config="region=<state-bucket-region>"
```

To migrate existing local state after the bucket exists:

```bash
terraform -chdir=environments/dev init -migrate-state \
  -backend-config="bucket=<your-state-bucket>" \
  -backend-config="region=<state-bucket-region>"

terraform -chdir=environments/prod init -migrate-state \
  -backend-config="bucket=<your-state-bucket>" \
  -backend-config="region=<state-bucket-region>"
```

Terraform state can contain sensitive values. Do not commit `.tfstate`, `.tfstate.backup`, or real `.tfvars` files.

## Backend Bootstrap

`bootstrap/s3-backend` is a one-time example for creating the S3 state bucket. It intentionally has no remote backend because it creates the backend itself.

```bash
cd bootstrap/s3-backend
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your real bucket name and allowed IAM principals
terraform init
terraform plan
terraform apply
```

The state bucket must have:

- server-side encryption enabled
- versioning enabled
- all S3 public access blocked
- restricted IAM access to only trusted human/admin roles and GitHub Actions OIDC roles
- lockfile access for `*.tflock` objects when `use_lockfile = true`

The bootstrap example enables encryption, versioning, public-access blocking, noncurrent-version lifecycle cleanup, TLS-only bucket policy enforcement, and optional bucket-policy access for the dev/prod state objects and lock files.

## Environments

Dev is smaller and cheaper.

| Setting | Value |
| --- | --- |
| VPC CIDR | `10.10.0.0/16` |
| Availability Zones | 2 |
| NAT Gateway | Single NAT Gateway |
| EKS API endpoint | Public, restricted by `endpoint_public_access_cidrs` |
| Deletion protection | Off |
| Node type | `t3.small` |
| Desired nodes | 1 |

Prod is more production-like.

| Setting | Value |
| --- | --- |
| VPC CIDR | `10.20.0.0/16` |
| Availability Zones | 3 |
| NAT Gateway | One NAT Gateway per AZ |
| EKS API endpoint | Private |
| Deletion protection | On |
| Node type | `t3.small` |
| Desired nodes | 3 |

Prod uses a private Kubernetes API endpoint. `kubectl` and future Terraform operations that talk to the cluster must run from a network path that can reach the VPC, such as VPN, a bastion path, or a private runner.

## Local Workflow

```bash
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars
terraform -chdir=environments/dev init \
  -backend-config="bucket=<your-state-bucket>" \
  -backend-config="region=<state-bucket-region>"
terraform -chdir=environments/dev plan
terraform -chdir=environments/dev apply
```

After apply:

```bash
$(terraform -chdir=environments/dev output -raw configure_kubectl)
kubectl get nodes
```

Use the same pattern for `environments/prod`, after confirming your runner or workstation can reach the private EKS endpoint.

## CI/CD

The repository includes two GitHub Actions workflows:

- `.github/workflows/terraform-pr.yml`: PR checks for `dev`.
- `.github/workflows/terraform-deploy.yml`: protected `main` and manual plan/apply for `dev`.

The PR pipeline runs:

- `terraform fmt -check -recursive`
- `terraform init`
- `terraform validate`
- `tflint`
- `checkov`
- `terraform plan`

The deployment pipeline runs plan, waits on the GitHub Environment gate for the target environment, then applies the saved plan. Concurrency is scoped per environment to prevent overlapping Terraform runs.

The current GitHub/AWS OIDC setup is configured for `dev` only. Re-enable `prod` in the workflow matrix after creating a separate production role, setting `AWS_ROLE_ARN_PROD`, and configuring the GitHub `prod` Environment with required reviewers.

## GitHub OIDC

Use GitHub OIDC with short-lived AWS credentials. Do not create long-lived AWS access keys for CI.

Required GitHub variables:

| Variable | Purpose |
| --- | --- |
| `TF_STATE_BUCKET` | S3 bucket that stores Terraform state |
| `TF_STATE_REGION` | AWS region for the state bucket and AWS provider |
| `AWS_ROLE_ARN_DEV` | Least-privilege role assumed for dev plans/applies |
| `AWS_ROLE_ARN_PROD` | Least-privilege role assumed for prod plans/applies after prod is re-enabled |
| `TF_VAR_ENDPOINT_PUBLIC_ACCESS_CIDRS` | JSON-style CIDR list for the dev public EKS API endpoint, such as `["203.0.113.10/32"]` |

Create an IAM OIDC provider for `https://token.actions.githubusercontent.com`, then create separate dev and prod IAM roles. This repository is configured to use GitHub's immutable OIDC subject format, so scope each trust policy to this repository's owner and repository IDs.

Repository identity:

| Field | Value |
| --- | --- |
| Repository | `tejasmane-cd/terrafrom-eks-learn` |
| Owner ID | `242378642` |
| Repository ID | `1267317998` |

The dev role `github-actions-terraform-dev` should trust the PR, main-branch, and dev-environment subjects:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:tejasmane-cd@242378642/terrafrom-eks-learn@1267317998:pull_request",
            "repo:tejasmane-cd@242378642/terrafrom-eks-learn@1267317998:ref:refs/heads/main",
            "repo:tejasmane-cd@242378642/terrafrom-eks-learn@1267317998:environment:dev"
          ]
        }
      }
    }
  ]
}
```

The prod role should use the same immutable repository prefix, but trust `environment:prod` for apply. Least privilege for each role should include only the AWS actions needed to manage the environment resources plus S3 access to that environment's state key and matching `.tflock` object. Production state access should not be granted to the dev role.

## Kubernetes Upgrade

The cluster version is pinned to EKS Kubernetes `1.36`, which is in Amazon EKS standard support in August 2026. Version `1.31` is only in extended support and reaches the end of extended support on November 26, 2026.

Pinned add-ons in `modules/eks`:

| Add-on | Version |
| --- | --- |
| CoreDNS | `v1.14.3-eksbuild.14` |
| kube-proxy | `v1.36.0-eksbuild.17` |
| VPC CNI | `v1.22.4-eksbuild.3` |
| EKS Pod Identity Agent | `v1.3.10-eksbuild.2` |

Before upgrading an existing cluster:

1. Read the EKS release notes for every minor version between the current version and `1.36`.
2. Run EKS upgrade insights and check for removed Kubernetes APIs.
3. Upgrade one minor version at a time if the cluster already exists.
4. Upgrade the control plane first.
5. Upgrade managed node groups after the control plane is healthy.
6. Update EKS add-ons and verify CoreDNS, kube-proxy, VPC CNI, and EKS Pod Identity Agent are healthy.
7. Confirm applications do not rely on removed APIs such as `gitRepo` volumes in Kubernetes `1.36`.

The module uses EKS managed node groups and AWS-managed add-ons. It does not add Karpenter, AWS Load Balancer Controller, EBS CSI, External Secrets, monitoring, or DR features.

Useful AWS references:

- EKS Kubernetes versions: <https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html>
- EKS 1.36 release notes: <https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions-standard.html>
- CoreDNS add-on versions: <https://docs.aws.amazon.com/eks/latest/userguide/managing-coredns.html>
- kube-proxy add-on versions: <https://docs.aws.amazon.com/eks/latest/userguide/managing-kube-proxy.html>
- VPC CNI add-on versions: <https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html>
- Pod Identity Agent: <https://docs.aws.amazon.com/eks/latest/userguide/pod-id-agent-setup.html>

## Validation

Run locally before opening a PR:

```bash
terraform fmt -check -recursive
terraform -chdir=environments/dev init \
  -backend-config="bucket=<your-state-bucket>" \
  -backend-config="region=<state-bucket-region>"
terraform -chdir=environments/dev validate
terraform -chdir=environments/prod init \
  -backend-config="bucket=<your-state-bucket>" \
  -backend-config="region=<state-bucket-region>"
terraform -chdir=environments/prod validate
tflint --chdir=environments/dev --recursive
tflint --chdir=environments/prod --recursive
checkov --directory . --config-file .checkov.yaml
```

## Cleanup

To avoid AWS costs, destroy environment resources when you finish learning:

```bash
terraform -chdir=environments/dev destroy
terraform -chdir=environments/prod destroy
```

Keep the backend bucket until all remote state objects are intentionally archived or deleted.
