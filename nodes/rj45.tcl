#
# Copyright 2005-2013 University of Zagreb.
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

# $Id: rj45.tcl 130 2015-02-24 09:52:19Z valter $


#****h* imunes/rj45.tcl
# NAME
#  rj45.tcl -- defines rj45 specific procedures
# FUNCTION
#  This module is used to define all the rj45 specific procedures.
# NOTES
#  Procedures in this module start with the keyword rj45 and
#  end with function specific part that is the same for all the
#  node types that work on the same layer.
#****

set MODULE rj45
registerModule $MODULE

namespace eval $MODULE {
	# Define all node-specific procedures. All non-defined procedures will call
	# genericL2.* procedure from nodes/generic_l2.tcl
	namespace import ::genericL2::*
	namespace export *

	################################################################################
	########################### CONFIGURATION PROCEDURES ###########################
	################################################################################

	proc namingBase {} {
		return "rj45-"
	}

	#****f* rj45.tcl/rj45.ifacePrefix
	# NAME
	#   rj45.ifacePrefix -- interface name prefix
	# SYNOPSIS
	#   rj45.ifacePrefix
	# FUNCTION
	#   Returns rj45 interface name prefix.
	# RESULT
	#   * name -- name prefix string
	#****
	proc ifacePrefix {} {
		return "x"
	}

	proc getPrivateNs { eid node_id } {
		global isOSlinux isOSfreebsd

		if { $isOSlinux } {
			return $eid
		}

		if { $isOSfreebsd } {
			return $eid
		}
	}

	proc getPublicNs { eid node_id } {
		global isOSlinux isOSfreebsd

		if { $isOSlinux } {
			return $eid
		}

		if { $isOSfreebsd } {
			return $eid
			return
		}
	}

	proc getHookData { node_id iface_id } {
		global isOSlinux isOSfreebsd

		# rj45 does not differentiate between private/public iface
		set private_elem [getIfcName $node_id $iface_id]
		set vlan [getIfcVlanTag $node_id $iface_id]

		if { $vlan != "" && [getIfcVlanDev $node_id $iface_id] != "" } {
			set private_elem ${private_elem}_$vlan
		}
		set public_elem $private_elem

		# Linux - not used
		# FreeBSD - hook for connecting to netgraph node
		set hook_name "lower"

		return [list $private_elem $public_elem $hook_name]
	}

	proc getExecCommand { eid node_id { flags "" } } {
		return ""
	}

	################################################################################
	############################ INSTANTIATE PROCEDURES ############################
	################################################################################

	#****f* rj45.tcl/rj45.prepareSystem
	# NAME
	#   rj45.prepareSystem -- prepare system
	# SYNOPSIS
	#   rj45.prepareSystem
	# FUNCTION
	#   Loads ng_ether into the kernel.
	#****
	proc prepareSystem {} {
		global isOSlinux isOSfreebsd

		if { $isOSlinux } {
			return
		}

		if { $isOSfreebsd } {
			catch { rexec kldload ng_ether }

			return
		}
	}

	proc checkNodePrerequisites { eid node_id } {
		return true
	}

	proc checkIfacesPrerequisites { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		foreach iface_id $ifaces {
			removeStateNodeIface $node_id $iface_id "error"
			setStateErrorMsgNodeIface $node_id $iface_id ""

			if { [getIfcName $node_id $iface_id] == "UNASSIGNED" } {
				set ifaces [removeFromList $ifaces $iface_id]
			}
		}

		if { $ifaces == {} } {
			return true
		}

		set stolen {}
		set vlan_pairs [dict create]
		set direct {}
		set direct_l2 {}
		foreach other_node_id [getFromRunning "node_list"] {
			if {
				([getFromRunning "cfg_deployed"] &&
				! [isRunningNode $other_node_id]) ||
				$other_node_id in [getFromRunning "no_auto_execute_nodes"]
			} {
				continue
			}

			set other_ifaces [ifcList $other_node_id]
			if { $node_id == $other_node_id } {
				set other_ifaces [removeFromList $other_ifaces $ifaces]
			}

			dputs "checking $other_node_id - '$other_ifaces'"
			foreach other_iface_id $other_ifaces {
				if {
					[getFromRunning "cfg_deployed"] &&
					! [isRunningNodeIface $other_node_id $other_iface_id] &&
					"creating" ni [getStateNodeIface $other_node_id $other_iface_id]
				} {
					dputs "skipping $other_node_id - '$other_ifaces'"
					continue
				}

				if { [getIfcType $other_node_id $other_iface_id] == "stolen" } {
					set other_iface_name [getIfcName $other_node_id $other_iface_id]
					set other_vlan [getIfcVlanTag $other_node_id $other_iface_id]
					set other_dev [getIfcVlanDev $other_node_id $other_iface_id]
					if { $other_vlan != "" && $other_dev != "" } {
						dict lappend vlan_pairs $other_dev $other_vlan
						set other_iface_name "${other_iface_name}_$other_vlan"
					}

					set other_link_id [getIfcLink $other_node_id $other_iface_id]
					if { $other_link_id != "" && [getLinkDirect $other_link_id] } {
						lassign [logicalPeerByIfc $other_node_id $other_iface_id] peer_id peer_iface_id
						if { [getNodeType $peer_id] in "hub lanswitch" } {
							if { $other_iface_name ni $direct_l2 } {
								lappend direct_l2 $other_iface_name
							}

							continue
						}

						if { $other_iface_name ni $direct } {
							lappend direct $other_iface_name
						}

						continue
					}

					if { $other_iface_name ni $stolen } {
						lappend stolen $other_iface_name
					}

					continue
				}
			}
		}

		# check own ifaces
		set error_ifaces {}
		foreach iface_id $ifaces {
			setStateErrorMsgNodeIface $node_id $iface_id ""

			set add_to_vlan 0
			set vlan [getIfcVlanTag $node_id $iface_id]
			set dev_name [getIfcVlanDev $node_id $iface_id]
			if { $vlan != "" && $dev_name != "" } {
				set iface_name "${dev_name}_$vlan"
				set add_to_vlan 1
			} else {
				set iface_name [getIfcName $node_id $iface_id]
			}

			set link_id [getIfcLink $node_id $iface_id]
			set link_is_direct [getLinkDirect $link_id]
			set add_to_direct 0
			set link_is_direct_l2 0
			lassign [logicalPeerByIfc $node_id $iface_id] peer_id peer_iface_id
			if { $link_is_direct && [getNodeType $peer_id] in "hub lanswitch" } {
				set link_is_direct_l2 1
			}

			if { $link_id != "" && $link_is_direct && ! $link_is_direct_l2 } {
				if { $iface_name in $direct_l2 } {
					addStateNodeIface $node_id $iface_id "error"
					if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
						setStateErrorMsgNodeIface $node_id $iface_id "Cannot use '$iface_name' for $iface_id - existing passthru mode with L2 node prevents from using it for anything else."
					}

					if { $iface_id ni $error_ifaces } {
						lappend error_ifaces $iface_id
					}
				}

				if { $iface_name in $stolen } {
					addStateNodeIface $node_id $iface_id "error"
					if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
						setStateErrorMsgNodeIface $node_id $iface_id "Cannot use '$iface_name' for $iface_id - already stolen in the experiment."
					}

					if { $iface_id ni $error_ifaces } {
						lappend error_ifaces $iface_id
					}
				}

				if { $dev_name != "" } {
					if { $dev_name in $stolen } {
						addStateNodeIface $node_id $iface_id "error"
						if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
							setStateErrorMsgNodeIface $node_id $iface_id "Cannot use '$dev_name' for $iface_id - already stolen in the experiment."
						}

						if { $iface_id ni $error_ifaces } {
							lappend error_ifaces $iface_id
						}
					}

					if { $iface_name in $stolen } {
						addStateNodeIface $node_id $iface_id "error"
						if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
							setStateErrorMsgNodeIface $node_id $iface_id "Cannot use '$dev_name' for $iface_id - already used as a trunk in the experiment."
						}

						if { $iface_id ni $error_ifaces } {
							lappend error_ifaces $iface_id
						}
					}
				}

				if { $iface_name ni $direct } {
					set add_to_direct 1
				}
			}

			set add_to_stolen 0
			if { $link_is_direct == 0 || $link_is_direct_l2 } {
				if { $iface_name in $direct_l2 } {
					addStateNodeIface $node_id $iface_id "error"
					if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
						setStateErrorMsgNodeIface $node_id $iface_id "Cannot use '$iface_name' for $iface_id - existing passthru mode with L2 node prevents from using it for anything else."
					}

					if { $iface_id ni $error_ifaces } {
						lappend error_ifaces $iface_id
					}
				}

				if { $iface_name in $direct } {
					addStateNodeIface $node_id $iface_id "error"
					if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
						if { $link_is_direct_l2 } {
							setStateErrorMsgNodeIface $node_id $iface_id "Cannot use '$iface_name' for $iface_id on L2 node - already used in the experiment."
						} else {
							setStateErrorMsgNodeIface $node_id $iface_id "Cannot steal '$iface_name' for $iface_id - already used as a direct interface in the experiment."
						}
					}

					if { $iface_id ni $error_ifaces } {
						lappend error_ifaces $iface_id
					}
				}

				if { $iface_name in $stolen } {
					addStateNodeIface $node_id $iface_id "error"
					if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
						setStateErrorMsgNodeIface $node_id $iface_id "Cannot use '$iface_name' for $iface_id - already stolen in the experiment."
					}

					if { $iface_id ni $error_ifaces } {
						lappend error_ifaces $iface_id
					}
				}

				if { $iface_name in [dict keys $vlan_pairs] } {
					addStateNodeIface $node_id $iface_id "error"
					if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
						setStateErrorMsgNodeIface $node_id $iface_id "Cannot steal '$iface_name' for $iface_id - already used as a trunk in the experiment."
					}

					if { $iface_id ni $error_ifaces } {
						lappend error_ifaces $iface_id
					}
				}

				if { $dev_name != "" } {
					if { $dev_name in $direct } {
						addStateNodeIface $node_id $iface_id "error"
						if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
							setStateErrorMsgNodeIface $node_id $iface_id "Cannot use '$dev_name' for $iface_id - already used in the experiment."
						}

						if { $iface_id ni $error_ifaces } {
							lappend error_ifaces $iface_id
						}
					}

					if { $dev_name in $stolen } {
						addStateNodeIface $node_id $iface_id "error"
						if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
							setStateErrorMsgNodeIface $node_id $iface_id "Cannot use '$dev_name' for $iface_id - already stolen in the experiment."
						}

						if { $iface_id ni $error_ifaces } {
							lappend error_ifaces $iface_id
						}
					}

					if { $dev_name in [dict keys $vlan_pairs] && $vlan in [dictGet $vlan_pairs $dev_name] } {
						addStateNodeIface $node_id $iface_id "error"
						if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
							setStateErrorMsgNodeIface $node_id $iface_id "Cannot use '$dev_name' for $iface_id - VLAN $vlan already used in the experiment."
						}

						if { $iface_id ni $error_ifaces } {
							lappend error_ifaces $iface_id
						}
					}
				}

				if { $iface_name ni $stolen } {
					set add_to_stolen 1
				}
			}

			if { $add_to_vlan } {
				dict lappend vlan_pairs $dev_name $vlan
			}

			if { $add_to_direct } {
				lappend direct $iface_name
			}

			if { $add_to_stolen } {
				lappend stolen $iface_name
			}

			if { $link_is_direct_l2 } {
				if { $iface_name ni $direct_l2 } {
					lappend direct_l2 $iface_name
				}
			}
		}

		set ifaces [removeFromList $ifaces $error_ifaces]

		set host_ifaces [getHostIfcList]

		set node_name [getNodeName $node_id]
		foreach iface_id $ifaces {
			set link_id [getIfcLink $node_id $iface_id]
			if { $link_id != "" && [getLinkDirect $link_id] } {
				continue
			}

			set vlan [getIfcVlanTag $node_id $iface_id]
			set dev_name [getIfcVlanDev $node_id $iface_id]
			if { $vlan == "" || $dev_name == "" } {
				set iface_name [getIfcName $node_id $iface_id]
				if { $iface_name ni $host_ifaces } {
					lappend error_ifaces $iface_id

					addStateNodeIface $node_id $iface_id "error"
					if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
						setStateErrorMsgNodeIface $node_id $iface_id "Cannot use '$iface_name' for $iface_id - no interface on host!"
					}
				}

				continue
			}

			# check if VLAN ID is already taken
			# this can be only done by trying to create it, as it's possible that the same
			# VLAN interface already exists in some other namespace
			try {
				if { $isOSlinux } {
					rexec ip link add link $dev_name name ${dev_name}_$vlan type vlan id $vlan
				}

				if { $isOSfreebsd } {
					rexec ifconfig $dev_name.$vlan create
				}
			} on ok {} {
				if { $isOSlinux } {
					rexec ip link del ${dev_name}_$vlan
				}

				if { $isOSfreebsd } {
					rexec ifconfig $dev_name.$vlan destroy
				}
			} on error err {
				lappend error_ifaces $iface_id

				addStateNodeIface $node_id $iface_id "error"
				if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
					setStateErrorMsgNodeIface $node_id $iface_id "VLAN error on '$node_name', interface '$dev_name': $err"
				}
			}
		}

		foreach iface_id [removeFromList $ifaces $error_ifaces] {
			try {
				rexec test -d /sys/class/net/$iface_name/wireless
			} on error {} {
				# not wireless, so MAC address can be changed
				removeStateNodeIface $node_id $iface_id "wireless"
			} on ok {} {
				# we cannot use macvlan on wireless interfaces, so MAC address cannot be changed
				addStateNodeIface $node_id $iface_id "wireless"
				if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
					setStateErrorMsgNodeIface $node_id $iface_id "Wireless interface '$iface_name' for $iface_id detected, cannot change MAC address."
				}
			}
		}

		if { $error_ifaces != {} } {
			return false
		}

		return true
	}

	#****f* rj45.tcl/rj45.nodeCreate
	# NAME
	#   rj45.nodeCreate -- instantiate
	# SYNOPSIS
	#   rj45.nodeCreate $eid $node_id
	# FUNCTION
	#   Procedure rj45.nodeCreate puts real interface into promiscuous mode.
	# INPUTS
	#   * eid -- experiment id
	#   * node_id -- node id
	#****
	proc nodeCreate { eid node_id } {
		addStateNode $node_id "node_creating"
	}

	proc nodeCreate_check { eid node_id } {
		removeStateNode $node_id "error"
		addStateNode $node_id "running"

		return true
	}

	#****f* rj45.tcl/rj45.nodeNamespaceSetup
	# NAME
	#   rj45.nodeNamespaceSetup -- rj45 node nodeNamespaceSetup
	# SYNOPSIS
	#   rj45.nodeNamespaceSetup $eid $node_id
	# FUNCTION
	#   Linux only. Attaches the existing Docker netns to a new one.
	# INPUTS
	#   * eid -- experiment id
	#   * node_id -- node id
	#****
	proc nodeNamespaceSetup { eid node_id } {
	}

	proc nodeNamespaceSetup_check { eid node_id } {
		return true
	}

	proc nodePhysIfacesCreate { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		# first deal with VLAN interfaces to avoid 'non-existant'
		# interface error
		set vlan_ifaces {}
		set nonvlan_ifaces {}
		foreach iface_id $ifaces {
			if { [getIfcVlanTag $node_id $iface_id] != "" && [getIfcVlanDev $node_id $iface_id] != "" } {
				lappend vlan_ifaces $iface_id
			} else {
				lappend nonvlan_ifaces $iface_id
			}
		}

		foreach iface_id [concat $vlan_ifaces $nonvlan_ifaces] {
			unsetRunning "${node_id}|${iface_id}_active_name"
			unsetRunning "${node_id}|${iface_id}_active_vlan"
			unsetRunning "${node_id}|${iface_id}_active_dev"

			lassign [logicalPeerByIfc $node_id $iface_id] peer_id peer_iface_id
			if { [getIfcName $node_id $iface_id] == "UNASSIGNED" } {
				removeStateNodeIface $peer_id $peer_iface_id "error creating running"

				continue
			}

			# EID netns
			set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
			lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] iface_name - -

			set vlan [getIfcVlanTag $node_id $iface_id]
			set dev_name [getIfcVlanDev $node_id $iface_id]

			if { $isOSlinux } {
				if { $vlan != "" && $dev_name != "" } {
					pipesExec "ip link set $dev_name up" "hold"
					pipesExec "ip link add link $dev_name name $iface_name type vlan id $vlan" "hold"
				}

				# actually, capture iface to experiment namespace
				pipesExec "ip link set $iface_name netns $private_ns" "hold"
				pipesExec "ip -n $private_ns link set $iface_name up promisc on" "hold"
			}

			if { $isOSfreebsd } {
				if { $vlan != "" && $dev_name != "" } {
					pipesExec "ifconfig $dev_name up" "hold"
					pipesExec "ifconfig $dev_name.$vlan create" "hold"
					pipesExec "ifconfig ${dev_name}.$vlan name $iface_name" "hold"
				}

				pipesExec "ifconfig $iface_name vnet $private_ns" "hold"
				pipesExec "jexec $private_ns ifconfig $iface_name up promisc" "hold"
			}

			setToRunning "${node_id}|${iface_id}_active_name" $iface_name
			setToRunning "${node_id}|${iface_id}_active_vlan" $vlan
			setToRunning "${node_id}|${iface_id}_active_dev" $dev_name

			addStateNode $node_id "pifaces_creating"
			addStateNodeIface $node_id $iface_id "creating"
		}
	}

	proc nodePhysIfacesDirectCreate { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		if { $isOSlinux } {
			global devfs_number

			# default netns
			set private_ns "imunes_$devfs_number"
			set public_ns [invokeNodeProc $node_id "getPublicNs" $eid $node_id]

			foreach iface_id $ifaces {
				unsetRunning "${node_id}|${iface_id}_active_name"
				unsetRunning "${node_id}|${iface_id}_active_vlan"
				unsetRunning "${node_id}|${iface_id}_active_dev"

				lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] iface_name - -
				set link_id [getIfcLink $node_id $iface_id]

				lassign [logicalPeerByIfc $node_id $iface_id] peer_id peer_iface_id

				if {
					"creating" in [getStateNodeIface $node_id $iface_id]
				} {
					if { [getNodeType $peer_id] == "rj45" } {
						# rj45-rj45 link
						setNsIfcMaster $private_ns $iface_name $eid-$link_id "up"
					}

					continue
				}

				addStateNode $node_id "pifaces_creating"
				addStateNode $peer_id "pifaces_creating"

				addStateNodeIface $node_id $iface_id "creating"
				addStateNodeIface $peer_id $peer_iface_id "creating"

				set vlan [getIfcVlanTag $node_id $iface_id]
				set dev_name [getIfcVlanDev $node_id $iface_id]

				setToRunning "${node_id}|${iface_id}_active_name" $iface_name
				setToRunning "${node_id}|${iface_id}_active_vlan" $vlan
				setToRunning "${node_id}|${iface_id}_active_dev" $dev_name

				if { $vlan != "" && $dev_name != "" } {
					set total_vlans [getFromRunning "${dev_name}|${vlan}_direct_count"]
					if { $total_vlans != "" } {
						setToRunning "${dev_name}|${vlan}_direct_count" [incr total_vlans]
					} else {
						pipesExec "ip link add link $dev_name name $iface_name netns $public_ns type vlan id $vlan" "hold"
						setToRunning "${dev_name}|${vlan}_direct_count" 1
					}
				}

				if { [getNodeType $peer_id] == "rj45" } {
					# create link bridge in the default netns and attach to it
					createNsLinkBridge $private_ns $eid-$link_id
					setNsIfcMaster $private_ns $iface_name $eid-$link_id "up"
				}

				# invoke other node
				invokeNodeProc $peer_id "nodePhysIfacesDirectCreate" $eid $peer_id $peer_iface_id
			}
		}

		if { $isOSfreebsd } {
			return [invokeNodeProc $node_id "nodePhysIfacesCreate" $eid $node_id $ifaces]
		}
	}

	proc nodePhysIfacesCreate_check { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		foreach iface_id $ifaces {
			if {
				[isRunningNodeIface $node_id $iface_id] ||
				"creating" ni [getStateNodeIface $node_id $iface_id]
			} {
				set ifaces [removeFromList $ifaces $iface_id]
			}
		}

		if { $ifaces == {} } {
			return true
		}

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

		if { $isOSlinux } {
			foreach iface_id $ifaces {
				removeStateNodeIface $node_id $iface_id "error creating"
				setStateErrorMsgNodeIface $node_id $iface_id ""
				addStateNodeIface $node_id $iface_id "running"
			}

			return true
		}

		if { $isOSfreebsd } {
			set cmds "ifconfig -l"
			if { $private_ns != "" } {
				set cmds "jexec $private_ns sh -c '$cmds'"
			}
		}

		set cmds [getTimeoutCmd "ifacesconf_timeout" $cmds]

		try {
			rexec $cmds
		} on ok ifaces_all {
			if { [string trim $ifaces_all "\n "] == "" } {
				return false
			}

			set ifaces_created {}
			foreach iface_id $ifaces {
				lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] iface_name - -
				if {
					[isRunningNodeIface $node_id $iface_id] ||
					("creating" in [getStateNodeIface $node_id $iface_id] &&
					$iface_name in $ifaces_all)
				} {
					lappend ifaces_created $iface_id

					removeStateNodeIface $node_id $iface_id "error creating"
					setStateErrorMsgNodeIface $node_id $iface_id ""
					addStateNodeIface $node_id $iface_id "running"
				} else {
					addStateNodeIface $node_id $iface_id "error"
					if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
						setStateErrorMsgNodeIface $node_id $iface_id "Interface '$iface_id' ($iface_name) not created."
					}
				}
			}

			if { [llength $ifaces] == [llength $ifaces_created] } {
				return true
			}

			return false
		} on error {} {
			return false
		}

		return false
	}

	################################################################################
	############################# TERMINATE PROCEDURES #############################
	################################################################################

	proc nodePhysIfacesDestroy { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		addStateNode $node_id "pifaces_destroying"

		# EID netns
		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

		foreach iface_id $ifaces {
			set active_iface_name [getFromRunning "${node_id}|${iface_id}_active_name"]
			unsetRunning "${node_id}|${iface_id}_active_name"
			if { $active_iface_name == "" } {
				removeStateNodeIface $node_id $iface_id "running"

				continue
			}

			addStateNodeIface $node_id $iface_id "destroying"

			set active_vlan [getFromRunning "${node_id}|${iface_id}_active_vlan"]
			set active_dev [getFromRunning "${node_id}|${iface_id}_active_dev"]
			unsetRunning "${node_id}|${iface_id}_active_vlan"
			unsetRunning "${node_id}|${iface_id}_active_dev"
			if { $active_vlan != "" && $active_dev != "" } {
				if { $isOSlinux } {
					pipesExec "ip -n $private_ns link del $active_iface_name" "hold"
				}

				if { $isOSfreebsd } {
					pipesExec "ifconfig $active_iface_name -vnet $eid destroy" ""
				}

				continue
			}

			releaseExtIfcByName $eid $active_iface_name $node_id
		}
	}

	proc nodePhysIfacesDirectDestroy { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		if { $isOSlinux } {
			addStateNode $node_id "pifaces_destroying"

			# EID netns
			set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

			foreach iface_id $ifaces {
				set active_iface_name [getFromRunning "${node_id}|${iface_id}_active_name"]
				set active_vlan [getFromRunning "${node_id}|${iface_id}_active_vlan"]
				set active_dev [getFromRunning "${node_id}|${iface_id}_active_dev"]
				unsetRunning "${node_id}|${iface_id}_active_name"
				unsetRunning "${node_id}|${iface_id}_active_vlan"
				unsetRunning "${node_id}|${iface_id}_active_dev"

				if { $active_iface_name == "" } {
					removeStateNodeIface $node_id $iface_id "running"

					continue
				}

				lassign [logicalPeerByIfc $node_id $iface_id] peer_id peer_iface_id

				if {
					"destroying" in [getStateNodeIface $node_id $iface_id]
				} {
					pipesExec "echo already destroyed!" "hold"
					continue
				}

				addStateNode $node_id "pifaces_destroying"
				addStateNode $peer_id "pifaces_destroying"
				addStateNodeIface $node_id $iface_id "destroying"
				addStateNodeIface $peer_id $peer_iface_id "destroying"

				if { [getNodeType $peer_id] == "rj45" } {
					global devfs_number

					# rj45-rj45 link
					set link_id [getIfcLink $node_id $iface_id]

					# destroy link bridge in the default netns
					pipesExec "ip -n imunes_$devfs_number link del $eid-$link_id"
				} else {
					invokeNodeProc $peer_id "nodePhysIfacesDirectDestroy" $eid $peer_id $peer_iface_id
				}

				if { $active_vlan != "" && $active_dev != "" } {
					set total_vlans [getFromRunning "${active_dev}|${active_vlan}_direct_count"]
					if { $total_vlans > 1 } {
						setToRunning "${active_dev}|${active_vlan}_direct_count" [incr total_vlans -1]
					} else {
						unsetRunning "${active_dev}|${active_vlan}_direct_count"
						pipesExec "ip -n $private_ns link del $active_iface_name" "hold"
					}
				}
			}
		}

		if { $isOSfreebsd } {
			return [invokeNodeProc $node_id "nodePhysIfacesDestroy" $eid $node_id $ifaces]
		}
	}

	proc nodeIfacesDestroy_check { eid node_id ifaces } {
		removeStateNode $node_id "pifaces_destroying"

		foreach iface_id $ifaces {
			removeStateNodeIface $node_id $iface_id "error destroying running"
		}

		return true
	}

	#****f* rj45.tcl/rj45.nodeDestroy
	# NAME
	#   rj45.nodeDestroy -- destroy
	# SYNOPSIS
	#   rj45.nodeDestroy $eid $node_id
	# FUNCTION
	#   Destroys an rj45 emulation interface.
	# INPUTS
	#   * eid -- experiment id
	#   * node_id -- node id
	#****
	proc nodeDestroy { eid node_id } {
		removeStateNode $node_id "error running"
	}

	proc nodeDestroy_check { eid node_id } {
		return true
	}
}
