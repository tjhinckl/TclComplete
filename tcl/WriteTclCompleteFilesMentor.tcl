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

    proc write_json {name content} {
        set fh [open $name.json w]
        puts $fh $content
        close $fh
        puts "...[file tail $name] file complete."
    }

    proc build_all_json {dir} {
        set dir $dir/TclComplete
        mkdir_fresh $dir

        puts "parsing Tessent shell commands..."

        set help_commands [get_help_commands]
        set commands [list {*}[get_all_sorted_commands] {*}$help_commands]

        set fh [open $dir/syntaxdb_tessent.tcl w]
        puts $fh "lappend ::knownCommands $help_commands"
        close $fh

        write_json $dir/commands [list_to_json $commands]

        set details {}
        foreach command $commands {
            dict set details $command [get_details $command]
        }

        write_json $dir/details [dict_of_dicts_to_json $details]

        set options {}
        dict for {command option} $details {
            dict set options $command [dict keys $option]
        }

        write_json $dir/options [dict_of_lists_to_json $options]

        write_json $dir/designs {[]}
        write_json $dir/g_vars {[]}
        write_json $dir/g_var_arrays {[]}
        write_json $dir/iccpp {[]}
        write_json $dir/app_vars {[]}
        write_json $dir/regexp_char_classes {[]}
        write_json $dir/packages {[]}
        write_json $dir/techfile_types {[]}

        set others {}
        foreach command $commands {
            lappend others $command {}
        }
        set json [dict_to_json $others]

        write_json $dir/descriptions $json
        write_json $dir/app_options {{}}
        write_json $dir/environment [dict_to_json [regsub -all {\"} [array get ::env] {\"}]]
        write_json $dir/iccpp_dict {{}}
        write_json $dir/techfile_layer_dict {{}}
        write_json $dir/attributes {{}}
        write_json $dir/techfile_attr_dict {{}}
    }
}
