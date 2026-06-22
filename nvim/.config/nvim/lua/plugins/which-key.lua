local ok, which_key = pcall(require, "which-key")
if not ok then
  return
end

which_key.setup({
  preset = "helix",
  delay = 300,
  win = {
    border = "rounded",
    padding = { 1, 2 },
  },
  layout = {
    spacing = 4,
  },
})

which_key.add({
  { "<leader>f", group = "Find / search" },
  { "<leader>g", group = "Git" },
  { "<leader>gh", group = "Git hunks" },
  { "<leader>c", group = "Code / LSP" },
  { "<leader>d", group = "Debug" },
  { "<leader>b", group = "Buffers" },
  { "<leader>w", group = "Windows" },
  { "<leader>t", group = "Terminal / tests" },
  { "<leader>x", group = "Diagnostics" },
  { "<leader>q", group = "Quit / session" },
  { "<leader>u", group = "UI toggles" },
  { "<leader>a", group = "AI / agents" },
  { "[", group = "Previous" },
  { "]", group = "Next" },
  { "g", group = "Goto" },
}, { mode = "n" })

which_key.add({
  { "<leader>f", group = "Find / search" },
  { "<leader>c", group = "Code / LSP" },
}, { mode = "x" })
