local gh = function(repo)
  return "https://github.com/" .. repo
end

vim.pack.add({
  { src = gh("neovim/nvim-lspconfig") },
  { src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },
  { src = gh("folke/which-key.nvim") },
  { src = gh("stevearc/conform.nvim") },
  { src = gh("Saghen/blink.cmp"), version = vim.version.range("1") },
  { src = gh("nvim-mini/mini.icons") },
  { src = gh("nvim-mini/mini.ai") },
  { src = gh("nvim-mini/mini.pairs") },
  { src = gh("nvim-mini/mini.surround") },
  { src = gh("nvim-lua/plenary.nvim") },
  { src = gh("nvim-mini/mini.statusline") },
  { src = gh("j-hui/fidget.nvim") },
  { src = gh("folke/tokyonight.nvim") },
}, {
  confirm = false,
  load = true,
})

-- bundled with nvim 0.12 but opt-in: :Undotree, and :DiffTool / `nvim -d`
-- on two directories (git difftool -d)
vim.cmd.packadd("nvim.undotree")
vim.cmd.packadd("nvim.difftool")
