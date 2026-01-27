output "database_name" {
  description = "Name of the created database"
  value       = snowflake_database.this.name
}

output "schema_name" {
  description = "Name of the created schema"
  value       = snowflake_schema.this.name
}

output "fully_qualified_schema_name" {
  description = "Fully qualified schema name (database.schema)"
  value       = "${snowflake_database.this.name}.${snowflake_schema.this.name}"
}
