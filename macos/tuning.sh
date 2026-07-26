#!/usr/bin/env bash
# macOS responsiveness tuning for an AeroSpace user.
#
#   ./tuning.sh apply  [tier]     tier = aerospace | balanced | aggressive  (default: balanced)
#   ./tuning.sh revert            restores the state captured before the first apply
#   ./tuning.sh status            show current values
#
# The first `apply` snapshots every key it is about to touch (value or unset)
# to $STATE_FILE; `revert` replays that snapshot, so it restores THIS machine's
# actual prior state rather than values hardcoded from some other machine.
#
# Every change here is a user-level `defaults` key. Nothing needs sudo, nothing
# touches SIP, nothing is destructive. `revert` puts it all back.
#
# CAVEAT: `defaults write` always succeeds — it just stores a key. It does NOT
# prove macOS still honours that key. Several long-circulated tweaks became inert
# in recent macOS releases, and everything here was only verified on the author's
# machine at the time of writing. Keys flagged UNVERIFIED are ones I could not
# confirm have an effect even there; all are harmless to set, any may do nothing
# on your macOS release.

set -euo pipefail
TIER="${2:-balanced}"

STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/macos-tuning.pre"

# Every key `apply` may touch, with its plist type. Single source of truth for
# the pre-apply snapshot and for revert. Format: 'domain|key|type'.
# (NSUserKeyEquivalents is handled separately by SHORTCUTS below — revert must
# delete entry-by-entry, not restore the whole dict, to spare hand-set ones.)
MANAGED_KEYS=(
  'com.apple.dock|expose-group-apps|bool'
  'com.apple.dock|mru-spaces|bool'
  'com.apple.dock|autohide-delay|float'
  'com.apple.dock|autohide-time-modifier|float'
  'com.apple.dock|no-bouncing|bool'
  'com.apple.dock|magnification|bool'
  'com.apple.dock|launchanim|bool'
  'com.apple.dock|mineffect|string'
  'com.apple.dock|show-recents|bool'
  'com.apple.dock|expose-animation-duration|float'
  'com.apple.spaces|spans-displays|bool'
  'com.apple.finder|DisableAllAnimations|bool'
  'com.apple.Accessibility|ReduceMotionEnabled|bool'
  'NSGlobalDomain|NSAutomaticWindowAnimationsEnabled|bool'
  'NSGlobalDomain|NSWindowResizeTime|float'
  'NSGlobalDomain|QLPanelAnimationDuration|float'
  'NSGlobalDomain|KeyRepeat|int'
  'NSGlobalDomain|InitialKeyRepeat|int'
  'NSGlobalDomain|ApplePressAndHoldEnabled|bool'
)

# Record the current value (or unset-ness) of every managed key, once. Runs
# before the first apply writes anything; later applies keep the original
# baseline. Format per line: 'domain|key|type|value-or-(unset)'.
snapshot_state() {
  if [ -f "$STATE_FILE" ]; then
    echo "==> pre-tuning snapshot already exists: $STATE_FILE"
    return
  fi
  echo "==> snapshotting pre-tuning state -> $STATE_FILE"
  mkdir -p "$(dirname "$STATE_FILE")"
  local spec domain key type value
  for spec in "${MANAGED_KEYS[@]}"; do
    IFS='|' read -r domain key type <<<"$spec"
    value="$(defaults read "$domain" "$key" 2>/dev/null || echo '(unset)')"
    printf '%s|%s|%s|%s\n' "$domain" "$key" "$type" "$value"
  done > "$STATE_FILE"
}

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

# ─── custom menu-item shortcuts (App Shortcuts) ───────────────────────────────
#
# Written to NSGlobalDomain rather than per-app. Two reasons:
#   1. Safari's prefs live in a TCC-protected container that Terminal cannot
#      write to without granting Full Disk Access.
#   2. A global key equivalent matches on menu-item TITLE, so one entry covers
#      every app exposing that item — which is exactly what we want here.
#
# GOTCHA: "Minimize " has a TRAILING SPACE. That is not a typo. Some apps' menu
# item is literally "Minimize " and the match is exact, so both spellings are
# listed. Retyping this list by hand is how people end up with a binding that
# silently does nothing.
#
# Format: 'Menu Item Title|KeyEquivalent'
#   @ = Cmd   ~ = Option   ^ = Ctrl   $ = Shift
#
# This array is the single source of truth for BOTH apply and revert.
# shellcheck disable=SC2016  # '$m' below is a literal Shift-glyph, not a variable
SHORTCUTS=(
  # Neutralise hide/minimise. Cmd+H and Cmd+M yank windows out of the layout
  # where AeroSpace can no longer tile or focus them — the single most annoying
  # macOS default for any tiling WM user. Remapped to an unreachable chord
  # (Cmd+Option+Ctrl+Shift+M) rather than removed, because macOS offers no way
  # to simply unbind a standard menu shortcut.
  'Hide|@~^$m'
  'Hide All|@~^$m'
  'Hide Window|@~^$m'
  'Minimize|@~^$m'
  'Minimize |@~^$m'
  'Minimize All|@~^$m'
  'Minimize Window|@~^$m'

  # Detach the current tab into its own window. Safari ships no binding for it.
  # Cmd+Option+N is free: Cmd+N = New Window, Cmd+Shift+N = New Private Window,
  # Ctrl+Cmd+N = New Empty Tab Group. Also picked up by Terminal, which has the
  # same menu item — same action, same key, which is fine.
  'Move Tab to New Window|@~n'
)

apply_shortcuts() {
  echo "==> App Shortcuts (menu-item key equivalents)"
  for entry in "${SHORTCUTS[@]}"; do
    title="${entry%%|*}"
    keys="${entry##*|}"
    defaults write -g NSUserKeyEquivalents -dict-add "$title" "$keys"
    printf "    %-24s -> %s\n" "[$title]" "$keys"
  done
  echo "    (relaunch apps for menu shortcuts to appear)"
}

revert_shortcuts() {
  echo "==> removing App Shortcuts this script manages"
  # Delete key-by-key. A blanket `defaults delete -g NSUserKeyEquivalents` would
  # also destroy any custom shortcuts you set by hand in System Settings.
  for entry in "${SHORTCUTS[@]}"; do
    title="${entry%%|*}"
    /usr/libexec/PlistBuddy -c "Delete :NSUserKeyEquivalents:'$title'" \
      ~/Library/Preferences/.GlobalPreferences.plist 2>/dev/null || true
  done
  killall cfprefsd 2>/dev/null || true
  echo "    NOTE: this restores working Cmd+H / Cmd+M, which will hide and"
  echo "    minimise windows out from under AeroSpace again."
}

restart_ui() {
  echo "==> restarting Dock / Finder / SystemUIServer"
  killall Dock 2>/dev/null || true
  killall Finder 2>/dev/null || true
  killall SystemUIServer 2>/dev/null || true
}

do_apply() {
  echo "tier: $TIER"
  snapshot_state
  apply_aerospace
  apply_shortcuts
  [[ "$TIER" == "aerospace" ]] || { apply_dock; apply_animations; apply_keyboard; }
  restart_ui
  cat <<'EOF'

Done. Notes:
  * 'Displays have separate Spaces' needs a LOGOUT to fully take effect.
  * Reduce Motion: verify in System Settings > Accessibility > Display.
  * Judge the Dock delay for a day; bump autohide-delay to 0.15 if it flickers.
EOF
}

# ─── revert to the state captured before the first apply ──────────────────────
do_revert() {
  echo "==> reverting to pre-tuning state"

  if [ -f "$STATE_FILE" ]; then
    local domain key type value
    while IFS='|' read -r domain key type value; do
      if [ "$value" = "(unset)" ]; then
        defaults delete "$domain" "$key" 2>/dev/null || true
        printf '    deleted  %s %s\n' "$domain" "$key"
      else
        # `defaults read` prints bools as 0/1; `defaults write -bool` wants words.
        if [ "$type" = "bool" ]; then
          case "$value" in 1) value=true ;; 0) value=false ;; esac
        fi
        defaults write "$domain" "$key" "-$type" "$value"
        printf '    restored %s %s = %s\n' "$domain" "$key" "$value"
      fi
    done < "$STATE_FILE"
    rm -f "$STATE_FILE"   # gone on purpose: the next apply takes a fresh baseline
  else
    echo "    NO SNAPSHOT at $STATE_FILE (apply never ran on this machine?)."
    echo "    Falling back to deleting every managed key — that restores macOS"
    echo "    *defaults*, not whatever custom values you had before."
    local spec domain key type
    for spec in "${MANAGED_KEYS[@]}"; do
      IFS='|' read -r domain key type <<<"$spec"
      defaults delete "$domain" "$key" 2>/dev/null || true
    done
  fi

  revert_shortcuts
  restart_ui
  echo "Reverted."
}

do_status() {
  echo "=== Dock ==="
  for k in autohide autohide-delay autohide-time-modifier mineffect launchanim \
           magnification no-bouncing expose-animation-duration expose-group-apps \
           mru-spaces show-recents tilesize; do
    printf "  %-28s %s\n" "$k" "$(defaults read com.apple.dock "$k" 2>/dev/null || echo '(unset)')"
  done
  echo "=== Global ==="
  for k in NSAutomaticWindowAnimationsEnabled NSWindowResizeTime QLPanelAnimationDuration \
           KeyRepeat InitialKeyRepeat ApplePressAndHoldEnabled; do
    printf "  %-36s %s\n" "$k" "$(defaults read -g "$k" 2>/dev/null || echo '(unset)')"
  done
  echo "=== App Shortcuts (NSUserKeyEquivalents) ==="
  /usr/libexec/PlistBuddy -c 'Print :NSUserKeyEquivalents' \
    ~/Library/Preferences/.GlobalPreferences.plist 2>/dev/null \
    | sed -n 's/^ *\([^=]*\) = \(.*\)/  [\1] -> \2/p' || echo "  (none set)"
  echo "=== Spaces / Accessibility ==="
  printf "  %-28s %s\n" "spans-displays" "$(defaults read com.apple.spaces spans-displays 2>/dev/null || echo '(unset)')"
  printf "  %-28s %s\n" "ReduceMotionEnabled" "$(defaults read com.apple.Accessibility ReduceMotionEnabled 2>/dev/null || echo '(unset)')"
  printf "  %-28s %s\n" "reduceTransparency" "$(defaults read com.apple.universalaccess reduceTransparency 2>/dev/null || echo '(unset)')"
  echo "=== Snapshot ==="
  if [ -f "$STATE_FILE" ]; then
    printf "  pre-tuning snapshot: %s\n" "$STATE_FILE"
  else
    echo "  pre-tuning snapshot: (none — apply has not run yet)"
  fi
}

case "${1:-}" in
  apply)  do_apply ;;
  revert) do_revert ;;
  status) do_status ;;
  *) echo "usage: $0 {apply [aerospace|balanced|aggressive] | revert | status}"; exit 1 ;;
esac
