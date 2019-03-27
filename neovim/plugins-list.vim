"" Plugins

let s:plug_path = g:vim_home_path . '/autoload/plug.vim'
if empty(glob(s:plug_path))
  execute "silent !curl -fLo" s:plug_path "--create-dirs"
    \ "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin(g:vim_home_path . '/plugged')

" Color Schemes
" Plug 'https://github.com/nightsense/cosmic_latte'
" Plug 'https://github.com/NLKNguyen/papercolor-theme'
" Plug 'https://github.com/altercation/vim-colors-solarized'
Plug 'https://github.com/lifepillar/vim-solarized8'

" Airline
Plug 'https://github.com/vim-airline/vim-airline'
Plug 'https://github.com/vim-airline/vim-airline-themes'
Plug 'https://github.com/powerline/fonts'
let g:airline_powerline_fonts = 0
let g:airline#extensions#whitespace#enabled = 0

" Markdown highlighting
Plug 'https://github.com/godlygeek/tabular'
Plug 'https://github.com/plasticboy/vim-markdown'
let g:vim_markdown_math = 1
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_new_list_item_indent = 0
let g:vim_markdown_auto_insert_bullets = 0

" JS Highlighting
Plug 'https://github.com/isRuslan/vim-es6'

" Google's Formatter
Plug 'https://github.com/google/vim-maktaba'
Plug 'https://github.com/google/vim-codefmt'
Plug 'https://github.com/google/vim-glaive'

" git diff gutter to show changes
" Plug 'https://github.com/airblade/vim-gitgutter'
" let g:gitgutter_enabled = 0

" Linting
Plug 'https://github.com/w0rp/ale'
let g:ale_enabled = 0
" Eclim
let g:EclimJavascriptValidate = 0
let g:EclimJavascriptLintEnabled = 0

" CSS Syntax Highlighting
" Plug 'https://github.com/ap/vim-css-color'

" Editor Config
Plug 'https://github.com/editorconfig/editorconfig-vim'

" Fuzzy Finder
" Plug 'https://github.com/ctrlpvim/ctrlp.vim'

" " Multiple Cursors
" Plug 'https://github.com/terryma/vim-multiple-cursors'

" Swapping windows
" Plug 'https://github.com/wesQ3/vim-windowswap'

"" Tim Pope Plugins <3

" Git stuff
Plug 'https://github.com/tpope/vim-fugitive'

" Asynchronous Dispatch
Plug 'https://github.com/tpope/vim-dispatch'

" Unix Commands
Plug 'https://github.com/tpope/vim-eunuch'

" " Sensible Vim
" Plug 'https://github.com/tpope/vim-sensible'

call plug#end()

call glaive#Install()
execute "Glaive codefmt google_java_executable=\"java -jar"
      \ g:vim_home_path . "/format/google-java-format-1.7-all-deps.jar\""

