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

---

## Version-specific nature (legacy vs future)

Today the flow assumes:

1. **Legacy binary** — downloaded from GitHub Releases (default tag `v0.1.11`, repo `deep-thought-labs/infinite`) into `tests/systemtests/binaries/v0.5/evmd`. No `git checkout` of the old tag.
2. **Current binary** — built from the working tree and installed as `tests/systemtests/binaries/evmd` for validation and for the post-upgrade node.

**Implications for maintainers:**

- **Gentx regeneration** exists because `testnet init-files` embeds gentx signed for **`stake`**, while Infinite customizations align bonding and bank to **`drop`**. If a future legacy line already uses `drop` everywhere *and* gentx matches `bond_denom`, you might simplify or drop parts of the strip/regenerate pipeline — but only after proving the embedded txs remain valid.
- **`upgradeName`** and **`upgradeHeight`** in `v4_v5.go` must stay aligned with the handler constants in the application (see `infinited/upgrades.go` or equivalent).
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
    → StartChain with halt-height → deposit/vote → wait PASSED → await upgrade height
    → stop → switch to current binary → StartChain → smoke bank send
```

---

## Files and configuration

| Artifact | Role |
|----------|------|
| `scripts/genesis-configs/upgrade-test.json` | Harness-only economics and IDs: `local-4221`, EVM `4221`, **short** gov periods, deposits in **`drop`**. **Constraint:** `expedited_voting_period` must be **strictly less** than `voting_period` (SDK). |
| `scripts/customize_genesis.sh` | Applies profile; for `upgrade-test`, uses `--skip-accounts` (module/vesting setup scripts only accept mainnet/testnet/creative). Sets staking/mint/bank alignment to **`drop`** and **merges duplicate denoms per account** so `genesis gentx` does not hit “duplicate denomination drop”. |
| `tests/systemtests/chainupgrade/v4_v5.go` | Orchestrates gentx regeneration, keyring merge, proposal JSON, fees/deposit, **`awaitGovProposalStatus`** (tally is time-based, not “last vote”), halt height, binary swap, smoke test. |
| `tests/systemtests/README.md` | How to run system tests locally / Docker; points here for upgrade specifics. |

To tune **gov timing** or deposits for CI stability, prefer **`upgrade-test.json`** and, if needed, the proposal/fee strings in `v4_v5.go` — avoid scattering one-off JSON hacks in Go.

---

## Governance and timing pitfalls

- **Voting period vs block height:** The test asserts `PROPOSAL_STATUS_PASSED` before relying on upgrade height. The chain must reach **tally** (after `voting_end_time`) before the upgrade height if you want a deterministic pass; `voting_period` must be long enough for **sequential** votes from all validators plus margin, but short enough that voting completes **before** `upgradeHeight` under the test’s block times.
- **Inactive / still voting:** If votes are fired too late or `voting_period` is too short relative to wall-clock steps, queries can return `PROPOSAL_STATUS_VOTING_PERIOD` or “inactive proposal”. The helper **`awaitGovProposalStatus`** polls `gov proposal` and advances blocks until `PASSED` (or timeout / rejection).

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
- [ ] `upgradeName` / `upgradeHeight` match app upgrade registration.
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
