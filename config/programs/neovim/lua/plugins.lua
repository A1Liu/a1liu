-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
        { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
        { out, "WarningMsg" },
        { "\nPress any key to exit..." },
      }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
local lazy_plugins = require("lazy")

local PluginsSpec = {}

table.insert(
  PluginsSpec,
  {"nvim-treesitter/nvim-treesitter", build = ":TSUpdate"}
  )

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

[[
local id = vim.api.nvim_create_augroup("NerdTree", {
    clear = true
  })

vim.api.nvim_create_autocmd({"BufEnter"}, {
    pattern = {"nerdtree"},
    group = id,
    callback = function(ev)
      vim.b.ALIU_NERDTREE_BUFFER = true

      -- vim.api.nvim_buf_set_keymap('n', '<C-J>', '4gj', {
      --     noremap = true,
      --   })

      -- vim.api.nvim_buf_set_keymap('n', '<C-J>', '4gj', {
      --     noremap = true,
      --   })
      -- vim.api.nvim_buf_set_keymap('n', '<C-K>', '4gk', {
      --     noremap = true,
      --   })
      -- vim.api.nvim_buf_set_keymap('v', '<C-J>', '4gj', {
      --     noremap = true,
      --   })
      -- vim.api.nvim_buf_set_keymap('v', '<C-K>', '4gk', {
      --     noremap = true,
      --   })
    end
  })
]]

lazy_plugins.setup({
    spec = PluginsSpec,

    -- Configure any other settings here. See the documentation for more details.
    -- colorscheme that will be used when installing plugins.
    install = { colorscheme = { "wildcharm" } },
    -- automatically check for plugin updates
    -- checker = { enabled = true, notify = false },
  })
