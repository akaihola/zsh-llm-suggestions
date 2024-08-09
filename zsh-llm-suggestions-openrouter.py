#!/usr/bin/env python3

import sys
import os

MISSING_PREREQUISITES = "zsh-llm-suggestions missing prerequisites:"

def highlight_explanation(explanation):
    try:
        import pygments
        from pygments.lexers import MarkdownLexer
        from pygments.formatters import TerminalFormatter
        return pygments.highlight(explanation, MarkdownLexer(), TerminalFormatter(style='material'))
    except ImportError:
        return explanation

def main():
    mode = sys.argv[1]
    if mode not in ['generate', 'explain']:
        print("ERROR: something went wrong in zsh-llm-suggestions, please report a bug. Got unknown mode: " + mode)
        return

    try:
        import llm
    except ImportError:
        print(f'echo "{MISSING_PREREQUISITES} Install LLM library." && pip3 install llm-openrouter')
        return

    buffer = sys.stdin.read()
    system_message = """You are a zsh shell expert, please write a ZSH command that solves my problem.
You should only output the completed command, no need to include any other explanation."""
    if mode == 'explain':
        system_message = """You are a zsh shell expert, please briefly explain how the given command works. Be as concise as possible. Use Markdown syntax for formatting."""

    try:
        model = llm.get_model("openrouter/anthropic/claude-3.5-sonnet:beta")
        response = model.prompt(buffer, system=system_message)
        output = response.text().strip()
    except llm.api.ApiError as e:
        if "api_key" in str(e).lower():
            print("Error: OpenRouter API key not set or invalid. Please set it using one of the following methods:")
            print("1. Run: llm keys set openrouter --value YOUR_API_KEY")
            print("2. Set the OPENROUTER_API_KEY environment variable")
            print("3. Store your key using secret-tool: secret-tool store --label='OpenRouter API Key' service openrouter.ai")
        else:
            print(f"Error running LLM command: {e}")
        return
    except Exception as e:
        print(f"Error running LLM command: {e}")
        return

    if mode == 'generate':
        print(output)
    elif mode == 'explain':
        print(highlight_explanation(output))

if __name__ == '__main__':
    main()
