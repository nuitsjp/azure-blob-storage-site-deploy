# Repository Guidelines

## Primary Directive

- Think in English, interact with the user in Japanese.
- All text, comments, and documentation must be written in Japanese.
- Class names, function names, and other identifiers must be written in English.
- Can execute GitHub CLI/Azure CLI. Will execute and verify them personally
  whenever possible.
- Do not modify files directly on the main branch.
- Create a branch with an appropriate name and switch to it before making any modifications.

## Project Structure & Module Organization
This repository is currently design-first and documentation-heavy.

- `README.md`: project overview, scope, and deployment concept (Japanese).
- `docs/Architecture.md`: implementation plan for the Composite Action, script layout, and test strategy.
- `docs/`: supporting documentation (currently minimal/empty).
- E2Eテスト用リポジトリは外部管理（推奨: `azure-blob-storage-site-deploy-dev` の `repos/e2e`）。

Planned runtime files (`action.yml`, `scripts/`, `tests/`, `.github/workflows/`) are described in `docs/Architecture.md` but may not exist yet.

## Build, Test, and Development Commands
There is no root build/test pipeline implemented yet. Use these commands during setup and review:

- `git status` - verify only intended files changed.
- `git log --oneline -n 10` - review recent commit conventions before committing.
- `git -C ..\\azure-blob-storage-site-deploy-dev submodule status --recursive` - 開発用メタリポジトリで `product` / `e2e` の状態を確認（任意）

When implementation starts, follow `docs/Architecture.md` for Bash script and Bats test commands.

## Coding Style & Naming Conventions
- Documentation: keep Markdown concise, task-focused, and consistent with existing headings.
- Language: Japanese is used in core docs; keep terminology consistent (`deploy`, `cleanup`, `target_prefix`).
- Planned scripts (per `docs/Architecture.md`): Bash with small functions, side effects isolated in wrappers (for example `scripts/lib/azure.sh`).
- Naming: lowercase file names; tests as `test_*.bats`; PR staging prefixes as `pr-<number>`.

## Testing Guidelines
- Current state: no automated tests in the root repository.
- If adding implementation code, add tests alongside it using the planned Bats structure in `tests/`.
- Prefer unit tests for pure functions first, then flow tests with mocks, and keep Azure-dependent checks in the external E2E repository (for example `azure-blob-storage-site-deploy-dev/repos/e2e`).
- PR作成前に、変更範囲に応じたテスト/検証コマンドを必ず実行する。
- PR本文には、実行した検証コマンドだけでなく結果（例: `2件 pass`, `34件 pass`）も記載する。

## Commit & Pull Request Guidelines
- Follow the existing Conventional Commit style seen in history: `feat: ...`, `docs: ...`.
- Japanese commit messages are acceptable and already used; prioritize clarity and scope.
- PRs should include: purpose, changed files/areas, validation performed (commands run), and any architecture impact.
- Link related issues/tasks when applicable, and note cross-repo impacts explicitly when the external E2E repository changes.
- 子IssueはPR作成・レビュー中の段階ではCloseしない。原則としてPRマージ後にCloseし、親Issueのチェックリストも同時に更新する。
- PR本文には目的、変更ファイル/変更範囲、実施した検証（コマンドと結果）、影響範囲を含める。
