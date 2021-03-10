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


" Consider putting this into a separate plugin "ivar-vision"
" Highlight ivar description on the bottom status line
" Adapted from Damian Conway's Vim plugins for Perl
"  https://github.com/thoughtstream/Damian-Conway-s-Vim-Setup/blob/master/plugin/trackperlvars.vim
" arrays (names and values of every Tcl array variable)

function! DisplayIvar()
    let current_word = expand('<cword>')
    let ivar_name = matchstr(current_word, 'ivar(\zs.*\ze)')
    let g:ivar_display = get(g:ivar_dict,ivar_name,"")
    if len(g:ivar_display) > 0
        " Temporarily set highlighting for the echo status bar
        echohl Pmenu

        " Adjust the cmdline window height if the string is too long.
        " This will prevent having hit-enter prompts.
        if len(g:ivar_display) > &columns-15
            let new_cmdheight = len(g:ivar_display)/(&columns-15) + 1
            exec "set cmdheight=".new_cmdheight
        else
            set cmdheight&
        endif

        echo   g:ivar_display

        echohl None
        let g:displaying_message = 1


    elseif g:displaying_message==1
        " This turns it off
        set cmdheight&
        echo ""
        let g:displaying_message=0
    endif

endfunction

let g:TclComplete#arrays = TclComplete#ReadJsonFile('arrays.json','dict')
if has_key(g:TclComplete#arrays, 'ivar')
    " Include more keyword characters to identify the ivar array
    set iskeyword+=(
    set iskeyword+=)
    set iskeyword+=,

    " These arrays were dumped into TclComplete/arrays.json
    let g:ivar_array = get(g:TclComplete#arrays, 'ivar')
    let g:ivar_desc  = get(g:TclComplete#arrays, 'ivar_desc')
    let g:ivar_type  = get(g:TclComplete#arrays, 'ivar_type')

    "Form the ivar dictionary
    let g:ivar_dict = {}
    for ivar_name in keys(g:ivar_array)
        let value = get(g:ivar_array, ivar_name, "")
        let desc  = get(g:ivar_desc, ivar_name, "")
        let type  = get(g:ivar_type, ivar_name, "undefined")
        let display_str = "ivar(".ivar_name.") = ".value
        if len(desc)>0
            let display_str .= ", (".desc.")"
        endif
        let g:ivar_dict[ivar_name] = display_str
    endfor

    let g:displaying_message = 0
    " highlight Ivar ctermbg=blue ctermfg=yellow

    autocmd CursorMoved   * call DisplayIvar()
    autocmd CursorMovedI  * call DisplayIvar()
    autocmd BufLeave      * set cmdheight&|echo""

endif

