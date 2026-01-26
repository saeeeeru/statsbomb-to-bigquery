"""CLI for StatsBomb to Snowflake landing layer loader."""

from typing import Annotated, Optional

import typer
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TaskProgressColumn
from rich.table import Table

from .config import get_settings, Settings
from .fetcher import StatsBombFetcher
from .loader import SnowflakeLoader

app = typer.Typer(
    name="statsbomb-load",
    help="Load StatsBomb Open Data into Snowflake landing layer",
)
console = Console()


def create_progress() -> Progress:
    """Create a rich progress bar."""
    return Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        BarColumn(),
        TaskProgressColumn(),
        console=console,
    )


@app.command()
def init_tables(
    dry_run: Annotated[
        bool, typer.Option("--dry-run", help="Print DDL statements without executing")
    ] = False,
) -> None:
    """Initialize landing layer tables in Snowflake."""
    console.print("[bold blue]Initializing Snowflake landing layer tables[/bold blue]")

    settings = get_settings()
    loader = SnowflakeLoader(settings.snowflake, dry_run=dry_run)

    with loader.connection() as conn:
        loader.execute_ddl(conn)

    console.print("[bold green]Done![/bold green]")


@app.command()
def load_all(
    dry_run: Annotated[
        bool, typer.Option("--dry-run", help="Fetch data but don't load to Snowflake")
    ] = False,
    skip_events: Annotated[
        bool, typer.Option("--skip-events", help="Skip loading events data")
    ] = False,
    skip_lineups: Annotated[
        bool, typer.Option("--skip-lineups", help="Skip loading lineups data")
    ] = False,
    skip_three_sixty: Annotated[
        bool, typer.Option("--skip-three-sixty", help="Skip loading 360 data")
    ] = False,
    competition_ids: Annotated[
        Optional[str],
        typer.Option("--competitions", help="Comma-separated competition IDs to load"),
    ] = None,
    season_ids: Annotated[
        Optional[str],
        typer.Option("--seasons", help="Comma-separated season IDs to load"),
    ] = None,
    incremental: Annotated[
        bool,
        typer.Option("--incremental", help="Skip matches already loaded (based on events table)"),
    ] = False,
) -> None:
    """Load all StatsBomb data into Snowflake landing layer."""
    console.print("[bold blue]Loading StatsBomb data to Snowflake landing layer[/bold blue]")

    settings = get_settings()

    # Parse competition/season filters
    comp_filter = [int(x) for x in competition_ids.split(",")] if competition_ids else None
    season_filter = [int(x) for x in season_ids.split(",")] if season_ids else None

    # Initialize fetcher
    fetcher = StatsBombFetcher(
        base_url=settings.statsbomb.base_url,
        competition_ids=comp_filter or settings.statsbomb.competition_ids,
        season_ids=season_filter or settings.statsbomb.season_ids,
    )

    # Initialize loader
    loader = SnowflakeLoader(settings.snowflake, dry_run=dry_run)

    # Stats tracking
    stats = {
        "competitions": 0,
        "matches": 0,
        "events": 0,
        "lineups": 0,
        "three_sixty": 0,
    }

    with loader.connection() as conn:
        # Load competitions
        competitions_data = fetcher.fetch_competitions()
        stats["competitions"] = loader.load_competitions(
            conn, competitions_data, settings.batch_size
        )

        # Get existing match IDs for incremental load
        existing_match_ids: set[int] = set()
        if incremental:
            console.print("[blue]Checking for existing matches...[/blue]")
            existing_match_ids = loader.get_loaded_match_ids(conn)
            console.print(f"[green]Found {len(existing_match_ids)} existing matches[/green]")

        # Collect all matches first
        all_matches: list[tuple[int, dict]] = []  # (match_id, match_data)
        match_to_comp: dict[int, tuple[int, int]] = {}  # match_id -> (comp_id, season_id)

        with create_progress() as progress:
            for comp, matches in fetcher.fetch_all_matches(progress):
                stats["matches"] += loader.load_matches(
                    conn, matches, comp.competition_id, comp.season_id, settings.batch_size
                )

                for match in matches:
                    match_id = match["match_id"]
                    if incremental and match_id in existing_match_ids:
                        continue
                    all_matches.append((match_id, match))
                    match_to_comp[match_id] = (comp.competition_id, comp.season_id)

        # Load match details (events, lineups, 360)
        if all_matches:
            console.print(f"\n[blue]Loading details for {len(all_matches)} matches...[/blue]")

            match_ids = [m[0] for m in all_matches]

            with create_progress() as progress:
                for details in fetcher.fetch_match_details(
                    match_ids,
                    include_events=not skip_events,
                    include_lineups=not skip_lineups,
                    include_three_sixty=not skip_three_sixty,
                    progress=progress,
                ):
                    match_id = details["match_id"]

                    if not skip_events and details.get("events"):
                        stats["events"] += loader.load_events(
                            conn, details["events"], match_id, settings.batch_size
                        )

                    if not skip_lineups and details.get("lineups"):
                        stats["lineups"] += loader.load_lineups(
                            conn, details["lineups"], match_id
                        )

                    if not skip_three_sixty and details.get("three_sixty"):
                        stats["three_sixty"] += loader.load_three_sixty(
                            conn, details["three_sixty"], match_id, settings.batch_size
                        )

    # Print summary
    console.print("\n[bold green]Load complete![/bold green]")
    _print_stats(stats)


@app.command()
def load_competitions(
    dry_run: Annotated[
        bool, typer.Option("--dry-run", help="Fetch data but don't load to Snowflake")
    ] = False,
) -> None:
    """Load only competitions data."""
    console.print("[bold blue]Loading competitions data[/bold blue]")

    settings = get_settings()
    fetcher = StatsBombFetcher(base_url=settings.statsbomb.base_url)
    loader = SnowflakeLoader(settings.snowflake, dry_run=dry_run)

    with loader.connection() as conn:
        competitions_data = fetcher.fetch_competitions()
        count = loader.load_competitions(conn, competitions_data, settings.batch_size)

    console.print(f"[bold green]Loaded {count} competitions[/bold green]")


@app.command()
def load_matches(
    competition_id: Annotated[int, typer.Argument(help="Competition ID")],
    season_id: Annotated[int, typer.Argument(help="Season ID")],
    dry_run: Annotated[
        bool, typer.Option("--dry-run", help="Fetch data but don't load to Snowflake")
    ] = False,
    include_details: Annotated[
        bool, typer.Option("--include-details", help="Also load events, lineups, and 360 data")
    ] = False,
) -> None:
    """Load matches for a specific competition and season."""
    console.print(
        f"[bold blue]Loading matches for competition {competition_id}, "
        f"season {season_id}[/bold blue]"
    )

    settings = get_settings()
    fetcher = StatsBombFetcher(base_url=settings.statsbomb.base_url)
    loader = SnowflakeLoader(settings.snowflake, dry_run=dry_run)

    with loader.connection() as conn:
        matches = fetcher.fetch_matches(competition_id, season_id)
        count = loader.load_matches(
            conn, matches, competition_id, season_id, settings.batch_size
        )

        if include_details and matches:
            match_ids = [m["match_id"] for m in matches]
            console.print(f"\n[blue]Loading details for {len(match_ids)} matches...[/blue]")

            events_count = 0
            lineups_count = 0
            three_sixty_count = 0

            with create_progress() as progress:
                for details in fetcher.fetch_match_details(match_ids, progress=progress):
                    match_id = details["match_id"]

                    if details.get("events"):
                        events_count += loader.load_events(
                            conn, details["events"], match_id, settings.batch_size
                        )

                    if details.get("lineups"):
                        lineups_count += loader.load_lineups(conn, details["lineups"], match_id)

                    if details.get("three_sixty"):
                        three_sixty_count += loader.load_three_sixty(
                            conn, details["three_sixty"], match_id, settings.batch_size
                        )

            console.print(f"[green]Loaded {events_count} events[/green]")
            console.print(f"[green]Loaded {lineups_count} lineups[/green]")
            console.print(f"[green]Loaded {three_sixty_count} 360 records[/green]")

    console.print(f"[bold green]Loaded {count} matches[/bold green]")


@app.command()
def list_competitions() -> None:
    """List available competitions from StatsBomb Open Data."""
    settings = get_settings()
    fetcher = StatsBombFetcher(base_url=settings.statsbomb.base_url)

    competitions = fetcher.fetch_competitions()

    # Group by competition
    by_competition: dict[int, list] = {}
    for comp in competitions:
        comp_id = comp["competition_id"]
        if comp_id not in by_competition:
            by_competition[comp_id] = []
        by_competition[comp_id].append(comp)

    table = Table(title="StatsBomb Open Data Competitions")
    table.add_column("Competition ID", justify="right", style="cyan")
    table.add_column("Competition Name", style="green")
    table.add_column("Country", style="yellow")
    table.add_column("Seasons", style="magenta")

    for comp_id in sorted(by_competition.keys()):
        comps = by_competition[comp_id]
        first = comps[0]
        seasons = ", ".join(
            f"{c['season_name']} ({c['season_id']})" for c in sorted(comps, key=lambda x: x["season_id"])
        )
        table.add_row(
            str(comp_id),
            first["competition_name"],
            first["country_name"],
            seasons,
        )

    console.print(table)


def _print_stats(stats: dict[str, int]) -> None:
    """Print loading statistics."""
    table = Table(title="Load Statistics")
    table.add_column("Data Type", style="cyan")
    table.add_column("Rows Loaded", justify="right", style="green")

    for data_type, count in stats.items():
        table.add_row(data_type.replace("_", " ").title(), str(count))

    console.print(table)


if __name__ == "__main__":
    app()
