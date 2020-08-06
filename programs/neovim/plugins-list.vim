"" Plugins

let s:plug_home = PathJoin(g:vim_home_path, 'plugged')
let s:pathogen_home = PathJoin(g:vim_home_path, 'bundle')
let s:plug_script_path = PathJoin(g:vim_home_path, 'plug.vim')
let s:pathogen_script_path = PathJoin(g:vim_home_path, 'pathogen.vim')
let g:plugins_installed = ReadFlag('plugins-installed')
call DebugPrint('plug home is: ' . s:plug_home)
call DebugPrint('pathogen home is: ' . s:pathogen_home)
call DebugPrint('plug script is: ' . s:plug_script_path)
call DebugPrint('pathogen script is: ' . s:pathogen_script_path)

let s:plugins_list = []
function! InstallPathogenPlugin(path)
  call DebugPrint('adding plugin: ' . a:path)
  let s:plugins_list = s:plugins_list + [ a:path ]
  if !g:plugins_installed
    let s:cwd = getcwd()
    execute 'cd ' . s:pathogen_home
    execute 'silent !git clone https://github.com/' . a:path
    execute 'cd ' . s:cwd
  endif
endfunction

function! ReinstallPathogenPlugins()
  let s:cwd = getcwd()
  for plugin in s:plugins_list
    let s:plugin_path = PathJoin(s:pathogen_home, split(plugin,'/')[1])
    if empty(glob(s:plugin_path))
      execute "cd " . s:pathogen_home
      execute 'silent !git clone https://github.com/' . plugin
    else
      execute "cd " . s:plugin_path
      execute 'silent !git pull'
    endif
  endfor
  execute "cd " . s:cwd
  execute pathogen#infect()
endfunction

if !g:plugins_installed
  call DebugPrint('plugins not installed, installing package manager...')
  if g:os !=? 'Windows'
    execute 'silent !curl -LSso ' . s:plug_script_path .
          \ ' https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    execute 'source ' . s:plug_script_path
  else
    execute 'silent !curl -LSso ' . s:pathogen_script_path .
          \ ' https://tpo.pe/pathogen.vim'
    execute 'source ' . s:pathogen_script_path
  endif
  call SetFlag('plugins-installed', 1)
else
  " This forces the loading of the script, so that `sudo vim` can work nicely
  if g:os !=? 'Windows'
    execute 'source ' . s:plug_script_path
  else
    execute 'source ' . s:pathogen_script_path
  endif
endif


if g:os !=? 'Windows'
  call plug#begin()
else
  command! -nargs=1 Plug call InstallPathogenPlugin(<args>)
  command! PlugInstall call ReinstallPathogenPlugins()
endif

" Color Schemes
Plug 'lifepillar/vim-solarized8'

" Languages
if ReadFlag('polyglot-enabled')
  Plug 'sheerun/vim-polyglot'
  let g:rustfmt_autosave = 1
  let g:vim_markdown_math = 1
  let g:vim_markdown_frontmatter = 1
  let g:vim_markdown_folding_disabled = 1
  let g:vim_markdown_new_list_item_indent = 0
  let g:vim_markdown_auto_insert_bullets = 0
endif

" Snippets
if ReadFlag('snippets-enabled')
  Plug 'SirVer/ultisnips'
  Plug 'honza/vim-snippets'
  let g:UltiSnipsExpandTrigger="<C-N><C-N>"
  let g:UltiSnipsJumpForwardTrigger="<C-R>"
  let g:UltiSnipsJumpBackwardTrigger="<C-E>"
endif

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

augroup AutoFormatting
  autocmd!
  autocmd FileType * let b:autoformat_enabled = 0
  autocmd FileType rust,java,c,cpp,go,arduino let b:autoformat_enabled = 1
  autocmd FileType swift let b:autoformat_enabled = 1
        \ | let b:autoformat_remove_trailing_spaces = 0
        \ | let b:autoformat_retab = 0
  autocmd FileType vim let b:autoformat_enabled = 1
  autocmd BufWrite * if exists('b:autoformat_enabled') && b:autoformat_enabled | Autoformat | endif
  autocmd FileType markdown,tex let b:autoformat_autoindent = 0
        \ | let b:autoformat_remove_trailing_spaces = 0
        \ | let b:autoformat_retab = 0
augroup END

" Language server support because I have to I guess
if ReadFlag('lang-server-enabled')
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


"" Tim Pope Plugins <3

" Unix Commands
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-fugitive'

if g:os !=? 'Windows'
  call plug#end()
  if !g:plugins_installed
    PlugInstall
  endif
else
  execute pathogen#infect()
endif
