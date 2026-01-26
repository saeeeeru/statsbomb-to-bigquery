"""Configuration management for StatsBomb Snowflake loader."""

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class SnowflakeSettings(BaseSettings):
    """Snowflake connection settings."""

    model_config = SettingsConfigDict(env_prefix="SNOWFLAKE_")

    account: str = Field(..., description="Snowflake account identifier")
    user: str = Field(..., description="Snowflake username")
    password: str = Field(..., description="Snowflake password")
    warehouse: str = Field(default="COMPUTE_WH", description="Snowflake warehouse")
    database: str = Field(default="RAW", description="Snowflake database for landing layer")
    schema_name: str = Field(
        default="STATSBOMB", alias="SNOWFLAKE_SCHEMA", description="Snowflake schema"
    )
    role: str | None = Field(default=None, description="Snowflake role")


class StatsBombSettings(BaseSettings):
    """StatsBomb data source settings."""

    model_config = SettingsConfigDict(env_prefix="STATSBOMB_")

    base_url: str = Field(
        default="https://raw.githubusercontent.com/statsbomb/open-data/master/data",
        description="Base URL for StatsBomb open data",
    )
    # Optional: filter specific competitions/seasons
    competition_ids: list[int] | None = Field(
        default=None, description="Specific competition IDs to load (None = all)"
    )
    season_ids: list[int] | None = Field(
        default=None, description="Specific season IDs to load (None = all)"
    )


class Settings(BaseSettings):
    """Application settings."""

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    snowflake: SnowflakeSettings = Field(default_factory=SnowflakeSettings)
    statsbomb: StatsBombSettings = Field(default_factory=StatsBombSettings)
    batch_size: int = Field(default=1000, description="Batch size for inserts")
    dry_run: bool = Field(default=False, description="Dry run mode (no actual inserts)")


def get_settings() -> Settings:
    """Get application settings from environment."""
    return Settings(
        snowflake=SnowflakeSettings(),
        statsbomb=StatsBombSettings(),
    )
