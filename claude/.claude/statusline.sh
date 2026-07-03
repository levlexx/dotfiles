#!/usr/bin/env bash
# Claude Code status line — Tokyo Night capsules, matching tmux/nvim.
set -u

input=$(cat)

IFS=$'\t' read -r model effort cost added removed ctx_tokens ctx_pct rl_pct rl_reset <<EOF
$(printf '%s' "$input" | jq -r '[
  (.model.display_name // "Claude"),
  (.effort.level // "-"),
  (.cost.total_cost_usd // 0),
  (.cost.total_lines_added // 0),
  (.cost.total_lines_removed // 0),
  (.context_window.total_input_tokens // 0),
  (.context_window.used_percentage // 0),
  (.rate_limits.five_hour.used_percentage // ""),
  (.rate_limits.five_hour.resets_at // "")
] | @tsv')
EOF

# Tokyo Night
CYAN="125;207;255"      # #7dcfff
BLUE="122;162;247"      # #7aa2f7 (accents / icon color)
BLUE_BG="122;162;247"   # #7aa2f7 (model pill bg)
MODEL_FG="22;22;30"     # #16161e (bold text on bright model pill)
DARK="41;46;66"         # #292e42 (dark pill bg)
FG="192;202;245"        # #c0caf5
MUTED="169;177;214"     # #a9b1d6 (lines/cost default fg)
GREEN="158;206;106"     # #9ece6a
RED="247;118;142"       # #f7768e
YELLOW="224;175;104"    # #e0af68

# capsule <bg> <body...>  →  rounded pill like the tmux status bar
# (\356\202\266 / \356\202\264 are the U+E0B6 / U+E0B4 half-circle caps)
capsule() {
  local bg="$1"
  shift
  printf '\033[38;2;%sm\356\202\266\033[48;2;%sm%b\033[0m\033[38;2;%sm\356\202\264\033[0m' "$bg" "$bg" "$*" "$bg"
}

fg() { printf '\033[38;2;%sm' "$1"; }

# green under 70%, yellow under 90%, red above
pct_color() {
  if [ "${1:-0}" -ge 90 ]; then
    printf '%s' "$RED"
  elif [ "${1:-0}" -ge 70 ]; then
    printf '%s' "$YELLOW"
  else
    printf '%s' "$GREEN"
  fi
}

# 280433 → 280k, 1234567 → 1.2M
humanize() {
  awk -v n="$1" 'BEGIN {
    if (n >= 1000000) printf "%.1fM", n / 1000000
    else if (n >= 1000) printf "%dk", n / 1000
    else printf "%d", n
  }'
}

# ── model + effort ───────────────────────────────────────────────────
model_body="$(fg "$MODEL_FG")\033[1m✳ ${model}"
[ "$effort" != "-" ] && model_body="$model_body\033[22m $(fg "$MODEL_FG")${effort}"
out="$(capsule "$BLUE_BG" "$model_body")"

# ── context tokens used ──────────────────────────────────────────────
if [ "$ctx_tokens" != "0" ]; then
  out="$out $(capsule "$DARK" "$(fg "$BLUE")󰊠 $(fg "$FG")$(humanize "$ctx_tokens") $(fg "$(pct_color "$ctx_pct")")${ctx_pct}%")"
fi

# ── 5h session window: used % + reset time ───────────────────────────
if [ -n "$rl_reset" ]; then
  reset_time=$(date -r "$rl_reset" +%H:%M 2>/dev/null || echo "?")
  out="$out $(capsule "$DARK" "$(fg "$BLUE")󰥔 $(fg "$(pct_color "$rl_pct")")${rl_pct}% $(fg "$CYAN")↻ ${reset_time}")"
fi

# ── session: lines changed + cost ────────────────────────────────────
session=""
if [ "$added" != "0" ] || [ "$removed" != "0" ]; then
  session="$(fg "$GREEN")+${added} $(fg "$RED")-${removed}"
fi
cost_fmt=$(printf '$%.2f' "$cost" 2>/dev/null || echo '$0.00')
[ "$cost_fmt" != '$0.00' ] && session="${session:+$session }$(fg "$MUTED")${cost_fmt}"
[ -n "$session" ] && out="$out $(capsule "$DARK" "$session")"

printf '%b' "$out"
