# Runs with `terraform test`. mock_provider needs Terraform >= 1.7, which is
# newer than the module's own required_version (>= 1.5) on purpose: the higher
# version is only needed to run these tests, never to consume the module.
# No AWS credentials and no network access are required.

mock_provider "aws" {}

variables {
  identifier = "test-db"
  username   = "appadmin"
  password   = "not-a-real-password"
}

run "defaults_are_safe" {
  command = plan

  assert {
    condition     = aws_db_instance.this.publicly_accessible == false
    error_message = "The instance must not be internet-facing by default."
  }

  assert {
    condition     = aws_db_instance.this.storage_encrypted == true
    error_message = "Storage must be encrypted at rest by default."
  }

  assert {
    condition     = aws_db_instance.this.skip_final_snapshot == false
    error_message = "Destroying the instance must take a final snapshot by default."
  }

  assert {
    condition     = aws_db_instance.this.deletion_protection == true
    error_message = "Deletion protection must be on by default."
  }

  assert {
    condition     = aws_db_instance.this.backup_retention_period > 0
    error_message = "Automated backups must be enabled by default."
  }
}

run "final_snapshot_identifier_is_derived_from_the_identifier" {
  command = plan

  assert {
    condition     = aws_db_instance.this.final_snapshot_identifier == "test-db-final"
    error_message = "A final snapshot name must be derived when the caller does not supply one, otherwise AWS rejects the destroy."
  }
}

run "final_snapshot_identifier_can_be_overridden" {
  command = plan

  variables {
    final_snapshot_identifier = "test-db-decommission-2026"
  }

  assert {
    condition     = aws_db_instance.this.final_snapshot_identifier == "test-db-decommission-2026"
    error_message = "An explicit final_snapshot_identifier must win over the derived name."
  }
}

run "skipping_the_final_snapshot_clears_its_name" {
  command = plan

  variables {
    skip_final_snapshot       = true
    final_snapshot_identifier = "test-db-final"
  }

  assert {
    condition     = aws_db_instance.this.final_snapshot_identifier == null
    error_message = "final_snapshot_identifier conflicts with skip_final_snapshot and must be dropped when snapshots are skipped."
  }
}

run "opting_out_of_the_safe_defaults_still_works" {
  command = plan

  variables {
    publicly_accessible     = true
    deletion_protection     = false
    skip_final_snapshot     = true
    backup_retention_period = 0
  }

  assert {
    condition     = aws_db_instance.this.publicly_accessible == true
    error_message = "publicly_accessible must remain caller-controllable."
  }

  assert {
    condition     = aws_db_instance.this.deletion_protection == false
    error_message = "deletion_protection must remain caller-controllable."
  }
}

run "rejects_backup_retention_above_the_aws_maximum" {
  command = plan

  variables {
    backup_retention_period = 36
  }

  expect_failures = [var.backup_retention_period]
}

run "rejects_negative_backup_retention" {
  command = plan

  variables {
    backup_retention_period = -1
  }

  expect_failures = [var.backup_retention_period]
}

run "rejects_allocated_storage_below_the_aws_minimum" {
  command = plan

  variables {
    allocated_storage = 5
  }

  expect_failures = [var.allocated_storage]
}
