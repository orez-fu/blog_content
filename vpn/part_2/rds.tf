resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-rds"
  subnet_ids = values(aws_subnet.data)[*].id

  tags = {
    Name = "${local.name_prefix}-rds-subnet-group"
  }
}

resource "aws_db_instance" "mysql" {
  identifier = "${local.name_prefix}-mysql"

  allocated_storage           = var.db_allocated_storage
  db_name                     = var.db_name
  db_subnet_group_name        = aws_db_subnet_group.main.name
  deletion_protection         = var.db_deletion_protection
  engine                      = "mysql"
  instance_class              = var.db_instance_class
  manage_master_user_password = true
  username                    = var.db_username

  backup_retention_period = 1
  copy_tags_to_snapshot   = true
  multi_az                = false
  publicly_accessible     = false
  skip_final_snapshot     = true
  storage_encrypted       = true
  storage_type            = "gp3"

  vpc_security_group_ids = [aws_security_group.rds.id]

  tags = {
    Name      = "${local.name_prefix}-mysql"
    TrustZone = "data"
  }
}
