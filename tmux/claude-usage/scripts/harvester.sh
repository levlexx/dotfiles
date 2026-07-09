#!/usr/bin/env bash
#
# Claude Code statusLine command — the "harvester".
# Based on docker-run/tmux-claude-usage (MIT).
#
# Claude Code runs this on every render and passes session JSON on stdin. We
# pull out the official account usage (rate_limits) and write it to a small
# cache file for the tmux segment to read. It prints nothing, so no status
# line appears inside the pane — usage shows up only in the tmux bar.

set -uo pipefail

# Pinned under $HOME (not XDG_CACHE_HOME) so this harvester and the tmux
# segment resolve the same path even when their environments differ. Must
# match scripts/segment.sh.
CACHE_DIR="$HOME/.cache/claude-usage"
CACHE_FILE="$CACHE_DIR/usage"

input="$(cat)"

# Claude Code may be launched from a GUI context whose PATH lacks Homebrew,
# so fall back to common install locations before giving up quietly.
JQ="$(command -v jq 2>/dev/null || true)"
if [ -z "$JQ" ]; then
	for d in /opt/homebrew/bin /usr/local/bin /usr/bin /bin; do
		if [ -x "$d/jq" ]; then JQ="$d/jq"; break; fi
	done
fi
[ -n "$JQ" ] || exit 0

data="$(printf '%s' "$input" | "$JQ" -r '
	.rate_limits as $r
	| "FIVE_HOUR_PCT=\($r.five_hour.used_percentage // "")",
	  "FIVE_HOUR_RESET=\($r.five_hour.resets_at // "")",
	  "SEVEN_DAY_PCT=\($r.seven_day.used_percentage // "")",
	  "SEVEN_DAY_RESET=\($r.seven_day.resets_at // "")"
' 2>/dev/null)" || exit 0

# Freshness guard for the shared cache: every Claude session writes this one
# file, and an idle session re-rendering would replay the stale snapshot it
# last saw. Accept a snapshot only if at least as fresh as what's cached — a
# later five_hour window (greater resets_at) wins, and within the same window
# the higher used_percentage is the newer reading (usage only climbs).
should_write() {
	[ -f "$CACHE_FILE" ] || return 0

	local nr np cr cp
	nr="$(printf '%s\n' "$data" | sed -n 's/^FIVE_HOUR_RESET=//p')"
	np="$(printf '%s\n' "$data" | sed -n 's/^FIVE_HOUR_PCT=//p')"
	cr="$(sed -n 's/^FIVE_HOUR_RESET=//p' "$CACHE_FILE" 2>/dev/null)"
	cp="$(sed -n 's/^FIVE_HOUR_PCT=//p' "$CACHE_FILE" 2>/dev/null)"

	awk -v nr="$nr" -v np="$np" -v cr="$cr" -v cp="$cp" 'BEGIN {
		if (nr == "" || np == "" || cr == "" || cp == "") exit 0
		nr += 0; np += 0; cr += 0; cp += 0
		if (nr > cr) exit 0              # newer window
		if (nr == cr && np >= cp) exit 0 # same window, fresher reading
		exit 1                           # stale snapshot: keep what we have
	}'
}

# Only write when there is actual usage data, so a render without rate_limits
# never clobbers a good cache.
if printf '%s' "$data" | grep -q 'PCT=[0-9]' && should_write; then
	mkdir -p "$CACHE_DIR"
	{
		printf '%s\n' "$data"
		printf 'UPDATED_AT=%s\n' "$(date +%s)"
	} >"$CACHE_FILE.tmp.$$" 2>/dev/null && mv "$CACHE_FILE.tmp.$$" "$CACHE_FILE" 2>/dev/null
fi

exit 0
