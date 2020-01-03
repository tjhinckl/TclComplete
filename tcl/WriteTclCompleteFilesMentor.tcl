#!/usr/intel/pkgs/tcl-tk/8.6.8/bin/tclsh
#############################################
#### WriteTclCompleteFilesMentor.tcl ########
#############################################

# Authors:  Troy Hinckley, Chris Heithoff
# Description:  Run the main proc in a Mentor tool to create
#  a group of files containing commands, command options, etc, 
#  which will be consumed by an auto-completion text editor plugin.
# Date of latest revision: 17-Dec-2019

# Bring the namespace into existence (if not already)
namespace eval TclComplete {}

set location [file dirname [file normalize [info script]]]
source $location/common.tcl
source $location/mentor.tcl

proc TclComplete::WriteFilesMentor {dir_location} {
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

    # Get command options for Mentor [help -all] commands.
    puts "parsing Tessent shell commands..."
    set mentor_cmd_dict    [TclComplete::get_mentor_cmd_dict]
    set cmd_dict           [dict merge $cmd_dict $mentor_cmd_dict]

    # Merge in additional options for commands which can work for non-Synopsys tools.
    set hardcoded_cmd_dict  [TclComplete::get_hardcoded_cmd_dict]
    set namespace_cmd_dict  [TclComplete::get_namespace_cmd_dict $all_command_list]
    set cmd_dict  [dict merge $cmd_dict $hardcoded_cmd_dict $namespace_cmd_dict]

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
    TclComplete::write_packages_json          $outdir

    # What's this file for?  Is this an Emacs thing?  (Ask Troy)
    set fh [open $outdir/syntaxdb_tessent.tcl w]
    set help_commands [TclComplete::mentor_get_help_commands]
    puts $fh "lappend ::knownCommands $help_commands"
    close $fh

    # Write empty lists or dictionaries for these files.  
    #   (TODO  Make this more automatic)
    TclComplete::write_json $outdir/designs {[]}
    TclComplete::write_json $outdir/g_vars {[]}
    TclComplete::write_json $outdir/g_var_arrays {[]}
    TclComplete::write_json $outdir/iccpp {[]}
    TclComplete::write_json $outdir/app_vars {[]}
    TclComplete::write_json $outdir/techfile_types {[]}
    TclComplete::write_json $outdir/app_options {{}}
    TclComplete::write_json $outdir/iccpp_dict {{}}
    TclComplete::write_json $outdir/techfile_layer_dict {{}}
    TclComplete::write_json $outdir/attributes {{}}
    TclComplete::write_json $outdir/techfile_attr_dict {{}}

    # Vim stuff
    TclComplete::write_vim_tcl_syntax    $outdir $all_command_list
    
    # Description dict. 
    #  Start keys only for all commands
    set description_dict [TclComplete::list2keys [dict keys $cmd_dict]]
    #  Add the result of info args for every proc that lists arguments
    set description_dict [TclComplete::add_args_to_description_dict $description_dict]
    set description_json [TclComplete::dict_to_json $description_dict]
    TclComplete::write_json $outdir/descriptions $description_json

    puts "...done\n"
}
