-- flash.nvim: labelled jumps. `s` belongs to mini.surround (sa/sd/sr), so
-- jumps live on S; f/t/F/T get labels too (flash's char mode).
-- quicker.nvim: editable quickfix (write to apply), > / < expand context.

local function gh(repo)
  return "https://github.com/" .. repo
end

vim.pack.add({
  { src = gh("folke/flash.nvim") },
  { src = gh("stevearc/quicker.nvim") },
}, {
  confirm = false,
  load = true,
})

require("flash").setup({})

require("quicker").setup({
  keys = {
    {
      ">",
      function()
        require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
      end,
      desc = "Expand quickfix context",
    },
    {
      "<",
      function()
        require("quicker").collapse()
      end,
      desc = "Collapse quickfix context",
    },
  },
})

local map = vim.keymap.set

map({ "n", "x", "o" }, "S", function()
  require("flash").jump()
end, { desc = "Flash jump" })
map({ "o", "x" }, "R", function()
  require("flash").treesitter_search()
end, { desc = "Flash treesitter search" })
map("o", "r", function()
  require("flash").remote()
end, { desc = "Flash remote" })
map("n", "<leader>uu", "<cmd>Undotree<cr>", { desc = "Undo tree" })
