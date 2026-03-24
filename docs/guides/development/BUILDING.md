# Building Guide - Infinite Drive

Complete guide for building Infinite Drive in different scenarios, with clearly differentiated workflows.

## 📋 Table of Contents

- [Build Workflows](#build-workflows)
- [Workflow 1: Development Build](#workflow-1-development-build)
- [Workflow 2: Testing Build](#workflow-2-testing-build)
- [Workflow 3: Release Builds (Local)](#workflow-3-release-builds-local)
- [Workflow 4: GitHub Actions Releases (Reference)](#workflow-4-github-actions-releases-reference)
- [Requirements by Build Type](#requirements-by-build-type)
- [Detailed Commands](#detailed-commands)
- [Troubleshooting](#troubleshooting)

## 🎯 Build Workflows

Choose the workflow based on your objective:

| Objective | Workflow | Command | Time |
|-----------|----------|---------|------|
| **Daily development** | Development Build | `make install` | 2-5 min |
| **Verify it compiles** | Testing Build | `make build` | 2-5 min |
| **Release test (local)** | Release Build (Local) | `make release-dry-run-linux` | 10-15 min |
| **Published binaries** | GitHub Actions (remote) | Push tag `v*.*.*` (maintainers) | CI-managed |

---

## 🔨 Workflow 1: Development Build

**Purpose**: Compile and install the binary for daily development use.

**What you get**:

- ✅ Compiled `infinited` binary
- ✅ Installed in `$HOME/go/bin/infinited`
- ✅ Available in PATH (if configured)
- ✅ Ready to use in commands

**When to use**: Active development, need binary available, local testing

### Requirements

- **Go**: versión en `go.mod` en la raíz (actualmente **1.25.8**)
- **Space**: ~5GB for dependencies

### Automatic Prerequisites Verification

**Recommended**: Use the verification script before building:

```bash
# Automatically verify all prerequisites
./scripts/check_build_prerequisites.sh
```

This script verifies:

- ✅ Docker installed and running
- ✅ Go installed (correct version according to go.mod)
- ✅ Make, Git installed
- ✅ Available disk space
- ✅ Docker permissions (Linux)

**More information**: See [development/SCRIPTS.md](SCRIPTS.md)

### Steps

#### 1. Verify Go

**Option A: Automatic Verification** (Recommended)

```bash
./scripts/check_build_prerequisites.sh
```

**Option B: Manual Verification**

```bash
go version
# Debe coincidir con la directiva `go` de go.mod
```

#### 2. Compile and Install

```bash
# From project root
make install
```

**What this command does**:

1. Downloads all Go dependencies (first time)
2. Compiles the `infinited` binary
3. Installs it to `$HOME/go/bin/infinited`

**Estimated time**:

- First time: 5-10 minutes (downloads dependencies)
- Subsequent times: 2-5 minutes

#### 3. Verify Installation

```bash
# Verify it was installed
infinited version

# You should see:
# infinite
# infinited version 0.1.9-...
```

### Binary Location

The binary is installed in: `$HOME/go/bin/infinited`

**To use it directly**, make sure `$HOME/go/bin` is in your PATH:

```bash
# Add to PATH (add to ~/.bashrc or ~/.zshrc)
export PATH=$PATH:$HOME/go/bin

# Verify
which infinited
```

### Cleanup (If You Need to Recompile)

```bash
# Remove installed binary
rm -f $HOME/go/bin/infinited

# Clean build directory
rm -rf build/

# Recompile
make install
```

---

## 🚀 Workflow 1.5: All-in-One Local Node Script

**Purpose**: Complete automated setup: compile, configure, and start a local testnet node.

**Scripted path**: the repository root script **`./local_node.sh`** runs `make install` (unless `--no-install`), initializes chain data under `~/.infinited`, provisions dev keys/accounts, adjusts genesis (via `jq`), and starts the node. Use **`./local_node.sh --help`** for flags.

**What you get** (same goals if you follow the manual README flow instead of the script):

- ✅ Compiled `infinited` binary (if not already compiled)
- ✅ Local blockchain configuration initialized
- ✅ Default genesis from `infinited init` (or official `genesis.json` if you follow the README replace step)
- ✅ Test accounts created and funded
- ✅ Node started and ready to use

**When to use**: Complete testing, development with full node, integration testing

### Running a node

Three ways to get a running node are described **once** in the [repository README.md](../../README.md) (*Run a Node*):

1. **Drive** — [Drive repo](https://github.com/deep-thought-labs/drive) and [official docs](https://docs.infinitedrive.xyz/en) cover installation, `drive.sh`, and operations.
2. **Pre-built binary** — [latest GitHub release](https://github.com/deep-thought-labs/infinite/releases/latest), then init + official genesis + start (see README Option 2).
3. **Build from source** — `make install` from this repo, then the same init/genesis/start as the README (see README Option 3).

After **`make install`**, a typical mainnet-style sequence (Options 2 and 3) is:

```bash
infinited init my-node --chain-id infinite_421018-1 --home ~/.infinited

curl -fsSL -o ~/.infinited/config/genesis.json \
  https://assets.infinitedrive.xyz/mainnet/genesis.json

infinited genesis validate-genesis --home ~/.infinited

# P2P seed: always prefer the value from network-data.json (see Option B below)
infinited start \
  --chain-id infinite_421018-1 \
  --evm.evm-chain-id 421018 \
  --p2p.seeds fe304bbda1a243eb2bd30a4558923b39d04ca5eb@server-xenia88.infinitedrive.xyz:26656 \
  --home ~/.infinited
```

See [README.md](../../README.md) for the authoritative breakdown.

### Genesis produced by `infinited init` alone

After `infinited init`, the generated `genesis.json` is built from **`DefaultGenesis()`** in `infinited/app.go` and helpers in **`infinited/genesis.go`**. In summary:

- **Aligned with Infinite Drive identity** for core parameters: base denom **`drop`**, staking / mint / gov min deposits use that denom, EVM module gets **default precompiles** and sensible defaults.
- **ERC20 module**: default state suitable for local work; published network genesis files add production **token pairs** and full economics.
- **Published `genesis.json`** files from `assets.infinitedrive.xyz` add ModuleAccounts, vesting, and production tokenomics for each environment.

Use this `init` genesis for **private or local** development. **Joining mainnet, testnet, or creative** requires replacing `genesis.json` with the matching published file (see below).

### Option A — Local-only chain (no public network sync)

Keep the genesis from **`infinited init`**; skip replacing `genesis.json` with a download from `assets.infinitedrive.xyz`. The commands below use **mainnet’s official identifiers**: Cosmos `chain_id` `infinite_421018-1` and EVM chain ID `421018`, as in [mainnet `network-data.json`](https://assets.infinitedrive.xyz/mainnet/network-data.json). The chain runs from that **`init`** genesis file. For a **private** devnet with its own identifiers, choose a `chain-id` / `--evm.evm-chain-id` pair and use the same values in **`init`** and **`start`**.

```bash
infinited init my-node --chain-id infinite_421018-1 --home ~/.infinited
infinited genesis validate-genesis --home ~/.infinited
infinited start --chain-id infinite_421018-1 --evm.evm-chain-id 421018 --home ~/.infinited
```

### Option B — Join a public network (replace genesis)

Run **`infinited init` with the Cosmos `chain-id` of the network you join**, then **download** the matching official `genesis.json` (replacing the file produced by `init`). **Purpose** of each published genesis:

| Network | Cosmos `chain-id` | EVM chain ID | Official `genesis.json` | `network-data.json` (canonical metadata) | Human-readable index |
|---------|-------------------|--------------|-------------------------|------------------------------------------|------------------------|
| **Mainnet** | `infinite_421018-1` | `421018` | `https://assets.infinitedrive.xyz/mainnet/genesis.json` | [`…/mainnet/network-data.json`](https://assets.infinitedrive.xyz/mainnet/network-data.json) | [Mainnet assets](https://assets.infinitedrive.xyz/mainnet/) |
| **Testnet** | `infinite_421018001-1` | `421018001` | `https://assets.infinitedrive.xyz/testnet/genesis.json` | [`…/testnet/network-data.json`](https://assets.infinitedrive.xyz/testnet/network-data.json) | [Testnet assets](https://assets.infinitedrive.xyz/testnet/) |
| **Creative** | `infinite_421018002-1` | `421018002` | `https://assets.infinitedrive.xyz/creative/genesis.json` | [`…/creative/network-data.json`](https://assets.infinitedrive.xyz/creative/network-data.json) | [Creative assets](https://assets.infinitedrive.xyz/creative/) |

**Canonical source**: Each [`network-data.json`](https://assets.infinitedrive.xyz/mainnet/network-data.json) is the **live** reference for that environment. It includes the **genesis URL** (under `resources.genesis`), **P2P seed addresses** (under `endpoints.p2p`), RPC/EVM endpoints, and other identifiers. **Re-fetch this file whenever you deploy or document operational values** so you use current seeds and paths. The [JSON schema](https://assets.infinitedrive.xyz/references/NETWORK_DATA_JSON_SCHEMA) describes the structure.

**Resolve P2P seed at runtime** (example with [`jq`](https://jqlang.github.io/jq/); requires `curl` and `jq`):

```bash
P2P_SEED=$(curl -fsSL https://assets.infinitedrive.xyz/mainnet/network-data.json | jq -r '.endpoints.p2p[0].url')
# Then pass: --p2p.seeds "$P2P_SEED"
```

**Example (mainnet — replace + validate + start with sync)** — swap URLs and IDs for testnet or creative using the table; **seed strings below match `network-data.json` at last verification** and may change—prefer `jq` or the JSON above:

```bash
infinited init my-node --chain-id infinite_421018-1 --home ~/.infinited

curl -fsSL -o ~/.infinited/config/genesis.json \
  https://assets.infinitedrive.xyz/mainnet/genesis.json

infinited genesis validate-genesis --home ~/.infinited

infinited start \
  --chain-id infinite_421018-1 \
  --evm.evm-chain-id 421018 \
  --p2p.seeds fe304bbda1a243eb2bd30a4558923b39d04ca5eb@server-xenia88.infinitedrive.xyz:26656 \
  --home ~/.infinited
```

| Network | Example `--p2p.seeds` (from `network-data.json`; verify live) |
|---------|----------------------------------------------------------------|
| **Mainnet** | `fe304bbda1a243eb2bd30a4558923b39d04ca5eb@server-xenia88.infinitedrive.xyz:26656` |
| **Testnet** | `ed3a45ee1ad114830afe6de7dc90c61f893c04da@server-xenia88.infinitedrive.xyz:26666` |
| **Creative** | `e8e7b5f008a59e72ac624cde9607a90178e9cc14@server-xenia.infinitedrive.xyz:26676` |

You can set **`p2p.seeds`** in `~/.infinited/config/config.toml` instead of the flag. For more context on the network, see the **[official blockchain documentation](https://docs.infinitedrive.xyz/en/blockchain)**.

### Optional checks once the node is running

```bash
./scripts/validate_token_config.sh
./scripts/infinite_health_check.sh
```

**More information**:

- Validation workflows: [testing/VALIDATION.md](../testing/VALIDATION.md); per-script: [SCRIPTS.md](SCRIPTS.md)

---

## 🧪 Workflow 2: Testing Build

**Purpose**: Only compile the binary without installing it, useful for verifying it compiles correctly.

**What you get**:

- ✅ Compiled binary in `./build/infinited`
- ✅ Doesn't modify your PATH
- ✅ Useful for CI/CD and testing

**When to use**: Verify compilation, CI/CD, don't want to install

### Requirements

- **Go**: versión en `go.mod` en la raíz (actualmente **1.25.8**)

### Steps

#### 1. Compile

```bash
# From project root
make build
```

**What it does**:

1. Compiles the binary
2. Places it in `./build/infinited`
3. **Does NOT** install it to the system

**Estimated time**: 2-5 minutes

#### 2. Use the Binary

```bash
# Use directly from build/
./build/infinited version

# Or move it where you need it
cp ./build/infinited /desired/path/
```

### Build Variants

```bash
# Compile specifically for Linux
make build-linux

# Compile for specific platform
make build-cross-linux-amd64
make build-cross-linux-arm64
make build-cross-darwin-amd64
make build-cross-darwin-arm64
make build-cross-windows-amd64
```

---

## 🏗️ Workflow 3: Release Builds (Local)

**Purpose**: Test the release build process locally before creating an official release.

**What you get**:

- ✅ GoReleaser **Linux** binaries (**amd64** and **arm64**) in `./dist/` (see `.goreleaser.yml`)
- ✅ Files in `./dist/` ready for distribution
- ✅ **Does NOT** publish anything to GitHub

**When to use**: Before creating a release, verify the process works

### Requirements

- **Docker**: Installed and running
- **Go**: versión en `go.mod` en la raíz (actualmente **1.25.8**)
- **Time**: 10-30 minutes

### Verify Docker

```bash
# Verify Docker
docker --version
docker ps  # Should work without errors
```

### Quick Build (Linux Only)

**Command**: `make release-dry-run-linux`

**What it does**:

- Uses **`.goreleaser.linux-only.yml`** (same **Linux amd64 / arm64** targets as the default config, tuned for quicker local iteration)
- Creates files in `./dist/`
- **Does NOT** publish to GitHub

**Time**: 10-15 minutes

```bash
make release-dry-run-linux
```

### Full GoReleaser dry-run (same targets as CI)

**Command**: `make release-dry-run`

**What it does**:

- Uses **`.goreleaser.yml`** (the same config **GitHub Actions** uses on version tags)
- Compiles **Linux amd64** and **Linux arm64** only (`infinited-linux-amd64`, `infinited-linux-arm64`)
- Creates archives / `checksums.txt` under `./dist/`
- **Does NOT** publish to GitHub

**Time**: ~20-30 minutes (varies by machine; ARM64 cross-build may fail on some Mac hosts—see note below)

```bash
make release-dry-run
```

### Verify Results

```bash
# See what was created
ls -lh dist/

# You should see Linux binaries (names depend on archive templates), e.g.:
# - infinited-linux-amd64
# - infinited-linux-arm64
# - checksums.txt
```

**Note about Mac M1**: ARM64 builds may fail on Mac M1 with Docker emulation. This is expected. Builds work correctly in GitHub Actions.

**More information**: See [RELEASES.md](../infrastructure/RELEASES.md) for official releases.

---

## 🏷️ Workflow 4: GitHub Actions Releases (Reference)

**Purpose**: **Versioned release binaries** are produced by **automation** in this repository. **Pre-built artifacts**: [GitHub Releases](https://github.com/deep-thought-labs/infinite/releases/latest). **Local dry-runs** (`make release-dry-run*`) validate the same pipeline on your machine before tagging.

**What is configured**: [`.github/workflows/release.yml`](../../../.github/workflows/release.yml) runs **GoReleaser** when a **semantic version tag** matching `v*.*.*` is pushed (for example `v1.2.3`). Per **`.goreleaser.yml`**, it builds **Linux amd64 and arm64** artifacts, attaches them to a **GitHub Release**, and generates **checksums**. Maintainers can also trigger the workflow manually from the Actions UI (`workflow_dispatch`) for snapshot-style runs.

**Where to go next** (same split as in each guide’s intro):

| You want to… | Open |
|--------------|------|
| **Ship a version** (prepare branch, `v*.*.*` tag, push, verify release assets on GitHub) | **[infrastructure/RELEASES.md](../infrastructure/RELEASES.md)** |
| **Configure or debug CI** (Settings → Actions permissions, secrets, workflow logs, why a job fails) | **[infrastructure/CI_CD.md](../infrastructure/CI_CD.md)** |

---

## 📊 Requirements by Build Type

| Build Type | Go | Docker | jq | Time | Use |
|------------|-----|--------|-----|------|-----|
| `make install` | ✅ | ❌ | ❌ | 2-5 min | Development |
| `make build` | ✅ | ❌ | ❌ | 2-5 min | Testing |
| `make release-dry-run-linux` | ✅ | ✅ | ❌ | 10-15 min | Pre-release |
| `make release-dry-run` | ✅ | ✅ | ❌ | 20-30 min | Complete pre-release |

---

## 📝 Detailed Commands

### make install

**Description**: Compiles and installs the binary to your system.

**Result location**: `$HOME/go/bin/infinited`

**Usage**:

```bash
make install
infinited version
```

### make build

**Description**: Only compiles, doesn't install.

**Result location**: `./build/infinited`

**Usage**:

```bash
make build
./build/infinited version
```

### make build-linux

**Description**: Compiles for Linux (cross-compilation).

**Result location**: `./build/infinited`

**Usage**:

```bash
make build-linux
```

### Specific Cross-Compilation

```bash
# Linux AMD64
make build-cross-linux-amd64

# Linux ARM64
make build-cross-linux-arm64

# macOS Intel
make build-cross-darwin-amd64

# macOS Apple Silicon
make build-cross-darwin-arm64

# Windows AMD64
make build-cross-windows-amd64
```

**Note**: Cross-compilation may require additional tools depending on your system.

---

## 🐛 Troubleshooting

### Error: "command not found: infinited"

**Problem**: The binary is not in your PATH.

**Solution**:

```bash
# Verify it was installed
ls -la $HOME/go/bin/infinited

# Add to PATH (add to ~/.bashrc or ~/.zshrc)
export PATH=$PATH:$HOME/go/bin

# Reload shell
source ~/.bashrc  # or source ~/.zshrc
```

### Error: "go: cannot find main module"

**Problem**: You're not in the correct directory.

**Solution**:

```bash
# Make sure you're in the project root
cd /path/to/project/infinite

# Verify go.mod exists
ls go.mod
```

### CGO Compilation Error

**Problem**: Missing compilation tools.

**Solution**:

```bash
# macOS
xcode-select --install

# Linux (Ubuntu/Debian)
sudo apt-get install build-essential

# Linux (CentOS/RHEL)
sudo yum groupinstall "Development Tools"
```

### Build Very Slow

**Common causes**:

- First compilation (downloads dependencies) - Normal
- Low RAM available
- Slow CPU

**Solutions**:

- First time: It's normal, may take 5-10 minutes
- Close other applications consuming resources
- Consider using `make build` instead of `make install` if you only need to verify compilation

### Docker Doesn't Work for release-dry-run

**Problem**: Docker is not running or you don't have permissions.

**Solution**:

```bash
# Verify Docker
docker ps

# If it fails, start Docker
# macOS: Open Docker Desktop
# Linux: sudo systemctl start docker

# Verify permissions (Linux)
sudo usermod -aG docker $USER
# Log out and log back in
```

---

## 📚 More Information

- **[QUICK_START.md](../QUICK_START.md)** - Quick start
- **[RELEASES.md](../infrastructure/RELEASES.md)** - Procedure to publish a version (tag, push, verify release)
- **[CI_CD.md](../infrastructure/CI_CD.md)** - GitHub Actions settings, secrets, workflow troubleshooting
- **[TROUBLESHOOTING.md](../reference/TROUBLESHOOTING.md)** - More problem solutions

---

## 🔗 Quick Reference

| Need | Command | Time |
|------|---------|------|
| Compile for development | `make install` | 2-5 min |
| Only verify compilation | `make build` | 2-5 min |
| Release test (Linux) | `make release-dry-run-linux` | 10-15 min |
| Release test (complete) | `make release-dry-run` | 20-30 min |
