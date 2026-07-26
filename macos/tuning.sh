#!/usr/bin/env bash
# macOS responsiveness tuning — MacBook Air M5, macOS 26.5.2, AeroSpace user.
#
#   ./tuning.sh apply  [tier]     tier = aerospace | balanced | aggressive  (default: balanced)
#   ./tuning.sh revert            restores the state observed before first run
#   ./tuning.sh status            show current values
#
# Every change here is a user-level `defaults` key. Nothing needs sudo, nothing
# touches SIP, nothing is destructive. `revert` puts it all back.
#
# CAVEAT: `defaults write` always succeeds — it just stores a key. It does NOT
# prove macOS still honours that key. Several long-circulated tweaks became inert
# in recent macOS releases. Keys flagged UNVERIFIED below are ones I could not
# confirm still have an effect on macOS 26; harmless to set, may do nothing.

set -euo pipefail
TIER="${2:-balanced}"

# ─── things AeroSpace itself recommends ───────────────────────────────────────
apply_aerospace() {
  echo "==> AeroSpace-recommended macOS settings"

  # Mission Control gets confused because AeroSpace parks hidden windows in the
  # screen corner. Grouping by app is the documented workaround.
  defaults write com.apple.dock expose-group-apps -bool true

  # 'Displays have separate Spaces' must be OFF (spans-displays = true).
  # AeroSpace: wrong focus on multi-monitor, perf problems, API instability.
  # Already correct on this machine — asserted here for reproducibility.
  defaults write com.apple.spaces spans-displays -bool true

  # Don't let macOS reorder Spaces underneath the window manager.
  defaults write com.apple.dock mru-spaces -bool false
}

# ─── Dock: the single biggest perceived-latency win ───────────────────────────
apply_dock() {
  echo "==> Dock"

  case "$TIER" in
    aggressive)
      defaults write com.apple.dock autohide-delay -float 0      # no hover pause
      defaults write com.apple.dock autohide-time-modifier -float 0
      ;;
    *)
      defaults write com.apple.dock autohide-delay -float 0.1    # avoids edge flicker
      defaults write com.apple.dock autohide-time-modifier -float 0.15
      ;;
  esac

  defaults write com.apple.dock no-bouncing -bool true       # no attention bouncing
  defaults write com.apple.dock magnification -bool false    # hover zoom = animation
  defaults write com.apple.dock launchanim -bool false       # already off here
  defaults write com.apple.dock mineffect -string scale      # scale > genie
  defaults write com.apple.dock show-recents -bool false
  defaults write com.apple.dock expose-animation-duration -float 0.1   # Mission Control
}

# ─── System-wide animation removal ────────────────────────────────────────────
apply_animations() {
  echo "==> Window & system animations"

  defaults write -g NSAutomaticWindowAnimationsEnabled -bool false  # open/close
  defaults write -g NSWindowResizeTime -float 0.001                 # UNVERIFIED
  defaults write -g QLPanelAnimationDuration -float 0               # Quick Look
  defaults write com.apple.finder DisableAllAnimations -bool true

  # Reduce Motion is the real system-level switch. It is TCC-protected, so this
  # write may not stick — set it in System Settings > Accessibility > Display.
  defaults write com.apple.Accessibility ReduceMotionEnabled -bool true 2>/dev/null || true
}

# ─── Keyboard: only in aggressive ─────────────────────────────────────────────
apply_keyboard() {
  [[ "$TIER" == "aggressive" ]] || return 0
  echo "==> Keyboard repeat (aggressive only)"

  defaults write -g KeyRepeat -int 1          # was 2
  defaults write -g InitialKeyRepeat -int 10  # was 15

  # TRADE-OFF: makes holding a key repeat it instead of opening the accent
  # picker. Good for vim-style nav; you lose press-and-hold accented characters.
  # Note AeroSpace already consumes Option+letter, so press-and-hold is your
  # remaining route to é/ü/etc. Skip this line if you type accents.
  defaults write -g ApplePressAndHoldEnabled -bool false
}

restart_ui() {
  echo "==> restarting Dock / Finder / SystemUIServer"
  killall Dock 2>/dev/null || true
  killall Finder 2>/dev/null || true
  killall SystemUIServer 2>/dev/null || true
}

do_apply() {
  echo "tier: $TIER"
  apply_aerospace
  [[ "$TIER" == "aerospace" ]] || { apply_dock; apply_animations; apply_keyboard; }
  restart_ui
  cat <<'EOF'

Done. Notes:
  * 'Displays have separate Spaces' needs a LOGOUT to fully take effect.
  * Reduce Motion: verify in System Settings > Accessibility > Display.
  * Judge the Dock delay for a day; bump autohide-delay to 0.15 if it flickers.
EOF
}

# ─── revert to the state observed before any of this was applied ──────────────
do_revert() {
  echo "==> reverting to pre-tuning state"

  # These were UNSET originally -> delete them.
  for k in autohide-delay autohide-time-modifier no-bouncing \
           expose-animation-duration expose-group-apps; do
    defaults delete com.apple.dock "$k" 2>/dev/null || true
  done
  for k in NSAutomaticWindowAnimationsEnabled NSWindowResizeTime \
           QLPanelAnimationDuration ApplePressAndHoldEnabled; do
    defaults delete -g "$k" 2>/dev/null || true
  done
  defaults delete com.apple.finder DisableAllAnimations 2>/dev/null || true
  defaults delete com.apple.Accessibility ReduceMotionEnabled 2>/dev/null || true

  # These HAD values before -> restore them, don't delete.
  defaults write com.apple.dock magnification -bool true   # was 1
  defaults write -g KeyRepeat -int 2                       # was 2
  defaults write -g InitialKeyRepeat -int 15               # was 15

  restart_ui
  echo "Reverted. spans-displays / mru-spaces / launchanim left as-is (already yours)."
}

do_status() {
  echo "=== Dock ==="
  for k in autohide autohide-delay autohide-time-modifier mineffect launchanim \
           magnification no-bouncing expose-animation-duration expose-group-apps \
           mru-spaces show-recents tilesize; do
    printf "  %-28s %s\n" "$k" "$(defaults read com.apple.dock $k 2>/dev/null || echo '(unset)')"
  done
  echo "=== Global ==="
  for k in NSAutomaticWindowAnimationsEnabled NSWindowResizeTime QLPanelAnimationDuration \
           KeyRepeat InitialKeyRepeat ApplePressAndHoldEnabled; do
    printf "  %-36s %s\n" "$k" "$(defaults read -g $k 2>/dev/null || echo '(unset)')"
  done
  echo "=== Spaces / Accessibility ==="
  printf "  %-28s %s\n" "spans-displays" "$(defaults read com.apple.spaces spans-displays 2>/dev/null || echo '(unset)')"
  printf "  %-28s %s\n" "ReduceMotionEnabled" "$(defaults read com.apple.Accessibility ReduceMotionEnabled 2>/dev/null || echo '(unset)')"
  printf "  %-28s %s\n" "reduceTransparency" "$(defaults read com.apple.universalaccess reduceTransparency 2>/dev/null || echo '(unset)')"
}

case "${1:-}" in
  apply)  do_apply ;;
  revert) do_revert ;;
  status) do_status ;;
  *) echo "usage: $0 {apply [aerospace|balanced|aggressive] | revert | status}"; exit 1 ;;
esac
