#!/usr/intel/pkgs/tcl-tk/8.6.8/bin/tclsh

#############################################################
# Super version of info commands that also goes into namespaces
#############################################################
proc get_all_sorted_commands {} {
    set commands  [lsort -nocase [info commands]]

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
