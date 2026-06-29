vim.loader.enable()

vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("core.options")
require("core.pack")
require("core.keymaps")
require("core.autocmds")

require("plugins.theme")
require("plugins.mini")
require("plugins.explorer")
require("plugins.statusline")
require("plugins.dashboard")
require("plugins.notifications")
require("plugins.which-key")
require("plugins.treesitter")
require("plugins.git")
require("plugins.fzf")
require("plugins.nx")
require("plugins.blink")
require("plugins.lsp")
require("plugins.conform")
require("plugins.debug")
