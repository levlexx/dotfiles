local configured = false

local function gh(repo)
  return "https://github.com/" .. repo
end

local function setup()
  vim.pack.add({
    { src = gh("mfussenegger/nvim-dap") },
    { src = gh("nvim-neotest/nvim-nio") },
    { src = gh("rcarriga/nvim-dap-ui") },
    { src = gh("theHamsta/nvim-dap-virtual-text") },
  }, {
    confirm = false,
    load = true,
  })

  local dap_ok, dap = pcall(require, "dap")
  if not dap_ok then
    vim.notify("nvim-dap is not available", vim.log.levels.WARN)
    return
  end

  local dapui_ok, dapui = pcall(require, "dapui")
  local virtual_text_ok, virtual_text = pcall(require, "nvim-dap-virtual-text")
  local config = require("config.dap")

  if configured then
    return dap, dapui_ok and dapui or nil, config
  end
  configured = true

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

  config.setup(dap)
  return dap, dapui_ok and dapui or nil, config
end

local function with_dap(callback)
  return function()
    local dap, dapui, config = setup()
    if dap ~= nil then
      callback(dap, dapui, config)
    end
  end
end

local map = vim.keymap.set

map("n", "<leader>db", with_dap(function(dap)
  dap.toggle_breakpoint()
end), { desc = "Toggle breakpoint" })
map("n", "<leader>dB", with_dap(function(dap)
  dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end), { desc = "Conditional breakpoint" })
map("n", "<leader>dc", with_dap(function(dap)
  dap.continue()
end), { desc = "Continue" })
map("n", "<leader>di", with_dap(function(dap)
  dap.step_into()
end), { desc = "Step into" })
map("n", "<leader>do", with_dap(function(dap)
  dap.step_over()
end), { desc = "Step over" })
map("n", "<leader>dO", with_dap(function(dap)
  dap.step_out()
end), { desc = "Step out" })
map("n", "<leader>dr", with_dap(function(dap)
  dap.repl.open()
end), { desc = "Open REPL" })
map("n", "<leader>dl", with_dap(function(dap)
  dap.run_last()
end), { desc = "Run last debug session" })
map("n", "<leader>dt", with_dap(function(_, _, config)
  config.debug_nearest_go_test()
end), { desc = "Debug nearest Go test" })
map("n", "<leader>du", with_dap(function(_, dapui)
  if dapui ~= nil then
    dapui.toggle()
  else
    vim.notify("nvim-dap-ui is not available", vim.log.levels.WARN)
  end
end), { desc = "Toggle debug UI" })

map("n", "<leader>da", with_dap(function(dap)
  dap.run({
    type = "go",
    name = "Attach to running process",
    request = "attach",
    mode = "local",
    processId = require("dap.utils").pick_process,
  })
end), { desc = "Attach Go process" })
map("n", "<leader>dC", with_dap(function(_, _, config)
  config.debug_cloud_run_local()
end), { desc = "Debug Cloud Run local" })
map("n", "<leader>df", with_dap(function(_, _, config)
  config.debug_current_file()
end), { desc = "Debug current file" })
map("n", "<leader>dp", with_dap(function(_, _, config)
  config.debug_go_package_tests()
end), { desc = "Debug package tests" })
map("n", "<leader>ds", with_dap(function(_, _, config)
  config.debug_go_service()
end), { desc = "Debug Go service env" })
map("n", "<leader>dv", with_dap(function(_, dapui)
  if dapui ~= nil then
    dapui.eval(nil, { enter = true })
  end
end), { desc = "Preview variable" })
map("n", "<leader>dx", with_dap(function(dap)
  dap.terminate()
end), { desc = "Terminate debug session" })
