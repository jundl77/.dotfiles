set shell=bash

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
Plug 'easymotion/vim-easymotion'
Plug 'Shougo/vimproc.vim'
Plug 'nvie/vim-flake8'
Plug 'bling/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'tpope/vim-repeat'
Plug 'terryma/vim-multiple-cursors'
Plug 'kana/vim-submode'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'Raimondi/delimitMate'
Plug 'rhysd/vim-grammarous'
Plug 'reedes/vim-wordy'

" Install vim or neovim specific plugins
if has('nvim')
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
    " Create dirs
    call system('mkdir ' . vimDir)
    call system('mkdir ' . myUndoDir)
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

let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#fnamemod = ':t'
set laststatus=2

let g:EasyMotion_do_mapping = 0 " Disable default mappings
let g:EasyMotion_smartcase = 1

" Gif config
map  / <Plug>(easymotion-sn)
omap / <Plug>(easymotion-tn)

" These `n` & `N` mappings are options. You do not have to map `n` & `N` to EasyMotion.
" Without these mappings, `n` & `N` works fine. (These mappings just provide
" different highlight method and have some other features )
map n <Plug>(easymotion-next)

map N <Plug>(easymotion-prev)

map <C-h> :NERDTreeToggle<CR>

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

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
set pastetoggle=<f5>
set hidden
set mouse=a
set foldmethod=indent
set foldnestmax=10
set nofoldenable
set foldlevel=2
let g:jsx_ext_required = 0

let g:ctrlp_custom_ignore = 'node_modules\|DS_Store\|git'

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
