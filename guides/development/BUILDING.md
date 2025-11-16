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
