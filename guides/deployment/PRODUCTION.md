# Production Deployment

**⚠️ PRODUCTION READY**: These instructions are designed for actual production deployment with proper security, service management, and monitoring.

**Important**: This section uses different data directory locations (`/opt/infinited`) compared to development (`~/.infinited`). This is intentional for production security and organization.

## Table of Contents

1. [Option A: Building Production Binary](#option-a-building-production-binary)
2. [Option B: Downloading Precompiled Binaries (Recommended)](#option-b-downloading-precompiled-binaries-recommended)
3. [System Service Setup (systemd)](#system-service-setup-systemd)
4. [Firewall Configuration](#firewall-configuration)
5. [Production Monitoring](#production-monitoring)
6. [Security Considerations](#security-considerations)
7. [Post-Deployment Configuration](#post-deployment-configuration)

## Option A: Building Production Binary

**What this does**: Creates optimized binaries for production deployment with smaller size and better performance.

**Why optimize**: Production binaries should be smaller, faster, and not include debug information.

### Step 0: Clean Previous Development Binaries

**What this does**: Removes any development binaries to avoid confusion.

**Why this is important**: You might have development binaries from testing that could conflict with production binaries.

```bash
# Remove development binary to avoid confusion
rm -f $HOME/go/bin/infinited

# Verify it's removed
which infinited
# Should return nothing or "infinited not found"
```

### Step 1: Build Production Binary

**What this does**: Compiles the Infinite Drive binary with production optimizations.

**Why this step**: Creates optimized binaries that are smaller and faster than development builds.

```bash
# Build with production optimizations for Linux
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o infinited-linux-amd64 ./infinited/cmd/infinited

# For macOS (Intel)
CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -ldflags="-w -s" -o infinited-darwin-amd64 ./infinited/cmd/infinited

# For macOS (Apple Silicon)
CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build -ldflags="-w -s" -o infinited-darwin-arm64 ./infinited/cmd/infinited
```

**What the flags do**:
- `CGO_ENABLED=0`: Disables CGO for static linking
- `-ldflags="-w -s"`: Strips debug information and symbol table
- `GOOS` and `GOARCH`: Target operating system and architecture

**Alternative**: If you prefer not to compile from source, you can download precompiled binaries from the [Option B: Downloading Precompiled Binaries (Recommended)](#option-b-downloading-precompiled-binaries-recommended) section below.

## Option B: Downloading Precompiled Binaries (Recommended)

**What this does**: Downloads precompiled binaries instead of building from source.

**Why use this**: Faster deployment, no need for Go toolchain, pre-optimized binaries.

**When to use**: When you want to deploy quickly without compiling from source.

### Available Platforms

**What platforms are supported**: Precompiled binaries are available for the most common platforms.

- **Linux AMD64**: `infinited-linux-amd64`
- **macOS Intel**: `infinited-darwin-amd64`
- **macOS Apple Silicon**: `infinited-darwin-arm64`
- **Windows AMD64**: `infinited-windows-amd64.exe`

### Download Commands

**What these commands do**: Download the appropriate binary for your platform.

#### Linux AMD64
```bash
# Download Linux binary
wget https://github.com/deep-thought-labs/infinite/releases/latest/download/infinited-linux-amd64

# Make executable
chmod +x infinited-linux-amd64

# Verify download
file infinited-linux-amd64
# Should show: infinited-linux-amd64: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, Go BuildID=...
```

#### macOS Intel
```bash
# Download macOS Intel binary
wget https://github.com/deep-thought-labs/infinite/releases/latest/download/infinited-darwin-amd64

# Make executable
chmod +x infinited-darwin-amd64

# Verify download
file infinited-darwin-amd64
# Should show: infinited-darwin-amd64: Mach-O 64-bit executable x86_64
```

#### macOS Apple Silicon
```bash
# Download macOS Apple Silicon binary
wget https://github.com/deep-thought-labs/infinite/releases/latest/download/infinited-darwin-arm64

# Make executable
chmod +x infinited-darwin-arm64

# Verify download
file infinited-darwin-arm64
# Should show: infinited-darwin-arm64: Mach-O 64-bit executable arm64
```

#### Windows AMD64
```bash
# Download Windows binary (in WSL2 or PowerShell)
wget https://github.com/deep-thought-labs/infinite/releases/latest/download/infinited-windows-amd64.exe

# Verify download
file infinited-windows-amd64.exe
# Should show: infinited-windows-amd64.exe: PE32+ executable (console) x86-64 (stripped to external PDB), for MS Windows
```

### Verification and Installation

**What this does**: Verifies the downloaded binary and prepares it for installation.

```bash
# Check binary version (replace with your platform)
./infinited-linux-amd64 version

# Expected output: 0.5.0-rc.0-xx-gxxxxxxxx

# Check binary integrity (optional)
sha256sum infinited-linux-amd64
# Compare with checksums from GitHub releases

# For production installation, continue with System Service Setup section
# The binary is now ready to be installed to /opt/infinited/
```

**Important**: After downloading, follow the same installation steps as in the "Option A: Building Production Binary" section, starting from Step 3 (Install Binary).

## System Service Setup (systemd)

**What this does**: Creates a system service that automatically starts, stops, and restarts your blockchain node.

**Why use systemd**: Provides automatic startup, process management, logging, and crash recovery.

**Note**: This is for Linux systems. macOS uses different service management.

### Step 2: Create Service User and Directory Structure

```bash
# Create dedicated user for security
sudo useradd -r -s /bin/false infinited

# Create directory structure (binary and data in same location for simplicity)
sudo mkdir -p /opt/infinited
sudo chown -R infinited:infinited /opt/infinited
```

### Step 3: Install Binary

```bash
# Copy binary to production location
sudo cp infinited-linux-amd64 /opt/infinited/infinited
sudo chmod +x /opt/infinited/infinited
sudo chown infinited:infinited /opt/infinited/infinited
```

### Step 4: Node Initialization

**What this does**: Initializes the blockchain node with proper configuration for production.

**Important**: Choose the correct initialization method based on your node type.

#### Option A: Full Node (Non-Validator)

**What this is**: A node that syncs the blockchain but doesn't participate in consensus.

```bash
# Initialize as full node
sudo -u infinited /opt/infinited/infinited init production-node --chain-id infinite_421018-1 --home /opt/infinited
```

#### Option B: Validator Node (Recommended for Production)

**What this is**: A node that participates in consensus and validates transactions.

**Why use this**: Validators earn rewards and help secure the network.

##### Step 3B.1: Generate Validator Keys (DRY RUN)

**What this does**: Generates validator keys without storing them in keyring.

**Why dry run**: Allows you to get the mnemonic phrase for secure storage.

```bash
# Generate validator keys (dry run - no storage)
sudo -u infinited /opt/infinited/infinited keys add validator --dry-run --keyring-backend test --home /opt/infinited

# This will output:
# - Public key
# - Address
# - Mnemonic phrase (SAVE THIS SECURELY!)
```

**Important**: Save the mnemonic phrase securely. You'll need it for the next step.

##### Step 3B.2: Initialize with Recovery

**What this does**: Initializes the node using your validator keys.

```bash
# Initialize with recovery (using your mnemonic)
sudo -u infinited /opt/infinited/infinited init production-node --chain-id infinite_421018-1 --home /opt/infinited --recover

# When prompted, enter your mnemonic phrase
# This ensures the validator key matches your generated keys
```

**Alternative**: If you have existing keys, you can use them instead of generating new ones.

### Step 5: Create Service File

```bash
# Create systemd service file
sudo nano /etc/systemd/system/infinited.service
```

**Copy this content**:
```ini
[Unit]
Description=Infinite Drive Blockchain Node
After=network.target
Wants=network.target

[Service]
Type=simple
User=infinited
Group=infinited
WorkingDirectory=/opt/infinited
ExecStart=/opt/infinited/infinited start \
  --chain-id infinite_421018-1 \
  --evm.evm-chain-id 421018 \
  --json-rpc.api eth,txpool,personal,net,debug,web3 \
  --home /opt/infinited
Restart=always
RestartSec=3
LimitNOFILE=4096
StandardOutput=journal
StandardError=journal
SyslogIdentifier=infinited

[Install]
WantedBy=multi-user.target
```

**Important**: The `--home /opt/infinited` flag ensures the node uses `/opt/infinited` as its data directory, which is where we installed the binary and initialized the node.

### Step 6: Enable and Start Service

```bash
# Reload systemd configuration
sudo systemctl daemon-reload

# Enable service to start on boot
sudo systemctl enable infinited

# Start the service
sudo systemctl start infinited

# Check service status
sudo systemctl status infinited
```

### Step 7: Service Management Commands

**What these commands do**: Allow you to manage your blockchain node service.

```bash
# Start the service
sudo systemctl start infinited

# Stop the service
sudo systemctl stop infinited

# Restart the service
sudo systemctl restart infinited

# Check service status
sudo systemctl status infinited

# View service logs
sudo journalctl -u infinited -f

# View recent logs
sudo journalctl -u infinited --since "1 hour ago"
```

## Firewall Configuration

**What this does**: Opens necessary ports for blockchain communication while keeping your server secure.

**Why configure firewall**: Blockchain nodes need specific ports open for communication.

```bash
# Allow necessary ports (Ubuntu/Debian with ufw)
sudo ufw allow 8545/tcp comment "JSON-RPC API"
sudo ufw allow 1317/tcp comment "REST API"
sudo ufw allow 26657/tcp comment "Tendermint RPC"
sudo ufw allow 26656/tcp comment "P2P (if validator)"

# Check firewall status
sudo ufw status
```

**Port explanations**:
- `8545`: JSON-RPC API for dApps and wallets
- `1317`: REST API for blockchain queries
- `26657`: Tendermint RPC for low-level access
- `26656`: P2P port for validator communication (only if running validator)

## Production Monitoring

**What this does**: Sets up automated monitoring to ensure your node stays healthy.

**Why monitor**: Production nodes need continuous monitoring to detect issues quickly.

### Automated Health Checks

```bash
# Set up cron job for health checks
crontab -e

# Add this line to check every 5 minutes
*/5 * * * * /path/to/scripts/infinite_health_check.sh >> /var/log/infinited-health.log 2>&1
```

### Log Management

```bash
# Set up log rotation
sudo nano /etc/logrotate.d/infinited
```

**Copy this content**:
```
/var/log/infinited-health.log {
    daily
    missingok
    rotate 7
    compress
    notifempty
    create 644 infinited infinited
}
```

### Performance Monitoring

```bash
# Monitor system resources
htop

# Check disk usage
df -h

# Monitor network connections
netstat -tlnp | grep -E "(8545|1317|26657)"

# Check memory usage
ps -p $(pgrep infinited) -o rss,vsz
```

## Security Considerations

### 1. Network Security

**What this covers**: Securing your node's network access.

```bash
# Restrict JSON-RPC to localhost only (if not needed externally)
# Edit the service file to add: --json-rpc.addr 127.0.0.1

# Use fail2ban to protect against brute force attacks
sudo apt install fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### 2. File Permissions

**What this covers**: Ensuring proper file permissions for security.

```bash
# Set proper permissions
sudo chown -R infinited:infinited /opt/infinited
sudo chmod -R 755 /opt/infinited
sudo chmod 600 /opt/infinited/config/node_key.json
sudo chmod 600 /opt/infinited/config/priv_validator_key.json
```

### 3. Backup Strategy

**What this covers**: Protecting your node's data.

```bash
# Create backup script
sudo nano /opt/infinited/backup.sh
```

**Copy this content**:
```bash
#!/bin/bash
BACKUP_DIR="/opt/backups/infinited"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR
tar -czf $BACKUP_DIR/infinited_backup_$DATE.tar.gz -C /opt infinited/
find $BACKUP_DIR -name "infinited_backup_*.tar.gz" -mtime +7 -delete
```

```bash
# Make executable and set up cron job
sudo chmod +x /opt/infinited/backup.sh
sudo crontab -e

# Add daily backup at 2 AM
0 2 * * * /opt/infinited/backup.sh
```

### 4. SSL/TLS Configuration (Optional)

**What this covers**: Securing API endpoints with SSL/TLS.

```bash
# Install nginx for SSL termination
sudo apt install nginx certbot python3-certbot-nginx

# Configure SSL certificate
sudo certbot --nginx -d your-domain.com

# Configure nginx reverse proxy
sudo nano /etc/nginx/sites-available/infinited
```

**Example nginx configuration**:
```nginx
server {
    listen 443 ssl;
    server_name your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:1317;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Post-Deployment Configuration

**What this covers**: Additional configuration needed after the node is running.

### 1. Verify Node Status

**What this does**: Ensures your node is running correctly and syncing.

```bash
# Check if node is running
sudo systemctl status infinited

# Check if node is syncing
curl -s http://localhost:26657/status | jq '.result.sync_info.catching_up'

# Check latest block height
curl -s http://localhost:26657/status | jq '.result.sync_info.latest_block_height'

# Check node info
curl -s http://localhost:26657/status | jq '.result.node_info'
```

### 2. Configure Genesis (If Needed)

**What this does**: Sets up the genesis configuration for your specific network.

**When needed**: If you're joining an existing network or setting up a new one.

```bash
# Download genesis file (if joining existing network)
# For mainnet:
sudo -u infinited wget -O /opt/infinited/config/genesis.json https://assets.infinitedrive.xyz/mainnet/genesis.json

# For testnet:
# sudo -u infinited wget -O /opt/infinited/config/genesis.json https://assets.infinitedrive.xyz/testnet/genesis.json

# Or configure custom genesis (if setting up new network)
sudo -u infinited nano /opt/infinited/config/genesis.json
```

### 3. Configure Peers (If Needed)

**What this does**: Connects your node to other nodes in the network.

```bash
# Add persistent peers
sudo -u infinited nano /opt/infinited/config/config.toml

# Add to persistent_peers section:
# persistent_peers = "node1@ip1:port1,node2@ip2:port2"
```

### 4. Validator-Specific Configuration

**What this does**: Additional configuration needed for validator nodes.

**Only for validators**: Skip if you're running a full node only.

```bash
# Check validator key
sudo -u infinited /opt/infinited/infinited keys show validator --home /opt/infinited

# Check validator address
sudo -u infinited /opt/infinited/infinited keys show validator --bech val --home /opt/infinited

# Create validator transaction (when ready to become validator)
sudo -u infinited /opt/infinited/infinited tx staking create-validator \
  --amount=1000000000000000000000drop \
  --pubkey=$(sudo -u infinited /opt/infinited/infinited tendermint show-validator --home /opt/infinited) \
  --moniker="your-validator-name" \
  --chain-id=infinite_421018-1 \
  --commission-rate="0.10" \
  --commission-max-rate="0.20" \
  --commission-max-change-rate="0.01" \
  --min-self-delegation="1" \
  --from=validator \
  --home /opt/infinited
```

## Maintenance

### Regular Updates

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Infinite Drive (when new versions are released)
cd /path/to/infinite
git pull
make install
sudo systemctl restart infinited
```

### Health Monitoring

```bash
# Check node health
./scripts/infinite_health_check.sh

# Monitor logs for errors
sudo journalctl -u infinited --since "1 hour ago" | grep -i error

# Check disk space
df -h /opt/infinited
```

## Next Steps

- **[Troubleshooting](TROUBLESHOOTING.md)** - Common issues and solutions
- **Join the Network**: Connect to other nodes in the network
- **Validator Setup**: Learn how to become a validator
- **Monitoring Tools**: Set up advanced monitoring with Prometheus/Grafana
