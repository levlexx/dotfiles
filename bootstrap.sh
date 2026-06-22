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
    print -u2 "skip existing non-symlink: $target"
  else
    ln -s "$source" "$target"
    print "linked $target"
  fi
}

install_tmux_plugins() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"

  if [[ ! -d "$tpm_dir/.git" ]]; then
    mkdir -p "${tpm_dir:h}"
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi

  tmux start-server \; source-file "$HOME/.tmux.conf"
  "$tpm_dir/bin/install_plugins"
}

link "$dotfiles_dir/zsh/.zshrc" "$HOME/.zshrc"
link "$dotfiles_dir/tmux/.tmux.conf" "$HOME/.tmux.conf"
link "$dotfiles_dir/git/.gitconfig" "$HOME/.gitconfig"
link "$dotfiles_dir/git/.config/git/ignore" "$HOME/.config/git/ignore"
link "$dotfiles_dir/docker/.dockerignore" "$HOME/.dockerignore"
link "$dotfiles_dir/mise/.config/mise/config.toml" "$HOME/.config/mise/config.toml"
link "$dotfiles_dir/nvim/.config/nvim" "$HOME/.config/nvim"
link "$dotfiles_dir/starship/.config/starship.toml" "$HOME/.config/starship.toml"
link "$dotfiles_dir/lazygit/.config/lazygit" "$HOME/.config/lazygit"
link "$dotfiles_dir/atuin/.config/atuin/config.toml" "$HOME/.config/atuin/config.toml"
link "$dotfiles_dir/ghostty/.config/ghostty/config.ghostty" "$HOME/.config/ghostty/config.ghostty"

install_tmux_plugins
