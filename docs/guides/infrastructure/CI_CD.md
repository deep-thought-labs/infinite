# CI/CD and GitHub Actions Configuration

## How this guide relates to RELEASES.md

Companion guide: **[RELEASES.md](RELEASES.md)**.

| Use **this file (`CI_CD.md`)** when you need to… | Use **[`RELEASES.md`](RELEASES.md)** when you need to… |
|--------------------------------------------------|--------------------------------------------------------|
| Set **GitHub → Settings → Actions** (**workflow permissions**), manage **Secrets**, interpret failing **workflow** logs across the repo, or confirm `.github/workflows/` is present | Execute the **release checklist**: prepare code, **tag** the version, **push** the tag, confirm the **GitHub Release** and attached **artifacts** |

**Rule of thumb**: **`CI_CD.md`** = *repository and Actions configuration + troubleshooting the automation*. **`RELEASES.md`** = *end-to-end procedure to publish a new version*.

## 📋 Table of Contents

- [What is CI/CD?](#what-is-cicd)
- [Initial Configuration](#initial-configuration)
- [GitHub Secrets](#github-secrets)
- [Release automation](#release-automation)
- [Monitor GitHub Actions](#monitor-github-actions)
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

## Release automation

Pushing a semantic tag `v*.*.*` triggers `.github/workflows/release.yml` (also supports `workflow_dispatch`). Step-by-step for maintainers (prepare code, tag, push, verify assets): **[RELEASES.md](RELEASES.md)**.

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

- **[RELEASES.md](RELEASES.md)** - Complete guide on how to create releases
- **[BUILDING.md](../development/BUILDING.md)** - Compilation guide
- **[GitHub Actions Documentation](https://docs.github.com/en/actions)** - Official documentation

---

## 🔗 Quick Reference

| Action | Where | What It Does |
|--------|-------|-------------|
| Configure permissions | Settings → Actions → General | Allows creating releases |
| Add secrets | Settings → Secrets → Actions | Encrypted variables |
| View workflows | "Actions" tab | Monitor executions |
| View logs | Actions → Workflow → Job | Debugging |
