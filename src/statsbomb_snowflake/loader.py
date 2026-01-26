"""Snowflake loader module for landing layer."""

import json
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Generator

import snowflake.connector
from rich.console import Console
from snowflake.connector import SnowflakeConnection
from snowflake.connector.cursor import SnowflakeCursor

from .config import SnowflakeSettings

console = Console()

# Path to DDL files
DDL_DIR = Path(__file__).parent.parent.parent / "ddl" / "landing"


class SnowflakeLoader:
    """Loader for StatsBomb data into Snowflake landing layer."""

    def __init__(self, settings: SnowflakeSettings, dry_run: bool = False):
        self.settings = settings
        self.dry_run = dry_run
        self._connection: SnowflakeConnection | None = None

    @contextmanager
    def connection(self) -> Generator[SnowflakeConnection, None, None]:
        """Context manager for Snowflake connection."""
        conn = snowflake.connector.connect(
            account=self.settings.account,
            user=self.settings.user,
            password=self.settings.password,
            warehouse=self.settings.warehouse,
            database=self.settings.database,
            schema=self.settings.schema_name,
            role=self.settings.role,
        )
        try:
            yield conn
        finally:
            conn.close()

    @contextmanager
    def cursor(self, conn: SnowflakeConnection) -> Generator[SnowflakeCursor, None, None]:
        """Context manager for Snowflake cursor."""
        cur = conn.cursor()
        try:
            yield cur
        finally:
            cur.close()

    def execute_ddl(self, conn: SnowflakeConnection) -> None:
        """Execute all DDL files to create landing layer tables."""
        console.print("[blue]Creating landing layer tables...[/blue]")

        if not DDL_DIR.exists():
            console.print(f"[red]DDL directory not found: {DDL_DIR}[/red]")
            return

        ddl_files = sorted(DDL_DIR.glob("*.sql"))
        if not ddl_files:
            console.print("[yellow]No DDL files found[/yellow]")
            return

        with self.cursor(conn) as cur:
            # Create schema if not exists
            cur.execute(f"CREATE SCHEMA IF NOT EXISTS {self.settings.schema_name}")

            for ddl_file in ddl_files:
                console.print(f"  Executing {ddl_file.name}...")
                ddl_sql = ddl_file.read_text()

                # Execute each statement separately (split by semicolon)
                for statement in ddl_sql.split(";"):
                    statement = statement.strip()
                    if statement:
                        if self.dry_run:
                            console.print(f"    [dim]DRY RUN: {statement[:100]}...[/dim]")
                        else:
                            cur.execute(statement)

        console.print("[green]Landing layer tables created successfully[/green]")

    def _get_load_timestamp(self) -> str:
        """Get current timestamp for _loaded_at column."""
        return datetime.now(timezone.utc).isoformat()

    def load_competitions(
        self, conn: SnowflakeConnection, competitions: list[dict[str, Any]], batch_size: int = 1000
    ) -> int:
        """Load competitions data into landing layer.

        Returns number of rows loaded.
        """
        if not competitions:
            return 0

        table = "landing_competitions"
        console.print(f"[blue]Loading {len(competitions)} competitions to {table}...[/blue]")

        if self.dry_run:
            console.print(f"[dim]DRY RUN: Would load {len(competitions)} rows[/dim]")
            return len(competitions)

        loaded_at = self._get_load_timestamp()
        rows_loaded = 0

        with self.cursor(conn) as cur:
            # Truncate and reload for competitions (small dataset, full refresh)
            cur.execute(f"TRUNCATE TABLE IF EXISTS {table}")

            for i in range(0, len(competitions), batch_size):
                batch = competitions[i : i + batch_size]
                values = []
                for comp in batch:
                    comp_json = json.dumps(comp, ensure_ascii=False)
                    values.append((comp["competition_id"], comp["season_id"], comp_json, loaded_at))

                cur.executemany(
                    f"""
                    INSERT INTO {table} (competition_id, season_id, raw_data, _loaded_at)
                    VALUES (%s, %s, PARSE_JSON(%s), %s)
                    """,
                    values,
                )
                rows_loaded += len(batch)

        console.print(f"[green]Loaded {rows_loaded} competitions[/green]")
        return rows_loaded

    def load_matches(
        self,
        conn: SnowflakeConnection,
        matches: list[dict[str, Any]],
        competition_id: int,
        season_id: int,
        batch_size: int = 1000,
    ) -> int:
        """Load matches data into landing layer.

        Returns number of rows loaded.
        """
        if not matches:
            return 0

        table = "landing_matches"
        console.print(
            f"[blue]Loading {len(matches)} matches for competition {competition_id}, "
            f"season {season_id}...[/blue]"
        )

        if self.dry_run:
            console.print(f"[dim]DRY RUN: Would load {len(matches)} rows[/dim]")
            return len(matches)

        loaded_at = self._get_load_timestamp()
        rows_loaded = 0

        with self.cursor(conn) as cur:
            # Delete existing matches for this competition/season (incremental load)
            cur.execute(
                f"""
                DELETE FROM {table}
                WHERE competition_id = %s AND season_id = %s
                """,
                (competition_id, season_id),
            )

            for i in range(0, len(matches), batch_size):
                batch = matches[i : i + batch_size]
                values = []
                for match in batch:
                    match_json = json.dumps(match, ensure_ascii=False)
                    values.append(
                        (
                            match["match_id"],
                            competition_id,
                            season_id,
                            match_json,
                            loaded_at,
                        )
                    )

                cur.executemany(
                    f"""
                    INSERT INTO {table} (match_id, competition_id, season_id, raw_data, _loaded_at)
                    VALUES (%s, %s, %s, PARSE_JSON(%s), %s)
                    """,
                    values,
                )
                rows_loaded += len(batch)

        console.print(f"[green]Loaded {rows_loaded} matches[/green]")
        return rows_loaded

    def load_events(
        self,
        conn: SnowflakeConnection,
        events: list[dict[str, Any]],
        match_id: int,
        batch_size: int = 1000,
    ) -> int:
        """Load events data into landing layer.

        Returns number of rows loaded.
        """
        if not events:
            return 0

        table = "landing_events"

        if self.dry_run:
            console.print(f"[dim]DRY RUN: Would load {len(events)} events for match {match_id}[/dim]")
            return len(events)

        loaded_at = self._get_load_timestamp()
        rows_loaded = 0

        with self.cursor(conn) as cur:
            # Delete existing events for this match (incremental load)
            cur.execute(f"DELETE FROM {table} WHERE match_id = %s", (match_id,))

            for i in range(0, len(events), batch_size):
                batch = events[i : i + batch_size]
                values = []
                for event in batch:
                    event_json = json.dumps(event, ensure_ascii=False)
                    values.append(
                        (
                            event.get("id"),
                            match_id,
                            event.get("type", {}).get("name"),
                            event_json,
                            loaded_at,
                        )
                    )

                cur.executemany(
                    f"""
                    INSERT INTO {table} (event_id, match_id, event_type, raw_data, _loaded_at)
                    VALUES (%s, %s, %s, PARSE_JSON(%s), %s)
                    """,
                    values,
                )
                rows_loaded += len(batch)

        return rows_loaded

    def load_lineups(
        self,
        conn: SnowflakeConnection,
        lineups: list[dict[str, Any]],
        match_id: int,
    ) -> int:
        """Load lineups data into landing layer.

        Returns number of rows loaded.
        """
        if not lineups:
            return 0

        table = "landing_lineups"

        if self.dry_run:
            console.print(
                f"[dim]DRY RUN: Would load {len(lineups)} lineups for match {match_id}[/dim]"
            )
            return len(lineups)

        loaded_at = self._get_load_timestamp()

        with self.cursor(conn) as cur:
            # Delete existing lineups for this match
            cur.execute(f"DELETE FROM {table} WHERE match_id = %s", (match_id,))

            values = []
            for lineup in lineups:
                lineup_json = json.dumps(lineup, ensure_ascii=False)
                values.append(
                    (
                        match_id,
                        lineup.get("team_id"),
                        lineup_json,
                        loaded_at,
                    )
                )

            cur.executemany(
                f"""
                INSERT INTO {table} (match_id, team_id, raw_data, _loaded_at)
                VALUES (%s, %s, PARSE_JSON(%s), %s)
                """,
                values,
            )

        return len(lineups)

    def load_three_sixty(
        self,
        conn: SnowflakeConnection,
        three_sixty_data: list[dict[str, Any]],
        match_id: int,
        batch_size: int = 1000,
    ) -> int:
        """Load 360 data into landing layer.

        Returns number of rows loaded.
        """
        if not three_sixty_data:
            return 0

        table = "landing_three_sixty"

        if self.dry_run:
            console.print(
                f"[dim]DRY RUN: Would load {len(three_sixty_data)} 360 records "
                f"for match {match_id}[/dim]"
            )
            return len(three_sixty_data)

        loaded_at = self._get_load_timestamp()
        rows_loaded = 0

        with self.cursor(conn) as cur:
            # Delete existing 360 data for this match
            cur.execute(f"DELETE FROM {table} WHERE match_id = %s", (match_id,))

            for i in range(0, len(three_sixty_data), batch_size):
                batch = three_sixty_data[i : i + batch_size]
                values = []
                for record in batch:
                    record_json = json.dumps(record, ensure_ascii=False)
                    values.append(
                        (
                            record.get("event_uuid"),
                            match_id,
                            record_json,
                            loaded_at,
                        )
                    )

                cur.executemany(
                    f"""
                    INSERT INTO {table} (event_uuid, match_id, raw_data, _loaded_at)
                    VALUES (%s, %s, PARSE_JSON(%s), %s)
                    """,
                    values,
                )
                rows_loaded += len(batch)

        return rows_loaded

    def get_loaded_match_ids(self, conn: SnowflakeConnection) -> set[int]:
        """Get set of match IDs already loaded in events table."""
        with self.cursor(conn) as cur:
            cur.execute("SELECT DISTINCT match_id FROM landing_events")
            return {row[0] for row in cur.fetchall()}
