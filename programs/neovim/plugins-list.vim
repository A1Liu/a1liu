"" Plugins

let g:plug_home = PathJoin(g:vim_home_path, 'plugged')
call DebugPrint('Plug home is: ' . g:plug_home)

if g:first_run
  call DebugPrint('First run, installing packages...')
  autocmd VimEnter * PlugInstall --sync | so $MYVIMRC
else
  call DebugPrint("Not first run.")
endif

call plug#begin()

" Color Schemes
" Plug 'lifepillar/vim-solarized8'

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
Plug 'autozimu/LanguageClient-neovim', {
    \ 'branch': 'next',
    \ 'do': 'bash install.sh',
    \ }

" Eclim
let g:EclimJavascriptValidate = 0
let g:EclimJavascriptLintEnabled = 0

"" Tim Pope Plugins <3

" Unix Commands
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-rsi'

call plug#end()

if !g:first_run
  call glaive#Install()
endif
