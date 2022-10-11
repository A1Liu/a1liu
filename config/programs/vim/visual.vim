command! ToggleBgFlag :call ToggleFlag('light-mode') | call ReadBgFlag()
command! ToggleBg :call ToggleFlag('light-mode') | call ReadBgFlag()

command! ReadBgFlag :call ReadBgFlag()
function! ReadBgFlag()
  if Flag('light-mode')
    set background=light
  else
    set background=dark
  endif
endfunction

function! CheckTermGui()
  if has('gui_running')
    return 1
  endif

  if !exists('+termguicolors') || !has("termguicolors")
    return 0
  endif

  if $TERM_PROGRAM ==? "Apple_Terminal"
    return 0
  endif

  " if g:os ==? 'Windows'
  "   return 0
  " endif

  return 1
endfunction

" https://medium.com/@dubistkomisch/how-to-actually-get-italics-and-true-colour-to-work-in-iterm-tmux-vim-9ebe55ebc2be
if CheckTermGui()
  Dbg "term gui colors enabled"
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

set number norelativenumber " line numberings
set hlsearch incsearch " highlighting when using find
set cc=80
set cursorline
set showmode ruler cul cc=80 laststatus=2 showcmd

" https://shapeshed.com/vim-statuslines/
set statusline=
set statusline+=\ %{&bomb?'BOM':''}
set statusline+=\ %f
set statusline+=%m
set statusline+=%=
set statusline+=\ %y
set statusline+=\ %p%%
set statusline+=\ %c:%l\ 

" GUI Mode
if has('gui_running')
  set guioptions=cs
  if !has('gui_macvim')
    au! GUIEnter * simalt ~x
  endif
endif

command! SynStack :call SynStack()

" Color Scheme
try
  colorscheme solarized8_high
catch
  colorscheme default
endtry
ReadBgFlag

" Font on GUI Programs
if g:os ==? 'Windows'
  if &guifont !=? 'Consolas:h16'
    set guifont=Consolas:h16
  endif
elseif g:os ==? 'Darwin'
  if &guifont !=? 'Menlo:h8'
    set guifont=Menlo:h8
  endif
else
  if &guifont !=? 'Courier:h8'
    set guifont=Courier:h8
  endif
endif
