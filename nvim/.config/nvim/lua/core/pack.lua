local gh = function(repo)
  return "https://github.com/" .. repo
end

vim.pack.add({
  { src = gh("neovim/nvim-lspconfig") },
  { src = gh("nvim-treesitter/nvim-treesitter") },
  { src = gh("folke/which-key.nvim") },
  { src = gh("stevearc/conform.nvim") },
  { src = gh("Saghen/blink.cmp"), version = vim.version.range("1") },
  { src = gh("nvim-mini/mini.icons") },
  { src = gh("nvim-mini/mini.ai") },
  { src = gh("nvim-mini/mini.pairs") },
  { src = gh("nvim-mini/mini.statusline") },
  { src = gh("j-hui/fidget.nvim") },
  { src = gh("folke/tokyonight.nvim") },
}, {
  confirm = false,
  load = true,
})
