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
if !exists("g:OneTabImap") || g:OneTabImap!=1
    " Default.  Use <tab> prefix in the maps.   The existence of two character
    " maps beginning with <tab> mean that <tab> itself must wait for 'timeoutlen'.
    inoremap <buffer> <tab><space>  <c-x><c-o>
    inoremap <buffer> <tab>a <c-r>=TclComplete#AttributeComplete()<cr>
else
    " Reserve <tab> for TclComplete only.  Use <c-g> prefix so that
    " TclComplete <tab> doesn't need to wait for 'timeoutlen'
    inoremap <buffer> <c-g><c-a> <c-r>=TclComplete#AttributeComplete()<cr>
endif

" Let <tab> activate and advance through the popup menu.  
"   I would Shift-Tab to go backwards, but that's a Konsole shortcut
if !exists('g:TclComplete#tab_opt_out')
    inoremap <buffer> <expr> <tab> pumvisible() ? "\<c-n>" : "\<c-x>\<c-o>"
endif

" ^D and ^U for faster scrolling through the popup menu.
inoremap <buffer> <expr> <c-d> pumvisible() ? repeat("\<c-n>",g:TclComplete#popupscroll) : "\<c-d>"
inoremap <buffer> <expr> <c-u> pumvisible() ? repeat("\<c-p>",g:TclComplete#popupscroll) : "\<c-u>"

"""""""""""""""""""""""""""""""""""""""""""
" Source iabbrev commands
"""""""""""""""""""""""""""""""""""""""""""
if exists("g:TclComplete#dir")
    let s:aliases_file = g:TclComplete#dir."/aliases.vim"
    if file_readable(s:aliases_file)
        execute "source ".s:aliases_file
    endif
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

    " Identify the current word under the cursor
    let current_word = expand('<cword>')

    " Is the curent word an ivar()?  If so, pull out the ivar name
    let ivar_name = matchstr(current_word, 'ivar(\zs.*\ze)')

    if ivar_name==''
        call IvarVisionToggleOff()
        return
    endif
        
    " Now's the time to load the ivar_dict if not already done
    if !exists('g:ivar_dict')
        call IvarVisionCreateDict()
    endif

    " Get the display string from the ivar dict
    " Exit early if nothing to display
    let g:ivar_display = get(g:ivar_dict,ivar_name,"")
    if g:ivar_display == ''
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

        " If possible, substitute the ward full path with '$ward' for brevity.
        let value = substitute(value,$ward,'$ward','g')

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

