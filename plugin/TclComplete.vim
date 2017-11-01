" TclComplete.vim - Auto-complete cells, ports and nets of a design into InsertMode
" Maintainer:   Chris Heithoff ( christopher.b.heithoff@intel.com )
" Version:      1.0
" Latest Revision Date: 31-Oct-2017

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Set default values.  These could be overridden in your ~/.vimrc
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"  Possible locations of the TclComplete files (in order of priority)
"     1) g:TclComplete#dir defined in ~/.vimrc 
"     2) $WARD/TclComplete
"     3) $WARD/dp/inputs/TclComplete
"     4) The location of this plugin.
if !exists("g:TclComplete#dir")
    if isdirectory("$WARD/TclComplete")
        let g:TclComplete#dir = $WARD."/TclComplete"
    elseif isdirectory("$WARD/dp/inputs/TclComplete")
        let g:TclComplete#dir = $WARD."/dp/inputs/TclComplete"
    else
        let g:TclComplete#dir = expand("<sfile>:p:h:h")."/sample"
    endif
endif

" Default the completion mode to wildcard glob style, not regex
if !exists("g:TclComplete#popupscroll")
    let g:TclComplete#popupscroll = 10
endif


                                               
