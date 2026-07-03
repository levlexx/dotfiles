local function gh(repo)
  return "https://github.com/" .. repo
end

vim.pack.add({
  { src = gh("folke/todo-comments.nvim"), version = vim.version.range("1") },
}, {
  confirm = false,
  load = true,
})

require("todo-comments").setup({})

local map = vim.keymap.set

map("n", "]t", function()
  require("todo-comments").jump_next()
end, { desc = "Next TODO comment" })
map("n", "[t", function()
  require("todo-comments").jump_prev()
end, { desc = "Previous TODO comment" })
