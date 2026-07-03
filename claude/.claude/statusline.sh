#!/usr/bin/env bash
# Claude Code status line — Tokyo Night capsules, matching tmux/nvim.
set -u

input=$(cat)

IFS=$'\t' read -r model dir cost added removed <<EOF
$(printf '%s' "$input" | jq -r '[
  (.model.display_name // "Claude"),
  (.workspace.current_dir // .cwd // ""),
  (.cost.total_cost_usd // 0),
  (.cost.total_lines_added // 0),
  (.cost.total_lines_removed // 0)
] | @tsv')
EOF

# Tokyo Night
BLUE="122;162;247"      # #7aa2f7 (accents)
BLUE_BG="61;89;161"     # #3d59a1 (model capsule)
INK="26;27;38"       # #1a1b26
DARK="31;35;53"      # #1f2335
FG="192;202;245"     # #c0caf5
GREEN="158;206;106"  # #9ece6a
RED="247;118;142"    # #f7768e
YELLOW="224;175;104" # #e0af68

# capsule <bg> <body...>  →  rounded pill like the tmux status bar
# (\356\202\266 / \356\202\264 are the U+E0B6 / U+E0B4 half-circle caps)
capsule() {
  local bg="$1"
  shift
  printf '\033[38;2;%sm\356\202\266\033[48;2;%sm%b\033[0m\033[38;2;%sm\356\202\264\033[0m' "$bg" "$bg" "$*" "$bg"
}

fg() { printf '\033[38;2;%sm' "$1"; }

# ── model ────────────────────────────────────────────────────────────
out="$(capsule "$BLUE_BG" "$(fg "$FG")\033[1m✳ ${model}")"

# ── directory ────────────────────────────────────────────────────────
short_dir="${dir/#$HOME/\~}"
short_dir="${short_dir##*/}"
[ -z "$short_dir" ] && short_dir="~"
out="$out $(capsule "$DARK" "$(fg "$BLUE")󰉋 $(fg "$FG")${short_dir}")"

# ── git branch ───────────────────────────────────────────────────────
branch=$(git -C "$dir" branch --show-current 2>/dev/null)
if [ -n "$branch" ]; then
  dirty=""
  [ -n "$(git -C "$dir" status --porcelain 2>/dev/null | head -c1)" ] && dirty=" $(fg "$YELLOW")●"
  out="$out $(capsule "$DARK" "$(fg "$BLUE") $(fg "$FG")${branch}${dirty}")"
fi

# ── session: lines changed + cost ────────────────────────────────────
session=""
if [ "$added" != "0" ] || [ "$removed" != "0" ]; then
  session="$(fg "$GREEN")+${added} $(fg "$RED")-${removed}"
fi
cost_fmt=$(printf '$%.2f' "$cost" 2>/dev/null || echo '$0.00')
[ "$cost_fmt" != '$0.00' ] && session="${session:+$session }$(fg "$YELLOW")${cost_fmt}"
[ -n "$session" ] && out="$out $(capsule "$DARK" "$session")"

printf '%b' "$out"
