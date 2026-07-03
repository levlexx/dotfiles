# Design: nvim workflow, LSP fix, cheatsheets, prose stack, git hooks

Date: 2026-07-03
Status: approved

## Problem

1. angularls crashes on startup in every Angular project (exit 1). Root cause
   confirmed from `~/.local/state/nvim/lsp.log`: lspconfig's default probe
   locations assume an npm-global layout; with mise shims they resolve to
   garbage paths, so `@angular/language-service` is never found. Symptoms:
   eternal "initializing" fidget popup, no template intellisense, lag from
   restart noise. vtsls itself is healthy (ready in ~1s in project-a/client).
2. neo-tree is heavy (drags in plenary + nui) and slower than needed.
3. No HTTP client, no discoverable cheatsheets (nvim partially via which-key,
   tmux none, shell none), no prose linting, no commit hygiene enforcement.
4. Root README is stale; nvim README documents neo-tree.

## Design

### 1. Fix angularls (`nvim/lua/plugins/lsp.lua`)

Override `cmd` with `--tsProbeLocations`/`--ngProbeLocations` set to:
`<cwd>/node_modules,<mise-install>/lib/node_modules/@angular/language-server/node_modules`

- mise install dir resolved by glob over
  `~/.local/share/mise/installs/npm-angular-language-server/*/...`
  (survives version upgrades; latest match wins).
- Project `node_modules` probed first so a project-local
  `@angular/language-service` (version-matched to the project) wins over the
  global 22.0.4 — mitigates the historical `ngtypecheck.ts` crash too.
- If the glob matches nothing, do not override `cmd` (keep lspconfig default).
- Verified: the mise install's probe dir contains both
  `@angular/language-service` and `typescript`.

### 2. neo-tree → oil.nvim (rewrite `nvim/lua/plugins/explorer.lua`)

- `oil.nvim` with `default_file_explorer = true`; hide git-ignored heavy dirs
  (`node_modules`, `.angular`, `.nx`, `dist`, ...); mini.icons auto-detected.
- Keymaps: `-` open parent dir; `<leader>e` float toggle at current file;
  `<leader>fE` oil at cwd. `<leader>fe` removed (same as `-` in oil's model).
- Remove neo-tree, plenary, nui (nothing else uses them). One-time
  `vim.pack.del` cleanup.

### 3. kulala.nvim (new `nvim/lua/plugins/http.lua`)

- Pinned `version = vim.version.range("5")`; `http` treesitter parser added.
- `<leader>R` group (REST): send request, send all, replay last, pick env,
  toggle response view. Registered in which-key.

### 4. which-key tuning (`nvim/lua/plugins/which-key.lua`)

- `delay = 200` (0 for plugin views), `expand = 1`, add `<leader>R` group.

### 5. tmux-which-key (`.tmux.conf`)

- TPM plugin `alexwforsythe/tmux-which-key`; `prefix+Space` opens action menu.
- `next-layout` moves from `prefix+Space` to `prefix+y`.

### 6. navi (shell cheatsheet)

- Brewfile + `.zshrc` widget (`eval "$(navi widget zsh)"`, guarded) → Ctrl-G.

### 7. Prose stack

- harper-ls (mise/aqua, brew fallback) LSP for `markdown`, `gitcommit` only.
- Built-in spell: autocmd sets `spell`, `spelllang=en_us` for those filetypes.
- vale + vale-ls installed; `vale_ls` attaches only in projects with a
  `.vale.ini` (its root marker). Starter config at `~/.config/vale/.vale.ini`.

### 8. Git hooks: typos + commitlint (global, chaining)

- `core.hooksPath = ~/.config/git/hooks` (new `git/.config/git/hooks/`).
- `pre-commit`: `typos` on staged files, then chain to repo's own hook.
- `commit-msg`: strip AI attribution trailers (Co-Authored-By for AI agents,
  "Generated with" lines) from any AI tool, then commitlint (conventional
  rules), then chain.
- Chaining via `git rev-parse --git-path hooks`; husky/lefthook repos
  unaffected (local core.hooksPath wins); `--no-verify` escapes.
- commitlint conventional rules written inline in
  `~/.config/commitlint/commitlint.config.mjs` (avoids npm `extends`
  resolution failure with mise's isolated installs). Verify at implementation.
- mise: `npm:@commitlint/cli`, `aqua:crate-ci/typos` (verify aqua ids).
- bootstrap.sh links the new hook/config files.

### 9. README rewrite

- Root `README.md` from scratch: what/bootstrap/short "how to use" keybinding
  tables per tool (zsh keys incl. Ctrl-R/Ctrl-T/Ctrl-G, tmux prefix table +
  which-key menu, nvim leader groups + core keys, git hooks behavior).
- nvim README: replace neo-tree sections with oil, add kulala + prose stack.

## Verification

- Headless nvim: config loads clean; oil/kulala/harper configs load.
- Regression test: angularls attaches AND reaches `initialized` in
  `~/Projects/project-a/client`.
- tmux: config loads on a scratch server; TPM plugin installs.
- Hooks: fixture repo — bad commit message rejected, good accepted; staged
  typo rejected; chaining to a local hook works; `--no-verify` bypasses.
- zsh: `zsh -n` + interactive smoke test (navi widget bound).

## Out of scope

- project-b/frontend has no node_modules — LSP can't work there until
  `npm install` (user action).
- Per-project vale style packages (`vale sync`) — user configures per docs
  project.
