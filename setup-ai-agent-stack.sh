#!/bin/bash

########################################
# OpenClaw AI Agent Workstation Setup
# Secure, idempotent bootstrap script
# macOS Apple Silicon (M-series)
########################################

set -euo pipefail

########################################
# CONFIGURATION
########################################

ADMIN_USER="cv"
AGENT_USER="onyxv"
AGENT_GROUP="agenttools"

BREW_PREFIX="/opt/homebrew"
BREW="$BREW_PREFIX/bin/brew"

AGENT_HOME="/Users/$AGENT_USER"
WORKSPACE="$AGENT_HOME/agent-workspace"
VENV="$WORKSPACE/venv"

PYTHON_VERSION="3.12"
PYTHON_BIN="$BREW_PREFIX/opt/python@${PYTHON_VERSION}/bin/python${PYTHON_VERSION}"

########################################
# HELPER FUNCTIONS
########################################

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

check_user_exists() {
    id "$1" &>/dev/null
}

check_group_exists() {
    dscl . -read /Groups/"$1" &>/dev/null
}

brew_package_installed() {
    $BREW list "$1" &>/dev/null
}

########################################
log "========================================="
log "OpenClaw AI Agent Workstation Setup"
log "========================================="
########################################

# Verify running as root or with sudo
if [[ $EUID -ne 0 ]]; then
   log "ERROR: This script must be run with sudo"
   exit 1
fi

########################################
# 1. VERIFY HOMEBREW
########################################

log "Step 1: Verifying Homebrew installation..."

if [[ ! -x "$BREW" ]]; then
    log "ERROR: Homebrew not found at $BREW_PREFIX"
    log "Please install Homebrew first: https://brew.sh"
    exit 1
fi

# Ensure Homebrew environment is available
eval "$($BREW shellenv)"

log "✓ Homebrew found at $BREW_PREFIX"

########################################
# 2. CONFIGURE GROUP PERMISSIONS
########################################

log "Step 2: Configuring group-based permissions..."

# Create agenttools group if it doesn't exist
if ! check_group_exists "$AGENT_GROUP"; then
    log "Creating group: $AGENT_GROUP"
    sudo dseditgroup -o create "$AGENT_GROUP"
else
    log "✓ Group $AGENT_GROUP already exists"
fi

# Add users to group
for user in "$ADMIN_USER" "$AGENT_USER"; do
    if check_user_exists "$user"; then
        if ! dseditgroup -o checkmember -m "$user" "$AGENT_GROUP" &>/dev/null; then
            log "Adding $user to $AGENT_GROUP group"
            sudo dseditgroup -o edit -a "$user" -t user "$AGENT_GROUP"
        else
            log "✓ User $user already in $AGENT_GROUP group"
        fi
    else
        log "WARNING: User $user does not exist, skipping group assignment"
    fi
done

# Set Homebrew group permissions
if [[ -d "$BREW_PREFIX" ]]; then
    log "Setting Homebrew group permissions..."
    sudo chgrp -R "$AGENT_GROUP" "$BREW_PREFIX" 2>/dev/null || true
    sudo chmod -R g+w "$BREW_PREFIX" 2>/dev/null || true
fi

########################################
# 3. INSTALL SYSTEM DEPENDENCIES
########################################

log "Step 3: Installing system dependencies..."

PACKAGES=(
    "git"
    "tmux"
    "colima"
    "docker"
    "ollama"
)

for pkg in "${PACKAGES[@]}"; do
    if brew_package_installed "$pkg"; then
        log "✓ $pkg already installed"
    else
        log "Installing $pkg..."
        sudo -u "$ADMIN_USER" "$BREW" install "$pkg"
    fi
done

########################################
# 4. INSTALL RUST (before Python deps)
########################################

log "Step 4: Installing Rust compiler..."

if brew_package_installed "rust"; then
    log "✓ Rust already installed"
else
    log "Installing Rust..."
    sudo -u "$ADMIN_USER" "$BREW" install rust
fi

########################################
# 5. INSTALL PYTHON 3.12
########################################

log "Step 5: Installing Python ${PYTHON_VERSION}..."

if brew_package_installed "python@${PYTHON_VERSION}"; then
    log "✓ Python ${PYTHON_VERSION} already installed"
else
    log "Installing Python ${PYTHON_VERSION}..."
    sudo -u "$ADMIN_USER" "$BREW" install "python@${PYTHON_VERSION}"
fi

# Verify Python binary exists
if [[ ! -x "$PYTHON_BIN" ]]; then
    log "ERROR: Python binary not found at $PYTHON_BIN"
    exit 1
fi

log "✓ Python version: $($PYTHON_BIN --version)"

########################################
# 6. CREATE AGENT WORKSPACE
########################################

log "Step 6: Creating agent workspace..."

# Verify agent user exists
if ! check_user_exists "$AGENT_USER"; then
    log "ERROR: Agent user $AGENT_USER does not exist"
    log "Please create the user first: sudo sysadminctl -addUser $AGENT_USER"
    exit 1
fi

# Create only specific writable directories (NOT entire home)
WRITABLE_DIRS=(
    "$AGENT_HOME/.local"
    "$AGENT_HOME/.cache"
    "$WORKSPACE"
)

for dir in "${WRITABLE_DIRS[@]}"; do
    if [[ ! -d "$dir" ]]; then
        log "Creating directory: $dir"
        sudo -u "$AGENT_USER" mkdir -p "$dir"
    else
        log "✓ Directory exists: $dir"
    fi
    # Ensure correct ownership (non-recursive for safety)
    sudo chown "$AGENT_USER:staff" "$dir"
done

log "✓ Agent workspace created at $WORKSPACE"

########################################
# 7. CREATE VIRTUAL ENVIRONMENT
########################################

log "Step 7: Creating Python virtual environment..."

if [[ -d "$VENV" ]] && [[ -x "$VENV/bin/python" ]]; then
    log "✓ Virtual environment already exists"
else
    log "Creating virtual environment with Python ${PYTHON_VERSION}..."
    sudo -u "$AGENT_USER" -H bash -c "cd '$WORKSPACE' && '$PYTHON_BIN' -m venv '$VENV'"
fi

log "✓ Virtual environment ready at $VENV"

########################################
# 8. INSTALL PYTHON DEPENDENCIES
########################################

log "Step 8: Installing Python dependencies..."

# Upgrade pip tooling first
log "Upgrading pip, setuptools, wheel..."
sudo -u "$AGENT_USER" -H bash -c "
    source '$VENV/bin/activate' && \
    pip install --upgrade pip setuptools wheel
"

# Install AI stack packages
log "Installing AI stack packages..."
sudo -u "$AGENT_USER" -H bash -c "
    source '$VENV/bin/activate' && \
    pip install --upgrade \
        langchain \
        langgraph \
        crewai \
        openclaw \
        openai \
        anthropic \
        tiktoken \
        playwright \
        qdrant-client \
        duckdb \
        fastapi \
        'uvicorn>=0.30'
"

log "✓ Python dependencies installed"

########################################
# 9. INSTALL PLAYWRIGHT BROWSERS
########################################

log "Step 9: Installing Playwright browsers..."

PLAYWRIGHT_PATH="$AGENT_HOME/.cache/ms-playwright"

sudo -u "$AGENT_USER" -H bash -c "
    export PLAYWRIGHT_BROWSERS_PATH='$PLAYWRIGHT_PATH'
    source '$VENV/bin/activate' && \
    python -m playwright install chromium
"

log "✓ Playwright Chromium installed to $PLAYWRIGHT_PATH"

########################################
# 10. CONFIGURE DOCKER VIA COLIMA
########################################

log "Step 10: Configuring Docker via Colima..."

# Start Colima as admin user (NOT root)
sudo -u "$ADMIN_USER" bash -c "
    eval \"\$($BREW shellenv)\"
    if colima status &>/dev/null; then
        echo '✓ Colima already running'
    else
        echo 'Starting Colima...'
        colima start --cpu 4 --memory 8 --disk 100
    fi
"

# Pull Docker images
log "Pulling Docker images..."
IMAGES=(
    "python:3.11"
    "node:20"
    "ubuntu:22.04"
    "qdrant/qdrant"
)

for img in "${IMAGES[@]}"; do
    if sudo -u "$ADMIN_USER" docker image inspect "$img" &>/dev/null; then
        log "✓ Image $img already exists"
    else
        log "Pulling $img..."
        sudo -u "$ADMIN_USER" docker pull "$img" || log "WARNING: Failed to pull $img"
    fi
done

log "✓ Docker configured via Colima"

########################################
# 11. INSTALL OLLAMA
########################################

log "Step 11: Configuring Ollama..."

# Start Ollama service
if sudo -u "$ADMIN_USER" "$BREW" services list | grep ollama | grep started &>/dev/null; then
    log "✓ Ollama service already running"
else
    log "Starting Ollama service..."
    sudo -u "$ADMIN_USER" "$BREW" services start ollama
    sleep 3
fi

log "✓ Ollama service configured"

########################################
# 12. PULL DEFAULT MODELS
########################################

log "Step 12: Pulling default Ollama models..."

# Wait for Ollama to be ready
for i in {1..10}; do
    if curl -s http://localhost:11434/api/tags &>/dev/null; then
        break
    fi
    log "Waiting for Ollama to be ready... ($i/10)"
    sleep 2
done

MODELS=("llama3" "codellama")

for model in "${MODELS[@]}"; do
    if ollama list | grep -q "^$model"; then
        log "✓ Model $model already pulled"
    else
        log "Pulling model $model..."
        ollama pull "$model" || log "WARNING: Failed to pull $model"
    fi
done

log "✓ Default models configured"

########################################
# 13. INSTALL OPENCLAW
########################################

log "Step 13: Verifying OpenClaw installation..."

if sudo -u "$AGENT_USER" -H bash -c "source '$VENV/bin/activate' && pip show openclaw &>/dev/null"; then
    log "✓ OpenClaw installed"
else
    log "WARNING: OpenClaw not found in pip packages"
fi

########################################
# 14. GENERATE TMUX LAUNCH SCRIPT
########################################

log "Step 14: Generating tmux launch script..."

TMUX_SCRIPT="$AGENT_HOME/start-agents.sh"

cat > "$TMUX_SCRIPT" <<'EOF'
#!/bin/bash
#
# Agent Persistence Script
# Launches AI agents in tmux session
#

SESSION="agents"
WORKSPACE="$HOME/agent-workspace"
VENV="$WORKSPACE/venv"

# Check if session exists
if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "Session '$SESSION' already exists. Attaching..."
    tmux attach -t "$SESSION"
    exit 0
fi

# Create new session
echo "Creating new tmux session: $SESSION"
tmux new-session -d -s "$SESSION" -n "main"

# Setup environment
tmux send-keys -t "$SESSION:main" "cd $WORKSPACE" C-m
tmux send-keys -t "$SESSION:main" "source $VENV/bin/activate" C-m
tmux send-keys -t "$SESSION:main" "clear" C-m

# Create additional windows
tmux new-window -t "$SESSION" -n "logs"
tmux new-window -t "$SESSION" -n "monitor"

# Select main window
tmux select-window -t "$SESSION:main"

# Attach to session
tmux attach -t "$SESSION"
EOF

chmod +x "$TMUX_SCRIPT"
chown "$AGENT_USER:staff" "$TMUX_SCRIPT"

log "✓ Tmux launch script created at $TMUX_SCRIPT"

########################################
# COMPLETION
########################################

log ""
log "========================================="
log "✓ Installation Complete!"
log "========================================="
log ""
log "SECURITY ARCHITECTURE:"
log "  - Admin user ($ADMIN_USER): System services, Homebrew, Docker/Colima"
log "  - Agent user ($AGENT_USER): OpenClaw and AI workloads (non-admin)"
log "  - Group ($AGENT_GROUP): Shared Homebrew access"
log "  - Writable paths: $WORKSPACE, ~/.local, ~/.cache only"
log "  - Container sandbox: Docker via Colima (non-root)"
log ""
log "TO START WORKING:"
log "  sudo -iu $AGENT_USER"
log "  cd ~/agent-workspace"
log "  source venv/bin/activate"
log ""
log "TO START AGENTS IN TMUX:"
log "  sudo -iu $AGENT_USER"
log "  ~/start-agents.sh"
log ""
log "VERIFY INSTALLATION:"
log "  ollama list"
log "  ollama run llama3"
log "  docker ps"
log "  python --version"
log ""
