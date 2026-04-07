# Hyperlane on Infinite Drive

**Status:** **In-code integration** is documented; what remains is **operations**: deployments and real connectivity to the Hyperlane ecosystem — see [OPERATIONS.md](OPERATIONS.md).

This folder documents [Hyperlane](https://hyperlane.xyz/) on the **Infinite Improbability Drive** chain ([`infinite` repo](https://github.com/deep-thought-labs/infinite)).

## What the code covers — and what it does not

- **`x/core` + `x/warp` in `infinited`** turn on Hyperlane on the **Cosmos** side of the binary (native state, Warp in Go, alongside existing IBC and EVM).
- That **does not** replace the **on-chain** work still required: in practice, treat **Cosmos** and **EVM** as **two separate workstreams** if you want both experiences — each needs its own deployment, registry entries as appropriate, and **relayers** (without relayers, messages do not complete end-to-end). [OPERATIONS.md](OPERATIONS.md) summarizes what is left to do, relayers, and a short note on **security (ISM)**.

## Documents in this folder

| Document | Contents |
|----------|----------|
| [**INTEGRATION.md**](INTEGRATION.md) | Code: repo context, technical matrix, store upgrade, tests. |
| [**OPERATIONS.md**](OPERATIONS.md) | **After the code:** Cosmos/EVM duality, pending work, relayers, ISM at a high level, links to official docs. |
| [**README.md**](README.md) | This index. |

**Technical summary (code):** `hyperlane-cosmos@v1.2.0-rc.0` in [`infinited/go.mod`](../../../infinited/go.mod); [`infinited/app.go`](../../../infinited/app.go); [`infinited/config/permissions.go`](../../../infinited/config/permissions.go); stores in [`infinited/upgrades.go`](../../../infinited/upgrades.go) — migration [`infinite-v0.1.10-to-v0.2.0`](../../migrations/infinite_v0.1.10_to_v0.2.0.md). Tests: [`infinited/tests/integration/hyperlane_test.go`](../../../infinited/tests/integration/hyperlane_test.go).

## Fork traceability and maintenance

- **Divergence / product extensions:** [UPSTREAM_DIVERGENCE_RECORD.md — Extensiones de producto (fork)](../../fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md#extensiones-de-producto-fork).
- **Code-phase closeout log:** [logs/2026-04-03-hyperlane-integration.md](../../fork-maintenance/logs/2026-04-03-hyperlane-integration.md).

## Cross-references

- Fork maintenance: [`docs/fork-maintenance/README.md`](../../fork-maintenance/README.md)
- Testing: [`docs/guides/development/TESTING.md`](../../guides/development/TESTING.md)
