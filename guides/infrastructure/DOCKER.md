# Docker Usage in Infinite Drive

Guide on how Docker is used in Infinite Drive's build process.

## 📋 Table of Contents

- [Why Docker?](#why-docker)
- [Docker Configuration](#docker-configuration)
- [Builds with Docker](#builds-with-docker)
- [Troubleshooting](#troubleshooting)

## 🐳 Why Docker?

**Docker** is used in Infinite Drive for:
- ✅ **Consistent cross-compilation**: Reproducible builds for multiple platforms
- ✅ **Isolated environment**: Doesn't contaminate your local system
- ✅ **Same configuration**: Same environment as GitHub Actions

**When it's used**:
- Release builds (`make release-dry-run`)
- GitHub Actions (automatic)

**When it's NOT used**:
- Normal development compilation (`make install`)
- Simple builds (`make build`)

---

## ⚙️ Docker Configuration

### Installation

#### macOS

```bash
# Option 1: Docker Desktop (Recommended)
# Download from: https://www.docker.com/products/docker-desktop/

# Option 2: Homebrew
brew install --cask docker
```

#### Linux (Ubuntu/Debian)

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker
```

**⚠️ IMPORTANT**: After adding your user to the docker group, **log out and log back in** (or run `newgrp docker`).

### Verify Installation

```bash
# Verify version
docker --version

# Verify it works (without sudo on Linux)
docker ps

# Basic test
docker run hello-world
```

### Resource Configuration (macOS/Windows)

In Docker Desktop:
1. Open Docker Desktop
2. Settings → Resources
3. Configure:
   - **RAM**: 4GB+ recommended
   - **CPU**: 2+ cores recommended
   - **Disk**: 20GB+ recommended

---

## 🏗️ Builds with Docker

### Release Build (Uses Docker)

**Command**: `make release-dry-run-linux` or `make release-dry-run`

**What it does**:
1. Uses Docker to create an isolated environment
2. Compiles binaries inside the container
3. Copies binaries to `./dist/`

**Requirements**:
- Docker running
- Sufficient disk space

**Time**: 10-30 minutes

### Internal Process

When you run `make release-dry-run`:

1. **Docker pull**: Downloads `goreleaser/goreleaser-cross` image (if it doesn't exist)
2. **Docker run**: Runs GoReleaser inside the container
3. **Build**: Compiles binaries for all platforms
4. **Copy**: Copies binaries from container to `./dist/`

**You don't need to understand this** - just run the command and it works.

---

## 🐛 Troubleshooting

### Error: "docker: command not found"

**Problem**: Docker is not installed or not in PATH

**Solution**:
```bash
# Verify installation
which docker

# If not installed, install (see installation section above)
```

### Error: "permission denied while trying to connect to the Docker daemon socket"

**Problem**: Your user doesn't have permissions to use Docker (Linux)

**Solution**:
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and log back in, or:
newgrp docker

# Verify
docker ps
```

### Error: "Cannot connect to the Docker daemon"

**Problem**: Docker is not running

**Solution**:
```bash
# macOS/Windows: Open Docker Desktop

# Linux: Start service
sudo systemctl start docker
sudo systemctl enable docker  # To start automatically
```

### Build Very Slow

**Causes**:
- First time (downloads Docker image)
- Emulation on Mac M1 (slower than native)
- Limited resources

**Solutions**:
- First time: It's normal, may take longer
- Mac M1: It's expected, native builds on GitHub Actions are faster
- Increase Docker Desktop resources

### ARM64 Build Fails on Mac M1

**Problem**: ARM64 build fails with assembler errors

**This is expected and normal**:
- ✅ AMD64 build works
- ⚠️ ARM64 build may fail on Mac M1 with Docker emulation
- ✅ ARM64 builds work correctly on GitHub Actions (native Ubuntu)

**You don't need to do anything** - this is expected behavior.

---

## 📚 More Information

- **[guides/infrastructure/RELEASES.md](RELEASES.md)** - Release guide
- **[guides/development/BUILDING.md](../development/BUILDING.md)** - Compilation guide
- **[Docker Documentation](https://docs.docker.com/)** - Official documentation

---

## 🔗 Quick Reference

| Command | Uses Docker | Time |
|---------|------------|------|
| `make install` | ❌ No | 2-5 min |
| `make build` | ❌ No | 2-5 min |
| `make release-dry-run-linux` | ✅ Yes | 10-15 min |
| `make release-dry-run` | ✅ Yes | 20-30 min |
