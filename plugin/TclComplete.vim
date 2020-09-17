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
"     4) $ward/TclComplete
if !exists("g:TclComplete#dir")
    if isdirectory($WARD."/TclComplete")
        let g:TclComplete#dir = $WARD."/TclComplete"
    elseif isdirectory($WARD."/dp/user_scripts/TclComplete")
        let g:TclComplete#dir = $WARD."/dp/user_scripts/TclComplete"
    elseif isdirectory($ward."/TclComplete")
        let g:TclComplete#dir = $ward."/TclComplete"
    else
        let g:TclComplete#dir = expand("<sfile>:p:h:h")."/sample"
    endif
endif

" This activates the syntax/tcl.vim file 
execute "set runtimepath+=".g:TclComplete#dir

" How far does ctrl-d and ctrl-u move the popup menu?
if !exists("g:TclComplete#popupscroll")
    let g:TclComplete#popupscroll = 10
endif

                                               
