# Building Guide - Infinite Drive

Complete guide for building Infinite Drive in different scenarios, with clearly differentiated workflows.

## 📋 Table of Contents

- [Build Workflows](#build-workflows)
- [Workflow 1: Development Build](#workflow-1-development-build)
- [Workflow 2: Testing Build](#workflow-2-testing-build)
- [Workflow 3: Release Builds (Local)](#workflow-3-release-builds-local)
- [Requirements by Build Type](#requirements-by-build-type)
- [Detailed Commands](#detailed-commands)
- [Troubleshooting](#troubleshooting)

## 🎯 Build Workflows

Choose the workflow based on your objective:

| Objective | Workflow | Command | Time |
|-----------|----------|---------|------|
| **Daily development** | Development Build | `make install` | 2-5 min |
| **Verify it compiles** | Testing Build | `make build` | 2-5 min |
| **Release test** | Release Build (Local) | `make release-dry-run-linux` | 10-15 min |

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

- **Go**: 1.21 or higher
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
# Should show: go version go1.21.x or higher
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

**What you get**:
- ✅ Compiled `infinited` binary (if not already compiled)
- ✅ Local blockchain configuration initialized
- ✅ Genesis file customized for Infinite Drive
- ✅ Test accounts created and funded
- ✅ Node started and ready to use

**When to use**: Complete testing, development with full node, integration testing

### Command

```bash
# Full setup and start
./local_node.sh

# Skip compilation (if already compiled)
./local_node.sh --no-install

# Overwrite existing data without prompt
./local_node.sh -y

# See all options
./local_node.sh --help
```

### What `local_node.sh` Does

The script performs a complete setup in this order:

1. **Compiles the binary** (unless `--no-install` is used)
2. **Initializes the chain** with `infinited init`
3. **Customizes the Genesis file** (see details below)
4. **Creates test accounts** (validator + dev0, dev1, dev2, dev3)
5. **Funds accounts** in genesis
6. **Finalizes genesis** (gentx, collect-gentxs, validate-genesis)
7. **Starts the node** with all APIs enabled

### Genesis File Customizations

The script automatically modifies the Genesis file to configure Infinite Drive correctly. Here's what it changes:

#### 1. Module Denominations

All modules are configured to use `"drop"` as the base denomination:

```bash
# Staking module
.app_state.staking.params.bond_denom = "drop"

# Mint module  
.app_state.mint.params.mint_denom = "drop"

# Governance module
.app_state.gov.params.min_deposit[0].denom = "drop"
.app_state.gov.params.expedited_min_deposit[0].denom = "drop"

# EVM module
.app_state.evm.params.evm_denom = "drop"
```

**Why**: Ensures all modules use the Infinite Drive base token (`drop`) instead of the Cosmos SDK default (`stake`). These values are also set in code (`infinited/genesis.go`), but the script ensures they're correctly applied in the Genesis JSON.

#### 2. Token Metadata

Adds complete token metadata for the Improbability (42) token:

```json
{
  "description": "Improbability Token — Project 42: Sovereign, Perpetual, DAO-Governed",
  "denom_units": [
    {"denom": "drop", "exponent": 0, "aliases": []},
    {"denom": "Improbability", "exponent": 18, "aliases": ["improbability"]}
  ],
  "base": "drop",
  "display": "Improbability",
  "name": "Improbability",
  "symbol": "42",
  "uri": "https://assets.infinitedrive.xyz/tokens/42/icon.png"
}
```

**Why**: Provides complete token information for wallets, explorers, and dApps to display the token correctly.

#### 3. EVM Precompiles

Enables all static precompiles for EVM compatibility:

```bash
.app_state.evm.params.active_static_precompiles = [
  "0x0000000000000000000000000000000000000100",  # ECRecover
  "0x0000000000000000000000000000000000000400",  # SHA256
  "0x0000000000000000000000000000000000000800",  # RIPEMD160
  "0x0000000000000000000000000000000000000801",  # Identity
  "0x0000000000000000000000000000000000000802",  # ModExp
  "0x0000000000000000000000000000000000000803",  # BN256Add
  "0x0000000000000000000000000000000000000804",  # BN256Mul
  "0x0000000000000000000000000000000000000805",  # BN256Pairing
  "0x0000000000000000000000000000000000000806",  # Blake2F
  "0x0000000000000000000000000000000000000807"   # PointEvaluation
]
```

**Why**: Enables all standard Ethereum precompiles for full EVM compatibility.

#### 4. ERC20 Native Token Pair

Configures the native token as an ERC20:

```bash
.app_state.erc20.native_precompiles = ["0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"]
.app_state.erc20.token_pairs = [{
  "contract_owner": 1,
  "erc20_address": "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
  "denom": "drop",
  "enabled": true
}]
```

**Why**: Allows the native `drop` token to be used as an ERC20 token in smart contracts.

#### 5. Consensus Parameters

Adjusts block gas limit for development:

```bash
.consensus.params.block.max_gas = "10000000"
```

**Why**: Sets a reasonable gas limit for local testing.

#### 6. Governance Periods (Development Only)

**⚠️ IMPORTANT**: These values are for **development only** and should **NOT** be used in production:

```bash
# Development: Fast periods for quick testing
max_deposit_period: "30s"        # (Production: "172800s" = 2 days)
voting_period: "30s"             # (Production: "172800s" = 2 days)
expedited_voting_period: "15s"   # (Production: "86400s" = 1 day)
```

**Why**: Allows quick testing of governance proposals without waiting days. **For production, use realistic periods** (see [configuration/GENESIS.md](../configuration/GENESIS.md)).

#### 7. Configuration File Optimizations

The script also optimizes `config.toml` and `app.toml` for development:

- **Faster block times**: Reduced consensus timeouts
- **All APIs enabled**: REST, gRPC, JSON-RPC, Tendermint RPC
- **Prometheus metrics**: Enabled for monitoring
- **Indexer enabled**: For transaction indexing

**Why**: Provides a complete development environment with all features accessible.

### Test Accounts

The script creates these accounts by default:

| Account | Address (EVM) | Address (Cosmos) | Balance |
|---------|---------------|------------------|---------|
| `mykey` (validator) | - | `cosmos1...` | 100,000,000,000,000,000,000,000,000 drop |
| `dev0` | `0xC6Fe5D33615a1C52c08018c47E8Bc53646A0E101` | `cosmos1cml96vmptgw99syqrrz8az79xer2pcgp84pdun` | 1,000,000,000,000,000,000,000 drop |
| `dev1` | `0x963EBDf2e1f8DB8707D05FC75bfeFFBa1B5BaC17` | `cosmos1jcltmuhplrdcwp7stlr4hlhlhgd4htqh3a79sq` | 1,000,000,000,000,000,000,000 drop |
| `dev2` | `0x40a0cb1C63e026A81B55EE1308586E21eec1eFa9` | `cosmos1gzsvk8rruqn2sx64acfsskrwy8hvrmafqkaze8` | 1,000,000,000,000,000,000,000 drop |
| `dev3` | `0x498B5AeC5D439b733dC2F58AB489783A23FB26dA` | `cosmos1fx944mzagwdhx0wz7k9tfztc8g3lkfk6rrgv6l` | 1,000,000,000,000,000,000,000 drop |

**Note**: The validator account (`mykey`) is automatically set up as the genesis validator.

### Verifying the Setup

After the node starts, you can verify the configuration:

```bash
# In another terminal, validate token configuration
./scripts/validate_token_config.sh

# Check node health
./scripts/infinite_health_check.sh

# Verify customizations
./scripts/validate_customizations.sh
```

**Expected results**:
- ✅ All denominations should be `"drop"`
- ✅ Token metadata should show Improbability (42)
- ✅ Chain ID should be `infinite_421018-1`
- ✅ EVM Chain ID should be `421018` (0x66c9a)

### Important Notes

1. **Data Location**: All data is stored in `$HOME/.infinited/`
2. **Overwriting**: Use `-y` flag to overwrite existing data, or `-n` to keep it
3. **Development Only**: The governance periods are set for quick testing. **Do not use these values in production**
4. **Code vs. Script**: The code (`infinited/genesis.go`) sets defaults, but `local_node.sh` ensures they're applied correctly in the Genesis JSON

**More information**:
- Genesis configuration: [configuration/GENESIS.md](../configuration/GENESIS.md)
- Validation scripts: [testing/VALIDATION.md](../testing/VALIDATION.md)

---

## 🧪 Workflow 2: Testing Build

**Purpose**: Only compile the binary without installing it, useful for verifying it compiles correctly.

**What you get**:
- ✅ Compiled binary in `./build/infinited`
- ✅ Doesn't modify your PATH
- ✅ Useful for CI/CD and testing

**When to use**: Verify compilation, CI/CD, don't want to install

### Requirements

- **Go**: 1.21 or higher

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
- ✅ Binaries compiled for multiple platforms
- ✅ Files in `./dist/` ready for distribution
- ✅ **Does NOT** publish anything to GitHub

**When to use**: Before creating a release, verify the process works

### Requirements

- **Docker**: Installed and running
- **Go**: 1.21 or higher
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
- Compiles for Linux AMD64 and ARM64
- Creates files in `./dist/`
- **Does NOT** publish to GitHub

**Time**: 10-15 minutes

```bash
make release-dry-run-linux
```

### Complete Build (All Platforms)

**Command**: `make release-dry-run`

**What it does**:
- Compiles for Linux, macOS, Windows
- Creates files in `./dist/`
- **Does NOT** publish to GitHub

**Time**: 20-30 minutes

```bash
make release-dry-run
```

### Verify Results

```bash
# See what was created
ls -lh dist/

# You should see:
# - infinited-linux-amd64
# - infinited-linux-arm64
# - infinited-darwin-amd64
# - infinited-darwin-arm64
# - infinited-windows-amd64.exe
# - checksums.txt
```

**Note about Mac M1**: ARM64 builds may fail on Mac M1 with Docker emulation. This is expected. Builds work correctly in GitHub Actions.

**More information**: See [guides/infrastructure/RELEASES.md](../infrastructure/RELEASES.md) for official releases.

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

- **[guides/QUICK_START.md](../QUICK_START.md)** - Quick start
- **[guides/infrastructure/RELEASES.md](../infrastructure/RELEASES.md)** - Official releases with GitHub Actions
- **[guides/reference/TROUBLESHOOTING.md](../reference/TROUBLESHOOTING.md)** - More problem solutions

---

## 🔗 Quick Reference

| Need | Command | Time |
|------|---------|------|
| Compile for development | `make install` | 2-5 min |
| Only verify compilation | `make build` | 2-5 min |
| Release test (Linux) | `make release-dry-run-linux` | 10-15 min |
| Release test (complete) | `make release-dry-run` | 20-30 min |
