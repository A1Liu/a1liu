let s:flag_prefix = PathJoin(g:cfg_dir, 'local', 'flags', 'vim-')

function! ReadFlag(flag)
  let flag_path = s:flag_prefix . a:flag
  return !empty(glob(flag_path))
endfunction

" Toggles flag and returns new value
function! ToggleFlag(flag)
  let flag_path = s:flag_prefix . a:flag
  if filereadable(flag_path)
    execute "call delete(fnameescape('" . flag_path . "'))"
    return 0
  else
    execute "call writefile([], '" . flag_path . "')"
    return 1
  endif
endfunction

" Sets flag and returns previous value
function! SetFlag(flag, value)
  let flag_path = s:flag_prefix . a:flag
  let prev_value = filereadable(flag_path)

  if a:value
    execute "call writefile([], '" . flag_path . "')"
  else
    execute "call delete(fnameescape('" . flag_path . "'))"
  endif

  return prev_value
endfunction

function! ListFlags(flag_glob)
  let flag_path = s:flag_prefix . a:flag_glob
  let flags = []
  for flag in glob(flag_path, 0, 1)
    call add(flags, fnamemodify(flag, ':t'))
  endfor

  return flags
endfunction

function! GoToCurrentTag() " Go to definition of word under cursor
  return GoToTag(expand("<cword>"))
endfunction

function! GoToTag(tagname) " Go to a tag
  try
    if a:tagname != ""
      silent exe 'ts ' . a:tagname
      let old_tags = &tags
      let &tags = get(tagfiles(), 0) " Don't know why this is necessary but it is
      exe 'new' | exe 'tjump ' . a:tagname | exe 'norm zz'
      let &tags = old_tags
    endif
  catch
  endtry
endfunction

" Rooter
function! GitRoot()
  return system('git rev-parse --show-toplevel')
endfunction

function! SynStack()
  if !exists("*synstack")
    return
  endif
  echo map(synstack(line('.'), col('.')), 'synIDattr(v:val,"name")')
endfunction

try
  function! RunInit()
    let save_pos = getpos(".")
    execute 'source ' . PathJoin(g:vim_home_path, 'init.vim')
    call setpos(".", save_pos)
  endfunction
catch
endtry

function! Zip(l1, l2)
  let len1 = len(a:l1)
  let len2 = len(a:l2)
  if len1 != len2
    throw "lists aren't the same length"
  endif

  let current = 0
  let new = []
  while current < len1
    call add(new, [a:l1[current], a:l2[current]])
    let current += 1
  endwhile

  return new
endfunction


function! Cwd()
  try
    return getcwd()
  catch
    return resolve('~')
  endtry
endfunction

" https://vi.stackexchange.com/questions/9888/how-to-pipe-characters-to-cmd
function! GetVisualSelection()
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][col1 - 1:]
  return join(lines, "\\n")
endfunction
