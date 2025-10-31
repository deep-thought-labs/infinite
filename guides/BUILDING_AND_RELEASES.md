# Building and Releases

**Copyright (c) 2025 Deep Thought Labs**  
Comprehensive guide for building Infinite Drive binaries and managing releases.

---

## Table of Contents

1. [Overview](#overview)
2. [Build System Architecture](#build-system-architecture)
3. [Local Development Builds](#local-development-builds)
4. [Production Releases](#production-releases)
5. [Understanding Build Limitations](#understanding-build-limitations)
6. [Troubleshooting](#troubleshooting)
7. [GitHub Actions Automated Releases](#github-actions-automated-releases)

---

## Overview

Infinite Drive uses **GoReleaser** for automated multi-platform builds. The build system supports:

- **Linux**: AMD64 and ARM64
- **macOS**: Intel (AMD64) and Apple Silicon (ARM64)
- **Windows**: AMD64

### Key Requirements

- **CGO Enabled**: Required for cryptographic functions (secp256k1)
- **Docker**: Used for consistent cross-compilation environments
- **Go Version**: 1.25.0 (see `go.mod`)

### Build Artifacts

- Binaries are built in the `dist/` directory (ignored by git)
- Archives include: README.md, LICENSE, CHANGELOG.md
- Checksums (SHA256) are generated for verification

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

### Prerequisites

- **Docker**: Must be installed and running
- **Make**: Build system command runner
- **Git**: For version detection

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

