#!/usr/intel/pkgs/tcl-tk/8.6.8/bin/tclsh
#############################################
#### WriteTclCompleteFilesStd.tcl ########
#############################################

# Author:  Chris Heithoff
# Description:  Run the main proc in a tclsh shell to generate
#  a group of json files containing commands, command options, etc, 
#  which will be consumed by an auto-completion text editor plugin.
# Date of latest revision: 03-Jan-2020

# Bring the namespace into existence (if not already)
namespace eval TclComplete {}

set location [file dirname [file normalize [info script]]]
source $location/common.tcl

proc TclComplete::WriteFilesStd {dir_location} {
    # Form a list of all commands, including those inside namespaces.
    set all_command_list [TclComplete::get_all_sorted_commands]

    # Initialize nested dictionary for commands
    #   key1 = command name
    #   key2 = options (initialize as empty)
    #   value = descriptions (initialize as empty)
    set cmd_dict [dict create]
    foreach cmd $all_command_list {
        dict set cmd_dict $cmd {} {}
    }

    # Merge in commands with subcommands as options (as revealed through namespaces)
    set namespace_cmd_dict  [TclComplete::get_namespace_cmd_dict $all_command_list]
    set cmd_dict            [dict merge $cmd_dict $namespace_cmd_dict]

    # Finally, add any hardcoded command options and descriptions that are not 
    #  revealed through help and man pages.
    set hardcoded_cmd_dict  [TclComplete::get_hardcoded_cmd_dict]
    set cmd_dict            [dict merge $cmd_dict $hardcoded_cmd_dict]

    # Add expression functions as options for the expr command.
    set func_list [ lsort -u [info function] ]
    dict set cmd_dict "expr" [TclComplete::list2keys $func_list]

    ################################################################################
    ### Write out files to the TclComplete directory
    ################################################################################
    # Setup the output directory and dump the log
    set outdir $dir_location/TclComplete
    puts "Making new directory:  $outdir"

    TclComplete::mkdir_fresh $outdir
    TclComplete::write_log   $outdir

    # Standard stuff.
    TclComplete::write_json_from_cmd_dict    $outdir $cmd_dict
    TclComplete::write_environment_json      $outdir
    TclComplete::write_regex_char_class_json $outdir
    TclComplete::write_packages_json         $outdir

    # Find any arrays and dump their current values.
    TclComplete::write_arrays_json $outdir

    # Vim stuff
    TclComplete::write_vim_tcl_syntax    $outdir $all_command_list
    
    # Write key-only command description dictionary
    set description_dict [TclComplete::list2keys [dict keys $cmd_dict]]
    set description_json [TclComplete::dict_to_json $description_dict]
    TclComplete::write_json $outdir/descriptions $description_json

    puts "...done\n"
}

puts "sourced: WriteTclCompleteFilesStd.tcl."
puts "IMPORTANT:  To create the TclComplete directory under <path>"
puts "   TclComplete::WriteFilesStd <path>"
