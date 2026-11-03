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
busy_last=0

# Tokyo Night is dark by default. With `set -g @follow_macos on` the pane
# backgrounds and borders follow macOS light/dark (Tokyo Night day / night),
# checked ~every 5s; pair it with Ghostty's `theme = light:...,dark:...`.
appearance=""
ticks=0
apply_appearance() {
	local mode
	mode=dark
	if [ "$(t show -gqv @follow_macos 2>/dev/null)" = on ] &&
		! defaults read -g AppleInterfaceStyle >/dev/null 2>&1; then
		mode=light
	fi
	# compare with tmux, not a local copy: a config reload resets @appearance
	# (and the styles) so the next check repaints
	appearance="$mode"
	[ "$mode" = "$(t show -gqv @appearance 2>/dev/null)" ] && return
	if [ "$mode" = light ]; then
		t set -g window-style "bg=#d0d5e3" \; set -g window-active-style "bg=#e1e2e7" \; \
			set -g status-style "bg=default,fg=#3760bf" \; \
			set -g pane-border-style "fg=#a8aecb" \; set -g pane-active-border-style "fg=#2e7de9" \; \
			set -g @appearance light 2>/dev/null
	else
		t set -g window-style "bg=#16161e" \; set -g window-active-style "bg=#1a1b26" \; \
			set -g status-style "bg=default,fg=#a9b1d6" \; \
			set -g pane-border-style "fg=#414868" \; set -g pane-active-border-style "fg=#7aa2f7" \; \
			set -g @appearance dark 2>/dev/null
	fi
}

# one read per tick: clients (C) and every window's agent state (W)
while snapshot="$(t list-clients -F 'C #{client_name}' \; list-windows -a -F 'W #{@claude_state}' 2>/dev/null)"; do
	# a newer loop took over (e.g. after a server restart race)
	[ "$(t show -gqv @anim_pid 2>/dev/null)" = "$$" ] || exit 0

	# about every 5s whether busy (0.16s ticks) or idle (1s ticks)
	ticks=$((ticks + 1))
	if [ "$ticks" -ge 5 ] || [ -z "$appearance" ]; then
		[ "$busy_last" = 1 ] && [ "$ticks" -lt 30 ] || { apply_appearance; ticks=0; }
	fi

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
	busy_last=$((busy > 0 ? 1 : 0))
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
