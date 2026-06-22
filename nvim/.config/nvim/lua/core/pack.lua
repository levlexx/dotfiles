local gh = function(repo)
  return "https://github.com/" .. repo
end

vim.pack.add({
  { src = gh("neovim/nvim-lspconfig") },
  { src = gh("nvim-treesitter/nvim-treesitter") },
  { src = gh("ibhagwan/fzf-lua") },
  { src = gh("folke/which-key.nvim") },
  { src = gh("lewis6991/gitsigns.nvim") },
  { src = gh("stevearc/conform.nvim") },
  { src = gh("Saghen/blink.cmp"), version = vim.version.range("1") },
  { src = gh("nvim-mini/mini.icons") },
  { src = gh("nvim-mini/mini.ai") },
  { src = gh("nvim-mini/mini.pairs") },
  { src = gh("nvim-mini/mini.statusline") },
  { src = gh("goolord/alpha-nvim") },
  { src = gh("j-hui/fidget.nvim") },
  { src = gh("mfussenegger/nvim-dap") },
  { src = gh("rcarriga/nvim-dap-ui") },
  { src = gh("theHamsta/nvim-dap-virtual-text") },
  { src = gh("nvim-neotest/nvim-nio") },
  { src = gh("folke/tokyonight.nvim") },
}, {
  confirm = false,
  load = true,
})
