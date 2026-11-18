# CLAUDE.md

James's dotfiles: shell, editor, terminal and tool configs for his Macs
(Apple silicon, Homebrew in `/opt/homebrew`), plus a few Linux-only pieces.
The remote is `git@github.com:jbboynton/dotfiles.git`, on `main`.

Read this before changing anything. Most of it records decisions already
made, so they don't get re-litigated or quietly undone.

This file is the repo's only documentation: anything a future session
needs goes here, kept short and current, not in a separate doc that can go
stale. `.ignored/` (gitignored) holds local scratch, plus private docs that
must stay out of this public repo. Those are listed here, and are the only
files in it a session should read:

- `.ignored/home-audit.md`: the brief for the home folder audit (see Open
  items). Read it before working on the audit.
- `.ignored/handoff-tmux-queue.md`: where the tmux work stands (see Open
  items), and `.ignored/tmux-tests/`, the scripts that test it on a
  private tmux server.

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
back into a plain file, or keep settings in macOS preferences. Don't link
those. `bin/snapshot_config` copies the settings into the repo, with a
restore note at the top, and commits just that file. A LaunchAgent in
`Library/LaunchAgents/` runs it when the file (or its folder) changes, and
rcm links each copy, named `*.bak`, next to the original.

| App | Agent | What's copied |
| --- | --- | --- |
| LinearMouse | `linearmouse-snapshot` | device settings (`~/.config/linearmouse/linearmouse.json`) and app settings (preferences) |
| Keyboard Maestro | `keyboard-maestro-snapshot` | the macros file (see Keyboard Maestro) |
| iStat Menus | `istatmenus-snapshot` | the `com.bjango.istatmenus.menubar.7` and `.status` preferences |
| Thaw | `thaw-snapshot` | the profile, from `~/Library/Application Support/Thaw/Profiles/`; its live preferences are an opaque blob. A new profile needs its own line in the agent |

Options, all in `snapshot_config`'s header:

- `--plist` saves a binary plist as XML, so it diffs; the restore note is an
  XML comment, so the copy stays a valid plist.
- `--defaults DOMAIN` reads a preferences domain through `defaults export`.
  Restoring is `defaults import`, which merges, so left-out keys stay put.
- `--drop REGEX` leaves out matching top-level keys: noise (window frames,
  update checks, menu bar positions) and anything private. The repo is
  public; iStat Menus' license and device authorization are dropped. So
  is its `Item.Visibility`, which records whether each menu bar item is
  showing right now and flips many times a day.
- `--keychain SERVICE` refuses to write or commit if that Keychain item's
  value turns up in the copy.

It exits in milliseconds when the source isn't newer than the copy (some
apps touch their folder constantly), commits one snapshot at a time (several
agents can fire at once), and waits out a git lock James is holding. A
failed commit leaves the copy for a manual commit and notifies; the next run
tries again.

Snapshots are always committed to `main`, whatever is checked out. On a
feature branch the commit is built without touching the branch, the index
or the working tree, so a snapshot never lands in the middle of other work.
The copy then shows as modified on that branch until it is rebased onto
`main` (`git rebase --autostash main`), which already has it.

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
  - Turbo plugins load one at a time, in the order they are declared, and
    `zicompinit` takes about 300 ms. gitstatus is therefore declared first,
    in `zshrc`, though its functions are in `zsh/prompt.zsh`: declared
    last, the prompt's git info took 700 ms to appear; first, 190 ms.
    `wait'0a'` does not reorder it. `.ignored/tmux-tests/prompttime.sh`
    measures both.
- **Hard-coded values need a drift check.** When a value is written out
  instead of computed (Homebrew's variables, batman's `MANPAGER`, rbenv's
  shims folder),
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
| `alias-reminders.zsh` | zsh-you-should-use: a command typed out in full, when an alias exists for it, runs with a reminder of the alias (hardcore mode, which stops it instead, is off). Also `alias_candidates`, which lists frequent full commands without an alias. |
| `bat.zsh` | `MANPAGER` and `MANROFFOPT` for batman, written out (checked by `env_drift`). |
| `drift.zsh` | Schedules `env_drift` and shows its report. |
| `eza.zsh` | `EZA_COLORS` for eza listings. |
| `fzf.zsh` | fzf's bindings (Ctrl-R, Ctrl-T) in a turbo block, plus Ctrl-P for files and folders. |
| `fzf-tab.zsh` | fzf-tab settings. Tab accepts the highlighted completion. |
| `homebrew.zsh` | Homebrew's completions on `fpath`. |
| `keybindings.zsh` | Every key binding, history search included, in one place. |
| `rbenv.zsh` | What `rbenv init -` prints, written out (checked by `env_drift`). It replaced a plugin that ran rbenv in every new shell, about 80 ms; James rarely runs Ruby but wants it to keep working. |
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
  installed, otherwise only the libraries. `ll` and `llt` (in
  `zsh/functions/`) page through bat when the listing is taller than the
  window, and print plain when piped.
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
  by one under `keyboard.bindings`. Keyboard Maestro: cmd-return switches to
  its Space; shift-cmd-return runs `bin/alacritty_here`, which brings it to
  the current Space instead (a new window at the old one's frame, the tmux
  client moved over, the old window closed; macOS has no way to move another
  app's window between Spaces).
- **tmux** passes Alacritty's truecolor, OSC 8 links, underline styles and
  extended keys through (`terminal-features`). A feature reaches a client
  only when it attaches: reload, then detach and reattach.
  - `extended-keys` is `always` with the `csi-u` format. With `on`, tmux
    honors only xterm's request (`CSI > 4 ; n m`). Claude Code sends it;
    vim doesn't, so Alacritty's Ctrl-> binding reached vim as a plain `.`.
    A pane takes the setting when it is created: panes older than a
    change keep their old mode (`#{pane_key_mode}` shows it).
  - Alacritty names an ordinary key in a binding by the character it
    types with the binding's modifiers held: Ctrl-Shift-period is
    `key = ">"`, not `"."` and not `"Period"`. A name it doesn't know is
    accepted silently and never matches.
  - `allow-passthrough` stays off: it exists for desktop notifications,
    which Alacritty doesn't show.
  - A click (`MouseDown1Pane`) runs `bin/tmux_open`, which opens an OSC 8
    link, a bare URL, or a path that exists: text files in vim in a new
    window (`file:12` and `file#L12` jump to the line), the rest with
    `open`. Anything else is ignored, and the click still reaches the
    pane. A path that wraps onto a second row is not matched.
    Option-click (`M-MouseDown1Pane`) opens any path in vim instead: a
    folder, an image, or a bare name such as `bin`.
  - Fuzzy pickers: `prefix Tab` (windows) and `prefix Shift-Tab`
    (sessions) are tmux 3.8's own. `prefix F` is tmux-fzf, for commands
    and key bindings.
  - **Test tmux changes on a private server, never James's:**
    `tmux -L NAME -f CONF`, with the plugin lines stripped from the copy of
    `tmux.conf` (continuum would restore, then autosave over, his saved
    sessions). For a real client, run it under `script -q FILE env
    TERM=alacritty tmux -L NAME ... new-session CMD` and pipe keys and
    SGR mouse clicks into its stdin; `FILE` then holds what tmux sent the
    terminal. Kill the server afterwards.
- **Claude Code's editor** (Ctrl-G) is `bin/claude_edit`, set as `EDITOR`
  under `env` in `~/.claude/settings.json` (not in this repo), so only
  Claude Code sees it. It opens vim in the pane below Claude's, holding
  only the draft, and shows the whole chat in Claude's pane meanwhile.
  `prefix e` picks a different pane; `prefix E` resets that.
  - Not a floating pane, by James's choice. vim starts in a window named
    "parked" and trades places with the target (`swap-pane`), so no pane
    changes size; the target waits there and is traded back. With no pane
    below Claude, vim gets a split.
  - Claude Code blanks its own pane while its editor runs, and cannot be
    kept interactive. The script runs `less` there on the whole chat,
    rebuilt from the session's transcript and opened at the end, so James
    can scroll back while he writes (keys or the wheel, with that pane
    focused). It is a copy of the text, not Claude's own screen: no tool
    output. Claude Code redraws when the editor exits.
  - `pandoc -t ansi` renders the chat: bold and italics without their
    markup, and links as OSC 8 hyperlinks that can be clicked. James asked
    for no label on the pager and no part of the chat in the vim buffer.
    Outside tmux there is no second pane, so there the last message still
    goes above the draft and is stripped on exit.
  - James's choices for the chat view, to look like Claude Code's own:
    `❯ YOU` and `❯ CLAUDE` before each speaker's text (two blank lines
    above each but the first), which is indented two spaces and stays
    within 80 columns; inline code cyan; links light cyan, underlined,
    bold only inside bold text. Tables are the exception to 80 columns:
    the script draws them itself, each column as wide as its content,
    wrapping cells only at the pane's width (pandoc's gfm reader makes
    every column of a wide table equal), with four spaces between
    columns and the header row bold light blue over a dim blue rule.
    A table sits two spaces further in than the text, with two blank
    lines above and below it. Every second row has a faint background
    (James wanted neither blank lines nor rules between rows), which
    also marks out a row whose cells wrap onto several lines; the header
    has a different, bluish one. A space of padding sits inside the left
    and right edges. No column is narrower than its longest word.
  - `:wq` sends the reply if it was written or changed. `:cq`, a kill, or
    an unchanged draft sends nothing and leaves the text in Claude's
    prompt. `CLAUDE_EDIT_SEND=0` turns sending off.
    - Claude Code drops an Enter that arrives before it has read the
      reply back, about 100 ms after the script exits. So a process the
      script leaves behind reads Claude's pane every few milliseconds and
      presses Enter once the prompt (the `❯` row under a rule) starts
      with the reply. If it never sees that, it presses Enter at 0.6
      seconds, the fixed wait this replaced. It depends on how Claude
      Code draws its prompt; `.ignored/tmux-tests/realsend.py` checks it
      against a real Claude Code.
  - Speed is the point; James feels 200 ms. Measured with
    `.ignored/tmux-tests/opentime.py` on a 150-message chat: vim starts
    about 110 ms after Ctrl-G and the chat is on screen by 130 ms (850 ms
    before the cache); the reply is sent about 135 ms after `:wq`.
    - pandoc takes half a second on a long chat, so its output is kept
      under `$TMPDIR/claude-edit-cache`, per transcript and text width.
      Each Ctrl-G styles only what the transcript has gained. Table
      layout is not kept; it takes milliseconds, so resizing is cheap
      too. A Stop hook in `~/.claude/settings.json` runs
      `claude_edit --warm` when Claude finishes a turn, so the cache is
      usually complete before Ctrl-G. Raise `CACHE` in the script when
      the styling of kept text changes.
    - vim's pane signals its exit on a tmux channel (`wait-for`); the
      script does not poll tmux for it.
  - `q` in that pane resets it after a stray key or click: the pager
    quits and the script starts it again at the end, laid out afresh. A
    change in the pane's width lays it out afresh unasked (less swallows
    the first key after a resize, so `q` alone would take two presses)
    and keeps the reader's place, by finding the top line on screen in
    the old layout and the same text in the new. Keys
    that would leave the chat (`v`, `!`, `s`, `|`, `h`) do nothing.
  - The pager is not in mouse mode (`--mouse`): there it leaves a clicked
    link highlighted and jumps on a right-click. The script tags the pane
    `@chat_view`, and tmux's `WheelUpPane`/`WheelDownPane` bindings send
    it `k`/`j`; clicks open links through `tmux_open`, drags select.
  - Ctrl-V in the reply's buffer pastes through `bin/claude_paste` and
    `vim/autoload/claudepaste.vim`. Ordinary text goes in as it is. A file
    copied in Finder, an image on the clipboard, or text over 40 lines
    goes in as a label, `[Image #1]`, with a line for it at the end of the
    buffer: `[Image #1]: file:///path`. Labels count up by kind (Image,
    Video, File, Text). Only text returns from the editor, so the path is
    how the image reaches Claude, which opens it on reading the reply.
    Clipboard images and long text are saved under `$TMPDIR/claude-paste`,
    which macOS clears of files unused for three days.
  - It stays `less`, not bat: bat is not a pager and would run the same
    `less` underneath, and its markdown highlighting shows the markup
    that pandoc's rendering hides.
  - This is the first step toward a queue layout for the bullpen (current
    chat top left, its terminal or reply below, waiting chats stacked on
    the right). The design is James's sketch; ask him for it.
  - Claude Code passes one file, `claude-prompt-*.md`; anything else (git,
    from Claude's shell) gets plain vim.
  - The editor's environment has no session ID. The script finds it from
    `~/.claude/sessions/<pid>.json` of its parent Claude process, which is
    undocumented and may move.
  - Claude Code's own `externalEditorContext` does the same as `#` lines,
    unwrapped. Leave it off; the script copes if it is on.
- **Claude Code's status line** is `bin/claude_statusline`, set as
  `statusLine` in `~/.claude/settings.json` (not in this repo). Its header
  documents every mark. The layout is James's: two lines per
  repository. The first is `project | agent/lane ‹branch› marks` at
  the left and, for the first repository, `model effort ＊` at the
  right. The second is `build test ci e2e merge` at the left and the
  pull requests or the release at the right. A blank line ends the
  output; Claude Code drops a line that is empty or only spaces, so
  it holds a blank braille cell (U+2800). The project name is yellow,
  like the prompt's path. James chose to drop the environment.
  - `claude_statusline --alias NAME [DIR]` shows a repository under
    another name (an empty NAME undoes it). The aliases are in
    `~/.config/claude_statusline/aliases`, outside this public repo
    because they name private projects.
  - `claude_statusline --lines 1 [DIR]` drops a repository's second
    line (marks, pull requests, release), for projects that do not
    need it, such as this one; `--lines 2` brings it back. The list
    is `~/.config/claude_statusline/one-line`.
  - Commits ahead and behind are `￪2 ￬1` in gray. Not green and red,
    which read as lines added and removed, and not subscript digits,
    which were too hard to read.
  - The script is live in every open session the moment it is saved.
    Edit a copy, test it with sample JSON on stdin, then copy it over.
  - Everything clickable is an underlined OSC 8 link. The project name's
    link is `file://FOLDER#alt=GITHUB_URL`: `tmux_open` opens the folder
    on a click and the part after `alt=` on an Option-click.
  - Links do not respond to hover inside tmux: with `mouse on`, tmux
    takes the mouse and has no hover event. Alacritty highlights a link
    under the pointer only while Shift is held.
  - The agent is the pane's `@role` (the bullpen sets it; `terminal`
    counts as none), else the `--agent` name. The lane is the folder
    name of a linked git worktree, and the project is then the
    repository it was cut from.
  - `build`, `test` and `e2e` come from records that `bin/report_run`
    writes, not from what an agent says: running, passed or failed,
    with the time and the commit, one per repository. `npmrc` sets it
    as npm's `script-shell`, so every `npm test`, `npm run e2e` and
    `npm run build` on this Mac is recorded whoever runs it, and no
    project's `package.json` names it (CI does not have the script).
    Other npm scripts go straight to `/bin/sh`. For anything that is
    not an npm script: `report_run test -- COMMAND`. Every run is
    also a line in `~/.local/state/claude_statusline/runs.tsv`, with
    how long it took; `report_run --log [DAYS]` adds them up.
  - Each of the four marks is `✓` passed, `✕` failed or `–` nothing to
    report, and has two sources: the run `report_run` recorded here,
    and GitHub's checks on the commit, sorted by name (`checks_e2e`,
    `checks_build` and `checks_test` at the top of the script; `ci`
    is the rest). A failure in either wins.
  - A result belongs to code, not to a commit. `report_run` records
    the tree of the tracked files, and the status line compares it
    with the tree now, so an edit dims the mark's name and committing
    what was tested does not. GitHub's checks are dim while there
    are changes to commit. The sign keeps its color either way: James
    wanted a pass to read green and a failure red at a glance.
    Untracked files do not count. The trees
    come from staging everything in a copy of the index (`add -u`,
    `write-tree`); the real index is never touched.
  - Each name has its own color (blue, cyan, magenta, plain, navy), dim
    until it has a result for this code, and a failure is red
    throughout. A failure in any one resets the rest to `–`:
    `report_run` deletes the other records, and the status line hides
    a pass while something is failing.
  - Cost, measured 2026-11-18: a render takes 26 ms. Refreshing a
    repository's git cache takes 60 ms, or 85 to 95 ms with changes to
    commit; it runs inside a render only when HEAD or the index has
    changed, otherwise behind it. `report_run` adds 56 ms to a run it
    records and 9 ms to any other npm script.
  - `merge` says whether the release pull request can be merged: no
    conflicts. It is about the release, not the checkout, so it takes
    no part in the reset. Being behind `main` does not fail it: James
    cares about conflicts, and being behind is not one.
    `release_linear` in the script adds that stricter check.
  - `release #567 (16 ✔︎ 43 ✕)` is the open release pull request, into
    `main` from `staging` or a `release/` branch. James's rule for the
    counts: only pull requests that its description lists count,
    green when every check on their last commit passed, red
    otherwise. Issues, labels and milestones are not trusted. The
    bullpen's release descriptions have listed issues so far, which
    count for nothing.
  - `＊` means a newer Claude Code is out. Claude Code's own "Update
    available!" notice is turned off with `DISABLE_AUTOUPDATER` under
    `env` in `~/.claude/settings.json`, which also stops its version
    check, so the script asks `downloads.claude.ai` itself every six
    hours. Homebrew installs the updates either way.
- **Vim's spelling** is `vim/autoload/spellmenu.vim` and
  `vim/rcfiles/spelling`. Capitalization at the start of a sentence is
  fixed on leaving insert mode, in the lines just typed only; `u` takes
  a fix back. Spelling and ALE errors are curly underlines in the
  error's color (`t_Cs`, `t_AU` in `vim/rcfiles/general`). Vim's word
  list is `vim/spell/en.utf-8.add`; `config/aspell/personal.en.pws` is
  aspell's, empty and unused by Vim.
- **Chat state.** Claude Code hooks in `~/.claude/settings.json` (global,
  not in this repo) run `bin/agent_state`, which records on the chat's
  tmux pane whether Claude is `working`, `blocked` (a permission prompt or
  a direct question) or `idle`. An agent with a question that can wait
  runs `agent_state wants QUESTION` itself. The status bar puts a red `✕`
  after a window's name for each blocked chat in it, and a yellow `...`
  right after the name when a chat in it wants input.
  - The hooks are `async`, print nothing and always exit 0: a hook that
    prints or fails can change what Claude does.
  - No hook fires when James denies a permission prompt; the state
    corrects itself at the next tool call or the end of the turn.
- **gh**: `config/gh/config.yml` is managed. `hosts.yml` holds the login
  token and is gitignored. Never commit it.

## Keyboard Maestro

The macros live in Keyboard Maestro's own file,
`~/Library/Application Support/Keyboard Maestro/Keyboard Maestro Macros.plist`,
which it rewrites on every save. A LaunchAgent snapshots it into
`Library/Application Support/Keyboard Maestro/Keyboard Maestro Macros.plist.bak`
and commits it (see "Files an app rewrites"). To restore, quit Keyboard
Maestro and its Engine, then run the `plutil` command in the copy's header.

- **No secrets in macros.** The repo is public. A macro that needs a
  password reads it from the login Keychain when it runs, with an Execute
  Shell Script action (results trimmed, to the clipboard or pasted):
  `security find-generic-password -a "$USER" -s 'Keyboard Maestro: NAME' -w`.
  Add each such item to the `--keychain` list in
  `Library/LaunchAgents/com.jamesboynton.keyboard-maestro-snapshot.plist`
  and reload the agent.
- **Back up a macro before changing it**: a `.kmmacros` file (a plist array
  holding one group whose `Macros` contains the macro's XML), outside the
  repo. Double-clicking it imports it again.
- **Working on macros without James's hands**, all through osascript:
  - Read with `xml of macro id "UUID"` (Keyboard Maestro Editor). Change
    with `set xml of action N of macro ...`; a whole macro's `xml` can't be
    set. Create with `make new macro`, then `make new action` and
    `make new trigger` `with properties {xml: ...}`.
  - Run with `tell application "Keyboard Maestro Engine" to do script "UUID"`.
    It returns when the macro finishes, so timing the call times the macro.
  - Check results through Keyboard Maestro, which has Accessibility
    permission (osascript doesn't): pass an Execute AppleScript action's XML
    to `do script`, saving its result to a variable, and read it with
    `getvariable`. `CGWindowListCopyWindowInfo` (from JXA, no permission
    needed) shows which windows are on the current Space.
  - Switch Spaces for a test with System Events `key code 124 using control
    down`, run inside Keyboard Maestro; its own keystroke action lacks the fn
    flag the shortcut needs. Close test windows afterwards, and leave
    James's windows where they were.
  - The Engine's log: `~/Library/Logs/Keyboard Maestro/Engine.log`.
- **Macros that pair with this repo:** cmd-return activates Alacritty;
  shift-cmd-return runs `~/.bin/alacritty_here`. Shift-cmd-/ activates
  Claude; shift-opt-cmd-/ runs `~/.bin/claude_here`, which holds Claude's
  title bar and switches back (Claude has no New Window command and ignores
  menu commands while in the background). Cmd-' and shift-cmd-' open a
  Firefox window and a private one in the current Space: they press the File
  menu item through Accessibility, because Firefox's own `--new-window`
  activates Firefox first and macOS then switches Spaces. Cmd-\ opens a
  Finder window at the last folder used; "Remember the last Finder folder"
  keeps a fallback in the `FinderLastFolder` variable.

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

As of November 16, 2026:

- The tmux work is in two parts. Part 1 (PR 31) landed on November 16.
  Part 2 (PR 32, `tmux-quality-of-life-2`) is `claude_queue`, a queue in
  the bullpen's `pm` window of the chats that need James: built and
  tested on a fake bullpen, never run on the real one, and paused until
  part 1 has been in use for a while. Its state, James's decisions and
  what is left are in `.ignored/handoff-tmux-queue.md` and in PR 32. Its
  branch predates part 1's last commit (the chat cache and the faster
  send) and must be rebased onto `main` first; expect conflicts in
  `bin/claude_edit`.

- The spell file (`vim/spell/en.utf-8.add`) gains words almost every time
  James writes prose in vim, which leaves the repo permanently dirty. Plan:
  a LaunchAgent, like the LinearMouse one, that commits it whenever it
  changes, replacing `bin/sup`. vim writes it through the link, so it only
  needs committing, not copying.
- `bin/dup` was an earlier attempt at what `rc sync` does now, and is
  superseded by it.
- Clean up old backups and unused configs once everything is confirmed
  working.
- The home folder audit (brief: `.ignored/home-audit.md`), which includes
  the unfinished Homebrew cleanup.
  That cleanup's whole state (decisions, rules, restore notes) is in
  `~/Notes/brew-todo.md`; read it before touching Homebrew.
- Still to build: a vim write hook that offers a one-word command to commit
  a changed dotfile through Claude Code.
- The QuickTime recording macros ("Start QuickTime movie recording" and
  the two "Stop" ones) wait through fixed pauses, up to 5.5 seconds, and
  click fixed screen positions. Replace them with Pause Until conditions
  on the window or button, and test with real recordings.

## Related

- `~/Code/OpenWithVim`: opens files from Finder in vim, in a new tmux window.
- `~/Code/micpatch`: retired. Read its `RETIRED.md` before reviving it.
