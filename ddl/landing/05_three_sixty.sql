-- Landing layer table for StatsBomb 360 data
-- Raw JSON data is stored in VARIANT column for flexibility
-- 360 data provides freeze frame information for events

CREATE TABLE IF NOT EXISTS landing_three_sixty (
    -- Primary key columns
    event_uuid VARCHAR(36) NOT NULL,  -- UUID format, links to events

    -- Foreign key columns (for partitioning/filtering)
    match_id INTEGER NOT NULL,

    -- Raw JSON data from StatsBomb API
    raw_data VARIANT NOT NULL,

    -- Metadata columns
    _loaded_at TIMESTAMP_TZ NOT NULL DEFAULT CURRENT_TIMESTAMP(),

    -- Primary key constraint
    PRIMARY KEY (event_uuid)
);

-- Index for common query patterns
CREATE INDEX IF NOT EXISTS idx_landing_three_sixty_match_id ON landing_three_sixty (match_id);

-- Comment on table
COMMENT ON TABLE landing_three_sixty IS 'Landing layer for StatsBomb 360 data. Contains freeze frame information for events.';

-- Comments on columns
COMMENT ON COLUMN landing_three_sixty.event_uuid IS 'UUID linking to the corresponding event';
COMMENT ON COLUMN landing_three_sixty.match_id IS 'Unique identifier for the match';
COMMENT ON COLUMN landing_three_sixty.raw_data IS 'Raw JSON data from StatsBomb open data (freeze frame)';
COMMENT ON COLUMN landing_three_sixty._loaded_at IS 'Timestamp when the record was loaded'
