resource "aws_db_instance" "this" {
  identifier        = var.identifier
  engine            = var.engine
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage

  db_name  = var.db_name
  username = var.username
  password = var.manage_master_user_password ? null : var.password

  # With manage_master_user_password RDS generates the password and keeps it in
  # Secrets Manager, so it never appears in the plan or state.
  manage_master_user_password   = var.manage_master_user_password ? true : null
  master_user_secret_kms_key_id = var.manage_master_user_password ? var.master_user_secret_kms_key_id : null

  multi_az          = var.multi_az
  storage_encrypted = var.storage_encrypted

  vpc_security_group_ids = var.vpc_security_group_ids
  db_subnet_group_name   = var.db_subnet_group_name
  publicly_accessible    = var.publicly_accessible

  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection

  skip_final_snapshot = var.skip_final_snapshot

  # AWS rejects the destroy unless a name is supplied for the final snapshot, so
  # derive one from the identifier when the caller has not chosen one. It must
  # stay null while skip_final_snapshot is true or the provider reports a
  # conflict between the two arguments.
  final_snapshot_identifier = var.skip_final_snapshot ? null : coalesce(var.final_snapshot_identifier, "${var.identifier}-final")

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.manage_master_user_password != (var.password != null)
      error_message = "Set exactly one of password or manage_master_user_password = true. Prefer manage_master_user_password so the master password stays out of Terraform state."
    }
  }

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}
