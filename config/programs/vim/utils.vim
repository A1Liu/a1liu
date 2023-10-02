let s:flag_prefix = PathJoin(g:cfg_dir, 'local', 'flags', 'vim-')
let s:flag_dict = {}


function! GlobFlag(flag)
  let flag_path = s:flag_prefix . a:flag
  return !empty(glob(flag_path))
endfunction

function! PlugFlag(plug, ...)
  let forwarded_args = ['plug-' . a:plug] + a:000
  return call('GetFlag', forwarded_args)
endfunction

" Toggles flag and returns new value
function! ToggleFlag(flag)
  return !SetFlag(a:flag, !GetFlag(a:flag))
endfunction

" Gets the value of a flag, and optionally takes a list of reasons the flag
" is being used
function GetFlag(flag, ...)
  if !g:init_script_finished
    if !has_key(s:flag_dict, a:flag)
      let s:flag_dict[a:flag] = []
    endif

    let s:flag_dict[a:flag] = s:flag_dict[a:flag] + a:000
  endif

  let flag_path = s:flag_prefix . a:flag
  let prev_value = filereadable(flag_path)

  return prev_value
endfunction

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

" Usage: Write `:put=FlagDocs()` in the README to update the docs
function! FlagDocs()
  let out = ""
  for flag in FlagList()
    let out = out . "  - `" . flag . "`"
    let docs = FlagInfo(flag)
    if len(docs) == 1
      let out = out . " - " . docs[0]
      let out = out . "\n"
      continue
    endif

    for doc in docs
      let out = out . "\n    - " . doc
    endfor

    let out = out . "\n"
  endfor

  return out
endfunction

function! FlagList()
  return keys(s:flag_dict)
endfunction

function! FlagInfo(name)
  return s:flag_dict[a:name]
endfunction

function! ListFlags(flag_glob)
  let flag_path = s:flag_prefix . a:flag_glob
  let flags = []
  for flag in glob(flag_path, 0, 1)
    call add(flags, fnamemodify(flag, ':t'))
  endfor

  return flags
endfunction

function! SynStack()
  if exists("*synstack")
    echo map(synstack(line('.'), col('.')), 'synIDattr(v:val,"name")')
  endif
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
