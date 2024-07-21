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
# getIfcOperState { node_id iface_id }
#	Returns "up" or "down".
#
# setIfcOperState { node_id iface_id state }
#	Sets the new interface state. Implicit default is "up".
#
# getIfcNatState { node_id iface_id }
#	Returns "on" or "off".
#
# setIfcNatState { node_id iface_id state }
#	Sets the new interface NAT state. Implicit default is "off".
#
# getIfcQDisc { node_id iface_id }
#	Returns "FIFO", "WFQ" or "DRR".
#
# setIfcQDisc { node_id iface_id qdisc }
#	Sets the new queuing discipline. Implicit default is FIFO.
#
# getIfcQDrop { node_id iface_id }
#	Returns "drop-tail" or "drop-head".
#
# setIfcQDrop { node_id iface_id qdrop }
#	Sets the new queuing discipline. Implicit default is "drop-tail".
#
# getIfcQLen { node_id iface_id }
#	Returns the queue length limit in packets.
#
# setIfcQLen { node_id iface_id len }
#	Sets the new queue length limit.
#
# getIfcMTU { node_id iface_id }
#	Returns the configured MTU, or an empty string if default MTU is used.
#
# setIfcMTU { node_id iface_id mtu }
#	Sets the new MTU. Zero MTU value denotes the default MTU.
#
# getIfcIPv4addrs { node_id iface_id }
#	Returns a list of all IPv4 addresses assigned to an interface.
#
# setIfcIPv4addrs { node_id iface_id addr }
#	Sets a new IPv4 address(es) on an interface. The correctness of the
#	IP address format is not checked / enforced.
#
# getIfcIPv6addrs { node_id iface_id }
#	Returns a list of all IPv6 addresses assigned to an interface.
#
# setIfcIPv6addrs { node_id iface_id addr }
#	Sets a new IPv6 address(es) on an interface. The correctness of the
#	IP address format is not checked / enforced.
#
# ifcList { node_id }
#	Returns a list of all interfaces present in a node.
#
# logicalPeerByIfc { node_id iface_id }
#	Returns id of the logical node on the other side of the interface.
#
# hasIPv4Addr { node_id }
# hasIPv6Addr { node_id }
#	Returns true if at least one interface has an IPv{4|6} address
#	configured, otherwise returns false.
#
# newIface { ifc_type node_id }
#	Returns the first available name for a new interface of the
#       specified type.
#

#****f* nodecfg.tcl/getIfcOperState
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
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "shutdown" } {
	    return "down"
	}
    }

    return "up"
}

#****f* nodecfg.tcl/setIfcOperState
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
    set ifcfg [list "interface $iface_id"]
    if { $state == "down" } {
	lappend ifcfg " shutdown"
    }

    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "shutdown" && \
	  [lrange $line 0 1] != "no shutdown" } {

	    lappend ifcfg $line
	}
    }

    netconfInsertSection $node_id $ifcfg
}

#****f* nodecfg.tcl/getIfcNatState
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
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] in "!nat nat" } {
	    return "on"
	}
    }

    return "off"
}

#****f* nodecfg.tcl/setIfcNatState
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
    set ifcfg [list "interface $iface_id"]
    if { $state == "on" } {
	lappend ifcfg " !nat"
    }

    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] ni "!nat nat" } {
	    lappend ifcfg $line
	}
    }

    netconfInsertSection $node_id $ifcfg
}

#****f* nodecfg.tcl/getIfcQDisc
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
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "fair-queue" } {
	    return WFQ
	}
	if { [lindex $line 0] == "drr-queue" } {
	    return DRR
	}
    }

    return FIFO
}

#****f* nodecfg.tcl/setIfcQDisc
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
    set ifcfg [list "interface $iface_id"]
    if { $qdisc == "WFQ" } {
	lappend ifcfg " fair-queue"
    }

    if { $qdisc == "DRR" } {
	lappend ifcfg " drr-queue"
    }

    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "fair-queue" && \
	    [lindex $line 0] != "drr-queue" } {
	    lappend ifcfg $line
	}
    }

    netconfInsertSection $node_id $ifcfg
}

#****f* nodecfg.tcl/getIfcQDrop
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
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "drop-head" } {
	    return drop-head
	}
    }

    return drop-tail
}

#****f* nodecfg.tcl/setIfcQDrop
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
    set ifcfg [list "interface $iface_id"]
    if { $qdrop == "drop-head" } {
	lappend ifcfg " drop-head"

    }

    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "drop-head" && \
	    [lindex $line 0] != "drop-tail" } {
	    lappend ifcfg $line
	}
    }

    netconfInsertSection $node_id $ifcfg
}

#****f* nodecfg.tcl/getIfcQLen
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
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "queue-len" } {
	    return [lindex $line 1]
	}
    }

    return 50
}

#****f* nodecfg.tcl/setIfcQLen
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
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "queue-len" } {
	    lappend ifcfg $line
	}
    }

    if { $len > 5 && $len != 50 } {
	lappend ifcfg " queue-len $len"
    }

    netconfInsertSection $node_id $ifcfg
}

#****f* nodecfg.tcl/getIfcMTU
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
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "mtu" } {
	    return [lindex $line 1]
	}
    }

    # Return defaults
    switch -exact [string range $iface_id 0 1] {
	lo { return 16384 }
	se { return 2044 }
    }

    return 1500
}

#****f* nodecfg.tcl/setIfcMTU
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
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "mtu" } {
	    lappend ifcfg $line
	}
    }

    set limit 9018
    if { $mtu >= 256 && $mtu <= $limit } {
	lappend ifcfg " mtu $mtu"
    }

    netconfInsertSection $node_id $ifcfg
}

#****f* nodecfg.tcl/getIfcMACaddr
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
    set addr ""
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lrange $line 0 1] == "mac address" } {
	    set addr [lindex $line 2]
	}
    }

    return $addr
}

#****f* nodecfg.tcl/setIfcMACaddr
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
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lrange $line 0 1] != "mac address" } {
	    lappend ifcfg $line
	}
    }

    if { $addr != "" } {
	lappend ifcfg " mac address $addr"
    }

    netconfInsertSection $node_id $ifcfg
}

#****f* nodecfg.tcl/getIfcIPv4addrs
# NAME
#   getIfcIPv4addrs -- get interface IPv4 addresses.
# SYNOPSIS
#   set addrs [getIfcIPv4addrs $node_id $iface_id]
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
    set addrlist {}
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lrange $line 0 1] == "ip address" } {
	    lappend addrlist [lindex $line 2]
	}
    }

    return $addrlist
}

#****f* nodecfg.tcl/setIfcIPv4addrs
# NAME
#   setIfcIPv4addrs -- set interface IPv4 addresses.
# SYNOPSIS
#   setIfcIPv4addrs $node_id $iface_id $addrs
# FUNCTION
#   Sets new IPv4 address(es) on an interface. The correctness of the IP
#   address format is not checked / enforced.
# INPUTS
#   * node_id -- the node id of the node whose interface's IPv4 address is set.
#   * iface_id -- interface id
#   * addrs -- new IPv4 addresses.
#****
proc setIfcIPv4addrs { node_id iface_id addrs } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lrange $line 0 1] != "ip address" } {
	    lappend ifcfg $line
	}
    }

    foreach addr $addrs {
	if { $addr != "" } {
	    set addr [string trim $addr]
	    lappend ifcfg " ip address $addr"
	}
    }

    netconfInsertSection $node_id $ifcfg
}

#****f* nodecfg.tcl/getIfcType
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
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "type" } {
	    return [lindex $line 1]
	}
    }
}

#****f* nodecfg.tcl/setIfcType
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
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "type" } {
	    lappend ifcfg $line
	}
    }

    if { $type != "" } {
	lappend ifcfg " type $type"
    }

    netconfInsertSection $node_id $ifcfg
}

#****f* nodecfg.tcl/getIfcName
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
    return $iface_id
}

#****f* nodecfg.tcl/setIfcName
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
}

#****f* nodecfg.tcl/getLogIfcType
# NAME
#   getLogIfcType -- get logical interface type
# SYNOPSIS
#   getLogIfcType $node_id $iface_id
# FUNCTION
#   Returns logical interface type from a node.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
#****
proc getLogIfcType { node_id iface_id } {
    return [getIfcType $node_id $iface_id]
}

#****f* nodecfg.tcl/setLogIfcType
# NAME
#   setLogIfcType -- set logical interface type
# SYNOPSIS
#   setLogIfcType $node_id $iface_id $type
# FUNCTION
#   Sets node's logical interface type.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
#   * type -- interface type
#****
proc setLogIfcType { node_id iface_id type } {
    setIfcType $node_id $iface_id $type
}

#****f* nodecfg.tcl/getIfcStolenIfc
# NAME
#   getIfcStolenIfc -- get logical interface type
# SYNOPSIS
#   getIfcStolenIfc $node_id $iface_id
# FUNCTION
#   Returns logical interface type from a node.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
#****
proc getIfcStolenIfc { node_id iface_id } {
}

#****f* nodecfg.tcl/setIfcStolenIfc
# NAME
#   setIfcStolenIfc -- set interface stolen interface
# SYNOPSIS
#   setIfcStolenIfc $node_id $iface_id $stolen_iface
# FUNCTION
#   Sets node's interface stolen stolen interface.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
#   * stolen_iface -- stolen interface
#****
proc setIfcStolenIfc { node_id iface_id stolen_iface } {
}

#****f* nodecfg.tcl/getIfcIPv6addrs
# NAME
#   getIfcIPv6addrs -- get interface IPv6 addresses.
# SYNOPSIS
#   set addrs [getIfcIPv6addrs $node_id $iface_id]
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
    set addrlist {}
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lrange $line 0 1] == "ipv6 address" } {
	    lappend addrlist [lindex $line 2]
	}
    }

    return $addrlist
}

#****f* nodecfg.tcl/setIfcIPv6addrs
# NAME
#   setIfcIPv6addrs -- set interface IPv6 addresses.
# SYNOPSIS
#   setIfcIPv6addrs $node_id $iface_id $addrs
# FUNCTION
#   Sets new IPv6 address(es) on an interface. The correctness of the IP
#   address format is not checked / enforced.
# INPUTS
#   * node_id -- the node id of the node whose interface's IPv6 address is set.
#   * iface_id -- interface id
#   * addrs -- new IPv6 addresses.
#****
proc setIfcIPv6addrs { node_id iface_id addrs } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lrange $line 0 1] != "ipv6 address" } {
	    lappend ifcfg $line
	}
    }

    foreach addr $addrs {
	if { $addr != "" } {
	    set addr [string trim $addr]
	    lappend ifcfg " ipv6 address $addr"
	}
    }

    netconfInsertSection $node_id $ifcfg
}

#****f* nodecfg.tcl/getIfcPeer
# NAME
#   getIfcPeer -- get node's peer by interface.
# SYNOPSIS
#   set peer_id [getIfcPeer $node_id $iface_id]
# FUNCTION
#   Returns id of the node on the other side of the interface. If the node on
#   the other side of the interface is situated on the other canvas or
#   connected via split link, this function returns a pseudo node.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
# RESULT
#   * peer_id -- node id of the node on the other side of the interface
#****
proc getIfcPeer { node_id iface_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set entry [lsearch -inline [set $node_id] "interface-peer {$iface_id *}"]

    return [lindex [lindex $entry 1] 1]
}

#****f* linkcfg.tcl/getIfcLink
# NAME
#   getIfcLink -- get link by interface
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
    upvar 0 ::cf::[set ::curcfg]::link_list link_list

    set peer_id [getIfcPeer $node_id $iface_id]
    if { $peer_id == "" } {
	return
    }

    foreach link_id $link_list {
	set endpoints [getLinkPeers $link_id]
	if { $endpoints in "{$node_id $peer_id} {$peer_id $node_id}" } {
	    break
	}
    }

    return $link_id
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
}

#****f* nodecfg.tcl/getIfcLinkLocalIPv6addr
# NAME
#   getIfcLinkLocalIPv6addr -- get interface link-local IPv6 address.
# SYNOPSIS
#   set addr [getIfcLinkLocalIPv6addr $node_id $iface_id]
# FUNCTION
#   Returns link-local IPv6 addresses that is calculated from the interface
#   MAC address. This can be done only for physical interfaces, or interfaces
#   with a MAC address assigned.
# INPUTS
#   * node_id -- the node id of the node whose link-local IPv6 address is returned.
#   * iface_id -- interface id.
# RESULT
#   * addr -- The link-local IPv6 address that will be assigned to the
#     specified interface.
#****
proc getIfcLinkLocalIPv6addr { node_id iface_id } {
    if { [isIfcLogical $node_id $iface_id] } {
	return ""
    }

    set mac [getIfcMACaddr $node_id $iface_id]

    set bytes [split $mac :]
    set bytes [linsert $bytes 3 fe]
    set bytes [linsert $bytes 3 ff]

    set first [expr 0x[lindex $bytes 0]]
    set xored [expr $first^2]
    set result [format %02x $xored]

    set bytes [lreplace $bytes 0 0 $result]

    set i 0
    lappend final fe80::
    foreach b $bytes {
	lappend final $b
	if { [expr $i%2] == 1 && $i < 7 } {
	    lappend final :
	}
	incr i
    }
    lappend final /64

    return [ip::normalize [join $final ""]]
}

#****f* nodecfg.tcl/ifcList
# NAME
#   ifcList -- get list of all interfaces
# SYNOPSIS
#   set ifcs [ifcList $node_id]
# FUNCTION
#   Returns a list of all interfaces present in a node.
# INPUTS
#   * node_id -- node id
# RESULT
#   * interfaces -- list of all node's interfaces
#****
proc ifcList { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set interfaces ""
    foreach entry [lsearch -all -inline [set $node_id] "interface-peer *"] {
	lappend interfaces [lindex [lindex $entry 1] 0]
    }

    return $interfaces
}

proc ifaceNames { node_id } {
    return [ifcList $node_id]
}

proc getIfacesByType { node_id args } {
    set all_ifaces [allIfcList $node_id]
    if { $all_ifaces == {} } {
	return
    }

    set iface_ids {}
    foreach type $args {
	foreach iface_id $all_ifaces {
	    if { [getIfcType $node_id $iface_id] == $type } {
		lappend iface_ids $iface_id
	    }
	}
    }

    return $iface_ids
}

proc getIfaceNamesByType { node_id args } {
    set filtered_ifaces [getIfacesByType $node_id {*}$args]

    set iface_names {}
    foreach iface_id $filtered_ifaces {
	lappend iface_names [getIfcName $node_id $iface_id]
    }

    return $iface_names
}

#****f* nodecfg.tcl/logIfcList
# NAME
#   logIfcList -- logical interfaces list
# SYNOPSIS
#   logIfcList $node_id
# FUNCTION
#   Returns the list of all the node's logical interfaces.
# INPUTS
#   * node_id -- node id
# RESULT
#   * interfaces -- list of node's logical interfaces
#****
proc logIfcList { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set interfaces ""
    set netconf [lindex [lsearch -inline [set $node_id] "network-config *"] 1]
    foreach line $netconf {
	if { "interface" in $line } {
	    set iface_id [lindex $line 1]
	    if { $iface_id ni [ifcList $node_id] } {
		lappend interfaces $iface_id
	    }
	}
    }

    return $interfaces
}

proc logIfaceNames { node_id } {
    return [logIfcList $node_id]
}

#****f* nodecfg.tcl/isIfcLogical
# NAME
#   isIfcLogical -- is given interface logical
# SYNOPSIS
#   isIfcLogical $node_id $iface_id
# FUNCTION
#   Returns true or false whether the node's interface is logical or not.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
# RESULT
#   * check -- true if the interface is logical, otherwise false.
#****
proc isIfcLogical { node_id iface_id } {
    if { $iface_id in [logIfcList $node_id] } {
	return true
    }

    return false
}

#****f* nodecfg.tcl/allIfcList
# NAME
#   allIfcList -- all interfaces list
# SYNOPSIS
#   allIfcList $node_id
# FUNCTION
#   Returns the list of all node's interfaces.
# INPUTS
#   * node_id -- node id
# RESULT
#   * interfaces -- list of node's interfaces
#****
proc allIfcList { node_id } {
    return [concat [logIfcList $node_id] [ifcList $node_id]]
}

#****f* nodecfg.tcl/logicalPeerByIfc
# NAME
#   logicalPeerByIfc -- get node's peer by interface.
# SYNOPSIS
#   set peer_id [logicalPeerByIfc $node_id $iface_id]
# FUNCTION
#   Returns id of the node on the other side of the interface. If the node on
#   the other side of the interface is connected via normal link (not split)
#   this function acts the same as the function getIfcPeer, but if the nodes
#   are connected via split links or situated on different canvases this
#   function returns the logical peer node.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
# RESULT
#   * peer_id -- node id of the node on the other side of the interface
#****
proc logicalPeerByIfc { node_id iface_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set peer_id [getIfcPeer $node_id $iface_id]
    if { $peer_id == "" } {
	return
    }

    if { [getNodeType $peer_id] == "pseudo" } {
	set node_id [getNodeMirror $peer_id]
	set peer_id [getIfcPeer $node_id "0"]
	set peer_iface_id [ifcByPeer $peer_id $node_id]
    } else {
	set peer_iface_id ""
	foreach link_id [linksByPeers $node_id $peer_id] {
	    set ifaces [getLinkPeersIfaces $link_id]

	    set peer_idx [lsearch -exact [getLinkPeers $link_id] $node_id]
	    set my_ifc [lindex $ifaces $peer_idx]
	    if { $iface_id == $my_ifc } {
		set peer_iface_id [removeFromList $ifaces $iface_id "keep_doubles"]
		break
	    }
	}
    }

    return "$peer_id $peer_iface_id"
}

#****f* nodecfg.tcl/ifcByPeer
# NAME
#   ifcByPeer -- get node interface by peer.
# SYNOPSIS
#   set iface_id [getIfcPeer $node_id $peer_id]
# FUNCTION
#   Returns the name of the interface connected to the specified peer. If the
#   peer node is on different canvas or connected via split link to the
#   specified node this function returns an empty string.
# INPUTS
#   * node_id -- node id
#   * peer_id -- id of the peer node
# RESULT
#   * iface_id -- interface id
#****
proc ifcByPeer { node_id peer_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set entry [lsearch -inline [set $node_id] "interface-peer {* $peer_id}"]

    return [lindex [lindex $entry 1] 0]
}

#****f* nodecfg.tcl/hasIPv4Addr
# NAME
#   hasIPv4Addr -- has IPv4 address.
# SYNOPSIS
#   set check [hasIPv4Addr $node_id]
# FUNCTION
#   Returns true if at least one interface has an IPv4 address configured,
#   otherwise returns false.
# INPUTS
#   * node_id -- node id
# RESULT
#   * check -- true if at least one interface has an IPv4 address, otherwise
#     false.
#****
proc hasIPv4Addr { node_id } {
    foreach iface_id [ifcList $node_id] {
	if { [getIfcIPv4addrs $node_id $iface_id] != {} } {
	    return true
	}
    }

    return false
}

#****f* nodecfg.tcl/hasIPv6Addr
# NAME
#   hasIPv6Addr -- has IPv6 address.
# SYNOPSIS
#   set check [hasIPv6Addr $node_id]
# FUNCTION
#   Retruns true if at least one interface has an IPv6 address configured,
#   otherwise returns false.
# INPUTS
#   * node_id -- node id
# RESULT
#   * check -- true if at least one interface has an IPv6 address, otherwise
#     false.
#****
proc hasIPv6Addr { node_id } {
    foreach iface_id [ifcList $node_id] {
	if { [getIfcIPv6addrs $node_id $iface_id] != {} } {
	    return true
	}
    }

    return false
}

#****f* nodecfg.tcl/getIfcVlanDev
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
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "vlan-dev" } {
	    return [lindex $line 1]
	}
    }
}

#****f* nodecfg.tcl/setIfcVlanDev
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
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "vlan-dev" } {
	    lappend ifcfg $line
	}
    }

    if { $dev in [ifcList $node_id] } {
	lappend ifcfg " vlan-dev $dev"
    }

    netconfInsertSection $node_id $ifcfg
}

#****f* nodecfg.tcl/getIfcVlanTag
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
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "vlan-tag" } {
	    return [lindex $line 1]
	}
    }
}

#****f* nodecfg.tcl/setIfcVlanTag
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
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "vlan-tag" } {
	    lappend ifcfg $line
	}
    }

    if { $tag >= 1 && $tag <= 4094 } {
	lappend ifcfg " vlan-tag $tag"
    }

    netconfInsertSection $node_id $ifcfg
}

#****f* nodecfg.tcl/nodeCfggenIfcIPv4
# NAME
#   nodeCfggenIfcIPv4 -- generate interface IPv4 configuration
# SYNOPSIS
#   nodeCfggenIfcIPv4 $node_id
# FUNCTION
#   Generate configuration for all IPv4 addresses on all node
#   interfaces.
# INPUTS
#   * node_id -- node to generate configuration for
# RESULT
#   * value -- interface IPv4 configuration script
#****
proc nodeCfggenIfcIPv4 { node_id iface_id } {
    set cfg {}
    set primary 1
    foreach addr [getIfcIPv4addrs $node_id $iface_id] {
	lappend cfg [getIPv4IfcCmd [getIfcName $node_id $iface_id] $addr $primary]
	set primary 0
    }

    return $cfg
}

#****f* nodecfg.tcl/nodeCfggenIfcIPv6
# NAME
#   nodeCfggenIfcIPv6 -- generate interface IPv6 configuration
# SYNOPSIS
#   nodeCfggenIfcIPv6 $node_id
# FUNCTION
#   Generate configuration for all IPv6 addresses on all node
#   interfaces.
# INPUTS
#   * node_id -- node to generate configuration for
# RESULT
#   * value -- interface IPv6 configuration script
#****
proc nodeCfggenIfcIPv6 { node_id iface_id } {
    set cfg {}
    set primary 1
    foreach addr [getIfcIPv6addrs $node_id $iface_id] {
	lappend cfg [getIPv6IfcCmd [getIfcName $node_id $iface_id] $addr $primary]
	set primary 0
    }

    return $cfg
}

#****f* nodecfg.tcl/newIface
# NAME
#   newIface -- new interface
# SYNOPSIS
#   set iface_id [newIface $type $node_id]
# FUNCTION
#   Returns the first available name for a new interface of the specified type.
# INPUTS
#   * node_id -- node id
#   * type -- interface type
#   * auto_config -- enable auto iface configuration
#   * stolen_iface -- if stolen, interface name
# RESULT
#   * iface_id -- the first available name for a interface of the specified type
#****
proc newIface { node_id iface_type auto_config { stolen_iface "" } } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set iface_id [chooseIfName $node_id $node_id]

    setNodeIface $node_id $iface_id ""
    lappend $node_id "interface-peer {$iface_id \"\"}"

    if { $auto_config } {
	set node_type [getNodeType $node_id]
	$node_type.confNewIfc $node_id $iface_id
    }

    return $iface_id
}

#****f* nodecfg.tcl/newLogIface
# NAME
#   newLogIface -- new logical interface
# SYNOPSIS
#   newLogIface $type $node_id
# FUNCTION
#   Returns the first available name for a new logical interface of the
#   specified type.
# INPUTS
#   * type -- interface type
#   * node_id -- node id
#****
proc newLogIface { type node_id } {
    for { set id 0 } { [lsearch -exact [logIfcList $node_id] $type$id] >= 0 } { incr id } {}

    return $type$id
}

proc removeIface { node_id iface_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id
    upvar 0 ::cf::[set ::curcfg]::IPv4UsedList IPv4UsedList
    upvar 0 ::cf::[set ::curcfg]::IPv6UsedList IPv6UsedList
    upvar 0 ::cf::[set ::curcfg]::MACUsedList MACUsedList

    set link_id [getIfcLink $node_id $iface_id]
    if { $link_id != "" } {
	removeLink $link_id 1
    }

    set IPv4UsedList [removeFromList $IPv4UsedList [getIfcIPv4addrs $node_id $iface_id] "keep_doubles"]
    set IPv6UsedList [removeFromList $IPv6UsedList [getIfcIPv6addrs $node_id $iface_id] "keep_doubles"]
    set MACUsedList [removeFromList $MACUsedList [getIfcMACaddr $node_id $iface_id] "keep_doubles"]

    netconfClearSection $node_id "interface $iface_id"
    set idx [lsearch [set $node_id] "interface-peer \{$iface_id *"]
    set $node_id [lreplace [set $node_id] $idx $idx]

    foreach lifc [logIfcList $node_id] {
	switch -exact [getLogIfcType $node_id $lifc] {
	    vlan {
		if { [getIfcVlanDev $node_id $lifc] == $iface_id } {
		    netconfClearSection $node_id "interface $lifc"
		}
	    }
	}
    }
}

proc nodeCfggenIfc { node_id iface_id } {
    global isOSlinux

    set cfg {}

    set iface_name [getIfcName $node_id $iface_id]

    set mac_addr [getIfcMACaddr $node_id $iface_id]
    if { $mac_addr != "" } {
	lappend cfg [getMacIfcCmd $iface_name $mac_addr]
    }

    set mtu [getIfcMTU $node_id $iface_id]
    lappend cfg [getMtuIfcCmd $iface_name $mtu]

    if { [getIfcNatState $node_id $iface_id] == "on" } {
	lappend cfg [getNatIfcCmd $iface_name]
    }

    set primary 1
    set addrs [getIfcIPv4addrs $node_id $iface_id]
    foreach addr $addrs {
	if { $addr != "" } {
	    lappend cfg [getIPv4IfcCmd $iface_name $addr $primary]
	    set primary 0
	}
    }

    set primary 1
    set addrs [getIfcIPv6addrs $node_id $iface_id]
    if { $isOSlinux } {
	# Linux is prioritizing IPv6 addresses in reversed order
	set addrs [lreverse $addrs]
    }
    foreach addr $addrs {
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

proc nodeUncfggenIfc { node_id iface_id } {
    set cfg {}

    set iface_name [getIfcName $node_id $iface_id]

    set addrs [getIfcIPv4addrs $node_id $iface_id]
    foreach addr $addrs {
        if { $addr != "" } {
            lappend cfg [getDelIPv4IfcCmd $iface_name $addr]
        }
    }

    set addrs [getIfcIPv6addrs $node_id $iface_id]
    foreach addr $addrs {
        if { $addr != "" } {
            lappend cfg [getDelIPv6IfcCmd $iface_name $addr]
        }
    }

    return $cfg
}

proc routerCfggenIfc { node_id iface_id } {
    set ospf_enabled [getNodeProtocol $node_id "ospf"]
    set ospf6_enabled [getNodeProtocol $node_id "ospf6"]

    set cfg {}

    set model [getNodeModel $node_id]
    set iface_name [getIfcName $node_id $iface_id]
    if { $iface_name == "lo0" } {
	set model "static"
    }

    switch -exact -- $model {
	"quagga" -
	"frr" {
	    set mac_addr [getIfcMACaddr $node_id $iface_id]
	    if { $mac_addr != "" } {
		lappend cfg [getMacIfcCmd $iface_name $mac_addr]
	    }

	    set mtu [getIfcMTU $node_id $iface_id]
	    lappend cfg [getMtuIfcCmd $iface_name $mtu]

	    if { [getIfcNatState $node_id $iface_id] == "on" } {
		lappend cfg [getNatIfcCmd $iface_name]
	    }

	    lappend cfg "vtysh << __EOF__"
	    lappend cfg "conf term"
	    lappend cfg "interface $iface_name"

	    set addrs [getIfcIPv4addrs $node_id $iface_id]
	    foreach addr $addrs {
		if { $addr != "" } {
		    lappend cfg " ip address $addr"
		}
	    }

	    if { $ospf_enabled } {
		if { ! [isIfcLogical $node_id $iface_id] } {
		    lappend cfg " ip ospf area 0.0.0.0"
		}
	    }

	    set addrs [getIfcIPv6addrs $node_id $iface_id]
	    foreach addr $addrs {
		if { $addr != "" } {
		    lappend cfg " ipv6 address $addr"
		}
	    }

	    if { $model == "frr" && $ospf6_enabled } {
		if { ! [isIfcLogical $node_id $iface_id] } {
		    lappend cfg " ipv6 ospf6 area 0.0.0.0"
		}
	    }

	    if { [getIfcOperState $node_id $iface_id] == "down" } {
		lappend cfg " shutdown"
	    } else {
		lappend cfg " no shutdown"
	    }

	    lappend cfg "!"
	    lappend cfg "__EOF__"
	}
	"static" {
	    set cfg [concat $cfg [nodeCfggenIfc $node_id $iface_id]]
	}
    }

    return $cfg
}

proc routerUncfggenIfc { node_id iface_id } {
    set ospf_enabled [getNodeProtocol $node_id "ospf"]
    set ospf6_enabled [getNodeProtocol $node_id "ospf6"]

    set cfg {}

    set model [getNodeModel $node_id]
    set iface_name [getIfcName $node_id $iface_id]
    if { $iface_name == "lo0" } {
	set model "static"
    }

    switch -exact -- $model {
	"quagga" -
	"frr" {
	    lappend cfg "vtysh << __EOF__"
	    lappend cfg "conf term"
	    lappend cfg "interface $iface_name"

	    set addrs [getIfcIPv4addrs $node_id $iface_id]
	    foreach addr $addrs {
		if { $addr != "" } {
		    lappend cfg " no ip address $addr"
		}
	    }

	    if { $ospf_enabled } {
		if { ! [isIfcLogical $node_id $iface_id] } {
		    lappend cfg " no ip ospf area 0.0.0.0"
		}
	    }

	    set addrs [getIfcIPv6addrs $node_id $iface_id]
	    foreach addr $addrs {
		if { $addr != "" } {
		    lappend cfg " no ipv6 address $addr"
		}
	    }

	    if { $model == "frr" && $ospf6_enabled } {
		if { ! [isIfcLogical $node_id $iface_id] } {
		    lappend cfg " no ipv6 ospf6 area 0.0.0.0"
		}
	    }

	    lappend cfg " shutdown"

	    lappend cfg "!"
	    lappend cfg "__EOF__"
	}
	"static" {
	    set cfg [concat $cfg [nodeUncfggenIfc $node_id $iface_id]]
	}
    }

    return $cfg
}
