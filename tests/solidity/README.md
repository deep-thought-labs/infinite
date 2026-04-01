## Solidity tests (`tests/solidity`)

This directory contains Solidity/EVM tests that run against a locally spawned node and exercise:

- JSON-RPC
- EVM precompiles (staking, distribution, gov, bech32, etc.)

### Run

From the repo root:

```bash
make test-solidity
```

This target:

- builds and installs the node binary
- installs JS deps under `tests/solidity/`
- spawns a local node via `local_node.sh`
- runs the test suites (Hardhat + Truffle) via `yarn test --network cosmos`

### Bech32 prefixes and why we derive addresses

Infinite Drive uses Bech32 prefixes:

- account: `infinite`
- validator operator: `infinitevaloper`
- validator consensus: `infinitevalcons`

Bech32 strings include a checksum. **Changing the prefix (HRP) changes the checksum**.

That means a string produced by “just swapping the prefix” (e.g. taking a valid `cosmosvaloper...` address and replacing the prefix with `infinitevaloper...`) becomes **invalid** and will fail decoding, typically surfacing as errors like:

- `unknown address format: infinitevaloper...`

To avoid this class of failures, the Solidity suites should:

- keep **canonical hex addresses** as the source of truth, and
- derive Bech32 strings at runtime via the `Bech32I` precompile:
  - `hexToBech32(<hex>, "infinite")`
  - `hexToBech32(<hex>, "infinitevaloper")`

This guarantees the checksum matches the prefix used by the chain.

### Notes for stability (CI/local)

- **Denom**: the canonical base denom on this fork is **`drop`**. When a Solidity test submits a tx that includes `Coin{denom, amount}`, prefer `drop` (or query chain params when applicable) to avoid transactions being rejected at CheckTx and never landing in a block.
- **Gov precompile suite**: proposal submission can be environment-dependent (e.g. min deposit / CheckTx semantics). The harness treats this as a **non-critical** suite and may **skip** the gov tx-flow tests if `submitProposal` does not get mined (to avoid flaking `make test-solidity`).
