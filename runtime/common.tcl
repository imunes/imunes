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
# This work was supported in part by the Croatian Ministry of Science
# and Technology through the research contract #IP-2003-143.
#

global vroot_unionfs vroot_linprocfs ifc_dad_disable regular_termination \
	devfs_number auto_etc_hosts linkJitterConfiguration ipsecSecrets \
	ipsecConf ipFastForwarding

set linkJitterConfiguration 0
set vroot_unionfs 1
set vroot_linprocfs 0
set ifc_dad_disable 0
set regular_termination 1
set devfs_number 46837
set auto_etc_hosts 0
set ipFastForwarding 0

#****f* common.tcl/getVrootDir
# NAME
#   getVrootDir -- get virtual root directory
# SYNOPSIS
#   getVrootDir
# FUNCTION
#   Helper function that returns virtual root directory.
# RESULT
#   * vroot_dir -- virtual root directory
#****
proc getVrootDir {} {
	global vroot_unionfs

	if { $vroot_unionfs } {
		return "/var/imunes"
	} else {
		return "/vroot"
	}
}

proc prepareInstantiateVars { { force "" } } {
	if { ! [getFromRunning "cfg_deployed"] && $force == "" } {
		return
	}

	set vars "instantiate_nodes create_nodes_ifaces instantiate_links \
		configure_links configure_nodes_ifaces configure_nodes"
	foreach var $vars {
		upvar 1 $var $var
		set $var [getFromExecuteVars "$var"]
		dputs "'[info level -1]' - '[info level 0]': $var '[set $var]'"
	}
}

proc prepareTerminateVars {} {
	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	set vars "terminate_nodes destroy_nodes_ifaces terminate_links \
		unconfigure_links unconfigure_nodes_ifaces unconfigure_nodes"
	foreach var $vars {
		upvar 1 $var $var
		set $var [getFromExecuteVars "$var"]
		dputs "'[info level -1]' - '[info level 0]': $var '[set $var]'"
	}
}

proc updateInstantiateVars { { force "" } } {
	if { ! [getFromRunning "cfg_deployed"] && $force == "" } {
		return
	}

	set vars "instantiate_nodes create_nodes_ifaces instantiate_links \
		configure_links configure_nodes_ifaces configure_nodes"
	foreach var $vars {
		upvar 1 $var $var
		dputs "'[info level -1]' - '[info level 0]': $var '[set $var]'"
		setToExecuteVars "$var" [set $var]
	}
}

proc updateTerminateVars {} {
	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	set vars "terminate_nodes destroy_nodes_ifaces terminate_links \
		unconfigure_links unconfigure_nodes_ifaces unconfigure_nodes"
	foreach var $vars {
		upvar 1 $var $var
		dputs "'[info level -1]' - '[info level 0]': $var '[set $var]'"
		setToExecuteVars "$var" [set $var]
	}
}

proc trigger_nodeConfig { node_id } {
	if {
		! [getFromRunning "cfg_deployed"] ||
		[getFromRunning "${node_id}_running"] == false
	} {
		return
	}

	prepareInstantiateVars

	if { $node_id ni $configure_nodes } {
		lappend configure_nodes $node_id
	}

	updateInstantiateVars
}

proc trigger_nodeUnconfig { node_id } {
	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	prepareTerminateVars

	set node_running [getFromRunning "${node_id}_running"]
	if { $node_id ni $unconfigure_nodes && $node_running == true } {
		lappend unconfigure_nodes $node_id
	}

	updateTerminateVars
}

proc trigger_nodeReconfig { node_id } {
	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	set node_running [getFromRunning "${node_id}_running"]
	if { $node_running == true } {
		trigger_nodeUnconfig $node_id
	}

	trigger_nodeConfig $node_id
}

proc trigger_nodeFullConfig { node_id } {
	if {
		! [getFromRunning "cfg_deployed"] ||
		[getFromRunning "${node_id}_running"] == false
	} {
		return
	}

	trigger_nodeConfig $node_id
	foreach iface_id [allIfcList $node_id] {
		trigger_ifaceConfig $node_id $iface_id
	}
}

proc trigger_nodeFullUnconfig { node_id } {
	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	trigger_nodeUnconfig $node_id
	foreach iface_id [allIfcList $node_id] {
		trigger_ifaceUnconfig $node_id $iface_id
	}
}

proc trigger_nodeFullReconfig { node_id } {
	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	set node_running [getFromRunning "${node_id}_running"]
	if { $node_running == true } {
		trigger_nodeUnconfig $node_id

		prepareTerminateVars
		dict set unconfigure_nodes_ifaces $node_id "*"
		updateTerminateVars
	}

	trigger_nodeConfig $node_id

	prepareInstantiateVars
	dict set configure_nodes_ifaces $node_id "*"
	updateInstantiateVars
}

proc trigger_nodeCreate { node_id } {
	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	prepareInstantiateVars

	if { $node_id ni $instantiate_nodes } {
		lappend instantiate_nodes $node_id
	}

	if { $node_id ni $configure_nodes } {
		lappend configure_nodes $node_id
	}

	dict set create_nodes_ifaces $node_id "*"
	dict set configure_nodes_ifaces $node_id "*"

	updateInstantiateVars

	foreach iface_id [ifcList $node_id] {
		set link_id [getIfcLink $node_id $iface_id]
		if { $link_id == "" } {
			continue
		}

		if { [getLinkDirect $link_id] } {
			lassign [logicalPeerByIfc $node_id $iface_id] peer_id peer_iface_id
			trigger_ifaceConfig $peer_id $peer_iface_id
		}

		trigger_linkRecreate $link_id
	}
}

proc trigger_nodeDestroy { node_id } {
	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	prepareTerminateVars

	set node_running [getFromRunning "${node_id}_running"]
	if { $node_id ni $terminate_nodes && $node_running == true } {
		lappend terminate_nodes $node_id
	}

	if { $node_id ni $unconfigure_nodes && $node_running == true } {
		lappend unconfigure_nodes $node_id
	}

	if { $node_running == true } {
		dict set unconfigure_nodes_ifaces $node_id "*"
		dict set destroy_nodes_ifaces $node_id "*"
	}

	updateTerminateVars

	foreach iface_id [ifcList $node_id] {
		set link_id [getIfcLink $node_id $iface_id]
		if { $link_id == "" } {
			continue
		}

		trigger_linkRecreate $link_id
	}

	prepareInstantiateVars

	if { $node_id in $instantiate_nodes } {
		set instantiate_nodes [removeFromList $instantiate_nodes $node_id]
	}

	if { $node_id in $configure_nodes } {
		set configure_nodes [removeFromList $configure_nodes $node_id]
	}

	if { $node_id in [dict keys $create_nodes_ifaces] } {
		dict unset create_nodes_ifaces $node_id
	}

	if { $node_id in [dict keys $configure_nodes_ifaces] } {
		dict unset configure_nodes_ifaces $node_id
	}

	updateInstantiateVars
}

proc trigger_nodeRecreate { node_id } {
	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	set node_running [getFromRunning "${node_id}_running"]
	if { $node_running == true } {
		trigger_nodeDestroy $node_id
	}

	trigger_nodeCreate $node_id

	foreach iface_id [ifcList $node_id] {
		set link_id [getIfcLink $node_id $iface_id]
		if { $link_id == "" } {
			continue
		}

		trigger_linkRecreate $link_id
	}
}

proc trigger_linkConfig { link_id } {
	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	prepareInstantiateVars

	if { $link_id ni $configure_links } {
		lappend configure_links $link_id
	}

	updateInstantiateVars
}

proc trigger_linkUnconfig { link_id } {
	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	prepareTerminateVars

	set link_running [getFromRunning "${link_id}_running"]
	if { $link_id ni $unconfigure_links && $link_running } {
		lappend unconfigure_links $link_id
	}

	updateTerminateVars

	prepareInstantiateVars

	if { $link_id in $configure_links && ! $link_running } {
		set configure_links [removeFromList $configure_links $link_id]
	}

	updateInstantiateVars
}

proc trigger_linkReconfig { link_id } {
	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	set link_running [getFromRunning "${link_id}_running"]
	if { $link_running } {
		trigger_linkUnconfig $link_id
	}

	trigger_linkConfig $link_id
}

proc trigger_linkCreate { link_id } {
	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	prepareInstantiateVars

	if { $link_id ni $instantiate_links } {
		lappend instantiate_links $link_id

		foreach node_id [getLinkPeers $link_id] {
			set node_type [getNodeType $node_id]
			if { $node_type in "packgen" } {
				trigger_nodeReconfig $node_id
			} elseif { $node_type in "filter" } {
				trigger_nodeReconfig $node_id
			}
		}
	}

	updateInstantiateVars

	trigger_linkConfig $link_id
}

proc trigger_linkDestroy { link_id } {
	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	trigger_linkUnconfig $link_id

	prepareTerminateVars

	set link_running [getFromRunning "${link_id}_running"]
	if { $link_id ni $terminate_links && $link_running } {
		lappend terminate_links $link_id

		foreach node_id [getLinkPeers $link_id] {
			set node_type [getNodeType $node_id]
			if { $node_type in "packgen" } {
				trigger_nodeReconfig $node_id
			} elseif { $node_type in "filter" } {
				trigger_nodeReconfig $node_id
			}
		}
	}

	updateTerminateVars

	prepareInstantiateVars

	if { $link_id in $instantiate_links && ! $link_running } {
		set instantiate_links [removeFromList $instantiate_links $link_id]
	}

	updateInstantiateVars
}

proc trigger_linkRecreate { link_id } {
	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	set link_running [getFromRunning "${link_id}_running"]
	if { $link_running } {
		trigger_linkDestroy $link_id
	}

	trigger_linkCreate $link_id
}

proc trigger_ifaceCreate { node_id iface_id } {
	if {
		! [getFromRunning "cfg_deployed"] ||
		[getFromRunning "${node_id}_running"] == false
	} {
		return
	}

	prepareInstantiateVars

	set ifaces [dictGet $create_nodes_ifaces $node_id]
	if { "*" ni $ifaces && $iface_id ni $ifaces } {
		dict lappend create_nodes_ifaces $node_id $iface_id
	}

	updateInstantiateVars

	trigger_ifaceConfig $node_id $iface_id

	set link_id [getIfcLink $node_id $iface_id]
	if { $link_id != "" && [getLinkDirect $link_id] } {
		lassign [logicalPeerByIfc $node_id $iface_id] peer_id peer_iface_id
		trigger_ifaceConfig $peer_id $peer_iface_id
	}

	# if any of the logical interfaces have $iface_id as master, recreate them
	set iface_name [getIfcName $node_id $iface_id]
	foreach log_iface_id [logIfcList $node_id] {
		if { [getIfcVlanDev $node_id $log_iface_id] != $iface_name } {
			continue
		}

		if { "*" ni $ifaces && $log_iface_id ni $ifaces } {
			trigger_ifaceCreate $node_id $log_iface_id
		}
	}
}

proc trigger_ifaceDestroy { node_id iface_id } {
	if {
		! [getFromRunning "cfg_deployed"] ||
		[getFromRunning "${node_id}_running"] == false
	} {
		return
	}

	prepareTerminateVars

	set iface_running [getFromRunning "${node_id}|${iface_id}_running"]
	set ifaces [dictGet $destroy_nodes_ifaces $node_id]
	if { "*" ni $ifaces && $iface_id ni $ifaces && $iface_running } {
		dict lappend destroy_nodes_ifaces $node_id $iface_id
	}

	updateTerminateVars

	prepareInstantiateVars

	set ifaces [dictGet $create_nodes_ifaces $node_id]
	if { $iface_id in $ifaces && ! $iface_running } {
		set ifaces [removeFromList $ifaces $iface_id]
		if { $ifaces == {} } {
			dict unset create_nodes_ifaces $node_id
		} else {
			dict set create_nodes_ifaces $node_id $ifaces
		}
	}

	updateInstantiateVars

	trigger_ifaceUnconfig $node_id $iface_id
}

proc trigger_ifaceRecreate { node_id iface_id } {
	if {
		! [getFromRunning "cfg_deployed"] ||
		[getFromRunning "${node_id}_running"] == false
	} {
		return
	}

	set iface_running [getFromRunning "${node_id}|${iface_id}_running"]
	if { $iface_running } {
		trigger_ifaceDestroy $node_id $iface_id
	}

	trigger_ifaceCreate $node_id $iface_id
}

proc trigger_ifaceConfig { node_id iface_id } {
	if {
		! [getFromRunning "cfg_deployed"] ||
		[getFromRunning "${node_id}_running"] == false
	} {
		return
	}

	prepareInstantiateVars

	set ifaces [dictGet $configure_nodes_ifaces $node_id]
	if { "*" ni $ifaces && $iface_id ni $ifaces } {
		dict lappend configure_nodes_ifaces $node_id $iface_id
	}

	updateInstantiateVars
}

proc trigger_ifaceUnconfig { node_id iface_id } {
	if {
		! [getFromRunning "cfg_deployed"] ||
		[getFromRunning "${node_id}_running"] == false
	} {
		return
	}

	prepareTerminateVars

	set iface_running [getFromRunning "${node_id}|${iface_id}_running"]
	set ifaces [dictGet $unconfigure_nodes_ifaces $node_id]
	if { "*" ni $ifaces && $iface_id ni $ifaces && $iface_running } {
		dict lappend unconfigure_nodes_ifaces $node_id $iface_id
	}

	updateTerminateVars

	prepareInstantiateVars

	set ifaces [dictGet $configure_nodes_ifaces $node_id]
	if { $iface_id in $ifaces && ! $iface_running } {
		set ifaces [removeFromList $ifaces $iface_id]
		if { $ifaces == {} } {
			dict unset configure_nodes_ifaces $node_id
		} else {
			dict set configure_nodes_ifaces $node_id $ifaces
		}
	}

	updateInstantiateVars
}

proc trigger_ifaceReconfig { node_id iface_id } {
	if {
		! [getFromRunning "cfg_deployed"] ||
		[getFromRunning "${node_id}_running"] == false
	} {
		return
	}

	set iface_running [getFromRunning "${node_id}|${iface_id}_running"]
	if { $iface_running } {
		trigger_ifaceUnconfig $node_id $iface_id
	}

	trigger_ifaceConfig $node_id $iface_id
}

#****f* exec.tcl/statline
# NAME
#   statline -- status line
# SYNOPSIS
#   statline $line
# FUNCTION
#   Sets the string of the status line. If the execution mode is set to batch
#   the line is just printed on the standard output.
# INPUTS
#   * line -- line to be displayed
#****
proc statline { line } {
	global execMode

	if { $execMode == "batch" } {
		puts $line
		flush stdout
	} else {
		dputs $line

		.bottom.textbox config -text "$line"
		animateCursor
	}
}

#****f* exec.tcl/displayBatchProgress
# NAME
#   displayBatchProgress - display progress percentage in batch mode
# SYNOPSIS
#   displayBatchProgress $progress $total
# FUNCTION
#   Updates the progress percentage when starting an experiment in batch mode.
# INPUTS
#   * progress -- current step
#   * total -- total number of steps
#****
proc displayBatchProgress { prgs tot } {
	global execMode debug

	if { $execMode == "batch" } {
		puts -nonewline "\r                                                "
		puts -nonewline "\r> $prgs/$tot "
		flush stdout
	} elseif { $debug } {
		dputs -nonewline "\r                                                "
		dputs -nonewline "\r> $prgs/$tot "
	}
}

#****f* exec.tcl/pipesCreate
# NAME
#   pipesCreate -- pipes create
# SYNOPSIS
#   pipesCreate
# FUNCTION
#   Create pipes for parallel execution to the shell.
#****
proc pipesCreate {} {
	global inst_pipes last_inst_pipe

	set ncpus [getCpuCount]
	for { set i 0 } { $i < $ncpus } { incr i } {
		set inst_pipes($i) [open "| sh" r+]
	}
	set last_inst_pipe 0
}

proc pipesExec { line args } {
	global debug

	if { $debug && $line != "" } {
		set logfile "/var/log/imunes/[getFromRunning "eid"].log"

		pipesExecNoLog "printf \"RUN: \" >> $logfile ; cat >> $logfile 2>&1 <<\"IMUNESEOF\"\n$line\nIMUNESEOF" "hold"
		pipesExecNoLog "$line >> $logfile 2>&1" "$args"
	} else {
		pipesExecNoLog $line {*}$args
	}
}

#****f* exec.tcl/pipesExec
# NAME
#   pipesExec -- pipes execute
# SYNOPSIS
#   pipesExec line hold
# FUNCTION
#   Puts the shell command to the pipe.
# INPUTS
#   * line -- shell command
#   * args -- if empty, increment last pipe
#****
proc pipesExecNoLog { line args } {
	global inst_pipes last_inst_pipe

	set pipe $inst_pipes($last_inst_pipe)
	puts $pipe $line

	flush $pipe
	if { $args != "hold" } {
		incr last_inst_pipe
	}
	if { $last_inst_pipe >= [llength [array names inst_pipes]] } {
		set last_inst_pipe 0
	}
}

#****f* exec.tcl/pipesClose
# NAME
#   pipesClose -- pipes close
# SYNOPSIS
#   pipesClose
# FUNCTION
#   Close pipes.
#****
proc pipesClose {} {
	global inst_pipes last_inst_pipe

	foreach i [array names inst_pipes] {
		close $inst_pipes($i) w
		# A dummy read, just to flush the output from the command pipeline
		read $inst_pipes($i)
		catch { close $inst_pipes($i) }
	}
}

#****f* exec.tcl/setOperMode
# NAME
#   setOperMode -- set operating mode
# SYNOPSIS
#   setOperMode $new_oper_mode
# FUNCTION
#   Sets imunes operating mode to the value of the parameter new_oper_mode.
#   The mode can be set only to edit or exec.
#   When changing the mode to exec all the emulation interfaces are checked
#   (if they are nonexistent the message is displayed, and mode is not
#   changed), all the required buttons are disabled (except the
#   simulation/Terminate button, that is enabled) and procedure deployCfg is
#   called.
#   The mode can not be changed to exec if imunes operates only in editor mode
#   (editor_only variable is set).
#   When changing the mode to edit, all required buttons are enabled (except
#   for simulation/Terminate button that is disabled) and procedure
#   vimageCleanup is called.
# INPUTS
#   * new_oper_mode -- the new operating mode. Can be edit or exec.
#****
proc setOperMode { new_oper_mode } {
	global all_modules_list editor_only execMode isOSfreebsd isOSlinux

	if {
		! [getFromRunning "cfg_deployed"] &&
		$new_oper_mode == "exec"
	} {
		if { ! $isOSlinux && ! $isOSfreebsd } {
			after idle { .dialog1.msg configure -wraplength 4i }
			tk_dialog .dialog1 "IMUNES error" \
				"Error: To execute experiment, run IMUNES on FreeBSD or Linux." \
				info 0 Dismiss
			return
		}

		catch { exec id -u } uid
		if { $uid != "0" } {
			after idle { .dialog1.msg configure -wraplength 4i }
			tk_dialog .dialog1 "IMUNES error" \
				"Error: To execute experiment, run IMUNES with root permissions." \
				info 0 Dismiss
			return
		}

		set err [checkSysPrerequisites]
		if { $err != "" } {
			after idle { .dialog1.msg configure -wraplength 4i }
			tk_dialog .dialog1 "IMUNES error" \
				"$err" \
				info 0 Dismiss
			return
		}

		if { $editor_only } {
			.menubar.experiment entryconfigure "Execute" -state disabled
			return
		}

		if { [allSnapshotsAvailable] == 0 } {
			return
		}

		# Verify that links to external interfaces are properly configured
		if { [checkExternalInterfaces] } {
			return
		}
	}

	#.panwin.f1.left.select configure -state active
	if { "$new_oper_mode" == "exec" && [exec id -u] == 0 } {
		.menubar.experiment entryconfigure "Execute" -state disabled
		.menubar.experiment entryconfigure "Terminate" -state normal
		.menubar.experiment entryconfigure "Restart" -state normal
		.menubar.edit entryconfigure "Undo" -state disabled
		.menubar.edit entryconfigure "Redo" -state disabled
		.panwin.f1.c bind node <Double-1> "spawnShellExec"
		.panwin.f1.c bind nodelabel <Double-1> "spawnShellExec"

		setToRunning "oper_mode" "exec"

		wm protocol . WM_DELETE_WINDOW {
		}

		if { ! [getFromRunning "cfg_deployed"] } {
			setToExecuteVars "instantiate_nodes" [getFromRunning "node_list"]
			setToExecuteVars "create_nodes_ifaces" "*"
			setToExecuteVars "instantiate_links" [getFromRunning "link_list"]
			setToExecuteVars "configure_links" "*"
			setToExecuteVars "configure_nodes_ifaces" "*"
			setToExecuteVars "configure_nodes" "*"

			deployCfg 1

			setToRunning "cfg_deployed" true
		}

		wm protocol . WM_DELETE_WINDOW {
			exit
		}

		.bottom.experiment_id configure -text "Experiment ID = [getFromRunning "eid"]"
		if { [getFromRunning "auto_execution"] } {
			set oper_mode_text "exec mode"
			set oper_mode_color "black"
		} else {
			set oper_mode_text "paused"
			set oper_mode_color "red"
		}
	} else {
		if { [getFromRunning "oper_mode"] != "edit" } {
			global regular_termination

			wm protocol . WM_DELETE_WINDOW {
			}

			set eid [getFromRunning "eid"]
			if { $regular_termination } {
				setToExecuteVars "terminate_nodes" [getFromRunning "node_list"]
				setToExecuteVars "destroy_nodes_ifaces" "*"
				setToExecuteVars "terminate_links" [getFromRunning "link_list"]
				setToExecuteVars "unconfigure_links" "*"
				setToExecuteVars "unconfigure_nodes_ifaces" "*"
				setToExecuteVars "unconfigure_nodes" "*"

				undeployCfg $eid 1
			} else {
				vimageCleanup $eid
			}

			pipesCreate
			killExtProcess "socat.*$eid"
			pipesClose

			setToExecuteVars "terminate_cfg" [cfgGet]
			setToRunning "cfg_deployed" false

			wm protocol . WM_DELETE_WINDOW {
				exit
			}
		}

		if { $editor_only } {
			.menubar.experiment entryconfigure "Execute" -state disabled
		} else {
			.menubar.experiment entryconfigure "Execute" -state normal
		}

		.menubar.experiment entryconfigure "Terminate" -state disabled
		.menubar.experiment entryconfigure "Restart" -state disabled

		if { [getFromRunning "undolevel"] > 0 } {
			.menubar.edit entryconfigure "Undo" -state normal
		} else {
			.menubar.edit entryconfigure "Undo" -state disabled
		}

		if { [getFromRunning "redolevel"] > [getFromRunning "undolevel"] } {
			.menubar.edit entryconfigure "Redo" -state normal
		} else {
			.menubar.edit entryconfigure "Redo" -state disabled
		}

		.panwin.f1.c bind node <Double-1> "nodeConfigGUI .panwin.f1.c {}"
		.panwin.f1.c bind nodelabel <Double-1> "nodeConfigGUI .panwin.f1.c {}"

		setToRunning "oper_mode" "edit"
		.bottom.experiment_id configure -text ""
		set oper_mode_text "edit mode"
		set oper_mode_color "black"
	}

	.bottom.oper_mode configure -text "$oper_mode_text"
	.bottom.oper_mode configure -foreground $oper_mode_color

	catch { redrawAll }
	.panwin.f1.c config -cursor left_ptr
}

#****f* exec.tcl/spawnShellExec
# NAME
#   spawnShellExec -- spawn shell in exec mode on double click
# SYNOPSIS
#   spawnShellExec
# FUNCTION
#   This procedure spawns a new shell on a selected and current
#   node.
#****
proc spawnShellExec {} {
	set node_id [lindex [.panwin.f1.c gettags {node && current}] 1]
	if { $node_id == "" } {
		set node_id [lindex [.panwin.f1.c gettags {nodelabel && current}] 1]
		if { $node_id == "" } {
			return
		}
	}

	if {
		[[getNodeType $node_id].virtlayer] != "VIRTUALIZED" ||
		[getFromRunning "${node_id}_running"] == false
	} {
		nodeConfigGUI .panwin.f1.c $node_id
	} else {
		set cmd [lindex [existingShells [[getNodeType $node_id].shellcmds] $node_id] 0]
		if { $cmd == "" } {
			return
		}

		spawnShell $node_id $cmd
	}
}

#****f* exec.tcl/fetchNodesConfiguration
# NAME
#   fetchNodesConfiguration -- fetches current node configuration
# SYNOPSIS
#   fetchNodesConfiguration
# FUNCTION
#   This procedure is called when the button3.menu.sett->Fetch Node
#   Configurations button is pressed. It is used to update the selected nodes
#   configurations from the running experiment settings.
#****
proc fetchNodesConfiguration {} {
	foreach node_id [selectedNodes] {
		if { [getFromRunning ${node_id}_running] != true } {
			continue
		}

		set lines [fetchNodeRunningConfig $node_id]
	}

	redrawAll
}

# helper func
proc writeDataToFile { path data } {
	file mkdir [file dirname $path]
	set fileId [open $path w]
	puts $fileId $data
	close $fileId
}

# helper func
proc readDataFromFile { path } {
	set fileId [open $path r]
	set data [string trim [read $fileId]]
	close $fileId

	return $data
}

#****f* editor.tcl/resumeSelectedExperiment
# NAME
#   resumeSelectedExperiment -- resume selected experiment
# SYNOPSIS
#   resumeSelectedExperiment $exp
# FUNCTION
#   Resumes selected experiment.
# INPUTS
#   * exp -- experiment id
#****
proc resumeSelectedExperiment { exp } {
	global runtimeDir

	set eid [getFromRunning "eid"]
	if { $eid != "" } {
		set curr_eid $eid
		if { $curr_eid == $exp } {
			return
		}
	}

	newProject

	setToRunning "current_file" [getExperimentConfigurationFromFile $exp]
	openFile
	readRunningVarsFile $exp
	#catch { cd [getFromRunning "cwd"] }

	setToRunning "eid" $exp
	setToRunning "cfg_deployed" true
	setOperMode exec
}

#****f* exec.tcl/dumpLinksToFile
# NAME
#   dumpLinksToFile -- dump formatted link list to file
# SYNOPSIS
#   dumpLinksToFile $path
# FUNCTION
#   Saves the list of all links to $path.
# INPUTS
#   * path -- absolute path of the file
#****
proc dumpLinksToFile { path } {
	set data ""
	set linkDelim ":"
	set skipLinks ""

	foreach link_id [getFromRunning "link_list"] {
		if { $link_id in $skipLinks } {
			continue
		}

		lassign [getLinkPeers $link_id] node1_id node2_id
		lassign [getLinkPeersIfaces $link_id] iface1_id iface2_id

		set mirror_link_id [getLinkMirror $link_id]
		if { $mirror_link_id != "" } {
			lappend skipLinks $mirror_link_id

			# switch direction for mirror links
			lassign "$node2_id [lindex [getLinkPeers $mirror_link_id] 1]" node1_id node2_id
			lassign "$iface2_id [lindex [getLinkPeersIfaces $mirror_link_id] 1]" iface1_id iface2_id
		}

		set name1 [getNodeName $node1_id]
		set name2 [getNodeName $node2_id]

		set linkname "$name1$linkDelim$name2"

		set lpair [list $node1_id [getIfcName $node1_id $iface1_id]]
		set rpair [list $node2_id [getIfcName $node2_id $iface2_id]]

		set line "$link_id {$node1_id-$node2_id {{$lpair} {$rpair}} $linkname}\n"
		set data "$data$line"
	}

	set data [string trimright $data "\n"]

	writeDataToFile $path $data
}

#****f* exec.tcl/fetchExperimentFolders
# NAME
#   fetchExperimentFolders -- fetch experiment folders
# SYNOPSIS
#   fetchExperimentFolders
# FUNCTION
#   Returns folders of all running experiments as a list.
# RESULT
#   * exp_list -- experiment folder list
#****
proc fetchExperimentFolders {} {
	global runtimeDir
	set exp_list ""
	set exp_files [glob -nocomplain -directory $runtimeDir -type d *]
	if { $exp_files != "" } {
		foreach file $exp_files {
			lappend exp_list [file tail $file]
		}
	}
	return $exp_list
}

#****f* exec.tcl/getResumableExperiments
# NAME
#   getResumableExperiments -- get resumable experiments
# SYNOPSIS
#   getResumableExperiments
# FUNCTION
#   Returns IDs of all experiments which can be resumed as a list.
# RESULT
#   * exp_list -- experiment id list
#****
proc getResumableExperiments {} {
	set exp_list ""
	set exp_folders [fetchExperimentFolders]
	foreach exp [fetchRunningExperiments] {
		if { $exp in $exp_folders } {
			lappend exp_list $exp
		}
	}
	return $exp_list
}

#****f* exec.tcl/getExperimentTimestampFromFile
# NAME
#   getExperimentTimestampFromFile -- get experiment timestamp from file
# SYNOPSIS
#   getExperimentTimestampFromFile $eid
# FUNCTION
#   Returns the specified experiment timestamp from file.
# INPUTS
#   * eid -- experiment id
# RESULT
#   * timestamp -- experiment timestamp
#****
proc getExperimentTimestampFromFile { eid } {
	global runtimeDir

	set pathToFile "$runtimeDir/$eid/timestamp"
	set timestamp ""
	if { [file exists $pathToFile] } {
		set fileId [open $pathToFile r]
		set timestamp [string trim [read $fileId]]
		close $fileId
	}

	return $timestamp
}

#****f* exec.tcl/getExperimentNameFromFile
# NAME
#   getExperimentNameFromFile -- get experiment name from file
# SYNOPSIS
#   getExperimentNameFromFile $eid
# FUNCTION
#   Returns the specified experiment name from file.
# INPUTS
#   * eid -- experiment id
# RESULT
#   * name -- experiment name
#****
proc getExperimentNameFromFile { eid } {
	global runtimeDir

	set pathToFile "$runtimeDir/$eid/name"
	set name ""
	if { [file exists $pathToFile] } {
		set name [readDataFromFile $pathToFile]
	}

	return $name
}

#****f* exec.tcl/getExperimentConfigurationFromFile
# NAME
#   getExperimentConfigurationFromFile -- get experiment configuration from
#       file
# SYNOPSIS
#   getExperimentConfigurationFromFile $eid
# FUNCTION
#   Returns the specified experiment configuration from file.
# INPUTS
#   * eid -- experiment id
# RESULT
#   * file -- experiment configuration
#****
proc getExperimentConfigurationFromFile { eid } {
	global runtimeDir

	set pathToFile "$runtimeDir/$eid/config.imn"
	set file ""
	if { [file exists $pathToFile] } {
		set file $pathToFile
	}

	return $file
}

#****f* exec.tcl/captureOnExtIfc
# NAME
#   captureOnExtIfc -- start wireshark on an interface
# SYNOPSIS
#   captureOnExtIfc $node_id $command
# FUNCTION
#   Start tcpdump or Wireshark on the specified external interface.
# INPUTS
#   * node_id -- node id
#   * command -- tcpdump or wireshark
#****
proc captureOnExtIfc { node_id command } {
	set ifc [lindex [ifcList $node_id] 0]
	if { "$ifc" == "" } {
		return
	}

	set eid [getFromRunning "eid"]

	if { $command == "tcpdump" } {
		exec xterm -name imunes-terminal -T "Capturing $eid-$node_id" -e "tcpdump -ni $eid-$node_id" 2> /dev/null &
	} else {
		exec $command -o "gui.window_title:[getNodeName $node_id] ($eid)" -k -i $eid-$node_id 2> /dev/null &
	}
}
