variable "loader_role_name" {
  description = "Name of the loader role"
  type        = string
}

variable "reader_role_name" {
  description = "Name of the reader role"
  type        = string
}

variable "admin_role_name" {
  description = "Name of the admin role"
  type        = string
}

variable "database_name" {
  description = "Name of the database to grant access to"
  type        = string
}

variable "schema_name" {
  description = "Name of the schema to grant access to"
  type        = string
}

variable "warehouse_name" {
  description = "Name of the warehouse to grant access to"
  type        = string
}
