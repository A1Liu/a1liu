"" Plugins

let s:plug_path = g:vim_home_path . '/autoload/plug.vim'
if empty(glob(s:plug_path))
  execute "silent !curl -fLo" s:plug_path "--create-dirs"
    \ "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin(g:vim_home_path . '/plugged')

" Color Schemes
" Plug 'nightsense/cosmic_latte'
" Plug 'NLKNguyen/papercolor-theme'
" Plug 'altercation/vim-colors-solarized'
Plug 'lifepillar/vim-solarized8'

" Airline
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'powerline/fonts'
let g:airline_powerline_fonts = 0
let g:airline#extensions#whitespace#enabled = 0

" Markdown highlighting
Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown'
let g:vim_markdown_math = 1
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_new_list_item_indent = 0
let g:vim_markdown_auto_insert_bullets = 0

" JS Highlighting
Plug 'isRuslan/vim-es6'

" Rust Highlighting, Linting, Etc.
Plug 'rust-lang/rust.vim'
let g:rustfmt_autosave = 1

" Google's Formatter
Plug 'google/vim-maktaba'
Plug 'google/vim-codefmt'
Plug 'google/vim-glaive'

" git diff gutter to show changes
" Plug 'airblade/vim-gitgutter'
" let g:gitgutter_enabled = 0

" Linting
Plug 'w0rp/ale'
let g:ale_enabled = 0
" Eclim
let g:EclimJavascriptValidate = 0
let g:EclimJavascriptLintEnabled = 0

" CSS Syntax Highlighting
" Plug 'ap/vim-css-color'

" Editor Config
Plug 'editorconfig/editorconfig-vim'

" Fuzzy Finder
" Plug 'ctrlpvim/ctrlp.vim'

" " Multiple Cursors
" Plug 'terryma/vim-multiple-cursors'

" Swapping windows
" Plug 'wesQ3/vim-windowswap'

"" Tim Pope Plugins <3

" Git stuff
Plug 'tpope/vim-fugitive'

" Asynchronous Dispatch
Plug 'tpope/vim-dispatch'

" Unix Commands
Plug 'tpope/vim-eunuch'

" " Sensible Vim
" Plug 'tpope/vim-sensible'

call plug#end()

call glaive#Install()

" TODO Get stuff to download this file from internet
" https://github.com/google/google-java-format/releases/download/google-java-format-1.7/google-java-format-1.7-all-deps.jar
execute "Glaive codefmt google_java_executable=\"java -jar"
      \ g:vim_home_path . "/format/google-java-format-1.7-all-deps.jar\""

