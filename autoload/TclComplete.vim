"tclcomplete.vim - Omni Completion for Synopsys Tcl
" Creator: Chris Heithoff < christopher.b.heithoff@intel.com >
" Version: 0.1
" Last Updated: 27 Oct 2017
"
"
function! TclComplete#GetData()
    let l:dir = g:TclComplete#dir
    execute "source ".g:TclComplete#dir."/descriptions.vim"
    execute "source ".g:TclComplete#dir."/attributes.vim"
    execute "source ".g:TclComplete#dir."/commands.vim"
    execute "source ".g:TclComplete#dir."/options.vim"
    execute "source ".g:TclComplete#dir."/details.vim"
    execute "source ".g:TclComplete#dir."/aliases.vim"
    echo dir
endfunction


function! TclComplete#FindStart()
    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && line[start - 1] =~ '[\-a-zA-Z0-9:_*]'
        let start -= 1
    endwhile
    " Save s:start for use in the next pass through the function
    let s:start = start
    return start
endfunction

function! TclComplete#FindActiveCmd()
    " Go back to beginning of line or first open left bracket
    let l:right_bracket_count=0
    let line = getline('.')
    let start_cmd = col('.') - 1
    while start_cmd > 0 
        let char_behind = line[start_cmd-1]
        " Keep a track of right/left brackets
        if char_behind == ']'
            let l:right_bracket_count+=1
        elseif char_behind == '['
            let l:right_bracket_count-=1
        endif
        " Break when we find an unmatched left bracket
        if l:right_bracket_count < 0
            break
        endif

        " Move backwards for next iteration through loop
        let start_cmd -= 1
    endwhile

    " Now move the cursor to the right again through white space.
    while start_cmd < len(line)
        if line[start_cmd]=~ '\s'
            let start_cmd += 1
        else
            break
        endif
    endwhile

    let cmd_name = matchstr(line, '[\-a-zA-Z0-9:_]\+',start_cmd)

    " Special exception for "package require"
    if cmd_name == "package" && line =~ "require"
        let cmd_name = "package require"
    endif
    return [start_cmd, cmd_name]
endfunction


function! TclComplete#Complete(findstart, base)
    if !exists("g:TclComplete#cmds") 
        call TclComplete#GetData()
    endif

    "findstart = 1 to figure the start point of your current word
    if a:findstart 
        let s:start = TclComplete#FindStart()
        return s:start

    "findstart = 0 when we need to return the list of completions
    else
        let g:base = a:base
        let [l:active_cmd_start, l:active_cmd] = TclComplete#FindActiveCmd()

        " Complete either as a command or an option (or a package)
        if l:active_cmd_start==s:start
            let l:complete_list = g:TclComplete#cmds
            let l:menu_dict     = g:TclComplete#descriptions
        else
            let l:complete_list = get(g:TclComplete#options,l:active_cmd,[])
            let l:menu_dict     = get(g:TclComplete#details,l:active_cmd,[])
        endif

        " Weird Vim bug?  If you type a dash '-' and then trigger auto-complete,
        " then a:base is '0', not '-'.  
        if a:base == '0'
            let l:base = '-'
        else
            let l:base = a:base
        endif

        " Allow a wildcard to work
        let l:base = substitute(l:base,'*','.*','g')
        let g:base = l:base

        " Finally, we filter the choices and add the description.
        let res = []
        for m in l:complete_list
            " if m=~ '^' . escape(l:base,'-')
            if m=~ '^' .l:base
                let menu = get(l:menu_dict,m,'')
                if menu =~ 'Synonym' 
                    continue
                else
                    " Option1: Use this function.
                    " call complete_add({'word':m, 'menu':menu})
                    " Option2: Add to the res list (this is faster)
                    call add(res, {'word':m, 'menu':menu})
                endif
            endif
        endfor
        return res
    endif
endfunction

