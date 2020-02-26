#!/bin/bash

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

vagrant_directory() {
  local project_root_dir="$(git rev-parse --show-toplevel)"
  local vagrant_dir="$project_root_dir/ops"

  if [ ! -d "$vagrant_dir" ]; then
    echo "Error: couldn't locate the ops directory -- checked: $vagrant_dir"
    return 1
  fi

  echo "$vagrant_dir"
}

vh() {
  pushd "$(vagrant_directory)" &> /dev/null || exit
  vagrant halt
  popd &> /dev/null || exit
}

vrest() {
  pushd "$(vagrant_directory)" &> /dev/null || exit

  vagrant halt
  echo "VM halted..."

  sleep 3

  echo "Restarting VM..."
  vagrant up

  popd &> /dev/null || exit
}

vssh() {
  pushd "$(vagrant_directory)" &> /dev/null || exit
  vagrant ssh "$@"
  popd  &> /dev/null || exit
}

vsshc() {
  pushd "$(vagrant_directory)" &> /dev/null || exit
  vagrant ssh -c "cd /ops || exit; $*"
  popd  &> /dev/null || exit
}

vu() {
  pushd "$(vagrant_directory)" &> /dev/null || exit
  vagrant up
  popd &> /dev/null || exit
}

# vim:ft=bash
