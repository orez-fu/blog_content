output "vpc_id" {
  description = "ID of the EKS VPC"
  value       = aws_vpc.eks.id
}

output "region" {
  description = "AWS region where the cluster is deployed"
  value       = var.region
}

output "public_subnet_ids" {
  description = "IDs of public subnets for load balancers and NAT gateways"
  value       = values(aws_subnet.public)[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets for worker nodes"
  value       = values(aws_subnet.private)[*].id
}

output "cluster_security_group_id" {
  description = "Security group associated with the EKS control plane"
  value       = aws_security_group.cluster.id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.this.name
}

output "eks_cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required for kubeconfig"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}
