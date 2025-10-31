#!/usr/bin/env bash
#
# Copyright (c) 2025 Deep Thought Labs
# All rights reserved.
#
# This file is part of the Infinite Drive blockchain tooling.
#
# Purpose: Verify all prerequisites required for building Infinite Drive binaries
#          Checks Docker, Go, Make, Git, and repository access
#
# Usage: ./scripts/check_build_prerequisites.sh
#
# Exit codes:
#   0 - All prerequisites met
#   1 - One or more prerequisites missing or misconfigured
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track if any checks fail
FAILED=0

echo -e "${BLUE}🔍 Checking prerequisites for Infinite Drive builds...${NC}"
echo ""

# Check Docker
echo -n "Docker installation: "
if docker --version >/dev/null 2>&1; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | tr -d ',')
    echo -e "${GREEN}✅ Installed (version $DOCKER_VERSION)${NC}"
else
    echo -e "${RED}❌ Missing${NC}"
    echo "   Install: https://docs.docker.com/get-docker/"
    FAILED=1
fi

# Check Docker running
echo -n "Docker running: "
if docker ps >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Running${NC}"
else
    echo -e "${RED}❌ Not running${NC}"
    echo "   Start Docker Desktop or run: sudo systemctl start docker"
    FAILED=1
fi

# Check Docker permissions (Linux)
if [ "$(uname)" != "Darwin" ] && [ "$(uname)" != "MINGW"* ]; then
    echo -n "Docker permissions: "
    if docker ps >/dev/null 2>&1; then
        echo -e "${GREEN}✅ User can run Docker${NC}"
    else
        echo -e "${YELLOW}⚠️  May need to add user to docker group${NC}"
        echo "   Run: sudo usermod -aG docker \$USER (then logout/login)"
    fi
fi

# Check Go
echo -n "Go installation: "
if go version >/dev/null 2>&1; then
    GO_VERSION=$(go version | awk '{print $3}')
    echo -e "${GREEN}✅ Installed (version $GO_VERSION)${NC}"
else
    echo -e "${RED}❌ Missing${NC}"
    echo "   Install: https://go.dev/dl/"
    FAILED=1
fi

# Check Go version matches go.mod
echo -n "Go version matches go.mod (1.25.0): "
if go version >/dev/null 2>&1; then
    if go version | grep -q "go1.25"; then
        echo -e "${GREEN}✅ Correct version${NC}"
    else
        echo -e "${YELLOW}⚠️  Version mismatch${NC}"
        echo "   Required: go1.25.0 (see go.mod)"
        echo "   Install: https://go.dev/dl/go1.25.0.linux-amd64.tar.gz"
    fi
else
    echo -e "${RED}❌ Cannot check (Go not installed)${NC}"
    FAILED=1
fi

# Check Go environment
echo -n "Go environment configured: "
if go env GOPATH >/dev/null 2>&1 && go env GOROOT >/dev/null 2>&1; then
    GOPATH=$(go env GOPATH)
    GOROOT=$(go env GOROOT)
    echo -e "${GREEN}✅ Configured${NC}"
    echo "   GOPATH: $GOPATH"
    echo "   GOROOT: $GOROOT"
else
    echo -e "${RED}❌ Not configured${NC}"
    echo "   Set GOPATH and GOROOT in your shell configuration"
    FAILED=1
fi

# Optional: Check cross-compilation toolchains (Linux AMD64 only)
if [ "$(uname)" = "Linux" ] && [ "$(uname -m)" = "x86_64" ]; then
    echo -n "Cross-compilation toolchains (for ARM64 builds): "
    if command -v aarch64-linux-gnu-gcc >/dev/null 2>&1 && command -v x86_64-linux-gnu-gcc >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Installed${NC}"
    else
        echo -e "${YELLOW}⚠️  Missing (optional for local ARM64 cross-compilation)${NC}"
        echo "   Install: sudo apt-get update && sudo apt-get install -y gcc-aarch64-linux-gnu gcc-x86-64-linux-gnu"
        echo "   Note: Required only for compiling ARM64 binaries from AMD64 host. Not needed for GitHub Actions."
    fi
fi

# Check Make
echo -n "Make installation: "
if make --version >/dev/null 2>&1; then
    MAKE_VERSION=$(make --version | head -n1 | awk '{print $3}')
    echo -e "${GREEN}✅ Installed (version $MAKE_VERSION)${NC}"
else
    echo -e "${RED}❌ Missing${NC}"
    echo "   Linux: sudo apt install build-essential"
    echo "   macOS: xcode-select --install"
    FAILED=1
fi

# Check Git
echo -n "Git installation: "
if git --version >/dev/null 2>&1; then
    GIT_VERSION=$(git --version | awk '{print $3}')
    echo -e "${GREEN}✅ Installed (version $GIT_VERSION)${NC}"
else
    echo -e "${RED}❌ Missing${NC}"
    echo "   Linux: sudo apt install git"
    echo "   macOS: brew install git"
    FAILED=1
fi

# Check if in repository
echo -n "In Infinite Drive repository: "
if git status >/dev/null 2>&1; then
    REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
    if [ -n "$REPO_ROOT" ]; then
        echo -e "${GREEN}✅ Yes${NC}"
        echo "   Repository: $REPO_ROOT"
    else
        echo -e "${YELLOW}⚠️  Not in git repository${NC}"
        echo "   Clone: git clone https://github.com/deep-thought-labs/infinite.git"
    fi
else
    echo -e "${YELLOW}⚠️  Not in git repository${NC}"
    echo "   Clone: git clone https://github.com/deep-thought-labs/infinite.git"
fi

# Check disk space (rough estimate)
echo -n "Available disk space: "
if command -v df >/dev/null 2>&1; then
    AVAILABLE_GB=$(df -BG . 2>/dev/null | tail -1 | awk '{print $4}' | sed 's/G//')
    if [ -n "$AVAILABLE_GB" ] && [ "$AVAILABLE_GB" -ge 10 ]; then
        echo -e "${GREEN}✅ Sufficient ($AVAILABLE_GB GB available)${NC}"
    elif [ -n "$AVAILABLE_GB" ]; then
        echo -e "${YELLOW}⚠️  Low space ($AVAILABLE_GB GB available, recommended: 20GB+)${NC}"
    else
        echo -e "${YELLOW}⚠️  Could not determine${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Could not check${NC}"
fi

echo ""
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All critical prerequisites are met!${NC}"
    echo ""
    echo "You can now proceed with builds:"
    echo "  - make release-dry-run-linux    # Quick Linux build test"
    echo "  - make release-dry-run         # Full platform test"
    exit 0
else
    echo -e "${RED}❌ Some prerequisites are missing or misconfigured${NC}"
    echo ""
    echo "Please install the missing components before proceeding."
    echo "See: guides/BUILDING_AND_RELEASES.md for detailed installation instructions"
    exit 1
fi

