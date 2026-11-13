# Prompt
# Shows a short version of the current path and git status

# Expand variables in the prompt, and allow prompt hooks
setopt prompt_subst
autoload -Uz add-zsh-hook

# Git part of the prompt, empty outside a repo or until gitstatus is up
typeset -g prompt_git=''
typeset -g prompt_git_dir=''

# Load gitstatus after the prompt is up; it keeps a git daemon running so
# each prompt only asks it, instead of running git
zinit wait'0' lucid for \
  atload'prompt_git_start' \
    romkatv/gitstatus

# Start the daemon, counting at most one file of each kind, since the prompt
# only shows whether there are any
function prompt_git_start() {
  gitstatus_stop PROMPT && gitstatus_start -s 1 -u 1 -c 1 -d 1 PROMPT
  add-zsh-hook precmd prompt_git_query
  prompt_git_query

  # Redraw the prompt that was shown before gitstatus was ready
  if zle; then
    zle reset-prompt
  fi
}

# Ask for the current folder, waiting at most 10 ms before letting the
# answer arrive in the background
function prompt_git_query() {
  gitstatus_query -t 0.01 -c prompt_git_async PROMPT || return

  # Still waiting: keep the old git info only if the folder hasn't changed
  if [[ $VCS_STATUS_RESULT == tout ]]; then
    if [[ $PWD != $prompt_git_dir ]]; then
      prompt_git=''
    fi

    return
  fi

  prompt_git_update
}

# A late answer: update and redraw
function prompt_git_async() {
  prompt_git_update
  zle reset-prompt
}

# Build the git part, in the same format vcs_info used to produce
function prompt_git_update() {
  prompt_git=''
  prompt_git_dir=$PWD

  # Not a git repo
  if [[ $VCS_STATUS_RESULT != ok-* ]]; then
    return
  fi

  # Branch name, or the short commit when detached
  local where=${VCS_STATUS_LOCAL_BRANCH:-${VCS_STATUS_COMMIT[1,7]}}
  where=${where//\%/%%}

  # During a merge or rebase: [branch|action]
  if [[ -n $VCS_STATUS_ACTION ]]; then
    prompt_git="%F{5}[%F{2}$where%F{3}|%F{1}$VCS_STATUS_ACTION%F{5}]%f "
    return
  fi

  # Otherwise ‹branch›, then S staged, * unstaged, ?? untracked
  prompt_git="%F{2}‹$where› "

  if (( VCS_STATUS_HAS_STAGED )); then
    prompt_git+="%F{2}S "
  fi

  if (( VCS_STATUS_HAS_UNSTAGED )); then
    prompt_git+="%F{3}* "
  fi

  if (( VCS_STATUS_HAS_UNTRACKED )); then
    prompt_git+="%F{1}?? "
  fi

  prompt_git+="%f"
}

# Last 3 path parts, git info, then $
PROMPT='%F{3}%3~ ${prompt_git}%f$ '
