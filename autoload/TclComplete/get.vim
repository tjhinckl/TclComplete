""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Give each completion list/dict a different getter function
"  for lazy loading.  Only load the json when needed instead
"  of loading everything at once, which slows down the first
"  TclComplete operation for the user.
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! TclComplete#get#Commands()
    if !exists('g:TclComplete#cmds')
        let g:TclComplete#cmds = TclComplete#ReadJsonFile('commands.json','list')
    endif
    return g:TclComplete#cmds
endfunction

function! TclComplete#get#Options()
    if !exists('g:TclComplete#options')
        let g:TclComplete#options = TclComplete#ReadJsonFile('options.json','dict')
    endif
    return g:TclComplete#options
endfunction

function! TclComplete#get#OptionDetails()
    if !exists('g:TclComplete#details')
        let g:TclComplete#details = TclComplete#ReadJsonFile('details.json','dict')
    endif
    return g:TclComplete#details
endfunction

function! TclComplete#get#Descriptions()
    if !exists('g:TclComplete#descriptions')
        let g:TclComplete#descriptions = TclComplete#ReadJsonFile('descriptions.json','dict')
    endif
    return g:TclComplete#descriptions
endfunction

function! TclComplete#get#Attributes()
    if !exists('g:TclComplete#attributes')
        let g:TclComplete#attributes = TclComplete#ReadJsonFile('attributes.json','dict')
    endif
    return g:TclComplete#attributes
endfunction

function! TclComplete#get#ObjectClasses()
    if !exists('g:TclComplete#object_classes')
        let g:TclComplete#object_classes = sort(keys(TclComplete#get#Attributes()))
    endif
    return g:TclComplete#object_classes
endfunction

function! TclComplete#get#MsgIds()
    if !exists('g:TclComplete#msg_ids')
        let g:TclComplete#msg_ids = TclComplete#ReadJsonFile('msg_ids.json', 'dict')
    endif
    return g:TclComplete#msg_ids
endfunction

function! TclComplete#get#RegexpCharClassList()
    if !exists('g:TclComplete#regexp_char_class_list')
        let g:TclComplete#regexp_char_class_list = TclComplete#ReadJsonFile('regexp_char_classes.json','list')
    endif
    return g:TclComplete#regexp_char_class_list
endfunction

function! TclComplete#get#Packages()
    if !exists('g:TclComplete#packages')
        let g:TclComplete#packages = TclComplete#ReadJsonFile('packages.json', 'dict')
    endif
    return g:TclComplete#packages
endfunction

function! TclComplete#get#Namespaces()
    if !exists('g:TclComplete#namespaces')
        " Use the TclComplete#cmds list to derive namespaces 
        let g:TclComplete#namespaces = copy(TclComplete#get#Commands())

        " Use only commands including ::
        call filter(g:TclComplete#namespaces,"v:val=~'::'")

        " Only keep the namespace part of the command name
        let map_cmd = "substitute(v:val,'::[^:]*$','','')"
        call map(g:TclComplete#namespaces,map_cmd)
        call uniq(sort(g:TclComplete#namespaces,'i'))
    endif
    return g:TclComplete#namespaces
endfunction

function! TclComplete#get#IccppParams()
    if !exists('g:TclComplete#iccpp')
        let g:TclComplete#iccpp = TclComplete#ReadJsonFile('iccpp.json', 'list')
    endif
    return g:TclComplete#iccpp
endfunction

function! TclComplete#get#IccppDict()
    if !exists('g:TclComplete#iccpp_dict')
        let g:TclComplete#iccpp_dict = TclComplete#ReadJsonFile('iccpp_dict.json', 'dict')
    endif
    return g:TclComplete#iccpp_dict
endfunction

function! TclComplete#get#GVars()
    if !exists('g:TclComplete#g_vars')
        let g:TclComplete#g_vars = TclComplete#ReadJsonFile('g_vars.json', 'dict')
    endif
    return g:TclComplete#g_vars
endfunction

function! TclComplete#get#GVarArrays()
    if !exists('g:TclComplete#g_var_arrays')
        let g:TclComplete#g_var_arrays = TclComplete#ReadJsonFile('g_var_arrays.json', 'dict')
    endif
    return g:TclComplete#g_var_arrays
endfunction

function! TclComplete#get#Arrays()
    if !exists('g:TclComplete#arrays')
        let g:TclComplete#arrays = TclComplete#ReadJsonFile('arrays.json','dict')
    endif
    return g:TclComplete#arrays
endfunction

function! TclComplete#get#IvarDict()
    if !exists('g:TclComplete#ivar_dict')
        let g:TclComplete#ivar_dict = TclComplete#ReadJsonFile('ivar_dict.json','dict')
    endif
    return g:TclComplete#ivar_dict
endfunction

function! TclComplete#get#IvarLibDict()
    if !exists('g:TclComplete#ivar_lib_dict')
        let g:TclComplete#ivar_lib_dict = TclComplete#ReadJsonFile('ivar_lib_dict.json','dict')
    endif
    return g:TclComplete#ivar_lib_dict
endfunction

" Try to convert the value in ivar_dict.json file for 'iproc_search_path'
" into a comma separated string. 
function! TclComplete#get#IprocSearchPath()
    if !exists('g:TclComplete#iproc_search_path')
        let search_path = get(TclComplete#get#IvarDict(), 'search_path', '')
        if search_path != ''
            " Weird stuff here... the value is 'iproc_search_path {path1 path2 path3}'
            " and should be converted to 'path1,path2,path3'
            let search_path = trim(join(split(search_path)[1:], ","), "{}")
        endif
        let g:TclComplete#iproc_search_path = search_path
    endif

    return g:TclComplete#iproc_search_path
endfunction

function! TclComplete#get#TrackPatterns()
    if !exists('g:TclComplete#track_patterns')
        " Get the track patterns from the G_ROUTE_TRACK_PATTERNS array
        let g:TclComplete#track_patterns = filter(copy(TclComplete#get#GVarArrays()),"v:val=~'G_ROUTE_TRACK_PATTERNS'")
        call map(g:TclComplete#track_patterns,"split(v:val,'[()]')[1]")
    endif
    return g:TclComplete#track_patterns
endfunction


function! TclComplete#get#TechFileTypes()
    if !exists('g:TclComplete#techfile_types')
        let g:TclComplete#techfile_types      = TclComplete#ReadJsonFile('techfile_types.json','list')
    endif
    return g:TclComplete#techfile_types
endfunction

function! TclComplete#get#TechFileLayerDict()
    if !exists('g:TclComplete#techfile_layer_dict')
        let g:TclComplete#techfile_layer_dict = TclComplete#ReadJsonFile('techfile_layer_dict.json','dict')
    endif
    return g:TclComplete#techfile_layer_dict
endfunction

function! TclComplete#get#TechFileAttrDict()
    if !exists('g:TclComplete#techfile_attr_dict')
        let g:TclComplete#techfile_attr_dict  = TclComplete#ReadJsonFile('techfile_attr_dict.json','dict')
    endif
    return g:TclComplete#techfile_attr_dict
endfunction

function! TclComplete#get#AppVarList()
    if !exists('g:TclComplete#app_var_list')
        let g:TclComplete#app_var_list = TclComplete#ReadJsonFile('app_vars.json','dict')
    endif
    return g:TclComplete#app_var_list
endfunction

function! TclComplete#get#AppOptionDict()
    if !exists('g:TclComplete#app_options_dict')
        let g:TclComplete#app_options_dict  = TclComplete#ReadJsonFile('app_options.json','dict')
    endif
    return g:TclComplete#app_options_dict
endfunction

function! TclComplete#get#Designs()
    if !exists('g:TclComplete#designs')
        let g:TclComplete#designs = TclComplete#ReadJsonFile('designs.json','list')
    endif
    return g:TclComplete#designs
endfunction

function! TclComplete#get#GuiLayoutWindowList()
    if !exists('g:TclComplete#gui_layout_window_list')
        let g:TclComplete#gui_layout_window_list = TclComplete#ReadJsonFile('gui_settings_layout.json','list')
    endif
    return g:TclComplete#gui_layout_window_list
endfunction

function! TclComplete#get#RdtStepDict()
    if !exists('g:TclComplete#rdt_step_dict')
        let g:TclComplete#rdt_step_dict  = TclComplete#ReadJsonFile('rdt_steps.json','dict')
    endif
    return g:TclComplete#rdt_step_dict
endfunction

function! TclComplete#get#RdtStageList()
    if !exists('g:TclComplete#rdt_stage_list')
        let g:TclComplete#rdt_stage_list = sort(keys(TclComplete#get#RdtStepDict()))
    endif
    return g:TclComplete#rdt_stage_list
endfunction

