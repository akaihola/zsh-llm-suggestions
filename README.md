# LLM-based command suggestions for zsh

![Demo of zsh-llm-suggestions](https://github.com/stefanheule/zsh-llm-suggestions/blob/master/zsh-llm-suggestions.gif?raw=true)

`zsh` commands can be difficult to remember, but LLMs are great at turning
human descriptions of what to do into a command. Enter `zsh-llm-suggestions`:
You describe what you would like to do directly in your prompt, you hit a
keyboard shortcut of your choosing, and the LLM replaces your request with
the command.

Similarly, if you have a command that you don't understand, `zsh-llm-suggestions`
can query an LLM for you to explain that command. You can combine these, by
first generating a command from a human description, and then asking the LLM
to explain the command.

## Installation

There are two ways to install this plugin:

### Manual Installation

1. Clone the repository:

```
git clone https://github.com/stefanheule/zsh-llm-suggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-llm-suggestions
```

2. Add the plugin to your `.zshrc`:

```zsh
plugins=(... zsh-llm-suggestions)
```

### Using a Plugin Manager

If you're using a plugin manager, follow its instructions to add this plugin. For example, with [zplug](https://github.com/zplug/zplug), add the following to your `.zshrc`:

```zsh
zplug "stefanheule/zsh-llm-suggestions"
```

### Configuration

The plugin comes with default keybindings, but you can customize them in your `.zshrc`:

```zsh
# OpenAI
bindkey '^o' zsh_llm_suggestions_openai # Ctrl + O to have OpenAI suggest a command
bindkey '^[^o' zsh_llm_suggestions_openai_explain # Ctrl + Alt + O to have OpenAI explain a command

# GitHub Copilot
bindkey '^p' zsh_llm_suggestions_github_copilot # Ctrl + P to have GitHub Copilot suggest a command
bindkey '^[^p' zsh_llm_suggestions_github_copilot_explain # Ctrl + Alt + P to have GitHub Copilot explain a command

# OpenRouter
bindkey '^r' zsh_llm_suggestions_openrouter # Ctrl + R to have OpenRouter suggest a command
bindkey '^[^r' zsh_llm_suggestions_openrouter_explain # Ctrl + Alt + R to have OpenRouter explain a command
```

Make sure `python3` is installed.

All LLMs require a bit of configuration. Either follow the rest of the instructions
here, or just enter something on the prompt (because an empty prompt won't run the
LLM) and hit your configured keyboard shortcut. Instead of answering the prompt, it will
tell you how to finish the setup.

For `zsh_llm_suggestions_openai` (OpenAI-based suggestions):
- Set the `OPENAI_API_KEY` environment variable to your API key. You can get it
  from [https://platform.openai.com/api-keys](https://platform.openai.com/api-keys). Note
  that every suggestion costs a small amount of money, you are solely responsible for
  these charges.
  ```
  export OPENAI_API_KEY="..."
  ```
- The necessary Python packages will be installed automatically in a virtual environment.

For `zsh_llm_suggestions_github_copilot` (GitHub Copilot suggestions):
- Install GitHub CLI: Follow [https://github.com/cli/cli#installation](https://github.com/cli/cli#installation).
- Authenticate with GitHub:
  ```
  gh auth login --web -h github.com
  ```
- Install GitHub Copilot extension:
  ```
  gh extension install github/gh-copilot
  ```

For `zsh_llm_suggestions_openrouter` (OpenRouter-based suggestions):
- Set the `OPENROUTER_API_KEY` environment variable to your API key. You can get it
  from [https://openrouter.ai/keys](https://openrouter.ai/keys). Note that every suggestion
  costs a small amount of money, you are solely responsible for these charges.
  ```
  export OPENROUTER_API_KEY="..."
  ```
- Alternatively, you can store your API key using `secret-tool`:
  ```
  secret-tool store --label='OpenRouter API Key' service openrouter.ai
  ```
- The necessary Python packages will be installed automatically in a virtual environment.

## Usage

### LLM suggested commands

Type out what you'd like to do in English, then hit the configured hotkey (e.g., Ctrl+P, Ctrl+O, or Ctrl+R).
`zsh-llm-suggestions` will then query the selected LLM (OpenAI, GitHub Copilot, or OpenRouter), and replace
the query with the suggested command.

If you don't like the suggestion and think the LLM can do better, just hit the hotkey again,
and a new suggestion will be fetched.

### Explain commands using LLM

If you typed a command (or maybe the LLM generated one) that you don't understand, hit
the configured explanation hotkey (e.g., Ctrl+Alt+O, Ctrl+Alt+P, or Ctrl+Alt+R) to have the
selected LLM explain the command in English.

## Warning

There are some risks using `zsh-llm-suggestions`:
1. LLMs can suggest bad commands, it is up to you to make sure you
   are okay executing the commands.
2. The supported LLMs are not free, so you might incur a cost when using `zsh-llm-suggestions`.

## Supported LLMs

Currently, three LLMs are supported:
1. GitHub Copilot (via GitHub CLI). Requires a GitHub Copilot subscription.
2. OpenAI. Requires an OpenAI API key. Currently uses `gpt-4-1106-preview`.
3. OpenRouter. Requires an OpenRouter API key. Uses the model specified in the Python script (currently "openrouter/anthropic/claude-3.5-sonnet:beta").
