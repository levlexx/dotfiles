local M = {}
local configured = false

local function gh(repo)
  return "https://github.com/" .. repo
end

local function setup()
  vim.pack.add({
    { src = gh("ibhagwan/fzf-lua") },
  }, {
    confirm = false,
    load = true,
  })

  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("fzf-lua is not available", vim.log.levels.WARN)
    return
  end

  if configured then
    return fzf
  end
  configured = true

  fzf.setup({
    winopts = {
      border = "rounded",
      height = 0.85,
      width = 0.9,
      title = " Search ",
      title_pos = "center",
      preview = {
        default = "bat",
        border = "rounded",
        layout = "flex",
      },
    },
    keymap = {
      fzf = {
        ["ctrl-q"] = "select-all+accept",
        ["ctrl-u"] = "half-page-up",
        ["ctrl-d"] = "half-page-down",
      },
    },
  })

  pcall(fzf.register_ui_select)
  return fzf
end

function M.run(command, opts)
  local fzf = setup()
  if fzf == nil then
    return
  end

  local picker = fzf[command]
  if type(picker) ~= "function" then
    vim.notify("Unknown fzf-lua picker: " .. command, vim.log.levels.WARN)
    return
  end

  picker(opts or {})
end

function M.setup()
  setup()
end

return M
