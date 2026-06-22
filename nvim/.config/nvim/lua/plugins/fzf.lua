local ok, fzf = pcall(require, "fzf-lua")
if not ok then
  return
end

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
