local capabilities = vim.lsp.protocol.make_client_capabilities()
local blink_ok, blink = pcall(require, "blink.cmp")
if blink_ok then
  capabilities = blink.get_lsp_capabilities(capabilities)
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
      require("fzf-lua").lsp_references()
    end, "References")

    map("n", "<leader>cs", function()
      require("fzf-lua").lsp_document_symbols()
    end, "Document symbols")

    map("n", "<leader>cS", function()
      require("fzf-lua").lsp_workspace_symbols()
    end, "Workspace symbols")
  end,
})

vim.lsp.config("gopls", {
  capabilities = capabilities,
  settings = {
    gopls = {
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
      experimental = {
        maxInlayHintLength = 30,
        completion = {
          enableServerSideFuzzyMatch = true,
        },
      },
    },
    typescript = {
      updateImportsOnFileMove = { enabled = "always" },
      suggest = {
        completeFunctionCalls = true,
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
  },
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
  "vtsls",
  "tsp_server",
  "jsonls",
  "yamlls",
  "dockerls",
  "docker_compose_language_service",
})
