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

set options {
    {e.arg	"" "specify experiment ID"}
    {eid.arg	"" "specify experiment ID"}
    {b		"batch mode on"}
    {batch	"batch mode on"}
    {d.secret	"debug mode on"}
    {u		"update IMUNES"}
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

proc updateIMUNES {} {
    package require http
    global execMode
    set url "http://www.imunes.tel.fer.hr/dl/update"
    set token [::http::geturl $url]
    set data [::http::data $token]
    ::http::cleanup $token          

    set newv [lindex $data 0]
    set ndate [lindex $data 1]
    set url [lindex $data 2]
    set sha [lindex $data 3]
    set updateFolder "/tmp/imunes_[string range $sha 0 10]"
    file delete -force $updateFolder
    file mkdir $updateFolder

    catch {exec imunes -v} curd
    set curv [string trim [lindex $curd 2] ,]
    set cdate [string trim [lindex $curd end] ,]

    if { $curv < $newv } {
	set message "Current version: $curv ($cdate)\nNew version: $newv ($ndate)\nDownload and install new version?"
	if {$execMode == "batch"} {
	    puts -nonewline "$message (Y/n) "
	    flush stdout
	    set answer [gets stdin]
	} else {
	    set answer [tk_dialog .dialog1 "IMUNES update" "$message" \
	    questhead 0 Yes No]
	}

	if { $answer == 0 || $answer == "y" || $answer == "Y" || $answer == "" } {
	    set count 4
	    set startedCount 0
	    if {$execMode != "batch"} {
		set w .startup
		catch {destroy $w}
		toplevel $w -takefocus 1
		wm transient $w .
		wm title $w "Updating IMUNES..."
		message $w.msg -justify left -aspect 1200 \
		    -text "Downloading the latest tarball..."
		pack $w.msg
		update
		ttk::progressbar $w.p -orient horizontal -length 250 \
		-mode determinate -maximum $count -value $startedCount 
		pack $w.p
		update
	    } else {
		puts -nonewline "Installing"
		flush stdout
	    }
	    package require tar
	    package require sha256
	    set dwFile "$updateFolder/imunes.tar.gz"
	    set tarFile "$updateFolder/imunes.tar"

	    http::geturl $url -channel [open $dwFile w]
	    if {$execMode != "batch"} {
		incr startedCount
		$w.p configure -value $startedCount
		$w.msg configure -text "Calculating checksum..."
		update
	    } else {
		puts -nonewline "."
		flush stdout
	    }

	    set dwsha [ ::sha2::sha256 -hex -file $dwFile ]
	    if { $dwsha != $sha } {
		if {$execMode == "batch"} {
		    puts ""
		    puts "Download corrupt, try again."
		} else {
		    catch {destroy $w}
		    tk_dialog .dialog1 "IMUNES update" \
		    "Download corrupt, try again." \
		    info 0 Dismiss
		}
		return
	    }

	    if {$execMode != "batch"} {
		incr startedCount
		$w.p configure -value $startedCount
		$w.msg configure -text "Extracting archive..."
		update
	    } else {
		puts -nonewline "."
		flush stdout
	    }
	    set targz [open $dwFile rb]
	    zlib push gunzip $targz
	    set tar [open $tarFile wb+]
	    puts $tar [read $targz]
	    close $targz
	    close $tar
	    set rootFolder [lindex [::tar::stat $tarFile] 0]
	    ::tar::untar $tarFile -dir $updateFolder

	    if {$execMode != "batch"} {
		incr startedcount
		$w.p configure -value $startedCount
		$w.msg configure -text "Installing IMUNES..."
		update
	    } else {
		puts -nonewline "."
		flush stdout
	    }
	    catch { exec make install -C $updateFolder/$rootFolder } err

	    if {$execMode != "batch"} {
		incr startedCount
		$w.p configure -value $startedCount
		$w.msg configure -text "Update complete."
		update
	    } else {
		puts -nonewline "."
		flush stdout
	    }

	    if {$execMode == "batch"} {
		puts ""
		puts "IMUNES updated successfully."
	    } else {
		catch {destroy $w}
		tk_dialog .dialog1 "IMUNES update" \
		"Update completed successfully. Please restart IMUNES." \
		info 0 Dismiss
	    }
	}
    } else {
	if {$execMode == "batch"} {
	    puts "The newest IMUNES already installed."
	} else {
	    tk_dialog .dialog1 "IMUNES update" \
	    "The newest IMUNES already installed." \
	    info 0 Dismiss
	}
    }
}

if { $params(u) } {
    set execMode batch
    catch {exec id -u} uid
    if { $uid != "0" } {
	puts "Error: To update, run IMUNES with root permissions."
	exit
    }
    updateIMUNES
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

# Runtime libriaries
source "$ROOTDIR/$LIBDIR/runtime/exec.tcl"
if { $initMode == 1 } {
    prepareDevfs
    exit
}
source "$ROOTDIR/$LIBDIR/runtime/cfgparse.tcl"
source "$ROOTDIR/$LIBDIR/runtime/eventsched.tcl"
source "$ROOTDIR/$LIBDIR/runtime/filemgmt.tcl"

# Configuration libraries
source "$ROOTDIR/$LIBDIR/config/annotationscfg.tcl"
source "$ROOTDIR/$LIBDIR/config/ipsec.tcl"
source "$ROOTDIR/$LIBDIR/config/ipv4.tcl"
source "$ROOTDIR/$LIBDIR/config/ipv6.tcl"
source "$ROOTDIR/$LIBDIR/config/linkcfg.tcl"
source "$ROOTDIR/$LIBDIR/config/mac.tcl"
source "$ROOTDIR/$LIBDIR/config/nodecfg.tcl"

# The following files need to be sourced in this particular order. If not
# the placement of the toolbar icons will be altered.
source "$ROOTDIR/$LIBDIR/nodes/hub.tcl"
source "$ROOTDIR/$LIBDIR/nodes/lanswitch.tcl"
source "$ROOTDIR/$LIBDIR/nodes/click_l2.tcl"
source "$ROOTDIR/$LIBDIR/nodes/rj45.tcl"
source "$ROOTDIR/$LIBDIR/nodes/genericrouter.tcl"
source "$ROOTDIR/$LIBDIR/nodes/click_l3.tcl"
source "$ROOTDIR/$LIBDIR/nodes/host.tcl"
source "$ROOTDIR/$LIBDIR/nodes/pc.tcl"
#source "$ROOTDIR/$LIBDIR/nodes/ipfirewall.tcl"
source "$ROOTDIR/$LIBDIR/nodes/localnodes.tcl"
source "$ROOTDIR/$LIBDIR/nodes/annotations.tcl"

# Router models
source "$ROOTDIR/$LIBDIR/nodes/quagga.tcl"
source "$ROOTDIR/$LIBDIR/nodes/xorp.tcl"
source "$ROOTDIR/$LIBDIR/nodes/static.tcl"

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

package require platform
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

#
# Read config files, the first one found: .imunesrc, $HOME/.imunesrc
#
readConfigFile


#
# Initialization should be complete now, so let's start doing something...
#

if {$execMode == "interactive"} {
    source "$ROOTDIR/$LIBDIR/gui/canvas.tcl"
    source "$ROOTDIR/$LIBDIR/gui/copypaste.tcl"
    source "$ROOTDIR/$LIBDIR/gui/drawing.tcl"
    source "$ROOTDIR/$LIBDIR/gui/editor.tcl"
    source "$ROOTDIR/$LIBDIR/gui/help.tcl"
    source "$ROOTDIR/$LIBDIR/gui/theme.tcl"
    source "$ROOTDIR/$LIBDIR/gui/initgui.tcl"
    source "$ROOTDIR/$LIBDIR/gui/linkcfgGUI.tcl"
    source "$ROOTDIR/$LIBDIR/gui/mouse.tcl"
    source "$ROOTDIR/$LIBDIR/gui/nodecfgGUI.tcl"
    source "$ROOTDIR/$LIBDIR/gui/topogen.tcl"
    source "$ROOTDIR/$LIBDIR/gui/widgets.tcl"
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
	set configFile "/var/run/imunes/$eid_base/config.imn"
	set ngmapFile "/var/run/imunes/$eid_base/ngnodemap"
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
