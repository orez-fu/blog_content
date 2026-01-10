variable "project_name" {
  description = "Prefix used for naming AWS resources"
  type        = string
  default     = "eks-demo"
}

variable "region" {
  description = "AWS region to deploy the EKS stack"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "demo-eks-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS control plane"
  type        = string
  default     = "1.30"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones to use"
  type        = number
  default     = 2
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default = {
    Project = "lab"
  }
}

variable "external_dns_chart_version" {
  description = "Helm chart version for external-dns"
  type        = string
  default     = "1.14.5"
}

variable "metrics_server_chart_version" {
  description = "Helm chart version for metrics-server"
  type        = string
  default     = "3.12.1"
}
