local M = {}
local configured = false
local dashboard_config

local function gh(repo)
  return "https://github.com/" .. repo
end

local function setup()
  vim.pack.add({
    { src = gh("goolord/alpha-nvim") },
  }, {
    confirm = false,
    load = true,
  })

  local ok, alpha = pcall(require, "alpha")
  if not ok then
    vim.notify("alpha-nvim is not available", vim.log.levels.WARN)
    return
  end

  if configured then
    return alpha
  end
  configured = true

  local dashboard = require("alpha.themes.dashboard")

  dashboard.section.header.val = {
    "",
    "   ██████╗ ██╗   ██╗██╗███╗   ███╗",
    "   ██╔══██╗██║   ██║██║████╗ ████║",
    "   ██║  ██║██║   ██║██║██╔████╔██║",
    "   ██║  ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
    "   ██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
    "   ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
    "",
  }
  dashboard.section.header.opts.hl = "NvimDashboardHeader"

  dashboard.section.buttons.val = {
    dashboard.button("f", "  Find files", "<cmd>lua require('plugins.fzf').run('files')<cr>"),
    dashboard.button("r", "󰋚  Recent files", "<cmd>lua require('plugins.fzf').run('oldfiles')<cr>"),
    dashboard.button("p", "󰉋  Projects", "<cmd>lua require('plugins.fzf').run('files', { cwd = vim.fn.expand('~/Projects') })<cr>"),
    dashboard.button("g", "  Git files", "<cmd>lua require('plugins.fzf').run('git_files')<cr>"),
    dashboard.button("s", "󰦛  Restore session", "<cmd>if filereadable('Session.vim') | source Session.vim | else echo 'No Session.vim' | endif<cr>"),
    dashboard.button("e", "󰙅  Explorer", "<cmd>lua require('plugins.explorer').toggle()<cr>"),
    dashboard.button("q", "󰅚  Quit", "<cmd>qa<cr>"),
  }
  for _, button in ipairs(dashboard.section.buttons.val) do
    button.opts.hl = "NvimDashboardButton"
    button.opts.hl_shortcut = "NvimDashboardShortcut"
  end

  dashboard.section.footer.val = "Build · Neovim 0.12 · vim.pack · Go-first"
  dashboard.section.footer.opts.hl = "NvimDashboardFooter"
  dashboard.config.opts = vim.tbl_extend("force", dashboard.config.opts or {}, { autostart = false })
  dashboard_config = dashboard.config

  alpha.setup(dashboard_config)
  return alpha
end

function M.open()
  local alpha = setup()
  if alpha ~= nil then
    alpha.start(false, dashboard_config)
  end
end

vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("UserDashboard", { clear = true }),
  callback = function()
    if vim.fn.argc() == 0 and vim.api.nvim_buf_get_name(0) == "" and vim.bo.buftype == "" then
      M.open()
    end
  end,
})

return M
