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
  default     = "STATSBOMB"
}

variable "database_name" {
  description = "Name of the database"
  type        = string
  default     = "RAW"
}

variable "schema_name" {
  description = "Name of the schema"
  type        = string
  default     = "STATSBOMB"
}

variable "data_retention_days" {
  description = "Number of days for Time Travel"
  type        = number
  default     = 7
}

################################################################################
# Warehouse Variables
################################################################################

variable "warehouse_name" {
  description = "Name of the warehouse"
  type        = string
  default     = "STATSBOMB_WH"
}

variable "warehouse_size" {
  description = "Size of the warehouse"
  type        = string
  default     = "Small"
}

variable "warehouse_auto_suspend" {
  description = "Auto-suspend time in seconds"
  type        = number
  default     = 300
}

variable "warehouse_min_cluster_count" {
  description = "Minimum number of clusters"
  type        = number
  default     = 1
}

variable "warehouse_max_cluster_count" {
  description = "Maximum number of clusters"
  type        = number
  default     = 2
}

variable "warehouse_scaling_policy" {
  description = "Scaling policy (STANDARD or ECONOMY)"
  type        = string
  default     = "STANDARD"
}
