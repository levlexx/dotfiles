#!/usr/bin/env bash
#
# Claude Code hook — stamps the agent's work state on the tmux window so the
# window tab can show a colored ✳ (working / done). Wired via settings.json:
#   UserPromptSubmit -> working, Stop -> done, SessionStart -> done,
#   SessionEnd -> clear.
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

case "$state" in
working | done)
	"$TMUX_BIN" set-option -w -t "$TMUX_PANE" @claude_state "$state" 2>/dev/null
	;;
clear)
	"$TMUX_BIN" set-option -w -u -t "$TMUX_PANE" @claude_state 2>/dev/null
	;;
*)
	exit 0
	;;
esac

# Option changes alone don't repaint the bar; nudge every attached client so
# the icon flips immediately instead of on the next status-interval.
"$TMUX_BIN" list-clients -F '#{client_name}' 2>/dev/null | while IFS= read -r client; do
	"$TMUX_BIN" refresh-client -S -t "$client" 2>/dev/null
done

exit 0
