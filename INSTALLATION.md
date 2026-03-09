# OpenClaw AI Agent Workstation Setup

Secure, reproducible installation for OpenClaw and local AI agent workstation on macOS Apple Silicon.

## Security Architecture

This installation follows the principle of least privilege with a multi-layered security approach:

### User Separation
- **Admin user (cv)**: Manages system services, Homebrew, Docker/Colima
- **Agent user (onyxv)**: Full macOS user account, runs AI workloads (non-admin, no sudo)
- Complete user isolation with separate home directories at `/Users/cv` and `/Users/onyxv`
- Agent user can log in via GUI or terminal as a standard macOS user

### Group-Based Access
- **agenttools group**: Shared access to Homebrew packages
- Both users are members, enabling package use without admin rights
- Homebrew directories have group write permissions

### Restricted Write Access
Agent user workspace structure:
- `/Users/onyxv/agent-workspace` - AI workloads and projects
- `/Users/onyxv/.local` - User-level configurations
- `/Users/onyxv/.cache` - Temporary files and caches
- `/Users/onyxv/.config` - Application configurations

The agent user has a complete macOS home directory with standard permissions.
Protected system directories remain read-only (e.g., `/opt/homebrew` system files).

### Container Sandbox
- All untrusted code execution runs in Docker containers
- Colima provides Docker runtime (runs as admin user, not root)
- Pre-pulled images: python:3.11, node:20, ubuntu:22.04, qdrant/qdrant
- Containers provide isolation from host system

### Python Environment Isolation
- Dedicated virtual environment at `/Users/onyxv/agent-workspace/venv`
- Python 3.12 (avoiding 3.14 compatibility issues)
- All AI packages installed in isolated venv
- No system-wide Python package pollution

## Installation

### Prerequisites
1. macOS Sonoma or newer on Apple Silicon (M-series)
2. Admin access to run the setup script
3. The script will create users if they don't exist:
   - Admin user (cv) - if not already present
   - Agent user (onyxv) - created as full macOS user

### Run Installation
```bash
sudo bash setup.sh
```

The script is idempotent and can be safely re-run. It will:
1. Install Homebrew (if needed)
2. Create full macOS user accounts (if needed)
3. Configure group-based permissions
4. Install system dependencies (git, tmux, colima, docker, ollama)
5. Install Rust compiler (required for tiktoken)
6. Install Python 3.12
7. Create agent workspace with proper home directory
8. Create Python virtual environment
9. Install AI stack (langchain, langgraph, crewai, etc.)
10. Install Playwright Chromium browser
11. Configure Docker via Colima
12. Start Ollama service
13. Pull default models (llama3, codellama)
14. Copy example scripts to workspace
15. Generate tmux launch script and workspace README

## Verification

Run the verification script to check installation:
```bash
sudo bash verify-installation.sh
```

This checks:
- User and group configuration
- Homebrew and packages
- Python environment
- Workspace permissions
- Docker and Colima status
- Ollama models
- All Python dependencies

## Usage

### Start Working as Agent User
```bash
# Switch to the agent user (full macOS user)
sudo -iu onyxv

# Quick start with aliases
workspace              # Activates Python venv
agents                 # Starts tmux session

# Or manually
cd ~/agent-workspace
source venv/bin/activate
```

### Start Agents in Tmux (Persistent Sessions)
```bash
sudo -iu onyxv
~/start-agents.sh
```

The tmux session persists after terminal disconnect. Reattach with:
```bash
tmux attach -t agents
```

### Test Installation
```bash
# Test Ollama
ollama list
ollama run llama3

# Test Docker
docker ps
docker run --rm python:3.11 python --version

# Test Python environment
python --version
pip list

# Test OpenClaw
python -c "import openclaw; print('OpenClaw ready')"
```

## Installed Components

### System Tools
- Git - Version control
- Tmux - Terminal multiplexer for persistent sessions
- Colima - Docker runtime for macOS
- Docker - Container platform
- Ollama - Local LLM runtime
- Rust - Compiler (required for tiktoken)

### Python Stack (in venv)
- langchain - LLM application framework
- langgraph - Graph-based LLM workflows
- crewai - Multi-agent orchestration
- openclaw - AI agent framework
- openai - OpenAI API client
- anthropic - Anthropic API client
- tiktoken - Token counting
- playwright - Browser automation
- qdrant-client - Vector database client
- duckdb - Embedded analytics database
- fastapi - Web framework
- uvicorn - ASGI server

### Models
- llama3 - General purpose LLM
- codellama - Code-focused LLM

### Docker Images
- python:3.11 - Python runtime
- node:20 - Node.js runtime
- ubuntu:22.04 - Ubuntu base
- qdrant/qdrant - Vector database

## Known Issues Avoided

This installation explicitly avoids common problems:

1. **Python 3.14 incompatibility** - Uses Python 3.12
2. **uvicorn metadata errors** - Installs uvicorn>=0.30
3. **Missing Rust compiler** - Installs Rust before Python deps
4. **Playwright permissions** - Installs to user cache directory
5. **Colima running as root** - Runs as admin user
6. **Protected directory modification** - Only touches safe directories
7. **Recursive chown on home** - Only changes specific directories

## Troubleshooting

### Ollama not responding
```bash
# Restart Ollama service
brew services restart ollama

# Check status
brew services list | grep ollama
```

### Colima not running
```bash
# Start Colima
colima start

# Check status
colima status
```

### Python packages missing
```bash
# Reinstall in venv
cd ~/agent-workspace
source venv/bin/activate
pip install --upgrade langchain langgraph crewai openclaw
```

### Permission denied errors
```bash
# Verify workspace ownership
ls -la ~/agent-workspace

# Should show: onyxv staff
```

## Security Best Practices

1. **Never run AI agents as admin** - Always use onyxv user
2. **Keep containers updated** - Regularly pull new images
3. **Monitor agent activity** - Check logs in tmux sessions
4. **Limit network access** - Use firewall rules if needed
5. **Review agent code** - Inspect before running untrusted agents
6. **Backup workspace** - Regular backups of ~/agent-workspace

## Maintenance

### Update packages
```bash
# Update Homebrew packages
brew update && brew upgrade

# Update Python packages
cd ~/agent-workspace
source venv/bin/activate
pip list --outdated
pip install --upgrade <package>
```

### Pull new models
```bash
ollama pull <model-name>
ollama list
```

### Update Docker images
```bash
docker pull python:3.11
docker pull node:20
docker pull ubuntu:22.04
docker pull qdrant/qdrant
```

## Support

For issues or questions:
1. Check verification script output
2. Review logs in tmux sessions
3. Check Homebrew services: `brew services list`
4. Verify permissions: `ls -la ~/agent-workspace`
