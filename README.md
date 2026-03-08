# OpenClaw AI Agent Workstation Setup

Complete, secure, idempotent installation for OpenClaw and local AI agent development on macOS Apple Silicon.

## Quick Start

### New or Existing Machine (Idempotent)
```bash
sudo bash setup.sh
```

### Verify Installation
```bash
sudo bash verify-installation.sh
```

## What You Get

A secure, production-ready AI development environment with:

- **Python 3.12** virtual environment with AI stack
- **Ollama** for local LLM inference (llama3, codellama)
- **Docker + Colima** for containerized execution
- **Playwright** for browser automation
- **OpenClaw** and CrewAI frameworks
- **Security-first** architecture with user separation

## Files

| File | Purpose |
|------|---------|
| `setup.sh` | Idempotent setup for new or existing machines |
| `verify-installation.sh` | Check installation status and health |
| `QUICKSTART.md` | Quick reference guide |
| `INSTALLATION.md` | Detailed documentation and troubleshooting |

## Security Architecture

### User Separation
- **cv** (admin): System services, Homebrew, Docker/Colima
- **onyxv** (agent): AI workloads, no admin privileges

### Principle of Least Privilege
- Agent user can only write to: `~/agent-workspace`, `~/.local`, `~/.cache`
- Protected directories: `~/Library`, `~/Documents`, `/opt/homebrew`
- All untrusted code runs in Docker containers

### Group-Based Access
- **agenttools** group: Shared Homebrew access
- Both users are members for package management

## Usage

Start working as agent user:
```bash
sudo -iu onyxv
cd ~/agent-workspace
source venv/bin/activate
```

Start persistent tmux session:
```bash
sudo -iu onyxv
~/start-agents.sh
```

Test installation:
```bash
ollama run llama3
docker ps
python --version
```

## Key Features

✅ **Idempotent** - Safe to run multiple times  
✅ **Secure** - Least privilege, user separation, container isolation  
✅ **Python 3.12** - Avoids 3.14 compatibility issues  
✅ **Complete** - All dependencies included  
✅ **Documented** - Comprehensive guides and troubleshooting  
✅ **Tested** - Handles known failure modes  

## Requirements

- macOS Sonoma or newer
- Apple Silicon (M-series) Mac
- Internet connection for downloads
- Admin access for initial setup

## Installed Components

### System
- Homebrew, Git, tmux
- Docker, Colima
- Ollama
- Rust compiler
- Python 3.12

### Python Packages
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
- python:3.11, node:20
- ubuntu:22.04
- qdrant/qdrant

## Documentation

- **QUICKSTART.md** - Quick reference and common tasks
- **INSTALLATION.md** - Detailed setup guide and architecture
- **This README** - Overview and getting started

## Troubleshooting

See `INSTALLATION.md` for detailed troubleshooting, or run:

```bash
sudo bash verify-installation.sh
```

Common fixes:
```bash
# Restart Ollama
brew services restart ollama

# Restart Colima
colima restart

# Recreate venv
rm -rf ~/agent-workspace/venv
/opt/homebrew/opt/python@3.12/bin/python3.12 -m venv ~/agent-workspace/venv
```

## Design Principles

1. **Security First** - Least privilege, user separation, container isolation
2. **Idempotent** - Safe to run repeatedly without side effects
3. **Reproducible** - Same result every time
4. **Documented** - Clear explanations and troubleshooting
5. **Tested** - Handles known failure modes
6. **Minimal** - Only essential components

## Known Issues Avoided

This setup explicitly avoids common problems:

- ❌ Python 3.14 incompatibilities → Uses Python 3.12
- ❌ uvicorn metadata errors → Installs uvicorn>=0.30
- ❌ Missing Rust compiler → Installs Rust before Python deps
- ❌ Playwright permissions → Installs to user cache
- ❌ Colima as root → Runs as admin user
- ❌ Protected directory modification → Only touches safe paths
- ❌ Recursive chown on home → Only changes specific directories

## Support

For issues:
1. Run `verify-installation.sh` to check status
2. Check `INSTALLATION.md` troubleshooting section
3. Review logs in tmux sessions
4. Verify permissions: `ls -la ~/agent-workspace`

## License

This setup script is provided as-is for setting up OpenClaw AI agent workstations.
