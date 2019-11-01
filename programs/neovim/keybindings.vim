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

" What the heck is Select mode?
nnoremap gh <Nop>
nnoremap g<C-H> <Nop>

" Using <C-J> and <C-K> for navigating the pop-up menu
inoremap <expr> <C-J> pumvisible() ? "\<C-N>" : "\<C-J>"
inoremap <expr> <C-K> pumvisible() ? "\<C-P>" : "\<C-K>"

" Unmapping <C-Q>
nnoremap <C-Q> <Nop>

" Not portable
" " Saving with <C-S>
" nnoremap <C-S> :w<CR>

" Disabling ex mode
nnoremap <S-Q> <Nop>

" Formatting with <Leader><S>
nnoremap <Leader><C-S> :FormatCode<CR>

" Terminal keybindings
if has('nvim')
  tnoremap <C-\><C-\> <C-\><C-N>
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

"" Tabs
" New tab in terminal using gn
nnoremap gn :tabnew<Enter>:term<Enter>

" Chrome-like tab handling
nnoremap <Tab> gt
nnoremap <S-Tab> gT

" Getting back jump list functionality
nnoremap <C-P> <C-I>

" Better Screen Repaint
" Taken shamelessly verbatim from vim-sensible
nnoremap <silent> <C-L> :nohlsearch<C-R>=has('diff')?'<Bar>diffupdate':''<CR><CR><C-L>

" New buffer in window to the right
nnoremap <C-W>v <C-W>v:enew<CR>
nnoremap <C-W><S-V> :aboveleft :vsplit<CR>:enew<CR>
nnoremap <C-W><S-N> :aboveleft :split<CR>:enew<CR>

" Pressing j and k go up and down the sections of a soft-wrapped line
" https://statico.github.io/vim.html
" https://statico.github.io/vim2.html
nmap j gj
nmap k gk

