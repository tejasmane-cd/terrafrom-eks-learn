# Terraform EKS Learning Project

This repository is a learning-friendly Terraform project for creating an Amazon EKS cluster with reusable modules.

It has two environments:

- `dev`: cheaper setup for practice
- `prod`: more production-like setup with high availability choices

Important: do not run `terraform plan` from the repository root. The root folder has no `.tf` files. Run Terraform from `environments/dev` or `environments/prod`.

## Project Structure

```text
terrafrom-eks-learn/
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── versions.tf
│   └── eks/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── versions.tf
└── environments/
    ├── dev/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   ├── versions.tf
    │   └── terraform.tfvars.example
    └── prod/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        ├── versions.tf
        └── terraform.tfvars.example
```

## What Each Folder Means

`modules/vpc` contains reusable networking code.

It creates:

- VPC
- public subnets
- private subnets
- Internet Gateway
- NAT Gateway
- DNS support
- Kubernetes subnet tags for load balancers

`modules/eks` contains reusable EKS code.

It creates:

- EKS cluster
- managed node groups
- EKS addons
- cluster IAM resources through the upstream EKS module
- outputs for kubectl access

`environments/dev` and `environments/prod` are where you actually run Terraform.

Each environment calls the modules like this:

```hcl
module "vpc" {
  source = "../../modules/vpc"
}

module "eks" {
  source = "../../modules/eks"
}
```

This is the main learning idea: modules contain reusable code, and environments pass different values into those modules.

## Terraform Command Location

Wrong:

```bash
terraform plan
```

from:

```bash
~/terrafrom-eks-learn
```

This gives:

```text
Error: No configuration files
```

Correct:

```bash
cd environments/dev
terraform init
terraform plan
```

or:

```bash
cd environments/prod
terraform init
terraform plan
```

You can also run from the root using `-chdir`:

```bash
terraform -chdir=environments/dev init
terraform -chdir=environments/dev plan
```

## Dev Environment

Dev is smaller and cheaper.

| Setting | Value |
| --- | --- |
| VPC CIDR | `10.10.0.0/16` |
| Availability Zones | 2 |
| NAT Gateway | Single NAT Gateway |
| EKS API endpoint | Public |
| Deletion protection | Off |
| Node type | `t3.small` |
| Desired nodes | 1 |

Run dev:

```bash
cd environments/dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

After apply:

```bash
$(terraform output -raw configure_kubectl)
kubectl get nodes
```

## Prod Environment

Prod is more production-like.

| Setting | Value |
| --- | --- |
| VPC CIDR | `10.20.0.0/16` |
| Availability Zones | 3 |
| NAT Gateway | One NAT Gateway per AZ |
| EKS API endpoint | Private |
| Deletion protection | On |
| Node type | `m6i.large` |
| Desired nodes | 3 |

Run prod:

```bash
cd environments/prod
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

Prod uses a private Kubernetes API endpoint. That means `kubectl` and future Terraform runs must be done from a network that can reach the VPC, such as VPN, bastion host, or a CI runner inside the AWS network.

## How The Modules Connect

The VPC module creates networking first:

```hcl
module "vpc" {
  source = "../../modules/vpc"
}
```

The EKS module then uses values from the VPC module:

```hcl
module "eks" {
  source = "../../modules/eks"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
}
```

This means EKS nodes are launched into the private subnets created by the VPC module.

## Important Terraform Files

`main.tf` defines resources and module calls.

`variables.tf` defines inputs.

`outputs.tf` prints useful values after apply.

`versions.tf` defines Terraform and provider requirements.

`terraform.tfvars` contains environment-specific values. This file is usually not committed because it may contain local or sensitive values.

`terraform.tfvars.example` is a safe example file you can copy.

## Common Commands

Format Terraform files:

```bash
terraform fmt -recursive
```

Validate dev:

```bash
terraform -chdir=environments/dev validate
```

Validate prod:

```bash
terraform -chdir=environments/prod validate
```

Plan dev:

```bash
terraform -chdir=environments/dev plan
```

Apply dev:

```bash
terraform -chdir=environments/dev apply
```

Destroy dev:

```bash
terraform -chdir=environments/dev destroy
```

## Remote State

For learning, local state is okay.

For team or real use, configure remote state with S3 and DynamoDB locking in each environment's `versions.tf`.

Example:

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

## Learning Flow

Recommended order:

1. Read `environments/dev/main.tf`.
2. See how it calls `modules/vpc`.
3. Open `modules/vpc/main.tf` and understand the network.
4. Go back to `environments/dev/main.tf`.
5. See how it passes VPC outputs into `modules/eks`.
6. Open `modules/eks/main.tf` and understand the cluster.
7. Run `terraform plan` from `environments/dev`.
8. Read the plan before applying.

## Cleanup

To avoid AWS costs, destroy resources when you finish learning:

```bash
cd environments/dev
terraform destroy
```

For prod:

```bash
cd environments/prod
terraform destroy
```
