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
    NvimSLClaude = { fg = palette.orange, bg = palette.surface_alt, bold = true },
    NvimSLClaudeWait = { fg = palette.bg, bg = palette.red, bold = true },
    NvimSLClaudeWaitCap = { fg = palette.red, bg = palette.bg },
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

-- short oil directory: ~-relative, middle components shortened when long
local function oil_path()
  local ok, oil = pcall(require, "oil")
  local dir = ok and oil.get_current_dir() or nil
  if not dir then
    return "oil"
  end

  dir = vim.fn.fnamemodify(dir, ":~")
  if #dir > 45 then
    dir = vim.fn.pathshorten(dir, 2)
  end
  return dir
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

-- Claude capsule: claudecode.nvim connection plus this tmux window's agent
-- state (@claude_state, stamped by the claude-usage hooks). The state is
-- polled from tmux about once a second; the spinner only ticks while working.
local glyph = vim.fn.nr2char
local claude_icons = {
  robot = glyph(0xF06A9),
  waiting = glyph(0xF009E),
  done = glyph(0xF012C),
  error = glyph(0xF015A),
}
local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local claude = { state = "", frame = 1 }

local function poll_claude_state()
  local pane = vim.env.TMUX_PANE
  if not pane then
    return
  end
  vim.system({ "tmux", "display", "-p", "-t", pane, "#{@claude_state}" }, { text = true }, function(out)
    local state = vim.trim(out.stdout or "")
    if state ~= claude.state then
      claude.state = state
      vim.schedule(function()
        vim.cmd.redrawtabline()
      end)
    end
  end)
end

if vim.env.TMUX_PANE then
  local ticks = 0
  vim.uv.new_timer():start(
    0,
    150,
    vim.schedule_wrap(function()
      ticks = ticks + 1
      if ticks % 7 == 1 then
        poll_claude_state()
      end
      if claude.state == "working" then
        claude.frame = claude.frame % #spinner + 1
        vim.cmd.redrawtabline()
      end
    end)
  )
end

local function claude_status()
  local ok, cc = pcall(require, "claudecode")
  local connected = ok and cc.is_claude_connected and cc.is_claude_connected()
  local icon = claude.state == "working" and spinner[claude.frame] or claude_icons[claude.state]
  if not connected and not icon then
    return ""
  end
  local text = claude_icons.robot .. (connected and " ide" or "") .. (icon and (" " .. icon) or "")
  if claude.state == "waiting" then
    return capsule(text, "NvimSLClaudeWait", "NvimSLClaudeWaitCap")
  end
  return capsule(text, "NvimSLClaude", "NvimSLSurfaceCap")
end

-- Render the status panel at the TOP: the tabline slot is free (no tab pages
-- used) and accepts the same %-syntax, so it just evaluates mini's content.
-- The bottom statusline is hidden via laststatus=0 in core/options.lua.
vim.o.showtabline = 2
vim.o.tabline = "%!v:lua.MiniStatusline.active()"

-- The tabline does not redraw on cursor/mode events by itself.
vim.api.nvim_create_autocmd(
  { "ModeChanged", "CursorMoved", "CursorMovedI", "DiagnosticChanged", "LspAttach", "LspDetach", "BufWritePost" },
  {
    group = vim.api.nvim_create_augroup("UserTopStatusline", { clear = true }),
    command = "redrawtabline",
  }
)

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
        claude_status(),
        capsule(filetype(), "NvimSLSurface", "NvimSLSurfaceCap"),
        capsule(encoding(), "NvimSLSurface", "NvimSLSurfaceCap"),
        capsule(location(), mode_group, mode_cap),
      })

      local file_section
      if vim.bo.filetype == "oil" then
        file_section = " " .. capsule("󰉋 " .. oil_path(), "NvimSLSurface", "NvimSLSurfaceCap")
      else
        file_section = " %#NvimSLFile#  " .. filename() .. " %*"
      end

      return left .. "%<" .. file_section .. "%=" .. right
    end,
    inactive = function()
      local name = vim.bo.filetype == "oil" and ("󰉋 " .. oil_path()) or filename()
      return "%#NvimSLInactive# " .. name .. "%=" .. location() .. " %*"
    end,
  },
})
