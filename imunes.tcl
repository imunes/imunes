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

# $Id: imunes.tcl 149 2015-03-27 15:50:14Z valter $

#****h* imunes/imunes.tcl
# NAME
#    imunes.tcl
# FUNCTION
#    Starts imunes in batch or interactive mode. Include procedures from
#    external files and initializes global variables.
#
#	imunes [-b] [-e experiment_id] [filename]
#
#    When starting the program in batch mode the option -b must be
#    specified.
#
#    When starting the program with defined filename, configuration for
#    file "filename" is loaded to imunes.
#****

package require cmdline
package require ip
package require platform

set options {
    {e.arg	"" "specify experiment ID"}
    {eid.arg	"" "specify experiment ID"}
    {b		"batch mode on"}
    {batch	"batch mode on"}
    {d.secret	"debug mode on"}
    {i		"setup devfs rules for virtual nodes"}
    {v		"print IMUNES version"}
    {version	"print IMUNES version"}
}

set usage "\[-e | -eid eid\] topology.imn - Starting IMUNES GUI
imunes -b \[-e | -eid eid\] topology.imn - Starting experiment (batch)
imunes -b -e | -eid eid - Terminating experiment (batch)"

catch {array set params [::cmdline::getoptions argv $options $usage]} err
if { $err != "" } {
    puts stderr "Usage:"
    puts stderr $err
    exit
}

set fileName [lindex $argv 0]
if { ! [ string match "*.imn" $fileName ] && $fileName != "" } {
    puts stderr "File '$fileName' is not an IMUNES .imn file"
    exit
}

set initMode 0
if { $params(i) } {
    set initMode 1
}

set debug 0
set execMode interactive
if { $params(b) || $params(batch)} {
    if { $params(e) == "" && $params(eid) == "" && $fileName == "" } {
	puts stderr "Usage:"
	puts stderr $usage
	exit
    }
    catch {exec id -u} uid
    if { $uid != "0" } {
	puts "Error: To execute experiment, run IMUNES with root permissions."
	exit
    }
    set execMode batch
} else {
    if { $params(d) } {
	set debug 1
    }
}

set eid_base i[format %04x [expr {[pid] + [expr { round( rand()*10000 ) }]}]]
if { $params(e) != "" || $params(eid) != "" } {
    set eid_base $params(e)
    if { $params(eid) != "" } {
	set eid_base $params(eid)
    }
    if { $params(b) || $params(batch) } {
	    puts "Using experiment ID '$eid_base'."
    }
}

#
# Include procedure definitions from external files. There must be
# some better way to accomplish the same goal, but that's how we do it
# for the moment.
#
# The ROOTDIR and LIBDIR variables will be automatically set to the proper
# value by the installation script.
#

#****v* imunes.tcl/ROOTDIR
# NAME
#    ROOTDIR
# FUNCTION
#    The location of imunes library files. The ROOTDIR and LIBDIR variables
#    will be automatically set to the proper value by the installation script.
#*****

#****v* imunes.tcl/LIBDIR
# NAME
#    LIBDIR
# FUNCTION
#    The location of imunes library files. The ROOTDIR and LIBDIR variables
#    will be automatically set to the proper value by the installation script.
#*****

set LIBDIR ""
set ROOTDIR "."

if { $ROOTDIR == "." } {
    set BINDIR ""
} else {
    set BINDIR "bin"
}

set baseTitle "IMUNES"
set imunesVersion "Unknown"
set imunesCommit ""
set imunesChangedDate ""
set imunesAdditions ""

set verfile [open "$ROOTDIR/$LIBDIR/VERSION" r]
set data [read $verfile]
foreach line [split $data "\n"] {
    if {[string match "VERSION:*" $line]} {
	set imunesVersion [string range $line [expr [string first ":" $line] + 2] end]
    }
    if {[string match "Commit:*" $line]} {
	set imunesCommit [string range $line [expr [string first ":" $line] + 2] end]
    }
    if {[string match "Last changed:*" $line]} {
	set imunesChangedDate [string range $line [expr [string first ":" $line] + 2] end]
    }
    if {[string match "Additions:*" $line]} {
	set imunesAdditions [string range $line [expr [string first ":" $line] + 2] end]
    }
}

if { [string match "*Format*" $imunesCommit] } {
    set imunesChangedDate ""
    set imunesLastYear ""
} else {
    set imunesVersion "$imunesVersion (git: $imunesCommit)"
    set imunesLastYear [lindex [split $imunesChangedDate "-"] 0]
    set imunesChangedDate "Last changed: $imunesChangedDate"
}

if { $params(v) || $params(version)} {
    puts "IMUNES $imunesVersion"
    if { $imunesChangedDate != "" } {
	puts "$imunesChangedDate"
    }
    if { $imunesAdditions != "" } {
	puts "Additions: $imunesAdditions"
    }
    exit
}

set os [platform::identify]

# Runtime libriaries
foreach file [glob -directory $ROOTDIR/$LIBDIR/runtime *.tcl] {
    if { [string match -nocase "*linux.tcl" $file] != 1 } {
	source $file
    }
}

# Set default L2 node list
set l2nodes "hub lanswitch click_l2 rj45"
# Set default L3 node list
set l3nodes "genericrouter quagga xorp static click_l3 host pc"
# Set default supported router models
set supp_router_models "xorp quagga static"

if { [string match -nocase "*linux*" $os] == 1 } {
    # Limit default nodes on linux
    set l2nodes "lanswitch rj45"
    set l3nodes "genericrouter quagga static pc host"
    set supp_router_models "quagga static"
    source $ROOTDIR/$LIBDIR/runtime/linux.tcl
}
if { [string match -nocase "*freebsd*" $os] == 1 } {
    source $ROOTDIR/$LIBDIR/runtime/freebsd.tcl
    if { $initMode == 1 } {
	prepareDevfs
	exit
    }
}

if { $execMode == "batch" } {
    set err [checkSysPrerequisites]
    if { $err != "" } {
	puts $err
	exit
    }
}

# Configuration libraries
foreach file [glob -directory $ROOTDIR/$LIBDIR/config *.tcl] {
    source $file
}

# The following files need to be sourced in this particular order. If not
# the placement of the toolbar icons will be altered.
# L2 nodes
foreach file $l2nodes {
    source "$ROOTDIR/$LIBDIR/nodes/$file.tcl"
}
# L3 nodes
foreach file $l3nodes {
    source "$ROOTDIR/$LIBDIR/nodes/$file.tcl"
}
# additional nodes
source "$ROOTDIR/$LIBDIR/nodes/localnodes.tcl"
source "$ROOTDIR/$LIBDIR/nodes/annotations.tcl"

#
# Global variables are initialized here
#

#****v* imunes.tcl/prefs
# NAME
#    prefs
# FUNCTION
#    Contains the list of preferences. When starting a program
#    this list is empty.
#*****

# Clipboard
namespace eval cf::clipboard {}
set cf::clipboard::node_list {}
set cf::clipboard::link_list {}
set cf::clipboard::annotation_list {}
set cf::clipboard::canvas_list {}
set cf::clipboard::image_list {}

set cfg_list {}
set curcfg ""

#****v* imunes.tcl/editor_only
# NAME
#    editor_only -- if set, Experiment -> Execute is disabled
# FUNCTION
#    IMUNES GUI can be used in editor-only mode.i
#    This variable can be modified in .imunesrc.

set editor_only false

#****v* imunes.tcl/gui_unix
# NAME
#    gui_unix
# FUNCTION
#    false: IMUNES GUI is on MS Windows,
#    true: GUI is on FreeBSD / Linux / ...
#    Used in spawnShell to start xterm or command.com with NetCat
#*****

if { $tcl_platform(platform) == "unix" } {
    set gui_unix true
} else {
    set gui_unix false
}

set winOS false
if {[string match -nocase "*win*" [platform::identify]] == 1} {
    set winOS true
}

if {!$winOS} {
    catch {exec convert -version | head -1 | cut -d " " -f 1,2,3} imInfo
} else {
    set imInfo $env(PATH)
}

set hasIM true
if { [string match -nocase "*imagemagick*" $imInfo] != 1} {
    set hasIM false
}

set runtimeDir "/var/run/imunes"

#
# Read config files, the first one found: .imunesrc, $HOME/.imunesrc
#
# XXX
readConfigFile

#
# Initialization should be complete now, so let's start doing something...
#

if {$execMode == "interactive"} {
    foreach file "canvas copypaste drawing editor help theme initgui linkcfgGUI \
	mouse nodecfgGUI topogen widgets" {
	source "$ROOTDIR/$LIBDIR/gui/$file.tcl"
    }
    if { $debug == 1 } {
	source "$ROOTDIR/$LIBDIR/gui/debug.tcl"
    }

    newProject
    if { $argv != "" && [file exists $argv] } {
	set ::cf::[set curcfg]::currentFile $argv
	openFile
    }
    updateProjectMenu
    # Fire up the animation loop
    animate
    # Event scheduler - should be started / stopped on per-experiment base?
#     evsched
} else {
    if {$argv != ""} {
	if { ![file exists $argv] } {
	    puts "Error: file '$argv' doesn't exist"
	    exit
	}
	global currentFileBatch
	set currentFileBatch $argv
	set fileId [open $argv r]
	set cfg ""
	foreach entry [read $fileId] {
	    lappend cfg $entry
	}
	close $fileId

	set curcfg [newObjectId cfg]
	lappend cfg_list $curcfg
	namespace eval ::cf::[set curcfg] {}

	loadCfg $cfg

	if { [checkExternalInterfaces] } {
	    return
	}
	if { [allSnapshotsAvailable] == 1 } {
	    deployCfg
	    createExperimentFilesFromBatch
	}
    } else {
	set configFile "$runtimeDir/$eid_base/config.imn"
	set ngmapFile "$runtimeDir/$eid_base/ngnodemap"
	if { [file exists $configFile] && [file exists $ngmapFile] \
	    && $regular_termination } {
	    set fileId [open $configFile r]
	    set cfg ""
	    foreach entry [read $fileId] {
		lappend cfg $entry
	    }
	    close $fileId

	    set curcfg [newObjectId cfg]
	    lappend cfg_list $curcfg
	    namespace eval ::cf::[set curcfg] {}
	    upvar 0 ::cf::[set ::curcfg]::ngnodemap ngnodemap
	    upvar 0 ::cf::[set ::curcfg]::eid eid
	    set eid $eid_base

	    set fileId [open $ngmapFile r]
	    array set ngnodemap [gets $fileId]
	    close $fileId

	    loadCfg $cfg

	    terminateAllNodes $eid_base
	} else {
	    vimageCleanup $eid_base
	}

	deleteExperimentFiles $eid_base
    }
}
