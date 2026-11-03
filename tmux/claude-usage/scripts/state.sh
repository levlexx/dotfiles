#!/usr/bin/env bash
#
# Claude Code hook — stamps the agent's work state on the tmux window so the
# window tab can show it. Wired via settings.json (see bootstrap.sh):
#   UserPromptSubmit, PostToolUse     -> working  (spinner, scripts/animate.sh)
#   PermissionRequest, Notification   -> waiting  (pulsing bell: needs you)
#   Stop                              -> done     (check until you look at it)
#   StopFailure                       -> error
#   SessionStart                      -> idle
#   SessionEnd                        -> clear
# Runs inside the claude process, which inherits $TMUX_PANE from its pane.

set -uo pipefail

state="${1:-}"
[ -n "${TMUX_PANE:-}" ] || exit 0

# Hooks may run with a GUI-ish PATH; fall back to common tmux locations.
TMUX_BIN="$(command -v tmux 2>/dev/null || true)"
if [ -z "$TMUX_BIN" ]; then
	for d in /opt/homebrew/bin /usr/local/bin /usr/bin; do
		if [ -x "$d/tmux" ]; then TMUX_BIN="$d/tmux"; break; fi
	done
fi
[ -n "$TMUX_BIN" ] || exit 0

# visible first: it is never empty, and tab IFS would swallow an empty state
IFS=$'\t' read -r visible current <<EOF
$("$TMUX_BIN" display -p -t "$TMUX_PANE" '#{&&:#{window_active},#{session_attached}}	#{@claude_state}' 2>/dev/null)
EOF

case "$state" in
working | waiting | error | idle) ;;
done)
	# finished while you're looking at it: nothing left to flag
	[ "${visible:-0}" = 1 ] && state=idle
	;;
clear)
	"$TMUX_BIN" set-option -w -u -t "$TMUX_PANE" @claude_state 2>/dev/null
	state=""
	;;
*) exit 0 ;;
esac

# PostToolUse fires on every tool call; skip the repaint when nothing changed.
[ -n "$state" ] && [ "$state" = "${current:-}" ] && exit 0
[ -n "$state" ] && "$TMUX_BIN" set-option -w -t "$TMUX_PANE" @claude_state "$state" 2>/dev/null

# Option changes alone don't repaint the bar; nudge every attached client so
# the icon flips immediately instead of on the next status-interval.
"$TMUX_BIN" list-clients -F '#{client_name}' 2>/dev/null | while IFS= read -r client; do
	"$TMUX_BIN" refresh-client -S -t "$client" 2>/dev/null
done
