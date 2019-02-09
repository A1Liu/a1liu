" set mouse=a " Mouse functionality
" Changing line with the arrow keys
" set whichwrap+=<,>,[,]
" https://superuser.com/questions/35389/in-vim-how-do-i-make-the-left-and-right-arrow-keys-change-line

" Plugins
runtime plugins-list.vim

" Indenting
set tabstop=2 expandtab shiftwidth=2

"" Keybindings
let mapleader=","


"" Visual Changes
syntax on " Syntax highlighting
set number " line numberings
set hls ic " highlighting when using find

" Showing non-printing characters
set list
set showbreak=↪
set listchars=tab:»\ ,extends:›,precedes:‹,nbsp:·,trail:· " ,eol:↲
set backspace=indent,eol,start

" Split panes more obvious
augroup BgHighlight
    autocmd!
    autocmd WinEnter * set cul
    autocmd WinLeave * set nocul
augroup END




