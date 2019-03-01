" set mouse=a " Mouse functionality
" Changing line with the arrow keys
" set whichwrap+=<,>,[,]
" https://superuser.com/questions/35389/in-vim-how-do-i-make-the-left-and-right-arrow-keys-change-line

" Plugins
runtime plugins-list.vim

"" Indenting
set tabstop=2 expandtab shiftwidth=2
autocmd BufRead,BufNewFile,BufEnter *.md,*.markdown set tabstop=3 shiftwidth=3


"" Commands
" TODO Make a toggle for showing column on left hand side

"" Keybindings
let mapleader=","

"" Visual Changes
set number " line numberings
set background=dark
set hlsearch incsearch " highlighting when using find
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

" Syntax Highlighting
syntax enable " Syntax highlighting

" " Liquid and LaTeX highlighting for Markdown
" " https://stsievert.com/blog/2016/01/06/vim-jekyll-mathjax/
" function! MathAndLiquid()
"     "" Define certain regions
"     " Block math. Look for "$$[anything]$$"
"     syn region math start=/\$\$/ end=/\$\$/
"     " inline math. Look for "$[not $][anything]$"
"     syn match math_block '\$[^$].\{-}\$'
" 
"     " Liquid single line. Look for "{%[anything]%}"
"     syn match liquid '{%.*%}'
"     " Liquid multiline. Look for "{%[anything]%}[anything]{%[anything]%}"
"     syn region highlight_block start='{% highlight .*%}' end='{%.*%}'
"     " Fenced code blocks, used in GitHub Flavored Markdown (GFM)
"     syn region highlight_block start='\n\s*```.*?\n' end='\n```\s*?\n'
" 
"     "" Actually highlight those regions.
"     hi link math Type
"     hi link liquid PreProc
"     hi link highlight_block Function
"     hi link math_block Function
" endfunction
" 
" " Call everytime we open a Markdown file
" autocmd BufRead,BufNewFile,BufEnter *.md,*.markdown
"       \ set filetype=markdown |
"       \ call MathAndLiquid()
