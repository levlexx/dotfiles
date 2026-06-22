# Neovim

Minimal Neovim 0.12+ configuration using `vim.pack`.

## UI

| Feature | Implementation |
| --- | --- |
| Explorer | `neo-tree.nvim` |
| Statusline | `mini.statusline` |
| Dashboard | `alpha.nvim` |
| Notifications | `fidget.nvim` |
| Buffer tabs | intentionally omitted |

Explorer keys:

| Key | Action |
| --- | --- |
| `<leader>e` | Toggle explorer and reveal current file |
| `<leader>fe` | Reveal current file in explorer |
| `<leader>fE` | Open explorer at cwd |

Neo-tree file operations:

| Key | Action |
| --- | --- |
| `a` | Add file or directory |
| `r` | Rename |
| `m` | Move |
| `d` | Delete |
| `y` | Copy to clipboard |
| `p` | Paste from clipboard |
| `R` | Refresh |

## Keybindings

`<leader>` is `Space`.

| Group | Purpose |
| --- | --- |
| `<leader>f` | Find / search |
| `<leader>g` | Git |
| `<leader>c` | Code / LSP |
| `<leader>b` | Buffers |
| `<leader>w` | Windows |
| `<leader>t` | Terminal / tests |
| `<leader>x` | Diagnostics / quickfix |
| `<leader>q` | Quit / session |
| `<leader>u` | UI toggles |
| `<leader>a` | AI / agents |
| `<leader>d` | Debug |

### Find / Search

| Key | Action |
| --- | --- |
| `<leader><space>` | Find files |
| `<leader>/` | Live grep |
| `<leader>e` | Explorer |
| `<leader>fe` | Reveal file in explorer |
| `<leader>fE` | Explorer cwd |
| `<leader>ff` | Find files |
| `<leader>fg` | Find git files |
| `<leader>fl` | Live grep |
| `<leader>fw` | Find word or visual selection |
| `<leader>fr` | Recent files |
| `<leader>ft` | Find TODO/FIXME |
| `<leader>fk` | Find keymaps |
| `<leader>fh` | Find help |
| `<leader>fc` | Find config files |

### Git

| Key | Action |
| --- | --- |
| `<leader>gg` | Lazygit |
| `<leader>gs` | Git status |
| `<leader>gc` | Git commits |
| `<leader>gf` | Current file history |
| `<leader>gb` | Blame line |
| `]h` / `[h` | Next / previous hunk |
| `<leader>ghp` | Preview hunk |
| `<leader>ghr` | Reset hunk |
| `<leader>ghs` | Stage hunk |

### Nx

| Key | Action |
| --- | --- |
| `<leader>nx` | Nx actions |
| `<leader>nr` | Nx run many |
| `<leader>na` | Nx affected |
| `<leader>ng` | Nx generators |

### Code / LSP

| Key | Action |
| --- | --- |
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gI` | Go to implementation |
| `gy` | Go to type definition |
| `gr` | References |
| `K` | Hover |
| `gK` | Signature help |
| `<leader>ca` | Code action |
| `<leader>cr` | Rename |
| `<leader>cs` | Document symbols |
| `<leader>cS` | Workspace symbols |
| `<leader>cf` | Format |

### Diagnostics

| Key | Action |
| --- | --- |
| `]d` / `[d` | Next / previous diagnostic |
| `]e` / `[e` | Next / previous error |
| `]w` / `[w` | Next / previous warning |
| `<leader>xd` | Line diagnostic |
| `<leader>xx` | Document diagnostics |
| `<leader>xX` | Workspace diagnostics |
| `<leader>xl` | Toggle location list |
| `<leader>xq` | Toggle quickfix |

### Buffers / Windows / Terminal

| Key | Action |
| --- | --- |
| `<leader>,` | Find buffers |
| `<leader>bb` | Find buffers |
| `<leader>ba` | Alternate buffer |
| `<leader>bd` | Delete buffer |
| `<leader>bo` | Delete other buffers |
| `<leader>ws` | Split below |
| `<leader>wv` | Split right |
| `<leader>wd` | Delete window |
| `<leader>tt` | Terminal |
| `<leader>tv` | Vertical terminal |
| `<leader>tg` | `go test ./...` |
| `<leader>qS` | Save `Session.vim` |
| `<leader>qs` | Restore `Session.vim` |

### UI / Agents

| Key | Action |
| --- | --- |
| `<leader>uC` | Colorschemes |
| `<leader>uD` | Dashboard |
| `<leader>uh` | Toggle inlay hints |
| `<leader>uw` | Toggle wrap |
| `<leader>ul` | Toggle line numbers |
| `<leader>uL` | Toggle relative numbers |
| `<leader>ao` | OpenCode |
| `<leader>ac` | Claude Code |
| `<leader>ag` | Gemini CLI |

Use `<leader>?` to show buffer-local keymaps and `<C-w><space>` for window key discovery.

## Tooling

Runtime and editor tools are managed by mise. Install/update the configured Node, Go, LSP, and formatter tools with:

```sh
mise install
```

That includes:

```text
biome
prettier
stylua
lua-language-server
vtsls
tsp
tsp-server
tree-sitter
vscode-json-language-server
yaml-language-server
docker-langserver
docker-compose-langserver
```

Go command-line tools are installed separately into `~/go/bin` with the mise-managed Go runtime:

```sh
mise run install-go-tools
```

That task installs these tools with the mise-managed Go runtime into `~/go/bin`:

```text
gopls
goimports
gofumpt
staticcheck
dlv
govulncheck
golangci-lint
```

Validate the active runtime and tool versions with:

```sh
mise run doctor
```

Neovim Go support uses:

| Feature | Tool |
| --- | --- |
| LSP | `gopls` |
| Formatting | `goimports`, then `gofumpt` via `conform.nvim` |
| Diagnostics | `gopls` |
| Full linting | `golangci-lint run ./...` from CLI/CI |
| Vulnerability scan | `govulncheck ./...` |
| Debugging | `dlv` through `nvim-dap` |

`gopls` is configured with `gofumpt = true`, selected analyses, `staticcheck = false`, and `vulncheck = "Prompt"`. This keeps editor feedback fast and leaves heavier linting to `golangci-lint`.

No project template directory currently exists in this dotfiles repo, so Go project templates are not included here.

## Debugging

Debugging uses `nvim-dap`, `nvim-dap-ui`, and `nvim-dap-virtual-text`.

Go uses manual Delve setup. Mason is not required.

| Key | Action |
| --- | --- |
| `<leader>db` | Toggle breakpoint |
| `<leader>dB` | Conditional breakpoint |
| `<leader>dc` | Continue |
| `<leader>di` | Step into |
| `<leader>do` | Step over |
| `<leader>dO` | Step out |
| `<leader>dr` | Open DAP REPL |
| `<leader>dl` | Run last debug session |
| `<leader>dt` | Debug nearest Go test |
| `<leader>du` | Toggle DAP UI |
| `<leader>df` | Debug current file |
| `<leader>dp` | Debug Go package tests |
| `<leader>da` | Attach to running Go process |
| `<leader>ds` | Debug Go service with env vars |
| `<leader>dC` | Debug Cloud Run-like local process |
| `<leader>dv` | Floating variable preview |
| `<leader>dx` | Terminate debug session |

### Go

Supported configurations:

| Config | Use |
| --- | --- |
| Debug current file | Debug current Go file/main package |
| Debug package | Debug current package/module |
| Debug package tests | Run package tests under Delve |
| Attach to running process | Pick a local process |
| Attach remote Delve `:38697` | Attach to `dlv dap -l 127.0.0.1:38697` |
| Debug Go service with env vars | Loads `.env`, `.env.local`, `.env.debug` |
| Debug Cloud Run-like local process | Adds `PORT`, `K_SERVICE`, `K_REVISION`, `K_CONFIGURATION` defaults |

Env files are read from the current working directory in this order:

```text
.env
.env.local
.env.debug
```

Later files override earlier values.

### TypeScript / Angular

TypeScript and Angular debugging uses Microsoft's JS debug adapter. Install/update it with:

```sh
mise run install-js-debug-adapter
```

Supported configurations:

| Config | Use |
| --- | --- |
| Debug current TS/JS file | Launch current file with Node |
| Attach to Node process | Pick running Node process |
| Debug Angular app at localhost:4200 | Launch Chrome against Angular dev server |
| Attach Chrome remote debug `:9222` | Attach to existing Chrome debugging session |

Adapter lookup order:

```text
$JS_DEBUG_ADAPTER
~/.local/share/vscode-js-debug/dist/src/dapDebugServer.js
~/.local/share/js-debug/src/dapDebugServer.js
~/.local/share/vscode-js-debug/src/dapDebugServer.js
stdpath('data')/vscode-js-debug/dist/src/dapDebugServer.js
stdpath('data')/js-debug/src/dapDebugServer.js
stdpath('data')/vscode-js-debug/src/dapDebugServer.js
```

For Angular, start the app separately:

```sh
ng serve
```

Then run `Debug Angular app at localhost:4200` from DAP.

### Troubleshooting

| Problem | Fix |
| --- | --- |
| `Delve is not installed or not on PATH` | Install Delve and ensure `dlv` is on `PATH` |
| Breakpoints do not bind in Go | Run from module root and ensure package builds |
| Nearest Go test not found | Put cursor inside or below `func TestXxx(...)` |
| Env vars missing | Create `.env.debug` in project root or export vars before launching Neovim |
| JS debug adapter not found | Run `mise run install-js-debug-adapter` |
| Angular debugger opens but breakpoints do not bind | Check `webRoot`, source maps, and that `ng serve` is running |
| Chrome attach fails | Start Chrome with `--remote-debugging-port=9222` |
