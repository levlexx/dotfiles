local ok, alpha = pcall(require, "alpha")
if not ok then
  return
end

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
  dashboard.button("f", "  Find files", "<cmd>lua require('fzf-lua').files()<cr>"),
  dashboard.button("r", "󰋚  Recent files", "<cmd>lua require('fzf-lua').oldfiles()<cr>"),
  dashboard.button("p", "󰉋  Projects", "<cmd>lua require('fzf-lua').files({ cwd = vim.fn.expand('~/Projects') })<cr>"),
  dashboard.button("g", "  Git files", "<cmd>lua require('fzf-lua').git_files()<cr>"),
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

alpha.setup(dashboard.config)
