local Util = require("util")

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

local Plug = Util.import("vim-plug")

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

Plug("nvim-treesitter/nvim-treesitter", {
  run = function()
    vim.cmd('TSUpdate')
  end,  -- We recommend updating the parsers on update
})

Plug("neovim/nvim-lspconfig")

vim.api.nvim_set_keymap('v', '<C-F>', '', { noremap = true })
vim.api.nvim_set_keymap('n', '<C-F>', '', {
    noremap = true,
    callback = function()
      vim.lsp.buf.hover() -- goto def
    end
})
vim.api.nvim_set_keymap('n', '<Leader>b', '', {
    noremap = true,
    callback = function()
      vim.lsp.buf.implementation() -- goto def
    end
})
vim.api.nvim_set_keymap('n', '<C-E>', '', {
    noremap = true,
    callback = function()
      vim.lsp.buf.hover()
    end
})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    vim.print("LSP Attached!")

    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client.supports_method('textDocument/implementation') then
    end

    if client.supports_method('textDocument/completion') then
      -- Enable auto-completion
      -- vim.lsp.completion.enable(true, client.id, args.buf, {autotrigger = true})
    end
    if client.supports_method('textDocument/formatting') then
      -- Format the current buffer on save
      vim.api.nvim_create_autocmd('BufWritePre', {
        buffer = args.buf,
        callback = function()
          vim.lsp.buf.format({bufnr = args.buf, id = client.id})
        end,
      })
    end
  end,
})

-- Plug.begin()

Plug.ends()

-- require('lspconfig').pyright.setup{}
require('lspconfig').ts_ls.setup {
  on_init = function(client, _)
    client.server_capabilities.semanticTokensProvider = nil  -- turn off semantic tokens
  end,
  filetypes = {
    "javascript",
    "typescript",
    "typescriptreact",
    "javascriptreact",
  },
}

--[[
require('nvim-treesitter.configs').setup {
  highlight = {
    enable = true
  }
}
]]--
