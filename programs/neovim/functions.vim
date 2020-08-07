function! ReadFlag(flag)
  let l:flag_path = PathJoin(g:cfg_dir, 'local', 'flags', 'vim-' . a:flag)
  return !empty(glob(l:flag_path))
endfunction

" Toggles flag and returns new value
function! ToggleFlag(flag)
  let l:flag_path = PathJoin(g:cfg_dir, 'local', 'flags', 'vim-' . a:flag)
  if filereadable(l:flag_path)
    execute "call delete(fnameescape('" . l:flag_path . "'))"
    return 0
  else
    execute "call writefile([], '" . l:flag_path . "')"
    return 1
  endif
endfunction

" Sets flag and returns previous value
function! SetFlag(flag, value)
  let l:flag_path = PathJoin(g:cfg_dir, 'local', 'flags', 'vim-' . a:flag)
  let l:prev_value = filereadable(l:flag_path)

  if a:value
    execute "call writefile([], '" . l:flag_path . "')"
  else
    execute "call delete(fnameescape('" . l:flag_path . "'))"
  endif

  return l:prev_value
endfunction

function! ListFlags(flag_glob)
  let l:flag_path = PathJoin(g:cfg_dir, 'local', 'flags', 'vim-' . a:flag_glob)
  let l:flags = []
  for flag in glob(l:flag_path, 0, 1)
    let l:flags = l:flags + [ fnamemodify(flag, ':t') ]
  endfor

  return l:flags
endfunction

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
