# Development Guide - Infinite Drive

Guide for developers working on Infinite Drive code.

## 📋 Table of Contents

- [Environment Setup](#environment-setup)
- [Development Workflow](#development-workflow)
- [Project Structure](#project-structure)
- [Making Changes](#making-changes)
- [Testing During Development](#testing-during-development)
- [Customization Validation](#customization-validation)

## ⚙️ Environment setup

Toolchain versions, prerequisite checks, PATH, and install location are documented once in **[BUILDING.md](BUILDING.md)** (requirements and Workflow 1).

---

## 🔄 Development Workflow

### 1. Get the Code

```bash
# Clone repository
git clone https://github.com/deep-thought-labs/infinite.git
cd infinite

# Or if you already have it, update
git pull origin main
```

### 2. Compile

```bash
# Compile and install
make install

# Verify
infinited version
```

### 3. Make Changes

Edit the files you need. See [Project Structure](#project-structure) to understand where everything is.

### 4. Validate Changes

```bash
# Validate customizations
./scripts/validate_customizations.sh

# Compile to verify there are no errors
make install

# Run tests
make test-unit
```

### 5. Commit and Push

```bash
# See changes
git status
git diff

# Add changes
git add .

# Commit
git commit -m "Description of changes"

# Push
git push origin your-branch
```

---

## 📁 Project Structure

### Main Directories

```
infinite/
├── infinited/              # Main application
│   ├── app.go             # App configuration
│   ├── genesis.go          # Custom genesis functions
│   ├── cmd/infinited/      # Main command
│   └── config/             # Configuration (bech32, etc.)
├── x/                      # Cosmos SDK modules
│   ├── vm/                 # EVM module
│   ├── erc20/              # ERC20 module
│   └── feemarket/          # Fee Market module
├── testutil/               # Test utilities
│   └── constants/          # Constants (denoms, chain IDs)
├── scripts/                # Utility scripts
├── docs/guides/            # Developer guides (this documentation tree)
└── Makefile               # Build commands
```

### Key Files for Customizations

| File | What It Contains |
|------|------------------|
| `x/vm/types/params.go` | DefaultEVMDenom, DefaultEVMChainID |
| `testutil/constants/constants.go` | ExampleAttoDenom, ChainsCoinInfo |
| `infinited/config/bech32.go` | Bech32Prefix ("infinite") |
| `infinited/genesis.go` | Custom genesis functions |
| `infinited/app.go` | DefaultGenesis() that applies customizations |

**More information**: See [UPSTREAM_DIVERGENCE_RECORD.md](../../fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md)

---

## ✏️ Making Changes

### Customization Changes

If you make changes to customizations (tokens, chain IDs, bech32):

1. **Make the change** in the code
2. **Validate**:

   ```bash
   ./scripts/validate_customizations.sh
   ```

3. **Compile**:

   ```bash
   make install
   ```

4. **Test** (if possible):

   ```bash
   # Start a node (Drive, release binary, or source — see README *Run a Node*), then:
   ./scripts/validate_token_config.sh
   ```

### Functional Code Changes

If you make changes to code logic:

1. **Make the change**
2. **Compile**:

   ```bash
   make install
   ```

3. **Run tests**:

   ```bash
   make test-unit
   ```

4. **Validate customizations** (to ensure they weren't broken):

   ```bash
   ./scripts/validate_customizations.sh
   ```

---

## 🧪 Testing During Development

### Quick Tests

```bash
# Unit tests (quick)
make test-unit

# Tests for a specific package
cd x/vm/types
go test -v
```

### Complete Tests

```bash
# All tests
make test-all

# Tests with coverage
make test-unit-cover
```

**More information**: See [development/TESTING.md](TESTING.md)

---

## ✅ Customization validation

Script behavior and checks: **[SCRIPTS.md](SCRIPTS.md#2-validate_customizationssh)**. When to run it with other steps: **[VALIDATION.md](../testing/VALIDATION.md)**.

---

## 🔍 Debugging

### View Node Logs

If you have a node running:

```bash
# View logs in real time
tail -f ~/.infinited/logs/infinited.log

# Or if running in terminal
# Logs appear directly in output
```

### Compilation Debug

```bash
# Compile with debug information
make build

# See what flags are used
make build  # Shows BUILD_FLAGS in output
```

### Verify Configuration

```bash
# View node configuration
cat ~/.infinited/config/app.toml
cat ~/.infinited/config/config.toml
cat ~/.infinited/config/genesis.json
```

---

## 📚 More Information

- **[QUICK_START.md](../QUICK_START.md)** - Quick start
- **[BUILDING.md](BUILDING.md)** - Compilation guide
- **[TESTING.md](TESTING.md)** - Testing guide
- **[SCRIPTS.md](SCRIPTS.md)** — Per-script reference
- **[VALIDATION.md](../testing/VALIDATION.md)** — Validation workflows
- **[fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md](../../fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md)** - Upstream divergence record
- **[fork-maintenance/README.md](../../fork-maintenance/README.md)** - Merge playbook, verification, templates, merge logs

---

## 🔗 Quick Reference

| Action | Command | When to Use |
|--------|---------|-------------|
| Compile | `make install` | After changes |
| Validate | `./scripts/validate_customizations.sh` | Before commit |
| Tests | `make test-unit` | Verify changes |
| Start node | README *Run a Node*: [Drive](https://github.com/deep-thought-labs/drive) / [latest binary](https://github.com/deep-thought-labs/infinite/releases/latest) / source | Test changes |
