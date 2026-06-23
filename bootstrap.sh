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
link "$dotfiles_dir/tmux/.tmux/git-ref" "$HOME/.tmux/git-ref"
link "$dotfiles_dir/git/.gitconfig" "$HOME/.gitconfig"
link "$dotfiles_dir/git/.config/git/ignore" "$HOME/.config/git/ignore"
link "$dotfiles_dir/docker/.dockerignore" "$HOME/.dockerignore"
link "$dotfiles_dir/mise/.config/mise/config.toml" "$HOME/.config/mise/config.toml"
link "$dotfiles_dir/nvim/.config/nvim" "$HOME/.config/nvim"
link "$dotfiles_dir/starship/.config/starship.toml" "$HOME/.config/starship.toml"
link "$dotfiles_dir/lazygit/.config/lazygit" "$HOME/.config/lazygit"
link "$dotfiles_dir/atuin/.config/atuin/config.toml" "$HOME/.config/atuin/config.toml"
link "$dotfiles_dir/ghostty/.config/ghostty/config" "$HOME/.config/ghostty/config"
link "$dotfiles_dir/ghostty/.config/ghostty/themes/Tokyo Night" "$HOME/.config/ghostty/themes/Tokyo Night"

install_tmux_plugins
