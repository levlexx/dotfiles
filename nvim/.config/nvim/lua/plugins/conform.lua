local ok, conform = pcall(require, "conform")
if not ok then
  return
end

conform.setup({
  formatters_by_ft = {
    go = { "goimports", "gofumpt" },
    lua = { "stylua" },
    javascript = { "biome" },
    javascriptreact = { "biome" },
    typescript = { "biome" },
    typescriptreact = { "biome" },
    typespec = { "typespec" },
    json = { "biome" },
    jsonc = { "biome" },
    yaml = { "prettier" },
  },
  format_on_save = function(bufnr)
    if vim.bo[bufnr].filetype == "typespec" then
      return
    end

    return {
      timeout_ms = 1500,
      lsp_format = "fallback",
    }
  end,
  format_after_save = function(bufnr)
    if vim.bo[bufnr].filetype ~= "typespec" then
      return
    end

    return {
      lsp_format = "fallback",
    }
  end,
})
