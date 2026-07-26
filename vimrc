" bash is not a usable shell on Windows (missing, or resolves to WSL's
" System32 bash.exe), which would break system() and :! there
if !has('win32')
  set shell=bash
endif

set nocompatible              " be iMproved, required
filetype off                  " required

" PLUGINS START ---- Specify directory for plugins
if has('nvim')
  call plug#begin('~/.config/nvim/plugged')
else
  call plug#begin('~/.vim/plugged')
endif

" Plugins for neovim and vim
Plug 'scrooloose/nerdcommenter'
Plug 'nvie/vim-flake8'
Plug 'tpope/vim-repeat'
Plug 'kana/vim-submode'
Plug 'rhysd/vim-grammarous'
Plug 'reedes/vim-wordy'

" Install vim or neovim specific plugins (the Lua plugins cannot load in plain vim)
if has('nvim')
  Plug 'smoka7/hop.nvim'                      " replaces easymotion/vim-easymotion (unmaintained)
  Plug 'nvim-lualine/lualine.nvim'            " replaces bling/vim-airline (unmaintained)
  Plug 'nvim-tree/nvim-web-devicons'
  Plug 'nvim-lua/plenary.nvim'
  Plug 'nvim-telescope/telescope.nvim'        " replaces ctrlpvim/ctrlp.vim (old, no live-grep)
  Plug 'nvim-tree/nvim-tree.lua'              " file-explorer sidebar, replaces NERDTree
  Plug 'windwp/nvim-autopairs'                " replaces Raimondi/delimitMate (unmaintained)
  Plug 'neovim/nvim-lspconfig'                " CLion-style go-to-def/rename/find-usages
  Plug 'williamboman/mason.nvim'              " auto-installs language servers
  Plug 'williamboman/mason-lspconfig.nvim'
  Plug 'neomake/neomake'
else
  Plug 'scrooloose/syntastic'
  Plug 'Valloric/YouCompleteMe'
endif

call plug#end()
"
" Brief help
"   :PlugInstall [name ...] [#threads]	       Install plugins
"   :PlugUpdate [name ...] [#threads]	         Install or update plugins
"   :PlugClean[!]	                             Remove unused directories (bang version will clean without prompt)
"   :PlugUpgrade	                             Upgrade vim-plug itself
"   :PlugStatus	                               Check the status of plugins
"   :PlugDiff	                                 Examine changes from the previous update and the pending changes
"   :PlugSnapshot[!] [output path]	           Generate script for restoring the current snapshot of the plugins
"
" PLUGINS END

let mapleader=","
syntax on
set number
set cursorline
set cursorcolumn
nnoremap <Tab> :bnext<CR>
nnoremap <S-Tab> :bprevious<CR>
map q: <Nop>
nnoremap Q <nop>
autocmd InsertLeave * write

" Special config for iTerm
if $TERM_PROGRAM =~ "iTerm"
  let &t_SI = "\<Esc>]50;CursorShape=1\x7" " Vertical bar in insert mode
  let &t_EI = "\<Esc>]50;CursorShape=0\x7" " Block in normal mode
endif"

" Put plugins and dictionaries in this dir (also on Windows)
if has('nvim')
  let vimDir = '$HOME/.bundle/nvim'
else
  let vimDir = '$HOME/.vim'
endif
let &runtimepath.=','.vimDir

" Set up spellchecking
" set spell spelllang=en_us

" Keep undo history across sessions by storing it in a file
if has('persistent_undo')
    let myUndoDir = expand(vimDir . '/undodir')
    " Native mkdir() instead of system('mkdir'): works on Windows too, where
    " shelling out to a unix mkdir is not available
    call mkdir(expand(vimDir), 'p')
    call mkdir(myUndoDir, 'p')
    let &undodir = myUndoDir
    set undofile
endif

highlight CursorColumn ctermfg=none ctermbg=23 cterm=bold guifg=white guibg=darkgrey gui=bold
autocmd InsertEnter * highlight CursorColumn ctermfg=none ctermbg=none cterm=bold guifg=white guibg=yellow gui=bold
autocmd InsertLeave * highlight CursorColumn ctermfg=none ctermbg=23 cterm=bold guifg=Black guibg=yellow gui=NONE
autocmd BufWritePre *.ts{x} :%s/\s\+$//e

highlight OverLength ctermbg=red ctermfg=white guibg=#592929
match OverLength /\%121v.\+/
highlight ExtraWhitespace ctermbg=darkgrey guibg=darkgrey
match ExtraWhitespace /\s\+$/
highlight Folded ctermbg=darkgrey guibg=darkgrey

set backspace=indent,eol,start

set laststatus=2

" Native /, n, N restored (easymotion previously remapped them); keep the
" smartcase behavior easymotion's search used to provide
set ignorecase
set smartcase

if has('nvim')
  " hop.nvim jump-to-match (replaces easymotion)
  nnoremap s <cmd>HopChar2<CR>
  nnoremap S <cmd>HopWord<CR>

  " nvim-tree file-explorer sidebar (replaces NERDTree)
  nnoremap <C-h> <cmd>NvimTreeToggle<CR>

  " Telescope, CLion-style keybinds. Many terminals (Terminal.app, default
  " tmux) cannot transmit Ctrl+Shift chords, and Windows Terminal grabs
  " Ctrl+Shift+F for its own find, so <C-p> (the old ctrlp key) and
  " <leader>ff / <leader>fg work everywhere as fallbacks.
  nnoremap <C-S-n> <cmd>Telescope find_files<CR>
  nnoremap <C-S-f> <cmd>Telescope live_grep<CR>
  nnoremap <C-p> <cmd>Telescope find_files<CR>
  nnoremap <leader>ff <cmd>Telescope find_files<CR>
  nnoremap <leader>fg <cmd>Telescope live_grep<CR>
endif

" Config syntastic
if has('nvim')
  call neomake#configure#automake('nrwi', 500)
else
  let g:syntastic_always_populate_loc_list = 1
  let g:syntastic_auto_loc_list = 1
  let g:syntastic_check_on_open = 1
  let g:syntastic_check_on_wq = 1
  let g:syntastic_typescript_tsc_fname = ''
  let g:syntastic_typescript_tsc_args = '--target ES6'
  let g:syntastic_javascript_checkers = ['jsxhint']
  let g:syntastic_javascript_jsxhint_exec = 'jsx-jshint-wrapper'
  let g:syntastic_quiet_messages = { "regex": [
          \ '\possible unwanted space at "{"',
          \ '\Command terminated with space',
          \ ] }
endif

let g:indentLine_enabled = 1
let g:indentLine_color_term = 239
let g:indentLine_char = '|'

filetype plugin indent on
set tabstop=2
set expandtab
set shiftwidth=2
set smartindent
set autoindent
try
  set pastetoggle=<f5>
catch
endtry
set hidden
set mouse=a
set foldmethod=indent
set foldnestmax=10
set nofoldenable
set foldlevel=2
let g:jsx_ext_required = 0

let g:NERDSpaceDelims = 1
nnoremap <C-c> :call NERDComment(0,"toggle")<CR>
vnoremap <C-c> :call NERDComment(0,"toggle")<CR>

nnoremap <Leader>w <C-w>
vnoremap <M-c> "+y

" Hybrid line numbers
set number relativenumber

:augroup numbertoggle
:  autocmd!
:  autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
:  autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
:augroup END

" Create new line by pressing enter or shift enter
map <Enter> o<ESC>
map <S-Enter> O<ESC>

" Setting leader char to semicolon (on home row)
let mapleader = ";"

" Setting window navigation
" Create a submode to handle windows
" The submode is entered whith <Leader>k and exited with <Leader>
call submode#enter_with('WindowsMode', 'n', '', '<Leader>k', ':echo "windows mode"<CR>')
call submode#leave_with('WindowsMode', 'n', '', '<Leader>')

" Change of windows with hjkl
call submode#map('WindowsMode', 'n', '', 'j', '<C-w>j')
call submode#map('WindowsMode', 'n', '', 'k', '<C-w>k')
call submode#map('WindowsMode', 'n', '', 'h', '<C-w>h')
call submode#map('WindowsMode', 'n', '', 'l', '<C-w>l')

" Close a window with q
call submode#map('WindowsMode', 'n', '', 'q', '<C-w>c')

" Setting tab navigation
nnoremap th  :tabfirst<CR>
nnoremap tk  :tabnext<CR>
nnoremap tj  :tabprev<CR>
nnoremap tl  :tablast<CR>
nnoremap tt  :tabedit<Space>
nnoremap tn  :tabnext<Space>
nnoremap tm  :tabm<Space>
nnoremap td  :tabclose<CR>

" Setting buffer navigation
" Next buffer
map <leader>n :bn<cr>
" Previous buffer
map <leader>p :bp<cr>
" Close buffer
map <leader>d :bd<cr>

" Disabling the directional keys
map <up> <nop>
map <down> <nop>
map <left> <nop>
map <right> <nop>
imap <up> <nop>
imap <down> <nop>
imap <left> <nop>
imap <right> <nop>

imap gj j
imap gk k
set tw=180

" Map ESC key to more user friendly places
imap ii <Esc>
nnoremap <Tab> <Esc>
vnoremap <Tab> <Esc>
onoremap <Tab> <Esc>
cnoremap <Tab> <C-C><Esc>

" Share clipboard (OSX)
" set clipboard=unnamed

if has('nvim')
lua << EOF
-- pcall every require: on the very first launch none of these plugins exist
-- yet (the installers run nvim headlessly against this exact config to
-- bootstrap :PlugInstall), and a missing plugin must not abort the chunk.
local function try(mod)
  local ok, m = pcall(require, mod)
  return ok and m or nil
end

local hop = try('hop')
if hop then hop.setup() end
local autopairs = try('nvim-autopairs')
if autopairs then autopairs.setup{} end
local tree = try('nvim-tree')
if tree then tree.setup{} end
local lualine = try('lualine')
if lualine then lualine.setup{ options = { theme = 'auto' } } end
local telescope = try('telescope')
if telescope then
  telescope.setup{
    defaults = {
      file_ignore_patterns = { 'node_modules', '%.git/', '%.DS_Store' },
    },
  }
end

-- LSP needs nvim 0.11+: vim.lsp.config/enable and vim.lsp.completion don't
-- exist before that, and mason-lspconfig v2 refuses to load there (apt ships
-- 0.9 or older on Ubuntu/Debian). Skip the whole section on old nvim instead
-- of erroring on every launch.
if vim.fn.has('nvim-0.11') == 1 then
  -- Auto-installed via Mason: pyright (Python), lua_ls (editing these configs)
  local mason = try('mason')
  local mason_lspconfig = try('mason-lspconfig')
  if mason and mason_lspconfig then
    mason.setup()
    mason_lspconfig.setup{
      ensure_installed = { 'pyright', 'lua_ls' },
    }

    -- CLion-style code navigation (needs a language server attached to work; :LspInfo to check)
    local on_attach = function(client, bufnr)
      local opts = { buffer = bufnr, silent = true }
      vim.keymap.set('n', '<C-b>', vim.lsp.buf.definition, opts)         -- Go to Declaration
      vim.keymap.set('n', '<C-A-b>', vim.lsp.buf.implementation, opts)   -- Go to Implementation
      vim.keymap.set('n', '<A-F7>', vim.lsp.buf.references, opts)        -- Find Usages
      vim.keymap.set('n', '<S-F6>', vim.lsp.buf.rename, opts)            -- Rename
      vim.keymap.set('n', '<C-q>', vim.lsp.buf.hover, opts)              -- Quick Documentation
      vim.keymap.set('n', '<A-CR>', vim.lsp.buf.code_action, opts)       -- Show Intention Actions
      vim.keymap.set('n', '<C-A-l>', function() vim.lsp.buf.format{ async = true } end, opts) -- Reformat Code
      vim.keymap.set('n', '<F2>', vim.diagnostic.goto_next, opts)        -- Next Highlighted Error
      vim.keymap.set('n', '<S-F2>', vim.diagnostic.goto_prev, opts)      -- Previous Highlighted Error
      if client:supports_method('textDocument/completion') then
        vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
      end
    end

    -- nvim-lspconfig still ships the default per-server configs vim.lsp.config() merges with;
    -- vim.lsp.config/enable is the native nvim 0.11+ API replacing require('lspconfig').X.setup{}
    vim.lsp.config('pyright', { on_attach = on_attach })
    vim.lsp.config('lua_ls', { on_attach = on_attach })
    vim.lsp.enable({ 'pyright', 'lua_ls' })
  end
end
EOF
endif
