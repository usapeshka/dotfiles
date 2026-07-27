# AeroSpace: Tiling, Workspaces & Daily Use

Practical guide to *this* config (`aerospace.toml`, same directory).
Everything here was verified against AeroSpace 0.21.3-Beta on this machine.

---

## Cheat sheet

| Keys | Action |
|---|---|
| `Alt+Enter` | New terminal window **here** |
| `Alt+H/J/K/L` | Focus left / down / up / right |
| `Alt+Shift+H/J/K/L` | **Move** window (reorder) |
| `Alt+Shift+;` → `Alt+Shift+H/J/K/L` | **Join** window with neighbour (nest → grids) |
| `Alt+/` | Flip orientation: columns ↔ rows |
| `Alt+,` | Accordion (stack, one visible) |
| `Alt+F` | Fullscreen |
| `Alt+Shift+Space` | Float / unfloat |
| `Alt+-` / `Alt+=` | Shrink / grow |
| `Alt+B` | **Reset**: flatten all nesting + equalise |
| `Alt+Shift+B` | Equalise only (keeps nesting) |
| `Alt+1..4` | Workspace 1–4 (external) |
| `Alt+A/S/D/G` | Workspace A/S/D/G (MacBook) |
| `Alt+Shift+<same>` | Send window to that workspace, follow it |
| `Alt+Tab` | Previous workspace |
| `Alt+Shift+M` | Focus the other monitor — lands on whatever workspace is visible there (`*1\|S` ↔ `1\|*S`) |
| `Alt+Shift+;` | Service mode (then `Esc` to leave) |

Service mode extras: `R` reset · `Shift+R` sort every window to its home workspace (`sort-windows.sh`) · `B` balance · `F` float · `Backspace` close all but current · `Esc` reload config.

---

## 1. Mental model

Don't think about monitors first. Think:

```
Windows  →  Containers  →  Workspace  →  Monitor
```

- A **window** is one app window.
- A **container** groups windows and has one orientation: horizontal or vertical.
- A **workspace** is a whole desktop. It lives on exactly one monitor.
- A **monitor** shows exactly one workspace at a time.

The crucial part: **a workspace is a tree.** Windows are leaves, containers are
branches. You never place windows at coordinates — you reshape a tree.

```
Workspace A
└── root (horizontal)
    ├── VS Code
    └── container (vertical)
        ├── Browser
        └── Terminal

┌───────────────┬────────────┐
│               │  Browser   │
│   VS Code     ├────────────┤
│               │  Terminal  │
└───────────────┴────────────┘
```

That picture *is* the tree. Nothing more to it.

---

## 2. This machine's layout

External monitor sits **above** the MacBook. Arrange macOS Displays the same way.

```
      ┌──────────────────────────┐
      │   HP                     │   1  2  3  4   ← main surface
      │   (external)             │
      └──────────────────────────┘
                   ▲
      ┌──────────────────────────┐
      │   MacBook built-in       │   A  S  D  G   ← side surface
      └──────────────────────────┘
```

Numbers = external. Letters = laptop. Workspace switching happens far more
often on the external (it's where the active work lives), and `Alt+1..4` is
the easiest chord to hit — so the numbers go to the monitor you switch on
most. (This is a swap of the original layout, which had numbers on the
laptop and letters on the external.)

To hop between the two monitors without thinking about workspace names at
all, `Alt+Shift+M` focuses the other monitor — it lands on whatever
workspace happens to be visible there, so it stays correct no matter what
you have open. The mouse warps along with focus
(`on-focused-monitor-changed`).

Suggested purposes (consistency builds muscle memory):

| WS | Monitor | Purpose |
|---|---|---|
| 1 | External | Terminal / ad-hoc shell |
| 2 | External | Finder / files |
| 3 | External | Slack / Messages / Mail |
| 4 | External | Music / utilities |
| A | MacBook | IDE / editor |
| S | MacBook | Browser / docs |
| D | MacBook | Database / API tools |
| G | MacBook | Scratch / temporary |

Pinning is enforced by `[workspace-to-monitor-force-assignment]` at the bottom
of `aerospace.toml`.

### Pin what you glance at, not what you work in

The "one app per workspace" model is a good *starter* model and a bad
*steady-state* model. Terminals and browsers want to sit **beside** the thing
they act on — pinning them fights the whole point of tiling.

So: numbers lean app-pinned (Slack, Music, Mail — singletons you visit).
Letters are **task**-scoped: workspace A is "the auth refactor", holding
whatever editor + terminal + browser that work needs.

Read the table above as *purpose*, not *inventory*. Workspace 1 is not "every
terminal I own" — a terminal running your dev server belongs on A next to the code.

---

## 3. The two rules of tiling

Everything follows from these.

**Rule 1 — `Alt+/` transposes.**
Flips the orientation of the container holding the focused window. If that window
is a direct child of root, the whole workspace transposes: columns ↔ rows.

**Rule 2 — join nests, and the new container is the OPPOSITE orientation.**
`join-with` is the only command that adds nesting, so it is the only route to a
grid. You never specify the orientation — it alternates automatically.

| You are in | You join | New container is |
|---|---|---|
| horizontal row | left / right | **vertical** |
| vertical column | up / down | **horizontal** |

This is backwards from most people's intuition. The direction key says *which
neighbour to grab*, not what orientation to produce.

**Where new windows go:** next to the focused window, inside that window's
**parent container**. So the parent's orientation decides whether `Alt+Enter`
gives you a new column or a new row.

---

## 4. Tiling recipes

`JOIN-LEFT` below = `Alt+Shift+;` then `Alt+Shift+H`.

### One window

```
┌──────────────────────┐
│          T1          │
└──────────────────────┘
```

### Two windows — `Alt+/` is all you need

```
      root = h_tiles                    root = v_tiles
┌──────────┬───────────┐          ┌──────────────────────┐
│    T1    │    T2     │  Alt+/   │          T1          │
│          │           │ ───────► ├──────────────────────┤
└──────────┴───────────┘          │          T2          │
                                  └──────────────────────┘
```

Both are direct children of root, so flipping root is the whole job. No join.

### Three windows

Plain (all siblings), `Alt+/` transposes:

```
┌───────┬───────┬──────┐          ┌──────────────────────┐
│  T1   │  T2   │  T3  │  Alt+/   │          T1          │
│       │       │      │ ───────► ├──────────────────────┤
└───────┴───────┴──────┘          │          T2          │
                                  ├──────────────────────┤
                                  │          T3          │
                                  └──────────────────────┘
```

**Main + sidebar** — `Alt+Enter`×3, focus is already on T3, `JOIN-LEFT`, `Alt+Shift+B`:

```
┌───────────┬──────────┐
│           │    T2    │
│    T1     ├──────────┤
│           │    T3    │
└───────────┴──────────┘
```

**Mirrored** — `Alt+Enter`×3, `Alt+H` `Alt+H` to reach T1, `JOIN-RIGHT`, `Alt+Shift+B`:

```
┌──────────┬───────────┐
│    T1    │           │
├──────────┤    T3     │
│    T2    │           │
└──────────┴───────────┘
```

### Four windows — the 2×2 grid

```
┌──────┬──────┬──────┬──────┐            ┌───────────┬──────────┐
│  T1  │  T2  │  T3  │  T4  │            │    T1     │    T3    │
└──────┴──────┴──────┴──────┘   ───────►  ├───────────┼──────────┤
       Alt+Enter ×4                       │    T2     │    T4    │
                                          └───────────┴──────────┘
```

1. `Alt+Enter` ×4 — four columns, focus lands on T4
2. `JOIN-LEFT` — nests T3+T4 into the right column
3. `Alt+H` — focus into the left pair (may take two presses)
4. `JOIN-LEFT` — nests T1+T2 into the left column
5. `Alt+Shift+B` — equal quarters

**Order matters.** You must spawn all four *first*. If you build the left column
early — two windows, join them — that container becomes root's only child and
flatten-normalization dissolves it, leaving two plain rows. **The sibling has to
exist before the nesting will survive.**

### One big + three stacked

Same move repeated, focusing each next window and joining left:

```
┌───────────┬──────────┐
│           │    T2    │
│           ├──────────┤
│    T1     │    T3    │
│           ├──────────┤
│           │    T4    │
└───────────┴──────────┘
```

---

## 5. move vs join — the #1 trap

Same keys, different mode, completely different command.

| Keys | Mode | Runs | Effect |
|---|---|---|---|
| `Alt+Shift+H` | main | `move left` | **Reorders.** Structure unchanged. |
| `Alt+Shift+;` → `Alt+Shift+H` | service | `join-with left` | **Nests.** Creates a container. |

```
MOVE left                              JOIN-WITH left

┌────┬────┬────┐                       ┌────┬────┬────┐
│ T1 │ T2 │ T3 │                       │ T1 │ T2 │ T3 │
└────┴────┴────┘                       └────┴────┴────┘
        │                                      │
        ▼                                      ▼
┌────┬────┬────┐                       ┌─────────┬──────┐
│ T1 │ T3 │ T2 │                       │         │  T2  │
└────┴────┴────┘                       │   T1    ├──────┤
                                       │         │  T3  │
still 3 flat columns                   └─────────┴──────┘
```

**`move` changes *where* a window sits. `join-with` changes *what it belongs to*.**

If you're trying to build a grid and pressing `Alt+Shift+H` without the service-mode
prefix, windows will shuffle sideways forever and you'll never get nesting.

Also: `join left` on T2 and `join right` on T1 produce the **identical** container.
Per axis there are only two moves; direction just says which neighbour to grab.

Joins only work **along the container's axis**. In a horizontal row, `up`/`down`
do nothing — AeroSpace says `No windows in the specified direction` and nothing changes.

---

## 6. Reset & escape hatches

| Keys | Effect |
|---|---|
| `Alt+B` | **Full reset** — flatten all nesting + equalise |
| `Alt+Shift+B` | Equalise only, **keeps** nesting |
| `Alt+Shift+;` → `Shift+R` | **Sort**: send every window to its home workspace (`sort-windows.sh`), then flatten + equalise all workspaces |

Don't untangle a bad tree — flatten it and rebuild. It's three keystrokes.

If panes are merely uneven, use `Alt+Shift+B`; `Alt+B` would destroy your grid.

**`Alt+B` does not reset root orientation.** On a vertical workspace you get a
flat *column*. For a full reset: `Alt+B` then `Alt+/`.

It also doesn't unfloat windows, move anything between workspaces, or close anything.

---

## 7. Floating

`Alt+Shift+Space` toggles the focused window between floating and tiled.
(Service mode `F` does the same.)

One key does both because `layout` with multiple arguments picks the first that
isn't the current state:

| Starting state | Command | Result |
|---|---|---|
| tiled | `layout floating tiling` | floating |
| floating | `layout floating tiling` | tiled |
| either | `layout floating` / `layout tiling` | forced |

Un-floating rejoins the workspace's **current** structure — it doesn't remember
where the window used to sit.

A floating window ignores tiling entirely and overlaps everything. If a layout
looks inexplicably broken, check for a stray floating window (see §9).

**Permanent floating** for apps tiling only squashes — dialogs, media players,
calculators, colour pickers:

```toml
[[on-window-detected]]
if.app-id = 'com.apple.systempreferences'
run = 'layout floating'
```

Find a bundle id with `osascript -e 'id of app "App Name"'`.

---

## 8. Opening windows where you want them

### The Spotlight problem

macOS apps are single-instance. Spotlight doesn't *create* anything for an
already-running app — it sends **activate**. macOS raises that app's existing
window, and AeroSpace follows focus to whatever workspace it lives on. You get
teleported away.

**There is no AeroSpace setting that fixes this.** It's inherent to macOS
activation. Same behaviour with Raycast and Alfred.

### Fix: ask for a new window, not an activation

`Alt+Enter` does this for Terminal:

```toml
alt-enter = '''exec-and-forget osascript -e 'tell application "Terminal" to do script ""' '''
```

`do script ""` **creates** a window instead of activating, so it appears on the
**currently focused** workspace. Deliberately no `to activate` — the new window
takes keyboard focus on its own, and `activate` is the exact call that teleports.

Same trick for other apps:

| App | Command |
|---|---|
| Safari | `tell application "Safari" to make new document` |
| Chrome / Brave / Arc | `tell application "Google Chrome" to make new window` |
| Finder | `tell application "Finder" to make new Finder window` |

For apps with no AppleScript support, `open -na "AppName"` forces a second
instance — last resort, and **not** for Safari (two instances share state badly).

### Fix: or just drag the window to you

Let Spotlight teleport you, then press `Alt+Shift+<workspace>`. That moves the
window to where you want it and follows.

Two keystrokes, works for **every** app, no config. Note the difference:
`Alt+Shift+A` **relocates your existing** window (keeps your tabs, the old
workspace loses it). The AppleScript gives you a **second, fresh** window.

---

## 9. Debugging: read the tree

When a layout confuses you, print it:

```bash
aerospace list-windows --workspace A \
  --format '%{window-id} %{app-name} parent=%{window-parent-container-layout} self=%{window-layout}'
```

```bash
# root orientation of every workspace
aerospace list-workspaces --all --format '%{workspace} root=%{workspace-root-container-layout}'
```

Reading it:

- `parent=h_tiles` on every window → flat row, **no nesting** (so: no grid)
- `parent=v_tiles` on two windows only → those two share a nested column
- `self=floating` → that window is floating and ignoring tiling

Useful format placeholders: `window-id`, `window-title`, `window-layout`,
`window-parent-container-layout`, `window-is-fullscreen`, `workspace`,
`workspace-root-container-layout`, `workspace-is-visible`, `app-name`,
`app-bundle-id`, `monitor-name`.

---

## 10. Gotchas (all verified)

**`split` does nothing.** AeroSpace itself says:

> `'split' has no effect when 'enable-normalization-flatten-containers' normalization enabled. My recommendation: keep the normalizations enabled, and prefer 'join-with' over 'split'.`

Use `join-with`. This is the most common "why is nothing happening".

**Root orientation is sticky per workspace.** It is *not* re-derived from the
monitor each time, and it survives `Alt+B`. Different workspaces on the same
monitor can differ. Don't assume — check (§9) or just press `Alt+/`.

**Nesting needs an existing sibling.** A container that ends up as root's only
child gets dissolved by flatten-normalization. Build all windows first, then join.

**Perpendicular joins are no-ops**, not errors. `No windows in the specified
direction`, nothing changes.

**`[workspace-to-monitor-force-assignment]` must stay LAST in the TOML file.**
In TOML every key after a table header belongs to that table — a setting added
below it silently becomes a workspace assignment.

**`Alt+Shift+Tab`** (`move-workspace-to-monitor`) fights the force-assignment:
it moves a workspace, then AeroSpace pulls it back. Harmless but confusing.

**Apple Terminal + "Option as Meta" leaks `Esc` — and interrupts Claude Code.**
AeroSpace hotkeys are supposed to be consumed before the focused app sees them,
but with the stock macOS Terminal focused the `Alt+…` keypress *also* reaches
the terminal (long-standing AeroSpace ↔ Apple Terminal friction, see
[nikitabobko/AeroSpace#555](https://github.com/nikitabobko/AeroSpace/issues/555)).
If the Terminal profile has **"Use Option as Meta Key"** enabled (Claude Code's
`/terminal-setup` turns it on for Option+Enter newlines), the leaked
`Alt+Shift+1` arrives as `ESC !` — and a stray `ESC` is exactly the
"interrupt the current turn" key in Claude Code (also cancels pending input in
vim, tmux, etc.). Net effect: moving a window with `Alt+Shift+<ws>` aborts
whatever Claude is doing in that terminal.

Verify it: run `cat -v`, press `Alt+Shift+1` — `^[!` appears.

Fixes, pick one:
- **Disable "Use Option as Meta Key"** for the profile (Terminal → Settings →
  Profiles → Keyboard). The leak then types a harmless `⁄`-style character
  instead of `ESC`. Costs Option+Enter-as-newline in Claude Code — type `\`
  then Enter instead. Re-running `/terminal-setup` re-enables it — remember why.
  **← applied on this machine** (fira profile, 2026-07-27).
- **Rebind AeroSpace to `ctrl-alt-…`** — Terminal never translates Ctrl chords
  into `ESC` sequences, so leaks become inert. Costs muscle memory.
- **Switch to iTerm2 / Ghostty** — they don't exhibit the leak, and support
  "Option as Esc+" per-side. Cleanest long-term, biggest change.

---

## 11. Config settings worth understanding

```toml
enable-normalization-flatten-containers = true
enable-normalization-opposite-orientation-for-nested-containers = true
```

The first dissolves pointless single-child containers (and is why `split` is a
no-op). The second is what makes grids effortless — nested containers alternate
orientation automatically. **Keep both on.**

```toml
default-root-container-orientation = 'auto'   # wide monitor → horizontal
default-root-container-layout      = 'tiles'  # tiles | accordion
accordion-padding                  = 30
```

```toml
gaps.inner.horizontal = 8    # set all gaps to 0 for edge-to-edge
```

```toml
on-focused-monitor-changed = ['move-mouse monitor-lazy-center']
focus-follows-mouse.enabled = false
```

The first warps the pointer so it never gets lost on the other screen.

```toml
persistent-workspaces = ["1","2","3","4","A","S","D","G"]
```

Keeps empty workspaces from vanishing from the menubar.

### Optional improvements

**Join in main mode.** Currently every join needs the `Alt+Shift+;` prefix and
drops back to main afterwards, so you can't chain two joins. This makes grids
half the keystrokes, and gives join its own distinct chord (`Alt+Shift` = move,
`Alt+Ctrl` = group):

```toml
    alt-ctrl-h = 'join-with left'
    alt-ctrl-j = 'join-with down'
    alt-ctrl-k = 'join-with up'
    alt-ctrl-l = 'join-with right'
```

**Pin the singleton apps** — only once you're sure, after a week of moving
windows by hand:

```toml
[[on-window-detected]]
if.app-id = 'com.tinyspeck.slackmacgap'
run = 'move-node-to-workspace 3'
```

Resist doing this for terminals and browsers. `on-window-detected` fires on
window *creation*, so "all terminals → workspace 1" means every new shell you
spawn gets yanked off your work surface. It's the rule people add on day two and
delete on day five.

### macOS-level settings

These live outside `aerospace.toml`, in `../macos/tuning.sh` (`apply` / `revert` /
`status`). The ones that matter for tiling:

| Setting | Why |
|---|---|
| **Displays have separate Spaces → OFF** | AeroSpace's top recommendation. Enabled, it causes wrong focus on multi-monitor, perf problems, and instability in the APIs AeroSpace depends on. Needs a logout. |
| **Group windows by application → ON** | `expose-group-apps`. AeroSpace parks hidden windows off-screen, which makes Mission Control render at absurd sizes. Documented workaround. |
| **Automatically rearrange Spaces → OFF** | `mru-spaces`. Stops macOS reordering Spaces under the window manager. |
| **Cmd+H / Cmd+M neutralised** | The most important one. Hide and minimise remove a window from the layout where AeroSpace can no longer tile or focus it — easy to hit by accident, confusing when you do. |

macOS gives no way to *unbind* a standard menu shortcut, so hide/minimise are
instead remapped to an unreachable chord via `NSUserKeyEquivalents`:

```
Hide · Hide All · Hide Window · Minimize · Minimize  · Minimize All · Minimize Window   →  @~^$m
Move Tab to New Window                                                                  →  @~n
```

`@`=Cmd `~`=Option `^`=Ctrl `$`=Shift. Note `Minimize ` **with a trailing space** —
not a typo. Some apps' menu item is literally that, and matching is exact, so both
spellings are needed. `tuning.sh` holds the authoritative list; don't retype it.

`Cmd+Option+N` (Move Tab to New Window) pairs well with tiling: detach a tab, then
`Alt+Shift+<workspace>` to park it beside whatever it relates to.

### Modifier choice

Keep `Alt` as the window-manager modifier. AeroSpace hotkeys are **global** — they
consume the keypress before the app sees it (exception: stock Apple Terminal
leaks the keypress through, see §10) — so binding `Cmd+…` removes that
shortcut from every app. `Cmd+Enter` is real elsewhere (Safari address bar,
Spotlight reveal-in-Finder, VS Code, most chat apps, iTerm2 fullscreen).

Cost of `Alt`: `Option+letter` normally types special characters, so
`Alt+A/S/D/G` shadows `å ß ∂ ©` and `Alt+H/J/K/L` shadows others. `Alt+Enter` is
free — `Option+Enter` produces no character.

### Reload

`auto-reload-config = true`, so saving is enough. Otherwise `Alt+Shift+;` then
`Esc`, or:

```bash
aerospace reload-config --dry-run   # validate without applying
aerospace reload-config
```

---

## 12. Daily practice

**Keep workspace purposes identical every day** for the first week. Consistency
is the whole payoff — hands learn where things live and switching stops being a
decision.

**Don't chase perfect layouts.** Two windows side by side covers most work.
Reach for a grid when you actually need four things visible at once.

**`Alt+B` liberally.** It's cheap. Flatten and rebuild beats untangling.

**Add automation last.** Move windows by hand until you *know* which apps always
belong in one place. That list is far shorter than it feels on day one.

**A useful morning shape:** external on `1` with a terminal, laptop on `A` with the
editor, and everything else a single keystroke away.
