# Testing Guide - Infinite Drive

Guide for running tests and validating Infinite Drive code.

For an **ordered checklist** that includes lint, build, tests, and fork scripts, see **[../testing/PROJECT_INTEGRITY_CHECKLIST.md](../testing/PROJECT_INTEGRITY_CHECKLIST.md)**.

## 📋 Table of Contents

- [Test Types](#test-types)
- [Unit Tests](#unit-tests)
- [Integration Tests](#integration-tests)
- [Complete Tests](#complete-tests)
- [End-to-end system tests](#end-to-end-system-tests)
- [Tests with Coverage](#tests-with-coverage)
- [Granular coverage blocks (`test-unit-cover`)](#granular-coverage-blocks-test-unit-cover)
- [Mempool Krakatoa tests under test-unit-cover](#mempool-krakatoa-tests-under-test-unit-cover)
- [Code Validation](#code-validation)

## 🧪 Test Types

| Type | Command | What It Tests | Time |
|------|---------|---------------|------|
| **Unit** | `make test-unit` | Individual functions | 5-15 min |
| **Integration** | `make test-infinited` | Component integration | 10-20 min |
| **Complete** | `make test-all` | All tests | 15-30 min |
| **With Coverage** | `make test-unit-cover` | Four blocks, merged `coverage.txt` (see below) | 10-20 min |

---

## 🔬 Unit Tests

**Purpose**: Test individual functions and components of the code.

**What it tests**: Function logic, validations, calculations, etc.

**When to use**: After making code changes, before commit

### Run Unit Tests

```bash
# Run all unit tests
make test-unit
```

**What it does**:

- Runs all unit tests in the project
- Shows results in real time
- Reports failures if any

**Estimated time**: 5-15 minutes

**Expected output**:

```
?       github.com/cosmos/evm    [no test files]
ok      github.com/cosmos/evm/x/vm/types    0.123s
ok      github.com/cosmos/evm/x/vm/keeper   2.456s
...
```

### Specific Unit Tests

```bash
# Run tests for a specific package
cd x/vm/types
go test -v

# Run a specific test
go test -v -run TestFunctionName
```

---

## 🔗 Integration Tests

**Purpose**: Test integration between different system components.

**What it tests**: Module interaction, complete flows, configuration

**When to use**: Before important releases, after major changes

### Run Integration Tests

```bash
# Integration tests for infinited
make test-infinited
```

**What it does**:

- Runs integration tests specific to `infinited`
- Tests complete application flows
- Validates configuration and initialization

**Estimated time**: 10-20 minutes

---

## End-to-end system tests

The repo includes **`tests/systemtests`** (cosmos/evm-style harness): mempool, EIP-712, account abstraction, and **on-chain upgrade** coverage. See [tests/systemtests/README.md](../../../tests/systemtests/README.md) for how to run them (`make test-system` on Linux, `make test-system-docker` on macOS).

The **software-upgrade** path (legacy release binary → customized genesis → governance → current binary) is documented in **[CHAIN_UPGRADE_SYSTEM_TEST.md](../testing/CHAIN_UPGRADE_SYSTEM_TEST.md)**. That guide is version-specific maintenance material: when the “from” binary or upgrade name changes, update the test and that document together.

#### System tests: txpool queued assertions

Mempool scenarios (including **exclusive** / Krakatoa-style configs) assert EVM mempool state via `eth_txpool_content`. **`CheckTxsPending`** already retries until a tx appears in **pending**; historically **`CheckTxsQueuedAsync`** used the first successful RPC response as a **single snapshot**, which could flake on slower or busy CI runners when a tx was still classified as **pending** instead of **queued**.

`CheckTxsQueuedAsync` in [`tests/systemtests/suite/test_helpers.go`](../../../tests/systemtests/suite/test_helpers.go) now **polls** (same overall deadline as pending checks: `defaultTxPoolContentTimeout` in [`query.go`](../../../tests/systemtests/suite/query.go), ~100 ms between attempts, bounded per-call timeout `txPoolQueuedPollRPC`) until all expected txs satisfy the queued-vs-pending rules, or the deadline is reached. Fork maintenance note: [UPSTREAM_DIVERGENCE_RECORD.md — Estabilidad CI (tests Go)](../../fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md#estabilidad-ci-tests-go).

---

## 🧱 Solidity harness (`make test-solidity`)

The repo includes Solidity-based tests under **`tests/solidity/`** that exercise the JSON-RPC stack and EVM precompiles against a locally spawned node (`local_node.sh`).

Run:

```bash
make test-solidity
```

**Important (Bech32 / Infinite prefixes)**:

- Infinite Drive uses Bech32 prefixes like **`infinite`**, **`infinitevaloper`**, **`infinitevalcons`**.
- **Do not** hardcode “looks-right” Bech32 strings by swapping the prefix (e.g. taking a valid `cosmosvaloper...` and replacing the prefix with `infinitevaloper...`). Bech32 includes a checksum, so changing the HRP without recomputing it produces an **invalid string** and errors like **`unknown address format`**.
- In Solidity tests, prefer deriving Bech32 strings from **canonical hex addresses** using the `Bech32I` precompile (`hexToBech32(...)`). This guarantees a valid checksum for the requested prefix.

**Important (denoms / governance / flakiness)**:

- This fork’s base denom is **`drop`**. Tests that include `Coin{denom, amount}` should use `drop` (or query params) to avoid CheckTx rejections.
- The gov precompile tx-flow suite may be **skipped** in environments where proposal submission doesn’t get mined (rather than making `make test-solidity` flaky).

For details and repo-specific conventions, see `tests/solidity/README.md`.

---

## ✅ Complete Tests

**Purpose**: Run all tests (unit + integration).

**What it tests**: Complete system

**When to use**: Before releases, after important changes, CI/CD

### Run All Tests

```bash
# Run all tests
make test-all
```

**What it does**:

- Runs unit tests
- Runs integration tests
- Runs additional tests

**Estimated time**: 15-30 minutes

---

## 📊 Tests with Coverage

**Purpose**: Run tests and generate code coverage report.

**What you get**: Report showing what percentage of code is covered by tests

**When to use**: To verify test quality, identify uncovered code

### Run Tests with Coverage

```bash
# Unit tests with coverage (runs all four blocks, then merges into coverage.txt)
make test-unit-cover
```

**What it does**:

- Builds **`test-unit-cover-merge`**, whose prerequisites are the four blocks below; with default **`make`** they run **sequentially**, with **`make -j4 test-unit-cover`** (or higher) they can run **in parallel** locally. Each block uses **`-race`**, **`-tags=test`**, and **`-timeout=15m`**
- Merges block profiles into **`coverage.txt`** (same path filter as before), then prints **`go tool cover -func`**

**Estimated time**: 10-20 minutes

### Granular coverage blocks (`test-unit-cover`)

**Why (fork)**: Splitting coverage isolates **which tree** failed or hit the global test timeout (e.g. **`infinited/tests/integration`** vs root **`tests/integration/*`** vs core packages). GitHub Actions runs one matrix leg per block; Codecov receives **one upload per block** with **`flags`**: `evm-core`, `evm-integration`, `infinited-core`, `infinited-integration` (see [`.github/workflows/test.yml`](../../../.github/workflows/test.yml)).

| Make target | Scope |
|-------------|--------|
| `make test-unit-cover-evm-core` | Root module **`github.com/cosmos/evm/...`** excluding **`tests/integration`** |
| `make test-unit-cover-evm-integration` | Root **`tests/integration/...`** only |
| `make test-unit-cover-infinited-core` | Submodule **`infinited/`** excluding **`tests/integration`** |
| `make test-unit-cover-infinited-integration` | **`infinited/tests/integration/...`** only |
| `make test-unit-cover-merge` | Merges `coverage_*.txt` → **`coverage.txt`** (requires all four block outputs) |

Intermediate files: `coverage_evm_core.txt`, `coverage_evm_integration.txt`, `coverage_infinited_core.txt`, `coverage_infinited_integration.txt` (gitignored). **`COVERPKG_INFINITED`** scopes **`infinited`** blocks to the submodule module list.

**CI / branch protection**: After this split, the **Tests** workflow exposes **four check rows** (matrix). If you use required status checks, add **each** matrix permutation GitHub shows (names depend on the job + matrix labels), or use a single aggregate job later if you prefer one gate.

**Maintenance record**: [fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md](../../fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md) — *Estabilidad CI (tests Go)*; operational CI table: [guides/infrastructure/CI_CD.md](../infrastructure/CI_CD.md).

**Upstream merges:** New or changed tests are classified **automatically** by path into one of the four blocks (see `PACKAGES_*` in the root `Makefile`). When merging [cosmos/evm](https://github.com/cosmos/evm), use the diff checklist and edge cases (new module layout, `test.yml` conflicts) in [MERGE_STRATEGIES.md — §3.1](../../fork-maintenance/MERGE_STRATEGIES.md#31-tests-y-cobertura-en-bloques-tras-traer-upstream).

### View Coverage Report

```bash
# View report in terminal
go tool cover -func=coverage.txt

# View HTML report (opens in browser)
go tool cover -html=coverage.txt
```

### Mempool Krakatoa tests under test-unit-cover

Krakatoa mempool tests run under the **`test-unit-cover-evm-core`** block (root module, no `tests/integration` path): **`go test -race`** with **`-coverpkg`** set to the whole root module list. That pass is slower and more sensitive to timing than non-race unit runs.

Krakatoa mempool tests under `mempool/` use **`mempool.AllowUnsafeSyncInsert`** inside `setupKrakatoaMempoolWithAccounts` so EVM inserts wait for `LegacyPool.Add`’s synchronous promotion path (see comments on `AllowUnsafeSyncInsert` in `mempool/mempool.go` and `LegacyPool.Add` in `mempool/txpool/legacypool/legacypool.go`). That removes most insert/`Sync` flakes; **`TestKrakatoaMempool_ReapNewBlock`** still uses **`require.Eventually`** after a simulated new block bumps the account nonce, because demotion of the stale pending tx can lag behind a single `Sync()` under **`-race`** during that coverage block.

Fork maintenance note: [UPSTREAM_DIVERGENCE_RECORD.md](../../fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md) — *Estabilidad CI (tests Go)*.

---

## 🔍 Code Validation

**Purpose**: Validate that customizations are correctly implemented.

**Script**: `scripts/validate_customizations.sh`

**What it validates**:

- ✅ Token configuration (denoms, chain ID)
- ✅ Custom genesis functions
- ✅ Bech32 prefixes
- ✅ Upstream compliance

**Usage**:

```bash
# Validate customizations
./scripts/validate_customizations.sh
```

**When to use**:

- After making changes
- Before commit
- During merges with upstream

**More information**: Node/script checks live in [SCRIPTS.md](SCRIPTS.md); grouped flows in [VALIDATION.md](../testing/VALIDATION.md).

---

## 🐛 Troubleshooting

### Tests Fail

**Problem**: Some tests fail

**Solutions**:

1. **Verify no processes are running**:

   ```bash
   # Verify infinited processes
   ps aux | grep infinited
   
   # Kill processes if necessary
   pkill infinited
   ```

2. **Clean and recompile**:

   ```bash
   rm -rf build/
   make install
   ```

3. **Run tests again**:

   ```bash
   make test-unit
   ```

### Tests Very Slow

**Causes**:

- First run (downloads dependencies)
- Slow system
- Many tests

**Solutions**:

- First time: It's normal, may take longer
- Run specific tests instead of all
- Close other applications

### Coverage Not Generated

**Problem**: `coverage.txt` is not created

**Solution**:

```bash
# Make sure you run the correct command
make test-unit-cover

# Verify it was created
ls -la coverage.txt
```

---

## 📚 More Information

- **[VALIDATION.md](../testing/VALIDATION.md)** — Validation workflows
- **[SCRIPTS.md](SCRIPTS.md)** — Script reference (e.g. node health)
- **[BUILDING.md](BUILDING.md)** - Compilation guide
- **[fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md](../../fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md)** - Upstream divergence record

---

## 🔗 Quick Reference

| Need | Command | Time |
|------|---------|------|
| Quick tests | `make test-unit` | 5-15 min |
| Complete tests | `make test-all` | 15-30 min |
| Coverage (merged) | `make test-unit-cover` | 10-20 min |
| Coverage (one block) | `make test-unit-cover-evm-core` (etc.) | varies |
| Validate code | `./scripts/validate_customizations.sh` | <1 min |
