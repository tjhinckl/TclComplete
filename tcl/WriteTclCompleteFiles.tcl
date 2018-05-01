#############################################
#### create_tcl_omnicomplete_files.tcl ######
#############################################

# Author: Chris Heithoff
# Description:  Source this from the icc2_shell (or dc or pt?) to 
#               create a file that can be used for tcl omnicompletion
#               in Vim.
# Date of latest revision: 11-April-2018

##############################
# Helpers procs defined first 
##############################
proc mkdir_fresh {dir} {
    if {[file exists $dir]} {
        echo "Deleting previous $dir"
        file delete -force $dir
    }
    file mkdir $dir
}

        
# Run "help <command>".  Parse and return the description
#  Corner case:  "help help" returns help for three commands
proc get_description_from_help {cmd} {
    set result ""
    redirect -variable help_text {help $cmd}
    # Look for <cmdname>     # Description of the command
    foreach line [split $help_text "\n"] {
        if {[regexp {^\s*(\S+)\s+(#.*$)} $line -> cmd_name description]} {
            if {$cmd_name == $cmd} {
                set result [regsub -all {"} $description {\"}]
                #" Comment to fix Vim syntax coloring
            }
        }
    }
    return $result 
}

proc get_options_from_help {cmd} {
    # Returns a dictionary.  Key = option name  Value = option detail
    set result [dict create]

    # Parse the "help -v" text for this command
    redirect -variable help_text {help -v $cmd}
    if {[regexp "CMD-040" $help_text]} {return ""}

    # First look for the command name, then look for options
    set looking_for_command 1
    set looking_for_options 0

    foreach line  [split $help_text "\n"] {
        # We need to look only in the correct section. 
        # Some help results list multiple helps (like "help -v help")
        #   This only works when the descripion is there too, preceded by #
        if {$looking_for_command} {
            if {[regexp {^\s+(\S+)\s+(#.*$)} $line -> cmd_name description]} {
                if {$cmd_name == $cmd} {
                    set looking_for_command 0
                    set looking_for_options  1
                    continue
                }
            }
        }
        # Now get the command options. This start with a dash.
        #  They might be surrounded by brackets.
        #  The option is first, then the details, surrounded by parentheses.
        if {$looking_for_options} {
            if {[regexp {^\s*\[?(-[a-zA-Z0-9_]+)[^(]*(.*$)} $line -> opt detail] } {
                set detail [regsub -all {"} $detail {\"}]
                #" (comment to correct Vim syntax coloring)
                dict set result $opt $detail
            }
            # Exit loop if there is an empty line.
            if {[regexp {^\s*$} $line]} {
                break
            }
        }
    }
    return $result
}

# Run "man <command>".  Parse and return the options.
proc get_options_from_man {cmd} {
    set result {}
    redirect -variable man_text {man $cmd}
    foreach line [split $man_text "\n"] {
        # Look for "-option" at beginning of line.  This might grab too much?
        if {[regexp {^\s+(-[a-z]+)} $line -> opt]} {
            lappend result $opt
        }
    }
    return [lsort -u $result]
}

##########################################################################
# Helper proc to remove a final comma from a json list/dictionary
#   [               [
#    d,              d,
#    e,       ==>    e,
#    f,              f
#   ]               ]
##########################################################################
proc remove_final_comma {json_string} {
    set json_string [string trimright $json_string "\n,"]
    return "$json_string\n"
}
#################################
# Return a json string for a list
#################################
proc list_to_json {list} {
    set indent "    "
    set result "\[\n"
    foreach item [lsort $list] {
        append result "${indent}\"${item}\",\n"
    }
    set result [remove_final_comma $result]
    append result "]"
    return $result
}

#################################
# Return a json string for a dict
#################################
proc dict_to_json {dict} {
    set indent "    "
    set result "{\n"
    foreach key [lsort [dict keys $dict]] {
        set value [dict get $dict $key]
        set key   [string trim $key   "\""]
        set value [string trim $value "\""]
        append result "${indent}\"${key}\":\"${value}\",\n"
    }
    set result [remove_final_comma $result]
    append result "}"
    return $result
}
##########################################################################
# Return a json string for a dictionary of lists
##########################################################################
proc dict_of_lists_to_json {dict_of_lists} {
    set indent "    "
    set result "{\n"
    foreach key [lsort [dict keys $dict_of_lists]] {
        append result "${indent}\"${key}\":\n"
        append result "${indent}${indent}\[\n"
        foreach value [dict get $dict_of_lists $key] {
            append result "${indent}${indent}\"${value}\",\n"
        }
        set result [remove_final_comma $result]
        append result "${indent}${indent}\],\n"
    }
    set result [remove_final_comma $result]
    append result "}"
    return $result
}
        
##########################################################################
# Return a json string for a dictionary of dictionaries
##########################################################################
proc dict_of_dicts_to_json {dict_of_dicts} {
    set indent "    "
    set result "{\n"
    foreach key [lsort [dict keys $dict_of_dicts]] {
        append result "${indent}\"${key}\":\n"
        append result "${indent}${indent}\{\n"
        dict for {instance_name ref_name} [dict get $dict_of_dicts $key] {
            append result "${indent}${indent}\"${instance_name}\":\"${ref_name}\",\n"
        }
        set result [remove_final_comma $result]
        append result "${indent}${indent}\},\n"
    }
    set result [remove_final_comma $result]
    append result "}"
    return $result
}
####################################################################
# Ask the synopsys tool for commands, procs, packages, and functions
####################################################################
# Form a list of all commands (and remove the . command at the beginning.
#
#  Try to get an order like this:
#     Tcl built ins   ($builtin_list)
#     Synopsys commands     ($command_list)
#     procs in the current namespace   ($proc_list)
#     procs in the child namespaces    (proc_list)

echo "------------------------------------------------"
echo "---TclComplete:  querying SynopsysTcl for data..."
redirect -variable all_command_list {lsort -u [info command]}

# Divide all_command_list into builtin and regular commands
# The first uses the 'man' command, the other uses the 'help -v' 
# command to list the options.
set builtin_list {} 
set command_list {}
set proc_list    {}

# Initial some dicts
set desc_dict [dict create]
set namespace_children_dict [dict create]

## Split up all the commands into three lists (just for priority in the final list order)
foreach cmd $all_command_list {
    set description [get_description_from_help $cmd]
    dict set desc_dict $cmd $description
    if {[regexp "Builtin" $description]} {
        lappend builtin_list $cmd
    } elseif {[info procs $cmd]==""} {
        lappend command_list $cmd
    } else {
        lappend proc_list $cmd
    }
}
echo " ...\$builtin_list built"
echo " ...\$command_list built"

# We're not done with procs!  There are more procs inside namespaces.
set namespace_list [lsort -u [namespace children]]
echo " ...\$namespace_list built"
foreach namespace $namespace_list {
    redirect -variable namespace_procs {lsort -u [eval "info proc {${namespace}::*}"]}
    foreach proc_name $namespace_procs {
        set proc_name [string trim $proc_name "::"]
        lappend proc_list $proc_name
        set description [get_description_from_help $proc_name]
        dict set desc_dict $proc_name $description
    }
}
echo "...\$proc_list built"
echo "...\$desc_dict built"


######################################################################
# Form some other data structures for use later
######################################################################
# Form a list of expr functions
set func_list [ lsort -u [info function] ]
echo "...\$func_list built"

# Form a list of packages
set package_list [ lsort -u [package names] ]
echo "...\$package_list built"

# Form a list of aliases
redirect -variable alias_string {alias}
set alias_list [split $alias_string "\n"]
echo "...\$alias_list built"

#####################
# Application options
#####################
proc get_app_option_from_man_page {app_option} {
    redirect -variable man_text {man $app_option}
    set TYPE_flag 0
    set DEFAULT_flag 0
    set TYPE    ""
    set DEFAULT ""
    foreach line [split $man_text "\n"] {
        if {[regexp "^TYPE" $line]} { 
            set TYPE_flag 1
        } elseif {[regexp "^DEFAULT" $line]} { 
            set DEFAULT_flag 1
        } elseif {$TYPE_flag==1} {
            set TYPE [lindex $line 0]
            set TYPE_flag 0
        } elseif {$DEFAULT_flag==1} {
            set DEFAULT [lindex $line 0]
            set DEFAULT_flag 0
            break
        }
    }
    if {$TYPE!=""} {
        return "$TYPE:default=$DEFAULT"
    } else {
        return "unknown type"
    }
}

redirect -variable app_option_list {lsort -u [get_app_options]}
set app_option_dict [dict create]
foreach app_option $app_option_list {
    dict set app_option_dict $app_option [get_app_option_from_man_page $app_option]
}

    

####################################################################
# ICCPP parameters (this will be empty if ::iccpp_com doesn't exist)
####################################################################
set iccpp_param_list [array names ::iccpp_com::params_map]

####################################################################
# G_variables
####################################################################
setvar Gvar_list {}
setvar Gvar_array_list {}
foreach name [lsort -dictionary [array names ::GLOBAL_VAR::global_var]] {
    set name [lindex [split $name ","] 0]
    if [string match "*(*" $name] {
        lappend Gvar_array_list $name
    }
    set name [regsub {\(.*\)} $name "("]
    lappend Gvar_list $name
}
set Gvar_list       [lsort -unique -dictionary $Gvar_list]
set Gvar_array_list [lsort -unique -dictionary $Gvar_array_list]

######################################################################
# Form a multi-level dictionary of attributes
#  attribute_dict['class']['attr_name'] = choices
######################################################################
set attribute_dict [dict create]

# Dump list_attributes 
redirect -variable attribute_list {list_attributes -nosplit}
set attribute_list [split $attribute_list "\n"]
set start [expr {[lsearch -glob $attribute_list "-----*"]+1}]
set attribute_list [lrange $attribute_list $start end]

# ...again but for -application
redirect -variable attribute_class_list {list_attributes -nosplit -application}
set attribute_class_list [split $attribute_class_list "\n"]
set start [expr {[lsearch -glob $attribute_class_list "-----*"]+1}]
set attribute_class_list [lrange $attribute_class_list $start end]

# Now iterate over these lists to fill up the attribute dictionary
foreach entry [concat $attribute_list $attribute_class_list] {
    # Skip invalid entries
    if {[llength $entry]<3} {continue}

    # Parse entry for attr_name(like "length"), attr_class(like "wire"), and attr_datatype(like "float")
    set attr_name      [lindex $entry 0]                                                 
    set attr_class     [lindex $entry 1]
    set attr_datatype  [lindex $entry 2]

    # If necessary, initialize a dict for the class of this entry
    #   and also a subdict "choices".  
    if {![dict exists $attribute_dict $attr_class]} {
        dict set attribute_dict $attr_class [dict create]
    }

    # Derive the attribute possible values (data type, or constrained list)
    if {[llength $entry]>=5} {
        set attr_choices [lrange $entry 5 end]
    } else {
        set attr_choices $attr_datatype
    }

    # Fill up the class dict: key=attr-name, value=attr_choices
    dict set attribute_dict $attr_class $attr_name $attr_choices
}

######################################################################
# Form data structures from the ::techfile_info array
#   techfile_types - List
#   techfile_layers - Dict (keys = types, values = list of layers)
#   techfile_attributes - Dict (keys = "type:layer" - values = list of attributes)
######################################################################
# This command creates the ::techfile_info array
catch {::tech::read_techfile_info}
set techfile_types {}
set techfile_layer_dict [dict create]
set techfile_attr_dict  [dict create]
foreach name [lsort [array names ::techfile_info]] {
    lassign [split $name ":"] Type Layer
    if {$Type ni $techfile_types} {
        lappend techfile_types $Type
    }
    dict lappend techfile_layer_dict $Type $Layer
    dict set techfile_attr_dict $name [dict keys $::techfile_info($name)]
}

######################################################################
# Now that we have all the commands and some other stuff, 
# let's figure out the command descriptions, options, and option details
######################################################################
echo "TclComplete....building commands options"
set opt_dict     [dict create]
set details_dict [dict create]
echo "...\$opt_dict initialized"
echo "...\$details_dict initialized"

# non-builtins use "help" to get options 
foreach cmd [concat $command_list $proc_list] {
    dict set opt_dict     $cmd {}
    dict set details_dict $cmd [dict create]
    dict for {opt_name details} [get_options_from_help $cmd] {
        # APPEND this opt to this command's entry in opt_dict
        dict lappend opt_dict $cmd $opt_name

        # CREATE a dictionary to thi commands entry in details_dict
        dict set details_dict $cmd $opt_name $details
    }
} 
echo "...completed options for commands and proc"

    
# builtins use "man" or "namespace ensembles" to get options.  
#  (some special cases are hard coded)
foreach bi $builtin_list {
    if {[namespace ensemble exists $bi]} {
        set opts [dict keys [namespace ensemble configure $bi -map]]
    } else {
        set opts [get_options_from_man $bi]
    }
    dict set opt_dict $bi $opts
}
echo "...completed options for builtins"

# Special cases for options
dict set opt_dict "expr" $func_list
dict set opt_dict "info"    [lsort "args body class cmdcount commands complete coroutine default errorstack exists frame functions globals hostname level library loaded locals nameofexecutable object patchlevel procs script sharelibextension tclversion vars"]
dict set opt_dict "package" [lsort "ifneeded names present provide require unknown vcompare versions vsatisfies prefer"]
dict set opt_dict "package require" $package_list
echo "...completed options for special cases"

################################################################################
### Now  write out sourceable Vimscript code!!! 
###  - An earlier version of this script wrote out text files to be parse in Vim
###    Why not just directly write it out as Vimscript so that the Vim plugin 
###    runs faster ??!!
################################################################################
# 1)  Setup the output directory and dump the log
set outdir $::env(WARD)/TclComplete
mkdir_fresh $outdir
echo "Making new \$WARD/TclComplete directory..."

set log [open $outdir/WriteTclCompleteFiles.log w]
puts $log "#######################################################"
puts $log "### WriteNetlistInfo.log ##############################"
puts $log "#######################################################"
puts $log "Generated by: $::env(USER)"
puts $log "          at: [date]"
puts $log "        WARD: $::env(WARD)"
puts $log "    based on: $::env(TOOL_CFG)"
close $log 

# 2) Write data structures out in Vim format.
#    WARNING!  This is a backslash hellscape!
#       - Key names, value names and list elements must be
#         in quotes because they will be treated as strings in Vim.
#       - The command descriptions and option details will possibly
#         have either single quotes (apostrophes) or doubt quotes, 
#         these must be escaped.  (is regsub the best choice?)
#       - The puts string must be in double quotes instead of {} 
#         because variables need to be expanded.
#       - Square brackets must be escaped so Tcl ignore command substitution.
#       - Double quotes inside the string must be escaped so they 
#         don't close the surrounding double quotes.
#       - Vim comments are a start-of-string double quote
#       - Vim line continuation is a \ at beginning on next line
#            (not like Tcl or shell, which is end of previous line)
         
#-------------------------------------
#  All the commands in a Vim ordered list
#    g:TclComplete#cmds
#-------------------------------------
    set f [open $outdir/commands.vim w]
    puts $f "let g:TclComplete#cmds = \["
    foreach cmd [concat $builtin_list $command_list $proc_list] {
        puts $f "   \\ \"$cmd\"," 
    }
    puts $f "   \\]"
    close $f
    echo "...commands.vim file complete."

    echo [list_to_json [concat $builtin_list $command_list $proc_list]] > $outdir/commands.json
    echo "...commands.json file complete."
#-----------------------------------------
# Command options in a Vim dictionary.
#   key = command name
#   value = ordered list of options
#   g:TclComplete#options['cmd'] = ['opt1', 'opt2',]
#-----------------------------------------
    set f [open $outdir/options.vim w]
    # initialize details and opts dicts
    puts $f "let options = {}"
    foreach cmd [dict keys $opt_dict] {
        set option_string "\["
        foreach opt [lsort [dict get $opt_dict $cmd]] {
            append option_string "\"$opt\","
        }
        puts $f "let options\[\"$cmd\"\] = $option_string\]"
    }
    puts $f "\"\" Reassign to a global variable \"\""
    puts $f "let g:TclComplete#options = options"
    close $f
    echo "...options.vim file complete."

    echo [dict_of_lists_to_json $opt_dict] > $outdir/options.json
    echo "...options.json file complete."

#-----------------------------------------
# Command option details in a Vim dictionary of dictionaries
#   key = command name
#   value = dictionary with key=option and value=details
#   g:TclComplete#details['cmd']['opt1'] = "details of the option"
#-----------------------------------------
    set f [open $outdir/details.vim w]
    puts $f "let details = {}"
    dict for {cmd opt_detail_dict} $details_dict {
        puts $f "   let details\[\"$cmd\"\]={}"
        dict for {opt detail} $opt_detail_dict {
            puts $f "        let details\[\"$cmd\"\]\[\"$opt\"\] = \"$detail\""
        }
    }
    puts $f "\"\" Reassign to a global variable \"\""
    puts $f "let g:TclComplete#details = details"
    close $f
    echo "...details.vim file complete."

    echo [dict_of_dicts_to_json $details_dict] > $outdir/details.json
    echo "...details.json file complete."
#-----------------------------------------
# Command descriptions in a Vim dictionary
#   key = command name
#   value = command description
#   g:TclComplete#descriptions['cmd'] = "description of the command"
#-----------------------------------------
    set f   [open $outdir/descriptions.vim w]
    puts $f "let description = {}"
    dict for {cmd description} $desc_dict {
        puts $f "let description\[\"$cmd\"\] = \"$description\""
    }
    puts $f "\"\" Reassign to a global variable \"\""
    puts $f "let g:TclComplete#descriptions = description"
    close $f
    echo "...descriptions.vim file complete."

    echo [dict_to_json $desc_dict] > $outdir/descriptions.json
    echo "...descriptions.json file complete."

#----------------------------------------------------
# Write out aliases as Vim insert mode abbreviations
#----------------------------------------------------
    set f   [open $outdir/aliases.vim w]
    # Some aliases are useless in a script
    # set alias_exclusion_list { 2D_check_legality 2D_legalizer_toolbox cr h hg lag lcg pac pc pl pop push qtcl_activate_widget_slot qtcl_add_widget_property qtcl_check_widget qtcl_connect_widgets qtcl_create_widget qtcl_destroy_widget qtcl_disconnect_widgets qtcl_get_widget_data qtcl_get_widget_property qtcl_operate_widget qtcl_remove_widget_property qtcl_set_widget_property ra rc rt rtmax rtmin s_cell s_net s_port s_terminal sg st stages steps zs} 
        
    # foreach entry $alias_list {
    #     if {[regexp {(\S+)\s+(.*$)} $entry -> alias_name alias_def]} {
    #         if {$alias_name ni $alias_exclusion_list} {
    #             puts $f "iabbrev [string trim $entry]"
    #         }
    #     }
    # }
    
    # Forget about the aliases dumped from ICC2.  Let's just do a few.
    puts $f "iabbrev fic foreach_in_collection"
    puts $f "iabbrev ga  get_attribute"
    puts $f "iabbrev cs  change_selection"
    puts $f "iabbrev gs  get_selection"
    
    close $f
    echo "...aliases.vim file complete."


#----------------------------------------------------
# Write out attributes as a big fat Vim dictionary
#----------------------------------------------------
    set f [open $outdir/attributes.vim w]
    puts $f "let attributes = {}"
    dict for {class class_dict} $attribute_dict {
        puts  $f "let attributes\[\"$class\"\]={}"

        # class is 'cell', 'pin', etc
        # class_dict :  key=attr_name    key=attr_choices

        dict for {attr_name attr_choices} $class_dict {
            puts $f "let attributes\[\"$class\"\]\[\"$attr_name\"\] = \"$attr_choices\""
        }

    }
    puts $f "\"\" Reassign to a global variable \"\""
    puts $f "let g:TclComplete#attributes = attributes"
    close $f
    echo "...attributes.vim file complete."

    echo [dict_of_dicts_to_json $attribute_dict] > $outdir/attributes.json
    echo "...attributes.json file complete."

#-------------------------------------
#  G variables (these are only the ones that exist in the session)
#-------------------------------------
    set f [open $outdir/g_vars.vim w]
    puts $f "let g:TclComplete#g_vars = \["
    foreach g_var $Gvar_list {
        puts $f "   \\ \"$g_var\"," 
    }
    puts $f "   \\]"
    close $f
    echo "...g_vars.vim file complete."

    set f [open $outdir/g_var_arrays.vim w]
    puts $f "let g:TclComplete#g_var_arrays = \["
    foreach g_var_array $Gvar_array_list {
        puts $f "   \\ \"$g_var_array\"," 
    }
    puts $f "   \\]"
    close $f
    echo "...g_var_arrays.vim file complete."

    echo [list_to_json $Gvar_list] > $outdir/g_vars.json
    echo "...g_vars.json file complete."

    echo [list_to_json $Gvar_array_list] > $outdir/g_var_arrays.json
    echo "...g_var_arrays.json file complete."
    
#-------------------------------------
#  iccpp parameters in a vim ordered list
#    g:tclcomplete#iccpp
#-------------------------------------
    # list format of just the parameter names.
    set f [open $outdir/iccpp.vim w]
    puts $f "let g:TclComplete#iccpp = \["
    foreach param $iccpp_param_list {
        puts $f "   \\ \"$param\"," 
    }
    puts $f "   \\]"
    close $f
    echo "...iccpp.vim file complete."

    echo [list_to_json $iccpp_param_list] > $outdir/iccpp.json
    echo "...iccpp_dict.json file complete."

    set f [open $outdir/iccpp_dict.vim w]
    # initialize details and opts dicts
    puts $f "let iccpp_dict = {}"
    foreach param $iccpp_param_list {
        puts $f "let iccpp_dict\[\"$param\"\] = \"$::iccpp_com::params_map($param)\""
    }
    # dictionary format to include the default values.
    puts $f "\"\" reassign to a global variable \"\""
    puts $f "let g:TclComplete#iccpp_dict = iccpp_dict"
    close $f
    echo "...iccpp_dict.vim file complete."

#-------------------------------------
#  icc2 app options
#-------------------------------------
    echo [dict_to_json $app_option_dict] > $outdir/app_options.json
    echo "...iccpp_dict.json file complete."
    
#-------------------------------------
#  techfile information
#-------------------------------------
    echo [list_to_json $techfile_types] > $outdir/techfile_types.json
    echo "...techfile_types.json file complete."
    echo [dict_of_lists_to_json $techfile_layer_dict] > $outdir/techfile_layer_dict.json
    echo "...techfile_layer_dict.json file complete."
    echo [dict_of_lists_to_json $techfile_attr_dict] > $outdir/techfile_attr_dict.json
    echo "...techfile_attr_dict.json file complete."
#----------------------------------------------------
# write out syntax highlighting commands
#----------------------------------------------------
    file mkdir "$outdir/syntax"
    set f [open "$outdir/syntax/tcl.vim" w]
    puts $f "\"syntax coloring for g_variables"
    puts $f "\"-------------------------------"
    puts $f "syntax match g_var /\\CG_\\w\\+/"
    puts $f "highlight link g_var title"

    puts $f "\"syntax coloring for keywords"
    puts $f "\"-------------------------------"
    foreach command $command_list  {
        if {$command in "foreach foreach_in_collection while"} {continue}
        puts $f "syn keyword tclcommand $command"
    }
    foreach proc_name $proc_list {
        puts $f "syn keyword tclproccommand $proc_name"
    }
    set attr_syntax_list {}
    dict for {class class_dict} $attribute_dict {
        foreach attr_name [dict keys $class_dict] {
            lappend attr_syntax_list $attr_name
        }
    }
    puts $f "\"syntax coloring for attributes"
    puts $f "\"-------------------------------"
    set attr_syntax_list [lsort -unique $attr_syntax_list]
    foreach attr_name $attr_syntax_list {
        puts $f "syn keyword tclexpand $attr_name"
    }

    echo "...syntax/tcl.vim file complete."
    close $f

echo "...done\n"
