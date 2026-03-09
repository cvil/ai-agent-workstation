# Troubleshooting Guide

Common issues and solutions for the AI Agent Workstation setup.

## Colima Issues

### Issue: "disk in use by instance" error

**Symptoms:**
```
failed to run attach disk "colima", in use by instance "colima"
```

**Cause:** Colima's disk is locked from a previous instance that didn't shut down cleanly.

**Solution:**
```bash
# Delete the stuck instance
colima delete -f

# Start fresh
colima start --cpu 4 --memory 8 --disk 100

# Verify it's running
colima status
docker ps
```

### Issue: Colima won't start after macOS update

**Solution:**
```bash
# Stop and delete
colima stop
colima delete -f

# Reinstall if needed
brew reinstall colima

# Start fresh
colima start --cpu 4 --memory 8 --disk 100
```

### Issue: Docker commands fail with "Cannot connect to the Docker daemon"

**Solution:**
```bash
# Check Colima status
colima status

# If not running, start it
colima start

# If running but Docker still fails, restart
colima restart
```

## Python Environment Issues

### Issue: Wrong Python version in venv

**Solution:**
```bash
# Remove old venv
rm -rf ~/agent-workspace/venv

# Create new venv with correct Python
/opt/homebrew/opt/python@3.12/bin/python3.12 -m venv ~/agent-workspace/venv

# Activate and reinstall packages
source ~/agent-workspace/venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install langchain langgraph crewai openai anthropic tiktoken playwright qdrant-client duckdb fastapi uvicorn
```

### Issue: pip install fails with "No module named 'pip'"

**Solution:**
```bash
# Recreate venv
rm -rf ~/agent-workspace/venv
/opt/homebrew/opt/python@3.12/bin/python3.12 -m venv ~/agent-workspace/venv
source ~/agent-workspace/venv/bin/activate
```

### Issue: tiktoken installation fails

**Cause:** Missing Rust compiler

**Solution:**
```bash
# Install Rust
brew install rust

# Try pip install again
source ~/agent-workspace/venv/bin/activate
pip install tiktoken
```

## Ollama Issues

### Issue: Ollama not responding

**Solution:**
```bash
# Check if service is running
brew services list | grep ollama

# Restart service
brew services restart ollama

# Wait a few seconds
sleep 3

# Test
curl http://localhost:11434/api/tags
```

### Issue: Model download fails or is slow

**Solution:**
```bash
# Check available space
df -h

# Try pulling again
ollama pull llama3

# If still failing, try a smaller model first
ollama pull llama3:8b
```

### Issue: "connection refused" when running ollama commands

**Solution:**
```bash
# Start Ollama service
brew services start ollama

# Check it's running
brew services list | grep ollama

# Test connection
ollama list
```

## User and Permission Issues

### Issue: "Permission denied" when accessing workspace

**Solution:**
```bash
# Fix ownership
sudo chown -R onyxv:staff /Users/onyxv/agent-workspace

# Verify
ls -la /Users/onyxv/agent-workspace
```

### Issue: Can't switch to onyxv user

**Solution:**
```bash
# Check user exists
id onyxv

# If not, create it
sudo sysadminctl -addUser onyxv -password -

# Ensure home directory exists
sudo createhomedir -c -u onyxv
```

### Issue: Shell aliases not working

**Solution:**
```bash
# Verify .zshrc exists
cat /Users/onyxv/.zshrc

# If missing, recreate it
sudo -iu onyxv bash -c 'cat > ~/.zshrc << "EOF"
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
alias workspace="cd ~/agent-workspace && source venv/bin/activate"
alias agents="~/start-agents.sh"
EOF'

# Reload shell
exec zsh
```

## Homebrew Issues

### Issue: "Permission denied" when using brew

**Solution:**
```bash
# Fix Homebrew permissions
sudo chgrp -R agenttools /opt/homebrew
sudo chmod -R g+w /opt/homebrew

# Verify group membership
dscl . -read /Groups/agenttools GroupMembership
```

### Issue: brew command not found

**Solution:**
```bash
# Add to PATH
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# Or add to shell config
echo 'export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"' >> ~/.zshrc
```

## Playwright Issues

### Issue: Chromium browser not found

**Solution:**
```bash
# Switch to agent user
sudo -iu onyxv

# Activate venv
cd ~/agent-workspace
source venv/bin/activate

# Install Chromium
python -m playwright install chromium
```

### Issue: Playwright fails with "Executable doesn't exist"

**Solution:**
```bash
# Set browser path and reinstall
export PLAYWRIGHT_BROWSERS_PATH=/Users/onyxv/.cache/ms-playwright
python -m playwright install chromium
```

## Network Issues

### Issue: Can't pull Docker images or Ollama models

**Solution:**
```bash
# Check internet connection
ping -c 3 google.com

# Check DNS
nslookup docker.io

# Try with different DNS (if needed)
# System Preferences > Network > Advanced > DNS
# Add: 8.8.8.8, 1.1.1.1
```

## Script Execution Issues

### Issue: "Permission denied" when running setup.sh

**Solution:**
```bash
# Make executable
chmod +x setup.sh

# Run with sudo
sudo bash setup.sh
```

### Issue: Script fails partway through

**Solution:**
```bash
# Check the log file (shown at start of script)
cat /tmp/ai-agent-setup-*.log

# Re-run the script (it's idempotent)
sudo bash setup.sh
```

## Verification

After fixing any issues, run the verification script:

```bash
sudo bash verify-installation.sh
```

## Getting Help

If issues persist:

1. Check the setup log file: `/tmp/ai-agent-setup-*.log`
2. Run verification: `sudo bash verify-installation.sh`
3. Check service status:
   ```bash
   brew services list
   colima status
   docker ps
   ollama list
   ```
4. Review the SCRIPT_REVIEW.md for detailed behavior documentation

## Clean Reinstall

If all else fails, clean reinstall:

```bash
# Stop services
brew services stop ollama
colima stop
colima delete -f

# Remove workspace (backup first if needed!)
sudo rm -rf /Users/onyxv/agent-workspace

# Re-run setup
sudo bash setup.sh
```

## Common Error Messages

### "command not found: colima"
- Homebrew not in PATH
- Solution: `export PATH="/opt/homebrew/bin:$PATH"`

### "No such file or directory: python3.12"
- Python 3.12 not installed
- Solution: `brew install python@3.12`

### "Cannot connect to the Docker daemon"
- Colima not running
- Solution: `colima start`

### "Model not found"
- Ollama model not pulled
- Solution: `ollama pull llama3`

### "zsh: command not found: workspace"
- Shell config not loaded
- Solution: `source ~/.zshrc` or restart terminal
