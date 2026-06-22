local ok, blink = pcall(require, "blink.cmp")
if not ok then
  return
end

blink.setup({
  keymap = {
    preset = "enter",
    ["<C-y>"] = { "select_and_accept" },
  },
  completion = {
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 200,
    },
    menu = {
      draw = {
        treesitter = { "lsp" },
      },
    },
  },
  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
  },
})
