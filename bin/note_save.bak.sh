#!/bin/bash
# Persists notes to GitHub. Notes repository: https://github.com/jbboynton/notes

note="$1"
notes_dir="$HOME/notes"

base_file="$(basename -- "$note")"
file_without_ext="${base_file%.*}"
html_output="$notes_dir/$file_without_ext.html"
tmp_output="$notes_dir/$file_without_ext.tmp.html"

error() {
  local message="$1"

  echo >&2 "Error: $message"
  exit 1
}

verify_note_is_markdown() {
  local extension="${base_file##*.}"

  [ "$extension" == "md" ]
}

note_exists() {
  [ -f "$notes_dir/$base_file" ]
}

clear_html() {
  [ -f "$html_output" ] && rm "$html_output"
}

add_head() {
  local html_head="$notes_dir/_head.html"

  cat "$html_head" >> "$html_output"
}

generate_html() {
  pandoc -o "$tmp_output" "$notes_dir/$base_file"
}

add_generated_html() {
  generate_html

  cat "$tmp_output" >> "$html_output"

  rm "$tmp_output"
}

add_tail() {
  local html_tail="</body></html>"

  echo "$html_tail" >> "$html_output"
}

build_html() {
  add_head
  add_generated_html
  add_tail
}

ensure_on_master() {
  local branch="$(git symbolic-ref --short -q HEAD)"

  [ "$branch" == "master" ]
}

save() {
  git add \*.md
  git commit -m "Auto-committed on save."
  git push origin master
}

note_exists || error "could not find note (looked in $notes_dir for $base_file)"
verify_note_is_markdown || error "note is note a markdown file ($base_file)"

clear_html
build_html

# ensure_on_master || error "on a branch other than master"
# save

# echo "You need to handle both: saving a file in Vim, and passing the name"
# echo "of a note to the note() command in the terminal."
