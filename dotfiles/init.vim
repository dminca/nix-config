colorscheme murphy
set number
set relativenumber

" file manager settings: netrw
let g:netrw_keepdir=0
" https://shapeshed.com/vim-netrw/
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_browse_split = 4
let g:netrw_winsize = 25

" Show vertical line guide width
set colorcolumn=79

" Highlight search results
set hlsearch

" Show 'invisible' characters
set lcs=tab:\ \ ,trail:·,nbsp:_
set list

" For regular expressions turn magic on
set magic

" Show matching brackets when text indicator is over them
set showmatch
" How many tenths of a second to blink when matching brackets
set mat=2
set background=dark

" Display vim colors properly on ubuntu
if $COLORTERM == 'gnome-terminal'
  set t_Co=256
endif

" Set utf8 as standard encoding and en_US as the standard language
set encoding=utf8

" Use Unix as the standard file type
set ffs=unix,dos,mac

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Text, tab and indent related
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Use spaces instead of tabs
set expandtab

" Be smart when using tabs ;)
set smarttab

" 1 tab == 2 spaces
set shiftwidth=2
set tabstop=2

set ai "Auto indent
set si "Smart indent

""""""""""""""""""""""""""""""
" => Status line
""""""""""""""""""""""""""""""
" Always show the status line
set laststatus=2

" Format the status line
set statusline=\ %{HasPaste()}%F%m%r%h\ %w\ \ CWD:\ %r%{getcwd()}%h\ \ \ Line:\ %l

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Helper functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Returns true if paste mode is enabled
function! HasPaste()
  if &paste
    return 'PASTE MODE '
  en
  return ''
endfunction

function! CommitMessages()
    let g:git_ci_msg_user = substitute(system("git config --get user.name"), '\n$', '', '')
    let g:git_ci_msg_email = substitute(system("git config --get user.email"), '\n$', '', '')

    nmap S oSigned-off-by: <C-R>=printf("%s <%s>", g:git_ci_msg_user, g:git_ci_msg_email)<CR><CR><ESC>
    nmap R oReviewed-by: <C-R>=printf("%s <%s>", g:git_ci_msg_user, g:git_ci_msg_email)<CR><ESC>
    iab #S Signed-off-by: <C-R>=printf("%s <%s>", g:git_ci_msg_user, g:git_ci_msg_email)<CR>
    iab #R Reviewed-by: <C-R>=printf("%s <%s>", g:git_ci_msg_user, g:git_ci_msg_email)<CR>
    iab #O Signed-off-by:
    iab #V Reviewed-by:
    iab #P Pair-Programmed-With:
    iab ME <C-R>=printf("%s <%s>", g:git_ci_msg_user, g:git_ci_msg_email)<CR>
endf
autocmd BufWinEnter COMMIT_EDITMSG,*.diff,*.patch,*.patches.txt call CommitMessages()

