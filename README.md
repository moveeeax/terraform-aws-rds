# terraform-aws-rds

Terraform module that manages an [Amazon RDS](https://aws.amazon.com/rds/)
database instance. It creates a single DB instance and exposes the connection
endpoint so applications can wire up to it.

The defaults are the ones you would want in production: storage encrypted at
rest, no public IP, automated backups retained for seven days, deletion
protection on, and a final snapshot taken on destroy. Every one of them is a
variable you can turn off deliberately — see
[`examples/basic`](examples/basic) for a sandbox that does exactly that.

## Usage

```hcl
module "rds" {
  source = "github.com/moveeeax/terraform-aws-rds?ref=v1.0.0" # pin to a release tag

  identifier = "prod-postgres"
  engine     = "postgres"

  db_name  = "appdb"
  username = "appadmin"
  password = var.db_password

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

### Keeping the master password out of state

A `password` you pass in is stored in Terraform state. To avoid that, leave
`password` unset and let RDS generate the password and keep it in AWS Secrets
Manager; the secret's ARN is exported as `master_user_secret_arn`:

```hcl
  username                    = "appadmin"
  manage_master_user_password = true
  # master_user_secret_kms_key_id = aws_kms_key.db.arn  # optional, defaults to aws/secretsmanager
```

`manage_master_user_password` defaults to `false`, so upgrading the module does
not touch an instance that already uses `password`. It is the recommended
setting for new instances. Switching an existing instance over is a deliberate
change: on apply RDS replaces the current master password with a generated one
stored in the secret, and anything still connecting with the old password
starts failing. Point the applications at the secret (or rotate them in the
same change window) before you apply it.

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| aws       | >= 5.0   |

## Inputs

| Name                     | Description                                             | Type           | Default          | Required |
|--------------------------|---------------------------------------------------------|----------------|------------------|:--------:|
| `identifier`             | Unique identifier for the DB instance. Must start with a letter and contain only letters, numbers, and single hyphens. | `string` | n/a | yes |
| `engine`                 | Database engine to use.                                 | `string`       | `"postgres"`     |    no    |
| `engine_version`         | Engine version to run.                                  | `string`       | `null`           |    no    |
| `instance_class`         | Instance class for the DB instance.                     | `string`       | `"db.t3.micro"`  |    no    |
| `allocated_storage`      | Allocated storage in gibibytes.                         | `number`       | `20`             |    no    |
| `db_name`                | Name of the initial database to create.                 | `string`       | `null`           |    no    |
| `username`               | Master username for the DB instance.                    | `string`       | n/a              |   yes    |
| `password`               | Master password for the DB instance. Ends up in Terraform state; set exactly one of this or `manage_master_user_password`. | `string` | `null` | no |
| `manage_master_user_password` | Let RDS generate the master password and keep it in Secrets Manager, out of Terraform state. | `bool` | `false` | no |
| `master_user_secret_kms_key_id` | KMS key for the managed master user secret. `null` uses `aws/secretsmanager`. | `string` | `null` | no |
| `multi_az`               | Deploy the instance across multiple AZs.                | `bool`         | `false`          |    no    |
| `storage_encrypted`      | Encrypt the underlying storage.                         | `bool`         | `true`           |    no    |
| `vpc_security_group_ids` | VPC security group IDs to associate.                    | `list(string)` | `[]`             |    no    |
| `db_subnet_group_name`   | Name of the DB subnet group to launch in.               | `string`       | `null`           |    no    |
| `publicly_accessible`    | Give the instance a public IP and public DNS name.      | `bool`         | `false`          |    no    |
| `backup_retention_period` | Days to retain automated backups. `0` disables them.   | `number`       | `7`              |    no    |
| `deletion_protection`    | Protect the instance from deletion.                     | `bool`         | `true`           |    no    |
| `skip_final_snapshot`    | Skip the final snapshot on destroy.                     | `bool`         | `false`          |    no    |
| `final_snapshot_identifier` | Name of the final snapshot. `null` derives `<identifier>-final`. | `string` | `null`     |    no    |
| `tags`                   | Tags applied to the DB instance.                        | `map(string)`  | `{}`             |    no    |
| `timeouts`               | Per-operation timeouts (`create`/`update`/`delete`) for the RDS API calls. `null` for a key keeps the AWS provider's own default. | `object({...})` | `null` |    no    |

## Outputs

| Name       | Description                                            |
|------------|--------------------------------------------------------|
| `id`       | Identifier of the DB instance.                         |
| `arn`      | ARN of the DB instance.                                |
| `endpoint` | Connection endpoint in address:port form.              |
| `address`  | Hostname of the DB instance.                           |
| `port`     | Port the DB instance listens on.                       |
| `master_user_secret_arn` | ARN of the Secrets Manager secret with the master password when `manage_master_user_password` is enabled, otherwise `null`. |

## Tearing an instance down

`deletion_protection` defaults to `true`, so a `terraform destroy` against a
fresh instance fails until you disable it. That is the point. To decommission
one on purpose:

1. Set `deletion_protection = false` and apply.
2. Decide about the data. Leaving `skip_final_snapshot = false` keeps a final
   snapshot named `<identifier>-final` (override with
   `final_snapshot_identifier`). Setting `skip_final_snapshot = true` throws the
   data away.
3. `terraform destroy`.

## Long-running operations

The AWS provider's default timeouts (40 minutes to create, 80 to update, 60
to destroy) are sometimes too short for large multi-AZ instances or storage
resizes. Override any of them with `timeouts`:

```hcl
module "rds" {
  source = "github.com/moveeeax/terraform-aws-rds"

  # ...

  timeouts = {
    create = "60m"
    update = "90m"
  }
}
```

A key left out (or the whole variable left `null`) keeps the provider's own
default for that operation.

## Development

```sh
terraform init -backend=false
terraform validate
terraform test
```

`terraform test` uses a mocked AWS provider, so it needs no credentials and
makes no API calls. Running the tests needs Terraform >= 1.7 for
`mock_provider`; consuming the module still only needs >= 1.5.

## License

[MIT](LICENSE)
