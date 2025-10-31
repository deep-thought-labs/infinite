# Building and Releases

**Copyright (c) 2025 Deep Thought Labs**  
Comprehensive guide for building Infinite Drive binaries and managing releases.

---

## Table of Contents

1. [Prerequisites](#prerequisites) - Complete system requirements
2. [Overview](#overview)
3. [Build System Architecture](#build-system-architecture)
4. [Understanding Docker Build Configuration](#understanding-docker-build-configuration) - **Important: Read this first!**
5. [Local Development Builds](#local-development-builds)
6. [Production Releases](#production-releases)
7. [Understanding Build Limitations](#understanding-build-limitations)
8. [Troubleshooting](#troubleshooting)
9. [GitHub Actions Automated Releases](#github-actions-automated-releases)

---

## Prerequisites

**⚠️ IMPORTANT**: Before attempting to build Infinite Drive binaries, ensure all prerequisites are installed and properly configured.

### System Requirements

| Requirement | Minimum | Recommended | Notes |
|-------------|---------|-------------|-------|
| **RAM** | 4GB | 8GB+ | More RAM speeds up compilation |
| **Storage** | 10GB free | 20GB+ free | Docker images and build artifacts |
| **CPU** | 2 cores | 4+ cores | Multi-core significantly speeds up builds |
| **OS** | Linux/macOS/Windows+WSL2 | Ubuntu 22.04+ / macOS 12+ | Native Linux recommended |

### Required Software

#### 1. Docker (REQUIRED)

**What it is**: Containerization platform used for consistent cross-compilation environments.

**Why you need it**: GoReleaser uses Docker containers (`goreleaser-cross`) to build binaries for multiple platforms in isolated, reproducible environments.

**Installation**:

**Linux (Ubuntu/Debian)**:
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group (logout/login required)
sudo usermod -aG docker $USER

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker
```

**macOS**:
```bash
# Install Docker Desktop (recommended)
# Download from: https://www.docker.com/products/docker-desktop/

# Or install via Homebrew
brew install --cask docker

# Start Docker Desktop application
```

**Windows (WSL2)**:
```bash
# Install Docker Desktop for Windows
# Download from: https://www.docker.com/products/docker-desktop/

# Ensure WSL2 backend is enabled in Docker Desktop settings
```

**Verify Installation**:
```bash
# Check Docker is running
docker --version
# Should output: Docker version 24.x.x or similar

# Test Docker access (should run without sudo)
docker run hello-world
```

**Docker Configuration Requirements**:
- **Docker must be running**: `docker ps` should work without errors
- **User permissions**: Must be able to run Docker without `sudo` (Linux)
- **Docker resources** (macOS/Windows):
  - Recommended: 4GB+ RAM allocated to Docker
  - Recommended: 2+ CPU cores allocated
  - Configure in Docker Desktop → Settings → Resources

#### 2. Go Programming Language (REQUIRED)

**What it is**: Go compiler and toolchain for building the Infinite Drive binary.

**Why you need it**: Infinite Drive is written in Go and requires Go to compile, even when using Docker builds (for dependency resolution).

**Version Requirement**: **Go 1.25.0** (exact version specified in `go.mod`)

**Installation**:

**Linux (Ubuntu/Debian)**:
```bash
# Remove old Go version if exists
sudo apt remove golang-go

# Download Go 1.25.0
wget https://go.dev/dl/go1.25.0.linux-amd64.tar.gz

# Extract to /usr/local
sudo tar -C /usr/local -xzf go1.25.0.linux-amd64.tar.gz

# Add to PATH (add to ~/.bashrc or ~/.zshrc)
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# Reload shell configuration
source ~/.bashrc  # or source ~/.zshrc
```

**macOS**:
```bash
# Using Homebrew
brew install go@1.25

# Or download directly from https://go.dev/dl/
# Download go1.25.0.darwin-amd64.tar.gz (Intel) or
#         go1.25.0.darwin-arm64.tar.gz (Apple Silicon)
```

**Verify Installation**:
```bash
go version
# Should output: go version go1.25.0 linux/amd64 (or your architecture)

# Verify Go environment
go env GOPATH
go env GOROOT
```

**Important**: The Go version must match `go.mod`. Check with:
```bash
grep "^go " go.mod
# Should show: go 1.25.0
```

#### 3. Make (REQUIRED)

**What it is**: Build automation tool that provides convenient commands for building.

**Why you need it**: The project uses Makefile targets (`make release-dry-run`, etc.) as the primary interface for building.

**Installation**:

**Linux (Ubuntu/Debian)**:
```bash
sudo apt update
sudo apt install build-essential
```

**macOS**:
```bash
# Usually pre-installed. If not:
xcode-select --install
```

**Windows (WSL2)**:
```bash
# Included in build-essential
sudo apt install build-essential
```

**Verify Installation**:
```bash
make --version
# Should output: GNU Make 4.x
```

#### 4. Git (REQUIRED)

**What it is**: Version control system for cloning the repository.

**Why you need it**: Required to clone the Infinite Drive repository and for version detection in GoReleaser.

**Installation**:

**Linux (Ubuntu/Debian)**:
```bash
sudo apt update
sudo apt install git
```

**macOS**:
```bash
# Usually pre-installed. If not:
brew install git
```

**Verify Installation**:
```bash
git --version
# Should output: git version 2.x.x
```

#### 5. Git Repository Access (REQUIRED)

**What you need**: Clone of the Infinite Drive repository.

```bash
# Clone the repository
git clone https://github.com/deep-thought-labs/infinite.git
cd infinite

# Verify you're in the repository
git status
```

### Prerequisites Summary Checklist

Before running any build commands, verify all prerequisites:

```bash
# ✅ Docker is installed and running
docker --version
docker ps

# ✅ Go 1.25.0 is installed
go version
# Should show: go version go1.25.0

# ✅ Make is available
make --version

# ✅ Git is available
git --version

# ✅ You're in the repository
git status
# Should show repository information

# ✅ Go environment is configured
go env GOPATH
go env GOROOT
# Should show valid paths

# ✅ Docker can access the socket (Linux only)
ls -l /var/run/docker.sock
# Should show docker group access
```

### Platform-Specific Additional Requirements

#### macOS (Apple Silicon M1/M2/M3)

**Additional considerations**:
- Docker Desktop must be running
- May experience slower builds due to emulation (expected)
- ARM64 builds may fail locally (use GitHub Actions for ARM64)

#### Linux

**Additional requirements**:
- User must be in `docker` group:
  ```bash
  sudo usermod -aG docker $USER
  # Logout and login again for changes to take effect
  ```
- Sufficient disk space for Docker images:
  ```bash
  # Check available space
  df -h
  # Docker images can be several GB
  ```

#### Windows (WSL2)

**Additional requirements**:
- WSL2 must be installed and updated
- Docker Desktop with WSL2 backend enabled
- Linux distribution installed in WSL2 (Ubuntu recommended)

### Network Requirements

- **Internet connection**: Required for:
  - Downloading Docker images (`goreleaser-cross`)
  - Downloading Go dependencies
  - Cloning repository
- **Bandwidth**: 
  - Initial setup: ~2-3GB (Docker images + dependencies)
  - Subsequent builds: ~100-500MB (dependency updates)

### Quick Verification Script

We provide a script to automatically verify all prerequisites:

```bash
# Run the verification script
./scripts/check_build_prerequisites.sh
```

**What it checks:**
- ✅ Docker installation and version
- ✅ Docker service running
- ✅ Docker user permissions (Linux)
- ✅ Go installation and version (must be 1.25.0)
- ✅ Go environment variables (GOPATH, GOROOT)
- ✅ Make installation
- ✅ Git installation
- ✅ Repository access (git status)
- ✅ Available disk space

**Example output:**
```
🔍 Checking prerequisites for Infinite Drive builds...

Docker installation: ✅ Installed (version 24.0.7)
Docker running: ✅ Running
Go installation: ✅ Installed (version go1.25.0)
Go version matches go.mod (1.25.0): ✅ Correct version
Go environment configured: ✅ Configured
Make installation: ✅ Installed (version 4.3)
Git installation: ✅ Installed (version 2.42.0)
In Infinite Drive repository: ✅ Yes
Available disk space: ✅ Sufficient (150 GB available)

✅ All critical prerequisites are met!
```

**If prerequisites are missing**, the script will:
- Show what's missing (❌)
- Display warnings for version mismatches (⚠️)
- Provide installation instructions
- Exit with error code 1

---

## Overview

Infinite Drive uses **GoReleaser** for automated multi-platform builds. The build system supports:

- **Linux**: AMD64 and ARM64
- **macOS**: Intel (AMD64) and Apple Silicon (ARM64)
- **Windows**: AMD64

### Key Technical Requirements

- **CGO Enabled**: Required for cryptographic functions (secp256k1)
- **Docker**: Used for consistent cross-compilation environments
- **Go Version**: 1.25.0 (see `go.mod`)

### Build Artifacts

- Binaries are built in the `dist/` directory (ignored by git)
- Archives include: README.md, LICENSE, CHANGELOG.md
- Checksums (SHA256) are generated for verification

---

## Understanding Docker Build Configuration

**⚠️ IMPORTANT**: Before running builds, understand how Docker flags work.

### Key Concept: Container Platform vs Build Targets

**Common misconception**: "Using `--platform linux/amd64` means only AMD64 binaries are built"

**Reality**: ❌ **False**

**How it actually works**:
- `--platform linux/amd64` sets the **container host architecture** (where GoReleaser runs)
- GoReleaser **inside** the container reads `.goreleaser.yml` to determine **what platforms to compile for**
- The container can run on AMD64 but compile for ARM64, Windows, macOS, etc.
- Cross-compilation toolchains handle this automatically

**Example**:
```
Your Mac M1 (ARM64)
  ↓ docker run --platform linux/amd64
Container: Linux AMD64 (emulated)
  ↓ goreleaser reads .goreleaser.yml
Builds binaries for ALL platforms:
  ✅ linux_amd64
  ✅ linux_arm64
  ✅ darwin_amd64
  ✅ darwin_arm64
  ✅ windows_amd64
```

**Why use `--platform linux/amd64`?**:
- Ensures consistent build environment across all machines
- `goreleaser-cross` is optimized for Linux AMD64
- On Mac M1, forces emulation (slower but consistent results)

### Docker Flags Explained

All build commands use these Docker flags:

| Flag | Purpose | Required? |
|------|---------|-----------|
| `--rm` | Auto-remove container after build | ✅ Yes |
| `--privileged` | Enable Docker-in-Docker (needed for cross-compilation) | ✅ Yes |
| `--platform linux/amd64` | Set container host architecture (NOT build targets) | ✅ Yes |
| `-e CGO_ENABLED=1` | Enable CGO for cryptographic functions | ✅ Yes |
| `-e TMVERSION=...` | Pass CometBFT version to build | ✅ Yes |
| `-v /var/run/docker.sock:...` | Docker socket access (for Docker-in-Docker) | ⚠️ Recommended |
| `-v $(pwd):/go/src/...` | Mount source code into container | ✅ Yes |
| `-v ${GOPATH}/pkg:/go/pkg` | Cache Go modules (performance) | ⚠️ Recommended |
| `-w /go/src/...` | Set working directory | ✅ Yes |

**Detailed explanation**: See [DOCKER_BUILD_CONFIGURATION.md](./DOCKER_BUILD_CONFIGURATION.md) for complete flag-by-flag documentation.

---

## Build System Architecture

### Files Overview

| File | Purpose | Usage |
|------|---------|-------|
| `.goreleaser.yml` | Full release configuration | All platforms for production |
| `.goreleaser.linux-only.yml` | Linux-only configuration | Faster development builds |
| `.github/workflows/release.yml` | CI/CD automation | Automatic releases on tags |
| `Makefile` | Build commands | Developer interface |

### Configuration Files

#### `.goreleaser.yml`
Main configuration for complete releases. Includes all platforms:
- Linux AMD64 and ARM64
- macOS Intel and Apple Silicon
- Windows AMD64

**Usage:**
```bash
make release-dry-run    # Test all platforms locally
make release           # Create official release (requires .release-env)
```

#### `.goreleaser.linux-only.yml`
Optimized configuration for faster development builds:
- Linux AMD64 ✅ (works everywhere)
- Linux ARM64 ⚠️ (may fail on Mac M1 with Docker emulation)

**Usage:**
```bash
make release-dry-run-linux    # Quick Linux build test
```

---

## Local Development Builds

**⚠️ Prerequisites**: Ensure you have completed all requirements in the [Prerequisites](#prerequisites) section before proceeding.

### Quick Test Build (Linux Only)

**Fastest option for local development:**

```bash
make release-dry-run-linux
```

**What this does:**
- Builds only Linux platforms (AMD64 and ARM64)
- Runs in Docker container (consistent environment)
- Creates snapshot build (doesn't publish)

**Expected time:** ~10-15 minutes on Mac M1 (may vary)

**Note:** If ARM64 build fails with assembler errors on Mac M1, this is **expected**. See [Understanding Build Limitations](#understanding-build-limitations).

### Full Platform Test Build

**Test all platforms before release:**

```bash
make release-dry-run
```

**What this does:**
- Builds all platforms (Linux, macOS, Windows)
- Tests complete release configuration
- Takes longer but validates everything

**Expected time:** ~20-30 minutes on Mac M1 (may vary significantly)

### Manual Single-Platform Builds

For quick testing of a single platform, you can use direct Go commands:

```bash
# Linux AMD64
cd infinited
CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build -o ../build/infinited-linux-amd64 ./cmd/infinited

# macOS (Apple Silicon)
CGO_ENABLED=1 GOOS=darwin GOARCH=arm64 go build -o ../build/infinited-darwin-arm64 ./cmd/infinited
```

---

## Production Releases

### Official Release Process

Production releases are **automatically created** when you push a version tag:

```bash
# Create and push version tag
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions will:
1. Detect the version tag
2. Build binaries for all platforms
3. Create GitHub Release
4. Upload binaries and checksums
5. Generate changelog from git commits

### Manual Release (Development)

If you need to create a release manually (requires `.release-env` file):

```bash
# Ensure .release-env exists with required variables
make release
```

**Required in `.release-env`:**
```
GITHUB_TOKEN=your_github_token_here
```

---

## Understanding Build Limitations

### Mac M1 / Apple Silicon Considerations

**Why ARM64 builds may fail on Mac M1:**

1. **Docker Emulation**: 
   - Build commands use `--platform linux/amd64` to force x86_64 emulation
   - This ensures consistent builds, but adds overhead

2. **Cross-Compilation Complexity**:
   - Building ARM64 binaries inside an x86_64-emulated container
   - Requires cross-compilation toolchains that may not be fully configured
   - Assembler errors (`gcc_arm64.S: Error: no such instruction`) indicate toolchain mismatch

3. **Expected Behavior**:
   - ✅ AMD64 builds work correctly (native emulation)
   - ⚠️ ARM64 builds may fail (toolchain limitations)
   - ✅ Both work correctly in GitHub Actions (Ubuntu native)

### Platform-Specific Behavior

| Platform | Local Mac M1 | Ubuntu Native | GitHub Actions |
|----------|--------------|--------------|----------------|
| Linux AMD64 | ✅ Works | ✅ Works | ✅ Works |
| Linux ARM64 | ⚠️ May fail | ✅ Works | ✅ Works |
| macOS Intel | ⚠️ Slow | ❌ Not tested | ⚠️ Requires setup |
| macOS Apple Silicon | ⚠️ Slow | ❌ Not tested | ⚠️ Requires setup |
| Windows AMD64 | ⚠️ Slow | ⚠️ May work | ✅ Works |

### Recommended Workflow

1. **Development**: Use `make release-dry-run-linux` for quick testing
2. **Pre-Release**: Test locally with `make release-dry-run` (expect ARM64 to potentially fail)
3. **Production**: Push version tag - GitHub Actions handles all platforms correctly

---

## Troubleshooting

### Build Fails with "no such instruction" (ARM64)

**Symptom:**
```
gcc_arm64.S: Error: no such instruction: `stp x29,x30,[sp,'
```

**Cause:** Cross-compilation toolchain issue when building ARM64 in emulated Docker.

**Solution:** This is expected on Mac M1. Use GitHub Actions for ARM64 builds, or test only AMD64 locally.

### Build Takes Too Long

**Possible causes:**
- Docker emulation overhead (Mac M1)
- Slow internet (downloading dependencies)
- Limited system resources

**Solutions:**
- Use `make release-dry-run-linux` for faster builds
- Ensure good internet connection
- Increase Docker resources (CPU/Memory in Docker Desktop)

### "unknown flag: --debug" Error

**Symptom:**
```
error=unknown flag: --debug
```

**Cause:** GoReleaser version doesn't support `--debug` flag.

**Solution:** Removed from configuration. GoReleaser shows progress by default.

### Missing CometBFT Version

**Symptom:**
```
TMVERSION is empty
```

**Solution:** Ensure Go modules are up to date:
```bash
go mod tidy
go mod download
```

### Docker Permission Errors

**Symptom:**
```
permission denied: /var/run/docker.sock
```

**Solution:**
- Ensure Docker is running
- User must have Docker access
- On Linux: `sudo usermod -aG docker $USER` (logout/login required)

---

## GitHub Actions Automated Releases

### Automatic Release Trigger

Pushing a version tag automatically triggers the release workflow:

```bash
git tag v1.0.0
git push origin v1.0.0
```

### Workflow Steps

1. **Checkout Code**: Full git history (for changelog)
2. **Setup Go**: Version 1.25 from `go.mod`
3. **Get CometBFT Version**: Extracted from Go modules
4. **Install CGO Tools**: Cross-compilation compilers
5. **Run GoReleaser**: Build all platforms and create release

### Manual Workflow Trigger

You can manually trigger the workflow from GitHub UI:
1. Go to **Actions** tab
2. Select **Release** workflow
3. Click **Run workflow** (dropdown)
4. Choose branch and click **Run workflow**

This runs in "snapshot" mode (doesn't create actual release, only tests).

### Release Artifacts

Each release includes:
- Binaries for all platforms (tar.gz for Linux/macOS, zip for Windows)
- `checksums.txt` (SHA256 verification)
- Source archives
- Release notes (auto-generated changelog)

### Release Notes

Automatically generated from git commits between tags:
- Excludes: docs, tests, merge commits
- Includes: feature descriptions, bug fixes, breaking changes

---

## Best Practices

### Before Creating a Release

1. ✅ Test locally with `make release-dry-run-linux`
2. ✅ Verify code is committed and pushed
3. ✅ Check version in `go.mod` and `version/version.go`
4. ✅ Update CHANGELOG.md if needed
5. ✅ Create and push version tag

### Development Workflow

1. **Quick Testing**: Use `make release-dry-run-linux`
2. **Full Validation**: Use `make release-dry-run` (accept ARM64 may fail on Mac)
3. **CI/CD Validation**: Push to branch, let GitHub Actions test
4. **Production Release**: Push version tag

### Version Tagging

Follow semantic versioning:
- **Major** (v2.0.0): Breaking changes
- **Minor** (v1.1.0): New features, backwards compatible
- **Patch** (v1.0.1): Bug fixes, backwards compatible

---

## Additional Resources

- **GoReleaser Documentation**: https://goreleaser.com/
- **Docker Documentation**: https://docs.docker.com/
- **GitHub Actions**: https://docs.github.com/en/actions

---

## Support

If you encounter issues not covered here:
1. Check [Troubleshooting](#troubleshooting) section
2. Review GitHub Actions logs for detailed error messages
3. Verify Docker and Go versions are compatible
4. Check system resources (CPU, memory, disk space)

---

*Last updated: 2025*

