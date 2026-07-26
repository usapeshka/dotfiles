#!/usr/bin/env bash
#
# Bootstrap this machine from the dotfiles repo.
#
#   git clone <repo> ~/dotfiles && ~/dotfiles/install.sh [tier]
#
# tier is passed through to macos/tuning.sh (aerospace|balanced|aggressive).
# Omitted -> tuning.sh's own default applies; that script is the single source
# of truth for the default, so the two can't drift apart.
# Idempotent — safe to re-run any time, e.g. after pulling changes.
#
# Only aerospace/ needs symlinking: AeroSpace requires its config at a fixed
# path. macos/tuning.sh is *executed*, and cheatsheet.md is just read, so
# neither needs to appear anywhere else on disk.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIER="${1:-}"   # empty = let tuning.sh apply its own default

link() {
  local src="$1" dest="$2"

  # Already correct? Nothing to do.
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "  ok        $dest"
    return
  fi

  # A real file/dir is in the way — move it aside rather than destroy it.
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    local backup="$dest.backup.$$"
    mv "$dest" "$backup"
    echo "  BACKED UP $dest -> $backup"
  fi

  mkdir -p "$(dirname "$dest")"
  ln -sfn "$src" "$dest"
  echo "  linked    $dest -> $src"
}

echo "==> AeroSpace"
if command -v aerospace >/dev/null 2>&1; then
  echo "  ok        already installed ($(command -v aerospace))"
elif command -v brew >/dev/null 2>&1; then
  brew install --cask nikitabobko/tap/aerospace
else
  echo "  SKIPPED   no Homebrew found — install by hand:"
  echo "            https://github.com/nikitabobko/AeroSpace"
fi

echo "==> symlinks"
link "$DOTFILES/aerospace" "$HOME/.config/aerospace"
link "$DOTFILES/vim/vimrc" "$HOME/.vimrc"
link "$DOTFILES/vim/colors" "$HOME/.vim/colors"

# ~/.zshrc itself stays out of the repo (work aliases, machine paths — see
# .gitignore's comment), so the shell functions are wired in with a single
# source line instead of a symlink. Idempotent: appended once, ever.
echo "==> zsh functions"
if [ -f "$HOME/.zshrc" ] && grep -qF 'dotfiles/zsh/functions.zsh' "$HOME/.zshrc"; then
  echo "  ok        already sourced from ~/.zshrc"
else
  printf '\n# generic shell functions from the dotfiles repo (added by install.sh)\nsource ~/dotfiles/zsh/functions.zsh\n' >> "$HOME/.zshrc"
  echo "  added     source line to ~/.zshrc"
fi

# vim-plug is a single autoload file; plugins themselves stay machine-local
# (~/.vim/plugged) and are fetched inside vim with :PlugInstall.
echo "==> vim-plug"
if [ -f "$HOME/.vim/autoload/plug.vim" ]; then
  echo "  ok        already installed"
else
  curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  echo "  installed — run 'vim +PlugInstall +qall' to fetch plugins"
fi

# Catch config typos at install time, not at the next reload. --dry-run needs
# the AeroSpace server, so this only runs when the app is already up; on a
# fresh machine the first launch validates instead.
echo "==> validate aerospace config"
if command -v aerospace >/dev/null 2>&1 && pgrep -xq AeroSpace; then
  if aerospace reload-config --dry-run; then
    echo "  ok        config valid"
  else
    echo "  WARNING   config failed validation — fix it before 'aerospace reload-config'"
  fi
else
  echo "  skipped   AeroSpace not running"
fi

echo "==> macOS settings (tier: ${TIER:-tuning.sh default})"
"$DOTFILES/macos/tuning.sh" apply ${TIER:+"$TIER"}

cat <<'EOF'

==> Manual steps that cannot be scripted from a repo

  1. Grant AeroSpace Accessibility permission:
       System Settings > Privacy & Security > Accessibility
     Per-machine TCC consent — no way around doing this by hand.

  2. Enable Reduce Motion:
       System Settings > Accessibility > Display > Reduce motion
     tuning.sh attempts it, but the key is TCC-protected and may not stick.

  3. Log out and back in.
     'Displays have separate Spaces' only fully applies after a session restart.

  4. Arrange displays to match physical layout:
       System Settings > Displays > Arrange...
     This machine's config assumes the external monitor sits ABOVE the laptop.
     Workspaces 1-4 pin to built-in, A/S/D/G to the external.

Then: open -a AeroSpace && aerospace reload-config
EOF
