#!/bin/bash

bak() {
  cp "$1" "$1.bak"
}

# brew() {
#   arch -arm64 /opt/homebrew/bin/brew "$@"
# }

cd() {
  builtin cd "$@" \
    && exa -abghlm --sort name --group-directories-first --git
}

cdv() {
  builtin cd "$@" && vim .
}

cdg() {
  cd "$(root_directory)" || exit
}

copy() {
  cat "$1" | /usr/bin/pbcopy
}

pbcopy() {
  /usr/bin/pbcopy "$@"

  echo "Copy with command \`copy <filename>\`"
}

g() {
  if [[ "$#" -gt 0 ]]; then
    git "$@"
  else
    git status --short --branch
  fi
}

gcm() {
  git commit -m "$*"
}

root_directory() {
  local project_root_dir="$(git rev-parse --show-toplevel)"
  local not_found="No \`.git\` directory could be located."

  if [ ! -d "$project_root_dir" ]; then
    echo "$not_found"
    return 1
  fi

  echo "$project_root_dir"
}

modx() {
  local filename="$1"

  if [ ! -f "$filename" ]; then
    echo -e "#!/bin/bash\n" > "$filename"
  fi

  chmod +x "$filename"
}

v() {
  if [[ "$#" -gt 0 ]]; then
    vim "$@"
  else
    vim .
  fi
}

# vim:ft=bash
