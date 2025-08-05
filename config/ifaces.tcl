#
# Copyright 2024- University of Zagreb.
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

#****f* ifaces.tcl/getIfcOperState
# NAME
#   getIfcOperState -- get interface operating state
# SYNOPSIS
#   set state [getIfcOperState $node_id $iface_id]
# FUNCTION
#   Returns the operating state of the specified interface. It can be "up" or
#   "down".
# INPUTS
#   * node_id -- node id
#   * iface_id -- the interface that is up or down
# RESULT
#   * state -- the operating state of the interface, can be either "up" or
#     "down".
#****
proc getIfcOperState { node_id iface_id } {
	return [cfgGetWithDefault "up" "nodes" $node_id "ifaces" $iface_id "oper_state"]
}

#****f* ifaces.tcl/setIfcOperState
# NAME
#   setIfcOperState -- set interface operating state
# SYNOPSIS
#   setIfcOperState $node_id $iface_id
# FUNCTION
#   Sets the operating state of the specified interface. It can be set to "up"
#   or "down".
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface
#   * state -- new operating state of the interface, can be either "up" or
#     "down"
#****
proc setIfcOperState { node_id iface_id state } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "oper_state" $state

	trigger_ifaceReconfig $node_id $iface_id
}

#****f* ifaces.tcl/getIfcNatState
# NAME
#   getIfcNatState -- get interface NAT state
# SYNOPSIS
#   set state [getIfcNatState $node_id $iface_id]
# FUNCTION
#   Returns the NAT state of the specified interface. It can be "on" or "off".
# INPUTS
#   * node_id -- node id
#   * iface_id -- the interface that is used for NAT
# RESULT
#   * state -- the NAT state of the interface, can be either "on" or "off"
#****
proc getIfcNatState { node_id iface_id } {
	return [cfgGetWithDefault "off" "nodes" $node_id "ifaces" $iface_id "nat_state"]
}

#****f* ifaces.tcl/setIfcNatState
# NAME
#   setIfcNatState -- set interface NAT state
# SYNOPSIS
#   setIfcNatState $node_id $iface_id
# FUNCTION
#   Sets the NAT state of the specified interface. It can be set to "on" or "off"
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface
#   * state -- new NAT state of the interface, can be either "on" or "off"
#****
proc setIfcNatState { node_id iface_id state } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "nat_state" $state

	trigger_ifaceReconfig $node_id $iface_id
}

#****f* ifaces.tcl/getIfcQDisc
# NAME
#   getIfcQDisc -- get interface queuing discipline
# SYNOPSIS
#   set qdisc [getIfcQDisc $node_id $iface_id]
# FUNCTION
#   Returns one of the supported queuing discipline ("FIFO", "WFQ" or "DRR")
#   that is active for the specified interface.
# INPUTS
#   * node_id -- represents the node id of the node whose interface's queuing
#     discipline is checked.
#   * iface_id -- interface id
# RESULT
#   * qdisc -- returns queuing discipline of the interface, can be "FIFO",
#     "WFQ" or "DRR".
#****
proc getIfcQDisc { node_id iface_id } {
	return [cfgGetWithDefault "FIFO" "nodes" $node_id "ifaces" $iface_id "ifc_qdisc"]
}

#****f* ifaces.tcl/setIfcQDisc
# NAME
#   setIfcQDisc -- set interface queueing discipline
# SYNOPSIS
#   setIfcQDisc $node_id $iface_id $qdisc
# FUNCTION
#   Sets the new queuing discipline for the interface. Implicit default is
#   FIFO.
# INPUTS
#   * node_id -- represents the node id of the node whose interface's queuing
#     discipline is set.
#   * iface_id -- interface id
#   * qdisc -- queuing discipline of the interface, can be "FIFO", "WFQ" or
#     "DRR".
#****
proc setIfcQDisc { node_id iface_id qdisc } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "ifc_qdisc" $qdisc

	# TODO
	trigger_ifaceReconfig $node_id $iface_id
}

#****f* ifaces.tcl/getIfcQDrop
# NAME
#   getIfcQDrop -- get interface queue dropping policy
# SYNOPSIS
#   set qdrop [getIfcQDrop $node_id $iface_id]
# FUNCTION
#   Returns one of the supported queue dropping policies ("drop-tail" or
#   "drop-head") that is active for the specified interface.
# INPUTS
#   * node_id -- represents the node id of the node whose interface's queue
#     dropping policy is checked.
#   * iface_id -- interface id
# RESULT
#   * qdrop -- returns queue dropping policy of the interface, can be
#     "drop-tail" or "drop-head".
#****
proc getIfcQDrop { node_id iface_id } {
	return [cfgGetWithDefault "drop-tail" "nodes" $node_id "ifaces" $iface_id "ifc_qdrop"]
}

#****f* ifaces.tcl/setIfcQDrop
# NAME
#   setIfcQDrop -- set interface queue dropping policy
# SYNOPSIS
#   setIfcQDrop $node_id $iface_id $qdrop
# FUNCTION
#   Sets the new queuing discipline. Implicit default is "drop-tail".
# INPUTS
#   * node_id -- represents the node id of the node whose interface's queue
#     droping policie is set.
#   * iface_id -- interface id
#   * qdrop -- new queue dropping policy of the interface, can be "drop-tail"
#     or "drop-head".
#****
proc setIfcQDrop { node_id iface_id qdrop } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "ifc_qdrop" $qdrop

	# TODO
	trigger_ifaceReconfig $node_id $iface_id
}

#****f* ifaces.tcl/getIfcQLen
# NAME
#   getIfcQLen -- get interface queue length
# SYNOPSIS
#   set qlen [getIfcQLen $node_id $iface_id]
# FUNCTION
#   Returns the queue length limit in number of packets.
# INPUTS
#   * node_id -- represents the node id of the node whose interface's queue
#     length is checked.
#   * iface_id -- interface id
# RESULT
#   * qlen -- queue length limit represented in number of packets.
#****
proc getIfcQLen { node_id iface_id } {
	return [cfgGetWithDefault 50 "nodes" $node_id "ifaces" $iface_id "queue_len"]
}

#****f* ifaces.tcl/setIfcQLen
# NAME
#   setIfcQLen -- set interface queue length
# SYNOPSIS
#   setIfcQLen $node_id $iface_id $len
# FUNCTION
#   Sets the queue length limit.
# INPUTS
#   * node_id -- represents the node id of the node whose interface's queue
#     length is set.
#   * iface_id -- interface id
#   * qlen -- queue length limit represented in number of packets.
#****
proc setIfcQLen { node_id iface_id len } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "queue_len" $len

	# TODO
	trigger_ifaceReconfig $node_id $iface_id
}

#****f* ifaces.tcl/getIfcMTU
# NAME
#   getIfcMTU -- get interface MTU size.
# SYNOPSIS
#   set mtu [getIfcMTU $node_id $iface_id]
# FUNCTION
#   Returns the configured MTU, or a default MTU.
# INPUTS
#   * node_id -- represents the node id of the node whose interface's MTU is
#     checked.
#   * iface_id -- interface id
# RESULT
#   * mtu -- maximum transmission unit of the packet, represented in bytes.
#****
proc getIfcMTU { node_id iface_id } {
	set default_mtu 1500

	switch -exact [getIfcType $node_id $iface_id] {
		lo { set default_mtu 16384 }
		se { set default_mtu 2044 }
	}

	return [cfgGetWithDefault $default_mtu "nodes" $node_id "ifaces" $iface_id "mtu"]
}

#****f* ifaces.tcl/setIfcMTU
# NAME
#   setIfcMTU -- set interface MTU size.
# SYNOPSIS
#   setIfcMTU $node_id $iface_id $mtu
# FUNCTION
#   Sets the new MTU. Zero MTU value denotes the default MTU.
# INPUTS
#   * node_id -- represents the node id of the node whose interface's MTU is set.
#   * iface_id -- interface id
#   * mtu -- maximum transmission unit of a packet, represented in bytes.
#****
proc setIfcMTU { node_id iface_id mtu } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "mtu" $mtu

	trigger_ifaceReconfig $node_id $iface_id
}

#****f* ifaces.tcl/getIfcMACaddr
# NAME
#   getIfcMACaddr -- get interface MAC address.
# SYNOPSIS
#   set addr [getIfcMACaddr $node_id $iface_id]
# FUNCTION
#   Returns the MAC address assigned to the specified interface.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
# RESULT
#   * addr -- The MAC address assigned to the specified interface.
#****
proc getIfcMACaddr { node_id iface_id } {
	return [cfgGet "nodes" $node_id "ifaces" $iface_id "mac"]
}

#****f* ifaces.tcl/setIfcMACaddr
# NAME
#   setIfcMACaddr -- set interface MAC address.
# SYNOPSIS
#   setIfcMACaddr $node_id $iface_id $addr
# FUNCTION
#   Sets a new MAC address on an interface. The correctness of the MAC address
#   format is not checked / enforced.
# INPUTS
#   * node_id -- the node id of the node whose interface's MAC address is set.
#   * iface_id -- interface id
#   * addr -- new MAC address.
#****
proc setIfcMACaddr { node_id iface_id addr } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "mac" $addr

	trigger_ifaceReconfig $node_id $iface_id
}

#****f* ifaces.tcl/getIfcIPv4addrs
# NAME
#   getIfcIPv4addrs -- get interface IPv4 addresses.
# SYNOPSIS
#   set addrs4 [getIfcIPv4addrs $node_id $iface_id]
# FUNCTION
#   Returns the list of IPv4 addresses assigned to the specified interface.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
# RESULT
#   * addrList -- A list of all the IPv4 addresses assigned to the specified
#     interface.
#****
proc getIfcIPv4addrs { node_id iface_id } {
	return [cfgGet "nodes" $node_id "ifaces" $iface_id "ipv4_addrs"]
}

#****f* ifaces.tcl/setIfcIPv4addrs
# NAME
#   setIfcIPv4addrs -- set interface IPv4 addresses.
# SYNOPSIS
#   setIfcIPv4addrs $node_id $iface_id $addrs4
# FUNCTION
#   Sets new IPv4 address(es) on an interface. The correctness of the IP
#   address format is not checked / enforced.
# INPUTS
#   * node_id -- the node id of the node whose interface's IPv4 address is set.
#   * iface_id -- interface id
#   * addrs4 -- new IPv4 addresses.
#****
proc setIfcIPv4addrs { node_id iface_id addrs4 } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "ipv4_addrs" $addrs4

	trigger_ifaceReconfig $node_id $iface_id

	set node_type [getNodeType $node_id]
	set is_extnat [expr {$node_type == "ext" && [getNodeNATIface $node_id] != "UNASSIGNED"}]
	if { $is_extnat } {
		trigger_nodeReconfig $node_id
	}

	if { [isIfcLogical $node_id $iface_id] || ! ($node_type in "router nat64" || $is_extnat) } {
		return
	}

	lassign [getSubnetData $node_id $iface_id {} {} 0] subnet_gws subnet_data
	if { $subnet_gws == "{||}" } {
		return
	}

	set has_extnat [string match "*ext*" $subnet_gws]
	foreach subnet_node [removeFromList [dict keys $subnet_data] $node_id] {
		if { [getNodeAutoDefaultRoutesStatus $subnet_node] != "enabled" } {
			continue
		}

		set subnet_node_type [getNodeType $subnet_node]
		if { $subnet_node_type == "ext" || [$subnet_node_type.netlayer] != "NETWORK" } {
			# skip extnat and L2 nodes
			continue
		}

		if { ! $has_extnat && $subnet_node_type in "router nat64" } {
			# skip routers if there is no extnats
			continue
		}

		trigger_nodeReconfig $subnet_node
	}
}

#****f* ifaces.tcl/getIfcType
# NAME
#   getIfcType -- get logical interface type
# SYNOPSIS
#   getIfcType $node_id $iface_id
# FUNCTION
#   Returns logical interface type from a node.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
#****
proc getIfcType { node_id iface_id } {
	return [cfgGet "nodes" $node_id "ifaces" $iface_id "type"]
}

#****f* ifaces.tcl/setIfcType
# NAME
#   setIfcType -- set logical interface type
# SYNOPSIS
#   setIfcType $node_id $iface_id $type
# FUNCTION
#   Sets node's logical interface type.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
#   * type -- interface type
#****
proc setIfcType { node_id iface_id type } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "type" $type
}

#****f* ifaces.tcl/getIfcName
# NAME
#   getIfcName -- get interface name
# SYNOPSIS
#   set name [getIfcName $node_id $iface_id]
# FUNCTION
#   Returns the name of the specified interface.
# INPUTS
#   * node_id -- node id
#   * iface_id -- the interface id
# RESULT
#   * name -- the name of the interface
#****
proc getIfcName { node_id iface_id } {
	return [cfgGet "nodes" $node_id "ifaces" $iface_id "name"]
}

#****f* ifaces.tcl/setIfcName
# NAME
#   setIfcName -- set interface name
# SYNOPSIS
#   setIfcName $node_id $iface_id $name
# FUNCTION
#   Sets the name of the specified interface.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
#   * name -- new name of the interface
#****
proc setIfcName { node_id iface_id name } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "name" $name

	# TODO
	trigger_ifaceRecreate $node_id $iface_id

	set link_id [getIfcLink $node_id $iface_id]
	if { $link_id != "" } {
		trigger_linkRecreate $link_id
	}
}

#****f* ifaces.tcl/getIfcIPv6addrs
# NAME
#   getIfcIPv6addrs -- get interface IPv6 addresses.
# SYNOPSIS
#   set addrs6 [getIfcIPv6addrs $node_id $iface_id]
# FUNCTION
#   Returns the list of IPv6 addresses assigned to the specified interface.
# INPUTS
#   * node_id -- the node id of the node whose interface's IPv6 addresses are returned.
#   * iface_id -- interface id
# RESULT
#   * addrList -- A list of all the IPv6 addresses assigned to the specified
#     interface.
#****
proc getIfcIPv6addrs { node_id iface_id } {
	return [cfgGet "nodes" $node_id "ifaces" $iface_id "ipv6_addrs"]
}

#****f* ifaces.tcl/setIfcIPv6addrs
# NAME
#   setIfcIPv6addrs -- set interface IPv6 addresses.
# SYNOPSIS
#   setIfcIPv6addrs $node_id $iface_id $addrs6
# FUNCTION
#   Sets new IPv6 address(es) on an interface. The correctness of the IP
#   address format is not checked / enforced.
# INPUTS
#   * node_id -- the node id of the node whose interface's IPv6 address is set.
#   * iface_id -- interface id
#   * addrs6 -- new IPv6 addresses.
#****
proc setIfcIPv6addrs { node_id iface_id addrs6 } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "ipv6_addrs" $addrs6

	trigger_ifaceReconfig $node_id $iface_id

	set node_type [getNodeType $node_id]
	set is_extnat [expr {($node_type == "ext" && [getNodeNATIface $node_id] != "UNASSIGNED")}]
	if { [isIfcLogical $node_id $iface_id] || ! ($node_type in "router nat64" || $is_extnat) } {
		return
	}

	lassign [getSubnetData $node_id $iface_id {} {} 0] subnet_gws subnet_data
	if { $subnet_gws == "{||}" } {
		return
	}

	set has_extnat [string match "*ext*" $subnet_gws]
	foreach subnet_node [removeFromList [dict keys $subnet_data] $node_id] {
		if { [getNodeAutoDefaultRoutesStatus $subnet_node] != "enabled" } {
			continue
		}

		set subnet_node_type [getNodeType $subnet_node]
		if { $subnet_node_type == "ext" || [$subnet_node_type.netlayer] != "NETWORK" } {
			# skip extnat and L2 nodes
			continue
		}

		if { ! $has_extnat && [getNodeType $subnet_node] in "router nat64" } {
			# skip routers if there is no extnats
			continue
		}

		trigger_nodeReconfig $subnet_node
	}
}

#****f* linkcfg.tcl/getIfcLink
# NAME
#   getIfcLink -- get interface's link
# SYNOPSIS
#   set link_id [getIfcLink $node_id $iface_id]
# FUNCTION
#   Returns the link id of the link connected to the node's interface.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
# RESULT
#   * link_id -- link id
#****
proc getIfcLink { node_id iface_id } {
	return [cfgGet "nodes" $node_id "ifaces" $iface_id "link"]
}

#****f* linkcfg.tcl/setIfcLink
# NAME
#   setIfcLink -- set interface's link
# SYNOPSIS
#   setIfcLink $node_id $iface_id $link_id
# FUNCTION
#   Sets the link id of the link connected to the node's interface.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
#   * link_id -- link id
#****
proc setIfcLink { node_id iface_id link_id } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "link" $link_id

	# TODO?
	#trigger_linkRecreate $link_id
}

#****f* ifaces.tcl/getIfcVlanDev
# NAME
#   getIfcVlanDev -- get interface vlan-dev
# SYNOPSIS
#   getIfcVlanDev $node_id $iface_id
# FUNCTION
#   Returns node's interface's vlan dev.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
# RESULT
#   * tag -- interfaces's vlan-dev
#****
proc getIfcVlanDev { node_id iface_id } {
	return [cfgGet "nodes" $node_id "ifaces" $iface_id "vlan_dev"]
}

#****f* ifaces.tcl/setIfcVlanDev
# NAME
#   setIfcVlanDev -- set interface vlan-dev
# SYNOPSIS
#   setIfcVlanDev $node_id $iface_id $dev
# FUNCTION
#   Sets the node's interface's vlan dev.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
#   * dev -- vlan-dev
#****
proc setIfcVlanDev { node_id iface_id dev } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "vlan_dev" $dev

	if { [getNodeType $node_id] == "rj45" } {
		trigger_nodeRecreate $node_id
	}
}

#****f* ifaces.tcl/getIfcVlanTag
# NAME
#   getIfcVlanTag -- get interface vlan-tag
# SYNOPSIS
#   getIfcVlanTag $node_id $iface_id
# FUNCTION
#   Returns node's interface's vlan tag.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
# RESULT
#   * tag -- interfaces's vlan-tag
#****
proc getIfcVlanTag { node_id iface_id } {
	if { [getNodeType $node_id] in "lanswitch" } {
		set default_tag 1
	} else {
		set default_tag ""
	}

	return [cfgGetWithDefault $default_tag "nodes" $node_id "ifaces" $iface_id "vlan_tag"]
}

#****f* ifaces.tcl/setIfcVlanTag
# NAME
#   setIfcVlanTag -- set interface vlan-tag
# SYNOPSIS
#   setIfcVlanTag $node_id $iface_id $tag
# FUNCTION
#   Sets the node's interface's vlan tag.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
#   * tag -- vlan-tag
#****
proc setIfcVlanTag { node_id iface_id tag } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "vlan_tag" $tag

	set node_type [getNodeType $node_id]
	if { [getNodeType $node_id] == "rj45" } {
		trigger_nodeRecreate $node_id
	} elseif { [getNodeType $node_id] == "lanswitch" } {
		foreach other_iface_id [ifcList $node_id] {
			if { $iface_id != $other_iface_id && [getIfcVlanType $node_id $other_iface_id] != "trunk" } {
				continue
			}

			trigger_ifaceReconfig $node_id $other_iface_id
			set link_id [getIfcLink $node_id $other_iface_id]
			if { $link_id != "" } {
				trigger_linkRecreate $link_id
			}
		}
	}
}

#****f* ifaces.tcl/getIfcVlanType
# NAME
#   getIfcVlanType -- get interface vlan type
# SYNOPSIS
#   getIfcVlanType $node_id $iface_id
# FUNCTION
#   Returns node's interface's vlan type.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
# RESULT
#   * type -- interfaces's vlan type
#****
proc getIfcVlanType { node_id iface_id } {
	return [cfgGetWithDefault "access" "nodes" $node_id "ifaces" $iface_id "vlan_type"]
}

#****f* ifaces.tcl/setIfcVlanType
# NAME
#   setIfcVlanType -- set interface vlan type
# SYNOPSIS
#   setIfcVlanType $node_id $iface_id $tag
# FUNCTION
#   Sets the node's interface's vlan tag.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
#   * type -- vlan type
#****
proc setIfcVlanType { node_id iface_id type } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "vlan_type" $type

	if { [getNodeType $node_id] in "rj45 lanswitch" } {
		trigger_nodeRecreate $node_id
	}
}
