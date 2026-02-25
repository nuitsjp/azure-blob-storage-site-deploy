# azure-blob-storage-site-deploy

[開発者向け](https://github.com/nuitsjp/azure-blob-storage-site-deploy-dev)

GitHub Actionsで、Azure Blob Storageの静的Webサイト機能にコンテンツを公開するためのComposite Actionです。

複数リポジトリのサイトを単一ストレージアカウントに集約し、`main`・`develop` 等の複数環境を同時公開します。PR作成時にステージング環境を自動デプロイし、マージ／クローズ時に自動クリーンナップします。

プロダクションサイトではなく、開発文書などを公開する用途にフォーカスしています。SPA（Single Page Application）には非対応で、静的サイトジェネレーターで生成したHTMLの公開に適しています。

## 特徴

- **PRステージング** — PRオープンで自動作成、クローズで自動削除。環境数に制限なし
- **クリーンデプロイ** — 既存ファイルを全削除してからアップロードするため、削除・リネームが確実に反映
- **マルチ環境** — `main/`、`develop/`、`pr-42/` のようにプレフィックスで環境を分離し同時公開
- **マルチリポジトリ** — `site_name` による名前空間分離で、複数リポジトリのサイトを単一ストレージアカウントに集約
- **OIDC認証** — Azure Entra IDのフェデレーション資格情報による安全な認証（ストレージキー不要）

## 前提条件

- Azure Blob Storageの静的Webサイト機能が有効化済みのストレージアカウント
- GitHub ActionsからAzure OIDC認証で接続できる設定（Azure Entra IDアプリ登録 + フェデレーション資格情報）
- ストレージアカウントに対する「Storage Blob Data Contributor」ロールの割り当て

## 制限事項

SPA（Single Page Application）はマルチ環境構成で非対応です。

Azure Blob Storageの静的Webサイトではエラードキュメントがストレージアカウント全体で1つしか設定できず、プレフィックスで複数環境を分離する本アクションの構成ではサイトごとのフォールバックを実現できません。SSG（静的サイトジェネレーター）で生成したHTMLであれば問題なくデプロイできます。

SPAをホスティングする場合は、Azure Static Web Appsの利用を推奨します。

## 利用方法

`branch_name` と `pull_request_number` を渡すだけで、Action内部でプレフィックスを自動解決します。呼び出し側での分岐ロジックは不要です。

```yaml
name: Deploy

on:
  push:
    branches: [main]
    paths:
      - "docs/**/*.md"
      - ".github/workflows/deploy.yml"
  pull_request:
    types: [opened, synchronize, reopened, closed]
    paths:
      - "docs/**/*.md"
      - ".github/workflows/deploy.yml"

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

      - name: Workflow Summary にデプロイ先URLを出力
        if: success() && steps.deploy.outputs.site_url != ''
        run: |
          site_url="${{ steps.deploy.outputs.site_url }}"
          {
            echo "## デプロイ先URL"
            echo "- URL: [${site_url}](${site_url})"
          } >> "$GITHUB_STEP_SUMMARY"

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
| `storage_account` | **yes** | Azure Storageアカウント名 |
| `source_dir` | deploy時のみ | アップロード対象ディレクトリ |
| `site_name` | no | サイト識別名。省略時は `GITHUB_REPOSITORY` からリポジトリ名を自動導出。複数リポジトリを同一ストレージアカウントにデプロイする場合に指定 |
| `branch_name` | conditional | ブランチ名。`pull_request_number` 未指定時にプレフィックスとして使用 |
| `pull_request_number` | conditional | PR番号。指定時は `pr-<番号>` をプレフィックスとして使用（`branch_name` より優先） |

> `branch_name` と `pull_request_number` のいずれかは必須でが、使用法に記述したように双方を指定しておくことでブランチとPRの両方に対応可能です。

### アウトプット

| 名前 | 説明 |
|------|------|
| `site_url` | deploy成功時の配置先URL（末尾スラッシュ付き）。例: `https://<account>.<zone>.web.core.windows.net/my-docs/pr-42/` |

## URL構造

デプロイされたサイトは `<endpoint>/<site_name>/<prefix>/` 配下に配置されます。プレフィックスは `branch_name` または `pr-<pull_request_number>` から自動決定されます。

```
https://<account>.<zone>.web.core.windows.net/
├── api-docs/              ← site_name: api-docs（リポジトリA）
│   ├── main/              ← branch_name: main
│   ├── develop/           ← branch_name: develop
│   └── pr-42/             ← pull_request_number: 42
└── user-guide/            ← site_name: user-guide（リポジトリB）
    ├── main/
    └── pr-10/
```

### 注意

Azure Blob Storageの静的Webサイトは `/<site_name>/<prefix>` から `/<site_name>/<prefix>/` への自動リダイレクトを行いません。リンクには必ず末尾スラッシュを含めてください。`site_url` 出力には末尾スラッシュが自動的に付与されます。

## Azure Static Web Apps (SWA) との比較

Private Endpointを利用できる環境で、ネットワークレベルでアクセスを制限したい場合は本アクション（Blob Storage方式）が適しています。

一方、Entra ID / GitHub等による個別ユーザー認証が必要な場合はSWAの利用を推奨します。

それぞれには下記のような特徴があります。

| 観点 | Blob Storage + 本アクション | SWA Free | SWA Standard |
|---|---|---|---|
| リポジトリ | 無制限 | 1 | 1 |
| 永続環境（main, develop等） | 無制限 | 1 | 1 |
| PRステージング数 | 無制限 | 最大3 | 最大10 |
| Private Endpoint | ○（web + blob 2つ必要） | × | ○ ※1 |
| 個別ユーザー認証（Entra ID / GitHub等） | △ 別途サービスとの組み合わせで対応可 | ○ （最大25ユーザー） | ○ ※2 |
| SPA（React, Vue等） | × ※3 | ○ | ○ |
| 月額料金の目安 | 約 ¥2,340 ※4 | 無料 | 約 ¥1,440 / 約 ¥2,610 ※5 |

料金は $1 = ¥160で換算した参考値です。

※1 Private Endpointは本番環境に設定可能です。プレビュー環境は動的に発行されるドメインを使用するため、適用には注意が必要です。

※2 Standardプランでは招待ベースのロール管理（25名まで）に加え、サーバーレス関数による無制限のロール割り当てが可能です。ただしカスタム認証はプレビュー環境ではドメインが動的に変わるため、適用には注意が必要です。

※3 Azure Blob Storageの静的Webサイトではエラードキュメントがストレージアカウント全体で1つしか設定できず、プレフィックスで複数環境を分離する本アクションの構成ではサイトごとのフォールバックを実現できません。

※4 Private Endpoint（web + blob 2つ、約 ¥1,170 × 2）の費用です。利用量に応じてストレージおよび帯域幅のコストが別途発生する場合があります。

※5約 ¥1,440はStandardプラン単体の料金です。Private Endpoint利用時は約 ¥1,170が加算されます。

SWAを利用するときに、個別ユーザー認証を行いたい場合、下記のActionsを利用することでGitHubユーザーをSWAの招待ユーザーとして自動追加することが可能です。

- [ssd-mkdocs-platform/swa-github-role-sync](https://github.com/ssd-mkdocs-platform/swa-github-role-sync)

## ライセンス

[MIT](LICENSE)
