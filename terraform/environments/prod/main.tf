################################################################################
# StatsBomb Snowflake Infrastructure - Production Environment
################################################################################

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.87"
    }
  }

  # Uncomment and configure for remote state management
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "statsbomb/prod/terraform.tfstate"
  #   region         = "ap-northeast-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "snowflake" {
  account  = var.snowflake_account
  user     = var.snowflake_user
  password = var.snowflake_password
  role     = var.snowflake_role
}

################################################################################
# Database & Schema
################################################################################

module "database" {
  source = "../../modules/database"

  database_name       = var.database_name
  database_comment    = "StatsBomb Open Data - Production"
  data_retention_days = var.data_retention_days
  schema_name         = var.schema_name
  schema_comment      = "Landing layer for StatsBomb data"
  with_managed_access = true
}

################################################################################
# Warehouse
################################################################################

module "warehouse" {
  source = "../../modules/warehouse"

  warehouse_name    = var.warehouse_name
  warehouse_comment = "Warehouse for StatsBomb data processing - Production"
  warehouse_size    = var.warehouse_size

  auto_suspend        = var.warehouse_auto_suspend
  auto_resume         = true
  initially_suspended = true

  # Production scaling settings
  min_cluster_count = var.warehouse_min_cluster_count
  max_cluster_count = var.warehouse_max_cluster_count
  scaling_policy    = var.warehouse_scaling_policy
}

################################################################################
# Roles & Grants
################################################################################

module "roles" {
  source = "../../modules/roles"

  loader_role_name = "${var.project_prefix}_LOADER"
  reader_role_name = "${var.project_prefix}_READER"
  admin_role_name  = "${var.project_prefix}_ADMIN"

  database_name  = module.database.database_name
  schema_name    = module.database.schema_name
  warehouse_name = module.warehouse.warehouse_name

  depends_on = [module.database, module.warehouse]
}

################################################################################
# Landing Layer Tables
################################################################################

module "landing_tables" {
  source = "../../modules/landing_tables"

  database_name = module.database.database_name
  schema_name   = module.database.schema_name

  depends_on = [module.database]
}
