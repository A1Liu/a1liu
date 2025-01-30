"" Keybindings

noremap <C-C> <Esc>
noremap! <C-C> <Esc>
snoremap <C-C> <Esc>
nnoremap r<C-C> <Nop>
cunmap <C-C>

" Mapping <C-H> to escape
"   NOTE: To get this mapping to work in NeoVim, you may need to run
"   something like:
"      infocmp $TERM | sed 's/kbs=^[hH]/kbs=\\177/' > $TERM.ti && tic $TERM.ti
"
"                               - Albert Liu, Jun 18, 2023 Sun 18:09
snoremap <C-H> <Esc>
noremap <C-H> <Esc>
noremap! <C-H> <Esc>
cnoremap <C-H> <C-C>
nnoremap r<C-H> <Nop>

" Terminal keybindings
if exists(':terminal')
  tnoremap <C-H> <C-\><C-N>
  tnoremap <C-W><C-H> <C-W>h
endif

" Change Leader key
let mapleader=" "
nnoremap <SPACE> <Nop>

" Leader Mappings
nnoremap <Leader>r :!
nnoremap <Leader>R :read !
nnoremap <Leader>f /

" Placeholder
nnoremap <Leader><Tab> /<++><CR>cf>
nnoremap <Leader><S-Tab> ?<++><CR>cf>

" Setting up Ctrl-K in normal mode
" https://github.com/tpope/vim-rsi/issues/15#issuecomment-198632142
cnoremap <C-A> <Home>
cnoremap <C-K> <C-\>e getcmdpos() == 1 ? '' : getcmdline()[:getcmdpos()-2]<CR>
cnoremap <C-B> <C-Left>
cnoremap <C-F> <C-Right>
cnoremap <Up> <C-P>
cnoremap <Down> <C-N>

" Screw that man pages stuff
nnoremap <S-K> gk
vnoremap <S-K> gk
vnoremap <S-J> gj

" What the heck is Select mode?
nnoremap g<C-H> <Nop>

if GetFlag('aliu', "Using `<C-T>` to put in a timestamped signature")
  nnoremap <C-T> a<C-R>=strftime("- Albert Liu, %b %d, %Y %a %H:%M")<CR><Esc>
  inoremap <C-T> <C-R>=strftime("- Albert Liu, %b %d, %Y %a %H:%M")<CR>
endif

" Unmapping <C-Q>
nnoremap <C-Q> <Nop>

" Mapping semicolon to colon
nnoremap ; :

" Disabling ex mode
nnoremap <S-Q> <Nop>

" Go to definition
nnoremap <silent> gd :call LanguageClient#textDocument_definition()<CR>

" Control left/right in command mode
cnoremap <Esc>[1;5D <C-Left>
cnoremap <Esc>[1;5C <C-Right>

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

nnoremap <C-J> 4gj
nnoremap <C-K> 4gk
vnoremap <C-J> 4gj
vnoremap <C-K> 4gk

" Visual Star
" http://got-ravings.blogspot.com/2008/07/vim-pr0n-visual-search-mappings.html
"
" Press * in visual mode to go to the next occurence
" of the text currently in your selection
function! s:VSetSearch()
  let temp = @@
  norm! gvy
  let @/ = '\V' . substitute(escape(@@, '\'), '\n', '\\n', 'g')
  let @@ = temp
endfunction

vnoremap * :<C-u>call <SID>VSetSearch()<CR>//<CR>
vnoremap # :<C-u>call <SID>VSetSearch()<CR>??<CR>
