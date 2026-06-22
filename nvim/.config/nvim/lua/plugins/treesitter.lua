local ok, treesitter = pcall(require, "nvim-treesitter.configs")
if not ok then
  return
end

treesitter.setup({
  ensure_installed = {
    "bash",
    "dockerfile",
    "go",
    "gomod",
    "gosum",
    "gowork",
    "javascript",
    "json",
    "jsonc",
    "lua",
    "markdown",
    "markdown_inline",
    "tsx",
    "typespec",
    "typescript",
    "vim",
    "vimdoc",
    "yaml",
  },
  auto_install = false,
  highlight = { enable = true },
  indent = { enable = true },
})
