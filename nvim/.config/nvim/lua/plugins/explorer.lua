vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local M = {}
local configured = false
local gh = function(repo)
  return "https://github.com/" .. repo
end

local function setup()
  if configured then
    return
  end
  configured = true

  vim.pack.add({
    { src = gh("nvim-neo-tree/neo-tree.nvim"), version = "v3.x" },
    { src = gh("nvim-lua/plenary.nvim") },
    { src = gh("MunifTanjim/nui.nvim") },
  }, {
    confirm = false,
    load = true,
  })

  require("neo-tree").setup({
    close_if_last_window = false,
    enable_diagnostics = true,
    enable_git_status = true,
    popup_border_style = "rounded",
    default_component_configs = {
      indent = {
        with_expanders = true,
        expander_collapsed = "",
        expander_expanded = "",
      },
      modified = { symbol = "●" },
      git_status = {
        symbols = {
          added = "󰐕",
          deleted = "󰍵",
          modified = "󰜥",
          renamed = "󰁕",
          untracked = "󰋗",
          ignored = "󰈉",
          unstaged = "󰄱",
          staged = "󰱒",
          conflict = "󰀦",
        },
      },
      diagnostics = {
        symbols = {
          hint = "󰌶",
          info = "󰋽",
          warn = "󰀪",
          error = "󰅚",
        },
      },
    },
    filesystem = {
      bind_to_cwd = false,
      follow_current_file = {
        enabled = true,
        leave_dirs_open = false,
      },
      use_libuv_file_watcher = true,
      filtered_items = {
        hide_dotfiles = false,
        hide_gitignored = false,
      },
    },
    window = {
      position = "left",
      width = 34,
    },
  })
end

local function execute(opts)
  setup()
  require("neo-tree.command").execute(vim.tbl_extend("force", {
    source = "filesystem",
    position = "left",
  }, opts or {}))
end

function M.toggle()
  execute({ toggle = true, reveal = true })
end

function M.reveal()
  execute({ action = "focus", reveal = true })
end

function M.cwd()
  execute({ action = "focus", dir = vim.uv.cwd() })
end

return M
