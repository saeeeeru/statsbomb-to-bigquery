variable "database_name" {
  description = "Name of the Snowflake database"
  type        = string
}

variable "database_comment" {
  description = "Comment for the database"
  type        = string
  default     = ""
}

variable "data_retention_days" {
  description = "Number of days for Time Travel"
  type        = number
  default     = 1
}

variable "schema_name" {
  description = "Name of the schema"
  type        = string
}

variable "schema_comment" {
  description = "Comment for the schema"
  type        = string
  default     = ""
}

variable "with_managed_access" {
  description = "Enable managed access for the schema"
  type        = bool
  default     = false
}
