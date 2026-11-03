#!/usr/bin/env bash
#
# Claude Code PostToolUse hook (Edit|Write|MultiEdit): format the file Claude
# just changed with the project's own formatter, so diffs never carry
# formatting noise. Only formats when the project opts in (go.mod, a biome or
# prettier config, a stylua config); never fails the tool call.

set -uo pipefail

JQ="$(command -v jq || echo /opt/homebrew/bin/jq)"
file="$("$JQ" -r '.tool_input.file_path // empty' 2>/dev/null)"
[ -n "$file" ] && [ -f "$file" ] || exit 0

dir="$(cd "$(dirname "$file")" && pwd)"

# nearest ancestor (up to the repo root) containing one of the given names
find_up() {
	local d="$dir" name
	while [ "$d" != "/" ]; do
		for name in "$@"; do
			[ -e "$d/$name" ] && { printf '%s' "$d"; return 0; }
		done
		[ -d "$d/.git" ] && return 1
		d="$(dirname "$d")"
	done
	return 1
}

run() { "$@" >/dev/null 2>&1 || true; }

case "$file" in
*.go)
	find_up go.mod >/dev/null || exit 0
	command -v goimports >/dev/null && run goimports -w "$file"
	command -v gofumpt >/dev/null && run gofumpt -w "$file"
	;;
*.lua)
	root="$(find_up .stylua.toml stylua.toml)" || exit 0
	command -v stylua >/dev/null && (cd "$root" && run stylua "$file")
	;;
*.ts | *.tsx | *.js | *.jsx | *.mjs | *.cjs | *.json | *.jsonc | *.css | *.scss | *.html)
	if root="$(find_up biome.json biome.jsonc)"; then
		tool=biome args=(format --write)
	elif root="$(find_up .prettierrc .prettierrc.json .prettierrc.js .prettierrc.cjs .prettierrc.yaml .prettierrc.yml prettier.config.js prettier.config.mjs)"; then
		tool=prettier args=(--write)
	else
		exit 0
	fi
	# the project's pinned version first, the mise-installed one otherwise
	bin="$root/node_modules/.bin/$tool"
	[ -x "$bin" ] || bin="$(command -v "$tool")" || exit 0
	(cd "$root" && run "$bin" "${args[@]}" "$file")
	;;
esac

exit 0
