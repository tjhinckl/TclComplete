""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Settings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
setlocal omnifunc=TclComplete#Complete

setlocal completeopt=menuone,longest

setlocal timeout
setlocal ttimeoutlen=100  "Wait time for triggering abbreviations (if ambiguity exists)


""""""""""""""""""""""""""""""""""""""""
" Initial conditions
""""""""""""""""""""""""""""""""""""""""
" This gets a non-empty value during TclComplete#AskForAttribute()
let g:TclComplete#attr_flag  = 'no'
let g:TclComplete#attr_class = ''

" This gets a yes value during TclComplete#CommandComplete()
let g:TclComplete#cmd_flag  = 'no'

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
    inoremap <buffer> <tab>k <c-r>=TclComplete#CommandComplete()<cr>
else
    " Reserve <tab> for TclComplete only.  Use <c-g> prefix so that
    " TclComplete <tab> doesn't need to wait for 'timeoutlen'
    inoremap <buffer> <c-g><c-a> <c-r>=TclComplete#AttributeComplete()<cr>
    inoremap <buffer> <c-g><c-k> <c-r>=TclComplete#CommandComplete()<cr>
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
""  TclComplete VISION 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Consider putting this into a separate plugin.
" Highlight ivar description on the bottom status line
" Adapted from Damian Conway's Vim plugins for Perl
"  https://github.com/thoughtstream/Damian-Conway-s-Vim-Setup/blob/master/plugin/trackperlvars.vim
"
" Include more keyword characters to identify the ivar array
"   with the cword() function
set iskeyword+=(
set iskeyword+=)
set iskeyword+=,

" Save the user's selection for 'showcmd' setting.
"   This affects the number of columns available in the status line
let g:TclComplete#showcmd = &showcmd
let g:TclComplete#vision_initialized = 0
let g:TclComplete#vision_disabled    = 0


 augroup TclCompleteVision
     " Clear the group if previously defined (because autocmds are appended to existing ones)
     autocmd!

     " Call TclCompleteVision whenever the cursor is moved.
     autocmd CursorMoved  *.tcl call TclCompleteVision()
     autocmd CursorMovedI *.tcl call TclCompleteVision()

     " Turn it off when you leave to a new buffer.
     autocmd BufLeave     *.tcl  call TclCompleteVisionToggleOff()
     autocmd WinLeave     *.tcl  call TclCompleteVisionToggleOff()

     " Redo the g:ivar_vision when resizing because
     " we need to re-limit the display strings by
     " the number of window columns
    autocmd VimResized *  call TclCompleteVisionInitialize()
 augroup END

function! TclCompleteVision()
    echo ""

    if g:TclComplete#vision_initialized == 0
        call TclCompleteVisionInitialize()
    endif

    " Get the current word under the cursor
    let current_word = expand('<cword>')

    let g:vision_current_word = current_word

    " Is it a proc?
    if has_key(TclComplete#get#Descriptions(), current_word)
        let g:TclComplete#display_str = get(TclComplete#get#Descriptions(), current_word,"")
        let g:vision_word = current_word
    elseif match(current_word, '\(::\)\?ivar(')>-1
        " Is it an ivar?  
        let ivar_name = get(split(current_word,'[()]'),1,"")
        let ivar_name = substitute(ivar_name,'^::','','')
        let g:vision_word = ivar_name
        let g:TclComplete#display_str = IvarVisionGetDisplayStr(ivar_name)
    elseif match(current_word, 'env(')>-1
        let env_name = get(split(current_word,'[()]'),1,"")
        let g:vision_word = env_name
        let env_array = get(TclComplete#get#Arrays(),'env', {})
        let g:TclComplete#display_str = '$'.env_name.' = '.get(env_array,env_name,"")
    else
        " Or something else?
        let g:vision_word = "none"
        let g:TclComplete#display_str = ""
    endif
    
    " Turn off and return if nothing to display
    if g:TclComplete#display_str == ""
        call TclCompleteVisionToggleOff()
        return
    endif

    " Temporarily set highlighting for the echo status bar
    echohl Pmenu

    " Adjust the cmdline window height if the string is too long.
    " This will prevent having hit-enter prompts.
    let g:TclComplete#display_str = g:TclComplete#display_str[0:&columns-2]

    " Turn off showcmd to give more space on the status line
    "   (don't worry, it will be restored in IvarVisionToggleOff)
    set noshowcmd

    " Finally!   Echo to the cmdline window!
    echo   g:TclComplete#display_str

    " Turn off the temporary highlighting because it shouldn't be persistent.
    echohl None

endfunction


function! TclCompleteVisionInitialize()

    " Initialize the array used for ivar_vision because it has formatting
    "  based on number of available columns
    let g:ivar_vision = {}

    " These arrays should be in TclComplete/arrays.json 
    let g:ivar_array = TclComplete#get#IvarDict()
    let g:ivar_desc  = get(TclComplete#get#Arrays(),'ivar', {})
    let g:ivar_type  = get(TclComplete#get#Arrays(),'ivar_type', {})

    let g:TclCompleteVisionInitialized = 1

    return
endfunction

" Call this function during events
function! TclCompleteVisionToggleOff()
    set cmdheight&
    let &showcmd = g:TclComplete#showcmd
    echo ""
endfunction

" Return the string used in ivar_vision 
function! IvarVisionGetDisplayStr(ivar_name)
    " Check cache first:
    if has_key(g:ivar_vision, a:ivar_name)
        return get(g:ivar_vision, a:ivar_name)
    endif

    " Get the ivar's value (substitute literal '$ward' if possible)
    let value = get(TclComplete#get#IvarDict(), a:ivar_name, "")
    let value = substitute(value,$ward,'$ward','g')
    
    " Make an empty string display literally as empty string
    if value == ""
        let value = "{}"
    endif

    " Add a description from ivar_desc array
    let desc  = get(g:ivar_desc, a:ivar_name, "")

    " Construct the string to display.  
    "   - start with the ivar name
    let display_name = "ivar(".a:ivar_name.") = "

    " Get the available space.  Reserve some space for fixed characters.
    let available_space = &columns - len(display_name) - 5

    if len(desc)==0
        " No description.  Just display the value within available space.
        if len(value) <= available_space
            let display_end = value
        else
            let display_end = value[0:available_space]."..."
        endif
    else
        " Add the description within available space.
        let available_space = available_space - 4
        let display_len = len(value) + len(desc)
        if display_len > available_space
            let chop_pct =  1.0 * available_space / display_len
            let value_allowed_len = float2nr(chop_pct * len(value))
            let desc_allowed_len  = float2nr(chop_pct * len(desc))
            if value_allowed_len < len(value)
                let value = value[0:value_allowed_len-3].".."
            endif
            if desc_allowed_len < len(desc)
                let desc = desc[0:desc_allowed_len-3].".."
            endif
        endif
        let display_end = value." (".desc.")"
    endif

    let display_string = display_name.display_end

    " Save to cache
    let g:ivar_vision[a:ivar_name] = display_string

    return display_string

endfunction

