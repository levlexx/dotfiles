local M = {}

local function executable(name)
  return vim.fn.executable(name) == 1
end

local function split_args(input)
  if input == nil or input == "" then
    return {}
  end
  return vim.split(input, "%s+", { trimempty = true })
end

local function read_env_file(path)
  local env = {}
  if vim.fn.filereadable(path) == 0 then
    return env
  end

  for _, line in ipairs(vim.fn.readfile(path)) do
    local trimmed = vim.trim(line)
    if trimmed ~= "" and not trimmed:match("^#") then
      local key, value = trimmed:match("^([%w_]+)%s*=%s*(.*)$")
      if key ~= nil then
        value = value:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
        env[key] = value
      end
    end
  end

  return env
end

local function merge_env(...)
  local result = {}
  for _, env in ipairs({ ... }) do
    for key, value in pairs(env or {}) do
      result[key] = value
    end
  end
  return result
end

local function project_env()
  local cwd = vim.uv.cwd() or vim.fn.getcwd()
  return merge_env(
    read_env_file(cwd .. "/.env"),
    read_env_file(cwd .. "/.env.local"),
    read_env_file(cwd .. "/.env.debug")
  )
end

local function go_test_name()
  local current = vim.api.nvim_win_get_cursor(0)[1]
  for line = current, 1, -1 do
    local text = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1]
    local name = text and text:match("^func%s+(Test[%w_]+)%s*%(")
    if name ~= nil then
      return name
    end
  end
end

local function js_debug_adapter()
  if vim.env.JS_DEBUG_ADAPTER ~= nil and vim.env.JS_DEBUG_ADAPTER ~= "" then
    return vim.fn.expand(vim.env.JS_DEBUG_ADAPTER)
  end

  local candidates = {
    vim.fn.expand("~/.local/share/vscode-js-debug/dist/src/dapDebugServer.js"),
    vim.fn.expand("~/.local/share/js-debug/src/dapDebugServer.js"),
    vim.fn.expand("~/.local/share/vscode-js-debug/src/dapDebugServer.js"),
    vim.fn.stdpath("data") .. "/vscode-js-debug/dist/src/dapDebugServer.js",
    vim.fn.stdpath("data") .. "/js-debug/src/dapDebugServer.js",
    vim.fn.stdpath("data") .. "/vscode-js-debug/src/dapDebugServer.js",
  }

  for _, candidate in ipairs(candidates) do
    if vim.fn.filereadable(candidate) == 1 then
      return candidate
    end
  end
end

local function chrome_path()
  local candidates = {
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
  }

  for _, candidate in ipairs(candidates) do
    if vim.fn.executable(candidate) == 1 then
      return candidate
    end
  end
end

local function setup_go(dap)
  dap.adapters.go = function(callback, config)
    if config.request == "attach" and config.mode == "remote" then
      callback({
        type = "server",
        host = config.host or "127.0.0.1",
        port = config.port or 38697,
      })
      return
    end

    if not executable("dlv") then
      vim.notify("Delve is not installed or not on PATH", vim.log.levels.ERROR)
      return
    end

    callback({
      type = "server",
      port = "${port}",
      executable = {
        command = "dlv",
        args = { "dap", "-l", "127.0.0.1:${port}" },
        detached = vim.fn.has("win32") == 0,
      },
    })
  end

  dap.configurations.go = {
    {
      type = "go",
      name = "Debug current file",
      request = "launch",
      mode = "debug",
      program = "${file}",
      env = project_env,
    },
    {
      type = "go",
      name = "Debug package",
      request = "launch",
      mode = "debug",
      program = "${workspaceFolder}",
      env = project_env,
    },
    {
      type = "go",
      name = "Debug package tests",
      request = "launch",
      mode = "test",
      program = "${workspaceFolder}",
      env = project_env,
    },
    {
      type = "go",
      name = "Debug Go service with env vars",
      request = "launch",
      mode = "debug",
      program = "${workspaceFolder}",
      env = project_env,
      args = function()
        return split_args(vim.fn.input("Args: "))
      end,
    },
    {
      type = "go",
      name = "Debug Cloud Run-like local process",
      request = "launch",
      mode = "debug",
      program = "${workspaceFolder}",
      env = function()
        return merge_env(project_env(), {
          PORT = vim.env.PORT or "8080",
          K_SERVICE = vim.env.K_SERVICE or "local-service",
          K_REVISION = vim.env.K_REVISION or "local-revision",
          K_CONFIGURATION = vim.env.K_CONFIGURATION or "local-config",
        })
      end,
      args = function()
        return split_args(vim.fn.input("Args: "))
      end,
    },
    {
      type = "go",
      name = "Attach to running process",
      request = "attach",
      mode = "local",
      processId = require("dap.utils").pick_process,
    },
    {
      type = "go",
      name = "Attach remote Delve :38697",
      request = "attach",
      mode = "remote",
      host = "127.0.0.1",
      port = 38697,
    },
  }
end

local function setup_javascript(dap)
  local adapter = js_debug_adapter()

  local function missing_adapter()
    vim.notify(
      "JS debug adapter not found. Run `mise run install-js-debug-adapter`. See README debugging troubleshooting.",
      vim.log.levels.ERROR
    )
  end

  for _, name in ipairs({ "pwa-node", "pwa-chrome" }) do
    if adapter == nil then
      dap.adapters[name] = missing_adapter
    else
      dap.adapters[name] = {
        type = "server",
        host = "127.0.0.1",
        port = "${port}",
        executable = {
          command = "node",
          args = { adapter, "${port}" },
        },
      }
    end
  end

  local browser = chrome_path()
  local node_configs = {
    {
      type = "pwa-node",
      request = "launch",
      name = "Debug current TS/JS file",
      program = "${file}",
      cwd = "${workspaceFolder}",
      runtimeExecutable = "node",
      sourceMaps = true,
      skipFiles = { "<node_internals>/**" },
      console = "integratedTerminal",
    },
    {
      type = "pwa-node",
      request = "attach",
      name = "Attach to Node process",
      processId = require("dap.utils").pick_process,
      cwd = "${workspaceFolder}",
      sourceMaps = true,
      skipFiles = { "<node_internals>/**" },
    },
    {
      type = "pwa-chrome",
      request = "launch",
      name = "Debug Angular app at localhost:4200",
      url = "http://localhost:4200",
      webRoot = "${workspaceFolder}",
      runtimeExecutable = browser,
      sourceMaps = true,
    },
    {
      type = "pwa-chrome",
      request = "attach",
      name = "Attach Chrome remote debug :9222",
      port = 9222,
      webRoot = "${workspaceFolder}",
      sourceMaps = true,
    },
  }

  for _, filetype in ipairs({ "javascript", "javascriptreact", "typescript", "typescriptreact" }) do
    dap.configurations[filetype] = node_configs
  end
end

function M.setup(dap)
  setup_go(dap)
  setup_javascript(dap)
end

function M.debug_current_file()
  local dap = require("dap")
  if vim.bo.filetype == "go" then
    dap.run({
      type = "go",
      name = "Debug current file",
      request = "launch",
      mode = "debug",
      program = vim.fn.expand("%:p"),
      env = project_env(),
    })
  else
    dap.continue()
  end
end

function M.debug_nearest_go_test()
  if vim.bo.filetype ~= "go" then
    vim.notify("Nearest test debugging is configured for Go files", vim.log.levels.WARN)
    return
  end

  local name = go_test_name()
  if name == nil then
    vim.notify("No nearest Go test found", vim.log.levels.WARN)
    return
  end

  require("dap").run({
    type = "go",
    name = "Debug nearest Go test",
    request = "launch",
    mode = "test",
    program = "${workspaceFolder}",
    args = { "-test.run", "^" .. name .. "$" },
    env = project_env(),
  })
end

function M.debug_go_package_tests()
  require("dap").run({
    type = "go",
    name = "Debug package tests",
    request = "launch",
    mode = "test",
    program = "${workspaceFolder}",
    env = project_env(),
  })
end

function M.debug_go_service()
  require("dap").run({
    type = "go",
    name = "Debug Go service with env vars",
    request = "launch",
    mode = "debug",
    program = "${workspaceFolder}",
    env = project_env(),
    args = split_args(vim.fn.input("Args: ")),
  })
end

function M.debug_cloud_run_local()
  require("dap").run({
    type = "go",
    name = "Debug Cloud Run-like local process",
    request = "launch",
    mode = "debug",
    program = "${workspaceFolder}",
    env = merge_env(project_env(), {
      PORT = vim.env.PORT or "8080",
      K_SERVICE = vim.env.K_SERVICE or "local-service",
      K_REVISION = vim.env.K_REVISION or "local-revision",
      K_CONFIGURATION = vim.env.K_CONFIGURATION or "local-config",
    }),
    args = split_args(vim.fn.input("Args: ")),
  })
end

return M
