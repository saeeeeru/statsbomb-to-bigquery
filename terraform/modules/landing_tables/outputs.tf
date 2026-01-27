output "table_names" {
  description = "Names of the created landing tables"
  value = {
    competitions = snowflake_table.landing_competitions.name
    matches      = snowflake_table.landing_matches.name
    events       = snowflake_table.landing_events.name
    lineups      = snowflake_table.landing_lineups.name
    three_sixty  = snowflake_table.landing_three_sixty.name
  }
}

output "fully_qualified_table_names" {
  description = "Fully qualified names of the created landing tables"
  value = {
    competitions = "${var.database_name}.${var.schema_name}.${snowflake_table.landing_competitions.name}"
    matches      = "${var.database_name}.${var.schema_name}.${snowflake_table.landing_matches.name}"
    events       = "${var.database_name}.${var.schema_name}.${snowflake_table.landing_events.name}"
    lineups      = "${var.database_name}.${var.schema_name}.${snowflake_table.landing_lineups.name}"
    three_sixty  = "${var.database_name}.${var.schema_name}.${snowflake_table.landing_three_sixty.name}"
  }
}
