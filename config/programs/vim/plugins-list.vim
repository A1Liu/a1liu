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

if PlugFlag('format-womp', "Automatic formatting with :Autoformat")
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

if PlugFlag('files', "enables NERDTree") && !has('nvim')
  Plug 'preservim/nerdtree'
  let g:NERDTreeMapJumpNextSibling = ""
  let g:NERDTreeMapJumpPrevSibling = ""

  function! SmartNERDTree()
    if @% == ""
      NERDTreeFocus
    else
      NERDTreeFind
    endif
  endfun

  augroup NerdTree
    au!

    "" VSCode key - Toggle the file viewer
    nnoremap <C-B> :call SmartNERDTree()<CR>
    au BufEnter NERD_Tree_*
          \ nnoremap <buffer> <C-B> :NERDTreeClose<CR>

    au BufEnter NERD_Tree_* nnoremap <buffer> <C-J> 4gj
    au BufEnter NERD_Tree_* nnoremap <buffer> <C-K> 4gk
    au BufEnter NERD_Tree_* vnoremap <buffer> <C-J> 4gj
    au BufEnter NERD_Tree_* vnoremap <buffer> <C-K> 4gk
  augroup end
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

" Snippets
if PlugFlag('snippets', "Snippets") && !has("gui_macvim")
  Plug 'SirVer/ultisnips'
  Plug 'honza/vim-snippets'

  let g:UltiSnipsExpandTrigger="<C-N><C-N>"
  let g:UltiSnipsJumpForwardTrigger="<C-R>"
  let g:UltiSnipsJumpBackwardTrigger="<C-E>"
endif

if has('nvim')
else
  call plug#end()
endif
