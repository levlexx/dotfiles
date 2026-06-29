local capabilities = vim.lsp.protocol.make_client_capabilities()
local blink_ok, blink = pcall(require, "blink.cmp")
if blink_ok then
  capabilities = blink.get_lsp_capabilities(capabilities)
end

local heavy_dirs = {
  "**/node_modules",
  "**/.git",
  "**/.angular",
  "**/.nx",
  "**/dist",
  "**/build",
  "**/coverage",
  "**/vendor",
}

local function has_path(path)
  return vim.uv.fs_stat(path) ~= nil
end

local function has_package(root, name)
  local package_json = root .. "/package.json"
  if not has_path(package_json) then
    return false
  end

  local ok, content = pcall(vim.fn.readfile, package_json)
  if not ok then
    return false
  end

  local json_ok, package = pcall(vim.json.decode, table.concat(content, "\n"))
  if not json_ok or type(package) ~= "table" then
    return false
  end

  local dependencies = package.dependencies or {}
  local dev_dependencies = package.devDependencies or {}
  return dependencies[name] ~= nil or dev_dependencies[name] ~= nil
end

local function angular_root_dir(bufnr, on_dir)
  local file = vim.api.nvim_buf_get_name(bufnr)
  local root = vim.fs.root(file, { "angular.json", "nx.json" })
  if root == nil then
    return
  end

  if has_path(root .. "/angular.json") or has_package(root, "@angular/core") or has_path(root .. "/node_modules/@angular/core") then
    on_dir(root)
  end
end

vim.diagnostic.config({
  severity_sort = true,
  virtual_text = {
    spacing = 4,
    source = "if_many",
  },
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLsp", { clear = true }),
  callback = function(event)
    local bufnr = event.buf
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
    end

    map("n", "gd", vim.lsp.buf.definition, "Goto definition")
    map("n", "gD", vim.lsp.buf.declaration, "Goto declaration")
    map("n", "gI", vim.lsp.buf.implementation, "Goto implementation")
    map("n", "gy", vim.lsp.buf.type_definition, "Goto type definition")
    map("n", "K", vim.lsp.buf.hover, "Hover")
    map("n", "gK", vim.lsp.buf.signature_help, "Signature help")
    map("i", "<C-k>", vim.lsp.buf.signature_help, "Signature help")
    map({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("n", "<leader>cr", vim.lsp.buf.rename, "Rename")

    map("n", "gr", function()
      require("plugins.fzf").run("lsp_references")
    end, "References")

    map("n", "<leader>cs", function()
      require("plugins.fzf").run("lsp_document_symbols")
    end, "Document symbols")

    map("n", "<leader>cS", function()
      require("plugins.fzf").run("lsp_workspace_symbols")
    end, "Workspace symbols")
  end,
})

vim.lsp.config("gopls", {
  capabilities = capabilities,
  settings = {
    gopls = {
      ["build.directoryFilters"] = {
        "-**/node_modules",
        "-**/.git",
        "-**/.angular",
        "-**/.nx",
        "-**/dist",
        "-**/build",
        "-**/coverage",
        "-**/vendor",
      },
      ["ui.diagnostic.diagnosticsDelay"] = "500ms",
      gofumpt = true,
      staticcheck = false,
      vulncheck = "Prompt",
      usePlaceholders = true,
      completeUnimported = true,
      analyses = {
        nilness = true,
        shadow = true,
        unusedparams = true,
        unusedwrite = true,
      },
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
    },
  },
})

vim.lsp.config("lua_ls", {
  capabilities = capabilities,
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        checkThirdParty = false,
        library = vim.api.nvim_get_runtime_file("", true),
      },
      telemetry = { enable = false },
      hint = { enable = true },
    },
  },
})

vim.lsp.config("vtsls", {
  capabilities = capabilities,
  settings = {
    complete_function_calls = true,
    vtsls = {
      enableMoveToFileCodeAction = true,
      autoUseWorkspaceTsdk = true,
      tsserver = {
        maxTsServerMemory = 4096,
        watchOptions = {
          excludeDirectories = heavy_dirs,
          excludeFiles = {
            "**/.git/**",
            "**/.angular/**",
            "**/.nx/**",
            "**/dist/**",
            "**/build/**",
            "**/coverage/**",
          },
        },
      },
      experimental = {
        maxInlayHintLength = 30,
        completion = {
          enableServerSideFuzzyMatch = true,
        },
      },
    },
    typescript = {
      updateImportsOnFileMove = { enabled = "always" },
      preferences = {
        importModuleSpecifier = "shortest",
        importModuleSpecifierEnding = "minimal",
        includePackageJsonAutoImports = "on",
        quoteStyle = "auto",
      },
      suggest = {
        autoImports = true,
        classMemberSnippets = { enabled = true },
        completeFunctionCalls = true,
        completeJSDocs = true,
        enabled = true,
        includeAutomaticOptionalChainCompletions = true,
        includeCompletionsForImportStatements = true,
        objectLiteralMethodSnippets = { enabled = true },
        paths = true,
      },
      inlayHints = {
        enumMemberValues = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        parameterNames = { enabled = "literals" },
        parameterTypes = { enabled = true },
        propertyDeclarationTypes = { enabled = true },
        variableTypes = { enabled = false },
      },
    },
    javascript = {
      updateImportsOnFileMove = { enabled = "always" },
      preferences = {
        importModuleSpecifier = "shortest",
        importModuleSpecifierEnding = "minimal",
        quoteStyle = "auto",
      },
      suggest = {
        autoImports = true,
        classMemberSnippets = { enabled = true },
        completeFunctionCalls = true,
        completeJSDocs = true,
        enabled = true,
        includeAutomaticOptionalChainCompletions = true,
        includeCompletionsForImportStatements = true,
        paths = true,
      },
    },
  },
})

vim.lsp.config("angularls", {
  capabilities = capabilities,
  root_dir = angular_root_dir,
})

vim.lsp.config("tsp_server", {
  capabilities = capabilities,
})

vim.lsp.config("jsonls", {
  capabilities = capabilities,
  settings = {
    json = {
      validate = { enable = true },
    },
  },
})

vim.lsp.config("yamlls", {
  capabilities = capabilities,
  settings = {
    redhat = { telemetry = { enabled = false } },
    yaml = {
      keyOrdering = false,
      validate = true,
      format = { enable = true },
    },
  },
})

vim.lsp.config("dockerls", {
  capabilities = capabilities,
})

vim.lsp.config("docker_compose_language_service", {
  capabilities = capabilities,
})

vim.lsp.enable({
  "gopls",
  "lua_ls",
  "angularls",
  "vtsls",
  "tsp_server",
  "jsonls",
  "yamlls",
  "dockerls",
  "docker_compose_language_service",
})
