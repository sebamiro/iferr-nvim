if exists('g:loaded_iferr') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

command! Iferr lua require'iferr'.iferr()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_iferr = 1
