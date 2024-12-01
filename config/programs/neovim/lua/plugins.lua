local PluginsSpec = {}

table.insert(PluginsSpec, {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = {
        "c",
        "lua",
        "vim",
        "zig",
        "vimdoc",
      },
    })
  end,
})

table.insert(PluginsSpec, {"preservim/nerdtree"})

vim.g.NERDTreeMapJumpNextSibling = ""
vim.g.NERDTreeMapJumpPrevSibling = ""

vim.api.nvim_set_keymap('n', '<C-B>', '', {
  noremap = true,
  callback = function()

    if string.find(vim.bo.filetype, "nerdtree") then
      vim.cmd('NERDTreeClose')
    elseif vim.fn.expand("%") == "" then
      vim.cmd('NERDTreeFocus')
    else
      vim.cmd('NERDTreeFind')
    end
  end
})

