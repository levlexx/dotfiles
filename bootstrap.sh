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
    # compact long sessions at 400K instead of ~967K on 1M-context models:
    # every turn resends the whole context; keep a value set by hand
    .autoCompactWindow //= 400000 |
    # keep secrets out of the model context: Claude file tools and the
    # cat/head/sed it runs cannot read these (kubectl and co. still can)
    .permissions.deny = ((.permissions.deny // []) + [
      "Read(//**/.env)", "Read(//**/.env.local)", "Read(//**/.env.*.local)",
      "Read(//**/.env.production)", "Read(//**/.env.prod)",
      "Read(//**/*.pem)", "Read(//**/*.p12)", "Read(//**/id_rsa*)", "Read(//**/id_ed25519*)",
      "Read(~/.ssh/**)", "Read(~/.aws/**)", "Read(~/.config/gcloud/**)", "Read(~/.kube/**)",
      "Read(~/.docker/config.json)", "Read(~/.netrc)", "Read(~/.config/gh/hosts.yml)",
      "Read(~/.local/share/atuin/key)", "Read(~/.claude.json)",
      "Read(~/Library/Application Support/doctl/**)", "Read(~/.config/doctl/**)",
      "Read(~/.config/sops/age/**)", "Bash(sops -d *)", "Bash(sops --decrypt *)",
      "Bash(sops decrypt *)", "Bash(age-keygen -y *)"
    ] | unique) |
    # read-only gcloud/doctl runs without a prompt; deploy/delete/update still ask
    .permissions.allow = ((.permissions.allow // []) + [
      "Bash(gcloud * list)", "Bash(gcloud * list *)",
      "Bash(gcloud * describe *)", "Bash(gcloud logging read *)",
      "Bash(gcloud config list)", "Bash(gcloud config get *)",
      "Bash(gcloud config configurations list)", "Bash(gcloud auth list)",
      "Bash(doctl * list)", "Bash(doctl * list *)", "Bash(doctl * get *)",
      "Bash(doctl auth list)", "Bash(doctl apps logs *)"
    ] | unique) |
    .statusLine = {type: "command", command: ($s + "/statusline.sh"), padding: 0}
    | .hooks = (.hooks // {}) + {
        UserPromptSubmit: [{hooks: [cmd("state.sh working")]}],
        PostToolUse: [
          {hooks: [cmd("state.sh working")]},
          # format what Claude edited with the project formatter
          {matcher: "Edit|Write|MultiEdit", hooks: [{type: "command", command: ($ENV.HOME + "/.claude/hooks/format.sh"), timeout: 30}]}
        ],
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

# Claude Code plugins: LSPs stay on everywhere (~0 tokens, start only on
# matching files); the rest are installed but OFF by default, since each one
# costs context in every session. Turn them on per project with `ccp plugin`.
# Servers: gopls (mise run install-go-tools), typescript-language-server (mise).
install_claude_plugins() {
  if ! command -v claude >/dev/null 2>&1; then
    print -u2 "skip claude plugins: claude is not installed"
    return
  fi

  local plugin
  local -a always=(gopls-lsp typescript-lsp lua-lsp)
  local -a opt_in=(superpowers figma frontend-design context7)
  for plugin in $always $opt_in; do
    claude plugin install "$plugin@claude-plugins-official" >/dev/null 2>&1 \
      && print "claude plugin -> $plugin" \
      || print -u2 "skip claude plugin $plugin: install failed"
  done

  # install enables; switch the opt-in ones back off at user level
  local settings="$HOME/.claude/settings.json" tmp
  [[ -f "$settings" ]] && command -v jq >/dev/null 2>&1 || return
  tmp="$(mktemp)"
  # --args turns every later word into $ARGS, so the file goes in on stdin
  if jq --args '.enabledPlugins |= reduce $ARGS.positional[] as $p (. // {}; .[$p + "@claude-plugins-official"] = false)' \
    $opt_in <"$settings" >"$tmp"; then
    mv "$tmp" "$settings"
    print "claude plugins off by default: ${(j:, :)opt_in}"
  else
    rm -f "$tmp"
  fi
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
  # delete local branches whose PRs are merged: gh poi
  gh extension list | grep -q 'seachicken/gh-poi' || gh extension install seachicken/gh-poi
}

# beta + log-streaming: `gcloud beta run services logs tail` (crtail)
install_gcloud_components() {
  if ! command -v gcloud >/dev/null 2>&1; then
    print -u2 "skip gcloud components: gcloud is not installed"
    return
  fi
  gcloud components install beta log-streaming --quiet >/dev/null 2>&1 \
    && print "gcloud components -> beta log-streaming" \
    || print -u2 "skip gcloud components: install failed"
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
link "$dotfiles_dir/atuin/.config/atuin/themes" "$HOME/.config/atuin/themes"
link "$dotfiles_dir/yazi/.config/yazi/theme.toml" "$HOME/.config/yazi/theme.toml"
link "$dotfiles_dir/k9s/.config/k9s/config.yaml" "$HOME/.config/k9s/config.yaml"
link "$dotfiles_dir/k9s/.config/k9s/plugins.yaml" "$HOME/.config/k9s/plugins.yaml"
link "$dotfiles_dir/k9s/.config/k9s/skins/tokyonight.yaml" "$HOME/.config/k9s/skins/tokyonight.yaml"
link "$dotfiles_dir/lazydocker/.config/lazydocker/config.yml" "$HOME/.config/lazydocker/config.yml"
link "$dotfiles_dir/btop/.config/btop/btop.conf" "$HOME/.config/btop/btop.conf"
link "$dotfiles_dir/vale/.config/vale/.vale.ini" "$HOME/.config/vale/.vale.ini"
link "$dotfiles_dir/bat/.config/bat" "$HOME/.config/bat"
link "$dotfiles_dir/eza/.config/eza" "$HOME/.config/eza"
link "$dotfiles_dir/tmux/claude-usage" "$HOME/.tmux/claude-usage"
link "$dotfiles_dir/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
link "$dotfiles_dir/claude/commands" "$HOME/.claude/commands"
link "$dotfiles_dir/claude/agents" "$HOME/.claude/agents"
link "$dotfiles_dir/claude/hooks" "$HOME/.claude/hooks"
link "$dotfiles_dir/claude/bin/ccp" "$HOME/.local/bin/ccp"
link "$dotfiles_dir/golang/bin/gprof" "$HOME/.local/bin/gprof"
link "$dotfiles_dir/golang/bin/gbench" "$HOME/.local/bin/gbench"
link "$dotfiles_dir/golang/bin/dlvk" "$HOME/.local/bin/dlvk"
link "$dotfiles_dir/diagrams/bin/diag" "$HOME/.local/bin/diag"
link "$dotfiles_dir/tmux/scripts" "$HOME/.tmux/scripts"
link "$dotfiles_dir/sesh/.config/sesh/sesh.toml" "$HOME/.config/sesh/sesh.toml"
link "$dotfiles_dir/direnv/.config/direnv/direnv.toml" "$HOME/.config/direnv/direnv.toml"
link "$dotfiles_dir/direnv/.config/direnv/lib" "$HOME/.config/direnv/lib"
link "$dotfiles_dir/lnav/formats" "$HOME/.config/lnav/formats/dotfiles"
link "$dotfiles_dir/navi/cheats" "$HOME/.local/share/navi/cheats/dotfiles"
link "$dotfiles_dir/ghostty/.config/ghostty/config" "$HOME/.config/ghostty/config"
link "$dotfiles_dir/ghostty/.config/ghostty/shaders" "$HOME/.config/ghostty/shaders"
link "$dotfiles_dir/ghostty/.config/ghostty/themes/Tokyo Night" "$HOME/.config/ghostty/themes/Tokyo Night"

configure_claude_settings
install_brew_packages
install_claude_plugins
build_bat_cache
install_gh_extensions
configure_notifier_icon
install_gcloud_components
install_tmux_plugins
