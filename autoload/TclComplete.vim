"tclcomplete.vim - Omni Completion for Synopsys Tcl
" Creator: Chris Heithoff < christopher.b.heithoff@intel.com >
" Version: 0.5
" Last Updated: 06 November 2017
"
"
""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" TclComplete#GetData()
" - this is called when TclComplete is activated.
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! TclComplete#GetData()                                     
    let l:dir = g:TclComplete#dir

    "g:TclComplete#descriptions  
    "   dictionary: key = 'command', value = 'description of command'
    execute "source ".g:TclComplete#dir."/descriptions.vim"

    "  g:TclComplete#attributes 
    "   multi-level dictionary [object_class][attr_name] = choices
    execute "source ".g:TclComplete#dir."/attributes.vim"

    "  g:TclComplete#cmds  
    "     list:  builtins first, then commands, then procs inside child namespaces
    execute "source ".g:TclComplete#dir."/commands.vim"

    "  g:TclComplete#options
    "     dict: key = ['command']  value = alphabetical list of options
    execute "source ".g:TclComplete#dir."/options.vim"

    "  g:TclComplete#details 
    "     dict: key   = ['command']['option']
    "           value = description of option 
    execute "source ".g:TclComplete#dir."/details.vim"

    " This depends on the taglist containing G_variables.  rdt_tags does that.
    let g:TclComplete#g_vars = map(taglist('^G_'),"v:val['name']")
endfunction                                                            l

function! TclComplete#AttrChoices(A,L,P)
    return join(sort(keys(g:TclComplete#attributes)),"\n")
endfunction

function! TclComplete#AttributeComplete()
    call TclComplete#AskForAttribute()
    return "\<c-x>\<c-o>"
endfunction

function! TclComplete#AskForAttribute()
    " This function doesn't return anything, but instead sets a g: variables
    " behind the scenes
    let g:TclComplete#attr_flag = 'yes'
    let l:message = "Please enter an attribute class (tab for auto-complete, enter to use prev value): "
    let l:attr_class = input(l:message,'',"custom,TclComplete#AttrChoices")
    if l:attr_class != ''
        let g:TclComplete#attr_class = l:attr_class
    endif
endfunction


function! TclComplete#ScanBufferForVariableNames()
    " Assign the matches to dict keys for uniqueness instead of dealing with a non-unique list.
    let matches = {}
    let regex_str = '\v('
    let regex_str.= '\$'
    let regex_str.= '|set\s+'
    let regex_str.= '|foreach(_in_collection)?\s+'
    let regex_str.= ')\zs\h\w*'
    for linenum in range(1,line('$'))
        if linenum==line('.') 
            continue
        endif
        let line = getline(linenum)
        let match = matchstr(line,regex_str)
        let matches[match] = ''
        " TODO:  Add stuff for lassign, dict for {key value}, etc.
    endfor
    " TODO: Add stuff for procs aguments
    " TODO: Restrict foreach and proc args to within the block only.
    return sort(filter(keys(matches),"v:val!=''"),'i')
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" TclComplete#FindStart()
" - used by TclComplete#Complete() to look at the 
"   characters before the cursor to determined
"   the starting point of auto-completion.
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! TclComplete#FindStart()
    let l:line = getline('.')
    let l:index = col('.') - 1
    " Important:  We need to search for :: for namespaces, $ for var names
    "             and * for the wildcard mode, and -dashes for options
    let l:valid_chars = '[\-a-zA-Z0-9:_*$]'

    " Move backward as long as the previous character(index-1)  is part of valid_chars
    while  l:index>0 && l:line[l:index - 1]=~l:valid_chars
        let l:index -= 1
    endwhile

    " Save this index to indicate completion will begin there
    "   (do not include leading "::" )
    if l:line[l:index:l:index+1]=="::"
        let s:start_of_completion = l:index+2
    else
        let s:start_of_completion = l:index
    endif

    " Continue going backward to the start of line or first unmatched left bracket
    let l:right_bracket_count=0
    while l:index > 0
        let l:char_behind = l:line[l:index-1]
        " Keep a track of right/left brackets
        if l:char_behind == ']'
            let l:right_bracket_count+=1
        elseif l:char_behind == '['
            let l:right_bracket_count-=1
        endif
        " Break when we find an unmatched left bracket
        if l:right_bracket_count < 0
            break
        endif
        " If we made is this far, then decrement the index
        let l:index -= 1
    endwhile

    " Now move the index to the right again through white space until we hit a command.
    while l:index < len(line) && l:line[l:index]=~'\s'
        let l:index += 1
    endwhile
    
    " Just ahead of a possible :: global namespace
    if line[l:index:l:index+1]=="::"
        let l:index += 2
    endif

    " All done moving the index. Save s:active_cmd as a script variable
    if l:index==s:start_of_completion
        let s:active_cmd = ''
    else
        let s:active_cmd = matchstr(l:line, '[\-a-zA-Z0-9:_]\+',l:index)
    endif

    " Finally, return the start which is required for a completion function
    return s:start_of_completion
endfunction


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"" Main OmniCompletion function here!!! """""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! TclComplete#Complete(findstart, base)
    " First things first, source the completion scripts if necessary
    if !exists("g:TclComplete#cmds") 
        call TclComplete#GetData()
    endif

    "findstart = 1 to figure the start point of your current word
    if a:findstart 
        return TclComplete#FindStart()

    "findstart = 0 when we need to return the list of completions
    else
        " Adjust the base argument. 
        " 1)  Vim converts a dash in the base to a 0.  Why is that?
        let l:base = a:base=='0' ? '-' : a:base
        " 2) Allow a wildcard * to work as a regex .*
        let l:base = substitute(l:base,'*','.*','g')
        " 3) Allow a $ to be treated literally
        let l:base = substitute(l:base,'\$','\\$','g')

        " Save globally for debug purpose
        let g:base = l:base

        " Default the completion list and menu dict
        let l:complete_list = {}
        let l:menu_dict     = {}
    
        " Many types of completion.
        "  1) G_var style
        if l:base =~# '^G'
            let l:complete_list = g:TclComplete#g_vars

        "  2) $var style
        elseif l:base=~ '^\\\$'
            let l:complete_list = map(TclComplete#ScanBufferForVariableNames(),"'$'.v:val")

        "  3) Attribute style (dependent on attr_class)
        elseif g:TclComplete#attr_flag == 'yes'
            let l:complete_list = sort(keys(get(g:TclComplete#attributes,g:TclComplete#attr_class,{})))
            let l:menu_dict     = get(g:TclComplete#attributes,g:TclComplete#attr_class,{})
            let g:TclComplete#attr_flag  = 'no'

        "  4) Commands and descriptions
        elseif s:active_cmd == ''
            let l:complete_list = g:TclComplete#cmds
            let l:menu_dict     = g:TclComplete#descriptions

        "  5) Options of a previous command.
        else
            " Complete package require with packages
            if getline('.') =~# '^package require'
                let l:complete_list = g:TclComplete#options['package require']

            " Complete unset, lappend and dict set with variable names
            elseif s:active_cmd =~# '\v^(unset|lappend|dict set)$'
                let l:complete_list = TclComplete#ScanBufferForVariableNames()

            elseif s:active_cmd =~# '\v(set|get)_attribute'
                call TclComplete#AskForAttribute()
                let l:complete_list = sort(keys(get(g:TclComplete#attributes,g:TclComplete#attr_class,{})))
                let l:menu_dict     = get(g:TclComplete#attributes,g:TclComplete#attr_class,{})
                let g:TclComplete#attr_flag = 'no'
                
            " Complete everything else with just the command list
            else
                let l:complete_list = get(g:TclComplete#options,s:active_cmd,[])
                let l:menu_dict     = get(g:TclComplete#details,s:active_cmd,[])
            endif
        endif

        let g:b = l:complete_list

        " Finally, we filter the choices and add the description.
        let res = []
        for m in l:complete_list
            if m=~# '^'.l:base
                let menu = get(l:menu_dict,m,'')
                if menu =~ 'Synonym' 
                    continue
                else
                    call add(res, {'word':m, 'menu':menu})
                endif
            endif
        endfor
        return res
    endif
endfunction

