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
      api.config.mappings.default_on_attach(bufnr)

      local opts = {
        buffer = bufnr, noremap = true, silent = true, nowait = true
      }

      vim.keymap.set("n", "<C-K>", "4gk", opts)
      vim.keymap.set("n", "<C-J>", "4gj", opts)

      vim.keymap.set("n", "C", api.tree.change_root_to_node, opts)
      vim.keymap.set("n", "<CR>", api.node.open.no_window_picker, opts)
      vim.keymap.set("n", "D", api.fs.trash, opts)
      vim.keymap.set("n", "a", api.fs.create, opts)
      vim.keymap.set("n", "H", api.tree.toggle_hidden_filter, opts)
      vim.keymap.set("n", "I", api.tree.toggle_gitignore_filter, opts)
      vim.keymap.set("n", "R", api.tree.reload, opts)
      vim.keymap.set("n", "m", api.node.show_info_popup, opts)
      vim.keymap.set("n", "<C-B>", api.tree.close, opts)
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
    local treesitter = require('nvim-treesitter')
    treesitter.setup {
      install_dir = vim.fn.stdpath('data') .. '/tree-sitter',
      highlight = {
        enable = true
      },
    }

    -- treesitter.install {
    --   "lua",
    --   "vim",
    --   "vimdoc",
    --   "graphql",
    -- }

    -- Some kind of weird bug happening in auto-indent for graphql.
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "graphql" },
      callback = function()
        vim.bo.autoindent = true
        vim.bo.smartindent = false
        vim.bo.cindent = false
        vim.bo.indentexpr = ""
      end,
    })
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
        javascript = { require("formatter.filetypes.javascript").prettier, },
        javascriptreact = { require("formatter.filetypes.javascriptreact").prettier, },
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

    -- More configs: (Use Vim's `gx` to go to the URL)
    -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
    vim.lsp.config("lua_ls", {
      settings = { diagnostics = { globals = { "vim" } } }
    })
    vim.lsp.enable("lua_ls")

    vim.lsp.config("pyright", {
      settings = {
        python = {
          analysis = {
            diagnosticSeverityOverrides = {
              -- This took so long to figure out. See `python.analysis.diagnosticSeverityOverrides`
              -- from https://github.com/microsoft/pyright/blob/main/docs/settings.md
              reportPrivateImportUsage = false,
            },
          }
        }
      }
    })
    vim.lsp.enable("pyright")

    -- LSP Config for mypy
    vim.lsp.enable("bashls")
    vim.lsp.enable("gopls")

    vim.lsp.config("ts_ls", {
      on_init = function(client, _)
        client.server_capabilities.semanticTokensProvider = nil -- turn off semantic tokens
      end,
      filetypes = {
        "javascript",
        "typescript",
        "typescriptreact",
        "javascriptreact",
      },
    })
    vim.lsp.enable("ts_ls")

    vim.lsp.enable("rust_analyzer")

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


Plug("folke/snacks.nvim")
Plug("NickvanDyke/opencode.nvim", {
  config = function()
    local opencode = require('opencode')

    vim.keymap.set('n', '<leader>oA', function() opencode.ask() end)
    vim.keymap.set('n', '<leader>op', function() opencode.select_prompt() end)
    vim.keymap.set('n', '<leader>ot', function() opencode.toggle() end)

    vim.keymap.set('n', '<leader>oa', function() opencode.ask('@cursor: ') end)
    vim.keymap.set('v', '<leader>oa', function() opencode.ask('@selection: ') end)
    vim.keymap.set('n', '<leader>on', function() opencode.command('session_new') end)
    vim.keymap.set('n', '<leader>oy', function() opencode.command('messages_copy') end)
    vim.keymap.set('n', '<leader>oe', function() opencode.prompt("Explain @cursor and its context") end)

    -- vim.keymap.set('n', '<S-C-u>',    function() opencode.command('messages_half_page_up') end)
    -- vim.keymap.set('n', '<S-C-d>',    function() opencode.command('messages_half_page_down') end)
  end
})

-- Plug.begin()

Plug.ends()
