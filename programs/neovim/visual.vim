"" Visual Changes

" Getting terminal colors to work
" https://medium.com/@dubistkomisch/how-to-actually-get-italics-and-true-colour-to-work-in-iterm-tmux-vim-9ebe55ebc2be

command! ToggleBgFlag call ToggleFlag('light-mode') | call ReadBgFlag()
command! ToggleBg call ToggleFlag('light-mode') | call ReadBgFlag()

command! ReadBgFlag call ReadBgFlag()
function! ReadBgFlag()
  if ReadFlag('light-mode')
    set background=light
  else
    set background=dark
  endif
endfunction

if exists('+termguicolors') && has("termguicolors") && $TERM_PROGRAM !=? "Apple_Terminal" && g:os ==? 'Darwin'
  call DebugPrint("term gui colors enabled")
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

set number norelativenumber " line numberings
set hlsearch incsearch " highlighting when using find
set cc=80
set cursorline

" https://shapeshed.com/vim-statuslines/
set statusline=
set statusline+=\ %f
set statusline+=%m
set statusline+=%=
set statusline+=\ %y
set statusline+=\ %p%%
set statusline+=\ %c:%l
set statusline+=\

" GUI Mode
if has('gui_running')
  set guioptions=cs
endif

command! SynStack call SynStack()

" Color Scheme
try
  colorscheme solarized8_high
  ReadBgFlag
  call DebugPrint('succeeded in loading solarized8_high')
catch
  call DebugPrint('failed to load solarized8_high')
  colorscheme default
  if has('gui_running')
    set background=light
  endif
endtry

" Font on GUI Programs
if g:os ==? 'Windows'
  if &guifont !=? 'Consolas:h8'
    set guifont=Consolas:h8
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
