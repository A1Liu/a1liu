" set mouse=a " Mouse functionality
" Changing line with the arrow keys
" set whichwrap+=<,>,[,]
" https://superuser.com/questions/35389/in-vim-how-do-i-make-the-left-and-right-arrow-keys-change-line

" Plugins
runtime plugins-list.vim

"" Indenting
set tabstop=2 expandtab shiftwidth=2
set foldlevelstart=4

function! MarkdownJekyllSettings()
  let l:begin=getline(1)
  if l:begin == "---"
    set tabstop=3 shiftwidth=3
  endif
endfunction

augroup KramdownHighlighting
  autocmd!
  autocmd BufRead,BufNewFile,BufEnter *.md,*.markdown
    \ call MarkdownJekyllSettings()
  autocmd BufLeave *.md,*.markdown
    \ set tabstop=2 | set shiftwidth=2
augroup END

"" Commands
" TODO Make a toggle for showing column on left hand side
" TODO Make a command to create a window to the left and/or update the one to
" the left; do the same for right. The idea is to have a workflow with a left
" and right pane

"" Keybindings
let mapleader=","
tnoremap <Esc> <C-\><C-n>

" Window switching
" map <C-j> <C-W>j
" map <C-k> <C-W>k
" map <C-h> <C-W>h
" map <C-l> <C-W>l

"" Visual Changes
set number " line numberings
set background=dark
set hlsearch incsearch " highlighting when using find
set cc=80
:hi ColorColumn ctermbg=DarkGreen guibg=DarkGreen
set cul

"" netrw
" Folders n stuff
let g:netrw_sort_sequence='[\/]$,\<core\%(\.\d\+\)\=\>,'
" Docs
let g:netrw_sort_sequence.= 'README,LICENSE,*.md$,*.markdown$,'
" C and C++ Files
let g:netrw_sort_sequence.= '\.h$,\.c$,\.cpp$,'
" Java files
let g:netrw_sort_sequence.= '\.java$,'
" The vast majority of files
let g:netrw_sort_sequence.= '\~\=\*$,*,'
" Files that begin with the '.' character, and other mildly hidden files
let g:netrw_sort_sequence.= '^\..*$,'
" Compiled files
let g:netrw_sort_sequence.= '\.o$,\.obj$,\.class$,'
" Vim files? Text editor info files and dumb files
let g:netrw_sort_sequence.= '\.info$,\.swp$,\.bak$,^\.DS_Store$,\~$'

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
