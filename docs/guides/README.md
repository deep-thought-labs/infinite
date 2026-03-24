# Infinite Drive Guides

Complete index of all Infinite Drive documentation, organized by category.

## 🚀 Entry Point

**New here?** Start here:

👉 **[QUICK_START.md](QUICK_START.md)** - Quick start for developers

This file is the **index**; each topic is explained once in the linked guide.

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
| **[development/SCRIPTS.md](development/SCRIPTS.md)** | **Canonical** reference for each `scripts/*.sh` | Look up what a script does |
| **[fork-maintenance/README.md](../fork-maintenance/README.md)** | Fork maintenance: divergence record, merge playbook, logs | Sync with cosmos/evm safely |

### 🧪 Testing and Validation

Guides for validating and testing the system.

| Guide | Description | When to Use |
|-------|-------------|-------------|
| **[testing/PROJECT_INTEGRITY_CHECKLIST.md](testing/PROJECT_INTEGRITY_CHECKLIST.md)** | **Canonical checklist** — all commands to validate the repo end-to-end | Before PR, after big changes, before release |
| **[testing/VALIDATION.md](testing/VALIDATION.md)** | Multi-step validation **workflows** (grouped commands) | Know what to run together and when |

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
| **[configuration/GENESIS.md](configuration/GENESIS.md)** | Creating or transforming genesis for a network (advanced) | New chain genesis, module accounts, vesting; deeper than BUILDING/README run-a-node flows |
| **[configuration/MODULE_ACCOUNTS.md](configuration/MODULE_ACCOUNTS.md)** | ModuleAccounts structure and configuration | Understand and configure tokenomics pools |
| **[configuration/VESTING_ACCOUNTS.md](configuration/VESTING_ACCOUNTS.md)** | Vesting accounts configuration | Configure accounts with locked tokens and gradual unlock |
| **[configuration/TOKEN_SUPPLY.md](configuration/TOKEN_SUPPLY.md)** | Understanding token creation in Genesis | Learn how tokens are created and supply/balance relationship |

### 🏭 Infrastructure

Guides about infrastructure, CI/CD, and tools.

| Guide | Description | When to Use |
|-------|-------------|-------------|
| **[infrastructure/RELEASES.md](infrastructure/RELEASES.md)** | **Ship a version**: git steps, `v*.*.*` tag, push, verify GitHub Release + binaries | Publish a new version |
| **[infrastructure/CI_CD.md](infrastructure/CI_CD.md)** | **Wire and debug Actions**: Settings → permissions, Secrets, workflow logs, runner errors | First-time repo CI setup; any workflow failing for config/permissions |
| **[infrastructure/DOCKER.md](infrastructure/DOCKER.md)** | Docker usage in builds | Understand Docker builds |

### 📖 Reference

Reference documentation and troubleshooting.

| Guide | Description | When to Use |
|-------|-------------|-------------|
| **[reference/TROUBLESHOOTING.md](reference/TROUBLESHOOTING.md)** | Problem solving | When something doesn't work |

---

## 🗺️ Navigation Map

### By Objective

**I want to...**

- **...orient myself**: [QUICK_START.md](QUICK_START.md) → links to the right guide
- **...compile**: [development/BUILDING.md](development/BUILDING.md)
- **...run a node** (Drive / binary / source): [README.md](../../README.md#run-a-node) in the repository root
- **...validate the whole repo**: [testing/PROJECT_INTEGRITY_CHECKLIST.md](testing/PROJECT_INTEGRITY_CHECKLIST.md); **workflows**: [testing/VALIDATION.md](testing/VALIDATION.md); **per script**: [development/SCRIPTS.md](development/SCRIPTS.md)
- **...check a running node**: [development/SCRIPTS.md](development/SCRIPTS.md#5-infinite_health_checksh) (`infinite_health_check.sh`)
- **...publish a version (tag, verify release)**: [infrastructure/RELEASES.md](infrastructure/RELEASES.md)
- **...fix Actions permissions, secrets, or workflow errors**: [infrastructure/CI_CD.md](infrastructure/CI_CD.md)
- **...deploy to production**: [deployment/PRODUCTION.md](deployment/PRODUCTION.md)
- **...author or deeply customize genesis** (new networks, module accounts): [configuration/GENESIS.md](configuration/GENESIS.md)
- **...understand ModuleAccounts**: [configuration/MODULE_ACCOUNTS.md](configuration/MODULE_ACCOUNTS.md)
- **...configure vesting accounts**: [configuration/VESTING_ACCOUNTS.md](configuration/VESTING_ACCOUNTS.md)
- **...resolve a problem**: [reference/TROUBLESHOOTING.md](reference/TROUBLESHOOTING.md)
- **...merge upstream (cosmos/evm)**: [fork-maintenance/README.md](../fork-maintenance/README.md) → [PLAYBOOK.md](../fork-maintenance/PLAYBOOK.md)

### By Experience Level

**I am...**

- **New**: Start with [QUICK_START.md](QUICK_START.md)
- **Active developer**: [development/DEVELOPMENT.md](development/DEVELOPMENT.md); upstream sync: [fork-maintenance/README.md](../fork-maintenance/README.md)
- **DevOps/Infrastructure**: ship a release → [infrastructure/RELEASES.md](infrastructure/RELEASES.md); Actions settings / secrets / failing workflows → [infrastructure/CI_CD.md](infrastructure/CI_CD.md)
- **Validator**: [deployment/VALIDATORS.md](deployment/VALIDATORS.md)

---

## 📝 Documentation Notes

### Structure

- **Single source of truth**: avoid duplicating the same commands in multiple files; prefer links (e.g. scripts → [SCRIPTS.md](development/SCRIPTS.md), validation sequences → [VALIDATION.md](testing/VALIDATION.md), releases → [RELEASES.md](infrastructure/RELEASES.md)).
- **Main entry** at repo root: [QUICK_START.md](QUICK_START.md); **index**: this file.

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
| Full integrity checklist | [testing/PROJECT_INTEGRITY_CHECKLIST.md](testing/PROJECT_INTEGRITY_CHECKLIST.md) |
| Validation workflows | [testing/VALIDATION.md](testing/VALIDATION.md) |
| Release | [infrastructure/RELEASES.md](infrastructure/RELEASES.md) |
| Problems | [reference/TROUBLESHOOTING.md](reference/TROUBLESHOOTING.md) |
| Upstream merge | [fork-maintenance/README.md](../fork-maintenance/README.md) |

---

## 📚 External Documentation

- **[fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md](../fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md)** - Upstream divergence record (this fork)
- **[fork-maintenance/README.md](../fork-maintenance/README.md)** - Merge playbook, verification, logs
- **[README.md](../../README.md)** - Project overview
- **[scripts/README.md](../../scripts/README.md)** - Scripts documentation (if exists)
