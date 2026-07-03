vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local M = {}
local gh = function(repo)
  return "https://github.com/" .. repo
end

vim.pack.add({
  { src = gh("stevearc/oil.nvim"), version = vim.version.range("2") },
}, {
  confirm = false,
  load = true,
})

require("oil").setup({
  default_file_explorer = true,
  skip_confirm_for_simple_edits = true,
  watch_for_changes = true,
  view_options = {
    show_hidden = true,
    is_always_hidden = function(name)
      return name == ".git" or name == ".DS_Store"
    end,
  },
  float = {
    max_width = 0.6,
    max_height = 0.7,
    border = "rounded",
  },
})

function M.parent()
  require("oil").open()
end

function M.toggle_float()
  require("oil").toggle_float()
end

function M.cwd()
  require("oil").open(vim.uv.cwd())
end

return M
