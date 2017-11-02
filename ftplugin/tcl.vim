""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Assign Tcl omni-completion, activated also by <tab> key
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
setlocal omnifunc=TclComplete#Complete

" Let <tab> activate and advance through the popup menu.  
"   I would Shift-Tab to go backwards, but that's a Konsole shortcut
if !exists('g:TclComplete#tab_opt_out')
    inoremap <buffer> <expr> <tab> pumvisible() ? "\<c-n>" : "\<c-x><c-o>"
endif

" ^D and ^U for faster scrolling through the popup menu.
inoremap <buffer> <expr> <c-d> pumvisible() ? repeat("\<c-n>",g:TclComplete#popupscroll) : "\<c-d>"
inoremap <buffer> <expr> <c-u> pumvisible() ? repeat("\<c-p>",g:TclComplete#popupscroll) : "\<c-u>"

" Pre-load the data into Vim (this takes too long!)
"  until I speed things up then don't do this.
"  Plan: Convert the TclComplete collateral input files into sourceable Vim
" call g:TclComplete#GetData() 

