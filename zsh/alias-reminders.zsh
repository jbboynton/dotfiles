# Alias reminders
# Catch commands typed out in full that already have an alias, and find
# commands typed often enough to deserve one

# Load you-should-use after the prompt is up
zinit wait'0' lucid for \
  MichaelAquilina/zsh-you-should-use

# Stop the command and show the alias instead of running it
YSU_HARDCORE=1

# Skip aliases that swap one tool for another, so typing bat itself is fine
YSU_IGNORED_ALIASES=("cat" "less")

# List full commands run at least 5 times (or $1) that no alias covers yet
function alias_candidates() {
  local -i min=${1:-5}
  local -A counts
  local cmd value
  local -a words

  # Count each command line in history, ignoring one-word commands
  for cmd in "${(@f)$(fc -ln 1)}"; do
    words=(${(z)cmd})

    if (( $#words < 2 )); then
      continue
    fi

    counts[$cmd]=$(( ${counts[$cmd]:-0} + 1 ))
  done

  # Print the frequent ones, most used first, skipping any an alias covers
  for cmd in ${(k)counts}; do
    if (( counts[$cmd] < min )); then
      continue
    fi

    for value in ${(v)aliases}; do
      if [[ $cmd == $value || $cmd == "$value "* ]]; then
        continue 2
      fi
    done

    print -r -- "${counts[$cmd]} $cmd"
  done | sort -rn | head -20
}
