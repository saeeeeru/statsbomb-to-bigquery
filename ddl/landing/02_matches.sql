-- Landing layer table for StatsBomb matches data
-- Raw JSON data is stored in VARIANT column for flexibility

CREATE TABLE IF NOT EXISTS landing_matches (
    -- Primary key columns
    match_id INTEGER NOT NULL,

    -- Foreign key columns (for partitioning/filtering)
    competition_id INTEGER NOT NULL,
    season_id INTEGER NOT NULL,

    -- Raw JSON data from StatsBomb API
    raw_data VARIANT NOT NULL,

    -- Metadata columns
    _loaded_at TIMESTAMP_TZ NOT NULL DEFAULT CURRENT_TIMESTAMP(),

    -- Primary key constraint
    PRIMARY KEY (match_id)
);

-- Comment on table
COMMENT ON TABLE landing_matches IS 'Landing layer for StatsBomb matches data. Contains raw JSON data for each match.';

-- Comments on columns
COMMENT ON COLUMN landing_matches.match_id IS 'Unique identifier for the match';
COMMENT ON COLUMN landing_matches.competition_id IS 'Unique identifier for the competition';
COMMENT ON COLUMN landing_matches.season_id IS 'Unique identifier for the season';
COMMENT ON COLUMN landing_matches.raw_data IS 'Raw JSON data from StatsBomb open data';
COMMENT ON COLUMN landing_matches._loaded_at IS 'Timestamp when the record was loaded'
