#!/usr/bin/env zsh
set -eu

dotfiles_dir="${DOTFILES_DIR:-${0:A:h}}"

link() {
  local source="$1"
  local target="$2"

  mkdir -p "${target:h}"

  if [[ -L "$target" ]]; then
    ln -sfn "$source" "$target"
    print "linked $target"
  elif [[ -e "$target" ]]; then
    if [[ -f "$source" && -f "$target" ]] && cmp -s "$source" "$target"; then
      rm "$target"
      ln -s "$source" "$target"
      print "linked $target"
    else
      print -u2 "skip existing non-symlink: $target"
    fi
  else
    ln -s "$source" "$target"
    print "linked $target"
  fi
}

# Wire Claude Code into the tmux claude-usage plugin: the statusLine renders
# the capsule row under the prompt (and feeds the usage harvester), and hooks
# stamp the per-window agent state shown in the tmux tabs:
#   working (spinner, +N subagents) · waiting (bell, red tab) · done · error ·
#   idle; prefix N / prefix C jump to them
configure_claude_settings() {
  local settings="$HOME/.claude/settings.json"
  local scripts="$HOME/.tmux/claude-usage/scripts"

  if ! command -v jq >/dev/null 2>&1; then
    print -u2 "skip claude settings: jq is not installed"
    return
  fi

  if [[ ! -f "$settings" ]]; then
    print -u2 "skip claude settings: no $settings"
    return
  fi

  local tmp
  tmp="$(mktemp)"
  if jq --arg s "$scripts" '
    def cmd(c): {type: "command", command: ($s + "/" + c)};
    .statusLine = {type: "command", command: ($s + "/statusline.sh"), padding: 0}
    | .hooks = (.hooks // {}) + {
        UserPromptSubmit: [{hooks: [cmd("state.sh working")]}],
        PostToolUse: [{hooks: [cmd("state.sh working")]}],
        Notification: [{
          matcher: "permission_prompt|elicitation_dialog|agent_needs_input",
          hooks: [cmd("state.sh waiting"), cmd("notify.sh waiting")]
        }],
        Stop: [{hooks: [cmd("state.sh done"), cmd("notify.sh done")]}],
        StopFailure: [{hooks: [cmd("state.sh error")]}],
        SubagentStart: [{hooks: [cmd("state.sh sub+")]}],
        SubagentStop: [{hooks: [cmd("state.sh sub-")]}],
        SessionStart: [{hooks: [cmd("state.sh idle")]}],
        SessionEnd: [{hooks: [cmd("state.sh clear")]}]
      }' \
    "$settings" >"$tmp"; then
    mv "$tmp" "$settings"
    print "claude settings -> statusline + agent state hooks"
  else
    rm -f "$tmp"
    print -u2 "skip claude settings: jq edit failed"
  fi
}

# Code intelligence for Claude (go to definition / references via LSP).
# Servers: gopls (mise run install-go-tools), typescript-language-server (mise).
install_claude_plugins() {
  if ! command -v claude >/dev/null 2>&1; then
    print -u2 "skip claude plugins: claude is not installed"
    return
  fi

  local plugin
  for plugin in gopls-lsp typescript-lsp lua-lsp; do
    claude plugin install "$plugin@claude-plugins-official" >/dev/null 2>&1 \
      && print "claude plugin -> $plugin" \
      || print -u2 "skip claude plugin $plugin: install failed"
  done
}

# Give terminal-notifier the Claude icon so claude-usage notifications don't
# show a generic terminal. macOS ignores -appIcon, so the bundle icon is
# swapped and the app re-signed; re-run after a brew upgrade reverts it.
configure_notifier_icon() {
  local icns="$dotfiles_dir/tmux/claude-usage/assets/claude.icns"
  local app app_icns

  app="$(ls -d /opt/homebrew/Cellar/terminal-notifier/*/terminal-notifier.app 2>/dev/null | head -1)"
  if [[ -z "$app" || ! -f "$icns" ]]; then
    print -u2 "skip notifier icon: terminal-notifier or claude.icns missing"
    return
  fi

  app_icns="$app/Contents/Resources/Terminal.icns"
  if cmp -s "$icns" "$app_icns"; then
    return
  fi

  cp "$icns" "$app_icns"
  codesign --force -s - "$app" 2>/dev/null
  touch "$app"
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$app"
  killall NotificationCenter 2>/dev/null || true
  print "notifier icon -> claude"
}

install_brew_packages() {
  if [[ "${SKIP_BREW:-0}" == "1" ]]; then
    print "skip brew bundle"
    return
  fi

  if ! command -v brew >/dev/null 2>&1; then
    print -u2 "skip brew bundle: brew is not installed"
    return
  fi

  brew bundle --file="$dotfiles_dir/Brewfile"
}

# bat (and delta's syntax-theme) only see custom themes after a cache build
build_bat_cache() {
  if ! command -v bat >/dev/null 2>&1; then
    print -u2 "skip bat cache: bat is not installed"
    return
  fi

  bat cache --build >/dev/null && print "bat cache -> tokyonight_night"
}

install_gh_extensions() {
  if ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1; then
    print -u2 "skip gh extensions: gh missing or not logged in (gh auth login)"
    return
  fi

  # PR / issue dashboard: gh dash
  gh extension list | grep -q 'dlvhdr/gh-dash' || gh extension install dlvhdr/gh-dash
}

install_tmux_plugins() {
  if [[ "${SKIP_TMUX_PLUGINS:-0}" == "1" ]]; then
    print "skip tmux plugins"
    return
  fi

  if ! command -v tmux >/dev/null 2>&1; then
    print -u2 "skip tmux plugins: tmux is not installed"
    return
  fi

  if ! command -v git >/dev/null 2>&1; then
    print -u2 "skip tmux plugins: git is not installed"
    return
  fi

  local tpm_dir="$HOME/.tmux/plugins/tpm"

  if [[ ! -d "$tpm_dir/.git" ]]; then
    mkdir -p "${tpm_dir:h}"
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi

  tmux start-server \; source-file "$HOME/.tmux.conf"
  if [[ -x "$tpm_dir/bin/install_plugins" ]]; then
    "$tpm_dir/bin/install_plugins"
  fi
}

link "$dotfiles_dir/zsh/.zshrc" "$HOME/.zshrc"
link "$dotfiles_dir/tmux/.tmux.conf" "$HOME/.tmux.conf"
link "$dotfiles_dir/git/.gitconfig" "$HOME/.gitconfig"
link "$dotfiles_dir/git/.config/git/ignore" "$HOME/.config/git/ignore"
link "$dotfiles_dir/git/.config/git/hooks/pre-commit" "$HOME/.config/git/hooks/pre-commit"
link "$dotfiles_dir/git/.config/git/hooks/commit-msg" "$HOME/.config/git/hooks/commit-msg"
link "$dotfiles_dir/commitlint/.config/commitlint/commitlint.config.mjs" "$HOME/.config/commitlint/commitlint.config.mjs"
link "$dotfiles_dir/docker/.dockerignore" "$HOME/.dockerignore"
link "$dotfiles_dir/mise/.config/mise/config.toml" "$HOME/.config/mise/config.toml"
link "$dotfiles_dir/nvim/.config/nvim" "$HOME/.config/nvim"
link "$dotfiles_dir/starship/.config/starship.toml" "$HOME/.config/starship.toml"
link "$dotfiles_dir/lazygit/.config/lazygit" "$HOME/.config/lazygit"
link "$dotfiles_dir/atuin/.config/atuin/config.toml" "$HOME/.config/atuin/config.toml"
link "$dotfiles_dir/btop/.config/btop/btop.conf" "$HOME/.config/btop/btop.conf"
link "$dotfiles_dir/vale/.config/vale/.vale.ini" "$HOME/.config/vale/.vale.ini"
link "$dotfiles_dir/bat/.config/bat" "$HOME/.config/bat"
link "$dotfiles_dir/eza/.config/eza" "$HOME/.config/eza"
link "$dotfiles_dir/tmux/claude-usage" "$HOME/.tmux/claude-usage"
link "$dotfiles_dir/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
link "$dotfiles_dir/tmux/scripts" "$HOME/.tmux/scripts"
link "$dotfiles_dir/sesh/.config/sesh/sesh.toml" "$HOME/.config/sesh/sesh.toml"
link "$dotfiles_dir/ghostty/.config/ghostty/config" "$HOME/.config/ghostty/config"
link "$dotfiles_dir/ghostty/.config/ghostty/shaders" "$HOME/.config/ghostty/shaders"
link "$dotfiles_dir/ghostty/.config/ghostty/themes/Tokyo Night" "$HOME/.config/ghostty/themes/Tokyo Night"

configure_claude_settings
install_brew_packages
install_claude_plugins
build_bat_cache
install_gh_extensions
configure_notifier_icon
install_tmux_plugins
