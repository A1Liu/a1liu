"" Visual Changes
set number relativenumber " line numberings
set hlsearch incsearch " highlighting when using find
set cc=80
set cul

" https://shapeshed.com/vim-statuslines/
set statusline=
set statusline+=\ %f
set statusline+=%m
set statusline+=%=
set statusline+=\ %y
set statusline+=\ %p%%
set statusline+=\ %c:%l
set statusline+=\ 

" Hiding the UI
" https://unix.stackexchange.com/questions/140898/vim-hide-status-line-in-the-bottom
let s:hidden_all = 0
function! ToggleHiddenAll()
  if s:hidden_all  == 0
    let s:hidden_all = 1
    set noshowmode
    set noruler
    set laststatus=0
    set noshowcmd
    set nocul
    set cc=
  else
    let s:hidden_all = 0
    set showmode
    if &ft != 'netrw'
      set ruler
      set cul
      set cc=80
    endif
    set laststatus=2
    set showcmd
  endif
endfunction

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

" Color Scheme
hi clear
if exists("syntax_on")
  syntax reset
endif

colorscheme solarized8_high

let s:config_dir = fnamemodify(g:vim_home_path, ':h:h')
let s:dark_mode_flag = s:config_dir . '/local/flags/vim-dark-mode'
" function! ToggleBg()
"   if filereadable(s:dark_mode_flag)
"     " execute "delete '" . s:dark_mode_flag . "'"
"     set background=light
"   else
"      " execute "file '" . s:dark_mode_flag
"     set background=dark
"   endif
" endfunction


if filereadable(s:dark_mode_flag)
  set background=dark
else
  set background=light
endif

" colorscheme darkblue
" hi Normal ctermfg=Gray ctermbg=Black
" hi ColorColumn ctermbg=Gray ctermfg=Black
" hi Search cterm=reverse ctermbg=Black ctermfg=Yellow
" hi IncSearch cterm=reverse ctermbg=Black ctermfg=Yellow
" hi StatusLine ctermbg=Gray ctermfg=Black
" hi ErrorMsg ctermbg=Red ctermfg=White
" hi Visual cterm=reverse ctermfg=Gray ctermbg=Black
" hi WildMenu ctermfg=Gray ctermbg=Black
" hi NonText ctermfg=LightBlue
" hi Comment ctermfg=DarkGray
" hi Pmenu ctermbg=Gray ctermfg=Black
" hi PmenuSel ctermbg=Magenta ctermfg=Black
