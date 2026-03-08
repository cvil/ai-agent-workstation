#!/bin/bash
#
# Verification Script for OpenClaw AI Agent Workstation
# Run as: sudo bash verify-installation.sh
#

set -euo pipefail

ADMIN_USER="cv"
AGENT_USER="onyxv"
AGENT_GROUP="agenttools"
WORKSPACE="/Users/$AGENT_USER/agent-workspace"
VENV="$WORKSPACE/venv"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass() {
    echo -e "${GREEN}✓${NC} $1"
}

fail() {
    echo -e "${RED}✗${NC} $1"
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "========================================="
echo "OpenClaw Installation Verification"
echo "========================================="
echo ""

# Check users
echo "Checking users and groups..."
if id "$ADMIN_USER" &>/dev/null; then
    pass "Admin user $ADMIN_USER exists"
else
    fail "Admin user $ADMIN_USER not found"
fi

if id "$AGENT_USER" &>/dev/null; then
    pass "Agent user $AGENT_USER exists"
else
    fail "Agent user $AGENT_USER not found"
fi

if dscl . -read /Groups/"$AGENT_GROUP" &>/dev/null; then
    pass "Group $AGENT_GROUP exists"
else
    fail "Group $AGENT_GROUP not found"
fi

# Check Homebrew
echo ""
echo "Checking Homebrew..."
if [[ -x "/opt/homebrew/bin/brew" ]]; then
    pass "Homebrew installed"
    BREW_VERSION=$(/opt/homebrew/bin/brew --version | head -n1)
    echo "  Version: $BREW_VERSION"
else
    fail "Homebrew not found"
fi

# Check packages
echo ""
echo "Checking installed packages..."
PACKAGES=("git" "tmux" "colima" "docker" "ollama" "rust" "python@3.12")
for pkg in "${PACKAGES[@]}"; do
    if /opt/homebrew/bin/brew list "$pkg" &>/dev/null; then
        pass "$pkg installed"
    else
        fail "$pkg not installed"
    fi
done

# Check Python
echo ""
echo "Checking Python..."
PYTHON_BIN="/opt/homebrew/opt/python@3.12/bin/python3"
if [[ -x "$PYTHON_BIN" ]]; then
    pass "Python 3.12 found"
    PY_VERSION=$($PYTHON_BIN --version)
    echo "  Version: $PY_VERSION"
else
    fail "Python 3.12 not found"
fi

# Check workspace
echo ""
echo "Checking workspace..."
if [[ -d "$WORKSPACE" ]]; then
    pass "Workspace exists: $WORKSPACE"
    WORKSPACE_OWNER=$(stat -f "%Su" "$WORKSPACE")
    if [[ "$WORKSPACE_OWNER" == "$AGENT_USER" ]]; then
        pass "Workspace owned by $AGENT_USER"
    else
        fail "Workspace owned by $WORKSPACE_OWNER (expected $AGENT_USER)"
    fi
else
    fail "Workspace not found: $WORKSPACE"
fi

# Check virtual environment
echo ""
echo "Checking virtual environment..."
if [[ -d "$VENV" ]] && [[ -x "$VENV/bin/python" ]]; then
    pass "Virtual environment exists"
    VENV_PY_VERSION=$($VENV/bin/python --version)
    echo "  Version: $VENV_PY_VERSION"
else
    fail "Virtual environment not found or invalid"
fi

# Check Python packages
echo ""
echo "Checking Python packages..."
if [[ -x "$VENV/bin/pip" ]]; then
    PACKAGES=("langchain" "langgraph" "crewai" "openclaw" "openai" "anthropic" "tiktoken" "playwright" "qdrant-client" "duckdb" "fastapi" "uvicorn")
    for pkg in "${PACKAGES[@]}"; do
        if sudo -u "$AGENT_USER" "$VENV/bin/pip" show "$pkg" &>/dev/null; then
            pass "$pkg installed"
        else
            warn "$pkg not installed"
        fi
    done
fi

# Check Playwright
echo ""
echo "Checking Playwright..."
PLAYWRIGHT_PATH="/Users/$AGENT_USER/.cache/ms-playwright"
if [[ -d "$PLAYWRIGHT_PATH" ]]; then
    pass "Playwright cache exists"
    CHROMIUM_COUNT=$(find "$PLAYWRIGHT_PATH" -name "chrome-mac" -o -name "chromium-*" 2>/dev/null | wc -l)
    if [[ $CHROMIUM_COUNT -gt 0 ]]; then
        pass "Chromium browser installed"
    else
        warn "Chromium browser not found"
    fi
else
    warn "Playwright cache not found"
fi

# Check Colima
echo ""
echo "Checking Colima..."
if sudo -u "$ADMIN_USER" colima status &>/dev/null; then
    pass "Colima is running"
else
    warn "Colima is not running"
fi

# Check Docker
echo ""
echo "Checking Docker..."
if sudo -u "$ADMIN_USER" docker ps &>/dev/null; then
    pass "Docker is accessible"
    IMAGES=("python:3.11" "node:20" "ubuntu:22.04" "qdrant/qdrant")
    for img in "${IMAGES[@]}"; do
        if sudo -u "$ADMIN_USER" docker image inspect "$img" &>/dev/null; then
            pass "Image $img exists"
        else
            warn "Image $img not found"
        fi
    done
else
    warn "Docker not accessible"
fi

# Check Ollama
echo ""
echo "Checking Ollama..."
if curl -s http://localhost:11434/api/tags &>/dev/null; then
    pass "Ollama service is running"
    if command -v ollama &>/dev/null; then
        MODELS=("llama3" "codellama")
        for model in "${MODELS[@]}"; do
            if ollama list | grep -q "^$model"; then
                pass "Model $model available"
            else
                warn "Model $model not found"
            fi
        done
    fi
else
    warn "Ollama service not responding"
fi

# Check tmux script
echo ""
echo "Checking tmux launch script..."
TMUX_SCRIPT="/Users/$AGENT_USER/start-agents.sh"
if [[ -f "$TMUX_SCRIPT" ]] && [[ -x "$TMUX_SCRIPT" ]]; then
    pass "Tmux launch script exists and is executable"
else
    warn "Tmux launch script not found or not executable"
fi

echo ""
echo "========================================="
echo "Verification Complete"
echo "========================================="
echo ""
echo "To start working as agent user:"
echo "  sudo -iu $AGENT_USER"
echo "  cd ~/agent-workspace"
echo "  source venv/bin/activate"
echo ""
