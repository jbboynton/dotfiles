# Drift
# Check in the background that hard-coded settings still match their tools

# Run last, two seconds after the prompt is up
zinit wait'2' lucid for \
  id-as'env-drift' as'null' atload'drift_check' \
    zdharma-continuum/null

# Start the check once a day, or every shell while a problem is open
function drift_check() {
  local dir=${XDG_CACHE_HOME:-$HOME/.cache}/env-drift
  local -a fresh=($dir/stamp(Nm-1))

  # Show the last report, if it found anything
  if [[ -s $dir/report ]]; then
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd drift_report
  elif (( $#fresh )); then
    return
  fi

  # Lowest priority, killed after 5 seconds, never waited on
  (
    mkdir -p $dir
    : >| $dir/stamp

    FPATH_CHECK=${(j.:.)fpath} timeout -k 1 5 nice -n 19 \
      $HOME/.bin/env_drift >| $dir/report.new.$$ 2>&1

    # 124 is timeout's exit status when it had to kill the check
    if (( $? == 124 )); then
      print -r -- "env_drift timed out after 5 seconds" >> $dir/report.new.$$
    fi

    mv -f $dir/report.new.$$ $dir/report
  ) &!
}

# Run the check by hand. fpath isn't exported, so pass it along; without
# it, env_drift skips checking fpath
function env_drift() {
  FPATH_CHECK=${(j.:.)fpath} command env_drift "$@"
}

# Print the report at the next prompt, once per shell
function drift_report() {
  local report=${XDG_CACHE_HOME:-$HOME/.cache}/env-drift/report

  if [[ -s $report ]]; then
    print -P "%F{1}Settings out of sync with their tools%f"
    local line
    for line in ${(f)"$(<$report)"}; do
      print -r -- "  - $line"
    done
    print -r -- "Found by ~/.dotfiles/bin/env_drift, which zsh/drift.zsh runs in the"
    print -r -- "background once a day. Fix each setting where it says, then run"
    print -r -- "\`env_drift\` to check: no output means all clear. Until a check comes"
    print -r -- "back clean, this shows in every new shell."
  fi

  add-zsh-hook -d precmd drift_report
}
