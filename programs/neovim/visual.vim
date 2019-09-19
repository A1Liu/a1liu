
"" Visual Changes
set number relativenumber " line numberings
set hlsearch incsearch " highlighting when using find
set cc=80
set cul

" Color Scheme
colorscheme darkblue
set background=light
hi Normal ctermfg=Gray ctermbg=Black
hi ColorColumn ctermbg=Gray ctermfg=Black
hi Search cterm=reverse ctermbg=Black ctermfg=Yellow
hi IncSearch cterm=reverse ctermbg=Black ctermfg=Yellow
hi StatusLine ctermbg=Gray ctermfg=Black
hi ErrorMsg ctermbg=Red ctermfg=White
hi Visual cterm=reverse ctermfg=Gray ctermbg=Black
hi WildMenu ctermfg=Gray ctermbg=Black
hi NonText ctermfg=LightBlue
hi Comment ctermfg=DarkGray

set statusline=
set statusline+=\ %f
set statusline+=%m
set statusline+=%=
set statusline+=\ %y
set statusline+=\ %p%%
set statusline+=\ %c:%l
set statusline+=\ 

" Split panes more obvious, terminal prettier
augroup BgHighlight
  autocmd!
  autocmd BufWinEnter,WinEnter,BufEnter *
    \ if &ft != 'netrw' && &buftype !='terminal' |
      \ setlocal cul cc=80 |
      \ setlocal relativenumber |
      \ let s:hidden_all = 1 | call ToggleHiddenAll() |
    \ endif " Set color column
  if has('nvim')
    autocmd TermOpen * setlocal nonumber norelativenumber cc= wrap
  endif
  autocmd BufWinEnter,WinEnter * if &ft == 'netrw' | setlocal cc= | endif
  autocmd BufWinLeave,WinLeave *
    \ if &ft != 'netrw' && &buftype != 'terminal' |
      \ setlocal nocul |
      \ setlocal cc= |
      \ setlocal norelativenumber |
    \ endif
augroup END

