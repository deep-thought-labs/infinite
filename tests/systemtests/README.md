# Getting started with a new system test

## Overview

The systemtests suite is an end-to-end test suite that runs the evmd process and sends RPC requests from separate Ethereum/Cosmos clients. The systemtests for cosmos/evm use the `cosmossdk.io/systemtests` package by default. For more details, please refer to https://github.com/cosmos/cosmos-sdk/tree/main/tests/systemtests.

## Preparation

`make test-system` builds the **current branch** as `tests/systemtests/binaries/evmd` and downloads the **legacy** chain-upgrade binary from **GitHub Releases** (default tag `v0.1.10`, repo `deep-thought-labs/infinite`) into `tests/systemtests/binaries/v0.5/evmd`. There is **no** `git checkout` of the old tag; the baseline always comes from release artifacts + `checksums.txt`.

- **Linux:** `make test-system` (needs `curl`, `shasum` / SHA-256 tooling as provided by the Makefile on Linux).
- **macOS:** release archives are Linux-only; use Docker (see below).

`make test-system-docker` uses Docker’s **default Linux platform for your machine** (e.g. `linux/arm64` on Apple Silicon). **Do not** add `--platform linux/amd64` in the Makefile for that target on ARM Macs: running the node binary under QEMU breaks CometBFT P2P handshakes (`chacha20poly1305: message authentication failed`), leaves `numPeers=0`, and tests fail with `timeout waiting for node start`.

Override the release tag if needed: `make SYSTEMTEST_LEGACY_TAG=v0.1.10 test-system-docker`.

### Faster local Docker loop (recommended)

`make test-system-docker` starts a **fresh** container every time and reinstalls Debian packages plus Foundry, which is slow.

For day-to-day work on macOS:

1. **Once** (or when `tests/systemtests/docker/Dockerfile` changes):  
   `make test-system-docker-build`
2. **Each test run:**  
   `make test-system-docker-reuse`

`test-system-docker-reuse` uses image `infinite-systemtest-env:local` and Docker **named volumes** for Go module and build caches (`infinite-systemtest-gomod`, `infinite-systemtest-gocache`), so dependency downloads are mostly one-time per machine.

Optional overrides: `SYSTEMTEST_DOCKER_IMAGE`, `SYSTEMTEST_DOCKER_GOMOD_VOLUME`, `SYSTEMTEST_DOCKER_GOCACHE_VOLUME` (see root `Makefile`).

### Run a single system test in Docker

The root Docker targets now accept `TEST_ARGS`, which is passed through to the `go test` invocation inside the container. For example:

```shell
make test-system-docker-reuse TEST_ARGS='-run TestChainUpgrade -count=1'
```

## Run Individual test

Each scenario now has its own `Test…` wrapper in `main_test.go`, so you can target a specific flow directly. For example, to exercise the mempool ordering suite:

```shell
cd tests/systemtests
go test -failfast -mod=readonly -tags=system_test ./... -run TestMempoolTxsOrdering \
  --verbose --binary evmd --block-time 3s --chain-id local-4221 --bech32=infinite
```

Use `--bech32=infinite` so address encoding matches this chain (default in `cosmossdk.io/systemtests` is `cosmos`).

Mempool scenarios:

**Txpool assertions:** `suite.CheckTxsQueuedAsync` polls `eth_txpool_content` (with an overall timeout) until expected txs are classified as **queued** rather than relying on one snapshot immediately after submit. This aligns with how pending checks retry and reduces CI flakes for exclusive-mempool / dynamic-fee cases. See root [docs/guides/development/TESTING.md](../../docs/guides/development/TESTING.md#system-tests-txpool-queued-assertions).

| Test name | Description |
|-----------|-------------|
| `TestMempoolTxsOrdering` | Ordering of pending transactions across nodes |
| `TestMempoolTxsReplacement` | Replacement behaviour for EVM transactions |
| `TestMempoolTxsReplacementWithCosmosTx` | Replacement when Cosmos transactions are present |
| `TestMempoolMixedTxsReplacementEVMAndCosmos` | Mixed Cosmos/EVM replacement coverage |
| `TestMempoolTxRebroadcasting` | Rebroadcasting and nonce-gap handling |
| `TestMempoolCosmosTxsCompatibility` | Cosmos-only transactions interacting with the mempool |

EIP-712 scenarios:

| Test name | Description |
|-----------|-------------|
| `TestEIP712BankSend` | Single transfer signed via EIP-712 |
| `TestEIP712BankSendWithBalanceCheck` | Transfer plus balance assertions |
| `TestEIP712MultipleBankSends` | Sequential transfers with nonce management |

Account abstraction:

| Test name | Description |
|-----------|-------------|
| `TestAccountAbstractionEIP7702` | Account abstraction (EIP-7702) flow |

Chain lifecycle:

| Test name | Description |
|-----------|-------------|
| `TestChainUpgrade` | End-to-end upgrade handling; after legacy `SetupChain`, runs `scripts/customize_genesis.sh --network upgrade-test --skip-accounts`, then regenerates gentx in **`drop`** and runs gov until `PASSED` before the upgrade height. **Canonical doc:** [CHAIN_UPGRADE_SYSTEM_TEST.md](../../docs/guides/testing/CHAIN_UPGRADE_SYSTEM_TEST.md) (summary in [GENESIS.md](../../docs/guides/configuration/GENESIS.md#chain-upgrade-system-test-upgrade-test)) |

> ℹ️ `TestChainUpgrade` uses **`infinite-v0.1.10-to-v0.1.12`**, the same string as **`UpgradeName`** in `infinited/upgrades.go` (production governance). Upstream’s sample `v0.4.0-to-v0.5.0` appears only in their docs; this fork does not register it.
>
> ℹ️ The shared system test suite keeps a single chain alive across multiple tests when the node arguments are identical. Running several tests back-to-back therefore re-uses the same process unless a scenario explicitly changes the node configuration.

**Mempool broadcast scenarios** (`mempool/test_broadcast.go`): gossip deadlines and height assertions are tuned for **P2P latency under Docker/CI** (longer waits than the SDK default; height may drift slightly within a bound). That is **test harness** stability, not a change to node mempool logic.

## Run all tests

```shell
make test
```

## Updating Node's Configuration

New in systemtests v1.4.0, you can now update the `config.toml` of the nodes. To do so, the system under test should be set up like so:

```go
s := systemtest.Sut
s.ResetChain(t)
s.SetupChain("--config-changes=consensus.timeout_commit=10s")
```
