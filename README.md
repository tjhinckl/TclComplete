# TclComplete is a Vim auto-completion plugin for Tcl and Synopsys Tcl.
Author:  Chris Heithoff ( christopher.b.heithoff@intel.com )  

Use your TAB key to trigger auto-completion specialized for your Tcl.

See doc/TclComplete.txt (in this repo) for further details.

<p align="center"><img src="TclComplete_commands.gif"></p>

==============================================================================
## Installing this plugin
1.  Vim8.0 or above is required. 

     (see https://intel.sharepoint.com/sites/intelvimusers/SitePages/Intel%20Vim%20Users/News1888624.aspx)

2.  If you are on an Intel EC SLES11 machine, you might need to use a non-default version of Git.

   This version is known to work.
    `/usr/intel/pkgs/git/2.8.4/bin/git`

   Consider setting up an alias for cloning, pulling or pushing with Intel's gitlab.
>     alias gitlab '/usr/intel/pkgs/git/2.8.4/bin/git'


3.  To install the plugin, make a pack directory in your ~/.vim folder and a subdirectory for the plugin.
>     mkdir -p ~/.vim/pack/from_gitlab/start
>     cd ~/.vim/pack/from_gitlab/start
>     git clone https://gitlab.devtools.intel.com/cbheitho/TclComplete

   If the git clone step doesn't work (because of a recent change to gitlab.devtools.intel.com) then add these git settings and try again.
>     git config --global http.sslCAPath /etc/ssl/certs
>     git config --global http.proxy http://proxy-chain.intel.com:911

4.  In your ~/.vimrc, you *must* enable filetype plugins
>     filetype plugin indent on

For core Tcl8.6 commands only, you can stop here.  The sample/TclComplete directory
is sufficient.

To optimize Tcl for your specific tool, follow these additional directions:

1.  Start your Tcl based tool (such as PrimeTime, FusionCompiler, etc)

2.  Run the command which will create the TclComplete directory underneath <directory>  
For Synopsys tools
>     source ~/.vim/pack/from_gitlab/start/TclComplete/tcl/WriteTclCompleteFilesSynopsys.tcl
>     TclComplete::WriteFilesSynopsys <directory>
For Mentor tools
>     source ~/.vim/pack/from_gitlab/start/TclComplete/tcl/WriteTclCompleteFilesMentor.tcl
>     TclComplete::WriteFilesMentor <directory>
For other tools (or if the above don't work)
>     source ~/.vim/pack/from_gitlab/start/TclComplete/tcl/WriteTclCompleteFilesStd.tcl
>     TclComplete::WriteFilesStd <directory>


==============================================================================
## Introduction
   TclComplete.vim adds omni-completion for Tcl (filetype=tcl).

   Omni-completion is a built-in Vim auto-completion reserved for
   filetype-dependent user-defined completion.
   
   Vim ships with omni-completion for Python, Ruby, Tcl, Javascript, etc...
   but not a dedicated one for Tcl....so here it is!
   
==============================================================================
## TclComplete directory description.

   The TclComplete directory contains a number of .json files representing 
   the data structures (lists, dicts, dicts of list, etc) for all the completion options.

   JSON format is not Vim specific, so similar plugins for other text
   editors can use these.  (contact Francis Creed for emacs versions)
   
   There will also be two Vim specific files.  One defines some
   insert mode aliases.  The other does syntax highlighting.

==============================================================================
## Location of TclComplete directory

By default, Vim will look hierarchically below a $WARD or $ward directory for a directory named TclComplete. 
Otherwise, it will use the sample/TclComplete directory in this plugin's location.  

To specify a different location, include this in your .vimrc file:   
>     :let g:TclComplete#dir = "/non/default/directory/"

 - Hard-coded strings must be in quotes.   
 - Environment variables use $ prefixes.  
 - Concatenate strings and expressions with a dot (.)  

For example:  
>     :let g:TclComplete#dir = $PROJ_AREA . "/TclComplete"

==============================================================================
## Entering TclComplete auto-completion

The `tab` key, or `^X ^O`  will trigger TclComplete compleion.                                         
      
This will bring up Vim's pop-up autocompletion menu.  

The menu is context aware, so you may be presented with a list of procs and 
commands, or a list of command -options, or attributes, or more.

==============================================================================
## Once the pop-up menu is open....

  Entering auto-complete mode will open a pop-up menu.  This is the same type
of pop-up menu used in Vim's built-in auto-complete modes. (:help insert_expand)

  `^N` and `^P` will switch to the next/previous choices.

  `^E` will end the pop-up menu and return to insert mode
  
  `^Y` will accept the current choice and stay in insert mode.  ('yes')

  `TAB`  When the pop-up menu is open, TAB will act like control-n (^N)

   `^D`   Scroll the pop-up menu down by 10 choices.

   `^U`   Scroll the pop-up menu up by 10 choices.

   (the scroll distance can be set by a g:TclComplete#popupscroll variable)

==============================================================================
## Wildcard mode.

  By default, the auto-completion works with wildcard patterns too.
  
  For example, if you type \*cells\* and then hit `TAB`, then any proc containing 
  the string 'cells' will appear in the popup menu.

==============================================================================
## Aliases become insert mode abbreviations
Some interactive Tcl shell aliases you defined when the $WARD/TclComplete collateral 
was generated will be converted into iabbrev commands in $WARD/TclComplete/aliases.vim.

In other words, type 'fic' followed by `space` will automatically replace
'fic' with foreach_in_collection. 

This plugin's Tcl script intentionally to limits the abbrevations to:
 `fic`   = foreach_in_collection
 `ga`    = get_attribute
 `cs`    = change_selection
 `gs`    = get_selection

To avoid triggering an abbreviation, type `ctrl-v space` 

==============================================================================
## Special categories of completion
- variable names starting with `$` 
- attributes in the `get_attribute` or `set_attribute` commands
- attributes after a `-filter` option
- `expr` functions
- command ensembles (`dict`, `string`, `package`, etc)
- `package require`
- filenames after the `-file` arg in `iproc_source` and `iproc_source_distributed`
- iccpp parameters with `iccpp_com::get_param` and `iccpp_com::set_param`
- `tech::get_techfile_info` autocompletion 
- environment variable completion (after `getenv`, `setenv` and `$::env( )`
- `get_xxx -design` completion (also works for `current_design` and `set_working_design`)
- namespaces for "namespace" ensemble commands.
- inside a `namespace eval ... {}` block
- inside a `oo:: {}` block.
- things that act like namespace ensemble but aren't 
- dotted object attributes (like net.cell.full_name)
- array variable names
- filter special codes
- encoding names
- regexp character classes (like `[:alnum:]`)
- `string is` arguments
- rdt stages and steps (if using an Intel RDT flow)

