#!/usr/bin/env bash
#
# tmux segment — reads the harvested Claude usage cache and renders it as a
# Tokyo Night capsule matching the rest of the status bar:
#   󰥔 42% ↻ 14:30 󰸗 12%   (5h window · reset time · 7d window)
# Pure bash, no network; runs on every status-line redraw.
# Based on docker-run/tmux-claude-usage (MIT).

set -uo pipefail

# used_percentage is a dot-decimal float; force the C locale so printf '%.0f'
# parses it even under a comma-radix locale.
export LC_ALL=C

CACHE_FILE="$HOME/.cache/claude-usage/usage" # must match scripts/harvester.sh
[ -f "$CACHE_FILE" ] || exit 0

# Only show the capsule when the current window is running claude. The entry
# point passes #{window_id}, expanded by tmux before the job runs. Matched via
# ps on each pane's tty — #{pane_current_command} is useless here because the
# claude binary's process name is its version string (e.g. "2.1.202").
window_id="${1:-}"
if [ -n "$window_id" ]; then
	claude_here=0
	while IFS= read -r tty; do
		if ps -o comm= -t "${tty#/dev/}" 2>/dev/null | grep -qxE '(.*/)?claude'; then
			claude_here=1
			break
		fi
	done < <(tmux list-panes -t "$window_id" -F '#{pane_tty}' 2>/dev/null)
	[ "$claude_here" = 1 ] || exit 0
fi

# Load the harvested values without sourcing (no code execution from the file).
five_pct="" five_reset="" seven_pct="" seven_reset=""
while IFS='=' read -r key val; do
	case "$key" in
	FIVE_HOUR_PCT) five_pct="$val" ;;
	FIVE_HOUR_RESET) five_reset="$val" ;;
	SEVEN_DAY_PCT) seven_pct="$val" ;;
	SEVEN_DAY_RESET) seven_reset="$val" ;;
	esac
done <"$CACHE_FILE"

# Tokyo Night
DARK="#292e42"
BLUE="#7aa2f7"
CYAN="#7dcfff"
GREEN="#9ece6a"
YELLOW="#e0af68"
RED="#f7768e"
PURPLE="#bb9af7"
DIM="#565f89"

# green under 70%, yellow under 90%, red above — same as the old status line
pct_color() {
	if [ "$1" -ge 90 ]; then
		printf '%s' "$RED"
	elif [ "$1" -ge 70 ]; then
		printf '%s' "$YELLOW"
	else
		printf '%s' "$GREEN"
	fi
}

now="$(date +%s)"

# Normalize one window: rounds the percentage and self-expires the cache —
# once the reset time has passed, the window has provably rolled over, so
# show 0% with no countdown instead of a stale figure.
# Sets REPLY_PCT / REPLY_RESET (empty reset = don't show one).
window() {
	local pct_raw="$1" reset_epoch="$2"
	REPLY_PCT="" REPLY_RESET=""
	[ -n "$pct_raw" ] || return 1
	printf -v REPLY_PCT '%.0f' "$pct_raw" 2>/dev/null || return 1
	if [[ "$reset_epoch" =~ ^[0-9]+$ ]]; then
		if [ "$now" -ge "$reset_epoch" ]; then
			REPLY_PCT=0
		else
			REPLY_RESET="$reset_epoch"
		fi
	fi
	return 0
}

body=""

# model · version, stamped on the window by scripts/statusline.sh
if [ -n "$window_id" ]; then
	IFS=$'\x1f' read -r model version <<EOF
$(tmux display -p -t "$window_id" '#{@claude_model}'$'\x1f''#{@claude_version}' 2>/dev/null)
EOF
	if [ -n "${model:-}" ]; then
		body+="#[fg=$PURPLE,bg=$DARK,bold]󰚩 $model#[nobold]"
		[ -n "${version:-}" ] && body+="#[fg=$DIM] v$version"
		body+="#[fg=$DIM] │ "
	fi
fi

if window "$five_pct" "$five_reset"; then
	body+="#[fg=$BLUE,bg=$DARK]󰥔 #[fg=$(pct_color "$REPLY_PCT")]${REPLY_PCT}%"
	if [ -n "$REPLY_RESET" ]; then
		body+="#[fg=$CYAN] ↻ $(date -r "$REPLY_RESET" +%H:%M 2>/dev/null || echo '?')"
	fi
fi

if window "$seven_pct" "$seven_reset"; then
	[ -n "$body" ] && body+=" "
	body+="#[fg=$BLUE,bg=$DARK]󰸗 #[fg=$(pct_color "$REPLY_PCT")]${REPLY_PCT}%"
fi

[ -n "$body" ] || exit 0

# rounded capsule caps (U+E0B6 / U+E0B4), matching the other status capsules;
# byte escapes so editors and tools can't silently drop the private-use glyphs
L=$'\xee\x82\xb6' R=$'\xee\x82\xb4'
printf '#[fg=%s,bg=default]%s#[bg=%s]%s#[fg=%s,bg=default]%s ' "$DARK" "$L" "$DARK" "$body" "$DARK" "$R"
