## Pull request title (required for CI)

The workflow **PR Conventional Commit Validation** checks the **title** of this pull request (not this description). Use [Conventional Commits](https://www.conventionalcommits.org/) style:

```text
type: short summary
```

Optional scope:

```text
type(scope): short summary
```

**Allowed types** (must be one of these — case-sensitive prefix before `:`):

| Type | When to use it |
|------|----------------|
| **feat** | New user-facing capability or API (a “feature”). |
| **fix** | A bug fix or correction of incorrect behavior. |
| **docs** | Documentation only (README, comments, guides, no logic change). |
| **test** | Adding or changing tests only (no production behavior change). |
| **ci** | Continuous integration / GitHub Actions / build pipelines. |
| **refactor** | Internal restructuring without changing external behavior. |
| **perf** | Performance improvements (speed, memory, less work). |
| **chore** | Maintenance that does not fit elsewhere (deps bump, tooling, housekeeping). |
| **revert** | Reverts a previous commit (often `revert: …`). |
| **style** | Formatting, whitespace, lint-only fixes (no logic change). |
| **build** | Build system, compiler flags, packaging, or release tooling. |

Examples: `feat: add ledger test helpers`, `ci: use ubuntu-latest for workflows`, `fix: correct bech32 prefix in IBC tests`.

---

# Description

<!-- Add a description of the changes that this PR introduces and the files that
are the most critical to review. -->

<!-- Please keep your PR as draft until it's ready for review -->

<!-- Pull requests that sit inactive for longer than 30 days will be closed.  -->

Closes: #XXXX

---

## Author Checklist

**All** items are required. Please add a note to the item if the item is not applicable and
please add links to any relevant follow up issues.

I have...

- [ ] tackled an existing issue or discussed with a team member
- [ ] left instructions on how to review the changes
- [ ] targeted the `main` branch
