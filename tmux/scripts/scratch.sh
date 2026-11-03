#!/usr/bin/env bash
#
# Toggle a persistent scratch shell in a popup: one hidden "<session>-scratch"
# session per tmux session. Pressing the key again inside the popup detaches
# its client, which closes the popup and keeps the shell alive.
# Args: session_name pane_current_path client_name

set -uo pipefail

session="$1" dir="$2" client="$3"

if [[ "$session" == *-scratch ]]; then
	tmux detach-client -t "$client"
	exit 0
fi

scratch="${session}-scratch"
tmux display-popup -c "$client" -E -w 80% -h 75% -d "$dir" -T " scratch " \
	"TMUX= tmux new-session -A -s '$scratch' \; set -t '$scratch' status off"
