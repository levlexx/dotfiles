local palette = require("core.palette")

local function set_highlights()
  local highlights = {
    Normal = { fg = palette.fg, bg = palette.bg },
    NormalFloat = { fg = palette.fg, bg = palette.surface },
    FloatBorder = { fg = palette.border, bg = palette.surface },
    FloatTitle = { fg = palette.blue, bg = palette.surface, bold = true },
    Pmenu = { fg = palette.fg, bg = palette.surface },
    PmenuSel = { fg = palette.bg, bg = palette.blue, bold = true },
    WinSeparator = { fg = palette.border, bg = palette.bg },
    StatusLine = { fg = palette.fg, bg = palette.bg },
    StatusLineNC = { fg = palette.dim, bg = palette.bg },

    WhichKey = { fg = palette.blue },
    WhichKeyDesc = { fg = palette.fg },
    WhichKeyGroup = { fg = palette.purple, bold = true },
    WhichKeySeparator = { fg = palette.dim },
    WhichKeyValue = { fg = palette.green },

    FzfLuaBorder = { fg = palette.border, bg = palette.bg },
    FzfLuaTitle = { fg = palette.blue, bg = palette.bg, bold = true },
    FzfLuaNormal = { fg = palette.fg, bg = palette.bg },
    FzfLuaPreviewNormal = { fg = palette.fg, bg = palette.surface },
    FzfLuaPreviewBorder = { fg = palette.border, bg = palette.surface },

    NeoTreeNormal = { fg = palette.fg, bg = palette.bg },
    NeoTreeNormalNC = { fg = palette.muted, bg = palette.bg },
    NeoTreeWinSeparator = { fg = palette.border, bg = palette.bg },
    NeoTreeDirectoryName = { fg = palette.blue, bold = true },
    NeoTreeDirectoryIcon = { fg = palette.blue },
    NeoTreeFileName = { fg = palette.fg },
    NeoTreeFileNameOpened = { fg = palette.green, bold = true },
    NeoTreeGitAdded = { fg = palette.green },
    NeoTreeGitDeleted = { fg = palette.red },
    NeoTreeGitModified = { fg = palette.orange },
    NeoTreeGitUntracked = { fg = palette.purple },
    NeoTreeIndentMarker = { fg = palette.border },

    NvimDashboardHeader = { fg = palette.blue, bold = true },
    NvimDashboardButton = { fg = palette.fg },
    NvimDashboardShortcut = { fg = palette.green, bold = true },
    NvimDashboardFooter = { fg = palette.dim },
  }

  for group, value in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, value)
  end
end

local ok, tokyonight = pcall(require, "tokyonight")
if ok then
  tokyonight.setup({
    style = "moon",
    styles = {
      sidebars = "dark",
      floats = "dark",
    },
  })
end

if not pcall(vim.cmd.colorscheme, "tokyonight") then
  vim.cmd.colorscheme("habamax")
end

set_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = set_highlights,
})
