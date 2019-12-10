#############################################
#### TclCompleteSynopsys.tcl
#############################################

# Author: Chris Heithoff
# Description:  Procs used with WriteTclCompleteFiles.tcl that
#               will work with Synopsys tools.
# Date of latest revision: 10-Dec-2019

# Bring the namespace into existence. (if not already)
namespace eval TclComplete {}

puts "Sourcing TclCompleteSynopsys.tcl"

#########################################################
# Run help on a command.  Return the command's description
#########################################################
proc TclComplete::get_description_from_help {cmd} {
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

#########################################################
# Run man on a command.  Return the command's description
#########################################################
proc TclComplete::get_description_from_man {cmd} {
    redirect -variable man_text {man $cmd}
    set man_lines [split $man_text "\n"]
    if {[regexp "No manual entry for" [lindex $man_lines 0]]} {
        return ""
    }

    # The description of the command should be in the line after the NAME line
    # Example:
    # NAME
    #        puts - Write to a channel
    coroutine next_man_line TclComplete::next_element_in_list $man_lines
    TclComplete::advance_coroutine_to next_man_line "NAME*"
    set line [next_man_line]
    set description [lindex [split $line "-"] 1]
    return "#$description"
}

#####################################################
# Run help -v on a command and then parse the options
#####################################################
proc TclComplete::get_options_from_help {cmd} {
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
                # Check for synonym
                if {[regexp -nocase {synonym for '([^']*)'} $line -> synonym]} {
                    set cmd $synonym
                } elseif {$cmd_name == $cmd} {
                    set looking_for_command 0
                    set looking_for_options 1
                    continue
                }
                
            }
        } elseif {$looking_for_options} {
            # Now get the command options which start with a dash.
            #  They might be surrounded by brackets.
            #  The option is first, then the details, surrounded by parentheses.
            if {[regexp {^\s*\[?(-[a-zA-Z0-9_]+)[^(]*(.*$)} $line -> opt detail] } {
                set detail [regsub -all {"} $detail {\"}]
                #" (comment to correct Vim syntax coloring)
                dict set result $opt $detail
            } 

            # Exit loop if there is a # sign, which indicates a second command
            # is getting listed now. (but also not including a dash)
            if {[regexp {\s*[[:alpha:]][[:alnum:]_]*\s+# } $line]} {
                break
            }
        }
    }
    return $result
}

#####################################################
# Run "man <command>".  Parse and return the options.
#####################################################
proc TclComplete::get_options_from_man {cmd} {
    set option_list {}
    redirect -variable man_text {man $cmd}
    set man_lines [split $man_text "\n"]
    if {[regexp "No manual entry for" [lindex $man_lines 0]]} {
        return ""
    }

    # Options for builtin Tcl commands can be found in at least two places
    #  1) In the SYNOPSIS section
    # Example:
    #     SYNOPSIS
    #            puts ?-nonewline? ?channelId? string
    #  2) In the DESCRIPTION section
    #  Example for lsort:
    #   -ascii Use  string  comparison  with Unicode code-point collation order
    #          (the name is for backward-compatibility reasons.)  This  is  the
    #          default.
    #
    #  3) ...or some man pages (like add_power_state) have a SYNTAX section instead
    #     Example:
    #       SYNTAX
    #          status add_power_state
    #                 [-supply ]
    #                 object_name
    coroutine next_man_line TclComplete::next_element_in_list $man_lines
    set line [next_man_line]
    
    while {[command_exists next_man_line] } {
        set line [next_man_line]
        if {$line eq "SYNOPSIS"} {
            # Find SYNOPSIS options here and return from the proc early.
            #  Expect a few Tcl builtin commands here.
            set line [next_man_line]
            set matches [regexp -all -inline {\?-[[:alpha:]]\w*} $line]
            set matches [lmap match $matches {string trim $match "?"}]
            set matches [lminus -- $matches {-option}]
            if {[llength $matches]>0} {
                foreach match $matches {
                    lappend option_list $match
                }
                return [lsort $option_list]
            }
        } elseif {$line eq "SYNTAX"} {
            # Parse lines in the SYNTAX section.
            while {[command_exists next_man_line]} {
                set line [next_man_line]
                set matches [regexp -all -inline {[-][[:alpha:]]\w*} $line]
                foreach match $matches {
                    lappend option_list $match
                } 
                if {[string is upper $line]} {
                    # The next section is indicated by an ALL_CAPS line
                    return [lsort $option_list]
                }
            }
        } elseif {$line eq "DESCRIPTION"} {
            # Parse lines in the DESCRIPTION section.
            while {[command_exists next_man_line]} {
                set line [next_man_line]
                # I wanted to use a [lindex $line 0] to get a first word, but some of
                # the lines of man page text are not friendly to list commands.  
                set line [string trim $line]
                if {[regexp {^[-][[:alpha:]]\w+} $line match]} {
                    lappend option_list $match
                } elseif {$line eq "EXAMPLES"} {
                    return [lsort -u $option_list]
                }
            }
        }
    }

    # In case we never returned inside in the while loop but exhausted the coroutine.
    return [lsort -u $option_list]
}

#####################################################
# Run "man <app_option>".  Parse and return the values
#####################################################
proc TclComplete::get_app_option_from_man_page {app_option} {
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
            set TYPE [string trim $line]
            set TYPE_flag 0
        } elseif {$DEFAULT_flag==1} {
            set DEFAULT [string trim $line]
            # change double quotes in text to single to make json happpier later
            set DEFAULT [regsub -all "\"" $DEFAULT {'}]
            set DEFAULT_flag 0
            break
        }
    }
    if {$TYPE!=""} {
        return "$TYPE ($DEFAULT)"
    } else {
        return "unknown type"
    }
}


proc TclComplete::get_synopsys_descriptions {commands} {
    # Return a dictionary of command descriptions
    #   Key = command name
    #   Value = desciption of the command.
    set desc_dict [dict create]
    foreach cmd $commands {
        set description [TclComplete::get_description_from_help $cmd]
        if {$description eq "# Builtin"} {
            set description [TclComplete::get_description_from_man $cmd]
        }
        dict set desc_dict $cmd $description
    }
    echo " ...\$desc_dict built (Synopsys)"
    return $desc_dict
}
