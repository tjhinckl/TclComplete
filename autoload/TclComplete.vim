"tclcomplete.vim - Omni Completion for Synopsys Tcl
" Creator: Chris Heithoff < christopher.b.heithoff@intel.com >
" Version: 0.5
" Last Updated: 06 November 2017
"

function! TclComplete#ReadJsonFile(json_file)
    let json_full_path = g:TclComplete#dir.'/'.a:json_file
    let file_lines = readfile(json_full_path)
    let file_as_one_string = join(file_lines)
    let object = json_decode(file_as_one_string)
    return object
endfunction
    
""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" TclComplete#GetContextList()
" - This finds the line of the previous unmatched curly
"   brace and return the command found.
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! TclComplete#GetContextList()
    " Save the location of the cursor as a mark
    normal ma
    " Jump back to previous open brace.  Do not add to jumplist
    keepjumps call searchpair('{','','}','bW')
    
    " Find the command before the open brace.
    let context_list = split(getline('.'))

    " Jump back to original position.
    normal g`a

    " Return what was found.
    return context_list
endfunction
""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" TclComplete#GetData()
" - this is called when TclComplete is activated.
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! TclComplete#GetData()                                     
    let l:dir = g:TclComplete#dir

    "   dictionary: key = 'command', value = 'description of command'
    let g:TclComplete#descriptions = TclComplete#ReadJsonFile('descriptions.json')

    "   multi-level dictionary [object_class][attr_name] = choices
    let g:TclComplete#attributes = TclComplete#ReadJsonFile('attributes.json')
    let g:TclComplete#object_classes = sort(keys(g:TclComplete#attributes))

    "     list:  builtins first, then commands, then procs inside child namespaces
    let g:TclComplete#cmds = TclComplete#ReadJsonFile('commands.json')

    "     dict: key = ['command']  value = alphabetical list of options
    let g:TclComplete#options = TclComplete#ReadJsonFile('options.json')

    "     dict: key   = ['command']['option']
    "           value = description of option 
    let g:TclComplete#details = TclComplete#ReadJsonFile('details.json')

    "  g:TclComplete#iccpp (list of iccpp parameters)
    let g:TclComplete#iccpp = TclComplete#ReadJsonFile('iccpp.json')

    " dict if iccpp parameters plus their default values
    let g:TclComplete#iccpp_dict = TclComplete#ReadJsonFile('iccpp_dict.json')

    " G variables that were loaded into your session.
    let g:TclComplete#g_vars = TclComplete#ReadJsonFile('g_vars.json')
    let g:TclComplete#g_var_arrays = TclComplete#ReadJsonFile('g_var_arrays.json')

    let g:TclComplete#app_options_dict  = TclComplete#ReadJsonFile('app_options.json')
    
    " Tech file information from the ::techfile_info array (rdt thing)
    let g:TclComplete#techfile_types      = TclComplete#ReadJsonFile('techfile_types.json')
    let g:TclComplete#techfile_layer_dict = TclComplete#ReadJsonFile('techfile_layer_dict.json')
    let g:TclComplete#techfile_attr_dict  = TclComplete#ReadJsonFile('techfile_attr_dict.json')

    " Tech file information from the ::techfile_info array (rdt thing)
    let g:TclComplete#environment  = TclComplete#ReadJsonFile('environment.json')

    " Design names in your session
    let g:TclComplete#designs = TclComplete#ReadJsonFile('designs.json')

    " App variables
    let g:TclComplete#app_var_list = TclComplete#ReadJsonFile('app_vars.json')
endfunction                                                            l

function! TclComplete#GetObjectClass(get_command)
    " Strip off 'get_'
    let object = a:get_command[4:]
    if index(g:TclComplete#object_classes, object) >= 0
        return object
    endif
    " Try without the 's'.  get_cells vs get_cell
    let object = object[0:-2]
    if index(g:TclComplete#object_classes, object) >= 0
        return object
    endif

    " Otherwise...nothing
    return ''
endfunction
    
function! TclComplete#AttrChoices(A,L,P)
    return join(sort(keys(g:TclComplete#attributes)),"\n")
endfunction

function! TclComplete#AttributeComplete()
    call TclComplete#AskForAttribute()
    return "\<c-x>\<c-o>"
endfunction

function! TclComplete#AskForAttribute()
    " his function doesn't return anything, but instead sets a g: variables
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
    " TODO: Add stuff for procs arguments
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
    "             and . for app_options.
    let l:valid_chars = '[\-a-zA-Z0-9:_*$(.]'

    " Move backward as long as the previous character(index-1)  is part of valid_chars
    while  l:index>0 && l:line[l:index - 1]=~l:valid_chars
        let l:index -= 1
    endwhile

    " Save this index to indicate completion will begin there
    "   (do not include leading "::" )
    if l:line[l:index:l:index+1]=="::"
        let s:start_of_completion = l:index+2
        let s:global = 1
    else
        let s:start_of_completion = l:index
        let s:global = 0
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
        let g:last_completed_word = ''
    else
        let s:active_cmd = matchstr(l:line, '[\-a-zA-Z0-9:_]\+',l:index)
        let g:last_completed_word = split(l:line[0:s:start_of_completion-1])[-1]
    endif

    " Let's also figure out the last completed word

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

        " Save the command before previous curly brace
        let l:context = g:TclComplete#GetContextList()
        let g:context = l:context

        " Default the completion list and menu dict
        let l:complete_list = {}
        let l:menu_dict     = {}
    
        " Many types of completion.
        " 1)  -options that start with a dash
        if l:base[0] == '-' 
            let g:ctype = 1
            let l:complete_list = get(g:TclComplete#options,s:active_cmd,[])
            let l:menu_dict     = get(g:TclComplete#details,s:active_cmd,[])

        " 2)  G_var completion (either array or non-array names)
        elseif l:base =~# '^G' 
            let g:ctype = 2
            if l:base =~# '('
                let l:complete_list = g:TclComplete#g_var_arrays
            else
                let l:complete_list = g:TclComplete#g_vars
            endif

        "  3) $variable completion (scan the current buffer for these!)
        elseif l:base=~ '^\\\$'
            let g:ctype = 3
            let l:complete_list = map(TclComplete#ScanBufferForVariableNames(),"'$'.v:val")
            
        "  3) namespace context
        elseif get(l:context,0,'')=='namespace' && get(l:context,1,'')=='eval' && len(l:context)>2
            let g:ctype = 31
            let namespace = l:context[2]

            if s:global
                " If you already typed a :: then use fully qualified paths
                let l:complete_list = g:TclComplete#cmds
                let l:menu_dict     = g:TclComplete#descriptions
            else
                " If you have not typed a ::, then limit the scope to namespace
                let l:complete_list = filter(copy(g:TclComplete#cmds),"v:val=~'^".namespace."'")
                call map(l:complete_list,"substitute(v:val,'^".namespace."::','','')")
            endif

            
        "  3) oo context
        elseif get(l:context,0)=~'^oo::'
            let g:ctype = 32
            let l:complete_list = get(g:TclComplete#options, l:context[0])

        "  4) Command completion if no command exists yet.
        elseif s:active_cmd == ''
            let g:ctype = 4
            let l:complete_list = g:TclComplete#cmds
            let l:menu_dict     = g:TclComplete#descriptions
        
        "  5) Attribute completion if the object class cannot easily be derived
        "        The attr_flag is 'yes' only when the object class is known.
        elseif g:TclComplete#attr_flag == 'yes'
            let g:ctype = 5
            let l:complete_list = sort(keys(get(g:TclComplete#attributes,g:TclComplete#attr_class,{})))
            let l:menu_dict     = get(g:TclComplete#attributes,g:TclComplete#attr_class,{})
            let g:TclComplete#attr_flag  = 'no'

        elseif s:active_cmd =~# '\v(set_attribute|get_attribute|filter_collection)'
            let g:ctype = 6
            call TclComplete#AskForAttribute()
            let l:complete_list = sort(keys(get(g:TclComplete#attributes,g:TclComplete#attr_class,{})))
            let l:menu_dict     = get(g:TclComplete#attributes,g:TclComplete#attr_class,{})
            let g:TclComplete#attr_flag = 'no'

        " 6) Attribute completion if the object class can be derived from the command name (I LOVE THIS ONE)
        elseif g:last_completed_word=="-filter" && s:active_cmd =~# '^get_'
            let g:ctype = 6
            let g:TclComplete#attr_class = TclComplete#GetObjectClass(s:active_cmd)
            let l:complete_list = sort(keys(get(g:TclComplete#attributes,g:TclComplete#attr_class,{})))
            let l:menu_dict     = get(g:TclComplete#attributes,g:TclComplete#attr_class,{})
            let g:TclComplete#attr_flag = 'no'

        " 7) G_var completion but for the getvar/setvar/etc commands
        elseif s:active_cmd =~# '\v^(setvar|getvar|lappend_var|info_var|append_var)$'
            let g:ctype = 7
            let l:complete_list = g:TclComplete#g_vars

        " 8) Complete unset, lappend and dict set with variable names
        elseif s:active_cmd =~# '\v^(unset|lappend|dict set)$'
            let g:ctype = 8
            let l:complete_list = TclComplete#ScanBufferForVariableNames()

        " 9) environment 
        elseif s:active_cmd=~# '\v(get|set)env'
            let g:ctype = 9
            let l:complete_list = sort(keys(g:TclComplete#environment))

        " 10)  Design names for the -design option or commands that use the design
        elseif g:last_completed_word == "-design" || s:active_cmd=~# '\v^(current_design|set_working_design)'
            let g:ctype = 10
            let l:complete_list = g:TclComplete#designs

        " 11) application options
        elseif s:active_cmd =~# '\v(get|set|report|reset)_app_options(_value)?'
            let g:ctype = 11
            let l:complete_list = sort(keys(g:TclComplete#app_options_dict))
            let l:menu_dict = g:TclComplete#app_options_dict


        " 12) application variables from your synopsys tool
        elseif s:active_cmd=~# 'app_var'
            let g:ctype = 12
            let l:complete_list = sort(g:TclComplete#app_var_list)

        " 13) iccpp parameters
        elseif s:active_cmd =~# '\viccpp_com::(set|get)_param'
            let g:ctype = 13
            let l:complete_list = sort(keys(g:TclComplete#iccpp_dict))
            let l:menu_dict = g:TclComplete#iccpp_dict

        " 14) Completions for two word combinations.
        elseif s:active_cmd=='package' && g:last_completed_word=='require'
            let g:ctype = 141
            let l:complete_list = g:TclComplete#options['package require']
        elseif s:active_cmd=='info' && g:last_completed_word=='class'
            let g:ctype = 142
            let l:complete_list = g:TclComplete#options['info class']
        elseif s:active_cmd=='info' && g:last_completed_word=='object'
            let g:ctype = 143
            let l:complete_list = g:TclComplete#options['info object']
        elseif s:active_cmd=='namespace' && g:last_completed_word=='ensemble'
            let g:ctype = 144
            let l:complete_list = g:TclComplete#options['namespace ensemble']
        elseif s:active_cmd=='string' && g:last_completed_word=='is'
            let g:ctype = 145
            let l:complete_list = g:TclComplete#options['string is']
            let l:menu_dict     = g:TclComplete#details['string is']


        " 15) App vars
        elseif s:active_cmd=~# 'app_var'
            let g:ctype = 15
            let l:complete_list = sort(g:TclComplete#app_var_list)


        " 16) Techfile stuff (relies on $SD_BUILD2/utils/shared/techfile.tcl)
        elseif s:active_cmd =~ 'tech::get_techfile_info'
            let g:ctype = 16
            if g:last_completed_word=='-type'
                let l:complete_list = g:TclComplete#techfile_types
            elseif g:last_completed_word=='-layer'
                let l:tech_file_type = matchstr(getline('.'), '-type\s\+\zs\w\+')
                let l:menu_dict = g:TclComplete#techfile_layer_dict
                let l:complete_list = sort(get(g:TclComplete#techfile_layer_dict,l:tech_file_type,[]))
            else
                let l:tech_file_type  = matchstr(getline('.'), '-type\s\+\zs\w\+')
                let l:tech_file_layer = matchstr(getline('.'), '-layer\s\+\zs\w\+')
                let l:tech_file_key = l:tech_file_type.":".l:tech_file_layer
                let l:tech_file_dict = g:TclComplete#techfile_attr_dict
                let l:complete_list =  sort(get(g:TclComplete#techfile_attr_dict,l:tech_file_key,['-type','-layer']))
            endif

        " Default) Options of the active command.
        else
            let g:ctype = 777
            let l:complete_list = get(g:TclComplete#options,s:active_cmd,[])
            let l:menu_dict     = get(g:TclComplete#details,s:active_cmd,[])
        endif

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

