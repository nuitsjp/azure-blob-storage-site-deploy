# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Language Rules

- Think in English, interact with the user in Japanese.
- All text, comments, and documentation must be written in Japanese.
- Class names, function names, and other identifiers must be written in English.

## Project Overview

A reusable GitHub Actions Composite Action that deploys multiple documentation sites to a single Azure Blob Storage account using static website functionality. Supports persistent branch deployments (main, develop) and PR-based staging environments with automatic creation/deletion.

Implementation language is bash. No build step exists — this is a shell-based Composite Action.

## Development Commands

### Setup

```bash
./scripts/install-bats.sh    # Install bats-core v1.11.1 to .tools/
git submodule update --init --recursive   # Fetch e2e/ test submodule
```

### Running Tests

```bash
cd tests
PATH="$(pwd)/bin:$PATH" bats unit    # Run unit tests (test_validate, test_prefix, test_azure)
PATH="$(pwd)/bin:$PATH" bats flow    # Run flow tests (test_deploy, test_cleanup)
```

Run a single test file:

```bash
cd tests
PATH="$(pwd)/bin:$PATH" bats unit/test_validate.bats
```

CI runs both unit and flow tests on every PR via `.github/workflows/test-unit.yml`.

## Architecture

### Logic/Side-effects Separation

The core design principle: pure logic is separated from Azure CLI side effects for testability.

- **Logic layer** (`scripts/lib/validate.sh`, `scripts/lib/prefix.sh`): Pure functions with no external dependencies. Input validation, prefix/URL building.
- **Side-effect layer** (`scripts/lib/azure.sh`): Thin wrappers around `az storage blob upload-batch` / `delete-batch`. Mocked in tests via `tests/helpers/mock_azure.sh`.
- **Entry points** (`scripts/deploy.sh`, `scripts/cleanup.sh`): Called from `action.yml`, orchestrate logic + side-effect layers.

### Test Strategy

| Layer | Location | Azure Required | Trigger |
|---|---|---|---|
| Unit tests | `tests/unit/` | No | PR (CI) |
| Flow tests | `tests/flow/` (mock azure) | No | PR (CI) |
| E2E tests | `e2e/` submodule (separate repo) | Yes | Manual / pre-release |

The mock (`tests/helpers/mock_azure.sh`) replaces the `az` function and records call arguments in a log file for assertion.

### E2E Submodule

`e2e/` is a git submodule pointing to `nuitsjp/azure-blob-storage-site-deploy-e2e`. It contains a separate repo that calls this action as an external consumer. E2E tests are kept separate so test PR operations don't interfere with action development. Submodule pointer updates should be noted explicitly in commits.

## Branch and Commit Workflow

- Do not modify files directly on the main branch. Create a feature branch first.
- Conventional Commit style: `feat: ...`, `docs: ...`, `chore: ...`. Japanese commit messages are acceptable.
- PR descriptions must include: purpose, changed files/scope, verification commands **with results** (e.g., `34件 pass`), and impact scope.
- Child issues are closed after PR merge, not during review.

## Key Design Decisions

- **PR number (not branch name) for staging prefix**: Branch names can contain Japanese characters, slashes, etc. PR numbers are guaranteed integers.
- **Deploy strategy**: `delete-batch` old files first, then `upload-batch` new ones (ensures renamed/deleted files don't persist).
- **URL trailing slash**: Azure Blob Storage doesn't auto-redirect `/pr-42` → `/pr-42/`. URLs must always include a trailing slash.
- **Composite Action over Reusable Workflow**: Runs as steps within caller's job (no separate job overhead), better testability.
