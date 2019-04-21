"" Initialize global variables
" https://stackoverflow.com/questions/4976776/how-to-get-path-to-the-current-vimscript-being-executed/4977006
let g:vim_home_path = fnamemodify(resolve(expand('<sfile>:p')), ':h')
let g:placeholder = '<++>'
set guicursor= " don't want unknown characters in linux
set t_Co=256



"" Plugins
execute 'source ' . g:vim_home_path . '/plugins-list.vim'

"" Keybindings
execute 'source ' . g:vim_home_path . '/keybindings.vim'


"" Visual Changes
set number relativenumber " line numberings
set hlsearch incsearch " highlighting when using find
set ignorecase smartcase " Ignore case except when including capital letters
set cc=80
set cul
set splitright splitbelow
" https://shapeshed.com/vim-statuslines/


" Hiding the UI
" https://unix.stackexchange.com/questions/140898/vim-hide-status-line-in-the-bottom
let s:hidden_all = 0
function! ToggleHiddenAll()
    if s:hidden_all  == 0
        let s:hidden_all = 1
        set noshowmode
        set noruler
        set laststatus=0
        set noshowcmd
        set nocul
        set cc=
    else
        let s:hidden_all = 0
        set showmode
        if &ft != 'netrw'
          set ruler
          set cul
          set cc=80
        endif
        set laststatus=2
        set showcmd
    endif
endfunction

" nnoremap <S-h> :call ToggleHiddenAll()<CR>

" Folding
" https://vim.fandom.com/wiki/Keep_folds_closed_while_inserting_text
autocmd InsertEnter * if !exists('w:last_fdm') | let w:last_fdm=&foldmethod | setlocal foldmethod=manual | endif
autocmd InsertLeave,WinLeave * if exists('w:last_fdm') | let &l:foldmethod=w:last_fdm | unlet w:last_fdm | endif

" Color Theme
filetype plugin indent on
syntax enable " Syntax highlighting
let g:airline_theme='base16_solarized'
if strftime('%H') >= 8 && strftime('%H') < 22 " 10am to 10pm
  set background=light
else
  set background=dark
  let g:airline_solarized_bg='dark'
endif
colorscheme solarized8_high

" Showing non-printing characters
set list
set showbreak=↪
set listchars=tab:»\ ,extends:›,precedes:‹,nbsp:·,trail:· " ,eol:↲

" Split panes more obvious, terminal prettier
augroup BgHighlight
    autocmd!
    autocmd BufWinEnter,WinEnter,BufEnter * if &ft != 'netrw' && &buftype !='terminal' |
          \ setlocal cul cc=80 |
          \ setlocal relativenumber |
          \ let s:hidden_all = 1 | call ToggleHiddenAll() |
          \ endif " Set color column
    autocmd TermOpen * setlocal nonumber norelativenumber cc=
    autocmd BufWinEnter,WinEnter * if &ft == 'netrw' | setlocal cc= | endif
    autocmd BufWinLeave,WinLeave * if &ft != 'netrw' && &buftype != 'terminal' | 
          \ setlocal nocul | setlocal cc= | setlocal norelativenumber | endif
augroup END



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
command! AL aboveleft
command! RunInit so $MYVIMRC



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

