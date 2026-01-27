-- Landing layer table for StatsBomb competitions data
-- Raw JSON data is stored in VARIANT column for flexibility

CREATE TABLE IF NOT EXISTS landing_competitions (
    -- Primary key columns
    competition_id INTEGER NOT NULL,
    season_id INTEGER NOT NULL,

    -- Raw JSON data from StatsBomb API
    raw_data VARIANT NOT NULL,

    -- Metadata columns
    _loaded_at TIMESTAMP_TZ NOT NULL DEFAULT CURRENT_TIMESTAMP(),

    -- Primary key constraint
    PRIMARY KEY (competition_id, season_id)
);

-- Comment on table
COMMENT ON TABLE landing_competitions IS 'Landing layer for StatsBomb competitions data. Contains raw JSON data for each competition/season combination.';

-- Comments on columns
COMMENT ON COLUMN landing_competitions.competition_id IS 'Unique identifier for the competition';
COMMENT ON COLUMN landing_competitions.season_id IS 'Unique identifier for the season';
COMMENT ON COLUMN landing_competitions.raw_data IS 'Raw JSON data from StatsBomb open data';
COMMENT ON COLUMN landing_competitions._loaded_at IS 'Timestamp when the record was loaded'
