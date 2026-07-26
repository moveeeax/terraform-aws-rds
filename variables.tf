variable "identifier" {
  description = "Unique identifier for the DB instance. Must start with a letter, contain only letters, numbers, and hyphens, not end with a hyphen, and not contain two consecutive hyphens."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,62}$", var.identifier)) && !can(regex("--", var.identifier)) && !endswith(var.identifier, "-")
    error_message = "identifier must be 1-63 characters, start with a letter, contain only letters, numbers, and hyphens, not end with a hyphen, and not contain two consecutive hyphens."
  }
}

variable "engine" {
  description = "Database engine to use, for example postgres or mysql."
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Engine version to run. Null lets AWS pick the default for the engine."
  type        = string
  default     = null
}

variable "instance_class" {
  description = "Instance class for the DB instance."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in gibibytes."
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage >= 20
    error_message = "allocated_storage must be at least 20 GiB."
  }
}

variable "db_name" {
  description = "Name of the initial database to create. Null skips creation."
  type        = string
  default     = null
}

variable "username" {
  description = "Master username for the DB instance."
  type        = string
}

variable "password" {
  description = "Master password for the DB instance."
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Whether to deploy the instance across multiple availability zones."
  type        = bool
  default     = false
}

variable "storage_encrypted" {
  description = "Whether to encrypt the underlying storage."
  type        = bool
  default     = true
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs to associate with the instance."
  type        = list(string)
  default     = []
}

variable "db_subnet_group_name" {
  description = "Name of the DB subnet group to launch the instance in. Null uses the default."
  type        = string
  default     = null
}

variable "publicly_accessible" {
  description = "Whether the instance gets a public IP and a publicly resolvable DNS name. Keep this false unless the database genuinely has to be reachable from the internet."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups. Zero disables automated backups and also disables point-in-time recovery."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35 && floor(var.backup_retention_period) == var.backup_retention_period
    error_message = "backup_retention_period must be a whole number between 0 and 35."
  }
}

variable "deletion_protection" {
  description = "Whether to protect the instance from being deleted. Set this to false before a deliberate teardown."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Whether to skip taking a final snapshot when the instance is destroyed. Skipping it means the data is gone for good."
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "Name of the final snapshot taken on destroy. Null derives \"<identifier>-final\". Ignored when skip_final_snapshot is true."
  type        = string
  default     = null

  validation {
    condition = var.final_snapshot_identifier == null ? true : (
      can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,254}$", var.final_snapshot_identifier)) &&
      !can(regex("--", var.final_snapshot_identifier)) &&
      !endswith(var.final_snapshot_identifier, "-")
    )
    error_message = "final_snapshot_identifier must be 1-255 characters, start with a letter, contain only letters, numbers, and hyphens, not end with a hyphen, and not contain two consecutive hyphens."
  }
}

variable "tags" {
  description = "Tags applied to the DB instance."
  type        = map(string)
  default     = {}
}

variable "timeouts" {
  description = "Per-operation timeouts for the underlying RDS API calls. Null for any key leaves the AWS provider's own default for that operation (create 40m, update 80m, delete 60m), which is too short for some multi-AZ or large-storage instances."
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}
