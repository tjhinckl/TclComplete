#############################################
#### create_tcl_omnicomplete_files.tcl ######
#############################################

# Author: Chris Heithoff
# Description:  Source this from the icc2_shell (or dc or pt?) to 
#               create a file that can be used for tcl omnicompletion
#               in Vim.
# Date of latest revision: 10-July-2018

#---------------------------------------#
#           JSON procs                  #
#---------------------------------------#
# Return a json string for a Tcl list
proc list_to_json {list} {
    set indent "    "
    set result "\[\n"
    foreach item $list {
        append result "${indent}\"${item}\",\n"
    }
    set result [remove_final_comma $result]
    append result "]"
    return $result
}

# Return a json string for a Tcl dict
proc dict_to_json {dict} {
    set indent "    "
    set result "{\n"
    foreach key [lsort [dict keys $dict]] {
        set value [dict get $dict $key]
        append result "${indent}\"${key}\":\"${value}\",\n"
    }
    set result [remove_final_comma $result]
    append result "}"
    return $result
}

# Return a json string for a Tcl dictionary of lists
proc dict_of_lists_to_json {dict_of_lists} {
    set indent "    "
    set result "{\n"
    foreach key [lsort [dict keys $dict_of_lists]] {
        append result "${indent}\"${key}\":\n"
        append result "${indent}${indent}\[\n"
        foreach value [lsort [dict get $dict_of_lists $key]] {
            append result "${indent}${indent}\"${value}\",\n"
        }
        set result [remove_final_comma $result]
        append result "${indent}${indent}\],\n"
    }
    set result [remove_final_comma $result]
    append result "}"
    return $result
}
        
# Return a json string for a Tcl dictionary of dictionaries
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

##############################
# Like shell mkdir
##############################
proc mkdir_fresh {dir} {
    if {[file exists $dir]} {
        echo "Deleting previous $dir"
        file delete -force $dir
    }
    file mkdir $dir
}

        
#########################################################
# Run help on a command.  Return the command's description
#########################################################
proc get_description_from_help {cmd} {
    set result ""
    redirect -variable help_text {help $cmd}
    # Look for <cmdname>     # Description of the command
    foreach line [split $help_text "\n"] {
        if {[regexp {^\s*(\S+)\s+(#.*$)} $line -> cmd_name description]} {
            if {$cmd_name == $cmd} {
                set result [regsub -all {"} $description {\"}]
                # " 
            }
        }
    }
    return $result 
}


#####################################################
# Run help -v on a command and then parse the options
#####################################################
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
                    set looking_for_options 1
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

#####################################################
# Run "man <command>".  Parse and return the options.
#####################################################
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

#####################################################
# Run "man <app_option>".  Parse and return the values
#####################################################
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

###########################
# Main script starts here.
###########################
# Form a list of all commands, including those inside namespaces.
#  Most of the code here is sort in a particular order
echo "------------------------------------------------"
echo "---TclComplete:  forming the list of all commands"
proc get_all_sorted_commands {} {
    set commands  [lsort -nocase [info command]]

    # Pull out any commands starting with _underscore (put them at the end)
    set _commands  [lsearch -all -inline $commands _*]
    set commands   [lsearch -all -inline -not $commands _*]

    # Some commands tried to be namespaced with single colons. They show
    # up with [info command] because it's a fake namespace.
    set :commands  [lsearch -all -inline $commands *:*]
    set commands   [lsearch -all -inline -not $commands *:*]
    
    # Remove the . command.  Who needs autocomplete for a dot?
    set commands   [lsearch -all -inline -not $commands .]

    # Put the namespaced commands into their own lists so that they 
    # can be put at the end of the all_command_list later.
    set ns_cmds1 {}
    set ns_cmds2 {}

    # Search through namespaces for more commands with [info command <namespace>*]
    set global_namespaces [lsort -nocase [namespace children]]
    foreach gn $global_namespaces {
        # Get the cmds inside each global namespace, but without the leading :: colons.
        set cmds1 [lsort -nocase [info command ${gn}::*]]
        set cmds1 [lmap x $cmds1 {string trim $x "::"}]
        set ns_cmds1 [concat $ns_cmds1 $cmds1]

        # Go down one more level in the namespaces
        set hier_namespaces [lsort -nocase [namespace children $gn]]
        foreach hn $hier_namespaces {
            set cmds2 [lsort -nocase [info command ${hn}::*]]
            set cmds2 [lmap x $cmds2 {string trim $x "::"}]
            set ns_cmds2 [concat $ns_cmds2 $cmds2]
        }
    }
    set all_command_list [concat $commands $ns_cmds1 $ns_cmds2 ${_commands} ${:commands}]
    return $all_command_list
}
    
set all_command_list [get_all_sorted_commands]

## Fill up the description dictionary.
#   Key = command name
#   Value = desciption of the command.
set desc_dict [dict create]
foreach cmd $all_command_list {
    set description [get_description_from_help $cmd]
    dict set desc_dict $cmd $description
}
echo " ...\$desc_dict built"

######################################################################
# Now that we have all the commands, use the help/man commands to 
# get the options for each command and the details of each option.
######################################################################
echo "---TclComplete....building command options"
set opt_dict     [dict create]
set details_dict [dict create]

foreach cmd $all_command_list {
    # Initialize the dictionaries.   
    #   opt_dict:  key=cmd, value=list of options
    #   details_dict:  key1=cmd, key2=option, value=detail of the option.
    dict set opt_dict     $cmd {}
    dict set details_dict $cmd [dict create]

    # Fill up options for namespace ensemble subcommands first.
    #   (not common.  stuff like 'dict' and 'string')
    if {[namespace ensemble exists $cmd]} {
        set map_keys    [dict keys [namespace ensemble configure $cmd -map]]
        set subcommands [namespace ensemble configure $cmd -subcommands]
        set ensemble_options [lsort -u [concat $map_keys $subcommands]]
        if {[llength $ensemble_options]} {
            dict set opt_dict $cmd $ensemble_options
        }
    }

    # Use either the 'help -v' or 'man' commands to get command options.
    if {[llength [set help_dict [get_options_from_help $cmd]]]>0} {
        dict for {opt_name details} $help_dict {
            dict lappend opt_dict $cmd $opt_name
            dict set details_dict $cmd $opt_name $details
        }
    } else {
        foreach opt_name [get_options_from_man $cmd] {
            dict lappend opt_dict $cmd $opt_name
        }
    }
}
echo "...found options for all commands."

    
 
##########################################################################
# Special cases.  Some of these look like namespace ensemble, but are not.
##########################################################################
# Any math function can be used in expr
set func_list [ lsort -u [info function] ]
dict set opt_dict "expr" $func_list
echo "...\$func_list built"

# info options
dict set opt_dict "info"  [concat [dict get $opt_dict "info"] [lsort "args body class cmdcount commands complete coroutine default errorstack exists frame functions globals hostname level library loaded locals nameofexecutable object patchlevel procs script sharelibextension tclversion vars"]]

# after options
dict set opt_dict "after" [list cancel idle info]

# interp options
dict set opt_dict "interp" [list alias aliases bgerror cancel create debug delete eval exists hide hidden invokehidden issafe limit marktrusted recursionlimit share slaves target transfer]

# encoding options
dict set opt_dict "encoding" [list convertfrom convertto dirs names system]
set encoding_names [lsort [encoding names]]
dict set opt_dict "encoding convertfrom" $encoding_names
dict set opt_dict "encoding convertto"   $encoding_names
dict set opt_dict "encoding system"      $encoding_names

# zlib options
dict set opt_dict "zlib" [list adler32 compress crc32 decompress deflate gunzip gzip inflate push stream]
dict set opt_dict "zlib gunzip" [list -headerVar]
dict set opt_dict "zlib gzip"   [list -level -header]
dict set opt_dict "zlib -headerVar" [list comment crc filename os size time type]
dict set opt_dict "zlib -header"    [list comment crc filename os size time type]
dict set opt_dict "zlib stream" [list compress decompress deflate gunzip gzip inflate]
dict set opt_dict "zlib push"   [list compress decompress deflate gunzip gzip inflate]

# package options
dict set opt_dict "package" [list forget ifneeded names prefer present provide require unknown vcompare versions vsatisfies -exact]


# STUFF FOR OBJECT ORIENTED TCL WITH THE OO PACKAGE
if {[namespace exists "oo"]} {
    dict set opt_dict "oo::class" [list create new]
    foreach oo_cmd {oo::define oo::objdefine} {
        set subcommands [lsort [info commands ${oo_cmd}::*]]
        set subcommands [lmap cmd $subcommands {namespace tail $cmd}]
        dict set opt_dict $oo_cmd $subcommands
    }
    dict set opt_dict "info class"  [list call constructor definition destructor filters forward instances methodtype mixins subclasses superclasses variables]
    dict set opt_dict "info object" [list call class definition filters forward isa methods methodtype mixins namespace variables vars]
    lappend all_command_list [list self my]
    dict set opt_dict "self" [list call caller class filter method namespace next object target]
}

# "namespace ensemble" subcommands and options
dict set opt_dict "namespace ensemble" [list create configure exists -command -map -namespace -parameters -prefixes -subcommands -unknown]
    
# Offer valid type names for the argument following "string is"
dict set opt_dict   "string is" [list alnum alpha ascii boolean control digit double entier false graph integer list lower print punct space true upper wideinteger wordchar xdigit]
dict set details_dict  "string is" alnum       "Any Unicode alphabet or digit character."
dict set details_dict  "string is" alpha       "Any Unicode alphabet character."
dict set details_dict  "string is" ascii       "Any  character  with a value less than \u0080."
dict set details_dict  "string is" boolean     "Any of the forms allowed to Tcl_GetBoolean."
dict set details_dict  "string is" control     "Any Unicode control character."
dict set details_dict  "string is" digit       "Any  Unicode  digit  character. "
dict set details_dict  "string is" double      "Any  of  the  valid  forms for a double in Tcl."
dict set details_dict  "string is" entier      "Any of the valid string formats for an integer value of arbitrary size in Tcl."
dict set details_dict  "string is" false       "Any of the forms allowed to Tcl_GetBoolean where the value is false."
dict set details_dict  "string is" graph       "Any Unicode printing character, except space."
dict set details_dict  "string is" integer     "Any of the valid string formats for a 32-bit integer value  in Tcl."
dict set details_dict  "string is" list        "Any proper list structure."
dict set details_dict  "string is" lower       "Any Unicode lower case alphabet character."
dict set details_dict  "string is" print       "Any Unicode printing character, including space."
dict set details_dict  "string is" punct       "Any Unicode punctuation character."
dict set details_dict  "string is" space       "Any  Unicode  whitespace  character."
dict set details_dict  "string is" true        "Any of the forms allowed to Tcl_GetBoolean where the value is true."
dict set details_dict  "string is" upper       "Any  upper  case  alphabet  character in the Unicode character set."
dict set details_dict  "string is" wideinteger "Any of the valid forms for a wide integer in  Tcl."
dict set details_dict  "string is" wordchar    "Any  Unicode  word  character.  "
dict set details_dict  "string is" xdigit      "Any hexadecimal digit character (0-9A-Fa-f)."

# Format special characters (define for format and scan commands)
dict set opt_dict  "format" "%d %s %c %u %x %X %o %b %f %e %E %g %G"
dict set details_dict "format" "%d" "Signed decimal"
dict set details_dict "format" "%s" "String"
dict set details_dict "format" "%c" "Unicode character"
dict set details_dict "format" "%u" "Unsigned decimal"
dict set details_dict "format" "%x" "Lower case hex"
dict set details_dict "format" "%X" "Upper case hex"
dict set details_dict "format" "%o" "Octal"
dict set details_dict "format" "%b" "Binary"
dict set details_dict "format" "%f" "Floating point (default precision=6)"
dict set details_dict "format" "%e" "Scientific notication x.yyye+zz"
dict set details_dict "format" "%E" "Scientific notication x.yyyE+zz"
dict set details_dict "format" "%g" "%f or %e, based on precision"
dict set details_dict "format" "%G" "%f or %E, based on precision"
dict set opt_dict "scan" [dict get $opt_dict "format"]
dict set details_dict "scan" [dict get $details_dict "format"]
echo "...completed options for special cases in the opt_dict"


###########################################################
# Form a list of application options (and a dictionary too)
###########################################################
set app_option_dict [dict create]
if {[info commands get_app_options] != ""} {
    set app_option_list [lsort -u [get_app_options]]
} else {
    set app_option_list {}
}
foreach app_option $app_option_list {
    dict set app_option_dict $app_option [get_app_option_from_man_page $app_option]
}

#################################################################
# Make a package list for 'package require', 'package forget, etc
#################################################################
set package_list [lsort -u [package names]]

####################################################################
# ICCPP parameters (this will be empty if ::iccpp_com doesn't exist)
####################################################################
set iccpp_param_list [lsort [array names ::iccpp_com::params_map]]
set iccpp_param_dict [array get   ::iccpp_com::params_map]

#####################
# app_vars
#####################
set app_var_list [lsort [get_app_var -list *]]

#########################
# regexp character classes
#########################
set regexp_char_classes [list :alpha: :upper: :lower: :digit: :xdigit: :alnum: :blank: :space: :punct: :graph: :cntrl: ]

###############################################################################
# G_variables.  rdt G_var names are stored in the secret ::GLOBAL_VAR::global_var
# array.  The array name will also include comma separated keywords like history
# and subst and constant.
###############################################################################
set Gvar_list {}
set Gvar_array_list {}
foreach g_var [lsort [info var G_*]] {
    if [array exists $g_var] {
        lappend Gvar_list "${g_var}("
        foreach name [lsort [array names $g_var]] {
            lappend Gvar_array_list "${g_var}($name)"
        }
    } else {
        lappend Gvar_list $g_var
    }
}
# Put the complete array names at the end of the list.  This is handy for the popup menu.
set Gvar_list [concat $Gvar_list $Gvar_array_list]

######################################################################
# Form a nested dictionary of attributes of object classes.
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
set techfile_types {}
set techfile_layer_dict [dict create]
set techfile_attr_dict  [dict create]
if {[info commands ::tech::read_techfile_info] != ""} {
    # This command creates the ::techfile_info array
    ::tech::read_techfile_info
    foreach name [lsort [array names ::techfile_info]] {
        lassign [split $name ":"] Type Layer
        if {$Type ni $techfile_types} {
            lappend techfile_types $Type
        }
        dict lappend techfile_layer_dict $Type $Layer
        dict set techfile_attr_dict $name [dict keys $::techfile_info($name)]
    }
}
################################################################################
### Now  write out the data structures in JSON format!
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
if [info exists ::env(TOOL_CFG)] {
    puts $log "    based on: $::env(TOOL_CFG)"
}
close $log 

# 2) Write data structures out in JSON format.
#-------------------------------------
#  All the commands in a JSON list.
#-------------------------------------
    echo [list_to_json $all_command_list] > $outdir/commands.json
    echo "...commands.json file complete."

#-------------------------------------
#  All the packages in a JSON list.
#-------------------------------------
    echo [list_to_json $package_list] > $outdir/packages.json
    echo "...packages.json file complete."
#-----------------------------------------
# Command options in a JSON dict of lists.
#   key = command name
#   value = ordered list of options
#-----------------------------------------
    echo [dict_of_lists_to_json $opt_dict] > $outdir/options.json
    echo "...options.json file complete."

#-----------------------------------------
# Command option details in a JSON dictionary of dictionaries
#   key = command name
#   value = dictionary with key=option and value=details
#-----------------------------------------
    echo [dict_of_dicts_to_json $details_dict] > $outdir/details.json
    echo "...details.json file complete."

#-----------------------------------------
# Command descriptions in a JSON dictionary
#   key = command name
#   value = command description
#-----------------------------------------
    echo [dict_to_json $desc_dict] > $outdir/descriptions.json
    echo "...descriptions.json file complete."

#----------------------------------------------------
# Write out aliases as Vim insert mode abbreviations
#----------------------------------------------------
    set f   [open $outdir/aliases.vim w]
    puts $f "iabbrev fic foreach_in_collection"
    puts $f "iabbrev ga  get_attribute"
    puts $f "iabbrev cs  change_selection"
    puts $f "iabbrev gs  get_selection"
    
    close $f
    echo "...aliases.vim file complete."

#----------------------------------------------------
# Write out attributes as a big fat JSON dict of dicts.
#----------------------------------------------------
    echo [dict_of_dicts_to_json $attribute_dict] > $outdir/attributes.json
    echo "...attributes.json file complete."

#-------------------------------------
#  G variables which already exists in the session.
#-------------------------------------
    echo [list_to_json $Gvar_list] > $outdir/g_vars.json
    echo "...g_vars.json file complete."

    echo [list_to_json $Gvar_array_list] > $outdir/g_var_arrays.json
    echo "...g_var_arrays.json file complete."
    
#-------------------------------------
#  iccpp parameters in a JSON ordered list
#-------------------------------------
    echo [list_to_json $iccpp_param_list] > $outdir/iccpp.json
    echo "...iccpp.json file complete."
    echo [dict_to_json $iccpp_param_dict] > $outdir/iccpp_dict.json
    echo "...iccpp_dict.json file complete."

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

#-------------------------------------
#  existing designs in your block
#-------------------------------------
    echo [list_to_json [lsort [get_attribute [get_designs -quiet] name]]] > $outdir/designs.json
    echo "...designs.json file complete."
    
#-------------------------------------
#  app_vars
#-------------------------------------
    echo [list_to_json $app_var_list] > $outdir/app_vars.json
    echo "...app_vars.json file complete."
    
#-------------------------------------
#  regexp character classes
#-------------------------------------
    echo [list_to_json $regexp_char_classes] > $outdir/regexp_char_classes.json
    echo "...regexp_char_classes.json file complete."
#-------------------------------------
#  environment variables
#-------------------------------------
    
    echo [dict_to_json [regsub -all {"} [array get ::env] {\"}]]  > $outdir/environment.json
    # " 
    echo "...environment.json file complete."
    
#----------------------------------------------------
# write out syntax highlighting commands
#----------------------------------------------------
    file mkdir "$outdir/syntax"
    set f [open "$outdir/syntax/tcl.vim" w]
    puts $f "\"syntax coloring for g_variables"
    puts $f "\"-------------------------------"
    puts $f "syntax match g_var /\\<\\CG_\\w\\+/"
    puts $f "highlight link g_var title"

    puts $f "\"syntax coloring for procs and commands"
    puts $f "\"--------------------------------------"

    foreach cmd $all_command_list {
        if {[info procs $cmd]!=""} {
            puts $f "syn keyword tclproccommand $cmd"
        } else {
            puts $f "syn keyword tclcommand $cmd"
        }
    }

    puts $f "\"syntax coloring for attributes"
    puts $f "\"-------------------------------"
    set attr_syntax_list {}
    dict for {class class_dict} $attribute_dict {
        foreach attr_name [dict keys $class_dict] {
            lappend attr_syntax_list $attr_name
        }
    }
    set attr_syntax_list [lsort -unique $attr_syntax_list]
    foreach attr_name $attr_syntax_list {
        puts $f "syn keyword tclexpand $attr_name"
    }

    echo "...syntax/tcl.vim file complete."
    close $f


# Clean up time.  Give Tcl some memory back.
unset all_command_list
unset app_option_list
unset app_var_list
unset details_dict
unset desc_dict
unset opt_dict
unset app_option_dict
unset iccpp_param_dict
unset techfile_attr_dict
unset techfile_layer_dict

echo "...done\n"
