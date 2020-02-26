"" Initialize global variables
" https://stackoverflow.com/questions/4976776/how-to-get-path-to-the-current-vimscript-being-executed/4977006
" https://github.com/tonsky/FiraCode

" Print debugging information
function! DebugPrint(message)
  if $VIM_DEBUG != ''
    echo 'DEBUG:' a:message
    return 1
  endif
  return 0
endfunction

call DebugPrint('Debug mode active')

if !exists('g:os')
  if has('win64') || has('win32') || has('win16')
    let g:os = 'Windows'
    " https://stackoverflow.com/questions/94382/vim-with-powershell
    set shell=cmd.exe
    set shellcmdflag=/c\ powershell.exe\ -NoLogo\ -NoProfile\ -NonInteractive\ -ExecutionPolicy\ RemoteSigned
    set shellpipe=|
    set shellredir=>
  else
    let g:os = substitute(system('uname'), '\n', '', '')
  endif
endif
call DebugPrint('OS is: ' . g:os)

" Combine paths in a cross-platform way
function! PathJoin(...)
  if g:os == 'Windows'
    return join(a:000, '\')
  else
    return join(a:000, '/')
  endif
endfunction

let g:vim_home_path = fnamemodify(resolve(expand('<sfile>:p')), ':h')
let g:cfg_dir = fnamemodify(g:vim_home_path, ':h:h')
let g:placeholder = '<++>'
call DebugPrint('Vim Home path is: ' . g:vim_home_path)
call DebugPrint('Config path is: ' . g:cfg_dir)

let g:plug_path = PathJoin(g:vim_home_path, 'autoload', 'plug.vim')
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

" Getting terminal colors to work
" https://medium.com/@dubistkomisch/how-to-actually-get-italics-and-true-colour-to-work-in-iterm-tmux-vim-9ebe55ebc2be

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
if g:os == 'Darwin'
  set clipboard=unnamed
elseif g:os == 'Windows'
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

" Syntax Highlighting
filetype plugin indent on " Filetype detection
syntax enable " Actual highlighting

" Showing non-printing characters
set list
set showbreak=\\r
set listchars=tab:»\ ,nbsp:·,trail:· " extends:›,precedes:‹,

"" Indenting
set tabstop=2 expandtab shiftwidth=2 softtabstop=2
set foldlevelstart=4

" Markdown and Jekyll Settings
function! MarkdownJekyllSettings()
  let l:begin=getline(1)
  if l:begin == "---"
    set tabstop=3 shiftwidth=3 softtabstop=3
  endif
endfunction

augroup KramdownHighlighting
  autocmd!
  autocmd BufRead,BufNewFile,BufEnter *.md,*.markdown
    \ call MarkdownJekyllSettings()
  autocmd BufLeave *.md,*.markdown
    \ set tabstop=2 | set shiftwidth=2
augroup END



"" Formatting
augroup autoformat_settings
  autocmd FileType c,cpp,proto,java,javascript,glsl AutoFormatBuffer clang-format
  if executable('js-beautify')
    autocmd FileType html,css,sass,scss,less AutoFormatBuffer js-beautify
  endif
  if executable('yapf')
    autocmd FileType python AutoFormatBuffer yapf
  endif
  " if executable('prettier')
  "   autocmd FileType javascript AutoFormatBuffer prettier
  " endif
  " autocmd FileType dart AutoFormatBuffer dartfmt
  " autocmd FileType go AutoFormatBuffer gofmt
  " autocmd FileType bzl AutoFormatBuffer buildifier
  " autocmd FileType gn AutoFormatBuffer gn
  " Alternative: autocmd FileType python AutoFormatBuffer autopep8
  " autocmd FileType vue AutoFormatBuffer prettier
augroup END



"" Saving my ass
set undofile
let s:temp = substitute(PathJoin(g:vim_home_path, 'undohist'), ' ', '\ ', '')
execute 'set undodir=' . s:temp
call DebugPrint("Undo dir is: " . s:temp)


"" Commands
" TODO Make a toggle for showing column on left hand side

command! RunInit so $MYVIMRC

" Vim tab-local working directories
command! -nargs=1 -complete=dir Cd let t:wd=fnamemodify(<q-args>, ':p:h') | exe "cd" t:wd
augroup TabContext
  " http://vim.1045645.n5.nabble.com/Different-working-directories-in-different-tabs-td4441751.html
  au TabEnter * if exists("t:wd") | exe "cd" t:wd | endif
augroup END

" command! Root exe "Rooter" | let t:wd=getcwd()

" https://github.com/junegunn/fzf.vim/issues/251
" command! -nargs=? -complete=dir FD call
"   \ fzf#run(fzf#wrap(
"   \ {'source': 'find '
"   \ . (<q-args> == '' ? fnamemodify('.', ':p:h') : fnamemodify(<q-args>, ':p:h'))
"   \ . ' -type d',
"   \  'sink': 'Cd'}))



"" File System/Navigation

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
  if a:tagname != ""
    try | silent exe 'ts ' . a:tagname | catch | return | endtry
    let l:old_tags = &tags
    let &tags = get(tagfiles(), 0) " Don't know why this is necessary but it is
    exe 'new' | exe 'tjump ' . a:tagname | exe 'norm zz'
    let &tags = l:old_tags
  endif
endfunction

command! Def call GoToCurrentTag()

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

