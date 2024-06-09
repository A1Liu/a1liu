command! ToggleBgFlag :call ToggleFlag('light-mode') | call ReadBgFlag()
command! ToggleBg :call ToggleFlag('light-mode') | call ReadBgFlag()

command! ReadBgFlag :call ReadBgFlag()
function! ReadBgFlag()
  if GetFlag('light-mode', "enables light mode")
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
set cursorline
set showmode ruler cul cc=80 laststatus=2 showcmd

" https://shapeshed.com/vim-statuslines/
set statusline=
" Something that I will inevitably run into sometime in the future, and when
" that happens I will updated this message with what BOM actually is and why
" it's important. It has caused me pain in the past though, and so I have
" added this to reduce that pain in the future.
set statusline+=\ %{&bomb?'BOM':''}
" File name
set statusline+=\ %f
" Whether the file has been modified without being saved
set statusline+=%m
" Spacer
set statusline+=%=
" File type
set statusline+=\ %y
" Progress through the file
set statusline+=\ %p%%
" Column and line info
set statusline+=\ %c:%l
" Space at the end
set statusline+=%{\"\\ua0\"}

" GUI Mode
if has('gui_running')
  if !has('gui_macvim')
    set guioptions=cs
    augroup GuiMacvim
      autocmd!
      autocmd! GUIEnter * simalt ~x
    augroup end
  endif
endif

command! SynStack :call SynStack()

" Color Scheme
try
  colorscheme solarized8_high
catch
  colorscheme habamax
endtry
ReadBgFlag

" Font on GUI Programs
if g:os ==? 'Windows'
  if &guifont !=? 'Consolas:h14'
    set guifont=Consolas:h14
  endif
elseif g:os ==? 'Darwin'
  if &guifont !=? 'Menlo:h12'
    set guifont=Menlo:h12
  endif
else
  if &guifont !=? 'Courier:h8'
    set guifont=Courier:h8
  endif
endif
