#############################################
#### WriteTclCompleteFilesSynopsys.tcl ######
#############################################

# Author: Chris Heithoff
# Description:  Run the main proc in a Synopsys tool to create
#  a group of files containing commands, command options, etc, 
#  which will be consumed by an auto-completion text editor plugin.
#      
# Date of latest revision: 17-Dec-2019

# Bring the namespace into existence (if not already)
namespace eval TclComplete {}

set location [file dirname [file normalize [info script]]]
source $location/common.tcl
source $location/synopsys.tcl


proc TclComplete::WriteFilesSynopsys {dir_location} {
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

    # Synopsys tools have good commands for deriving commands options (redirect, man, help)
    set synopsys_cmd_dict  [TclComplete::get_synopsys_cmd_dict $all_command_list]
    set cmd_dict           [dict merge $cmd_dict $synopsys_cmd_dict]

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
    TclComplete::write_packages_json         $outdir

    # Synopsys/Intel only
    TclComplete::write_attributes_json   $outdir
    TclComplete::write_app_vars_json     $outdir
    TclComplete::write_app_options_json  $outdir
    TclComplete::write_designs_json      $outdir
    TclComplete::write_gui_settings_json $outdir
    TclComplete::write_techfile_json     $outdir
    TclComplete::write_gvars_json        $outdir
    TclComplete::write_iccpp_json        $outdir
    TclComplete::write_descriptions_json $outdir $all_command_list
    TclComplete::write_rdt_steps         $outdir

    # Vim stuff
    TclComplete::write_aliases_vim       $outdir
    TclComplete::write_vim_tcl_syntax    $outdir $all_command_list

    puts "...done\n"
}
