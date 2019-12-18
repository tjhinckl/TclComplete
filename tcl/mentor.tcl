#############################################
#### mentor.tcl
#############################################

# Author: Chris Heithoff
# Description:  Procs used with WriteTclCompleteFilesMentor.tcl.
# Date of latest revision: 18-Dec-2019

# Bring the namespace into existence. (if not already)
namespace eval TclComplete {}


######################################################
# Get all the available commands listed in [help -all]
######################################################
proc TclComplete::mentor_get_help_commands {} {
    # "help -all" lists all the help-able commands, but 
    catch_output {help -all} -output help_std_out
    set lines [split $help_std_out "\n"]
    set commands {}
    foreach line $lines {
        # Skip unavailable commands
        if {[string match "*(...unavailable...)*" $line]} {
            continue
        }

        if {[llength $line] > 0} {
            lappend commands [lindex $line 0]
        }
    }
    return $commands
}

######################################################
# Run this before TclComplete::mentor_parse_help 
######################################################
proc TclComplete::mentor_prepare_string_for_parse {input_string} {
    # Make sure that braces are not butted against other grouping characters
    #   so that they are a proper Tcl list.
    set m1a "{"
    set m1b " {"
    set m2a "}"
    set m2b "} "

    # Put spaces around brackets so they will be parsed as their own tokens.
    set m3a {[}
    set m3b { [ }
    set m4a {]}
    set m4b { ] }
    set mapping [list $m1a $m1b $m2a $m2b $m3a $m3b $m4a $m4b]

    set new_string [string map $mapping $input_string]

    # standardize details whitespace
    set new_string [regsub -all {\s+} [string trim $new_string] { }]
    return $new_string
}

########################################################
# Return a command dictionary derived with Mentor's help 
########################################################
proc TclComplete::get_mentor_cmd_dict {} {
    set commands [TclComplete::mentor_get_help_commands]

    set cmd_dict [dict create]
    foreach cmd $commands {
        # Call [help $command] and save the string to $help
        if {[catch {
            catch_output "help $cmd" -output help
        } error]} {
            continue
        }

        set help [TclComplete::mentor_prepare_string_for_parse $help]

        set parsed_options [TclComplete::mentor_parse_help $help]
        dict set cmd_dict $cmd $parsed_options
    }
    return $cmd_dict
}

########################################################################################                   
# Parse the Mentor help string for a command and return a dictionary of command options.
########################################################################################                   
proc TclComplete::mentor_parse_help {section} {
    set size [llength $section]
    set options [dict create]

    # The help string will start with the command name, so start parsing on index 1.
    for {set i 1} {$i < $size} {incr i} {
        set token [lindex $section $i]
        # stop parsing when we reach the contexts token because details
        # options after that don't apply to the current command
        if {$token == "contexts:"} {
            return $options
        }
        
        # Keys to the options dictionary will be options starting with a dash.
        # The token after the option will be used as the dict value, if applicable.
        # Note that mutually exclusive options are grouped in the help string 
        # inside curlies, so that parse proc must recurse one level for those.
        if {[llength $token ] > 1} {
            set sub_options [TclComplete::mentor_parse_help $token]
            set options [dict merge $options $sub_options]
        } elseif {[string match -* $token]} {
            # Peek ahead to see if this option has enumerated values
            set next [lindex $section [expr {$i + 1}]]
            if {[llength $next] > 1 || [string match <* $next]} {
                dict set options $token $next
                # Increment i because $next doesn't need to be parsed again.
                incr i
            } else {
                dict set options $token {}
            }
        }
    }
    return $options
}
