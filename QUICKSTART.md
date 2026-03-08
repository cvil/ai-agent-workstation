# Quick Start Guide

## Installation

Run this single command to set up everything (works for new or existing machines):

```bash
sudo bash setup.sh
```

This script is idempotent and will:
1. Install Homebrew (if needed)
2. Create users (cv and onyxv) if they don't exist
3. Install all dependencies
4. Set up Python environment
5. Install AI stack
6. Configure Docker/Colima
7. Pull Ollama models
8. Create tmux launcher

## Verify Installation

### System Tools
- Homebrew (package manager)
- Git, tmux
- Docker + Colima (container runtime)
- Ollama (local LLM server)
- Rust (compiler for Python packages)
- Python 3.12

### Python Packages (in venv)
- langchain, langgraph
- crewai, openclaw
- openai, anthropic
- tiktoken, playwright
- qdrant-client, duckdb
- fastapi, uvicorn

### Models
- llama3 (general purpose)
- codellama (code focused)

### Docker Images
- python:3.11
- node:20
- ubuntu:22.04
- qdrant/qdrant

## Usage

### Start Working as Agent User

```bash
sudo -iu onyxv
cd ~/agent-workspace
source venv/bin/activate
```

### Start Persistent Agent Session

```bash
sudo -iu onyxv
~/start-agents.sh
```

Tmux commands:
- `Ctrl+b d` - Detach from session
- `tmux attach -t agents` - Reattach to session
- `Ctrl+b c` - Create new window
- `Ctrl+b n` - Next window
- `Ctrl+b p` - Previous window

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
pip list | grep langchain

# Test OpenClaw
python -c "import openclaw; print('OpenClaw ready')"
```

## Verify Installation

Run the verification script:

```bash
sudo bash verify-installation.sh
```

## Security Model

### User Separation
- **cv** (admin): Manages system services, Homebrew, Docker
- **onyxv** (agent): Runs AI workloads, no admin privileges

### Restricted Write Access
Agent user can only write to:
- `/Users/onyxv/agent-workspace` - AI projects
- `/Users/onyxv/.local` - User configs
- `/Users/onyxv/.cache` - Temporary files

Protected (read-only for agent):
- `~/Library` - macOS system files
- `~/Documents`, `~/Desktop` - Personal files
- `/opt/homebrew` - System packages

### Container Isolation
- All untrusted code runs in Docker containers
- Colima provides Docker runtime (non-root)
- Pre-configured sandbox images

## Troubleshooting

### Ollama not responding
```bash
brew services restart ollama
brew services list | grep ollama
```

### Colima not running
```bash
colima start
colima status
```

### Python packages missing
```bash
cd ~/agent-workspace
source venv/bin/activate
pip install --upgrade langchain langgraph crewai openclaw
```

### Permission errors
```bash
# Check workspace ownership
ls -la ~/agent-workspace
# Should show: onyxv staff

# Fix if needed (run as root)
sudo chown -R onyxv:staff /Users/onyxv/agent-workspace
```

### Wrong Python version in venv
```bash
# Remove and recreate venv
rm -rf ~/agent-workspace/venv
/opt/homebrew/opt/python@3.12/bin/python3.12 -m venv ~/agent-workspace/venv
source ~/agent-workspace/venv/bin/activate
pip install --upgrade pip setuptools wheel
# Reinstall packages...
```

## File Structure

```
/Users/onyxv/
├── agent-workspace/          # Main workspace
│   └── venv/                 # Python virtual environment
├── .local/                   # User-level configs
├── .cache/                   # Temporary files
│   └── ms-playwright/        # Browser binaries
└── start-agents.sh           # Tmux launcher script
```

## Common Tasks

### Update Python packages
```bash
cd ~/agent-workspace
source venv/bin/activate
pip list --outdated
pip install --upgrade <package>
```

### Pull new Ollama models
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

### Update Homebrew packages
```bash
brew update
brew upgrade
```

## Next Steps

1. Test the installation with verification script
2. Start a tmux session as agent user
3. Run a simple test with Ollama
4. Try running OpenClaw examples
5. Set up your first AI agent project

## Support Files

- `setup.sh` - Idempotent setup for new or existing machines
- `verify-installation.sh` - Check installation status
- `INSTALLATION.md` - Detailed documentation
- `QUICKSTART.md` - This file

## Notes

- The installation is idempotent - safe to run multiple times
- Python 3.12 is used (not 3.14) for compatibility
- All services run as non-root users
- Colima runs as admin user, not root
- Agent user has no sudo privileges
