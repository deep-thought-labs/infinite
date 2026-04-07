# Infinite Bank — technical integration

## Repository context (Infinite Improbability Drive)

This file documents code that lives in the **Infinite Improbability Drive** chain repository — the monorepo you clone and build to produce the **`infinited`** binary (project overview: [README](../../../README.md) at the **repository root**). That tree is a **fork of** [cosmos/evm](https://github.com/cosmos/evm); the **root `go.mod`** still declares **`module github.com/cosmos/evm`** so imports stay compatible with the upstream module layout. Packages such as **`github.com/cosmos/evm/x/bank`** are implemented **in this same checkout** under `x/bank/`, not fetched as an external module for day-to-day development.

**Where to run commands:** use the **top-level directory** of that checkout — the folder that contains `go.mod`, `Makefile`, `x/`, `proto/`, and `infinited/` (**repository root**). The **exact commands and order** for verification are in **[How to test](#how-to-test)** only. Only when a snippet shows **`cd infinited`** are you inside **`infinited/`** (that subdirectory has its own `go.mod` for the node binary).

## What it is and what it is for

This codebase adds an **application module** in Go at **`github.com/cosmos/evm/x/bank`** (directory **`x/bank/`** here), which **currently** exposes **`MsgSetDenomMetadata`**. It lets **governance**, once a proposal passes, **define or correct** **denom metadata** in **Cosmos SDK `x/bank`** state (the same internal operation as the SDK keeper’s `SetDenomMetaData`, which is not exposed as a standard SDK transaction message). Any client that reads metadata from bank (for example ERC-20 precompiles that query the keeper) will see the **current values** after the message executes successfully.

### Extensibility

The layout follows the usual Cosmos module pattern (`AppModule`, `keeper/`, `types/`, protobuf `service Msg`): it is **ready for more RPCs** on the same **`Msg`** service (or other `.proto` files), new implementations under **`x/bank/keeper`**, wiring in **`RegisterServices`**, and extending **`RegisterInterfaces`** / amino in `types/codec.go` as needed. The goal is to keep **messages that extend SDK bank behaviour** in this module **without** editing the native `bank` module code or growing `app.go` beyond registering the `AppModule`. Any change that affects persisted module state may require bumping **consensus version** and, when applicable, migrations.

### Module identifier (`ModuleName`)

In `x/bank/types/keys.go` the constant is **`ModuleName = "infinitebank"`**. That string is the **module name in the Cosmos SDK runtime**: genesis ordering, begin/end block order, per-module genesis map keys, etc. It is **not** the token symbol or the wallet-facing name. It must **differ** from the standard SDK module name **`"bank"`** (`banktypes.ModuleName`): in `infinited` both **`sdkbank.NewAppModule`** (native bank) and **`bank.NewAppModule`** (this module, import `github.com/cosmos/evm/x/bank`) are registered. Application code often imports `github.com/cosmos/evm/x/bank/types` as `evmbanktypes`; there **`evmbanktypes.ModuleName` == `"infinitebank"`**.

### Authority for `MsgSetDenomMetadata`

It should run only inside an **x/gov** proposal; the **`authority`** field must be the **gov** module account address. The handler rejects any other authority. (Future messages in this module may use different authorization rules.)

## Proto

- **`proto/cosmos/evm/bank/v1/tx.proto`** — protobuf package **`cosmos.evm.bank.v1`** and `go_package` **`github.com/cosmos/evm/x/bank/types`**, aligned with other protos under `proto/cosmos/evm/` and with `scripts/generate_protos.sh` (only files whose `go_package` references `cosmos/evm`). Additional messages can be added as extra **`rpc`** entries on the same `service Msg`.
- Generated gogo code: **`x/bank/types/tx.pb.go`** (`make proto-gen` or `buf generate` with the plugins referenced in the repo Makefile).
- Pulsar API (e.g. reflection): **`api/cosmos/evm/bank/v1/*.go`** (`buf generate` with `proto/buf.gen.pulsar.yaml`).

The message **type URL** in transactions and proposal JSON is **`/cosmos.evm.bank.v1.MsgSetDenomMetadata`** (do not confuse with other package prefixes that do not match this generated file).

## Code layout

| Piece | Path |
|--------|------|
| Types, codec, empty `{}` genesis JSON | `x/bank/types/` (`ModuleName` in `keys.go`) |
| Msg server | `x/bank/keeper/msg_server.go` |
| `AppModule` | `x/bank/module.go` |
| App wiring | `infinited/app.go`: SDK module `sdkbank.NewAppModule(...)` and extension `bank.NewAppModule(...)`; ordering lists include **`"infinitebank"`** (via `evmbanktypes.ModuleName`) in addition to `banktypes.ModuleName` |

### On-chain software upgrades (Infinite Drive)

The extension **does not** register a separate **`KVStoreKey`** for `infinitebank` in `infinited/app.go`; state changes use **SDK `x/bank`**. The fork plan **`infinite-v0.1.10-to-v0.1.12`** therefore does **not** add `infinitebank` to **`StoreUpgrades.Added`** in `infinited/upgrades.go` (unlike **Hyperlane** `hyperlane` / `warp` stores). New binaries still pick up the module via **`ModuleManager.RunMigrations`** when upgrading from a release that omitted it. Canonical write-up: [migrations/infinite_v0.1.10_to_v0.1.12.md](../../migrations/infinite_v0.1.10_to_v0.1.12.md).

After changing this module, use **[How to test](#how-to-test)** for the full local verification sequence (no duplicate command list elsewhere in this file).

---

## How to use

For **operators** and **integrators** submitting proposals on live or test networks.

### What it does

After a governance proposal that includes it passes, **`MsgSetDenomMetadata`** writes denom metadata into SDK **`x/bank`** state (same semantics as the standard keeper: `SetDenomMetaData`). Use it to set or update **name, symbol, units (exponents)**, and optional fields (`uri`, `uri_hash`) for a `denom` that already exists on chain.

### Restrictions

- It is **not** a normal user-signed transaction: the message must be inside a **gov** proposal, and **`authority`** must **exactly** match the **gov** module account (otherwise the handler returns `ErrInvalidSigner`).
- **`metadata`** must pass SDK **`Metadata.Validate()`** (see next section). If validation fails, execution of the message may **fail** when gov runs it.

### Metadata validation (Cosmos SDK x/bank)

The handler calls `msg.Metadata.Validate()` **before** `SetDenomMetaData` (see `x/bank/keeper/msg_server.go`). The rules are **not** defined by this fork: they come from **`github.com/cosmos/cosmos-sdk/x/bank/types`**, methods `Metadata.Validate()` and `DenomUnit.Validate()`, for whichever Cosmos SDK version your repo’s `go.mod` pins (e.g. the `infinited` module).

#### `Metadata` checks

| Check | Detail |
|--------------|---------|
| `name` | Cannot be empty or whitespace-only (`TrimSpace`). |
| `symbol` | Same as `name`. |
| `base` | Must be a **valid denom** per `sdk.ValidateDenom` (SDK default regex: leading letter; 3–128 chars; charset `[a-zA-Z0-9/:._-]`, suitable for `ibc/…`). |
| `display` | Same valid-denom rules as `base`. |
| `denom_units` | At least one entry; see ordering and `DenomUnit` rules below. |
| First unit (`denom_units[0]`) | `denom` **must equal** `base` and `exponent` **must be 0**. |
| Remaining units | `exponent` must be **strictly increasing** (ascending order). |
| Duplicates | No two units may share the same `denom`. |
| `display` in units | Some `denom_units` entry must have `denom == display`. |
| `description`, `uri`, `uri_hash` | **Not** validated by `Metadata.Validate()`; may be empty or set as needed. |

#### Each `DenomUnit`

| Check | Detail |
|--------------|---------|
| `denom` | Must pass `sdk.ValidateDenom`. |
| `aliases` | No duplicates; no empty or whitespace-only alias strings. |

#### Typical error strings (reference)

The SDK returns fixed or `fmt`-style messages such as: `name field cannot be blank`, `symbol field cannot be blank`, `invalid metadata base denom`, `invalid metadata display denom`, `metadata's first denomination unit must be the one with base denom`, `the exponent for base denomination unit … must be 0`, `denom units should be sorted asc by exponent`, `duplicate denomination unit`, `metadata must contain a denomination unit with display denom`, `invalid denom unit`, `duplicate denomination unit alias`, `alias for denom unit … cannot be blank`.

To debug **`Metadata.Validate()`** failures, combine **`--dry-run`** on `submit-proposal` (see [Simulation without broadcast](#simulation-without-broadcast)) with checking **execution results** when gov applies the message after the vote.

### Protobuf type (for `proposal.json`)

- **Message type URL:** `/cosmos.evm.bank.v1.MsgSetDenomMetadata`  
  (asserted in tests: `sdk.MsgTypeURL(&MsgSetDenomMetadata{})` in `x/bank/types/typeurl_test.go`.)

### `authority` address

Fetch the gov module account for **the network you use** (Bech32 prefix depends on the chain, e.g. `infinite` on Infinite Drive):

```bash
infinited q auth module-account gov --node <RPC>
```

Use the returned address verbatim in the message JSON.

### Example `proposal.json` (gov v1)

Replace `<GOV_MODULE_ADDRESS>` and point **`metadata`** at a **real** `base` denom that already exists on that chain.

**`deposit` (required, real):** must be a valid coin string that satisfies **your** network’s governance **minimum deposit** (query `infinited q gov params --node <RPC>` and use `min_deposit` exactly — correct **amount** and **denom**, usually the chain’s **fee/staking** token). Submission fails if `deposit` does not match what `gov` expects; it has **nothing** to do with the illustrative **TOAST** metadata in `messages`.

The **`metadata` block below is only illustrative**: it uses an obvious toy identity (**`utoast` / TOAST**) so the example is not mistaken for your chain’s native token.

```json
{
  "messages": [
    {
      "@type": "/cosmos.evm.bank.v1.MsgSetDenomMetadata",
      "authority": "<GOV_MODULE_ADDRESS>",
      "metadata": {
        "description": "Illustrative metadata for a sample TOAST asset (replace with a real denom on your chain)",
        "denom_units": [
          { "denom": "utoast", "exponent": 0, "aliases": [] },
          { "denom": "TOAST", "exponent": 6, "aliases": [] }
        ],
        "base": "utoast",
        "display": "TOAST",
        "name": "Toast sample token",
        "symbol": "TOAST",
        "uri": "",
        "uri_hash": ""
      }
    }
  ],
  "metadata": "https://example.invalid/proposal-42",
  "deposit": "<MIN_DEPOSIT_FROM_GOV_PARAMS>",
  "title": "Update denom metadata",
  "summary": "Proposal that executes MsgSetDenomMetadata after the vote."
}
```

### CLI: submit proposal, vote, verify

From your environment (with `infinited` on `PATH`; build from the **repository root** with `make build-from-infinited`, or from `infinited/` with `go build -o ../build/infinited ./cmd/infinited`), with correct `chain-id` / node:

```bash
# 1) Submit the proposal (depositor signs)
infinited tx gov submit-proposal path/to/proposal.json \
  --from <your_key> \
  --chain-id <CHAIN_ID> \
  --gas auto --gas-adjustment 1.3 \
  --fees <amount><fee_denom>

# 2) Vote (after voting opens)
infinited tx gov vote <proposal_id> yes --from <your_key> --chain-id <CHAIN_ID> ...

# 3) After the message runs, query bank metadata
infinited q bank denom-metadata <base_denom> --node <RPC>
# or list all:
infinited q bank denoms-metadata --node <RPC>
```

Built-in help describes the JSON shape:

```bash
infinited tx gov submit-proposal --help
```

### Simulation without broadcast

The Cosmos SDK client supports **`--dry-run`** on `infinited tx gov submit-proposal` (and other `tx` commands): the node **simulates** the transaction and **does not broadcast** it. You still need a reachable **`--node`** and a valid **`--from`** in the keyring to build and sign the simulation.

**What `submit-proposal --dry-run` usually covers**

- Primarily the **proposal submission transaction** (encoding, proposer signature, deposit, gas when using `--gas auto`, etc.).
- The node **may** surface **some** issues in embedded `messages` **if** the simulation runs them; exact behaviour depends on SDK version and how gov simulates `MsgSubmitProposal`.

**What `--dry-run` does not replace**

- **Definitive** validation of **`MsgSetDenomMetadata`** happens when **x/gov executes** that message **after** the proposal passes: **`authority` + `Metadata.Validate()` + `SetDenomMetaData`**. If that fails, errors show up in **block events / logs** (metadata unchanged).
- Therefore **`--dry-run` on submit does not guarantee** the inner message will succeed at execution time; it is a pre-check, not a substitute for vote + execution or integration tests.

**Example command**

```bash
infinited tx gov submit-proposal proposal.json \
  --from <key> \
  --chain-id <CHAIN_ID> \
  --node <RPC> \
  --dry-run
```

After the proposal passes, confirm on chain that the message applied (e.g. `infinited q gov proposal <id>` and `infinited q bank denom-metadata <base>`).

---

## How to test

### 1. Protobuf codegen (only after editing `.proto`)

**Run from:** **repository root** (the directory with the root `go.mod` and `Makefile`).

If you change **`proto/cosmos/evm/bank/v1/tx.proto`** (or other generated protos in this repo), regenerate first:

```bash
make proto-gen
```

Then continue with steps 2–4 (tidy if needed, then unit tests and build). If you only changed Go under `x/bank/` and did not touch protos, **skip this step**.

### 2. Go module tidy (only if dependencies changed)

**Run from:** **repository root**.

If **`go.mod`** / **`go.sum`** changed (new imports, bumps, or after regenerating protos that affect modules), run:

```bash
go mod tidy
```

### 3. Unit tests for `x/bank`

**Run from:** **repository root** — **not** from `infinited/`.

```bash
go test ./x/bank/... -count=1
```

This runs **`x/bank/types/typeurl_test.go`** (message type URL) and **`x/bank/keeper/msg_server_test.go`** (authority check, metadata validation, successful `SetDenomMetaData` call and `set_denom_metadata` event).

### 4. Build the `infinited` binary

The Makefile target **`build-from-infinited`** is defined for this repository: it runs `go build` inside **`infinited/`** and writes **`build/infinited`** next to the root `go.mod` (see `BUILDDIR` in the root `Makefile`).

**Run from:** **repository root**:

```bash
make build-from-infinited
```

**Alternative without Make** — **run from:** `infinited/` (so the build uses `infinited/go.mod`), writing the binary next to the root `build/` folder:

```bash
cd infinited
go build -o ../build/infinited ./cmd/infinited
```

### 5. Optional: full `infinited` module test suite

**Run from:** **repository root**:

```bash
make test-infinited
```

This runs **`go test`** for all packages listed under **`infinited/`** (excluding simulation), with race and `test` build tags — it is **slower** than `go test ./x/bank/...` alone.

### 6. Local or test network (E2E)

For **end-to-end** flow (proposal → vote → execution → query), follow the same guidance as for the rest of the binary: [docs/guides/development/TESTING.md](../../guides/development/TESTING.md), local networks (`local_node.sh` / project testnet config), and **shortened gov parameters only in dev**.

Typical steps:

1. Run `infinited` node(s) that include the `infinitebank` module.
2. Ensure balance and rights for gov **deposit**.
3. Submit `proposal.json` as above, vote, and verify with `infinited q bank denom-metadata`.

---

## Maintainers: integrating changes from cosmos/evm

When pulling commits from [cosmos/evm](https://github.com/cosmos/evm), resolve conflicts in `infinited/app.go` (module ordering; imports **`sdkbank`** = SDK bank, **`bank`** = `github.com/cosmos/evm/x/bank`), under `x/bank/**`, and regenerate protos if buf dependencies change.
