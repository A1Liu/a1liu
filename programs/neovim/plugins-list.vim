"" Plugins

let s:plug_home = PathJoin(g:vim_home_path, 'plugged')
let s:pathogen_home = PathJoin(g:vim_home_path, 'bundle')
let s:autoload_path = PathJoin(g:vim_home_path, 'autoload')
let g:plugins_installed = ReadFlag('plugins-installed')
call DebugPrint('plug home is: ' . s:plug_home)
call DebugPrint('pathogen home is: ' . s:pathogen_home)

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
    let s:plug_install_path = PathJoin(s:autoload_path, 'plug.vim')
    execute 'silent !curl -fLo ' . s:plug_install_path
          \ . ' https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
  else
    let s:pathogen_install_path = PathJoin(s:autoload_path, 'pathogen.vim')
    execute 'silent !curl -LSso ' . s:pathogen_install_path . ' https://tpo.pe/pathogen.vim'
  endif
  call SetFlag('plugins-installed', 1)
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
Plug 'sheerun/vim-polyglot'
let g:rustfmt_autosave = 1
let g:vim_markdown_math = 1
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_new_list_item_indent = 0
let g:vim_markdown_auto_insert_bullets = 0

" Snippets
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
let g:UltiSnipsExpandTrigger="<C-N><C-N>"
let g:UltiSnipsJumpForwardTrigger="<C-R>"
let g:UltiSnipsJumpBackwardTrigger="<C-E>"

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
  autocmd FileType java,c,cpp,go,arduino let b:autoformat_enabled = 1
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
  let g:LanguageClient_serverCommands = {
        \ 'rust' : ['~/.cargo/bin/rustup', 'run', 'stable', 'rls'],
        \ 'go'   : ['gopls'],
        \ 'swift': ['xcrun', 'sourcekit-ls'],
        \ }
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
else
  execute pathogen#infect()
endif
