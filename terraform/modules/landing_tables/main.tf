################################################################################
# Snowflake Landing Layer Tables Module
################################################################################

locals {
  fully_qualified_schema = "\"${var.database_name}\".\"${var.schema_name}\""
}

################################################################################
# Competitions Table
################################################################################

resource "snowflake_table" "landing_competitions" {
  database = var.database_name
  schema   = var.schema_name
  name     = "LANDING_COMPETITIONS"
  comment  = "Landing layer for StatsBomb competitions data. Contains raw JSON data for competition and season information."

  column {
    name     = "COMPETITION_ID"
    type     = "NUMBER(38,0)"
    nullable = false
  }

  column {
    name     = "SEASON_ID"
    type     = "NUMBER(38,0)"
    nullable = false
  }

  column {
    name     = "RAW_DATA"
    type     = "VARIANT"
    nullable = false
  }

  column {
    name     = "_LOADED_AT"
    type     = "TIMESTAMP_TZ(9)"
    nullable = false
    default {
      expression = "CURRENT_TIMESTAMP()"
    }
  }

  primary_key {
    keys = ["COMPETITION_ID", "SEASON_ID"]
  }
}

################################################################################
# Matches Table
################################################################################

resource "snowflake_table" "landing_matches" {
  database = var.database_name
  schema   = var.schema_name
  name     = "LANDING_MATCHES"
  comment  = "Landing layer for StatsBomb matches data. Contains raw JSON data for match information."

  column {
    name     = "MATCH_ID"
    type     = "NUMBER(38,0)"
    nullable = false
  }

  column {
    name     = "COMPETITION_ID"
    type     = "NUMBER(38,0)"
    nullable = false
  }

  column {
    name     = "SEASON_ID"
    type     = "NUMBER(38,0)"
    nullable = false
  }

  column {
    name     = "RAW_DATA"
    type     = "VARIANT"
    nullable = false
  }

  column {
    name     = "_LOADED_AT"
    type     = "TIMESTAMP_TZ(9)"
    nullable = false
    default {
      expression = "CURRENT_TIMESTAMP()"
    }
  }

  primary_key {
    keys = ["MATCH_ID"]
  }

  cluster_by = ["COMPETITION_ID", "SEASON_ID"]
}

################################################################################
# Events Table
################################################################################

resource "snowflake_table" "landing_events" {
  database = var.database_name
  schema   = var.schema_name
  name     = "LANDING_EVENTS"
  comment  = "Landing layer for StatsBomb events data. Contains raw JSON data for match events (passes, shots, etc.)."

  column {
    name     = "EVENT_ID"
    type     = "VARCHAR(36)"
    nullable = false
  }

  column {
    name     = "MATCH_ID"
    type     = "NUMBER(38,0)"
    nullable = false
  }

  column {
    name     = "EVENT_TYPE"
    type     = "VARCHAR(100)"
    nullable = true
  }

  column {
    name     = "RAW_DATA"
    type     = "VARIANT"
    nullable = false
  }

  column {
    name     = "_LOADED_AT"
    type     = "TIMESTAMP_TZ(9)"
    nullable = false
    default {
      expression = "CURRENT_TIMESTAMP()"
    }
  }

  primary_key {
    keys = ["EVENT_ID"]
  }

  cluster_by = ["MATCH_ID", "EVENT_TYPE"]
}

################################################################################
# Lineups Table
################################################################################

resource "snowflake_table" "landing_lineups" {
  database = var.database_name
  schema   = var.schema_name
  name     = "LANDING_LINEUPS"
  comment  = "Landing layer for StatsBomb lineups data. Contains raw JSON data for match lineups."

  column {
    name     = "MATCH_ID"
    type     = "NUMBER(38,0)"
    nullable = false
  }

  column {
    name     = "TEAM_ID"
    type     = "NUMBER(38,0)"
    nullable = false
  }

  column {
    name     = "RAW_DATA"
    type     = "VARIANT"
    nullable = false
  }

  column {
    name     = "_LOADED_AT"
    type     = "TIMESTAMP_TZ(9)"
    nullable = false
    default {
      expression = "CURRENT_TIMESTAMP()"
    }
  }

  primary_key {
    keys = ["MATCH_ID", "TEAM_ID"]
  }
}

################################################################################
# Three-Sixty Table
################################################################################

resource "snowflake_table" "landing_three_sixty" {
  database = var.database_name
  schema   = var.schema_name
  name     = "LANDING_THREE_SIXTY"
  comment  = "Landing layer for StatsBomb 360 data. Contains freeze frame information for events."

  column {
    name     = "EVENT_UUID"
    type     = "VARCHAR(36)"
    nullable = false
  }

  column {
    name     = "MATCH_ID"
    type     = "NUMBER(38,0)"
    nullable = false
  }

  column {
    name     = "RAW_DATA"
    type     = "VARIANT"
    nullable = false
  }

  column {
    name     = "_LOADED_AT"
    type     = "TIMESTAMP_TZ(9)"
    nullable = false
    default {
      expression = "CURRENT_TIMESTAMP()"
    }
  }

  primary_key {
    keys = ["EVENT_UUID"]
  }

  cluster_by = ["MATCH_ID"]
}
