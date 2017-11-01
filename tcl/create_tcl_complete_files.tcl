#############################################
#### create_tcl_omnicomplete_files.tcl ######
#############################################

# Author: Chris Heithoff
# Description:  Source this from the icc2_shell (or dc or pt?) to 
#               create a file that can be used for tcl omnicompletion.
#               The format of the output file is:
#                command_name -option1 -option2 -option3
#                proc_name    -option1 -option2 -option3
#                .....
# Date of latest revision: 27-Oct-2017

##############################
# Helpers procs defined first 
##############################
proc mkdir_fresh {dir} {
    if {[file exists $dir]} {
        echo "Deleting previous $dir"
        file delete -force $dir
    }

    file mkdir $dir
}

        
# Run "help -v  <command>".  Parse and return the options.
proc get_description_from_help {cmd} {
    redirect -variable help_text {help $cmd}
    if {[regexp "CMD-040" $help_text]} {
        return {}
    }
    set result ""
    foreach line [split $help_text "\n"] {
        if {[regexp {^\s+([a-zA-Z0-9_]+)\s+(#.*$)} $line -> cmd_name description]} {
            if {$cmd_name == $cmd} {
                set result $description
            }
        }
    }
    return $result 
}

proc get_options_from_help {cmd} {
    set result {}
    redirect -variable help_text {help -v $cmd}
    if {[regexp "CMD-040" $help_text]} {return ""}

    set looking_for_command 1
    set looking_for_option  0

    foreach line  [split $help_text "\n"] {
        # We need to look only in the correct section. 
        # Some help results list multiple helps (like "help -v help")
        if {$looking_for_command} {
            if {[regexp {^\s+([a-zA-Z0-9_:]+)\s+(#.*$)} $line -> cmd_name description]} {
                if {$cmd_name == $cmd} {
                    set looking_for_command 0
                    set looking_for_option  1
                    continue
                }
            }
        }

        # Now get the command options.  They might be surround by [ and ].
        if {$looking_for_option} {
            if {[regexp {^\s+\[?(-[a-zA-Z0-9_]+)} $line -> opt] } {
                lappend result $opt
            }
            # Exit loop if there is an empty line.
            if {[regexp {^\s*$} $line]} {
                break
            }
        }
    }
    return [lsort -u $result]
}

# Run "man <command>".  Parse and return the options.
proc get_options_from_man {cmd} {
    set result {}
    redirect -variable man_text {man $cmd}
    foreach line [split $man_text "\n"] {
        # Look for "-option" at beginning of line.  This might grab too much?
        if {[regexp {^\s+(-[a-z]+)} $line -> opt]} {
            lappend result $opt
        }
    }
    return [lsort -u $result]
}

####################################################################
# Ask the synopsys tool for commands, procs, packages, and functions
####################################################################
# Form a list of all commands (and remove the . command at the beginning.
redirect -variable command_list {lsort -u [info command]}
if {[lindex $command_list 0]=="."} {
    set command_list [lrange $command_list 1 end]
    set command_list [string trim $command_list]
}

# Form a list of namespace children relative to ::
redirect -variable namespace_list {lsort -u [namespace children]}
set namespace_list [string trim $namespace_list]

# Form a list of all procs
redirect -variable proc_list {lsort -u [info proc]}
set proc_list [string trim $proc_list]
# Also add procs within namespaces
foreach namespace $namespace_list {
    # string trim $namespace "::"
    redirect -variable namespace_procs {lsort -u [eval "info proc {${namespace}::*}"]}
    foreach n $namespace_procs {
        lappend proc_list [string trim $n "::"]
    }
}

# Form a list of expr functions
redirect -variable func_list {lsort -u [info function]}
set func_list [string trim $func_list]

# Form a list of packages
redirect -variable package_list {lsort -u [package names]}
set package_list [string trim $package_list]


# Initialize the builtin_list.  Built-ins respond to help
# with "<command> # Builtin" and need to use "man <command"
set builtin_list {} 


######################################################################
# Now that we have all the commands and stuff, let's find the options!
######################################################################
# 1)  Setup the output directory
set outdir $::env(WARD)/TclComplete
mkdir_fresh $outdir

# 2)  Write out the list of commands.
#      (but save the builtins for later)
set f [open $outdir/commands.txt w]
foreach cmd $command_list {
    set opts        [get_options_from_help $cmd]
    set description [get_description_from_help $cmd]
    if {[regexp "Builtin" $description]} {
        lappend builtin_list $cmd
        continue
    }
    puts $f "$cmd%$opts%$description"
}
close $f

# 3)  Write out the list of procs as csv
set f [open $outdir/procs.txt w]
foreach proc $proc_list {
    set opts        [get_options_from_help $proc]
    set description [get_description_from_help $proc]
    puts $f "$proc%$opts%$description"
}
close $f

# 4)  Write out the list of builtins.  "help" shows no options for builtins,
#       so "man" or namespace ensembles are used.
set f [open $outdir/builtins.txt w]
foreach bi $builtin_list {
    if {[namespace ensemble exists $bi]} {
        set opts [dict keys [namespace ensemble configure $bi -map]]
    } else {
        set opts [get_options_from_man $bi]
    }
    # Special cases
    if {$bi == "expr"} {
        set opts $func_list
    } elseif {$bi == "info"} {
        set opts [lsort "args body class cmdcount commands complete coroutine default errorstack exists frame functions globals hostname level library loaded locals nameofexecutable object patchlevel procs script sharelibextension tclversion vars"]
    } elseif {$bi == "package"} {
        set opts [lsort "ifneeded names present provide require unknown vcompare versions vsatisfies prefer"]
    }

    puts $f "$bi%$opts%"

}
close $f

# 5)  Write out the list of packages
set f [open $outdir/packages.txt w]
foreach pack $package_list {
    puts $f "$pack"
}
close $f


# 6)  Write out the list of namespaces
set f [open $outdir/namespaces.txt w]
foreach namespace $namespace_list {
    puts $f "$namespace%[namespace children $namespace]%"
}
close $f
