# Dotfiles

Personal macOS setup: zsh + tmux + Neovim (native `vim.pack`) + Ghostty,
Tokyo Night everywhere. Tools come from Homebrew and mise; files are linked
by `bootstrap.sh` (plain symlinks, no stow).

## Bootstrap

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
./bootstrap.sh          # symlinks + brew bundle + tmux plugins
mise install
mise run install-go-tools
mise run install-js-debug-adapter
mise run doctor
```

Machine-specific git identity goes in `~/.gitconfig.local`.

## How to use it

### Shell (zsh)

| Key / command | Action |
| --- | --- |
| `Ctrl-R` | Atuin fuzzy history search |
| `Ctrl-T` | fzf file picker |
| `Alt-C` | fzf cd into directory |
| `Ctrl-G` | navi command cheatsheets |
| `Tab` | fzf-tab completion menu |
| `z <dir>` | zoxide jump |
| `ll` / `lt` | eza list / tree |
| `lg` | lazygit |
| `ld` | lazydocker |
| `cw <name>` | Claude in an isolated git worktree |
| `btop` | system resource monitor |
| `v` | nvim |
| `y` | yazi file manager |
| `g`, `gst`, `gd`, `gpl`, `gpu`, … | git aliases (see `.zshrc`) |

New terminals attach to the `main` tmux session automatically.

### tmux (prefix `Ctrl-a`)

| Key | Action |
| --- | --- |
| `prefix Space` | **which-key action menu (start here)** |
| `prefix \|` / `prefix -` | split right / below |
| `prefix h/j/k/l` | move between panes (`Ctrl-h/j/k/l` works without prefix) |
| `prefix H/J/K/L` | resize pane |
| `prefix c` / `n` / `p` / `Tab` | new / next / previous / last window |
| `prefix m` | zoom pane |
| `prefix y` | cycle layouts |
| `prefix Enter` | copy mode (vi keys, `y` → clipboard) |
| `prefix x` / `X` | kill pane / window |
| `prefix r` | reload config |
| `prefix o` | sesh session picker (sessions, pinned, zoxide dirs) |
| `prefix g` | lazygit popup |
| `prefix t` | scratch shell popup (same key hides it) |
| `prefix A` | Claude in a split on the right |
| `prefix W` | Claude in a new git worktree, own window |
| `prefix F` | fingers: copy hashes / paths / URLs by hint |
| `prefix a` / `S` | last window / last session |

Sessions persist and auto-restore (resurrect + continuum).

### Neovim (leader = `Space`)

| Key | Action |
| --- | --- |
| `Space Space` | find files |
| `Space /` | live grep |
| `-` | edit parent directory (oil.nvim — rename/delete files like text) |
| `Space e` | floating explorer |
| `Space ?` | which-key: all buffer keymaps |
| `gd` / `gr` / `K` | LSP definition / references / hover |
| `Space ca` / `Space cr` | code action / rename |
| `Space cf` | format |
| `Space gg` | lazygit |
| `]d` `[d` `]h` `[h` | next/prev diagnostic, git hunk |
| `Space Rs` | send HTTP request in `.http` files (kulala) |

Leader groups (which-key pops up after `Space`): `f` find · `g` git ·
`c` code · `b` buffers · `w` windows · `t` terminal · `x` diagnostics ·
`R` REST · `D` database · `d` debug · `n` nx · `a` AI agents · `u` UI ·
`q` quit. Full reference: [nvim/.config/nvim/README.md](nvim/.config/nvim/README.md).

### Git hooks (global, all repos)

- `pre-commit`: [typos](https://github.com/crate-ci/typos) spell-checks staged files
- `commit-msg`: strips AI attribution trailers, enforces
  [conventional commits](https://www.conventionalcommits.org) via commitlint
- Repos with their own hooks (husky/lefthook) are unaffected; local hooks are
  chained after the global ones. Bypass anything with `git commit --no-verify`.

### Prose

- markdown/gitcommit buffers get harper-ls grammar checks + `spell`
  (`]s` next typo, `z=` suggestions)
- projects with a `.vale.ini` also get vale style linting

## Tooling

- Go and Node runtimes, LSP servers, and CLI dev tools are managed by mise —
  not Homebrew (`mise/.config/mise/config.toml`).
- Neovim uses native `vim.pack` and `vim.lsp.config` — no lazy.nvim, no Mason.
- tmux plugins are installed by `bootstrap.sh` through TPM.

## Managed links

| Link | Source |
| --- | --- |
| `~/.zshrc`, `~/.tmux.conf`, `~/.gitconfig` | `zsh/`, `tmux/`, `git/` |
| `~/.config/git/ignore`, `~/.config/git/hooks/*` | `git/` |
| `~/.config/nvim` | `nvim/` |
| `~/.config/mise/config.toml` | `mise/` |
| `~/.config/starship.toml`, `~/.config/lazygit` | `starship/`, `lazygit/` |
| `~/.config/atuin/config.toml` | `atuin/` |
| `~/.config/btop/btop.conf` | `btop/` |
| `~/.config/ghostty/*` | `ghostty/` |
| `~/.config/vale/.vale.ini` | `vale/` |
| `~/.config/commitlint/commitlint.config.mjs` | `commitlint/` |
| `~/.dockerignore` | `docker/` |
