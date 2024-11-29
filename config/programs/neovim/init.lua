local home = vim.fs.dirname(vim.fn.resolve(vim.fn.expand('<sfile>:p')))
local cfg_dir = vim.fs.dirname(vim.fs.dirname(home))

Config = {
  home = home,
  cfg_dir = cfg_dir,
  vim_dir = vim.fs.joinpath(cfg_dir, "programs", "vim"),
}


-- Basic configs
vim.cmd('source ' .. vim.fs.joinpath(Config.vim_dir, "init.vim"))

local Util = require("util")

Util.import("compat/mod")
Util.import("plugins")

print("Path" .. Config.home)

