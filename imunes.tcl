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
#        imunes [-b] [-e experiment_id] [filename]
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

set LIBDIR ""
set ROOTDIR "."

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

safePackageRequire [list cmdline platform ip base64 json json::write]

set initMode 0
set execMode interactive
set debug 0
set printVersion 0
set prepareFlag 0
set forceFlag 0
set nodecreate_timeout 5
set ifacesconf_timeout 5
set nodeconf_timeout 5
set selected_experiment ""
set gui 1

set options {
	{a			"Attach to a running experiment"}
	{attach		"Attach to a running experiment"}
	{e.arg		"" "Specify experiment ID"}
	{eid.arg	"" "Specify experiment ID"}
	{b			"Turn on batch mode"}
	{batch		"Turn on batch mode"}
	{c.secret	"Run in CLI mode"}
	{cli.secret	"Run in CLI mode"}
	{d.secret	"Turn on debug mode"}
	{p			"Prepare virtual root file system"}
	{prepare	"Prepare virtual root file system"}
	{f			"Force virtual root preparation (delete existing vroot)"}
	{force		"Force virtual root preparation (delete existing vroot)"}
	{i			"Setup devfs rules for virtual nodes (Only on FreeBSD)"}
	{l			"Run in legacy/slow mode"}
	{legacy		"Run in legacy/slow mode"}
	{v			"Print IMUNES version"}
	{version	"Print IMUNES version"}
	{h			"Print this message"}
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
foreach file_path [glob -directory $ROOTDIR/$LIBDIR/runtime *.tcl] {
	if {
		[string match -nocase "*linux.tcl" $file_path] != 1 &&
		[string match -nocase "*freebsd.tcl" $file_path] != 1
	} {
		safeSourceFile $file_path
	}
}

if { ! [info exists eid_base] } {
	set eid_base [genExperimentId]
}

# bases for naming new nodes
array set nodeNamingBase {
	pc pc
	ext ext
	filter filter
	router router
	host host
	hub hub
	lanswitch switch
	nat64 nat64-
	rj45 rj45-
	packgen packgen
	stpswitch stpswitch
	wlan wlan
}

set option_defaults {
	auto_etc_hosts		0
	IPv4autoAssign		1
	IPv6autoAssign		1
	routerRipEnable		1
	routerRipngEnable	1
	routerOspfEnable	0
	routerOspf6Enable	0
	routerBgpEnable		0
	routerLdpEnable		0
	routerDefaultsModel	"frr"
}

set gui_option_defaults {
	show_interface_names	1
	show_interface_ipv4		1
	show_interface_ipv6		1
	show_node_labels		1
	show_link_labels		1
	show_background_image	0
	show_annotations		1
	show_grid				1
	icon_size				"normal"
	zoom					1
	default_link_color		"Red"
	default_link_width		2
	default_fill_color		"Gray"
	default_text_color		"#000000"
}

foreach {option default_value} [concat $option_defaults $gui_option_defaults] {
	global $option

	set $option $default_value
}

global rdconfig
set rdconfig [list $routerRipEnable $routerRipngEnable $routerOspfEnable $routerOspf6Enable $routerBgpEnable $routerLdpEnable]

set all_modules_list {}
set runnable_node_types {}

# Set default node type list
set node_types "lanswitch hub rj45 stpswitch filter packgen \
	router host pc nat64 ext"
# Set default supported router models
set supp_router_models "frr quagga static"

if { $isOSlinux } {
	safeSourceFile $ROOTDIR/$LIBDIR/runtime/linux.tcl
} elseif { $isOSfreebsd } {
	safeSourceFile $ROOTDIR/$LIBDIR/runtime/freebsd.tcl
}

if { $initMode == 1 } {
	prepareDevfs 1
	exit
}

if { $execMode == "batch" } {
	set err [checkSysPrerequisites]
	if { $err != "" } {
		puts stderr $err
		exit
	}
}

# Configuration libraries
foreach file_path [glob -directory $ROOTDIR/$LIBDIR/config *.tcl] {
	safeSourceFile $file_path
}

# The following files need to be sourced in this particular order. If not
# the placement of the toolbar icons will be altered.
foreach node_type $node_types {
	safeSourceFile "$ROOTDIR/$LIBDIR/nodes/$node_type.tcl"
}

# Node-specific configuration libraries
foreach file_path [glob -nocomplain -directory $ROOTDIR/$LIBDIR/nodes/config *.tcl] {
	safeSourceFile $file_path
}

# additional nodes
safeSourceFile "$ROOTDIR/$LIBDIR/nodes/localnodes.tcl"

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
set cf::clipboard::dict_cfg [dict create]

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

if { ! $isOSwin } {
	catch { exec magick -version | head -1 | cut -d " " -f 1,2,3 } imInfo
} else {
	set imInfo $env(PATH)
}

set hasIM true
if { [string match -nocase "*imagemagick*" $imInfo] != 1 } {
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

if { $execMode == "interactive" } {
	if { $selected_experiment != "" && $selected_experiment ni [getResumableExperiments] } {
		puts stderr "Experiment with EID '$selected_experiment' not running"
		exit 1
	}

	if { $gui } {
		safePackageRequire Tk "To run the IMUNES GUI, Tk must be installed."

		# Node GUI base libraries
		foreach node_type $node_types {
			safeSourceFile "$ROOTDIR/$LIBDIR/gui/nodes/$node_type.tcl"
		}

		# Node-specific GUI configuration libraries
		foreach file_path [glob -nocomplain -directory $ROOTDIR/$LIBDIR/gui/nodes/config *.tcl] {
			safeSourceFile $file_path
		}

		set skip_files "theme.tcl initgui.tcl topogen.tcl debug.tcl"
		foreach file_path [glob -directory $ROOTDIR/$LIBDIR/gui *.tcl] {
			if { [file tail $file_path] ni $skip_files } {
				safeSourceFile $file_path
			}
		}

		foreach skip_file $skip_files {
			safeSourceFile "$ROOTDIR/$LIBDIR/gui/$skip_file"
		}
	}

	safeSourceFile "$ROOTDIR/$LIBDIR/gui/debug.tcl"

	newProject

	if { $selected_experiment != "" } {
		if { $gui } {
			resumeAndDestroy
		} else {
			resumeSelectedExperiment $selected_experiment

			upvar 0 ::cf::[set ::curcfg]::dict_run_gui dict_run_gui
			set dict_run_gui ""

			cfgUnset "gui"
		}
	} else {
		if { $argv != "" && [file exists $argv] } {
			setToRunning "cwd" [pwd]
			setToRunning "current_file" $argv
			openFile
		}
	}

	if { $gui } {
		updateProjectMenu
		# Fire up the animation loop
		animate
		# Event scheduler - should be started / stopped on per-experiment base?
		#evsched
	} else {
		puts ""
		puts "*** WARNING: This is an experimental feature. Proceed with caution! ***"
		puts ""
		puts -nonewline "> "
		flush stdout
		while { [gets stdin line] >= 0 } {
			try {
				eval {*}$line
			} on ok retv {
				puts "OK: '$retv'"
			} on error retv {
				puts "ERROR: '$retv'"
			}
			puts -nonewline "> "
			flush stdout
		}
	}
} else {
	if { $argv != "" } {
		if { ! [file exists $argv] } {
			puts stderr "Error: file '$argv' doesn't exist"
			exit
		}

		global currentFileBatch
		set currentFileBatch $argv

		set curcfg [newObjectId $cfg_list "cfg"]
		lappend cfg_list $curcfg

		namespace eval ::cf::[set curcfg] {}
		upvar 0 ::cf::[set ::curcfg]::dict_run dict_run
		upvar 0 ::cf::[set ::curcfg]::dict_run_gui dict_run_gui
		upvar 0 ::cf::[set ::curcfg]::execute_vars execute_vars
		upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg
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
		setToRunning "current_file" $currentFileBatch

		readCfgJson $currentFileBatch

		setToRunning "cwd" [pwd]
		setToRunning "current_file" $argv

		if { [checkExternalInterfaces] } {
			return
		}

		if { [allSnapshotsAvailable] == 1 } {
			setToExecuteVars "instantiate_nodes" [getFromRunning "node_list"]
			setToExecuteVars "create_nodes_ifaces" "*"
			setToExecuteVars "instantiate_links" [getFromRunning "link_list"]
			setToExecuteVars "configure_links" "*"
			setToExecuteVars "configure_nodes_ifaces" "*"
			setToExecuteVars "configure_nodes" "*"

			deployCfg 1
			createExperimentFilesFromBatch
		}
	} else {
		set configFile "$runtimeDir/$eid_base/config.imn"
		if { [file exists $configFile] } {
			set curcfg [newObjectId $cfg_list "cfg"]
			lappend cfg_list $curcfg

			namespace eval ::cf::[set curcfg] {}
			upvar 0 ::cf::[set ::curcfg]::dict_run dict_run
			upvar 0 ::cf::[set ::curcfg]::dict_run_gui dict_run_gui
			upvar 0 ::cf::[set ::curcfg]::execute_vars execute_vars
			upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg
			set dict_cfg [dict create]
			setOption "version" $CFG_VERSION

			set dict_run [dict create]
			set dict_run_gui [dict create]
			set execute_vars [dict create]

			setToRunning "eid" $eid_base
			setToRunning "oper_mode" "edit"
			setToRunning "auto_execution" 1
			setToRunning "no_auto_execute_nodes" {}
			setToRunning "cfg_deployed" false
			setToRunning "stop_sched" true
			setToRunning "undolevel" 0
			setToRunning "redolevel" 0
			setToRunning "current_file" $configFile

			readCfgJson $configFile

			readRunningVarsFile $eid_base
			setToRunning "cfg_deployed" true

			if { [getFromExecuteVars "terminate_cfg"] == "" } {
				setToExecuteVars "terminate_cfg" [cfgGet]
			}
			setToExecuteVars "terminate_nodes" [getFromRunning "node_list"]
			setToExecuteVars "destroy_nodes_ifaces" "*"
			setToExecuteVars "terminate_links" [getFromRunning "link_list"]
			setToExecuteVars "unconfigure_links" "*"
			setToExecuteVars "unconfigure_nodes_ifaces" "*"
			setToExecuteVars "unconfigure_nodes" "*"

			undeployCfg $eid_base 1
		}

		terminate_deleteExperimentFiles $eid_base
	}
}
