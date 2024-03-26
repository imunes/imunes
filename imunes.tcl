# 2019-2020 Sorbonne University
# In this version of imunes we added a full integration of emulation of 
# Linux namespaces and CISCO routers, saving of parameters, VLANs, WiFi 
# emulation and other features
# This work was developed by Benadji Hanane and Oulad Said Chawki
# Supervised and maintained by Naceur Malouch - LIP6/SU
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

global dynacurdir
set LIBDIR "lib/imunes"
set ROOTDIR "/usr/local"
set dynacurdir "$ROOTDIR/$LIBDIR"
set curdir [pwd]


if { $ROOTDIR == "." } {
    set BINDIR ""
} else {
    set BINDIR "bin"
}

try {
    source "$ROOTDIR/$LIBDIR/helpers.tcl"
} on error { result options } {
    puts stderr "Could not find file helpers.tcl in $ROOTDIR/$LIBDIR:"
    puts stderr $result
    exit 1
}

safePackageRequire [list cmdline platform ip base64]

set initMode 0
set execMode interactive
set debug 0
set eid_base i[format %04x [expr {[pid] + [expr { round( rand()*10000 ) }]}]]
set printVersion 0
set prepareFlag 0
set forceFlag 0

set options {
    {e.arg	"" "Specify experiment ID"}
    {eid.arg	"" "Specify experiment ID"}
    {b		"Turn on batch mode"}
    {batch	"Turn on batch mode"}
    {d.secret	"Turn on debug mode"}
    {p		"Prepare virtual root file system"}
    {prepare	"Prepare virtual root file system"}
    {f		"Force virtual root preparation (delete existing vroot)"}
    {force	"Force virtual root preparation (delete existing vroot)"}
    {i		"Setup devfs rules for virtual nodes (Only on FreeBSD)"}
    {v		"Print IMUNES version"}
    {version	"Print IMUNES version"}
    {h		"Print this message"}
}

set usage [getPrettyUsage $options]
parseCmdArgs $options $usage

set baseTitle "IMUNES"
set imunesVersion "Unknown"
set imunesChangedDate ""
set imunesLastYear ""
set imunesAdditions ""

fetchImunesVersion
if { $printVersion } {
    printImunesVersion
    exit
}

set isOSfreebsd false
set isOSlinux false
set isOSwin false

setPlatformVariables

if { $prepareFlag } {
    prepareVroot
    exit
}

# Runtime libriaries
foreach file [glob -directory $ROOTDIR/$LIBDIR/runtime *.tcl] {
    if { [string match -nocase "*linux.tcl" $file] != 1 } {
	safeSourceFile $file
    }
}
# modification for namespace and cisco router

# Set default L2 node list
set l2nodes "hub lanswitch click_l2 rj45 stpswitch filter packgen ext"
# Set default L3 node list
set l3nodes "genericrouter quagga xorp static click_l3 host pc nat64 nouveauPc nouveauRouteur AP STA"
# Set default supported router models
set supp_router_models "xorp quagga static"

if { $isOSlinux } {
    # Limit default nodes on linux
    set l2nodes "lanswitch rj45 ext"
    set l3nodes "genericrouter quagga static host pc nat64 nouveauPc nouveauRouteur AP STA"
    set supp_router_models "quagga static"
    safeSourceFile $ROOTDIR/$LIBDIR/runtime/linux.tcl
    if { $initMode == 1 } {
	#puts "INFO: devfs preparation is done only on FreeBSD."
	exit
    }
}
if { $isOSfreebsd } {
    safeSourceFile $ROOTDIR/$LIBDIR/runtime/freebsd.tcl
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
    safeSourceFile $file
}

# The following files need to be sourced in this particular order. If not
# the placement of the toolbar icons will be altered.
# L2 nodes
foreach file $l2nodes {
    safeSourceFile "$ROOTDIR/$LIBDIR/nodes/$file.tcl"
}
# L3 nodes
foreach file $l3nodes {
    safeSourceFile "$ROOTDIR/$LIBDIR/nodes/$file.tcl"
}
# additional nodes
safeSourceFile "$ROOTDIR/$LIBDIR/nodes/localnodes.tcl"
safeSourceFile "$ROOTDIR/$LIBDIR/nodes/annotations.tcl"

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

set winOS false
if { $isOSwin } {
    set winOS true
}

if { !$isOSwin } {
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
    safePackageRequire Tk "To run the IMUNES GUI, Tk must be installed."
    foreach file "canvas copypaste drawing editor help theme linkcfgGUI \
	mouse nodecfgGUI widgets" {
	safeSourceFile "$ROOTDIR/$LIBDIR/gui/$file.tcl"
    }
    source "$ROOTDIR/$LIBDIR/gui/initgui.tcl"
    source "$ROOTDIR/$LIBDIR/gui/topogen.tcl"
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

#Modification for dyanmips

global RouterCisco
set RouterCisco ""

global listRouterCisco
set listRouterCisco ""

#Modification vlan
global eidvlan modevlan booleen
set eidvlan ""
set modevlan ""
set booleen "false"

#Modifiation for wifi

global masque dhcpIp1 dhcpIp2
set masque "24"
global listAP listAPIP
set listAPIP ""
set listAP ""
global listSTA
set listSTA ""

