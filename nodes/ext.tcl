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

# $Id: ext.tcl 63 2013-10-03 12:17:50Z valter $


#****h* imunes/ext.tcl
# NAME
#  ext.tcl -- defines ext specific procedures
# FUNCTION
#  This module is used to define all the ext specific procedures.
# NOTES
#  Procedures in this module start with the keyword ext and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE ext
registerModule $MODULE

namespace eval $MODULE {
	# Define all node-specific procedures. All non-defined procedures will call
	# genericL3.* procedures from nodes/generic_l3.tcl
	namespace import ::genericL3::*
	namespace export *

	################################################################################
	########################### CONFIGURATION PROCEDURES ###########################
	################################################################################

	#****f* ext.tcl/ext.virtlayer
	# NAME
	#   ext.virtlayer -- virtual layer
	# SYNOPSIS
	#   set layer [ext.virtlayer]
	# FUNCTION
	#   Returns the layer on which the ext is instantiated i.e. returns NATIVE.
	# RESULT
	#   * layer -- set to NATIVE
	#****
	proc virtlayer {} {
		return NATIVE
	}

	proc namingBase {} {
		return "ext"
	}

	#****f* ext.tcl/ext.confNewNode
	# NAME
	#   ext.confNewNode -- configure new node
	# SYNOPSIS
	#   ext.confNewNode $node_id
	# FUNCTION
	#   Configures new node with the specified id.
	# INPUTS
	#   * node_id -- node id
	#****
	proc confNewNode { node_id } {
		invokeTypeProc "genericL2" "confNewNode" $node_id

		setNodeNATIface $node_id "UNASSIGNED"
	}

	#****f* ext.tcl/ext.confNewIfc
	# NAME
	#   ext.confNewIfc -- configure new interface
	# SYNOPSIS
	#   ext.confNewIfc $node_id $iface_id
	# FUNCTION
	#   Configures new interface for the specified node.
	# INPUTS
	#   * node_id -- node id
	#   * iface_id -- interface name
	#****
	proc confNewIfc { node_id iface_id } {
		global mac_byte4 mac_byte5

		autoIPv4addr $node_id $iface_id
		autoIPv6addr $node_id $iface_id

		set bkp_mac_byte4 $mac_byte4
		set bkp_mac_byte5 $mac_byte5
		randomizeMACbytes
		autoMACaddr $node_id $iface_id
		set mac_byte4 $bkp_mac_byte4
		set mac_byte5 $bkp_mac_byte5
	}

	proc generateConfigIfaces { node_id ifaces } {
	}

	proc generateUnconfigIfaces { node_id ifaces } {
	}

	proc generateConfig { node_id } {
	}

	proc generateUnconfig { node_id } {
	}

	#****f* ext.tcl/ext.ifacePrefix
	# NAME
	#   ext.ifacePrefix -- interface name
	# SYNOPSIS
	#   ext.ifacePrefix
	# FUNCTION
	#   Returns ext interface name prefix.
	# RESULT
	#   * name -- name prefix string
	#****
	proc ifacePrefix {} {
		return "ext"
	}

	#****f* ext.tcl/ext.maxIfaces
	# NAME
	#   ext.maxIfaces -- maximum number of links
	# SYNOPSIS
	#   ext.maxIfaces
	# FUNCTION
	#   Returns ext node maximum number of links.
	# RESULT
	#   * maximum number of links.
	#****
	proc maxIfaces {} {
		return 1
	}

	proc getPrivateNs { eid node_id } {
		global isOSlinux isOSfreebsd

		if { $isOSlinux } {
			global devfs_number

			return "imunes_$devfs_number"
		}

		if { $isOSfreebsd } {
			# nothing
			return
		}
	}

	proc getPublicNs { eid node_id } {
		global isOSlinux isOSfreebsd

		if { $isOSlinux } {
			return $eid
		}

		if { $isOSfreebsd } {
			return $eid
		}
	}

	proc getHookData { node_id iface_id } {
		global isOSlinux isOSfreebsd

		# Linux - interface name of the node (inside default namespace)
		# FreeBSD - interface name of the node (inside default namespace)
		set private_elem "[getFromRunning "eid"]-$node_id"

		# Linux - public part of veth pair (inside EID namespace)
		# FreeBSD - name of public netgraph peer (inside EID jail)
		set public_elem "$node_id-$iface_id"

		# Linux - not used
		# FreeBSD - hook for connecting to netgraph node
		set hook_name "ether"

		return [list $private_elem $public_elem $hook_name]
	}

	proc getExecCommand { eid node_id { flags "" } } {
		return ""
	}

	################################################################################
	############################ INSTANTIATE PROCEDURES ############################
	################################################################################

	#****f* ext.tcl/ext.prepareSystem
	# NAME
	#   ext.prepareSystem -- prepare system
	# SYNOPSIS
	#   ext.prepareSystem
	# FUNCTION
	#   Does nothing
	#****
	proc prepareSystem {} {
		global isOSlinux isOSfreebsd

		if { $isOSlinux } {
			catch { rexec sysctl net.ipv4.conf.all.forwarding=1 }
		}

		if { $isOSfreebsd } {
			catch { rexec kldload ipfilter }
			catch { rexec sysctl net.inet.ip.forwarding=1 }
		}
	}

	proc checkNodePrerequisites { eid node_id } {
		setStateErrorMsgNode $node_id ""

		foreach iface_id [allIfcList $node_id] {
			if { [isRunningNodeIface $node_id $iface_id] } {
				continue
			}

			addStateNodeIface $node_id $iface_id "creating"
			set ext_ifc_exists [invokeNodeProc $node_id "nodePhysIfacesCreate_check" $eid $node_id $iface_id]
			removeStateNodeIface $node_id $iface_id "creating running"
			if { $ext_ifc_exists } {
				addStateNode $node_id "error"
				setStateErrorMsgNode $node_id "Interface '$eid-$node_id' already exists in global namespace!"

				return false
			}

			setStateNodeIface $node_id $iface_id ""
		}

		removeStateNode $node_id "error"

		return true
	}

	proc checkIfacesPrerequisites { eid node_id ifaces } {
		# TODO
		set error_ifaces {}
		foreach iface_id $ifaces {
			if { [isRunningNodeIface $node_id $iface_id] } {
				continue
			}

			removeStateNodeIface $node_id $iface_id "error"
			setStateErrorMsgNodeIface $node_id $iface_id ""

			addStateNodeIface $node_id $iface_id "creating"
			set ext_ifc_exists [invokeNodeProc $node_id "nodePhysIfacesCreate_check" $eid $node_id $iface_id]
			removeStateNodeIface $node_id $iface_id "creating running"
			if { $ext_ifc_exists } {
				lappend error_ifaces $iface_id

				addStateNode $node_id "error"
				setStateErrorMsgNode $node_id "Interface '$eid-$node_id' already exists in global namespace!"
			}

			setStateNodeIface $node_id $iface_id ""
		}

		removeStateNode $node_id "pifaces_creating lifaces_creating"

		if { $error_ifaces != {} } {
			return false
		}

		return true
	}

	#****f* ext.tcl/ext.nodeCreate
	# NAME
	#   ext.nodeCreate -- instantiate
	# SYNOPSIS
	#   ext.nodeCreate $eid $node_id
	# FUNCTION
	#   Creates an ext node.
	#   Does nothing, as it is not created per se.
	# INPUTS
	#   * eid -- experiment id
	#   * node_id -- node id
	#****
	proc nodeCreate { eid node_id } {
		if { ! [isErrorNode $node_id] } {
			setStateNode $node_id "node_creating"
		}
	}

	proc nodeCreate_check { eid node_id } {
		setStateNode $node_id "running"

		return true
	}

	#****f* ext.tcl/ext.nodeNamespaceSetup
	# NAME
	#   ext.nodeNamespaceSetup -- ext node nodeNamespaceSetup
	# SYNOPSIS
	#   ext.nodeNamespaceSetup $eid $node_id
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

	#****f* ext.tcl/ext.nodeInitConfigure
	# NAME
	#   ext.nodeInitConfigure -- ext node nodeInitConfigure
	# SYNOPSIS
	#   ext.nodeInitConfigure $eid $node_id
	# FUNCTION
	#   Runs initial L3 configuration, such as creating logical interfaces and
	#   configuring sysctls.
	# INPUTS
	#   * eid -- experiment id
	#   * node_id -- node id
	#****
	proc nodeInitConfigure { eid node_id } {
	}

	proc nodeInitConfigure_check { eid node_id } {
		return true
	}

	proc nodePhysIfacesCreate { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		addStateNode $node_id "pifaces_creating"

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		set public_ns [invokeNodeProc $node_id "getPublicNs" $eid $node_id]
		foreach iface_id $ifaces {
			addStateNodeIface $node_id $iface_id "creating"

			lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] iface_name public_iface -

			if { $isOSlinux } {
				# Create a veth pair - private iface in global NS and public iface
				# in the experiment NS
				createNsVethPair \
					$iface_name $iface_name $private_ns "" \
					"$eid-$public_iface" $public_iface $public_ns "config"
			}

			if { $isOSfreebsd } {
				# save newly created ngnodeX into a shell variable ifid and
				# rename the ng node to $public_iface (unique to this experiment)
				set cmds "ifid=\$(printf \"mkpeer . eiface $public_iface ether \n"
				set cmds "$cmds show .:$public_iface\" | jexec $eid ngctl -f - | head -n1 | cut -d' ' -f4)"
				set cmds "$cmds; jexec $eid ngctl name \$ifid: $public_iface"
				set cmds "$cmds; jexec $eid ifconfig \$ifid name $iface_name"

				pipesExec $cmds "hold"
				pipesExec "ifconfig $iface_name -vnet $eid" "hold"

				set ether [getIfcMACaddr $node_id $iface_id]
				if { $ether == "" } {
					autoMACaddr $node_id $iface_id
				}

				set ether [getIfcMACaddr $node_id $iface_id]
				pipesExec "ifconfig $iface_name link $ether" "hold"
			}
		}
	}

	proc nodeLogIfacesCreate { eid node_id ifaces } {
	}

	#****f* ext.tcl/ext.nodeIfacesConfigure
	# NAME
	#   ext.nodeIfacesConfigure -- configure ext node interfaces
	# SYNOPSIS
	#   ext.nodeIfacesConfigure $eid $node_id $ifaces
	# FUNCTION
	#   Configure interfaces on a ext. Set MAC, MTU, queue parameters, assign the IP
	#   addresses to the interfaces, etc. This procedure can be called if the node
	#   is instantiated.
	# INPUTS
	#   * eid -- experiment id
	#   * node_id -- node id
	#   * ifaces -- list of interface ids
	#****
	proc nodeIfacesConfigure { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		set cmds ""

		foreach iface_id $ifaces {
			lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] iface_name - -

			set ether [getIfcMACaddr $node_id $iface_id]
			if { $ether == "" } {
				set ether [autoMACaddr $node_id $iface_id]
			}

			set addrs4 [getIfcIPv4addrs $node_id $iface_id]
			setToRunning "${node_id}|${iface_id}_old_ipv4_addrs" $addrs4

			set addrs6 [getIfcIPv6addrs $node_id $iface_id]
			setToRunning "${node_id}|${iface_id}_old_ipv6_addrs" $addrs6

			if { $isOSlinux } {
				append cmds "ip l set $iface_name address $ether; "

				foreach ipv4 $addrs4 {
					append cmds "ip a add $ipv4 dev $iface_name; "
				}

				foreach ipv6 $addrs6 {
					append cmds "ip a add $ipv6 dev $iface_name; "
				}

				append cmds "ip l set $iface_name up; "
			}

			if { $isOSfreebsd } {
				append cmds "ifconfig $iface_name link $ether; "

				foreach ipv4 $addrs4 {
					append cmds "ifconfig $iface_name $ipv4; "
				}

				foreach ipv6 $addrs6 {
					append cmds "ifconfig $iface_name inet6 $ipv6; "
				}

				append cmds "ifconfig $iface_name up; "
			}
		}

		if { $cmds == "" } {
			return
		}

		addStateNode $node_id "ifaces_configuring"

		pipesExec "$cmds" "hold"
	}

	proc nodeIfacesConfigure_check { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		foreach iface_id $ifaces {
			if { ! [isRunningNodeIface $node_id $iface_id] } {
				set ifaces [removeFromList $ifaces $iface_id]
			}
		}

		if { $ifaces == {} } {
			return true
		}

		if { $isOSlinux } {
			# get list of interface names that are up
			set cmds "ip -br l | grep \"<.*UP.*>\" | sed \"s/\[@\[:space:]].*//\""
		}

		if { $isOSfreebsd } {
			# get list of interface names that are up
			set cmds "ifconfig -lu"
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
					[isRunningNodeIface $node_id $iface_id] &&
					$iface_name in $ifaces_all
				} {
					lappend ifaces_created $iface_id

					removeStateNodeIface $node_id $iface_id "error"
					setStateErrorMsgNodeIface $node_id $iface_id ""
				} else {
					addStateNodeIface $node_id $iface_id "error"
					if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
						setStateErrorMsgNodeIface $node_id $iface_id "Interface '$iface_id' ($iface_name) not configured."
					}
				}
			}

			if { [llength $ifaces] == [llength $ifaces_created] } {
				removeStateNode $node_id "ifaces_configuring"

				return true
			}

			return false
		} on error {} {
			return false
		}

		return false
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

	#****f* ext.tcl/ext.nodeConfigure
	# NAME
	#   ext.nodeConfigure -- start
	# SYNOPSIS
	#   ext.nodeConfigure $eid $node_id
	# FUNCTION
	#   Starts a new ext. The node can be started if it is instantiated.
	#   Simulates the booting proces of a ext, by calling l3node.nodeConfigure procedure.
	#   Sets up the NAT for the given interface if assigned.
	# INPUTS
	#   * eid -- experiment id
	#   * node_id -- node id
	#****
	proc nodeConfigure { eid node_id } {
		global isOSlinux isOSfreebsd

		set ifaces [ifcList $node_id]
		if { $ifaces == {} } {
			return
		}

		set host_out_iface [getNodeNATIface $node_id]
		if { $host_out_iface == "UNASSIGNED" } {
			return
		}

		foreach iface_id $ifaces {
			set out_ip [lindex [getIfcIPv4addrs $node_id $iface_id] 0]
			if { $out_ip == "" } {
				return
			}

			set prefix_len [lindex [split $out_ip "/"] 1]
			set subnet "[ip::prefix $out_ip]/$prefix_len"

			set cmds ""
			if { $isOSlinux } {
				append cmds "iptables -t nat -A POSTROUTING -o $host_out_iface -j MASQUERADE -s $subnet; "
				append cmds "iptables -A FORWARD -i $eid-$node_id -o $host_out_iface -j ACCEPT; "
				append cmds "iptables -A FORWARD -o $eid-$node_id -j ACCEPT; "
			}

			if { $isOSfreebsd } {
				append cmds "echo 'map $host_out_iface $subnet -> 0/32' | ipnat -f -; "
			}

			pipesExec "$cmds" "hold"
		}

		addStateNode $node_id "node_configuring"
	}

	proc nodeConfigure_check { eid node_id } {
		global isOSlinux isOSfreebsd

		set host_out_iface [getNodeNATIface $node_id]

		# only one interface for now
		set cmds ""
		foreach iface_id [ifcList $node_id] {
			set out_ip [lindex [getIfcIPv4addrs $node_id $iface_id] 0]
			if { $out_ip == "" } {
				return
			}

			set prefix_len [lindex [split $out_ip "/"] 1]
			set subnet "[ip::prefix $out_ip]/$prefix_len"

			if { $isOSlinux } {
				set cmds "iptables -C FORWARD -o $eid-$node_id -j ACCEPT; "
			}

			if { $isOSfreebsd } {
				set cmds "ipnat -l | grep 'map $host_out_iface $subnet -> 0/32'; "
			}
		}

		set cmds [getTimeoutCmd "nodeconf_timeout" $cmds]

		set node_configured [isOk $cmds]
		if { $node_configured } {
			removeStateNode $node_id "error"
		} else {
			addStateNode $node_id "error"
		}

		return $node_configured
	}

	################################################################################
	############################# TERMINATE PROCEDURES #############################
	################################################################################

	proc nodeUnconfigure { eid node_id } {
		global isOSlinux isOSfreebsd

		set ifaces [ifcList $node_id]
		if { $ifaces == {} } {
			return
		}

		set host_out_iface [getNodeNATIface $node_id]
		if { $host_out_iface == "UNASSIGNED" } {
			return
		}

		foreach iface_id $ifaces {
			set out_ip [lindex [getIfcIPv4addrs $node_id $iface_id] 0]
			if { $out_ip == "" } {
				return
			}

			set prefix_len [lindex [split $out_ip "/"] 1]
			set subnet "[ip::prefix $out_ip]/$prefix_len"

			set cmds ""
			if { $isOSlinux } {
				append cmds "iptables -t nat -D POSTROUTING -o $host_out_iface -j MASQUERADE -s $subnet; "
				append cmds "iptables -D FORWARD -i $eid-$node_id -o $host_out_iface -j ACCEPT; "
				append cmds "iptables -D FORWARD -o $eid-$node_id -j ACCEPT; "
			}

			if { $isOSfreebsd } {
				append cmds "echo 'map $host_out_iface $subnet -> 0/32' | ipnat -f - -pr; "
			}

			pipesExec "$cmds" "hold"
		}

		addStateNode $node_id "node_unconfiguring"
	}

	proc nodeUnconfigure_check { eid node_id } {
		global isOSlinux isOSfreebsd

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

		set host_out_iface [getNodeNATIface $node_id]

		# only one interface for now
		set cmds ""
		foreach iface_id [ifcList $node_id] {
			set out_ip [lindex [getIfcIPv4addrs $node_id $iface_id] 0]
			if { $out_ip == "" } {
				return
			}

			set prefix_len [lindex [split $out_ip "/"] 1]
			set subnet "[ip::prefix $out_ip]/$prefix_len"

			if { $isOSlinux } {
				set cmds "iptables -C FORWARD -o $eid-$node_id -j ACCEPT; "
			}

			if { $isOSfreebsd } {
				set cmds "ipnat -l | grep 'map $host_out_iface $subnet -> 0/32'; "
			}
		}

		set cmds [getTimeoutCmd "nodeconf_timeout" $cmds]

		set node_configured [isNotOk $cmds]
		if { $node_configured } {
			removeStateNode $node_id "error"
		} else {
			addStateNode $node_id "error"
		}

		return $node_configured
	}

	#****f* ext.tcl/ext.nodeShutdown
	# NAME
	#   ext.nodeShutdown -- shutdown
	# SYNOPSIS
	#   ext.nodeShutdown $eid $node_id
	# FUNCTION
	#   Shutdowns an ext node.
	#   It kills all external packet sniffers and sets the interface down.
	# INPUTS
	#   * eid -- experiment id
	#   * node_id -- node id
	#****
	proc nodeShutdown { eid node_id } {
		global isOSlinux isOSfreebsd
		global ttyrcmd

		foreach iface_id [ifcList $node_id] {
			if { ! [isRunningNodeIface $node_id $iface_id] } {
				continue
			}

			if { $isOSlinux } {
				pipesExec "ip link set $eid-$node_id up" "hold"
			}

			if { $isOSfreebsd } {
				pipesExec "ifconfig $eid-$node_id up" "hold"
			}

			killExtProcess "wireshark.*[getNodeName $node_id].*\\($eid\\)"
			killExtProcess "[getActiveOption "terminal_command"] -T Capturing $eid-$node_id -e $ttyrcmd tcpdump -leni $eid-$node_id"

			if { $isOSlinux } {
				pipesExec "ip link set $eid-$node_id down" "hold"
			}

			if { $isOSfreebsd } {
				pipesExec "ifconfig $eid-$node_id down" "hold"
			}
		}

		addStateNode $node_id "node_shutting"
	}

	proc nodeShutdown_check { eid node_id } {
		global isOSlinux isOSfreebsd

		set ifaces [ifcList $node_id]
		foreach iface_id $ifaces {
			if { ! [isRunningNodeIface $node_id $iface_id] } {
				set ifaces [removeFromList $ifaces $iface_id]
			}
		}

		if { $ifaces == {} } {
			return true
		}

		if { $isOSlinux } {
			# get list of interface names that are down
			set cmds "ip -br l | grep \"<.*UP.*>\" | sed \"s/\[@\[:space:]].*//\""
		}

		if { $isOSfreebsd } {
			# get list of interface names that are down
			set cmds "ifconfig -lu"
		}

		set cmds [getTimeoutCmd "ifacesconf_timeout" $cmds]

		try {
			rexec $cmds
		} on ok ifaces_all {
			if { [string trim $ifaces_all "\n "] == "" } {
				set ifaces_unconfigured $ifaces
			} else {
				set ifaces_unconfigured {}
				foreach iface_id $ifaces {
					if {
						[isRunningNodeIface $node_id $iface_id] &&
						"$eid-$node_id" ni $ifaces_all
					} {
						lappend ifaces_unconfigured $iface_id
					} else {
						addStateNodeIface $node_id $iface_id "error"
					}
				}
			}

			foreach iface_id $ifaces_unconfigured {
				removeStateNodeIface $node_id $iface_id "error"
			}

			if { [llength $ifaces] == [llength $ifaces_unconfigured] } {
				removeStateNode $node_id "node_shutting"

				return true
			}
		} on error {} {
			return false
		}

		return false
	}

	proc detachFromLink { eid node_id iface_id link_id { direct "" } } {
		global isOSlinux isOSfreebsd

		if { $isOSlinux } {
			if { $direct } {
				# link already destroyed, except in some cases

				return
			}

			lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] - public_iface -
			pipesExec "ip -n $eid link set $public_iface down"

			return
		}

		if { $isOSfreebsd } {
			# nothing to do, destroyLinkBetween does everything
			return
		}
	}

	#****f* ext.tcl/ext.nodeIfacesUnconfigure
	# NAME
	#   ext.nodeIfacesUnconfigure -- unconfigure ext node interfaces
	# SYNOPSIS
	#   ext.nodeIfacesUnconfigure $eid $node_id $ifaces
	# FUNCTION
	#   Unconfigure interfaces on an ext to a default state. Set name to iface_id,
	#   flush IP addresses to the interfaces, etc. This procedure can be called if
	#   the node is instantiated.
	# INPUTS
	#   * eid -- experiment id
	#   * node_id -- node id
	#   * ifaces -- list of interface ids
	#****
	proc nodeIfacesUnconfigure { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		set cmds ""
		set iface_id [lindex $ifaces 0]
		if { $iface_id == "" } {
			return
		}

		set outifc "$eid-$node_id"

		set addrs4 [getFromRunning "${node_id}|${iface_id}_old_ipv4_addrs"]
		set addrs6 [getFromRunning "${node_id}|${iface_id}_old_ipv6_addrs"]

		if { $isOSlinux } {
			foreach ipv4 $addrs4 {
				append cmds "ip a del $ipv4 dev $outifc; "
			}

			foreach ipv6 $addrs6 {
				append cmds "ip a del $ipv6 dev $outifc; "
			}
		}

		if { $isOSfreebsd } {
			foreach ipv4 $addrs4 {
				append cmds "ifconfig $outifc inet $ipv4 -alias; "
			}

			foreach ipv6 $addrs6 {
				append cmds "ifconfig $outifc inet $ipv6 -alias; "
			}
		}

		if { $cmds == "" } {
			return
		}

		addStateNode $node_id "ifaces_unconfiguring"

		pipesExec "echo $$ > /tmp/$eid-$node_id-IFACES_UNCONFIG ; $cmds" "hold"
	}

	proc nodeIfacesUnconfigure_check { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		set startup_fname "/tmp/$eid-$node_id-IFACES_UNCONFIG"
		set cmds "test -n \"\$(cat $startup_fname 2>/dev/null)\" && ! kill -0 \$(cat $startup_fname) 2>/dev/null && rm -f $startup_fname"

		set cmds [getTimeoutCmd "ifacesconf_timeout" $cmds]

		set ifaces_unconfigured [isOk $cmds]
		if { $ifaces_unconfigured } {
			removeStateNode $node_id "error"
		} else {
			addStateNode $node_id "error"
		}

		return $ifaces_unconfigured
	}

	proc nodePhysIfacesDestroy { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		addStateNode $node_id "pifaces_destroying"

		set public_ns [invokeNodeProc $node_id "getPublicNs" $eid $node_id]

		foreach iface_id $ifaces {
			addStateNodeIface $node_id $iface_id "destroying"

			if { $isOSlinux } {
				pipesExec "ip -n $public_ns link del $node_id-$iface_id" "hold"
			}

			if { $isOSfreebsd } {
				pipesExec "jexec $public_ns ngctl msg $node_id-$iface_id: shutdown" "hold"
			}
		}
	}

	proc isNodeError { eid node_id } {
		return false
	}

	proc isNodeErrorIfaces { eid node_id } {
		return false
	}

	#****f* ext.tcl/ext.nodeDestroy
	# NAME
	#   ext.nodeDestroy -- destroy
	# SYNOPSIS
	#   ext.nodeDestroy $eid $node_id
	# FUNCTION
	#   Destroys an ext node.
	#   Does nothing, as it is not created.
	# INPUTS
	#   * eid -- experiment id
	#   * node_id -- node id
	#****
	proc nodeDestroy { eid node_id } {
		addStateNode $node_id "node_destroying"
	}

	proc nodeDestroy_check { eid node_id } {
		if { "node_destroying" ni [getStateNode $node_id] } {
			return false
		}

		removeStateNode $node_id "error running"

		return true
	}

	proc nodeDestroyFS { eid node_id } {
	}

	proc nodeDestroyFS_check { eid node_id } {
		return true
	}
}
