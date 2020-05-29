# TclComplete is a Vim auto-completion plugin for Tcl and Synopsys Tcl.
Author:  Chris Heithoff ( christopher.b.heithoff@intel.com )  

Use your TAB key to trigger auto-completion specialized for your Tcl.

See doc/TclComplete.txt (in this repo) for further details.

Visit this InsideBlue page for demonstration videos:  
https://soco.intel.com/groups/vim-users/blog/2018/07/13/auto-completion-for-synopsystcl



==============================================================================
## Installing this plugin
1.  Vim8.0 or above is required. 

     (see https://soco.intel.com/groups/vim-users/blog/2016/11/28/how-to-set-your-vim-version-at-intel )

2.  If you are on an Intel EC SLES11 machine, you must use a newer version
     of Git than the default version.

   This version is known to work.
>   /usr/intel/pkgs/git/2.12.0a/bin/git

   Add this line to your `~/.itools` file to use this as default
>   P:git      2.12.0a

3.  To install the plugin, make a pack directory in your ~/.vim folder and a subdirectory for the plugin.
>     mkdir -p ~/.vim/pack/from_gitlab/start
>     cd ~/.vim/pack/from_gitlab/start
>     git clone https://gitlab.devtools.intel.com/cbheitho/TclComplete
   If the git clone step doesn't work (because of a recent change to gitlab.devtools.intel.com) then disable ssL verification and try again.
>     git config --global http.sslVerify false

4.  In your ~/.vimrc, you *must* enable filetype plugins
>     filetype plugin indent on

5.  Start your tcl shell 

6.  Create the TclComplete files from your tcl shell:
For Synopsys tools
>     source ~/.vim/pack/from_gitlab/start/TclComplete/tcl/WriteTclCompleteFilesSynopsys.tcl
>     TclComplete::WriteFilesSynopsys <directory>
For Mentor tools
>     source ~/.vim/pack/from_gitlab/start/TclComplete/tcl/WriteTclCompleteFilesMentor.tcl
>     TclComplete::WriteFilesMentor <directory>




==============================================================================
## Introduction
   TclComplete.vim adds omni-completion for Tcl (filetype=tcl).

   Omni-completion is a built-in Vim auto-completion reserved for
   filetype-dependent user-defined completion.
   
   Vim ships with omni-completion for Python, Ruby, Tcl, Javascript, etc...
   but not a dedicated one for Tcl....so here it is!
   
==============================================================================
## Populating the completion files

   Because there can be different versions of Tcl, and also many
   possible procs that may vary from project to project, it is
   recommended to open up your Tcl shell (or icc2_shell or pt_shell..)
   and source the tcl/WriteTclCompleteFiles.tcl file.

   This will create a directory $WARD/TclComplete and populate it with
   .json files representing the data structures (lists, dicts, dicts of list, etc)
   for all the completion options.
   JSON format is not Vim specific, so similar plugins for other text
   editors can use these.  (contact Francis Creed for emacs versions)
   
   There will also be two Vim specific files.  One defines some
   insert mode aliases.  The other does syntax highlighting.

   NOTE:  This expects user to be an Intel back-end engineer who works
     in a back-end environment, where the $WARD is your work area. If 
     you need this changed, then modify the tcl script or fake it out
     by defining an environment variable called WARD.)

==============================================================================
## Location of TclComplete directory

By default, TclComplete will look for the following directories
  (in order of descending priority)
     $WARD/TclComplete
     $WARD/dp/user_scripts/TclComplete

To override default, include this in your .vimrc file:   
>  :let g:TclComplete#dir = "/non/default/directory/"

Hard-coded strings must be in quotes. 
Environment variables use $ prefixes.
Concatenate strings and expressions with a dot (.)
For example:
>  :let g:TclComplete#dir = $PROJ_AREA . "/TclComplete"

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
- variable names starting with $ 
- attributes in the get_attribute/set_attribute commands
- attributes after a -filter option
- expr functions
- command ensembles (dict, string, package, etc)
- package require
- iccpp parameters with iccpp_com::get_param and iccpp_com::set_param
- tech::get_techfile_info autocompletion 
- environment variable completion (after getenv, setenv and $::env( )
- get_xxx -design completion (also works for current_design and set_working_design)
- namespaces for "namespace" ensemble commands.
- inside a namespace eval ... {} block
- inside a oo:: {} block.
- things that act like namespace ensemble but aren't 
- dotted object attributes (like net.cell.full_name)
- array variable names
- filter special codes
- encoding names
- regexp character classes (like [:alnum:])
- "string is" arguments
- rdt stages and steps (if using an Intel RDT flow)

