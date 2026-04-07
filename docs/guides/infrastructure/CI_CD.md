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
- [Path filtering (docs-only changes)](#path-filtering-docs-only-changes)
  - [Workflow inventory](#workflow-inventory)
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

## Path filtering (docs-only changes)

**Problem**: A pull request that only edits documentation (for example `CHANGELOG.md`, `docs/**/*.md`, or other Markdown) does not need the same heavy jobs as code changes, but workflows still used to **start** every job and pay setup cost (checkout, Go, Foundry) before skipping the test step.

**Approach**: Use a small prerequisite job with [`dorny/paths-filter`](https://github.com/dorny/paths-filter) and **`if:` on downstream jobs** so jobs that only exist to run Go tests, coverage, or system tests are **not scheduled** when no matching paths changed.

**Implemented in this repo** (job-level [`dorny/paths-filter`](https://github.com/dorny/paths-filter) + `needs` / `if`):

| Workflow | File | Behavior |
|----------|------|------------|
| Tests | [test.yml](../../../.github/workflows/test.yml) | `tests_go` / `tests_scripts` gate **`test-unit-cover`** (matrix: four `make test-unit-cover-*` blocks) and `test-scripts`. |
| System Test | [system-test.yml](../../../.github/workflows/system-test.yml) | `code` gates `test-system`. |
| JSON-RPC compat | [jsonrpc-compatibility.yml](../../../.github/workflows/jsonrpc-compatibility.yml) | `code` gates the Docker test job (covers **merge_group** / **push** where workflow-level `paths` do not apply). |
| Solidity | [solidity-test.yml](../../../.github/workflows/solidity-test.yml) | `code` gates `make test-solidity`. |
| CodeQL | [codeql-analysis.yml](../../../.github/workflows/codeql-analysis.yml) | Per-language matrix legs run only when matching paths (or this workflow) changed. |
| Lint | [lint.yml](../../../.github/workflows/lint.yml) | `go` / `markdown` gates **golangci** vs **markdownlint** separately. |
| Slither | [slither.yml](../../../.github/workflows/slither.yml) | `sol` gates analysis. |
| Solhint | [solhint.yml](../../../.github/workflows/solhint.yml) | `sol` gates **solhint**. |
| Markdown links | [markdown-links.yml](../../../.github/workflows/markdown-links.yml) | `md` gates link check. |
| Build | [build.yml](../../../.github/workflows/build.yml) | `code` gates the matrix on **push**; **workflow_dispatch** always builds. |

**Branch protection**: If a repository **required check** names a job that becomes **skipped** on docs-only PRs, GitHub may block the merge. Options: require a workflow that always completes, use a small aggregate job, or do not require skipped jobs. Adjust **Settings → Rules / Branch protection** to match.

**Tests — `test-unit-cover` matrix**: The **Tests** workflow runs **four** coverage legs; each job is named **`test-unit-cover (<block>)`** with `block` ∈ `evm-core`, `evm-integration`, `infinited-core`, `infinited-integration` (short PR check names; the `Makefile` targets remain `test-unit-cover-*`). If you require checks by name, expect **`Tests / test-unit-cover (evm-core)`** (etc.) or verify under **Actions** after the first run. Rationale: [guides/development/TESTING.md — Granular coverage blocks](../development/TESTING.md#granular-coverage-blocks-test-unit-cover).

**Extending**: To skip more heavy workflows on docs-only changes, add a `changes` job (or reuse a reusable workflow) and gate jobs with `needs` + `if: needs.changes.outputs.<name> == 'true'`. Keep filter lists in sync with what actually affects the job.

### Workflow inventory

All workflows under [`.github/workflows/`](../../../.github/workflows/):

| Workflow | Triggers (summary) | Cost / note | Apply job-level `paths-filter`? |
|----------|-------------------|-------------|-----------------------------------|
| [test.yml](../../../.github/workflows/test.yml) | PR, merge queue, push `main` / `release/**` | High (Go, **four** coverage matrix legs + Codecov each) | **Done** |
| [system-test.yml](../../../.github/workflows/system-test.yml) | Same pattern | High (Go + Foundry) | **Done** |
| [jsonrpc-compatibility.yml](../../../.github/workflows/jsonrpc-compatibility.yml) | PR **with paths**, plus **merge_group** and **push** | **High** | **Done** (see table above). |
| [codeql-analysis.yml](../../../.github/workflows/codeql-analysis.yml) | PR | **High** | **Done** — per-language matrix `if`. |
| [solidity-test.yml](../../../.github/workflows/solidity-test.yml) | PR, merge queue, push | Medium | **Done**. |
| [lint.yml](../../../.github/workflows/lint.yml) | PR, merge queue | Medium / low | **Done** — separate gates for Go vs Markdown. |
| [slither.yml](../../../.github/workflows/slither.yml) | PR | Medium | **Done**. |
| [solhint.yml](../../../.github/workflows/solhint.yml) | PR | Low–medium | **Done**. |
| [markdown-links.yml](../../../.github/workflows/markdown-links.yml) | PR to `main` / `release/**` | Low | **Done**. |
| [build.yml](../../../.github/workflows/build.yml) | PR with `paths:`; push; `workflow_dispatch` | High | **Done** — internal filter on **push**; dispatch always builds. |
| [proto.yml](../../../.github/workflows/proto.yml) | PR with `paths: proto/**` only | Medium | **No** — workflow does not run on docs-only PRs. Inner `get-diff` is optional cleanup only. |
| [tests-compatibility-*.yml](../../../.github/workflows/) (Foundry, Hardhat, Web3.js, Viem, Uniswap v3) | PR/push `main`/`develop` with `paths:` per harness | High (Go + Foundry + Node) | **Low priority** — already scoped by directory/scripts in `on: paths` (verify paths are correct relative to repo root; some entries use `../../scripts/…`, which may not match). |
| [release.yml](../../../.github/workflows/release.yml) | Tags `v*.*.*`, `workflow_dispatch` | Release build | **No** — not tied to arbitrary PR doc edits. |
| [dependencies.yml](../../../.github/workflows/dependencies.yml) | `workflow_dispatch`, schedule | Medium | **No** — not triggered by normal PRs. |
| [bsr-push.yml](../../../.github/workflows/bsr-push.yml), [trigger-docs-update.yml](../../../.github/workflows/trigger-docs-update.yml) | Manual / disabled | N/A | **No** — disabled by fork policy. |
| [stale.yml](../../../.github/workflows/stale.yml) | Schedule | Low | **No**. |
| [pr_title.yml](../../../.github/workflows/pr_title.yml), [labeler.yml](../../../.github/workflows/labeler.yml) | PR metadata | Very low | **No** — should run on every PR; cost is negligible. |

**Summary**: Heavy PR / merge-queue workflows listed above now use the same **changes** pattern where it mattered. **Proto** and **evm-tools-compatibility** workflows remain scoped by workflow-level `on: paths`; verify those globs match repo paths (some scripts used `../../` prefixes that GitHub may not match).

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
