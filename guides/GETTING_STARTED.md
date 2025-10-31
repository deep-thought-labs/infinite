# Getting Started with Infinite Drive

**Goal**: Get your blockchain node running in minutes, then learn advanced configuration options.

Infinite Drive is a Cosmos EVM-compatible blockchain.

## Quick Navigation

- **[Prerequisites](#prerequisites)** - System requirements and environment setup
- **[Quick Start](#quick-start)** - Get running in 5 minutes with automated script
- **[Understanding What Just Happened](#understanding-what-just-happened)** - What the script created for you
- **[Next Steps](#next-steps)** - Choose your path forward

## Prerequisites

Before you begin, ensure your system meets the following requirements:

### System Requirements

- **Operating System**: Linux, macOS, or Windows (with WSL2)
- **RAM**: Minimum 4GB, Recommended 8GB+
- **Storage**: At least 10GB free space
- **CPU**: Multi-core processor recommended

### Platform Support Notice

**What this means**: Infinite Drive supports multiple operating systems, but this documentation focuses on Unix-like systems.

**Recommended Platforms**:
- **Linux (Ubuntu/Debian)**: Full support with detailed instructions
- **macOS**: Full support with detailed instructions
- **Windows**: Supported but requires WSL2; limited documentation

**Why Unix-like systems**: The blockchain ecosystem and tools are primarily designed for Unix-like systems. While Windows is supported, we recommend using:
- **Ubuntu Server** (for production)
- **Ubuntu Desktop** (for development)
- **macOS** (for development)
- **Docker containers** with Ubuntu (for any platform)

**Current Documentation Scope**: This guide provides detailed instructions for Linux/Unix systems. Windows users can follow along but may need to adapt some commands for WSL2.

### Required Software

#### 1. Go Programming Language
**What it is**: Go is the programming language used to build Infinite Drive.  
**Why you need it**: The blockchain node is written in Go and needs Go to compile.

**Installation Options**:

**Option A: Install via package manager (Recommended)**
```bash
# Ubuntu/Debian:
sudo apt update
sudo apt install golang-go

# macOS (with Homebrew):
brew install go

# Verify installation
go version
# Should output: go version go1.25.x linux/amd64 (or your architecture)
```

**Option B: Manual installation**
```bash
# Visit https://golang.org/dl/ and download the appropriate version for your OS
# Follow the installation instructions for your platform

# Verify installation
go version
```

#### 2. Git
**What it is**: Version control system to download the source code.  
**Why you need it**: Required to clone the Infinite Drive repository.

```bash
# Install Git (if not already installed)
# Ubuntu/Debian:
sudo apt update && sudo apt install git

# macOS (with Homebrew):
brew install git

# Verify installation
git --version
```

#### 3. Make (Build Tool)
**What it is**: Build automation tool that simplifies compilation.  
**Why you need it**: The project uses Makefile for easy compilation.

```bash
# Ubuntu/Debian:
sudo apt install build-essential

# macOS (usually pre-installed):
# If not available, install Xcode Command Line Tools:
xcode-select --install

# Verify installation
make --version
```

#### 4. curl (HTTP Client)
**What it is**: Command-line tool for making HTTP requests.  
**Why you need it**: Required for testing APIs and health checks.

```bash
# Ubuntu/Debian:
sudo apt install curl

# macOS (usually pre-installed):
# If not available, install Homebrew first, then:
brew install curl

# Verify installation
curl --version
```

#### 5. jq (JSON Processor) - Optional but Recommended
**What it is**: Command-line JSON processor for testing API responses.  
**Why it's useful**: Makes testing the blockchain APIs much easier.

```bash
# Ubuntu/Debian:
sudo apt install jq

# macOS:
brew install jq

# Verify installation
jq --version
```

### Optional Development Tools

**What these are**: Additional tools for comprehensive development, code quality checks, and smart contract work.  
**Why they're optional**: They are NOT required to compile the main `infinited` binary. Only install if you plan to:
- Develop or modify smart contracts
- Work on Python scripts
- Run full linting checks
- Contribute code to the project

#### Python Linters (Optional)
**When you need them**: Only if working on Python scripts (e.g., `scripts/compile_smart_contracts/`).  
**What they do**: Check Python code quality and style.

```bash
# Install both Python linters
pip install pylint flake8

# Verify installation
pylint --version
flake8 --version
```

**Note**: The main binary compiles fine without these. They're only for Python script development.

#### Solidity Linter (Optional)
**When you need it**: Only if developing or modifying smart contracts in `contracts/`.  
**What it does**: Checks Solidity contract code quality.

```bash
# Install solhint (requires Node.js and npm)
npm install -g solhint@v5.0.5

# Verify installation
solhint --version
```

**Note**: Smart contracts are pre-compiled. You only need this if modifying contract code.

#### Summary: What You Actually Need

| Tool | Required for Binary? | When You Need It |
|------|----------------------|------------------|
| **Go** | ✅ YES | Always - compiles the binary |
| **Git** | ✅ YES | To clone the repository |
| **Make** | ✅ YES | For build automation |
| **curl** | ✅ YES | Testing APIs and health checks |
| **jq** | ⚠️ Recommended | Testing and debugging |
| **pylint/flake8** | ❌ Optional | Python script development only |
| **solhint** | ❌ Optional | Smart contract development only |

**Bottom line**: To compile and run `infinited`, you only need Go, Git, Make, and curl. The linters are quality assurance tools for contributing code.

### Environment Setup

#### Configure Go Environment (REQUIRED)
**What this does**: Sets up your system to find Go and compiled binaries.  
**Why it's important**: Without this, you'll get "command not found" errors when trying to run `infinited`.

#### For macOS

```bash
# Add Go to your PATH permanently (if Go is installed manually)
echo 'export PATH="$PATH:/usr/local/go/bin"' >> ~/.zshrc
echo 'export PATH="$PATH:/usr/local/go/bin"' >> ~/.zprofile

# Set GOPATH (though Go 1.11+ uses modules, some tools still reference it)
echo 'export GOPATH="$HOME/go"' >> ~/.zshrc
echo 'export GOPATH="$HOME/go"' >> ~/.zprofile

# Add Go bin directory (where make install places binaries like infinited)
echo 'export PATH="$PATH:$GOPATH/bin"' >> ~/.zshrc
echo 'export PATH="$PATH:$GOPATH/bin"' >> ~/.zprofile

# Reload your shell configuration
source ~/.zshrc
```

**Note**: If Go was installed via Homebrew, the `/usr/local/go/bin` path may not be needed (Homebrew usually handles this automatically). You can skip those lines if `go version` already works.

#### For Ubuntu/Linux

```bash
# Add Go to your PATH permanently (if Go is installed manually)
echo 'export PATH="$PATH:/usr/local/go/bin"' >> ~/.bashrc
echo 'export PATH="$PATH:/usr/local/go/bin"' >> ~/.profile

# Set GOPATH (though Go 1.11+ uses modules, some tools still reference it)
echo 'export GOPATH="$HOME/go"' >> ~/.bashrc
echo 'export GOPATH="$HOME/go"' >> ~/.profile

# Add Go bin directory (where make install places binaries like infinited)
echo 'export PATH="$PATH:$GOPATH/bin"' >> ~/.bashrc
echo 'export PATH="$PATH:$GOPATH/bin"' >> ~/.profile

# Reload your shell configuration
source ~/.bashrc
```

**Note**: If Go was installed via `apt`, it's usually already in PATH at `/usr/bin/go`. You can skip the `/usr/local/go/bin` lines if `go version` already works without them.

**Important Notes**:
- The `$GOPATH/bin` directory is where compiled binaries will be installed (like `infinited`)
- This ensures that when you run `make install`, the `infinited` binary will be accessible from anywhere
- After applying this configuration, **open a new terminal window** and run `go version` to verify it persists
- For troubleshooting PATH issues, see the [PATH Configuration section in Troubleshooting](TROUBLESHOOTING.md#path-configuration-issues-fixes-most-command-not-found-errors)

## Quick Start

**What we're doing**: Using the automated script to compile, configure, and start your blockchain node with test data.

### 1. Clone the Repository

```bash
# Clone the Infinite Drive repository
git clone https://github.com/deep-thought-labs/infinite.git
cd infinite

# Verify you're in the correct directory
ls -la
# You should see: Makefile, go.mod, infinited/, infinite/, local_node.sh, etc.
```

### 2. Run the Automated Setup Script

**What this script does**:
- Compiles the blockchain binary (`infinited`)
- Creates a test blockchain with sample accounts
- Starts the node with all necessary services
- Initializes token metadata for local testing

```bash
# Run the automated setup (this will take 2-3 minutes)
./local_node.sh
```

**What happens during execution**:
1. **Compilation**: Downloads dependencies and compiles `infinited`
2. **Configuration**: Creates blockchain configuration files
3. **Genesis Setup**: Creates initial blockchain state with test accounts
4. **Node Start**: Launches the blockchain node with all services

### 3. Understanding the Script Options

The `local_node.sh` script has different options depending on your needs:

```bash
# Fresh start (recommended for first time)
./local_node.sh

# Skip compilation (if already compiled and want faster startup)
./local_node.sh --no-install
```

**When to use each option**:
- **First time**: Use `./local_node.sh` (full setup including compilation)
- **Subsequent runs**: Use `./local_node.sh --no-install` (skips compilation, faster startup)
- **Fresh blockchain**: Delete `~/.infinited` folder first, then run `./local_node.sh`
- **Development testing**: Use `--no-install` for quick restarts during development

### 4. Verify Everything is Working

After the script completes, you should see:
- Blockchain node running and producing blocks
- Three services available:
  - **JSON-RPC (EVM)**: `http://localhost:8545`
  - **REST API**: `http://localhost:1317` 
  - **Tendermint RPC**: `http://localhost:26657`

**Quick test**:
```bash
# Test if the node is responding
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://localhost:8545

# Expected response: a hex chain ID (e.g., mainnet 0x66c9a for 421018, or testnet 0x1919b571 for 421018001)
```

**Setup complete.** The node is running with:
- ✅ EVM compatibility (Ethereum tools work)
- ✅ TEA token configured
- ✅ Test accounts with balances
- ✅ All APIs responding

## Understanding What Just Happened

**What the script created for you**:

### 1. Binary Location
The `infinited` binary was compiled and installed to: `$HOME/go/bin/infinited`

**Why this location**: This is the standard Go workspace location. By adding `$GOPATH/bin` to your PATH (done in Prerequisites), the system can find the binary from anywhere.

**Important**: If you manually compile binaries to other locations later, you might have conflicts. Always use `make install` for consistency.

### 2. Data Directory
Blockchain data is stored in: `~/.infinited/`

**What's inside**:
- `config/`: Blockchain configuration files
- `data/`: Blockchain state and blocks
- `keys/`: Test account keys (for development only)

### 3. Running Services
Your node is running three services simultaneously:

- **JSON-RPC (Port 8545)**: Ethereum-compatible API for dApps
- **REST API (Port 1317)**: Cosmos SDK API for blockchain queries  
- **Tendermint RPC (Port 26657)**: Low-level blockchain RPC

### 4. Network & Genesis Notes
The script creates a local development blockchain. In real networks you MUST use the official genesis files provided by Infinite:

- **Mainnet**:
  - Cosmos Chain ID: `infinite_421018-1`
  - EVM Chain ID: `421018`
  - Bech32 prefix: `infinite`
  - Token: Improbability (display `TEA`, base `drop`)

- **Testnet**:
  - Cosmos Chain ID: `infinite_421018001-1`
  - EVM Chain ID: `421018001`
  - Bech32 prefix: `infinitetest`
  - Token: Improbability (display `TEA-test`, base `drop`)

IMPORTANT:
- Always use the officially published `genesis.json` for the target network.
- Do NOT mix mainnet/testnet chain IDs or prefixes.
- Start nodes always passing both chain IDs via flags:
  - Mainnet:
    ```bash
    infinited start \
      --chain-id infinite_421018-1 \
      --evm.evm-chain-id 421018
    ```
  - Testnet:
    ```bash
    infinited start \
      --chain-id infinite_421018001-1 \
      --evm.evm-chain-id 421018001
    ```
- The examples in this guide are for local development only.

Defaults (when flags are omitted):
- Cosmos chain-id: read from `genesis.json` in the selected home
- EVM chain-id: defaults to Mainnet `421018`
- Home directory: defaults to `~/.infinited` (Mainnet path)

## Next Steps

Now that your node is running, choose your path forward:

### 🧪 **For Testing & Development**
- **[Development Guide](DEVELOPMENT_GUIDE.md)** - Learn how to test your node, compile manually, and understand the blockchain internals
- **[Troubleshooting](TROUBLESHOOTING.md)** - Common issues and solutions

### 🚀 **For Production Deployment**
- **[Production Deployment](PRODUCTION_DEPLOYMENT.md)** - Deploy to production servers with proper security, monitoring, and service management

### 📚 **For Learning More**
- **Explore the APIs**: Try the JSON-RPC and REST API endpoints
- **Deploy Smart Contracts**: Use tools like Hardhat or Foundry
- **Join the Network**: Connect to other nodes in the network
- **Contribute**: Help improve Infinite Drive by contributing to the project

## Support

- **Documentation**: Check the `infinite/` folder for detailed documentation
- **Health Scripts**: Use `./infinite_health_check.sh` for diagnostics
- **Issues**: Report bugs and issues on GitHub
- **Community**: Join our community discussions

---

*You're ready to proceed.*
