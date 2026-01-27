# Snowflake Infrastructure (Terraform)

StatsBomb Snowflake インフラストラクチャを Terraform で管理します。

## ディレクトリ構造

```
terraform/
├── modules/                    # 再利用可能なモジュール
│   ├── database/              # Database & Schema
│   ├── warehouse/             # Warehouse
│   ├── roles/                 # Roles & Grants
│   └── landing_tables/        # Landing層テーブル
└── environments/              # 環境別設定
    ├── dev/                   # 開発環境
    └── prod/                  # 本番環境
```

## モジュール概要

| モジュール | 説明 |
|-----------|------|
| `database` | Database と Schema を作成 |
| `warehouse` | Virtual Warehouse を作成 |
| `roles` | Role（LOADER, READER, ADMIN）と権限を設定 |
| `landing_tables` | Landing層の5テーブルを作成 |

## 作成されるリソース

### Roles

| Role | 用途 | 権限 |
|------|------|------|
| `{PREFIX}_LOADER` | ETL/ELTプロセス | Database/Schema USAGE, テーブルへの全DML |
| `{PREFIX}_READER` | 分析・BI | Database/Schema USAGE, テーブルへのSELECT |
| `{PREFIX}_ADMIN` | 管理者 | 全リソースへのALL PRIVILEGES |

### Tables

| テーブル | 説明 |
|----------|------|
| `LANDING_COMPETITIONS` | 大会・シーズン情報 |
| `LANDING_MATCHES` | 試合情報 |
| `LANDING_EVENTS` | イベントデータ |
| `LANDING_LINEUPS` | ラインナップ |
| `LANDING_THREE_SIXTY` | 360度データ |

## セットアップ

### 前提条件

- Terraform >= 1.0.0
- Snowflake アカウント
- SYSADMIN または ACCOUNTADMIN ロールを持つユーザー

### 1. 環境変数ファイルの作成

```bash
# 開発環境
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars を編集して接続情報を設定
```

### 2. Terraform の初期化

```bash
cd terraform/environments/dev
terraform init
```

### 3. プランの確認

```bash
terraform plan
```

### 4. 適用

```bash
terraform apply
```

## 環境別の差分

| 設定 | dev | prod |
|------|-----|------|
| Database名 | RAW_DEV | RAW |
| Time Travel | 1日 | 7日 |
| Warehouse Size | X-Small | Small |
| Auto Suspend | 60秒 | 300秒 |
| Multi-cluster | 無効 | 有効 (1-2) |

## 認証方法

### パスワード認証（基本）

```hcl
provider "snowflake" {
  account  = "your_account.region"
  user     = "terraform_user"
  password = "your_password"
  role     = "SYSADMIN"
}
```

### キーペア認証（推奨）

```hcl
provider "snowflake" {
  account         = "your_account.region"
  user            = "terraform_user"
  private_key_path = "~/.ssh/snowflake_key.p8"
  role            = "SYSADMIN"
}
```

キーペアの生成:

```bash
# 秘密鍵の生成
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out snowflake_key.p8 -nocrypt

# 公開鍵の生成
openssl rsa -in snowflake_key.p8 -pubout -out snowflake_key.pub

# Snowflakeでユーザーに公開鍵を設定
# ALTER USER terraform_user SET RSA_PUBLIC_KEY='MIIBIjANBg...';
```

## リモート State 管理

本番環境では S3 + DynamoDB でリモート State を管理することを推奨:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "statsbomb/prod/terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

## CI/CD Integration

GitHub Actions での実行例:

```yaml
name: Terraform

on:
  push:
    branches: [main]
    paths: ['terraform/**']
  pull_request:
    paths: ['terraform/**']

jobs:
  terraform:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: terraform/environments/prod

    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.0

      - name: Terraform Init
        run: terraform init
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

      - name: Terraform Plan
        run: terraform plan -no-color
        env:
          TF_VAR_snowflake_account: ${{ secrets.SNOWFLAKE_ACCOUNT }}
          TF_VAR_snowflake_user: ${{ secrets.SNOWFLAKE_USER }}
          TF_VAR_snowflake_password: ${{ secrets.SNOWFLAKE_PASSWORD }}

      - name: Terraform Apply
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: terraform apply -auto-approve
        env:
          TF_VAR_snowflake_account: ${{ secrets.SNOWFLAKE_ACCOUNT }}
          TF_VAR_snowflake_user: ${{ secrets.SNOWFLAKE_USER }}
          TF_VAR_snowflake_password: ${{ secrets.SNOWFLAKE_PASSWORD }}
```

## トラブルシューティング

### エラー: "Insufficient privileges"

Terraform 実行ユーザーに適切な権限が付与されているか確認:

```sql
GRANT CREATE DATABASE ON ACCOUNT TO ROLE SYSADMIN;
GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE SYSADMIN;
```

### エラー: "Object already exists"

既存リソースを import するか、削除してから再実行:

```bash
# Import example
terraform import module.database.snowflake_database.this RAW_DEV
```
