# Docker Build Configuration Explained

**Copyright (c) 2025 Deep Thought Labs**  
Detailed explanation of Docker flags and build configuration for Infinite Drive releases.

---

## Understanding Docker Build Commands

All release commands in the Makefile use Docker with `goreleaser-cross`. This document explains what each flag does and why it's needed.

---

## Docker Command Structure

All release commands follow this pattern:

```bash
docker run \
    --rm \
    --privileged \
    --platform linux/amd64 \
    -e CGO_ENABLED=1 \
    -e TMVERSION=$(TMVERSION) \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v `pwd`:/go/src/$(PACKAGE_NAME) \
    -v ${GOPATH}/pkg:/go/pkg \
    -w /go/src/$(PACKAGE_NAME) \
    ghcr.io/goreleaser/goreleaser-cross:${GOLANG_CROSS_VERSION} \
    [goreleaser-arguments]
```

---

## Flag-by-Flag Explanation

### `--rm`
**What it does**: Automatically removes the container when it exits.

**Why needed**: 
- Prevents accumulation of stopped containers
- Saves disk space
- Cleaner Docker environment

**Required?**: ✅ **YES** - Standard practice, prevents clutter

---

### `--privileged`
**What it does**: Gives extended privileges to the container.

**Why needed**: 
- Required for nested Docker operations
- `goreleaser-cross` may need to run Docker-in-Docker for some builds
- Allows access to all devices

**Required?**: ✅ **YES** - GoReleaser cross-compilation requires this

**Security note**: This is safe because:
- Container runs in isolated environment
- Only used for builds, not in production
- Temporary (removed with `--rm`)

---

### `--platform linux/amd64`
**What it does**: Forces Docker to run the container with x86_64 architecture.

**Common misconception**: 
❌ **This does NOT limit what platforms GoReleaser compiles for**

**What it actually does**:
- Sets the **host container architecture** (where GoReleaser runs)
- Ensures consistent environment regardless of your machine (Mac M1, ARM, etc.)
- GoReleaser inside the container still compiles for **all platforms** specified in `.goreleaser.yml`

**Why `linux/amd64` specifically**:
- `goreleaser-cross` image is optimized for Linux AMD64
- Provides most stable build environment
- Ensures consistent behavior across all developer machines
- On Mac M1, this forces emulation (slower but consistent)

**Required?**: ✅ **YES** - Ensures consistent build environment

**Important**: 
- Even if you want to build for ARM64, you still use `--platform linux/amd64`
- GoReleaser handles cross-compilation to ARM64 **inside** the container
- The container platform ≠ target build platforms

---

### `-e CGO_ENABLED=1`
**What it does**: Sets environment variable inside container to enable CGO.

**Why needed**: 
- Infinite Drive uses cryptographic functions (secp256k1) that require CGO
- Without CGO, the binary would fail at runtime
- Required for linking with C libraries

**Is it redundant?**: 
- The `.goreleaser.yml` also sets `CGO_ENABLED=1` in `env:` section
- **However**: The Docker `-e` flag ensures it's set **before** GoReleaser starts
- Some tools read environment variables at startup
- **Best practice**: Set it in both places for redundancy

**Required?**: ✅ **YES** - Critical for cryptographic functions

---

### `-e TMVERSION=$(TMVERSION)`
**What it does**: Passes CometBFT version to the container.

**Why needed**: 
- Used in build flags: `-X github.com/cometbft/cometbft/version.TMCoreSemVer={{ .Env.TMVERSION }}`
- Ensures binary reports correct CometBFT version
- Extracted from Go modules: `go list -m github.com/cometbft/cometbft`

**Required?**: ✅ **YES** - Needed for version embedding

---

### `-v /var/run/docker.sock:/var/run/docker.sock`
**What it does**: Mounts Docker socket into container.

**Why needed**: 
- Allows container to communicate with Docker daemon on host
- Required for Docker-in-Docker operations
- Some GoReleaser features may need nested containers

**Required?**: ⚠️ **MAYBE** - Depends on GoReleaser version and features
- Included for safety and future-proofing
- Some GoReleaser operations may require it
- **Best practice**: Keep it for compatibility

---

### `-v \`pwd\`:/go/src/$(PACKAGE_NAME)`
**What it does**: Mounts current directory (repo) into container at `/go/src/github.com/cosmos/evm`.

**Why needed**: 
- GoReleaser needs access to source code
- Ensures container sees all files in repository
- Required for building

**Path mapping**: 
- Host: Current directory (where you run `make`)
- Container: `/go/src/github.com/cosmos/evm`
- Matches Go workspace structure expected by goreleaser-cross

**Required?**: ✅ **YES** - Essential for build

---

### `-v ${GOPATH}/pkg:/go/pkg`
**What it does**: Mounts Go module cache into container.

**Why needed**: 
- Speeds up builds by reusing downloaded dependencies
- Prevents re-downloading Go modules on every build
- Shares cache between host and container

**Performance benefit**: 
- First build: Downloads all dependencies (~2-3GB)
- Subsequent builds: Uses cached modules (much faster)

**Required?**: ⚠️ **OPTIONAL but RECOMMENDED**
- Builds work without it, but slower
- **Best practice**: Keep it for performance

---

### `-w /go/src/$(PACKAGE_NAME)`
**What it does**: Sets working directory inside container.

**Why needed**: 
- GoReleaser needs to run from repository root
- Ensures paths in config files resolve correctly
- Matches the mount point of source code

**Required?**: ✅ **YES** - Required for correct path resolution

---

### Image: `ghcr.io/goreleaser/goreleaser-cross:${GOLANG_CROSS_VERSION}`
**What it is**: Pre-configured Docker image with GoReleaser and cross-compilation tools.

**What's inside**:
- GoReleaser binary
- Cross-compilation toolchains (gcc for each platform)
- Go compiler
- All dependencies for multi-platform builds

**Version**: `${GOLANG_CROSS_VERSION}` = `v1.22` (defined in Makefile)

**Required?**: ✅ **YES** - This is the build environment

---

## Differences Between Commands

### `release-dry-run` vs `release-dry-run-linux` vs `release`

| Aspect | release-dry-run | release-dry-run-linux | release |
|--------|----------------|----------------------|---------|
| **Docker flags** | Same | Same | Same + `--env-file .release-env` |
| **GoReleaser args** | `--snapshot --clean --skip validate --skip publish` | Same + `--config .goreleaser.linux-only.yml` | `release --clean --skip validate` |
| **Config file** | `.goreleaser.yml` (default) | `.goreleaser.linux-only.yml` | `.goreleaser.yml` (default) |
| **Platforms** | All (Linux, macOS, Windows) | Linux only (amd64, arm64) | All (Linux, macOS, Windows) |
| **Output** | Test builds in `dist/` | Test builds in `dist/` | GitHub Release |
| **Purpose** | Test all platforms | Fast Linux test | Production release |

**Key insights**:
1. ✅ All use **same Docker flags** - Correct! Ensures consistent environment
2. ✅ Only difference is GoReleaser arguments and config file - Correct!
3. ✅ `release` adds `--env-file` for GitHub token - Correct!

---

## Why `--platform linux/amd64` Doesn't Limit Build Targets

**Common confusion**: "If I use `--platform linux/amd64`, won't it only build for AMD64?"

**Answer**: ❌ **NO**

**Explanation**:

1. **Docker `--platform` flag**: Controls **container host architecture**
   - Determines what architecture the **container OS** runs on
   - Affects the **build environment**, not build targets

2. **GoReleaser targets**: Controlled by `.goreleaser.yml` **inside** container
   - The container can run on AMD64 but compile for ARM64, Windows, macOS, etc.
   - Cross-compilation toolchains handle this

3. **Example flow**:
   ```
   Your Mac M1 (ARM64)
     ↓ docker run --platform linux/amd64
   Container runs Linux AMD64 (emulated)
     ↓ goreleaser reads .goreleaser.yml
   Compiles binaries for:
     - linux_amd64 ✅
     - linux_arm64 ✅
     - darwin_amd64 ✅
     - darwin_arm64 ✅
     - windows_amd64 ✅
   ```

**Visual comparison**:

| Your Machine | Container Platform | What Gets Built |
|--------------|-------------------|-----------------|
| Mac M1 (ARM64) | `--platform linux/amd64` → Linux AMD64 (emulated) | **All platforms** from `.goreleaser.yml` |
| Ubuntu AMD64 | `--platform linux/amd64` → Linux AMD64 (native) | **All platforms** from `.goreleaser.yml` |
| Windows | `--platform linux/amd64` → Linux AMD64 (via WSL2) | **All platforms** from `.goreleaser.yml` |

**Conclusion**: `--platform linux/amd64` ensures consistent build environment, but GoReleaser config determines what gets built.

---

## Flag Necessity Analysis

### ✅ Essential Flags (Cannot Remove)

1. `--rm` - Prevents container accumulation
2. `--privileged` - Required for Docker-in-Docker
3. `--platform linux/amd64` - Ensures consistent environment
4. `-e CGO_ENABLED=1` - Required for cryptographic functions
5. `-e TMVERSION` - Required for version embedding
6. `-v $(pwd):/go/src/...` - Required for source code access
7. `-w /go/src/...` - Required for correct path resolution
8. Image name - Required build environment

### ⚠️ Optional but Recommended

1. `-v ${GOPATH}/pkg:/go/pkg` - Performance optimization
   - **Can remove**: Yes, but builds will be slower
   - **Keep it**: Recommended for faster builds

### ❓ May or May Not Be Needed

1. `-v /var/run/docker.sock:/var/run/docker.sock` - Docker-in-Docker
   - **Likely needed**: For some GoReleaser features
   - **Safe to keep**: Doesn't hurt, ensures compatibility
   - **Recommendation**: **Keep it** for future-proofing

---

## Configuration Validation

### Current Configuration Analysis

✅ **All Docker flags are correctly configured**

**Verified**:
- ✅ Same flags across all commands (consistency)
- ✅ All essential flags present
- ✅ Optional flags included for performance
- ✅ No redundant or conflicting flags

### Recommendations

1. **Keep current configuration** - It's optimal
2. **All flags serve a purpose** - No unnecessary flags found
3. **Configuration is consistent** - Good practice

---

## Troubleshooting Flags

### "Permission denied" on `/var/run/docker.sock`

**Problem**: Docker socket not accessible

**Solution**:
```bash
# Linux: Add user to docker group
sudo usermod -aG docker $USER
# Logout and login again
```

### "Cannot connect to Docker daemon"

**Problem**: Docker not running

**Solution**:
```bash
# Linux
sudo systemctl start docker

# macOS/Windows
# Start Docker Desktop application
```

### "platform linux/amd64 cannot be used"

**Problem**: Docker doesn't support platform emulation

**Solution**:
- Update Docker Desktop (Mac/Windows)
- Enable emulation in Docker settings
- Or build on native Linux machine

---

## Best Practices Summary

1. ✅ **Keep all current flags** - They're all necessary or beneficial
2. ✅ **Use `--platform linux/amd64`** - Ensures consistency
3. ✅ **Set `CGO_ENABLED=1`** - Required for crypto
4. ✅ **Mount GOPATH/pkg** - Performance optimization
5. ✅ **Use `--privileged`** - Required for cross-compilation
6. ✅ **Mount docker.sock** - Future-proofing for GoReleaser features

---

## Quick Reference

**Minimal required flags**:
```bash
docker run --rm --privileged --platform linux/amd64 \
  -e CGO_ENABLED=1 -e TMVERSION=... \
  -v $(pwd):/go/src/... -w /go/src/... \
  ghcr.io/goreleaser/goreleaser-cross:v1.22 \
  [goreleaser-args]
```

**Recommended flags** (current):
```bash
docker run --rm --privileged --platform linux/amd64 \
  -e CGO_ENABLED=1 -e TMVERSION=... \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(pwd):/go/src/... -v ${GOPATH}/pkg:/go/pkg \
  -w /go/src/... \
  ghcr.io/goreleaser/goreleaser-cross:v1.22 \
  [goreleaser-args]
```

**Difference**: Performance optimization (`GOPATH/pkg` mount) and Docker socket access.

---

*Last updated: 2025*

