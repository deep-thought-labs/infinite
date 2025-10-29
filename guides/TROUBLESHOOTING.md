# Troubleshooting

**When to use this**: When something isn't working as expected or you get error messages.

This guide covers common issues you might encounter and how to solve them.

## Table of Contents

1. [Common Issues](#common-issues)
2. [Getting Help](#getting-help)
3. [Useful Diagnostic Commands](#useful-diagnostic-commands)
4. [Performance Issues](#performance-issues)

## Common Issues

### 1. "infinited: command not found"

**What this means**: The system can't find the `infinited` binary.

**Why this happens**: The binary is installed to `$HOME/go/bin/` but this directory isn't in your PATH.

**Solution**:
```bash
# Temporary fix (for current session)
export PATH=$HOME/go/bin:$PATH

# Permanent fix (add to shell configuration)
echo 'export PATH=$HOME/go/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Verify it works
which infinited
```

### 2. "go: command not found"

**What this means**: Go programming language is not installed or not in PATH.

**Why this happens**: Go wasn't installed properly or PATH wasn't configured.

**Solution**:
```bash
# Install Go from https://golang.org/dl/
# Then add to PATH as shown in Prerequisites section
export PATH=$PATH:/usr/local/go/bin
```

### 3. "make: command not found"

**What this means**: Build tools are not installed.

**Why this happens**: Your system doesn't have the necessary build tools.

**Solution**:
```bash
# Ubuntu/Debian
sudo apt install build-essential

# macOS
xcode-select --install

# Verify installation
make --version
```

### 4. Port Already in Use

**What this means**: Another process is using the ports that Infinite Drive needs.

**Why this happens**: You might have another blockchain node running or another service using the same ports.

**Solution**:
```bash
# Check what's using the ports
lsof -i :8545  # JSON-RPC
lsof -i :1317  # REST API
lsof -i :26657 # Tendermint RPC

# Kill the process (replace PID with actual process ID)
kill -9 <PID>

# Or change ports in configuration if needed
```

### 5. Permission Denied

**What this means**: You don't have permission to access the data directory.

**Why this happens**: The data directory was created with different permissions.

**Solution**:
```bash
# Fix permissions
sudo chown -R $USER:$USER ~/.infinited
chmod -R 755 ~/.infinited
```

### 6. "No space left on device"

**What this means**: Your disk is full.

**Why this happens**: Blockchain data grows over time and needs sufficient disk space.

**Solution**:
```bash
# Check disk usage
df -h

# Clean up if needed
# Remove old logs, temporary files, etc.
```

### 7. Node Won't Start

**What this means**: The blockchain node fails to start or crashes immediately.

**Why this happens**: Configuration issues, missing dependencies, or corrupted data.

**Solution**:
```bash
# Check logs for errors
tail -f ~/.infinited/logs/infinited.log

# Check if ports are available
netstat -tlnp | grep -E "(8545|1317|26657)"

# Try starting with verbose logging
infinited start --log-level debug

# Reset data directory if corrupted (WARNING: This deletes all data)
rm -rf ~/.infinited
./local_node.sh
```

### 8. API Endpoints Not Responding

**What this means**: The node is running but API calls fail.

**Why this happens**: Network configuration issues or service not properly started.

**Solution**:
```bash
# Check if services are running
curl -s http://localhost:8545 -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'

# Check firewall settings
sudo ufw status

# Check if node is syncing
curl -s http://localhost:26657/status | jq '.result.sync_info.catching_up'
```

### 9. Chain ID Mismatch

**What this means**: The chain ID returned by the API doesn't match expected values.

**Why this happens**: Configuration mismatch or wrong genesis file.

**Solution**:
```bash
# Check current chain ID
curl -s http://localhost:26657/status | jq '.result.node_info.network'

# Expected: "421018"
# If different, check genesis file
cat ~/.infinited/config/genesis.json | jq '.chain_id'
```

### 10. Token Metadata Issues

**What this means**: TEA token metadata is incorrect or missing.

**Why this happens**: Genesis configuration issues or metadata not properly set.

**Solution**:
```bash
# Check token metadata
curl -s http://localhost:1317/cosmos/bank/v1beta1/denoms_metadata | jq '.metadatas[] | select(.base == "drop")'

# Expected to show TEA token with proper metadata
# If missing, check genesis file
cat ~/.infinited/config/genesis.json | jq '.app_state.bank.denom_metadata'
```

## Getting Help

If you encounter issues not covered in this guide:

1. **Check the logs**: Look in `~/.infinited/logs/` for error messages
2. **Run health check**: Use `./infinite_health_check.sh` to diagnose issues
3. **Check system resources**: Ensure sufficient RAM and disk space
4. **Verify network**: Ensure ports are not blocked by firewall
5. **Check systemd logs** (if using production setup): `sudo journalctl -u infinited`

### Additional Resources

- **Documentation**: Check the `infinite/` folder for detailed documentation
- **Health Scripts**: Use `./infinite_health_check.sh` for diagnostics
- **Issues**: Report bugs and issues on GitHub
- **Community**: Join our community discussions

## Useful Diagnostic Commands

**What these commands do**: Help you diagnose issues with your node.

### Process and Service Status

```bash
# Check if node is running
ps aux | grep infinited

# Check node status (if accessible)
infinited status

# Check systemd service status (production)
sudo systemctl status infinited

# View recent logs
tail -f ~/.infinited/logs/infinited.log

# View systemd logs (production)
sudo journalctl -u infinited -f
```

### System Resources

```bash
# Check disk usage
du -sh ~/.infinited
df -h

# Check memory usage
ps -p $(pgrep infinited) -o rss,vsz
free -h

# Check CPU usage
top -p $(pgrep infinited)
```

### Network and Connectivity

```bash
# Check network connections
netstat -tlnp | grep -E "(8545|1317|26657)"

# Test API endpoints
curl -s http://localhost:8545 -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'

# Test REST API
curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info

# Test Tendermint RPC
curl -s http://localhost:26657/status
```

### Blockchain State

```bash
# Check latest block height
curl -s http://localhost:26657/status | jq '.result.sync_info.latest_block_height'

# Check if node is syncing
curl -s http://localhost:26657/status | jq '.result.sync_info.catching_up'

# Check chain ID
curl -s http://localhost:26657/status | jq '.result.node_info.network'

# Check token metadata
curl -s http://localhost:1317/cosmos/bank/v1beta1/denoms_metadata
```

### Configuration Files

```bash
# Check genesis file
cat ~/.infinited/config/genesis.json | jq '.'

# Check config file
cat ~/.infinited/config/config.toml

# Check app config
cat ~/.infinited/config/app.toml
```

## Performance Issues

### High Memory Usage

**Symptoms**: Node uses excessive RAM, system becomes slow.

**Solutions**:
```bash
# Check memory usage
ps -p $(pgrep infinited) -o rss,vsz

# Restart node to clear memory
sudo systemctl restart infinited

# Check for memory leaks in logs
sudo journalctl -u infinited | grep -i memory
```

### Slow Block Production

**Symptoms**: Blocks take longer than expected to be produced.

**Solutions**:
```bash
# Check if node is syncing
curl -s http://localhost:26657/status | jq '.result.sync_info.catching_up'

# Check disk I/O
iostat -x 1

# Check network latency
ping -c 10 8.8.8.8
```

### High CPU Usage

**Symptoms**: Node uses excessive CPU, system becomes unresponsive.

**Solutions**:
```bash
# Check CPU usage
top -p $(pgrep infinited)

# Check for infinite loops in logs
sudo journalctl -u infinited | grep -i "error\|panic"

# Restart node
sudo systemctl restart infinited
```

### Disk Space Issues

**Symptoms**: Node stops working due to insufficient disk space.

**Solutions**:
```bash
# Check disk usage
df -h
du -sh ~/.infinited

# Clean up old logs
find ~/.infinited/logs -name "*.log" -mtime +7 -delete

# Clean up old backups
find /opt/backups -name "*.tar.gz" -mtime +30 -delete
```

## Next Steps

- **[Development Guide](DEVELOPMENT_GUIDE.md)** - Learn more about development and testing
- **[Production Deployment](PRODUCTION_DEPLOYMENT.md)** - Deploy to production with proper monitoring
- **[Node Health Scripts](NODE_HEALTH_SCRIPTS.md)** - Comprehensive health monitoring and verification tools
- **Community Support**: Join discussions and get help from other users
- **Report Issues**: Help improve Infinite Drive by reporting bugs
