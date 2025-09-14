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
#	relative or absolute path to the current configuration file
#
# file_types
#	types that will be displayed when opening new file
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
#	unless the file name is an empty string
#
# fileOpenStartUp
#   - opens the file named as command line argument
#
# fileOpenDialogBox
#   - opens dialog box for selecting a file to open
#
# fileSaveDialogBox
#   - opens dialog box for saving a file under new name if there is no
#	current file
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
	global curcfg cfg_list
	global CFG_VERSION
	global gui

	set curcfg [newObjectId $cfg_list "cfg"]
	lappend cfg_list $curcfg

	namespace eval ::cf::[set curcfg] {}
	upvar 0 ::cf::[set ::curcfg]::dict_run dict_run
	upvar 0 ::cf::[set ::curcfg]::dict_run_gui dict_run_gui
	upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg
	upvar 0 ::cf::[set ::curcfg]::execute_vars execute_vars

	set dict_cfg [dict create]
	setOption "version" $CFG_VERSION

	set dict_run [dict create]
	set dict_run_gui [dict create]
	set execute_vars [dict create]

	setToRunning "eid" ""
	setToRunning "oper_mode" "edit"
	setToRunning "auto_execution" 1
	setToRunning "no_auto_execute_nodes" {}
	setToRunning "cfg_deployed" false
	setToRunning "stop_sched" true
	setToRunning "undolevel" 0
	setToRunning "redolevel" 0
	if { $gui } {
		setToRunning_gui "canvas_list" {}
		setToRunning_gui "curcanvas" [newCanvas ""]
	}
	setToRunning "current_file" ""
	setToRunning "modified" false
	saveToUndoLevel 0

	if { $gui } {
		.bottom.oper_mode configure -text "[getFromRunning "oper_mode"] mode"
		updateProjectMenu
	}
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

	.menubar.file delete 10 end
	.menubar.file add separator

	foreach cfg $cfg_list {
		set fname [getFromRunning "current_file" $cfg]
		if { $fname == "" } {
			set fname "untitled[string range $cfg 3 end]"
		}

		set modified ""
		if { [getFromRunning "modified" $cfg] } {
			set modified " *"
		}
		.menubar.file add checkbutton -label "$fname$modified" -variable curcfg \
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
	global curcfg showTree gui

	if { $curcfg == 0 } {
		set curcfg "cfg0"
	}

	setOperMode [getFromRunning "oper_mode"]
	if { $gui } {
		applyOptionsToGUI
		switchCanvas none
		redrawAll
		updateProjectMenu
		refreshToolBarNodes
		setWmTitle [getFromRunning "current_file"]
		if { $showTree } {
			refreshTopologyTree
		}

		toggleAutoExecutionGUI [getFromRunning "auto_execution"]
	}
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
	global remote curcfg baseTitle imunesVersion imunesAdditions

	if { $fname == "" } {
		set fname "untitled[string range $curcfg 3 end]"
	}

	set modified ""
	if { [getFromRunning "modified"] } {
		set modified " *"
	}

	set remote_str ""
	if { $remote != "" } {
		global isOSfreebsd isOSlinux

		if { $isOSfreebsd } {
			set os "FreeBSD"
		} elseif { $isOSlinux } {
			set os "Linux"
		}

		set remote_str "remote $os host '$remote' - "
	}
	wm title . "$baseTitle - $remote_str$fname$modified"
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
	global showTree autorearrange_enabled gui

	readCfgJson [getFromRunning "current_file"]

	if { $gui } {
		set canvas_list [getFromRunning_gui "canvas_list"]
		if { $canvas_list == {} } {
			newCanvas ""
			set canvas_list [getFromRunning_gui "canvas_list"]

			set autorearrange_enabled 1
		}
		setToRunning_gui "curcanvas" [lindex $canvas_list 0]
	}

	applyOptionsToGUI

	if { $gui } {
		switchCanvas none

		set node_list [getFromRunning "node_list"]
		foreach gui_node_id [dict keys [cfgGet "gui" "nodes"]] {
			if { ! [isPseudoNode $gui_node_id] && $gui_node_id ni $node_list } {
				cfgUnset "gui" "nodes" $gui_node_id
			}
		}

		set link_list [getFromRunning "link_list"]
		foreach gui_link_id [dict keys [cfgGet "gui" "links"]] {
			if { ! [isPseudoLink $gui_link_id] && $gui_link_id ni $link_list } {
				cfgUnset "gui" "links" $gui_link_id
			}
		}

		redrawAll
	}

	setToRunning "oper_mode" "edit"
	setToRunning "cfg_deployed" false
	setToRunning "stop_sched" true
	setToRunning "undolevel" 0
	setToRunning "redolevel" 0
	setToRunning "modified" false

	if { $gui } {
		saveToUndoLevel 0
		setActiveToolGroup select
		updateProjectMenu
		setWmTitle [getFromRunning "current_file"]

		if { $showTree } {
			refreshTopologyTree
		}

		if { $autorearrange_enabled } {
			after 1000 set autorearrange_enabled 0
			rearrange ""
		}
	}
}

proc saveOptions { { option_names {} } } {
	global all_options all_gui_options default_options custom_options
	global gui execMode

	if { $option_names == {} } {
		set option_names [dict keys $default_options]
	}

	foreach {option_name default_value} $default_options {
		if { $option_name ni $option_names } {
			continue
		}

		if { $option_name in $all_options } {
			set gui_suffix ""
		} elseif { $option_name in $all_gui_options } {
			if { ! $gui } {
				continue
			}
			set gui_suffix "_gui"
		} else {
			continue
		}

		if { $option_name ni [dictGet $custom_options "custom_override"] } {
			set custom_value [dictGet $custom_options $option_name]
			if { $custom_value != "" } {
				set default_value $custom_value
			}
		}

		set value [getActiveOption $option_name]
		if { $value != $default_value } {
			setOption$gui_suffix $option_name $value
		} else {
			unsetOption$gui_suffix $option_name
		}
	}

	if { ! $gui && $execMode != "batch" } {
		set tmp [getFromRunning "modified"]
		cfgUnset "gui"
		setToRunning "modified" $tmp

		return
	}

	if { [cfgGet "gui" "options"] == "" } {
		set tmp [getFromRunning "modified"]
		cfgUnset "gui" "options"
		setToRunning "modified" $tmp
	}
}

proc applyOptionsToGUI {} {
	global all_options all_gui_options default_options
	global gui

	if { ! $gui } {
		return
	}

	foreach {option_name default_value} $default_options {
		if { $option_name in $all_options } {
			set gui_suffix ""
		} elseif { $option_name in $all_gui_options } {
			set gui_suffix "_gui"
		} else {
			continue
		}

		global $option_name

		set value [getOption$gui_suffix $option_name]
		if { $value == "" } {
			set value [getActiveOption $option_name]
		}

		set $option_name $value
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
	if { $selected_file != "" } {
		set current_file $selected_file
		setToRunning "current_file" $current_file

		saveCfgJson $current_file

		.bottom.textbox config -text "Saved [file tail $current_file]"

		setToRunning "modified" false
		updateProjectMenu
		setWmTitle $current_file
	}
}

#****f* filemgmt.tcl/fileOpenDialogBox
# NAME
#   fileOpenDialogBox -- open file dialog box
# SYNOPSIS
#   fileOpenDialogBox
# FUNCTION
#   Opens an open file dialog box.
#****
proc fileOpenDialogBox {} {
	global file_types

	set selected_file [tk_getOpenFile -filetypes $file_types]
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
	global cfg_list curcfg gui

	if { $gui && [checkAndPromptSave $curcfg] != 0 } {
		return
	}

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

		if { $gui } {
			setToRunning_gui "curcanvas" [lindex [getFromRunning_gui "canvas_list"] 0]
			switchCanvas none
			setToRunning "undolevel" 0
			setToRunning "redolevel" 0
			saveToUndoLevel 0
		}
	} else {
		newProject
	}

	if { $gui } {
		setActiveToolGroup select
		updateProjectMenu
	}
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
#   variables $all_options/$all_gui_options are legitimate options to give.
#***
proc readConfigFile { file_name } {
	global all_options all_gui_options custom_options last_config_file

	dputs "Reading custom editor preferences from: '$file_name'"

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

	foreach {option_name option_value} $read_options {
		if { $option_name ni "$all_options $all_gui_options custom_override" } {
			continue
		}

		set custom_options [dictSet $custom_options $option_name $option_value]
	}

	if { $read_options != "" } {
		dputs "	-> Loaded custom options: '$custom_options'"
	}

	set last_config_file $file_name
}

#****f* filemgmt.tcl/readConfigFiles
# NAME
#   readConfigFiles -- read configuration file
# SYNOPSIS
#   readConfigFiles
# FUNCTION
#   Read existing config files, in this order:
#	 - ./.imunesrc
#	 - /etc/imunes/config
#	 - $HOME/.imunes.rc if it exists, otherwise $XDG_CONFIG_HOME/imunes/config
#	 - ./.imunes.rc
#
#   After that, read /etc/imunes/override which overrides any previously set
#   options.
#
#	All the configuration files are JSON files, except for .imunesrc, which
#	is a TCL file which will be sourced. It is kept for compatibility
#	reasons.
#
#   NOTE: If $XDG_CONFIG_HOME is either not set or empty, a default of
#   $HOME/.config is used
#
#	Check config.example for the list of options.
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
