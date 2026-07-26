# dotfiles

macOS setup for an [AeroSpace](https://github.com/nikitabobko/AeroSpace) tiling-WM
workflow: the window-manager config, the macOS settings that make tiling pleasant,
and the docs I actually reach for.

## Quick start

```bash
git clone https://github.com/usapeshka/dotfiles ~/dotfiles && ~/dotfiles/install.sh
```

Idempotent — re-run any time, e.g. after pulling changes. It will:

1. Install AeroSpace via Homebrew if it isn't already.
2. Symlink `~/.config/aerospace` → `~/dotfiles/aerospace`, `~/.vimrc` → `~/dotfiles/vim/vimrc`,
   and `~/.vim/colors` → `~/dotfiles/vim/colors` (backing up anything in the way).
3. Bootstrap vim-plug if missing (plugins themselves: `vim +PlugInstall +qall`).
4. Validate `aerospace.toml` if AeroSpace is running.
5. Apply macOS settings via `macos/tuning.sh`.

A short list of steps that can't be scripted (Accessibility consent, a logout)
is printed at the end.

## Layout

| Path | What |
|---|---|
| [`aerospace/aerospace.toml`](aerospace/aerospace.toml) | AeroSpace config — i3-style, workspaces 1–4 on the laptop, A/S/D/G on the external |
| [`aerospace/README.md`](aerospace/README.md) | Deep guide: the tiling mental model, recipes, gotchas — all verified |
| [`macos/tuning.sh`](macos/tuning.sh) | macOS responsiveness tuning: `apply [tier]` / `revert` / `status` |
| [`vim/vimrc`](vim/vimrc) | Vim config — vim-plug, vim-sensible, fzf, atom-dark |
| [`vim/README.md`](vim/README.md) | Stack notes: what each piece is for, mappings, gotchas |
| [`zsh/functions.zsh`](zsh/functions.zsh) | Portable shell functions (`tz`, `yt`, `m3u`) — sourced from `~/.zshrc` |
| [`cheatsheet.md`](cheatsheet.md) | Personal quick reference for commands I look up more than once |
| [`install.sh`](install.sh) | Bootstrap, see above |

## Tuning tiers

`tuning.sh apply` takes a tier: `aerospace` (only what AeroSpace itself
recommends), `balanced` (the default — animations off, sane Dock), or
`aggressive` (adds instant Dock and fast key repeat; costs you press-and-hold
accented characters).

The first `apply` snapshots every setting it is about to touch, so
`tuning.sh revert` restores *this machine's* actual prior state — not
someone else's defaults.

## Non-goals

The repo deliberately does **not** manage `~/.config` wholesale, `~/.zshrc`
itself, or anything credential-adjacent — see the comment in
[`.gitignore`](.gitignore). Portable shell functions are extracted into
`zsh/functions.zsh` and pulled in with one `source` line; the rc file with
its work aliases and machine paths stays private. A few symlinks, no
stow/chezmoi.
