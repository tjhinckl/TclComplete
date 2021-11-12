""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Give each completion list/dict a different getter function
"  for lazy loading.  Only load the json when needed instead
"  of loading everything at once, which slows down the first
"  TclComplete operation for the user.
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! TclComplete#get#Commands()
    if !has_key(g:TclComplete#json_vars, 'cmds')
        let g:TclComplete#json_vars['cmds'] = TclComplete#ReadJsonFile('commands.json','list')
    endif
    return g:TclComplete#json_vars['cmds']
endfunction

function! TclComplete#get#Options()
    if !has_key(g:TclComplete#json_vars, 'options')
        let g:TclComplete#json_vars['options'] = TclComplete#ReadJsonFile('options.json','dict')
    endif
    return g:TclComplete#json_vars['options']
endfunction

function! TclComplete#get#OptionDetails()
    if !has_key(g:TclComplete#json_vars, 'details')
        let g:TclComplete#json_vars['details'] = TclComplete#ReadJsonFile('details.json','dict')
    endif
    return g:TclComplete#json_vars['details']
endfunction

function! TclComplete#get#Descriptions()
    if !has_key(g:TclComplete#json_vars, 'descriptions')
        let g:TclComplete#json_vars['descriptions'] = TclComplete#ReadJsonFile('descriptions.json','dict')
    endif
    return g:TclComplete#json_vars['descriptions']
endfunction

function! TclComplete#get#Attributes()
    if !has_key(g:TclComplete#json_vars, 'attributes')
        let g:TclComplete#json_vars['attributes'] = TclComplete#ReadJsonFile('attributes.json','dict')
    endif
    return g:TclComplete#json_vars['attributes']
endfunction

function! TclComplete#get#ObjectClasses()
    if !has_key(g:TclComplete#json_vars, 'object_classes')
        let g:TclComplete#json_vars['object_classes'] = sort(keys(TclComplete#get#Attributes()))
    endif
    return g:TclComplete#json_vars['object_classes']
endfunction

function! TclComplete#get#MsgIds()
    if !has_key(g:TclComplete#json_vars, 'msg_ids')
        let g:TclComplete#json_vars['msg_ids'] = TclComplete#ReadJsonFile('msg_ids.json', 'dict')
    endif
    return g:TclComplete#json_vars['msg_ids']
endfunction

function! TclComplete#get#RegexpCharClassList()
    if !has_key(g:TclComplete#json_vars, 'regexp_char_class_list')
        let g:TclComplete#json_vars['regexp_char_class_list'] = TclComplete#ReadJsonFile('regexp_char_classes.json','list')
    endif
    return g:TclComplete#json_vars['regexp_char_class_list']
endfunction

function! TclComplete#get#Packages()
    if !has_key(g:TclComplete#json_vars, 'packages')
        let g:TclComplete#json_vars['packages'] = TclComplete#ReadJsonFile('packages.json', 'dict')
    endif
    return g:TclComplete#json_vars['packages']
endfunction

function! TclComplete#get#Namespaces()
    if !has_key(g:TclComplete#json_vars, 'namespaces')
        " Use the TclComplete#cmds list to derive namespaces 
        let namespaces = copy(TclComplete#get#Commands())

        " Use only commands including ::
        call filter(namespaces,"v:val=~'::'")

        " Only keep the namespace part of the command name
        let map_cmd = "substitute(v:val,'::[^:]*$','','')"
        call map(namespaces,map_cmd)
        call uniq(sort(namespaces,'i'))
        let g:TclComplete#json_vars['namespaces'] = namespaces
    endif
    return g:TclComplete#json_vars['namespaces']
endfunction

function! TclComplete#get#IccppParams()
    if !has_key(g:TclComplete#json_vars, 'iccpp')
        let g:TclComplete#json_vars['iccpp'] = TclComplete#ReadJsonFile('iccpp.json', 'list')
    endif
    return g:TclComplete#json_vars['iccpp']
endfunction

function! TclComplete#get#IccppDict()
    if !has_key(g:TclComplete#json_vars, 'iccpp_dict')
        let g:TclComplete#json_vars['iccpp_dict'] = TclComplete#ReadJsonFile('iccpp_dict.json', 'dict')
    endif
    return g:TclComplete#json_vars['iccpp_dict']
endfunction

function! TclComplete#get#GVars()
    if !has_key(g:TclComplete#json_vars, 'g_vars')
        let g:TclComplete#json_vars['g_vars'] = TclComplete#ReadJsonFile('g_vars.json', 'dict')
    endif
    return g:TclComplete#json_vars['g_vars']
endfunction

function! TclComplete#get#GVarArrays()
    if !has_key(g:TclComplete#json_vars, 'g_var_arrays')
        let g:TclComplete#json_vars['g_var_arrays'] = TclComplete#ReadJsonFile('g_var_arrays.json', 'dict')
    endif
    return g:TclComplete#json_vars['g_var_arrays']
endfunction

function! TclComplete#get#Arrays()
    if !has_key(g:TclComplete#json_vars, 'arrays')
        let g:TclComplete#json_vars['arrays'] = TclComplete#ReadJsonFile('arrays.json','dict')
    endif
    return g:TclComplete#json_vars['arrays']
endfunction

function! TclComplete#get#IvarDict()
    if !has_key(g:TclComplete#json_vars, 'ivar_dict')
        let g:TclComplete#json_vars['ivar_dict'] = TclComplete#ReadJsonFile('ivar_dict.json','dict')
    endif
    return g:TclComplete#json_vars['ivar_dict']
endfunction

function! TclComplete#get#IvarLibDict()
    if !has_key(g:TclComplete#json_vars, 'ivar_lib_dict')
        let g:TclComplete#json_vars['ivar_lib_dict'] = TclComplete#ReadJsonFile('ivar_lib_dict.json','dict')
    endif
    return g:TclComplete#json_vars['ivar_lib_dict']
endfunction

" Try to convert the value in ivar_dict.json file for 'iproc_search_path'
" into a comma separated string. 
function! TclComplete#get#IprocSearchPath()
    if !has_key(g:TclComplete#json_vars, 'iproc_search_path')
        let search_path = get(TclComplete#get#IvarDict(), 'search_path', '')
        if search_path != ''
            " Weird stuff here... the value is 'iproc_search_path {path1 path2 path3}'
            " and should be converted to 'path1,path2,path3'
            let search_path = trim(join(split(search_path)[1:], ","), "{}")
        endif
        let g:TclComplete#json_vars['iproc_search_path'] = search_path
    endif

    return g:TclComplete#json_vars['iproc_search_path']
endfunction

function! TclComplete#get#TrackPatterns()
    if !has_key(g:TclComplete#json_vars, 'track_patterns')
        " Get the track patterns from the G_ROUTE_TRACK_PATTERNS array
        let track_patterns = filter(copy(TclComplete#get#GVarArrays()),"v:val=~'G_ROUTE_TRACK_PATTERNS'")
        call map(track_patterns,"split(v:val,'[()]')[1]")
        let g:TclComplete#json_vars['track_patterns'] = track_patterns
    endif
    return g:TclComplete#json_vars['track_patterns']
endfunction


function! TclComplete#get#TechFileTypes()
    if !has_key(g:TclComplete#json_vars, 'techfile_types')
        let g:TclComplete#json_vars['techfile_types']      = TclComplete#ReadJsonFile('techfile_types.json','list')
    endif
    return g:TclComplete#json_vars['techfile_types']
endfunction

function! TclComplete#get#TechFileLayerDict()
    if !has_key(g:TclComplete#json_vars, 'techfile_layer_dict')
        let g:TclComplete#json_vars['techfile_layer_dict'] = TclComplete#ReadJsonFile('techfile_layer_dict.json','dict')
    endif
    return g:TclComplete#json_vars['techfile_layer_dict']
endfunction

function! TclComplete#get#TechFileAttrDict()
    if !has_key(g:TclComplete#json_vars, 'techfile_attr_dict')
        let g:TclComplete#json_vars['techfile_attr_dict']  = TclComplete#ReadJsonFile('techfile_attr_dict.json','dict')
    endif
    return g:TclComplete#json_vars['techfile_attr_dict']
endfunction

function! TclComplete#get#AppVarList()
    if !has_key(g:TclComplete#json_vars, 'app_var_list')
        let g:TclComplete#json_vars['app_var_list'] = TclComplete#ReadJsonFile('app_vars.json','dict')
    endif
    return g:TclComplete#json_vars['app_var_list']
endfunction

function! TclComplete#get#AppOptionDict()
    if !has_key(g:TclComplete#json_vars, 'app_options_dict')
        let g:TclComplete#json_vars['app_options_dict']  = TclComplete#ReadJsonFile('app_options.json','dict')
    endif
    return g:TclComplete#json_vars['app_options_dict']
endfunction

function! TclComplete#get#Designs()
    if !has_key(g:TclComplete#json_vars, 'designs')
        let g:TclComplete#json_vars['designs'] = TclComplete#ReadJsonFile('designs.json','list')
    endif
    return g:TclComplete#json_vars['designs']
endfunction

function! TclComplete#get#GuiLayoutWindowList()
    if !has_key(g:TclComplete#json_vars, 'gui_layout_window_list')
        let g:TclComplete#json_vars['gui_layout_window_list'] = TclComplete#ReadJsonFile('gui_settings_layout.json','list')
    endif
    return g:TclComplete#json_vars['gui_layout_window_list']
endfunction

function! TclComplete#get#RdtStepDict()
    if !has_key(g:TclComplete#json_vars, 'rdt_step_dict')
        let g:TclComplete#json_vars['rdt_step_dict']  = TclComplete#ReadJsonFile('rdt_steps.json','dict')
    endif
    return g:TclComplete#json_vars['rdt_step_dict']
endfunction

function! TclComplete#get#RdtStageList()
    if !has_key(g:TclComplete#json_vars, 'rdt_stage_list')
        let g:TclComplete#json_vars['rdt_stage_list'] = sort(keys(TclComplete#get#RdtStepDict()))
    endif
    return g:TclComplete#json_vars['rdt_stage_list']
endfunction

