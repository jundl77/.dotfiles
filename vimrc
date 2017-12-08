set shell=bash
set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/syntastic'
Plugin 'scrooloose/nerdcommenter'
Plugin 'easymotion/vim-easymotion'
Plugin 'Shougo/vimproc.vim'
Plugin 'Quramy/tsuquyomi'
Plugin 'leafgarland/typescript-vim'
Plugin 'Quramy/vim-js-pretty-template'
Plugin 'pangloss/vim-javascript'
Plugin 'mxw/vim-jsx'
Plugin 'ianks/vim-tsx'
Plugin 'bling/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'tpope/vim-repeat'
Plugin 'wakatime/vim-wakatime'
Plugin 'terryma/vim-multiple-cursors'
Plugin 'Valloric/YouCompleteMe'
Plugin 'ctrlpvim/ctrlp.vim'
Plugin 'Raimondi/delimitMate'
Plugin 'suan/vim-instant-markdown'
Plugin 'tpope/vim-surround'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line
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
if $TERM_PROGRAM =~ "iTerm"
  let &t_SI = "\<Esc>]50;CursorShape=1\x7" " Vertical bar in insert mode
  let &t_EI = "\<Esc>]50;CursorShape=0\x7" " Block in normal mode
endif"

" Put plugins and dictionaries in this dir (also on Windows)
let vimDir = '$HOME/.vim'
let &runtimepath.=','.vimDir

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

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 1
let g:syntastic_typescript_tsc_fname = ''
let g:syntastic_typescript_tsc_args = '--target ES6'
let g:syntastic_javascript_checkers = ['jsxhint']
let g:syntastic_javascript_jsxhint_exec = 'jsx-jshint-wrapper'
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

" Disabling the directional keys
map <up> <nop>
map <down> <nop>
map <left> <nop>
map <right> <nop>
imap <up> <nop>
imap <down> <nop>
imap <left> <nop>
imap <right> <nop>

" Map ESC key to more user friendly places
imap ii <Esc>
nnoremap <Tab> <Esc>
vnoremap <Tab> <Esc>gV
onoremap <Tab> <Esc>
cnoremap <Tab> <C-C><Esc>

" Share clipboard (OSX)
set clipboard=unnamed
