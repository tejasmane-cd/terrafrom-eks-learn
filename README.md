# Terraform EKS Learning Project

Learn EKS on AWS with reusable Terraform modules and separate `dev` / `prod` environments.

**Always run Terraform from an environment folder:**

```bash
terraform -chdir=environments/dev plan
```

## What you'll learn

| Layer | What it does |
| --- | --- |
| `modules/vpc` | VPC, public/private subnets, NAT, DNS, Kubernetes ELB subnet tags |
| `modules/eks` | EKS cluster, managed node groups, core add-ons (CNI, CoreDNS, kube-proxy) |
| `environments/*` | Wires modules together with env-specific settings |

Pattern: **environment root → local wrapper module → `terraform-aws-modules`**

## Project layout

```text
bootstrap/s3-backend/   # one-time: create the remote state bucket
modules/vpc/            # networking
modules/eks/            # cluster
environments/dev/       # smaller, public API, cheaper
environments/prod/      # HA NAT, private API, deletion protection
```

## Quick start

**1. Bootstrap state (once)**

```bash
cd bootstrap/s3-backend
cp terraform.tfvars.example terraform.tfvars   # edit bucket name + IAM principals
terraform init && terraform apply
```

**2. Deploy dev**

```bash
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars
terraform -chdir=environments/dev init \
  -backend-config="bucket=<your-state-bucket>" \
  -backend-config="region=<state-bucket-region>"
terraform -chdir=environments/dev apply
```

**3. Connect to the cluster**

```bash
$(terraform -chdir=environments/dev output -raw configure_kubectl)
kubectl get nodes
```

**4. Clean up when done**

```bash
terraform -chdir=environments/dev destroy
```

## Dev vs prod

| | Dev | Prod |
| --- | --- | --- |
| VPC CIDR | `10.10.0.0/16` | `10.20.0.0/16` |
| AZs / NAT | 2 AZs, single NAT | 3 AZs, NAT per AZ |
| EKS API | Public (CIDR-restricted) | Private only |
| Nodes | 2 × `t3.small` | 3 × `t3.small` (scales to 10) |

Prod's private API needs VPN, bastion, or a private runner for `kubectl` and Terraform.

## Remote state

- S3 backend with native lockfiles (`use_lockfile = true`)
- Keys: `terrafrom-eks-learn/dev/terraform.tfstate` and `.../prod/...`
- Never commit `.tfstate` or real `.tfvars` files

## CI/CD (optional)

GitHub Actions runs `fmt`, `validate`, `tflint`, `checkov`, and `plan` on PRs for **dev**. Deploy uses OIDC (no long-lived AWS keys). See workflow files in `.github/workflows/`.

Required GitHub variables: `TF_STATE_BUCKET`, `TF_STATE_REGION`, `AWS_ROLE_ARN_DEV`, `TF_VAR_ENDPOINT_PUBLIC_ACCESS_CIDRS`.

## Pinned versions

| Component | Version |
| --- | --- |
| Terraform | `>= 1.10.0, < 1.17.0` |
| Kubernetes | `1.36` |
| VPC module | `terraform-aws-modules/vpc/aws ~> 5.21` |
| EKS module | `terraform-aws-modules/eks/aws ~> 21.25` |

## Out of scope (good next modules to add)

- AWS Load Balancer Controller + Ingress (ALB)
- EBS CSI (persistent volumes)
- IRSA (IAM roles for service accounts)
- Monitoring, Karpenter, External DNS

## Local validation

```bash
terraform fmt -check -recursive
terraform -chdir=environments/dev validate
tflint --chdir=environments/dev --recursive
checkov --directory . --config-file .checkov.yaml
```

## References

- [EKS Kubernetes versions](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html)
- [terraform-aws-modules/eks](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
