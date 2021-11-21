"" Keybindings

" Change Leader key
let mapleader=" "
nnoremap <SPACE> <Nop>

noremap <C-C> <Esc>
noremap! <C-C> <Esc>
snoremap <C-C> <Esc>
nnoremap r<C-C> <Nop>
cunmap <C-C>

if !has('nvim')
  " Mapping <C-H> to escape
  snoremap <C-H> <Esc>
  noremap <C-H> <Esc>
  noremap! <C-H> <Esc>
  cnoremap <C-H> <C-C>
  nnoremap r<C-H> <Nop>

  " Terminal keybindings
  if exists(':terminal')
    tnoremap <C-H> <C-\><C-N>
  endif
endif

noremap <C-C> <Esc>
noremap! <C-C> <Esc>
snoremap <C-C> <Esc>
" Fixing C-Left and C-Right
" https://unix.stackexchange.com/questions/1709/how-to-fix-ctrl-arrows-in-vim
noremap <ESC>[1;5D <C-Left>
noremap <ESC>[1;5C <C-Right>
noremap! <ESC>[1;5D <C-Left>
noremap! <ESC>[1;5C <C-Right>

" Leader Mappings
nnoremap <Leader>r :!
nnoremap <Leader>R :read !

" Taken from vim-rsi
" cnoremap <C-B> <C-Left>
" cnoremap <C-F> <C-Right>

" Setting up Ctrl-K in normal mode
" https://github.com/tpope/vim-rsi/issues/15#issuecomment-198632142
cnoremap <C-A> <Home>
cnoremap <C-K> <C-\>e getcmdpos() == 1 ? '' : getcmdline()[:getcmdpos()-2]<CR>
cnoremap <C-B> <C-Left>
cnoremap <C-F> <C-Right>
cnoremap <Up> <C-P>
cnoremap <Down> <C-N>

" Screw that man pages stuff
nnoremap <S-K> gj
vnoremap <S-K> gj
vnoremap <S-L> gk

" What the heck is Select mode?
nnoremap <silent> gh :call LanguageClient#textDocument_hover()<CR>
nnoremap g<C-H> <Nop>

" Using <C-J> and <C-K> for navigating the pop-up menu
" inoremap <C-N><C-O> <C-N>
inoremap <C-N><C-O> <C-X><C-O>
inoremap <C-N> <Nop>
inoremap <C-N><C-T> <C-N>
inoremap <expr> <C-D> pumvisible() ? "\<C-N>\<C-N>\<C-N>\<C-N>\<C-N>" : "\<C-D>"
inoremap <expr> <C-U> pumvisible() ? "\<C-P>\<C-P>\<C-P>\<C-P>\<C-P>" : "\<C-U>"
inoremap <expr> <C-J> pumvisible() ? "\<C-N>" : "\<C-J>"
inoremap <expr> <C-K> pumvisible() ? "\<C-P>" : "\<C-K>"

" Using <C-T> to put in a lil thing with my name and stuff in it
if Flag('aliu')
  nnoremap <C-T> i<C-R>=strftime("- Albert Liu, %b %d, %Y %a %H:%M %Z")<CR><Esc>
  inoremap <C-T> <C-R>=strftime("- Albert Liu, %b %d, %Y %a %H:%M %Z")<CR>
endif

" Unmapping <C-Q>
nnoremap <C-Q> <Nop>

" Disabling ex mode
nnoremap <S-Q> <Nop>

" Placeholder
nnoremap <Leader><Tab> /<++><CR>cf>
nnoremap <Leader><S-Tab> ?<++><CR>cf>

" Go to definition
nnoremap <silent> gd :call LanguageClient#textDocument_definition()<CR>

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
noremap j h
onoremap j h

noremap k gj
onoremap k j

noremap l gk
onoremap l k

noremap ; l
onoremap ; l

noremap ' :

