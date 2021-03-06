" TclComplete.vim - Auto-complete cells, ports and nets of a design into InsertMode
" Maintainer:   Chris Heithoff ( christopher.b.heithoff@intel.com )
" Version:      2.1
" Latest Revision Date: 08-Apr-21

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Set default values.  These could be overridden in your ~/.vimrc
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"  Possible locations of the TclComplete files (in order of priority)
"     1) g:TclComplete#dir defined in ~/.vimrc 
"     2) ward or WARD work directory
"     3) sample/TclComplete in this plugin directory
if !exists("g:TclComplete#dir")
    if (exists('$WARD'))
        let g:TclComplete#ward = $WARD
    elseif (exists('$ward'))
        let g:TclComplete#ward = $ward
    endif

    if exists("g:TclComplete#ward")
        " Look for a TclComplete directory under the ward.
        "  - avoid globbing with ** because that would slow down Vim startup.
        "  - limit it to three directories down for now.
        let globs = ['/', '/dp/user_scripts/','/dp/scripts/','/*/']
        for glob in globs 
            " Call glob with third argument true to return a list.
            let __glob = glob(g:TclComplete#ward.glob.'TclComplete','',1)
            if len(__glob) > 0
                let g:TclComplete#dir = __glob[0]
                break
            endif
        endfor
    endif

    " Default
    if !exists("g:TclComplete#dir")
        let g:TclComplete#dir = expand("<sfile>:p:h:h")."/sample/TclComplete"
    endif
endif

" The TclComplete#ReadJsonFile() function adds key/values to this dict.
"   useful for debug
let g:TclComplete#json_status = {}

" All global vars derived from json files will go in this dict (see TclComplete/get.vim)
let g:TclComplete#json_vars = {}

" Remember a time when this plugin was loaded
let g:TclComplete#start_time = localtime()

" This activates the syntax/tcl.vim file 
execute "set runtimepath+=".g:TclComplete#dir

" How far does ctrl-d and ctrl-u move the popup menu?
if !exists("g:TclComplete#popupscroll")
    let g:TclComplete#popupscroll = 10
endif

