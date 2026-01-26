# StatsBomb to Snowflake

StatsBomb Open DataをSnowflakeのLanding層にロードするワークフロー

## 概要

このツールは[StatsBomb Open Data](https://github.com/statsbomb/open-data)（GitHub上で公開されているサッカー分析データ）をSnowflakeのLanding層テーブルに取り込むためのCLIツールです。

### データ構造

Landing層では以下のテーブルにデータを格納します：

| テーブル | 説明 |
|---------|------|
| `landing_competitions` | 大会/リーグとシーズン情報 |
| `landing_matches` | 試合情報 |
| `landing_events` | 試合内のイベントデータ（パス、シュート等） |
| `landing_lineups` | 試合のラインナップ（選手構成） |
| `landing_three_sixty` | 360度フリーズフレームデータ |

各テーブルは生のJSONデータを`VARIANT`型で保持し、後続の変換層（Staging/Mart）で必要なカラムを抽出します。

## セットアップ

### 1. インストール

```bash
# リポジトリのクローン
git clone <repository-url>
cd statsbomb-to-bigquery

# 依存関係のインストール
pip install -e .

# 開発用依存関係も含める場合
pip install -e ".[dev]"
```

### 2. 環境変数の設定

`.env.example`をコピーして`.env`を作成し、Snowflakeの接続情報を設定します：

```bash
cp .env.example .env
```

```env
# Snowflake接続設定
SNOWFLAKE_ACCOUNT=your_account.region
SNOWFLAKE_USER=your_username
SNOWFLAKE_PASSWORD=your_password
SNOWFLAKE_WAREHOUSE=COMPUTE_WH
SNOWFLAKE_DATABASE=RAW
SNOWFLAKE_SCHEMA=STATSBOMB
SNOWFLAKE_ROLE=your_role  # オプション
```

### 3. テーブルの作成

```bash
# Landing層のテーブルを作成
statsbomb-load init-tables

# ドライラン（DDLの確認のみ）
statsbomb-load init-tables --dry-run
```

## 使い方

### 全データのロード

```bash
# 全ての大会・シーズンのデータをロード
statsbomb-load load-all

# 特定の大会のみロード（例: La Liga = 11, Premier League = 2）
statsbomb-load load-all --competitions 11,2

# 特定のシーズンのみロード
statsbomb-load load-all --seasons 90,106

# インクリメンタルロード（既存データをスキップ）
statsbomb-load load-all --incremental

# イベントデータをスキップ（高速化）
statsbomb-load load-all --skip-events

# ドライラン
statsbomb-load load-all --dry-run
```

### 個別コマンド

```bash
# 利用可能な大会一覧を表示
statsbomb-load list-competitions

# 大会データのみロード
statsbomb-load load-competitions

# 特定の大会・シーズンの試合をロード
statsbomb-load load-matches 11 90  # La Liga 2020/2021

# 試合の詳細データ（イベント、ラインナップ、360）も含めてロード
statsbomb-load load-matches 11 90 --include-details
```

## ディレクトリ構造

```
.
├── pyproject.toml          # プロジェクト設定
├── .env.example            # 環境変数のテンプレート
├── README.md
├── ddl/
│   └── landing/            # Landing層のDDL定義
│       ├── 01_competitions.sql
│       ├── 02_matches.sql
│       ├── 03_events.sql
│       ├── 04_lineups.sql
│       └── 05_three_sixty.sql
└── src/
    └── statsbomb_snowflake/
        ├── __init__.py
        ├── cli.py          # CLIエントリポイント
        ├── config.py       # 設定管理
        ├── fetcher.py      # StatsBombデータ取得
        └── loader.py       # Snowflakeロード
```

## データ活用例

Landing層にロードしたデータは、Snowflakeのクエリで以下のように活用できます：

```sql
-- 大会情報の取得
SELECT
    competition_id,
    raw_data:competition_name::STRING AS competition_name,
    raw_data:season_name::STRING AS season_name,
    raw_data:country_name::STRING AS country_name
FROM landing_competitions;

-- 試合情報の取得
SELECT
    match_id,
    raw_data:home_team:home_team_name::STRING AS home_team,
    raw_data:away_team:away_team_name::STRING AS away_team,
    raw_data:home_score::INT AS home_score,
    raw_data:away_score::INT AS away_score,
    raw_data:match_date::DATE AS match_date
FROM landing_matches;

-- イベントの集計（例: チームごとのシュート数）
SELECT
    raw_data:team:name::STRING AS team_name,
    COUNT(*) AS shot_count
FROM landing_events
WHERE event_type = 'Shot'
GROUP BY team_name;
```

## ライセンス

StatsBomb Open Dataを使用する場合は、以下の帰属表示が必要です：
- データ出典: StatsBomb
- StatsBombのメディアパックに含まれるロゴを使用

詳細は[StatsBomb Open Data](https://github.com/statsbomb/open-data)のREADMEを参照してください。
