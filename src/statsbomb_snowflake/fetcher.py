"""StatsBomb Open Data fetcher module."""

import json
from collections.abc import Generator
from dataclasses import dataclass
from typing import Any

import requests
from rich.console import Console
from rich.progress import Progress, TaskID

console = Console()


@dataclass
class Competition:
    """Competition metadata."""

    competition_id: int
    season_id: int
    competition_name: str
    season_name: str
    country_name: str


class StatsBombFetcher:
    """Fetcher for StatsBomb Open Data from GitHub."""

    def __init__(
        self,
        base_url: str = "https://raw.githubusercontent.com/statsbomb/open-data/master/data",
        competition_ids: list[int] | None = None,
        season_ids: list[int] | None = None,
    ):
        self.base_url = base_url.rstrip("/")
        self.competition_ids = competition_ids
        self.season_ids = season_ids
        self.session = requests.Session()

    def _get_json(self, path: str) -> Any:
        """Fetch JSON data from StatsBomb open data repository."""
        url = f"{self.base_url}/{path}"
        response = self.session.get(url, timeout=30)
        response.raise_for_status()
        return response.json()

    def fetch_competitions(self) -> list[dict[str, Any]]:
        """Fetch all competitions data."""
        console.print("[blue]Fetching competitions...[/blue]")
        data = self._get_json("competitions.json")
        console.print(f"[green]Found {len(data)} competition/season combinations[/green]")
        return data

    def get_filtered_competitions(self) -> list[Competition]:
        """Get competitions filtered by configured IDs."""
        competitions_data = self.fetch_competitions()
        competitions = []

        for comp in competitions_data:
            comp_id = comp["competition_id"]
            season_id = comp["season_id"]

            # Apply filters if specified
            if self.competition_ids and comp_id not in self.competition_ids:
                continue
            if self.season_ids and season_id not in self.season_ids:
                continue

            competitions.append(
                Competition(
                    competition_id=comp_id,
                    season_id=season_id,
                    competition_name=comp["competition_name"],
                    season_name=comp["season_name"],
                    country_name=comp["country_name"],
                )
            )

        console.print(f"[green]Filtered to {len(competitions)} competition/season pairs[/green]")
        return competitions

    def fetch_matches(self, competition_id: int, season_id: int) -> list[dict[str, Any]]:
        """Fetch matches for a specific competition and season."""
        path = f"matches/{competition_id}/{season_id}.json"
        try:
            return self._get_json(path)
        except requests.HTTPError as e:
            if e.response.status_code == 404:
                console.print(
                    f"[yellow]No matches found for competition {competition_id}, "
                    f"season {season_id}[/yellow]"
                )
                return []
            raise

    def fetch_events(self, match_id: int) -> list[dict[str, Any]]:
        """Fetch events for a specific match."""
        path = f"events/{match_id}.json"
        try:
            return self._get_json(path)
        except requests.HTTPError as e:
            if e.response.status_code == 404:
                return []
            raise

    def fetch_lineups(self, match_id: int) -> list[dict[str, Any]]:
        """Fetch lineups for a specific match."""
        path = f"lineups/{match_id}.json"
        try:
            return self._get_json(path)
        except requests.HTTPError as e:
            if e.response.status_code == 404:
                return []
            raise

    def fetch_three_sixty(self, match_id: int) -> list[dict[str, Any]]:
        """Fetch 360 data for a specific match."""
        path = f"three-sixty/{match_id}.json"
        try:
            return self._get_json(path)
        except requests.HTTPError as e:
            if e.response.status_code == 404:
                return []
            raise

    def fetch_all_matches(
        self, progress: Progress | None = None
    ) -> Generator[tuple[Competition, list[dict[str, Any]]], None, None]:
        """Fetch all matches for filtered competitions."""
        competitions = self.get_filtered_competitions()

        task: TaskID | None = None
        if progress:
            task = progress.add_task("[cyan]Fetching matches...", total=len(competitions))

        for comp in competitions:
            matches = self.fetch_matches(comp.competition_id, comp.season_id)
            if matches:
                yield comp, matches
            if progress and task is not None:
                progress.update(task, advance=1)

    def fetch_match_details(
        self,
        match_ids: list[int],
        include_events: bool = True,
        include_lineups: bool = True,
        include_three_sixty: bool = True,
        progress: Progress | None = None,
    ) -> Generator[dict[str, Any], None, None]:
        """Fetch detailed data for matches (events, lineups, 360).

        Yields dicts with structure:
        {
            "match_id": int,
            "events": list | None,
            "lineups": list | None,
            "three_sixty": list | None,
        }
        """
        task: TaskID | None = None
        if progress:
            task = progress.add_task("[cyan]Fetching match details...", total=len(match_ids))

        for match_id in match_ids:
            result: dict[str, Any] = {"match_id": match_id}

            if include_events:
                result["events"] = self.fetch_events(match_id)

            if include_lineups:
                result["lineups"] = self.fetch_lineups(match_id)

            if include_three_sixty:
                result["three_sixty"] = self.fetch_three_sixty(match_id)

            yield result

            if progress and task is not None:
                progress.update(task, advance=1)


def serialize_json(data: Any) -> str:
    """Serialize data to JSON string for Snowflake VARIANT column."""
    return json.dumps(data, ensure_ascii=False)
