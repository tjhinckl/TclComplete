# TclComplete is a Vim auto-completion plugin for Tcl and Synopsys Tcl.
Author:  Chris Heithoff ( christopher.b.heithoff@intel.com )  

Use your <tab> key to trigger auto-completion specialized for your Tcl.

See doc/TclComplete.txt (in this repo) for further details.

Visit this InsideBlue page for demonstration videos:  
https://soco.intel.com/groups/vim-users/blog/2018/07/13/auto-completion-for-synopsystcl



==============================================================================
## Installation and setup
1.  Vim8.0 or above is required.  
2.  To install the plugin, make a pack directory in your ~/.vim folder and a subdirectory for the plugin.
>     mkdir -p ~/.vim/pack/from_gitlab/start
>     cd ~/.vim/pack/from_gitlab/start
>     git clone https://gitlab.devtools.intel.com/cbheitho/TclComplete
4.  Restart Vim and generate the help tags file.
>     :helptags ALL
5.  In your ~/.vimrc, you *must* enable filetype plugins
>     filetype plugin indent on

