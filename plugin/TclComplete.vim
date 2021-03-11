" TclComplete.vim - Auto-complete cells, ports and nets of a design into InsertMode
" Maintainer:   Chris Heithoff ( christopher.b.heithoff@intel.com )
" Version:      2.0
" Latest Revision Date: 11-March-2021

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

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""  IVAR VISION 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Consider putting this into a separate plugin.
" Highlight ivar description on the bottom status line
" Adapted from Damian Conway's Vim plugins for Perl
"  https://github.com/thoughtstream/Damian-Conway-s-Vim-Setup/blob/master/plugin/trackperlvars.vim
"
" Include more keyword characters to identify the ivar array
"   with the cword() function
" TODO:  Is it possible that these keyword chars affect other plugins?
set iskeyword+=(
set iskeyword+=)
set iskeyword+=,

" Call IvarVision whenever the cursor is moved.
autocmd CursorMoved   * call IvarVision()
autocmd CursorMovedI  * call IvarVision()

" Turn it off when you leave to a new buffer.
autocmd BufLeave      * call IvarVisionToggleOff()

" Redo the g:ivar_dict when resizing because
" we need to re-limit the display strings by
" the number of window columns
autocmd VimResized * call IvarVisionCreateDict()


function! IvarVision()
    if !exists('g:ivar_dict')
        call IvarVisionCreateDict()
    endif

    " Identify the current word under the cursor
    let current_word = expand('<cword>')

    " Is the curent word an ivar()?  If so, pull out the ivar name
    let ivar_name = matchstr(current_word, 'ivar(\zs.*\ze)')

    " Get the display string from the ivar dict
    " Exit early if nothing to display
    let g:ivar_display = get(g:ivar_dict,ivar_name,"")
    if g:ivar_display == ""
        call IvarVisionToggleOff()
        return
    endif

    " Temporarily set highlighting for the echo status bar
    echohl Pmenu

    " Adjust the cmdline window height if the string is too long.
    " This will prevent having hit-enter prompts.
    " TODO:  Do the math properly on this 
    if len(g:ivar_display) > &columns-15
        let new_cmdheight = len(g:ivar_display)/(&columns-15) + 1
        exec "set cmdheight=".new_cmdheight
    else
        set cmdheight&
    endif

    " Finally!   Echo to the cmdline window!
    echo   g:ivar_display

    " Turn off the temporary highlighting because it shouldn't be persistent.
    echohl None

endfunction


function! IvarVisionCreateDict()
    " Load the arrays.json file
    if !exists('g:TclComplete#arrays')
        let g:TclComplete#arrays = TclComplete#ReadJsonFile('arrays.json','dict')
    endif

    " Exit early with an empty dict if required.
    if !has_key(g:TclComplete#arrays, 'ivar')
        let g:ivar_dict = {}
        return
    endif

    " These arrays were dumped into TclComplete/arrays.json
    let g:ivar_array = get(g:TclComplete#arrays, 'ivar')
    let g:ivar_desc  = get(g:TclComplete#arrays, 'ivar_desc')
    let g:ivar_type  = get(g:TclComplete#arrays, 'ivar_type')

    "Form the ivar dictionary with the name from the original 
    "ivar array and the value as a display string combined from
    "ivar name, ivar value and ivar_desc value
    let g:ivar_dict = {}
    for ivar_name in keys(g:ivar_array)
        let value = get(g:ivar_array, ivar_name, "")
        " Limit the value to a column width
        if len(value) > &columns - 30
            let value = value[0:&columns-30]." ..."
        endif
        
        let display_str = "ivar(".ivar_name.") = ".value

        " Add a description from ivar_desc array
        let desc  = get(g:ivar_desc, ivar_name, "")
        if len(desc)>0
            " Limit the description to approx one line of text
            let g:desc_len = len(desc)
            let display_str .= ", (".desc.")"
        endif

        
        let g:ivar_dict[ivar_name] = display_str
    endfor

    return

endfunction

function IvarVisionToggleOff()
    set cmdheight&
    echo ""
endfunction

