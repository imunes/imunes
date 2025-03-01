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

# TODO: set on installation?
set runtimeDir "/var/run/imunes"

set sudo_user ""
catch { set sudo_user $env(SUDO_USER) }

set home_path ""
if { $sudo_user != "" } {
	catch { set home_path $env(SUDO_HOME) }
} else {
	catch { set home_path $env(HOME) }
}

set config_dir ""
catch { set config_dir $env(XDG_CONFIG_HOME) }
if { $config_dir == "" } {
	set config_dir "$home_path/.config"
}
set config_dir "$config_dir/imunes"
set config_path "$config_dir/config"

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
set max_jobs 0
set nodecreate_timeout 5
set ifacesconf_timeout 5
set nodeconf_timeout 5
set selected_experiment ""
set gui 1

global remote_error remote rcmd ttyrcmd remote_mux_path remote_factor
global escalation_comm rescalation_comm
set remote_error ""
set remote ""
set rcmd "sh"
set ttyrcmd "sh -c"
set remote_mux_path ""
set escalation_comm ""
set rescalation_comm ""
set remote_factor 2

set options {
	{a					"Attach to a running experiment"}
	{attach				"Attach to a running experiment"}
	{e.arg				"" "Specify experiment ID"}
	{eid.arg			"" "Specify experiment ID"}
	{b					"Turn on batch mode"}
	{batch				"Turn on batch mode"}
	{c.secret			"Run in CLI mode"}
	{cli.secret			"Run in CLI mode"}
	{d.secret			"Turn on debug mode"}
	{j.arg				"0" "Max parallel jobs (0 = number of CPUs)"}
	{p					"Prepare virtual root file system"}
	{prepare			"Prepare virtual root file system"}
	{r.arg.secret		"" "Connect to remote host via SSH"}
	{remote.arg.secret	"" "Connect to remote host via SSH"}
	{f					"Force virtual root preparation (delete existing vroot)"}
	{force				"Force virtual root preparation (delete existing vroot)"}
	{i					"Setup devfs rules for virtual nodes (Only on FreeBSD)"}
	{l					"Run in legacy/slow mode"}
	{legacy				"Run in legacy/slow mode"}
	{v					"Print IMUNES version"}
	{version			"Print IMUNES version"}
	{h					"Print this message"}
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

# Runtime libriaries
foreach file_path [glob -directory $ROOTDIR/$LIBDIR/runtime *.tcl] {
	if {
		[string match -nocase "*linux.tcl" $file_path] != 1 &&
		[string match -nocase "*freebsd.tcl" $file_path] != 1
	} {
		safeSourceFile $file_path
	}
}

setPlatformVariables

if { $prepareFlag } {
	prepareVroot
	exit
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

global named_colors
set named_colors "Red Green Blue Yellow Magenta Cyan Gray Black"

# These variables can be modified in IMUNES configuration files.
#	name					value		type						description
set options_defaults {
	"custom_override"		""			"string"					"a list of options that ignore values from .imn files"
	"auto_etc_hosts"		0			"bool"						"automatically create /etc/hosts entries in each node"
	"IPv4autoAssign"		1			"bool"						"automatically assign next free IPv4 address to interface"
	"IPv6autoAssign"		1			"bool"						"automatically assign next free IPv6 address to interface"
    "recents_number"		10			"int 0|999"					"max number of recently opened file names to keep"
	"routerDefaultsModel"	"frr"		"list frr|quagga|static"	"new routers will have this value set to routing model"
	"routerRipEnable"		1			"bool"						"enable/disable RIP protocol on newly created router nodes"
	"routerRipngEnable"		1			"bool"						"enable/disable RIPng protocol on newly created router nodes"
	"routerOspfEnable"		0			"bool"						"enable/disable OSPF protocol on newly created router nodes"
	"routerOspf6Enable"		0			"bool"						"enable/disable OSPF6 protocol on newly created router nodes"
	"routerBgpEnable"		0			"bool"						"enable/disable BGP protocol on newly created router nodes"
	"routerLdpEnable"		0			"bool"						"enable/disable LDP protocol on newly created router nodes"
	"editor_only"			0			"bool"						"if true, Experiment -> Execute is disabled"
}
#	name					value		type						description

#	name						value							type				description
set gui_options_defaults {
	"hidden_node_types"			"none"							"string"			"a list of node types to hide in the toolbar"
	"icon_size"					"normal"						"list small|normal"	"size of icons on canvas"
	"show_annotations"			1								"bool"				"show annotations on canvas"
	"show_background_image"		0								"bool"				"show background image on canvas"
	"show_grid"					1								"bool"				"show grid on canvas"
	"show_interface_ipv4"		1								"bool"				"show IPv4 addresses of nodes on canvas"
	"show_interface_ipv6"		1								"bool"				"show IPv6 addresses of nodes on canvas"
	"show_interface_names"		1								"bool"				"show interface names of nodes on canvas"
	"show_link_labels"			1								"bool"				"show labels for links on canvas"
	"show_node_labels"			1								"bool"				"show labels for nodes on canvas"
	"show_unsupported_nodes"	0								"bool"				"show unsupported node in the toolbar"
	"zoom"						1.0								"double 0.2|3.0" 	"canvas zoom"
	"default_link_color"		"Red"							"string"			"default link color"
	"default_link_width"		2								"int 2|8"			"default link width"
	"default_fill_color"		"Gray"							"string"			"default oval/rect annotation fill color"
	"default_text_color"		"#000000"						"string"			"default text annotation color"
	"terminal_command"			"xterm -name imunes-terminal"	"string"			"default terminal to open"
}
#	name						value							type				description

global global_override all_options all_gui_options default_options custom_options
set global_override {}
set all_options {}
set all_gui_options {}
set default_options [dict create]
set custom_options [dict create]

set options_max_length 0
foreach {name value type description} $options_defaults {
	global $name

	if { $name != "custom_override" } {
		dict set default_options $name $value
		lappend all_options $name
	}

	set $name $value

	if { [string length $name] > $options_max_length } {
		set options_max_length [string length $name]
	}
}

foreach {name value type description} $gui_options_defaults {
	global $name

	if { $name != "custom_override" } {
		dict set default_options $name $value
		lappend all_gui_options $name
	}

	set $name $value

	if { [string length $name] > $options_max_length } {
		set options_max_length [string length $name]
	}
}

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

if { $remote_error == "" && $execMode == "batch" } {
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

if { ! [file exists $config_dir] } {
    file mkdir $config_dir
}

# I don't want to add new runtime arguments for generating this file, but I
# also don't want to do it manually for each new option that is added to the
# list, so generate it every time in debug mode
if { $debug } {
	set json_cfg [createJson "object" [list "custom_override" "" {*}$default_options]]

	set preamble "#\n"
	append preamble "# This file is not parsed. If you want to apply options system-wide,\n"
	append preamble "# copy it to /etc/imunes/config and modify it there.\n"
	append preamble "# For per-user changes, copy it to \$XDG_CONFIG_HOME/imunes/config or\n"
	append preamble "# \$HOME/imunes/config if \$XDG_CONFIG_HOME is \"\" or not set."

	set comments "#\n"
	append comments "# non-GUI variables\n"
	foreach {name value type description} $options_defaults {
		set pad [string repeat " " [expr $options_max_length - [string length $name]]]
		append comments "# $name$pad - $description (default: \"$value\", type: \"$type\")\n"
	}
	append comments "# GUI variables\n"
	foreach {name value type description} $gui_options_defaults {
		set pad [string repeat " " [expr $options_max_length - [string length $name]]]
		append comments "# $name$pad - $description (default: \"$value\", type: \"$type\")\n"
	}
	append comments "#"

	set json_cfg "$preamble\n$comments\n$json_cfg"

	set fd [open "${config_path}.example" w+]
	puts $fd $json_cfg
	close $fd

	unset json_cfg
}

set recent_files {}
set recents_fname "$config_dir/recents"
if { ! [file isdirectory "$config_dir"] } {
    set recents_fname ""
} else {
	if { [file exists $recents_fname] } {
		set fd [open $recents_fname r]
		set data [read $fd]
		close $fd

		set fnames [split $data \n]
		foreach fname $fnames {
			if { $fname != "" } {
				lappend recent_files $fname
			}
		}
	}
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
	if { $selected_experiment != "" && $selected_experiment ni [getResumableExperiments] } {
		puts stderr "Experiment with EID '$selected_experiment' not running"
		mainPipeClose

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

	if { $remote_error != "" } {
		if { $gui } {
			after idle {.dialog1.msg configure -wraplength 4i}
			tk_dialog .dialog1 "IMUNES warning" \
				"$remote_error" \
				info 0 Dismiss
		}

		set remote_error ""
	}

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
		refreshToolBarNodes
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
	if { $remote_error != "" } {
		exit 1
	}

	catch { rexec id -u } uid
	if { $uid != "0" } {
		mainPipeClose
		puts stderr "Error: To execute experiment, run IMUNES with root permissions."

		exit 1
	}

	mainPipeCreate
	if { $argv != "" } {
		if { ! [file exists $argv] } {
			mainPipeClose
			puts stderr "Error: file '$argv' doesn't exist"

			exit 1
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
			mainPipeClose

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
		if { [isOk "test -f $configFile"] } {
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
			setToRunning "current_file" [getRunningExperimentConfigPath $eid_base]

			readCfgJson [getFromRunning "current_file"]

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

	mainPipeClose
}
