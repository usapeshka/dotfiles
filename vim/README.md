# Vim: stack notes

What this setup is made of, why each piece is there, and the mapping reference.
Config is [`vimrc`](vimrc), symlinked to `~/.vimrc` by `../install.sh`.

---

## The stack

| Layer | What | Why |
|---|---|---|
| vim 9.0 | macOS system vim (`/usr/bin/vim`) | No install needed; everything here works on stock vim |
| [vim-plug](https://github.com/junegunn/vim-plug) | Plugin manager — one file at `~/.vim/autoload/plug.vim` | Minimal, no runtime cost; `install.sh` bootstraps it |
| [vim-sensible](https://github.com/tpope/vim-sensible) | Consensus default settings | Covers `wildmenu`, `incsearch`, `autoread`, sane `scrolloff` floor, etc. — so the vimrc only states *opinions*, not table stakes |
| [fzf](https://github.com/junegunn/fzf) + [fzf.vim](https://github.com/junegunn/fzf.vim) | Fuzzy finder + vim commands on top | File navigation; the binary comes from Homebrew, the plugin just wires it in |
| `colors/atom-dark-256` | Colorscheme (a CSApprox 256-color snapshot of atom-dark) | Not on any plugin registry in this form — vendored in `colors/`, symlinked to `~/.vim/colors` |

### What lives where

```
~/dotfiles/vim/vimrc    ← the config (repo)          → symlinked to ~/.vimrc
~/dotfiles/vim/colors/  ← vendored colorschemes      → symlinked to ~/.vim/colors
~/.vim/autoload/plug.vim   machine-local, bootstrapped by install.sh
~/.vim/plugged/            machine-local, populated by :PlugInstall
~/.vim/undo/               machine-local, created by vimrc (persistent undo)
```

The rule: the repo holds what I wrote or chose; `~/.vim` holds what tools
download or generate. Nothing under `~/.vim` is tracked.

## Fresh machine

```bash
~/dotfiles/install.sh   # symlinks + vim-plug bootstrap
vim +PlugInstall +qall  # fetch plugins
```

`fzf` itself: `brew install fzf` (the plugin's `do` hook can also install it).

## Plugin management

```vim
:PlugInstall   " install everything in the plug#begin block
:PlugUpdate    " update plugins
:PlugClean     " remove plugins deleted from the vimrc
:PlugStatus    " what's installed vs declared
```

Adding a plugin = one `Plug '...'` line between `plug#begin`/`plug#end`,
save (auto-sources), `:PlugInstall`.

---

## Mappings

Leader is `,`.

### Files & navigation

| Keys | Action |
|---|---|
| `Ctrl+P` | fzf over **git-tracked** files (`:GFiles`) — the daily driver |
| `,pf` | fzf over **all** files (`:Files`) — when it's not in git yet |
| `,pv` | netrw file tree in a vertical split (`:Vex`) |
| `,ct` | close current tab |
| `Ctrl+H/J/K/L` | move between splits (matches AeroSpace's `Alt+H/J/K/L` muscle memory) |

### Editing

| Keys | Action |
|---|---|
| `J` / `K` (visual) | move selection down/up, reindenting |
| `,p` (visual) | paste over selection **without** losing the yanked text |
| `,pp` | run current file with python — command line stays open for args |
| `,<space>` | clear search highlight |

### Config quick-edits (open in a new tab)

| Keys | File |
|---|---|
| `,ev` | this vimrc |
| `,ae` | `aerospace.toml` |
| `,tu` | `macos/tuning.sh` |
| `,zs` | `~/.zshrc` |
| `,rr` / `,rc` | ranger `rc.conf` / `commands.py` |
| `,<CR>` | re-source the vimrc (also happens automatically on save) |

---

## Notes & gotchas

**Trailing whitespace in mappings is live code.** A mapping line ending in a
space executes that space as a keystroke. `,p` was silently moving the cursor
right after pasting for exactly this reason. If a mapping misbehaves,
`:verbose nmap <keys>` shows what's actually bound and where it came from.

**`silent!` on the colorscheme** is deliberate: on a machine where the
symlinks aren't in place yet, vim starts with default colors instead of an
error screen.

**Option names are case-sensitive.** `set t_Co=256` works; `set t_CO=256`
(which this config carried for years) is a silent no-op. Modern terminals
don't need either.

**vim-sensible interactions:** it already sets `backspace`, `incsearch`,
`wildmenu`, `autoread`. It also maps `Ctrl+L` to clear-highlight-and-redraw —
our split navigation shadows that on purpose; `,<space>` fills the gap.

**Hybrid line numbers** (`number` + `relativenumber`): the cursor line shows
its absolute number, everything else is relative — count is right there for
`5j` / `3k` jumps.
