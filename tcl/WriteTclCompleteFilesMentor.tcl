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
        # Prevent unhelpabe commands from getting false help string.
        #  ('help format' returns help string for 'help format_dictionary')
        if {$command ni [get_help_commands]} {
            return {}
        }
        set help {}
        if {[catch {catch_output "help $command" -output help} error]} {
            return {}
        }
        # Make sure that braces are not butted against other grouping characters
        #  (The string mapping is defined like this to help text editors from losing
        #  track of actual matched curlies in the functional code)
        set m1a "{"
        set m1b " {"
        set m2a "}"
        set m2b "} "
        # split out brackets so they will be parsed as their own tokens
        set m3a {[}
        set m3b { [ }
        set m4a {[}
        set m4b { [ }
        set mapping [list $m1a $m1b $m2a $m2b $m3a $m3b $m4a $m4b]
        set help [string map $mapping $help]
        # standardize details whitespace
        set help [regsub -all {\s+} [string trim $help] { }]
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

    proc build_all_json {dir} {
        set dir $dir/TclComplete
        TclComplete::mkdir_fresh $dir

        puts "parsing Tessent shell commands..."

        set help_commands [get_help_commands]
        set commands [list {*}[TclComplete::get_all_sorted_commands] {*}$help_commands]

        set fh [open $dir/syntaxdb_tessent.tcl w]
        puts $fh "lappend ::knownCommands $help_commands"
        close $fh

        TclComplete::write_json $dir/commands [TclComplete::list_to_json $commands]

        set details {}
        foreach command $commands {
            dict set details $command [get_details $command]
        }

        TclComplete::write_json $dir/details [TclComplete::dict_of_dicts_to_json $details]

        set options {}
        dict for {command option} $details {
            dict set options $command [dict keys $option]
        }

        TclComplete::write_json $dir/options [TclComplete::dict_of_lists_to_json $options]

        TclComplete::write_json $dir/designs {[]}
        TclComplete::write_json $dir/g_vars {[]}
        TclComplete::write_json $dir/g_var_arrays {[]}
        TclComplete::write_json $dir/iccpp {[]}
        TclComplete::write_json $dir/app_vars {[]}
        TclComplete::write_json $dir/regexp_char_classes {[]}
        TclComplete::write_json $dir/packages {[]}
        TclComplete::write_json $dir/techfile_types {[]}

        set others {}
        foreach command $commands {
            lappend others $command {}
        }
        set json [TclComplete::dict_to_json $others]

        TclComplete::write_json $dir/descriptions $json
        TclComplete::write_json $dir/app_options {{}}
        TclComplete::write_json $dir/environment [TclComplete::dict_to_json [regsub -all {\"} [array get ::env] {\"}]]
        TclComplete::write_json $dir/iccpp_dict {{}}
        TclComplete::write_json $dir/techfile_layer_dict {{}}
        TclComplete::write_json $dir/attributes {{}}
        TclComplete::write_json $dir/techfile_attr_dict {{}}
    }
}
