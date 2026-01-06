# zsh-cd-auto-commands
# Auto-execute commands when cd into specific directories

# Only work in interactive shell
if [[ ! -o interactive ]]; then
  return
fi

# Config file name
CD_AUTO_COMMANDS_RC=".cd-auto-commands"

# Global config file path (can be customized via environment variable)
CD_AUTO_COMMANDS_GLOBAL_DEFAULT="$HOME/$CD_AUTO_COMMANDS_RC"

# Debug mode (set to 1 to enable debug logs)
CD_AUTO_COMMANDS_DEBUG="${CD_AUTO_COMMANDS_DEBUG:-0}"

# Store last directory to avoid duplicate execution
typeset -g _CD_AUTO_COMMANDS_LAST_DIR=""

# Debug log function
function _debug_log() {
  if [[ "$CD_AUTO_COMMANDS_DEBUG" == "1" ]]; then
    echo "[DEBUG] $*" >&2
  fi
}

# Find local config file (no parent directory lookup)
function _find_local_config() {
  local config_file="$PWD/$CD_AUTO_COMMANDS_RC"
  _debug_log "Checking local config: $config_file"
  if [[ -f "$config_file" ]]; then
    _debug_log "Found local config file"
    echo "$config_file"
    return 0
  fi
  _debug_log "Local config file not found"
  return 1
}

# Get global config file path
function _get_global_config() {
  local global_config="${CD_AUTO_COMMANDS_GLOBAL:-$CD_AUTO_COMMANDS_GLOBAL_DEFAULT}"
  _debug_log "Checking global config: $global_config"
  if [[ -f "$global_config" ]]; then
    _debug_log "Found global config file"
    echo "$global_config"
    return 0
  fi
  _debug_log "Global config file not found"
  return 1
}

# Check config file format (whether contains [path] syntax)
function _is_global_format() {
  local config_file="$1"
  _debug_log "Checking config file format: $config_file"
  # Read first non-empty non-comment line
  while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    # Check if it's [path] format
    if [[ "$line" =~ "^\[.*\]$" ]]; then
      _debug_log "Detected [path] format: $line"
      return 0
    else
      _debug_log "Not [path] format, first line: $line"
      return 1
    fi
  done < "$config_file"
  _debug_log "Config file is empty or only has comments"
  return 1
}

# Path matching function (supports wildcard *)
function _match_path() {
  local pattern="$1"
  local target="$2"
  
  _debug_log "Path matching: pattern='$pattern' target='$target'"
  
  # Special handling for [.] representing current directory, highest priority
  if [[ "$pattern" == "." ]]; then
    _debug_log "Matched [.] current directory: success"
    return 0
  fi
  
  # Expand ~ to HOME directory
  pattern="${pattern/#\~/$HOME}"
  target="${target/#\~/$HOME}"
  
  _debug_log "Expanded paths: pattern='$pattern' target='$target'"
  
  # Use zsh pattern matching (only supports *)
  if [[ "$target" == $~pattern ]]; then
    _debug_log "Path matching: success"
    return 0
  fi
  _debug_log "Path matching: failed"
  return 1
}

# Execute config file (must start with [.] or [path])
function _execute_config() {
  local config_file="$1"
  local current_dir="$PWD"
  local in_section=0
  local section_path=""
  local matched=0
  local is_local_section=0
  
  _debug_log "Start parsing config file: $config_file"
  _debug_log "Current directory: $current_dir"
  
  while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    
    # Check if it's [path] section
    if [[ "$line" =~ "^\[(.*)\]$" ]]; then
      # Stop if already matched and encountered new section
      if [[ $matched -eq 1 ]]; then
        _debug_log "Already matched, stop parsing"
        break
      fi
      
      section_path="${match[1]}"
      _debug_log "Found new section: [$section_path]"
      
      # [.] has highest priority, match first
      if [[ "$section_path" == "." ]]; then
        in_section=1
        matched=1
        is_local_section=1
        _debug_log "Matched [.] section"
      # Other path matching
      elif _match_path "$section_path" "$current_dir"; then
        in_section=1
        matched=1
        is_local_section=0
        _debug_log "Path matched, entering section"
      else
        in_section=0
        _debug_log "Path not matched, skipping this section"
      fi
    elif [[ $in_section -eq 1 ]]; then
      # In matched section, execute command
      _debug_log "Executing command: $line"
      eval "$line"
    fi
  done < "$config_file"
  
  if [[ $matched -eq 1 ]]; then
    _debug_log "Config execution completed"
  else
    _debug_log "No matching section found"
  fi
  
  return $matched
}

# Main function for auto-executing commands
function cd_auto_commands() {
  _debug_log "==================== cd_auto_commands triggered ===================="
  _debug_log "Current directory: $PWD"
  _debug_log "Last directory: $_CD_AUTO_COMMANDS_LAST_DIR"
  
  # Skip if directory hasn't changed
  if [[ "$PWD" == "$_CD_AUTO_COMMANDS_LAST_DIR" ]]; then
    _debug_log "Directory unchanged, skipping execution"
    return
  fi
  
  # Check local config first
  local config_file
  config_file="$(_find_local_config)"
  
  if [[ -n "$config_file" ]]; then
    _debug_log "Using local config"
    # Local config must start with [.]
    if ! _is_global_format "$config_file"; then
      echo "[ERROR] Local config file must start with [.]: $config_file"
      return 1
    fi
    _execute_config "$config_file"
  else
    _debug_log "Local config not found, trying global config"
    # No local config, try global config
    config_file="$(_get_global_config)"
    if [[ -n "$config_file" ]]; then
      _debug_log "Using global config"
      if ! _is_global_format "$config_file"; then
        echo "[ERROR] Global config file must use [path] syntax: $config_file"
        return 1
      fi
      _execute_config "$config_file"
    else
      _debug_log "Global config not found either"
    fi
  fi
  
  # Update last executed directory
  _CD_AUTO_COMMANDS_LAST_DIR="$PWD"
  _debug_log "====================================================================="
}

# Register to chpwd hook
autoload -U add-zsh-hook
add-zsh-hook chpwd cd_auto_commands

# Also execute once on initial load
cd_auto_commands
