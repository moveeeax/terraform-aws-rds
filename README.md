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
  source = "github.com/moveeeax/terraform-aws-rds"

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

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| aws       | >= 5.0   |

## Inputs

| Name                     | Description                                             | Type           | Default          | Required |
|--------------------------|---------------------------------------------------------|----------------|------------------|:--------:|
| `identifier`             | Unique identifier for the DB instance.                  | `string`       | n/a              |   yes    |
| `engine`                 | Database engine to use.                                 | `string`       | `"postgres"`     |    no    |
| `engine_version`         | Engine version to run.                                  | `string`       | `null`           |    no    |
| `instance_class`         | Instance class for the DB instance.                     | `string`       | `"db.t3.micro"`  |    no    |
| `allocated_storage`      | Allocated storage in gibibytes.                         | `number`       | `20`             |    no    |
| `db_name`                | Name of the initial database to create.                 | `string`       | `null`           |    no    |
| `username`               | Master username for the DB instance.                    | `string`       | n/a              |   yes    |
| `password`               | Master password for the DB instance.                    | `string`       | n/a              |   yes    |
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

## Outputs

| Name       | Description                                            |
|------------|--------------------------------------------------------|
| `id`       | Identifier of the DB instance.                         |
| `arn`      | ARN of the DB instance.                                |
| `endpoint` | Connection endpoint in address:port form.              |
| `address`  | Hostname of the DB instance.                           |
| `port`     | Port the DB instance listens on.                       |

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
