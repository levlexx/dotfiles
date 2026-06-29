local ok, treesitter = pcall(require, "nvim-treesitter.configs")
if not ok then
  return
end

local function is_large_buffer(bufnr)
  local max_size = 256 * 1024
  local max_lines = 5000
  local name = vim.api.nvim_buf_get_name(bufnr)
  local stats = name ~= "" and vim.uv.fs_stat(name) or nil

  return (stats ~= nil and stats.size > max_size) or vim.api.nvim_buf_line_count(bufnr) > max_lines
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
  highlight = {
    enable = true,
    disable = function(_, bufnr)
      return is_large_buffer(bufnr)
    end,
  },
  indent = {
    enable = true,
    disable = function(_, bufnr)
      return is_large_buffer(bufnr)
    end,
  },
})
