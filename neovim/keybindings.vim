"" Keybindings
let mapleader=" "
nnoremap <SPACE> <Nop>
tnoremap <C-H> <C-\><C-n>
noremap <C-H> <Esc>
noremap! <C-H> <Esc>
cunmap <C-H>
cnoremap <C-H> <C-c>

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

" Chrome-like tab changing
nnoremap <Tab> gt
nnoremap <S-Tab> gT

" <C-L> removes the highlighted stuff while also clearning the screen
" Taken shamelessly verbatim from vim-sensible
nnoremap <silent> <C-L> :nohlsearch<C-R>=has('diff')?'<Bar>diffupdate':''<CR><CR><C-L>

" Pressing j and k go up and down the sections of a soft-wrapped line
" https://statico.github.io/vim.html
" https://statico.github.io/vim2.html
nmap j gj
nmap k gk

