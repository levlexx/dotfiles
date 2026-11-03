#!/usr/bin/env bash
#
# Agent animator — one loop per tmux server, started from claude-usage.tmux.
# While any window has a working (or waiting) Claude it advances a spinner
# frame (@spin) and a blink phase (@pulse) ~6x/s and repaints every client;
# otherwise it ticks once a second and only repaints on change. It also keeps
# @agents: a status-left summary of agent states across all sessions.

set -uo pipefail

TMUX_BIN="$(command -v tmux 2>/dev/null || echo /opt/homebrew/bin/tmux)"
t() { "$TMUX_BIN" "$@"; }

# single instance: another live loop already owns this server
pid="$(t show -gqv @anim_pid 2>/dev/null)"
if [ -n "$pid" ] && [ "$pid" != "$$" ] && kill -0 "$pid" 2>/dev/null; then
	exit 0
fi
t set -g @anim_pid "$$" || exit 0

frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
i=0
last=""

# one read per tick: clients (C) and every window's agent state (W)
while snapshot="$(t list-clients -F 'C #{client_name}' \; list-windows -a -F 'W #{@claude_state}' 2>/dev/null)"; do
	# a newer loop took over (e.g. after a server restart race)
	[ "$(t show -gqv @anim_pid 2>/dev/null)" = "$$" ] || exit 0

	working=0 waiting=0 done=0 error=0
	clients=()
	while IFS= read -r line; do
		case "$line" in
		"C "*) clients+=("${line#C }") ;;
		"W working") working=$((working + 1)) ;;
		"W waiting") waiting=$((waiting + 1)) ;;
		"W done") done=$((done + 1)) ;;
		"W error") error=$((error + 1)) ;;
		esac
	done <<<"$snapshot"

	frame="${frames[i % ${#frames[@]}]}"
	pulse=$(((i / 3) % 2))

	summary=""
	[ "$working" -gt 0 ] && summary+="#[fg=#e0af68]$frame $working "
	[ "$waiting" -gt 0 ] && summary+="#[fg=#f7768e,bold]󰂞 $waiting#[nobold] "
	[ "$done" -gt 0 ] && summary+="#[fg=#9ece6a]󰄬 $done "
	[ "$error" -gt 0 ] && summary+="#[fg=#f7768e]󰅚 $error "
	summary="${summary% }"

	busy=$((working + waiting))
	if [ "$busy" -gt 0 ] || [ "$summary" != "$last" ]; then
		cmd=(set -g @spin "$frame" \; set -g @pulse "$pulse" \; set -g @agents "$summary")
		for c in "${clients[@]}"; do
			cmd+=(\; refresh-client -S -t "$c")
		done
		t "${cmd[@]}" 2>/dev/null
		last="$summary"
	fi

	if [ "$busy" -gt 0 ]; then
		i=$((i + 1))
		sleep 0.16
	else
		sleep 1
	fi
done
