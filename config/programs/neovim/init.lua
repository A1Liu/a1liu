local home = vim.fs.dirname(vim.fn.resolve(vim.fn.expand('<sfile>:p')))
local cfg_dir = vim.fs.dirname(vim.fs.dirname(home))

Config = {
  home = home,
  cfg_dir = cfg_dir,
  vim_dir = vim.fs.joinpath(cfg_dir, "programs", "vim"),
}

local Util = require("util")

-- print("Path" .. Config.home)
Util.hello()

vim.cmd('source ' .. vim.fs.joinpath(Config.vim_dir, "init.vim"))
