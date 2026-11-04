-- nvim-treesitter main branch: rolling grammars, no configs.setup().
-- Parsers are installed once via `install()`; highlighting/indent start
-- per buffer from the FileType autocmd below.
local M = {}

local ok, treesitter = pcall(require, "nvim-treesitter")
if not ok then
  return M
end

local parsers = {
  "bash",
  "dockerfile",
  "go",
  "gomod",
  "gosum",
  "gowork",
  "http",
  "javascript",
  "json",
  "lua",
  "markdown",
  "markdown_inline",
  "mermaid",
  "sql",
  "tsx",
  "typespec",
  "typescript",
  "vim",
  "vimdoc",
  "yaml",
}

M.parsers = parsers

treesitter.install(parsers)

local function is_large_buffer(bufnr)
  local max_size = 256 * 1024
  local max_lines = 5000
  local name = vim.api.nvim_buf_get_name(bufnr)
  local stats = name ~= "" and vim.uv.fs_stat(name) or nil

  return (stats ~= nil and stats.size > max_size) or vim.api.nvim_buf_line_count(bufnr) > max_lines
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true }),
  callback = function(event)
    if is_large_buffer(event.buf) then
      return
    end
    -- no-op for filetypes without an installed parser
    if not pcall(vim.treesitter.start, event.buf) then
      return
    end
    vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

return M
