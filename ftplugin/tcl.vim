""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Settings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
setlocal omnifunc=TclComplete#Complete

setlocal completeopt=menuone,longest

setlocal timeout
setlocal timeoutlen=200   "Wait time for triggering mappings (if ambiguity exists)
setlocal ttimeoutlen=100  "Wait time for triggering abbreviations (if ambiguity exists)


""""""""""""""""""""""""""""""""""""""""
" Initial conditions
""""""""""""""""""""""""""""""""""""""""
" This gets a non-empty value during TclComplete#AskForAttribute()
let g:TclComplete#attr_flag  = 'no'
let g:TclComplete#attr_class = ''

"""""""""""""""""""""""""""""""""""""""""""
" Simple key maps to trigger the completion
"""""""""""""""""""""""""""""""""""""""""""
" For fastest completion, use an unambiguous map.  When using 
"  only <tab>, then Vim may wait for other keys before timing
"  out.  There are <tab>c, <tab>n, <tab>p maps in the NetlistComplete
"  plugin, so a lonely <tab> requires a wait period to wait for
"  'n', 'c', or 'p'.  
" <c-x><c-o> is the native omni-completion map.
" <tab><space> might be quicker to type.
inoremap <buffer> <tab><space>  <c-x><c-o>

" Let <tab> activate and advance through the popup menu.  
"   I would Shift-Tab to go backwards, but that's a Konsole shortcut
if !exists('g:TclComplete#tab_opt_out')
    inoremap <buffer> <expr> <tab> pumvisible() ? "\<c-n>" : "\<c-x>\<c-o>"
endif

" ^D and ^U for faster scrolling through the popup menu.
inoremap <buffer> <expr> <c-d> pumvisible() ? repeat("\<c-n>",g:TclComplete#popupscroll) : "\<c-d>"
inoremap <buffer> <expr> <c-u> pumvisible() ? repeat("\<c-p>",g:TclComplete#popupscroll) : "\<c-u>"


"""""""""""""""""""""""""""""""""""""""""""
" Trigger attribute style completion
"""""""""""""""""""""""""""""""""""""""""""
inoremap <buffer> <tab>a <c-r>=TclComplete#AttributeComplete()<cr>


"""""""""""""""""""""""""""""""""""""""""""
" Source iabbrev commands
"""""""""""""""""""""""""""""""""""""""""""
let s:aliases_file = g:TclComplete#dir."/aliases.vim"
if file_readable(s:aliases_file)
    execute "source ".s:aliases_file
endif


"""""""""""""""""""""""""""""""""""""""""""
" G_variable imap
"""""""""""""""""""""""""""""""""""""""""""
inoremap <buffer> <expr> G_ MapGVar()

function! MapGVar() 
   let line = getline('.')
   let cursor = col('.')-1

   " Default value
   let result = "G_"

   " Replace "$G_" with "[getvar G_"
   if cursor>=1
       if line[cursor-1]=="$"
           let result =  "\<BS>[getvar G_"
       endif
   endif

   " Replace "set G_" with "setvar G_"
   if cursor>=4
       if line[cursor-4:cursor-2]=="set"
           let result = "\<BS>\<BS>\<BS>\<BS>setvar G_"
       endif
   endif

   return result
endfunction


