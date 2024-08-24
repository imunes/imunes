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

# $Id: ifaces.tcl 149 2015-03-27 15:50:14Z valter $


#****h* imunes/ifaces.tcl
# NAME
#  ifaces.tcl -- file used for manipultaion with interfaces in IMUNES
# FUNCTION
#  This module is used to define all the actions used for configuring
#  interfaces in IMUNES.
#
# getIfcOperState { node_id ifc }
#	Returns "up" or "down".
#
# setIfcOperState { node_id ifc state }
#	Sets the new interface state. Implicit default is "up".
#
# getIfcNatState { node_id ifc }
#	Returns "on" or "off".
#
# setIfcNatState { node_id ifc state }
#	Sets the new interface NAT state. Implicit default is "off".
#
# getIfcQDisc { node_id ifc }
#	Returns "FIFO", "WFQ" or "DRR".
#
# setIfcQDisc { node_id ifc qdisc }
#	Sets the new queuing discipline. Implicit default is FIFO.
#
# getIfcQDrop { node_id ifc }
#	Returns "drop-tail" or "drop-head".
#
# setIfcQDrop { node_id ifc qdrop }
#	Sets the new queuing discipline. Implicit default is "drop-tail".
#
# getIfcQLen { node_id ifc }
#	Returns the queue length limit in packets.
#
# setIfcQLen { node_id ifc len }
#	Sets the new queue length limit.
#
# getIfcMTU { node_id ifc }
#	Returns the configured MTU, or an empty string if default MTU is used.
#
# setIfcMTU { node_id ifc mtu }
#	Sets the new MTU. Zero MTU value denotes the default MTU.
#
# getIfcIPv4addr { node_id ifc }
#	Returns a list of all IPv4 addresses assigned to an interface.
#
# setIfcIPv4addrs { node_id ifc addr }
#	Sets a new IPv4 address(es) on an interface. The correctness of the
#	IP address format is not checked / enforced.
#
# getIfcIPv6addr { node_id ifc }
#	Returns a list of all IPv6 addresses assigned to an interface.
#
# setIfcIPv6addrs { node_id ifc addr }
#	Sets a new IPv6 address(es) on an interface. The correctness of the
#	IP address format is not checked / enforced.
#
# ifcList { node_id }
#	Returns a list of all interfaces present in a node.
#
# logicalPeerByIfc { node_id ifc }
#	Returns id of the logical node on the other side of the interface.
#
# hasIPv4Addr { node_id }
# hasIPv6Addr { node_id }
#	Returns true if at least one interface has an IPv{4|6} address
#	configured, otherwise returns false.
#
# removeNode { node_id }
#	Removes the specified node as well as all the links that bind
#       that node to any other node.
#
# newIfc { ifc_type node_id }
#	Returns the first available name for a new interface of the
#       specified type.
#

#****f* nodecfg.tcl/getIfcOperState
# NAME
#   getIfcOperState -- get interface operating state
# SYNOPSIS
#   set state [getIfcOperState $node $ifc]
# FUNCTION
#   Returns the operating state of the specified interface. It can be "up" or
#   "down".
# INPUTS
#   * node -- node id
#   * ifc -- the interface that is up or down
# RESULT
#   * state -- the operating state of the interface, can be either "up" or
#     "down".
#****
proc _getIfcOperState { node_cfg iface } {
    return [_cfgGetWithDefault "up" $node_cfg "ifaces" $iface "oper_state"]
}

#****f* nodecfg.tcl/setIfcOperState
# NAME
#   setIfcOperState -- set interface operating state
# SYNOPSIS
#   setIfcOperState $node $ifc
# FUNCTION
#   Sets the operating state of the specified interface. It can be set to "up"
#   or "down".
# INPUTS
#   * node -- node id
#   * ifc -- interface
#   * state -- new operating state of the interface, can be either "up" or
#     "down"
#****
proc _setIfcOperState { node_cfg iface state } {
    return [_cfgSet $node_cfg "ifaces" $iface "oper_state" $state]
}

#****f* nodecfg.tcl/getIfcNatState
# NAME
#   getIfcNatState -- get interface NAT state
# SYNOPSIS
#   set state [getIfcNatState $node $ifc]
# FUNCTION
#   Returns the NAT state of the specified interface. It can be "on" or "off".
# INPUTS
#   * node -- node id
#   * ifc -- the interface that is used for NAT
# RESULT
#   * state -- the NAT state of the interface, can be either "on" or "off"
#****
proc _getIfcNatState { node_cfg iface } {
    return [_cfgGetWithDefault "off" $node_cfg "ifaces" $iface "nat_state"]
}

#****f* nodecfg.tcl/setIfcNatState
# NAME
#   setIfcNatState -- set interface NAT state
# SYNOPSIS
#   setIfcNatState $node $ifc
# FUNCTION
#   Sets the NAT state of the specified interface. It can be set to "on" or "off"
# INPUTS
#   * node -- node id
#   * ifc -- interface
#   * state -- new NAT state of the interface, can be either "on" or "off"
#****
proc _setIfcNatState { node_cfg iface state } {
    return [_cfgSet $node_cfg "ifaces" $iface "nat_state" $state]
}

#****f* nodecfg.tcl/getIfcQDisc
# NAME
#   getIfcQDisc -- get interface queuing discipline
# SYNOPSIS
#   set qdisc [getIfcQDisc $node $ifc]
# FUNCTION
#   Returns one of the supported queuing discipline ("FIFO", "WFQ" or "DRR")
#   that is active for the specified interface.
# INPUTS
#   * node -- represents the node id of the node whose interface's queuing
#     discipline is checked.
#   * ifc -- The interface name.
# RESULT
#   * qdisc -- returns queuing discipline of the interface, can be "FIFO",
#     "WFQ" or "DRR".
#****
proc _getIfcQDisc { node_cfg iface } {
    if { [_isIfcLogical $node_cfg $iface] } {
	return ""
    }

    return [_cfgGetWithDefault "FIFO" $node_cfg "ifaces" $iface "ifc_qdisc"]
}

#****f* nodecfg.tcl/setIfcQDisc
# NAME
#   setIfcQDisc -- set interface queueing discipline
# SYNOPSIS
#   setIfcQDisc $node $ifc $qdisc
# FUNCTION
#   Sets the new queuing discipline for the interface. Implicit default is
#   FIFO.
# INPUTS
#   * node -- represents the node id of the node whose interface's queuing
#     discipline is set.
#   * ifc -- interface name.
#   * qdisc -- queuing discipline of the interface, can be "FIFO", "WFQ" or
#     "DRR".
#****
proc _setIfcQDisc { node_cfg iface qdisc } {
    return [_cfgSet $node_cfg "ifaces" $iface "ifc_qdisc" $qdisc]
}

#****f* nodecfg.tcl/getIfcQDrop
# NAME
#   getIfcQDrop -- get interface queue dropping policy
# SYNOPSIS
#   set qdrop [getIfcQDrop $node $ifc]
# FUNCTION
#   Returns one of the supported queue dropping policies ("drop-tail" or
#   "drop-head") that is active for the specified interface.
# INPUTS
#   * node -- represents the node id of the node whose interface's queue
#     dropping policy is checked.
#   * ifc -- The interface name.
# RESULT
#   * qdrop -- returns queue dropping policy of the interface, can be
#     "drop-tail" or "drop-head".
#****
proc _getIfcQDrop { node_cfg iface } {
    if { [_isIfcLogical $node_cfg $iface] } {
	return ""
    }

    return [_cfgGetWithDefault "drop-tail" $node_cfg "ifaces" $iface "ifc_qdrop"]
}

#****f* nodecfg.tcl/setIfcQDrop
# NAME
#   setIfcQDrop -- set interface queue dropping policy
# SYNOPSIS
#   setIfcQDrop $node $ifc $qdrop
# FUNCTION
#   Sets the new queuing discipline. Implicit default is "drop-tail".
# INPUTS
#   * node -- represents the node id of the node whose interface's queue
#     droping policie is set.
#   * ifc -- interface name.
#   * qdrop -- new queue dropping policy of the interface, can be "drop-tail"
#     or "drop-head".
#****
proc _setIfcQDrop { node_cfg iface qdrop } {
    return [_cfgSet $node_cfg "ifaces" $iface "ifc_qdrop" $qdrop]
}

#****f* nodecfg.tcl/getIfcQLen
# NAME
#   getIfcQLen -- get interface queue length
# SYNOPSIS
#   set qlen [getIfcQLen $node $ifc]
# FUNCTION
#   Returns the queue length limit in number of packets.
# INPUTS
#   * node -- represents the node id of the node whose interface's queue
#     length is checked.
#   * ifc -- interface name.
# RESULT
#   * qlen -- queue length limit represented in number of packets.
#****
proc _getIfcQLen { node_cfg iface } {
    if { [_isIfcLogical $node_cfg $iface] } {
	return ""
    }

    return [_cfgGetWithDefault 50 $node_cfg "ifaces" $iface "queue_len"]
}

#****f* nodecfg.tcl/setIfcQLen
# NAME
#   setIfcQLen -- set interface queue length
# SYNOPSIS
#   setIfcQLen $node $ifc $len
# FUNCTION
#   Sets the queue length limit.
# INPUTS
#   * node -- represents the node id of the node whose interface's queue
#     length is set.
#   * ifc -- interface name.
#   * qlen -- queue length limit represented in number of packets.
#****
proc _setIfcQLen { node_cfg iface len } {
    return [_cfgSet $node_cfg "ifaces" $iface "queue_len" $len]
}

#****f* nodecfg.tcl/getIfcMTU
# NAME
#   getIfcMTU -- get interface MTU size.
# SYNOPSIS
#   set mtu [getIfcMTU $node $ifc]
# FUNCTION
#   Returns the configured MTU, or a default MTU.
# INPUTS
#   * node -- represents the node id of the node whose interface's MTU is
#     checked.
#   * ifc -- interface name.
# RESULT
#   * mtu -- maximum transmission unit of the packet, represented in bytes.
#****
proc _getIfcMTU { node_cfg iface } {
    set default_mtu 1500

    switch -exact [_getIfcType $node_cfg $iface] {
	lo { set default_mtu 16384 }
	se { set default_mtu 2044 }
    }

    return [_cfgGetWithDefault $default_mtu $node_cfg "ifaces" $iface "mtu"]
}

#****f* nodecfg.tcl/setIfcMTU
# NAME
#   setIfcMTU -- set interface MTU size.
# SYNOPSIS
#   setIfcMTU $node $ifc $mtu
# FUNCTION
#   Sets the new MTU. Zero MTU value denotes the default MTU.
# INPUTS
#   * node -- represents the node id of the node whose interface's MTU is set.
#   * ifc -- interface name.
#   * mtu -- maximum transmission unit of a packet, represented in bytes.
#****
proc _setIfcMTU { node_cfg iface mtu } {
    return [_cfgSet $node_cfg "ifaces" $iface "mtu" $mtu]
}

#****f* nodecfg.tcl/getIfcMACaddr
# NAME
#   getIfcMACaddr -- get interface MAC address.
# SYNOPSIS
#   set addr [getIfcMACaddr $node $ifc]
# FUNCTION
#   Returns the MAC address assigned to the specified interface.
# INPUTS
#   * node -- node id
#   * ifc -- interface name.
# RESULT
#   * addr -- The MAC address assigned to the specified interface.
#****
proc _getIfcMACaddr { node_cfg iface } {
    return [_cfgGet $node_cfg "ifaces" $iface "mac"]
}

#****f* nodecfg.tcl/setIfcMACaddr
# NAME
#   setIfcMACaddr -- set interface MAC address.
# SYNOPSIS
#   setIfcMACaddr $node $ifc $addr
# FUNCTION
#   Sets a new MAC address on an interface. The correctness of the MAC address
#   format is not checked / enforced.
# INPUTS
#   * node -- the node id of the node whose interface's MAC address is set.
#   * ifc -- interface name.
#   * addr -- new MAC address.
#****
proc _setIfcMACaddr { node_cfg iface addr } {
    return [_cfgSet $node_cfg "ifaces" $iface "mac" $addr]
}

#****f* nodecfg.tcl/getIfcIPv4addr
# NAME
#   getIfcIPv4addr -- get interface first IPv4 address.
# SYNOPSIS
#   set addr [getIfcIPv4addr $node $ifc]
# FUNCTION
#   Returns the first IPv4 address assigned to the specified interface.
# INPUTS
#   * node -- node id
#   * ifc -- interface name.
# RESULT
#   * addr -- first IPv4 address on the interface
#
#****
proc _getIfcIPv4addr { node_cfg iface } {
    return [lindex [_getIfcIPv4addrs $node_cfg $iface] 0]
}

#****f* nodecfg.tcl/getIfcIPv4addrs
# NAME
#   getIfcIPv4addrs -- get interface IPv4 addresses.
# SYNOPSIS
#   set addrs [getIfcIPv4addrs $node $ifc]
# FUNCTION
#   Returns the list of IPv4 addresses assigned to the specified interface.
# INPUTS
#   * node -- node id
#   * ifc -- interface name.
# RESULT
#   * addrList -- A list of all the IPv4 addresses assigned to the specified
#     interface.
#****
proc _getIfcIPv4addrs { node_cfg iface } {
    return [_cfgGet $node_cfg "ifaces" $iface "ipv4_addrs"]
}

#****f* nodecfg.tcl/setIfcIPv4addrs
# NAME
#   setIfcIPv4addrs -- set interface IPv4 addresses.
# SYNOPSIS
#   setIfcIPv4addrs $node $ifc $addrs
# FUNCTION
#   Sets new IPv4 address(es) on an interface. The correctness of the IP
#   address format is not checked / enforced.
# INPUTS
#   * node -- the node id of the node whose interface's IPv4 address is set.
#   * ifc -- interface name.
#   * addrs -- new IPv4 addresses.
#****
proc _setIfcIPv4addrs { node_cfg iface addrs } {
    return [_cfgSet $node_cfg "ifaces" $iface "ipv4_addrs" $addrs]
}

#****f* nodecfg.tcl/getIfcType
# NAME
#   getIfcType -- get logical interface type
# SYNOPSIS
#   getIfcType $node $ifc
# FUNCTION
#   Returns logical interface type from a node.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
#****
proc _getIfcType { node_cfg iface } {
    return [_cfgGet $node_cfg "ifaces" $iface "type"]
}

#****f* nodecfg.tcl/setIfcType
# NAME
#   setIfcType -- set logical interface type
# SYNOPSIS
#   setIfcType $node $ifc $type
# FUNCTION
#   Sets node's logical interface type.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
#   * type -- interface type
#****
proc _setIfcType { node_cfg iface type } {
    return [_cfgSet $node_cfg "ifaces" $iface "type" $type]
}

proc _getIfcName { node_cfg iface_id } {
    return [_cfgGet $node_cfg "ifaces" $iface_id "name"]
}

proc _setIfcName { node_cfg iface_id name } {
    return [_cfgSet $node_cfg "ifaces" $iface_id "name" $name]
}

#****f* nodecfg.tcl/getIfcIPv6addr
# NAME
#   getIfcIPv6addr -- get interface first IPv6 address.
# SYNOPSIS
#   set addr [getIfcIPv6addr $node $ifc]
# FUNCTION
#   Returns the first IPv6 address assigned to the specified interface.
# INPUTS
#   * node -- node id
#   * ifc -- interface name.
# RESULT
#   * addr -- first IPv6 address on the interface
#
#****
proc _getIfcIPv6addr { node_cfg iface } {
    return [lindex [_getIfcIPv6addrs $node_cfg $iface] 0]
}

#****f* nodecfg.tcl/getIfcIPv6addrs
# NAME
#   getIfcIPv6addrs -- get interface IPv6 addresses.
# SYNOPSIS
#   set addrs [getIfcIPv6addrs $node $ifc]
# FUNCTION
#   Returns the list of IPv6 addresses assigned to the specified interface.
# INPUTS
#   * node -- the node id of the node whose interface's IPv6 addresses are returned.
#   * ifc -- interface name.
# RESULT
#   * addrList -- A list of all the IPv6 addresses assigned to the specified
#     interface.
#****
proc _getIfcIPv6addrs { node_cfg iface } {
    return [_cfgGet $node_cfg "ifaces" $iface "ipv6_addrs"]
}

#****f* nodecfg.tcl/setIfcIPv6addrs
# NAME
#   setIfcIPv6addrs -- set interface IPv6 addresses.
# SYNOPSIS
#   setIfcIPv6addrs $node $ifc $addrs
# FUNCTION
#   Sets new IPv6 address(es) on an interface. The correctness of the IP
#   address format is not checked / enforced.
# INPUTS
#   * node -- the node id of the node whose interface's IPv6 address is set.
#   * ifc -- interface name.
#   * addrs -- new IPv6 addresses.
#****
proc _setIfcIPv6addrs { node_cfg iface addrs } {
    return [_cfgSet $node_cfg "ifaces" $iface "ipv6_addrs" $addrs]
}

proc _getIfcLink { node_cfg iface } {
    return [_cfgGet $node_cfg "ifaces" $iface "link"]
}

proc _setIfcLink { node_cfg iface link_id } {
    return [_cfgSet $node_cfg "ifaces" $iface "link" $link_id]
}

#****f* nodecfg.tcl/getIfcVlanDev
# NAME
#   getIfcVlanDev -- get interface vlan-dev
# SYNOPSIS
#   getIfcVlanDev $node $ifc
# FUNCTION
#   Returns node's interface's vlan dev.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
# RESULT
#   * tag -- interfaces's vlan-dev
#****
proc _getIfcVlanDev { node_cfg iface } {
    return [_cfgGet $node_cfg "ifaces" $iface "vlan_dev"]
}

#****f* nodecfg.tcl/setIfcVlanDev
# NAME
#   setIfcVlanDev -- set interface vlan-dev
# SYNOPSIS
#   setIfcVlanDev $node $ifc $dev
# FUNCTION
#   Sets the node's interface's vlan dev.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
#   * dev -- vlan-dev
#****
proc _setIfcVlanDev { node_cfg iface dev } {
    return [_cfgSet $node_cfg "ifaces" $iface "vlan_dev" $dev]
}

#****f* nodecfg.tcl/getIfcVlanTag
# NAME
#   getIfcVlanTag -- get interface vlan-tag
# SYNOPSIS
#   getIfcVlanTag $node $ifc
# FUNCTION
#   Returns node's interface's vlan tag.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
# RESULT
#   * tag -- interfaces's vlan-tag
#****
proc _getIfcVlanTag { node_cfg iface } {
    return [_cfgGet $node_cfg "ifaces" $iface "vlan_tag"]
}

#****f* nodecfg.tcl/setIfcVlanTag
# NAME
#   setIfcVlanTag -- set interface vlan-tag
# SYNOPSIS
#   setIfcVlanTag $node $ifc $tag
# FUNCTION
#   Sets the node's interface's vlan tag.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
#   * dev -- vlan-tag
#****
proc _setIfcVlanTag { node_cfg iface tag } {
    return [_cfgSet $node_cfg "ifaces" $iface "vlan_tag" $tag]
}

proc _getNodeIface { node_cfg iface_id } {
    return [_cfgGet $node_cfg "ifaces" $iface_id]
}

proc _setNodeIface { node_cfg iface_id new_iface } {
    return [_cfgSet $node_cfg "ifaces" $iface_id $new_iface]
}

##############################################################

#****f* nodecfg.tcl/ifcList
# NAME
#   ifcList -- get list of all interfaces
# SYNOPSIS
#   set ifcs [ifcList $node]
# FUNCTION
#   Returns a list of all interfaces present in a node.
# INPUTS
#   * node -- node id
# RESULT
#   * interfaces -- list of all node's interfaces
#****
proc _ifcList { node_cfg } {
    return [lsearch -glob -all -inline [dict keys [_cfgGet $node_cfg "ifaces"]] "ifc*"]
}

proc _ifaceNames { node_cfg } {
    set iface_names {}
    foreach {iface_id iface_cfg} [_cfgGet $node_cfg "ifaces"] {
	if { [string match "ifc*" $iface_id] } {
	    lappend iface_names [_cfgGet $iface_cfg "name"]
	}
    }

    return $iface_names
}

#****f* nodecfg.tcl/logIfcList
# NAME
#   logIfcList -- logical interfaces list
# SYNOPSIS
#   logIfcList $node
# FUNCTION
#   Returns the list of all the node's logical interfaces.
# INPUTS
#   * node -- node id
# RESULT
#   * interfaces -- list of node's logical interfaces
#****
proc _logIfcList { node_cfg } {
    return [lsearch -glob -all -inline [dict keys [_cfgGet $node_cfg "ifaces"]] "lifc*"]
}

proc _logIfaceNames { node_cfg } {
    set logiface_names {}
    foreach {logiface_id logiface_cfg} [_cfgGet $node_cfg "ifaces"] {
	if { [string match "lifc*" $logiface_id] } {
	    lappend logiface_names [_cfgGet $logiface_cfg "name"]
	}
    }

    return $logiface_names
}

#****f* nodecfg.tcl/isIfcLogical
# NAME
#   isIfcLogical -- is given interface logical
# SYNOPSIS
#   isIfcLogical $node $ifc
# FUNCTION
#   Returns true or false whether the node's interface is logical or not.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
# RESULT
#   * check -- true if the interface is logical, otherwise false.
#****
proc _isIfcLogical { node_cfg iface_id } {
    if { $iface_id in [_logIfcList $node_cfg] } {
	return true
    }

    return false
}

#****f* nodecfg.tcl/allIfcList
# NAME
#   allIfcList -- all interfaces list
# SYNOPSIS
#   allIfcList $node
# FUNCTION
#   Returns the list of all node's interfaces.
# INPUTS
#   * node -- node id
# RESULT
#   * interfaces -- list of node's interfaces
#****
proc _allIfcList { node_cfg } {
    return [dict keys [_cfgGet $node_cfg "ifaces"]]
}

proc _ifaceIdFromName { node_cfg iface_name } {
    foreach {iface_id iface_cfg} [_cfgGet $node_cfg "ifaces"] {
	if { $iface_name == [_cfgGet $iface_cfg "name"] } {
	    return $iface_id
	}
    }

    return ""
}

proc _chooseIfaceName { node_cfg } {
    set iface_prefix [[dictGet $node_cfg "type"].ifacePrefix]

    set ifaces {}
    foreach {iface_id iface_cfg} [dictGet $node_cfg "ifaces"] {
	if { [dictGet $iface_cfg "type"] == "phys" } {
	    set iface_name [dictGet $iface_cfg "name"]
	    if { [regexp "$iface_prefix\[0-9\]+" $iface_name] } {
		lappend ifaces $iface_name
	    }
	}
    }

    return [newObjectIdAlt $ifaces $iface_prefix]
}

proc _newIface { node_cfg iface_type auto_config { stolen_iface "" } } {
    set iface_list [lsearch -glob -all -inline [dict keys [_cfgGet $node_cfg "ifaces"]] "ifc*"]

    set iface_id [newObjectIdAlt $iface_list "ifc"]

    set node_cfg [_setIfcType $node_cfg $iface_id $iface_type]
    if { $iface_type == "stolen" } {
	set node_cfg [_setIfcName $node_cfg $iface_id $stolen_iface]
    } else {
	set node_cfg [_setIfcName $node_cfg $iface_id [_chooseIfaceName $node_cfg]]
    }

    # TODO
    if { $auto_config } {
	set node_cfg [[_cfgGet $node_cfg "type"]._confNewIfc $node_cfg $iface_id]
    }

    return [list $iface_id $node_cfg]
}

proc _newLogIface { node_cfg logiface_type } {
    set current_logiface_names [lsearch -all -inline -glob [_logIfaceNames $node_cfg] "$logiface_type*"]

    set logiface_id [newObjectIdAlt [_logIfcList $node_cfg] "lifc"]
    set node_cfg [_setNodeIface $node_cfg $logiface_id {}]

    set node_cfg [_setIfcType $node_cfg $logiface_id $logiface_type]
    set node_cfg [_setIfcName $node_cfg $logiface_id [newObjectIdAlt $current_logiface_names $logiface_type]]

    return [list $logiface_id $node_cfg]
}

proc _removeIface { node_cfg iface_id } {
    set iface_name [_getIfcName $node_cfg $iface_id]
    set node_cfg [dictUnset $node_cfg "ifaces" $iface_id]

    foreach {logiface_id iface_cfg} [_cfgGet $node_cfg "ifaces"] {
	switch -exact [_cfgGet $iface_cfg "type"] {
	    vlan {
		if { [_cfgGet $iface_cfg "vlan_dev"] == $iface_name } {
		    set node_cfg [dictUnset $node_cfg "ifaces" $logiface_id]
		}
	    }
	}
    }

    return $node_cfg
}

proc _nodeCfggenIfc { node_id iface_id } {
    set cfg {}

    set iface_name [getIfcName $node_id $iface_id]
    set mtu [getIfcMTU $node_id $iface_id]
    if { [getIfcType $node_id $iface_id] == "vlan" } {
	set tag [getIfcVlanTag $node_id $iface_id]
	set dev [getIfcVlanDev $node_id $iface_id]
	if { $tag != "" && $dev != "" } {
	    lappend cfg [getVlanTagIfcCmd $iface_name $dev $tag]
	}
    }

    lappend cfg [getMtuIfcCmd $iface_name $mtu]

    if { [getIfcNatState $node_id $iface_id] == "on" } {
	lappend cfg [getNatIfcCmd $iface_name]
    }

    set primary 1
    foreach addr [getIfcIPv4addrs $node_id $iface_id] {
	if { $addr != "" } {
	    lappend cfg [getIPv4IfcCmd $iface_name $addr $primary]
	    set primary 0
	}
    }

    set primary 1
    foreach addr [getIfcIPv6addrs $node_id $iface_id] {
	if { $addr != "" } {
	    lappend cfg [getIPv6IfcCmd $iface_name $addr $primary]
	    set primary 0
	}
    }

    set state [getIfcOperState $node_id $iface_id]
    if { $state == "" } {
	set state "up"
    }

    lappend cfg [getStateIfcCmd $iface_name $state]

    return $cfg
}
