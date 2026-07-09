#!/usr/bin/env bash
#
# Notification click handler — jump every attached tmux client to the given
# session + window and raise Ghostty. Args: <session_name> <window_id>.
# Runs from the notification daemon, so PATH is minimal — resolve tmux.

set -uo pipefail

session="${1:-}"
win_id="${2:-}"
[ -n "$session" ] && [ -n "$win_id" ] || exit 0

TMUX_BIN="$(command -v tmux 2>/dev/null || true)"
if [ -z "$TMUX_BIN" ]; then
	for d in /opt/homebrew/bin /usr/local/bin /usr/bin; do
		if [ -x "$d/tmux" ]; then TMUX_BIN="$d/tmux"; break; fi
	done
fi
[ -n "$TMUX_BIN" ] || exit 0

# select-window is session-scoped and works without a client; the window may
# have been closed since the notification fired, so tolerate failure.
"$TMUX_BIN" select-window -t "$win_id" 2>/dev/null

"$TMUX_BIN" list-clients -F '#{client_name}' 2>/dev/null | while IFS= read -r client; do
	"$TMUX_BIN" switch-client -c "$client" -t "$session" 2>/dev/null
done

open -b com.mitchellh.ghostty

exit 0
