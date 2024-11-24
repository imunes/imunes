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
    global curcfg cfg_list
    global CFG_VERSION

    set curcfg [newObjectId $cfg_list "cfg"]
    lappend cfg_list $curcfg

    namespace eval ::cf::[set curcfg] {}
    upvar 0 ::cf::[set ::curcfg]::dict_run dict_run
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    set dict_cfg [dict create]
    cfgSet "options" "version" $CFG_VERSION

    set dict_run [dict create]
    lappendToRunning "cfg_list" $curcfg
    setToRunning "eid" ""
    setToRunning "oper_mode" "edit"
    .bottom.oper_mode configure -text "[getFromRunning "oper_mode"] mode"
    setToRunning "cfg_deployed" false
    setToRunning "stop_sched" true
    setToRunning "undolevel" 0
    setToRunning "redolevel" 0
    setToRunning "zoom" 1.0
    setToRunning "canvas_list" {}
    setToRunning "curcanvas" [newCanvas ""]
    setToRunning "current_file" ""
    setToUndolog 0

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

    .menubar.file delete 10 end
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
    global curcfg showTree
    if { $curcfg == 0 } {
        set curcfg "cfg0"
    }

    setOperMode [getFromRunning "oper_mode"]
    switchCanvas none
    redrawAll
    setWmTitle [getFromRunning "current_file"]
    if { $showTree } {
	refreshTopologyTree
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
    global CFG_VERSION showTree

    set current_file [getFromRunning "current_file"]
    set dict_cfg [readCfgJson $current_file]
    set cfg_version [cfgGet "options" "version"]
    if { $cfg_version == "" } {
	puts "Loading legacy .imn configuration..."
	puts "This configuration will be saved as a new version (version $CFG_VERSION)."
	loadCfgLegacy ""
	set fileName [file tail $current_file]
	set fileId [open $current_file r]
	set cfg ""
	foreach entry [read $fileId] {
	    lappend cfg $entry
	}
	close $fileId
	loadCfgLegacy $cfg
    } elseif { $cfg_version < $CFG_VERSION } {
	puts "Loading older .imn configuration (version $cfg_version)..."
	puts "This configuration will be saved as a new version ($CFG_VERSION)."
	puts "Please check if everything is loaded/saved successfully."
    } elseif { $cfg_version > $CFG_VERSION } {
	puts "Your IMUNES version is too old for this configuration (version $cfg_version > $CFG_VERSION)."
	puts "Please install newer IMUNES or risk corrupting your topology."
    }

    setToRunning "curcanvas" [lindex [getFromRunning "canvas_list"] 0]
    switchCanvas none
    redrawAll
    setToRunning "cfg_deployed" false
    setToRunning "stop_sched" true
    setToRunning "undolevel" 0
    setToRunning "redolevel" 0
    setToUndolog 0
    setActiveTool select
    updateProjectMenu
    setWmTitle $current_file

    if { $showTree } {
	refreshTopologyTree
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
    if { $selected_file != ""} {
	set current_file $selected_file
	setToRunning "current_file" $current_file
	saveCfgJson $current_file

	set file_name [file tail $current_file]
	.bottom.textbox config -text "Saved $file_name"

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

    set current_file [getFromRunning "current_file"]
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
	setToUndolog 0
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
#   readConfigFile
# FUNCTION
#   Read config files, the first one found: .imunesrc, $HOME/.imunesrc
#***
proc readConfigFile {} {
    global exec_hosts editor_only
    global env
    if { [file exists ".imunesrc"] } {
	source ".imunesrc"
    } else {
	if { [catch { set myhome $env(HOME) }] } {
	    ;# not running on UNIX
	} else {
	    if { [file exists "$myhome/.imunesrc"] } {
	       source "$myhome/.imunesrc"
	    }
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
