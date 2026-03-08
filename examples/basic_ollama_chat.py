#!/usr/bin/env python3
"""
Basic Ollama Chat Example
Simple chat interface with Ollama
"""

from langchain_community.llms import Ollama

def main():
    print("=" * 60)
    print("Basic Ollama Chat (using llama3)")
    print("=" * 60)
    print("\nType 'quit' to exit\n")
    
    # Initialize Ollama
    llm = Ollama(model="llama3", base_url="http://localhost:11434")
    
    while True:
        try:
            user_input = input("\nYou: ").strip()
            
            if user_input.lower() in ['quit', 'exit', 'q']:
                print("Goodbye!")
                break
            
            if not user_input:
                continue
            
            print("\nAssistant: ", end="", flush=True)
            
            # Stream the response
            for chunk in llm.stream(user_input):
                print(chunk, end="", flush=True)
            
            print()  # New line after response
            
        except KeyboardInterrupt:
            print("\n\nGoodbye!")
            break
        except Exception as e:
            print(f"\nError: {str(e)}\n")

if __name__ == "__main__":
    main()
