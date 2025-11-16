# Testing Guide - Infinite Drive

Guide for running tests and validating Infinite Drive code.

## 📋 Table of Contents

- [Test Types](#test-types)
- [Unit Tests](#unit-tests)
- [Integration Tests](#integration-tests)
- [Complete Tests](#complete-tests)
- [Tests with Coverage](#tests-with-coverage)
- [Code Validation](#code-validation)

## 🧪 Test Types

| Type | Command | What It Tests | Time |
|------|---------|---------------|------|
| **Unit** | `make test-unit` | Individual functions | 5-15 min |
| **Integration** | `make test-infinited` | Component integration | 10-20 min |
| **Complete** | `make test-all` | All tests | 15-30 min |
| **With Coverage** | `make test-unit-cover` | Tests + coverage report | 10-20 min |

---

## 🔬 Unit Tests

**Purpose**: Test individual functions and components of the code.

**What it tests**: Function logic, validations, calculations, etc.

**When to use**: After making code changes, before commit

### Run Unit Tests

```bash
# Run all unit tests
make test-unit
```

**What it does**:
- Runs all unit tests in the project
- Shows results in real time
- Reports failures if any

**Estimated time**: 5-15 minutes

**Expected output**:
```
?       github.com/cosmos/evm    [no test files]
ok      github.com/cosmos/evm/x/vm/types    0.123s
ok      github.com/cosmos/evm/x/vm/keeper   2.456s
...
```

### Specific Unit Tests

```bash
# Run tests for a specific package
cd x/vm/types
go test -v

# Run a specific test
go test -v -run TestFunctionName
```

---

## 🔗 Integration Tests

**Purpose**: Test integration between different system components.

**What it tests**: Module interaction, complete flows, configuration

**When to use**: Before important releases, after major changes

### Run Integration Tests

```bash
# Integration tests for infinited
make test-infinited
```

**What it does**:
- Runs integration tests specific to `infinited`
- Tests complete application flows
- Validates configuration and initialization

**Estimated time**: 10-20 minutes

---

## ✅ Complete Tests

**Purpose**: Run all tests (unit + integration).

**What it tests**: Complete system

**When to use**: Before releases, after important changes, CI/CD

### Run All Tests

```bash
# Run all tests
make test-all
```

**What it does**:
- Runs unit tests
- Runs integration tests
- Runs additional tests

**Estimated time**: 15-30 minutes

---

## 📊 Tests with Coverage

**Purpose**: Run tests and generate code coverage report.

**What you get**: Report showing what percentage of code is covered by tests

**When to use**: To verify test quality, identify uncovered code

### Run Tests with Coverage

```bash
# Unit tests with coverage
make test-unit-cover
```

**What it does**:
- Runs unit tests
- Generates coverage report in `coverage.txt`

**Estimated time**: 10-20 minutes

### View Coverage Report

```bash
# View report in terminal
go tool cover -func=coverage.txt

# View HTML report (opens in browser)
go tool cover -html=coverage.txt
```

---

## 🔍 Code Validation

**Purpose**: Validate that customizations are correctly implemented.

**Script**: `scripts/validate_customizations.sh`

**What it validates**:
- ✅ Token configuration (denoms, chain ID)
- ✅ Custom genesis functions
- ✅ Bech32 prefixes
- ✅ Upstream compliance

**Usage**:
```bash
# Validate customizations
./scripts/validate_customizations.sh
```

**When to use**: 
- After making changes
- Before commit
- During merges with upstream

**More information**: See [guides/testing/VALIDATION.md](../testing/VALIDATION.md)

---

## 🐛 Troubleshooting

### Tests Fail

**Problem**: Some tests fail

**Solutions**:
1. **Verify no processes are running**:
   ```bash
   # Verify infinited processes
   ps aux | grep infinited
   
   # Kill processes if necessary
   pkill infinited
   ```

2. **Clean and recompile**:
   ```bash
   rm -rf build/
   make install
   ```

3. **Run tests again**:
   ```bash
   make test-unit
   ```

### Tests Very Slow

**Causes**:
- First run (downloads dependencies)
- Slow system
- Many tests

**Solutions**:
- First time: It's normal, may take longer
- Run specific tests instead of all
- Close other applications

### Coverage Not Generated

**Problem**: `coverage.txt` is not created

**Solution**:
```bash
# Make sure you run the correct command
make test-unit-cover

# Verify it was created
ls -la coverage.txt
```

---

## 📚 More Information

- **[guides/testing/VALIDATION.md](../testing/VALIDATION.md)** - Node validation scripts
- **[guides/development/BUILDING.md](BUILDING.md)** - Compilation guide
- **[CUSTOMIZATIONS.md](../../CUSTOMIZATIONS.md)** - Customizations reference

---

## 🔗 Quick Reference

| Need | Command | Time |
|------|---------|------|
| Quick tests | `make test-unit` | 5-15 min |
| Complete tests | `make test-all` | 15-30 min |
| Coverage | `make test-unit-cover` | 10-20 min |
| Validate code | `./scripts/validate_customizations.sh` | <1 min |
