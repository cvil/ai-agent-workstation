# Ollama Agent Examples

Simple examples to get started with local AI agents using Ollama.

## Prerequisites

Make sure you're in the agent workspace with the virtual environment activated:

```bash
sudo -iu onyxv
cd ~/agent-workspace
source venv/bin/activate
```

Verify Ollama is running:
```bash
ollama list
```

## Examples

### 1. Basic Chat (Simplest)

A simple chat interface with Ollama:

```bash
python examples/basic_ollama_chat.py
```

Try asking:
- "What is Python?"
- "Write a haiku about coding"
- "Explain recursion in simple terms"

### 2. Agent with Tools (More Advanced)

An agent that can use tools to interact with your system:

```bash
python examples/simple_ollama_agent.py
```

Try asking:
- "What directory am I in?"
- "List the files in the current directory"
- "What is the date today?" (uses shell command)
- "Show me the Python version" (runs `python --version`)

## How It Works

### Basic Chat
- Uses LangChain's Ollama integration
- Streams responses in real-time
- Simple question/answer format

### Agent with Tools
- Uses LangChain's ReAct agent pattern
- Agent can "think" and decide which tool to use
- Tools available:
  - `GetCurrentDirectory` - Shows current path
  - `ListFiles` - Lists files in a directory
  - `RunCommand` - Executes shell commands

## Troubleshooting

### "Connection refused" error
Ollama might not be running:
```bash
# Check if Ollama is running
brew services list | grep ollama

# Restart if needed
brew services restart ollama
```

### "Model not found" error
Pull the llama3 model:
```bash
ollama pull llama3
```

### Agent not working correctly
The ReAct agent pattern requires the model to follow a specific format. If it's not working well:
- Try simpler questions first
- The agent has a max of 5 iterations
- Some questions might be too complex for the local model

## Next Steps

1. Modify the tools in `simple_ollama_agent.py` to add your own capabilities
2. Try different Ollama models (codellama for code tasks)
3. Explore CrewAI for multi-agent workflows
4. Check out LangGraph for more complex agent patterns

## Safety Note

The `RunCommand` tool can execute any shell command. In a production environment, you should:
- Restrict which commands can be run
- Add approval workflows
- Run in a sandboxed environment
- Validate all inputs

This is a learning example - be careful what commands you let the agent run!
