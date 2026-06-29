local ok, blink = pcall(require, "blink.cmp")
if not ok then
  return
end

blink.setup({
  keymap = {
    preset = "super-tab",
    ["<CR>"] = { "accept", "fallback" },
    ["<C-y>"] = { "select_and_accept" },
  },
  completion = {
    accept = {
      auto_brackets = {
        enabled = true,
      },
    },
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 200,
    },
    ghost_text = {
      enabled = true,
    },
    menu = {
      draw = {
        treesitter = { "lsp" },
      },
    },
    list = {
      max_items = 80,
    },
  },
  signature = {
    enabled = true,
    window = {
      show_documentation = true,
    },
  },
  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
    providers = {
      lsp = {
        score_offset = 8,
      },
      buffer = {
        max_items = 8,
        min_keyword_length = 3,
      },
      snippets = {
        max_items = 20,
      },
    },
  },
})
