# Quick Start - Infinite Drive

> **Developer Entry Point** - Start here if you want to compile and test Infinite Drive locally.

## ⚡ Quick Start (3 Steps)

### 1. Verify Prerequisites

**Option A: Automatic Verification (Recommended)**

```bash
# Script that automatically verifies all prerequisites
./scripts/check_build_prerequisites.sh
```

This script verifies:
- ✅ Docker installed and running
- ✅ Go installed (correct version)
- ✅ Make, Git installed
- ✅ Available disk space

**Option B: Manual Verification**

Make sure you have installed:

```bash
# Verify Go (required: 1.21+)
go version

# Verify jq (required for scripts)
jq --version
```

**If you don't have them installed:**
- **Go**: [Go Installation](https://go.dev/doc/install)
- **jq**: 
  - macOS: `brew install jq`
  - Linux: `sudo apt-get install jq` or `sudo yum install jq`

### 2. Compile the Binary

```bash
# Compile and install infinited
make install
```

**What it does**: Compiles the `infinited` binary and installs it to `$HOME/go/bin/infinited`

**Estimated time**: 2-5 minutes (first time, downloads dependencies)

### 3. Verify Installation

```bash
# Verify it was installed correctly
infinited version

# You should see something like:
# infinite
# infinited version 0.1.9-...
```

## 🚀 Run a Node

To run a node, you have two options:

### Option 1: Using Drive (Recommended)

The easiest way to run a node is using **[Drive](https://github.com/deep-thought-labs/drive)**, the infrastructure management client:

**For Mainnet:**
```bash
# 1. Clone Drive repository
git clone https://github.com/deep-thought-labs/drive.git
cd drive

# 2. Navigate to mainnet service directory
cd services/node0-infinite

# 3. Start the container
./drive.sh up -d

# 4. Initialize the node (first time only)
./drive.sh node-ui
# Or via command line (simplified syntax):
./drive.sh node-init

# 5. Start the node
./drive.sh node-start
```

**For Testnet:**
```bash
# Same steps, but use testnet service directory
cd drive/services/node1-infinite-testnet
./drive.sh up -d
./drive.sh node-ui
```

**Key Points:**
- Use `./drive.sh` for all commands (automatically handles permissions and detects service name)
- **Simplified syntax:** `./drive.sh node-start` (no need to specify `exec` or service name)
- The `node-init` command automatically downloads the official genesis file from the configured URL
- See [README.md](../README.md) for complete instructions

> **Note:** The simplified syntax (`./drive.sh node-start`) is available from Drive v0.1.12+. For earlier versions, use the complete syntax: `./drive.sh exec infinite node-start`

### Option 2: Direct Installation

For direct installation from source:

```bash
# 1. Clone the repository
git clone https://github.com/deep-thought-labs/infinite.git
cd infinite

# 2. Compile the binary
make install

# 3. Initialize the node
infinited init my-node --chain-id infinite_421018-1 --home ~/.infinited

# 4. Obtain the official genesis file from URL
curl -o ~/.infinited/config/genesis.json \
  https://assets.infinitedrive.xyz/mainnet/genesis.json

# 5. Validate the genesis file
infinited genesis validate-genesis --home ~/.infinited

# 6. Start the node
infinited start --home ~/.infinited
```

See [README.md](../README.md) for more details.

## 📚 Next Steps

### For Development
- **[development/BUILDING.md](development/BUILDING.md)** - Complete compilation guide
- **[development/DEVELOPMENT.md](development/DEVELOPMENT.md)** - Detailed development guide

### For Testing
- **[testing/VALIDATION.md](testing/VALIDATION.md)** - Validation scripts and health checks
- **[development/TESTING.md](development/TESTING.md)** - Unit and integration tests

### For Production
- **[deployment/PRODUCTION.md](deployment/PRODUCTION.md)** - Production deployment
- **[deployment/VALIDATORS.md](deployment/VALIDATORS.md)** - Validator configuration

### For Releases
- **[infrastructure/RELEASES.md](infrastructure/RELEASES.md)** - Create releases with GitHub Actions

### Having Issues?
- **[reference/TROUBLESHOOTING.md](reference/TROUBLESHOOTING.md)** - Common problem solutions

## 🔧 Quick Reference Commands

| Command | What It Does | When to Use |
|---------|--------------|-------------|
| `make install` | Compiles and installs binary | Local development |
| `make build` | Only compiles (doesn't install) | Compilation testing |
| `make test-unit` | Runs unit tests | Verify changes |
| `infinited version` | Shows version | Verify installation |
| `./drive.sh node-start` | Starts node using Drive | Running a node |

## ⚠️ Important Notes

1. **First compilation**: May take several minutes while downloading dependencies
2. **PATH**: Make sure `$HOME/go/bin` is in your PATH to use `infinited` directly
3. **Disk space**: You need at least 10GB free for compilation and dependencies

## 🆘 Need Help?

- **Compilation error**: See [reference/TROUBLESHOOTING.md](reference/TROUBLESHOOTING.md)
- **More compilation details**: See [development/BUILDING.md](development/BUILDING.md)
- **Advanced configuration**: See [README.md](README.md) for complete index
