################################################################################
# Snowflake Database & Schema Module
################################################################################

resource "snowflake_database" "this" {
  name                        = var.database_name
  comment                     = var.database_comment
  data_retention_time_in_days = var.data_retention_days
}

resource "snowflake_schema" "this" {
  database            = snowflake_database.this.name
  name                = var.schema_name
  comment             = var.schema_comment
  with_managed_access = var.with_managed_access
}
