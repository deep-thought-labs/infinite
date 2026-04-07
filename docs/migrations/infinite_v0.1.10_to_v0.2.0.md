# Infinite Drive — software upgrade `infinite-v0.1.10-to-v0.2.0`

This guide describes the **on-chain software-upgrade plan** that Infinite Drive uses when moving validator sets from the **v0.1.10** release line to a **current** `infinited` binary (v0.2.0-era tree). It covers the **exact governance plan name**, what the **upgrade handler** and **store loader** do, how **Hyperlane** and **Infinite Bank** fit in, and—**for operators who have not done a coordinated upgrade before**—what will happen on-chain and **how to prepare, vote, and switch binaries**.

## Table of contents

- [What this upgrade does (plain language)](#what-this-upgrade-does-plain-language)
- [On-chain plan name (exact string)](#on-chain-plan-name-exact-string)
- [What the handler does today](#what-the-handler-does-today)
- [Infinite Bank (`x/bank` / `infinitebank`) — no new KV store on this plan](#infinite-bank-xbank--infinitebank--no-new-kv-store-on-this-plan)
- [Binaries and CI](#binaries-and-ci)
- [What validators should do (step by step)](#what-validators-should-do-step-by-step)
- [Example governance proposal (JSON)](#example-governance-proposal-json)
- [Appendix: what changes (binary only; Drive)](#appendix-what-changes-binary-only-drive)
- [Related documentation](#related-documentation)
- [When to add a new upgrade plan](#when-to-add-a-new-upgrade-plan)

## What this upgrade does (plain language)

A **software upgrade proposal** does **not** change the binary on your server by itself. It only **writes a schedule into chain state**: “at block height **H**, the chain will stop accepting blocks from the **old** software and will expect nodes to run a **new** `infinited` that knows how to apply plan `**infinite-v0.1.10-to-v0.2.0`**.”

**What you should picture:**

1. **Before height H:** everyone keeps running the **current** release (e.g. **v0.1.10**). The network is normal; blocks and transactions continue.
2. **Governance:** a **text + message** proposal is submitted. It contains one `**MsgSoftwareUpgrade`** message with the **exact plan name** and **height H**. Validators (and often delegators) **vote**. If the proposal **passes**, that schedule is **binding** for the chain.
3. **As H approaches:** operators must have the **new** `infinited` binary **built, verified, and ready** on each validator machine. **Do not** switch the binary before the process described below—height **H** is coordinated by the whole network.
4. **At height H:** the **old** binary reaches the upgrade height and **stops** progressing the chain (this is expected). The node is **waiting** for the **new** binary.
5. **After height H:** each operator **replaces** (or repoints) the `infinited` binary to the **new** version and **restarts** the node with the **same** data directory and validator keys. The **new** binary runs **migrations** (module version updates) and, for this plan, **creates the new key-value stores** for **Hyperlane** (`hyperlane`, `warp`). Then blocks continue from **H+1** (or the next height per CometBFT), now on the new code.

**Infinite Bank** in this release adds **governance-only** bank metadata tooling that uses the **existing** Cosmos `bank` store; it does **not** add a separate new database “bucket” on disk for this plan. **Hyperlane** **does** add new stores, which is why the upgrade plan includes a **store loader**—see [What the handler does today](#what-the-handler-does-today).

If any instruction below is unclear, treat **height H** and **plan name** as the two values that must match **exactly** between governance, the source code in `[infinited/upgrades.go](../../infinited/upgrades.go)`, and what your node runs.

## On-chain plan name (exact string)

Use this **verbatim** in `MsgSoftwareUpgrade` proposals:

```text
infinite-v0.1.10-to-v0.2.0
```

Registered in code as `**UpgradeName**` in `[infinited/upgrades.go](../../infinited/upgrades.go)`. The Go package in that file is named `**evmd**` for historical reasons; the binary you build and run is `**infinited**`. The `[tests/systemtests/chainupgrade/v0_1_10_to_v0_2_0.go](../../tests/systemtests/chainupgrade/v0_1_10_to_v0_2_0.go)` harness uses the **same** string (`upgradeName` constant) so CI matches production proposals.

## What the handler does today

- `**SetUpgradeHandler`**: Calls `**ModuleManager.RunMigrations**` only (no extra custom Go logic beyond a debug log line).
- `**UpgradeStoreLoader**`: For this plan only, `**StoreUpgrades.Added**` lists the Hyperlane module store keys `**hyperlane**` and `**warp**` (`hyperlanetypes.ModuleName`, `warptypes.ModuleName` from [hyperlane-cosmos](https://github.com/bcp-innovations/hyperlane-cosmos)).

Source of truth: `[infinited/upgrades.go](../../infinited/upgrades.go)`. Hyperlane integration context: [feature/hyperlane/INTEGRATION.md](../feature/hyperlane/INTEGRATION.md).

## Infinite Bank (`x/bank` / `infinitebank`) — no new KV store on this plan

The Cosmos EVM **Infinite Bank** extension (`[github.com/cosmos/evm/x/bank](../../x/bank/)`, module name `**infinitebank`**) registers an `**AppModule**` next to SDK `x/bank`, but **does not** add a dedicated entry to `**storetypes.NewKVStoreKeys`** in `[infinited/app.go](../../infinited/app.go)`. Persisted denom metadata goes through the **SDK `bankkeeper.Keeper`** (existing `**bank**` store).

Therefore `**infinitebank` is not** included in `**StoreUpgrades.Added`** for `infinite-v0.1.10-to-v0.2.0`. Bringing a chain from a **legacy binary without this module** still relies on `**RunMigrations`** (and the module’s default genesis / consensus version) so the new module is registered correctly. Product detail: [feature/infinite-bank/INTEGRATION.md](../feature/infinite-bank/INTEGRATION.md).

**If** a future change adds **dedicated persisted state** under a **new** store key for this module (or another fork module), that key must appear in `**StoreUpgrades.Added`** for the upgrade that introduces it — usually under a **new** governance-approved `infinite-…` plan name.

## Binaries and CI

- **Legacy node:** GitHub Release `**v0.1.10`** by default (`SYSTEMTEST_LEGACY_TAG` in the root `[Makefile](../../Makefile)`); download flow and overrides: [CHAIN_UPGRADE_SYSTEM_TEST.md](../guides/testing/CHAIN_UPGRADE_SYSTEM_TEST.md).
- **Post-upgrade node:** binary built from this repository (`infinited`).

The system test drops a legacy artifact under `**binaries/v0.5/evmd`** (path name is historical); the artifact is the **Infinite Drive** `v0.1.10` Linux binary from releases, not the current binary name.

## What validators should do (step by step)

Read this as a **checklist**. Replace **H** with the height chosen in the passed proposal.

### 1. Before anyone submits a proposal

- **Confirm** the chain is meant to move from **v0.1.10** (or equivalent) to a binary that **includes** this plan in `[infinited/upgrades.go](../../infinited/upgrades.go)`.
- **Build** the target `infinited` from a **tagged or reviewed** commit; record the **version / commit hash** you will use in production.
- **Test** the new binary on a **private testnet** or **staging** environment using the **same** plan name and a **test** height if possible (see [CHAIN_UPGRADE_SYSTEM_TEST.md](../guides/testing/CHAIN_UPGRADE_SYSTEM_TEST.md)).

### 2. Choose the upgrade height **H**

- **H** must be **after** the proposal can **pass** (deposit + voting period). If **H** arrives while the proposal is still voting, the upgrade will **not** behave as intended.
- Leave enough **wall-clock** time between **passing** and **H** for every operator to **download, verify, and install** the new binary.
- Communicate **H** in your validator / operator channel so no one is surprised.

### 3. Submit and vote on the proposal

- Use the **example JSON** in [Example governance proposal (JSON)](#example-governance-proposal-json) as a template.
- `**authority`** must be the **governance module account** address for **your** chain (query it—see the example section).
- `**plan.name`** must be **exactly** `infinite-v0.1.10-to-v0.2.0` (case-sensitive, no extra spaces).
- `**plan.height`** must be **H**, encoded as a **string** in JSON (e.g. `"1234567"`), matching what your `infinited` / CLI expects for `MsgSoftwareUpgrade`.
- After submission, **vote** `yes` (or follow your org’s governance process). Wait until the proposal status is **passed** before relying on the schedule.

### 4. Between “passed” and height **H**

- **Install** the new `infinited` binary on disk (e.g. side-by-side path or package update), but **keep running** the **old** process until the node **halts at H**.
- **Backup** critical data: validator keys, `config/`, and `data/` (per your security policy). **Operationally, this upgrade is designed so only the `infinited` binary changes**—your `data/` tree, `config/`, and key material **stay in place**. See [Appendix: what changes (binary only; Drive)](#appendix-what-changes-binary-only-drive).
- **Monitor** block height; ensure you are ready **before** **H**.

### 5. At and after height **H**

- When the **old** node **stops** at the upgrade height (logs will refer to the upgrade plan), **stop** the process cleanly if it has not already exited.
- **Replace only the `infinited` binary** (same node `**--home`**, same validator keys, same `config/` and `data/`). Your usual **start** / **Docker** / **Drive** commands stay the same in spirit—only the binary path or image layer that points to `infinited` is new. **Infinite Drive** operators using **[Drive](https://docs.infinitedrive.xyz/en)** (node lifecycle tooling) will receive a **concrete command** from the team to swap the binary inside the container or on the host; see the appendix.
- **Start** the node. The first startup after **H** applies **migrations** and **new stores** (`hyperlane`, `warp`) for this plan.
- **Watch logs** for errors. Confirm peers reconnect and **new blocks** are produced.
- Run a **smoke test** (e.g. query status, one harmless transaction) if your runbook requires it.

### 6. If something goes wrong

- **Do not** panic-change the plan name on a live chain without governance; the name is **fixed** in the binary’s `RegisterUpgradeHandlers`.
- Coordinate with other operators via your usual incident channel; compare **binary versions**, `**plan` in state**, and **height**.

## Example governance proposal (JSON)

Below is a **template** aligned with how `**TestChainUpgrade`** submits the upgrade (`[v0_1_10_to_v0_2_0.go](../../tests/systemtests/chainupgrade/v0_1_10_to_v0_2_0.go)`). Adjust `**deposit**`, `**title**`, `**summary**`, `**metadata**`, fees, and `**height**` for your network.

**1. Obtain the governance module address** (chain-specific):

```bash
infinited q auth module-account gov --output json | jq -r '.account.value.address'
# or, depending on CLI / output format:
infinited q auth module-accounts -o json | jq -r '.accounts[] | select(.value.name=="gov") | .value.base_account.address'
```

Use that string as `**authority**` below.

**2. Replace placeholders** in the JSON:


| Placeholder             | Meaning                                                                                                                                          |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `<GOV_MODULE_ADDRESS>`  | Output from the command above.                                                                                                                   |
| `<UPGRADE_HEIGHT>`      | Block height **H** (decimal digits only, as a **string** in JSON).                                                                               |
| `<DEPOSIT>`             | Minimum initial deposit for proposals on your chain, e.g. `100000000drop` (amount + base denom).                                                 |
| `<TITLE>` / `<SUMMARY>` | Human-readable text for explorers and voters.                                                                                                    |
| `<METADATA>`            | Gov v1 metadata (often a URI; use your chain’s convention).                                                                                      |
| `<NODE_HOME>`           | Validator node home directory (contains `config/`, `data/`, and usually the **file** keyring). Same path you pass to `infinited start --home …`. |


**3. Proposal body (example):**

```json
{
  "messages": [
    {
      "@type": "/cosmos.upgrade.v1beta1.MsgSoftwareUpgrade",
      "authority": "<GOV_MODULE_ADDRESS>",
      "plan": {
        "name": "infinite-v0.1.10-to-v0.2.0",
        "height": "<UPGRADE_HEIGHT>"
      }
    }
  ],
  "metadata": "<METADATA>",
  "deposit": "<DEPOSIT>",
  "title": "<TITLE>",
  "summary": "<SUMMARY>"
}
```

**4. Submit** (example for a **file** keyring under the node home; adjust fees and gas to your network):

```bash
infinited tx gov submit-proposal path/to/proposal.json \
  --from <KEY_NAME_IN_KEYRING> \
  --home <NODE_HOME> \
  --keyring-backend file \
  --chain-id <CHAIN_ID> \
  --node <RPC_URL_OPTIONAL> \
  --gas auto --gas-adjustment 1.3 \
  --fees <FEE_AMOUNT><DENOM>
```

- `**--home**`: Tells the CLI where the validator lives (`config/`, `data/`, and—when using `**file**`—the keyring files, typically under `<NODE_HOME>/keyring-file` unless you override with `**--keyring-dir**`).
- `**--keyring-backend file**`: Keys are read from **files** on disk (you will be prompted for the keyring password when signing). If you use `**test`** or `**os**` instead, drop or change these flags accordingly.
- `**--node**`: Optional; omit if `client.toml` already points at the right RPC.

**Vote** with the same `**--home`**, `**--keyring-backend**`, and `**--from**` pattern your operator account uses, then wait for **PASSED**, and follow [What validators should do (step by step)](#what-validators-should-do-step-by-step).

**Field notes (first-time readers):**

- `**messages`**: In Cosmos SDK **gov v1**, the executable content of the proposal is a list of messages. Here there is **only one**: upgrade the chain at `**height`** using plan `**name**`.
- `**authority**`: Only the **gov module** may execute `MsgSoftwareUpgrade` on-chain; that is why this address is required.
- `**plan.name`**: Must **match** `UpgradeName` in `[infinited/upgrades.go](../../infinited/upgrades.go)` **exactly**.
- `**plan.height`**: String form avoids JSON number issues on some tooling; it must be the **agreed** height **H**.

## Appendix: what changes (binary only; Drive)

**Scope of the change:** For this coordinated upgrade, **only the `infinited` executable** is meant to switch from the pre-upgrade build to the post-upgrade build. **Validator state** (`data/`), **configuration** (`config/`), **keyring**, and **CLI / systemd / Docker / Drive launch commands** should **remain the same**—you are not re-initializing the node, not wiping `data/`, and not rotating keys as part of this procedure.

- **Backups** (step 4) are still best practice before any production change; they are **insurance**, not a requirement to “restore into a new directory” for a normal upgrade.
- **Drive** ([repository](https://github.com/deep-thought-labs/drive), [documentation](https://docs.infinitedrive.xyz/en)): if you run your validator through **Drive**, you still only **replace the binary** the stack executes. The **Infinite Drive** team will share the **exact command** (or short runbook) to perform that swap—**Docker** image or volume path, or **bare-metal** install path—**at the moment the chain has halted** at height **H**. Until then, keep the current binary running.
- After the swap, **start** the node the same way you did before (same `drive.sh` / `docker compose` / `systemd` unit / `infinited start --home …`); only the resolved `**infinited`** binary should differ.

## Related documentation


| Topic                                                       | Document                                                                           |
| ----------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| End-to-end system test, genesis `upgrade-test`, maintenance | [CHAIN_UPGRADE_SYSTEM_TEST.md](../guides/testing/CHAIN_UPGRADE_SYSTEM_TEST.md)     |
| Hyperlane stores and upgrade notes                          | [feature/hyperlane/README.md](../feature/hyperlane/README.md)                      |
| Infinite Bank module (no separate store)                    | [feature/infinite-bank/README.md](../feature/infinite-bank/README.md)             |


## When to add a new upgrade plan

Add a **new** `UpgradeName` string and handler in `[infinited/upgrades.go](../../infinited/upgrades.go)`, extend `**StoreUpgrades.Added`** for every **new** mountable store key, and update **this file** plus [CHAIN_UPGRADE_SYSTEM_TEST.md](../guides/testing/CHAIN_UPGRADE_SYSTEM_TEST.md) if the system test should exercise the new plan. Examples of triggers: `**x/group`**, Hyperlane major store layout changes, or any fork module that introduces a **new** `KVStoreKey`.
