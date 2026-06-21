# OpenVPN on AWS — Part 2 infrastructure

This Terraform root provisions the AWS infrastructure used by the Part 2 demo:

- A multi-AZ VPC split into public, application, data, and production trust zones.
- OpenVPN Access Server in a public subnet.
- A private RDS MySQL instance in isolated data subnets.
- A private EKS cluster and managed node group in production subnets.
- An internal Application Load Balancer backed by Lambda.
- Security groups that accept both OpenVPN NAT traffic and the routed VPN client pool.

Grafana, Rancher, and Argo CD are intentionally a second deployment stage. Because the EKS API endpoint is private, install those add-ons only after the AWS infrastructure exists and the operator has connected through OpenVPN. Keeping cluster add-ons outside this root avoids a Terraform provider dependency cycle during the first apply.

## Layout

```text
part_2/
├── versions.tf              # Terraform and provider constraints
├── providers.tf             # AWS provider configuration
├── variables.tf             # User-configurable inputs
├── locals.tf                # Naming, tags, and CIDR calculations
├── network.tf               # VPC, trust-zone subnets, routes, NAT
├── security_groups.tf       # Least-privilege network rules
├── openvpn.tf               # OpenVPN EC2, key pair, and Elastic IP
├── rds.tf                   # Private RDS MySQL
├── eks.tf                   # Private EKS cluster and node group
├── lambda_alb.tf            # Internal ALB and Lambda target
├── outputs.tf               # Endpoints, commands, and group CIDRs
├── terraform.tfvars.example # Safe starting configuration
└── lambda/src/index.mjs     # Demo Lambda handler
```

## Prerequisites

- Terraform 1.10 or newer.
- AWS credentials with permission to create the resources in this root.
- An active subscription to the OpenVPN Access Server AMI in AWS Marketplace.
- Sufficient EIP, VPC, EKS, EC2, ELB, Lambda, and RDS service quotas.

## Deploy

1. Copy `terraform.tfvars.example` to `terraform.tfvars`.
2. Replace `admin_cidr_blocks` with your trusted public `/32` CIDR.
3. Review the billable resources, particularly EKS, EC2, RDS, ALB, and the NAT gateway.
4. Initialize and review the plan:

```bash
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

The RDS master password is managed by RDS in AWS Secrets Manager. Terraform outputs the secret ARN, not the password.

## Configure OpenVPN access groups

After the first apply, inspect the generated access matrix:

```bash
terraform output network_access_cidrs
```

Use those CIDRs in OpenVPN Access Server:

- `dba`: data CIDRs only.
- `developer`: application CIDRs only.
- `sre`: application, data, and production CIDRs.

The production CIDRs are deliberately separate from the internal ALB CIDRs. A Developer can therefore reach the private application endpoint without receiving a route to the EKS private API endpoint.

The security groups support both common OpenVPN configurations:

- NAT mode, where destinations see the OpenVPN EC2 network interface.
- Routing mode, where destinations retain an address from `vpn_client_cidr`.

Set `enable_vpn_routing_mode = true` to create return routes through the OpenVPN instance, but only after selecting routing mode in OpenVPN Access Server.

## Connect to EKS

Connect using an SRE VPN profile, then run the output command:

```bash
terraform output -raw eks_update_kubeconfig_command
```

The Terraform identity that creates the cluster receives bootstrap administrator access. Set `eks_admin_principal_arn` to create an explicit access entry for a long-lived SRE role.

## Test the Lambda-backed private API

Connect with a Developer or SRE VPN profile and run:

```bash
curl "$(terraform output -raw lambda_demo_url)"
```

The DBA profile should not receive the application CIDRs and therefore should not reach this endpoint.

## Cost and cleanup

This stack creates continuously billed resources. A single NAT gateway is used to reduce demo cost, but it is not a production high-availability design. Destroy the lab when finished:

```bash
terraform destroy
```

The generated SSH private key, Terraform state, variable values, and Lambda ZIP are ignored by Git. Commit `.terraform.lock.hcl` so provider selections remain reproducible.
