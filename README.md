# EKS Terraform (dev / prod)

Modular Terraform layout to deploy Amazon EKS with separate **dev** and **prod** environments.

## Layout

```
modules/eks-platform/     # Reusable VPC + EKS module
environments/dev/         # Smaller, cheaper dev cluster
environments/prod/        # HA prod cluster (private API, deletion protection)
```

```
terrafrom-eks-learn/
├── modules/
│   └── eks-platform/        ← reusable module
│       ├── main.tf           (VPC + EKS resources)
│       ├── variables.tf
│       ├── outputs.tf
│       └── versions.tf
└── environments/
    ├── dev/                 ← instantiates the module (dev config)
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── versions.tf
    └── prod/                ← instantiates the module (prod config)
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── versions.tf
```

## Infrastructure

### Dev — `10.10.0.0/16` · 2 AZs · public API endpoint

```
                              Internet
                                  │
                        ┌─────────┴──────────┐
                        │  Internet Gateway   │
                        └─────────┬──────────┘
                                  │
  ┌───────────── VPC  10.10.0.0/16 ──────────────────────────────────┐
  │                                                                   │
  │  PUBLIC SUBNETS                                                   │
  │  ┌───────────────────────────┐  ┌───────────────────────────┐   │
  │  │  us-east-1a               │  │  us-east-1b               │   │
  │  │  10.10.32.0/20            │  │  10.10.48.0/20            │   │
  │  │  ┌─────────────────────┐  │  │                           │   │
  │  │  │    NAT Gateway      │  │  │  (no NAT — single-AZ)    │   │
  │  │  └──────────┬──────────┘  │  │                           │   │
  │  └─────────────┼─────────────┘  └───────────────────────────┘   │
  │                │                                                  │
  │  PRIVATE SUBNETS                                                  │
  │  ┌─────────────┴─────────────┐  ┌───────────────────────────┐   │
  │  │  us-east-1a               │  │  us-east-1b               │   │
  │  │  10.10.0.0/20             │  │  10.10.16.0/20            │   │
  │  │  ┌──────────────────────┐ │  │  ┌──────────────────────┐ │   │
  │  │  │  EKS Managed Node    │ │  │  │  (scale-out, max 2)  │ │   │
  │  │  │  t3.small            │ │  │  └──────────────────────┘ │   │
  │  │  │  desired 1 / max 2   │ │  │                           │   │
  │  │  └──────────────────────┘ │  │                           │   │
  │  └───────────────────────────┘  └───────────────────────────┘   │
  │                                                                   │
  │  ┌─────────────────────────────────────────────────────────────┐ │
  │  │  EKS Control Plane  (Kubernetes 1.31)                       │ │
  │  │  Public API endpoint                                        │ │
  │  │  Addons: vpc-cni · kube-proxy · coredns (×1)               │ │
  │  │          eks-pod-identity-agent                             │ │
  │  └─────────────────────────────────────────────────────────────┘ │
  └───────────────────────────────────────────────────────────────────┘
```

### Prod — `10.20.0.0/16` · 3 AZs · private API endpoint

```
                              Internet
                                  │
                        ┌─────────┴──────────┐
                        │  Internet Gateway   │
                        └──┬──────┬──────┬───┘
                           │      │      │
  ┌────────────── VPC  10.20.0.0/16 ──────────────────────────────────────┐
  │                                                                        │
  │  PUBLIC SUBNETS                                                        │
  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐      │
  │  │  us-east-1a     │  │  us-east-1b     │  │  us-east-1c     │      │
  │  │  10.20.48.0/20  │  │  10.20.64.0/20  │  │  10.20.80.0/20  │      │
  │  │  ┌───────────┐  │  │  ┌───────────┐  │  │  ┌───────────┐  │      │
  │  │  │    NAT    │  │  │  │    NAT    │  │  │  │    NAT    │  │      │
  │  │  └─────┬─────┘  │  │  └─────┬─────┘  │  │  └─────┬─────┘  │      │
  │  └────────┼────────┘  └────────┼────────┘  └────────┼────────┘      │
  │           │                    │                      │               │
  │  PRIVATE SUBNETS                                                       │
  │  ┌────────┴────────┐  ┌────────┴────────┐  ┌────────┴────────┐      │
  │  │  us-east-1a     │  │  us-east-1b     │  │  us-east-1c     │      │
  │  │  10.20.0.0/20   │  │  10.20.16.0/20  │  │  10.20.32.0/20  │      │
  │  │  ┌───────────┐  │  │  ┌───────────┐  │  │  ┌───────────┐  │      │
  │  │  │ EKS Node  │  │  │  │ EKS Node  │  │  │  │ EKS Node  │  │      │
  │  │  │ m6i.large │  │  │  │ m6i.large │  │  │  │ m6i.large │  │      │
  │  │  └───────────┘  │  │  └───────────┘  │  │  └───────────┘  │      │
  │  │  desired 3 / max 10 (autoscaling across all three AZs)     │      │
  │  └─────────────────┘  └─────────────────┘  └─────────────────┘      │
  │                                                                        │
  │  ┌──────────────────────────────────────────────────────────────┐    │
  │  │  EKS Control Plane  (Kubernetes 1.31)                        │    │
  │  │  Private API endpoint — access via VPN / bastion only        │    │
  │  │  Deletion protection ON                                      │    │
  │  │  Addons: vpc-cni · kube-proxy · coredns (×2)                │    │
  │  │          eks-pod-identity-agent                              │    │
  │  └──────────────────────────────────────────────────────────────┘    │
  └────────────────────────────────────────────────────────────────────────┘
```

> **Prod access:** The Kubernetes API has no public endpoint. All `kubectl`
> and `terraform` commands must run from inside the VPC (VPN, bastion host,
> or an AWS CloudShell session scoped to the VPC).

## Prerequisites

- Terraform >= 1.5
- AWS CLI configured (`aws configure` or env vars)
- IAM permissions for VPC, EKS, EC2, IAM, KMS

## Deploy dev

```bash
cd environments/dev
cp terraform.tfvars.example terraform.tfvars   # edit as needed
terraform init
terraform plan
terraform apply
```

After apply:

```bash
$(terraform output -raw configure_kubectl)
kubectl get nodes
```

## Deploy prod

```bash
cd environments/prod
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

Prod uses a **private** Kubernetes API endpoint. Run `terraform apply` and `kubectl` from a network that can reach the VPC (VPN, bastion, or CI runner in the account).

## Environment differences

| Setting | dev | prod |
|--------|-----|------|
| AZs | 2 | 3 |
| NAT | Single | Per-AZ |
| API endpoint | Public | Private |
| Deletion protection | Off | On |
| Node type | t3.small | m6i.large |
| Nodes (desired) | 1 | 3 |

## Remote state (recommended)

Add a `backend "s3"` block in each environment’s `versions.tf` before team use. Example:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-tf-state"
    key            = "eks-learn/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

## Cleanup

```bash
cd environments/dev   # or prod
terraform destroy
```
