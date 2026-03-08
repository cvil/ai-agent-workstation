#!/usr/bin/env python3
"""
Simple AI Agent using Ollama + LangChain
Demonstrates a local agent that can use tools
"""

from langchain_community.llms import Ollama
from langchain.agents import Tool, AgentExecutor, create_react_agent
from langchain.prompts import PromptTemplate
import subprocess
import os

# Initialize Ollama with llama3
llm = Ollama(model="llama3", base_url="http://localhost:11434")

# Define some simple tools the agent can use
def get_current_directory():
    """Get the current working directory"""
    return os.getcwd()

def list_files(directory="."):
    """List files in a directory"""
    try:
        files = os.listdir(directory)
        return "\n".join(files)
    except Exception as e:
        return f"Error: {str(e)}"

def run_shell_command(command):
    """Run a shell command (use with caution!)"""
    try:
        result = subprocess.run(
            command, 
            shell=True, 
            capture_output=True, 
            text=True,
            timeout=10
        )
        return f"Output:\n{result.stdout}\nErrors:\n{result.stderr}"
    except Exception as e:
        return f"Error: {str(e)}"

# Create tools
tools = [
    Tool(
        name="GetCurrentDirectory",
        func=get_current_directory,
        description="Get the current working directory path"
    ),
    Tool(
        name="ListFiles",
        func=list_files,
        description="List all files in the current directory or a specified directory"
    ),
    Tool(
        name="RunCommand",
        func=run_shell_command,
        description="Run a shell command. Input should be a valid shell command string."
    ),
]

# Create a simple prompt template
template = """Answer the following questions as best you can. You have access to the following tools:

{tools}

Use the following format:

Question: the input question you must answer
Thought: you should always think about what to do
Action: the action to take, should be one of [{tool_names}]
Action Input: the input to the action
Observation: the result of the action
... (this Thought/Action/Action Input/Observation can repeat N times)
Thought: I now know the final answer
Final Answer: the final answer to the original input question

Begin!

Question: {input}
Thought: {agent_scratchpad}
"""

prompt = PromptTemplate.from_template(template)

# Create the agent
agent = create_react_agent(llm, tools, prompt)
agent_executor = AgentExecutor(
    agent=agent, 
    tools=tools, 
    verbose=True,
    max_iterations=5,
    handle_parsing_errors=True
)

def main():
    print("=" * 60)
    print("Simple Ollama Agent with LangChain")
    print("=" * 60)
    print("\nThis agent can:")
    print("  - Get current directory")
    print("  - List files")
    print("  - Run shell commands")
    print("\nType 'quit' to exit\n")
    
    while True:
        try:
            user_input = input("\nYou: ").strip()
            
            if user_input.lower() in ['quit', 'exit', 'q']:
                print("Goodbye!")
                break
            
            if not user_input:
                continue
            
            print("\nAgent thinking...\n")
            response = agent_executor.invoke({"input": user_input})
            print(f"\nAgent: {response['output']}\n")
            
        except KeyboardInterrupt:
            print("\n\nGoodbye!")
            break
        except Exception as e:
            print(f"\nError: {str(e)}\n")

if __name__ == "__main__":
    main()
