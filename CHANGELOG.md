# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- Docs: warn that switching an existing instance to
  `manage_master_user_password = true` replaces its master password, and that
  the default (`false`) leaves existing deployments untouched.
- Tests: assert that the default plan still sends `password` and leaves
  `manage_master_user_password` unset; cover a customer KMS key for the
  managed secret.

## [1.1.0] - 2026-11-05

### Added

- `manage_master_user_password` and `master_user_secret_kms_key_id` let RDS
  generate the master password and keep it in Secrets Manager, out of Terraform
  state. Output `master_user_secret_arn`. `password` is now optional; exactly
  one of `password` or `manage_master_user_password = true` must be set.
- `timeouts` input for the instance's create, update and delete operations.
- `identifier` and `final_snapshot_identifier` are validated against the RDS
  naming rules.

### Changed

- CI: tflint job, current action majors, pinned OpenTofu, Dependabot.

## [1.0.0] - 2026-07-26

Initial release (`v0.1.0` points at the same commit).

[Unreleased]: https://github.com/moveeeax/terraform-aws-rds/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/moveeeax/terraform-aws-rds/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/moveeeax/terraform-aws-rds/releases/tag/v1.0.0
