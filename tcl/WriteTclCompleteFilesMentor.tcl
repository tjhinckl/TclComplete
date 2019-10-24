#!/usr/intel/pkgs/tcl-tk/8.6.8/bin/tclsh

set location [file dirname [file normalize [info script]]]
source $location/common.tcl

namespace eval tshell {

    proc get_help_commands {} {
        catch_output {help -all} -output details
        set commands {}
        foreach x $details {
            if {! [string equal (...unavailable...) $x]} {
                lappend commands $x
            }
        }
        return $commands
    }

    proc get_details {command} {
        set help {}
        if {[catch {catch_output "help $command" -output help} error]} {
            return {}
        }
        # Make sure that braces are not butted against other grouping characters
        set help [string map {\} "\} "} $help]
        set help [string map {\{ " \{"} $help]
        # split out brackets so they will be parsed as their own tokens
        set help [string map {\[ " [ "} $help]
        set help [string map {\] " ] "} $help]
        # standardize details whitespace
        set help [regsub -all {\s+} $help { }]
        return [parse $help]
    }

    proc parse {section} {
        set options {}
        set size 0
        # occasionally some commands usage are malformed because of
        # missing closing braces. Add the closing braces so we can treat
        # the contents as a list.
        while {[catch {set size [llength $section]} err]} {
            if {$err == "unmatched open brace in list"} {
                append section " \}"
            } else {
                puts $err
                return {}
            }
        }

        for {set i 0} {$i < $size} {incr i} {
            set token [lindex $section $i]
            # stop parsing when we reach the contexts token because details
            # options after that don't apply to the current command
            if {$token == "contexts:"} {
                return $options
            }
            # Look in details sublists for more options
            if {[llength $token ] > 1} {
                set sub_options [parse $token]
                set options [dict merge $options $sub_options]
                # If token is command, add it to the dictionary
            } elseif {[string match -* $token]} {
                # Peek ahead to see if this option has enumerated values
                set next [lindex $section [expr {$i + 1}]]
                if {[llength $next] > 1 || [string match <* $next]} {
                    dict set options $token $next
                } else {
                    dict set options $token {}
                }
            }
        }
        return $options
    }

    proc build_json {dir} {
        set dir $dir/TclComplete
        mkdir_fresh $dir

        puts "parsing Tessent shell commands..."


        set commands [list {*}[get_all_sorted_commands] {*}[get_help_commands]]

        set fh [open $dir/commands.json w]
        puts $fh [list_to_json $commands]
        close $fh
        puts "...commands.json file complete."


        set details {}
        foreach command $commands {
            dict set details $command [get_details $command]
        }

        set fh [open $dir/details.json w]
        puts $fh [dict_of_dicts_to_json $details]
        close $fh
        puts "...details.json file complete."

        set options {}
        dict for {command option} $details {
            dict set options $command [dict keys $option]
        }

        set fh [open $dir/options.json w]
        puts $fh [dict_of_lists_to_json $options]
        close $fh
        puts "...options.json file complete."
    }
}
