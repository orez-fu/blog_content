variable "aws_region" {
  description = "AWS region used by the demo."
  type        = string
  default     = "us-east-1"
}

variable "availability_zones" {
  description = "Two or more AZs used by ALB, EKS, and the RDS subnet group."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two availability zones are required."
  }
}

variable "project_name" {
  description = "Project name used in resource names and tags."
  type        = string
  default     = "vpn-demo"
}

variable "environment" {
  description = "Environment name used in resource names and tags."
  type        = string
  default     = "lab"
}

variable "vpc_cidr" {
  description = "CIDR of the demo VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "admin_cidr_blocks" {
  description = "Trusted public CIDRs allowed to reach SSH and the OpenVPN Admin UI."
  type        = list(string)

  validation {
    condition     = length(var.admin_cidr_blocks) > 0 && alltrue([for cidr in var.admin_cidr_blocks : cidr != "0.0.0.0/0"])
    error_message = "Set at least one trusted CIDR and do not use 0.0.0.0/0."
  }
}

variable "vpn_client_cidr" {
  description = "OpenVPN client address pool. Used for documentation and routing-mode deployments."
  type        = string
  default     = "172.27.224.0/20"
}

variable "enable_vpn_routing_mode" {
  description = "Add VPC return routes to the VPN client pool through OpenVPN. Enable only when OpenVPN AS uses routing instead of NAT."
  type        = bool
  default     = false
}

variable "openvpn_instance_type" {
  description = "EC2 instance type for OpenVPN Access Server."
  type        = string
  default     = "t3.small"
}

variable "enable_nat_gateway" {
  description = "Create one NAT gateway for private EKS nodes. Disable only when equivalent VPC endpoints already exist."
  type        = bool
  default     = true
}

variable "eks_cluster_version" {
  description = "Optional EKS Kubernetes version. Null lets EKS select its default supported version."
  type        = string
  default     = null
  nullable    = true
}

variable "eks_admin_principal_arn" {
  description = "Optional IAM role ARN granted EKS cluster administrator access for the SRE team."
  type        = string
  default     = null
  nullable    = true
}

variable "eks_node_instance_types" {
  description = "Instance types used by the EKS managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_desired_size" {
  description = "Desired number of EKS worker nodes."
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Minimum number of EKS worker nodes."
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Maximum number of EKS worker nodes."
  type        = number
  default     = 3
}

variable "db_name" {
  description = "Initial MySQL database name."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "RDS administrator username."
  type        = string
  default     = "dbadmin"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "Allocated RDS storage in GiB."
  type        = number
  default     = 20
}

variable "db_deletion_protection" {
  description = "Protect the demo database from accidental deletion. Keep false for disposable labs."
  type        = bool
  default     = false
}

variable "additional_tags" {
  description = "Additional tags applied to all supported resources."
  type        = map(string)
  default     = {}
}
