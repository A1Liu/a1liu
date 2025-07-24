local Util = require("util")

local Plug = Util.import("vim-plug")

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true
Plug('nvim-tree/nvim-tree.lua', {
  config = function()
    local tree = require("nvim-tree")
    local api = require("nvim-tree.api")
    vim.api.nvim_set_keymap('n', '<C-B>', '', {
      noremap = true,
      callback = function()
        if vim.fn.expand("%") == "" then
          vim.cmd('NvimTreeFocus')
        else
          vim.cmd('NvimTreeFindFile')
        end
      end
    })

    local on_attach = function(bufnr)
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
      vim.keymap.set("n", "R", api.tree.reload, {
        buffer = bufnr, noremap = true, silent = true, nowait = true
      })
      vim.keymap.set("n", "<C-B>", api.tree.close, {
        buffer = bufnr, noremap = true, silent = true, nowait = true
      })
      vim.keymap.set("n", "m", api.node.show_info_popup, {
        buffer = bufnr, noremap = true, silent = true, nowait = true
      })
    end

    tree.setup({
      on_attach = on_attach,
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
    })
  end
})

Plug("nvim-treesitter/nvim-treesitter", {
  run = function()
    vim.cmd('TSUpdate')
  end, -- We recommend updating the parsers on update
  config = function()
    require('nvim-treesitter.configs').setup {
      highlight = {
        enable = true
      },
      ensure_installed = {
        "lua",
        "vim",
        "vimdoc",
        "graphql",
      },
    }
  end,
})

Plug('mhartington/formatter.nvim', {
  config = function()
    -- local util = require "formatter.util"
    require("formatter").setup {
      -- logging = true,
      -- log_level = vim.log.levels.DEBUG,
      filetype = {
        lua = { require("formatter.filetypes.lua").stylua, },
        typescript = { require("formatter.filetypes.typescript").prettier, },
        typescriptreact = { require("formatter.filetypes.typescriptreact").prettier, },
        rust = { require("formatter.filetypes.rust").rustfmt, },
        go = { require("formatter.filetypes.go").gofmt, },
      }
    }

    vim.keymap.set('n', '<Leader><C-F>', vim.cmd.Format, {
      noremap = true,
    })

    local auformat_group = vim.api.nvim_create_augroup("AutoFormatting", {
      clear = true,
    })

    local enabled_file_types = {
      -- ["rust"] = 1,
      ["java"] = 1,
      ["c"] = 1,
      ["cpp"] = 1,
      ["go"] = 1,
      ["arduino"] = 1,
      ["swift"] = 1,
      ["typescriptreact"] = 1,
    }

    vim.api.nvim_create_autocmd('FileType', {
      group = auformat_group,
      callback = function()
        if enabled_file_types[vim.bo.filetype] == 1 then
          vim.b.autoformat_enabled = 1

          vim.b.autoformat_remove_trailing_spaces = 0
          vim.b.autoformat_retab = 0
          vim.b.autoformat_autoindent = 0
        else
          vim.b.autoformat_enabled = 0
        end
      end,
    })

    vim.api.nvim_create_autocmd('BufWritePost', {
      group = auformat_group,
      callback = function()
        if vim.b.autoformat_enabled ~= 1 then
          return
        end

        vim.cmd("Format")
      end,
    })
  end
})

--[[
Likely installs:
- typescript-language-server
- lua-language-server
- prettier
]] --
Plug("williamboman/mason.nvim")
Plug("williamboman/mason-lspconfig.nvim")
Plug("neovim/nvim-lspconfig", {
  config = function()
    -- Setup order matters here
    require("mason").setup()
    require("mason-lspconfig").setup()

    local lspconfig = require('lspconfig')

    -- More configs: (Use Vim's `gx` to go to the URL)
    -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
    lspconfig.lua_ls.setup {
      settings = { diagnostics = { globals = { "vim" } } }
    }

    lspconfig.pyright.setup {}

    lspconfig.bashls.setup {}

    lspconfig.gopls.setup {}

    lspconfig.ts_ls.setup {
      on_init = function(client, _)
        client.server_capabilities.semanticTokensProvider = nil -- turn off semantic tokens
      end,
      filetypes = {
        "javascript",
        "typescript",
        "typescriptreact",
        "javascriptreact",
      },
    }

    lspconfig.rust_analyzer.setup {}

    vim.keymap.set('v', '<C-F>', '', { noremap = true })
    vim.keymap.set('n', '<C-F>', vim.lsp.buf.code_action, {
      noremap = true,
    })
    vim.keymap.set('n', '<Leader>w', vim.lsp.buf.rename, {
      noremap = true,
    })

    -- Forgot how to do this, had to use vim tutorial to help:
    -- https://vim.fandom.com/wiki/Improve_completion_popup_menu
    --
    -- note that we need to use VimEnter here because otherwise vim-rsi
    -- overwrites <C-F> .
    vim.api.nvim_create_autocmd('VimEnter', {
      callback = function()
        vim.keymap.set('i', '<C-F>', function()
          if vim.fn.pumvisible() == 1 then
            -- Confirm in omnifunc
            return "<C-Y>"
          else
            -- Open in omnifunc
            return "<C-X><C-O>"
          end
        end, { noremap = true, expr = true })
      end,
    })

    -- Using <C-J> and <C-K> for navigating the pop-up menu
    -- inoremap <C-N><C-O> <C-N>
    -- inoremap <C-N><C-O> <C-X><C-O>
    -- inoremap <C-N> <Nop>
    -- inoremap <C-N><C-T> <C-N>
    -- inoremap <expr> <C-D> pumvisible() ? "\<C-N>\<C-N>\<C-N>\<C-N>\<C-N>" : "\<C-D>"
    -- inoremap <expr> <C-U> pumvisible() ? "\<C-P>\<C-P>\<C-P>\<C-P>\<C-P>" : "\<C-U>"
    vim.keymap.set('i', '<C-J>', function()
      if vim.fn.pumvisible() == 1 then
        return "<C-N>"
      else
        return "<C-J>"
      end
    end, { noremap = true, expr = true })

    vim.keymap.set('i', '<C-K>', function()
      if vim.fn.pumvisible() == 1 then
        return "<C-P>"
      else
        return "<C-K>"
      end
    end, { noremap = true, expr = true })

    vim.keymap.set('n', '<Leader>b', vim.lsp.buf.implementation, {
      noremap = true,
    })

    vim.keymap.set('n', '<Leader>e', vim.diagnostic.open_float, {
      noremap = true,
    });

    vim.keymap.set('n', '<C-E>', vim.lsp.buf.hover, {
      noremap = true,
    })
    -- inoremap <silent><expr> <Tab> pumvisible() ? "\<C-n>" : "\<C-x>\<C-o>"

    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function()
        vim.print("LSP Attached!")

        -- local client = vim.lsp.get_client_by_id(args.data.client_id)
        -- if client.supports_method('textDocument/implementation') then
        -- end

        --[[
        if client.supports_method('textDocument/completion') then
           -- Enable auto-completion
           vim.lsp.completion.enable(true, client.id, args.buf, {autotrigger = true})
        end
        ]] --
      end,
    })
  end
})

-- Plug.begin()

Plug.ends()
