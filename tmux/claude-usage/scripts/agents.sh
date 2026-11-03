#!/usr/bin/env bash
#
# Agent picker: every Claude window across all sessions with its state,
# task title and last reply; the preview is the live screen of the claude
# pane. Enter jumps there.
# Args: client_name | --list

set -uo pipefail

client="$1"
ESC=$'\033'
rgb() { printf '%s[38;2;%sm' "$ESC" "$1"; }
DIM="$(rgb '86;95;137')" FG="$(rgb '192;202;245')" BLUE="$(rgb '122;162;247')" OFF="$ESC[0m"

lines="$(tmux list-windows -a -F '#{session_name}:#{window_index}	#{?@claude_pane,#{@claude_pane},#{pane_id}}	#{@claude_state}	#{window_name}	#{@claude_last}' 2>/dev/null |
	awk -F'\t' -v dim="$DIM" -v fg="$FG" -v blue="$BLUE" -v off="$OFF" -v esc="$ESC" '
		$3 == "" { next }
		{
			if ($3 == "working") { icon = "⠋"; c = "224;175;104"; rank = 3 }
			else if ($3 == "waiting") { icon = "󰂞"; c = "247;118;142"; rank = 0 }
			else if ($3 == "error") { icon = "󰅚"; c = "247;118;142"; rank = 1 }
			else if ($3 == "done") { icon = "󰄬"; c = "158;206;106"; rank = 2 }
			else { icon = "󰚩"; c = "86;95;137"; rank = 4 }
			last = $5; if (length(last) > 90) last = substr(last, 1, 89) "…"
			printf "%d\t%s\t%s\t%s[38;2;%sm%s %s%-14s %s%s %s%s%s\n", rank, $1, $2, esc, c, icon, blue, $1, fg, $4, dim, last, off
		}' | sort -t$'\t' -k1,1n | cut -f2-)"

# --list: print the rows and stop (for testing)
[ "$client" = "--list" ] && { printf '%s\n' "$lines"; exit 0; }

if [ -z "$lines" ]; then
	tmux display-message -c "$client" "no claude agents running"
	exit 0
fi

pick="$(printf '%s\n' "$lines" | fzf-tmux -p 85%,70% --ansi --no-sort \
	--delimiter=$'\t' --with-nth=3 \
	--border=rounded --border-label ' agents ' --prompt 'agent › ' \
	--header 'enter: jump · waiting first' \
	--preview 'tmux capture-pane -ep -t {2}' \
	--preview-window 'down,60%,border-top,follow')"

[ -n "$pick" ] && tmux switch-client -c "$client" -t "${pick%%$'\t'*}"
