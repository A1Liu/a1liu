"" Plugins

let s:manager_home = PathJoin(g:vim_home_path, 'plugged')
if g:os ==? 'Windows' || g:os ==? 'WSL'
  let s:manager_script_path = PathJoin(g:vim_home_path, 'pathogen.vim')
  let s:manager_script_url = 'https://tpo.pe/pathogen.vim'
else
  let s:manager_script_path = PathJoin(g:vim_home_path, 'plug.vim')
  let s:manager_script_url = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
endif

call DebugPrint('package manager home is: ' . s:manager_home)
call DebugPrint('package manager script is: ' . s:manager_script_path)
call DebugPrint('package manager source URL is: ' . s:manager_script_url)

if empty(glob(s:manager_script_path))
  call DebugPrint('installing package manager...')
  execute 'silent !curl -LSso ' . s:manager_script_path . ' ' . s:manager_script_url
endif

" This forces the loading of the script, so that `sudo vim` can work nicely
execute 'source ' . s:manager_script_path

if g:os !=? 'Windows' && g:os !=? 'WSL'
  call plug#begin()
else
  let g:plugins_list = []
  let g:plugin_paths = []
  function! AddPathogenPlugin(plugin)
    call DebugPrint('adding plugin: ' . a:plugin)
    let plugin_path = PathJoin(s:manager_home, split(a:plugin,'/')[1])
    call add(g:plugins_list, a:plugin)
    call add(g:plugin_paths, plugin_path)
  endfunction

  function! InstallPathogenPlugins()
    let cwd = Cwd()

    for [name, path] in Zip(g:plugins_list, g:plugin_paths)
      if empty(glob(path))
        execute "cd " . s:manager_home
        execute 'silent !git clone https://github.com/' . name
      else
        execute "cd " . path
        execute 'silent !git pull'
      endif
    endfor
    execute "cd " . cwd
    call call('pathogen#infect', g:plugin_paths)
  endfunction

  command! -nargs=1 Plug call AddPathogenPlugin(<args>)
  command! PlugInstall call InstallPathogenPlugins()
endif

if ReadFlag('plugins-base-enabled')
  " Autoformatters
  Plug 'Chiel92/vim-autoformat'
  let s:configfile_def = "'clang-format -lines='.a:firstline.':'.a:lastline.' --assume-filename=\"'.expand('%:p').'\" -style=file'"
  let s:noconfigfile_def = "'clang-format -lines='.a:firstline.':'.a:lastline.' --assume-filename=\"'.expand('%:p').'\"'"
  let g:formatdef_clangformat = "g:ClangFormatConfigFileExists() ? (" . s:configfile_def . ") : (" . s:noconfigfile_def . ")"
  let g:formatdef_swiftformat = "'swiftformat --quiet'"
  let g:formatters_java = ['clangformat']
  let g:formatters_javascript = ['prettier', 'clangformat']
  let g:formatters_arduino = ['clangformat']
  let g:formatters_swift = ['swiftformat']
  if DebugPrint('autoformat in verbose mode')
    let g:autoformat_verbosemode = 1
  else
    let g:autoformat_verbosemode = 0
  endif

  if g:os !=? 'Windows' && g:os !=? 'WSL'
    augroup AutoFormatting
      autocmd!
      autocmd FileType * let b:autoformat_enabled = 0
      autocmd FileType rust,java,c,cpp,go,arduino,swift let b:autoformat_enabled = 1
            \ | let b:autoformat_remove_trailing_spaces = 0
            \ | let b:autoformat_retab = 0
            \ | let b:autoformat_autoindent = 0
      autocmd FileType vim let b:autoformat_enabled = 1
            \ | let b:autoformat_remove_trailing_spaces = 0
      autocmd BufWrite * if exists('b:autoformat_enabled') && b:autoformat_enabled | Autoformat | endif
      autocmd FileType markdown,tex let b:autoformat_autoindent = 0
            \ | let b:autoformat_remove_trailing_spaces = 0
            \ | let b:autoformat_retab = 0
            \ | let b:autoformat_autoindent = 0
    augroup END
  endif

  Plug 'tpope/vim-eunuch'
  Plug 'tpope/vim-fugitive'
endif

if ReadFlag('plugins-solarized-enabled')
  Plug 'lifepillar/vim-solarized8'
endif

" Languages
if ReadFlag('plugins-polyglot-enabled')
  Plug 'sheerun/vim-polyglot'
  let g:rustfmt_autosave = 1
  let g:vim_markdown_math = 1
  let g:vim_markdown_frontmatter = 1
  let g:vim_markdown_folding_disabled = 1
  let g:vim_markdown_new_list_item_indent = 0
  let g:vim_markdown_auto_insert_bullets = 0
endif

" Snippets
if ReadFlag('plugins-snippets-enabled')
  Plug 'SirVer/ultisnips'
  Plug 'honza/vim-snippets'
  let g:UltiSnipsExpandTrigger="<C-N><C-N>"
  let g:UltiSnipsJumpForwardTrigger="<C-R>"
  let g:UltiSnipsJumpBackwardTrigger="<C-E>"
endif

" Language server support because I have to I guess
if ReadFlag('plugins-lsc-enabled')
  Plug 'autozimu/LanguageClient-neovim'
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
