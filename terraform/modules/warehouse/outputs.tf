output "warehouse_name" {
  description = "Name of the created warehouse"
  value       = snowflake_warehouse.this.name
}

output "warehouse_size" {
  description = "Size of the warehouse"
  value       = snowflake_warehouse.this.warehouse_size
}
