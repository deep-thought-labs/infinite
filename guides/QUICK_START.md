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

## 🚀 Start Local Node (Optional)

If you want to test the complete node with a local blockchain:

```bash
# Compile + configure + start local node
./local_node.sh
```

**What it does**:
- Compiles the binary (if not already compiled)
- Creates local blockchain configuration
- Initializes genesis with test accounts
- Starts the node with all services

**Useful options**:
```bash
# If already compiled, skip compilation (faster)
./local_node.sh --no-install

# See all options
./local_node.sh --help
```

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
| `./local_node.sh` | Compiles + starts node | Complete testing |
| `make test-unit` | Runs unit tests | Verify changes |
| `infinited version` | Shows version | Verify installation |

## ⚠️ Important Notes

1. **First compilation**: May take several minutes while downloading dependencies
2. **PATH**: Make sure `$HOME/go/bin` is in your PATH to use `infinited` directly
3. **Disk space**: You need at least 10GB free for compilation and dependencies

## 🆘 Need Help?

- **Compilation error**: See [reference/TROUBLESHOOTING.md](reference/TROUBLESHOOTING.md)
- **More compilation details**: See [development/BUILDING.md](development/BUILDING.md)
- **Advanced configuration**: See [README.md](README.md) for complete index
