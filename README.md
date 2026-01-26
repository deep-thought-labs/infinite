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

## Tokenomics – Pool Allocation (Executive Summary)

**Total Supply (Initial):** `100,000,200 Improbability [42]`**  
- **Circulating (Liquid):** `200 Improbability [42]`** – Distributed at genesis for bootstrap and visibility  
- **Locked (Vesting):** `100,000,000 Improbability [42]`** – Released gradually over **42 years**, controlled by on-chain DAO  

**Breakdown:**
- The **200 liquid tokens** enable immediate network operation (100 for validators, 100 for tokenomics pools)
- The **100,000,000 locked tokens** are held in vesting accounts and unlock linearly over 42 years
- **Total at genesis:** 100,000,200 tokens (200 liquid + 100,000,000 locked)

**Sole Controller:** On-chain DAO from block 1, with lab oversight on development operations  
**Inflation:** Dynamic, target-bonded, and governance-adjustable

| **Pool** | **ModuleAccount** | **% of Supply** | **Tokens Locked** | **Operational Mandate** |
|----------|-------------------|-----------------|-------------------|--------------------------|
| **A** | `strategic_delegation` | 40% | 40,000,000 Improbability [42] | Never spent — only delegated to validators |
| **B** | `security_rewards` | 25% | 25,000,000 Improbability [42] | Validator + staker rewards |
| **C** | `perpetual_rd` | 15% | 15,000,000 Improbability [42] | Institutional funding (Deep Thought Labs) |
| **D** | `fish_bootstrap` | 10% | 10,000,000 Improbability [42] | Seed liquidity pools |
| **E** | `privacy_resistance` | 7% | 7,000,000 Improbability [42] | ZK, anti-censura R&D |
| **F** | `community_growth` | 3% | 3,000,000 Improbability [42] | Grants, education, integrations |
| **TOTAL** | - | **100%** | **100,000,000 Improbability [42]** | - |

> **Note:** The table above shows the **locked tokens** (100,000,000) that will unlock over 42 years. These are separate from the **200 liquid tokens** distributed at genesis (100 for validators + 100 for pools visibility).

> **Note**: All pools are implemented as ModuleAccounts in genesis. For detailed configuration and technical implementation, see [guides/configuration/MODULE_ACCOUNTS.md](guides/configuration/MODULE_ACCOUNTS.md).

---

### **Genesis Bootstrap (200 [42])**

At **Block 1**, exactly **200 Improbability [42]** are minted as liquid tokens and distributed as follows:

#### **100 [42] → Initial Validator Set**
- **Purpose:** Bootstrap the network and enable immediate block production
- **Distribution:** Held by the initial validator, who distributes them pro-rata to the **first set of validators** as they join the chain
- **Function:** As new validators join, they receive tokens from this pool to enable staking and block production
- **From this seed, inflation begins**, and the network self-sustains

#### **100 [42] → Tokenomics Pools (ModuleAccounts)**
- **Purpose:** Provide **visual clarity and educational understanding** of the tokenomics distribution
- **Distribution:** Split proportionally across all 6 pools according to their tokenomics percentages:
  - **Pool A (40%):** `40 [42]` → `strategic_delegation`
  - **Pool B (25%):** `25 [42]` → `security_rewards`
  - **Pool C (15%):** `15 [42]` → `perpetual_rd`
  - **Pool D (10%):** `10 [42]` → `fish_bootstrap`
  - **Pool E (7%):** `7 [42]` → `privacy_resistance`
  - **Pool F (3%):** `3 [42]` → `community_growth`
- **Why 100 tokens?** This makes it **intuitively easy to understand** the distribution:
  - When you see `40 [42]` in the genesis file or on-chain, you immediately understand it represents **40% of the total allocation**
  - The numbers directly correspond to percentages, making the tokenomics **visually transparent** from day one
  - Anyone can verify the distribution by simply looking at the balances: 40 + 25 + 15 + 10 + 7 + 3 = 100

> **Note:** These 100 tokens in ModuleAccounts are **governed by the DAO** and represent the initial liquid allocation visible at chain launch.  
> **Total Supply Breakdown:**  
> - **200 tokens liquid** (100 validators + 100 pools)  
> - **100,000,000 tokens locked** in vesting (unlock over 42 years)  
> - **Total: 100,000,200 tokens** at genesis

---

### **Dynamic Inflation Model (Target-Bonded with Gradual Adjustment)**

#### **Initial Configuration**
- **Initial Inflation:** Starts at `10%` annually on circulating supply  
- **Target Stake Ratio:** `67%` of total liquid supply staked (`goal_bonded`)  
- **Inflation Bounds (Initial):**  
  - **Minimum:** `7%` annually (`inflation_min`)  
  - **Maximum:** `20%` annually (`inflation_max`)  
- **Automatic Adjustment (Per Block):**  
  - Inflation adjusts **each block** based on actual bonded ratio vs. target  
  - If **bonded ratio < 67%** → inflation **increases** (up to max `20%`)  
  - If **bonded ratio = 67%** → inflation **stays constant**  
  - If **bonded ratio > 67%** → inflation **decreases** (down to min `7%`)  
  - Rate of change: `13%` per year maximum (`inflation_rate_change`)  
  - Formula: `inflationRateChange = (1 - bondedRatio/goalBonded) × inflationRateChange`  

#### **Long-Term Strategy: Gradual Parameter Reduction (Bitcoin-Style)**

To maintain a **controlled and limited supply** while ensuring network security, we implement a **3-phase gradual adjustment strategy** via DAO governance:

**Phase 1: Initial Growth (Years 1-5)**
- **Initial Inflation:** `10%` annually
- **Bounds:** `7%` min, `20%` max
- **Objective:** Maximum incentives for validators, network security, and organic growth
- **Expected Supply Growth:** ~240K - 1.5M tokens/year (as circulating supply grows from 2.4M to 11.9M)

**Phase 2: Controlled Growth (Years 5-15) - Via Governance**
- **Proposed Reductions (via DAO proposals):**
  - **Year 5:** Reduce `inflation_min` to `5%`, `inflation_max` to `15%`
  - **Year 10:** Reduce `inflation_min` to `3%`, `inflation_max` to `10%`
- **Objective:** Control supply growth while maintaining sufficient validator incentives
- **Expected Supply Growth:** ~950K - 2.9M tokens/year (as circulating supply grows from 11.9M to 23.8M)

**Phase 3: Mature Network (Years 15+) - Via Governance**
- **Proposed Reductions (via DAO proposals):**
  - **Year 15:** Reduce `inflation_min` to `3%`, `inflation_max` to `7%`
  - **Years 20+:** Maintain minimum sustainable inflation (3-5% min, 7-10% max)
- **Objective:** Limited and controlled supply (Bitcoin-style), minimal sustainable incentives
- **Expected Supply Growth:** ~1.4M - 7M tokens/year (as circulating supply grows from 47.6M to 100M)

**Total Expected Supply (42 years with gradual adjustment):** ~150-200M tokens  
**vs without adjustment (10% constant):** ~300M+ tokens

#### **Governance Mechanism**

Parameter adjustments are implemented via **on-chain parameter change proposals**:
- **Proposal Type:** `MsgUpdateParams` for mint module
- **Decision Criteria:** Based on circulating supply, staking ratio, network health metrics
- **Frequency:** Every 2-5 years, aligned with network maturity phases
- **Flexibility:** DAO can adjust timing and values based on real-world conditions

**Governance Override:** DAO can adjust at any time via **on-chain parameter change proposals**:  
  - `inflation_min` and `inflation_max` (bounds)  
  - `goal_bonded` (target stake ratio)  
  - `inflation_rate_change` (adjustment sensitivity)

> **Note:** This strategy ensures a **gradual and limited supply** (Bitcoin-style) while maintaining network security through adequate validator incentives. The automatic per-block adjustment responds to staking ratios, while the gradual parameter reduction (via governance) controls long-term supply growth.

---

### **Market Birth & Liquidity Path**
1. **Block 1:** `200 [42]` liquid:
   - `100 [42]` → initial validator (distributes to first validator set)
   - `100 [42]` → tokenomics pools (40+25+15+10+7+3, visible on-chain)
2. **Staking begins** → validators start producing blocks  
3. **Inflation kicks in** → new tokens minted per block  
4. **Year 1+:** Pools unlock gradually over 42 years → delegated/spent via DAO governance  
5. **Validators control market release** → Bitcoin-style organic liquidity

---

### **Perpetual Commitment**
- **All pools unlock gradually over 42 years**, aligned with operational horizons  
- **DAO governs destination of every unlock and inflation stream**  
- **Lab retains operational control over Pool C (perpetual_rd)**  
- **Each pool’s ModuleAccounts are continuously refilled via block fees + inflation**  
- **No token enters circulation without validator custody first**  
- **Security, alignment, and long-term resilience from genesis**

---

### **Technical Implementation**

All tokenomics pools are implemented as **ModuleAccounts** in genesis:

- **Configuration**: JSON files in `scripts/genesis-configs/` (mainnet, testnet, creative)
- **Automation**: `setup_module_accounts.sh` script creates ModuleAccounts automatically
- **Documentation**: Complete technical details in [guides/configuration/MODULE_ACCOUNTS.md](guides/configuration/MODULE_ACCOUNTS.md)
- **Genesis Creation**: See [guides/configuration/GENESIS.md](guides/configuration/GENESIS.md) for step-by-step guide

---

## 🚀 Quick Start for Developers

**Want to compile and test Infinite Drive locally?**

👉 **[guides/QUICK_START.md](guides/QUICK_START.md)** - Developer entry point

This guide shows you the different available workflows:
- **All-in-One Workflow**: Compile + configure + start node (`./local_node.sh`)
- **Compilation Workflow**: Just compile the binary (`make install`)
- **Testing Workflow**: Validate everything works
- **Release Workflow**: Create releases with GitHub Actions

**📚 More documentation**: See [guides/README.md](guides/README.md) for complete index

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

[Full Guide →](./guides/QUICK_START.md)

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
- **Docs**: [Getting Started with Infinite Drive](./guides/QUICK_START.md)
- **Client**: [Drive](https://github.com/deep-thought-labs/drive) - Infrastructure management client
- **License**: [Apache 2.0](./LICENSE)
- [NOTICE & Attributions](./NOTICE)

---

*Part of Project 42. Building infrastructure for the cypherpunk nation. A [Deep Thought Labs](https://deep-thought.computer) project.*