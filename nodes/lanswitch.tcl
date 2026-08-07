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

# $Id: lanswitch.tcl 129 2015-02-13 11:14:44Z valter $


#****h* imunes/lanswitch.tcl
# NAME
#  lanswitch.tcl -- defines lanswitch specific procedures
# FUNCTION
#  This module is used to define all the lanswitch specific procedures.
# NOTES
#  Procedures in this module start with the keyword lanswitch and
#  end with function specific part that is the same for all the
#  node types that work on the same layer.
#****

set MODULE lanswitch
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
		return "switch"
	}

	proc getHookData { node_id iface_id } {
		global isOSlinux isOSfreebsd

		lassign [invokeTypeProc "genericL2" "getHookData" $node_id $iface_id] private_elem public_elem hook_name

		if { $isOSfreebsd } {
			# name of public netgraph peer
			if { [getNodeVlanFiltering $node_id] } {
				if { [getIfcVlanType $node_id $iface_id] == "trunk" } {
					set public_elem "$node_id-downstream"
				} else {
					set vlantag [getIfcVlanTag $node_id $iface_id]
					set public_elem "$node_id-v$vlantag"
				}
			}
		}

		return [list $private_elem $public_elem $hook_name]
	}

	################################################################################
	############################ INSTANTIATE PROCEDURES ############################
	################################################################################

	#****f* lanswitch.tcl/lanswitch.prepareSystem
	# NAME
	#   lanswitch.prepareSystem -- prepare system
	# SYNOPSIS
	#   lanswitch.prepareSystem
	# FUNCTION
	#   Loads ng_bridge into the kernel.
	#****
	proc prepareSystem {} {
		global isOSlinux isOSfreebsd

		if { $isOSlinux } {
			return [invokeTypeProc "genericL2" "prepareSystem"]
		}

		if { $isOSfreebsd } {
			catch { rexec kldload ng_bridge ng_vlan }
		}
	}

	#****f* lanswitch.tcl/lanswitch.nodeCreate
	# NAME
	#   lanswitch.nodeCreate -- instantiate
	# SYNOPSIS
	#   lanswitch.nodeCreate $eid $node_id
	# FUNCTION
	#   Procedure lanswitch.nodeCreate creates a new netgraph node of the type
	#   bridge. The name of the netgraph node is in the form of exprimentId_nodeId.
	# INPUTS
	#   * eid -- experiment id
	#   * node_id -- id of the node
	#****
	proc nodeCreate { eid node_id } {
		global isOSlinux isOSfreebsd

		addStateNode $node_id "node_creating"

		if { $isOSlinux } {
			set vlanfiltering "vlan_filtering [getNodeVlanFiltering $node_id]"

			set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
			pipesExec "ip netns exec $private_ns ip link add name $node_id type bridge $vlanfiltering" "hold"
			pipesExec "ip netns exec $private_ns ip link set $node_id up" "hold"
		}

		if { $isOSfreebsd } {
			# create an ng node and make it persistent in the same command
			# bridge demands hookname 'linkX'
			set ngcmds "mkpeer bridge link1 link1\n"
			set ngcmds "$ngcmds msg .link1 setpersistent\n"
			set ngcmds "$ngcmds name .link1 $node_id\n"

			if { [getNodeVlanFiltering $node_id] } {
				set ngcmds "$ngcmds mkpeer $node_id: vlan link0 unconfig\n"
				set ngcmds "$ngcmds name $node_id:link0 $node_id-vlan\n"
			}

			pipesExec "printf \"$ngcmds\" | jexec $eid ngctl -f -" "hold"
		}
	}

	proc nodeCreate_check { eid node_id } {
		global isOSlinux isOSfreebsd

		if { $isOSlinux } {
			set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
			set cmds "ip netns exec $private_ns ip link show dev $node_id | grep -q \"<.*UP.*>\""
		}

		if { $isOSfreebsd } {
			if { [getNodeVlanFiltering $node_id] } {
				set cmds "jexec $eid ngctl show $node_id-vlan:"
			} else {
				set cmds "jexec $eid ngctl show $node_id:"
			}
		}

		set cmds [getTimeoutCmd "ifacesconf_timeout" $cmds]

		set created [isOk $cmds]
		if { $created } {
			if { "node_creating" in [getStateNode $node_id] } {
				addStateNode $node_id "running"
			}
			removeStateNode $node_id "error"
		} else {
			addStateNode $node_id "error"
		}

		return $created
	}

	#****f* lanswitch.tcl/lanswitch.nodeIfacesConfigure
	# NAME
	#   lanswitch.nodeIfacesConfigure -- configure lanswitch node interfaces
	# SYNOPSIS
	#   lanswitch.nodeIfacesConfigure $eid $node_id $ifaces
	# FUNCTION
	#   Configure interfaces on a lanswitch. Set MAC, MTU, queue parameters, assign the IP
	#   addresses to the interfaces, etc. This procedure can be called if the node
	#   is instantiated.
	# INPUTS
	#   * eid -- experiment id
	#   * node_id -- node id
	#   * ifaces -- list of interface ids
	#****
	proc nodeIfacesConfigure { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		if { ! [getNodeVlanFiltering $node_id] } {
			return [invokeTypeProc "genericL2" "nodeIfacesConfigure" $eid $node_id $ifaces]
		}

		addStateNode $node_id "ifaces_configuring"

		foreach iface_id $ifaces {
			if { [isRunningNodeIface $node_id $iface_id] } {
				continue
			}
			set ifaces [removeFromList $ifaces $iface_id]

			if { ! [isErrorNodeIface $node_id $iface_id] } {
				continue
			}

			if { ! [isRunningNodeIface $node_id $iface_id] } {
				addStateNodeIface $node_id $iface_id "error"
				if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
					setStateErrorMsgNodeIface $node_id $iface_id "Interface $iface_id '[getIfcName $node_id $iface_id]' not created, skip configuration."
				}
			}
		}

		foreach iface_id $ifaces {
			set vlantype [getIfcVlanType $node_id $iface_id]
			set vlantag [getIfcVlanTag $node_id $iface_id]

			set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
			lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] iface_name public_iface -

			if { $isOSlinux } {
				if { $vlantype == "access"} {
					pipesExec "ip netns exec $private_ns bridge vlan del dev $iface_name vid 1" "hold"
					if { $vlantag != 1 } {
						pipesExec "ip netns exec $private_ns bridge vlan add dev $iface_name vid $vlantag pvid untagged" "hold"
					}

					continue
				}

				pipesExec "ip netns exec $private_ns bridge vlan add dev $iface_name vid 1 pvid untagged" "hold"

				foreach other_iface_id [ifcList $node_id] {
					set other_iface_vlantype [getIfcVlanType $node_id $other_iface_id]
					if { $other_iface_vlantype == "access" } {
						set id_vlantag [getIfcVlanTag $node_id $other_iface_id]
						pipesExec "ip netns exec $private_ns bridge vlan add dev $iface_name vid $id_vlantag tagged" "hold"
					}
				}

				continue
			}

			if { $isOSfreebsd } {
				set vlan_hook_name [lindex [split $public_iface "-"] end]

				setToRunning "${node_id}|${iface_id}_old_hook" $vlan_hook_name
				set total_hooks [getFromRunning "${node_id}|${vlan_hook_name}_hooks"]
				if { $total_hooks != "" } {
					# bridge already exists
					setToRunning "${node_id}|${vlan_hook_name}_hooks" [incr total_hooks]

					continue
				}

				set ng_vlan_id "$node_id-vlan"
				set ngcmds "mkpeer $ng_vlan_id: bridge $vlan_hook_name link0\n"
				append ngcmds "name $ng_vlan_id:$vlan_hook_name $public_iface\n"
				if { $vlantype != "trunk" } {
					append ngcmds "msg $ng_vlan_id: addfilter { vlan=$vlantag hook=\\\"$vlan_hook_name\\\" }\n"
				}

				pipesExec "printf \"$ngcmds\" | jexec $private_ns ngctl -f -" "hold"

				setToRunning "${node_id}|${vlan_hook_name}_hooks" 1

				continue
			}
		}
	}

	proc nodeIfacesConfigure_check { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		if { ! [getNodeVlanFiltering $node_id] } {
			return [invokeTypeProc "genericL2" "nodeIfacesConfigure_check" $eid $node_id $ifaces]
		}

		foreach iface_id $ifaces {
			if {
				! [isRunningNodeIface $node_id $iface_id] ||
				[isIfcLogical $node_id $iface_id]
			} {
				set ifaces [removeFromList $ifaces $iface_id]
			}
		}

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

		if { $isOSlinux } {
			set internal_cmds ""
			set vlantags {}
			set trunks {}
			foreach iface_id $ifaces {
				lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] iface_name - -
				set vlantag [getIfcVlanTag $node_id $iface_id]
				if { [getIfcVlanType $node_id $iface_id] == "trunk" } {
					lappend trunks $iface_name
					continue
				}

				if { $vlantag == 1 } {
					continue
				}

				lappend vlantags $vlantag
				append internal_cmds " bridge vlan show vid $vlantag | grep -qw $iface_name &&"
			}

			if { $internal_cmds == {} } {
				return true
			}

			foreach trunk_name $trunks {
				foreach vlantag $vlantags {
					append internal_cmds " bridge vlan show vid $vlantag | grep -qw $trunk_name &&"
				}
			}

			set cmds "\'$internal_cmds true'"
			set cmds "ip netns exec $private_ns sh -c $cmds"
		}

		if { $isOSfreebsd } {
			set internal_cmds ""
			foreach iface_id $ifaces {
				lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] - public_iface -
				append internal_cmds " ngctl show $public_iface: &&"
			}

			if { $internal_cmds == {} } {
				return true
			}

			set cmds "\'$internal_cmds true'"
			set cmds "jexec $private_ns sh -c $cmds"
		}

		set cmds [getTimeoutCmd "ifacesconf_timeout" $cmds]

		return [isOk $cmds]
	}

	################################################################################
	############################# TERMINATE PROCEDURES #############################
	################################################################################

	#****f* lanswitch.tcl/lanswitch.nodeIfacesUnconfigure
	# NAME
	#   lanswitch.nodeIfacesUnconfigure -- unconfigure lanswitch node interfaces
	# SYNOPSIS
	#   lanswitch.nodeIfacesUnconfigure $eid $node_id $ifaces
	# FUNCTION
	#   Unconfigure interfaces on a lanswitch to a default state. Set name to iface_id,
	#   flush IP addresses to the interfaces, etc. This procedure can be called if
	#   the node is instantiated.
	# INPUTS
	#   * eid -- experiment id
	#   * node_id -- node id
	#   * ifaces -- list of interface ids
	#****
	proc nodeIfacesUnconfigure { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		if { ! [getNodeVlanFiltering $node_id] } {
			return [invokeTypeProc "genericL2" "nodeIfacesUnconfigure" $eid $node_id $ifaces]
		}

		addStateNode $node_id "ifaces_unconfiguring"

		foreach iface_id $ifaces {
			if {
				! [isRunningNodeIface $node_id $iface_id] ||
				[isIfcLogical $node_id $iface_id]
			} {
				set ifaces [removeFromList $ifaces $iface_id]
			}
		}

		foreach iface_id $ifaces {
			set vlantype [getIfcVlanType $node_id $iface_id]
			set vlantag [getIfcVlanTag $node_id $iface_id]

			set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
			if { $isOSlinux } {
				if { $vlantag != 1 || $vlantype != "access"} {
					set iface_name [getIfcName $node_id $iface_id]
					pipesExec "ip netns exec $private_ns bridge vlan del dev $iface_name vid 1-4094" "hold"
					pipesExec "ip netns exec $private_ns bridge vlan add dev $iface_name vid 1 pvid untagged" "hold"
				}

				continue
			}

			if { $isOSfreebsd } {
				set vlan_hook_name [getFromRunning "${node_id}|${iface_id}_old_hook"]
				unsetRunning "${node_id}|${iface_id}_old_hook"

				set total_hooks [getFromRunning "${node_id}|${vlan_hook_name}_hooks"]
				if { $total_hooks > 1 } {
					# not the last link on bridge
					setToRunning "${node_id}|${vlan_hook_name}_hooks" [incr total_hooks -1]

					continue
				}

				set ngcmds "shutdown $node_id-vlan:$vlan_hook_name\n"
				pipesExec "printf \"$ngcmds\" | jexec $private_ns ngctl -f -" "hold"

				unsetRunning "${node_id}|${vlan_hook_name}_hooks"

				continue
			}
		}
	}

	# TODO
	proc nodeIfacesUnconfigure_check { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		if { ! [getNodeVlanFiltering $node_id] } {
			return [invokeTypeProc "genericL2" "nodeIfacesUnconfigure_check" $eid $node_id $ifaces]
		}

		foreach iface_id $ifaces {
			if {
				! [isRunningNodeIface $node_id $iface_id] ||
				[isIfcLogical $node_id $iface_id]
			} {
				set ifaces [removeFromList $ifaces $iface_id]
			}
		}

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

		if { $isOSlinux } {
			set internal_cmds ""
			set vlantags {}
			set trunks {}
			foreach iface_id $ifaces {
				lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] iface_name - -
				set vlantag [getIfcVlanTag $node_id $iface_id]
				if { [getIfcVlanType $node_id $iface_id] == "trunk" } {
					lappend trunks $iface_name
					continue
				}

				if { $vlantag == 1 } {
					continue
				}

				lappend vlantags $vlantag
				append internal_cmds " bridge vlan show vid $vlantag | grep -qw $iface_name ||"
			}

			if { $internal_cmds == "" } {
				return true
			}

			foreach trunk_name $trunks {
				foreach vlantag $vlantags {
					append internal_cmds " bridge vlan show vid $vlantag | grep -qw $trunk_name ||"
				}
			}

			set cmds "\'$internal_cmds false'"
			set cmds "ip netns exec $private_ns sh -c $cmds"
		}

		if { $isOSfreebsd } {
			set internal_cmds ""
			foreach iface_id $ifaces {
				lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] - public_iface ng_hook
				append internal_cmds " ngctl show $public_iface: ||"
			}

			if { $internal_cmds == "" } {
				return true
			}

			set cmds "\'$internal_cmds false'"
			set cmds "jexec $private_ns sh -c $cmds"
		}

		set cmds [getTimeoutCmd "ifacesconf_timeout" $cmds]

		return [isNotOk $cmds]
	}
}
