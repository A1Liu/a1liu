
" Print debugging information
function! DebugPrint(message)
  if $VIM_DEBUG == '1'
    echo 'DEBUG:' a:message
    return 1
  endif
  return 0
endfunction

if $VIM_DEBUG != ''
  let g:autoformat_verbosemode=1
endif
call DebugPrint('Debug mode active')

" Setting g:os flag
if !exists('g:os')
  let g:os = substitute(system('uname'), '\n', '', '')
  if has('win64') || has('win32') || has('win16') || g:os =~ "^MSYS_NT\.\+$"
    let g:os = 'Windows'
    " https://stackoverflow.com/questions/94382/vim-with-powershell
    set shell=cmd.exe
    " set shellcmdflag=/c\ powershell.exe\ -NoLogo\ -NoProfile\ -NonInteractive\ -ExecutionPolicy\ RemoteSigned
    " set shellpipe=|
    " set shellredir=>
  endif
endif
call DebugPrint('OS is: ' . g:os)

" Combine paths in a cross-platform way
function! PathJoin(...)
  if g:os ==? 'Windows'
    return join(a:000, '\')
  else
    return join(a:000, '/')
  endif
endfunction

" https://stackoverflow.com/questions/4976776/how-to-get-path-to-the-current-vimscript-being-executed/4977006
let g:vim_home_path = fnamemodify(resolve(expand('<sfile>:p')), ':h')
if g:os ==? 'Windows' && has('nvim') " Hack because neovim doesn't work
  let g:vim_home_path = 'C:\Users\Alyer\code\config\programs\neovim'
endif
let g:cfg_dir = fnamemodify(g:vim_home_path, ':h:h')
let g:placeholder = '<++>'
call DebugPrint('Vim Home path is: ' . g:vim_home_path)
call DebugPrint('Config path is: ' . g:cfg_dir)

" let g:plug_path = PathJoin(g:vim_home_path, 'autoload', 'plug.vim')
let g:first_run_flag_path = PathJoin(g:cfg_dir,'local', 'flags', 'installed-vim')
let g:first_run = empty(glob(g:first_run_flag_path))

if g:first_run
  execute "silent split " . g:first_run_flag_path
  execute "silent wq"
endif

"" Security
set nomodeline modelines=0

"" Compatibility
set guicursor= " Don't want unknown characters in Linux
set t_ut= " Dont want background to do weird stuff
set nocompatible

" Getting terminal colors to work
" https://medium.com/@dubistkomisch/how-to-actually-get-italics-and-true-colour-to-work-in-iterm-tmux-vim-9ebe55ebc2be
if exists('+termguicolors') && has("termguicolors") && $TERM_PROGRAM !=? "Apple_Terminal" && g:os ==? 'Darwin'
  call DebugPrint("term gui colors enabled")
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif


"" Plugins
let s:temp = PathJoin(g:vim_home_path, 'plugins-list.vim')
execute 'source ' . s:temp

"" Keybindings
let s:temp = PathJoin(g:vim_home_path, 'keybindings.vim')
execute 'source ' . s:temp

"" Colors
let s:temp = PathJoin(g:vim_home_path, 'visual.vim')
execute 'source ' . s:temp

if has('wildmenu')
  set wildmode=longest,full
  set wildignorecase wildmenu
endif
set splitright splitbelow
set ignorecase smartcase " Ignore case in searching except when including capital letters

" Clipboard
if g:os ==? 'Darwin'
  set clipboard=unnamed
elseif g:os ==? 'Windows'
  set clipboard=unnamed
else
  set clipboard=unnamedplus
  if executable('xsel')
    autocmd VimLeave * call system("xsel -ib", getreg('+'))
  endif
endif

" Deleting in insert mode
set backspace=indent,eol,start

" End of line in files
set nofixendofline

" Bell
set belloff=all

" Syntax Highlighting
filetype plugin indent on " Filetype detection
syntax enable " Actual highlighting

" Completions
" set omnifunc
set completefunc=LanguageClient#complete

" Showing non-printing characters
set list
if g:os ==? 'Windows'
  set showbreak=>
  set listchars=tab:>>,nbsp:-,trail:- " extends:›,precedes:‹,
else
  set showbreak=↳
  set listchars=tab:»\ ,extends:›,precedes:‹,nbsp:·,trail:·
endif

"" Indenting
set tabstop=2 expandtab shiftwidth=2 softtabstop=2
set foldlevelstart=4

" Markdown and Jekyll Settings
function! MdJekyllSettings()
  let l:begin=getline(1)
  if l:begin ==# "---"
    set tabstop=3 shiftwidth=3 softtabstop=3
  endif
endfunction

augroup KramdownHighlighting
  autocmd!
  autocmd BufRead,BufNewFile,BufEnter *.md,*.markdown call MdJekyllSettings()
  autocmd BufLeave *.md,*.markdown set tabstop=2 | set shiftwidth=2 | set softtabstop=2
augroup END



"" Langauge specific stuff
augroup LanguageSpecific
  autocmd!
  autocmd FileType go setlocal nolist noexpandtab
augroup END



"" Warnings and Error Messages
set autoread
" augroup WarningMessages
"   autocmd!
"   autocmd FileChangedShell * echo 'File was changed'
" augroup END



"" Saving my ass
set noswapfile
set undofile
let s:temp = PathJoin(g:vim_home_path, 'undohist')
execute 'set undodir=' . s:temp
call DebugPrint("Undo dir is: " . s:temp)


"" Commands
try
  function! RunInit()
    let save_pos = getpos(".")
    source $MYVIMRC
    call setpos(".", save_pos)
  endfunction
  command RunInit call RunInit()
catch
endtry

" Vim tab-local working directories
" command! -nargs=1 -complete=dir Cd let t:wd=fnamemodify(<q-args>, ':p:h') | exe "cd" t:wd
augroup TabContext
  " http://vim.1045645.n5.nabble.com/Different-working-directories-in-different-tabs-td4441751.html
  autocmd!
  autocmd TabEnter * if exists("t:wd") | exe "cd " . t:wd | endif
  autocmd TabLeave * let t:wd = getcwd()
  autocmd TabNew * try | exe "cd ". PathJoin('~', 'code') | catch | cd ~ | endtry
augroup END


"" File System/Navigation
6
" Rooter
function! GitRoot()
  return system('git rev-parse --show-toplevel')
endfunction

" Ctags
" Code mostly from https://github.com/webastien/vim-ctags
set tags=./tags,./TAGS,tags,TAGS

function! GoToCurrentTag() " Go to definition of word under cursor
  return GoToTag(expand("<cword>"))
endfunction

function! GoToTag(tagname) " Go to a tag
  try
    if a:tagname != ""
      silent exe 'ts ' . a:tagname
      let l:old_tags = &tags
      let &tags = get(tagfiles(), 0) " Don't know why this is necessary but it is
      exe 'new' | exe 'tjump ' . a:tagname | exe 'norm zz'
      let &tags = l:old_tags
    endif
  catch
  endtry
endfunction

command! Def :call LanguageClient#textDocument_definition()



" Folders n stuff
let g:netrw_sort_sequence='[\/]$,\<core\%(\.\d\+\)\=\>,'

" Docs
let g:netrw_sort_sequence.= 'README,LICENSE,*.md$,*.markdown$,'
" C and C++ Files
let g:netrw_sort_sequence.= '\.h$,\.c$,\.cpp$,'
" Java files
let g:netrw_sort_sequence.= '\.java$,'
" The vast majority of files
let g:netrw_sort_sequence.= '\~\=\*$,*,'
" Files that begin with the '.' character, and other mildly hidden files
let g:netrw_sort_sequence.= '^\..*$,'
" Compiled files
let g:netrw_sort_sequence.= '\.o$,\.obj$,\.class$,'
" Vim files? Text editor info files and dumb files
let g:netrw_sort_sequence.= '\.info$,\.swp$,\.bak$,^\.DS_Store$,\~$'
