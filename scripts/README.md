# Scripts - Infinite Drive

> **Copyright (c) 2025 Deep Thought Labs**  
> Internal tooling and automation scripts for Infinite Drive.

## 📚 Documentation

**All scripts documentation is now centralized in the main guides:**

👉 **[guides/development/SCRIPTS.md](../guides/development/SCRIPTS.md)** - Complete scripts guide

This guide includes:
- All available scripts
- When to use each script
- What each script does
- How to identify Deep Thought Labs scripts
- Workflow examples

## 🔍 Identifying Deep Thought Labs Scripts

All scripts developed by Deep Thought Labs have this header:

```bash
#!/bin/bash
#
# Copyright (c) 2025 Deep Thought Labs
# All rights reserved.
#
# This file is part of the Infinite Drive blockchain tooling.
```

**To find all Deep Thought Labs scripts:**

```bash
# Find all Deep Thought Labs scripts
grep -l "Deep Thought Labs" scripts/*.sh
```

## 📋 Quick Reference

| Script | Purpose | Documentation |
|-------|---------|---------------|
| `check_build_prerequisites.sh` | Verify build prerequisites | [SCRIPTS.md](../guides/development/SCRIPTS.md#1-check_build_prerequisitessh) |
| `validate_customizations.sh` | Validate customizations | [SCRIPTS.md](../guides/development/SCRIPTS.md#2-validate_customizationssh) |
| `validate_token_config.sh` | Validate token configuration | [SCRIPTS.md](../guides/development/SCRIPTS.md#3-validate_token_configsh) |
| `infinite_health_check.sh` | Node health check | [SCRIPTS.md](../guides/development/SCRIPTS.md#4-infinite_health_checksh) |
| `list_all_customizations.sh` | List all customizations | [SCRIPTS.md](../guides/development/SCRIPTS.md#5-list_all_customizationssh) |

**For complete documentation, see [guides/development/SCRIPTS.md](../guides/development/SCRIPTS.md)**

