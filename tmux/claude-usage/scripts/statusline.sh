#!/usr/bin/env bash
#
# Claude Code statusLine command. Three jobs per render:
#   1. feed the usage harvester (rate limits -> tmux usage capsule)
#   2. stamp the model and Claude Code version on the tmux window
#      (@claude_model / @claude_version), shown in that capsule
#   3. print a Tokyo Night capsule row above Claude's footer badges:
#      model · effort | context bar | branch / worktree / PR | +/- lines | time

set -uo pipefail
export LC_ALL=C

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
input="$(cat)"

# Hooks and status lines may run with a GUI-ish PATH.
find_bin() {
	local d
	command -v "$1" 2>/dev/null && return 0
	for d in /opt/homebrew/bin /usr/local/bin /usr/bin /bin; do
		[ -x "$d/$1" ] && { printf '%s' "$d/$1"; return 0; }
	done
	return 1
}
JQ="$(find_bin jq)" || exit 0

printf '%s' "$input" | "$DIR/harvester.sh"

# \x1f, not tab: bash collapses runs of tab IFS, dropping empty fields
IFS=$'\x1f' read -r model version effort fast ctx cwd worktree pr_num pr_state added removed dur_ms <<EOF
$(printf '%s' "$input" | "$JQ" -r '[
	(.model.display_name // "Claude"),
	(.version // ""),
	(.effort.level // ""),
	(.fast_mode // false),
	((.context_window.used_percentage // 0) | floor),
	(.workspace.current_dir // .cwd // ""),
	(.worktree.name // .workspace.git_worktree // ""),
	(.pr.number // ""),
	(.pr.review_state // ""),
	(.cost.total_lines_added // 0),
	(.cost.total_lines_removed // 0),
	(.cost.total_duration_ms // 0)
] | map(tostring) | join("\u001f")' 2>/dev/null)
EOF

if [ -n "${TMUX_PANE:-}" ] && TMUX_BIN="$(find_bin tmux)"; then
	"$TMUX_BIN" set -w -t "$TMUX_PANE" @claude_model "$model" \; \
		set -w -t "$TMUX_PANE" @claude_version "$version" 2>/dev/null
fi

# Tokyo Night, as "r;g;b"
BG="26;27;38"      # #1a1b26
SURFACE="41;46;66" # #292e42
FG="192;202;245"   # #c0caf5
DIM="86;95;137"    # #565f89
BLUE="122;162;247" # #7aa2f7
CYAN="125;207;255" # #7dcfff
GREEN="158;206;106"
YELLOW="224;175;104"
ORANGE="255;158;100"
RED="247;118;142"
PURPLE="187;154;247"

L=$'\xee\x82\xb6' # U+E0B6 rounded cap, left
R=$'\xee\x82\xb4' # U+E0B4 rounded cap, right
RESET=$'\033[0m'
fg() { printf '\033[38;2;%sm' "$1"; }
bg() { printf '\033[48;2;%sm' "$1"; }

# capsule <bg> <content-with-colors>
capsule() {
	printf '%s%s%s%s %s %s%s%s ' "$RESET" "$(fg "$1")" "$L" "$(bg "$1")" "$2" "$RESET$(fg "$1")" "$R" "$RESET"
}

pct_color() {
	if [ "$1" -ge 80 ]; then printf '%s' "$RED"
	elif [ "$1" -ge 50 ]; then printf '%s' "$YELLOW"
	else printf '%s' "$GREEN"; fi
}

out=""

# model · effort (+ fast mode)
head="$(fg "$BG")"$'\033[1m'"󰚩 $model"$'\033[22m'
[ -n "$effort" ] && head+=" · $effort"
[ "$fast" = true ] && head+=" 󱐋"
out+="$(capsule "$BLUE" "$head")"

# context window: 8-cell bar
filled=$(((ctx * 8 + 50) / 100))
[ "$filled" -gt 8 ] && filled=8
bar=""
for ((i = 0; i < 8; i++)); do
	if [ "$i" -lt "$filled" ]; then bar+="▰"; else bar+="▱"; fi
done
c="$(pct_color "$ctx")"
out+="$(capsule "$SURFACE" "$(fg "$c")$bar $(fg "$FG")${ctx}%")"

# git: branch, worktree, PR
if [ -n "$cwd" ] && branch="$(git -C "$cwd" symbolic-ref --short -q HEAD 2>/dev/null)"; then
	git_part="$(fg "$PURPLE")󰘬 $branch"
	[ -n "$worktree" ] && git_part+=" $(fg "$CYAN")󰙅 $worktree"
	if [ -n "$pr_num" ]; then
		case "$pr_state" in
		approved) pc="$GREEN" ;;
		changes_requested) pc="$RED" ;;
		draft) pc="$DIM" ;;
		*) pc="$YELLOW" ;;
		esac
		git_part+=" $(fg "$pc")󰓂 #$pr_num"
	fi
	out+="$(capsule "$SURFACE" "$git_part")"
fi

# lines changed this session
if [ "$added" != 0 ] || [ "$removed" != 0 ]; then
	out+="$(capsule "$SURFACE" "$(fg "$GREEN")+$added $(fg "$RED")-$removed")"
fi

# session wall time
mins=$((dur_ms / 60000))
if [ "$mins" -ge 60 ]; then
	t="$((mins / 60))h$((mins % 60))m"
else
	t="${mins}m"
fi
out+="$(capsule "$SURFACE" "$(fg "$ORANGE")󱎫 $(fg "$FG")$t")"

printf '%s\n' "$out"
