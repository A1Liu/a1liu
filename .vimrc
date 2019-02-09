set number " line numberings
" set mouse=a " Mouse functionality
syntax on " Syntax highlighting
set whichwrap+=<,>,[,]
" https://superuser.com/questions/35389/in-vim-how-do-i-make-the-left-and-right-arrow-keys-change-line
set tabstop=2 expandtab shiftwidth=2
set list
set showbreak=↪
set listchars=tab:»\ ,extends:›,precedes:‹,nbsp:·,trail:· " ,eol:↲
set backspace=indent,eol,start
set virtualedit=onemore

set hls ic

if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

" git diff gutter to show changes
Plug 'https://github.com/airblade/vim-gitgutter'

" Linting
Plug 'https://github.com/w0rp/ale'

" Editor Config
Plug 'https://github.com/editorconfig/editorconfig-vim'

" Multiple Cursors
" Plug 'https://github.com/terryma/vim-multiple-cursors'

" Unix Commands
Plug 'https://github.com/tpope/vim-eunuch'


call plug#end()
