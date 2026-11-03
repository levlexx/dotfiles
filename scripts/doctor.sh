#!/usr/bin/env bash
#
# dotfiles doctor: checks this machine against the repo, i.e. what CI can't
# see. Run after ./bootstrap.sh (or any time something feels off on the
# second Mac):  mise run doctor
#
# Links are read from bootstrap.sh itself, so this list never drifts.

set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fails=0 warns=0

ok() { printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; warns=$((warns + 1)); }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; fails=$((fails + 1)); }
section() { printf '\n\033[1m%s\033[0m\n' "$1"; }

section "links (from bootstrap.sh)"
link_ok=0
# tab-separated: link targets can contain spaces ("themes/Tokyo Night")
while IFS=$'\t' read -r src dst; do
	src="${src//\$dotfiles_dir/$DIR}"
	dst="${dst//\$HOME/$HOME}"
	if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
		link_ok=$((link_ok + 1))
	elif [ -e "$dst" ]; then
		fail "${dst/#$HOME/\~} exists but is not a link to the repo"
	else
		fail "${dst/#$HOME/\~} missing (run ./bootstrap.sh)"
	fi
done < <(sed -n 's/^link "\(.*\)" "\(.*\)"$/\1\t\2/p' "$DIR/bootstrap.sh")
ok "$link_ok links point into the repo"

section "packages"
if command -v brew >/dev/null; then
	if brew bundle check --no-upgrade --file="$DIR/Brewfile" >/dev/null 2>&1; then
		ok "Brewfile satisfied"
	else
		fail "Brewfile: missing packages (brew bundle --file=$DIR/Brewfile)"
	fi
else
	fail "brew not installed"
fi
if command -v mise >/dev/null; then
	missing="$(mise ls --missing 2>/dev/null | awk '{print $1}' | tr '\n' ' ')"
	if [ -z "$missing" ]; then ok "mise tools installed"; else fail "mise missing: $missing(mise install)"; fi
else
	fail "mise not installed"
fi
for bin in gopls tree-sitter typescript-language-server; do
	if command -v "$bin" >/dev/null || mise which "$bin" >/dev/null 2>&1; then
		ok "$bin"
	else
		warn "$bin not found (mise install / mise run install-go-tools)"
	fi
done

section "claude"
settings="$HOME/.claude/settings.json"
if [ -f "$settings" ]; then
	statusline="$(jq -r '.statusLine.command // ""' "$settings")"
	if [[ "$statusline" == *statusline.sh ]]; then ok "statusLine -> statusline.sh"; else fail "statusLine not wired (./bootstrap.sh)"; fi
	hooks="$(jq -r '.hooks // {} | keys | join(" ")' "$settings")"
	for h in UserPromptSubmit PostToolUse Notification Stop SessionStart; do
		[[ " $hooks " == *" $h "* ]] || fail "hook $h missing (./bootstrap.sh)"
	done
	ok "state hooks: $hooks"
	deny="$(jq -r '.permissions.deny // [] | length' "$settings")"
	if [ "$deny" -gt 0 ]; then ok "$deny secret deny rules"; else warn "no permissions.deny rules"; fi
	on="$(jq -r '.enabledPlugins // {} | to_entries | map(select(.value)) | map(.key | sub("@.*"; "")) | join(" ")' "$settings")"
	ok "plugins on everywhere: ${on:-none}"
else
	fail "no ~/.claude/settings.json (start claude once, then ./bootstrap.sh)"
fi
installed="$HOME/.claude/plugins/installed_plugins.json"
for p in gopls-lsp typescript-lsp lua-lsp superpowers figma; do
	jq -e --arg p "$p@claude-plugins-official" '.plugins[$p]' "$installed" >/dev/null 2>&1 ||
		warn "plugin $p not installed (./bootstrap.sh)"
done

section "tmux"
for p in tpm vim-tmux-navigator tmux-resurrect tmux-continuum tmux-which-key; do
	[ -d "$HOME/.tmux/plugins/$p" ] || fail "tmux plugin $p missing (prefix I)"
done
ok "tmux plugins present"
command -v tmux-fingers >/dev/null && ok "tmux-fingers" || fail "tmux-fingers missing (brew)"
if tmux info >/dev/null 2>&1; then
	pid="$(tmux show -gqv @anim_pid 2>/dev/null)"
	if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then ok "agent animator running"; else warn "agent animator not running (prefix r)"; fi
fi

section "terminal"
if command -v ghostty >/dev/null; then
	ghostty +validate-config >/dev/null 2>&1 && ok "ghostty config valid" || fail "ghostty config invalid (ghostty +validate-config)"
	ghostty +list-fonts 2>/dev/null | grep -q "JetBrainsMono Nerd Font" && ok "JetBrainsMono Nerd Font" ||
		fail "JetBrainsMono Nerd Font not installed"
fi
bat --list-themes 2>/dev/null | grep -q tokyonight_night && ok "bat theme cache" || fail "bat theme missing (bat cache --build)"

section "gcloud"
if command -v gcloud >/dev/null; then
	acct="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null)"
	[ -n "$acct" ] && ok "gcloud logged in ($acct)" || warn "gcloud not logged in (gcloud auth login)"
	[ -f "$HOME/.config/gcloud/application_default_credentials.json" ] && ok "application default credentials" ||
		warn "no ADC for local SDKs (gcloud auth application-default login)"
	comps="$(gcloud components list --only-local-state --format='value(id)' 2>/dev/null | tr '\n' ' ')"
	[[ " $comps " == *" log-streaming "* ]] && ok "gcloud beta + log-streaming" ||
		warn "gcloud log-streaming missing, crtail won't work (./bootstrap.sh)"
	n="$(gcloud config configurations list --format='value(name)' 2>/dev/null | wc -l | tr -d ' ')"
	ok "$n gcloud configuration(s) (gcinit binds a repo)"
else
	warn "gcloud not installed"
fi

section "accounts"
gh auth status >/dev/null 2>&1 && ok "gh logged in" || warn "gh not logged in (gh auth login)"
atuin status >/dev/null 2>&1 && ok "atuin sync logged in" || warn "atuin sync not set up (atuin login)"

printf '\n'
if [ "$fails" -gt 0 ]; then
	printf '\033[31m%d problem(s)\033[0m, %d warning(s)\n' "$fails" "$warns"
	exit 1
fi
printf '\033[32mall good\033[0m, %d warning(s)\n' "$warns"
