# Infinite Drive — software upgrade `infinite-v0.1.10-to-v0.1.12`

Fork-specific guide for the **on-chain software-upgrade plan** used in production governance and in **`TestChainUpgrade`**. It is **not** an upstream [cosmos/evm](https://github.com/cosmos/evm) stack bump checklist; those live in `v0.*_to_v0.*.md` files in this folder.

## On-chain plan name (exact string)

Use this **verbatim** in `MsgSoftwareUpgrade` proposals:

```text
infinite-v0.1.10-to-v0.1.12
```

Registered in code as **`UpgradeName`** in [`infinited/upgrades.go`](../../infinited/upgrades.go). The [`tests/systemtests/chainupgrade/v0_1_10_to_v0_1_12.go`](../../tests/systemtests/chainupgrade/v0_1_10_to_v0_1_12.go) harness must use the **same** string (`upgradeName` constant).

The `infinite-` prefix distinguishes Infinite Drive plans from upstream-style names (e.g. sample `v0.4.0-to-v0.5.0` in cosmos/evm docs), which this fork does **not** register.

## What the handler does today

- **`SetUpgradeHandler`:** runs **`ModuleManager.RunMigrations`** (no extra custom logic).
- **`UpgradeStoreLoader`:** `StoreUpgrades.Added` includes **`hyperlane`** and **`warp`** (Hyperlane `x/core` and `x/warp`); see [`infinited/upgrades.go`](../../infinited/upgrades.go). Detail: [docs/feature/hyperlane/INTEGRATION.md](../feature/hyperlane/INTEGRATION.md).

## Binaries and CI

- **Legacy node:** GitHub Release **`v0.1.10`** by default (`SYSTEMTEST_LEGACY_TAG` in the root [`Makefile`](../../Makefile)); download flow and overrides: [CHAIN_UPGRADE_SYSTEM_TEST.md](../guides/testing/CHAIN_UPGRADE_SYSTEM_TEST.md).
- **Post-upgrade node:** binary built from this repository (`infinited`).

## Operator checklist (high level)

1. Build and ship the new `infinited` binary that includes this plan’s handler.
2. Submit a governance proposal with **`name`: `infinite-v0.1.10-to-v0.1.12`** and a chosen **`height`** above tally.
3. After the upgrade height, ensure nodes run the new binary; confirm migrations and (if configured) new stores.

## Related documentation

| Topic | Document |
|-------|-----------|
| End-to-end system test, genesis `upgrade-test`, maintenance | [CHAIN_UPGRADE_SYSTEM_TEST.md](../guides/testing/CHAIN_UPGRADE_SYSTEM_TEST.md) |
| Fork divergence (plan naming policy) | [UPSTREAM_DIVERGENCE_RECORD.md](../fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md) |
| Future `x/group` work | [features/x-group/IMPLEMENTATION_PLAN.md](../features/x-group/IMPLEMENTATION_PLAN.md) |
| Hyperlane stores on upgrade | [feature/hyperlane/INTEGRATION.md](../feature/hyperlane/INTEGRATION.md) |

## Upcoming work (placeholder)

When **`x/group`** (or other modules beyond Hyperlane) is added with a **new store**, update:

- `infinited/upgrades.go` — add the module store key to `StoreUpgrades.Added` for the upgrade that introduces it (same or a **new** `infinite-…` plan name, as decided by governance).
- This file — record the new plan name and store list if it differs from the baseline above.
