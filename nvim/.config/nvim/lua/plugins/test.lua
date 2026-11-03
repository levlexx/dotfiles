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
  -- TypeScript: vitest (alltrack) and jest (Nx workspaces such as octopus);
  -- karma projects have no maintained adapter
  { src = gh("marilari88/neotest-vitest") },
  { src = gh("nvim-neotest/neotest-jest") },
}, {
  confirm = false,
  load = true,
})

local configured = false

-- Nx: run jest from the workspace root (nx.json) with the nearest project
-- jest.config, so `jest --config apps/x/jest.config.ts` resolves presets
local jest_configs = { "jest.config.ts", "jest.config.js", "jest.config.cjs", "jest.config.mjs" }

local function nearest(names, path)
  return vim.fs.find(names, { upward = true, path = vim.fs.dirname(path) })[1]
end

local function jest_config(path)
  return nearest(jest_configs, path)
end

local function jest_cwd(path)
  local nx = nearest({ "nx.json" }, path)
  if nx then
    return vim.fs.dirname(nx)
  end
  local config = jest_config(path)
  return config and vim.fs.dirname(config) or vim.fn.getcwd()
end

local function neotest()
  local t = require("neotest")
  if not configured then
    configured = true
    t.setup({
      adapters = {
        require("neotest-golang")({
          go_test_args = { "-count=1" },
        }),
        require("neotest-vitest"),
        require("neotest-jest")({
          jestCommand = "npx jest",
          jestConfigFile = jest_config,
          cwd = jest_cwd,
          env = { CI = "true" },
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
