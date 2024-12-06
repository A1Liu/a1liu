local Util = require("util")

local Plug = Util.import("vim-plug")

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true
Plug('nvim-tree/nvim-tree.lua')
Plug('nvim-tree/nvim-web-devicons') -- optional

vim.g.NERDTreeMapJumpNextSibling = ""
vim.g.NERDTreeMapJumpPrevSibling = ""

vim.api.nvim_set_keymap('n', '<C-B>', '', {
  noremap = true,
  callback = function()
    if string.find(vim.bo.filetype, "nerdtree") then
      vim.cmd('NvimTreeToggle')
    elseif vim.fn.expand("%") == "" then
      vim.cmd('NvimTreeFocus')
    else
      vim.cmd('NvimTreeFindFile')
    end
  end
})

Plug("nvim-treesitter/nvim-treesitter", {
  run = function()
    vim.cmd('TSUpdate')
  end,  -- We recommend updating the parsers on update
})

Plug("williamboman/mason.nvim")
Plug("williamboman/mason-lspconfig.nvim")
Plug("neovim/nvim-lspconfig")

vim.keymap.set('v', '<C-F>', '', { noremap = true })
vim.keymap.set('n', '<C-F>', vim.lsp.buf.code_action, {
    noremap = true,
})
vim.keymap.set('n', '<Leader>b', vim.lsp.buf.implementation, {
    noremap = true,
})
vim.keymap.set('n', '<C-E>', vim.lsp.buf.hover, {
    noremap = true,
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

require("nvim-tree").setup({
 renderer = {
    icons = {
      show = {
        git = true,
        file = false,
        folder = false,
        folder_arrow = true,
      },
      glyphs = {
        folder = {
          arrow_closed = "⏵",
          arrow_open = "⏷",
        },
        git = {
          unstaged = "✗",
          staged = "✓",
          unmerged = "⌥",
          renamed = "➜",
          untracked = "★",
          deleted = "⊖",
          ignored = "◌",
        },
      },
    },
  },
  on_attach = function(bufnr)
    local api = require("nvim-tree.api")
    vim.keymap.set("n", "C", api.tree.change_root_to_node, {
      buffer = bufnr, noremap = true, silent = true, nowait = true
    })
    vim.keymap.set("n", "<CR>", api.node.open.no_window_picker, {
      buffer = bufnr, noremap = true, silent = true, nowait = true
    })
    vim.keymap.set("n", "D", api.fs.trash, {
      buffer = bufnr, noremap = true, silent = true, nowait = true
    })
    vim.keymap.set("n", "a", api.fs.create, {
      buffer = bufnr, noremap = true, silent = true, nowait = true
    })
    vim.keymap.set("n", "H", api.tree.toggle_hidden_filter, {
      buffer = bufnr, noremap = true, silent = true, nowait = true
    })
    vim.keymap.set("n", "I", api.tree.toggle_gitignore_filter, {
      buffer = bufnr, noremap = true, silent = true, nowait = true
    })
  end
})

require("mason").setup()
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
  },
  ensure_installed = {
    "c",
    "lua",
    "vim",
    "zig",
    "vimdoc",
  },
}
]]--
