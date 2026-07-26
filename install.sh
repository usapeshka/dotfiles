#!/usr/bin/env bash
#
# Bootstrap this machine from the dotfiles repo.
#
#   git clone <repo> ~/dotfiles && ~/dotfiles/install.sh [tier]
#
# tier is passed through to macos/tuning.sh (aerospace|balanced|aggressive).
# Idempotent — safe to re-run any time, e.g. after pulling changes.
#
# Only aerospace/ needs symlinking: AeroSpace requires its config at a fixed
# path. macos/tuning.sh is *executed*, and cheatsheet.md is just read, so
# neither needs to appear anywhere else on disk.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIER="${1:-aggressive}"

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

echo "==> symlinks"
link "$DOTFILES/aerospace" "$HOME/.config/aerospace"

echo "==> macOS settings (tier: $TIER)"
"$DOTFILES/macos/tuning.sh" apply "$TIER"

cat <<'EOF'

==> Manual steps that cannot be scripted from a repo

  1. Install AeroSpace, if it isn't already:
       https://github.com/nikitabobko/AeroSpace   (or: brew install --cask nikitabobko/tap/aerospace)

  2. Grant AeroSpace Accessibility permission:
       System Settings > Privacy & Security > Accessibility
     Per-machine TCC consent — no way around doing this by hand.

  3. Enable Reduce Motion:
       System Settings > Accessibility > Display > Reduce motion
     tuning.sh attempts it, but the key is TCC-protected and may not stick.

  4. Log out and back in.
     'Displays have separate Spaces' only fully applies after a session restart.

  5. Arrange displays to match physical layout:
       System Settings > Displays > Arrange...
     This machine's config assumes the external monitor sits ABOVE the laptop.
     Workspaces 1-4 pin to built-in, A/S/D/G to the external.

Then: aerospace reload-config
EOF
