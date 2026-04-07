# Validation workflows

Use this document for **multi-step validation flows** (what to run together and when). Per-script behavior lives in **[development/SCRIPTS.md](../development/SCRIPTS.md)**.

| Topic | Canonical doc |
|-------|----------------|
| **Each script** (purpose, usage, output, requirements) | [development/SCRIPTS.md](../development/SCRIPTS.md#validation-and-verification-scripts) |
| **Ordered full-repo check** (lint → build → tests → …) | [PROJECT_INTEGRITY_CHECKLIST.md](PROJECT_INTEGRITY_CHECKLIST.md) |
| **`make test-*` and coverage** | [development/TESTING.md](../development/TESTING.md) (granular coverage: [Granular coverage blocks](../development/TESTING.md#granular-coverage-blocks-test-unit-cover)) |
| **Build prerequisites and compile** | [development/BUILDING.md](../development/BUILDING.md) |

## Validation scripts at a glance

| Script | Requires running node |
|--------|------------------------|
| `check_build_prerequisites.sh` | No |
| `validate_customizations.sh` | No |
| `validate_genesis_structure.sh` | No |
| `validate_token_config.sh` | Yes |
| `infinite_health_check.sh` | Yes |

## Recommended workflows

### Quick validation after changes

**When:** After editing code.

```bash
./scripts/validate_customizations.sh
make install
make test-unit
```

### Complete validation before commit

**When:** Before an important commit.

```bash
./scripts/validate_customizations.sh
make install
make test-all
# If a node is running:
./scripts/validate_token_config.sh
```

### Running node validation

**When:** After starting a node or changing chain/token config.

```bash
./scripts/infinite_health_check.sh
./scripts/validate_token_config.sh
```

### Pre-release validation

**When:** Before tagging / publishing a release.

```bash
make lint
make install
./scripts/validate_customizations.sh
make test-all
make release-dry-run-linux
# If a test node is up:
./scripts/infinite_health_check.sh
./scripts/validate_token_config.sh
```

Release steps on GitHub: [infrastructure/RELEASES.md](../infrastructure/RELEASES.md).

## Auxiliary: compare tree to upstream

`list_all_customizations.sh` is documented in [SCRIPTS.md §6](../development/SCRIPTS.md#6-list_all_customizationssh). Typical usage:

```bash
./scripts/list_all_customizations.sh upstream/main
```

## Troubleshooting

### Script cannot reach the node

**Symptom:** `infinite_health_check.sh` or `validate_token_config.sh` fail.

1. Confirm `infinited` is running.
2. Confirm ports **8545** (JSON-RPC), **1317** (REST), **26657** (CometBFT RPC).
3. Run commands from the **repository root**.

**Optional manual checks** (same endpoints the health script uses): see [SCRIPTS.md — `infinite_health_check.sh`](../development/SCRIPTS.md#5-infinite_health_checksh).

### `validate_customizations.sh` fails

1. Save all files; confirm branch.
2. Read the script output for the failing check.
3. See [fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md](../../fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md).

### `make test-unit` or `make test-all` fail

1. See [development/TESTING.md](../development/TESTING.md).
2. Clean and rebuild: `rm -rf build/` then `make install`, then re-run tests.

## See also

- [QUICK_START.md](../QUICK_START.md)
- [fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md](../../fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md)
