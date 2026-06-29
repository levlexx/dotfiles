local configured = false

local function gh(repo)
  return "https://github.com/" .. repo
end

local function setup()
  vim.pack.add({
    { src = gh("nvim-lua/plenary.nvim") },
    { src = gh("nvim-telescope/telescope.nvim") },
    { src = gh("Equilibris/nx.nvim") },
  }, {
    confirm = false,
    load = true,
  })

  local nx_ok, nx = pcall(require, "nx")
  local telescope_ok, telescope = pcall(require, "telescope")
  if not nx_ok or not telescope_ok then
    vim.notify("nx.nvim is not available", vim.log.levels.WARN)
    return
  end

  if not configured then
    configured = true
    nx.setup({
      nx_cmd_root = "npx nx",
      read_init = false,
    })
    pcall(telescope.load_extension, "nx")
  end

  return telescope
end

local function nx_picker(name)
  return function()
    local telescope = setup()
    if telescope == nil then
      return
    end
    telescope.extensions.nx[name]({})
  end
end

vim.keymap.set("n", "<leader>nx", nx_picker("actions"), { desc = "Nx actions" })
vim.keymap.set("n", "<leader>nr", nx_picker("run_many"), { desc = "Nx run many" })
vim.keymap.set("n", "<leader>na", nx_picker("affected"), { desc = "Nx affected" })
vim.keymap.set("n", "<leader>ng", nx_picker("generators"), { desc = "Nx generators" })
