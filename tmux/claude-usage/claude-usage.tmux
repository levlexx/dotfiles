#!/usr/bin/env bash
#
# Entry point — replaces the `#{claude_usage}` placeholder in status-right /
# status-left with a call to the segment script.
# Based on docker-run/tmux-claude-usage (MIT).

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLACEHOLDER='#{claude_usage}'
# tmux expands #{window_id} before running the job, so the segment knows the
# window being drawn and re-runs on every window switch (new job string).
SCRIPT_CALL="#($CURRENT_DIR/scripts/segment.sh '#{window_id}')"

interpolate_option() {
	local option="$1" value
	value="$(tmux show-option -gqv "$option")"
	tmux set-option -gq "$option" "${value//$PLACEHOLDER/$SCRIPT_CALL}"
}

chmod +x "$CURRENT_DIR"/scripts/*.sh 2>/dev/null
interpolate_option "status-right"
interpolate_option "status-left"
