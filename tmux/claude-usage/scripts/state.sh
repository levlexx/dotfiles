#!/usr/bin/env bash
#
# Claude Code hook — stamps the agent's work state on the tmux window so the
# window tab can show it. Wired via settings.json (see bootstrap.sh):
#   UserPromptSubmit, PostToolUse     -> working  (spinner, scripts/animate.sh)
#   Notification (permission, ask)    -> waiting  (pulsing bell, red tab)
#   Stop                              -> done     (check until you look at it)
#   StopFailure                       -> error
#   SessionStart                      -> idle
#   SessionEnd                        -> clear
#   SubagentStart / SubagentStop      -> sub+ / sub-  (+N next to the spinner)
# Also keeps, per window: @claude_pane (the claude pane, for previews) and
# @claude_last (Claude's last reply or what it is waiting for, one line).
# Runs inside the claude process, which inherits $TMUX_PANE from its pane.

set -uo pipefail

state="${1:-}"
[ -n "${TMUX_PANE:-}" ] || exit 0

# Hook JSON arrives on stdin; don't block when run by hand.
input=""
[ -t 0 ] || input="$(cat)"

# Hooks may run with a GUI-ish PATH; resolve tools with fallbacks.
find_bin() {
	local d
	command -v "$1" 2>/dev/null && return 0
	for d in /opt/homebrew/bin /usr/local/bin /usr/bin /bin; do
		[ -x "$d/$1" ] && { printf '%s' "$d/$1"; return 0; }
	done
	return 1
}
TMUX_BIN="$(find_bin tmux)" || exit 0
t() { "$TMUX_BIN" "$@"; }

# visible first: it is never empty, and tab IFS would swallow an empty state
IFS=$'\t' read -r visible subs current <<EOF
$(t display -p -t "$TMUX_PANE" '#{&&:#{window_active},#{session_attached}}	#{?@claude_subagents,#{@claude_subagents},0}	#{@claude_state}' 2>/dev/null)
EOF
subs="${subs:-0}"

# one line of context for the picker and notifications
last_line() {
	local JQ
	[ -n "$input" ] || return 0
	JQ="$(find_bin jq)" || return 0
	printf '%s' "$input" | "$JQ" -r "$1 // empty" 2>/dev/null |
		tr '\n\t' '  ' | sed -e 's/  */ /g' -e 's/^ //' -e 's/ $//' | cut -c1-300
}

cmd=()
case "$state" in
working | error | idle) ;;
waiting)
	msg="$(last_line '.message')"
	[ -n "$msg" ] && cmd+=(set -w -t "$TMUX_PANE" @claude_last "$msg" \;)
	;;
done)
	msg="$(last_line '.last_assistant_message')"
	[ -n "$msg" ] && cmd+=(set -w -t "$TMUX_PANE" @claude_last "$msg" \;)
	# finished while you're looking at it: nothing left to flag
	[ "${visible:-0}" = 1 ] && state=idle
	;;
sub+ | sub-)
	if [ "$state" = "sub+" ]; then subs=$((subs + 1)); else subs=$((subs - 1)); fi
	[ "$subs" -lt 0 ] && subs=0
	t set -w -t "$TMUX_PANE" @claude_subagents "$subs" 2>/dev/null
	exit 0
	;;
clear)
	t set -w -u -t "$TMUX_PANE" @claude_state \; \
		set -w -u -t "$TMUX_PANE" @claude_last \; \
		set -w -u -t "$TMUX_PANE" @claude_pane \; \
		set -w -u -t "$TMUX_PANE" @claude_subagents \; \
		set -w -u -t "$TMUX_PANE" @tab_bg \; \
		set -w -u -t "$TMUX_PANE" @tab_fg \; \
		set -w -u -t "$TMUX_PANE" @tab_idx 2>/dev/null
	state=""
	;;
*) exit 0 ;;
esac

# PostToolUse fires on every tool call; skip the repaint when nothing changed.
if [ -n "$state" ]; then
	[ "$state" = "${current:-}" ] && [ ${#cmd[@]} -eq 0 ] && exit 0
	cmd+=(set -w -t "$TMUX_PANE" @claude_state "$state" \; set -w -t "$TMUX_PANE" @claude_pane "$TMUX_PANE" \;)
	[ "$state" = idle ] && cmd+=(set -w -t "$TMUX_PANE" @claude_subagents 0 \;)
	# a waiting agent turns its whole (inactive) tab red
	if [ "$state" = waiting ]; then
		cmd+=(set -w -t "$TMUX_PANE" @tab_bg "#f7768e" \; set -w -t "$TMUX_PANE" @tab_fg "#1a1b26" \;
			set -w -t "$TMUX_PANE" @tab_idx "#1a1b26" \;)
	else
		cmd+=(set -w -u -t "$TMUX_PANE" @tab_bg \; set -w -u -t "$TMUX_PANE" @tab_fg \;
			set -w -u -t "$TMUX_PANE" @tab_idx \;)
	fi
	t "${cmd[@]}" 2>/dev/null
fi

# Option changes alone don't repaint the bar; nudge every attached client so
# the icon flips immediately instead of on the next status-interval.
t list-clients -F '#{client_name}' 2>/dev/null | while IFS= read -r client; do
	t refresh-client -S -t "$client" 2>/dev/null
done
