""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Assign Tcl omni-completion, activated also by <tab> key
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
setlocal omnifunc=TclComplete#Complete

" Let <tab> activate and advance through the popup menu.  
"   I would Shift-Tab to go backwards, but that's a Konsole shortcut
inoremap <buffer> <expr> <tab> pumvisible() ? "\<c-n>" : "\<c-x><c-o>"

" ^D and ^U for faster scrolling through the popup menu.
inoremap <buffer> <expr> <c-d> pumvisible() ? repeat("\<c-n>",g:TclComplete#popupscroll) : "\<c-d>"
inoremap <buffer> <expr> <c-u> pumvisible() ? repeat("\<c-p>",g:TclComplete#popupscroll) : "\<c-u>"



