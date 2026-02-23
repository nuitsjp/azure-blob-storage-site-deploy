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
- `Architecture.md`: implementation plan for the Composite Action, script layout, and test strategy.
- `docs/`: supporting documentation (currently minimal/empty).
- `e2e/`: git submodule for the external end-to-end test repository.
- `.gitmodules`: submodule source configuration.

Planned runtime files (`action.yml`, `scripts/`, `tests/`, `.github/workflows/`) are described in `Architecture.md` but may not exist yet.

## Build, Test, and Development Commands
There is no root build/test pipeline implemented yet. Use these commands during setup and review:

- `git submodule update --init --recursive` - fetch the `e2e/` test submodule.
- `git status` - verify only intended files changed.
- `git log --oneline -n 10` - review recent commit conventions before committing.

When implementation starts, follow `Architecture.md` for Bash script and Bats test commands.

## Coding Style & Naming Conventions
- Documentation: keep Markdown concise, task-focused, and consistent with existing headings.
- Language: Japanese is used in core docs; keep terminology consistent (`deploy`, `cleanup`, `target_prefix`).
- Planned scripts (per `Architecture.md`): Bash with small functions, side effects isolated in wrappers (for example `scripts/lib/azure.sh`).
- Naming: lowercase file names; tests as `test_*.bats`; PR staging prefixes as `pr-<number>`.

## Testing Guidelines
- Current state: no automated tests in the root repository.
- If adding implementation code, add tests alongside it using the planned Bats structure in `tests/`.
- Prefer unit tests for pure functions first, then flow tests with mocks, and keep Azure-dependent checks in the `e2e/` submodule.

## Commit & Pull Request Guidelines
- Follow the existing Conventional Commit style seen in history: `feat: ...`, `docs: ...`.
- Japanese commit messages are acceptable and already used; prioritize clarity and scope.
- 子IssueはPR作成・レビュー中の段階ではCloseしない。原則としてPRマージ後にCloseし、親Issueのチェックリストも同時に更新する。
- PRs should include: purpose, changed files/areas, validation performed (commands run), and any architecture impact.
- Link related issues/tasks when applicable, and note submodule updates explicitly if `e2e/` changes.
