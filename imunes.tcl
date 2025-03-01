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

set LIBDIR ""
set ROOTDIR "."

if { $ROOTDIR == "." } {
    set BINDIR ""
} else {
    set BINDIR "bin"
}

set runtimeDir "/var/run/imunes"

set home_path ""
catch { set home_path $env(HOME) }

set config_dir ""
catch { set config_dir $env(XDG_CONFIG_HOME) }
if { $config_dir == "" } {
    set config_dir "$home_path/.config"
}
set config_dir "$config_dir/imunes"
set config_path "$config_dir/config"

# TODO: check what if user is sudo
set sudo_user ""
catch { set sudo_user $env(SUDO_USER) }

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
set nodecreate_timeout 3
set ifacesconf_timeout 3
set nodeconf_timeout 3

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

# Set default node type list
set node_types "lanswitch hub rj45 stpswitch filter packgen router host pc nat64 ext extnat"
# Set default supported router models
set supp_router_models "frr quagga static"

if { $isOSlinux } {
    # Limit default nodes on linux
    set node_types "lanswitch hub rj45 router pc host nat64 ext extnat"
    set supp_router_models "frr quagga static"
    safeSourceFile $ROOTDIR/$LIBDIR/runtime/linux.tcl
}

if { $isOSfreebsd } {
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
foreach file [glob -directory $ROOTDIR/$LIBDIR/config *.tcl] {
    safeSourceFile $file
}

# The following files need to be sourced in this particular order. If not
# the placement of the toolbar icons will be altered.
foreach file $node_types {
    safeSourceFile "$ROOTDIR/$LIBDIR/nodes/$file.tcl"
    safeSourceFile "$ROOTDIR/$LIBDIR/gui/$file.tcl"
}

# additional nodes
safeSourceFile "$ROOTDIR/$LIBDIR/nodes/localnodes.tcl"

#
# Global variables are initialized here
#

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

# These variables can be modified in IMUNES configuration files.
#   name			value		type			description
set default_options {
    "auto_etc_hosts"		0		"bool"			"automatically create /etc/hosts entries in each node"
    "editor_only"		0		"bool"			"if true, Experiment -> Execute is disabled"
    "icon_size"			"normal"	"list small|normal"	"size of icons on canvas"
    "custom_override"		""		"string"		"a list of options that ignore values from .imn files"
    "show_annotations"		1		"bool"			"show annotations on canvas"
    "show_background_image"	0		"bool"			"show background image on canvas"
    "show_grid"			1		"bool"			"show grid on canvas"
    "show_interface_ipv4"	1		"bool"			"show IPv4 addresses of nodes on canvas"
    "show_interface_ipv6"	1		"bool"			"show IPv6 addresses of nodes on canvas"
    "show_interface_names"	1		"bool"			"show interface names of nodes on canvas"
    "show_link_labels"		1		"bool"			"show labels for links on canvas"
    "show_node_labels"		1		"bool"			"show labels for nodes on canvas"
    "zoom"			1.0		"double 0.2|3.0" 	"canvas zoom"
}

set global_override {}
set options_max_length 0
set running_options [dict create]
set topology_options [dict create]
set canvas_options [dict create]
foreach {name value type description} $default_options {
    if { $name != "custom_override" } {
	dict set running_options $name $value
    }

    set $name $value

    if { [string length $name] > $options_max_length } {
	set options_max_length [string length $name]
    }
}

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

set json_cfg [createJson "object" $running_options]
if { ! [file exists $config_dir] } {
    file mkdir $config_dir
}

# I don't want to add new runtime arguments for generating this file, but I
# also don't want to do it manually for each new option that is added to the
# list, so generate it every time in debug mode
if { $debug } {
    set preamble "#
# This file is not parsed. If you want to apply options system-wide,
# copy it to /etc/imunes/config and modify it there.
# For per-user changes, copy it to \$XDG_CONFIG_HOME/imunes/config or
# \$HOME/imunes/config if \$XDG_CONFIG_HOME is \"\" or not set."

    set config_path_orig "$config_path"
    set config_path "${config_path}.example"

    set comments "#\n"
    foreach {name value type description} $default_options {
	set pad [string repeat " " [expr $options_max_length - [string length $name]]]
	append comments "# $name$pad - $description (default: \"$value\", type: \"$type\")\n"
    }
    append comments "#"

    set json_cfg "$preamble\n$comments\n$json_cfg"
}

set fd [open "$config_path" w+]
puts $fd $json_cfg
close $fd

if { $debug } {
    set config_path "$config_path_orig"
}

# Read config files
set last_config_file $config_path
readConfigFiles
if { $last_config_file != "" } {
    set config_path $last_config_file
}

#
# Initialization should be complete now, so let's start doing something...
#

if { $execMode == "interactive" } {
    safePackageRequire Tk "To run the IMUNES GUI, Tk must be installed."

    foreach file "canvas copypaste drawing editor help theme linkcfgGUI \
	mouse nodecfgGUI ifacesGUI widgets annotations" {

	safeSourceFile "$ROOTDIR/$LIBDIR/gui/$file.tcl"
    }

    source "$ROOTDIR/$LIBDIR/gui/initgui.tcl"
    source "$ROOTDIR/$LIBDIR/gui/topogen.tcl"
    if { $debug == 1 } {
	source "$ROOTDIR/$LIBDIR/gui/debug.tcl"
    }

    newProject
    if { $argv != "" && [file exists $argv] } {
	setToRunning "cwd" [pwd]
	setToRunning "current_file" $argv
	openFile
    }

    updateProjectMenu
    # Fire up the animation loop
    animate
    # Event scheduler - should be started / stopped on per-experiment base?
#     evsched
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
	upvar 0 ::cf::[set ::curcfg]::execute_vars execute_vars
	upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg
	set dict_cfg [dict create]
	setOption "version" $CFG_VERSION

	set dict_run [dict create]
	set execute_vars [dict create]

	setToRunning "eid" ""
	setToRunning "oper_mode" "edit"
	setToRunning "auto_execution" 1
	setToRunning "cfg_deployed" false
	setToRunning "stop_sched" true
	setToRunning "undolevel" 0
	setToRunning "redolevel" 0

	readCfgJson $currentFileBatch

	setToRunning "curcanvas" [lindex [getFromRunning "canvas_list"] 0]
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
	if { [file exists $configFile] && $regular_termination } {
	    set curcfg [newObjectId $cfg_list "cfg"]
	    lappend cfg_list $curcfg

	    namespace eval ::cf::[set curcfg] {}
	    upvar 0 ::cf::[set ::curcfg]::dict_run dict_run
	    upvar 0 ::cf::[set ::curcfg]::execute_vars execute_vars
	    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg
	    set dict_cfg [dict create]
	    setOption "version" $CFG_VERSION

	    set dict_run [dict create]
	    set execute_vars [dict create]

	    setToRunning "eid" $eid_base
	    setToRunning "oper_mode" "edit"
	    setToRunning "auto_execution" 1
	    setToRunning "cfg_deployed" false
	    setToRunning "stop_sched" true
	    setToRunning "undolevel" 0
	    setToRunning "redolevel" 0
	    setToRunning "canvas_list" {}
	    setToRunning "current_file" $configFile

	    readCfgJson $configFile
	    setToRunning "curcanvas" [lindex [getFromRunning "canvas_list"] 0]

	    readRunningVarsFile $eid_base
	    setToRunning "cfg_deployed" true

	    setToExecuteVars "terminate_cfg" [cfgGet]
	    setToExecuteVars "terminate_nodes" [getFromRunning "node_list"]
	    setToExecuteVars "destroy_nodes_ifaces" "*"
	    setToExecuteVars "terminate_links" [getFromRunning "link_list"]
	    setToExecuteVars "unconfigure_links" "*"
	    setToExecuteVars "unconfigure_nodes_ifaces" "*"
	    setToExecuteVars "unconfigure_nodes" "*"

	    undeployCfg $eid_base 1
	} else {
	    vimageCleanup $eid_base
	}

	terminate_deleteExperimentFiles $eid_base
    }
}
