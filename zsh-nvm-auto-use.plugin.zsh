# Load this hook into zsh
autoload -U add-zsh-hook

# Make zsh's high-resolution clock available without an external command.
zmodload zsh/datetime

# Set NVM_AUTO_USE_DEBUG=1 before loading this plugin to show debug messages.
# Keep an existing setting, or use 0 (off) if no setting was provided.
NVM_AUTO_USE_DEBUG=${NVM_AUTO_USE_DEBUG:-0}
# Set to 0 to hide version-change notifications when debugging is off.
NVM_AUTO_USE_NOTIFY=${NVM_AUTO_USE_NOTIFY:-1}
_nvm_log() { [[ "$NVM_AUTO_USE_DEBUG" == "1" ]] && echo "[nvm-auto-use] $1" }

# nvm stores Node in a version-named folder, such as v24.9.0/bin/node.
# Use that folder name when it matches the Node actually selected by PATH.
# For a system installation, ask Node directly; if it is missing, say so.
_nvm_node_version() {
  local node_executable
  node_executable=$(command -v node) || { echo 'unavailable'; return 0; }
  local node_directory=${node_executable:h}
  local version=${node_directory:h:t}

  if [[ "$node_directory" == "${NVM_BIN-}" &&
        "$version" =~ '^v[0-9]+\.[0-9]+\.[0-9]+$' ]]; then
    echo "$version"
  else
    command node --version 2>/dev/null || echo 'unavailable'
  fi
}

# Remember the last successful request and Node environment between calls.
# These variables are global because the function runs again after each cd.
typeset -g _nvm_auto_use_request=''
typeset -g _nvm_auto_use_bin=''
typeset -g _nvm_auto_use_path=''
# Cache the full version for skip messages without repeating the lookup.
typeset -g _nvm_auto_use_version=''

# Function to automatically switch Node versions based on .nvmrc
load-nvmrc() {
  # Time the whole check, including early returns in the helper below.
  local started=$EPOCHREALTIME
  _nvm_auto_use
  local result=$?

  # Print milliseconds only when debugging, without changing the result.
  if [[ "$NVM_AUTO_USE_DEBUG" == "1" ]]; then
    printf '[nvm-auto-use] Done in %.2fms\n' "$(( (EPOCHREALTIME - started) * 1000 ))"
  fi
  return "$result"
}

# Keep the switching logic separate so every exit goes through the timer.
_nvm_auto_use() {
  _nvm_log "Checking for .nvmrc in $PWD"

  # In zsh, this checks whether the nvm function has been loaded.
  if ! (( $+functions[nvm] )); then
    _nvm_log "nvm is not loaded, skipping"
    return 0
  fi

  # Look in this directory first, then its parents. The closest file wins.
  # :h is zsh's way to get the parent directory without running dirname.
  local nvmrc_directory=$PWD
  # Depth 0 means this directory; each move to a parent adds 1.
  local search_depth=0
  while [[ ! -f "$nvmrc_directory/.nvmrc" ]]; do
    # Stop at the filesystem root: it has no parent to search.
    if [[ "$nvmrc_directory" == / ]]; then
      if [[ "$NVM_AUTO_USE_DEBUG" == "1" ]]; then
        # No version is requested, so report Node without switching it.
        local current_version
        current_version=$(_nvm_node_version)
        _nvm_log "No .nvmrc found (search depth: $search_depth), skipping (Node $current_version)"
      fi
      return 0
    fi
    nvmrc_directory=${nvmrc_directory:h}
    (( search_depth += 1 ))
  done

  local nvmrc_file="$nvmrc_directory/.nvmrc"
  _nvm_log "Found $nvmrc_file (search depth: $search_depth)"

  # Read the requested version without starting an external cat command.
  # local keeps this variable inside this function.
  local nvmrc_version
  nvmrc_version=$(<"$nvmrc_file")

  # For caching, treat 24 and v24 (also 24.1 or 24.1.0) as the same request.
  # This pattern matches only numeric versions, so alias names stay untouched.
  # ${nvmrc_version#v} removes a leading v; nvm still gets the original text.
  local request_key=$nvmrc_version
  if [[ "$nvmrc_version" =~ '^v[0-9]+(\.[0-9]+){0,2}$' ]]; then
    request_key=${nvmrc_version#v}
  fi

  # Skip nvm if the request and environment still match the last success.
  # NVM_BIN is the selected Node bin directory; PATH controls command lookup.
  # Checking both lets us notice manual Node switches. ${NVM_BIN-} is empty
  # when NVM_BIN is unset, which can happen after nvm deactivate.
  if [[ "$request_key" == "$_nvm_auto_use_request" &&
        "${NVM_BIN-}" == "$_nvm_auto_use_bin" &&
        "$PATH" == "$_nvm_auto_use_path" ]]; then
    _nvm_log "Request and Node environment unchanged, skipping (Node $_nvm_auto_use_version)"
    return 0
  fi

  # Read the actual version on a cache miss for change notifications and logs.
  # Unlike the request (24 or lts/*), this shows the full selected version.
  local previous_version
  previous_version=$(_nvm_node_version)

  _nvm_log "Using Node requested by .nvmrc: $nvmrc_version"
  # Run in the current shell so nvm's PATH changes persist.
  # --silent hides normal output, not errors. On failure, return nvm's error
  # code ($?) immediately so the failed request is not cached.
  nvm use --silent "$nvmrc_version" || return $?

  local selected_version
  selected_version=$(_nvm_node_version)

  # Save the environment AFTER nvm changes it, and only after success.
  _nvm_auto_use_request=$request_key
  _nvm_auto_use_bin=${NVM_BIN-}
  _nvm_auto_use_path=$PATH
  _nvm_auto_use_version=$selected_version

  # Debugging shows all changes; otherwise the notify flag controls them.
  # Unchanged versions remain debug-only.
  if [[ "$previous_version" == "$selected_version" ]]; then
    _nvm_log "Node version unchanged: $selected_version"
  elif [[ "$NVM_AUTO_USE_DEBUG" == "1" || "$NVM_AUTO_USE_NOTIFY" == "1" ]]; then
    echo "[nvm-auto-use] Switched Node from $previous_version to $selected_version"
  fi
  return 0
}

# Run load-nvmrc whenever we change directories (cd)
add-zsh-hook chpwd load-nvmrc

# Run once on startup after nvm is fully initialized, then remove itself
_load-nvmrc-once() {
  load-nvmrc
  add-zsh-hook -d precmd _load-nvmrc-once
}
add-zsh-hook precmd _load-nvmrc-once