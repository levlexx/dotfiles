local nx_ok, nx = pcall(require, "nx")
if not nx_ok then
  return
end

local telescope_ok, telescope = pcall(require, "telescope")
if not telescope_ok then
  return
end

nx.setup({
  nx_cmd_root = "npx nx",
  read_init = false,
})

pcall(telescope.load_extension, "nx")

local function nx_picker(name)
  return function()
    telescope.extensions.nx[name]({})
  end
end

vim.keymap.set("n", "<leader>nx", nx_picker("actions"), { desc = "Nx actions" })
vim.keymap.set("n", "<leader>nr", nx_picker("run_many"), { desc = "Nx run many" })
vim.keymap.set("n", "<leader>na", nx_picker("affected"), { desc = "Nx affected" })
vim.keymap.set("n", "<leader>ng", nx_picker("generators"), { desc = "Nx generators" })
