# Terraform EKS Learning Project

Learn EKS on AWS with reusable Terraform modules and separate `dev` / `prod` environments.

**Always run Terraform from an environment folder:**

```bash
terraform -chdir=environments/dev plan
```

## What you'll learn


| Module                                 | What it does                                                 |
| -------------------------------------- | ------------------------------------------------------------ |
| `modules/vpc`                          | VPC, subnets, NAT, Kubernetes ELB subnet tags                |
| `modules/eks`                          | EKS cluster, node groups, core add-ons                       |
| `modules/irsa`                         | IAM roles for Kubernetes service accounts                    |
| `modules/ebs-csi`                      | EBS CSI driver (IRSA + add-on + `gp3` StorageClass)          |
| `modules/aws-load-balancer-controller` | ALB controller (IRSA + Helm + IngressClass + demo Ingress)   |
| `modules/cert-manager`                 | Automatic TLS via Let's Encrypt (Helm + ClusterIssuer)       |
| `modules/external-dns`                 | Automated Route53 records from Ingress/Service (IRSA + Helm) |
| `environments/*`                       | Wires modules with env-specific settings                     |


Pattern: **environment → local wrapper → community module / Helm / Kubernetes**

## Project layout

```text
bootstrap/s3-backend/
modules/{vpc,eks,irsa,ebs-csi,aws-load-balancer-controller,cert-manager,external-dns}/
environments/{dev,prod}/
```

## GitHub Actions configuration

The PR plan and deploy workflows use `tsmane8787@gmail.com` for the Let's Encrypt ACME account, passed to Terraform as `cert_manager_acme_email`.

On the first deployment, when the EKS cluster does not exist yet, the deploy workflow plans and applies only the VPC and EKS cluster. Rerun the workflow after that succeeds to plan and deploy the Kubernetes add-ons.

**Dev** defaults to a public EKS API (`0.0.0.0/0`) in `variables.tf` because `terraform.tfvars` is not committed (gitignored). Override in local `environments/dev/terraform.tfvars` if you want your IP only.

