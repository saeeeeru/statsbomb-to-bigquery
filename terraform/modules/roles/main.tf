################################################################################
# Snowflake Roles & Grants Module
################################################################################

# Loader Role - for ETL/ELT processes
resource "snowflake_account_role" "loader" {
  name    = var.loader_role_name
  comment = "Role for loading data into landing layer"
}

# Reader Role - for analysts and BI tools
resource "snowflake_account_role" "reader" {
  name    = var.reader_role_name
  comment = "Role for reading data from landing layer"
}

# Admin Role - for managing the database and schema
resource "snowflake_account_role" "admin" {
  name    = var.admin_role_name
  comment = "Role for administering StatsBomb database"
}

################################################################################
# Database Grants
################################################################################

# Admin gets full control on database
resource "snowflake_grant_privileges_to_account_role" "admin_database" {
  account_role_name = snowflake_account_role.admin.name
  privileges        = ["ALL PRIVILEGES"]

  on_account_object {
    object_type = "DATABASE"
    object_name = var.database_name
  }
}

# Loader gets usage on database
resource "snowflake_grant_privileges_to_account_role" "loader_database" {
  account_role_name = snowflake_account_role.loader.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = var.database_name
  }
}

# Reader gets usage on database
resource "snowflake_grant_privileges_to_account_role" "reader_database" {
  account_role_name = snowflake_account_role.reader.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = var.database_name
  }
}

################################################################################
# Schema Grants
################################################################################

# Admin gets full control on schema
resource "snowflake_grant_privileges_to_account_role" "admin_schema" {
  account_role_name = snowflake_account_role.admin.name
  privileges        = ["ALL PRIVILEGES"]

  on_schema {
    schema_name = "\"${var.database_name}\".\"${var.schema_name}\""
  }
}

# Loader gets usage and create table on schema
resource "snowflake_grant_privileges_to_account_role" "loader_schema" {
  account_role_name = snowflake_account_role.loader.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW"]

  on_schema {
    schema_name = "\"${var.database_name}\".\"${var.schema_name}\""
  }
}

# Reader gets usage on schema
resource "snowflake_grant_privileges_to_account_role" "reader_schema" {
  account_role_name = snowflake_account_role.reader.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "\"${var.database_name}\".\"${var.schema_name}\""
  }
}

################################################################################
# Table Grants (Future Grants for new tables)
################################################################################

# Loader gets full control on all tables
resource "snowflake_grant_privileges_to_account_role" "loader_tables" {
  account_role_name = snowflake_account_role.loader.name
  privileges        = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${var.database_name}\".\"${var.schema_name}\""
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "loader_tables_existing" {
  account_role_name = snowflake_account_role.loader.name
  privileges        = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]

  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_schema          = "\"${var.database_name}\".\"${var.schema_name}\""
    }
  }
}

# Reader gets SELECT on all tables
resource "snowflake_grant_privileges_to_account_role" "reader_tables" {
  account_role_name = snowflake_account_role.reader.name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${var.database_name}\".\"${var.schema_name}\""
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "reader_tables_existing" {
  account_role_name = snowflake_account_role.reader.name
  privileges        = ["SELECT"]

  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_schema          = "\"${var.database_name}\".\"${var.schema_name}\""
    }
  }
}

################################################################################
# Warehouse Grants
################################################################################

# Loader gets usage on warehouse
resource "snowflake_grant_privileges_to_account_role" "loader_warehouse" {
  account_role_name = snowflake_account_role.loader.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = var.warehouse_name
  }
}

# Reader gets usage on warehouse
resource "snowflake_grant_privileges_to_account_role" "reader_warehouse" {
  account_role_name = snowflake_account_role.reader.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = var.warehouse_name
  }
}

# Admin gets full control on warehouse
resource "snowflake_grant_privileges_to_account_role" "admin_warehouse" {
  account_role_name = snowflake_account_role.admin.name
  privileges        = ["ALL PRIVILEGES"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = var.warehouse_name
  }
}

################################################################################
# Role Hierarchy
################################################################################

# Admin role inherits from loader and reader
resource "snowflake_grant_account_role" "admin_inherits_loader" {
  role_name        = snowflake_account_role.loader.name
  parent_role_name = snowflake_account_role.admin.name
}

resource "snowflake_grant_account_role" "admin_inherits_reader" {
  role_name        = snowflake_account_role.reader.name
  parent_role_name = snowflake_account_role.admin.name
}

# Grant roles to SYSADMIN for management
resource "snowflake_grant_account_role" "sysadmin_admin" {
  role_name        = snowflake_account_role.admin.name
  parent_role_name = "SYSADMIN"
}
