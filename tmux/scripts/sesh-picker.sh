#!/usr/bin/env bash
#
# Fuzzy session picker: tmux sessions, sesh.toml entries and zoxide dirs.
# Picking a directory creates (or reuses) a session rooted there.

set -uo pipefail

pick="$(
	sesh list --icons | fzf-tmux -p 70%,60% --no-sort --ansi \
		--border=rounded --border-label ' sesh ' --prompt 'all › ' \
		--header '^a all  ^t tmux  ^x zoxide  ^d kill' \
		--bind 'tab:down,btab:up' \
		--preview 'sesh preview {}' --preview-window 'right,55%,border-left' \
		--bind 'ctrl-a:change-prompt(all › )+reload(sesh list --icons)' \
		--bind 'ctrl-t:change-prompt(tmux › )+reload(sesh list -t --icons)' \
		--bind 'ctrl-x:change-prompt(zoxide › )+reload(sesh list -z --icons)' \
		--bind 'ctrl-d:execute(tmux kill-session -t {2..})+reload(sesh list --icons)'
)"

[ -n "$pick" ] && sesh connect "$pick"
