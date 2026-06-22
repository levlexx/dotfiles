local icons_ok, icons = pcall(require, "mini.icons")
if icons_ok then
  icons.setup()
  icons.mock_nvim_web_devicons()
end

local ai_ok, ai = pcall(require, "mini.ai")
if ai_ok then
  ai.setup()
end

local pairs_ok, pairs = pcall(require, "mini.pairs")
if pairs_ok then
  pairs.setup()
end
