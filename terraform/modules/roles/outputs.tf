output "loader_role_name" {
  description = "Name of the loader role"
  value       = snowflake_account_role.loader.name
}

output "reader_role_name" {
  description = "Name of the reader role"
  value       = snowflake_account_role.reader.name
}

output "admin_role_name" {
  description = "Name of the admin role"
  value       = snowflake_account_role.admin.name
}
