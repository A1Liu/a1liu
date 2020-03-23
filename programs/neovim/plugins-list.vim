"" Plugins

let s:plug_home = PathJoin(g:vim_home_path, 'plugged')
let s:pathogen_home = PathJoin(g:vim_home_path, 'bundle')
let s:autoload_path = PathJoin(g:vim_home_path, 'autoload')
call DebugPrint('Plug home is: ' . s:plug_home)
call DebugPrint('Pathogen home is: ' . s:pathogen_home)

function! InstallPathogenPlugin(path)
  if g:first_run
    let s:cwd = getcwd()
    execute "cd " . s:bundle_path
    execute "silent !git clone https://github.com/" . a:path
    execute "cd " . s:cwd
  endif
endfunction

if g:first_run
  call DebugPrint('First run, installing package manager...')
  if g:os !=? 'Windows'
    let s:plug_install_path = PathJoin(s:autoload_path, 'plug.vim')
    execute 'silent !curl -fLo ' . s:plug_install_path
          \ . ' https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
  else
    let s:pathogen_install_path = PathJoin(s:autoload_path, 'pathogen.vim')
    execute "silent !curl -LSso " . s:pathogen_install_path . " https://tpo.pe/pathogen.vim"
  endif
else
  call DebugPrint("Not first run.")
endif

if g:os !=? 'Windows'
  call plug#begin()
else
  command! -nargs=1 Plug call InstallPathogenPlugin(<args>)
endif

" Color Schemes
Plug 'lifepillar/vim-solarized8'

"" Highlighting

" Markdown highlighting
Plug 'plasticboy/vim-markdown'
let g:vim_markdown_math = 1
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_new_list_item_indent = 0
let g:vim_markdown_auto_insert_bullets = 0

" Languages
Plug 'sheerun/vim-polyglot'
let g:rustfmt_autosave = 1

" Google's Formatter
Plug 'google/vim-maktaba'
Plug 'google/vim-codefmt'
Plug 'google/vim-glaive'

" Language server support because I have to I guess
Plug 'autozimu/LanguageClient-neovim'
let g:LanguageClient_serverCommands = {
    \ 'rust': ['~/.cargo/bin/rustup', 'run', 'stable', 'rls'],
    \ 'go'  : ['gopls'],
    \ }

" Eclim
let g:EclimJavascriptValidate = 0
let g:EclimJavascriptLintEnabled = 0

"" Tim Pope Plugins <3

" Unix Commands
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-rsi'

if g:os !=? 'Windows'
  call plug#end()
else
  execute pathogen#infect()
endif

if !g:first_run
  call glaive#Install()
endif
