
zsh_llm_suggestions_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'

    cleanup() {
      kill $pid
      echo -ne "\e[?25h"
    }
    trap cleanup SIGINT
    
    echo -ne "\e[?25l"
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b"
    done
    printf "    \b\b\b\b"

    echo -ne "\e[?25h"
    trap - SIGINT
}

zsh_llm_suggestions_run_query() {
  local llm="$1"
  local query="$2"
  local result_file="$3"
  local mode="$4"
  echo -n "$query" | eval $llm $mode > $result_file
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
  fi

  # Temporary file to store the result of the background process
  local result_file="/tmp/zsh-llm-suggestions-result"
  # Run the actual query in the background (since it's long-running, and so that we can show a spinner)
  read < <( zsh_llm_suggestions_run_query $llm $query $result_file $mode & echo $! )
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
}

SCRIPT_DIR=$( cd -- "$( dirname -- "$0" )" &> /dev/null && pwd )
VENV_DIR="$HOME/.local/share/zsh-llm-suggestions/venv"

# Create virtualenv if it doesn't exist
if [[ ! -d "$VENV_DIR" ]]; then
  python3 -m venv "$VENV_DIR"
  "$VENV_DIR/bin/pip" install pygments llm-openrouter openai
fi

# Set OpenRouter API key if not already set
if [[ -z "$OPENROUTER_API_KEY" ]]; then
  if command -v secret-tool &> /dev/null; then
    export OPENROUTER_API_KEY=$(secret-tool lookup service openrouter.ai)
  fi
  if [[ -z "$OPENROUTER_API_KEY" ]]; then
    echo "OpenRouter API key not set. Please set it using one of the following methods:"
    echo "1. Run: llm keys set openrouter --value YOUR_API_KEY"
    echo "2. Set the OPENROUTER_API_KEY environment variable"
    echo "3. Store your key using secret-tool: secret-tool store --label='OpenRouter API Key' service openrouter.ai"
  else
    "$VENV_DIR/bin/llm" keys set openrouter --value "$OPENROUTER_API_KEY"
  fi
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

zsh_llm_suggestions_openrouter() {
  zsh_llm_completion "zsh_llm_suggestions_run_python $SCRIPT_DIR/zsh-llm-suggestions-openrouter.py" "generate"
}

zsh_llm_suggestions_openrouter_explain() {
  zsh_llm_completion "zsh_llm_suggestions_run_python $SCRIPT_DIR/zsh-llm-suggestions-openrouter.py" "explain"
}

zle -N zsh_llm_suggestions_openai
zle -N zsh_llm_suggestions_openai_explain
zle -N zsh_llm_suggestions_github_copilot
zle -N zsh_llm_suggestions_github_copilot_explain
zle -N zsh_llm_suggestions_openrouter
zle -N zsh_llm_suggestions_openrouter_explain
