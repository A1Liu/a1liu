"" Plugins

let g:plugin_manager_home = PathJoin(g:vim_home_path, 'plugged')
if g:os ==? 'Windows' || g:os ==? 'WSL'
  let g:plugin_manager_script_path = PathJoin(g:vim_home_path, 'pathogen.vim')
  let g:plugin_manager_script_url = 'https://tpo.pe/pathogen.vim'
else
  let g:plugin_manager_script_path = PathJoin(g:vim_home_path, 'plug.vim')
  let g:plugin_manager_script_url = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
endif

Dbg 'plugins home is ' . ShortPath(g:plugin_manager_home)
Dbg 'plugin manager is ' . ShortPath(g:plugin_manager_script_path)
Dbg 'plugin manager URL is ' . ShortPath(g:plugin_manager_script_url)

if empty(glob(g:plugin_manager_script_path))
  Dbg 'installing package manager...'
  execute 'silent !curl -LSso ' . g:plugin_manager_script_path . ' ' . g:plugin_manager_script_url
endif

" This forces the loading of the script, so that `sudo vim` can work nicely
execute 'source ' . g:plugin_manager_script_path

"" TODO try to use vim-plug instead of pathogen on Windows again
if g:os !=? 'Windows' && g:os !=? 'WSL'
  call plug#begin()
else
  let g:plugins_list = []
  let g:plugin_paths = []
  function! AddPathogenPlugin(...)
    let plugin = a:1
    Dbg 'adding plugin: ' . plugin)
    let plugin_path = PathJoin(g:plugin_manager_home, split(plugin,'/')[1])
    call add(g:plugins_list, plugin)
    call add(g:plugin_paths, plugin_path)
  endfunction

  function! InstallPathogenPlugins()
    let cwd = Cwd()

    for [name, path] in Zip(g:plugins_list, g:plugin_paths)
      if empty(glob(path))
        execute "cd " . g:plugin_manager_home
        execute 'silent !git clone https://github.com/' . name
      else
        execute "cd " . path
        execute 'silent !git pull'
      endif
    endfor
    execute "cd " . cwd
    call call('pathogen#infect', g:plugin_paths)
  endfunction

  command! -nargs=* Plug :call AddPathogenPlugin(<args>)
  command! PlugInstall :call InstallPathogenPlugins()
endif

if ReadFlag('plugins-base-enabled')
  " Autoformatters
  Plug 'Chiel92/vim-autoformat'
  let s:configfile_def = "'clang-format -lines='.a:firstline.':'.a:lastline.' --assume-filename=\"'.expand('%:p').'\" -style=file'"
  let s:noconfigfile_def = "'clang-format -lines='.a:firstline.':'.a:lastline.' --assume-filename=\"'.expand('%:p').'\"'"
  let g:formatdef_clangformat = "g:ClangFormatConfigFileExists() ? (" . s:configfile_def . ") : (" . s:noconfigfile_def . ")"
  let g:formatdef_swiftformat = "'swiftformat --quiet'"
  let g:formatters_java = ['clangformat']
  let g:formatters_typescriptreact = ['prettier']
  let g:formatters_typescript = ['prettier']
  let g:formatters_javascript = ['prettier']
  let g:formatters_arduino = ['clangformat']
  let g:formatters_swift = ['swiftformat']
  Dbg 'autoformat in verbose mode'
  let g:autoformat_verbosemode = g:debug_mode

  if g:os !=? 'Windows' && g:os !=? 'WSL'
    augroup AutoFormatting
      autocmd!
      autocmd FileType * let b:autoformat_enabled = 0
      autocmd FileType rust,java,c,cpp,go,arduino,swift let b:autoformat_enabled = 1
            \ | let b:autoformat_remove_trailing_spaces = 0
            \ | let b:autoformat_retab = 0
            \ | let b:autoformat_autoindent = 0
      autocmd FileType vim let b:autoformat_enabled = 0
      autocmd BufWrite * if exists('b:autoformat_enabled') && b:autoformat_enabled | Autoformat | endif
      autocmd FileType markdown,tex let b:autoformat_autoindent = 0
            \ | let b:autoformat_remove_trailing_spaces = 0
            \ | let b:autoformat_retab = 0
            \ | let b:autoformat_autoindent = 0
    augroup END
  endif


  Plug 'tpope/vim-eunuch'
  Plug 'tpope/vim-fugitive'
  Plug '~/code/liu/vim-liu'
endif

if ReadFlag('plugins-eval-enabled')
  Plug 'vim-scripts/EvalSelection.vim'
endif

if ReadFlag('plugins-solarized-enabled')
  Plug 'lifepillar/vim-solarized8'
endif

" Languages
let polyglot_enabled = ReadFlag('plugins-polyglot-enabled')
let markdown_enabled = polyglot_enabled || ReadFlag('plugins-markdown-enabled')
if polyglot_enabled
  Plug 'sheerun/vim-polyglot'
  Plug 'jansedivy/jai.vim'
endif
if markdown_enabled && !polyglot_enabled
  Plug 'plasticboy/vim-markdown'
endif
if markdown_enabled
  let g:vim_markdown_math = 1
  let g:vim_markdown_frontmatter = 1
  let g:vim_markdown_folding_disabled = 1
  let g:vim_markdown_new_list_item_indent = 0
  let g:vim_markdown_auto_insert_bullets = 0
endif


" Snippets
if ReadFlag('plugins-snippets-enabled') && !has("gui_macvim")
  Plug 'SirVer/ultisnips'
  Plug 'honza/vim-snippets'
  let g:UltiSnipsExpandTrigger="<C-N><C-N>"
  let g:UltiSnipsJumpForwardTrigger="<C-R>"
  let g:UltiSnipsJumpBackwardTrigger="<C-E>"
endif

" Language server support because I have to I guess
if ReadFlag('plugins-lsc-enabled')
  Plug 'autozimu/LanguageClient-neovim', {
        \ 'branch': 'next',
        \ 'do': 'bash install.sh',
        \ }

  if g:os !=? 'Windows'
    let g:LanguageClient_serverCommands = {
          \ 'rust' : ['~/.cargo/bin/rustup', 'run', 'stable', 'rls'],
          \ 'go'   : ['gopls'],
          \ }
  else
    let g:LanguageClient_serverCommands = {
          \ 'rust' : ['~/.cargo/bin/rustup.exe', 'run', 'stable', 'rls'],
          \ 'go'   : ['gopls'],
          \ }

    let g:LanguageClient_diagnosticsDisplay = {
          \ 1: {
          \     "name": "Error",
          \     "texthl": "ALEError",
          \     "signText": "x",
          \     "signTexthl": "ALEErrorSign",
          \     "virtualTexthl": "Error",
          \ },
          \ 2: {
          \     "name": "Warning",
          \     "texthl": "ALEWarning",
          \     "signText": "!",
          \     "signTexthl": "ALEWarningSign",
          \     "virtualTexthl": "Todo",
          \ },
          \ 3: {
          \     "name": "Information",
          \     "texthl": "ALEInfo",
          \     "signText": "i",
          \     "signTexthl": "ALEInfoSign",
          \     "virtualTexthl": "Todo",
          \ },
          \ 4: {
          \     "name": "Hint",
          \     "texthl": "ALEInfo",
          \     "signText": "?",
          \     "signTexthl": "ALEInfoSign",
          \     "virtualTexthl": "Todo",
          \ },
          \  }

  endif
  command! LCRename :call LanguageClient#textDocument_rename()
  command! LCHover :call LanguageClient#textDocument_hover()
  command! LCAction :call LanguageClient_textDocument_codeAction()
  command! LCContext :call LanguageClient_contextMenu()
  command! LCStart LanguageClientStart
  command! LCStart LanguageClientStart
  command! LCStop LanguageClientStop
endif

if g:os !=? 'Windows' && g:os !=? 'WSL'
  call plug#end()
else
  call call('pathogen#infect', g:plugin_paths)
endif
