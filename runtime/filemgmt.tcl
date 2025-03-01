#
# Copyright 2004-2013 University of Zagreb.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# This work was supported in part by Croatian Ministry of Science
# and Technology through the research contract #IP-2003-143.
#

##****h* imunes/filemgmt.tcl
# NAME
#  filemgmt.tcl -- file used for manipulation with files
# FUNCTION
#  This module is used for all file manipulations. In this file
#  a file is read, a new file opened or existing file saved.
# NOTES
# variables:
#
# current_file
#    relative or absolute path to the current configuration file
#
# file_types
#    types that will be displayed when opening new file
#
# procedures used for loading and storing the configuration file:
#
# newProject
#   - creates an empty project
#
# openFile
#   - loads configuration from current_file
#
# saveFile {selected_file}
#   - saves current configuration to a file named selected_file
#     unless the file name is an empty string
#
# fileOpenStartUp
#   - opens the file named as command line argument
#
# fileOpenDialogBox
#   - opens dialog box for selecting a file to open
#
# fileSaveDialogBox
#   - opens dialog box for saving a file under new name if there is no
#     current file
#
# fileSaveAsDialogBox
#   - opens dialog box for saving a file under new name
#****

global file_types

set file_types {
    { "IMUNES network configuration" {.imn} }
    { "All files" {*} }
}

#****f* filemgmt.tcl/newProject
# NAME
#   newProject -- new project
# SYNOPSIS
#   newProject
# FUNCTION
#   Configures and creates a new Imunes project.
#****
proc newProject {} {
    global running_options topology_options
    global curcfg cfg_list
    global CFG_VERSION

    set curcfg [newObjectId $cfg_list "cfg"]
    lappend cfg_list $curcfg

    namespace eval ::cf::[set curcfg] {}
    upvar 0 ::cf::[set ::curcfg]::dict_run dict_run
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg
    upvar 0 ::cf::[set ::curcfg]::execute_vars execute_vars

    set dict_cfg [dict create]
    setOption "version" $CFG_VERSION

    set dict_run [dict create]
    set execute_vars [dict create]

    set topology_options {}
    applyOptions

    setToRunning "eid" ""
    setToRunning "oper_mode" "edit"
    setToRunning "auto_execution" 1
    setToRunning "cfg_deployed" false
    setToRunning "stop_sched" true
    setToRunning "undolevel" 0
    setToRunning "redolevel" 0
    setToRunning "canvas_list" {}
    setToRunning "curcanvas" [newCanvas ""]
    setToRunning "current_file" ""
    saveToUndoLevel 0

    .bottom.oper_mode configure -text "[getFromRunning "oper_mode"] mode"
    updateProjectMenu
    switchProject
}

#****f* filemgmt.tcl/updateProjectMenu
# NAME
#   updateProjectMenu -- update project menu
# SYNOPSIS
#   updateProjectMenu
# FUNCTION
#   Updates current project menu.
#****
proc updateProjectMenu {} {
    global curcfg cfg_list

    .menubar.file delete 11 end
    .menubar.file add separator

    foreach cfg $cfg_list {
	set fname [getFromRunning "current_file" $cfg]
	if { $fname == "" } {
	    set fname "untitled[string range $cfg 3 end]"
	}
	.menubar.file add checkbutton -label $fname -variable curcfg \
	    -onvalue $cfg -command switchProject
    }
}

#****f* filemgmt.tcl/switchProject
# NAME
#   switchProject -- switch project
# SYNOPSIS
#   switchProject
# FUNCTION
#   This procedure is called when a project has been chosen in the file menu.
#****
proc switchProject {} {
    global running_options curcfg showTree

    if { $curcfg == 0 } {
        set curcfg "cfg0"
    }

    applyOptions

    setOperMode [getFromRunning "oper_mode"]
    switchCanvas none
    redrawAll
    setWmTitle [getFromRunning "current_file"]
    if { $showTree } {
	refreshTopologyTree
    }

    toggleAutoExecutionGUI [getFromRunning "auto_execution"]
}

#****f* filemgmt.tcl/setWmTitle
# NAME
#   setWmTitle -- set window manager title
# SYNOPSIS
#   setWmTitle $fname
# FUNCTION
#   Sets the title for the current project window.
# INPUTS
#   * fname -- title
#****
proc setWmTitle { fname } {
    global curcfg baseTitle imunesVersion imunesAdditions

    if { $fname == "" } {
	set fname "untitled[string range $curcfg 3 end]"
    }
    wm title . "$baseTitle - $fname"
}

#****f* filemgmt.tcl/openFile
# NAME
#   openFile -- open file
# SYNOPSIS
#   openFile
# FUNCTION
#   Loads the configuration from the file named current_file.
#****
proc openFile {} {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg
    global runtimeDir showTree recent_files pinned_recent_files

    set current_file [getFromRunning "current_file"]
    readCfgJson $current_file

    setToRunning "curcanvas" [lindex [getFromRunning "canvas_list"] 0]
    applyOptions

    switchCanvas none
    redrawAll

    setToRunning "oper_mode" "edit"
    setToRunning "cfg_deployed" false
    setToRunning "stop_sched" true
    setToRunning "undolevel" 0
    setToRunning "redolevel" 0
    saveToUndoLevel 0
    setActiveTool select
    set file_to_add [file normalize $current_file]
    if { ! [string match "[file normalize $runtimeDir]*" $file_to_add] && "!$file_to_add" ni $pinned_recent_files } {
	set recent_files [linsert [removeFromList $recent_files $file_to_add] 0 $file_to_add]
	updateRecentsMenu
    }

    updateProjectMenu
    setWmTitle $current_file

    if { $showTree } {
	refreshTopologyTree
    }
}

proc saveOptions { { options "" } } {
    global running_options custom_override topology_options

    if { $options == "" } {
	set options [dict keys $running_options]
    }

    foreach option_name $options {
	if { $option_name == "custom_override" } {
	    continue
	}

	global $option_name

	setOption $option_name [set $option_name]
    }
}

proc applyOptions {} {
    global running_options custom_override topology_options global_override

    foreach option_name [dict keys $running_options] {
	if { $option_name == "custom_override" || $option_name in $global_override } {
	    continue
	}

	global $option_name

	set topology_option [getOption $option_name]
	if { $topology_option != "" } {
	    set topology_options [dictSet $topology_options $option_name $topology_option]
	}

	resetRunningOpt $option_name
	set $option_name [getOpt "running" $option_name]
    }
}

proc refreshRunningOpts {} {
    global running_options global_override
    set global_override {}

    foreach name [dict keys $running_options] {
	setOpt "running" $name [getOpt [getOptSource $name] $name]
    }
}

proc applyRunningOpts {} {
    global running_options

    foreach option_name [dict keys $running_options] {
	if { $option_name == "custom_override" } {
	    continue
	}

	global $option_name

	set $option_name [getOpt "running" $option_name]
    }
}

#****f* filemgmt.tcl/saveFile
# NAME
#   saveFile -- save file
# SYNOPSIS
#   saveFile $selected_file
# FUNCTION
#   Loads the current configuration into the selected_file file.
# INPUTS
#   * selected_file -- name of the file where current configuration is saved.
#****
proc saveFile { selected_file } {
    global recent_files pinned_recent_files

    if { $selected_file != "" } {
	set current_file $selected_file
	setToRunning "current_file" $current_file

	try {
	    set fileId [open $selected_file w]
	} on error err {
	    after idle {.dialog1.msg configure -wraplength 4i}
	    tk_dialog .dialog1 "IMUNES error" \
		"Cannot save file '$selected_file':\n$err" \
		warning 0 Dismiss

	    return
	}

	saveCfgJson $current_file

	set file_to_add [file normalize $current_file]
	if { "!$file_to_add" ni $pinned_recent_files } {
	    set recent_files [linsert [removeFromList $recent_files $file_to_add] 0 $file_to_add]
	    updateRecentsMenu
	}

	.bottom.textbox config -text "Saved [file tail $current_file]"

	updateProjectMenu
	setWmTitle $current_file
    }
}

#****f* filemgmt.tcl/updateRecentsMenu
# NAME
#   updateRecentsMenu -- update recent files menu
# SYNOPSIS
#   updateRecentsMenu
# FUNCTION
#   Updates recently opened files menu.
#****
proc updateRecentsMenu {} {
    global recents_fname pinned_recent_files recent_files recents_number

    set m .menubar.file.recent_files
    $m delete 0 end

    if { [llength $recent_files] > $recents_number } {
	set recent_files [lrange $recent_files 0 [expr $recents_number - 1]]
    }

    if { $recents_fname != "" } {
	set fd [open $recents_fname w+]
	puts $fd [join $pinned_recent_files \n]
	puts $fd [join $recent_files \n]
	close $fd
    }

    $m add command -label "Pin current to 'Recent files'" -underline 0 -command {
	global recent_files pinned_recent_files

	set current_file [getFromRunning "current_file"]
	if { $current_file == "" } {
	    return
	}

	set file_to_add [file normalize $current_file]
	set pinned_recent_files [linsert [removeFromList $pinned_recent_files "!$file_to_add"] end "!$file_to_add"]

	set recent_files [removeFromList $recent_files $file_to_add]
	updateRecentsMenu
    }

    $m add command -label "Remove current from 'Recent files'" -underline 0 -command {
	global recent_files pinned_recent_files

	set current_file [getFromRunning "current_file"]
	if { $current_file == "" } {
	    return
	}

	set file_to_remove [file normalize $current_file]
	set pinned_recent_files [removeFromList $pinned_recent_files "!$file_to_remove"]

	set recent_files [removeFromList $recent_files $file_to_remove]
	updateRecentsMenu
    }

    $m add separator

    foreach fname $pinned_recent_files {
	if { $fname != "" } {
	    set fname [string range $fname 1 end]
	    $m add command -label "$fname" -command "fileOpenDialogBox $fname"
	}
    }

    $m add separator

    foreach fname $recent_files {
	if { $fname != "" } {
	    $m add command -label "$fname" -command "fileOpenDialogBox $fname"
	}
    }
}

#****f* filemgmt.tcl/fileOpenDialogBox
# NAME
#   fileOpenDialogBox -- open file dialog box
# SYNOPSIS
#   fileOpenDialogBox selected_file
# FUNCTION
#   Opens an 'open file dialog box' or a specified file.
# INPUTS
#   * args -- if an argument is given, do not open the dialog
#****
proc fileOpenDialogBox { args } {
    global file_types recent_files pinned_recent_files

    if { $args == "" } {
	set selected_file [tk_getOpenFile -filetypes $file_types]
    } else {
	set selected_file $args

	set err ""
	if { ! [file exists $selected_file] } {
	    set err "File '$selected_file' does not exist."
	} elseif { ! [file isfile $selected_file] } {
	    set err "Path '$selected_file' is not a file."
	}

	if { $err != "" } {
	    after idle {.dialog1.msg configure -wraplength 4i}
	    set reply [tk_dialog .dialog1 "File error" \
		"$err\nRemove from Recent files?" \
		question 0 Yes No]

	    if { $reply == 0 } {
		set pinned_recent_files [removeFromList $pinned_recent_files "!$selected_file"]
		set recent_files [removeFromList $recent_files $selected_file]

		updateRecentsMenu
	    }

	    return
	}
    }

    if { $selected_file != "" } {
	newProject
	setToRunning "current_file" $selected_file
	openFile
    }

}

#****f* filemgmt.tcl/fileSaveDialogBox
# NAME
#   fileSaveDialogBox -- save file dialog box
# SYNOPSIS
#   fileSaveDialogBox
# FUNCTION
#   Opens dialog box for saving a file under new name
#   if there is no current file.
#****
proc fileSaveDialogBox {} {
    global file_types

    set current_file [getFromRunning "current_file"]
    if { $current_file == "" } {
	set selected_file [tk_getSaveFile -filetypes $file_types -initialfile \
	    untitled -defaultextension .imn]
	saveFile $selected_file
    } else {
	saveFile $current_file
    }
}

#****f* filemgmt.tcl/fileSaveAsDialogBox
# NAME
#   fileSaveAsDialogBox -- save as file dialog box
# SYNOPSIS
#   fileSaveAsDialogBox
# FUNCTION
#   Opens dialog box for saving a file under new name.
#****
proc fileSaveAsDialogBox {} {
    global file_types

    set selected_file [tk_getSaveFile -filetypes $file_types -initialfile \
	untitled -defaultextension .imn]

    saveFile $selected_file
}

#****f* filemgmt.tcl/closeFile
# NAME
#   closeFile -- close opened file
# SYNOPSIS
#   closeFile
# FUNCTION
#   Closes the current file.
#****
proc closeFile {} {
    global cfg_list curcfg

    set idx [lsearch -exact $cfg_list $curcfg]
    set cfg_list [removeFromList $cfg_list $curcfg]
    set len [llength $cfg_list]
    if { $len > 0 } {
	if { $idx > $len } {
	    set idx "end"
	} elseif { $idx != 0 } {
	    incr idx -1
	}
	set curcfg [lindex $cfg_list $idx]

	setToRunning "curcanvas" [lindex [getFromRunning "canvas_list"] 0]
	switchCanvas none
	setToRunning "undolevel" 0
	setToRunning "redolevel" 0
	saveToUndoLevel 0
    } else {
	newProject
    }

    setActiveTool select
    updateProjectMenu
    switchProject
}

#****f* filemgmt.tcl/readConfigFile
# NAME
#   readConfigFile -- read configuration file
# SYNOPSIS
#   readConfigFile $file_name
# FUNCTION
#   Read config file given with $file_name. The file should be in JSON format,
#   and it will be skipped if it cannot be parsed. Only options given by
#   variable $custom_options are legitimate options to give.
#***
proc readConfigFile { file_name } {
    global running_options custom_options last_config_file

    set fd [open $file_name r]
    set json_options [read $fd]
    close $fd

    # remove all comments (all lines starting with #)
    regsub -all -line {^[ \t]*#.*\n} $json_options "" json_options

    try {
	json::json2dict $json_options
    } on error err {
	puts stderr "Error sourcing config file '$file_name':\n$err"

	return
    } on ok read_options {}

    foreach {option_name val} $read_options {
	if { $option_name ni "[dict keys $running_options] custom_override"  } {
	    continue
	}

	global $option_name

	set $option_name $val
	dict set custom_options $option_name $val
    }

    set last_config_file $file_name
}

#****f* filemgmt.tcl/readConfigFiles
# NAME
#   readConfigFiles -- read configuration file
# SYNOPSIS
#   readConfigFiles
# FUNCTION
#   Read config files, the first one that it finds:
#   	./.imunesrc
#   	./.imunes.rc
#   	$HOME/.imunes.rc
#   	$XDG_CONFIG_HOME/imunes/config
#   	/etc/imunes/config
#
#   After that, read /etc/imunes/override which overrides any previously set
#   options.
#
#   For compatibility with legacy versions, ./.imunesrc will be sourced as a
#   TCL script, but other files are treated as JSON config files.
#   NOTE: If $XDG_CONFIG_HOME is either not set or empty, a default of
#   $HOME/.config is used
#***
proc readConfigFiles {} {
    global custom_options home_path config_dir last_config_file

    set custom_options {}

    if { [file exists ".imunesrc"] } {
	safeSourceFile ".imunesrc"
	set last_config_file ".imunesrc"
    }

    if { $home_path == "" } {
	# not running on UNIX
	if { [file exists ".imunes.rc"] } {
	    readConfigFile ".imunes.rc"
	}

	return
    }

    set home_config "$config_dir/config"
    if { [file exists "$home_path/.imunes.rc"] } {
	# $home_path/.imunes.rc overrides $config_dir/config
	set home_config "$home_path/.imunes.rc"
    }

    foreach file_name "/etc/imunes/config $home_config .imunes.rc /etc/imunes/override" {
	if { [file exists $file_name] } {
	    readConfigFile $file_name
	}
    }
}

#****f* filemgmt.tcl/relpath
# NAME
#   relpath -- return background image filename relative to configuration file
# SYNOPSIS
#   relpath bkgImageFilename
# FUNCTION
#   Returns relative pathname
# INPUTS
#   * target --
#***
#####
# Some examples
# puts [relpath /root/imunes/labos.imn /root/EXAMPLES/labos.gif]
# ../EXAMPLES/labos.gif
# puts [relpath /root/EXAMPLES/labos.imn /root/EXAMPLES/labos.gif]
# ./labos.gif

;#proc relpath {basedir target} {
proc relpath { target } {
    set basedir [getFromRunning "current_file"]

    # Try and make a relative path to a target file/dir from base directory
    set bparts [file split [file normalize $basedir]]
    set tparts [file split [file normalize $target]]

    if { [lindex $bparts 0] eq [lindex $tparts 0] } {
	# If the first part doesn't match - there is no good relative path
	set blen [expr {[llength $bparts] - 1}]
	set tlen [llength $tparts]
	for { set i 1 } { $i < $blen && $i < $tlen } { incr i } {
	    if { [lindex $bparts $i] ne [lindex $tparts $i] } { break }
	}

	set path [lrange $tparts $i end]
	for {} { $i < $blen } { incr i } {
	    set path [linsert $path 0 ..]
	}

	# Full name:
	# [file normalize [join $path [file separator]]]
	# Relative file name:
	return [join $path [file separator]]
    }

    return $target
}

proc setOpt { option_source option_name value } {
    global ${option_source}_options

    set ${option_source}_options \
	[dictSet [set ${option_source}_options] ${option_name} $value]

    return [set ${option_source}_options]
}

proc getOpt { option_source option_name } {
    global ${option_source}_options

    return [dictGet [set ${option_source}_options] ${option_name}]
}

proc resetRunningOpt { option_name } {
    return [setOpt "running" $option_name \
	[getOpt [getOptSource $option_name] $option_name]]
}

proc getOptSource { option_name } {
    global custom_override

    foreach option_source "custom topology canvas" {
	global ${option_source}_options

	set ${option_name}_$option_source [dictGet [set ${option_source}_options] $option_name]
    }

    if { $option_name ni $custom_override } {
	if { [set ${option_name}_canvas] != "" } {
	    return "canvas"
	} elseif { [set ${option_name}_topology] != "" } {
	    return "topology"
	}
    }

    if { [set ${option_name}_custom] != "" } {
	return "custom"
    }

    return "default"
}
