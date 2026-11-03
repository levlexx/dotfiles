#!/usr/bin/env bash
#
# Jump to the next agent that wants you, across all sessions: waiting first
# (permission / question), then error, then done (finished, not seen yet).
# Cycles past the current window so repeated presses visit each one.
# Args: client_name current_target (session:index)

set -uo pipefail

client="$1" current="$2"

windows="$(tmux list-windows -a -F '#{session_name}:#{window_index} #{@claude_state}' 2>/dev/null)"

for want in waiting error done; do
	targets=()
	while read -r target state; do
		[ "$state" = "$want" ] && targets+=("$target")
	done <<<"$windows"
	[ ${#targets[@]} -gt 0 ] || continue

	# first match after the current window, wrapping around
	pick="${targets[0]}"
	for i in "${!targets[@]}"; do
		if [ "${targets[$i]}" = "$current" ]; then
			pick="${targets[$(((i + 1) % ${#targets[@]}))]}"
			break
		fi
	done
	tmux switch-client -c "$client" -t "$pick"
	exit 0
done

tmux display-message -c "$client" "no agent needs you"
