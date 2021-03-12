# Example file to demonstrate the completion possibilities for TclComplete ##
# - with each exampleline, put the cursor at end of word and hit <tab> (or ctrl-x ctrl-o)

# Create the TclComplete files like this:
source ~/.vim/pack/my_plugins/start/TclComplete/tcl/WriteTclCompleteFilesSynopsys.tcl
TclComplete::WriteFilesSynopsys $ward

# 1)  Core Tcl commands, SNPS builtins or proc names
#    Applies to first word of the line or first word after left square bracket
lapp
get_*_block
hc_check_
*geo
puts [get_attribute [current_

#2) Command -option arguments (tcl core, snps, procs that used define_proc_attributes)
lsort -
get_cells -
hc_check_cbc_boundary -

#3) Built in Tcl commands that use two words in a command
info 
dict 
string 
package 
# also...
string is 

#4)  Synopsys attributes (the object_class is derived from get_* commands)
get_cells -filter 
get_cells -filter bounding_box.
get_pins -filter 
get_timing_arcs -filter 

# If the object_class cannot be derived, then it's a two step process.
get_attribute $coll  
filter_collection $coll  

# If the context not pre-defined for attributes, 
#   <tab>-a is an alternate way to trigger attribute completion
set my_favorite_attr 
set my_favorite_attr cell.

#5) Array names
env(
ivar(
ivar_desc(

# environment variables also complete with 
getenv 
setenv   

#6) ref names (only possible if a library and block were open in ICC2/FC when TclComplete collateral was created)
get_nets -design 
get_cells -design 
current_design 

#7) variable names.   Does not use json files.  Searches current buffer for variables.
puts $my_variable_previously_assigned
set my_very_very_very_long_var_name "a"
lappend my_extremely_long_list_name "b"
dict set my_even_more_extremely_long_dict_name key1 value1
lassign {1 2 3} x y z

puts $
info exists  
set 
lappend 
dict set 

#8) expr functions
expr {

#9) packages available in auto_path 
package require  

#10) namespaces
namespace 
namespace exists 

#11) regexp character classes (rarely used)
regexp {[:

#12)  Synopsys settings
get_app_option_value -name 
get_app_var 
set_app_options -name 
set_app_var 
report_app_options 

#13) Some GUI command options
gui_change_highlight -color  
gui_add_annotation -pattern 
gui_add_annotation -type 
gui_add_annotation -symbol_type 
gui_add_annotation -line_style 
gui_add_annotation -symbol_size 
gui_add_annotation -setting 

#14) format/scan codes
format 
scan 

#15) A limited number of insert mode abbreviations
ga
gs
cs
fic

#16) A syntax/tcl.vim file is also dumped out to highlight 
#  a) valid commmands (Tcl core, SNPS builtin, proc names)
lsort
lappend
puts
get_pins
ppp::push_routes
undefined_command

#  b) valid SNPS object attributes
get_ports -filter direction==in
get_attribute $port direction 

#  c) G_* gvars
getvar G_DESIGN_NAME


#15) optional others
# itar settings (if itar was loaded when TclComplete collateral was created)
iccpp_com::get_param 
iccpp_com::set_param

# For HDK, rdt steps
runRDT -stop 
runRDT -stop 04_hier_place.

# For HDK, G_vars
getvar G_
setvar G_

# For HDK track patterns
sd_create_tracks -pattern ec0_sdg_

# DEVELOPER TOPICS FOR DISCUSSION
# 1)  Let's test this over many environments.  
#     Find out what breaks.  In the past some uncommon characters in "help-strings" have 
#     crashed the TclComplete::WriteFilesSynopsys proc.  
#
# 2)  Can the TclComplete json files be pre-created with each CTH2 release?
#     - Users can point to CTH2 dirs by default instead of generating json for each $ward.
#     - SPR integration team does this with every new RTL release.

# 3)  Can the plugin VimScript code be part of a CTH2 release?  
#     - Users can activate the plugin with "packpath" command in ~/.vimrc instead
#     of installing from GitLab.
#
# 4)  What other completion contexts are there?
