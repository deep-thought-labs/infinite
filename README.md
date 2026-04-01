# Infinite Improbability Drive

> *"Governments of the Industrial World, you weary giants of flesh and steel — we are building the infrastructure you cannot control."*

**Project 42** — A cypherpunk nation in cyberspace. Powered by improbability.

**🌐 [infinitedrive.xyz](https://infinitedrive.xyz)** | **📚 [Official Documentation](https://docs.infinitedrive.xyz/en)** | **🔬 [Deep Thought Labs](https://deep-thought.computer)**

<div align="center">
  <img src="assets/dontpanic-space.jpg" alt="Don't Panic - Infinite Improbability Drive" width="600" style="max-width: 100%; height: auto; border-radius: 8px; margin: 2rem 0;" />
</div>

---

## Infinite Improbability Drive

Infinite Improbability Drive is **operational infrastructure** — the cryptographic backbone of our digital nation. Built with native EVM (Solidity) compatibility, full IBC protocol support, sovereign decentralized DNS, a truly decentralized P2P file system, and multi-chain bridges to Bitcoin, Ethereum, and Cosmos.

It is designed with **no single point of failure** and runs on infinite nodes, delivering true sovereignty, interoperability, and resilience for the cypherpunk nation in cyberspace.

### The Heart of the Drive: Improbability [42]

**Network Identity**  

- **Chain Name**: `infinite`
- **Cosmos Chain ID**: `infinite_421018-1`
- **EVM Chain ID**: `421018`
- **Bech32 Prefix**: `infinite`

**Native Token**  
The native token is called **Improbability** with the symbol **`42`**.  
Yes — the famous 42 from *The Hitchhiker’s Guide to the Galaxy*: the answer (and the question).

**Unit of Measurement**  
To keep things human and fun, we measure the token in **cups** (cups of Improbability). The smallest unit is called a **drop**.

- **1 cup** = 1 Improbability [42]  
- **1 cup** = 1 taza de improbabilidad  
- **1 cup** = 10¹⁸ drop

**In practice**  
When someone says “10 cups,” they simply mean 10 Improbability [42]. It’s memorable, approachable, and carries the spirit of the project.

> *Each cup of Improbability is the fuel that powers the Infinite Improbability Drive. Without improbability, there is no Drive.*

---

### The Infinite Improbability Drive: A Philosophical Foundation

> *"The Infinite Improbability Drive is a wonderful new method of crossing vast interstellar distances in a mere nothingth of a second, without all that tedious mucking about in hyperspace."* — The Hitchhiker’s Guide to the Galaxy

The **Infinite Improbability Drive** is the engine that powers this network — both literally and metaphorically. In Douglas Adams’ universe, the drive works by generating improbability: when it reaches infinite improbability, it passes through every conceivable point in every conceivable universe simultaneously. It doesn’t move through space in the conventional way; instead, it **warps probability itself**, turning the highly improbable into reality.

#### How It Works: Improbability as Fuel

The drive is created by connecting a Bambleweeny 57 Sub-Meson Brain to an atomic vector plotter suspended in a strong Brownian Motion producer — specifically, a **hot cup of tea**. In our network, each **cup of Improbability [42]** *is* that improbability — the raw fuel that bends probability and makes the impossible possible.

> *The drive runs on tea. Properly prepared.*  

**Improbability is the counterforce to entropy.**

While entropy pushes the universe toward disorder, improbability introduces the chance for order to emerge from chaos. In our blockchain, this manifests through decentralized consensus: each validator adds to the improbability field, each transaction becomes a certain event through cryptographic proof, and each block collapses infinite possibilities into a single, verifiable truth.

> *"The most exciting phrase to hear in science, the one that heralds new discoveries, is not 'Eureka!' but 'That's funny...'"* — Isaac Asimov

---

## 🚀 Run a Node

Choose one path. This section shows a **standard mainnet-style** `init` / genesis / `start` layout; **full** Drive and binary install and operations are in the linked documentation below.

### Option 1: Drive (recommended for operators and validators)

<details>
<summary>Click to expand</summary>

**[Drive](https://github.com/deep-thought-labs/drive)** is a **node management and operations tool** maintained by **Deep Thought Labs**. It packages **official, pre-built `infinited` binaries** and service definitions so you can run a node **without building this repository**.

- **Source code:** [github.com/deep-thought-labs/drive](https://github.com/deep-thought-labs/drive)
- **Official documentation:** [docs.infinitedrive.xyz](https://docs.infinitedrive.xyz/en) (guides for using Drive and the network)

Use those resources for installation, `drive.sh` commands, mainnet/testnet layouts, and UI flows.

</details>

### Option 2: Pre-built binary from GitHub Releases

<details>
<summary>Click to expand</summary>

Download the **latest published `infinited` binary** for your platform from the **current release** (GitHub redirects `/releases/latest` to the newest version):

- **[Latest release (download assets here)](https://github.com/deep-thought-labs/infinite/releases/latest)**
- [All releases](https://github.com/deep-thought-labs/infinite/releases) — browse older versions if needed

After you install the binary on your `PATH` (and mark it executable if required), run **`infinited init`** with the **Cosmos `chain-id`** of the network you intend to join, then **replace** `~/.infinited/config/genesis.json` with the published file for that network (the `curl` step overwrites what `init` generated). Pick one row:

| Network | Purpose | Cosmos `chain-id` | EVM chain ID | Official `genesis.json` |
|---------|---------|-------------------|--------------|-------------------------|
| **Mainnet** | Production | `infinite_421018-1` | `421018` | `https://assets.infinitedrive.xyz/mainnet/genesis.json` |
| **Testnet** | Public testing | `infinite_421018001-1` | `421018001` | `https://assets.infinitedrive.xyz/testnet/genesis.json` |
| **Creative** | Experimental | `infinite_421018002-1` | `421018002` | `https://assets.infinitedrive.xyz/creative/genesis.json` |

**Live metadata for each network** (genesis path, **P2P seeds**, RPC URLs, chain IDs): fetch the canonical **`network-data.json`** at any time so values stay current:

| Network | `network-data.json` | Index page |
|---------|---------------------|------------|
| **Mainnet** | [`https://assets.infinitedrive.xyz/mainnet/network-data.json`](https://assets.infinitedrive.xyz/mainnet/network-data.json) | [assets.infinitedrive.xyz/mainnet/](https://assets.infinitedrive.xyz/mainnet/) |
| **Testnet** | [`https://assets.infinitedrive.xyz/testnet/network-data.json`](https://assets.infinitedrive.xyz/testnet/network-data.json) | [assets.infinitedrive.xyz/testnet/](https://assets.infinitedrive.xyz/testnet/) |
| **Creative** | [`https://assets.infinitedrive.xyz/creative/network-data.json`](https://assets.infinitedrive.xyz/creative/network-data.json) | [assets.infinitedrive.xyz/creative/](https://assets.infinitedrive.xyz/creative/) |

**Example — join mainnet with P2P sync** (swap `chain-id`, `evm.evm-chain-id`, genesis URL, and `network-data.json` URL for testnet or creative using the tables above):

```bash
infinited init my-node --chain-id infinite_421018-1 --home ~/.infinited

curl -fsSL -o ~/.infinited/config/genesis.json \
  https://assets.infinitedrive.xyz/mainnet/genesis.json

infinited genesis validate-genesis --home ~/.infinited

# Prefer loading the seed from network-data.json (fresh value):
# P2P_SEED=$(curl -fsSL https://assets.infinitedrive.xyz/mainnet/network-data.json | jq -r '.endpoints.p2p[0].url')

infinited start \
  --chain-id infinite_421018-1 \
  --evm.evm-chain-id 421018 \
  --p2p.seeds fe304bbda1a243eb2bd30a4558923b39d04ca5eb@server-xenia88.infinitedrive.xyz:26656 \
  --home ~/.infinited
```

The `--p2p.seeds` value above matches **mainnet** `network-data.json` at last documentation update; **always confirm** with the live JSON or the `P2P_SEED` one-liner. Schema: [`NETWORK_DATA_JSON_SCHEMA`](https://assets.infinitedrive.xyz/references/NETWORK_DATA_JSON_SCHEMA). Additional context: [blockchain documentation](https://docs.infinitedrive.xyz/en/blockchain).

**Local-only** (no public sync): use `init` → `validate-genesis` → `start` with IDs you control and **do not** overwrite `genesis.json` from `assets.infinitedrive.xyz`. See [BUILDING.md — Running a node](docs/guides/development/BUILDING.md#running-a-node).

For genesis, ModuleAccounts, network parameters, and related topics, see the [blockchain documentation](https://docs.infinitedrive.xyz/en/blockchain).

</details>

### Option 3: Build from this repository

<details>
<summary>Click to expand</summary>

Use this when you **develop or verify the chain from source**: clone this repo, **verify build prerequisites**, compile, then run with the official genesis.

```bash
# 1. Clone the repository
git clone https://github.com/deep-thought-labs/infinite.git
cd infinite

# 2. Verify prerequisites (Go, Docker, Make, Git, jq, etc.)
./scripts/check_build_prerequisites.sh

# 3. Compile the binary
make install
# This installs infinited to $HOME/go/bin/infinited

# 4. Initialize the node (generates a dev-oriented genesis; see BUILDING.md)
infinited init my-node --chain-id infinite_421018-1 --home ~/.infinited

# 5. Replace genesis with the official file for your network (mainnet example — see table in Option 2)
curl -fsSL -o ~/.infinited/config/genesis.json \
  https://assets.infinitedrive.xyz/mainnet/genesis.json

# 6. Validate the genesis file
infinited genesis validate-genesis --home ~/.infinited

# 7. Start the node (match chain-id, EVM ID, and P2P seed to the network you chose)
infinited start \
  --chain-id infinite_421018-1 \
  --evm.evm-chain-id 421018 \
  --p2p.seeds fe304bbda1a243eb2bd30a4558923b39d04ca5eb@server-xenia88.infinitedrive.xyz:26656 \
  --home ~/.infinited
```

**Notes:**

- **Networks / P2P**: Same **mainnet / testnet / creative** tables and **`network-data.json`** sources as [Option 2](#option-2-pre-built-binary-from-github-releases) above. **Local-only** runs: [BUILDING.md — Running a node, Option A](docs/guides/development/BUILDING.md#option-a--local-only-chain-no-public-network-sync) (genesis from `init`, omit `--p2p.seeds`).
- Resolve anything `./scripts/check_build_prerequisites.sh` reports before `make install`. Full detail: [docs/guides/development/BUILDING.md](docs/guides/development/BUILDING.md) and [docs/guides/development/SCRIPTS.md](docs/guides/development/SCRIPTS.md).
- Ensure `$HOME/go/bin` is on your `PATH` after `make install`.
- Broader build and test workflows: [docs in this repository](docs/guides/README.md) and [official documentation](https://docs.infinitedrive.xyz/en).

</details>

---

## Cypherpunk Roots & Future

From the beginning, this project stands on the shoulders of visionaries:

- John Perry Barlow (1996): *"Cyberspace does not lie within your borders."*
- Eric Hughes (1993): *"Privacy is the power to selectively reveal oneself."*
- Satoshi Nakamoto (2008): *"Cryptographic proof instead of trust."*

In the quantum age we are entering, every private key becomes a personal Infinite Improbability Drive — a gateway to an entire universe of possibilities. One person, with one device and one key, can hold a sovereign world of identities, directions, and futures. This is true digital sovereignty: infinite realities, accessible to anyone, controlled by no one.

> **"We are creating a world that all may enter without privilege or prejudice accorded by race, economic power, military force, or station of birth."**  
> — John Perry Barlow, *A Declaration of the Independence of Cyberspace*

---

## Links

- **Project**: [infinitedrive.xyz](https://infinitedrive.xyz) | [@InfiniteDrive42](https://x.com/InfiniteDrive42)
- **Research laboratory**: [DeepThought.Computer](https://deep-thought.computer) | [@DeepThought_Lab](https://x.com/DeepThought_Lab)
- **Community**: [Telegram](https://t.me/+nt8ysid_-8VlMDVh)
- **Official documentation**: [docs.infinitedrive.xyz](https://docs.infinitedrive.xyz/en)
- **License**: [Apache 2.0](./LICENSE)
- [NOTICE & Attributions](./NOTICE)

---

*Project 42. Building infrastructure for the cypherpunk nation. A [Deep Thought Labs](https://deep-thought.computer) project.*
