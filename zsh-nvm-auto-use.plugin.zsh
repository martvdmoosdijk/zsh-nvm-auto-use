# This loads the add-zsh-hook function, which lets you run a function whenever certain events happen (like changing directories).
autoload -U add-zsh-hook

# Function to automatically switch Node versions based on .nvmrc
load-nvmrc() {
  if ! which nvm &>/dev/null; then
    return
  fi

  # If a .nvmrc file exists AND the current version isn't the one specified
  if [[ -f .nvmrc && "$(nvm version)" != "$(nvm version "$(cat .nvmrc)")" ]]; then
    echo "Change in .nvmrc detected, automatically switched node $(nvm version) to $(cat .nvmrc)"
    # Use the version specified in .nvmrc silently
    nvm use --silent
  fi
}

# Run load-nvmrc whenever we change directories (cd)
add-zsh-hook chpwd load-nvmrc

# Also run once when the shell starts
load-nvmrc