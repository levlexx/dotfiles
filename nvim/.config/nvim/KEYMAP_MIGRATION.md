# Keymap Migration Notes

This file records the LazyVim keymap audit and the migration into the native `vim.pack` config.

| Mode | Key | Action | Description | Source | Keep/Change/Remove |
| --- | --- | --- | --- | --- | --- |
| n | `<leader>ff` | `fzf-lua.files` | Find files | LazyVim picker | Keep |
| n | `<leader>fg` | `fzf-lua.git_files` | Find git files | LazyVim picker | Keep |
| n | `<leader>fr` | `fzf-lua.oldfiles` | Recent files | LazyVim picker | Keep |
| n | `<leader><space>` | `fzf-lua.files` | Find files | LazyVim picker | Keep |
| n | `<leader>/` | `fzf-lua.live_grep` | Live grep | LazyVim picker | Keep |
| n,x | `<leader>sw` | moved to `<leader>fw` | Find word or selection | LazyVim search | Change |
| n | `<leader>sg` | moved to `<leader>fl` and `<leader>/` | Live grep | LazyVim search | Change |
| n | `<leader>st` | moved to `<leader>ft` | TODO/FIXME search | LazyVim todo-comments | Change |
| n | `<leader>sd` | moved to `<leader>xx` | Document diagnostics | LazyVim picker | Change |
| n | `<leader>sD` | moved to `<leader>xX` | Workspace diagnostics | LazyVim picker | Change |
| n | `<leader>sk` | moved to `<leader>fk` | Keymap search | LazyVim picker | Change |
| n | `<leader>ss` | moved to `<leader>cs` | Document symbols | LazyVim LSP picker | Change |
| n | `<leader>sS` | moved to `<leader>cS` | Workspace symbols | LazyVim LSP picker | Change |
| n | `gd` | native LSP | Go to definition | LazyVim LSP | Keep |
| n | `gD` | native LSP | Go to declaration | LazyVim LSP | Keep |
| n | `gI` | native LSP | Go to implementation | LazyVim LSP | Keep |
| n | `gy` | native LSP | Go to type definition | LazyVim LSP | Keep |
| n | `gr` | `fzf-lua.lsp_references` | References | LazyVim LSP | Keep |
| n,x | `<leader>ca` | native LSP | Code action | LazyVim LSP | Keep |
| n | `<leader>cr` | native LSP | Rename | LazyVim LSP | Keep |
| n,x | `<leader>cf` | `conform.format` | Format | LazyVim format | Keep |
| n | `<leader>cd` | moved to `<leader>xd` | Line diagnostic | LazyVim diagnostic | Change |
| n | `]d` / `[d` | native diagnostic jump | Next / previous diagnostic | LazyVim diagnostic | Keep |
| n | `]e` / `[e` | native diagnostic jump | Next / previous error | LazyVim diagnostic | Keep |
| n | `]w` / `[w` | native diagnostic jump | Next / previous warning | LazyVim diagnostic | Keep |
| n | `<leader>xl` | native loclist | Toggle location list | LazyVim diagnostics | Keep |
| n | `<leader>xq` | native quickfix | Toggle quickfix | LazyVim diagnostics | Keep |
| n | `<leader>gg` | terminal `lazygit` | Lazygit | LazyVim Snacks | Keep |
| n | `<leader>gs` | `fzf-lua.git_status` | Git status | LazyVim picker | Keep |
| n | `<leader>gb` | `gitsigns.blame_line` | Blame line | LazyVim git | Keep |
| n | `<leader>gL` / `<leader>gl` | `fzf-lua.git_commits` via `<leader>gc` | Git log | LazyVim git | Change |
| n | `<leader>hp` / `<leader>hr` / `<leader>hb` | moved to `<leader>gh*` | Git hunk actions | New minimal config | Change |
| n | `<leader>,` | `fzf-lua.buffers` | Buffer picker | LazyVim picker | Keep |
| n | `<leader>bb` | now buffer picker | Buffer picker | LazyVim buffer alternate | Change |
| n | `<leader>bd` | native `bdelete` | Delete buffer | LazyVim buffer delete | Keep |
| n | `<leader>bo` | native loop | Delete other buffers | LazyVim buffer delete | Keep |
| n | `<S-h>` / `<S-l>` | native buffer nav | Previous / next buffer | LazyVim bufferline | Keep |
| n | `<leader>w*` | native window commands | Window operations | LazyVim windows | Keep |
| n | `<leader>t*` | native terminal commands | Terminal / Go tests | LazyVim terminal/test groups | Change |
| n | `<leader>u*` | native toggles | UI toggles | LazyVim Snacks toggles | Change |
| n | `<leader>a*` | external agent terminals | AI / agents | LazyVim AI extras convention | Change |
| n | `<leader>l` | none | Lazy plugin manager | LazyVim | Remove |
| n | `<leader>L` | none | LazyVim changelog | LazyVim | Remove |
| n | `<leader>n` | none | Notification history | LazyVim Snacks | Remove |
| n | `s` / `S` | none | Flash navigation | LazyVim Flash | Remove |
| n | `<leader>sr` | none | GrugFar search/replace | LazyVim GrugFar | Remove |
| n | `<leader>qs` / `<leader>ql` | none | Session restore | LazyVim persistence | Remove |
| n | `<leader><tab>*` | none | Tab management | LazyVim tabs | Remove |
