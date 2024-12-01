local home = vim.fs.dirname(vim.fn.resolve(vim.fn.expand('<sfile>:p')))
local cfg_dir = vim.fs.dirname(vim.fs.dirname(home))

print("stdpath" .. vim.fn.stdpath('config'))

Config = {
  home = home,
  cfg_dir = cfg_dir,
  vim_dir = vim.fs.joinpath(cfg_dir, "programs", "vim"),
}

print("Config ", Config)

-- Basic configs
vim.cmd('source ' .. vim.fs.joinpath(Config.vim_dir, "init.vim"))

print("Path 2" .. Config.home)

vim.print("runtimepath", vim.opt.runtimepath)

-- require("compat.mod")
vim.opt.runtimepath:append(',' .. Config.home)
local Util = require("util")

Util.import("compat")
Util.import("plugins")

-- print("Path" .. Config.home)
print("Path 3" .. Config.home)

