let true = 1
let false = 0

let s:flag_prefix = PathJoin(g:cfg_dir, 'local', 'flags', 'vim-')

function! GlobFlag(flag)
  let flag_path = s:flag_prefix . a:flag
  return !empty(glob(flag_path))
endfunction

function! PlugFlag(plug, ...)
  let forwarded_args = ["plugins-" . a:plug . "-enabled"] + a:000
  return call('Flag', forwarded_args)
endfunction

" Toggles flag and returns new value
function! ToggleFlag(flag)
  return !Flag(a:flag, !Flag(a:flag))
endfunction

function! Flag(flag, ...)
  if a:0 > 1
    throw "why did you provide more than one value to set?"
  endif

  let flag_path = s:flag_prefix . a:flag
  let prev_value = filereadable(flag_path)

  if a:0 == 1
    if a:1
      execute "call writefile([], '" . flag_path . "')"
    else
      execute "call delete(fnameescape('" . flag_path . "'))"
    endif
  endif

  return prev_value
endfunction

function! ListFlags(flag_glob)
  let flag_path = s:flag_prefix . a:flag_glob
  let flags = []
  for flag in glob(flag_path, g:false, g:true)
    call add(flags, fnamemodify(flag, ':t'))
  endfor

  return flags
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
