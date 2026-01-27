################################################################################
# Snowflake Warehouse Module
################################################################################

resource "snowflake_warehouse" "this" {
  name           = var.warehouse_name
  comment        = var.warehouse_comment
  warehouse_size = var.warehouse_size

  # Auto-suspend and auto-resume settings
  auto_suspend          = var.auto_suspend
  auto_resume           = var.auto_resume
  initially_suspended   = var.initially_suspended

  # Scaling policy (for multi-cluster warehouses)
  min_cluster_count        = var.min_cluster_count
  max_cluster_count        = var.max_cluster_count
  scaling_policy           = var.scaling_policy

  # Query settings
  statement_timeout_in_seconds      = var.statement_timeout_in_seconds
  statement_queued_timeout_in_seconds = var.statement_queued_timeout_in_seconds

  # Resource monitor (optional)
  resource_monitor = var.resource_monitor
}
