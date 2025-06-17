# Load basic Git info
autoload -Uz vcs_info
precmd_vcs_info() { vcs_info }
precmd_functions+=( precmd_vcs_info )
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' formats ' %F{magenta}%b%f'  # Removed %u%c which showed the 'u'

# Show last 2 directories
function short_pwd() {
  local pwd="${PWD/#$HOME/~}"
  local parts=(${(s:/:)pwd})
  (( ${#parts} > 2 )) && echo "~/${parts[-2]}/${parts[-1]}" || echo "$pwd"
}

# Git remote status
function git_remote_status() {
  local remote_status=""
  
  git rev-parse --is-inside-work-tree &>/dev/null || return
  
  local upstream=$(git rev-parse --abbrev-ref @{u} 2>/dev/null)
  if [[ -n "$upstream" ]]; then
    local ahead_behind=($(git rev-list --left-right --count HEAD...@{u} 2>/dev/null))
    local ahead=${ahead_behind[1]}
    local behind=${ahead_behind[2]}
    
    (( $ahead )) && remote_status+="%F{green}↑$ahead%f"
    (( $behind )) && remote_status+="%F{red}↓$behind%f"
  fi
  
  echo "$remote_status"
}

# Enhanced Git local status symbols
function git_local_status() {
  local git_status=$(git status --porcelain 2>/dev/null)
  local symbols=""
  
  # Modified files
  [[ -n $(echo "$git_status" | grep '^ M') ]] && symbols+="%F{red}✗%f"
  # Staged changes
  [[ -n $(echo "$git_status" | grep '^M ') ]] && symbols+="%F{green}✓%f"
  # Untracked files
  [[ -n $(echo "$git_status" | grep '^??') ]] && symbols+="%F{cyan}?%f"
  # Added files
  [[ -n $(echo "$git_status" | grep '^A ') ]] && symbols+="%F{blue}+%f"
  # Deleted files
  [[ -n $(echo "$git_status" | grep '^ D') ]] && symbols+="%F{yellow}⌫%f"
  # Renamed files
  [[ -n $(echo "$git_status" | grep '^R ') ]] && symbols+="%F{magenta}↻%f"
  
  echo "$symbols"
}

# Execution timer
function cmd_exec_time() {
  [[ -z "$cmd_timestamp" ]] && return
  local elapsed=$((($(date +%s%0N)/100000000 - cmd_timestamp)))
  unset cmd_timestamp
  (( elapsed < 1 )) && return

  if (( elapsed >= 36000 )); then
    printf "%%B%%F{208}%dh%dm %%f%%b" $((elapsed/36000)) $((elapsed%36000/600))
  elif (( elapsed >= 600 )); then
    printf "%%B%%F{208}%dm%ds %%f%%b" $((elapsed/600)) $((elapsed%600/10))
  else
    printf "%%B%%F{208}%d.%ds %%f%%b" $((elapsed/10)) $((elapsed%10))
  fi
}

# Record command start time
preexec() { cmd_timestamp=$(($(date +%s%0N)/100000000)) }

# Newline after commands
precmd() { precmd() { echo } }

# Main prompt
PROMPT=' %F{4}$(short_pwd)%F{magenta}${vcs_info_msg_0_} $(git_remote_status)$(git_local_status)%f
%(?.%B%F{208} >%f%b.%B%F{1}[%?] >%f%b) '
RPROMPT='$(cmd_exec_time)%B%F{208}[%T]%f%b'