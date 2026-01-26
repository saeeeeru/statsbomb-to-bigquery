-- Landing layer table for StatsBomb events data
-- Raw JSON data is stored in VARIANT column for flexibility
-- This is the largest table - each match can have thousands of events

CREATE TABLE IF NOT EXISTS landing_events (
    -- Primary key columns
    event_id VARCHAR(36) NOT NULL,  -- UUID format

    -- Foreign key columns (for partitioning/filtering)
    match_id INTEGER NOT NULL,

    -- Denormalized column for common queries
    event_type VARCHAR(100),

    -- Raw JSON data from StatsBomb API
    raw_data VARIANT NOT NULL,

    -- Metadata columns
    _loaded_at TIMESTAMP_TZ NOT NULL DEFAULT CURRENT_TIMESTAMP(),

    -- Primary key constraint
    PRIMARY KEY (event_id)
);

-- Index for common query patterns
CREATE INDEX IF NOT EXISTS idx_landing_events_match_id ON landing_events (match_id);
CREATE INDEX IF NOT EXISTS idx_landing_events_event_type ON landing_events (event_type);

-- Comment on table
COMMENT ON TABLE landing_events IS 'Landing layer for StatsBomb events data. Contains raw JSON data for each event in a match.';

-- Comments on columns
COMMENT ON COLUMN landing_events.event_id IS 'Unique identifier for the event (UUID)';
COMMENT ON COLUMN landing_events.match_id IS 'Unique identifier for the match';
COMMENT ON COLUMN landing_events.event_type IS 'Type of event (Pass, Shot, etc.) - denormalized for query performance';
COMMENT ON COLUMN landing_events.raw_data IS 'Raw JSON data from StatsBomb open data';
COMMENT ON COLUMN landing_events._loaded_at IS 'Timestamp when the record was loaded'
