if !GlobFlag('plug-*')
  Dbg 'No plugins enabled'
  finish
endif

"" Plugins
let g:plugin_manager_home = PathJoin(g:vim_home_path, 'plugged')
let g:plugin_manager_script_path = PathJoin(g:vim_home_path, 'plug.vim')
let g:plugin_manager_script_url = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

Dbg 'plugins home is ' . ShortPath(g:plugin_manager_home)
Dbg 'plugin manager is ' . ShortPath(g:plugin_manager_script_path)
Dbg 'plugin manager URL is ' . ShortPath(g:plugin_manager_script_url)

if empty(glob(g:plugin_manager_script_path))
  Dbg 'installing package manager...'
  execute 'silent !curl -LSso ' . g:plugin_manager_script_path . ' ' . g:plugin_manager_script_url
endif

" This forces the loading of the script, so that `sudo vim` can work nicely
execute 'source ' . g:plugin_manager_script_path

call plug#begin(g:plugin_manager_home)

if PlugFlag('base', "UNIX file commands", "Readline support")
  Plug 'tpope/vim-eunuch'
  Plug 'tpope/vim-rsi'

  " Git & Github
  Plug 'tpope/vim-fugitive'
  Plug 'tpope/vim-rhubarb'

  " NOTE: Git integration

  " Some kind of 'show commit for line' functionality
  " https://www.reddit.com/r/vim/comments/i50pce/how_to_show_commit_that_introduced_current_line/
  map <silent><Leader>g :call setbufvar(winbufnr(popup_atcursor(systemlist("cd " . shellescape(fnamemodify(resolve(expand('%:p')), ":h")) . " && git log --no-merges -n 1 -L " . shellescape(line("v") . "," . line(".") . ":" . resolve(expand("%:p")))), { "padding": [1,1,1,1], "pos": "botleft", "wrap": 0 })), "&filetype", "git")<CR>

  " This plugin is supposed to emulate GitLens, but it doesn't play nice with
  " other plugins. Oh well.
  "Plug 'APZelos/blamer.nvim'


  " TODO: Start using these
  " Plug 'machakann/vim-swap'
endif

if PlugFlag('format', "Automatic formatting with :Autoformat")
  " Autoformatters
  Plug 'Chiel92/vim-autoformat'

  let s:clangfmt = "-lines='.a:firstline.':'.a:lastline.' --assume-filename=\"'.expand('%:p').'\" -style=file"
  let g:formatdef_clangformat = "'clang-format " . s:clangfmt . "'"
  let g:formatdef_swiftformat = "'swiftformat --quiet'"
  let g:formatdef_prettier = '"npx prettier --stdin-filepath ".expand("%:p").(&textwidth ? " --print-width ".&textwidth : "")." --tab-width=".shiftwidth()'

  " Meh, clang-format not pulling its weight with Java 19, and also it's not
  " well supported by Java ecosystem, so difficult to get other peeps to use
  " it easily
  " let g:formatters_java = ['clangformat']

  let g:formatters_typescriptreact = ['prettier']
  let g:formatters_javascriptreact = ['prettier']
  let g:formatters_typescript = ['prettier']
  let g:formatters_javascript = ['prettier']
  let g:formatters_svelte = ['prettier']

  let g:formatters_arduino = ['clangformat']
  let g:formatters_swift = ['swiftformat']

  Dbg 'autoformat in verbose mode'
  let g:autoformat_verbosemode = g:debug_mode

  augroup AutoFormatting
    autocmd!
    autocmd FileType * let b:autoformat_enabled = 0
    autocmd FileType rust,java,c,cpp,go,arduino,swift let b:autoformat_enabled = 1
          \ | let b:autoformat_remove_trailing_spaces = 0
          \ | let b:autoformat_retab = 0
          \ | let b:autoformat_autoindent = 0
    autocmd FileType vim let b:autoformat_enabled = 0
    autocmd BufWrite * if exists('b:autoformat_enabled') && b:autoformat_enabled | Autoformat | endif
  augroup END
endif

if PlugFlag('fzf', "Fuzzy filename search", "Fuzzy text search (requires ripgrep)")
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'

  " I wanna make this save previous history, but that's
  " proving very annoying. Not sure what to do yet.

  nnoremap <Leader>F :RG<CR>
  nnoremap <Leader>O :GFiles<CR>

  " Read from clipboard when pressing Ctrl-V
  autocmd! FileType fzf tnoremap <expr> <C-v> getreg(nr2char('"'))

  " Override default fzf actions so that Ctrl-V always does a paste
  let g:fzf_action = { 'ctrl-t': 'tab split' }

  "" VSCode keys
  " 1. File name search
  " 2. File content search
  if has('gui_macvim')
    " NOTE: these commands map to CMD+SHIFT+O and etc. even though this
    " doesn't say it. MacVim actually has native handling of CMD+O and
    " CMD+F, so even though Vim can't tell whether Shift was pressed, MacVim
    " will only run these mappings when shift is pressed.
    nnoremap <D-O> :GFiles<CR>
    nnoremap <D-F> :RG<CR>
  endif
endif

" let g:vim_markdown_math = 1
" let g:vim_markdown_frontmatter = 1
" let g:vim_markdown_folding_disabled = 1
" let g:vim_markdown_new_list_item_indent = 0
" let g:vim_markdown_auto_insert_bullets = 0

" Language server support because I have to I guess
if PlugFlag('lsc', "Language server support for e.g. auto-importing functions")
  Plug 'neoclide/coc.nvim', {'branch': 'release'}

  " \ 'coc-rust-analyzer',

  " coc-tsserver requires `watchman` to do file refactors - https://facebook.github.io/watchman/
  let g:coc_global_extensions = [
        \ 'coc-tsserver',
        \ 'coc-svelte',
        \ 'coc-json',
        \ 'coc-go',
        \]

  " coc#refresh() opens the suggestion menu, and coc#pum#confirm executes
  " the suggestion
  "
  " note that we need to use VimEnter here because otherwise vim-rsi
  " overwrites <C-F> .
  autocmd VimEnter * inoremap <silent><expr> <C-F> coc#pum#visible() ? coc#pum#confirm() : coc#refresh()
  nnoremap <Leader>b <Plug>(coc-definition)
  nnoremap <Leader>n :call CocAction('jumpDefinition', 'split')<CR>
  nnoremap <Leader>v :call CocAction('jumpDefinition', 'vsplit')<CR>
  nnoremap <C-F> <Plug>(coc-codeaction-cursor)
  vnoremap <C-F> <Nop>

  nnoremap <C-E> :call CocAction('definitionHover')<CR>

  nnoremap <Leader>w <Plug>(coc-rename)
  nnoremap <Leader>e <Plug>(coc-codeaction-cursor)

  " Using <C-J> and <C-K> for navigating the pop-up menu
  " inoremap <C-N><C-O> <C-N>
  " inoremap <C-N><C-O> <C-X><C-O>
  " inoremap <C-N> <Nop>
  " inoremap <C-N><C-T> <C-N>
  " inoremap <expr> <C-D> pumvisible() ? "\<C-N>\<C-N>\<C-N>\<C-N>\<C-N>" : "\<C-D>"
  " inoremap <expr> <C-U> pumvisible() ? "\<C-P>\<C-P>\<C-P>\<C-P>\<C-P>" : "\<C-U>"
  inoremap <expr> <C-J> coc#pum#visible() ? "\<C-N>" : "\<C-J>"
  inoremap <expr> <C-K> coc#pum#visible() ? "\<C-P>" : "\<C-K>"
endif

call plug#end()
