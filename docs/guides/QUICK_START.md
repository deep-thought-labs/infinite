# Quick Start - Infinite Drive

> **Developer entry point** — minimal path to a working build. Details live in the linked guides only once.

## Build and verify (local)

1. **Prerequisites and compile** — follow [development/BUILDING.md](development/BUILDING.md) (Workflow 1: Development Build). It covers `check_build_prerequisites.sh`, `make install`, PATH, and `infinited version`.
2. **Tests** — [development/TESTING.md](development/TESTING.md).
3. **Full integrity check (lint + build + tests + scripts)** — [testing/PROJECT_INTEGRITY_CHECKLIST.md](testing/PROJECT_INTEGRITY_CHECKLIST.md).

## Run a node

Operational paths are defined in the [repository README.md](../../README.md) (*Run a Node*), in this order:

| Order | Path | Links |
|-------|------|--------|
| 1 | **Drive** (node manager; official binaries inside services) | [Repository](https://github.com/deep-thought-labs/drive) · [Documentation](https://docs.infinitedrive.xyz/en) |
| 2 | **Pre-built `infinited`** | [**Latest release**](https://github.com/deep-thought-labs/infinite/releases/latest) · [All releases](https://github.com/deep-thought-labs/infinite/releases) |
| 3 | **Build from this repository** | [README — Option 3](../../README.md#option-3-build-from-this-repository) · [BUILDING.md](development/BUILDING.md) |

## Where to go next

| Goal | Document |
|------|----------|
| Scripts (what each `.sh` does) | [development/SCRIPTS.md](development/SCRIPTS.md) |
| Validation sequences (grouped commands) | [testing/VALIDATION.md](testing/VALIDATION.md) |
| Releases / tags | [infrastructure/RELEASES.md](infrastructure/RELEASES.md) |
| Genesis / tokenomics | [configuration/GENESIS.md](configuration/GENESIS.md) |
| Production / validators | [deployment/PRODUCTION.md](deployment/PRODUCTION.md), [deployment/VALIDATORS.md](deployment/VALIDATORS.md) |
| CI / GitHub Actions setup | [infrastructure/CI_CD.md](infrastructure/CI_CD.md) |
| Problems | [reference/TROUBLESHOOTING.md](reference/TROUBLESHOOTING.md) |
| Day-to-day coding | [development/DEVELOPMENT.md](development/DEVELOPMENT.md) |
