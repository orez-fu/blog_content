output "network_access_cidrs" {
  description = "CIDRs to configure in OpenVPN Access Server group permissions."
  value = {
    dba = {
      data = [for subnet in values(aws_subnet.data) : subnet.cidr_block]
    }
    developer = {
      application = [for subnet in values(aws_subnet.application) : subnet.cidr_block]
    }
    sre = {
      application = [for subnet in values(aws_subnet.application) : subnet.cidr_block]
      data        = [for subnet in values(aws_subnet.data) : subnet.cidr_block]
      production  = [for subnet in values(aws_subnet.production) : subnet.cidr_block]
    }
  }
}

output "openvpn_public_ip" {
  description = "Elastic IP of OpenVPN Access Server."
  value       = aws_eip.openvpn.public_ip
}

output "openvpn_admin_url" {
  description = "OpenVPN Access Server Admin UI."
  value       = "https://${aws_eip.openvpn.public_ip}:943/admin"
}

output "openvpn_client_url" {
  description = "OpenVPN Access Server client UI."
  value       = "https://${aws_eip.openvpn.public_ip}/"
}

output "openvpn_ssh_command" {
  description = "SSH command for OpenVPN Access Server."
  value       = "ssh -i ${local_sensitive_file.openvpn_private_key.filename} openvpnas@${aws_eip.openvpn.public_ip}"
}

output "rds_endpoint" {
  description = "Private RDS MySQL endpoint."
  value       = aws_db_instance.mysql.address
}

output "rds_port" {
  description = "RDS MySQL port."
  value       = aws_db_instance.mysql.port
}

output "rds_master_secret_arn" {
  description = "Secrets Manager ARN containing the RDS master credentials."
  value       = try(aws_db_instance.mysql.master_user_secret[0].secret_arn, null)
}

output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.main.name
}

output "eks_private_endpoint" {
  description = "Private EKS Kubernetes API endpoint."
  value       = aws_eks_cluster.main.endpoint
}

output "eks_update_kubeconfig_command" {
  description = "Run after connecting as an SRE VPN user."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

output "internal_alb_dns_name" {
  description = "Private ALB DNS name used by Developer and SRE users."
  value       = aws_lb.internal.dns_name
}

output "lambda_demo_url" {
  description = "HTTP URL for the ALB-to-Lambda demo. Reachable only through the VPN."
  value       = "http://${aws_lb.internal.dns_name}/"
}
