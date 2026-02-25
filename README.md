# azure-blob-storage-site-deploy

> **開発者向け**: セットアップ・テスト実行・開発ワークフローについては [dev リポジトリ](https://github.com/nuitsjp/azure-blob-storage-site-deploy-dev) を参照してください。

リポジトリ内の開発ドキュメント等を Azure Blob Storage の静的 Web サイト機能で公開するための GitHub Actions Composite Action です。

複数リポジトリのサイトを単一ストレージアカウントに集約し、`main`・`develop` 等の複数環境を同時公開します。PR 作成時にステージング環境を自動デプロイし、マージ／クローズ時に自動クリーンナップします。

## 特徴

- **マルチリポジトリ** — `site_name` による名前空間分離で、複数リポジトリのサイトを単一ストレージアカウントに集約
- **マルチ環境** — `main/`、`develop/`、`pr-42/` のようにプレフィックスで環境を分離し同時公開
- **PR ステージング** — PR オープンで自動作成、クローズで自動削除。環境数に制限なし
- **クリーンデプロイ** — 既存ファイルを全削除してからアップロードするため、削除・リネームが確実に反映
- **OIDC 認証** — Azure Entra ID のフェデレーション資格情報による安全な認証（ストレージキー不要）

## 前提条件

- Azure Blob Storageの静的Webサイト機能が有効化済みのストレージアカウント
- GitHub ActionsからAzure OIDC認証で接続できる設定（Azure Entra IDアプリ登録 + フェデレーション資格情報）
- ストレージアカウントに対する「ストレージ Blob データ共同作成者」ロールの割り当て

## 制限事項

SPA（Single Page Application）はマルチ環境構成で非対応です。Azure Blob Storage の静的 Web サイトではエラードキュメントがストレージアカウント全体で 1 つしか設定できず、プレフィックスで複数環境を分離する本アクションの構成ではサイトごとのフォールバックを実現できません。SSG（静的サイトジェネレーター）で生成した HTML であれば問題なくデプロイできます。

## Azure Static Web Apps (SWA) との比較

Private Endpoint を利用できる環境で、ネットワークレベルでアクセスを制限したい場合は本アクション（Blob Storage 方式）が適しています。一方、Private Endpoint が利用できない環境や、Entra ID / GitHub 等による個別ユーザー認証が必要な場合は SWA の利用を推奨します。

SWA は静的サイトホスティングに優れたサービスですが、Private Endpoint によるネットワーク保護とステージング環境の併用では以下の制約があります。

- **ステージング環境数**: Standard プランでも最大 10。本アクションでは無制限
- **ネットワーク保護**: SWA のプレビュー環境は動的に発行されるドメイン（`<random>-<hash>.azurestaticapps.net`）を使用するため、Private Endpoint やカスタム認証ルールの適用が困難。Blob Storage なら Private Endpoint で容易に保護可能
- **認証**: SWA は Entra ID / GitHub 認証を組み込みで提供（招待ユーザー 25 名まで）。Blob Storage + Private Endpoint 方式ではネットワークレベルの保護は容易だが、同一ネットワーク内での個別ユーザー認証は別途構成が必要

### 比較表

| 観点 | Blob Storage + 本アクション | SWA Free | SWA Standard |
|---|---|---|---|
| 永続環境（main, develop 等） | 無制限 | 1 | 1 |
| PR ステージング数 | 無制限 | 最大 3 | 最大 10 |
| Private Endpoint | ○（web + blob 2 つ必要） | × | △ ※1 |
| 個別ユーザー認証（Entra ID / GitHub 等） | △ 別途サービスとの組み合わせで対応可 | ○ 組み込み（招待ユーザー 25 名まで） | △ ※2 |
| SPA（React, Vue 等） | × ※3 | ○ | ○ |
| 月額料金の目安 | 約 ¥2,340 ※4 | 無料 | 約 ¥1,440/アプリ |

> ※1 Standard プランでは本番環境に Private Endpoint を設定可能ですが、プレビュー環境は動的に発行されるドメインを使用するため適用が困難です。
>
> ※2 Standard プランでは招待ベースのロール管理（25 名まで）に加え、サーバーレス関数による無制限のロール割り当てが可能です。ただし関数によるロール管理は本番環境でのみ機能し、プレビュー環境ではドメインが動的に変わるため適用が困難です。
>
> ※3 Azure Blob Storage の静的 Web サイトではエラードキュメントがストレージアカウント全体で 1 つしか設定できず、プレフィックスで複数環境を分離する本アクションの構成ではサイトごとのフォールバックを実現できません。
>
> ※4 Private Endpoint（web + blob 2 つ、約 ¥1,170 × 2）の費用です。利用量に応じてストレージおよび帯域幅のコストが別途発生する場合があります。
>
> 料金は $1 = ¥160 で換算した参考値です。

## 利用方法

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
          branch_name: ${{ github.head_ref || github.ref_name }}
          pull_request_number: ${{ github.event.pull_request.number }}

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
          pull_request_number: ${{ github.event.pull_request.number }}
```

## パラメーター

### インプット

| 名前 | 必須 | 説明 |
|------|------|------|
| `action` | **yes** | `deploy`（デプロイ）または `cleanup`（削除） |
| `storage_account` | **yes** | Azure Storage アカウント名 |
| `source_dir` | deploy 時のみ | アップロード対象ディレクトリ |
| `site_name` | no | サイト識別名。省略時は `GITHUB_REPOSITORY` からリポジトリ名を自動導出。複数リポジトリを同一ストレージアカウントにデプロイする場合に指定 |
| `branch_name` | conditional | ブランチ名。`pull_request_number` 未指定時にプレフィックスとして使用 |
| `pull_request_number` | conditional | PR 番号。指定時は `pr-<番号>` をプレフィックスとして使用（`branch_name` より優先） |
| `static_website_endpoint` | no | 出力 `site_url` のベース URL。省略時は `https://<account>.z22.web.core.windows.net`。カスタムドメインや Azure Front Door 経由の場合に指定 |

> `branch_name` と `pull_request_number` のいずれかは必須です。

### アウトプット

| 名前 | 説明 |
|------|------|
| `site_url` | deploy 成功時の配置先 URL（末尾スラッシュ付き）。例: `https://<account>.z22.web.core.windows.net/my-docs/pr-42/` |

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

## 命名規約

| 環境 | 入力例 | Blobプレフィックス | 説明 |
|------|--------|----------------|------|
| 永続ブランチ | `site_name: api-docs`, `branch_name: main` | `api-docs/main` | site_name + ブランチ名 |
| PRステージング | `site_name: api-docs`, `pull_request_number: 42` | `api-docs/pr-42` | site_name + `pr-<PR番号>` |

## ライセンス

[MIT](LICENSE)
