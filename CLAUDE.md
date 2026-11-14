# CLAUDE.md

James's dotfiles: shell, editor, terminal and tool configs for his Macs
(Apple silicon, Homebrew in `/opt/homebrew`), plus a few Linux-only pieces.
The remote is `git@github.com:jbboynton/dotfiles.git`, on `main`.

Read this before changing anything. Most of it records decisions already
made, so they don't get re-litigated or quietly undone.

## How files get into place: rcm, through `rc`

The repo is managed with [rcm](https://github.com/thoughtbot/rcm). Every
top-level entry becomes a dotfile in `~`: `zshrc` → `~/.zshrc`,
`config/gh/config.yml` → `~/.config/gh/config.yml`, `bin/rc` → `~/.bin/rc`.
`rcrc` (linked as `~/.rcrc`) holds the exceptions:

- `UNDOTTED`: installed without a dot (`Brewfile` → `~/Brewfile`,
  `Library` → `~/Library`).
- `COPY_ALWAYS`: installed as a copy, not a link. `Library/LaunchAgents/*`
  is here because launchd won't load a symlinked LaunchAgent. After a copy
  changes, reload it with `launchctl bootout` / `launchctl bootstrap`.
- `EXCLUDES`: never installed (`CLAUDE.md`).

**Never run rcm's commands directly, and never overwrite a file in `~`.**
Losing a config file is the worst outcome here, so the rule is absolute:
nothing in the home folder is replaced unless git already has its contents,
or James passes `--force`. Even then it's moved aside, not deleted.

`bin/` has shims named `mkrc`, `rcup`, `rcdn` and `lsrc` that refuse to run
and point to `rc` (`bin/rc`). `rc help` prints a short summary. `rc` uses
rcm only to read its file list (`lsrc`). It makes links itself with
`ln -s` (no `-f`), copies with `cp -n` and moves with `mv -n`, so an
existing path makes a step fail instead of being replaced, and it checks
every step afterwards.

| Command | Does |
| --- | --- |
| `rc add FILE...` | Move files into the repo and link them back. Refuses folders, links, and anything already in the repo. `--undotted` for files with no leading dot, `--copy` for copies; both also record the setting in `rcrc`. |
| `rc sync` | Pick up changes made on another Mac: `git merge --ff-only` from the remote (git refuses rather than merging, or touching files with uncommitted changes), then `rc link` and `rc prune`. |
| `rc link` | Link or copy everything into place. Anything in the way is skipped and listed, untouched. A copy that is merely out of date (it matches a version git has committed, so it wasn't edited here) is updated, with the old one moved to `~/.rc-displaced/`. |
| `rc link --force` | Same, but whatever is in the way is first moved to `~/.rc-displaced/<timestamp>/`, keeping its path. |
| `rc unlink FILE...` | Remove links that point into the repo. Never removes real files. There is no "unlink everything". |
| `rc prune` | Remove broken links that point into the repo. |
| `rc ls` | `lsrc`, passed through. |

Every command except `ls` takes `--dry-run`. Use it first.

The test for "safe to replace" is whether git already has the contents:
links always qualify (they point into the repo), and so does a copy that
matches any committed version of its file. Anything else in the home folder
is James's and is never replaced without `--force`.

Why rc avoids rcm's own commands, learned the hard way:

- `rcup` overwrites anything that doesn't match once its prompt is
  answered, and `-f` skips the prompt. It has no never-overwrite mode.
- `rcdn` deletes `COPY_ALWAYS` files and whole folders whose parent is a
  link.
- `rcup FILE` (a single file) ignores `UNDOTTED`, and once installed
  `Library/...` into `~/.Library`.
- A new file in the repo isn't live until `rc link` links it.

### Files an app rewrites

Some apps replace their config file on every save, which turns a symlink
back into a plain file. Don't link those. `bin/snapshot_config` copies the
file into the repo, with a restore header on top, and commits just that
file. A LaunchAgent in `Library/LaunchAgents/` runs it when the file's
folder changes. LinearMouse works this way: the real file stays at
`~/.config/linearmouse/linearmouse.json`, and the committed copy is
`config/linearmouse/linearmouse.json.bak`, linked next to it.

## Shell startup

Startup speed is the main design constraint: count milliseconds. Nothing
may start a program (`$(...)`, `eval "$(tool ...)"`) while the prompt is
loading.

- **`zprofile`** runs only in login shells. tmux sets
  `default-command "${SHELL}"`, so panes are not login shells: they inherit
  the environment of the tmux server. A change to `zprofile` only reaches
  panes after `tmux kill-server`. Homebrew's variables are set by hand in
  `brew_env` rather than with `brew shellenv`.
- **`zshrc`** sets up history and zinit, declares plugins, then sources
  every file under `~/.zsh/`.
- **zinit turbo** (`wait'0'`, `lucid`) loads anything that can wait until
  after the prompt: plugins, fzf's bindings, gitstatus. The main block's
  `atinit` runs `zicompinit`, so fzf-tab is listed first in that block,
  ahead of plugins that wrap widgets. A file in `zsh/` can declare its own
  turbo block; `zdharma-continuum/null` with `id-as`, `as'null'` and
  `atload` is the pattern for "run this function later".
- **Hard-coded values need a drift check.** When a value is written out
  instead of computed (Homebrew's variables, batman's `MANPAGER`),
  `bin/env_drift` compares it with what the tool reports.
  `zsh/drift.zsh` runs it once a day in the background, at low priority,
  with a 5-second timeout, and warns at the next prompt on a mismatch or a
  timeout. Add a check there for each new hard-coded value.
- `fpath` isn't exported, so tmux panes don't inherit it. Anything added to
  it goes in a file in `zsh/` (see `zsh/homebrew.zsh`), not in `zprofile`.

### Files in `zsh/`

| File | Purpose |
| --- | --- |
| `aliases.zsh` | Aliases. `cat` and `less` are `bat`. |
| `alias-reminders.zsh` | zsh-you-should-use in hardcore mode: a command typed out in full, when an alias exists for it, is stopped and the alias shown. Also `alias_candidates`, which lists frequent full commands without an alias. |
| `bat.zsh` | `MANPAGER` and `MANROFFOPT` for batman, written out (checked by `env_drift`). |
| `drift.zsh` | Schedules `env_drift` and shows its report. |
| `fzf.zsh` | fzf's bindings (Ctrl-R, Ctrl-T) in a turbo block, plus Ctrl-P for files and folders. |
| `fzf-tab.zsh` | fzf-tab settings. Tab accepts the highlighted completion. |
| `homebrew.zsh` | Homebrew's completions on `fpath`. |
| `keybindings.zsh` | Every key binding, history search included, in one place. |
| `prompt.zsh` | Path plus git status from gitstatus. gitstatus keeps a daemon, and the prompt waits at most 10 ms before updating in the background. |
| `functions/` | One function per file. |

## Style

### Files in `zsh/`

Match the hand-written files exactly:

```zsh
# Title of file (the file name, in sentence case)
# One line on what the file is for

# One extra-terse line introducing what follows
some_config_line
```

- Spaces, never tabs. Don't line up trailing comments with spaces.
- A blank line before and after each `if`, `for` and `while` block.
- Comments say what and why, briefly; code says how.

### Scripts

- Shebangs are `#!/usr/bin/env bash` (or `zsh`, `python3`), never
  `#!/bin/bash`.
- Executable scripts stay executable. `sed -i` replaces the file and can
  drop the executable bit, so check `git diff --summary` for mode changes
  after bulk edits.

### Script output

How every utility script here prints, so they read alike. `bin/rc` is the
reference implementation (`out`, `err`, `gap`, `item`, `heading`, `tally`).

- **Blank lines group output.** Related lines sit together, with one blank
  line between groups. Output always ends with exactly one blank line, so
  the prompt sits a line below the last thing printed. Errors too.
- **Color sets the hierarchy, subtly, the way Homebrew does.** Headings are
  a blue `☞` with bold text; errors start with a bold red `‼︎`; notes with
  a yellow `Ꙫ!`. Bold picks out the one thing to notice (a
  command to run, a summary label). Cyan is for changes and secondary
  labels. Green means success, yellow a warning or a skip, red an error.
- **Per-file lines lead with a colored marker,** padded to two columns so
  paths line up: `✓⧾` added (green), `✓✧` changed and `⨉` removed (cyan),
  `◌` skipped or a warning (yellow), `⚑` failed (red, to stderr).
- **Summary counts are colored only when they are not zero.**
- **Color only on a terminal,** and never with `NO_COLOR` set, so piped
  output stays plain.

### Commits

Follow the existing history:

- Subject: imperative, sentence case, no trailing period, about 50
  characters at most ("Timestamp zsh history entries", "Make `rcred` a bin
  script").
- Code names in backticks.
- A blank line, then a body wrapped at 72 that says what changed and why,
  for anything not obvious from the subject. `- ` for lists.
- One logical change per commit.
- Commits are GPG-signed (`commit.gpgsign = true`). Never bypass signing;
  if it fails, stop and say so.
- The LinearMouse agent commits on its own as "Snapshot linearmouse.json".

## Tools and the decisions behind them

- **bat** is the pager for everything: `cat`/`less` aliases, gh, and man
  pages through bat-extras' batman. `bin/bat_extras_install` builds
  bat-extras from source into `~/.local/bin`. The built scripts start 2–3
  times faster than the source ones. It minifies everything when `shfmt` is
  installed, otherwise only the libraries.
- **delta** is git's pager and diff filter, with `zdiff3` conflicts.
- **entr** is installed (batwatch uses it) with no wrapper on purpose. Use
  it directly, in its own tmux window.
- **fzf-tab** replaces zsh's completion menu. fzf can't show completions
  horizontally, or fill them in while you move through them. If fzf-tab
  stops being worth it, fall back to zsh's own `menu select` with fuzzy
  matching.
- **Alacritty** reads `~/.config/alacritty/alacritty.toml`; the YAML file is
  unused. Option is not Alt (`option_as_alt` is off), so special characters
  still type. The few Option and Cmd combinations zsh needs are bound one
  by one under `keyboard.bindings`.
- **tmux** passes Alacritty's truecolor through (`terminal-features`).
- **gh**: `config/gh/config.yml` is managed. `hosts.yml` holds the login
  token and is gitignored. Never commit it.

## Safety

- **Ask before downloading or installing anything** (brew, pip, npm, git
  clone, curl), and remove whatever a task installed once it's done.
- **Back up before anything big.** `~/Code/dotfile-updates/backup.sh`
  copies every path rcm manages, plus the whole repo, with a manifest;
  `restore.sh` in each backup puts paths back (dry run unless `--apply`).
- **Secrets never go in the repo.** Ignored by design: `config/gh/hosts.yml`,
  `ssh/*` except `ssh/config`, `bin/teste` (a scratch script that stays
  local).
- **Known, and not secrets:** the default password in `bin/work/create_user`
  and the token in `bin/work/dup_ticket_test.json` have been defunct for
  years. Leave them as they are; don't flag them in scans.
- Some Claude setups can't read shell startup files (`zshrc`, `zprofile`)
  or credential folders. When that happens, give James the exact edit
  rather than working around it.

## Open items

As of November 13, 2026:

- The spell file (`vim/spell/en.utf-8.add`) gains words almost every time
  James writes prose in vim, which leaves the repo permanently dirty. Plan:
  a LaunchAgent, like the LinearMouse one, that commits it whenever it
  changes, replacing `bin/sup`. vim writes it through the link, so it only
  needs committing, not copying.
- `bin/dup` was an earlier attempt at what `rc sync` does now, and is
  superseded by it.
- Clean up old backups and unused configs once everything is confirmed
  working.
- The home folder audit, which includes the unfinished Homebrew cleanup.
  That cleanup's whole state (decisions, rules, restore notes) is in
  `~/Notes/brew-todo.md`; read it before touching Homebrew.
- Still to build: a vim write hook that offers a one-word command to commit
  a changed dotfile through Claude Code.

## Related

- `~/Code/OpenWithVim`: opens files from Finder in vim, in a new tmux window.
- `~/Code/micpatch`: retired. Read its `RETIRED.md` before reviving it.
