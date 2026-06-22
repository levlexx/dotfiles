local dap_ok, dap = pcall(require, "dap")
if not dap_ok then
  return
end

local dapui_ok, dapui = pcall(require, "dapui")
local virtual_text_ok, virtual_text = pcall(require, "nvim-dap-virtual-text")

if virtual_text_ok then
  virtual_text.setup({
    enabled = true,
    enabled_commands = true,
    highlight_changed_variables = true,
    highlight_new_as_changed = false,
    show_stop_reason = true,
    commented = true,
  })
end

if dapui_ok then
  dapui.setup({
    layouts = {
      {
        elements = {
          { id = "scopes", size = 0.35 },
          { id = "watches", size = 0.20 },
          { id = "breakpoints", size = 0.20 },
          { id = "stacks", size = 0.25 },
        },
        size = 40,
        position = "left",
      },
      {
        elements = {
          { id = "repl", size = 0.55 },
          { id = "console", size = 0.45 },
        },
        size = 12,
        position = "bottom",
      },
    },
    floating = {
      border = "rounded",
      mappings = {
        close = { "q", "<Esc>" },
      },
    },
  })

  dap.listeners.after.event_initialized["dapui"] = function()
    dapui.open()
  end
  dap.listeners.before.event_terminated["dapui"] = function()
    dapui.close()
  end
  dap.listeners.before.event_exited["dapui"] = function()
    dapui.close()
  end
end

vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn", linehl = "", numhl = "" })
vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticInfo", linehl = "Visual", numhl = "" })
vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DiagnosticInfo", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DiagnosticError", linehl = "", numhl = "" })

local config = require("config.dap")
config.setup(dap)

local map = vim.keymap.set

map("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
map("n", "<leader>dB", function()
  dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Conditional breakpoint" })
map("n", "<leader>dc", dap.continue, { desc = "Continue" })
map("n", "<leader>di", dap.step_into, { desc = "Step into" })
map("n", "<leader>do", dap.step_over, { desc = "Step over" })
map("n", "<leader>dO", dap.step_out, { desc = "Step out" })
map("n", "<leader>dr", dap.repl.open, { desc = "Open REPL" })
map("n", "<leader>dl", dap.run_last, { desc = "Run last debug session" })
map("n", "<leader>dt", config.debug_nearest_go_test, { desc = "Debug nearest Go test" })
map("n", "<leader>du", function()
  if dapui_ok then
    dapui.toggle()
  else
    vim.notify("nvim-dap-ui is not available", vim.log.levels.WARN)
  end
end, { desc = "Toggle debug UI" })

map("n", "<leader>da", function()
  dap.run({ type = "go", name = "Attach to running process", request = "attach", mode = "local", processId = require("dap.utils").pick_process })
end, { desc = "Attach Go process" })
map("n", "<leader>dC", config.debug_cloud_run_local, { desc = "Debug Cloud Run local" })
map("n", "<leader>df", config.debug_current_file, { desc = "Debug current file" })
map("n", "<leader>dp", config.debug_go_package_tests, { desc = "Debug package tests" })
map("n", "<leader>ds", config.debug_go_service, { desc = "Debug Go service env" })
map("n", "<leader>dv", function()
  if dapui_ok then
    dapui.eval(nil, { enter = true })
  end
end, { desc = "Preview variable" })
map("n", "<leader>dx", dap.terminate, { desc = "Terminate debug session" })
