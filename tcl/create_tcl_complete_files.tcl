#############################################
#### create_tcl_omnicomplete_files.tcl ######
#############################################

# Author: Chris Heithoff
# Description:  Source this from the icc2_shell (or dc or pt?) to 
#               create a file that can be used for tcl omnicompletion
#               in Vim.
# Date of latest revision: 02-Nov-2017

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

        
# Run "help <command>".  Parse and return the description
#  Corner case:  "help help" returns help for three commands
#  TODO Attributes are listed with help_attributes classnames!!!
proc get_description_from_help {cmd} {
    set result ""
    redirect -variable help_text {help $cmd}
    # Look for <cmdname>     # Description of the command
    foreach line [split $help_text "\n"] {
        if {[regexp {^\s*(\S+)\s+(#.*$)} $line -> cmd_name description]} {
            if {$cmd_name == $cmd} {
                set result [regsub -all {"} $description {\"}]
                #" Comment to fix Vim syntax coloring
            }
        }
    }
    return $result 
}

proc get_options_from_help {cmd} {
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
                if {$cmd_name == $cmd} {
                    set looking_for_command 0
                    set looking_for_options  1
                    continue
                }
            }
        }
        # Now get the command options. This start with a dash.
        #  They might be surrounded by brackets.
        #  The option is first, then the details, surrounded by parentheses.
        if {$looking_for_options} {
            if {[regexp {^\s*\[?(-[a-zA-Z0-9_]+)[^(]*(.*$)} $line -> opt detail] } {
                set detail [regsub -all {"} $detail {\"}]
                #" (comment to correct Vim syntax coloring)
                dict set result $opt $detail
            }
            # Exit loop if there is an empty line.
            if {[regexp {^\s*$} $line]} {
                break
            }
        }
    }
    return $result
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
#
#  Try to get an order like this:
#     Tcl built ins   ($builtin_list)
#     Synopsys commands     ($command_list)
#     procs in the current namespace   ($proc_list)
#     procs in the child namespaces    (proc_list)
echo "TclComplete:  querying SynopsysTcl for data..."
redirect -variable all_command_list {lsort -u [info command]}

# Divide all_command_list into builtin and regular commands
# The first uses the 'man' command, the other uses the 'help -v' 
# command to list the options.
set builtin_list {} 
set command_list {}
set proc_list    {}

# Initial some dicts
set desc_dict [dict create]
set namespace_children_dict [dict create]

## Split up all the commands into three lists (just for priority in the final list order)
foreach cmd $all_command_list {
    set description [get_description_from_help $cmd]
    dict set desc_dict $cmd $description
    if {[regexp "Builtin" $description]} {
        lappend builtin_list $cmd
    } elseif {[info procs $cmd]==""} {
        lappend command_list $cmd
    } else {
        lappend proc_list $cmd
    }
}
echo " ...\$builtin_list built"
echo " ...\$command_list built"

# We're not done with procs!  There are more procs inside namespaces.
set namespace_list [lsort -u [namespace children]]
echo " ...\$namespace_list built"
foreach namespace $namespace_list {
    redirect -variable namespace_procs {lsort -u [eval "info proc {${namespace}::*}"]}
    foreach proc_name $namespace_procs {
        set proc_name [string trim $proc_name "::"]
        lappend proc_list $proc_name
        set description [get_description_from_help $proc_name]
        dict set desc_dict $proc_name $description
    }
}
echo "...\$proc_list built"
echo "...\$desc_dict built"


######################################################################
# Form some other data structures for use later
######################################################################
# Form a list of expr functions
set func_list [ lsort -u [info function] ]
echo "...\$func_list built"

# Form a list of packages
set package_list [ lsort -u [package names] ]
echo "...\$package_list built"

# Form a list of aliases
redirect -variable alias_string {alias}
set alias_list [split $alias_string "\n"]
echo "...\$alias_list built"

######################################################################
# Now that we have all the commands and some other stuff, 
# let's figure out the command descriptions, options, and option details
######################################################################
echo "TclComplete....building commands options"
set opt_dict     [dict create]
set details_dict [dict create]
echo "...\$opt_dict initialized"
echo "...\$details_dict initialized"

# non-builtins use "help" to get options 
foreach cmd [concat $command_list $proc_list] {
    dict set opt_dict     $cmd {}
    dict set details_dict $cmd [dict create]
    dict for {opt_name details} [get_options_from_help $cmd] {
        # APPEND this opt to this command's entry in opt_dict
        dict lappend opt_dict $cmd $opt_name

        # CREATE a dictionary to thi commands entry in details_dict
        dict set details_dict $cmd $opt_name $details
    }
} 
echo "...completed options for commands and proc"

    
# builtins use "man" or "namespace ensembles" to get options.  
#  (some special cases are hard coded)
foreach bi $builtin_list {
    if {[namespace ensemble exists $bi]} {
        set opts [dict keys [namespace ensemble configure $bi -map]]
    } else {
        set opts [get_options_from_man $bi]
    }
    dict set opt_dict $bi $opts
}
echo "...completed options for builtins"

# Special cases for options
dict set opt_dict "expr" $func_list
dict set opt_dict "info"    [lsort "args body class cmdcount commands complete coroutine default errorstack exists frame functions globals hostname level library loaded locals nameofexecutable object patchlevel procs script sharelibextension tclversion vars"]
dict set opt_dict "package" [lsort "ifneeded names present provide require unknown vcompare versions vsatisfies prefer"]
dict set opt_dict "package require" $package_list
echo "...completed options for special cases"

################################################################################
### Now  write out sourceable Vimscript code!!! 
###  - An earlier version of this script wrote out text files to be parse in Vim
###    Why not just directly write it out as Vimscript so that the Vim plugin 
###    runs faster ??!!
################################################################################
# 1)  Setup the output directory
set outdir $::env(WARD)/TclComplete
mkdir_fresh $outdir
echo "Making new \$WARD/TclComplete directory..."

# 2) Write data structures out in Vim format.
#    WARNING!  This is a backslash hellscape!
#       - Key names, value names and list elements must be
#         in quotes because they will be treated as strings in Vim.
#       - The command descriptions and option details will possibly
#         have either single quotes (apostrophes) or doubt quotes, 
#         these must be escaped.  (is regsub the best choice?)
#       - The puts string must be in double quotes instead of {} 
#         because variables need to be expanded.
#       - Square brackets must be escaped so Tcl ignore command substitution.
#       - Double quotes inside the string must be escaped so they 
#         don't close the surrounding double quotes.
#       - Vim comments are a start-of-string double quote
#       - Vim line continuation is a \ at beginning on next line
#            (not like Tcl or shell, which is end of previous line)
         
#-------------------------------------
#  All the commands in a Vim ordered list
#    g:TclComplete#cmds
#-------------------------------------
    set f [open $outdir/commands.vim w]
    puts $f "let g:TclComplete#cmds = \["
    foreach cmd [concat $builtin_list $command_list $proc_list] {
        puts $f "   \\ \"$cmd\"," 
    }
    puts $f "   \\]"
    close $f
    echo "...commands.vim file complete."

#-----------------------------------------
# Command options in a Vim dictionary.
#   key = command name
#   value = ordered list of options
#   g:TclComplete#options['cmd'] = ['opt1', 'opt2',]
#-----------------------------------------
    set f [open $outdir/options.vim w]
    # initialize details and opts dicts
    puts $f "let options = {}"
    foreach cmd [dict keys $opt_dict] {
        set option_string "\["
        foreach opt [dict get $opt_dict $cmd] {
            append option_string "\"$opt\","
        }
        puts $f "let options\[\"$cmd\"\] = $option_string\]"
    }
    puts $f "\"\" Reassign to a global variable \"\""
    puts $f "let g:TclComplete#options = options"
    close $f
    echo "...options.vim file complete."

#-----------------------------------------
# Command option details in a Vim dictionary of dictionaries
#   key = command name
#   value = dictionary with key=option and value=details
#   g:TclComplete#details['cmd']['opt1'] = "details of the option"
#-----------------------------------------
    set f [open $outdir/details.vim w]
    puts $f "let details = {}"
    dict for {cmd opt_detail_dict} $details_dict {
        puts $f "   let details\[\"$cmd\"\]={}"
        dict for {opt detail} $opt_detail_dict {
            puts $f "        let details\[\"$cmd\"\]\[\"$opt\"\] = \"$detail\""
        }
    }
    puts $f "\"\" Reassign to a global variable \"\""
    puts $f "let g:TclComplete#details = details"
    close $f
    echo "...details.vim file complete."

#-----------------------------------------
# Command descriptions in a Vim dictionary
#   key = command name
#   value = command description
#   g:TclComplete#descriptions['cmd'] = "description of the command"
#-----------------------------------------
    set f   [open $outdir/descriptions.vim w]
    puts $f "let description = {}"
    dict for {cmd description} $desc_dict {
        puts $f "let description\[\"$cmd\"\] = \"$description\""
    }
    puts $f "\"\" Reassign to a global variable \"\""
    puts $f "let g:TclComplete#descriptions = description"
    close $f
    echo "...descriptions.vim file complete."

#----------------------------------------------------
# Write out aliases as Vim insert mode abbreviations
#----------------------------------------------------
    set f   [open $outdir/aliases.vim w]
    foreach entry $alias_list {
        if {[string length $entry]>0} {
            puts $f "iabbrev $entry"
        }
    }
    close $f
    echo "...alises.vim file complete."


