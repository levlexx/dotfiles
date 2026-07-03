local function gh(repo)
  return "https://github.com/" .. repo
end

vim.pack.add({
  { src = gh("MagicDuck/grug-far.nvim"), version = vim.version.range("1") },
}, {
  confirm = false,
  load = true,
})

local configured = false

local function grug()
  local g = require("grug-far")
  if not configured then
    configured = true
    g.setup({})
  end
  return g
end

local map = vim.keymap.set

map("n", "<leader>fR", function()
  grug().open()
end, { desc = "Find & replace (project)" })
map("x", "<leader>fR", function()
  grug().with_visual_selection()
end, { desc = "Find & replace selection" })
