# Load this hook into zsh
autoload -U add-zsh-hook

# Logger - Set to 1 to enable verbose logging
NVM_AUTO_USE_DEBUG=0
_nvm_log() { [[ "$NVM_AUTO_USE_DEBUG" == "1" ]] && echo "[nvm-auto-use] $1" }

# Function to automatically switch Node versions based on .nvmrc
load-nvmrc() {
  local _start=$EPOCHREALTIME

  _nvm_log "Checking for .nvmrc in $(pwd)"

  if ! (( $+functions[nvm] )); then
    _nvm_log "nvm is not loaded, skipping"
    _nvm_log "Done in $(( (EPOCHREALTIME - _start) * 1000 ))ms"
    return
  fi

  if [[ ! -f .nvmrc ]]; then
    _nvm_log "No .nvmrc found, skipping"
    _nvm_log "Done in $(( (EPOCHREALTIME - _start) * 1000 ))ms"
    return
  fi

  local nvmrc_version=$(<.nvmrc)
  local current_version=$(nvm version)
  local required_version=$(nvm version "$nvmrc_version")

  _nvm_log "Found .nvmrc requesting Node $nvmrc_version"
  _nvm_log "Currently using Node $current_version"

  if [[ "$current_version" != "$required_version" ]]; then
    _nvm_log "Switching from $current_version to $nvmrc_version..."
    nvm use --silent
    _nvm_log "Now using Node $(nvm version)"
  else
    _nvm_log "Already on the right version, nothing to do"
  fi

  _nvm_log "Done in $(( (EPOCHREALTIME - _start) * 1000 ))ms"
}

# Run load-nvmrc whenever we change directories (cd)
add-zsh-hook chpwd load-nvmrc

# Run once on startup after nvm is fully initialized, then remove itself
_load-nvmrc-once() {
  load-nvmrc
  add-zsh-hook -d precmd _load-nvmrc-once
}
add-zsh-hook precmd _load-nvmrc-once