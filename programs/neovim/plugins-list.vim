"" Plugins

if g:first_install
  execute "silent !curl -fLo " . g:plug_path . ' --create-dirs  "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"'
  autocmd VimEnter * PlugInstall --sync | so $MYVIMRC
endif

call plug#begin(g:vim_home_path . '/plugged')

" Color Schemes
" Plug 'nightsense/cosmic_latte'
" Plug 'NLKNguyen/papercolor-theme'
" Plug 'altercation/vim-colors-solarized'
" Plug 'lifepillar/vim-solarized8'

" Airline
" Plug 'vim-airline/vim-airline'
" Plug 'vim-airline/vim-airline-themes'
" Plug 'powerline/fonts'
let g:airline_powerline_fonts = 0
let g:airline#extensions#whitespace#enabled = 0
let g:airline#extensions#wordcount#enabled = 0 " Causes a really dumb glitch
                                               " when creating visual blocks
"" Highlighting

" Markdown highlighting
" Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown'
let g:vim_markdown_math = 1
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_new_list_item_indent = 0
let g:vim_markdown_auto_insert_bullets = 0
" JS
Plug 'isRuslan/vim-es6'
" Rust
Plug 'rust-lang/rust.vim'
let g:rustfmt_autosave = 1
" Zig
Plug 'ziglang/zig.vim'
" Google's Formatter
Plug 'google/vim-maktaba'
Plug 'google/vim-codefmt'
Plug 'google/vim-glaive'
" CSS Syntax Highlighting
" Plug 'ap/vim-css-color'

" Fuzzy finder
" Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
" Plug 'junegunn/fzf.vim' " Potentially unnecessary for what I do, really only
" need fzf
" Plug 'ctrlpvim/ctrlp.vim'

" Cd to git root
" Plug 'airblade/vim-rooter'
" let g:rooter_manual_only = 1
" let g:rooter_use_lcd = 1

" Rename files with Vim
" Plug 'qpkorr/vim-renamer'

" Eclim
let g:EclimJavascriptValidate = 0
let g:EclimJavascriptLintEnabled = 0

" Swapping windows
" Plug 'wesQ3/vim-windowswap'

"" Tim Pope Plugins <3

" Unix Commands
Plug 'tpope/vim-eunuch'

call plug#end()

if !g:first_install
  call glaive#Install()
endif
