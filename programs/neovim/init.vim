" Print debugging information
function! DebugPrint(message)
  if $VIM_DEBUG == '1'
    echo 'DEBUG:' a:message
    return 1
  endif
  return 0
endfunction

call DebugPrint('debug mode active')

" Combine paths in a cross-platform way
function! PathJoin(...)
  if g:os ==? 'Windows'
    return join(a:000, '\')
  else
    return join(a:000, '/')
  endif
endfunction

" Setting g:os flag
if !exists('g:os')
  let g:os = substitute(system('uname'), '\n', '', '')
  if has('win64') || has('win32') || has('win16')
    let g:os = 'Windows'
    set shell=cmd.exe
  elseif g:os =~ '^MSYS_NT-.\+$'
    let g:os = 'WSL'
    set shell=cmd.exe
  endif
endif
call DebugPrint('OS is: ' . g:os)

" https://stackoverflow.com/questions/4976776/how-to-get-path-to-the-current-vimscript-being-executed/4977006
let g:vim_home_path = fnamemodify(resolve(expand('<sfile>:p')), ':h')
let g:cfg_dir = fnamemodify(g:vim_home_path, ':h:h')
call DebugPrint('vim home path is: ' . g:vim_home_path)
call DebugPrint('config path is: ' . g:cfg_dir)

"" Security
set nomodeline modelines=0

"" Compatibility
set guicursor= " Don't want unknown characters in Linux
set t_ut= " Dont want background to do weird stuff
set nocompatible

"" Functions
let s:temp = PathJoin(g:vim_home_path, 'functions.vim')
execute 'source ' . s:temp

"" Plugins
if ReadFlag('plugins-*-enabled')
  let s:temp = PathJoin(g:vim_home_path, 'plugins-list.vim')
  execute 'source ' . s:temp
endif

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
elseif g:os ==? 'Windows' || g:os ==? 'WSL'
  set clipboard=unnamed
elseif g:os ==? 'Linux'
  set clipboard=unnamedplus
  if executable('xsel')
    autocmd VimLeave * call system("xsel -ib", getreg('+'))
  endif
endif

" Deleting in insert mode
set backspace=indent,eol,start

" End of line in files
try
  set nofixendofline
catch
endtry

" Virtual Edit
set virtualedit=all

" Bell
try
  set belloff=all
catch
endtry

" Syntax Highlighting
filetype plugin indent on " Filetype detection
syntax enable " Actual highlighting

" Completions
" set omnifunc
set completefunc=LanguageClient#complete

" Showing non-printing characters
set list
if g:os ==? 'Windows' || g:os ==? 'WSL'
  set showbreak=>
  set listchars=tab:>>,nbsp:-,trail:-
else
  set showbreak=↳
  set listchars=tab:»\ ,extends:›,precedes:‹,nbsp:·,trail:·
endif

"" Indenting and Simple formatting
set tabstop=2 expandtab shiftwidth=2 softtabstop=2
set foldlevelstart=4
set textwidth=80

" Markdown and Jekyll Settings
function! MdJekyllSettings()
  let begin=getline(1)
  if begin ==# "---"
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
set noswapfile undofile backup
let s:temp = PathJoin(g:vim_home_path, 'undohist')
execute 'set undodir=' . s:temp
call DebugPrint("undo dir is: " . s:temp)
let s:temp = PathJoin(g:vim_home_path, 'backups')
execute 'set backupdir=' . s:temp
call DebugPrint("backup dir is: " . s:temp)

""" Handling special characters
" set encoding=latin1
" set isprint=
" set display+=uhex

"" Tab-local working directories
" command! -nargs=1 -complete=dir Cd let t:wd=fnamemodify(<q-args>, ':p:h') | exe "cd" t:wd
augroup TabContext
  " http://vim.1045645.n5.nabble.com/Different-working-directories-in-different-tabs-td4441751.html
  autocmd!
  autocmd TabEnter * if exists("t:wd") | exe "cd " . t:wd | endif
  autocmd TabLeave * let t:wd = Cwd()
  if exists('##TabNew')
    autocmd TabNew * try | exe "cd ". PathJoin('~', 'code') | catch | cd ~ | endtry
  endif
augroup END
if has('gui_running')
  exe 'cd ' . PathJoin('~', 'code')
endif

"" Commands
command! RunInit :call RunInit()

"" File System/Navigation
" Ctags
" Code mostly from https://github.com/webastien/vim-ctags
set tags=./tags,./TAGS,tags,TAGS

command! Def :call LanguageClient#textDocument_definition()

"" Netrw
let g:netrw_banner = 0

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
