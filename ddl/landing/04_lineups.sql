-- Landing layer table for StatsBomb lineups data
-- Raw JSON data is stored in VARIANT column for flexibility
-- Each match has 2 lineups (one per team)

CREATE TABLE IF NOT EXISTS landing_lineups (
    -- Primary key columns (composite)
    match_id INTEGER NOT NULL,
    team_id INTEGER NOT NULL,

    -- Raw JSON data from StatsBomb API
    raw_data VARIANT NOT NULL,

    -- Metadata columns
    _loaded_at TIMESTAMP_TZ NOT NULL DEFAULT CURRENT_TIMESTAMP(),

    -- Primary key constraint
    PRIMARY KEY (match_id, team_id)
);

-- Comment on table
COMMENT ON TABLE landing_lineups IS 'Landing layer for StatsBomb lineups data. Contains raw JSON data for each team lineup in a match.';

-- Comments on columns
COMMENT ON COLUMN landing_lineups.match_id IS 'Unique identifier for the match';
COMMENT ON COLUMN landing_lineups.team_id IS 'Unique identifier for the team';
COMMENT ON COLUMN landing_lineups.raw_data IS 'Raw JSON data from StatsBomb open data';
COMMENT ON COLUMN landing_lineups._loaded_at IS 'Timestamp when the record was loaded'
