# EKS From The Ground Up – Terraform (Part 1)

Terraform configuration for the first article in the EKS series. It builds the network layer and control plane prerequisites:

- VPC with DNS support/hostnames enabled.
- Two public and two private subnets across the first two AZs, tagged for EKS and load balancers.
- Per-AZ NAT gateways with corresponding route tables.
- IAM role for the EKS control plane (AmazonEKSClusterPolicy).
- EKS cluster with public and private endpoint access and audit-related logs enabled.

## Usage

```bash
cd eks_from_ground_up/terraform_part_1
terraform init
terraform apply
```

Key variables (override via `-var` or `.tfvars`):

- `region` (default: `us-east-1`)
- `cluster_name` (default: `demo-eks-cluster`)
- `kubernetes_version` (default: `1.30`)
- `vpc_cidr` (default: `10.0.0.0/16`)
- `az_count` (default: `2`)

After `terraform apply`, fetch kubeconfig:

```bash
aws eks update-kubeconfig --name $(terraform output -raw eks_cluster_name) --region $(terraform output -raw region 2>/dev/null || echo us-east-1)
kubectl cluster-info
```
