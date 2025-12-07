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

global vroot_unionfs vroot_linprocfs ifc_dad_disable \
	devfs_number auto_etc_hosts linkJitterConfiguration ipsecSecrets \
	ipsecConf ipFastForwarding

set linkJitterConfiguration 0
set vroot_unionfs 1
set vroot_linprocfs 0
set ifc_dad_disable 0
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
		[getFromRunning "${node_id}_running"] == "false"
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
	if { $node_id ni $unconfigure_nodes && $node_running == "true" } {
		lappend unconfigure_nodes $node_id
	}

	updateTerminateVars
}

proc trigger_nodeReconfig { node_id } {
	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	set node_running [getFromRunning "${node_id}_running"]
	if { $node_running == "true" } {
		trigger_nodeUnconfig $node_id
	}

	trigger_nodeConfig $node_id
}

proc trigger_nodeFullConfig { node_id } {
	if {
		! [getFromRunning "cfg_deployed"] ||
		[getFromRunning "${node_id}_running"] == "false"
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
	if { $node_running == "true" } {
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
	global isOSlinux

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
			if { $isOSlinux } {
				trigger_ifaceCreate $peer_id $peer_iface_id
			}
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
	if { $node_id ni $terminate_nodes && $node_running == "true" } {
		lappend terminate_nodes $node_id
	}

	if { $node_id ni $unconfigure_nodes && $node_running == "true" } {
		lappend unconfigure_nodes $node_id
	}

	if { $node_running == "true" } {
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
	if { $node_running == "true" } {
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
	if { $link_id ni $unconfigure_links && $link_running == "true" } {
		lappend unconfigure_links $link_id
	}

	updateTerminateVars

	prepareInstantiateVars

	if { $link_id in $configure_links && $link_running != "true" } {
		set configure_links [removeFromList $configure_links $link_id]
	}

	updateInstantiateVars
}

proc trigger_linkReconfig { link_id } {
	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	set link_running [getFromRunning "${link_id}_running"]
	if { $link_running == "true" } {
		trigger_linkUnconfig $link_id
	}

	trigger_linkConfig $link_id
}

proc trigger_linkCreate { link_id } {
	global isOSlinux

	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	prepareInstantiateVars

	if { $link_id ni $instantiate_links } {
		lappend instantiate_links $link_id

		updateInstantiateVars

		lassign [getLinkPeers $link_id] node1_id node2_id
		lassign [getLinkPeersIfaces $link_id] iface1_id iface2_id
		foreach node_id "$node1_id $node2_id" iface_id "$iface1_id $iface2_id" {
			set node_type [getNodeType $node_id]
			if { $node_type in "packgen" } {
				trigger_nodeReconfig $node_id
			} elseif { $node_type in "filter" } {
				trigger_nodeReconfig $node_id
			}

			if { ! [getLinkDirect $link_id] || ! $isOSlinux } {
				continue
			}

			set ifaces [dictGet $create_nodes_ifaces $node_id]
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
	}

	trigger_linkConfig $link_id
}

proc trigger_linkDestroy { link_id } {
	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	trigger_linkUnconfig $link_id

	prepareTerminateVars

	set link_running [getFromRunning "${link_id}_running"]
	if { $link_id ni $terminate_links && $link_running == "true" } {
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

	if { $link_id in $instantiate_links && $link_running != "true" } {
		set instantiate_links [removeFromList $instantiate_links $link_id]
	}

	updateInstantiateVars
}

proc trigger_linkRecreate { link_id } {
	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	set link_running [getFromRunning "${link_id}_running"]
	if { $link_running == "true" } {
		trigger_linkDestroy $link_id
	}

	trigger_linkCreate $link_id
}

proc trigger_ifaceCreate { node_id iface_id } {
	if {
		! [getFromRunning "cfg_deployed"] ||
		[getFromRunning "${node_id}_running"] == "false"
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
		[getFromRunning "${node_id}_running"] == "false"
	} {
		return
	}

	prepareTerminateVars

	set iface_running [getFromRunning "${node_id}|${iface_id}_running"]
	set ifaces [dictGet $destroy_nodes_ifaces $node_id]
	if { "*" ni $ifaces && $iface_id ni $ifaces && $iface_running == "true" } {
		dict lappend destroy_nodes_ifaces $node_id $iface_id
	}

	updateTerminateVars

	prepareInstantiateVars

	set ifaces [dictGet $create_nodes_ifaces $node_id]
	if { $iface_id in $ifaces && $iface_running != "true" } {
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
		[getFromRunning "${node_id}_running"] == "false"
	} {
		return
	}

	set iface_running [getFromRunning "${node_id}|${iface_id}_running"]
	if { $iface_running == "true" } {
		trigger_ifaceDestroy $node_id $iface_id
	}

	trigger_ifaceCreate $node_id $iface_id
}

proc trigger_ifaceConfig { node_id iface_id } {
	if {
		! [getFromRunning "cfg_deployed"] ||
		[getFromRunning "${node_id}_running"] == "false"
	} {
		return
	}

	prepareInstantiateVars

	set ifaces [dictGet $configure_nodes_ifaces $node_id]
	if { "*" ni $ifaces && $iface_id ni $ifaces } {
		dict lappend configure_nodes_ifaces $node_id $iface_id
	}

	updateInstantiateVars

	if { [getNodeVlanFiltering $node_id] } {
		set link_id [getIfcLink $node_id $iface_id]
		if { $link_id != "" } {
			trigger_linkRecreate $link_id
		}
	}
}

proc trigger_ifaceUnconfig { node_id iface_id } {
	if {
		! [getFromRunning "cfg_deployed"] ||
		[getFromRunning "${node_id}_running"] == "false"
	} {
		return
	}

	prepareTerminateVars

	set iface_running [getFromRunning "${node_id}|${iface_id}_running"]
	set ifaces [dictGet $unconfigure_nodes_ifaces $node_id]
	if { "*" ni $ifaces && $iface_id ni $ifaces && $iface_running == "true" } {
		dict lappend unconfigure_nodes_ifaces $node_id $iface_id
	}

	updateTerminateVars

	prepareInstantiateVars

	set ifaces [dictGet $configure_nodes_ifaces $node_id]
	if { $iface_id in $ifaces && $iface_running != "true" } {
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
		[getFromRunning "${node_id}_running"] == "false"
	} {
		return
	}

	set iface_running [getFromRunning "${node_id}|${iface_id}_running"]
	if { $iface_running == "true" } {
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
	global execMode gui

	if { ! $gui || $execMode == "batch" } {
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
	global execMode debug gui

	if { ! $gui || $execMode == "batch" } {
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
	global rcmd remote remote_max_sessions

	if { $remote != "" && $remote_max_sessions > 0 } {
		set ncpus $remote_max_sessions
	} else {
		set ncpus [getCpuCount]
	}
	for { set i 0 } { $i < $ncpus } { incr i } {
		set inst_pipes($i) [open "| $rcmd > /dev/null" w]
		chan configure $inst_pipes($i) \
			-blocking 0 -buffering none -translation binary
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

	if { $args != "hold" } {
		flush $pipe
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
#   for simulation/Terminate button that is disabled)
# INPUTS
#   * new_oper_mode -- the new operating mode. Can be edit or exec.
#****
proc setOperMode { new_oper_mode } {
	global editor_only isOSfreebsd isOSlinux gui

	if {
		! [getFromRunning "cfg_deployed"] &&
		$new_oper_mode == "exec"
	} {
		if { ! $isOSlinux && ! $isOSfreebsd } {
			set err "Error: To execute experiment, run IMUNES on FreeBSD or Linux."

			if { $gui } {
				after idle { .dialog1.msg configure -wraplength 4i }
				tk_dialog .dialog1 "IMUNES error" \
					$err \
					info 0 Dismiss
			} else {
				puts stderr $err
			}

			return
		}

		catch { rexec id -u } uid
		if { $uid != "0" } {
			set err "Error: To execute experiment, run IMUNES with root permissions."

			if { $gui } {
				after idle { .dialog1.msg configure -wraplength 4i }
				tk_dialog .dialog1 "IMUNES error" \
					$err \
					info 0 Dismiss
			} else {
				puts stderr $err
			}

			return
		}

		set err [checkSysPrerequisites]
		if { $err != "" } {
			if { $gui } {
				after idle { .dialog1.msg configure -wraplength 4i }
				tk_dialog .dialog1 "IMUNES error" \
					"$err" \
					info 0 Dismiss
			} else {
				puts stderr $err
			}

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
	if { "$new_oper_mode" == "exec" } {
		if { $gui } {
			.menubar.experiment entryconfigure "Execute" -state disabled
			.menubar.experiment entryconfigure "Terminate" -state normal
			.menubar.experiment entryconfigure "Restart" -state normal
			.menubar.experiment entryconfigure "Refresh running experiment" -state normal
			.menubar.edit entryconfigure "Undo" -state disabled
			.menubar.edit entryconfigure "Redo" -state disabled
			.panwin.f1.c bind node <Double-1> "spawnShellExec"
			.panwin.f1.c bind nodelabel <Double-1> "spawnShellExec"
			.panwin.f1.c bind node_running <Double-1> "spawnShellExec"
		}

		setToRunning "oper_mode" "exec"

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

		if { $gui } {
			.bottom.experiment_id configure -text "Experiment ID = [getFromRunning "eid"]"
			if { [getFromRunning "auto_execution"] } {
				set oper_mode_text "exec mode"
				set oper_mode_color "black"
			} else {
				set oper_mode_text "paused"
				set oper_mode_color "red"
			}
		}
	} else {
		if { [getFromRunning "oper_mode"] != "edit" } {
			set eid [getFromRunning "eid"]
			setToExecuteVars "terminate_nodes" [getFromRunning "node_list"]
			setToExecuteVars "destroy_nodes_ifaces" "*"
			setToExecuteVars "terminate_links" [getFromRunning "link_list"]
			setToExecuteVars "unconfigure_links" "*"
			setToExecuteVars "unconfigure_nodes_ifaces" "*"
			setToExecuteVars "unconfigure_nodes" "*"

			undeployCfg $eid 1

			pipesCreate
			killExtProcess "socat.*$eid"
			pipesClose

			setToExecuteVars "terminate_cfg" [cfgGet]
			setToRunning "cfg_deployed" false
		}

		if { $gui } {
			if { $editor_only } {
				.menubar.experiment entryconfigure "Execute" -state disabled
			} else {
				.menubar.experiment entryconfigure "Execute" -state normal
			}

			.menubar.experiment entryconfigure "Terminate" -state disabled
			.menubar.experiment entryconfigure "Restart" -state disabled
			.menubar.experiment entryconfigure "Refresh running experiment" -state disabled

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
			.panwin.f1.c bind node_running <Double-1> "nodeConfigGUI .panwin.f1.c {}"
		}

		setToRunning "oper_mode" "edit"

		if { $gui } {
			.bottom.experiment_id configure -text ""
			set oper_mode_text "edit mode"
			set oper_mode_color "black"
		}
	}

	if { $gui } {
		.bottom.oper_mode configure -text "$oper_mode_text"
		.bottom.oper_mode configure -foreground $oper_mode_color

		catch { redrawAll }
		.panwin.f1.c config -cursor left_ptr
	}
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
	set node_id [lindex [.panwin.f1.c gettags "(node || nodelabel || node_running) && current"] 1]
	if { $node_id == "" } {
		return
	}

	if {
		[isPseudoNode $node_id] ||
		[[getNodeType $node_id].virtlayer] != "VIRTUALIZED" ||
		[getFromRunning "${node_id}_running"] == "false"
	} {
		nodeConfigGUI .panwin.f1.c $node_id
	} else {
		set cmd [existingShells [[getNodeType $node_id].shellcmds] $node_id "first_only"]
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
		if { [getFromRunning ${node_id}_running] != "true" } {
			continue
		}

		fetchNodeRunningConfig $node_id
	}

	redrawAll
}

# helper func
proc writeDataToFile { path data } {
	global remote rcmd

	rexec mkdir -p [file dirname $path]

	if { $remote != "" } {
		set file_id [open "| $rcmd dd of=$path status=none" w]
	} else {
		set file_id [open $path w]
	}

	puts $file_id $data
	close $file_id
}

# helper func
proc readDataFromFile { path } {
	global remote rcmd

	if { $remote != "" } {
		set file_id [open "| $rcmd cat $path" r]
	} else {
		set file_id [open $path r]
	}

	set data [string trim [read $file_id]]
	close $file_id

	return $data
}

proc readRunningVarsFile { eid } {
	global gui_option_defaults
	global runtimeDir gui remote

	upvar 0 ::cf::[set ::curcfg]::dict_run dict_run
	upvar 0 ::cf::[set ::curcfg]::dict_run_gui dict_run_gui
	upvar 0 ::cf::[set ::curcfg]::execute_vars execute_vars

	set vars_dict [readDataFromFile $runtimeDir/$eid/runningVars]

	set dict_run [dictGet $vars_dict "dict_run"]
	set dict_run_gui [dictGet $vars_dict "dict_run_gui"]
	set execute_vars [dictGet $vars_dict "execute_vars"]

	if { $gui } {
		set canvas_list [getFromRunning_gui "canvas_list"]
		if { $canvas_list == {} } {
			set canvas_list [getFromRunning "canvas_list"]
			if { $canvas_list != {} } {
				unsetRunning "canvas_list"
				setToRunning_gui "canvas_list" $canvas_list
			} else {
				newCanvas ""
				set canvas_list [getFromRunning_gui "canvas_list"]
			}
		}

		set annotation_list [getFromRunning_gui "annotation_list"]
		if { $annotation_list == {} } {
			set annotation_list [getFromRunning "annotation_list"]
			if { $annotation_list != {} } {
				unsetRunning "annotation_list"
				setToRunning_gui "annotation_list" $annotation_list
			}
		}

		set images [getFromRunning_gui "images"]
		if { $images == {} } {
			set images [getFromRunning "images"]
			if { $images != {} } {
				unsetRunning "images"
				setToRunning_gui "images" $images
			}
		}

		if { [getFromRunning "undolevel"] == "" } {
			setToRunning "undolevel" 0
		}

		if { [getFromRunning "redolevel"] == "" } {
			setToRunning "redolevel" 0
		}

		if { [getFromRunning_gui "zoom"] == "" } {
			setToRunning_gui "zoom" [dictGet $gui_option_defaults "zoom"]
		}

		if { [getFromRunning_gui "curcanvas"] == "" } {
			setToRunning_gui "curcanvas" [lindex $canvas_list 0]
		}
	}

	foreach node_id [getFromRunning "node_list"] {
		if { [cfgGet "nodes" $node_id] == "" } {
			cfgUnset "nodes" $node_id
			cfgUnset "gui" "nodes" $node_id
			setToRunning "node_list" [removeFromList [getFromRunning "node_list"] $node_id]
		}
	}

	foreach link_id [getFromRunning "link_list"] {
		if { [cfgGet "links" $link_id] == "" } {
			cfgUnset "links" $link_id
			cfgUnset "gui" "links" $link_id
			setToRunning "link_list" [removeFromList [getFromRunning "link_list"] $link_id]
		}
	}

	# older versions do not have this variable
	if { [getFromRunning "modified"] == "" } {
		setToRunning "modified" false
	}
}

#****f* exec.tcl/saveRunningConfiguration
# NAME
#   saveRunningConfiguration -- save running configuration in interactive
# SYNOPSIS
#   saveRunningConfiguration $eid
# FUNCTION
#   Saves running configuration of the specified experiment if running in
#   interactive mode.
# INPUTS
#   * eid -- experiment id
#****
proc saveRunningConfiguration { eid } {
	global runtimeDir remote rcmd

	set file_path "$runtimeDir/$eid/config.imn"

	if { $remote != "" } {
		set file_id [open "| $rcmd dd of=$file_path status=none" w]

		puts $file_id [saveCfgJson - "no_write"]
		close $file_id
	} else {
		saveCfgJson $file_path
	}
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
	set eid [getFromRunning "eid"]
	if { $eid != "" } {
		set curr_eid $eid
		if { $curr_eid == $exp } {
			return
		}
	}

	newProject

	setToRunning "current_file" [getRunningExperimentConfigPath $exp]
	openFile
	readRunningVarsFile $exp
	#catch { cd [getFromRunning "cwd"] }

	setToRunning "eid" $exp
	setToRunning "cfg_deployed" true
	setOperMode exec
	set stop_sched [getFromRunning "stop_sched"]
	if { $stop_sched != "" && ! $stop_sched } {
		startEventScheduling
	}
}

proc refreshRunningExperimentGUI {} {
	try {
		refreshRunningExperiment
	} on ok eid {
		toggleAutoExecutionGUI [getFromRunning "auto_execution"]

		return $eid
	} on error err {
		statline $err

		return ""
	}
}

proc refreshRunningExperiment {} {
	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	set eid [getFromRunning "eid"]

	setToRunning "current_file" [getRunningExperimentConfigPath $eid]
	if { [getFromRunning "current_file"] == "" } {
		global execMode

		set msg "The experiment with EID $eid has been terminated from outside this IMUNES instance."
		if { $execMode != "batch" } {
			after idle { .dialog1.msg configure -wraplength 4i }
			tk_dialog .dialog1 "IMUNES error" \
				$msg \
				info 0 Dismiss
		}

		setOperMode "edit"

		return -code error $msg
	}

	openFile
	readRunningVarsFile $eid
	setToRunning "cfg_deployed" true
	setOperMode exec

	return -code ok $eid
}

proc toggleAutoExecution {} {
	set auto_execution [getFromRunning "auto_execution"]

	setToRunning "auto_execution" [expr $auto_execution ^ 1]
	if { [getFromRunning "cfg_deployed"] && ! $auto_execution } {
		# when going from non-auto to auto execution, trigger (un)deployCfg
		redeployCfg
	} else {
		setToExecuteVars "terminate_cfg" [cfgGet]
	}

	createRunningVarsFile [getFromRunning "eid"]
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

#****f* common.tcl/getResumableExperiments
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
	global runtimeDir

	set exp_list {}
	catch { rexec find "$runtimeDir" -mindepth 1 -maxdepth 1 -print } exp_paths
	if { $exp_paths != "" } {
		set exp_list [lmap exp_path $exp_paths { file tail $exp_path }]
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
	global runtimeDir remote

	set path_to_file "$runtimeDir/$eid/timestamp"
	catch { rexec ls $path_to_file } err
	if { $err != $path_to_file } {
		return ""
	}

	return [string trim [readDataFromFile $path_to_file]]
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

	set file_path "$runtimeDir/$eid/name"
	catch { rexec ls $file_path } err
	if { $err != $file_path } {
		return ""
	}

	return [readDataFromFile $file_path]
}

#****f* exec.tcl/getRunningExperimentConfigPath
# NAME
#   getRunningExperimentConfigPath -- get experiment configuration file path
# SYNOPSIS
#   getRunningExperimentConfigPath $eid
# FUNCTION
#   Returns the path of the specified experiment configuration.
# INPUTS
#   * eid -- experiment id
# RESULT
#   * file_path -- experiment configuration
#****
proc getRunningExperimentConfigPath { eid } {
	global runtimeDir remote

	set file_path "$runtimeDir/$eid/config.imn"
	catch { rexec ls $file_path } err
	if { $err != $file_path } {
		return ""
	}

	if { $remote != "" } {
		set file_id [file tempfile tmppath]

		puts $file_id [readDataFromFile $file_path]
		set file_path $tmppath

		close $file_id
	}

	return $file_path
}

proc checkTerminalMissing {} {
	# FIXME make this modular
	set terminal "xterm"
	if { [catch { exec which $terminal }] } {
		tk_dialog .dialog1 "IMUNES error" \
			"Cannot open terminal. Is $terminal installed?" \
			info 0 Dismiss

		return true
	}

	return false
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
	global ttyrcmd

	set ifc [lindex [ifcList $node_id] 0]
	if { "$ifc" == "" } {
		return
	}

	set eid [getFromRunning "eid"]

	if { $command == "tcpdump" } {
		if { [checkTerminalMissing] } {
			return
		}

		exec xterm -name imunes-terminal -T "Capturing $eid-$node_id" -e {*}$ttyrcmd "tcpdump -ni $eid-$node_id" 2> /dev/null &
	} else {
		exec $command -o "gui.window_title:[getNodeName $node_id] ($eid)" -k -i $eid-$node_id 2> /dev/null &
	}
}

proc redeployCfg {} {
	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	if { ! [getFromRunning "auto_execution"] } {
		set eid [getFromRunning "eid"]

		createExperimentFiles $eid
		createRunningVarsFile $eid

		return
	}

	undeployCfg
	deployCfg
}
