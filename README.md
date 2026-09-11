# Terraform EKS Learning Project

Learn EKS on AWS with reusable Terraform modules and separate `dev` / `prod` environments.

**Always run Terraform from an environment folder:**

```bash
terraform -chdir=environments/dev plan
```

## What you'll learn

| Module | What it does |
| --- | --- |
| `modules/vpc` | VPC, subnets, NAT, Kubernetes ELB subnet tags |
| `modules/eks` | EKS cluster, node groups, core add-ons |
| `modules/irsa` | IAM roles for Kubernetes service accounts |
| `modules/ebs-csi` | EBS CSI driver (IRSA + add-on + `gp3` StorageClass) |
| `modules/aws-load-balancer-controller` | ALB controller (IRSA + Helm + IngressClass + demo Ingress) |
| `modules/cert-manager` | Automatic TLS via Let's Encrypt (Helm + ClusterIssuer) |
| `modules/external-dns` | Automated Route53 records from Ingress/Service (IRSA + Helm) |
| `environments/*` | Wires modules with env-specific settings |

Pattern: **environment → local wrapper → community module / Helm / Kubernetes**

## Project layout

```text
bootstrap/s3-backend/
modules/{vpc,eks,irsa,ebs-csi,aws-load-balancer-controller,cert-manager,external-dns}/
environments/{dev,prod}/
```

## Quick start

**1. Bootstrap state (once)**

```bash
cd bootstrap/s3-backend
cp terraform.tfvars.example terraform.tfvars
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

On a **brand-new** cluster, platform add-ons need the API server first:

```bash
terraform -chdir=environments/dev apply -target=module.vpc -target=module.eks
terraform -chdir=environments/dev apply
```

**3. Connect and verify**

```bash
$(terraform -chdir=environments/dev output -raw configure_kubectl)
kubectl get nodes
kubectl get clusterissuer
kubectl get pods -n cert-manager
kubectl get pods -n external-dns    # when enabled
kubectl get storageclass gp3
```

**4. Clean up**

```bash
terraform -chdir=environments/dev destroy
```

## Automatic TLS (cert-manager)

| Env | Default solver | Default issuer |
| --- | --- | --- |
| dev | HTTP-01 via ALB | Let's Encrypt **staging** |
| prod | DNS-01 via Route53 (IRSA) | Let's Encrypt **production** |

Add to an Ingress with a real DNS name:

```yaml
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-staging
spec:
  tls:
    - hosts:
        - app.example.com
      secretName: app-tls
```

Set `cert_manager_acme_email` in `terraform.tfvars`. For prod DNS-01, also set `cert_manager_route53_hosted_zone_arns`.

## Automated DNS (External DNS)

Off by default. Enable in `terraform.tfvars`:

```hcl
enable_external_dns = true
external_dns_route53_hosted_zone_arns = ["arn:aws:route53:::hostedzone/Z1234567890ABC"]
external_dns_domain_filters           = ["example.com"]
```

Annotate an Ingress or Service so External DNS creates Route53 records:

```yaml
metadata:
  annotations:
    external-dns.alpha.kubernetes.io/hostname: app.example.com
```

Works well with the ALB controller: External DNS points your domain at the ALB hostname.

## Dev vs prod

| | Dev | Prod |
| --- | --- | --- |
| EKS API | Public (CIDR-restricted) | Private only |
| Demo Ingress | Yes (`alb-demo` namespace) | No |
| cert-manager | HTTP-01 + staging issuer | DNS-01 + production issuer |
| External DNS | Optional (`enable_external_dns`) | Optional (`enable_external_dns`) |
| Nodes | 2 × `t3.small` | 3 × `t3.small` |

Prod needs VPC access for `kubectl`, Helm, and Terraform Kubernetes/Helm providers.

## Remote state

S3 backend with lockfiles. Keys: `terrafrom-eks-learn/{dev,prod}/terraform.tfstate`.

## Pinned versions

| Component | Version |
| --- | --- |
| Terraform | `>= 1.10.0, < 1.17.0` |
| Kubernetes | `1.36` |
| EBS CSI add-on | `v1.65.0-eksbuild.1` |
| AWS LB Controller chart | `1.11.0` |
| cert-manager chart | `v1.17.2` |
| External DNS chart | `1.15.2` |

## Next modules to add

Monitoring, Karpenter.

## Local validation

```bash
terraform fmt -check -recursive
terraform -chdir=environments/dev validate
tflint --chdir=environments/dev --recursive
checkov --directory . --config-file .checkov.yaml
```
