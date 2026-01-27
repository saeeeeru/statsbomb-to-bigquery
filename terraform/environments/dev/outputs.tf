output "database_name" {
  description = "Name of the created database"
  value       = module.database.database_name
}

output "schema_name" {
  description = "Name of the created schema"
  value       = module.database.schema_name
}

output "warehouse_name" {
  description = "Name of the created warehouse"
  value       = module.warehouse.warehouse_name
}

output "roles" {
  description = "Created role names"
  value = {
    loader = module.roles.loader_role_name
    reader = module.roles.reader_role_name
    admin  = module.roles.admin_role_name
  }
}

output "landing_tables" {
  description = "Fully qualified names of landing tables"
  value       = module.landing_tables.fully_qualified_table_names
}
