#!/usr/intel/pkgs/tcl-tk/8.6.8/bin/tclsh

# Bring the namespace into existence.
namespace eval TclComplete {}

set TclComplete::script_dir [file dirname [file normalize [info script]]]

#############################################################
# Super version of [info commands] that also goes into namespaces
#############################################################
proc TclComplete::get_all_sorted_commands {} {
    
    # Run [info commands] at global namespace to avoid TclComplete::* 
    #  commands from showing up as global commands.
    namespace eval :: {
        set ::TclComplete::commands  [lsort -nocase [info commands]]
    }

    # Pull out any commands starting with _underscore (put them at the end)
    set _commands  [lsearch -all -inline $::TclComplete::commands _*]
    set commands   [lsearch -all -inline -not $::TclComplete::commands _*]

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
    set global_namespaces [lsort -nocase [namespace children ::]]
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

    # Put them in the desired sequence.
    set all_command_list [concat $commands $ns_cmds1 $ns_cmds2 ${_commands} ${:commands}]

    # One last thing.  Remove any commands with percent sign in the name
    #  (one example is tcl::clock::formatproc'%m_%d_%H_%M'c )
    set all_command_list [lsearch -all -inline -not $all_command_list *%*]

    return $all_command_list
}

#---------------------------------------#
#           JSON procs                  #
#---------------------------------------#
# Return a json string for a Tcl list
proc TclComplete::list_to_json {list} {
    set indent "    "
    set result "\[\n"
    foreach item $list {
        append result "${indent}\"${item}\",\n"
    }
    set result [TclComplete::remove_final_comma $result]
    append result "]"
    return $result
}

# Return a json string for a Tcl dict
proc TclComplete::dict_to_json {dict} {
    set indent "    "
    set result "{\n"
    foreach key [lsort [dict keys $dict]] {
        set value [dict get $dict $key]
        append result "${indent}\"${key}\":\"${value}\",\n"
    }
    set result [TclComplete::remove_final_comma $result]
    append result "}"
    return $result
}

# Return a json string for a Tcl dictionary of lists
proc TclComplete::dict_of_lists_to_json {dict_of_lists args} {
    set indent "    "
    set result "{\n"
    foreach key [lsort [dict keys $dict_of_lists]] {
        append result "${indent}\"${key}\":\n"
        append result "${indent}${indent}\[\n"
        if {"no_sort" in $args} {
            set key_list [dict get $dict_of_lists $key]
        } else {
            set key_list [lsort [dict get $dict_of_lists $key]]
        }
        foreach value $key_list {
            append result "${indent}${indent}\"${value}\",\n"
        }
        set result [TclComplete::remove_final_comma $result]
        append result "${indent}${indent}\],\n"
    }
    set result [TclComplete::remove_final_comma $result]
    append result "}"
    return $result
}

# Return a json string for a Tcl dictionary of dictionaries
proc TclComplete::dict_of_dicts_to_json {dict_of_dicts} {
    set indent "    "
    set result "{\n"
    foreach key [lsort [dict keys $dict_of_dicts]] {
        append result "${indent}\"${key}\":\n"
        append result "${indent}${indent}\{\n"
        dict for {instance_name ref_name} [dict get $dict_of_dicts $key] {
            append result "${indent}${indent}\"${instance_name}\":\"${ref_name}\",\n"
        }
        set result [TclComplete::remove_final_comma $result]
        append result "${indent}${indent}\},\n"
    }
    set result [TclComplete::remove_final_comma $result]
    append result "}"
    return $result
}

proc TclComplete::write_json {name content} {
    set fh [open $name.json w]
    puts $fh $content
    close $fh
    puts "...[file tail $name].json file complete."
}

##########################################################################
# Helper proc to remove a final comma from a json list/dictionary
#   [               [
#    d,              d,
#    e,       ==>    e,
#    f,              f
#   ]               ]
##########################################################################
proc TclComplete::remove_final_comma {json_string} {
    set json_string [string trimright $json_string "\n,"]
    return "$json_string\n"
}

##############################
# Like shell mkdir
##############################
proc TclComplete::mkdir_fresh {dir} {
    if {[file exists $dir]} {
        puts "Deleting previous $dir"
        file delete -force $dir
    }
    file mkdir $dir
}


################################################
## Coroutine stuff #############################
################################################
# Use this proc as the command in a coroutine definition.
proc TclComplete::next_element_in_list {list} {
    yield
    foreach element $list {
        yield $element
    }
}

# Use this proc to advance an existing coroutine until the value matches a pattern
proc TclComplete::advance_coroutine_to {coroutine_name match_pattern } {
    while {[TclComplete::cmd_exists $coroutine_name] } {
        set next_item [$coroutine_name]
        if {[string match $match_pattern $next_item]} {
            return $next_item
            break
        }
    }
    return ""
}

#############################################################
# Some commands have subcommands that are not revealed by 
# namespace ensembles or help pages or man pages, but are 
# revealed in the error message when trying to use a bogus subcommand
###################################################################
proc TclComplete::get_subcommands {cmd} {
    ## Parse this message to return {this that other}
    #Error: unknown or ambiguous subcommand "bogus_subcommand": must be this, that or other"
	#    Use error_info for more info. (CMD-013)
    catch {redirect -variable msg {$cmd bogus_subcommand}}
    set msg [lindex [split $msg "\n"] 0]
    set msg [regsub {^Error: .* must be } $msg ""]
    set msg [regsub { or } $msg ""]
    set msg [regsub -all {\s+} $msg ""]
    set error_list [split $msg " ,"]
    return [lsort $error_list]
}

############################
# gratuitous helper proc 
############################
proc TclComplete::cmd_exists {cmd} {
    if {[llength [info command $cmd]]>0} {
        return 1
    } else {
        return 0
    }
}


#######################################################
# Return a command dict for namespace ensemble commands
#   key = cmd.   val1 = namespace subcommand  val2 = description of subcommand (blank)
#######################################################
proc TclComplete::get_namespace_cmd_dict {commands} {
    set cmd_dict [dict create]

    foreach cmd $commands {
        if {[namespace ensemble exists $cmd]} {
            set map_keys    [dict keys [namespace ensemble configure $cmd -map]]
            set subcommands [namespace ensemble configure $cmd -subcommands]
            set ensemble_options [lsort -u [concat $map_keys $subcommands]]
            foreach opt_name $ensemble_options {
                dict set cmd_dict $cmd $opt_name {}
            }
        }
    }
    return $cmd_dict
}

###############################################################################
# Return a command dictionary for standard Tcl commands
#  but with hardcoded values instead of derived.
#  Note:  The TclComplete::get_subcommands proc can derive subcommands for
#        a command like 'info' through generating an intentional error 
#        message parsing the result, but needs the Synopsys 'redirect' command.
###############################################################################
proc TclComplete::get_hardcoded_cmd_dict {} {
    # Return a nested dict with:
    #  key1 = command
    #    key2 = option
    #      value = description of option
    set cmd_dict [dict create]

    # Start with a smaller dictionary.
    #    key = command   value = list of options
    set hardcoded_opts [dict create]
    dict set hardcoded_opts info      "args body class cmdcount commands complete coroutine default errorstack exists frame functions globals hostname level library loaded locals nameofexecutable object patchlevel procs script sharedlibextension tclversion vars"
    dict set hardcoded_opts after     "cancel idle info"
    dict set hardcoded_opts interp    "alias aliases bgerror cancel create debug delete eval exists expose hidden hide invokehidden issafe limit marktrusted recursionlimit share slaves target transfer"
    dict set hardcoded_opts package   "forget ifneeded names prefer present provide require unknown vcompare versions vsatisfies -exact"
    # ----------------------------------------------------------------
    dict set hardcoded_opts encoding  "convertfrom convertto dirs names system"
    set encoding_names [lsort [encoding names]]
    dict set hardcoded_opts "encoding convertfrom" $encoding_names
    dict set hardcoded_opts "encoding convertto"   $encoding_names
    dict set hardcoded_opts "encoding system"      $encoding_names
    # ----------------------------------------------------------------
    dict set hardcoded_opts zlib               "adler32 compress crc32 decompress deflate gunzip gzip inflate push stream"
    dict set hardcoded_opts "zlib gunzip"      "-headerVar"
    dict set hardcoded_opts "zlib gzip"        "-level -header"
    dict set hardcoded_opts "zlib -headerVar"  "comment crc filename os size time type"
    dict set hardcoded_opts "zlib -header"     "comment crc filename os size time type"
    dict set hardcoded_opts "zlib stream"      "compress decompress deflate gunzip gzip inflate"
    dict set hardcoded_opts "zlib push"        "compress decompress deflate gunzip gzip inflate"
    # ----------------------------------------------------------------
    dict set hardcoded_opts "namespace ensemble" "create configure exists -command -map -namespace -parameters -prefixes -subcommands -unknown"
    # ----------------------------------------------------------------
    dict set hardcoded_opts "trace" "add info remove variable vdelete vinfo"
    # ----------------------------------------------------------------
    if {[namespace exists "::oo"]} {
        dict set hardcoded_opts "oo::class"      "create new"
        dict set hardcoded_opts "oo::define"     "constructor deletemethod destructor export filter forward method mixin renamemethod self superclass unexport variable"
        dict set hardcoded_opts "oo::objdefine"  "constructor deletemethod destructor export filter forward method mixin renamemethod self superclass unexport variable"
        dict set hardcoded_opts "info class"     "call constructor definition destructor filters forward instances methodtype mixins subclasses superclasses variables"
        dict set hardcoded_opts "info object"    "call class definition filters forward isa methods methodtype mixins namespace variables vars"
        dict set hardcoded_opts "self"           "list call caller class filter method namespace next object target"
    }
    # ----------------------------------------------------------------
    if {[TclComplete::cmd_exists generator]} {
        dict set hardcoded_opts generator "all and any concat concatMap contains define destroy drop dropWhile exists filter finally foldl foldl1 foldli foldr foldri foreach from generate head init iterate last length map names next or product reduce repeat scanl spawn splitWhen sum tail take takeList takeWhile to yield zip zipWith"
    }


    # Expand the hardcoded options into the format required for the cmd_dict.
    #   (the final value is empty string)
    foreach {cmd opts} $hardcoded_opts {
        foreach opt $opts {
            dict set cmd_dict $cmd $opt {}
        }
    }

    # Hard coded values which included option descriptions.
    dict set cmd_dict  "string is" alnum       "Any Unicode alphabet or digit character."
    dict set cmd_dict  "string is" alpha       "Any Unicode alphabet character."
    dict set cmd_dict  "string is" ascii       "Any character with a value less than U+0080."
    dict set cmd_dict  "string is" boolean     "Any of the forms allowed to Tcl_GetBoolean."
    dict set cmd_dict  "string is" control     "Any Unicode control character."
    dict set cmd_dict  "string is" digit       "Any Unicode digit character. "
    dict set cmd_dict  "string is" double      "Any of the valid forms for a double in Tcl."
    dict set cmd_dict  "string is" entier      "Any of the valid string formats for an integer value of arbitrary size in Tcl."
    dict set cmd_dict  "string is" false       "Any of the forms allowed to Tcl_GetBoolean where the value is false."
    dict set cmd_dict  "string is" graph       "Any Unicode printing character, except space."
    dict set cmd_dict  "string is" integer     "Any of the valid string formats for a 32-bit integer value in Tcl."
    dict set cmd_dict  "string is" list        "Any proper list structure."
    dict set cmd_dict  "string is" lower       "Any Unicode lower case alphabet character."
    dict set cmd_dict  "string is" print       "Any Unicode printing character, including space."
    dict set cmd_dict  "string is" punct       "Any Unicode punctuation character."
    dict set cmd_dict  "string is" space       "Any Unicode whitespace character."
    dict set cmd_dict  "string is" true        "Any of the forms allowed to Tcl_GetBoolean where the value is true."
    dict set cmd_dict  "string is" upper       "Any upper case alphabet character in the Unicode character set."
    dict set cmd_dict  "string is" wideinteger "Any of the valid forms for a wide integer in  Tcl."
    dict set cmd_dict  "string is" wordchar    "Any  Unicode  word  character.  "
    dict set cmd_dict  "string is" xdigit      "Any hexadecimal digit character (0-9A-Fa-f)."
    dict set cmd_dict  "string is" easter      "egg"
    # ----------------------------------------------------------------
    dict set cmd_dict "format" "%d" "Signed decimal"
    dict set cmd_dict "format" "%s" "String"
    dict set cmd_dict "format" "%c" "Unicode character"
    dict set cmd_dict "format" "%u" "Unsigned decimal"
    dict set cmd_dict "format" "%x" "Lower case hex"
    dict set cmd_dict "format" "%X" "Upper case hex"
    dict set cmd_dict "format" "%o" "Octal"
    dict set cmd_dict "format" "%b" "Binary"
    dict set cmd_dict "format" "%f" "Floating point (default precision=6)"
    dict set cmd_dict "format" "%e" "Scientific notication x.yyye+zz"
    dict set cmd_dict "format" "%g" "%f or %e, based on precision"
    dict set cmd_dict "format" "%G" "%f or %E, based on precision"
    dict set cmd_dict "scan"   [dict get $cmd_dict format]
    # ----------------------------------------------------------------
    dict set cmd_dict "trace add"    "command"   "... name <rename|delete> commandPrefix"
    dict set cmd_dict "trace add"    "execution" "... name <enter|leave|enterstep|leavestep> commandPrefix"
    dict set cmd_dict "trace add"    "variable"  "... name <array|read|write|unset> commandPrefix"
    dict set cmd_dict "trace remove" "command"   "... name opList commandPrefix"
    dict set cmd_dict "trace remove" "execution" "... name opList commandPrefix"
    dict set cmd_dict "trace remove" "variable"  "... name opList commandPrefix"
    dict set cmd_dict "trace info"   "command"   "... name"
    dict set cmd_dict "trace info"   "execution" "... name"
    dict set cmd_dict "trace info"   "variable"  "... name"
    # ----------------------------------------------------------------
    dict set cmd_dict "lsort"        "-ascii"      "Use string comparison with Unicode code-point collation.  This is the default"
    dict set cmd_dict "lsort"        "-dictionary" "Embedded numbers compare as integers, not characters"
    dict set cmd_dict "lsort"        "-integer"    "Convert list elements to integers and use integer comparison"
    dict set cmd_dict "lsort"        "-real"       "Convert list elements to floating-point values and use floating comparison"
    dict set cmd_dict "lsort"        "-command"    "Use a command as a comparison command"
    dict set cmd_dict "lsort"        "-increasing" "Sort the list in increasing order.  This is the default"
    dict set cmd_dict "lsort"        "-decreasing" "Sort the list in decreasing order."
    dict set cmd_dict "lsort"        "-indices"    "Return a list of indices in sorted order instead of the values themselves"
    dict set cmd_dict "lsort"        "-index"      "Each of the elements must be a proper Tcl sublist.  Sort by index of sublist"
    dict set cmd_dict "lsort"        "-index"      "Each of the elements must be a proper Tcl sublist.  Sort by index of sublist"
    dict set cmd_dict "lsort"        "-nocase"     "Compare in a case-insensitive manner."
    dict set cmd_dict "lsort"        "-unique"     "Remove duplicate elements in list"
    # ----------------------------------------------------------------
    dict set cmd_dict "return"       "-code"       "ok, error, return, break, or continue"
    dict set cmd_dict "return"       "-errorcode"  "List of additional information about the error.  Only used with -code error"
    dict set cmd_dict "return"       "-errorinfo"  "Info is the initial stack trace.  Only used with -code error"
    dict set cmd_dict "return"       "-errorstack" "Initial error stack reachable through info errorstack."
    dict set cmd_dict "return"       "-level"      "Defines the number of levels up the stack at which the return code of a command should be. Default=1"
    dict set cmd_dict "return"       "-options"    "The value must be a valid dictionary"
    # ----------------------------------------------------------------
    dict set cmd_dict "lsearch"      "-exact"      "Pattern is compared for exact equality against each list element."
    dict set cmd_dict "lsearch"      "-glob"       "Pattern is a glob-style pattern."
    dict set cmd_dict "lsearch"      "-regexp"     "Pattern is treated as a regular expression."
    dict set cmd_dict "lsearch"      "-sorted"     "The list elements are already in sorted order and a more efficient search algorithm is used."
    dict set cmd_dict "lsearch"      "-all"        "The result is all matching indices or values."
    dict set cmd_dict "lsearch"      "-inline"     "The matching value is returned instead of its index"
    dict set cmd_dict "lsearch"      "-not"        "This negates the sense of the match."
    dict set cmd_dict "lsearch"      "-start"      "The list is searched starting a position index"
    dict set cmd_dict "lsearch"      "-index"      "Each of the elements must be a proper Tcl sublist.  Sort by index of sublist"
    dict set cmd_dict "lsearch"      "-index"      "Each of the elements must be a proper Tcl sublist.  Sort by index of sublist"
    dict set cmd_dict "lsearch"      "-nocase"     "Compare in a case-insensitive manner."
    dict set cmd_dict "lsearch"      "-unique"     "Remove duplicate elements in list"
    dict set cmd_dict "lsearch"      "-ascii"      "Comparison with -sorted option done as Unicode strings"
    dict set cmd_dict "lsearch"      "-dictionary" "Comparison with -sorted option done with embedded numbers treated as integers"
    dict set cmd_dict "lsearch"      "-integer"    "Comparison with -sorted option done with list elements as integers"
    dict set cmd_dict "lsearch"      "-real"       "Comparison with -sorted option done with list elements as floating point"
    dict set cmd_dict "lsearch"      "-nocase"     "Comparison with -sorted option done ignoring case"
    dict set cmd_dict "lsearch"      "-increasing" "Comparison with -sorted option done in increasing order."
    dict set cmd_dict "lsearch"      "-decreasing" "Comparison with -sorted option done in decreasing order."
    dict set cmd_dict "lsearch"      "-index"      "Search criteria looks for index value of sublists"
    dict set cmd_dict "lsearch"      "-subindices" "Used with -index, the result will be a complete path within overall list"
    # ----------------------------------------------------------------
    dict set cmd_dict "regexp"   "-about"       "Returns a list containing information about the regex.  Intended for debugging"
    dict set cmd_dict "regexp"   "-expanded"    "Enables use of the syntax where whitespace and comments are ignored."
    dict set cmd_dict "regexp"   "-indices"     "Changes what is stored in the subMatchVars."
    dict set cmd_dict "regexp"   "-line"        "Enables newline-sensitive matching."
    dict set cmd_dict "regexp"   "-linestop"    "Changes behavior of . to stop at newlines."
    dict set cmd_dict "regexp"   "-lineanchor"  "Changes behavior of ^ and $ to match beginning and end of lines."
    dict set cmd_dict "regexp"   "-nocase"      "Causes upper-case characters in string to be treated as lower case."
    dict set cmd_dict "regexp"   "-all"         "Causes the regex to be matched as many times as possible."
    dict set cmd_dict "regexp"   "-inline"      "Causes the command to return, as a list, the data otherwise placed in match variables" 
    dict set cmd_dict "regexp"   "-start"       "Specifies a character index offset into the string to start matching"
    # ----------------------------------------------------------------
    dict set cmd_dict "regsub"   "-all"         "All matches in string are substituted.  Not just first match"
    dict set cmd_dict "regsub"   "-expanded"    "Enables use of the syntax where whitespace and comments are ignored."
    dict set cmd_dict "regsub"   "-line"        "Enables newline-sensitive matching."
    dict set cmd_dict "regsub"   "-linestop"    "Changes behavior of . to stop at newlines."
    dict set cmd_dict "regsub"   "-lineanchor"  "Changes behavior of ^ and $ to match beginning and end of lines."
    dict set cmd_dict "regsub"   "-nocase"      "Causes upper-case characters in string to be treated as lower case."
    dict set cmd_dict "regsub"   "-start"       "Specifies a character index offset into the string to start matching"




    return $cmd_dict
}

#######################################################
# Convert a list into keys of a dict, but empty values
#######################################################
proc TclComplete::list2keys {list} {
    set d [dict create]
    foreach key $list {
        dict set d $key {}
    }
    return $d
}

#######################################################
# Write json files derived from the cmd_dict
#   1)  commands.json 
#   2)  options.json  
#   3)  details.json  
# NOTE:  The details.json file is a superset of the other two.
#        Only producing that one would be sufficient and I'm
#        planning to only do file #3 in the future.
#######################################################
proc TclComplete::write_json_from_cmd_dict {outdir cmd_dict} {
    # 1) Command list....the important thing here is to sort it in a way that is most 
    #       useful in an autocompletion pop-up menu.  Do it here instead of deferring 
    #       to the text editor. (this code is similar to TclComplete::get_all_sorted_commands)
    # Sort the cmd_list like this.
    set commands   [list]
    set commands_1 [list]
    set commands_2 [list]
    set commands_4 [list]
    set commands_6 [list]
    set _commands  [list]
    set .commands  [list]

    foreach cmd [lsort -nocase [dict keys $cmd_dict]] {
        if {[string index $cmd 0] == "_"} {
            lappend _commands $cmd
        } elseif {[string index $cmd 0] == "."} {
            lappend .commands $cmd
        } elseif {[string match TclComplete::* $cmd]} {
            # We don't need to include TclComplete procs for later, right?
            continue
        } else {
            # Count the colons 
            set num_colons [expr {[llength [split $cmd ":"]] - 1 }]
            if {$num_colons == 0} {
                lappend commands $cmd
            } elseif {$num_colons in {1 2 4 6}} {
                lappend commands_${num_colons} $cmd
            } 
        } 
    }

    # Put the commands in the preferred order.
    set commands "$commands $commands_1 $commands_2 $commands_4 $commands_6 ${_commands} ${.commands}"

    TclComplete::write_json $outdir/commands [TclComplete::list_to_json $commands]

    # 2) Options dict of lists  (key=command, values = list of options)
    set opt_dict [dict create]
    foreach cmd $commands {
        set opt_list [lsort [dict keys [dict get $cmd_dict $cmd]]]
        dict set opt_dict $cmd $opt_list
    }
    TclComplete::write_json $outdir/options [TclComplete::dict_of_lists_to_json $opt_dict]

    # 3) Details dict of dicts (key1=command, key2=option, value=option description
    TclComplete::write_json $outdir/details [TclComplete::dict_of_dicts_to_json $cmd_dict]

}

#######################################################
# Write a json file with the regex character classes
#######################################################
proc TclComplete::write_regex_char_class_json {outdir} {
    set regexp_char_classes [list :alpha: :upper: :lower: :digit: :xdigit: :alnum: :blank: :space: :punct: :graph: :cntrl: ]
    TclComplete::write_json $outdir/regexp_char_classes [TclComplete::list_to_json $regexp_char_classes]
}

#######################################################
# Write a json file with the packages available
#######################################################
proc TclComplete::write_packages_json {outdir} {
    catch {package require look_for_a_package_that_does_not_exist_so_package_names_returns_all_available_packages}
    set package_list [lsort -u [package names]]
    TclComplete::write_json $outdir/packages [TclComplete::list_to_json $package_list]
}

#######################################################
# Write a json file with the environment variables
#  key = variable name    value = variable value
#######################################################
proc TclComplete::write_environment_json {outdir} {
    # First get the names, used as key to the JSON dict.
    set env_vars [array names ::env]

    # Then get the values, but make it more JSON friendly by escaping quotes.
    set env_dict [dict create]
    foreach env_var $env_vars {
        set env_val [array get ::env $env_var]
        set env_val [regsub -all "\"" $env_val {\"}]
        dict set env_dict $env_var $env_val
    }

    TclComplete::write_json $outdir/environment [TclComplete::dict_to_json $env_dict]
}

##############################################
# Write a TclComplete log file
#############################################
proc TclComplete::write_log {outdir} {
    set log [open $outdir/WriteTclCompleteFiles.log w]
    puts $log "#######################################################"
    puts $log "### WriteTclCompleteFiles.log #########################"
    puts $log "#######################################################"
    puts $log " Generated by: $::env(USER)"
    puts $log "           at: [clock format [clock seconds] -format {%a %b %d %H:%M:%S %Y}]"
    puts $log "  tcl version: $::tcl_patchLevel"
    puts $log "  TclComplete::script_dir $::TclComplete::script_dir"
    set optional_vars {
        env(WARD)
        env(TOOL_CFG)
        synopsys_program_name
        tessent_shell_dir
    }
    foreach optional_var $optional_vars {
        if {[info exists ::${optional_var}]} {
            puts $log [format "%13s: %s" $optional_var [set ::${optional_var}]]
        }
    }
    close $log 
}


############################################
# Write a syntax/tcl.vim file in Vimscript 
############################################          
proc TclComplete::write_vim_tcl_syntax {outdir cmd_list} {
    file mkdir "$outdir/syntax"
    set f [open "$outdir/syntax/tcl.vim" w]

    puts $f "\"syntax coloring for procs and commands"
    puts $f "\"--------------------------------------"
    foreach cmd $cmd_list {
        if {[info procs $cmd]!=""} {
            puts $f "syn keyword tclproccommand $cmd"
        } else {
            puts $f "syn keyword tclcommand $cmd"
        }
    }

    if {[llength [info vars ::synopsys*]]>0} {
        puts $f ""
        puts $f "\" syntax highlighting for Synopsys object attributes."
        puts $f "\"-------------------------------"
        set attr_list [TclComplete::get_synopsys_attributes]
        foreach attr_name $attr_list {
            puts $f "syn keyword tclexpand $attr_name"
        }
    } 

    if {[llength [info commands setvar]]>0} {
        puts $f ""
        puts $f "\"syntax coloring for g_variables"
        puts $f "\"-------------------------------"
        puts $f "syntax match g_var /\\<\\CG_\\w\\+/"
        puts $f "highlight link g_var title"
    }

    puts "...syntax/tcl.vim file complete."
    close $f
}

###########################################################################
# If descriptions are missing from commands, then add args if they're a proc
###########################################################################
proc TclComplete::add_args_to_description_dict {description_dict} {
    # description_dict:
    #    key = command name
    #    value = description of command
    foreach cmd [dict keys $description_dict] {
        if {[dict get $description_dict $cmd] eq ""} {
            # Important to evaluate info proc at global namespace
            #   because we're stuck here in the TclComplete namespace
            if {[info proc ::${cmd}] eq "::${cmd}"} {
                set info_args [info args ::${cmd}]
                if {$info_args eq "args"} {
                    set description ""
                } else {
                    set description "# args = $info_args"
                }
                dict set description_dict $cmd $description
            }
        }
    }
    return $description_dict
}

#########################################
# Get all the variables which are arrays
#########################################
proc TclComplete::info_arrays {} {
    # This proc is in the TclComplete namespace, but we want to look at global arrays
    namespace eval :: {
        set all_var_names [info vars]

        foreach var_name $all_var_names {
            if {[array exists $var_name]} {
                lappend arrays $var_name
            }
        }
    }
    return [lsort -unique $::arrays]
}

#######################################################
# Write a json file for all arrays
#  key = name of array (ivar, env, etc)
#  values = keys for that array 
#######################################################
proc TclComplete::write_arrays_json {outdir} {
    # Run in the global namespace because this proc is in a different namespace
    # and [info vars] is namespace sensitive.
    namespace eval :: {
         foreach var_name [info vars] {
            if {[array exists $var_name]} {
                lappend TclComplete::array_vars ${var_name}
            }
        }
    }

    # Get the current values and set it all in the array_dict. 
    #   (Import to add :: before $array_var in the array get command)
    set array_dict [dict create]
    foreach array_var $TclComplete::array_vars {
        puts "::$array_var"
        foreach {name value} [array get ::$array_var] {
            # Flatten any nested lists to make it work bettern with JSON.
            set value [join [join $value]]

            # Escape double quotes in the value to make it work with JSON.
            set value [regsub -all "\"" $value {\"}]
            dict set array_dict $array_var $name $value
        }
    }

    TclComplete::write_json $outdir/arrays [TclComplete::dict_of_dicts_to_json $array_dict]
}

