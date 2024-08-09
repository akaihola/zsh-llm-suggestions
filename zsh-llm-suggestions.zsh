
# Default prompt variables
ZSH_LLM_SUGGESTIONS_GENERATE_PROMPT=${ZSH_LLM_SUGGESTIONS_GENERATE_PROMPT:-"You are a zsh shell expert, please write a ZSH command that solves my problem. You should only output the completed command, no need to include any other explanation."}
ZSH_LLM_SUGGESTIONS_EXPLAIN_PROMPT=${ZSH_LLM_SUGGESTIONS_EXPLAIN_PROMPT:-"You are a zsh shell expert, please briefly explain how the given command works. Be as concise as possible. Use Markdown syntax for formatting."}

# Color variables
if type tput >/dev/null; then
    RESET="$(tput sgr0)"
    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
else
    RESET=""
    RED=""
    GREEN=""
fi

zsh_llm_suggestions_spinner() {
    local pid=$1
    local delay=0.1
    local spin='⣾⣽⣻⢿⡿⣟⣯⣷'

    cleanup() {
        kill "$pid"
        tput cnorm
    }
    trap cleanup SIGINT

    i=0
    tput civis
    while kill -0 "$pid" 2>/dev/null; do
        i=$(((i + 1) % ${#spin}))
        printf "  %s%s%s" "${RED}" "${spin:$i:1}" "${RESET}"
        sleep "$delay"
        printf "\b\b\b"
    done
    printf "   \b\b\b"
    tput cnorm
    trap - SIGINT
}

zsh_llm_suggestions_run_query() {
  local llm="$1"
  local query="$2"
  local result_file="$3"
  local mode="$4"
  local prompt="$5"
  echo -n "$prompt\n\n$query" | eval $llm $mode >! $result_file
}

zsh_llm_completion() {
  local llm="$1"
  local mode="$2"
  local query=${BUFFER}

  # Empty prompt, nothing to do
  if [[ "$query" == "" ]]; then
    return
  fi

  # If the prompt is the last suggestions, just get another suggestion for the same query
  if [[ "$mode" == "generate" ]]; then
    if [[ "$query" == "$ZSH_LLM_SUGGESTIONS_LAST_RESULT" ]]; then
      query=$ZSH_LLM_SUGGESTIONS_LAST_QUERY
    else
      ZSH_LLM_SUGGESTIONS_LAST_QUERY="$query"
    fi
    prompt="$ZSH_LLM_SUGGESTIONS_GENERATE_PROMPT"
  elif [[ "$mode" == "explain" ]]; then
    prompt="$ZSH_LLM_SUGGESTIONS_EXPLAIN_PROMPT"
  fi

  # Temporary file to store the result of the background process
  local result_file="/tmp/zsh-llm-suggestions-result-$$"
  # Remove the temporary file if it exists
  [[ -f "$result_file" ]] && rm -f "$result_file"
  # Run the actual query in the background (since it's long-running, and so that we can show a spinner)
  read < <( zsh_llm_suggestions_run_query $llm $query $result_file $mode $prompt &! echo $! )
  # Get the PID of the background process
  local pid=$REPLY
  # Call the spinner function and pass the PID
  zsh_llm_suggestions_spinner $pid
  
  if [[ "$mode" == "generate" ]]; then
    # Place the query in the history first
    print -s $query
    # Replace the current buffer with the result
    ZSH_LLM_SUGGESTIONS_LAST_RESULT=$(cat $result_file)
    BUFFER="${ZSH_LLM_SUGGESTIONS_LAST_RESULT}"
    CURSOR=${#ZSH_LLM_SUGGESTIONS_LAST_RESULT}
  fi
  if [[ "$mode" == "explain" ]]; then
    echo ""
    eval "cat $result_file"
    echo ""
    zle reset-prompt
  fi

  # Remove the temporary file after use
  rm -f "$result_file"
}

SCRIPT_DIR=$( cd -- "$( dirname -- "$0" )" &> /dev/null && pwd )
VENV_DIR="$HOME/.local/share/zsh-llm-suggestions/venv"

# Create virtualenv if it doesn't exist
if [[ ! -d "$VENV_DIR" ]]; then
  python3 -m venv "$VENV_DIR"
  "$VENV_DIR/bin/pip" install pygments llm-openrouter openai
fi

# Function to run Python scripts in the virtualenv
zsh_llm_suggestions_run_python() {
  "$VENV_DIR/bin/python" "$@"
}

zsh_llm_suggestions_openai() {
  zsh_llm_completion "zsh_llm_suggestions_run_python $SCRIPT_DIR/zsh-llm-suggestions-openai.py" "generate"
}

zsh_llm_suggestions_github_copilot() {
  zsh_llm_completion "zsh_llm_suggestions_run_python $SCRIPT_DIR/zsh-llm-suggestions-github-copilot.py" "generate"
}

zsh_llm_suggestions_openai_explain() {
  zsh_llm_completion "zsh_llm_suggestions_run_python $SCRIPT_DIR/zsh-llm-suggestions-openai.py" "explain"
}

zsh_llm_suggestions_github_copilot_explain() {
  zsh_llm_completion "zsh_llm_suggestions_run_python $SCRIPT_DIR/zsh-llm-suggestions-github-copilot.py" "explain"
}

zsh_llm_suggestions_setup_openrouter_api_key() {
  if [[ -z "$OPENROUTER_API_KEY" ]]; then
    if command -v secret-tool &> /dev/null; then
      export OPENROUTER_API_KEY=$(secret-tool lookup service openrouter.ai)
    fi
    if [[ -z "$OPENROUTER_API_KEY" ]]; then
      echo "OpenRouter API key not set. Please set it using one of the following methods:"
      echo "1. Run: $VENV_DIR/bin/llm keys set openrouter --value YOUR_API_KEY"
      echo "2. Set the OPENROUTER_API_KEY environment variable"
      echo "3. Store your key using secret-tool: secret-tool store --label='OpenRouter API Key' service openrouter.ai"
      return 1
    else
      "$VENV_DIR/bin/llm" keys set openrouter --value "$OPENROUTER_API_KEY"
    fi
  fi
  return 0
}

zsh_llm_suggestions_openrouter() {
  zsh_llm_suggestions_setup_openrouter_api_key || return
  zsh_llm_completion "zsh_llm_suggestions_run_python $SCRIPT_DIR/zsh-llm-suggestions-openrouter.py" "generate"
}

zsh_llm_suggestions_openrouter_explain() {
  zsh_llm_suggestions_setup_openrouter_api_key || return
  zsh_llm_completion "zsh_llm_suggestions_run_python $SCRIPT_DIR/zsh-llm-suggestions-openrouter.py" "explain"
}

zle -N zsh_llm_suggestions_openai
zle -N zsh_llm_suggestions_openai_explain
zle -N zsh_llm_suggestions_github_copilot
zle -N zsh_llm_suggestions_github_copilot_explain
zle -N zsh_llm_suggestions_openrouter
zle -N zsh_llm_suggestions_openrouter_explain
