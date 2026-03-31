# Chain upgrade system test (`TestChainUpgrade`)

This guide is the **canonical reference** for the end-to-end **software-upgrade** system test, its **genesis customization** path, and the **maintenance** expectations when Infinite Drive’s upgrade story changes. It complements (and does not replace) [GENESIS.md](../configuration/GENESIS.md) and [SCRIPTS.md](../development/SCRIPTS.md).

---

## Scope and intent

| Aspect | Detail |
|--------|--------|
| **Test entry** | `TestChainUpgrade` in `tests/systemtests` (implementation: `tests/systemtests/chainupgrade/v4_v5.go`) |
| **What it proves** | A **legacy** `evmd` binary can run until a planned height; an on-chain `MsgSoftwareUpgrade` proposal passes; the node restarts with the **current branch** binary and basic transactions still work. |
| **What it is not** | A recipe for production mainnet upgrades, nor a substitute for [migrations guides](../../migrations/) for operators. |

The harness is **large by nature**: it stitches together release artifacts, shell genesis customization, `jq`, per-validator `genesis gentx` / `collect-gentxs`, governance timing, and SDK systemtest keyring layout. Treat this file as the place to record **why** each step exists and **what to revisit** when the next upgrade path differs (e.g. both binaries share the same denom/gentx story).

### Legacy binary vs current binary (scope of changes)

| Expectation | Detail |
|-------------|--------|
| **Legacy `evmd`** | Treated as an **external release artifact** (default: downloaded from GitHub Releases into `tests/systemtests/binaries/v0.5/evmd`). This test **does not** assume you **edit or rebuild** the legacy binary from this repo’s tree **for the sake of the harness**. You may **pin a different tag** in the Makefile when the migrated-from version changes; that is still “use a published binary,” not “patch legacy source inside this test.” |
| **Goal** | A **successful on-chain software upgrade**: the legacy node runs until the scheduled height / halt behavior, then the process continues with the **current-branch** binary (built from the working tree) and a smoke transaction proves the chain is live. |
| **What may change in-repo** | Genesis scripts, systemtest orchestration (`v4_v5.go`), and the **current** application (`infinited/…`) so that the upgrade scenario is **reachable** and CI-stable — **not** a standing requirement to fork-patch the legacy executable’s source for every CI run. |

The application-side upgrade wiring described [below](#application-upgrade-names-and-handlers) applies to **`infinited` built from this repository** (the post-upgrade binary and normal nodes). It is **not** “modify the legacy release code”; it keeps the test deterministic while the legacy artifact remains whatever release you pin.

---

## Version-specific nature (legacy vs future)

Today the flow assumes:

1. **Legacy binary** — downloaded from GitHub Releases (default tag `v0.1.11`, repo `deep-thought-labs/infinite`) into `tests/systemtests/binaries/v0.5/evmd`. No `git checkout` of the old tag.
2. **Current binary** — built from the working tree and installed as `tests/systemtests/binaries/evmd` for validation and for the post-upgrade node.

**Implications for maintainers:**

- **Gentx regeneration** exists because `testnet init-files` embeds gentx signed for **`stake`**, while Infinite customizations align bonding and bank to **`drop`**. If a future legacy line already uses `drop` everywhere *and* gentx matches `bond_denom`, you might simplify or drop parts of the strip/regenerate pipeline — but only after proving the embedded txs remain valid.
- **`upgradeName`** and **`upgradeHeight`** in `v4_v5.go` must stay aligned with the handler constants in the application (see `UpgradeNameSystemTest` in `infinited/upgrades.go`).
- When the **migrated-from** version changes, update: release tag/Makefile defaults, any hard-coded paths under `binaries/v0.5/`, and this document’s “legacy” wording.

---

## High-level pipeline

```text
Stop chain → point SUT at legacy binary → SetupChain (testnet init-files)
    → customize_genesis.sh --network upgrade-test --skip-accounts (INFINITED_BIN=current)
    → read self-delegation amounts from embedded gentx
    → jq: clear app_state.genutil.gen_txs
    → copy genesis to all nodes
    → per-node: evmd genesis gentx (legacy binary, amounts in drop)
    → collect-gentxs on node0 → copy final genesis to all nodes
    → merge validator keyrings into testnet/keyring-test (CLI votes)
    → StartChain with halt-height → deposit/vote → wait PASSED → **await upgrade height − 1 via HTTP GET /status** (`awaitCometBlockHeightHTTP`, not `AwaitBlockHeight` nor an extra RPC websocket)
    → stop → switch to current binary → StartChain → smoke bank send
```

---

## Files and configuration

| Artifact | Role |
|----------|------|
| `scripts/genesis-configs/upgrade-test.json` | Harness-only economics and IDs: `local-4221`, EVM `4221`, **short** gov periods, deposits in **`drop`**. **Constraint:** `expedited_voting_period` must be **strictly less** than `voting_period` (SDK). |
| `scripts/customize_genesis.sh` | Applies profile; for `upgrade-test`, uses `--skip-accounts` (module/vesting setup scripts only accept mainnet/testnet/creative). Sets staking/mint/bank alignment to **`drop`** and **merges duplicate denoms per account** so `genesis gentx` does not hit “duplicate denomination drop”. |
| `tests/systemtests/chainupgrade/v4_v5.go` | Orchestrates gentx regeneration, keyring merge, proposal JSON, fees/deposit, **`awaitGovProposalStatus`** (tally is time-based, not “last vote”), halt height, binary swap, smoke test. |
| `infinited/upgrades.go` | Registers upgrade handlers for both the “real” upgrade name and the system-test upgrade name (see [Application: upgrade names and handlers](#application-upgrade-names-and-handlers)). |
| `tests/systemtests/README.md` | How to run system tests locally / Docker; points here for upgrade specifics. |

To tune **gov timing** or deposits for CI stability, prefer **`upgrade-test.json`** and, if needed, the proposal/fee strings in `v4_v5.go` — avoid scattering one-off JSON hacks in Go.

---

## Governance and timing pitfalls

- **Voting period vs block height:** The test asserts `PROPOSAL_STATUS_PASSED` before relying on upgrade height. The chain must reach **tally** (after `voting_end_time`) before the upgrade height if you want a deterministic pass; `voting_period` must be long enough for **sequential** votes from all validators plus margin, but short enough that voting completes **before** `upgradeHeight` under the test’s block times.
- **Inactive / still voting:** If votes are fired too late or `voting_period` is too short relative to wall-clock steps, queries can return `PROPOSAL_STATUS_VOTING_PERIOD` or “inactive proposal”. The helper **`awaitGovProposalStatus`** polls `gov proposal` on a short sleep loop until `PASSED` (it does **not** call `AwaitNextBlock`, which is tied to `--wait-time` and can fail with “no block within ~18s” under slow blocks).
- **`--halt-height` on the legacy node:** Must be **much larger** than `upgradeHeight` (not `upgradeHeight+1` alone). A low halt stops block production while the proposal is still in `VOTING_PERIOD`, so tally never runs and `AwaitNextBlock` times out.
- **Planned upgrade height in the proposal:** Must be **above** the height at which gov reaches `PASSED`. The **x/upgrade** handler **halts** the node at `upgradeHeight`; if that height is reached before `voting_end`, no further blocks are produced and the gov wait loops time out.
- **Reaching `upgradeHeight - 1` (pre-upgrade):** Do **not** rely on `sut.AwaitBlockHeight` from `cosmossdk.io/systemtests` for this step. Internally it calls `AwaitNextBlock` with a **short per-step cap** (`blockTime × 6`, often ~**18s**). Under Docker, a long suite, or when the harness’s websocket-driven height lags Comet, that can fail with `Timeout - no block within 18s` even though the node is healthy. The test uses **`awaitCometBlockHeightHTTP`**: plain **HTTP** polling of **`/status`** (no second Comet **websocket** client; the suite already holds one for the block listener—an extra client has correlated with **stuck height** in CI). Wall-clock budget: **`awaitPreUpgradeHeightDeadline`** (currently **15 minutes**). **`upgradeHeight`** in `v4_v5.go` is kept **moderate** (not ~100): after `PASSED` the chain is often only ~15–25 blocks high; requiring **80+** further blocks is slow on Docker and makes timeouts ambiguous (stall vs slow).

---

## Application: upgrade names and handlers

`TestChainUpgrade` must work with a **downloaded legacy binary** (release artifact) and a **current-branch binary** (built from this repo). We do **not** patch/rebuild the legacy artifact just to satisfy the harness.

In practice, some legacy artifacts may already have a compiled-in handler name that can interact poorly with the exact SDK/version wiring used by the harness once a plan is scheduled on-chain. To keep the system test deterministic without touching the legacy binary, we use a **test-only upgrade plan name** and register a matching handler in the **current** binary.

### What changed in this repository

| Piece | Behavior |
|-------|----------|
| **`tests/systemtests/chainupgrade/v4_v5.go`** | Uses a dedicated plan name: **`v0.4.0-to-v0.5.0-systemtest`**. |
| **`infinited/upgrades.go`** | Defines **`UpgradeNameSystemTest`** and registers `SetUpgradeHandler` for both **`UpgradeName`** and **`UpgradeNameSystemTest`**. Also configures the upgrade store loader for either name when resuming after a halt. |

### Relation to upstream `cosmos/evm`

Upstream **`evmd/upgrades.go`** (as of `main`) uses a single upgrade name constant and registers a single handler. This fork keeps the same “register at startup” pattern, but additionally registers the **system-test** upgrade name so the test can be stable against a legacy release artifact.

---

## Keyring and CLI (`--home`)

`cosmossdk.io/systemtests` exposes a shared CLI home under the testnet directory. **`SetupChain` only copies node0’s keyring** into that shared `keyring-test`. Gov votes use **`node0` … `node3`** keys; the test **`mergeAllValidatorKeyringsForCLI`** copies each validator’s `keyring-test` into the shared directory so `GetKeyAddr("node1")` et al. work.

---

## Running the test

From the repo root (see [tests/systemtests README](../../../tests/systemtests/README.md)):

- **Linux:** `make test-system` (downloads legacy binary, builds current).
- **macOS:** `make test-system-docker` (release zips are Linux binaries; QEMU amd64 on ARM breaks P2P).

Target only the upgrade test:

```bash
cd tests/systemtests
go test -failfast -mod=readonly -tags=system_test ./... -run TestChainUpgrade \
  --verbose --binary evmd --block-time 3s --chain-id local-4221 --bech32=infinite
```

---

## Maintenance checklist (after upstream merge or release changes)

- [ ] Legacy release tag still exists and checksums verify (`Makefile` / `SYSTEMTEST_LEGACY_TAG`).
- [ ] `upgradeName` / `upgradeHeight` match app upgrade registration (`UpgradeNameSystemTest` in `infinited/upgrades.go` for the system test; `UpgradeName` for the example upgrade).
- [ ] `upgrade-test.json` gov fields satisfy SDK ordering (`expedited` &lt; `voting`).
- [ ] `customize_genesis.sh` still merges bank denoms when EVM + staking both use `drop`.
- [ ] `jq` available in CI and local Docker image used for system tests.
- [ ] Re-run `TestChainUpgrade` (or full `make test-system-docker`).

---

## Related documentation

- [GENESIS.md — upgrade-test summary](../configuration/GENESIS.md#chain-upgrade-system-test-upgrade-test)
- [SCRIPTS.md — customize_genesis.sh](../development/SCRIPTS.md#scripts-customize_genesissh)
- [Fork maintenance — verification](../../fork-maintenance/VERIFICATION.md) and [playbook](../../fork-maintenance/PLAYBOOK.md) (post-merge testing)
- Version-to-version operator notes: [migrations/](../../migrations/)
