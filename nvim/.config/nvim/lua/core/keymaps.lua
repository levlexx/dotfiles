local map = vim.keymap.set

local function fzf(command, opts)
  return function()
    require("plugins.fzf").run(command, opts)
  end
end

local function toggle_quickfix()
  local ok, info = pcall(vim.fn.getqflist, { winid = 0 })
  if ok and info.winid ~= 0 then
    vim.cmd.cclose()
  else
    vim.cmd.copen()
  end
end

local function toggle_loclist()
  local ok, info = pcall(vim.fn.getloclist, 0, { winid = 0 })
  if ok and info.winid ~= 0 then
    vim.cmd.lclose()
  else
    pcall(vim.cmd.lopen)
  end
end

local function delete_other_buffers()
  local current = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= current and vim.bo[buf].buflisted then
      pcall(vim.cmd.bdelete, buf)
    end
  end
end

local function terminal(command, vertical)
  if vertical then
    vim.cmd.vsplit()
  else
    vim.cmd.split()
  end
  vim.cmd.enew()
  vim.fn.termopen(command)
  vim.cmd.startinsert()
end

local function agent(command)
  return function()
    if vim.fn.executable(command) == 0 then
      vim.notify(command .. " is not installed", vim.log.levels.WARN)
      return
    end
    terminal(command, true)
  end
end

local function diagnostic_goto(count, severity)
  return function()
    vim.diagnostic.jump({
      count = count,
      severity = severity,
      float = true,
    })
  end
end

local function toggle_inlay_hints()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
end

local function save_session()
  vim.cmd("mksession! Session.vim")
  vim.notify("Saved Session.vim")
end

local function restore_session()
  if vim.fn.filereadable("Session.vim") == 0 then
    vim.notify("No Session.vim in current directory", vim.log.levels.WARN)
    return
  end
  vim.cmd("source Session.vim")
end

-- Core editing ---------------------------------------------------------------
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
map({ "i", "n", "s", "x" }, "<C-s>", "<cmd>write<cr><esc>", { desc = "Save file" })
map("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

map("n", "<A-j>", "<cmd>move .+1<cr>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>move .-2<cr>==", { desc = "Move line up" })
map("v", "<A-j>", ":move '>+1<cr>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":move '<-2<cr>gv=gv", { desc = "Move selection up" })
map("x", "<", "<gv", { desc = "Indent left" })
map("x", ">", ">gv", { desc = "Indent right" })

-- Find / search --------------------------------------------------------------
map("n", "<leader><space>", fzf("files"), { desc = "Find files" })
map("n", "<leader>/", fzf("live_grep"), { desc = "Live grep" })
map("n", "<leader>e", function()
  require("plugins.explorer").toggle()
end, { desc = "Explorer" })
map("n", "<leader>fb", fzf("buffers"), { desc = "Find buffers" })
map("n", "<leader>fc", fzf("files", { cwd = vim.fn.stdpath("config") }), { desc = "Find config files" })
map("n", "<leader>fe", function()
  require("plugins.explorer").reveal()
end, { desc = "Reveal file in explorer" })
map("n", "<leader>fE", function()
  require("plugins.explorer").cwd()
end, { desc = "Explorer cwd" })
map("n", "<leader>ff", fzf("files"), { desc = "Find files" })
map("n", "<leader>fg", fzf("git_files"), { desc = "Find git files" })
map("n", "<leader>fh", fzf("help_tags"), { desc = "Find help" })
map("n", "<leader>fk", fzf("keymaps"), { desc = "Find keymaps" })
map("n", "<leader>fl", fzf("live_grep"), { desc = "Live grep" })
map("n", "<leader>fr", fzf("oldfiles"), { desc = "Recent files" })
map("n", "<leader>ft", function()
  require("plugins.fzf").run("live_grep", { search = "TODO|FIXME|FIX" })
end, { desc = "Find TODO/FIXME" })
map("n", "<leader>fw", fzf("grep_cword"), { desc = "Find word under cursor" })
map("x", "<leader>fw", fzf("grep_visual"), { desc = "Find selection" })

-- Git ------------------------------------------------------------------------
map("n", "<leader>gb", function()
  require("plugins.git").run("blame_line")
end, { desc = "Git blame line" })
map("n", "<leader>gc", fzf("git_commits"), { desc = "Git commits" })
map("n", "<leader>gf", fzf("git_bcommits"), { desc = "Git file history" })
map("n", "]h", function()
  require("plugins.git").run("nav_hunk", "next")
end, { desc = "Next git hunk" })
map("n", "[h", function()
  require("plugins.git").run("nav_hunk", "prev")
end, { desc = "Previous git hunk" })
map("n", "<leader>ghb", function()
  require("plugins.git").run("blame_line")
end, { desc = "Blame line" })
map("n", "<leader>ghp", function()
  require("plugins.git").run("preview_hunk")
end, { desc = "Preview git hunk" })
map("n", "<leader>ghr", function()
  require("plugins.git").run("reset_hunk")
end, { desc = "Reset git hunk" })
map("n", "<leader>ghs", function()
  require("plugins.git").run("stage_hunk")
end, { desc = "Stage git hunk" })
map("n", "<leader>gg", function()
  if vim.fn.executable("lazygit") == 1 then
    terminal("lazygit", true)
  else
    vim.notify("lazygit is not installed", vim.log.levels.WARN)
  end
end, { desc = "Lazygit" })
map("n", "<leader>gs", fzf("git_status"), { desc = "Git status" })

-- Code / LSP -----------------------------------------------------------------
map({ "n", "x" }, "<leader>cf", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format" })
map("n", "<leader>cR", "<cmd>LspRestart<cr>", { desc = "Restart LSP" })
map("n", "<leader>cF", "<cmd>ConformInfo<cr>", { desc = "Formatter info" })
map("n", "<leader>ci", "<cmd>checkhealth lsp<cr>", { desc = "LSP health" })
map("n", "<leader>cl", "<cmd>LspInfo<cr>", { desc = "LSP info" })

-- Buffers --------------------------------------------------------------------
map("n", "<leader>,", fzf("buffers"), { desc = "Find buffers" })
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>ba", "<cmd>buffer #<cr>", { desc = "Alternate buffer" })
map("n", "<leader>bb", fzf("buffers"), { desc = "Find buffers" })
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })
map("n", "<leader>bD", "<cmd>bdelete!<cr>", { desc = "Force delete buffer" })
map("n", "<leader>bn", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>bo", delete_other_buffers, { desc = "Delete other buffers" })
map("n", "<leader>bp", "<cmd>bprevious<cr>", { desc = "Previous buffer" })

-- Windows --------------------------------------------------------------------
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window", remap = true })
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })
map("n", "<leader>w=", "<C-w>=", { desc = "Equalize windows", remap = true })
map("n", "<leader>wd", "<C-w>c", { desc = "Delete window", remap = true })
map("n", "<leader>wh", "<C-w>h", { desc = "Go to left window", remap = true })
map("n", "<leader>wj", "<C-w>j", { desc = "Go to lower window", remap = true })
map("n", "<leader>wk", "<C-w>k", { desc = "Go to upper window", remap = true })
map("n", "<leader>wl", "<C-w>l", { desc = "Go to right window", remap = true })
map("n", "<leader>wo", "<C-w>o", { desc = "Only window", remap = true })
map("n", "<leader>ws", "<C-w>s", { desc = "Split below", remap = true })
map("n", "<leader>wv", "<C-w>v", { desc = "Split right", remap = true })

-- Terminal / tests -----------------------------------------------------------
map("n", "<leader>tg", function()
  terminal("go test ./...")
end, { desc = "Go test ./..." })
map("n", "<leader>tt", function()
  terminal(vim.o.shell)
end, { desc = "Terminal" })
map("n", "<leader>tv", function()
  terminal(vim.o.shell, true)
end, { desc = "Vertical terminal" })

-- Diagnostics / quickfix -----------------------------------------------------
map("n", "]d", diagnostic_goto(1), { desc = "Next diagnostic" })
map("n", "[d", diagnostic_goto(-1), { desc = "Previous diagnostic" })
map("n", "]e", diagnostic_goto(1, vim.diagnostic.severity.ERROR), { desc = "Next error" })
map("n", "[e", diagnostic_goto(-1, vim.diagnostic.severity.ERROR), { desc = "Previous error" })
map("n", "]w", diagnostic_goto(1, vim.diagnostic.severity.WARN), { desc = "Next warning" })
map("n", "[w", diagnostic_goto(-1, vim.diagnostic.severity.WARN), { desc = "Previous warning" })
map("n", "<leader>xd", vim.diagnostic.open_float, { desc = "Line diagnostic" })
map("n", "<leader>xl", toggle_loclist, { desc = "Toggle location list" })
map("n", "<leader>xq", toggle_quickfix, { desc = "Toggle quickfix" })
map("n", "<leader>xx", fzf("diagnostics_document"), { desc = "Document diagnostics" })
map("n", "<leader>xX", fzf("diagnostics_workspace"), { desc = "Workspace diagnostics" })

-- Quit / session -------------------------------------------------------------
map("n", "<leader>qq", "<cmd>quitall<cr>", { desc = "Quit all" })
map("n", "<leader>qQ", "<cmd>quitall!<cr>", { desc = "Force quit all" })
map("n", "<leader>qs", restore_session, { desc = "Restore session" })
map("n", "<leader>qS", save_session, { desc = "Save session" })
map("n", "<leader>qw", "<cmd>wq<cr>", { desc = "Write and quit" })

-- UI toggles -----------------------------------------------------------------
map("n", "<leader>ub", function()
  vim.o.background = vim.o.background == "dark" and "light" or "dark"
end, { desc = "Toggle background" })
map("n", "<leader>uC", fzf("colorschemes"), { desc = "Colorschemes" })
map("n", "<leader>uD", function()
  require("plugins.dashboard").open()
end, { desc = "Dashboard" })
map("n", "<leader>uh", toggle_inlay_hints, { desc = "Toggle inlay hints" })
map("n", "<leader>ul", function()
  vim.wo.number = not vim.wo.number
end, { desc = "Toggle line numbers" })
map("n", "<leader>uL", function()
  vim.wo.relativenumber = not vim.wo.relativenumber
end, { desc = "Toggle relative numbers" })
map("n", "<leader>ur", function()
  vim.cmd.nohlsearch()
  vim.cmd.diffupdate()
  vim.cmd("normal! <C-L>")
end, { desc = "Redraw and clear search" })
map("n", "<leader>uw", function()
  vim.wo.wrap = not vim.wo.wrap
end, { desc = "Toggle wrap" })

-- AI / agents ----------------------------------------------------------------
map("n", "<leader>ac", agent("claude"), { desc = "Claude Code" })
map("n", "<leader>ag", agent("gemini"), { desc = "Gemini CLI" })
map("n", "<leader>ao", agent("opencode"), { desc = "OpenCode" })

-- Discoverability ------------------------------------------------------------
map("n", "<leader>?", function()
  require("which-key").show({ global = false })
end, { desc = "Buffer keymaps" })

map("n", "<C-w><space>", function()
  require("which-key").show({ keys = "<C-w>", loop = true })
end, { desc = "Window keymaps" })
