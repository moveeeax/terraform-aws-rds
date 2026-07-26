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

run "rejects_identifier_starting_with_a_digit" {
  command = plan

  variables {
    identifier = "1-test-db"
  }

  expect_failures = [var.identifier]
}

run "rejects_identifier_with_a_trailing_hyphen" {
  command = plan

  variables {
    identifier = "test-db-"
  }

  expect_failures = [var.identifier]
}

run "rejects_identifier_with_consecutive_hyphens" {
  command = plan

  variables {
    identifier = "test--db"
  }

  expect_failures = [var.identifier]
}

run "rejects_empty_final_snapshot_identifier" {
  command = plan

  variables {
    final_snapshot_identifier = ""
  }

  expect_failures = [var.final_snapshot_identifier]
}

run "rejects_final_snapshot_identifier_with_a_trailing_hyphen" {
  command = plan

  variables {
    final_snapshot_identifier = "decommission-"
  }

  expect_failures = [var.final_snapshot_identifier]
}

run "multiple_optional_flags_together_do_not_interfere_with_each_other" {
  command = plan

  variables {
    multi_az                = true
    publicly_accessible     = true
    engine_version          = "16.4"
    vpc_security_group_ids  = ["sg-aaaaaaaa", "sg-bbbbbbbb"]
    db_subnet_group_name    = "custom-subnet-group"
    backup_retention_period = 14

    timeouts = {
      create = "60m"
      update = "90m"
      delete = "30m"
    }
  }

  assert {
    condition     = aws_db_instance.this.multi_az == true
    error_message = "multi_az must remain settable alongside other optional flags."
  }

  assert {
    condition     = aws_db_instance.this.publicly_accessible == true
    error_message = "publicly_accessible must remain settable alongside other optional flags."
  }

  assert {
    condition     = aws_db_instance.this.engine_version == "16.4"
    error_message = "engine_version must remain settable alongside other optional flags."
  }

  assert {
    condition     = length(aws_db_instance.this.vpc_security_group_ids) == 2
    error_message = "vpc_security_group_ids must remain settable alongside other optional flags."
  }

  assert {
    condition     = aws_db_instance.this.db_subnet_group_name == "custom-subnet-group"
    error_message = "db_subnet_group_name must remain settable alongside other optional flags."
  }

  assert {
    condition     = aws_db_instance.this.backup_retention_period == 14
    error_message = "backup_retention_period must remain settable alongside other optional flags."
  }
}

run "timeouts_default_to_unset" {
  command = plan

  assert {
    condition     = aws_db_instance.this.timeouts == null
    error_message = "No timeouts block should be generated when var.timeouts is left at its default null."
  }
}

run "timeouts_are_applied_when_set" {
  command = plan

  variables {
    timeouts = {
      create = "60m"
      update = "90m"
      delete = "30m"
    }
  }

  assert {
    condition     = aws_db_instance.this.timeouts.create == "60m"
    error_message = "A supplied create timeout must reach the resource."
  }

  assert {
    condition     = aws_db_instance.this.timeouts.update == "90m"
    error_message = "A supplied update timeout must reach the resource."
  }

  assert {
    condition     = aws_db_instance.this.timeouts.delete == "30m"
    error_message = "A supplied delete timeout must reach the resource."
  }
}

run "create_instance_with_initial_instance_class" {
  command = apply

  variables {
    instance_class = "db.t3.micro"
  }

  assert {
    condition     = aws_db_instance.this.instance_class == "db.t3.micro"
    error_message = "The instance must be created with the requested instance class."
  }
}

run "update_instance_class_in_place" {
  command = apply

  variables {
    instance_class = "db.t4g.small"
  }

  assert {
    condition     = aws_db_instance.this.instance_class == "db.t4g.small"
    error_message = "Changing instance_class on an existing instance must update it in place rather than requiring a new one."
  }
}
