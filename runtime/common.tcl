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
	devfs_number linkJitterConfiguration ipsecSecrets \
	ipsecConf

set linkJitterConfiguration 0
set vroot_unionfs 1
set vroot_linprocfs 0
set ifc_dad_disable 0
set devfs_number 46837

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
	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	prepareInstantiateVars

	if {
		! [isRunningNode $node_id] &&
		"*" ni $instantiate_nodes && $node_id ni $instantiate_nodes
	} {
		# quit if our node is dead and it won't be created
		return
	}

	prepareTerminateVars

	if {
		("*" ni $instantiate_nodes && $node_id ni $instantiate_nodes) &&
		("*" in $terminate_nodes || $node_id in $terminate_nodes)
	} {
		# quit if our node will be destroyed
		return
	}

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

	set node_running [isRunningNode $node_id]
	if { $node_id ni $unconfigure_nodes && $node_running } {
		lappend unconfigure_nodes $node_id
	}

	updateTerminateVars

	prepareInstantiateVars

	if { $node_id in $configure_nodes && $node_running != "true" } {
		dict unset configure_nodes $node_id
	}

	updateInstantiateVars
}

proc trigger_nodeReconfig { node_id } {
	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	if { [isRunningNode $node_id] } {
		trigger_nodeUnconfig $node_id
	}

	trigger_nodeConfig $node_id
}

proc trigger_nodeFullConfig { node_id } {
	if {
		! [getFromRunning "cfg_deployed"] ||
		! [isRunningNode $node_id]
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

	if { [isRunningNode $node_id] == "true" } {
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

	updateInstantiateVars

	trigger_nodeConfig $node_id
	trigger_ifaceCreate $node_id "*"
}

proc trigger_nodeDestroy { node_id } {
	if {
		! [getFromRunning "cfg_deployed"] ||
		! [isRunningNode $node_id]
	} {
		return
	}

	prepareTerminateVars

	if { $node_id ni $terminate_nodes } {
		lappend terminate_nodes $node_id
	}

	updateTerminateVars

	trigger_nodeUnconfig $node_id

	trigger_ifaceDestroy $node_id "*" 1

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

	if { [isRunningNode $node_id] == "true" } {
		trigger_nodeDestroy $node_id
	}

	trigger_nodeCreate $node_id
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

	set link_running [isRunningLink $link_id]
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

	set link_running [isRunningLink $link_id]
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

		prepareTerminateVars

		lassign [getLinkPeers $link_id] node1_id node2_id
		lassign [getLinkPeersIfaces $link_id] iface1_id iface2_id
		foreach node_id "$node1_id $node2_id" iface_id "$iface1_id $iface2_id" {
			set node_type [getNodeType $node_id]
			if { $node_type in "packgen" } {
				trigger_nodeReconfig $node_id
			} elseif { $node_type in "filter" } {
				trigger_nodeReconfig $node_id
			}

			set create_ifaces [dictGet $create_nodes_ifaces $node_id]
			if { "*" ni $create_ifaces && $iface_id ni $create_ifaces } {
				trigger_ifaceCreate $node_id $iface_id

				# if any of the logical interfaces have $iface_id as master, recreate them
				set iface_name [getIfcName $node_id $iface_id]
				foreach log_iface_id [logIfcList $node_id] {
					if { [getIfcVlanDev $node_id $log_iface_id] != $iface_name } {
						continue
					}

					set create_ifaces [dictGet $create_nodes_ifaces $node_id]
					if { "*" ni $create_ifaces && $log_iface_id ni $create_ifaces } {
						trigger_ifaceCreate $node_id $log_iface_id
					}
				}
			}
		}
	}

	trigger_linkConfig $link_id
}

proc trigger_linkDestroy { link_id { keep_ifaces 0 } } {
	global isOSlinux

	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	trigger_linkUnconfig $link_id

	prepareTerminateVars

	set link_running [isRunningLink $link_id]
	if { $link_id ni $terminate_links && $link_running == "true" } {
		lappend terminate_links $link_id

		updateTerminateVars

		set is_direct [getLinkDirect $link_id]
		foreach node_id [getLinkPeers $link_id] iface_id [getLinkPeersIfaces $link_id] {
			set node_type [getNodeType $node_id]
			if { $node_type in "packgen" } {
				trigger_nodeReconfig $node_id
			} elseif { $node_type in "filter" } {
				trigger_nodeReconfig $node_id
			}

			if { $keep_ifaces } {
				if { $isOSlinux && $is_direct } {
					trigger_ifaceRecreate $node_id $iface_id
				}
			} else {
				trigger_ifaceDestroy $node_id $iface_id
			}
		}
	} else {
		return
	}

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

	set link_running [isRunningLink $link_id]
	if { $link_running == "true" } {
		trigger_linkDestroy $link_id
	}

	trigger_linkCreate $link_id
}

proc trigger_ifaceCreate { node_id iface_id } {
	global isOSlinux

	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	prepareInstantiateVars

	if {
		! [isRunningNode $node_id] &&
		("*" ni $instantiate_nodes && $node_id ni $instantiate_nodes)
	} {
		# quit if our node is dead and it won't be created
		return
	}

	prepareTerminateVars

	set destroy_ifaces [dictGet $destroy_nodes_ifaces $node_id]
	if {
		[isRunningNodeIface $node_id $iface_id] &&
		("*" ni $destroy_ifaces && $iface_id ni $destroy_ifaces)
	} {
		# quit if this interface node is alive and it won't be destroyed
		return
	}

	set create_ifaces [dictGet $create_nodes_ifaces $node_id]
	if { "*" ni $create_ifaces && $iface_id ni $create_ifaces } {
		if { $iface_id == "*" } {
			dict set create_nodes_ifaces $node_id $iface_id

			set ifaces_list [allIfcList $node_id]
		} else {
			dict lappend create_nodes_ifaces $node_id $iface_id

			set ifaces_list $iface_id
		}

		updateInstantiateVars

		foreach iter_iface_id $ifaces_list {
			set link_id [getIfcLink $node_id $iter_iface_id]
			if { $link_id == "" } {
				continue
			}

			if { $isOSlinux && [getLinkDirect $link_id] } {
				lassign [logicalPeerByIfc $node_id $iter_iface_id] peer_id peer_iface_id -
				trigger_ifaceRecreate $peer_id $peer_iface_id

				# since interface gets destroyed, we lose a route so we reconfigure if needed
				set new_routes [appendNodeSubnetRoutes $peer_id {}]
				set node_type [getNodeType $node_id]
				if {
					$node_type in "router nat64" ||
					($node_type == "ext" && [getNodeNATIface $node_id] != "UNASSIGNED")
				} {
					triggerChangedDefaultRoutes {} $new_routes
				} elseif {
					[getNodeAutoDefaultRoutesStatus $node_id] == "enabled" &&
					[dictGet $new_routes $node_id] != {}
				} {
					trigger_nodeReconfig $node_id
				}
			}

			trigger_linkCreate $link_id
		}

		foreach iter_iface_id $ifaces_list {
			# if any of the logical interfaces have $iter_iface_id as master, recreate them
			set iface_name [getIfcName $node_id $iter_iface_id]
			foreach log_iface_id [logIfcList $node_id] {
				if { [getIfcVlanDev $node_id $log_iface_id] != $iface_name } {
					continue
				}

				set create_ifaces [dictGet $create_nodes_ifaces $node_id]
				if { "*" ni $create_ifaces && $log_iface_id ni $create_ifaces } {
					trigger_ifaceRecreate $node_id $log_iface_id
				}
			}
		}
	}

	trigger_ifaceConfig $node_id $iface_id
}

proc trigger_ifaceDestroy { node_id iface_id { keep_veth_peer 0 } } {
	global isOSlinux

	if {
		! [getFromRunning "cfg_deployed"] ||
		! [isRunningNode $node_id]
	} {
		return
	}

	trigger_ifaceUnconfig $node_id $iface_id

	prepareTerminateVars

	set destroy_ifaces [dictGet $destroy_nodes_ifaces $node_id]
	if { "*" ni $destroy_ifaces && $iface_id ni $destroy_ifaces } {
		if { $iface_id == "*" } {
			dict set destroy_nodes_ifaces $node_id $iface_id

			set ifaces_list [ifcList $node_id]
		} else {
			dict lappend destroy_nodes_ifaces $node_id $iface_id

			set ifaces_list $iface_id
		}

		updateTerminateVars

		foreach iter_iface_id $ifaces_list {
			set link_id [getIfcLink $node_id $iter_iface_id]
			if { $link_id == "" } {
				continue
			}

			trigger_linkDestroy $link_id $keep_veth_peer
		}
	} else {
		return
	}

	prepareInstantiateVars

	set create_ifaces [dictGet $create_nodes_ifaces $node_id]
	if { $iface_id in $create_ifaces } {
		set create_ifaces [removeFromList $create_ifaces $iface_id]
		if { $create_ifaces == {} } {
			dict unset create_nodes_ifaces $node_id
		} else {
			dict set create_nodes_ifaces $node_id $create_ifaces
		}
	}

	updateInstantiateVars
}

proc trigger_ifaceRecreate { node_id iface_id } {
	if {
		! [getFromRunning "cfg_deployed"] ||
		! [isRunningNode $node_id]
	} {
		return
	}

	set iface_running [isRunningNodeIface $node_id $iface_id]
	if { $iface_running == "true" } {
		trigger_ifaceDestroy $node_id $iface_id
	}

	trigger_ifaceCreate $node_id $iface_id
}

proc trigger_ifaceConfig { node_id iface_id } {
	global isOSfreebsd

	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	prepareInstantiateVars

	if {
		! [isRunningNode $node_id] &&
		("*" ni $instantiate_nodes && $node_id ni $instantiate_nodes)
	} {
		# quit if our node is dead and it won't be created
		return
	}

	prepareTerminateVars

	if {
		("*" ni $instantiate_nodes && $node_id ni $instantiate_nodes) &&
		("*" in $terminate_nodes || $node_id in $terminate_nodes)
	} {
		# quit if our node will be destroyed
		return
	}

	set ifaces [dictGet $configure_nodes_ifaces $node_id]
	if { "*" ni $ifaces && $iface_id ni $ifaces } {
		dict lappend configure_nodes_ifaces $node_id $iface_id
	}

	updateInstantiateVars

	if { $isOSfreebsd && [getNodeVlanFiltering $node_id] } {
		set link_id [getIfcLink $node_id $iface_id]
		if { $link_id != "" } {
			trigger_linkRecreate $link_id
		}
	}
}

proc trigger_ifaceUnconfig { node_id iface_id } {
	if {
		! [getFromRunning "cfg_deployed"] ||
		! [isRunningNode $node_id]
	} {
		return
	}

	prepareTerminateVars

	set unconfig_ifaces [dictGet $unconfigure_nodes_ifaces $node_id]
	if { "*" ni $unconfig_ifaces && $iface_id ni $unconfig_ifaces } {
		dict lappend unconfigure_nodes_ifaces $node_id $iface_id
	}

	updateTerminateVars

	prepareInstantiateVars

	set ifaces [dictGet $configure_nodes_ifaces $node_id]
	if { $iface_id in $ifaces } {
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
		! [isRunningNode $node_id]
	} {
		return
	}

	set iface_running [isRunningNodeIface $node_id $iface_id]
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
		sputs $line
		flush stdout
	} else {
		dputs $line

		.bottom.textbox config -text "$line" -foreground "black"
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
		sputs -nonewline "\r                                                "
		sputs -nonewline "\r> $prgs/$tot "
		flush stdout
	} elseif { $debug } {
		dputs -nonewline "\r                                                "
		dputs -nonewline "\r> $prgs/$tot "
	}
}

proc mainPipeCreate {} {
	global main_pipe
	global rcmd remote remote_mux_path

	if { $remote == "" } {
		return
	}

	if { ! [mainPipeClose] } {
		return -code error
	}

	set main_pipe [open "| $rcmd > /dev/null" w]
	chan configure $main_pipe \
		-blocking 0 -buffering none -translation binary

	set ctr 100
	while { $ctr > 0 } {
		catch { exec ssh -O check $remote -o ControlPath=$remote_mux_path } status
		if { [string match "Master running*" $status] } {
			return
		}

		dputs "Still opening... '$status'"
		after 100
		incr ctr -1
	}

	return -code error
}

proc mainPipeClose {} {
	global remote main_pipe remote_mux_path

	if { $remote == "" } {
		return
	}

	catch { exec ssh -O exit $remote -o ControlPath=$remote_mux_path } err

	set ctr 100
	while { $ctr > 0 } {
		catch { exec ssh -O check $remote -o ControlPath=$remote_mux_path } status
		if { [string match "*No such file or directory*" $status] } {
			return true
		}

		dputs "Still closing... '$status'"
		after 100
		incr ctr -1
	}

	catch { close $main_pipe }
	return false
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
	global rcmd remote
	global debug

	if { $debug } {
		set logdir "/var/log/imunes"
		if { [isNotOk "test -d \"$logdir\""] } {
			rexec mkdir -p $logdir
		}
	}

	set ncpus [getCpuCount]
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
		set logdir "/var/log/imunes"
		set logfile "$logdir/[getFromRunning "eid"].log"

		catch { info level [expr [info level] - 1] } e1
		pipesExecNoLog "cat >> $logfile 2>&1 <<\"IMUNESEOF\"\nRUN ($e1): $line\nIMUNESEOF\n $line >> $logfile 2>&1" "$args"
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
	global isOSfreebsd isOSlinux gui main_canvas_elem

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
				sputs stderr $err
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
				sputs stderr $err
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
				sputs stderr $err
			}

			return
		}

		if { [getActiveOption "editor_only"] } {
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
	} elseif {
		! [getFromRunning "cfg_deployed"] &&
		$new_oper_mode == "edit"
	} {
		set eid [getFromRunning "eid"]
		setToExecuteVars "terminate_cfg" [cfgGet]

		if { $gui } {
			if { [getActiveOption "editor_only"] } {
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
		}

		setToRunning "oper_mode" "edit"
		unsetRunning "running_state"

		if { $gui } {
			.bottom.experiment_id configure -text ""
			.bottom.oper_mode configure -text "edit mode"
			.bottom.oper_mode configure -foreground "black"

			catch { redrawAll }
			$main_canvas_elem config -cursor left_ptr
		}

		return
	}

	if { $gui } {
		bind $main_canvas_elem <1> ""
		bind $main_canvas_elem <B1-Motion> ""
		bind $main_canvas_elem <B1-ButtonRelease> ""
	}

	try {
		#.panwin.f1.left.select configure -state active
		if { "$new_oper_mode" == "exec" } {
			if { $gui } {
				.menubar.experiment entryconfigure "Execute" -state disabled
				.menubar.experiment entryconfigure "Terminate" -state normal
				.menubar.experiment entryconfigure "Restart" -state normal
				.menubar.experiment entryconfigure "Refresh running experiment" -state normal
				.menubar.edit entryconfigure "Undo" -state disabled
				.menubar.edit entryconfigure "Redo" -state disabled
			}

			setToRunning "oper_mode" "exec"

			if { ! [getFromRunning "cfg_deployed"] } {
				setToExecuteVars "instantiate_nodes" [getFromRunning "node_list"]
				setToExecuteVars "create_nodes_ifaces" "*"
				setToExecuteVars "instantiate_links" [getFromRunning "link_list"]
				setToExecuteVars "configure_links" "*"
				setToExecuteVars "configure_nodes_ifaces" "*"
				setToExecuteVars "configure_nodes" "*"

				mainPipeCreate
				deployCfg 1
				mainPipeClose

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

				mainPipeCreate
				undeployCfg $eid 1

				catch { rexec pkill -f "socat.*$eid" }
				mainPipeClose

				setToExecuteVars "terminate_cfg" [cfgGet]
				setToRunning "cfg_deployed" false
			}

			if { $gui } {
				if { [getActiveOption "editor_only"] } {
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
			}

			setToRunning "oper_mode" "edit"

			if { $gui } {
				.bottom.experiment_id configure -text ""
				set oper_mode_text "edit mode"
				set oper_mode_color "black"
			}
		}
	} on error err {
		if { $gui } {
			after idle { .dialog1.msg configure -wraplength 4i }
			tk_dialog .dialog1 "IMUNES error" \
				$err \
				info 0 Dismiss
		} else {
			sputs stderr $err
		}
	} finally {
		if { $gui } {
			bind $main_canvas_elem <1> "button1 %x %y none"
			bind $main_canvas_elem <B1-Motion> "button1-motion %x %y"
			bind $main_canvas_elem <B1-ButtonRelease> "button1-release %x %y"
		}
	}

	if { $gui } {
		.bottom.oper_mode configure -text "$oper_mode_text"
		.bottom.oper_mode configure -foreground $oper_mode_color

		catch { redrawAll }
		$main_canvas_elem config -cursor left_ptr
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
proc spawnShellExec { node_id } {
	set cmd [existingShells [invokeNodeProc $node_id "shellcmds"] $node_id "first_only"]
	if { $cmd == "" } {
		return
	}

	spawnShell $node_id $cmd
}

#****f* linux.tcl/existingShells
# NAME
#   existingShells -- check which shells exist in a node
# SYNOPSIS
#   existingShells $shells $node_id
# FUNCTION
#   This procedure checks which of the provided shells are available
#   in a running node.
# INPUTS
#   * shells -- list of shells.
#   * node_id -- node id of the node for which the check is performed.
#****
proc existingShells { shells node_id { first_only "" } } {
	set preferred_shell [getActiveOption "preferred_shell"]
	set shells "$preferred_shell [removeFromList $shells $preferred_shell]"

	set cmds "retval=\"\" ;\n"
	append cmds "\n"
	append cmds "for s in $shells; do\n"
	append cmds "	x=\"\$(command -v \$s)\" ;\n"
	append cmds "	test \$? -eq 0 && retval=\"\$retval \$x\" "
	if { $first_only != "" } {
		append cmds "&& break; \n"
	} else {
		append cmds "; \n"
	}
	append cmds "done ;\n"
	append cmds "echo \"\$retval\"\n"

	set cmds "\'$cmds\'"

	set os_cmd [invokeNodeProc $node_id "getExecCommand" [getFromRunning "eid"] $node_id]

	catch { rexec {*}$os_cmd sh -c {*}$cmds } existing

	return $existing
}

#****f* common.tcl/spawnShell
# NAME
#   spawnShell -- spawn shell
# SYNOPSIS
#   spawnShell $node_id $cmd
# FUNCTION
#   This procedure spawns a new shell for a specified node.
#   The shell is specified in cmd parameter.
# INPUTS
#   * node_id -- node id of the node for which the shell is spawned.
#   * cmd -- the path to the shell.
#****
proc spawnShell { node_id cmd } {
	global ttyrcmd

	if { [checkTerminalMissing] } {
		return
	}

	set eid [getFromRunning "eid"]

	set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
	set os_cmd [invokeNodeProc $node_id "getExecCommand" $eid $node_id "-it"]

	exec {*}[getActiveOption "terminal_command"] \
		-T "IMUNES: [getNodeName $node_id] (console) [lindex [split $cmd /] end]" \
		-e {*}$ttyrcmd "$os_cmd $cmd" &
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
		if { ! [isRunningNode $node_id] } {
			continue
		}

		fetchNodeRunningConfig $node_id
	}

	redrawAll
}

# helper func
proc writeDataToFile { path data } {
	global remote rcmd

	set dirname [file dirname $path]
	if { [isNotOk "test -d \"$dirname\""] } {
		rexec mkdir -p $dirname
	}

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

	if { [isNotOk "test -f \"$path\""] } {
		return -code error "Cannot open file '$path' for reading."
	}

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
	global gui_options_defaults
	global runtimeDir gui remote

	upvar 0 ::cf::[set ::curcfg]::dict_run dict_run
	upvar 0 ::cf::[set ::curcfg]::dict_run_gui dict_run_gui
	upvar 0 ::cf::[set ::curcfg]::execute_vars execute_vars

	try {
		readDataFromFile $runtimeDir/$eid/runningVars
	} on ok data {
		set vars_dict $data
	} on error err {
		return -code error $err
	}

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

		if { [getActiveOption "zoom"] == "" } {
			setOption_gui "zoom" [dictGet $gui_options_defaults "zoom"]
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
		if { $curr_eid == $exp && [getFromRunning "cfg_deployed"] } {
			return
		}
	}

	newProject

	set current_file ""
	try {
		getRunningExperimentConfigPath $exp
	} on ok current_file {
	} on error err {
		return -code error $err
	} finally {
		setToRunning "current_file" $current_file
	}

	try {
		openFile
		readRunningVarsFile $exp
	} on error err {
		return -code error $err
	}

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
	global gui execMode

	try {
		refreshRunningExperiment
	} on ok eid {
		toggleAutoExecutionGUI [getFromRunning "auto_execution"]

		return $eid
	} on error err {
		if { ! $gui || $execMode == "batch" } {
			statline $err
		} else {
			after idle { .dialog1.msg configure -wraplength 4i }
			tk_dialog .dialog1 "IMUNES error" $err \
				info 0 Dismiss
		}

		return ""
	}
}

proc refreshRunningExperiment {} {
	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	set eid [getFromRunning "eid"]

	set current_file ""
	try {
		getRunningExperimentConfigPath $eid
	} on ok current_file {
	} on error err {
		setToRunning "cfg_deployed" "false"
		setOperMode "edit"

		return -code error "$err\n\nThe experiment with EID $eid has been possibly terminated from outside this IMUNES instance."
	} finally {
		setToRunning "current_file" $current_file
	}

	try {
		openFile
		readRunningVarsFile $eid
	} on error err {
		return -code error $err
	}

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

	if { [getFromRunning "cfg_deployed"] } {
		try {
			getRunningExperimentConfigPath [getFromRunning "eid"]
		} on error err {
			setToRunning "cfg_deployed" "false"
			setOperMode "edit"

			return -code error "$err\n\nThe experiment with EID $eid has been possibly terminated from outside this IMUNES instance."
		}

		createRunningVarsFile [getFromRunning "eid"]
	}
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

	foreach link_id [getFromRunning "link_list"] {
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
	if { [isOk "test -d \"$runtimeDir\""] } {
		catch { rexec find "$runtimeDir" -mindepth 1 -maxdepth 1 -print } exp_paths
		if { $exp_paths != "" } {
			set exp_list [lmap exp_path $exp_paths { file tail $exp_path }]
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

	try {
		readDataFromFile "$runtimeDir/$eid/timestamp"
	} on ok data {
	} on error err {
		set data ""
	}

	return [string trim $data]
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

	try {
		readDataFromFile "$runtimeDir/$eid/name"
	} on ok data {
	} on error err {
		set data "N/A"
	}

	return $data
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
	if { $remote != "" } {
		set file_id [file tempfile tmppath]

		try {
			readDataFromFile $file_path
		} on ok data {
			puts $file_id $data
			set file_path $tmppath
		} on error err {
			return -code error $err
		} finally {
			close $file_id
		}
	} else {
		if { ! [file exists $file_path] } {
			return -code error "File '$file_path' does not exist."
		}
	}

	return $file_path
}

proc checkTerminalMissing {} {
	lassign [getActiveOption "terminal_command"] terminal
	set cmds "command -v $terminal"
	if { [catch { exec sh -c {*}$cmds }] == "" } {
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

		exec {*}[getActiveOption "terminal_command"] -T "Capturing $eid-$node_id" -e {*}$ttyrcmd "tcpdump -leni $eid-$node_id" 2> /dev/null &
	} else {
		exec $command -o "gui.window_title:[getNodeName $node_id] ($eid)" -k -i $eid-$node_id 2> /dev/null &
	}
}

proc redeployCfg {} {
	global gui main_canvas_elem

	if { ! [getFromRunning "cfg_deployed"] } {
		return
	}

	set eid [getFromRunning "eid"]

	try {
		getRunningExperimentConfigPath $eid
	} on error err {
		setToRunning "cfg_deployed" "false"
		setOperMode "edit"

		set err "$err\n\nThe experiment with EID $eid has been possibly terminated from outside this IMUNES instance."
		if { $gui } {
			after idle { .dialog1.msg configure -wraplength 4i }
			tk_dialog .dialog1 "IMUNES error" \
				$err \
				info 0 Dismiss
		} else {
			sputs stderr $err
		}

		return
	}

	if { $gui } {
		bind $main_canvas_elem <1> ""
		bind $main_canvas_elem <B1-Motion> ""
		bind $main_canvas_elem <B1-ButtonRelease> ""
	}

	try {
		if { ! [getFromRunning "auto_execution"] } {
			createExperimentFiles $eid
			createRunningVarsFile $eid
		} else {
			mainPipeCreate
			undeployCfg
			deployCfg
			mainPipeClose
		}
	} on error err {
		if { $gui } {
			after idle { .dialog1.msg configure -wraplength 4i }
			tk_dialog .dialog1 "IMUNES error" \
				$err \
				info 0 Dismiss
		} else {
			sputs stderr $err
		}
	} finally {
		if { $gui } {
			bind $main_canvas_elem <1> "button1 %x %y none"
			bind $main_canvas_elem <B1-Motion> "button1-motion %x %y"
			bind $main_canvas_elem <B1-ButtonRelease> "button1-release %x %y"
		}
	}
}

#****f* common.tcl/killExtProcess
# NAME
#   killExtProcess -- kill processes with the given regex
# SYNOPSIS
#   killExtProcess $regex
# FUNCTION
#   Executes a pkill command to kill all processes with a corresponding regex.
# INPUTS
#   * regex -- regularl expression of the processes
#****
proc killExtProcess { regex } {
	pipesExec "pkill -f \"$regex\"" "hold"
}

proc getTimeout { timeout_type } {
	global $timeout_type

	if { ! [info exists $timeout_type] } {
		return -code error "No var named $timeout_type"
	}

	return [expr { [getActiveOption "timeout_factor"] * [set $timeout_type] }]
}

proc getTimeoutCmd { timeout_type cmds } {
	set timeout [getTimeout $timeout_type]

	if { $timeout >= 0 } {
		return "timeout [expr $timeout/5.0] $cmds"
	}

	return $cmds
}

#****f* common.tcl/execCmdNode
# NAME
#   execCmdNode -- execute command on virtual node
# SYNOPSIS
#   execCmdNode $node_id $cmd
# FUNCTION
#   Executes a command on a virtual node and returns the output.
# INPUTS
#   * node_id -- virtual node id
#   * cmd -- command to execute
# RESULT
#   * returns the execution output
#****
proc execCmdNode { node_id cmd } {
	set os_cmd [invokeNodeProc $node_id "getExecCommand" [getFromRunning "eid"] $node_id]

	catch { eval [concat "rexec $os_cmd" $cmd] } output

	return $output
}

#****f* common.tcl/moveFileFromNode
# NAME
#   moveFileFromNode -- move file from virtual node
# SYNOPSIS
#   moveFileFromNode $node_id $path $ext_path
# FUNCTION
#   Moves file from virtual node to a specified external path.
# INPUTS
#   * node_id -- virtual node id
#   * path -- path to file in node
#   * ext_path -- external path
#****
proc moveFileFromNode { node_id path ext_path } {
	set host_path [getHostNodePath $node_id $path]
	if { $host_path != "" } {
		catch { rexec mv $host_path $ext_path }
	}
}

#****f* common.tcl/writeDataToNodeFile
# NAME
#   writeDataToNodeFile -- write data to virtual node
# SYNOPSIS
#   writeDataToNodeFile $node_id $path $data
# FUNCTION
#   Writes data to a file on the specified virtual node.
# INPUTS
#   * node_id -- virtual node id
#   * path -- path to file in node
#   * data -- data to write
#****
proc writeDataToNodeFile { node_id path data } {
	set host_path [getHostNodePath $node_id $path]
	if { $host_path != "" } {
		writeDataToFile $host_path $data
	}
}

#****f* common.tcl/execCmdNodeBkg
# NAME
#   execCmdNodeBkg -- execute command on virtual node
# SYNOPSIS
#   execCmdNodeBkg $node_id $cmd
# FUNCTION
#   Executes a command on a virtual node (in the background).
# INPUTS
#   * node_id -- virtual node id
#   * cmd -- command to execute
#****
proc execCmdNodeBkg { node_id cmd } {
	set os_cmd [invokeNodeProc $node_id "getExecCommand" [getFromRunning "eid"] $node_id "-d"]

	pipesExec "$os_cmd sh -c '$cmd'" "hold"
}

#****f* common.tcl/checkForExternalApps
# NAME
#   checkForExternalApps -- check whether external applications exist
# SYNOPSIS
#   checkForExternalApps $app_list
# FUNCTION
#   Checks whether a list of applications exist on the machine running IMUNES
#   by using the which command.
# INPUTS
#   * app_list -- list of applications
# RESULT
#   * returns 0 if the applications exist, otherwise it returns 1.
#****
proc checkForExternalApps { app_list } {
	foreach app $app_list {
		set cmds "command -v $app"
		set status [ catch { exec sh -c $cmds } err ]
		if { $status } {
			return 1
		}
	}

	return 0
}

#****f* common.tcl/checkForApplications
# NAME
#   checkForApplications -- check whether applications exist
# SYNOPSIS
#   checkForApplications $node_id $app_list
# FUNCTION
#   Checks whether a list of applications exist on the virtual node by using
#   the 'command' command.
# INPUTS
#   * node_id -- virtual node id
#   * app_list -- list of applications
# RESULT
#   * returns 0 if the applications exist, otherwise it returns 1.
#****
proc checkForApplications { node_id app_list } {
	set os_cmd [invokeNodeProc $node_id "getExecCommand" [getFromRunning "eid"] $node_id]

	foreach app $app_list {
		set os_cmd "$os_cmd sh -c 'command -v $app'"
		set status [ catch { rexec {*}$os_cmd } err ]
		if { $status } {
			return 1
		}
	}

	return 0
}

#****f* common.tcl/startXappOnNode
# NAME
#   startXappOnNode -- start X application in a virtual node
# SYNOPSIS
#   startXappOnNode $node_id $app
# FUNCTION
#   Start X application on virtual node
# INPUTS
#   * node_id -- virtual node id
#   * app -- application to start
#****
proc startXappOnNode { node_id app } {
	global debug remote

	if { $remote != "" } {
		sputs stderr "Running X applications in nodes on remote host is not supported."

		return
	}

	if { [checkForExternalApps "socat"] != 0 } {
		sputs stderr "To run X applications on the node, install socat on your host."
		return
	}

	set eid [getFromRunning "eid"]

	set logfile "/dev/null"
	if { $debug } {
		set logfile "/tmp/startxcmd_$eid\_$node_id.log"
	}

	eval exec startxcmd [getNodeName $node_id]@$eid $app > $logfile 2>> $logfile &
}

#****f* common.tcl/startTcpdumpOnNodeIfc
# NAME
#   startTcpdumpOnNodeIfc -- start tcpdump on an interface
# SYNOPSIS
#   startTcpdumpOnNodeIfc $node_id $iface_name
# FUNCTION
#   Start tcpdump in a terminal on a virtual node on the specified interface.
# INPUTS
#   * node_id -- virtual node id
#   * iface_name -- virtual node interface
#****
proc startTcpdumpOnNodeIfc { node_id iface_name } {
	if { [checkForApplications $node_id "tcpdump"] == 0 } {
		spawnShell $node_id "tcpdump -leni $iface_name"
	}
}

#****f* common.tcl/getHostIfcVlanExists
# NAME
#   getHostIfcVlanExists -- check if host VLAN interface exists
# SYNOPSIS
#   getHostIfcVlanExists $node_id $iface_name
# FUNCTION
#   Returns 1 if VLAN interface with the name iface_name for the given node cannot
#   be created.
# INPUTS
#   * node_id -- node id
#   * iface_name -- interface id
# RESULT
#   * check -- 1 if interface exists, 0 otherwise
#****
proc getHostIfcVlanExists { node_id iface_name } {
	global execMode gui

	# check if VLAN ID is already taken
	# this can be only done by trying to create it, as it's possible that the same
	# VLAN interface already exists in some other namespace
	set iface_id [ifaceIdFromName $node_id $iface_name]
	set vlan [getIfcVlanTag $node_id $iface_id]
	try {
		createVlanIfaceOnHost $iface_name $vlan
	} on ok {} {
		destroyVlanIfaceOnHost $iface_name $vlan

		return 0
	} on error err {
		set msg "Unable to create external interface '${iface_name}_$vlan':\n$err\n\nPlease\
			verify that VLAN ID $vlan with parent interface $iface_name is not already\
			assigned to another VLAN interface, potentially in a different jail/namespace."
	}

	if { ! $gui || $execMode == "batch" } {
		sputs stderr $msg
	} else {
		after idle { .dialog1.msg configure -wraplength 4i }
		tk_dialog .dialog1 "IMUNES error" $msg \
			info 0 Dismiss
	}

	return 1
}

#****f* common.tcl/nodeLogIfacesCreate
# NAME
#   nodeLogIfacesCreate -- create node logical interfaces
# SYNOPSIS
#   nodeLogIfacesCreate $node_id
# FUNCTION
#   Creates logical interfaces for the given node.
# INPUTS
#   * node_id -- node id
#****
proc nodeLogIfacesCreate { node_id ifaces } {
	set eid [getFromRunning "eid"]
	set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

	set cmds ""
	foreach iface_id $ifaces {
		set iface_name [getIfcName $node_id $iface_id]
		switch -exact [getIfcType $node_id $iface_id] {
			vlan {
				set tag [getIfcVlanTag $node_id $iface_id]
				set dev [getIfcVlanDev $node_id $iface_id]
				if { $tag != "" && $dev != "" } {
					append cmds "[getVlanTagIfcCmd $iface_name $dev $tag]\n"
					addStateNodeIface $node_id $iface_id "creating"
				} else {
					removeStateNodeIface $node_id $iface_id "running"
				}
			}
			lo {
				addStateNodeIface $node_id $iface_id "creating"
				if { $iface_name != "lo0" } {
					append cmds "[getLoopbackIfcCmd $iface_name]\n"
					append cmds "[getStateIfcCmd $iface_name "up"]\n"
				} else {
					append cmds "[getLo0HandleCmd]\n"
				}
			}
		}
	}

	if { $cmds != "" } {
		set os_cmd [invokeNodeProc $node_id "getExecCommand" $eid $node_id "-d"]
		pipesExec "$os_cmd sh -c '$cmds'" "hold"
	}

	# TODO: for podman?
	## docker interface is created before other ones, so let's rename it to something that's not used by IMUNES
	#if { [getNodeDockerAttach $node_id] == 1 } {
	#	set cmds "ip r save > /tmp/routes"
	#	set cmds "$cmds ; ip l set eth0 down"
	#	set cmds "$cmds ; ip l set eth0 name docker0"
	#	set cmds "$cmds ; ip l set docker0 up"
	#	set cmds "$cmds ; ip r restore < /tmp/routes"
	#	set cmds "$cmds ; rm -f /tmp/routes"
	#	pipesExec "docker exec -d $docker_id sh -c '$cmds'" "hold"
	#}
}
