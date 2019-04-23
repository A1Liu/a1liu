"" Keybindings

" Change Leader key
let mapleader=" "
nnoremap <SPACE> <Nop>

" Mapping <C-H> to escape
noremap <C-H> <Esc>
noremap! <C-H> <Esc>
cnoremap <C-H> <C-c>

" Terminal keybindings
tnoremap <C-\><C-\> <C-\><C-n>
tnoremap <C-H> <C-\><C-n>

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
nnoremap <C-N> :tabnew<Enter>:term<Enter>

" Better Screen Repaint
" Taken shamelessly verbatim from vim-sensible
nnoremap <silent> <C-L> :nohlsearch<C-R>=has('diff')?'<Bar>diffupdate':''<CR><CR><C-L>

" New buffer in window to the right
nnoremap <C-W>v <C-W>v:enew<CR>

" Pressing j and k go up and down the sections of a soft-wrapped line
" https://statico.github.io/vim.html
" https://statico.github.io/vim2.html
nmap j gj
nmap k gk

