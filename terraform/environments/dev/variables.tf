################################################################################
# Snowflake Connection Variables
################################################################################

variable "snowflake_account" {
  description = "Snowflake account identifier"
  type        = string
}

variable "snowflake_user" {
  description = "Snowflake username"
  type        = string
}

variable "snowflake_password" {
  description = "Snowflake password"
  type        = string
  sensitive   = true
}

variable "snowflake_role" {
  description = "Snowflake role for Terraform operations"
  type        = string
  default     = "SYSADMIN"
}

################################################################################
# Project Variables
################################################################################

variable "project_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "STATSBOMB_DEV"
}

variable "database_name" {
  description = "Name of the database"
  type        = string
  default     = "RAW_DEV"
}

variable "schema_name" {
  description = "Name of the schema"
  type        = string
  default     = "STATSBOMB"
}

variable "data_retention_days" {
  description = "Number of days for Time Travel"
  type        = number
  default     = 1
}

################################################################################
# Warehouse Variables
################################################################################

variable "warehouse_name" {
  description = "Name of the warehouse"
  type        = string
  default     = "STATSBOMB_WH_DEV"
}

variable "warehouse_size" {
  description = "Size of the warehouse"
  type        = string
  default     = "X-Small"
}

variable "warehouse_auto_suspend" {
  description = "Auto-suspend time in seconds"
  type        = number
  default     = 60
}
