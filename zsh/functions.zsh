# Generic shell functions — sourced from ~/.zshrc (install.sh adds the line).
#
# Only portable, personal utilities live here. Work aliases, machine paths,
# and anything credential-adjacent stay in ~/.zshrc, which is NOT in the repo
# — see the .gitignore comment for why.

# tz — the time everywhere I care about, plus epoch for logs/tickets.
tz() {
  echo "Epoch: $(date -u +%s)"
  TZ=America/Chicago date "+CHI %Y-%m-%d %H:%M %Z"
  TZ=America/New_York date "+NYC %Y-%m-%d %H:%M %Z"
  TZ=Europe/Minsk date "+MSK %Y-%m-%d %H:%M %Z"
}

# yt — download a YouTube video into ~/Videos/youtube/<today>/.
#
# Cookies come from Safari so age-/member-gated videos work; reading them
# needs Terminal to have Full Disk Access (System Settings > Privacy).
# On a machine without Safari cookies, pass --cookies-from-browser chrome
# (extra args go straight through to yt-dlp).
#
# Requires: brew install yt-dlp
yt() {
  if [[ -z "$1" ]]; then
    echo "Usage: yt <youtube-url> [extra yt-dlp args...]"
    return 1
  fi
  if ! command -v yt-dlp >/dev/null; then
    echo "yt: yt-dlp not installed (brew install yt-dlp)" >&2
    return 127
  fi

  local today outdir
  today=$(date +%Y-%m-%d)
  outdir="$HOME/Videos/youtube/$today"
  mkdir -p "$outdir"

  yt-dlp \
    --cookies-from-browser safari \
    -f "bv*+ba/b" \
    --merge-output-format mp4 \
    -o "$outdir/%(title)s.%(ext)s" \
    "$@"
}

# m3u — build a playlist of every audio/video file under the current
# directory, sorted, with paths relative to here. Name defaults to the
# directory's own name.
#
# `file -b` (brief) is load-bearing: without -b the output is "path: type"
# and a file living under a directory called audio/ or video/ would match
# on its *path*, whatever its actual type.
m3u() {
  local name="$1"

  if [ -z "$name" ]; then
    name="$(basename "$PWD")"
  fi

  [[ "$name" != *.m3u ]] && name="$name.m3u"

  find . -type f -print0 \
  | while IFS= read -r -d '' f; do
      if file -b --mime-type "$f" | grep -qE '^(audio|video)/'; then
        printf '%s\n' "$f"
      fi
    done \
  | sort \
  | sed 's|^\./||' \
  > "$name"
}
