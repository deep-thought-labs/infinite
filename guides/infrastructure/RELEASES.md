# Releases and GitHub Actions Guide

Complete guide for creating official Infinite Drive releases using GitHub Actions.

## 📋 Table of Contents

- [What is a Release?](#what-is-a-release)
- [Prerequisites](#prerequisites)
- [Complete Release Workflow](#complete-release-workflow)
- [GitHub Actions Configuration](#github-actions-configuration)
- [Create a Version Tag](#create-a-version-tag)
- [Release Testing (Dry Run)](#release-testing-dry-run)
- [Monitor the Process](#monitor-the-process)
- [Verify the Release](#verify-the-release)
- [Troubleshooting](#troubleshooting)

## 🎯 What is a Release?

A **release** is an official version of the software that includes:
- ✅ Compiled binaries for multiple platforms (Linux, macOS, Windows)
- ✅ Release notes with changes
- ✅ Downloadable files for users
- ✅ Git tags for versioning

**Difference with local compilation**:
- **Local compilation** (`make install`): Only for your machine
- **Release**: Binaries for all platforms, publicly published

## ⚙️ Prerequisites

### 1. Docker Installed

**For local release testing** (dry run):

```bash
# Verify Docker
docker --version
docker ps  # Should work without errors
```

**Installation**:
- **macOS**: [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- **Linux**: `curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh`

### 2. GitHub Actions Configuration

**⚠️ IMPORTANT**: Official releases are created automatically via GitHub Actions. You need to configure this once.

#### Required Secrets

GitHub Actions needs these secrets configured in the repository:

1. Go to your repository on GitHub
2. Settings → Secrets and variables → Actions
3. Add the following secrets:

| Secret | Description | Where to Get It |
|--------|-------------|-----------------|
| `GITHUB_TOKEN` | GitHub token (automatic) | Created automatically |
| `GORELEASER_KEY` | Key for GoReleaser (if using pro) | [GoReleaser](https://goreleaser.com) |

**Note**: For basic releases, `GITHUB_TOKEN` is sufficient.

#### Repository Permissions

Make sure GitHub Actions has permissions to:
- ✅ Create releases
- ✅ Upload assets
- ✅ Create tags

**Configuration**:
1. Settings → Actions → General
2. "Workflow permissions" → "Read and write permissions"
3. Save

**More details**: See [guides/infrastructure/CI_CD.md](CI_CD.md)

## 🚀 Complete Release Workflow

### Process Summary

```
1. Prepare code
   ↓
2. Create version tag
   ↓
3. Push tag to GitHub
   ↓
4. GitHub Actions detects the tag
   ↓
5. GitHub Actions compiles binaries
   ↓
6. GitHub Actions creates release
   ↓
7. Binaries available for download
```

**Total time**: ~30-45 minutes (automatic after push)

### Step 1: Prepare the Code

```bash
# 1. Make sure you're on the correct branch (usually main)
git checkout main

# 2. Make sure you have the latest changes
git pull origin main

# 3. Verify everything compiles locally
make install

# 4. Run tests
make test-all

# 5. Validate customizations
./scripts/validate_customizations.sh
```

**⚠️ IMPORTANT**: Make sure all changes are committed and pushed before creating the tag.

### Step 2: Create Version Tag

#### Version Format

Use [Semantic Versioning](https://semver.org/): `vMAJOR.MINOR.PATCH`

- **MAJOR**: Incompatible changes (v1.0.0 → v2.0.0)
- **MINOR**: Compatible new features (v1.0.0 → v1.1.0)
- **PATCH**: Bug fixes (v1.0.0 → v1.0.1)

#### Create the Tag

```bash
# Create local tag (format: vX.Y.Z)
git tag v1.0.0

# Verify the tag
git tag -l

# View tag information
git show v1.0.0
```

#### Tag with Message (Recommended)

```bash
# Create tag with descriptive message
git tag -a v1.0.0 -m "Release v1.0.0: Initial stable release"

# View the tag with message
git show v1.0.0
```

### Step 3: Push Tag to GitHub

```bash
# Push the tag (this activates GitHub Actions)
git push origin v1.0.0

# Or push all tags
git push --tags
```

**⚠️ IMPORTANT**: Once you push the tag, GitHub Actions activates automatically. You can't easily "undo" this.

### Step 4: Monitor GitHub Actions

1. Go to your repository on GitHub
2. Click on the **"Actions"** tab
3. You'll see a workflow running called **"Release"**
4. Click on the workflow to see details

**What you'll see**:
- Build for Linux AMD64
- Build for Linux ARM64
- Build for macOS AMD64
- Build for macOS ARM64
- Build for Windows AMD64
- Release creation
- Asset upload

**Estimated time**: 20-30 minutes

### Step 5: Verify the Release

Once GitHub Actions completes:

1. Go to **"Releases"** on GitHub (right side of repository)
2. You should see your new version (e.g., "v1.0.0")
3. Binaries will be available for download

**Location**: `https://github.com/your-user/infinite/releases/tag/v1.0.0`

## 🧪 Release Testing (Dry Run)

**Before creating a real release**, you can test the process locally.

### Quick Dry Run (Linux Only)

**Purpose**: Test the compilation process without publishing anything.

```bash
# Test build (Linux only, faster)
make release-dry-run-linux
```

**What it does**:
- Compiles binaries for Linux (AMD64 and ARM64)
- Creates files in `./dist/`
- **Does NOT** publish anything to GitHub

**Time**: 10-15 minutes

**When to use**: To verify the process works before creating a real release

### Complete Dry Run

**Purpose**: Test compilation for all platforms.

```bash
# Complete test build (all platforms)
make release-dry-run
```

**What it does**:
- Compiles binaries for all platforms
- Creates files in `./dist/`
- **Does NOT** publish anything to GitHub

**Time**: 20-30 minutes

**When to use**: Before an important release, to verify all platforms

### Verify Dry Run Results

```bash
# See what was created
ls -la dist/

# You should see:
# - infinited-linux-amd64
# - infinited-linux-arm64
# - infinited-darwin-amd64
# - infinited-darwin-arm64
# - infinited-windows-amd64.exe
# etc.
```

## 📊 Monitor the Process

### In GitHub Actions

1. **View real-time progress**:
   - Go to Actions → Click on the running workflow
   - You'll see real-time logs of each step

2. **Verify each platform compiles**:
   - Each build appears as a separate job
   - ✅ Green = success
   - ❌ Red = failure

3. **View error logs**:
   - Click on the failed job
   - View detailed logs

### Local Commands (For Dry Run)

```bash
# View build progress
# (The command will show output in real time)

# Verify Docker is running
docker ps

# View Docker logs if there are problems
docker logs <container-id>
```

## ✅ Verify the Release

### On GitHub

1. **Releases page**:
   - Go to `https://github.com/your-user/infinite/releases`
   - You should see your version listed

2. **Download binaries**:
   - Click on the release
   - Scroll down to "Assets"
   - Download the binary for your platform

3. **Verify binaries**:
   ```bash
   # Download and verify
   wget https://github.com/your-user/infinite/releases/download/v1.0.0/infinited-linux-amd64
   chmod +x infinited-linux-amd64
   ./infinited-linux-amd64 version
   ```

### Verify Tags in Git

```bash
# View all tags
git tag -l

# View remote tags
git ls-remote --tags origin

# View information of a specific tag
git show v1.0.0
```

## 🔄 Update an Existing Release

**⚠️ IMPORTANT**: You can't easily "update" an existing release. Best practice:

1. **Create a new release** with incremented version:
   ```bash
   git tag v1.0.1  # Patch release
   git push origin v1.0.1
   ```

2. **If you need to fix the same release**:
   - Delete the release on GitHub (not the tag)
   - Create a new tag with the same name but different commit
   - Push the tag again

## 🐛 Troubleshooting

### GitHub Actions Fails

**Problem**: The workflow fails during compilation

**Solutions**:
1. **View detailed logs**:
   - Click on the failed job
   - Review logs to see the specific error

2. **Test locally first**:
   ```bash
   make release-dry-run-linux
   ```
   If this fails, the problem is in your local configuration

3. **Verify Docker**:
   - GitHub Actions uses Docker for builds
   - Verify that `.github/workflows/release.yml` is correct

4. **Verify secrets**:
   - Make sure secrets are configured
   - Verify repository permissions

### Tag Already Exists

**Problem**: `git tag v1.0.0` says the tag already exists

**Solution**:
```bash
# View existing tags
git tag -l

# Delete local tag (if necessary)
git tag -d v1.0.0

# Delete remote tag (if necessary)
git push origin --delete v1.0.0

# Create new tag
git tag v1.0.0
```

### Release Not Created

**Problem**: Push the tag but release is not created

**Solutions**:
1. **Verify GitHub Actions**:
   - Go to Actions
   - See if the workflow ran
   - See if there are errors

2. **Verify permissions**:
   - Settings → Actions → General
   - "Workflow permissions" must be "Read and write"

3. **Verify configuration**:
   - Verify that `.github/workflows/release.yml` exists
   - Verify that the trigger is configured for tags

### Build Takes Too Long

**Normal**: Builds can take 20-30 minutes, especially the first time.

**If it takes more than 1 hour**:
- Verify GitHub Actions is not overloaded
- Check logs to see if there's a hung process
- Consider canceling and retrying

## 📚 More Information

- **[guides/QUICK_START.md](../QUICK_START.md)** - Quick start
- **[guides/development/BUILDING.md](../development/BUILDING.md)** - Compilation guide
- **[guides/infrastructure/CI_CD.md](CI_CD.md)** - Complete CI/CD configuration
- **[Semantic Versioning](https://semver.org/)** - Versioning specification

## 🔗 Quick Reference

| Action | Command | Time |
|--------|---------|------|
| Local test (Linux) | `make release-dry-run-linux` | 10-15 min |
| Local test (all) | `make release-dry-run` | 20-30 min |
| Create tag | `git tag v1.0.0` | <1 min |
| Push tag | `git push origin v1.0.0` | <1 min |
| Complete release | Tag → GitHub Actions | 30-45 min |
