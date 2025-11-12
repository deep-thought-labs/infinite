# Infinite Improbability Drive

> *"Governments of the Industrial World, you weary giants of flesh and steel — we are building the infrastructure you cannot control."*

**Part of Infinite Drive** — A cypherpunk nation in cyberspace. Powered by improbability.

> Infinite Drive is the complete ecosystem: **Infinite Improbability Drive** and **Drive**, the infrastructure management client. Part of **Project 42**. Developed by [Deep Thought Labs](https://deep-thought.computer).



---

## The Network

| Feature | Status |
|-------|--------|
| EVM Native (Solidity) | ✅ Native |
| IBC Protocol | ✅ Native |
| Decentralized DNS | ✅ Sovereign |
| P2P File System | ✅ Actually delivers |
| Multi-Chain Bridges | ✅ Bitcoin, Ethereum, Cosmos |
| No Single Point of Failure | ✅ Infinite nodes |

---

## Infinite Improbability Drive

- **Chain Name**: `infinite`
- **Chain ID**: `infinite_421018-1`
- **Token**: Improbability (42)
- **1 42 = 10¹⁸ drop**
- **Bech32**: `infinite`

> *The drive runs on tea. Properly prepared.*

---

## Tokenomics – Rubro Allocation (Executive Summary)

**Total Supply (Initial):** `100,000,000 Improbability [42]`**  
**Initial Circulating Supply:** `100 Improbability [42]`** – **Dedicated exclusively to bootstrap the initial validator set**  
**Vesting:** Gradual linear unlocking over extended periods (tailored per rubro, e.g., 10–20 years for perpetual sustainability)**  
**Sole Controller:** On-chain DAO from block 1, with lab oversight on development operations  
**Inflation:** Dynamic, target-bonded, and governance-adjustable

| **Rubro** | **% of Supply** | **Tokens Locked** | **Annual Unlock (Approx.)** | **Operational Mandate** |
|----------|------------------|-------------------|-----------------------------|--------------------------|
| **A. Consensus & Network Security** | 50 % | 50,000,000 Improbability [42] | 5,000,000 Improbability [42] | Perpetual validator & staker rewards |
| **B. Distributed Infrastructure** | 25 % | 25,000,000 Improbability [42] | 2,500,000 Improbability [42] | P2P nodes, relays, storage, IBC |
| **C. Development & Evolution** | 18 % | 18,000,000 Improbability [42] | 1,800,000 Improbability [42] | Upgrades, audits, R&D |
| **D. Governance & Ecosystem** | 5 % | 5,000,000 Improbability [42] | 500,000 Improbability [42] | Technical grants, proposals, docs |
| **E. Continuity Reserve** | 2 % | 2,000,000 Improbability [42] | 200,000 Improbability [42] | Systemic emergencies, succession |

---

### **Genesis Bootstrap (100 [42])**
> **100 Improbability [42] are minted liquid at genesis.**  
> **Sole purpose:** Distributed pro-rata to the **initial validator set** to enable immediate block production and staking.  
> From this seed, **inflation begins**, and the network self-sustains.

---

### **Dynamic Inflation Model (Target-Bonded)**

- **Base Inflation:** Starts at `7%` annually on circulating supply  
- **Target Stake Ratio:** `67%` of total liquid supply staked  
- **Automatic Adjustment:**  
  - If **staking < 60%** → inflation **increases** (max `10%`)  
  - If **staking > 75%** → inflation **decreases** (min `3%`)  
  - Adjustment occurs **per epoch** (automated via on-chain logic)  
- **Governance Override:** DAO can adjust:  
  - Inflation bounds  
  - Target stake ratio  
  - Adjustment sensitivity  
  via **on-chain parameter change proposals**

---

### **Market Birth & Liquidity Path**
1. **Block 1:** `100 [42]` → initial validators → staking begins  
2. **Inflation kicks in** → new tokens minted per block  
3. **Year 1+:** Rubro A unlocks `5 M [42]/year` → delegated via DAO → validators  
4. **Validators control market release** → Bitcoin-style organic liquidity

---

### **Perpetual Commitment**
- **All rubros unlock gradually over decades**, aligned with operational horizons  
- **DAO governs destination of every unlock and inflation stream**  
- **Lab retains operational control over Rubro C (development)**  
- **Each rubro’s accounts are continuously refilled via block fees + inflation**  
- **No token enters circulation without validator custody first**  
- **Security, alignment, and long-term resilience from genesis**

---

## Run a Node

### Option 1: Using Drive (Recommended)

The easiest way to run a node is using **[Drive](https://github.com/deep-thought-labs/drive)**, the infrastructure management client for **Infinite Improbability Drive**:

```bash
git clone https://github.com/deep-thought-labs/drive.git
cd drive/services/infinite-mainnet
docker compose up -d
docker compose exec infinite-mainnet node-ui
```

Drive provides a graphical interface and simplified node management. [Learn more →](https://github.com/deep-thought-labs/drive)

### Option 2: Direct Installation

For direct installation from source:

```bash
git clone https://github.com/deep-thought-labs/infinite.git
cd infinite
./local_node.sh
```

[Full Guide →](./guides/GETTING_STARTED.md)

---

## Tech Stack

- **Cosmos SDK + EvmOS**
- **CometBFT**
- **IBC-Go**
- **EIP-1559 Fee Market**
- **EIP-712 Signing**
- **Custom Opcodes**

> Forward-compatible with Ethereum. Runs *every* valid contract. Adds features Ethereum doesn't have yet.

---

## Cypherpunk Roots

- Barlow (1996): *"Cyberspace does not lie within your borders."*
- Hughes (1993): *"Privacy is the power to selectively reveal oneself."*
- Satoshi (2008): *"Cryptographic proof instead of trust."*

> **"We are creating a world that all may enter without privilege or prejudice accorded by race, economic power, military force, or station of birth."**  
> — *John Perry Barlow, A Declaration of the Independence of Cyberspace*

---

## Community
- **Project**: [infinitedrive.xyz](https://infinitedrive.xyz)
- **Lab**: [Deep Thought Labs](https://deep-thought.computer) - Research laboratory developing Infinite Drive
- **X**: [@DeepThought_Lab](https://x.com/DeepThought_Lab)
- **Telegram**: [Deep Thought Labs](https://t.me/+nt8ysid_-8VlMDVh)
- **Docs**: [Getting Started with Infinite Drive](./guides/GETTING_STARTED.md)
- **Client**: [Drive](https://github.com/deep-thought-labs/drive) - Infrastructure management client
- **License**: [Apache 2.0](./LICENSE)
- [NOTICE & Attributions](./NOTICE)

---

*Part of Project 42. Building infrastructure for the cypherpunk nation. A [Deep Thought Labs](https://deep-thought.computer) project.*