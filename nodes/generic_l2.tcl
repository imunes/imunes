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

namespace eval genericL2 {
	namespace export *

	################################################################################
	########################### CONFIGURATION PROCEDURES ###########################
	################################################################################

	proc netlayer {} {
		return LINK
	}

	proc virtlayer {} {
		return NATIVE
	}

	proc namingBase {} {
		return "l2"
	}

	proc confNewNode { node_id } {
		set node_type [getNodeType $node_id]
		set node_naming_base [invokeTypeProc $node_type "namingBase"]

		if { $node_type == "" || $node_naming_base == "" } {
			setNodeName $node_id $node_id
		} else {
			setNodeName $node_id [getNewNodeNameType $node_type $node_naming_base]
		}
	}

	proc confNewIfc { node_id iface_id } {
	}

	proc generateConfigIfaces { node_id ifaces } {
	}

	proc generateUnconfigIfaces { node_id ifaces } {
	}

	proc generateConfig { node_id } {
	}

	proc generateUnconfig { node_id } {
	}

	proc transformNode { node_id to_type } {
	}

	proc maxIfaces {} {
		return ""
	}

	proc ifacePrefix {} {
		return "e"
	}

	proc IPAddrRange {} {
	}

	proc collectIfcUppers { node_id iface_id } {
		return {}
	}

	proc collectIfcLowers { node_id iface_id } {
		return {}
	}

	proc collectIfcPeers { node_id iface_id } {
		set peers {}
		set my_prio [invokeNodeProc $node_id "getSubnetPriority" $node_id $iface_id]
		foreach other_iface_id [removeFromList [allIfcList $node_id] $iface_id] {
			lappend peers "$my_prio $node_id $other_iface_id 0"
		}

		set link_id [getIfcLink $node_id $iface_id]
		if { $link_id == "" } {
			return $peers
		}

		lassign [logicalPeerByIfc $node_id $iface_id] peer_id peer_iface_id peer_vlan_id
		set peer_prio [invokeNodeProc $peer_id "getSubnetPriority" $peer_id $peer_iface_id]

		set real_peer "$peer_prio $peer_id $peer_iface_id $peer_vlan_id"
		if { $real_peer ni $peers } {
			set peers [linsert $peers 0 $real_peer]
		}

		return $peers
	}

	proc collectIfcSubnet { node_id iface_id } {
	}

	proc getSubnetPriority { node_id iface_id } {
		return -1
	}

	proc bootcmd { node_id } {
	}

	proc shellcmds {} {
		return "csh bash sh tcsh"
	}

	proc getPrivateNs { eid node_id } {
		global isOSlinux isOSfreebsd

		if { $isOSlinux } {
			return $eid.$node_id
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
			# nothing
			return
		}
	}

	proc getHookData { node_id iface_id } {
		global isOSlinux isOSfreebsd

		# Linux - interface name of the node (inside node namespace)
		# FreeBSD - stolen interface name of the node (attached to netgraph node in EID jail)
		set private_elem [getIfcName $node_id $iface_id]

		if { $isOSlinux } {
			# public part of veth pair
			set public_elem "$node_id-$iface_id"
		}

		if { $isOSfreebsd } {
			# name of public netgraph peer
			set public_elem $node_id
		}

		# Linux - not used
		# FreeBSD - hook for connecting to netgraph node
		set hook_name "link[expr [string range $iface_id 3 end] + 1]"

		return [list $private_elem $public_elem $hook_name]
	}

	proc getExecCommand { eid node_id { flags "" } } {
		global isOSlinux isOSfreebsd

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		if { $isOSlinux } {
			return "ip netns exec $private_ns"
		}

		if { $isOSfreebsd } {
			return "jexec $eid"
		}
	}

	################################################################################
	############################ INSTANTIATE PROCEDURES ############################
	################################################################################

	proc prepareSystem {} {
		global isOSlinux isOSfreebsd

		if { $isOSlinux } {
			array set sysctls {
				net.bridge.bridge-nf-call-arptables	0
				net.bridge.bridge-nf-call-iptables	0
				net.bridge.bridge-nf-call-ip6tables	0
			}

			foreach {name val} [array get sysctls] {
				lappend cmd "sysctl $name=$val"
			}
			set cmds [join $cmd "; "]

			catch { rexec sh -c '$cmds' } err

			return
		}

		if { $isOSfreebsd } {
			catch { rexec kldload ng_hub }

			return
		}
	}

	proc checkNodePrerequisites { eid node_id } {
		global isOSlinux isOSfreebsd

		setStateErrorMsgNode $node_id ""
		if { $isOSlinux } {
			set private_ns_exists [invokeNodeProc $node_id "nodeNamespaceSetup_check" $eid $node_id]
			if { $private_ns_exists } {
				addStateNode $node_id "error"
				setStateErrorMsgNode $node_id "Namespace for node '$node_id' in experiment '$eid' already exists!"

				return false
			}
		}

		if { $isOSfreebsd } {
			set node_exists [invokeNodeProc $node_id "nodeCreate_check" $eid $node_id]
			if { $node_exists } {
				addStateNode $node_id "error"
				setStateErrorMsgNode $node_id "Netgraph node '$node_id' in experiment '$eid' already exists!"

				return false
			}
		}

		foreach iface_id [allIfcList $node_id] {
			setStateNodeIface $node_id $iface_id ""
		}

		removeStateNode $node_id "error"

		return true
	}

	proc checkIfacesPrerequisites { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		set stolen_ifaces {}
		foreach iface_id $ifaces {
			if { [isRunningNodeIface $node_id $iface_id] } {
				continue
			}

			removeStateNodeIface $node_id $iface_id "error"
			setStateErrorMsgNodeIface $node_id $iface_id ""
			if { [getIfcType $node_id $iface_id] == "stolen" } {
				lappend stolen_ifaces $iface_id
			}
		}

		set error_ifaces {}
		if { $stolen_ifaces != {} } {
			set host_ifaces [getHostIfcList]
			foreach iface_id $stolen_ifaces {
				set iface_name [getIfcName $node_id $iface_id]
				if { $iface_name ni $host_ifaces } {
					lappend error_ifaces $iface_id

					addStateNodeIface $node_id $iface_id "error"
					setStateErrorMsgNodeIface $node_id $iface_id "Host interface for $iface_id '[getIfcName $node_id $iface_id]' does not exist, skip stealing."
				}
			}
		}

		removeStateNode $node_id "pifaces_creating lifaces_creating"

		if { $error_ifaces != {} } {
			return false
		}

		return true
	}

	proc nodeNamespaceSetup { eid node_id } {
		global isOSlinux isOSfreebsd

		if { $isOSlinux } {
			addStateNode $node_id "ns_creating"

			set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
			pipesExec "ip netns add $private_ns" "hold"

			return
		}

		if { $isOSfreebsd } {
			# nothing
			return
		}
	}

	proc nodeNamespaceSetup_check { eid node_id } {
		global isOSlinux isOSfreebsd

		if { $isOSlinux } {
			set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
			set cmds "ip netns exec $private_ns true"

			set cmds [getTimeoutCmd "nodecreate_timeout" $cmds]

			set created [isOk $cmds]
			if { $created } {
				removeStateNode $node_id "error"
			} else {
				addStateNode $node_id "error"
			}

			return $created
		}

		if { $isOSfreebsd } {
			# shouldn't get here
			return false
		}
	}

	proc nodeCreate { eid node_id } {
		global isOSlinux isOSfreebsd

		addStateNode $node_id "node_creating"

		if { $isOSlinux } {
			set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

			pipesExec "ip -n $private_ns link add name $node_id type bridge ageing_time 0" "hold"
			pipesExec "ip -n $private_ns link set $node_id up" "hold"
		}

		if { $isOSfreebsd } {
			# create an ng node and make it persistent in the same command
			# hub demands hookname 'linkX'
			set ngcmds "mkpeer hub link1 link1\n"
			set ngcmds "$ngcmds msg .link1 setpersistent\n"
			set ngcmds "$ngcmds name .link1 $node_id\n"

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
			set cmds "jexec $eid ngctl show $node_id:"
		}

		set cmds [getTimeoutCmd "nodecreate_timeout" $cmds]

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

	proc nodeInitConfigure { eid node_id } {
	}

	proc nodeInitConfigure_check { eid node_id } {
		return true
	}

	proc nodePhysIfacesCreate { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		addStateNode $node_id "pifaces_creating"

		foreach iface_id $ifaces {
			addStateNodeIface $node_id $iface_id "creating"

			lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] iface_name public_iface ng_hook

			if { $isOSlinux } {
				set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
				set public_ns [invokeNodeProc $node_id "getPublicNs" $eid $node_id]

				if { [getIfcType $node_id $iface_id] == "stolen" } {
					# private hook is interface name in this case
					captureExtIfcByName $eid $iface_name $node_id
					setToRunning "${node_id}|${iface_id}_active_name" $iface_name
				} else {

					# Create a veth pair - private hook in node NS and public hook
					# in the experiment NS
					createNsVethPair \
						"$eid-$node_id-$iface_name" $iface_name $private_ns "" \
						"$eid-$public_iface" $public_iface $public_ns "config"
				}

				# bridge private hook with L2 node (node id is master)
				setNsIfcMaster $private_ns $iface_name $node_id "up"
			}

			if { $isOSfreebsd } {
				if { [getIfcType $node_id $iface_id] == "stolen" } {
					# private hook is interface name in this case
					captureExtIfcByName $eid $iface_name $node_id
					setToRunning "${node_id}|${iface_id}_active_name" $iface_name

					pipesExec "jexec $eid ngctl connect $public_iface: $iface_name: $ng_hook lower" "hold"
				} else {
					# skip testing for L2 interfaces as they are not really created on FreeBSD
					removeStateNodeIface $node_id $iface_id "creating"
					addStateNodeIface $node_id $iface_id "running"
				}
			}
		}
	}

	proc nodePhysIfacesDirectCreate { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		if { $isOSlinux } {
			foreach iface_id $ifaces {
				set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
				lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] iface_name - -

				lassign [logicalPeerByIfc $node_id $iface_id] peer_id peer_iface_id -

				if {
					"creating" in [getStateNodeIface $node_id $iface_id]
				} {
					set peer_public_ns [invokeNodeProc $peer_id "getPublicNs" $eid $peer_id]

					if { [getNodeType $peer_id] == "rj45" } {
						# non-VLAN rj45 interfaces are left in the default netns
						if { [getIfcVlanTag $peer_id $peer_iface_id] == "" || [getIfcVlanDev $peer_id $peer_iface_id] == "" } {
							global devfs_number

							set peer_public_ns "imunes_$devfs_number"
						}

						lassign [invokeNodeProc $peer_id "getHookData" $peer_id $peer_iface_id] peer_iface_name - -

						set full_virtual_ifc $eid-$node_id-$iface_id
						set cmds "ip -n $peer_public_ns link add link $peer_iface_name name $full_virtual_ifc netns $private_ns type"

						if { "wireless" ni [getStateNodeIface $peer_id $peer_iface_id] } {
							set cmds "$cmds macvlan mode passthru"
						} else {
							set cmds "$cmds ipvlan mode l2"
						}
						pipesExec "$cmds" "hold"

						set cmds "ip -n $peer_public_ns link set $peer_iface_name up"

						# assign the name of our interface to the created macvlan/ipvlan
						set cmds "$cmds ; ip -n $private_ns link set $full_virtual_ifc name $iface_name"
						set cmds "$cmds ; ip -n $private_ns link set $iface_name up"

						pipesExec "$cmds" "hold"
					} else {
						# skip creating our iface since it's already being created by peer,
						# just pull it in our netns, rename it and bridge it with L2 node
						pipesExec "ip -n $peer_public_ns link set $eid-$node_id-$iface_id netns $private_ns name $iface_name" "hold"
					}

					setNsIfcMaster $private_ns $iface_name $node_id "up"

					continue
				}

				if { [getNodeType $peer_id] == "rj45" } {
					# rj45 will call us
					continue
				}

				addStateNode $node_id "pifaces_creating"
				addStateNodeIface $node_id $iface_id "creating"

				set public_ns [invokeNodeProc $node_id "getPublicNs" $eid $node_id]

				set peer_running [isRunningNode $peer_id]
				if { ! [isRunningNodeIface $peer_id $peer_iface_id] } {
					if { $peer_running } {
						addStateNode $peer_id "pifaces_creating"
						addStateNodeIface $peer_id $peer_iface_id "creating"

						# Create a veth pair - private hook in node NS and other hook
						# in the other node NS
						createNsVethPair \
							"$eid-$node_id-$iface_id" $iface_name $private_ns "" \
							"$eid-$peer_id-$peer_iface_id" "$eid-$peer_id-$peer_iface_id" $public_ns ""
					} else {
						createNsVethPair \
							"$eid-$node_id-$iface_id" $iface_name $private_ns "" \
							"$eid-$node_id-$iface_id" "$node_id-$iface_id" $public_ns ""
					}
				}

				# bridge our private iface with L2 node
				setNsIfcMaster $private_ns $iface_name $node_id "up"

				# invoke other node
				if { $peer_running } {
					invokeNodeProc $peer_id "nodePhysIfacesDirectCreate" $eid $peer_id $peer_iface_id
				}
			}
		}

		if { $isOSfreebsd } {
			# same as regular interfaces
			return [invokeNodeProc $node_id "nodePhysIfacesCreate" $eid $node_id $ifaces]
		}
	}

	proc nodeLogIfacesCreate { eid node_id ifaces } {
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
			# get list of interface names
			set cmds "ip -br l | sed \"s/\[@\[:space:]].*//\""
			set cmds "ip netns exec $private_ns sh -c '$cmds'"
		}

		if { $isOSfreebsd } {
			# get list of interface names
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

	proc nodeIfacesConfigure { eid node_id ifaces } {
	}

	proc nodeIfacesConfigure_check { eid node_id ifaces } {
		return true
	}

	proc attachToLink { eid node_id iface_id link_id direct } {
		global isOSlinux isOSfreebsd

		if { $isOSlinux } {
			if { $direct } {
				return
			}

			lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] - public_iface -
			setNsIfcMaster $eid $public_iface $link_id "up"

			return
		}

		if { $isOSfreebsd } {
			# nothing to do, createLinkBetween does everything
			return
		}
	}

	proc nodeConfigure { eid node_id } {
	}

	proc nodeConfigure_check { eid node_id } {
		return true
	}

	################################################################################
	############################# TERMINATE PROCEDURES #############################
	################################################################################

	proc nodeUnconfigure { eid node_id } {
	}

	proc nodeUnconfigure_check { eid node_id } {
		return true
	}

	proc nodeShutdown { eid node_id } {
	}

	proc nodeShutdown_check { eid node_id } {
		return true
	}

	proc detachFromLink { eid node_id iface_id link_id { direct "" } } {
		global isOSlinux isOSfreebsd

		if { $isOSlinux } {
			if { $direct } {
				# actually destroying phys interfaces

				return
			}

			lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] - public_iface -
			pipesExec "ip -n $eid link set $public_iface nomaster down"

			return
		}

		if { $isOSfreebsd } {
			# nothing to do, destroyLinkBetween does everything
			return
		}
	}

	proc nodeIfacesUnconfigure { eid node_id ifaces } {
	}

	proc nodeIfacesUnconfigure_check { eid node_id ifaces } {
		return true
	}

	proc nodeLogIfacesDestroy { eid node_id ifaces } {
		foreach iface_id $ifaces {
			removeStateNodeIface $node_id $iface_id "running"
		}
	}

	proc nodePhysIfacesDestroy { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		addStateNode $node_id "pifaces_destroying"

		foreach iface_id $ifaces {
			addStateNodeIface $node_id $iface_id "destroying"

			lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] iface_name public_iface -
			if { [getIfcType $node_id $iface_id] == "stolen" } {
				releaseExtIfcByName $eid $iface_name $node_id
				unsetRunning "${node_id}|${iface_id}_active_name"

				continue
			}

			if { $isOSlinux } {
				set public_ns [invokeNodeProc $node_id "getPublicNs" $eid $node_id]
				pipesExec "ip -n $public_ns link del $public_iface" "hold"
			}

			if { $isOSfreebsd } {
				# skip testing for L2 interfaces as they are not really created on FreeBSD
				removeStateNodeIface $node_id $iface_id "destroying running"
			}
		}
	}

	proc nodePhysIfacesDirectDestroy { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		if { $isOSlinux } {
			foreach iface_id $ifaces {
				set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
				lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] iface_name - -

				lassign [logicalPeerByIfc $node_id $iface_id] peer_id peer_iface_id -

				if {
					"destroying" in [getStateNodeIface $node_id $iface_id]
				} {
					if { [getNodeType $peer_id] == "rj45" } {
						pipesExec "ip -n $private_ns link del $iface_name" "hold"

						continue
					}

					continue
				}

				if { [getNodeType $peer_id] == "rj45" } {
					# rj45 will call us
					continue
				}

				addStateNode $node_id "pifaces_destroying"
				addStateNode $peer_id "pifaces_destroying"
				addStateNodeIface $node_id $iface_id "destroying"
				addStateNodeIface $peer_id $peer_iface_id "destroying"

				pipesExec "ip -n $private_ns link del $iface_name" "hold"

				invokeNodeProc $peer_id "nodePhysIfacesDirectDestroy" $eid $peer_id $peer_iface_id
			}
		}

		if { $isOSfreebsd } {
			# same as regular interfaces
			return [invokeNodeProc $node_id "nodePhysIfacesDestroy" $eid $node_id $ifaces]
		}
	}

	proc nodeIfacesDestroy_check { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		foreach iface_id $ifaces {
			if {
				! [isRunningNodeIface $node_id $iface_id] ||
				"destroying" ni [getStateNodeIface $node_id $iface_id]
			} {
				set ifaces [removeFromList $ifaces $iface_id]
				removeStateNodeIface $node_id $iface_id "error destroying running"
			}
		}

		if { $ifaces == {} } {
			return true
		}

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

		if { $isOSlinux } {
			# get list of interface names
			set cmds "ip -br l | sed \"s/\[@\[:space:]].*//\""
			set cmds "ip netns exec $private_ns sh -c '$cmds'"
		}

		if { $isOSfreebsd } {
			# get list of interface names
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
				set ifaces_destroyed $ifaces
			} else {
				set ifaces_destroyed {}
				foreach iface_id $ifaces {
					lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] iface_name - -
					if {
						! [isRunningNodeIface $node_id $iface_id] ||
						("destroying" in [getStateNodeIface $node_id $iface_id] &&
						$iface_name ni $ifaces_all)
					} {
						lappend ifaces_destroyed $iface_id
					} else {
						addStateNodeIface $node_id $iface_id "error"
					}
				}
			}

			foreach iface_id $ifaces_destroyed {
				removeStateNodeIface $node_id $iface_id "error destroying running"
			}

			if { [llength $ifaces] == [llength $ifaces_destroyed] } {
				return true
			}
		} on error {} {
			return false
		}

		return false
	}

	proc nodeDestroy { eid node_id } {
		global isOSlinux isOSfreebsd

		if { ! [isRunningNode $node_id] } {
			return
		}

		addStateNode $node_id "node_destroying"

		if { $isOSlinux } {
			set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

			# delete our bridge and namespace
			pipesExec "ip -n $private_ns link delete $node_id" "hold"
			pipesExec "ip netns del $private_ns" "hold"
		}

		if { $isOSfreebsd } {
			pipesExec "jexec $eid ngctl msg $node_id: shutdown" "hold"
		}
	}

	proc nodeDestroy_check { eid node_id } {
		global isOSlinux isOSfreebsd

		if { "node_destroying" ni [getStateNode $node_id] } {
			return false
		}

		if { $isOSlinux } {
			set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
			set cmds "ip netns exec $private_ns true"
		}

		if { $isOSfreebsd } {
			set cmds "jexec $eid ngctl show $node_id:"
		}

		set cmds [getTimeoutCmd "nodecreate_timeout" $cmds]

		set destroyed [isNotOk $cmds]

		if { $destroyed } {
			removeStateNode $node_id "error running"
		} else {
			addStateNode $node_id "error"
		}

		return $destroyed
	}

	proc nodeDestroyFS { eid node_id } {
	}

	proc nodeDestroyFS_check { eid node_id } {
		return true
	}
}
