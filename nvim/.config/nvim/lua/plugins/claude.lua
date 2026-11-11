-- Claude Code over its IDE protocol: Claude sees the current selection and
-- open buffers, and proposes edits as native diffs (accept/deny below).
-- Release tags lag main by a year; nvim-pack-lock.json pins the commit.

local function gh(repo)
  return "https://github.com/" .. repo
end

vim.pack.add({
  { src = gh("coder/claudecode.nvim") },
}, {
  confirm = false,
  load = true,
})

local tmux_bin = vim.env.TMUX and vim.fn.exepath("tmux") or ""

-- Inside tmux Claude runs in a tmux split of this window: the nvim terminal
-- scrolls its TUI sideways and breaks selection and copy. A new pane does not
-- inherit nvim's environment, so the IDE connection variables go in with -e;
-- the ✳ state hooks set window options, so they still mark this window.
local function tmux_split(cmd, env)
  local args = { tmux_bin, "split-window", "-h", "-l", "38%", "-c", vim.fn.getcwd() }
  for key, value in pairs(env) do
    vim.list_extend(args, { "-e", key .. "=" .. value })
  end
  table.insert(args, cmd)
  return args
end

require("claudecode").setup({
  terminal = {
    split_side = "right",
    split_width_percentage = 0.38,
    provider = tmux_bin ~= "" and "external" or "native",
    provider_opts = { external_terminal_cmd = tmux_split },
  },
  diff_opts = {
    layout = "vertical",
    open_in_new_tab = false,
  },
})

local map = vim.keymap.set

map("n", "<leader>ac", "<cmd>ClaudeCode<cr>", { desc = "Claude: toggle" })
map("n", "<leader>af", "<cmd>ClaudeCodeFocus<cr>", { desc = "Claude: focus" })
map("n", "<leader>ar", "<cmd>ClaudeCode --resume<cr>", { desc = "Claude: resume" })
map("n", "<leader>aC", "<cmd>ClaudeCode --continue<cr>", { desc = "Claude: continue" })
map("n", "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", { desc = "Claude: model" })
map("n", "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", { desc = "Claude: add buffer" })
map("v", "<leader>as", "<cmd>ClaudeCodeSend<cr>", { desc = "Claude: send selection" })
map("n", "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", { desc = "Claude: accept diff" })
map("n", "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", { desc = "Claude: deny diff" })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "oil",
  callback = function(args)
    map("n", "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>", { buffer = args.buf, desc = "Claude: add file" })
  end,
})
