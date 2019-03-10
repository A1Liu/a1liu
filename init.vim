" set mouse=a " Mouse functionality
" Changing line with the arrow keys
" set whichwrap+=<,>,[,]
" https://superuser.com/questions/35389/in-vim-how-do-i-make-the-left-and-right-arrow-keys-change-line

"" Initialize global variables
let g:vim_home_path = fnamemodify($MYVIMRC, ':h')



"" Plugins
runtime plugins-list.vim



"" Visual Changes
set number relativenumber " line numberings
set hlsearch incsearch " highlighting when using find
set cc=80
set cul

" Color Theme
set termguicolors
if strftime('%H') >= 10 && strftime('%H') < 17
  set background=light
else
  set background=dark
endif
colorscheme cosmic_latte


" Showing non-printing characters
set list
set showbreak=↪
set listchars=tab:»\ ,extends:›,precedes:‹,nbsp:·,trail:· " ,eol:↲


" Split panes more obvious
augroup BgHighlight
    autocmd!
    autocmd WinEnter * set cul | set cc=80 | set relativenumber " Set color column
    autocmd WinLeave * set nocul | set cc= | set norelativenumber
augroup END


" Syntax Highlighting
syntax enable " Syntax highlighting



"" Indenting
set tabstop=2 expandtab shiftwidth=2
set foldlevelstart=4



"" Saving my ass
set undofile
execute 'set undodir=' . g:vim_home_path . '/undohist'



"" Markdown and Jekyll Settings
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

