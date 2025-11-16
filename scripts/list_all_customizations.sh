#!/bin/bash
#
# Copyright (c) 2025 Deep Thought Labs
# All rights reserved.
#
# This file is part of the Infinite Drive blockchain tooling.
#
# Purpose: List all files that differ from upstream repository.
#          Helps identify all customizations for documentation.
#
# Usage: ./scripts/list_all_customizations.sh [upstream-branch]
#        Default: upstream/main (original repository)
#        Example: ./scripts/list_all_customizations.sh upstream/main
#

set -e

# Determine upstream reference
UPSTREAM_REF="${1:-upstream/main}"

# Validate upstream reference exists
if ! git show-ref --verify --quiet "refs/remotes/$UPSTREAM_REF" 2>/dev/null && \
   ! git show-ref --verify --quiet "refs/heads/$UPSTREAM_REF" 2>/dev/null; then
    echo "❌ Error: Upstream reference '$UPSTREAM_REF' not found"
    echo ""
    echo "Available remotes:"
    git remote -v | awk '{print $1}' | sort -u
    echo ""
    echo "Available upstream branches:"
    git ls-remote --heads upstream 2>/dev/null | sed 's/.*refs\/heads\///' | head -5 || echo "  (none found)"
    echo ""
    echo "Usage: $0 [upstream-branch]"
    echo "Example: $0 upstream/main"
    exit 1
fi

echo "📋 All Customizations vs upstream repository"
echo "============================================"
echo "Comparing against: $UPSTREAM_REF"
echo ""

# Added files
echo "## Added Files (A)"
echo "---"
git diff --name-status $UPSTREAM_REF...HEAD | grep "^A" | awk '{print $2}' | sort
echo ""

# Modified files
echo "## Modified Files (M)"
echo "---"
git diff --name-status $UPSTREAM_REF...HEAD | grep "^M" | awk '{print $2}' | sort
echo ""

# Deleted files (in upstream, kept in fork)
echo "## Files Deleted in Upstream (kept in fork)"
echo "---"
git diff --name-status $UPSTREAM_REF...HEAD | grep "^D" | awk '{print $2}' | sort
echo ""

# Summary
ADDED=$(git diff --name-status $UPSTREAM_REF...HEAD | grep -c "^A" || echo "0")
MODIFIED=$(git diff --name-status $UPSTREAM_REF...HEAD | grep -c "^M" || echo "0")
DELETED=$(git diff --name-status $UPSTREAM_REF...HEAD | grep -c "^D" || echo "0")

echo "## Summary"
echo "---"
echo "Added: $ADDED files"
echo "Modified: $MODIFIED files"
echo "Deleted in upstream (kept): $DELETED files"
echo "Total differences: $((ADDED + MODIFIED + DELETED)) files"

