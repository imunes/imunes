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

global currentFile fileTypes
set currentFile ""

set fileTypes {
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

    set curcfg [newObjectId $cfg_list "cfg"]
    lappend cfg_list $curcfg

    namespace eval ::cf::[set curcfg] {}

    upvar 0 ::cf::[set ::curcfg]::canvas_list canvas_list
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    upvar 0 ::cf::[set ::curcfg]::undolevel undolevel
    upvar 0 ::cf::[set ::curcfg]::redolevel redolevel
    upvar 0 ::cf::[set ::curcfg]::undolog undolog
    upvar 0 ::cf::[set ::curcfg]::zoom zoom
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    upvar 0 ::cf::[set ::curcfg]::cfgDeployed cfgDeployed
    upvar 0 ::cf::[set ::curcfg]::eid eid
    upvar 0 ::cf::[set ::curcfg]::currentFile currentFile
    upvar 0 ::cf::[set ::curcfg]::stop_sched stop_sched

    loadCfgLegacy ""
    if { ! [info exists eid] } {
	set eid ""
    }

    set oper_mode edit
    .bottom.oper_mode configure -text "$oper_mode mode"
    set cfgDeployed false
    set stop_sched true
    set undolevel 0
    set redolevel 0
    set undolog(0) ""
    set zoom 1.0
    set canvas_list {}
    newCanvas ""
    set curcanvas [lindex $canvas_list 0]
    set currentFile ""
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
	set fname [set ::cf::[set cfg]::currentFile]
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
    upvar 0 ::cf::[set ::curcfg]::currentFile currentFile
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode

    setOperMode $oper_mode
    switchCanvas none
    redrawAll
    setWmTitle $currentFile
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
    upvar 0 ::cf::[set ::curcfg]::canvas_list canvas_list
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    upvar 0 ::cf::[set ::curcfg]::undolevel undolevel
    upvar 0 ::cf::[set ::curcfg]::redolevel redolevel
    upvar 0 ::cf::[set ::curcfg]::undolog undolog
    upvar 0 ::cf::[set ::curcfg]::currentFile currentFile
    upvar 0 ::cf::[set ::curcfg]::cfgDeployed cfgDeployed
    upvar 0 ::cf::[set ::curcfg]::stop_sched stop_sched
    global showTree

    set fileName [file tail $currentFile]
    set fileId [open $currentFile r]
    set cfg ""
    foreach entry [read $fileId] {
	lappend cfg $entry
    }
    close $fileId
    loadCfgLegacy $cfg
    set curcanvas [lindex $canvas_list 0]
    switchCanvas none
    redrawAll
    set cfgDeployed false
    set stop_sched true
    set undolevel 0
    set redolevel 0
    set undolog(0) $cfg
    setActiveTool select
    updateProjectMenu
    setWmTitle $currentFile
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
proc saveFile { selectedFile } {
    upvar 0 ::cf::[set ::curcfg]::currentFile currentFile

    if { $selectedFile != "" } {
	set currentFile $selectedFile
	set fileName [file tail $currentFile]
	set fileId [open $currentFile w]
	dumpCfg file $fileId
	close $fileId
	.bottom.textbox config -text "Saved $fileName"
	updateProjectMenu
	setWmTitle $currentFile
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
    global fileTypes

    set selectedFile [tk_getOpenFile -filetypes $fileTypes]
    if { $selectedFile != "" } {
	newProject
	upvar 0 ::cf::[set ::curcfg]::currentFile currentFile
	set currentFile $selectedFile
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
    upvar 0 ::cf::[set ::curcfg]::currentFile currentFile
    global fileTypes

    if { $currentFile == "" } {
	set selectedFile [tk_getSaveFile -filetypes $fileTypes -initialfile\
		   untitled -defaultextension .imn]
	saveFile $selectedFile
    } else {
	saveFile $currentFile
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
    upvar 0 ::cf::[set ::curcfg]::currentFile currentFile
    global fileTypes

    set selectedFile [tk_getSaveFile -filetypes $fileTypes -initialfile\
	       untitled -defaultextension .imn]

    saveFile $selectedFile
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
      
    if { [llength $cfg_list] > 1 } {
	set cfg_list [removeFromList $cfg_list $curcfg]

        set cfg [lindex $cfg_list 0]
        loadCfgLegacy $cfg
        set curcfg $cfg

        upvar 0 ::cf::[set ::curcfg]::canvas_list canvas_list
        upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
        upvar 0 ::cf::[set ::curcfg]::undolevel undolevel
        upvar 0 ::cf::[set ::curcfg]::redolevel redolevel
        upvar 0 ::cf::[set ::curcfg]::undolog undolog
        upvar 0 ::cf::[set ::curcfg]::currentFile currentFile

        set curcanvas [lindex $canvas_list 0]
        switchCanvas none
        set undolevel 0
        set redolevel 0
        set undolog(0) $cfg
        setActiveTool select
        updateProjectMenu
        switchProject
    }
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
    upvar 0 ::cf::[set ::curcfg]::currentFile currentFile

    set basedir $currentFile
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
