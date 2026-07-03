local function gh(repo)
  return "https://github.com/" .. repo
end

vim.pack.add({
  { src = gh("mistweaverco/kulala.nvim"), version = vim.version.range("5") },
}, {
  confirm = false,
  load = true,
})

require("kulala").setup({
  global_keymaps = false,
})

local map = vim.keymap.set

map("n", "<leader>Rs", function()
  require("kulala").run()
end, { desc = "Send request" })
map("n", "<leader>Ra", function()
  require("kulala").run_all()
end, { desc = "Send all requests" })
map("n", "<leader>Rr", function()
  require("kulala").replay()
end, { desc = "Replay last request" })
map("n", "<leader>Re", function()
  require("kulala").set_selected_env()
end, { desc = "Select environment" })
map("n", "<leader>Rt", function()
  require("kulala").toggle_view()
end, { desc = "Toggle body/headers view" })
map("n", "<leader>Ro", function()
  require("kulala").scratchpad()
end, { desc = "Open scratchpad" })
