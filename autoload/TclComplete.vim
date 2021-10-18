"tclcomplete.vim - Omni Completion for Synopsys Tcl
" Creator: Chris Heithoff < christopher.b.heithoff@intel.com >
" Version: 3.0
" Last Updated: 13-Sep-21
"

function! TclComplete#ReadJsonFile(json_file, json_type)
    let json_full_path = g:TclComplete#dir.'/'.a:json_file

    " Initialize the object
    if a:json_type=='list'
        let object = []
    elseif a:json_type=='dict'
        let object = {}
    endif
    
    " If no file exists, then return an empty list or empty dict
    if !filereadable(json_full_path)
        return object
    endif

    let file_lines = readfile(json_full_path)
    let file_as_one_string = join(file_lines)

    " Some json files might throw out some warnings.
    " ..suppress the warning with a try/endtry.
    try
        let object = json_decode(file_as_one_string)
    catch
        echomsg "Something funny happened with ".a:json_file
        if a:json_type=='list'
            let object = ['Bad json file '.a:json_file]
        elseif a:json_type=='dict'
            let object = {a:json_file : 'Bad json file'}
        endif
    endtry

    return object
endfunction
    
""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" TclComplete#GetContextList()
" - This finds the line of the previous UNMATCHED curly
"   brace and returns the command found.
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
"   TODO: Maybe make this lazy...only take the time to read a json file 
"           if the completion context was triggered.
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! TclComplete#GetData()                                     
    let l:dir = g:TclComplete#dir

    "   list of commands.  Namespaced commands at end.
    let g:TclComplete#cmds = TclComplete#ReadJsonFile('commands.json','list')

    "   dictionary: key = 'command', value = 'description of command'
    let g:TclComplete#descriptions = TclComplete#ReadJsonFile('descriptions.json','dict')

    "   dictionary: key = object_class, value = attribute for the class
    let g:TclComplete#attributes = TclComplete#ReadJsonFile('attributes.json','dict')
    let g:TclComplete#object_classes = sort(keys(g:TclComplete#attributes))

    "  define here the commands that will use attribute mode completion
    let g:TclComplete#attribute_funcs = {}
    for f in ['get_attribute', 'filter_collection', 'set_attribute', 'get_defined_attributes', 'sort_collection']
        let g:TclComplete#attribute_funcs[f]=''
    endfor

    "     list:  packages
    let g:TclComplete#packages = TclComplete#ReadJsonFile('packages.json','list')

    "     list: Use the TclComplete#cmds list to derive namespaces 
    let g:TclComplete#namespaces = copy(g:TclComplete#cmds)
    call filter(g:TclComplete#namespaces,"v:val=~'::'")
    let map_cmd = "substitute(v:val,'::[^:]*$','','')"
    call map(g:TclComplete#namespaces,map_cmd)
    call uniq(sort(g:TclComplete#namespaces,'i'))

    "     dict: key = ['command']  value = alphabetical list of options
    let g:TclComplete#options = TclComplete#ReadJsonFile('options.json','dict')

    "     dict: key   = ['command']['option']
    "           value = description of option 
    let g:TclComplete#details = TclComplete#ReadJsonFile('details.json','dict')

    "  g:TclComplete#iccpp (list of iccpp parameters)
    let g:TclComplete#iccpp = TclComplete#ReadJsonFile('iccpp.json','list')

    " dict if iccpp parameters plus their default values
    let g:TclComplete#iccpp_dict = TclComplete#ReadJsonFile('iccpp_dict.json','dict')

    " G variables that were loaded into your session.
    let g:TclComplete#g_vars = TclComplete#ReadJsonFile('g_vars.json','list')
    let g:TclComplete#g_var_arrays = TclComplete#ReadJsonFile('g_var_arrays.json','list')

    " arrays (names and values of every Tcl array variable)
    let g:TclComplete#arrays = TclComplete#ReadJsonFile('arrays.json','dict')

    " Prepare for faster ivar access later.
    let g:TclComplete#ivar_lib_names = {}
    let g:TclComplete#ivar_completion = {}
    call TclComplete#ivar_prep()


    " Get the track patterns from the G_ROUTE_TRACK_PATTERNS array
    let g:TclComplete#track_patterns = filter(copy(g:TclComplete#g_var_arrays),"v:val=~'G_ROUTE_TRACK_PATTERNS'")
    call map(g:TclComplete#track_patterns,"split(v:val,'[()]')[1]")

    " Synopsys app option dict
    let g:TclComplete#app_options_dict  = TclComplete#ReadJsonFile('app_options.json','dict')
    
    " Tech file information from the ::techfile_info array (rdt thing)
    let g:TclComplete#techfile_types      = TclComplete#ReadJsonFile('techfile_types.json','list')
    let g:TclComplete#techfile_layer_dict = TclComplete#ReadJsonFile('techfile_layer_dict.json','dict')
    let g:TclComplete#techfile_attr_dict  = TclComplete#ReadJsonFile('techfile_attr_dict.json','dict')

    " " Environment variables (this was made obsolete by g:TclComplete#arrays)
    " let g:TclComplete#environment  = sort(keys(TclComplete#ReadJsonFile('environment.json','dict')))

    " Design names in your session
    let g:TclComplete#designs = TclComplete#ReadJsonFile('designs.json','list')

    " App variables dict (key=app var name, value=app var value when JSON file was create)
    let g:TclComplete#app_var_list = TclComplete#ReadJsonFile('app_vars.json','dict')

    " RDT steps dict (key=stage name, value = list of steps for the stage)
    let g:TclComplete#rdt_step_dict  = TclComplete#ReadJsonFile('rdt_steps.json','dict')
    let g:TclComplete#rdt_stage_list = sort(keys(g:TclComplete#rdt_step_dict))
    let g:TclComplete#rdt_commands={}
    for cmd in ['runRDT','rdt_add_pre_step','rdt_add_post_step','rdt_add_pre_stage','rdt_add_post_stage','rdt_remove_stage','rdt_get_global_voltages','rdt_get_rail_voltage','rdt_get_scenario_data']
        let g:TclComplete#rdt_commands[cmd]=''
    endfor

    " GUI settings
    let g:TclComplete#gui_layout_window_list = TclComplete#ReadJsonFile('gui_settings_layout.json','list')

    " Regexp char classes
    let g:TclComplete#regexp_char_class_list = TclComplete#ReadJsonFile('regexp_char_classes.json','list')

    " Synopsys error message ids
    let g:TclComplete#msg_ids = TclComplete#ReadJsonFile('msg_ids.json', 'dict')
    let g:TclComplete#msg_id_funcs = {}
    for f in ['suppress_message', 'unsuppress_message'] 
        let g:TclComplete#msg_id_funcs[f]=''
    endfor
    

    "  Functions that use g_var completion
    let g:TclComplete#gvar_funcs = {}
    for f in ['setvar', 'getvar', 'lappend_var', 'info_var', 'append_var']
        let g:TclComplete#gvar_funcs[f]=''
    endfor

    "  Functions that use variable name completion
    let g:TclComplete#varname_funcs = {}
    for f in ['set', 'unset', 'append', 'lappend', 'lset', 'incr', 'info exists', 'dict set', 'dict unset', 'dict append', 'dict lappend', 'dict incr', 'dict with', 'dict update']
        let g:TclComplete#varname_funcs[f]=''
    endfor

    "  Functions that use environment completion
    let g:TclComplete#env_funcs = {}
    for f in ['getenv', 'setenv']
        let g:TclComplete#env_funcs[f]=''
    endfor

    "  Functions that use design completion
    let g:TclComplete#design_funcs = {}
    for f in ['current_design', 'set_working_design', 'set_working_design_stack']
        let g:TclComplete#design_funcs[f]=''
    endfor

    "  Functions that use track pattern completion
    let g:TclComplete#trackpattern_funcs = {}
    for f in ['sd_create_tracks','cr_create_track_region', 'cr_create_tracks_region']
        let g:TclComplete#trackpattern_funcs[f]=''
    endfor

    "  Functions that use application options
    let g:TclComplete#app_option_funcs = {}
    for f in ['get_app_options', 'set_app_options', 'report_app_options', 'reset_app_options', 'get_app_option_value']
        let g:TclComplete#app_option_funcs[f]=''
    endfor

endfunction

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

    " Try taking off one more letter (port_buses --> port_buse --> port_bus)
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
    let g:TclComplete#attr_flag = 'yes'
    call TclComplete#AskForAttribute()
    return "\<c-x>\<c-o>"
endfunction

function! TclComplete#AskForAttribute()
    " This does no return a value,  It launches an input prompt, and sets global variables.
    let l:message = "Please enter an object class (tab for auto-complete, enter to use prev value): "
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
        " Skip the line you're on.
        if linenum==line('.') 
            continue
        endif

        let line = getline(linenum)

        " Check for matches to the regex_str (set, foreach, foreach_in_collection)
        let match = matchstr(line,regex_str)
        if match!=''
            let matches[match] = ''
        endif

        " Check for proc arguments
        let match=matchstr(line,'\vproc .*\{\zs.*\ze}')
        if match!=''
            for var in split(match)
                let matches[var] = ''
            endfor
            continue
        endif

        " Check for final args of lassign or scan (go backwards from end. look for valid var names)
        if line=~'\v(lassign|^ *scan )'
            for var in reverse(split(line))
                if var=~'[$}"\]%]'
                    break
                endif
                let matches[var] = ''
            endfor
            continue
        endif
        " TODO:  Add stuff for 'dict for {key value}', etc.
    endfor
    " TODO: Restrict foreach and proc args to within the block only.
    return sort(filter(keys(matches),"v:val!=''"),'i')
endfunction

function! TclComplete#ScanBufferForArrayNames()
    " Assign the matches to dict keys for uniqueness instead of dealing with a non-unique list.
    let matches = {}
    let regex_str = '\varray\s+set\s+\zs\h\w*'
    for linenum in range(1,line('$'))
        " Skip the line you're on.
        if linenum==line('.') 
            continue
        endif

        let line = getline(linenum)

        " Check for matches to the regex_str (set, foreach, foreach_in_collection)
        let match = matchstr(line,regex_str)
        if match!=''
            let matches[match] = ''
        endif
    endfor
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

    " Adjust the cursor column by one to be used as index for looking 
    " up characters in the line string.
    let l:index = col('.') - 1

    " If the current line is the continuation of a previous line, then
    " include the characters of those lines too.
    let l:num_prev_chars = 0
    if line('.')==1
        let l:line = getline('.')
    else
        let l:line = getline('.')
        let i = 1
        while 1 
            " Include the previous line if it has a line continouation character
            let l:prev_line = getline(line('.') - i)
            if prev_line[len(prev_line)-1] == '\'
                " Trim off the line continuation slash
                let prev_line = prev_line[0:len(prev_line)-2]
                let l:len_prev_line = len(l:prev_line)

                " Insert prev_line to beginning of line and adjust index
                let l:line = prev_line.l:line
                let l:index += l:len_prev_line
                let l:num_prev_chars += l:len_prev_line
                
                " Increment counter to keep looking backwards
                let i+=1
            else
                " No more line continuation characters. Stop
                break
            endif
        endwhile
    endif
        
    " Important:  We need to search for these valid characters:
    "    : for namespaces
    "    $ for var names
    "    * for the wildcard mode
    "    - for dash options
    "    . for app_options and collection attributes
    let l:valid_chars = '[\-a-zA-Z0-9:_*$(.,]'

    " Look backwards at each character in the line string to first invalid char or start of string
    while  l:index>0 && l:line[l:index - 1]=~l:valid_chars
        let l:index -= 1
    endwhile

    " For start of completion, ignore any leading :: for namespaces.
    "    s:global is used later in TclComplete#Complete() function 
    "      to filter the completion list based on available namespaces.
    if l:line[l:index:l:index+1]=="::"
        let s:start_of_completion = l:index+2
        let s:global = 1
    else
        let s:start_of_completion = l:index
        let s:global = 0
    endif

    " Continue going backward to the start of line or first unmatched left square bracket
    "   This is how the active cmd is discovered.   That defines the context for completion.
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
    
    " Move index again ahead of a possible leading "::" at the beginning of a command.
    if line[l:index:l:index+1]=="::"
        let l:index += 2
    endif

    " The index has now been moved to the start of the active command.
    "   1)  Save active_cmd as a global variable
    "   2)  Save the last completed word too.  This gives more context.
    "           For example, "get_cells -filter " has "get_cells" as the 
    "           active command and -filter as the last completed word.
    " If there is no pre-typed active command, then we must be in command 
    "  completion mode.
    if l:index==s:start_of_completion
        let g:active_cmd = ''
        let g:last_completed_word = ''
    else
        let g:active_cmd = matchstr(l:line, '[\-a-zA-Z0-9:_]\+',l:index)
        let g:last_completed_word = split(l:line[0:s:start_of_completion-1])[-1]
    endif

    " Finally, return the start which is required for a completion function
    "   but now unadjust for the characters on previous lines due to line continuation
    return s:start_of_completion - l:num_prev_chars
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
        let l:base = a:base

        " Vim8.0 has a buggy thing where a '-' character found by TclComplete#FindStart()
        "  gets converted to a '0' (number type).
        if type(l:base) == type(0)
            let l:base = "-"
        endif

        " 1) Allow a wildcard * to work as a regex .*
        let l:base = substitute(l:base,'*','.*','g')
        " 2) Force a $ character in l:base to be a literal $ so regex matches with =~ operator still work.
        let l:base = substitute(l:base,'\$','\\$','g')

        " Save globally for debug purpose
        let g:base = l:base

        " Find the previous line (as a list) that contains the outer-most left curly brace.
        "   Let's call this the context.
        let l:context = g:TclComplete#GetContextList()
        let g:context = l:context

        " Default the completion list and menu dict
        let l:complete_list = {}
        let l:menu_dict     = {}
    
        """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
        " Many types of completion. Here goes a big if/elseif/else block
        """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
        " 1a)  If you've typed a dash, then get the -options of the active cmd.
        if l:base[0] == '-' 
            let g:ctype = 'dash'
            let l:complete_list = get(g:TclComplete#options,g:active_cmd,[])
            let l:menu_dict     = get(g:TclComplete#details,g:active_cmd,[])

        " 1b)  If you've typed "G_", then use list of g vars.
        elseif l:base[0:1] == 'G_' 
            let g:ctype = 'G_var'
            let l:complete_list = g:TclComplete#g_vars

        " 1c)  If you've typed an array that in the g:TclComplete#arrays dict, then 
        "      complete the names
        elseif l:base=~'('
            let g:ctype= 'array'
            " Find the base text before the left parenthesis
            let g:array_base = split(l:base,'(')[0]
            " The base might begin with slash-dollar \$, but the slash shouldn't be part of the complete list.
            if g:array_base[0] == '\'
                let g:array_base = g:array_base[1:]
            endif
            " The base might include $ or ::.  We don't want those for dictionary lookup
            let g:array_varname = substitute(g:array_base, '^[$:]*', '', 'g')

            " Get the array variable's name/value dict (default to empty dict)
            if has_key(g:TclComplete#arrays, g:array_varname)
                let g:array_dict  = get(g:TclComplete#arrays, g:array_varname)
                let g:array_names = keys(g:array_dict)

                " Make a list and dict with the full base name as keys 
                "   - ($ and ::) restored if needed. 
                "    - and a ( before the name.
                let l:menu_dict = {}

                " Special case for ivars.  
                if g:array_varname=='ivar'
                    let g:base = l:base
                    if l:base=~'^ivar(lib,[^,]*,'
                        " Insane ivar completion to manage thousands of ivar(lib,*) values
                        let g:ctype = 'ivar_lib'
                        let g:ivar_lib_name = split(l:base,'(')[1]
                        let g:ivar_lib_key = join(split(g:ivar_lib_name,',')[0:1],',')
                        let l:menu_dict = get(g:TclComplete#ivar_lib_names,g:ivar_lib_key)
                    elseif l:base=~'\$'
                        " ivar completion starting with dollar sign (with or without colons)
                        let g:ctype = 'dollar_ivar'
                        let l:menu_dict = g:TclComplete#dollar_ivar_completion
                        if l:base=~'::'
                            let g:ctype = 'dollar_colon_ivar'
                            let l:menu_dict = {}
                            for ivar_name in keys(g:TclComplete#ivar_completion) 
                                let val = get(g:TclComplete#ivar_completion, ivar_name)
                                let l:menu_dict['$::'.ivar_name] = val
                            endfor
                        endif
                    else
                        " Normal ivar completion (with or without colon)
                        let g:ctype = 'ivar'
                        let l:menu_dict = g:TclComplete#ivar_completion
                    endif
                else
                    for l:array_name in g:array_names
                        let l:array_full_name = g:array_base . "(" . l:array_name
                        let l:menu_dict[l:array_full_name] = g:array_dict[l:array_name]
                    endfor
                endif
                    
                let g:menu_dict = l:menu_dict
                let l:complete_list = sort(keys(l:menu_dict))
            elseif g:array_varname=='defined' || g:array_varname=='undefined'
                call TclComplete#AskForAttribute()
                let g:ctype= 'attributes (defined)'
                let l:complete_list = sort(keys(get(g:TclComplete#attributes,g:TclComplete#attr_class,{})))
                call map(l:complete_list,"g:array_varname.'('.v:val")
            else 
                let l:complete_list = []
            endif


        " 1d) If you've typed a "$", then use a list of variables in the buffer.
        "      (NOTE, I change $ to \$ in l:base earlier to avoid regex problems in =~ operations.
        elseif l:base[0:1] == '\$'
            let g:ctype = '$var'
            let l:complete_list = map(TclComplete#ScanBufferForVariableNames(),"'$'.v:val")
            " Always included ivar and env!
            call extend(l:complete_list,['$ivar', '$env', '$::ivar', '$::env'])
            

        " 1e) regexp character classes start with a single colon.  ([:alnum:], [:upper:], etc)
        elseif l:base[0] == ':' && l:base[1] != ':'
            let g:ctype = 'regexp char class' 
            let l:complete_list = g:TclComplete#regexp_char_class_list


        " 2) Command completion if no command exists yet.
        elseif g:active_cmd == ''
            " 2a) If you're inside a namespace eval block, then use cmds as scoped to the namespace
            if get(l:context,0,'')=='namespace' && get(l:context,1,'')=='eval' && len(l:context)>2
                let namespace = l:context[2]

                if s:global
                    let g:ctype = 'namespace context global'
                    " If you already typed a leading :: then use fully qualified paths
                    let l:complete_list = g:TclComplete#cmds
                    let l:menu_dict     = g:TclComplete#descriptions
                else
                    " If you have not typed a ::, then limit the scope to namespace or non-namespaced commands
                    let g:ctype = 'namespace context scoped'
                    let l:complete_list = copy(g:TclComplete#cmds)
                    let filter_cmd = "v:val=~'^".namespace."' || v:val!~'::'"
                    let map_cmd    = "substitute(v:val,'^".namespace."::','','')"
                    call filter(l:complete_list,filter_cmd)
                    call map(l:complete_list,map_cmd)
                    " call sort(l:complete_list,'i')
                endif
            " 2b) If you're in a oo::define (or similar) block, then only allow stuff like method, constructor, etc...
            elseif get(l:context,0)=~'^oo::'
                let g:ctype = 'oo context'
                let l:complete_list = get(g:TclComplete#options, l:context[0])

            " 2c) Regular old command completion.  
            else
                let g:ctype = 'command'
                let l:complete_list = g:TclComplete#cmds
                let l:menu_dict     = g:TclComplete#descriptions
            endif
        
        " 3) Complete object classes after '-class', typically during a get_attribute type command
        elseif g:last_completed_word=='-class'
            let g:ctype = 'object classes'
            let l:complete_list = g:TclComplete#object_classes

        " 4a) Attribute completion if triggered by the TclComplete#AttributeComplete() function
        "      (Rare.  this is triggered by the <tab>-a shortcut.)
        elseif g:TclComplete#attr_flag == 'yes'
            let g:ctype = 'attributes (attr_function)'
            let l:complete_list = sort(keys(get(g:TclComplete#attributes,g:TclComplete#attr_class,{})))
            let l:menu_dict     = get(g:TclComplete#attributes,g:TclComplete#attr_class,{})
            let g:TclComplete#attr_flag  = 'no'

        " 4b) Attribute completion following attribute commands (like get_attribute)
        elseif has_key(g:TclComplete#attribute_funcs,g:active_cmd)
            " Check for dotted attribute format.  (like cell.full_name, pin.cell.origin)
            if l:base =~ '\.'
                let g:ctype = 'attributes (dotted)'
                " Split by dots.
                let l:split_base = split(l:base,'\.')

                " Because splitting "cell." and "cell.n" by the "." will
                " either create one or two element lists...
                if l:base =~ '\.$'
                    let g:TclComplete#attr_class = get(l:split_base,-1)
                    let l:prefix = l:base 
                else
                    let g:TclComplete#attr_class = get(l:split_base,-2)
                    let l:prefix= join(l:split_base[0:-2],'.')."."
                endif
                
                " Change parent_block and parent_class to block and class.
                let g:TclComplete#attr_class = substitute(g:TclComplete#attr_class,'parent_','','')

                " Construct the complete_list so that the dotted prefixes are in front.
                let l:complete_list = sort(keys(get(g:TclComplete#attributes,g:TclComplete#attr_class,{})))
                call map(l:complete_list, "l:prefix.v:val")

            " Try to derive the object class based on a -class argument
            elseif getline('.')=~'-class'
                let g:ctype = 'attributes (derived from -class)'
                let l:split_line = split(getline('.'))
                let l:class_index = index(l:split_line,'-class')+1
                let g:TclComplete#attr_class=get(l:split_line,l:class_index,'')
                let l:complete_list = sort(keys(get(g:TclComplete#attributes,g:TclComplete#attr_class,{})))
                call extend(l:complete_list,["defined","undefined"])
                let l:menu_dict     = get(g:TclComplete#attributes,g:TclComplete#attr_class,{})

            " ...otherwise, ask the user for the object class.
            else
                call TclComplete#AskForAttribute()
                let g:ctype = 'attributes (AskForAttribute)'
                let l:complete_list = sort(keys(get(g:TclComplete#attributes,g:TclComplete#attr_class,{})))
                call extend(l:complete_list,["defined","undefined"])
                let l:menu_dict     = get(g:TclComplete#attributes,g:TclComplete#attr_class,{})
            endif

        " 4c) Attribute completion after the -filter option of get_cells, get_nets, etc.
        elseif g:last_completed_word=="-filter" && g:active_cmd =~# '^get_'
            " Check for dotted attribute format.  (like cell.full_name, pin.cell.origin)
            "  (THIS CODE IS REPEATED FROM 4b. CAN THIS BE RE-FACTORED BETTER?)
            if l:base =~ '\.'
                let g:ctype = 'attributes (dotted -filter)'
                " Split by dots.
                let l:split_base = split(l:base,'\.')

                if l:base =~ '\.$'
                    let g:TclComplete#attr_class = get(l:split_base,-1)
                    let l:prefix = l:base 
                else
                    let g:TclComplete#attr_class = get(l:split_base,-2)
                    let l:prefix= join(l:split_base[0:-2],'.')."."
                endif

                " Change parent_block and parent_class to block and class.
                let g:TclComplete#attr_class = substitute(g:TclComplete#attr_class,'parent_','','')

                " Construct the complete_list so that the dotted prefixes are in front.
                let l:complete_list = sort(keys(get(g:TclComplete#attributes,g:TclComplete#attr_class,{})))
                call map(l:complete_list, "l:prefix.v:val")
            else
                let g:ctype = 'attributes (derived from get_* -filter)'
                let g:TclComplete#attr_class = TclComplete#GetObjectClass(g:active_cmd)
                let l:complete_list = sort(keys(get(g:TclComplete#attributes,g:TclComplete#attr_class,{})))
                call extend(l:complete_list,["defined","undefined"])
                let l:menu_dict     = get(g:TclComplete#attributes,g:TclComplete#attr_class,{})
            endif


        " 5a) G_var completion but for the getvar/setvar/etc commands
        elseif has_key(g:TclComplete#gvar_funcs, g:active_cmd)
            let g:ctype = 'g_var function'
            let l:complete_list = g:TclComplete#g_vars

        " ivar bundle tag completion from archive
        elseif g:active_cmd == 'set' && g:last_completed_word =~ 'ivar(\w\+,\w\+,tag)'
            let g:ctype = 'bundle tag'
            let [__,block,bundle,tag] = split(g:last_completed_word,'[(),]')
            if exists('$PROJ_ARCHIVE')
                let arc_dir = join([$PROJ_ARCHIVE,'arc',block,bundle],"/")
                let g:ctype = arc_dir
                if isdirectory(arc_dir)
                    let l:complete_list = glob(arc_dir.'/*',"",'1')
                    call map(l:complete_list, 'split(v:val, "/")[-1]')
                endif
            endif
            

        " 5b) Complete the command with variable names (without $ sign)
        elseif has_key(g:TclComplete#varname_funcs, g:active_cmd) || has_key(g:TclComplete#varname_funcs, g:active_cmd.' '.g:last_completed_word)
            let g:ctype = 'varname function'
            let l:complete_list = TclComplete#ScanBufferForVariableNames()

        " 5c) Complete with environment variables
        elseif has_key(g:TclComplete#env_funcs, g:active_cmd)
            let g:ctype = 'env'
            let l:menu_dict = g:TclComplete#arrays['env']
            let l:complete_list = sort(keys(l:menu_dict))

        " 5d) Complete with the list of designs in your project.
        elseif g:last_completed_word == "-design" || has_key(g:TclComplete#design_funcs, g:active_cmd)
            let g:ctype = 'design'
            let l:complete_list = g:TclComplete#designs

        " 5e) Complete with Synopsys application options
        elseif has_key(g:TclComplete#app_option_funcs, g:active_cmd)
            let g:ctype = 'app_options'
            let l:complete_list = sort(keys(g:TclComplete#app_options_dict))
            let l:menu_dict = g:TclComplete#app_options_dict

        " 5f) Complete with Synopsys applicaiton variables
        elseif g:active_cmd=~# 'app_var'
            let g:ctype = 'app_var'
            let l:complete_list = sort(g:TclComplete#app_var_list)

        " 5g) Complete with iccpp (iTar) parameters
        elseif g:active_cmd =~# '\viccpp_com::(set|get)_param'
            let g:ctype = 'iccpp parameter'
            let l:complete_list = sort(keys(g:TclComplete#iccpp_dict))
            let l:menu_dict = g:TclComplete#iccpp_dict

        " 6a) Completions for two word combinations (like 'string is')
        elseif has_key(g:TclComplete#options,g:active_cmd." ".g:last_completed_word)
            let g:ctype = 'two word options'
            let l:two_word_command = join([g:active_cmd,g:last_completed_word])
            let l:complete_list = g:TclComplete#options[l:two_word_command]
            let l:menu_dict     = get(g:TclComplete#details,l:two_word_command,[])

        " 6b) Complete two word namespace commands with your namespaces.
        elseif g:active_cmd=='namespace'
            let l:namespace_options = get(g:TclComplete#options,'namespace',[])
            if index(l:namespace_options,g:last_completed_word)<0
                let g:ctype = 'namespace_options'
                let l:complete_list = g:TclComplete#options['namespace']
            else
                let g:ctype = 'namespaces'
                let l:complete_list = g:TclComplete#namespaces
            endif

        " 6c) Complete two word array commands with your array names
        elseif (g:active_cmd=='array' && g:last_completed_word != 'array') || g:active_cmd=='parray'
            let g:ctype = 'array'
            let l:complete_list = g:TclComplete#ScanBufferForArrayNames()

        " 6d) Complete two word package commands with your packages
        elseif g:active_cmd=='package' && g:last_completed_word != 'package' 
            let g:ctype = 'package'
            let l:complete_list = g:TclComplete#packages

        " 6e) Situations where the completion list should be a list of commands.
        elseif g:active_cmd=='info' && g:last_completed_word=~'^commands\?$'
            let g:ctype = 'info commands'
            let l:complete_list = g:TclComplete#cmds

        " 6f) compute polygons -operation
                " AND       Get the region covered by both objects1 and objects2
                " OR        Get the region covered by either objects1 or objects2
                " XOR       Get the region covered by objects1 or by objects2 but
                "                    not both
                " NOT       Get the region covered by objects1 but not by objects2
                " TOUCHING  Get the region covered by the poly_rects in objects1 that abuts
                "                    or overlaps with one or more poly_rects in objects2
                " INTERSECT Get the region covered by the poly_rects in objects1 that overlaps
                "                    with one or more poly_rects in objects2
        elseif g:active_cmd=='compute_polygons' && g:last_completed_word=='-operation'
            let g:ctype = 'compute_polygons'
            let l:complete_list = ['AND', 'OR', 'XOR', 'NOT', 'TOUCHING', 'INTERSECT']


        " 7a) Techfile stuff (relies on $SD_BUILD2/utils/shared/techfile.tcl)
        elseif g:active_cmd =~ 'tech::get_techfile_info'
            let g:ctype = 'techfile'
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

        " 8) Track patterns
        elseif has_key(g:TclComplete#trackpattern_funcs, g:active_cmd) && g:last_completed_word=='-pattern'
            let g:ctype = 'track_patterns'
            let l:complete_list = g:TclComplete#track_patterns

        " 9) GUI stuff
        elseif g:active_cmd=~'^gui' && g:last_completed_word!~'^gui'
            if g:last_completed_word == '-color'
                let l:complete_list = split('white red orange yellow green blue purple light_red light_orange light_yellow light_green light_blue light_purple')
            elseif g:last_completed_word == '-pattern'                                                             
                let l:complete_list = split('BDDiagPattern CrossPattern Dense1Pattern Dense2Pattern Dense3Pattern Dense4Pattern Dense5Pattern Dense6Pattern Dense7Pattern DiagCrossPattern FDiagPattern kHorPattern NoBrush SolidPattern VerPattern')
            elseif g:last_completed_word == '-type'
                let l:complete_list = split('arrow line polygon polyline rectangle ruler symbol text')
            elseif g:last_completed_word == '-symbol_type'
                let l:complete_list = split('diamond square triangle x')
            elseif g:last_completed_word=='-line_style'
                let l:complete_list = split('CustomDashLine DashDotDotLine DashDotLine DashLine DotLine NoPen SolidLine')
            elseif g:last_completed_word=='-symbol_size'
                let l:complete_list = range(3,100)
            elseif g:last_completed_word=='-setting'
                let l:complete_list = g:TclComplete#gui_layout_window_list
            endif

        " 11) Synopsys error/warning msg ids
        elseif has_key(g:TclComplete#msg_id_funcs, g:active_cmd)
            let g:ctype = 'msg_id'
            let l:complete_list = sort(keys(g:TclComplete#msg_ids))
            let l:menu_dict = g:TclComplete#msg_ids


        " 12) RDT stuff
        elseif has_key(g:TclComplete#rdt_commands,g:active_cmd)
            let g:ctype = 'rdt_steps'
            let l:complete_list = TclComplete#get_rdt_list(g:active_cmd,g:last_completed_word,l:base)
        
        " Default) Options of the active command.
        else
            let g:ctype = 'default'
            let l:complete_list = get(g:TclComplete#options,g:active_cmd,[])
            let l:menu_dict     = get(g:TclComplete#details,g:active_cmd,[])
        endif

        " Just in case nothing matches, let the user known.   
        if len(l:complete_list)==0
            echom "TclComplete: no matches found (do you have g:TclComplete#dir defined?)"
            return
        endif

        " Finally, we filter the choices and add the description.
        let res = []
        let g:complete_list = l:complete_list
        let g:menu_dict = l:menu_dict
        for m in l:complete_list
            if m=~# '^'.l:base
                let menu = get(l:menu_dict,m,'')
                call add(res, {'word':m, 'menu':menu})
            endif
        endfor
        return res
    endif
endfunction

"""""""" Helper proc for RDT """"""""""""""""""""""""""""
function! TclComplete#get_rdt_list(active_cmd,last_completed_word,base)
    """ runRDT command """""""""""""""""""""""
    if a:active_cmd=='runRDT'
        if a:last_completed_word=='-load'
            let g:ctype = 'runRDT -load'
            return g:TclComplete#rdt_stage_list
        elseif a:last_completed_word=='-stop'
            " Allow a stage.step format
            if a:base =~ '\.'
                let g:ctype='runRDT -stop stage.step'
                let l:rdt_stage = split(a:base,'\.')[0]
                let l:rdt_steps = get(g:TclComplete#rdt_step_dict,l:rdt_stage,'[]')
                return map(l:rdt_steps,"l:rdt_stage.'.'.v:val")
            else
            " ...or a stage name only
                let g:ctype='runRDT -stop stage'
                return g:TclComplete#rdt_stage_list
            endif
        elseif a:last_completed_word=='-load_cel'
            let g:ctype = 'runRDT -load_cel'
            return g:TclComplete#designs
        endif
    endif

    """ run_add_post_step/run_add_pre_step
    if a:active_cmd=~'^rdt_add_\(post\|pre\)_step'
        let g:ctype='rdt_add_post/pre_step'
        if a:active_cmd==a:last_completed_word
            return g:TclComplete#rdt_stage_list
        else
            return get(g:TclComplete#rdt_step_dict,a:last_completed_word,'[]')
        endif
    endif

    """ run_add_post_step/run_add_pre_stage
    if a:active_cmd=~'^rdt_add_\(post\|pre\)_stage'
        let g:ctype='rdt_add_post/pre_stage'
        if a:active_cmd==a:last_completed_word
            return ['[getvar G_FLOW]']
        elseif a:last_completed_word=~'G_FLOW'
            return g:TclComplete#rdt_stage_list
        else
            return get(g:TclComplete#rdt_step_dict,a:last_completed_word,'[]')
        endif
    endif

    """ rdt_remove_stage """""""""
    if a:active_cmd=='rdt_remove_stage'
        let g:ctype='rdt_remove_stage'

        if a:last_completed_word=='-flow'
            return ['[getvar G_FLOW]']
        elseif a:last_completed_word=='-stage'
            return g:TclComplete#rdt_stage_list
        endif
    endif

    """ rdt_get_global/rail_voltages  - complete with corner names
    if a:active_cmd=~'^rdt_get_\(global\|rail\)_voltage'
        let g:ctype='rdt_get__voltage corner'
        return TclComplete#get_g_var_array_names('G_CORNER_DETAILS')
    endif

    """ rdt_get_global/rail_voltages  - complete with corner names
    if a:active_cmd=='rdt_get_scenario_data'
        let g:ctype='rdt_get_scenario_data'
        return TclComplete#get_g_var_array_names('G_SCENARIO_DETAILS')
    endif

    " Return an empty list by default
    return []
endfunction

function! TclComplete#get_g_var_array_names(g_var)
    let result=[]
    for g_var in g:TclComplete#g_var_arrays
        let split_list = split(g_var,'(')
        if split_list[0]==a:g_var
            call add(result,split_list[1][0:-2])
        endif
    endfor
    return result
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" 1)  Change keys of g:TclComplete#arrays['ivar'] to start
"       with "ivar(".   
" 2)  Change values, if possible, of g:TclComplete#arrays['ivar'] to 
"       come from ivar_desc array
" 3)  Break up the ivar(lib,*,*,*) values because there are so many!
" 4)  
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! TclComplete#ivar_prep()
    if !has_key(g:TclComplete#arrays, 'ivar')
        return
    endif

    let ivar_dict = get(g:TclComplete#arrays, 'ivar')

    if has_key(g:TclComplete#arrays, 'ivar_desc')
        let value_dict = get(g:TclComplete#arrays,'ivar_desc')
    else
        let value_dict = ivar_dict
    endif

    for ivar_name in keys(ivar_dict)
        if ivar_name =~ '^/p/.*archive' 
            " Ignore ivar names like '/p/gnrc/archive...'
            continue

        elseif ivar_name =~ '^lib,' 
            " Special consideration for bit ivar(lib,*,*,*...) values
            let lib_fields = split(ivar_name,",")

            " Use the first two fields as an ivar( completion candidate.
            let first_two  = join(lib_fields[0:1], ",")
            let new_key = 'ivar('.first_two
            let g:TclComplete#ivar_completion[new_key] = ''

            " Also save the complete name in a new dict just for ivar lib names
            if !has_key(g:TclComplete#ivar_lib_names,first_two)
                let g:TclComplete#ivar_lib_names[first_two] = {}
            endif
            let g:TclComplete#ivar_lib_names[first_two]['ivar('.ivar_name] = ''

        else 
            let new_key = 'ivar('.ivar_name
            let new_value = get(value_dict, ivar_name, '')
            let g:TclComplete#ivar_completion[new_key] = new_value
        endif
    endfor

    " Make another ivar dictionary, but with all keys starting with '$'
    let g:TclComplete#dollar_ivar_completion = {}
    for ivar_name in keys(g:TclComplete#ivar_completion) 
        let val = get(g:TclComplete#ivar_completion, ivar_name)
        let g:TclComplete#dollar_ivar_completion['$'.ivar_name] = val
    endfor


endfunction
