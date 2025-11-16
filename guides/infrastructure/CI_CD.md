# CI/CD and GitHub Actions Configuration

Guide for configuring GitHub Actions and CI/CD workflow for Infinite Drive.

## 📋 Table of Contents

- [What is CI/CD?](#what-is-cicd)
- [Initial Configuration](#initial-configuration)
- [GitHub Secrets](#github-secrets)
- [Release Workflow](#release-workflow)
- [Troubleshooting](#troubleshooting)

## 🎯 What is CI/CD?

**CI/CD** (Continuous Integration / Continuous Deployment) automates:
- ✅ Binary compilation
- ✅ Test execution
- ✅ Release creation
- ✅ Binary publication

**For Infinite Drive**: GitHub Actions handles creating releases automatically when you push a version tag.

---

## ⚙️ Initial Configuration

### Requirements

- GitHub repository
- Administrator or write access permissions
- Access to repository Settings

### Step 1: Verify GitHub Actions Permissions

1. Go to your repository on GitHub
2. **Settings** → **Actions** → **General**
3. In **"Workflow permissions"**:
   - Select **"Read and write permissions"**
   - Check **"Allow GitHub Actions to create and approve pull requests"** (optional)
4. Click **"Save"**

**Why it's important**: GitHub Actions needs permissions to create releases and upload binaries.

### Step 2: Verify the Workflow Exists

The release workflow is at: `.github/workflows/release.yml`

**Verify**:
```bash
# From project root
ls -la .github/workflows/release.yml
```

If the file exists, the workflow is configured.

---

## 🔐 GitHub Secrets

### What are Secrets?

**Secrets** are encrypted environment variables that GitHub Actions can use without exposing them publicly.

### Required Secrets

For basic releases, **you DON'T need to configure secrets manually**. GitHub provides automatically:

- **`GITHUB_TOKEN`**: Created automatically, you don't need to configure it

### Optional Secrets (For GoReleaser Pro)

If you use GoReleaser Pro (paid version), you need:

- **`GORELEASER_KEY`**: GoReleaser Pro API key

**How to get it**:
1. Go to [GoReleaser Pro](https://goreleaser.com/pro)
2. Create an account or sign in
3. Generate an API key
4. Add as secret in GitHub

### How to Add Secrets

1. Go to your repository on GitHub
2. **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. Enter:
   - **Name**: `GORELEASER_KEY` (or the secret name)
   - **Secret**: The secret value
5. Click **"Add secret"**

**⚠️ IMPORTANT**: Once added, you cannot see the secret value again. If you lose it, you must create a new one.

---

## 🚀 Release Workflow

### How Does It Work?

1. **You create a version tag** locally
2. **You push the tag** to GitHub
3. **GitHub Actions detects the tag** automatically
4. **GitHub Actions compiles** binaries for all platforms
5. **GitHub Actions creates the release** with the binaries

### Workflow Trigger

The workflow activates when:
- You push a tag that matches the pattern `v*.*.*` (e.g., `v1.0.0`, `v2.3.1`)
- Or manually from GitHub Actions UI

**See configuration in**: `.github/workflows/release.yml`

```yaml
on:
  push:
    tags:
      - 'v*.*.*'  # Pattern for version tags
  workflow_dispatch:  # Allows manual activation
```

### Automatic Process

When you push a tag:

1. **Checkout**: GitHub Actions downloads the code
2. **Setup Go**: Installs Go on the runner
3. **Setup Docker**: Prepares Docker for builds
4. **Build**: Compiles binaries for all platforms
5. **Release**: Creates the release on GitHub
6. **Upload**: Uploads binaries as assets

**Total time**: ~30-45 minutes

---

## 📊 Monitor GitHub Actions

### View Running Workflows

1. Go to your repository on GitHub
2. Click on the **"Actions"** tab
3. You'll see all executed workflows

### View Workflow Details

1. Click on the workflow you want to see
2. You'll see the jobs (builds for each platform)
3. Click on a job to see detailed logs

### Real-Time Logs

Logs update in real time while the workflow runs. You can see:
- Compilation progress
- Errors if any
- Time for each step

---

## 🐛 Troubleshooting

### Workflow Doesn't Activate

**Problem**: You push the tag but the workflow doesn't run

**Solutions**:
1. **Verify tag format**:
   ```bash
   # Must be: vX.Y.Z (e.g., v1.0.0)
   git tag -l
   ```

2. **Verify the workflow exists**:
   ```bash
   ls -la .github/workflows/release.yml
   ```

3. **Verify permissions**:
   - Settings → Actions → General
   - "Workflow permissions" must be "Read and write"

4. **Verify the tag was pushed**:
   ```bash
   git ls-remote --tags origin
   ```

### Workflow Fails During Build

**Problem**: The workflow runs but fails to compile

**Solutions**:
1. **View detailed logs**:
   - Go to Actions → Click on the failed workflow
   - Click on the failed job
   - Review logs to see the specific error

2. **Test locally first**:
   ```bash
   # Test build locally
   make release-dry-run-linux
   ```
   If this fails, the problem is in your local configuration

3. **Verify Docker**:
   - The workflow uses Docker for builds
   - Verify that `.github/workflows/release.yml` is correct

### Release Created But No Binaries

**Problem**: The release is created but has no binaries

**Solutions**:
1. **Verify workflow logs**:
   - Look for errors in the "Upload artifacts" step
   - Verify that builds completed successfully

2. **Verify permissions**:
   - Settings → Actions → General
   - "Workflow permissions" must be "Read and write"

3. **Verify binary size**:
   - GitHub has size limits
   - Very large binaries may fail

### Secrets Don't Work

**Problem**: The workflow fails because it can't find a secret

**Solutions**:
1. **Verify the secret exists**:
   - Settings → Secrets and variables → Actions
   - Verify the secret is listed

2. **Verify secret name**:
   - The name must match exactly
   - Case-sensitive

3. **Verify the secret has a value**:
   - If the secret is empty, the workflow may fail

---

## 📚 More Information

- **[guides/infrastructure/RELEASES.md](RELEASES.md)** - Complete guide on how to create releases
- **[guides/development/BUILDING.md](../development/BUILDING.md)** - Compilation guide
- **[GitHub Actions Documentation](https://docs.github.com/en/actions)** - Official documentation

---

## 🔗 Quick Reference

| Action | Where | What It Does |
|--------|-------|-------------|
| Configure permissions | Settings → Actions → General | Allows creating releases |
| Add secrets | Settings → Secrets → Actions | Encrypted variables |
| View workflows | "Actions" tab | Monitor executions |
| View logs | Actions → Workflow → Job | Debugging |
