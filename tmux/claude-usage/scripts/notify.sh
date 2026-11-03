#!/usr/bin/env bash
#
# Claude Code Stop / PermissionRequest hook — posts a clickable macOS
# notification when a claude session finishes or needs you while you're
# looking elsewhere. Clicking it jumps to the
# exact tmux session + window (via scripts/focus-window.sh) and raises
# Ghostty. Skipped when Ghostty is frontmost AND the pane's window is the one
# currently on screen — you're already watching it.

set -uo pipefail

[ -n "${TMUX_PANE:-}" ] || exit 0

# done (Stop hook) or waiting (permission prompt / question for you)
kind="${1:-done}"

# hook JSON on stdin: Stop has last_assistant_message, Notification a message
input=""
[ -t 0 ] || input="$(cat)"
case "$kind" in
waiting) title="✋ Claude needs you" sound="Glass" ;;
*) title="✳ Claude done" sound="default" ;;
esac

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GHOSTTY_ID="com.mitchellh.ghostty"

# Hooks may run with a GUI-ish PATH; resolve tools with fallbacks.
find_bin() {
	local name="$1" d
	command -v "$name" 2>/dev/null && return 0
	for d in /opt/homebrew/bin /usr/local/bin /usr/bin /bin; do
		if [ -x "$d/$name" ]; then
			printf '%s' "$d/$name"
			return 0
		fi
	done
	return 1
}

TMUX_BIN="$(find_bin tmux)" || exit 0
JQ="$(find_bin jq)" || JQ=""
NOTIFIER="$(find_bin terminal-notifier)" || exit 0

IFS=$'\t' read -r session win_id win_active attached win_name project <<EOF
$("$TMUX_BIN" display-message -p -t "$TMUX_PANE" -F \
	'#{session_name}	#{window_id}	#{window_active}	#{session_attached}	#{window_name}	#{b:pane_current_path}' 2>/dev/null)
EOF
[ -n "${win_id:-}" ] || exit 0

# Window names carry nerd-font icons that macOS notifications render as "?";
# keep printable ASCII only and fall back to the window id.
win_name="$(printf '%s' "$win_name" | LC_ALL=C tr -cd '\40-\176' | sed -e 's/^ *//' -e 's/ *$//')"
[ -n "$win_name" ] || win_name="$win_id"

# Already on screen? (Ghostty focused + this window is the session's current
# window + a client is attached to the session.) Then no notification.
front="$(lsappinfo info -only bundleid "$(lsappinfo front 2>/dev/null)" 2>/dev/null)"
if [[ "$front" == *"$GHOSTTY_ID"* ]] && [ "${win_active:-0}" = 1 ] && [ "${attached:-0}" -ge 1 ]; then
	exit 0
fi

# body: what Claude said (or is asking), one line; fall back to where it is
body=""
if [ -n "$input" ] && [ -n "$JQ" ]; then
	body="$(printf '%s' "$input" | "$JQ" -r '.last_assistant_message // .message // empty' 2>/dev/null |
		tr '\n\t' '  ' | sed -e 's/  */ /g' -e 's/^ //' | cut -c1-180)"
fi
[ -n "$body" ] || body="session $session · window $win_name"

"$NOTIFIER" \
	-title "$title" \
	-subtitle "$project · $win_name" \
	-message "$body" \
	-group "claude-$win_id" \
	-sound "$sound" \
	-appIcon "$DIR/../assets/claude.png" \
	-execute "$DIR/focus-window.sh '$session' '$win_id'" \
	>/dev/null 2>&1 || true

exit 0
