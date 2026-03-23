# Infinite Drive Guides

Complete index of all Infinite Drive documentation, organized by category.

## 🚀 Entry Point

**New here?** Start here:

👉 **[QUICK_START.md](QUICK_START.md)** - Quick start for developers

This guide shows you the different available workflows and when to use each one.

---

## 📚 Guides by Category

### 🏗️ Development

Guides for developers working on the code.

| Guide | Description | When to Use |
|-------|-------------|-------------|
| **[QUICK_START.md](QUICK_START.md)** | ⭐ Entry point - Main workflows | First time, deciding what to do |
| **[development/BUILDING.md](development/BUILDING.md)** | Detailed compilation with differentiated workflows | Need to compile for different scenarios |
| **[development/DEVELOPMENT.md](development/DEVELOPMENT.md)** | Development guide | Active code development |
| **[development/TESTING.md](development/TESTING.md)** | Unit and integration tests | Run tests, validate code |
| **[development/SCRIPTS.md](development/SCRIPTS.md)** | Complete guide of useful scripts | Use validation and development scripts |
| **[fork-maintenance/README.md](../fork-maintenance/README.md)** | Fork maintenance: divergence record, merge playbook, logs | Sync with cosmos/evm safely |

### 🧪 Testing and Validation

Guides for validating and testing the system.

| Guide | Description | When to Use |
|-------|-------------|-------------|
| **[testing/VALIDATION.md](testing/VALIDATION.md)** | Validation scripts and health checks | Validate node, configuration, code |

### 🚀 Deployment

Guides for deploying Infinite Drive in production.

| Guide | Description | When to Use |
|-------|-------------|-------------|
| **[deployment/PRODUCTION.md](deployment/PRODUCTION.md)** | Production deployment | Deploy on real server |
| **[deployment/VALIDATORS.md](deployment/VALIDATORS.md)** | Validator configuration | Configure validators |

### ⚙️ Configuration

Guides for configuring specific aspects of the system.

| Guide | Description | When to Use |
|-------|-------------|-------------|
| **[configuration/GENESIS.md](configuration/GENESIS.md)** | Genesis configuration | Configure genesis for mainnet |
| **[configuration/MODULE_ACCOUNTS.md](configuration/MODULE_ACCOUNTS.md)** | ModuleAccounts structure and configuration | Understand and configure tokenomics pools |
| **[configuration/VESTING_ACCOUNTS.md](configuration/VESTING_ACCOUNTS.md)** | Vesting accounts configuration | Configure accounts with locked tokens and gradual unlock |
| **[configuration/TOKEN_SUPPLY.md](configuration/TOKEN_SUPPLY.md)** | Understanding token creation in Genesis | Learn how tokens are created and supply/balance relationship |

### 🏭 Infrastructure

Guides about infrastructure, CI/CD, and tools.

| Guide | Description | When to Use |
|-------|-------------|-------------|
| **[infrastructure/RELEASES.md](infrastructure/RELEASES.md)** | Create releases with GitHub Actions | Publish new version |
| **[infrastructure/CI_CD.md](infrastructure/CI_CD.md)** | CI/CD and GitHub Actions configuration | Configure workflows |
| **[infrastructure/DOCKER.md](infrastructure/DOCKER.md)** | Docker usage in builds | Understand Docker builds |
| **[infrastructure/HEALTH_CHECKS.md](infrastructure/HEALTH_CHECKS.md)** | Health check scripts | Monitor nodes |

### 📖 Reference

Reference documentation and troubleshooting.

| Guide | Description | When to Use |
|-------|-------------|-------------|
| **[reference/TROUBLESHOOTING.md](reference/TROUBLESHOOTING.md)** | Problem solving | When something doesn't work |

---

## 🗺️ Navigation Map

### By Objective

**I want to...**

- **...compile and test quickly**: [QUICK_START.md](QUICK_START.md) → All-in-One Workflow
- **...just compile the binary**: [QUICK_START.md](QUICK_START.md) → Simple Compilation Workflow
- **...validate everything works**: [testing/VALIDATION.md](testing/VALIDATION.md)
- **...create a release**: [infrastructure/RELEASES.md](infrastructure/RELEASES.md)
- **...deploy to production**: [deployment/PRODUCTION.md](deployment/PRODUCTION.md)
- **...configure genesis**: [configuration/GENESIS.md](configuration/GENESIS.md)
- **...understand ModuleAccounts**: [configuration/MODULE_ACCOUNTS.md](configuration/MODULE_ACCOUNTS.md)
- **...configure vesting accounts**: [configuration/VESTING_ACCOUNTS.md](configuration/VESTING_ACCOUNTS.md)
- **...resolve a problem**: [reference/TROUBLESHOOTING.md](reference/TROUBLESHOOTING.md)
- **...merge upstream (cosmos/evm)**: [fork-maintenance/README.md](../fork-maintenance/README.md) → [PLAYBOOK.md](../fork-maintenance/PLAYBOOK.md)

### By Experience Level

**I am...**

- **New**: Start with [QUICK_START.md](QUICK_START.md)
- **Active developer**: [development/DEVELOPMENT.md](development/DEVELOPMENT.md); upstream sync: [fork-maintenance/README.md](../fork-maintenance/README.md)
- **DevOps/Infrastructure**: [infrastructure/RELEASES.md](infrastructure/RELEASES.md) and [infrastructure/CI_CD.md](infrastructure/CI_CD.md)
- **Validator**: [deployment/VALIDATORS.md](deployment/VALIDATORS.md)

---

## 📝 Documentation Notes

### Structure

- **Main guides** are in the root of `docs/guides/` (this folder)
- **Specialized guides** are in subfolders by category
- **Each guide** is focused on a specific objective
- **Differentiated workflows** - each guide clearly explains different scenarios

### Conventions

- **Commands** are in code blocks with explanation
- **Purpose** of each command is clearly explained
- **Requirements** are listed at the start of each section
- **Troubleshooting** is at the end of each guide

### Updates

This documentation is updated when:

- New features are added
- Workflows change
- Common problems are identified

If you find outdated information, please open an issue or PR.

---

## 🔗 Quick Links

| Need | Go to |
|------|-------|
| Start | [QUICK_START.md](QUICK_START.md) |
| Compile | [development/BUILDING.md](development/BUILDING.md) |
| Useful scripts | [development/SCRIPTS.md](development/SCRIPTS.md) |
| Validate | [testing/VALIDATION.md](testing/VALIDATION.md) |
| Release | [infrastructure/RELEASES.md](infrastructure/RELEASES.md) |
| Problems | [reference/TROUBLESHOOTING.md](reference/TROUBLESHOOTING.md) |
| Upstream merge | [fork-maintenance/README.md](../fork-maintenance/README.md) |

---

## 📚 External Documentation

- **[fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md](../fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md)** - Upstream divergence record (this fork)
- **[fork-maintenance/README.md](../fork-maintenance/README.md)** - Merge playbook, verification, logs
- **[README.md](../../README.md)** - Project overview
- **[scripts/README.md](../../scripts/README.md)** - Scripts documentation (if exists)
