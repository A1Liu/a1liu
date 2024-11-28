local home = vim.fs.dirname(vim.fn.resolve(vim.fn.expand('<sfile>:p')))
local cfg_dir = vim.fs.dirname(vim.fs.dirname(home))

Config = {
  home = home,
  cfg_dir = cfg_dir,
  vim_dir = vim.fs.joinpath(cfg_dir, "programs", "vim"),
  vim_dir = vim.fs.joinpath(cfg_dir, "programs", "vim"),
}

-- print("Path" .. Config.home)

vim.cmd('source ' .. vim.fs.joinpath(Config.vim_dir, "init.vim"))
