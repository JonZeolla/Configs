""""""""""""""""""""""""""""
" Runtime path modifications
""""""""""""""""""""""""""""
" Add fzf
set rtp+=/usr/local/opt/fzf

"""""""""""""""
" Basic configs
"""""""""""""""
" Enable exrc for per-repo `vim` configs
set exrc
" Always parse as unix
set ffs=unix
" Blink instead of beep
set visualbell
" Disable spellcheck by default
set nospell
" Autocomplete :commands
set wildmenu
set wildmode=list:longest,full
syntax enable
set background=dark
set pastetoggle=<F1>
" Replace tabs with two spaces
set tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab
" Reduce the update time of neovim to get better GitGutter and coc experiences
set updatetime=100
" Give the cursor two lines of buffer from the start/end of a file
set scrolloff=2
" Ignore case when searching unless a capital letter is provided
set ignorecase smartcase
" Remove highlighting when searching
set nohlsearch
" Set the textwidth to 150 characters
set textwidth=150
" But don't word wrap when typing text
set formatoptions-=t

""""""""""""""
" Key mappings
""""""""""""""
" Simple macOS copy/paste
vnoremap <C-c> :w !pbcopy<CR><CR>
noremap <C-c><C-p> :r !pbpaste<CR><CR>
" Map starting a python REPL to ctrl+p ctrl+y
nmap <C-p><C-y> :CocCommand python.startREPL<CR>
" Map nerdtree to ctrl+n
nmap <C-n> :NERDTreeToggle<CR>
" Map fzf to ctrl+p
nmap <C-p> :FZF<CR>
" Toggle spellcheck
nnoremap <silent> <Leader>s :set spell!<CR>
" Toggle relative numbering
nnoremap <silent> <Leader>r :set rnu!<CR> :set number!<CR>
" Keep consistent escape key usage in terminal mode
tnoremap <Esc> <C-\><C-n>
" Reformat XML
noremap <silent> <Leader>x :%!xmllint --format %<CR>
" Reformat JSON
noremap <silent> <Leader>j :%!jq . %<CR>
" Vertically split, and jump to new side
noremap <silent> <Leader>n :vsplit <CR><C-w><C-w>

""""""""""""""""
" Code Commenter
""""""""""""""""
augroup code_commenter
  autocmd!
  autocmd FileType c,cpp,java,scala let b:leader = '// '
  autocmd FileType sh,ruby,python   let b:leader = '# '
  autocmd FileType conf,fstab,tf    let b:leader = '# '
  autocmd FileType yaml             let b:leader = '# '
  autocmd FileType tex              let b:leader = '% '
  autocmd FileType mail             let b:leader = '> '
  autocmd FileType vim              let b:leader = '" '
augroup END
noremap <silent> cc :<C-B>silent <C-E>s/^/<C-R>=escape(b:leader,'\/')<CR>/<CR>:nohlsearch<CR>
noremap <silent> uc :<C-B>silent <C-E>s/^\V<C-R>=escape(b:leader,'\/')<CR>//e<CR>:nohlsearch<CR>

"""""""""""""""""""
" Configure airline
"""""""""""""""""""
let g:airline_solarized_bg='dark'
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
" ale integration
let g:airline#extensions#ale#enabled = 1

"""""""""""""""
" Configure ale
"""""""""""""""
let g:ale_completion_enabled = 1
let b:ale_linters = {
      \   'ansible': ['ansible-lint'],
      \   'cloudformation': ['cfn-python-lint'],
      \   'dockerfile': ['dockerfile'],
      \   'python': ['pylint', 'mypy', 'unimport', 'bandit'],
      \}
let g:ale_fixers = {
      \   '*': ['remove_trailing_lines', 'trim_whitespace'],
      \   'go': ['gofmt'],
      \   'python': ['black', 'isort'],
      \   'rust': ['rustfmt'],
      \   'terraform': ['terraform'],
      \}
let g:ale_fix_on_save = 1
let g:ale_python_isort_options = '--profile black'
let g:ale_python_auto_pipenv = 1

"""""""""""""
" COC configs
"""""""""""""
" Setup extensions
let g:coc_global_extensions = [
      \ 'coc-docker',
      \ 'coc-git',
      \ 'coc-json',
      \ 'coc-powershell',
      \ 'coc-prettier',
      \ 'coc-pyright',
      \ 'coc-yaml',
      \ ]
