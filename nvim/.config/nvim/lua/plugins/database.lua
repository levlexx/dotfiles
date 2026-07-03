local function gh(repo)
  return "https://github.com/" .. repo
end

vim.g.db_ui_use_nerd_fonts = 1
vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/dadbod-ui"

vim.pack.add({
  { src = gh("tpope/vim-dadbod") },
  { src = gh("kristijanhusak/vim-dadbod-ui") },
  { src = gh("kristijanhusak/vim-dadbod-completion") },
}, {
  confirm = false,
  load = true,
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("UserDadbodCompletion", { clear = true }),
  pattern = { "sql", "mysql", "plsql" },
  callback = function()
    vim.bo.omnifunc = "vim_dadbod_completion#omni"
  end,
})

local map = vim.keymap.set

map("n", "<leader>Do", "<cmd>DBUI<cr>", { desc = "Open database UI" })
map("n", "<leader>Du", "<cmd>DBUIToggle<cr>", { desc = "Toggle database UI" })
map("n", "<leader>Da", "<cmd>DBUIAddConnection<cr>", { desc = "Add database connection" })
map("n", "<leader>Df", "<cmd>DBUIFindBuffer<cr>", { desc = "Find database buffer" })
