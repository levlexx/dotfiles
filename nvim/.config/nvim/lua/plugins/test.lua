local function gh(repo)
  return "https://github.com/" .. repo
end

vim.pack.add({
  { src = gh("nvim-neotest/nvim-nio"), version = vim.version.range("1") },
  -- master: nvim 0.12 treesitter fixes (neotest#548) are not in a 5.x tag yet
  { src = gh("nvim-neotest/neotest"), version = "master" },
  -- v2 targets the current tree-sitter-go grammar (statement_list inside
  -- block); v1 queries fail against nvim-treesitter main-branch parsers.
  -- Exact tag: the v2 tags are not reachable from the repo's stale default
  -- branch, so vim.version.range("2") resolves to v1.15.1.
  { src = gh("fredrikaverpil/neotest-golang"), version = "v2.9.0" },
}, {
  confirm = false,
  load = true,
})

local configured = false

local function neotest()
  local t = require("neotest")
  if not configured then
    configured = true
    t.setup({
      adapters = {
        require("neotest-golang")({
          go_test_args = { "-count=1" },
        }),
      },
    })
  end
  return t
end

local map = vim.keymap.set

map("n", "<leader>tn", function()
  neotest().run.run()
end, { desc = "Test nearest" })
map("n", "<leader>tf", function()
  neotest().run.run(vim.fn.expand("%"))
end, { desc = "Test file" })
map("n", "<leader>ta", function()
  neotest().run.run(vim.uv.cwd())
end, { desc = "Test all" })
map("n", "<leader>ts", function()
  neotest().summary.toggle()
end, { desc = "Test summary" })
map("n", "<leader>to", function()
  neotest().output_panel.toggle()
end, { desc = "Test output" })
map("n", "<leader>tw", function()
  neotest().watch.toggle(vim.fn.expand("%"))
end, { desc = "Test watch file" })
