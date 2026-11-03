local palette = require("core.palette")

local function set_highlights()
  -- the overrides are night colours; in light mode tokyonight "day" stands alone
  if vim.o.background == "light" then
    return
  end
  local highlights = {
    Normal = { fg = palette.fg, bg = palette.bg },
    -- inactive windows dim to the same #16161e as inactive tmux panes
    NormalNC = { fg = palette.fg, bg = palette.bg_dark },
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
    style = "night",
    light_style = "day",
    dim_inactive = true,
    styles = {
      sidebars = "dark",
      floats = "dark",
    },
  })
end

-- follow macOS light/dark like Ghostty and tmux: at startup, on focus and
-- every 5s (AppleInterfaceStyle is only set in dark mode)
local function macos_background()
  local ok, out = pcall(function()
    return vim.system({ "defaults", "read", "-g", "AppleInterfaceStyle" }, { text = true }):wait(500)
  end)
  return (ok and out.code == 0) and "dark" or "light"
end

local function sync_background()
  local bg = macos_background()
  if bg ~= vim.o.background then
    vim.o.background = bg
    pcall(vim.cmd.colorscheme, "tokyonight")
  end
end

if vim.fn.has("mac") == 1 then
  vim.o.background = macos_background()
  vim.api.nvim_create_autocmd("FocusGained", { callback = sync_background })
  vim.uv.new_timer():start(5000, 5000, vim.schedule_wrap(sync_background))
end

if not pcall(vim.cmd.colorscheme, "tokyonight") then
  vim.cmd.colorscheme("habamax")
end

set_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = set_highlights,
})
