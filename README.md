# Dotfiles

Personal macOS dotfiles managed with plain symlinks and mise.

## Bootstrap

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
brew bundle --file Brewfile
./bootstrap.sh
mise install
mise run install-go-tools
mise run install-js-debug-adapter
mise run doctor
```

## Tooling

- Go and Node runtimes are managed by mise.
- Go tools are installed into `~/go/bin` using the mise-managed Go runtime.
- Editor LSP and formatter tools are managed by mise, not Homebrew.
- Neovim uses native `vim.pack`, not LazyVim or Mason.
- tmux plugins are installed by `bootstrap.sh` through TPM.

## Managed Links

- `~/.zshrc`
- `~/.tmux.conf`
- `~/.gitconfig`
- `~/.config/git/ignore`
- `~/.dockerignore`
- `~/.config/mise/config.toml`
- `~/.config/nvim`
- `~/.config/starship.toml`
- `~/.config/lazygit`
- `~/.config/atuin/config.toml`
- `~/.config/ghostty/config`
- `~/.config/ghostty/themes/Tokyo Night`

Machine-specific Git identity belongs in `~/.gitconfig.local`.
