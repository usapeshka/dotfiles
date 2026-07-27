#!/bin/bash
# Sort every window to its home workspace by app type, then flatten + balance
# each workspace. Bound to service-mode shift-r in aerospace.toml.
#
# Which MONITOR each workspace shows on is decided by the config's
# [workspace-to-monitor-force-assignment] — this script only assigns
# windows to workspaces:
#   1 Terminal   2 Finder/files   3 chat   4 music/utilities
#   A IDE        S browser/docs   D DB/API tools   G scratch
set -uo pipefail

aerospace list-windows --all --format '%{window-id}|%{app-name}' |
while IFS='|' read -r id app; do
    case "$app" in
        'Cursor' | 'Code' | 'Visual Studio Code')     ws='A' ;;
        'Google Chrome' | 'Safari' | 'Arc' | 'Firefox') ws='S' ;;
        'Terminal' | 'iTerm2' | 'Ghostty')            ws='1' ;;
        'Finder')                                     ws='2' ;;
        'Slack' | 'Messages' | 'Mail')                ws='3' ;;
        'Music' | 'OpenVPN Connect')                  ws='4' ;;
        'TablePlus' | 'Postico' | 'Postman' | 'Insomnia') ws='D' ;;
        *) continue ;;  # unknown apps stay where they are
    esac
    aerospace move-node-to-workspace --window-id "$id" "$ws"
done

# Same cleanup service-mode `r` does, but for every workspace.
for ws in 1 2 3 4 A S D G; do
    aerospace flatten-workspace-tree --workspace "$ws"
    aerospace balance-sizes --workspace "$ws"
done
