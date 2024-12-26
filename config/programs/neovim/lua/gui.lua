local Util = require("util")

local fontsize = vim.g.override_gui_font_size or 11
local font = vim.g.override_gui_font

local lower_os = vim.g.os:lower()
if lower_os == "windows" then
  font = vim.g.override_gui_font or "Consolas"
elseif lower_os == "darwin" then
  font = vim.g.override_gui_font or "Menlo"
elseif lower_os == "linux" then
  font = vim.g.override_gui_font or "Courier"
end

function AdjustFontSize(amount)
  fontsize = fontsize + amount

  vim.o.guifont = font .. ":h" .. tostring(fontsize)
end

AdjustFontSize(0)

vim.keymap.set("n", "<C-+>", Util.curry(AdjustFontSize, 1), {
  silent = true, nowait = true
})
vim.keymap.set("n", "<C-=>", Util.curry(AdjustFontSize, 1), {
  silent = true, nowait = true
})
vim.keymap.set("n", "<C-->", Util.curry(AdjustFontSize, -1), {
  silent = true, nowait = true
})
