"" Keybindings
let mapleader=" "
nnoremap <SPACE> <Nop>
tnoremap <C-H> <C-\><C-n>
noremap <C-H> <Esc>
noremap! <C-H> <Esc>

" Placeholder
" function! NextPlaceholder()
"   execute 'normal! <Esc>/' . g:placeholder . '<CR>df' . g:placeholder[-1]
"   startinsert
" endfunction
" nnoremap <Leader><Tab> :call NextPlaceholder()<CR>
nnoremap <Leader><Tab> /<++><CR>cf>
" New tab using gn
nnoremap gn :tabnew<Enter>

" Taken shamelessly verbatim from vim-sensible
nnoremap <silent> <C-L> :nohlsearch<C-R>=has('diff')?'<Bar>diffupdate':''<CR><CR><C-L>

" Pressing j and k go up and down the sections of a soft-wrapped line
" https://statico.github.io/vim.html
" https://statico.github.io/vim2.html
nmap j gj
nmap k gk

