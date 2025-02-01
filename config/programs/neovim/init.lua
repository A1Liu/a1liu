local home = vim.fs.dirname(vim.fn.resolve(vim.fn.expand('<sfile>:p')))
local cfg_dir = vim.fs.dirname(vim.fs.dirname(home))

Config = {
  home = home,
  cfg_dir = cfg_dir,
  vim_dir = vim.fs.joinpath(cfg_dir, "programs", "vim"),
}

-- Basic configs
vim.cmd('source ' .. vim.fs.joinpath(Config.vim_dir, "init.vim"))

-- vim.print("runtimepath", vim.opt.runtimepath)

-- Re-add the home runtime path because sometimes it gets deleted
vim.opt.runtimepath:append(',' .. Config.home)
local Util = require("util")

Util.import("compat")

Util.import("plugins")

Util.import("gui")

-- vim.print("Path 3" .. Config.home)

