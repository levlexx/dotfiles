-- Diagrams: D2 syntax, `d2 fmt` on save and ASCII preview (d2-vim), plus a
-- live browser preview that re-renders on every write (`d2 --watch`, the
-- same as `diag watch`). Mermaid in markdown gets treesitter highlighting.
--   <leader>mw  live preview in the browser (toggle)
--   <leader>ma  ASCII preview split (toggle)
--   <leader>mr  render this file (.d2 -> svg, .py -> png) via diag
--   <leader>mn  new diagram from a template

local function gh(repo)
  return "https://github.com/" .. repo
end

vim.pack.add({ { src = gh("terrastruct/d2-vim") } }, { confirm = false, load = true })

-- d2-vim also maps <leader>d2 (ASCII preview, .d2 buffers) and <leader>yd2
vim.g.d2_ascii_preview_width = math.floor(vim.o.columns / 3)

local watchers = {}

local function stop_watch(file)
  if watchers[file] then
    vim.fn.jobstop(watchers[file])
    watchers[file] = nil
    return true
  end
  return false
end

local function toggle_watch()
  local file = vim.api.nvim_buf_get_name(0)
  if not file:match("%.d2$") then
    vim.notify("not a .d2 file", vim.log.levels.WARN)
    return
  end
  if stop_watch(file) then
    vim.notify("d2 preview stopped")
    return
  end
  watchers[file] = vim.fn.jobstart({ "d2", "--watch", file, (file:gsub("%.d2$", ".svg")) }, {
    env = { D2_LAYOUT = vim.env.D2_LAYOUT or "elk" },
    on_exit = function()
      watchers[file] = nil
    end,
  })
  vim.notify("d2 preview: browser reloads on every :w")
end

local function diag(args)
  vim.system(vim.list_extend({ "diag" }, args), { text = true }, function(res)
    vim.schedule(function()
      local out = vim.trim((res.stdout or "") .. (res.stderr or ""))
      vim.notify(out ~= "" and out or "done", res.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
    end)
  end)
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    for file in pairs(watchers) do
      stop_watch(file)
    end
  end,
})

local map = vim.keymap.set
map("n", "<leader>mw", toggle_watch, { desc = "Diagram: live preview" })
map("n", "<leader>ma", "<cmd>D2PreviewToggle<cr>", { desc = "Diagram: ASCII preview" })
map("n", "<leader>mr", function()
  diag({ "render", vim.api.nvim_buf_get_name(0) })
end, { desc = "Diagram: render file" })
map("n", "<leader>mn", function()
  vim.ui.select({ "service", "sequence", "c4", "deploy", "gcp", "do" }, { prompt = "Template" }, function(template)
    if not template then
      return
    end
    vim.ui.input({ prompt = "Name: " }, function(name)
      if not name or name == "" then
        return
      end
      local res = vim.system({ "diag", "new", name, template }, { text = true }):wait()
      if res.code ~= 0 then
        vim.notify(res.stderr, vim.log.levels.ERROR)
        return
      end
      vim.cmd.edit(vim.fn.fnameescape(vim.split(res.stdout, "\n")[1]))
    end)
  end)
end, { desc = "Diagram: new from template" })
