# 作業計画

Claude Codeに順次実行させるためのタスク分解。各タスクは1機能単位で、前のタスクの成果物に依存する。

## 前提ドキュメント

各タスク実行時、Claude Codeには以下のドキュメントをコンテキストとして渡すこと。

- `README.md` — 設計方針、インターフェース、制約
- `Architecture.md` — ディレクトリ構成、実装技術、テスト方針

---

## フェーズ1: 本体リポジトリの基盤

### タスク1: リポジトリ初期化とディレクトリ構成

**ゴール**: Architecture.mdに記載のディレクトリ構成を作成し、開発の土台を整える。

**成果物**:
- リポジトリのディレクトリ構造（`scripts/lib/`, `tests/unit/`, `tests/flow/`, `tests/helpers/`, `e2e/`）
- `.gitignore`
- `README.md`と`Architecture.md`を配置
- bats-coreの導入設定（gitサブモジュールまたはインストールスクリプト）

**完了条件**:
- `bats --version`がテストディレクトリで実行できる状態

---

### タスク2: バリデーション関数の実装とテスト

**ゴール**: `scripts/lib/validate.sh`の全関数を実装し、単体テストで品質を保証する。

**成果物**:
- `scripts/lib/validate.sh`
  - `validate_storage_account()` — アカウント名の形式チェック（3〜24文字、小文字英数字のみ）
  - `validate_action()` — `deploy`または`cleanup`のみ許可
  - `validate_source_dir()` — ディレクトリの存在チェック（`action=deploy`時のみ必須）
  - `validate_target_prefix()` — プレフィックスの形式チェック（空文字不可、使用可能文字の制限）
- `tests/unit/test_validate.bats`

**完了条件**:
- 全テストケースがパスする
- 正常系・異常系の両方がカバーされている

---

### タスク3: プレフィックス・URL関数の実装とテスト

**ゴール**: `scripts/lib/prefix.sh`の全関数を実装し、単体テストで品質を保証する。

**成果物**:
- `scripts/lib/prefix.sh`
  - `build_site_url()` — アカウント名とプレフィックスからアクセスURL生成（末尾`/`を保証）
  - `build_blob_pattern()` — delete-batch用のパターン文字列生成（`<prefix>/*`形式）
- `tests/unit/test_prefix.bats`

**完了条件**:
- 全テストケースがパスする
- 末尾スラッシュの付与が保証されている
- プレフィックスが空の場合のエッジケースが考慮されている

---

### タスク4: Azure CLIラッパーとモックの実装

**ゴール**: az cli呼び出しの副作用層を実装し、テスト用のモックを用意する。

**成果物**:
- `scripts/lib/azure.sh`
  - `azure_delete_prefix()` — `az storage blob delete-batch`のラッパー
  - `azure_upload_dir()` — `az storage blob upload-batch`のラッパー
- `tests/helpers/mock_azure.sh` — 上記関数と同名の関数を定義し、呼び出し引数を一時ファイルに記録する

**完了条件**:
- `azure.sh`の各関数が正しい引数で`az`コマンドを組み立てる
- モック版が呼び出し引数を記録し、後からアサートできる

---

### タスク5: deploy.shの実装とフローテスト

**ゴール**: deployアクションのエントリーポイントを実装し、モックを使ったフローテストで正しい実行順序を保証する。

**依存**: タスク2, 3, 4

**成果物**:
- `scripts/deploy.sh`
  - バリデーション実行
  - `azure_delete_prefix()`で既存ファイル削除
  - `azure_upload_dir()`でアップロード
  - デプロイ先URLを標準出力に出力
- `tests/flow/test_deploy.bats`

**完了条件**:
- モック経由でdelete-batch → upload-batchの順序で呼ばれることが検証されている
- バリデーションエラー時にaz cli関数が呼ばれないことが検証されている
- 正しい引数（ストレージアカウント名、プレフィックス、ソースディレクトリ）が渡されることが検証されている

---

### タスク6: cleanup.shの実装とフローテスト

**ゴール**: cleanupアクションのエントリーポイントを実装し、モックを使ったフローテストで動作を保証する。

**依存**: タスク2, 3, 4

**成果物**:
- `scripts/cleanup.sh`
  - バリデーション実行（`source_dir`は不要）
  - `azure_delete_prefix()`で対象プレフィックス配下を削除
- `tests/flow/test_cleanup.bats`

**完了条件**:
- モック経由でdelete-batchが正しいパターンで呼ばれることが検証されている
- バリデーションエラー時にaz cli関数が呼ばれないことが検証されている

---

### タスク7: action.ymlの実装

**ゴール**: Composite Action定義を作成し、inputs → スクリプト呼び出しの連携を完成させる。

**依存**: タスク5, 6

**成果物**:
- `action.yml`
  - inputs定義（`storage_account`, `source_dir`, `target_prefix`, `action`）
  - `action`の値に応じて`deploy.sh`または`cleanup.sh`を呼び出すcompositeステップ

**完了条件**:
- inputsの定義がREADME.mdのインターフェース仕様と一致している
- 環境変数経由でスクリプトにinputsが渡される

---

### タスク8: 単体テスト・フローテストのCIワークフロー

**ゴール**: PR作成・更新時に自動でテストが実行されるCI環境を構築する。

**依存**: タスク2〜6

**成果物**:
- `.github/workflows/test-unit.yml`
  - `pull_request`トリガー
  - bats-coreのセットアップ
  - 単体テスト（`tests/unit/`）とフローテスト（`tests/flow/`）の実行

**完了条件**:
- ワークフロー定義が構文的に正しい
- テスト結果がPRのChecksに表示される構成になっている

---

## フェーズ2: E2Eテスト用リポジトリ

### タスク9: E2Eリポジトリの初期化

**ゴール**: テスト用リポジトリを作成し、本体リポジトリのactionを使うワークフローを構築する。

**成果物**:
- `azure-blob-storage-site-deploy-e2e/`リポジトリの初期構成
  - `docs/index.html`, `docs/sub/page.html` — テスト用静的サイト
  - `.github/workflows/deploy.yml` — 本actionを使うワークフロー（`push`, `pull_request`トリガー）
  - `.gitignore`
- 本体リポジトリの`e2e/`にサブモジュールとして登録

**完了条件**:
- `deploy.yml`が本体リポジトリのactionを正しく参照している
- `git submodule update --init`でE2Eリポジトリが取得できる

---

### タスク10: E2E検証スクリプトの実装

**ゴール**: デプロイ結果をHTTPアクセスで検証するスクリプトを実装する。

**成果物**:
- `e2e/verify.sh`（E2Eリポジトリ内）
  - 指定URLへのHTTPアクセスとステータスコード検証（200 / 404）
  - レスポンスボディの内容チェック（期待するHTMLが含まれるか）
  - trailing slash付きURLの検証
  - リトライ機構（デプロイ反映待ち）

**完了条件**:
- URLとステータスコードを引数に取り、成功/失敗を返す
- リトライ回数とインターバルが設定可能

---

### タスク11: E2Eオーケストレーターワークフローの実装

**ゴール**: GitHub APIを使ってpush → PR作成 → PR更新 → PRクローズの一連のライフサイクルを自動実行し、各ステップ後に検証するワークフローを実装する。

**依存**: タスク9, 10

**成果物**:
- `.github/workflows/e2e-orchestrator.yml`（E2Eリポジトリ内）
  - `workflow_dispatch`トリガー（手動実行）
  - GitHub APIによるブランチ作成、PR作成、コミットpush、PRクローズの操作
  - 各操作後にdeploy.ymlワークフローの完了をポーリング
  - `verify.sh`による検証の実行
  - テストブランチの後片付け

**完了条件**:
- 手動実行でライフサイクル全体（デプロイ → 更新 → 削除）が一連で検証される
- いずれかのステップで検証失敗した場合、後片付けを行ったうえでワークフローが失敗する

---

## タスク依存関係

```
タスク1（リポジトリ初期化）
  ├── タスク2（validate.sh + テスト）
  ├── タスク3（prefix.sh + テスト）
  └── タスク4（azure.sh + モック）
        ├── タスク5（deploy.sh + フローテスト）
        └── タスク6（cleanup.sh + フローテスト）
              └── タスク7（action.yml）
                    └── タスク8（CIワークフロー）

タスク7 ─── タスク9（E2Eリポジトリ初期化 + サブモジュール登録）
              └── タスク10（verify.sh）
                    └── タスク11（E2Eオーケストレーター）
```

タスク2, 3, 4は相互に依存しないため並行実行可能だが、Claude Codeでの順次実行を前提として直列に記載している。