# Infinite Bank — SDK `bank` extension module

The **Infinite Drive** binary (`infinited`) runs both the **Cosmos SDK `bank` module** (transfers, balances, on-chain metadata) and an **additional module** in this repo (`github.com/cosmos/evm/x/bank`) intended for **messages that extend SDK bank behaviour** without modifying the native module. It **currently** registers **`MsgSetDenomMetadata`** (metadata via **x/gov**); the same module structure can host **more `Msg`** types later. Technical detail, validation rules, CLI notes, and testing: **[INTEGRATION.md](INTEGRATION.md)**.

**On-chain module name:** the SDK **`ModuleName`** constant for this extension is the string **`infinitebank`** (defined in `x/bank/types/keys.go`). It is used for genesis and module ordering and **must not** duplicate the standard bank module name **`"bank"`**.

## What the code includes today

- **`MsgSetDenomMetadata`** (proto **`cosmos.evm.bank.v1`**), handler that validates metadata and calls the SDK keeper’s **`SetDenomMetaData`**.
- **`AppModule`** registered in **`infinited/app.go`** alongside the native bank module.

**Not** shipped as mandatory in-repo deliverables (may be added later): dedicated CLI subcommands, per-message integration tests, and **additional messages** under `cosmos.evm.bank.v1` (the module is already structured to accept them; see [INTEGRATION.md — Extensibility](INTEGRATION.md#extensibility)).

## Documents in this folder

| Document | Contents |
|-----------|-----------|
| [**INTEGRATION.md**](INTEGRATION.md) | What the module is; **[extensibility](INTEGRATION.md#extensibility)** (more bank-related messages); proto and paths; **[how to use](INTEGRATION.md#how-to-use)**; **[metadata validation](INTEGRATION.md#metadata-validation-cosmos-sdk-xbank)**; **[how to test](INTEGRATION.md#how-to-test)**; `--dry-run`. |
| [**README.md**](README.md) | This index. |

## Wiring in the binary

The SDK bank keeper is constructed in [`infinited/app.go`](../../../infinited/app.go) (`bankkeeper.NewBaseKeeper`, **`sdkbank.NewAppModule`** for module **`bank`**). The extension is registered with **`bank.NewAppModule`** from `github.com/cosmos/evm/x/bank`. Any wiring change should be reflected here and in the [fork divergence record](../../fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md#extensiones-de-producto-fork).

## Fork traceability

- **Divergence / product extensions:** [UPSTREAM_DIVERGENCE_RECORD.md — Extensiones de producto (fork)](../../fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md#extensiones-de-producto-fork).
- **Implementation log:** [logs/2026-04-04-infinite-bank.md](../../fork-maintenance/logs/2026-04-04-infinite-bank.md).

## See also

- Fork maintenance: [`docs/fork-maintenance/README.md`](../../fork-maintenance/README.md)
- Testing guide: [`docs/guides/development/TESTING.md`](../../guides/development/TESTING.md)
