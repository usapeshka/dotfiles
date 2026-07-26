# Cheatsheet

Personal quick reference. Things I look up more than once land here.

**Convention:** one command per line, `#` comment on the same line saying what it
does. Prose notes go under a `**note:**` line inside the relevant section. If you
don't know where something belongs, put it in [Unsorted](#unsorted) — sorting later
is cheap, losing the note is not.

**Deeper docs:** AeroSpace tiling, workspaces, gotchas → [`aerospace/README.md`](aerospace/README.md)

---

## Git

```bash
git -C <repo> diff              # uncommitted changes
git -C <repo> log -p            # full history with diffs
git -C <repo> log --oneline     # compact history
git -C <repo> checkout .        # discard all uncommitted changes
git -C <repo> show HEAD:<path>  # read a file as of a commit
git mv <old> <new>              # rename, keeping history
git rm --cached <file>          # untrack but keep on disk
```

**note:** `-C <repo>` runs git against a repo without `cd`-ing. For this repo:
`git -C ~/.config diff`.

---

## AeroSpace

```bash
aerospace reload-config --dry-run   # validate config without applying
aerospace reload-config
aerospace list-monitors
aerospace list-workspaces --all --format '%{workspace} root=%{workspace-root-container-layout}'
aerospace list-windows --all --format '%{window-id} | %{workspace} | %{app-name} | %{window-title}'
```

Inspect the layout tree of a workspace — the debugging command:

```bash
aerospace list-windows --workspace A \
  --format '%{window-id} %{app-name} parent=%{window-parent-container-layout} self=%{window-layout}'
```

**note:** reading it — every window `parent=h_tiles` means a flat row, no nesting
(so no grid). Two windows sharing `v_tiles` means those two are a nested column.
`self=floating` means that window is ignoring tiling entirely.

**note:** `Alt+Shift+H` in main mode is `move` (reorders). Joining into a container
needs `Alt+Shift+;` first. This is the mistake I keep making.

---

## macOS

```bash
~/.config/macos/tuning.sh status    # current animation / Dock / shortcut state
~/.config/macos/tuning.sh apply     # reapply (idempotent) — use on a new machine
~/.config/macos/tuning.sh revert
```

```bash
osascript -e 'id of app "App Name"'          # bundle id, for AeroSpace window rules
defaults read <domain> <key>                 # read one setting
defaults read -g <key>                       # NSGlobalDomain
defaults delete <domain> <key>               # back to system default
sw_vers                                      # macOS version
```

Exact plist keys, including stray whitespace:

```bash
/usr/libexec/PlistBuddy -c 'Print :NSUserKeyEquivalents' ~/Library/Preferences/.GlobalPreferences.plist
```

**note:** `defaults write` always succeeds — it only stores a key. It does **not**
prove macOS still honours it. Plenty of circulated tweaks went inert years ago.

**note:** `defaults write com.apple.Safari …` fails — Safari's prefs are in a
TCC-protected container. Use `-g` (global) instead; key equivalents match on menu
item *title*, so it works across apps.

### Shortcuts I added

| Keys | Action |
|---|---|
| `Cmd+Option+N` | Move Tab to New Window (Safari, Terminal) |
| `Cmd+Option+Ctrl+Shift+M` | where Hide / Minimize went, i.e. disabled |

**note:** modifier glyphs — `@`=Cmd `~`=Option `^`=Ctrl `$`=Shift

---

## Shell

```bash
command -v <cmd>        # is it installed, and where
```

---

## Unsorted

<!-- Dump anything here. Sort it when the section gets annoying. -->
