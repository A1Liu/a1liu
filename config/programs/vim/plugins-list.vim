if !GlobFlag('plug-*')
  Dbg 'No plugins enabled'
  finish
endif

"" Plugins
let g:plugin_manager_home = PathJoin(g:vim_home_path, 'plugged')
let g:plugin_manager_script_path = PathJoin(g:vim_home_path, 'plug.vim')
let g:plugin_manager_script_url = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

Dbg 'plugins home is ' . ShortPath(g:plugin_manager_home)
Dbg 'plugin manager is ' . ShortPath(g:plugin_manager_script_path)
Dbg 'plugin manager URL is ' . ShortPath(g:plugin_manager_script_url)

if empty(glob(g:plugin_manager_script_path))
  Dbg 'installing package manager...'
  execute 'silent !curl -LSso ' . g:plugin_manager_script_path . ' ' . g:plugin_manager_script_url
endif

" This forces the loading of the script, so that `sudo vim` can work nicely
execute 'source ' . g:plugin_manager_script_path

call plug#begin(g:plugin_manager_home)

Plug '~/code/liu/vim-liu'

if PlugFlag('base')
  Plug 'tpope/vim-eunuch'
  Plug 'tpope/vim-fugitive'
  Plug 'machakann/vim-swap'
  Plug 'tpope/vim-rsi'
endif

if PlugFlag('format')
  " Autoformatters
  Plug 'Chiel92/vim-autoformat'

  let s:clangfmt = "-lines='.a:firstline.':'.a:lastline.' --assume-filename=\"'.expand('%:p').'\" -style=file"
  let g:formatdef_clangformat = "'clang-format " . s:clangfmt . "'"
  let g:formatdef_swiftformat = "'swiftformat --quiet'"

  " Meh, clang-format not pulling its weight with Java 19, and also it's not
  " well supported by Java ecosystem, so difficult to get other peeps to use
  " it easily
  " let g:formatters_java = ['clangformat']

  let g:formatters_typescriptreact = ['prettier']
  let g:formatters_javascriptreact = ['prettier']
  let g:formatters_typescript = ['prettier']
  let g:formatters_javascript = ['prettier']
  let g:formatters_svelte = ['prettier']

  let g:formatters_arduino = ['clangformat']
  let g:formatters_swift = ['swiftformat']

  Dbg 'autoformat in verbose mode'
  let g:autoformat_verbosemode = g:debug_mode

  augroup AutoFormatting
    autocmd!
    autocmd FileType * let b:autoformat_enabled = 0
    autocmd FileType rust,java,c,cpp,go,arduino,swift let b:autoformat_enabled = 1
          \ | let b:autoformat_remove_trailing_spaces = 0
          \ | let b:autoformat_retab = 0
          \ | let b:autoformat_autoindent = 0
    autocmd FileType vim let b:autoformat_enabled = 0
    autocmd BufWrite * if exists('b:autoformat_enabled') && b:autoformat_enabled | Autoformat | endif
  augroup END
endif

if PlugFlag('files')
  Plug 'preservim/nerdtree'
endif

if PlugFlag('fzf')
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'
endif

if PlugFlag('solarized')
  Plug 'lifepillar/vim-solarized8'
endif

" Languages
if PlugFlag('polyglot')
  let g:polyglot_disabled = []

  " See comment below for why polyglot's typescript is disabled
  call add(g:polyglot_disabled, 'typescript')

  " Filetype detection in polyglot leads to some problems with
  " Conquer-of-Code's TSX handling.
  call add(g:polyglot_disabled, 'ftdetect')

  Plug 'sheerun/vim-polyglot'
  Plug 'ziglang/zig.vim'
  Plug 'evanleck/vim-svelte'

  " Polyglot uses yats, which is 'advanced', i.e. overengineered and idiotic.
  " We use this plugin instead. Because, you can write all the stupid fucking
  " colors of the rainbow into your highlighter, it doesn't make the
  " experience any better.
  "                                 - Albert Liu, Feb 04, 2022 Fri 22:46 EST
  "
  " NOTE: Might need to fix all the instances of `hi link` to say `hi def link`
  " in the syntax folder of this highlighter so that it doesn't disappear when
  " using `<C-L>`
  "                                 - Albert Liu, May 14, 2022 Sat 17:16 EDT

  Plug 'leafgarland/typescript-vim'

  Plug 'jansedivy/jai.vim'
elseif PlugFlag('markdown')
  Plug 'plasticboy/vim-markdown'
endif

let g:vim_markdown_math = 1
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_new_list_item_indent = 0
let g:vim_markdown_auto_insert_bullets = 0

" Snippets
if PlugFlag('snippets') && !has("gui_macvim")
  Plug 'SirVer/ultisnips'
  Plug 'honza/vim-snippets'

  let g:UltiSnipsExpandTrigger="<C-N><C-N>"
  let g:UltiSnipsJumpForwardTrigger="<C-R>"
  let g:UltiSnipsJumpBackwardTrigger="<C-E>"
endif

" Language server support because I have to I guess
if PlugFlag('lsc')
  Plug 'neoclide/coc.nvim', {'branch': 'release'}

  let g:coc_global_extensions = [
        \ 'coc-tsserver',
        \ 'coc-json',
        \]

  " coc#refresh() executes the current suggestion
  inoremap <silent><expr> <C-F> coc#pum#visible() ? coc#pum#confirm() : coc#refresh()
  nnoremap <silent> <leader>B <Plug>(coc-implementation)
  " nnoremap <silent> <leader>G  :<C-u>CocList commands<cr>
endif

call plug#end()
