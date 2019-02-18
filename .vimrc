" set mouse=a " Mouse functionality
" Changing line with the arrow keys
" set whichwrap+=<,>,[,]
" https://superuser.com/questions/35389/in-vim-how-do-i-make-the-left-and-right-arrow-keys-change-line

" Plugins
runtime plugins-list.vim

"" Indenting
set tabstop=2 expandtab shiftwidth=2

"" Commands
" TODO Make a toggle for showing column on left hand side

"" Keybindings
let mapleader=","

"" Visual Changes
syntax on " Syntax highlighting
set number " line numberings
set hls ic " highlighting when using find
set cc=80
:hi ColorColumn ctermbg=DarkGreen guibg=DarkGreen
set cul

" Showing non-printing characters
set list
set showbreak=↪
set listchars=tab:»\ ,extends:›,precedes:‹,nbsp:·,trail:· " ,eol:↲
" set backspace=indent,eol,start

" Split panes more obvious
augroup BgHighlight
    autocmd!
    autocmd WinEnter * set cul | set cc=80 " Set color column
    autocmd WinLeave * set nocul | set cc=
augroup END

