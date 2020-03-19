"" Keybindings

" Change Leader key
let mapleader=" "
nnoremap <SPACE> <Nop>

" Mapping <C-H> to escape
noremap <C-C> <Esc>
noremap! <C-C> <Esc>
noremap <C-H> <Esc>
noremap! <C-H> <Esc>
cnoremap <C-H> <C-C>
nnoremap r<C-H> <Nop>
nnoremap r<C-C> <Nop>
cunmap <C-C>

" Fixing C-Left and C-Right
" https://unix.stackexchange.com/questions/1709/how-to-fix-ctrl-arrows-in-vim
noremap <ESC>[1;5D <C-Left>
noremap <ESC>[1;5C <C-Right>
noremap! <ESC>[1;5D <C-Left>
noremap! <ESC>[1;5C <C-Right>

" Taken from vim-rsi
cnoremap <C-B> <C-Left>
cnoremap <C-F> <C-Right>

" Setting up Ctrl-K in normal mode
" https://github.com/tpope/vim-rsi/issues/15#issuecomment-198632142
cnoremap <C-A> <Home>
cnoremap <C-K> <C-\>e getcmdpos() == 1 ? '' : getcmdline()[:getcmdpos()-2]<CR>

" Screw that man pages stuff
nnoremap <S-K> gk
vnoremap <S-K> gk
vnoremap <S-J> gj

" What the heck is Select mode?
nnoremap gh <Nop>
nnoremap g<C-H> <Nop>

" Using <C-J> and <C-K> for navigating the pop-up menu
inoremap <expr> <C-J> pumvisible() ? "\<C-N>" : "\<C-J>"
inoremap <expr> <C-K> pumvisible() ? "\<C-P>" : "\<C-K>"

" Unmapping <C-Q>
nnoremap <C-Q> <Nop>

" Mapping semicolon to colon
nmap ; :

" Disabling ex mode
nnoremap <S-Q> <Nop>

" Formatting with <Leader><S>
nnoremap <Leader><C-S> :FormatCode<CR>

" Terminal keybindings
if exists(':terminal')
  tnoremap <C-H> <C-\><C-N>
endif

" Placeholder
" function! NextPlaceholder()
"   execute 'normal /' . g:placeholder . '\<CR>'
"   ". '<CR>df' . g:placeholder[-1:]
"   " startinsert
" endfunction
" nnoremap <Leader><Tab> :call NextPlaceholder()<CR>
nnoremap <Leader><Tab> /<++><CR>cf>
nnoremap <Leader><S-Tab> ?<++><CR>cf>

" Go to definition
nnoremap gd :Def<CR>

"" Tabs
nnoremap <C-W><C-t> :tabnew<Enter>
nnoremap <C-W><C-e> :tabNext<Enter>
nnoremap <C-W><C-r> :tabnext<Enter>
nnoremap <C-W>t :tabnew<Enter>
nnoremap <C-W>e :tabNext<Enter>
nnoremap <C-W>r :tabnext<Enter>

" Getting back jump list functionality
nnoremap <C-P> <C-I>

" Better Screen Repaint
" Taken shamelessly verbatim from vim-sensible
nnoremap <silent> <C-L> :ReadBgFlag<CR>:nohlsearch<C-R>=has('diff')?'<Bar>diffupdate':''<CR><CR><C-L>

" New buffer in window to the right
nnoremap <C-W>v <C-W>v:enew<CR>
nnoremap <C-W><S-V> :aboveleft :vsplit<CR>:enew<CR>
nnoremap <C-W><S-N> :aboveleft :split<CR>:enew<CR>

" Pressing j and k go up and down the sections of a soft-wrapped line
" https://statico.github.io/vim.html
" https://statico.github.io/vim2.html
nnoremap j gj
nnoremap k gk

