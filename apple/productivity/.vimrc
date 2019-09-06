execute pathogen#infect()
filetype plugin indent on
syntax enable
set background=dark
colorscheme solarized
set pastetoggle=<F1>
set tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab

let g:airline_solarized_bg='dark'
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

let g:syntastic_python_checkers = ['pylint']
