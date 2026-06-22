local ok, statusline = pcall(require, "mini.statusline")
if not ok then
  return
end

local palette = require("core.palette")

local function set_highlights()
  local groups = {
    NvimSLModeNormal = { fg = palette.bg, bg = palette.blue, bold = true },
    NvimSLModeInsert = { fg = palette.bg, bg = palette.green, bold = true },
    NvimSLModeVisual = { fg = palette.bg, bg = palette.purple, bold = true },
    NvimSLModeReplace = { fg = palette.bg, bg = palette.red, bold = true },
    NvimSLModeCommand = { fg = palette.bg, bg = palette.orange, bold = true },
    NvimSLModeOther = { fg = palette.bg, bg = palette.cyan, bold = true },

    NvimSLCapNormal = { fg = palette.blue, bg = palette.bg },
    NvimSLCapInsert = { fg = palette.green, bg = palette.bg },
    NvimSLCapVisual = { fg = palette.purple, bg = palette.bg },
    NvimSLCapReplace = { fg = palette.red, bg = palette.bg },
    NvimSLCapCommand = { fg = palette.orange, bg = palette.bg },
    NvimSLCapOther = { fg = palette.cyan, bg = palette.bg },

    NvimSLSurface = { fg = palette.muted, bg = palette.surface_alt },
    NvimSLSurfaceCap = { fg = palette.surface_alt, bg = palette.bg },
    NvimSLGit = { fg = palette.green, bg = palette.surface_alt, bold = true },
    NvimSLWarn = { fg = palette.orange, bg = palette.surface_alt, bold = true },
    NvimSLError = { fg = palette.red, bg = palette.surface_alt, bold = true },
    NvimSLPurple = { fg = palette.purple, bg = palette.surface_alt, bold = true },
    NvimSLFile = { fg = palette.fg, bg = palette.bg },
    NvimSLInactive = { fg = palette.dim, bg = palette.bg },
  }

  for group, value in pairs(groups) do
    vim.api.nvim_set_hl(0, group, value)
  end
end

set_highlights()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_highlights })

local modes = {
  n = { "N", "NvimSLModeNormal", "NvimSLCapNormal" },
  no = { "O", "NvimSLModeNormal", "NvimSLCapNormal" },
  i = { "I", "NvimSLModeInsert", "NvimSLCapInsert" },
  ic = { "I", "NvimSLModeInsert", "NvimSLCapInsert" },
  v = { "V", "NvimSLModeVisual", "NvimSLCapVisual" },
  V = { "VL", "NvimSLModeVisual", "NvimSLCapVisual" },
  ["\22"] = { "VB", "NvimSLModeVisual", "NvimSLCapVisual" },
  R = { "R", "NvimSLModeReplace", "NvimSLCapReplace" },
  c = { "C", "NvimSLModeCommand", "NvimSLCapCommand" },
  t = { "T", "NvimSLModeOther", "NvimSLCapOther" },
}

local function capsule(text, group, cap_group)
  if text == nil or text == "" then
    return ""
  end
  return table.concat({ "%#", cap_group, "#%#", group, "# ", text, " %#", cap_group, "#%*" })
end

local function compact(items)
  local out = {}
  for _, item in ipairs(items) do
    if item and item ~= "" then
      table.insert(out, item)
    end
  end
  return table.concat(out, " ")
end

local function mode_capsule()
  local mode = modes[vim.fn.mode(1)] or { "?", "NvimSLModeOther", "NvimSLCapOther" }
  return capsule(mode[1], mode[2], mode[3]), mode[2], mode[3]
end

local function git_branch()
  local branch = vim.b.gitsigns_head
  if branch == nil or branch == "" then
    return ""
  end
  return " " .. branch
end

local function diagnostics()
  local error_count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
  local warn_count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
  local info_count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
  local hint_count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
  local parts = {}

  if error_count > 0 then
    table.insert(parts, "E" .. error_count)
  end
  if warn_count > 0 then
    table.insert(parts, "W" .. warn_count)
  end
  if info_count > 0 then
    table.insert(parts, "I" .. info_count)
  end
  if hint_count > 0 then
    table.insert(parts, "H" .. hint_count)
  end

  if #parts == 0 then
    return ""
  end
  return "󰒡 " .. table.concat(parts, " ")
end

local function lsp_status()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    return ""
  end

  local names = {}
  for _, client in ipairs(clients) do
    table.insert(names, client.name)
  end
  return " " .. table.concat(names, ",")
end

local function formatter_status()
  local conform_ok, conform = pcall(require, "conform")
  if not conform_ok then
    return ""
  end

  local names = conform.list_formatters_for_buffer(0)
  if #names == 0 then
    return ""
  end
  return "fmt " .. table.concat(names, ",")
end

local function filename()
  local name = vim.fn.expand("%:~:.")
  if name == "" then
    return "[No Name]"
  end
  return vim.bo.modified and name .. " ●" or name
end

local function filetype()
  local ft = vim.bo.filetype
  if ft == "" then
    return "text"
  end
  return ft
end

local function encoding()
  local enc = vim.bo.fileencoding ~= "" and vim.bo.fileencoding or vim.o.encoding
  return enc:upper()
end

local function location()
  local line = vim.fn.line(".")
  local total = math.max(vim.fn.line("$"), 1)
  local progress = math.floor((line / total) * 100)
  return string.format("%d:%d %d%%%%", line, vim.fn.col("."), progress)
end

statusline.setup({
  use_icons = true,
  content = {
    active = function()
      local mode, mode_group, mode_cap = mode_capsule()
      local left = compact({
        mode,
        capsule(git_branch(), "NvimSLGit", "NvimSLSurfaceCap"),
        capsule(diagnostics(), "NvimSLError", "NvimSLSurfaceCap"),
        capsule(lsp_status(), "NvimSLPurple", "NvimSLSurfaceCap"),
        capsule(formatter_status(), "NvimSLWarn", "NvimSLSurfaceCap"),
      })
      local right = compact({
        capsule(filetype(), "NvimSLSurface", "NvimSLSurfaceCap"),
        capsule(encoding(), "NvimSLSurface", "NvimSLSurfaceCap"),
        capsule(location(), mode_group, mode_cap),
      })

      return left .. "%< %#NvimSLFile#  " .. filename() .. " %*%=" .. right
    end,
    inactive = function()
      return "%#NvimSLInactive# " .. filename() .. "%=" .. location() .. " %*"
    end,
  },
})
