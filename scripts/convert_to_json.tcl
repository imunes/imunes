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

#****h* scripts/convert_to_json.tcl
# NAME
#    convert_to_json.tcl
# FUNCTION
#    Starts imunes in batch mode, loads a topology and (if it's a legacy
#    topology), converts it to a new JSON format.
#****

#
# Include procedure definitions from external files. There must be
# some better way to accomplish the same goal, but that's how we do it
# for the moment.
#
# The ROOTDIR and LIBDIR variables will be automatically set to the proper
# value by the installation script.
#

#****v* convert_to_json.tcl/ROOTDIR
# NAME
#    ROOTDIR
# FUNCTION
#    The location of imunes library files. The ROOTDIR and LIBDIR variables
#    will be automatically set to the proper value by the installation script.
#*****

#****v* convert_to_json.tcl/LIBDIR
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

fetchImunesVersion

try {
	source "$ROOTDIR/$LIBDIR/helpers.tcl"
} on error { result options } {
	puts stderr "Could not find file helpers.tcl in $ROOTDIR/$LIBDIR:"
	puts stderr $result
	exit 1
}

safePackageRequire [list cmdline platform ip base64 json json::write]

set initMode 0
set execMode batch
set debug 0
set printVersion 0
set prepareFlag 0
set forceFlag 0
set selected_experiment ""
set gui 0

# Runtime libriaries
foreach file [glob -directory $ROOTDIR/$LIBDIR/runtime *.tcl] {
	if { [string match -nocase "*linux.tcl" $file] != 1 } {
		safeSourceFile $file
	}
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

set all_modules_list {}
set runnable_node_types {}

set isOSfreebsd false
set isOSlinux false
set isOSwin false

# Set default node type list
set node_types "lanswitch hub rj45 stpswitch filter packgen \
	router host pc nat64 ext"
# Set default supported router models
set supp_router_models "frr quagga static"

# Configuration libraries
foreach file [glob -directory $ROOTDIR/$LIBDIR/config *.tcl] {
	safeSourceFile $file
}

# The following files need to be sourced in this particular order. If not
# the placement of the toolbar icons will be altered.
foreach file $node_types {
	safeSourceFile "$ROOTDIR/$LIBDIR/nodes/$file.tcl"
	safeSourceFile "$ROOTDIR/$LIBDIR/gui/nodes/$file.tcl"
}

# additional nodes
safeSourceFile "$ROOTDIR/$LIBDIR/nodes/localnodes.tcl"

#
# Global variables are initialized here
#

#****v* convert_to_json.tcl/prefs
# NAME
#    prefs
# FUNCTION
#    Contains the list of preferences. When starting a program
#    this list is empty.
#*****

set cfg_list {}
set curcfg ""

#****v* convert_to_json.tcl/editor_only
# NAME
#    editor_only -- if set, Experiment -> Execute is disabled
# FUNCTION
#    IMUNES GUI can be used in editor-only mode.i
#    This variable can be modified in .imunesrc.
set editor_only false

#
# Read config files, the first one found: .imunesrc, $HOME/.imunesrc
#
# XXX
readConfigFile

#
# Initialization should be complete now, so let's start doing something...
#

if { $argv != "" } {
	if { ! [file exists $argv] } {
		puts "Error: file '$argv' doesn't exist"
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
	setToRunning "cfg_deployed" false
	setToRunning "stop_sched" true
	setToRunning "undolevel" 0
	setToRunning "redolevel" 0
	setToRunning_gui "zoom" $zoom

	readCfgJson $currentFileBatch

	setToRunning_gui "curcanvas" [lindex [getFromRunning_gui "canvas_list"] 0]
	setToRunning "current_file" $argv

	set dir_name [file dirname $currentFileBatch]
	set file_name [file tail $currentFileBatch]
	saveCfgJson "$dir_name/json_$file_name"
	puts "Saved as $dir_name/json_$file_name"
} else {
	puts "Usage: ./imunes --convert <old_imunes_topology.imn>"
	exit
}
