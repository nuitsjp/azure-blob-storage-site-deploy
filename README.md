# azure-blob-storage-site-deploy

Azure Blob Storageの静的Webサイト機能を使い、単一のストレージアカウントに複数リポジトリの複数環境のサイトをデプロイするGitHub Actions Composite Actionです。

`site_name`による名前空間分離により、複数リポジトリが同一ストレージアカウントに安全にデプロイできます。`site_name`を省略すると、`GITHUB_REPOSITORY`環境変数からリポジトリ名を自動導出します。永続ブランチ（`main`、`develop`等）の常時公開と、PRごとのステージング環境の自動作成・自動削除を提供します。

## 特徴

- **マルチリポジトリ対応** — `site_name`による名前空間分離で、複数リポジトリが同一ストレージアカウントに安全にデプロイ。1つのPrivate Endpointで複数サイトをホスト可能
- **マルチ環境デプロイ** — 各サイト内で `main/`、`develop/`、`pr-42/` のようにプレフィックスで環境を分離
- **PRステージング** — PRのオープンでステージング環境を自動作成し、クローズで自動削除
- **クリーンデプロイ** — 既存ファイルを削除してからアップロードするため、ファイル名変更や削除が確実に反映される
- **OIDC認証** — Azure Entra IDのフェデレーション資格情報による安全な認証（ストレージキー不要）

## 前提条件

- Azure Blob Storageの静的Webサイト機能が有効化済みのストレージアカウント
- GitHub ActionsからAzure OIDC認証で接続できる設定（Azure Entra IDアプリ登録 + フェデレーション資格情報）
- ストレージアカウントに対する「ストレージ Blob データ共同作成者」ロールの割り当て

## 使い方

### 基本：push + PRを1つのワークフローで扱う

`branch_name` と `pull_request_number` を渡すだけで、Action内部でプレフィックスを自動解決します。呼び出し側での分岐ロジックは不要です。

```yaml
name: Deploy

on:
  push:
    branches: [main]
  pull_request:
    types: [opened, synchronize, reopened, closed]

permissions:
  contents: read
  id-token: write

jobs:
  deploy:
    if: github.event.action != 'closed'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - uses: nuitsjp/azure-blob-storage-site-deploy@v1
        id: deploy
        with:
          action: deploy
          storage_account: ${{ vars.AZURE_STORAGE_ACCOUNT }}
          source_dir: ./dist
          site_name: my-docs
          branch_name: ${{ github.head_ref || github.ref_name }}
          pull_request_number: ${{ github.event.pull_request.number }}
          static_website_endpoint: ${{ steps.website.outputs.endpoint }}

      # デプロイ先URL: ${{ steps.deploy.outputs.site_url }}

  cleanup:
    if: github.event_name == 'pull_request' && github.event.action == 'closed'
    runs-on: ubuntu-latest
    steps:
      - uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - uses: nuitsjp/azure-blob-storage-site-deploy@v1
        with:
          action: cleanup
          storage_account: ${{ vars.AZURE_STORAGE_ACCOUNT }}
          site_name: my-docs
          pull_request_number: ${{ github.event.pull_request.number }}
```

pushイベント時: `branch_name`="main", `pull_request_number`="" → プレフィックス = `my-docs/main`
PRイベント時: `branch_name`="feature/foo", `pull_request_number`="42" → プレフィックス = `my-docs/pr-42`

### site_name の省略（自動導出）

`site_name`を省略すると、GitHub Actionsの`GITHUB_REPOSITORY`環境変数（例: `owner/my-app`）からリポジトリ名（`my-app`）を自動導出します。多くの場合、リポジトリ名をそのまま`site_name`として使用するため、明示的な指定は不要です。

```yaml
- uses: nuitsjp/azure-blob-storage-site-deploy@v1
  with:
    action: deploy
    storage_account: ${{ vars.AZURE_STORAGE_ACCOUNT }}
    source_dir: ./dist
    # site_name 省略 → GITHUB_REPOSITORY からリポジトリ名を自動導出
    branch_name: ${{ github.head_ref || github.ref_name }}
    pull_request_number: ${{ github.event.pull_request.number }}
```

### カスタムエンドポイントの指定

`static_website_endpoint` を指定すると、出力される `site_url` のベースURLを制御できます。カスタムドメインやAzure Front Door経由の場合に便利です。

```yaml
- uses: nuitsjp/azure-blob-storage-site-deploy@v1
  id: deploy
  with:
    action: deploy
    storage_account: ${{ vars.AZURE_STORAGE_ACCOUNT }}
    source_dir: ./dist
    site_name: api-docs
    branch_name: main
    static_website_endpoint: https://docs.example.com
```

### マルチリポジトリデプロイ

`site_name`により、複数のリポジトリが同一ストレージアカウントに安全にデプロイできます。各リポジトリで固有の`site_name`を指定することで名前空間が分離されます。

```yaml
# リポジトリA: site_name: api-docs → $web/api-docs/main/
# リポジトリB: site_name: user-guide → $web/user-guide/main/
```

Private Endpointでアクセスを制限している場合、1つのストレージアカウント（＝1つのPrivate Endpoint）で複数サイトをホストできます。

## インプット

| 名前 | 必須 | 説明 |
|------|------|------|
| `action` | **yes** | `deploy`（デプロイ）または `cleanup`（削除） |
| `storage_account` | **yes** | Azure Storageアカウント名 |
| `source_dir` | deploy時のみ | アップロード対象ディレクトリ |
| `site_name` | no | サイト識別名。省略時は`GITHUB_REPOSITORY`からリポジトリ名を自動導出 |
| `branch_name` | conditional | ブランチ名。`pull_request_number` 未指定時にプレフィックスとして使用 |
| `pull_request_number` | conditional | PR番号。指定時は `pr-<番号>` をプレフィックスとして使用 |
| `static_website_endpoint` | no | 静的WebサイトのベースURL。省略時はデフォルトのエンドポイント `https://<account>.z22.web.core.windows.net` を使用 |

> `branch_name` と `pull_request_number` のいずれかは必須です。`pull_request_number` が指定されている場合はそちらが優先されます。

## アウトプット

| 名前 | 説明 |
|------|------|
| `site_url` | deploy成功時の配置先URL（末尾スラッシュ付き）。例: `https://<account>.z22.web.core.windows.net/api-docs/pr-42/` |

## URL構造

デプロイされたサイトは `<endpoint>/<site_name>/<prefix>/` 配下に配置されます。プレフィックスは `branch_name` または `pr-<pull_request_number>` から自動決定されます。

```
https://<account>.z22.web.core.windows.net/
├── api-docs/              ← site_name: api-docs（リポジトリA）
│   ├── main/              ← branch_name: main
│   ├── develop/           ← branch_name: develop
│   └── pr-42/             ← pull_request_number: 42
└── user-guide/            ← site_name: user-guide（リポジトリB）
    ├── main/
    └── pr-10/
```

> **注意**: Azure Blob Storageの静的Webサイトは `/<site_name>/<prefix>` から `/<site_name>/<prefix>/` への自動リダイレクトを行いません。リンクには必ず末尾スラッシュを含めてください。`site_url` 出力には末尾スラッシュが自動的に付与されます。

## `site_name` の命名規則

- 英数字・ハイフン・アンダースコア・ピリオドが使用可能（`^[a-zA-Z0-9]([a-zA-Z0-9._-]*[a-zA-Z0-9])?$`）
- 先頭・末尾は英数字のみ
- 最大100文字
- 省略時は`GITHUB_REPOSITORY`環境変数（`owner/repo-name`形式）からリポジトリ名部分を自動導出

## 命名規約

| 環境 | 入力例 | Blobプレフィックス | 説明 |
|------|--------|----------------|------|
| 永続ブランチ | `site_name: api-docs`, `branch_name: main` | `api-docs/main` | site_name + ブランチ名 |
| PRステージング | `site_name: api-docs`, `pull_request_number: 42` | `api-docs/pr-42` | site_name + `pr-<PR番号>` |

## ライセンス

[MIT](LICENSE)
