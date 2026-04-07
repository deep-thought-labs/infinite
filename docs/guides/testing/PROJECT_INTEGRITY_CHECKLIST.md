# Project integrity checklist

**Single entry point** for commands and checks to validate the repository end-to-end before a merge, after a large change, or before a release.

For **each script** (usage and behavior), see [development/SCRIPTS.md](../development/SCRIPTS.md#validation-and-verification-scripts). For **validation workflows** (grouping scripts), see [VALIDATION.md](VALIDATION.md). For **`make test-*`**, see [development/TESTING.md](../development/TESTING.md). This file only orders steps and states scope.

## From a clean clone to a pull request

Use this path on a **new machine** or **right after cloning** so nothing is skipped from “empty directory” to “ready to open a PR”.

| Step | What to do |
|------|------------|
| 1. Clone | `git clone <repo-url>` and `cd` into the project root. |
| 2. Install toolchain | Install **Go** (match `go` in root `go.mod`), **Make**, **Git**, **Docker** (used for several builds and release dry-runs), **jq** (scripts). For `make lint` you also need what each linter expects (e.g. **Node/npx** for Markdown, Python tooling if you run those linters). **Single place for versions, PATH (`$HOME/go/bin`), and workflow detail:** [development/BUILDING.md](../development/BUILDING.md) (Workflow 1 — Development Build). |
| 3. Verify prerequisites | Run `./scripts/check_build_prerequisites.sh` and fix every reported problem **before** compiling. On a clean system this step is **mandatory**, not optional. |
| 4. PR gate (no node required) | Run **Phases 1–4** below in order: `make lint` → `make install` → `make test-all` → `./scripts/validate_customizations.sh`. That matches what you want green before pushing a branch for review. |
| 5. Optional | **Phase 5** only if your change needs a **running node**. **Phase 6** is for release prep, not a normal PR. |
| 6. Push | Commit, push your branch, open the PR. |

Shorter onboarding without repeating commands: [QUICK_START.md](../QUICK_START.md).

## When to run this

| Moment | Minimum phases |
|--------|----------------|
| Daily / after edits | Phases 1–3 |
| Before opening a PR | Phases 1–4 |
| Before tagging / release | Phases 1–6 (add 5 only if you have a running node) |

## Phase 0 — Prerequisites

Verify the toolchain **before** Phase 2. **Always** run on a new clone or new machine; skip only if you already verified the same environment recently.

```bash
./scripts/check_build_prerequisites.sh
```

If anything fails, use [development/BUILDING.md](../development/BUILDING.md) and [development/SCRIPTS.md](../development/SCRIPTS.md#1-check_build_prerequisitessh) to fix it.

## Phase 1 — Static analysis and formatting policy

Aligns locally with what `make lint` covers in CI (Go, Python, contracts, Markdown):

```bash
make lint
```

Optional dependency audit:

```bash
make vulncheck
```

## Phase 2 — Build

Ensure the binary builds cleanly:

```bash
make install
```

(or `make build` if you only need `build/` artifacts — see [development/BUILDING.md](../development/BUILDING.md).)

## Phase 3 — Automated tests (Go and repo tests)

Full Go test sweep (root module + `infinited/`):

```bash
make test-all
```

Other targets you may add for stricter checks:

| Command | Use when |
|---------|----------|
| `make test-unit` | Faster subset (unit packages, no full `test-all` sweep) |
| `make test-unit-cover` | Full merged coverage (`coverage.txt`); or run a single block: `make test-unit-cover-evm-core`, `…-evm-integration`, `…-infinited-core`, `…-infinited-integration` (matches CI matrix) |
| `make test-infinited` | Focus on the `infinited` module only |
| `make test-scripts` | Python tests under `scripts/` (requires pytest) |
| `make test-solidity` | Solidity harness (see script output if deps missing) |

Details: [development/TESTING.md](../development/TESTING.md).

## Phase 4 — Fork identity and customization checks

Validates Infinite Drive–specific expectations in the tree (no running node required):

```bash
./scripts/validate_customizations.sh
```

Optional: compare tree vs upstream (see [VALIDATION.md](VALIDATION.md#auxiliary-compare-tree-to-upstream)):

```bash
./scripts/list_all_customizations.sh main
```

## Phase 5 — Runtime / node checks (optional)

Only if a node is already running (see [README.md](../../README.md) *Run a Node*: **Drive**, **pre-built binary** from [latest release](https://github.com/deep-thought-labs/infinite/releases/latest), or **build from source**):

```bash
./scripts/infinite_health_check.sh
./scripts/validate_token_config.sh
```

See [VALIDATION.md](VALIDATION.md#troubleshooting) and [SCRIPTS.md §5](../development/SCRIPTS.md#5-infinite_health_checksh).

## Phase 6 — Pre-release (optional)

Before creating a GitHub release, a dry run is useful:

```bash
make release-dry-run-linux
```

Official process: [infrastructure/RELEASES.md](../infrastructure/RELEASES.md).

## One-shot “heavy” local pass (reference)

Same sequence as **Pre-release validation** in [VALIDATION.md](VALIDATION.md#pre-release-validation), plus `make lint` at the start:

```bash
make lint
make install
./scripts/validate_customizations.sh
make test-all
make release-dry-run-linux   # optional
# If a node is up:
./scripts/infinite_health_check.sh
./scripts/validate_token_config.sh
```

## See also

| Document | Role |
|----------|------|
| [development/SCRIPTS.md](../development/SCRIPTS.md) | Per-script reference |
| [VALIDATION.md](VALIDATION.md) | Multi-step validation workflows, troubleshooting |
| [development/TESTING.md](../development/TESTING.md) | `make test-*` matrix |
| [development/BUILDING.md](../development/BUILDING.md) | Build variants and flags |
| [infrastructure/CI_CD.md](../infrastructure/CI_CD.md) | What CI runs on GitHub (parity expectations) |
| [QUICK_START.md](../QUICK_START.md) | High-level developer entry |
