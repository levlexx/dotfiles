local M = {}
local configured = false

local function gh(repo)
  return "https://github.com/" .. repo
end

local function setup()
  vim.pack.add({
    { src = gh("lewis6991/gitsigns.nvim") },
  }, {
    confirm = false,
    load = true,
  })

  local ok, gitsigns = pcall(require, "gitsigns")
  if not ok then
    vim.notify("gitsigns.nvim is not available", vim.log.levels.WARN)
    return
  end

  if not configured then
    configured = true
    gitsigns.setup()
  end

  return gitsigns
end

function M.run(method, ...)
  local gitsigns = setup()
  if gitsigns == nil then
    return
  end

  local fn = gitsigns[method]
  if type(fn) ~= "function" then
    vim.notify("Unknown gitsigns action: " .. method, vim.log.levels.WARN)
    return
  end

  fn(...)
end

vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
  group = vim.api.nvim_create_augroup("UserGitSigns", { clear = true }),
  once = true,
  callback = setup,
})

return M
