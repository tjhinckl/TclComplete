#############################################
#### WriteTclCompleteFiles.tcl ######
#############################################

# Author: Chris Heithoff
# Description:  Source this from the icc2_shell (or dc or pt?) to 
#               create a file that can be used for tcl omnicompletion
#               in Vim.
# Date of latest revision: 10-Dec-2019

# Bring the namespace into existence.
namespace eval TclComplete {}

set location [file dirname [file normalize [info script]]]
source $location/common.tcl

if {[llength [info vars tessent*]]>0} {
    set tcl_type "tessent"
} elseif {[llength [info vars synopsys*]]>0} {
    set tcl_type "synopsys"
} else {
    set tcl_type "tclsh"
}

if {$tcl_type == "synopsys"} {
    source $location/TclCompleteSynopsys.tcl
}

#############################################################
# Some commands have subcommands that are not revealed by 
# namespace ensembles or help pages or man pages, but are 
# revealed in the error message when trying to use a bogus subcommand
###################################################################
proc get_subcommands_from_error_msg {cmd} {
    ## Parse this message to return {this that other}
    #Error: unknown or ambiguous subcommand "bogus_subcommand": must be this, that or other"
	#    Use error_info for more info. (CMD-013)
    catch {redirect -variable msg {$cmd bogus_subcommand}}
    set msg [lindex [split $msg "\n"] 0]
    set msg [regsub {^Error: .* must be } $msg ""]
    set msg [regsub { or } $msg ""]
    set msg [regsub -all {\s+} $msg ""]
    set error_list [split $msg " ,"]
    return [lsort $error_list]
}

proc command_exists {cmd} {
    if {[llength [info command $cmd]]>0} {
        return 1
    } else {
        return 0
    }
}

###########################
# Main script starts here.
###########################
# Form a list of all commands, including those inside namespaces.
#  Most of the code here is sort in a particular order
puts "------------------------------------------------"
puts "---TclComplete:  forming the list of all commands"
set all_command_list [TclComplete::get_all_sorted_commands]

set desc_dict [TclComplete::get_synopsys_descriptions $all_command_list]

######################################################################
# Now that we have all the commands, use the help/man commands to 
# get the options for each command and the details of each option.
######################################################################
puts "---TclComplete....building command options"
set opt_dict     [dict create]
set details_dict [dict create]

foreach cmd $all_command_list {
    # Initialize the dictionaries.   
    #   opt_dict:  key=cmd, value=list of options
    #   details_dict:  key1=cmd, key2=option, value=detail of the option.
    dict set opt_dict     $cmd {}
    dict set details_dict $cmd [dict create]

    # Fill up options for namespace ensemble subcommands first.
    #   (not common.  stuff like 'dict' and 'string')
    if {[namespace ensemble exists $cmd]} {
        set map_keys    [dict keys [namespace ensemble configure $cmd -map]]
        set subcommands [namespace ensemble configure $cmd -subcommands]
        set ensemble_options [lsort -u [concat $map_keys $subcommands]]
        if {[llength $ensemble_options]} {
            dict set opt_dict $cmd $ensemble_options
        }
    }

    # Use either the 'help -v' or 'man' commands to get command options.
    if {[llength [set help_dict [TclComplete::get_options_from_help $cmd]]]>0} {
        dict for {opt_name details} $help_dict {
            # Replace literal tabs (plus additional spaces) to a single space.
            set details [regsub {\t *} $details " "]
            dict lappend opt_dict $cmd $opt_name
            dict set details_dict $cmd $opt_name $details
        }
    } else {
        foreach opt_name [TclComplete::get_options_from_man $cmd] {
            dict lappend opt_dict $cmd $opt_name
        }
    }
}
puts "...found options for all commands."

    
 
##########################################################################
# Special cases.  Some of these look like namespace ensemble, but are not.
##########################################################################
# Any math function can be used in expr
set func_list [ lsort -u [info function] ]
dict set opt_dict "expr" $func_list
puts "...\$func_list built"

# info options
dict set opt_dict "info"  [concat [dict get $opt_dict "info"] [get_subcommands_from_error_msg info]]

# after options
dict set opt_dict "after" [list cancel idle info]

# interp options
dict set opt_dict "interp" [get_subcommands_from_error_msg interp]

# encoding options
dict set opt_dict "encoding" [get_subcommands_from_error_msg encoding]
set encoding_names [lsort [encoding names]]
dict set opt_dict "encoding convertfrom" $encoding_names
dict set opt_dict "encoding convertto"   $encoding_names
dict set opt_dict "encoding system"      $encoding_names

# zlib options
dict set opt_dict "zlib" [get_subcommands_from_error_msg zlib]
dict set opt_dict "zlib gunzip" [list -headerVar]
dict set opt_dict "zlib gzip"   [list -level -header]
dict set opt_dict "zlib -headerVar" [list comment crc filename os size time type]
dict set opt_dict "zlib -header"    [list comment crc filename os size time type]
dict set opt_dict "zlib stream" [list compress decompress deflate gunzip gzip inflate]
dict set opt_dict "zlib push"   [list compress decompress deflate gunzip gzip inflate]

# package options
dict set opt_dict "package" [concat [get_subcommands_from_error_msg package] -exact]


# STUFF FOR OBJECT ORIENTED TCL WITH THE OO PACKAGE
if {[namespace exists "oo"]} {
    dict set opt_dict "oo::class" [list create new]
    foreach oo_cmd {oo::define oo::objdefine} {
        set subcommands [lsort [info commands ${oo_cmd}::*]]
        set subcommands [lmap cmd $subcommands {namespace tail $cmd}]
        dict set opt_dict $oo_cmd $subcommands
    }
    dict set opt_dict "info class"  [list call constructor definition destructor filters forward instances methodtype mixins subclasses superclasses variables]
    dict set opt_dict "info object" [list call class definition filters forward isa methods methodtype mixins namespace variables vars]
    lappend all_command_list [list self my]
    dict set opt_dict "self" [list call caller class filter method namespace next object target]
}

# "namespace ensemble" subcommands and options
dict set opt_dict "namespace ensemble" [list create configure exists -command -map -namespace -parameters -prefixes -subcommands -unknown]

# Generator stuff
if {[command_exists generator]} {
    dict set opt_dict generator [get_subcommands_from_error_msg generator]
}

# Offer valid type names for the argument following "string is"
dict set opt_dict   "string is" [list -strict alnum alpha ascii boolean control digit double entier false graph integer list lower print punct space true upper wideinteger wordchar xdigit]
dict set details_dict  "string is" alnum       "Any Unicode alphabet or digit character."
dict set details_dict  "string is" alpha       "Any Unicode alphabet character."
dict set details_dict  "string is" ascii       "Any  character  with a value less than \u0080."
dict set details_dict  "string is" boolean     "Any of the forms allowed to Tcl_GetBoolean."
dict set details_dict  "string is" control     "Any Unicode control character."
dict set details_dict  "string is" digit       "Any  Unicode  digit  character. "
dict set details_dict  "string is" double      "Any  of  the  valid  forms for a double in Tcl."
dict set details_dict  "string is" entier      "Any of the valid string formats for an integer value of arbitrary size in Tcl."
dict set details_dict  "string is" false       "Any of the forms allowed to Tcl_GetBoolean where the value is false."
dict set details_dict  "string is" graph       "Any Unicode printing character, except space."
dict set details_dict  "string is" integer     "Any of the valid string formats for a 32-bit integer value  in Tcl."
dict set details_dict  "string is" list        "Any proper list structure."
dict set details_dict  "string is" lower       "Any Unicode lower case alphabet character."
dict set details_dict  "string is" print       "Any Unicode printing character, including space."
dict set details_dict  "string is" punct       "Any Unicode punctuation character."
dict set details_dict  "string is" space       "Any  Unicode  whitespace  character."
dict set details_dict  "string is" true        "Any of the forms allowed to Tcl_GetBoolean where the value is true."
dict set details_dict  "string is" upper       "Any  upper  case  alphabet  character in the Unicode character set."
dict set details_dict  "string is" wideinteger "Any of the valid forms for a wide integer in  Tcl."
dict set details_dict  "string is" wordchar    "Any  Unicode  word  character.  "
dict set details_dict  "string is" xdigit      "Any hexadecimal digit character (0-9A-Fa-f)."

# Format special characters (define for format and scan commands)
dict set opt_dict  "format" "%d %s %c %u %x %X %o %b %f %e %E %g %G"
dict set details_dict "format" "%d" "Signed decimal"
dict set details_dict "format" "%s" "String"
dict set details_dict "format" "%c" "Unicode character"
dict set details_dict "format" "%u" "Unsigned decimal"
dict set details_dict "format" "%x" "Lower case hex"
dict set details_dict "format" "%X" "Upper case hex"
dict set details_dict "format" "%o" "Octal"
dict set details_dict "format" "%b" "Binary"
dict set details_dict "format" "%f" "Floating point (default precision=6)"
dict set details_dict "format" "%e" "Scientific notication x.yyye+zz"
dict set details_dict "format" "%g" "%f or %e, based on precision"
dict set details_dict "format" "%G" "%f or %E, based on precision"
dict set opt_dict "scan" [dict get $opt_dict "format"]
dict set details_dict "scan" [dict get $details_dict "format"]
puts "...completed options for special cases in the opt_dict"


###########################################################
# Form a list of application options (and a dictionary too)
###########################################################
set app_option_dict [dict create]
if {[command_exists  get_app_options]} {
    puts "...getting application options"
    set app_option_list [lsort -u [get_app_options]]
} else {
    set app_option_list {}
}
foreach app_option $app_option_list {
    dict set app_option_dict $app_option [get_app_option_from_man_page $app_option]
}

#################################################################
# Make a package list for 'package require', 'package forget, etc
#################################################################
puts "...getting package names"
set package_list [lsort -u [package names]]

####################################################################
# ICCPP parameters (this will be empty if ::iccpp_com doesn't exist)
####################################################################
set iccpp_param_list [lsort [array names ::iccpp_com::params_map]]
set iccpp_param_dict [array get   ::iccpp_com::params_map]

#####################
# app_vars
#####################
puts "...getting application variables"
set app_var_list [lsort [get_app_var -list *]]

#####################
# gui window settings
#####################
puts "...getting gui window settings"
if {[command_exists gui_get_current_window]} {
    redirect -variable gui_settings_layout {
        set window [gui_get_current_window -types Layout -mru]
        gui_get_setting -window $window -list
    }
    # Some settings include "<layer name>" suffix.  The space leads to a
    # malformed Tcl list.  We need to replace the space with an underscore.
    set gui_settings_layout [regsub -all {<layer name>} $gui_settings_layout "<layer_name>"]
} else {
    # In case this script is run without a GUI window open, then hardcode it.
    set gui_settings_layout {
        allowFontScaling allowVectorFont allowVerticalTextDrawing brightness cellEdgeLabelScheme
        cellFilterSize cellLabelScheme cellShape childViewName colorAirline colorBackground colorCellBackSideBump colorCellBlackBox colorCellCore colorCellCover colorCellFrontSideBump
        colorCellHardMacro colorCellIO colorCellNormalHier colorCellPhysOnly colorCellSoftMacro colorCellSpare colorCellTSV colorContactLayer_<layer_name> colorContactRegionLayer_<layer_name> colorCoreArea colorDRCDefault colorDRCSelection colorDieArea colorDrag colorEditGroup colorEditHighlight colorFPRegion colorFillInst colorForeground colorGrid colorHighlight colorIOGuide colorMovebound colorNetConnectivity colorOverlapBlockage
        colorPACore colorPAKOHard colorPAKOHardMacro colorPAKOPartial colorPAKOSoft colorPASiteArray colorPathCaptureClockPaths colorPathCells colorPathCommonClockPaths colorPathDataPaths colorPathLaunchClockPaths colorPin colorPinBlockageLayer_<layer_name> colorPinGuide colorPinLayer_<layer_name> colorPort colorPortShapeLayer_<layer_name> colorPowerplanRegion colorPreview colorRPGroup colorRPKeepout colorRailAnalysisTap colorRegion colorRegionHighlight colorRouteCorridorShape
        colorRouteGuide colorRouteGuideViaAccessPreference colorRouteGuideWireAccessPreference colorRoutedLayer_<layer_name> colorRoutingBlockageLayer_<layer_name> colorSelected colorShapingBlockage colorTextObjectLayer_<layer_name> colorTopologyEdge colorTopologyNode colorVAGuardband colorVoltageArea colorWiringGridLayer_<layer_name> customCellFiltering customObjectFilterSize customWireFilterSize deepSelect designWindow doubleBuffering eipBrightness eipShowContext expandCellCore expandCellHardMacro expandCellILM expandCellIO
        expandCellOthers expandCellSoftMacro expandFillInst fillMaskWithLayer filterBlockage filterCell filterCellBackSideBump filterCellBlackBox filterCellCore filterCellCover filterCellExtraText filterCellFlipChip filterCellFrontSideBump filterCellHardMacro filterCellIO filterCellNormalHier filterCellPhysOnly filterCellSoftMacro filterCellSpare filterCellTSV filterCellText filterCellTextArea filterContact filterContactLayers filterContactRegion
        filterCoreArea filterDieArea filterEditGroup filterFPRegion filterFillInst filterGuide filterIOGuide filterIOGuideText filterMargin filterMarginHard filterMarginHardMacro filterMarginRouteBlockage filterMarginSoft filterMovebound filterMoveboundExtraText filterMoveboundText filterNetType filterOtherLayers filterOverlapBlockage filterPACore filterPAKO filterPAKOHard filterPAKOHardMacro filterPAKOPartial filterPAKOSoft
        filterPASite filterPASiteArray filterPASiteArrayText filterPASiteText filterPin filterPinBlackBox filterPinBlockage filterPinBlockageText filterPinCellType filterPinClock filterPinCore filterPinGround filterPinGuide filterPinGuideText filterPinHardMacro filterPinNWell filterPinOthers filterPinPWell filterPinPad filterPinPower filterPinReset filterPinScan filterPinSignal filterPinSoftMacro filterPinText
        filterPinTieHigh filterPinTieLow filterPinType filterPolyContactLayers filterPolyLayers filterPort filterPortShape filterPortShapeAccess filterPortShapeText filterPortText filterPowerplanRegion filterRPGroup filterRPGroupText filterRPKeepout filterRailAnalysisTap filterRoute filterRouteCorridorShape filterRouteCorridorShapeText filterRouteGuide filterRouteGuideText filterRouteGuideViaAccessPreference filterRouteGuideWireAccessPreference filterRouteType filterRouted filterRoutedClock
        filterRoutedCoreWire filterRoutedDetailed filterRoutedFill filterRoutedFollowPin filterRoutedGRoute filterRoutedGround filterRoutedNWell filterRoutedNoNet filterRoutedOPC filterRoutedPGAugment filterRoutedPWell filterRoutedPinConMIO filterRoutedPinConStd filterRoutedPower filterRoutedRDL filterRoutedReset filterRoutedRing filterRoutedScan filterRoutedShield filterRoutedSignal filterRoutedStrap filterRoutedText filterRoutedTieHigh filterRoutedTieLow filterRoutedTrunk
        filterRoutedUser filterRoutedZeroSkew filterRoutingBlockage filterRoutingBlockageText filterRoutingLayers filterShapingBlockage filterShapingBlockageText filterText filterTextObject filterTextSelected filterTopology filterTopologyEdge filterTopologyNode filterVAGuardband filterVoltageArea filterVoltageAreaExtraText filterVoltageAreaText filterWiringGrid filterWiringGridNonPrefDir filterWiringGridPrefDir gridName hatchCellBackSideBump hatchCellBlackBox hatchCellCore hatchCellCover
        hatchCellFrontSideBump hatchCellHardMacro hatchCellIO hatchCellNormalHier hatchCellPhysOnly hatchCellSoftMacro hatchCellSpare hatchCellTSV hatchContactLayer_<layer_name> hatchContactRegionLayer_<layer_name> hatchEditGroup hatchFPRegion hatchFillInst hatchMovebound hatchOverlapBlockage hatchPACore hatchPAKOHard hatchPAKOHardMacro hatchPAKOPartial hatchPAKOSoft hatchPASiteArray hatchPinBlockageLayer_<layer_name> hatchPinGuide hatchPinLayer_<layer_name> hatchPortShapeLayer_<layer_name>
        hatchPowerplanRegion hatchRPGroup hatchRPKeepout hatchRailAnalysisTap hatchRouteCorridorShape hatchRouteGuide hatchRouteGuideViaAccessPreference hatchRouteGuideWireAccessPreference hatchRoutedLayer_<layer_name> hatchRoutingBlockageLayer_<layer_name> hatchShapingBlockage hatchTextObjectLayer_<layer_name> hatchTopologyNode hatchVAGuardband hatchVoltageArea hatchWiringGridLayer_<layer_name> infoTipLocation lineStyleCoreArea lineStyleDieArea lineStyleEditGroup lineStyleFPRegion lineStyleFillInst lineStyleMovebound lineStyleOverlapBlockage lineStylePAKOHard
        lineStylePAKOHardMacro lineStylePAKOPartial lineStylePAKOSoft lineStylePinGuide lineStylePowerplanRegion lineStyleRPGroup lineStyleRPKeepout lineStyleRailAnalysisTap lineStyleRouteGuide lineStyleShapingBlockage lineStyleTopologyEdge lineStyleTopologyNode lineStyleVAGuardband lineStyleVoltageArea lineWidthCoreArea lineWidthDieArea lineWidthEditGroup lineWidthFPRegion lineWidthFillInst lineWidthIOGuide lineWidthMovebound lineWidthOverlapBlockage lineWidthPAKOHard lineWidthPAKOHardMacro lineWidthPAKOPartial
        lineWidthPAKOSoft lineWidthPinGuide lineWidthPowerplanRegion lineWidthRPGroup lineWidthRPKeepout lineWidthRailAnalysisTap lineWidthRouteGuide lineWidthShapingBlockage lineWidthTopologyEdge lineWidthTopologyNode lineWidthVAGuardband lineWidthVoltageArea minimizeRedrawArea netRenderScheme overlayDesigns partialRedrawUpdates pathNetRenderLimit pathNetRenderScheme pathRenderLimit pinColorScheme renderAntiAlias renderQuality reverseWheel selectBlockage selectCell
        selectCellBlackBox selectCellCore selectCellCover selectCellFlipChip selectCellHardMacro selectCellIO selectCellNormalHier selectCellPhysOnly selectCellSoftMacro selectCellSpare selectCellTSV selectContact selectContactRegion selectCoreArea selectDieArea selectEditGroup selectFillInst selectGuide selectIOGuide selectLayer_<layer_name> selectMargin selectMarginHard selectMarginHardMacro selectMarginRouteBlockage selectMarginSoft
        selectMovebound selectOverlapBlockage selectPACore selectPAKO selectPASiteArray selectPin selectPinBlackBox selectPinBlockage selectPinClock selectPinCore selectPinGround selectPinGuide selectPinHardMacro selectPinNWell selectPinOthers selectPinPWell selectPinPad selectPinPower selectPinReset selectPinScan selectPinSignal selectPinSoftMacro selectPinTieHigh selectPinTieLow selectPort
        selectPortShape selectPowerplanRegion selectRPGroup selectRPKeepout selectRailAnalysisTap selectRoute selectRouteCorridorShape selectRouteGuide selectRouted selectRoutedClock selectRoutedCoreWire selectRoutedDetailed selectRoutedFill selectRoutedFollowPin selectRoutedGRoute selectRoutedGround selectRoutedNWell selectRoutedNoNet selectRoutedOPC selectRoutedPGAugment selectRoutedPWell selectRoutedPinConMIO selectRoutedPinConStd selectRoutedPower selectRoutedRDL
        selectRoutedReset selectRoutedRing selectRoutedScan selectRoutedShield selectRoutedSignal selectRoutedStrap selectRoutedTieHigh selectRoutedTieLow selectRoutedTrunk selectRoutedUser selectRoutedZeroSkew selectRoutingBlockage selectShapingBlockage selectTextObject selectTopology selectTopologyEdge selectTopologyNode selectVoltageArea selectWiringGrid shapeFilterSize shapeFilterWidthSize showBlockage showCell showCellBackSideBump showCellBlackBox
        showCellCore showCellCover showCellExtraText showCellFlipChip showCellFrontSideBump showCellHardMacro showCellIO showCellNormalHier showCellPhysOnly showCellSoftMacro showCellSpare showCellTSV showCellText showCellTextArea showColorMask showContact showContactLayer_<layer_name> showContactRegion showContactRegionLayer_<layer_name> showCoreArea showDimmed showEditGroup showFillInst showGuide showIOGuide
        showIOGuideText showInfoTip showLayer_<layer_name> showMargin showMarginHard showMarginHardMacro showMarginRouteBlockage showMarginSoft showMovebound showMoveboundExtraText showMoveboundText showOverlapBlockage showPACore showPAKO showPAKOHard showPAKOHardMacro showPAKOPartial showPAKOSoft showPASite showPASiteArray showPASiteArrayText showPASiteText showPin showPinBlackBox showPinBlockage
        showPinBlockageLayer_<layer_name> showPinBlockageText showPinClock showPinCore showPinGround showPinGuide showPinGuideText showPinHardMacro showPinLayer_<layer_name> showPinNWell showPinOthers showPinPWell showPinPad showPinPower showPinReset showPinScan showPinSignal showPinSoftMacro showPinText showPinTieHigh showPinTieLow showPort showPortShape showPortShapeAccess showPortShapeLayer_<layer_name>
        showPortShapeText showPortText showPowerplanRegion showRPGroup showRPGroupText showRPKeepout showRailAnalysisTap showRoute showRouteCorridorShape showRouteCorridorShapeText showRouteGuide showRouteGuideText showRouteGuideViaAccessPreference showRouteGuideWireAccessPreference showRouted showRoutedClock showRoutedCoreWire showRoutedDetailed showRoutedFill showRoutedFollowPin showRoutedGRoute showRoutedGround showRoutedLayer_<layer_name> showRoutedNWell showRoutedNoNet
        showRoutedOPC showRoutedPGAugment showRoutedPWell showRoutedPinConMIO showRoutedPinConStd showRoutedPower showRoutedRDL showRoutedReset showRoutedRing showRoutedScan showRoutedShield showRoutedSignal showRoutedStrap showRoutedText showRoutedTieHigh showRoutedTieLow showRoutedTrunk showRoutedUser showRoutedZeroSkew showRoutingBlockage showRoutingBlockageLayer_<layer_name> showRoutingBlockageText showScrollBars showShapingBlockage showShapingBlockageText
        showText showTextObject showTextObjectLayer_<layer_name> showTextSelected showTopology showTopologyEdge showTopologyNode showVAGuardband showViaTypeColor showVoltageArea showVoltageAreaExtraText showVoltageAreaText showWiringGrid showWiringGridLayer_<layer_name> showWiringGridNonPrefDir showWiringGridPrefDir slctStartLevel slctStopLevel timesNormalRendered timesSandboxRendered unplacedPinLocation utilizationLabeling viewLevel viewType 
    }
}

#########################
# regexp character classes
#########################
puts "...getting regexp char classes"
set regexp_char_classes [list :alpha: :upper: :lower: :digit: :xdigit: :alnum: :blank: :space: :punct: :graph: :cntrl: ]

###############################################################################
# G_variables.  rdt G_var names are stored in the secret ::GLOBAL_VAR::global_var
# array.  The array name will also include comma separated keywords like history
# and subst and constant.
###############################################################################
puts "...getting G_vars"
set Gvar_list {}
set Gvar_array_list {}
foreach g_var [lsort [info var G_*]] {
    if [array exists $g_var] {
        lappend Gvar_list "${g_var}("
        foreach name [lsort [array names $g_var]] {
            lappend Gvar_array_list "${g_var}($name)"
        }
    } else {
        lappend Gvar_list $g_var
    }
}
# Put the complete array names at the end of the list.  This is handy for the popup menu.
set Gvar_list [concat $Gvar_list $Gvar_array_list]

######################################################################
# Form a nested dictionary of attributes of object classes.
#  attribute_dict['class']['attr_name'] = choices
######################################################################
puts "...getting class attributes"
set attribute_dict [dict create]

# Dump list_attributes 
redirect -variable attribute_list {list_attributes -nosplit}
set attribute_list [split $attribute_list "\n"]
set start [expr {[lsearch -glob $attribute_list "-----*"]+1}]
set attribute_list [lrange $attribute_list $start end]

# ...again but for -application
redirect -variable attribute_class_list {list_attributes -nosplit -application}
set attribute_class_list [split $attribute_class_list "\n"]
set start [expr {[lsearch -glob $attribute_class_list "-----*"]+1}]
set attribute_class_list [lrange $attribute_class_list $start end]

# Now iterate over these lists to fill up the attribute dictionary
foreach entry [concat $attribute_list $attribute_class_list] {
    # Skip invalid entries
    if {[llength $entry]<3} {continue}

    # Parse entry for attr_name(like "length"), attr_class(like "wire"), and attr_datatype(like "float")
    set attr_name      [lindex $entry 0]                                                 
    set attr_class     [lindex $entry 1]
    set attr_datatype  [lindex $entry 2]

    # If necessary, initialize a dict for the class of this entry
    #   and also a subdict "choices".  
    if {![dict exists $attribute_dict $attr_class]} {
        dict set attribute_dict $attr_class [dict create]
    }

    # Derive the attribute possible values (data type, or constrained list)
    if {[llength $entry]>=5} {
        set attr_choices [lrange $entry 4 end]
    } else {
        set attr_choices $attr_datatype
    }

    # Fill up the class dict: key=attr-name, value=attr_choices
    dict set attribute_dict $attr_class $attr_name $attr_choices
}

######################################################################
# Form data structures from the ::techfile_info array
#   techfile_types - List
#   techfile_layers - Dict (keys = types, values = list of layers)
#   techfile_attributes - Dict (keys = "type:layer" - values = list of attributes)
######################################################################
set techfile_types {}
set techfile_layer_dict [dict create]
set techfile_attr_dict  [dict create]
if {[command_exists ::tech::read_techfile_info] } {
    # This command creates the ::techfile_info array
    ::tech::read_techfile_info
    foreach name [lsort [array names ::techfile_info]] {
        lassign [split $name ":"] Type Layer
        if {$Type ni $techfile_types} {
            lappend techfile_types $Type
        }
        dict lappend techfile_layer_dict $Type $Layer
        dict set techfile_attr_dict $name [dict keys $::techfile_info($name)]
    }
}
################################################################################
### Now  write out the data structures in JSON format!
################################################################################
# 1)  Setup the output directory and dump the log
set outdir $::env(WARD)/TclComplete
TclComplete::mkdir_fresh $outdir
puts "Making new \$WARD/TclComplete directory..."

set log [open $outdir/WriteTclCompleteFiles.log w]
puts $log "#######################################################"
puts $log "### WriteNetlistInfo.log ##############################"
puts $log "#######################################################"
puts $log "Generated by: $::env(USER)"
puts $log "          at: [date]"
puts $log "        WARD: $::env(WARD)"
if [info exists ::env(TOOL_CFG)] {
    puts $log "    based on: $::env(TOOL_CFG)"
}
close $log 

# 2) Write data structures out in JSON format.
#-------------------------------------
#  All the commands in a JSON list.
#-------------------------------------
    TclComplete::write_json $outdir/commands [TclComplete::list_to_json $all_command_list] 
    puts "...commands.json file complete."

#-------------------------------------
#  All the packages in a JSON list.
#-------------------------------------
    TclComplete::write_json $outdir/packages [TclComplete::list_to_json $package_list] 
    puts "...packages.json file complete."
#-----------------------------------------
# Command options in a JSON dict of lists.
#   key = command name
#   value = ordered list of options
#-----------------------------------------
    TclComplete::write_json $outdir/options [TclComplete::dict_of_lists_to_json $opt_dict]
    puts "...options.json file complete."

#-----------------------------------------
# Command option details in a JSON dictionary of dictionaries
#   key = command name
#   value = dictionary with key=option and value=details
#-----------------------------------------
    TclComplete::write_json $outdir/details [TclComplete::dict_of_dicts_to_json $details_dict]
    puts "...details.json file complete."

#-----------------------------------------
# Command descriptions in a JSON dictionary
#   key = command name
#   value = command description
#-----------------------------------------
    TclComplete::write_json $outdir/descriptions [TclComplete::dict_to_json $desc_dict] 
    puts "...descriptions.json file complete."

#----------------------------------------------------
# Write out aliases as Vim insert mode abbreviations
#----------------------------------------------------
    set f   [open $outdir/aliases.vim w]
    puts $f "iabbrev fic foreach_in_collection"
    puts $f "iabbrev ga  get_attribute"
    puts $f "iabbrev cs  change_selection"
    puts $f "iabbrev gs  get_selection"
    
    close $f
    puts "...aliases.vim file complete."

#----------------------------------------------------
# Write out attributes as a big fat JSON dict of dicts.
#----------------------------------------------------
    TclComplete::write_json $outdir/attributes [TclComplete::dict_of_dicts_to_json $attribute_dict] 
    puts "...attributes.json file complete."

#-------------------------------------
#  G variables which already exists in the session.
#-------------------------------------
    TclComplete::write_json $outdir/g_vars [TclComplete::list_to_json $Gvar_list]
    puts "...g_vars.json file complete."

    TclComplete::write_json $outdir/g_var_arrays [TclComplete::list_to_json $Gvar_array_list] 
    puts "...g_var_arrays.json file complete."
    
#-------------------------------------
#  iccpp parameters in a JSON ordered list
#-------------------------------------
    TclComplete::write_json $outdir/iccpp [TclComplete::list_to_json $iccpp_param_list]
    puts "...iccpp.json file complete."
    TclComplete::write_json $outdir/iccpp_dict [TclComplete::dict_to_json $iccpp_param_dict] 
    puts "...iccpp_dict.json file complete."

#-------------------------------------
#  icc2 app options
#-------------------------------------
    TclComplete::write_json $outdir/app_options [TclComplete::dict_to_json $app_option_dict] 
    puts "...app_options.json file complete."
    
#-------------------------------------
#  techfile information
#-------------------------------------
    TclComplete::write_json $outdir/techfile_types [TclComplete::list_to_json $techfile_types]
    puts "...techfile_types.json file complete."
    TclComplete::write_json $outdir/techfile_layer_dict [TclComplete::dict_of_lists_to_json $techfile_layer_dict]
    puts "...techfile_layer_dict.json file complete."
    TclComplete::write_json $outdir/techfile_attr_dict [TclComplete::dict_of_lists_to_json $techfile_attr_dict]
    puts "...techfile_attr_dict.json file complete."

#-------------------------------------
#  existing designs in your block
#-------------------------------------
    TclComplete::write_json $outdir/designs [TclComplete::list_to_json [lsort [get_attribute [get_designs -quiet] name]]]
    puts "...designs.json file complete."
    
#-------------------------------------
#  app_vars
#-------------------------------------
    TclComplete::write_json $outdir/app_vars [TclComplete::list_to_json $app_var_list]
    puts "...app_vars.json file complete."
    
#-------------------------------------
#  gui Layout window setting
#-------------------------------------
    TclComplete::write_json $outdir/gui_settings_layout [TclComplete::list_to_json $gui_settings_layout] 
    puts "...gui_settings_layout.json file complete."
    
#-------------------------------------
#  regexp character classes
#-------------------------------------
    TclComplete::write_json $outdir/regexp_char_classes [TclComplete::list_to_json $regexp_char_classes]
    puts "...regexp_char_classes.json file complete."
#-------------------------------------
#  environment variables
#-------------------------------------
    
    TclComplete::write_json $outdir/environment [TclComplete::dict_to_json [regsub -all {"} [array get ::env] {\"}]] 
    # " 
    puts "...environment.json file complete."
    
#----------------------------------------------------
# write out syntax highlighting commands
#----------------------------------------------------
    file mkdir "$outdir/syntax"
    set f [open "$outdir/syntax/tcl.vim" w]
    puts $f "\"syntax coloring for g_variables"
    puts $f "\"-------------------------------"
    puts $f "syntax match g_var /\\<\\CG_\\w\\+/"
    puts $f "highlight link g_var title"

    puts $f "\"syntax coloring for procs and commands"
    puts $f "\"--------------------------------------"

    foreach cmd $all_command_list {
        if {[info procs $cmd]!=""} {
            puts $f "syn keyword tclproccommand $cmd"
        } else {
            puts $f "syn keyword tclcommand $cmd"
        }
    }

    puts $f "\"syntax coloring for attributes"
    puts $f "\"-------------------------------"
    set attr_syntax_list {}
    dict for {class class_dict} $attribute_dict {
        foreach attr_name [dict keys $class_dict] {
            lappend attr_syntax_list $attr_name
        }
    }
    set attr_syntax_list [lsort -unique $attr_syntax_list]
    foreach attr_name $attr_syntax_list {
        puts $f "syn keyword tclexpand $attr_name"
    }

    puts "...syntax/tcl.vim file complete."
    close $f


# Clean up time.  Give Tcl some memory back.
unset all_command_list
unset app_option_list
unset app_var_list
unset details_dict
unset desc_dict
unset opt_dict
unset app_option_dict
unset iccpp_param_dict
unset techfile_attr_dict
unset techfile_layer_dict
unset gui_settings_layout

puts "...done\n"
