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

# $Id: nodecfg.tcl 149 2015-03-27 15:50:14Z valter $


#****h* imunes/nodecfg.tcl
# NAME
#  nodecfg.tcl -- file used for manipultaion with nodes in IMUNES
# FUNCTION
#  This module is used to define all the actions used for configuring 
#  nodes in IMUNES. The definition of nodes is presented in NOTES
#  section.
#
# NOTES
#  The IMUNES configuration file contains declarations of IMUNES objects.
#  Each object declaration contains exactly the following three fields:
#
#     object_class object_id class_specific_config_string
#
#  Currently only two object classes are supported: node and link. In the
#  future we plan to implement a canvas object, which should allow placing
#  other objects into multiple visual maps.
#
#  "node" objects are further divided by their type, which can be one of
#  the following:
#  * router
#  * host
#  * pc
#  * click_l2
#  * click_l3
#  * lanswitch
#  * hub
#  * rj45
#  * pseudo
#
#  The following node types are to be implemented in the future:
#  * frswitch
#  * text
#  * image
#
#
# Routines for manipulation of per-node network configuration files
# IMUNES keeps per-node network configuration in an IOS / Zebra / Quagga
# style format.
#
# Network configuration is embedded in each node's config section via the
# "network-config" statement. The following functions can be used to
# manipulate the per-node network config:
#
# netconfFetchSection { node_id sectionhead }
#	Returns a section of a config file starting with the $sectionhead
#	line, and ending with the first occurence of the "!" sign.
#
# netconfClearSection { node_id sectionhead }
#	Removes the appropriate section from the config.
#
# netconfInsertSection { node_id section }
#	Inserts a section in the config file. Sections beginning with the
#	"interface" keyword are inserted at the head of the config, and
#	all other sequences are simply appended to the config tail.
#
# getIfcOperState { node_id ifc }
#	Returns "up" or "down".
#
# setIfcOperState { node_id ifc state }
#	Sets the new interface state. Implicit default is "up".
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
# setIfcIPv4addr { node_id ifc addr }
#	Sets a new IPv4 address(es) on an interface. The correctness of the
#	IP address format is not checked / enforced.
#
# getIfcIPv6addr { node_id ifc }
#	Returns a list of all IPv6 addresses assigned to an interface.
#
# setIfcIPv6addr { node_id ifc addr }
#	Sets a new IPv6 address(es) on an interface. The correctness of the
#	IP address format is not checked / enforced.
#
# getStatIPv4routes { node_id }
#	Returns a list of all static IPv4 routes as a list of
#	{destination gateway {metric}} pairs.
#
# setStatIPv4routes { node_id route_list }
#	Replace all current static route entries with a new one, in form of
#	a list, as described above.
#
# getStatIPv6routes { node_id }
#	Returns a list of all static IPv6 routes as a list of
#	{destination gateway {metric}} pairs.
#
# setStatIPv6routes { node_id route_list }
#	Replace all current static route entries with a new one, in form of
#	a list, as described above.
#
# getNodeName { node_id }
#	Returns node's logical name.
#
# setNodeName { node_id name }
#	Sets a new node's logical name.
#
# nodeType { node_id }
#	Returns node's type.
#
# getNodeModel { node_id }
#	Returns node's optional model identifier.
#
# setNodeModel { node_id model }
#	Sets the node's optional model identifier.
#
# getNodeCanvas { node_id }
#	Returns node's canvas affinity.
#
# setNodeCanvas { node_id canvas_id }
#	Sets the node's canvas affinity.
#
# getNodeCoords { node_id }
#	Return icon coords.
#
# setNodeCoords { node_id coords }
#	Sets the coordinates.
#
# getNodeSnapshot { node_id }
#	Return node's snapshot name.
#
# setNodeSnapshot { node_id coords }
#	Sets node's snapshot name.
#
# getSTPEnabled { node_id }
#	Returns true if STP is enabled.
#
# setSTPEnabled { node_id state }
#	Sets STP state.
#
# getNodeLabelCoords { node_id }
#	Return node label coordinates.
#
# setNodeLabelCoords { node_id coords }
#	Sets the label coordinates.
#
# getNodeCPUConf { node_id }
#	Returns node's CPU scheduling parameters { minp maxp weight }.
#
# setNodeCPUConf { node_id param_list }
#	Sets the node's CPU scheduling parameters.
#
# ifcList { node_id }
#	Returns a list of all interfaces present in a node.
#
# peerByIfc { node_id ifc }
#	Returns id of the node on the other side of the interface
#
# logicalPeerByIfc { node_id ifc }
#	Returns id of the logical node on the other side of the interface.
#
# ifcByPeer { local_node_id peer_node_id }
#	Returns the name of the interface connected to the specified peer 
#       if the peer is on the same canvas, otherwise returns an empty string.
#
# ifcByLogicalPeer { local_node_id peer_node_id }
#	Returns the name of the interface connected to the specified peer.
#	Returns the right interface even if the peer node is on the other
#	canvas.
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
# All of the above functions are independent to any Tk objects. This means
# they can be used for implementing tasks external to GUI, so inside the
# GUI any updating of related Tk objects (such as text labels etc.) will
# have to be implemented by additional Tk code.
#
# Additionally, an alternative configuration can be specified in 
# "custom-config" section.
#
# getCustomEnabled { node }
#
# setCustomEnabled { node state }
#
# getCustomConfigSelected { node }
#
# setCustomConfigSelected { node conf }
#
# getCustomConfig { node id }
#
# setCustomConfig { node id cmd config }
#
# removeCustomConfig { node id }
#
# getCustomConfigCommand { node id }
#
# getCustomConfigIDs { node }
#
#****

#****f* nodecfg.tcl/typemodel
# NAME
#   typemodel -- find node's type and routing model 
# SYNOPSIS
#   set typemod [typemodel $node]
# FUNCTION
#   For input node this procedure returns the node's type and routing model
#   (if exists) 
# INPUTS
#   * node -- node id
# RESULT
#   * typemod -- returns node's type and routing model in form type.model
#****
proc typemodel { node } {
    set type [nodeType $node]
    set model [getNodeModel $node]
    if { $model != {} } {
	return $type.$model
    } else {

	return $type
       
    }
}

#****f* nodecfg.tcl/getCustomEnabled
# NAME
#   getCustomEnabled -- get custom configuration enabled state 
# SYNOPSIS
#   set enabled [getCustomEnabled $node]
# FUNCTION
#   For input node this procedure returns true if custom configuration is
#   enabled for the specified node. 
# INPUTS
#   * node -- node id
# RESULT
#   * enabled -- returns true if custom configuration is enabled 
#****
proc getCustomEnabled { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    if { [lindex [lsearch -inline [set $node] "custom-enabled *"] 1] == true } {
	return true
    } else {
	return false
    }
}

#****f* nodecfg.tcl/setCustomEnabled
# NAME
#   setCustomEnabled -- set custom configuration enabled state 
# SYNOPSIS
#   setCustomEnabled $node $enabled
# FUNCTION
#   For input node this procedure enables or disables custom configuration.
# INPUTS
#   * node -- node id
#   * enabled -- true if enabling custom configuration, false if disabling 
#****
proc setCustomEnabled { node enabled } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set i [lsearch [set $node] "custom-enabled *"]
    if { $i >= 0 } {
	set $node [lreplace [set $node] $i $i]
    }
    if { $enabled == true } {
	lappend $node [list custom-enabled $enabled]
    }
}

#****f* nodecfg.tcl/getCustomConfigSelected
# NAME
#   getCustomConfigSelected -- get default custom configuration
# SYNOPSIS
#   getCustomConfigSelected $node
# FUNCTION
#   For input node this procedure returns ID of a default configuration
# INPUTS
#   * node -- node id
# RESULT
#   * ID -- returns default custom configuration ID
#****
proc getCustomConfigSelected { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node
    return [lindex [lsearch -inline [set $node] "custom-selected *"] 1]
}

#****f* nodecfg.tcl/setCustomConfigSelected
# NAME
#   setCustomConfigSelected -- set default custom configuration
# SYNOPSIS
#   setCustomConfigSelected $node
# FUNCTION
#   For input node this procedure sets ID of a default configuration
# INPUTS
#   * node -- node id
#   * conf -- custom-config id
#****
proc setCustomConfigSelected { node conf } {
    upvar 0 ::cf::[set ::curcfg]::$node $node
    set i [lsearch [set $node] "custom-selected *"]
    if { $i >= 0 } {
	set $node [lreplace [set $node] $i $i]
    }
    lappend $node [list custom-selected $conf]
}

#****f* nodecfg.tcl/getCustomConfig
# NAME
#   getCustomConfig -- get custom configuration 
# SYNOPSIS
#   getCustomConfig $node $id
# FUNCTION
#   For input node and configuration ID this procedure returns custom
#   configuration.
# INPUTS
#   * node -- node id
#   * id -- configuration id
# RESULT
#   * customConfig -- returns custom configuration  
#****
proc getCustomConfig { node id } {
    upvar 0 ::cf::[set ::curcfg]::$node $node
    set customCfgsList {}
    set customCfgsList [lsearch -inline [set $node] "custom-configs *"]
    set customCfg [lsearch -inline [lindex $customCfgsList 1] "custom-config-id $id *"]
    set customConfig [lsearch [lindex $customCfg 2] "config*"]
    set customConfig [lindex [lindex $customCfg 2] $customConfig+1]

    return $customConfig
}

#****f* nodecfg.tcl/setCustomConfig
# NAME
#   setCustomConfig -- set custom configuration 
# SYNOPSIS
#   setCustomConfig $node $id $cmd $config
# FUNCTION
#   For input node this procedure sets custom configuration section in input
#   node.
# INPUTS
#   * node -- node id
#   * id -- custom-config id
#   * cmd -- custom command
#   * config -- custom configuration section  
#****
proc setCustomConfig { node id cmd config } {
    upvar 0 ::cf::[set ::curcfg]::$node $node
    if {$id in [getCustomConfigIDs $node] } {
	removeCustomConfig $node $id
    }
    set customCfg [list custom-config-id $id]
    set customCfg2 [list custom-command $cmd config]
    set cfg ""
    foreach zline [split $config {
}] {
	lappend cfg $zline
    }
    lappend customCfg2 $cfg

    lappend customCfg $customCfg2
    
    if {[lsearch [set $node] "custom-configs *"] != -1} {
	set customCfgsList [lsearch -inline [set $node] "custom-configs *"]
	set customCfgs [lindex $customCfgsList 1]
	lappend customCfgs $customCfg
	set customCfgsList [lreplace $customCfgsList 1 1 $customCfgs]
	set idx1 [lsearch [set $node] "custom-configs *"]
	set $node [lreplace [set $node] $idx1 $idx1 $customCfgsList]
    } else {
	set customCfgsList [list custom-configs]
	lappend customCfgsList [list $customCfg]
	set $node [linsert [set $node] end $customCfgsList]
    }
}

#****f* nodecfg.tcl/removeCustomConfig
# NAME
#   removeCustomConfig -- remove custom configuration 
# SYNOPSIS
#   removeCustomConfig $node $id
# FUNCTION
#   For input node and configuration ID this procedure removes custom
#   configuration from node.
# INPUTS
#   * node -- node id
#   * id -- configuration id
#****
proc removeCustomConfig { node id } {
    upvar 0 ::cf::[set ::curcfg]::$node $node
    set customCfgsList [lsearch -inline [set $node] "custom-configs *"]
    set idx [lsearch [lindex $customCfgsList 1] "custom-config-id $id *"]
    set customCfgs [lreplace [lindex $customCfgsList 1] $idx $idx]
    set customCfgsList [lreplace $customCfgsList 1 1 $customCfgs]
    set idx1 [lsearch [set $node] "custom-configs *"]
    set $node [lreplace [set $node] $idx1 $idx1 $customCfgsList]
}

#****f* nodecfg.tcl/getCustomConfigCommand
# NAME
#   getCustomConfigCommand -- get custom configuration boot command
# SYNOPSIS
#   getCustomConfigCommand $node $id
# FUNCTION
#   For input node and configuration ID this procedure returns custom
#   configuration boot command.
# INPUTS
#   * node -- node id
#   * id -- configuration id
# RESULT
#   * customCmd -- returns custom configuration boot command
#****
proc getCustomConfigCommand { node id } {
    upvar 0 ::cf::[set ::curcfg]::$node $node
    set customCfgsList {}
    set customCfgsList [lsearch -inline [set $node] "custom-configs *"]
    set customCfg [lsearch -inline [lindex $customCfgsList 1] "custom-config-id $id *"]
    set customCmd [lsearch [lindex $customCfg 2] "custom-command*"]
    set customCmd [lindex [lindex $customCfg 2] $customCmd+1]
    
    return $customCmd
}

#****f* nodecfg.tcl/getCustomConfigIDs
# NAME
#   getCustomConfigIDs -- get custom configuration IDs
# SYNOPSIS
#   getCustomConfigIDs $node
# FUNCTION
#   For input node this procedure returns all custom configuration IDs.
# INPUTS
#   * node -- node id
# RESULT
#   * IDs -- returns custom configuration IDs
#****
proc getCustomConfigIDs { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node
    set customCfgsList [lsearch -inline [set $node] "custom-configs *"]
    set customCfg [lsearch -all -inline [lindex $customCfgsList 1] "custom-config-id *"]
    set IDs {}
    foreach x $customCfg {
	lappend IDs [lindex $x 1]
    }
    return $IDs
}

#****f* nodecfg.tcl/netconfFetchSection
# NAME
#   netconfFetchSection -- fetch the network configuration section 
# SYNOPSIS
#   set section [netconfFetchSection $node $sectionhead]
# FUNCTION
#   Returns a section of a network part of a configuration file starting with
#   the $sectionhead line, and ending with the first occurrence of the "!"
#   sign.
# INPUTS
#   * node -- node id
#   * sectionhead -- represents the first line of the section in 
#     network-config part of the configuration file
# RESULT
#   * section -- returns a part of the configuration file between sectionhead
#     and "!"
#****
proc netconfFetchSection { node sectionhead } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set cfgmode global
    set section {}
    set netconf [lindex [lsearch -inline [set $node] "network-config *"] 1]
    foreach line $netconf {
	if { $cfgmode == "section" } {
	    if { "$line" == "!" } {
		return $section
	    }
	    lappend section "$line"
	    continue
	}
	if { "$line" == "$sectionhead" } {
	    set cfgmode section
	}
    }
}

#****f* nodecfg.tcl/netconfClearSection
# NAME
#   netconfClearSection -- clear the section from a network-config part
# SYNOPSIS
#   netconfClearSection $node $sectionhead
# FUNCTION
#   Removes the appropriate section from the network part of the
#   configuration.
# INPUTS
#   * node -- node id
#   * sectionhead -- represents the first line of the section that is to be
#     removed from network-config part of the configuration.
#****
proc netconfClearSection { node sectionhead } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set i [lsearch [set $node] "network-config *"]
    set netconf [lindex [lindex [set $node] $i] 1]
    set lnum_beg -1
    set lnum_end 0
    foreach line $netconf {
	if { $lnum_beg == -1 && "$line" == "$sectionhead" } {
	    set lnum_beg $lnum_end
	}
	if { $lnum_beg > -1 && "$line" == "!" } {
	    set netconf [lreplace $netconf $lnum_beg $lnum_end]
	    set $node [lreplace [set $node] $i $i \
		[list network-config $netconf]]
	    return
	}
	incr lnum_end
    }
}

#****f* nodecfg.tcl/netconfInsertSection
# NAME
#   netconfInsertSection -- Insert the section to a network-config
#   part of configuration
# SYNOPSIS
#   netconfInsertSection $node $section
# FUNCTION
#   Inserts a section in the configuration. Sections beginning with the
#   "interface" keyword are inserted at the head of the configuration, and all
#   other sequences are simply appended to the configuration tail.
# INPUTS
#   * node -- the node id of the node whose config section is inserted
#   * section -- represents the section that is being inserted. If there was a
#     section in network configuration with the same section head, it is lost.
#****
proc netconfInsertSection { node section } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set sectionhead [lindex $section 0]
    netconfClearSection $node $sectionhead
    set i [lsearch [set $node] "network-config *"]
    set netconf [lindex [lindex [set $node] $i] 1]
    set lnum_beg end
    if { "[lindex $sectionhead 0]" == "interface" } {
	set lnum [lsearch $netconf "hostname *"]
	if { $lnum >= 0 } {
	    set lnum_beg [expr $lnum + 2]
	}
    } elseif { "[lindex $sectionhead 0]" == "hostname" } {
	set lnum_beg 0
    }
    if { "[lindex $section end]" != "!" } {
	lappend section "!"
    }
    foreach line $section {
	set netconf [linsert $netconf $lnum_beg $line]
	if { $lnum_beg != "end" } {
	    incr lnum_beg
	}
    }
    set $node [lreplace [set $node] $i $i [list network-config $netconf]]
}

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
proc getIfcOperState { node ifc } {
    foreach line [netconfFetchSection $node "interface $ifc"] {
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
proc setIfcOperState { node ifc state } {
    set ifcfg [list "interface $ifc"]
    if { $state == "down" } {
	lappend ifcfg " shutdown"
    }
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] != "shutdown" && \
	    [lrange $line 0 1] != "no shutdown" } {
	    lappend ifcfg $line
	}
    }
    netconfInsertSection $node $ifcfg
}

#****f* nodecfg.tcl/getIfcDirect
# NAME
#   getIfcDirect -- get interface queuing discipline
# SYNOPSIS
#   set direction [getIfcDirect $node $ifc]
# FUNCTION
#   Returns the direction of the specified interface. It can be set to 
#   "internal" or "external".
# INPUTS
#   * node -- represents the node id of the node whose interface's queuing
#     discipline is checked.
#   * ifc -- The interface name.
# RESULT
#   * direction -- the direction of the interface, can be either "internal" or
#     "external".
#****
proc getIfcDirect { node ifc } {
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] == "external" } {
	    return external
	}
    }
    return internal
}

#****f* nodecfg.tcl/setIfcDirect
# NAME
#   setIfcDirect -- set interface direction
# SYNOPSIS
#   setIfcDirect $node $ifc $direct
# FUNCTION
#   Sets the direction of the specified interface. It can be set to "internal"
#   or "external".
# INPUTS
#   * node -- node id
#   * ifc -- interface
#   * direct -- new direction of the interface, can be either "internal" or
#     "external"
#****
proc setIfcDirect { node ifc direct } {
    set ifcfg [list "interface $ifc"]
    if { $direct == "external" } {
	lappend ifcfg " external"

    }
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] != "external" && \
	    [lindex $line 0] != "internal" } {
	    lappend ifcfg $line
	}
    }
    netconfInsertSection $node $ifcfg    
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
proc getIfcQDisc { node ifc } {
    foreach line [netconfFetchSection $node "interface $ifc"] {
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
proc setIfcQDisc { node ifc qdisc } {
    set ifcfg [list "interface $ifc"]
    if { $qdisc == "WFQ" } {
	lappend ifcfg " fair-queue"
    }
    if { $qdisc == "DRR" } {
	lappend ifcfg " drr-queue"
    }
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] != "fair-queue" && \
	    [lindex $line 0] != "drr-queue" } {
	    lappend ifcfg $line
	}
    }
    netconfInsertSection $node $ifcfg
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
proc getIfcQDrop { node ifc } {
    foreach line [netconfFetchSection $node "interface $ifc"] {
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
proc setIfcQDrop { node ifc qdrop } {
    set ifcfg [list "interface $ifc"]
    if { $qdrop == "drop-head" } {
	lappend ifcfg " drop-head"

    }
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] != "drop-head" && \
	    [lindex $line 0] != "drop-tail" } {
	    lappend ifcfg $line
	}
    }
    netconfInsertSection $node $ifcfg
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
proc getIfcQLen { node ifc } {
    foreach line [netconfFetchSection $node "interface $ifc"] {
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
#   setIfcQLen $node $ifc $len
# FUNCTION
#   Sets the queue length limit.
# INPUTS
#   * node -- represents the node id of the node whose interface's queue
#     length is set.
#   * ifc -- interface name.
#   * qlen -- queue length limit represented in number of packets.
#****
proc setIfcQLen { node ifc len } {
    set ifcfg [list "interface $ifc"]
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] != "queue-len" } {
	    lappend ifcfg $line
	}
    }
    if { $len > 5 && $len != 50 } {
	lappend ifcfg " queue-len $len"
    }
    netconfInsertSection $node $ifcfg
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
proc getIfcMTU { node ifc } {
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] == "mtu" } {
	    return [lindex $line 1]
	}
    }
    # Return defaults
    switch -exact [string range $ifc 0 1] {
	lo { return 16384 }
	se { return 2044 }
    }
    return 1500
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
proc setIfcMTU { node ifc mtu } {
    set ifcfg [list "interface $ifc"]
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] != "mtu" } {
	    lappend ifcfg $line
	}
    }
#    switch -exact [string range $ifc 0 2] {
#	eth { set limit 1500 }
#	ser { set limit 2044 }
#    }
    set limit 9018
    if { $mtu >= 256 && $mtu <= $limit } {
	lappend ifcfg " mtu $mtu"
    }
    netconfInsertSection $node $ifcfg
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
proc getIfcMACaddr { node ifc } {
    set addr ""
    foreach line [netconfFetchSection $node "interface $ifc"] {
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
#   setIfcMACaddr $node $ifc $addr
# FUNCTION
#   Sets a new MAC address on an interface. The correctness of the MAC address
#   format is not checked / enforced.
# INPUTS
#   * node -- the node id of the node whose interface's MAC address is set.
#   * ifc -- interface name.
#   * addr -- new MAC address.
#****
proc setIfcMACaddr { node ifc addr } {
    set ifcfg [list "interface $ifc"]
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lrange $line 0 1] != "mac address" } {
	    lappend ifcfg $line
	}
    }
    if { $addr != "" } {
	lappend ifcfg " mac address $addr"
    }
    netconfInsertSection $node $ifcfg
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
proc getIfcIPv4addr { node ifc } {
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lrange $line 0 1] == "ip address" } {
	    return [lindex $line 2]
	}
    }
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
proc getIfcIPv4addrs { node ifc } {
    set addrlist {}
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lrange $line 0 1] == "ip address" } {
	    lappend addrlist [lindex $line 2]
	}
    }
    return $addrlist
}

#****f* nodecfg.tcl/getLogIfcType
# NAME
#   getLogIfcType -- get logical interface type
# SYNOPSIS
#   getLogIfcType $node $ifc
# FUNCTION
#   Returns logical interface type from a node.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
#****
proc getLogIfcType { node ifc } {
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] == "type" } {
	    return [lindex $line 1]
	}
    }
}

#****f* nodecfg.tcl/setIfcIPv4addr
# NAME
#   setIfcIPv4addr -- set interface IPv4 address.
# SYNOPSIS
#   setIfcIPv4addr $node $ifc $addr
# FUNCTION
#   Sets a new IPv4 address(es) on an interface. The correctness of the IP
#   address format is not checked / enforced.
# INPUTS
#   * node -- the node id of the node whose interface's IPv4 address is set.
#   * ifc -- interface name.
#   * addr -- new IPv4 address.
#****
proc setIfcIPv4addr { node ifc addr } {
    set ifcfg [list "interface $ifc"]
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lrange $line 0 1] != "ip address" } {
	    lappend ifcfg $line
	}
    }
    if { $addr != "" } {
	lappend ifcfg " ip address $addr"
    }
    netconfInsertSection $node $ifcfg
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
proc setIfcIPv4addrs { node ifc addrs } {
    set ifcfg [list "interface $ifc"]
    foreach line [netconfFetchSection $node "interface $ifc"] {
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
    netconfInsertSection $node $ifcfg
}

#****f* nodecfg.tcl/setLogIfcType
# NAME
#   setLogIfcType -- set logical interface type
# SYNOPSIS
#   setLogIfcType $node $ifc $type
# FUNCTION
#   Sets node's logical interface type.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
#   * type -- interface type
#****
proc setLogIfcType { node ifc type } {
    set ifcfg [list "interface $ifc"]
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] != "type" } {
	    lappend ifcfg $line
	}
    }
    if { $type != "" } {
	lappend ifcfg " type $type"
    }
    netconfInsertSection $node $ifcfg
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
proc getIfcIPv6addr { node ifc } {
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lrange $line 0 1] == "ipv6 address" } {
	    return [lindex $line 2]
	}
    }
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
proc getIfcIPv6addrs { node ifc } {
    set addrlist {}
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lrange $line 0 1] == "ipv6 address" } {
	    lappend addrlist [lindex $line 2]
	}
    }
    return $addrlist
}

#****f* nodecfg.tcl/setIfcIPv6addr
# NAME
#   setIfcIPv6addr -- set interface IPv6 address.
# SYNOPSIS
#   setIfcIPv6addr $node $ifc $addr
# FUNCTION
#   Sets a new IPv6 address(es) on an interface. The correctness of the IP
#   address format is not checked / enforced.
# INPUTS
#   * node -- the node id of the node whose interface's IPv4 address is set.
#   * ifc -- interface name.
#   * addr -- new IPv6 address.
#****
proc setIfcIPv6addr { node ifc addr } {
    set ifcfg [list "interface $ifc"]
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lrange $line 0 1] != "ipv6 address" } {
	    lappend ifcfg $line
	}
    }
    if { $addr != "" } {
	lappend ifcfg " ipv6 address $addr"
    }
    netconfInsertSection $node $ifcfg
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
proc setIfcIPv6addrs { node ifc addrs } {
    set ifcfg [list "interface $ifc"]
    foreach line [netconfFetchSection $node "interface $ifc"] {
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
    netconfInsertSection $node $ifcfg
}

#****f* nodecfg.tcl/getIfcLinkLocalIPv6addr
# NAME
#   getIfcLinkLocalIPv6addr -- get interface link-local IPv6 address.
# SYNOPSIS
#   set addr [getIfcLinkLocalIPv6addr $node $ifc]
# FUNCTION
#   Returns link-local IPv6 addresses that is calculated from the interface
#   MAC address. This can be done only for physical interfaces, or interfaces
#   with a MAC address assigned.
# INPUTS
#   * node -- the node id of the node whose link-local IPv6 address is returned.
#   * ifc -- interface name.
# RESULT
#   * addr -- The link-local IPv6 address that will be assigned to the
#     specified interface.
#****
proc getIfcLinkLocalIPv6addr { node ifc } {
    if { [isIfcLogical $node $ifc] } {
	return ""
    }

    set mac [getIfcMACaddr $node $ifc]

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

#****f* nodecfg.tcl/getStatIPv4routes
# NAME
#   getStatIPv4routes -- get static IPv4 routes.
# SYNOPSIS
#   set routes [getStatIPv4routes $node]
# FUNCTION
#   Returns a list of all static IPv4 routes as a list of
#   {destination gateway {metric}} pairs.
# INPUTS
#   * node -- node id
# RESULT
#   * routes -- list of all static routes defined for the specified node
#****
proc getStatIPv4routes { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set routes {}
    set netconf [lindex [lsearch -inline [set $node] "network-config *"] 1]
    foreach entry [lsearch -all -inline $netconf "ip route *"] {
	lappend routes [lrange $entry 2 end]
    }
    return $routes
}

#****f* nodecfg.tcl/setStatIPv4routes
# NAME
#   setStatIPv4routes -- set static IPv4 routes.
# SYNOPSIS
#   setStatIPv4routes $node $routes
# FUNCTION
#   Replace all current static route entries with a new one, in form of a list
#   of {destination gateway {metric}} pairs.
# INPUTS
#   * node -- the node id of the node whose static routes are set.
#   * routes -- list of all static routes defined for the specified node
#****
proc setStatIPv4routes { node routes } {
    netconfClearSection $node "ip route [lindex [getStatIPv4routes $node] 0]"
    set section {}
    foreach route $routes {
	lappend section "ip route $route"
    }
    netconfInsertSection $node $section
}

#****f* nodecfg.tcl/getStatIPv6routes
# NAME
#   getStatIPv6routes -- get static IPv6 routes.
# SYNOPSIS
#   set routes [getStatIPv6routes $node]
# FUNCTION
#   Returns a list of all static IPv6 routes as a list of
#   {destination gateway {metric}} pairs.
# INPUTS
#   * node -- node id
# RESULT
#   * routes -- list of all static routes defined for the specified node
#****
proc getStatIPv6routes { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set routes {}
    set netconf [lindex [lsearch -inline [set $node] "network-config *"] 1]
    foreach entry [lsearch -all -inline $netconf "ipv6 route *"] {
	lappend routes [lrange $entry 2 end]
    }
    return $routes
}

#****f* nodecfg.tcl/setStatIPv6routes
# NAME
#   setStatIPv4routes -- set static IPv6 routes.
# SYNOPSIS
#   setStatIPv6routes $node $routes
# FUNCTION
#   Replace all current static route entries with a new one, in form of a list
#   of {destination gateway {metric}} pairs.
# INPUTS
#   * node -- node id
#   * routes -- list of all static routes defined for the specified node
#****
proc setStatIPv6routes { node routes } {
    netconfClearSection $node "ipv6 route [lindex [getStatIPv6routes $node] 0]"
    set section {}
    foreach route $routes {
	lappend section "ipv6 route $route"
    }
    netconfInsertSection $node $section
}

#****f* nodecfg.tcl/getNodeName
# NAME
#   getNodeName -- get node name.
# SYNOPSIS
#   set name [getNodeName $node]
# FUNCTION
#   Returns node's logical name.
# INPUTS
#   * node -- node id
# RESULT
#   * name -- logical name of the node
#****
proc getNodeName { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set netconf [lindex [lsearch -inline [set $node] "network-config *"] 1]
    return [lrange [lsearch -inline $netconf "hostname *"] 1 end]
}

#****f* nodecfg.tcl/setNodeName
# NAME
#   setNodeName -- set node name.
# SYNOPSIS
#   setNodeName $node $name
# FUNCTION
#   Sets node's logical name.
# INPUTS
#   * node -- node id
#   * name -- logical name of the node
#****
proc setNodeName { node name } {
    netconfClearSection $node "hostname [getNodeName $node]"
    netconfInsertSection $node [list "hostname $name"]
}

#****f* nodecfg.tcl/getNodeType
# NAME
#   getNodeType -- get node type.
# SYNOPSIS
#   set type [getNodeType $node]
# FUNCTION
#   Returns node's type.
# INPUTS
#   * node -- node id
# RESULT
#   * type -- type of the node
#****
proc nodeType { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    return [lindex [lsearch -inline [set $node] "type *"] 1]
}

#****f* nodecfg.tcl/getNodeModel
# NAME
#   getNodeModel -- get node routing model.
# SYNOPSIS
#   set model [getNodeModel $node]
# FUNCTION
#   Returns node's optional routing model. Currently supported models are 
#   quagga, xorp and static and only nodes of type router have a defined model.
# INPUTS
#   * node -- node id
# RESULT
#   * model -- routing model of the specified node
#****
proc getNodeModel { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    return [lindex [lsearch -inline [set $node] "model *"] 1]
}

#****f* nodecfg.tcl/setNodeModel
# NAME
#   setNodeModel -- set node routing model.
# SYNOPSIS
#   setNodeModel $node $model
# FUNCTION
#   Sets an optional routing model to the node. Currently supported models are
#   quagga, xorp and static and only nodes of type router have a defined model.
# INPUTS
#   * node -- node id
#   * model -- routing model of the specified node
#****
proc setNodeModel { node model } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set i [lsearch [set $node] "model *"]
    if { $i >= 0 } {
	set $node [lreplace [set $node] $i $i "model $model"]
    } else {
	set $node [linsert [set $node] 1 "model $model"]
    }
}

#****f* nodecfg.tcl/getNodeSnapshot
# NAME
#   getNodeSnapshot -- get node snapshot image name.
# SYNOPSIS
#   set snapshot [getNodeSnapshot $node]
# FUNCTION
#   Returns node's snapshot name.
# INPUTS
#   * node -- node id
# RESULT
#   * snapshot -- snapshot name for the specified node
#****
proc getNodeSnapshot { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    return [lindex [lsearch -inline [set $node] "snapshot *"] 1]
}

#****f* nodecfg.tcl/setNodeSnapshot
# NAME
#   setNodeSnapshot -- set node snapshot image name.
# SYNOPSIS
#   setNodeSnapshot $node $snapshot
# FUNCTION
#   Sets node's snapshot name.
# INPUTS
#   * node -- node id
#   * snapshot -- snapshot name for the specified node
#****
proc setNodeSnapshot { node snapshot } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set i [lsearch [set $node] "snapshot *"]
    if { $i >= 0 } {
	set $node [lreplace [set $node] $i $i "snapshot $snapshot"]
    } else {
	set $node [linsert [set $node] 1 "snapshot $snapshot"]
    }
}

#****f* nodecfg.tcl/getStpEnabled
# NAME
#   getStpEnabled -- get STP enabled state 
# SYNOPSIS
#   set enabled [getStpEnabled $node]
# FUNCTION
#   For input node this procedure returns true if STP is enabled
#   for the specified node. 
# INPUTS
#   * node -- node id
# RESULT
#   * enabled -- returns true if STP is enabled
#****
proc getStpEnabled { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set netconf [lindex [lsearch -inline [set $node] "network-config *"] 1]
    if { [lrange [lsearch -inline $netconf "stp-enabled *"] 1 end] == true } {
	return true
    }
    return false
}

#****f* nodecfg.tcl/setStpEnabled
# NAME
#   setStpEnabled -- set STP enabled state 
# SYNOPSIS
#   setStpEnabled $node $enabled
# FUNCTION
#   For input node this procedure enables or disables STP.
# INPUTS
#   * node -- node id
#   * enabled -- true if enabling STP, false if disabling 
#****
proc setStpEnabled { node enabled } {
    netconfClearSection $node "stp-enabled true"
    if { $enabled == true } {
	netconfInsertSection $node [list "stp-enabled $enabled"]
    }
}

#****f* nodecfg.tcl/getNodeCoords
# NAME
#   getNodeCoords -- get node icon coordinates.
# SYNOPSIS
#   set coords [getNodeCoords $node]
# FUNCTION
#   Returns node's icon coordinates.
# INPUTS
#   * node -- node id
# RESULT
#   * coords -- coordinates of the node's icon in form of {Xcoord Ycoord}
#****
proc getNodeCoords { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    return [lindex [lsearch -inline [set $node] "iconcoords *"] 1]
}

#****f* nodecfg.tcl/setNodeCoords
# NAME
#   setNodeCoords -- set node's icon coordinates.
# SYNOPSIS
#   setNodeCoords $node $coords
# FUNCTION
#   Sets node's icon coordinates.
# INPUTS
#   * node -- node id
#   * coords -- coordinates of the node's icon in form of {Xcoord Ycoord}
#****
proc setNodeCoords { node coords } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    foreach c $coords {
	set x [expr round($c)]
	lappend roundcoords $x
    }

    set i [lsearch [set $node] "iconcoords *"]
    if { $i >= 0 } {
	set $node [lreplace [set $node] $i $i "iconcoords {$roundcoords}"]
    } else {
	set $node [linsert [set $node] end "iconcoords {$roundcoords}"]
    }
}

#****f* nodecfg.tcl/getNodeLabelCoords
# NAME
#   getNodeLabelCoords -- get node's label coordinates.
# SYNOPSIS
#   set coords [getNodeLabelCoords $node]
# FUNCTION
#   Returns node's label coordinates.
# INPUTS
#   * node -- node id
# RESULT
#   * coords -- coordinates of the node's label in form of {Xcoord Ycoord}
#****
proc getNodeLabelCoords { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    return [lindex [lsearch -inline [set $node] "labelcoords *"] 1]
}

#****f* nodecfg.tcl/setNodeLabelCoords
# NAME
#   setNodeLabelCoords -- set node's label coordinates.
# SYNOPSIS
#   setNodeLabelCoords $node $coords
# FUNCTION
#   Sets node's label coordinates.
# INPUTS
#   * node -- node id
#   * coords -- coordinates of the node's label in form of Xcoord Ycoord
#****
proc setNodeLabelCoords { node coords } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    foreach c $coords {
	set x [expr round($c)]
	lappend roundcoords $x
    }

    set i [lsearch [set $node] "labelcoords *"]
    if { $i >= 0 } {
	set $node [lreplace [set $node] $i $i "labelcoords {$roundcoords}"]
    } else {
	set $node [linsert [set $node] end "labelcoords {$roundcoords}"]
    }
}

#****f* nodecfg.tcl/getNodeCPUConf
# NAME
#   getNodeCPUConf -- get node's CPU configuration
# SYNOPSIS
#   set conf [getNodeCPUConf $node]
# FUNCTION
#   Returns node's CPU scheduling parameters { minp maxp weight }.
# INPUTS
#   * node -- node id
# RESULT
#   * conf -- node's CPU scheduling parameters { minp maxp weight }
#****
proc getNodeCPUConf { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    return [join [lrange [lsearch -inline [set $node] "cpu *"] 1 3]]
}

#****f* nodecfg.tcl/setNodeCPUConf
# NAME
#   setNodeCPUConf -- set node's CPU configuration
# SYNOPSIS
#   setNodeCPUConf $node $param_list
# FUNCTION
#   Sets the node's CPU scheduling parameters.
# INPUTS
#   * node -- node id
#   * param_list -- node's CPU scheduling parameters { minp maxp weight }
#****
proc setNodeCPUConf { node param_list } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set i [lsearch [set $node] "cpu *"]
    if { $i >= 0 } {
	if { $param_list != "{}" } {
	    set $node [lreplace [set $node] $i $i "cpu $param_list"]
	} else {
	    set $node [lreplace [set $node] $i $i]
	}
    } else {
	if { $param_list != "{}" } {
	    set $node [linsert [set $node] 1 "cpu $param_list"]
	}
    }
}

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
proc ifcList { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set interfaces ""
    foreach entry [lsearch -all -inline [set $node] "interface-peer *"] {
	lappend interfaces [lindex [lindex $entry 1] 0]
    }
    return $interfaces
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
proc logIfcList { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set interfaces ""
    set netconf [lindex [lsearch -inline [set $node] "network-config *"] 1]
    foreach line $netconf {
	if { "interface" in $line } {
	    set ifc [lindex $line 1]
	    if {$ifc ni [ifcList $node]} {
		lappend interfaces $ifc 
	    }
	}
    }
    return $interfaces
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
proc isIfcLogical { node ifc } {
    if { $ifc in [logIfcList $node] } {
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
proc allIfcList { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set interfaces [concat [ifcList $node] [logIfcList $node]]
    set lo0_pos [lsearch $interfaces lo0]
    if { $lo0_pos != -1 } {
	set interfaces "lo0 [lreplace $interfaces $lo0_pos $lo0_pos]"
    }
    return $interfaces
}

#****f* nodecfg.tcl/peerByIfc
# NAME
#   peerByIfc -- get node's peer by interface.
# SYNOPSIS
#   set peer [peerByIfc $node $ifc]
# FUNCTION
#   Returns id of the node on the other side of the interface. If the node on
#   the other side of the interface is situated on the other canvas or
#   connected via split link, this function returns a pseudo node.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
# RESULT
#   * peer -- node id of the node on the other side of the interface
#****
proc peerByIfc { node ifc } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set entry [lsearch -inline [set $node] "interface-peer {$ifc *}"]
    return [lindex [lindex $entry 1] 1]
}

#****f* nodecfg.tcl/logicalPeerByIfc
# NAME
#   logicalPeerByIfc -- get node's peer by interface.
# SYNOPSIS
#   set peer [logicalPeerByIfc $node $ifc]
# FUNCTION
#   Returns id of the node on the other side of the interface. If the node on
#   the other side of the interface is connected via normal link (not split)
#   this function acts the same as the function peerByIfc, but if the nodes
#   are connected via split links or situated on different canvases this
#   function returns the logical peer node.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
# RESULT
#   * peer -- node id of the node on the other side of the interface
#****
proc logicalPeerByIfc { node ifc } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set peer [peerByIfc $node $ifc]
    if { [nodeType $peer] != "pseudo" } {
	return $peer

    } else {
	set mirror_node [getNodeMirror $peer]
	set mirror_ifc [ifcList $mirror_node]
	return [peerByIfc $mirror_node $mirror_ifc]
    }
}

#****f* nodecfg.tcl/ifcByPeer
# NAME
#   ifcByPeer -- get node interface by peer.
# SYNOPSIS
#   set ifc [peerByIfc $node $peer]
# FUNCTION
#   Returns the name of the interface connected to the specified peer. If the
#   peer node is on different canvas or connected via split link to the
#   specified node this function returns an empty string.
# INPUTS
#   * node -- node id
#   * peer -- id of the peer node
# RESULT
#   * ifc -- interface name
#****
proc ifcByPeer { node peer } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set entry [lsearch -inline [set $node] "interface-peer {* $peer}"]
    return [lindex [lindex $entry 1] 0]
}

#****f* nodecfg.tcl/ifcByLogicalPeer
# NAME
#   ifcByPeer -- get node interface by peer.
# SYNOPSIS
#   set ifc [peerByIfc $node $peer]
# FUNCTION
#   Returns the name of the interface connected to the specified peer. Returns
#   the right interface even if the peer node is on the other canvas or
#   connected via split link.
# INPUTS
#   * node -- node id
#   * peer -- id of the peer node
# RESULT
#   * ifc -- interface name
#****
proc ifcByLogicalPeer { node peer } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set ifc [ifcByPeer $node $peer]
    if { $ifc == "" } {
	#
	# Must search through pseudo peers
	#
	foreach ifc [ifcList $node] {
	    set t_peer [peerByIfc $node $ifc]
	    if { [nodeType $t_peer] == "pseudo" } {
		set mirror [getNodeMirror $t_peer]
		if { [peerByIfc $mirror [ifcList $mirror]] == $peer } {
		    return $ifc
		}
	    }
	}
	return ""
    } else {
	return $ifc    
    }
}

#****f* nodecfg.tcl/hasIPv4Addr
# NAME
#   hasIPv4Addr -- has IPv4 address.
# SYNOPSIS
#   set check [hasIPv4Addr $node]
# FUNCTION
#   Returns true if at least one interface has an IPv4 address configured,
#   otherwise returns false.
# INPUTS
#   * node -- node id
# RESULT
#   * check -- true if at least one interface has an IPv4 address, otherwise
#     false.
#****
proc hasIPv4Addr { node } {
    foreach ifc [ifcList $node] {
	if { [getIfcIPv4addr $node $ifc] != "" } {
	    return true
	}
    }
    return false
}

#****f* nodecfg.tcl/hasIPv6Addr
# NAME
#   hasIPv6Addr -- has IPv6 address.
# SYNOPSIS
#   set check [hasIPv6Addr $node]
# FUNCTION
#   Retruns true if at least one interface has an IPv6 address configured,
#   otherwise returns false.
# INPUTS
#   * node -- node id
# RESULT
#   * check -- true if at least one interface has an IPv6 address, otherwise
#     false.
#****
proc hasIPv6Addr { node } {
    foreach ifc [ifcList $node] {
	if { [getIfcIPv6addr $node $ifc] != "" } {
	    return true
	}
    }
    return false
}

#****f* nodecfg.tcl/removeNode
# NAME
#   removeNode -- removes the node
# SYNOPSIS
#   removeNode $node
# FUNCTION
#   Removes the specified node as well as all the links binding that node to
#   the other nodes.
# INPUTS
#   * node -- node id
#****
proc removeNode { node } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    upvar 0 ::cf::[set ::curcfg]::$node $node
    global nodeNamingBase

    if { [getCustomIcon $node] != "" } {
	removeImageReference [getCustomIcon $node] $node
    }

    foreach ifc [ifcList $node] {
	set peer [peerByIfc $node $ifc]
	set link [linkByPeers $node $peer]
	removeLink $link
    }
    set i [lsearch -exact $node_list $node]
    set node_list [lreplace $node_list $i $i]

    set node_type [nodeType $node]
    if { $node_type in [array names nodeNamingBase] } {
	recalculateNumType $node_type $nodeNamingBase($node_type)
    }
}

#****f* nodecfg.tcl/getNodeCanvas
# NAME
#   getNodeCanvas -- get node canvas id
# SYNOPSIS
#   set canvas [getNodeCanvas $node]
# FUNCTION
#   Returns node's canvas affinity.
# INPUTS
#   * node -- node id
# RESULT
#   * canvas -- canvas id
#****
proc getNodeCanvas { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    return [lindex [lsearch -inline [set $node] "canvas *"] 1]
}

#****f* nodecfg.tcl/setNodeCanvas
# NAME
#   setNodeCanvas -- set node canvas
# SYNOPSIS
#   setNodeCanvas $node $canvas
# FUNCTION
#   Sets node's canvas affinity.
# INPUTS
#   * node -- node id
#   * canvas -- canvas id
#****
proc setNodeCanvas { node canvas } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set i [lsearch [set $node] "canvas *"]
    if { $i >= 0 } {
	set $node [lreplace [set $node] $i $i "canvas $canvas"]
    } else {
	set $node [linsert [set $node] end "canvas $canvas"]
    }
}

#****f* nodecfg.tcl/newIfc
# NAME
#   newIfc -- new interface
# SYNOPSIS
#   set ifc [newIfc $type $node]
# FUNCTION
#   Returns the first available name for a new interface of the specified type.
# INPUTS
#   * type -- interface type
#   * node -- node id
# RESULT
#   * ifc -- the first available name for a interface of the specified type
#****
# modification for cisco router
proc newIfc { type node } {
   
    if {$type == "f"} { 
    set interfaces [ifcList $node]
    set f "/0"
    for { set id 0 } { [lsearch -exact $interfaces $type$id$f] >= 0 } {incr id} {}
    
    return $type$id$f 
 	} else {
    set interfaces [ifcList $node]

    for { set id 0 } { [lsearch -exact $interfaces $type$id] >= 0 } {incr id} {}
    return $type$id 
}
    
}

#****f* nodecfg.tcl/newLogIfc
# NAME
#   newLogIfc -- new logical interface
# SYNOPSIS
#   newLogIfc $type $node
# FUNCTION
#   Returns the first available name for a new logical interface of the
#   specified type.
# INPUTS
#   * type -- interface type
#   * node -- node id
#****
proc newLogIfc { type node } {
    set interfaces [logIfcList $node]
    for { set id 0 } { [lsearch -exact $interfaces $type$id] >= 0 } {incr id} {}
    return $type$id
}

#****f* nodecfg.tcl/newNode
# NAME
#   newNode -- new node
# SYNOPSIS
#   set node_id [newNode $type]
# FUNCTION
#   Returns the node id of a new node of the specified type.
# INPUTS
#   * type -- node type
# RESULT
#   * node_id -- node id of a new node of the specified type
#****
proc newNode { type } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    global viewid
    catch {unset viewid}
	
    set node [newObjectId node]
    upvar 0 ::cf::[set ::curcfg]::$node $node
    set $node {}
    lappend $node "type $type"
    lappend node_list $node

    if {[info procs $type.confNewNode] == "$type.confNewNode"} {
	$type.confNewNode $node
    }
    
    return $node
}

#****f* nodecfg.tcl/getNodeMirror
# NAME
#   getNodeMirror -- get node mirror
# SYNOPSIS
#   set mirror_node_id [getNodeMirror $node]
# FUNCTION
#   Returns the node id of a mirror pseudo node of the node. Mirror node is
#   the corresponding pseudo node. The pair of pseudo nodes, node and his
#   mirror node, are introduced to form a split in a link. This split can be
#   used for avoiding crossed links or for displaying a link between the nodes
#   on a different canvas.
# INPUTS
#   * node -- node id
# RESULT
#   * mirror_node_id -- node id of a mirror node
#****
proc getNodeMirror { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    return [lindex [lsearch -inline [set $node] "mirror *"] 1]
}

#****f* nodecfg.tcl/setNodeMirror
# NAME
#   setNodeMirror -- set node mirror
# SYNOPSIS
#   setNodeMirror $node $value
# FUNCTION
#   Sets the node id of a mirror pseudo node of the specified node. Mirror
#   node is the corresponding pseudo node. The pair of pseudo nodes, node and
#   his mirror node, are introduced to form a split in a link. This split can
#   be used for avoiding crossed links or for displaying a link between the
#   nodes on a different canvas.
# INPUTS
#   * node -- node id
#   * value -- node id of a mirror node
#****
proc setNodeMirror { node value } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set i [lsearch [set $node] "mirror *"]
    if { $value == "" } {
	set $node [lreplace [set $node] $i $i]
    } else {
	set $node [linsert [set $node] end "mirror $value"]
    }
}

#****f* nodecfg.tcl/getNodeProtocolRip
# NAME
#   getNodeProtocolRip
# SYNOPSIS
#   getNodeProtocolRip $node
# FUNCTION
#   Checks if node's current protocol is rip.
# INPUTS
#   * node -- node id 
# RESULT
#   * check -- 1 if it is rip, otherwise 0
#****
proc getNodeProtocolRip { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node    
	   
    if { [netconfFetchSection $node "router rip"] != "" } {
	return 1;
    } else {	
	return 0;
    }	    
}

#****f* nodecfg.tcl/getNodeProtocolRipng
# NAME
#   getNodeProtocolRipng
# SYNOPSIS
#   getNodeProtocolRipng $node
# FUNCTION
#   Checks if node's current protocol is ripng.
# INPUTS
#   * node -- node id
# RESULT
#   * check -- 1 if it is ripng, otherwise 0
#****
proc getNodeProtocolRipng { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node    
	   
    if { [netconfFetchSection $node "router ripng"] != "" } {
	return 1;
    } else {	
	return 0;
    }	    
}

#****f* nodecfg.tcl/getNodeProtocolOspfv2
# NAME
#   getNodeProtocolOspfv2
# SYNOPSIS
#   getNodeProtocolOspfv2 $node
# FUNCTION
#   Checks if node's current protocol is ospfv2.
# INPUTS
#   * node -- node id
# RESULT
#   * check -- 1 if it is ospfv2, otherwise 0
#****
proc getNodeProtocolOspfv2 { node } { 
    upvar 0 ::cf::[set ::curcfg]::$node $node

    if { [netconfFetchSection $node "router ospf"] != ""} {	
	return 1;
    } else {	
	return 0;
    }	
}

#****f* nodecfg.tcl/getNodeProtocolOspfv3
# NAME
#   getNodeProtocolOspfv3
# SYNOPSIS
#   getNodeProtocolOspfv3 $node
# FUNCTION
#   Checks if node's current protocol is ospfv3.
# INPUTS
#   * node -- node id
# RESULT
#   * check -- 1 if it is ospfv3, otherwise 0
#****
proc getNodeProtocolOspfv3 { node } { 
    upvar 0 ::cf::[set ::curcfg]::$node $node

    if { [netconfFetchSection $node "router ospf6"] != ""} {	
	return 1;
    } else {	
	return 0;
    }	
}

#****f* nodecfg.tcl/setNodeProtocolRip
# NAME
#   setNodeProtocolRip
# SYNOPSIS
#   setNodeProtocolRip $node $ripEnable
# FUNCTION
#   Sets node's protocol to rip.
# INPUTS
#   * node -- node id
#   * ripEnable -- 1 if enabling rip, 0 if disabling 
#****
proc setNodeProtocolRip { node ripEnable } {
    upvar 0 ::cf::[set ::curcfg]::$node $node    
	   
    if { $ripEnable == 1 } {
	netconfInsertSection $node [list "router rip" \
		" redistribute static" \
		" redistribute connected" \
		" redistribute ospf" \
		" network 0.0.0.0/0" \
		! ]
    } else {	
	netconfClearSection $node "router rip"	
    }	    
}

#****f* nodecfg.tcl/setNodeProtocolRipng
# NAME
#   setNodeProtocolRipng
# SYNOPSIS
#   setNodeProtocolRipng $node $ripngEnable
# FUNCTION
#   Sets node's protocol to ripng.
# INPUTS
#   * node -- node id
#   * ripngEnable -- 1 if enabling ripng, 0 if disabling 
#****
proc setNodeProtocolRipng { node ripngEnable } {
    upvar 0 ::cf::[set ::curcfg]::$node $node    
	   
    if { $ripngEnable == 1 } {
	netconfInsertSection $node [list "router ripng" \
		" redistribute static" \
		" redistribute connected" \
		" redistribute ospf6" \
		" network ::/0" \
		! ]
    } else {	
 	netconfClearSection $node "router ripng"	
    }	    
}

#****f* nodecfg.tcl/setNodeProtocolOspfv2
# NAME
#   setNodeProtocolOspfv2
# SYNOPSIS
#   setNodeProtocolOspfv2 $node $ospfEnable
# FUNCTION
#   Sets node's protocol to ospf.
# INPUTS
#   * node -- node id
#   * ospfEnable -- 1 if enabling ospf, 0 if disabling
#****
proc setNodeProtocolOspfv2 { node ospfEnable } { 
    upvar 0 ::cf::[set ::curcfg]::$node $node

    if { $ospfEnable == 1 } {
	netconfInsertSection $node [list "router ospf" \
		" redistribute static" \
		" redistribute connected" \
		" redistribute rip" \
		" network 0.0.0.0/0 area 0.0.0.0" \
		! ]
    } else {
	netconfClearSection $node "router ospf"
    }
}

#****f* nodecfg.tcl/setNodeProtocolOspfv3
# NAME
#   setNodeProtocolOspfv3
# SYNOPSIS
#   setNodeProtocolOspfv3 $node $ospf6Enable
# FUNCTION
#   Sets node's protocol to Ospfv3.
# INPUTS
#   * node -- node id
#   * ospf6Enable -- 1 if enabling ospf6, 0 if disabling
#****
proc setNodeProtocolOspfv3 { node ospf6Enable } { 
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set n [string trimleft $node "n"]

    if { $ospf6Enable == 1 } {
	netconfInsertSection $node [list "router ospf6" \
		" router-id 0.0.0.$n" \
		" redistribute static" \
		" redistribute connected" \
		" redistribute ripng" \
		! ]
# Possible new line:
#		" area 0.0.0.0 range ::/0" \
# Old line:		
#		" network ::/0 area 0.0.0.0" \
    } else {
	netconfClearSection $node "router ospf6"
    }
}

#****f* nodecfg.tcl/setNodeType
# NAME
#   setNodeType -- set node's type.
# SYNOPSIS
#   setNodeType $node $newtype
# FUNCTION
#   Sets node's type and configuration. Conversion is possible between router
#   on the one side, and the pc or host on the other side.
# INPUTS
#   * node -- node id
#   * newtype -- new type of node
#****
proc setNodeType { node newtype } {
    upvar 0 ::cf::[set ::curcfg]::$node $node
    global ripEnable ripngEnable ospfEnable ospf6Enable changeAddressRange \
     changeAddressRange6
    
    set oldtype [nodeType $node]
    if { [lsearch "rj45 hub lanswitch" $newtype] >= 0 } {
	return
    }
    if { [lsearch "rj45 hub lanswitch" $oldtype] >= 0 } {
	return
    }
    if { $oldtype == "router" && [lsearch "pc host" $newtype] >= 0 } {
	setType $node $newtype
	set i [lsearch [set $node] "model *"]
	set $node [lreplace [set $node] $i $i]
	setNodeName $node $newtype[string range $node 1 end]
	setNodeProtocolRip $node 0
	setNodeProtocolRipng $node 0
	setNodeProtocolOspfv2 $node 0
	setNodeProtocolOspfv3 $node 0
	set interfaces [ifcList $node]
	foreach ifc $interfaces {
	    set changeAddressRange 0
	    set changeAddressRange6 0
	    autoIPv4addr $node $ifc
	    autoIPv6addr $node $ifc
	}
    } elseif { [lsearch "host pc" $oldtype] >= 0 \
	    && $newtype == "router" } {
	setType $node $newtype
	setNodeModel $node "quagga"
	setNodeName $node $newtype[string range $node 1 end]
	netconfClearSection $node "ip route *"
	netconfClearSection $node "ipv6 route *"
	setNodeProtocolRip $node $ripEnable
	setNodeProtocolRipng $node $ripngEnable
	setNodeProtocolOspfv2 $node $ospfEnable 
	setNodeProtocolOspfv3 $node $ospf6Enable 
    }
}

#****f* nodecfg.tcl/setType
# NAME
#   setType -- set node's type.
# SYNOPSIS
#   setType $node $type
# FUNCTION
#   Sets node's type.
# INPUTS
#   * node -- node id
#   * type -- type of node
#****
proc setType { node type } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set i [lsearch [set $node] "type *"]
    if { $i >= 0 } {
	set $node [lreplace [set $node] $i $i "type $type"]
    } else {
	set $node [linsert [set $node] 1 "type $type"]
    }
}

#****f* nodecfg.tcl/setCloudParts
# NAME
#   setCloudParts -- set cloud parts
# SYNOPSIS
#   setCloudParts $node $nr_parts
# FUNCTION
#   Sets the parts of the node's cloud.
# INPUTS
#   * node -- node id
#   * nr_parts -- cloud parts
#****
proc setCloudParts { node nr_parts } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set i [lsearch [set $node] "num_parts *"]
    if { $i >= 0 } {
	set $node [lreplace [set $node] $i $i "num_parts $nr_parts"]
    } else {
	set $node [linsert [set $node] end "num_parts $nr_parts"];
    }
}

#****f* nodecfg.tcl/getCloudParts
# NAME
#   getCloudParts -- get cloud parts
# SYNOPSIS
#   getCloudParts $node
# FUNCTION
#   Returns the node's cloud parts.
# INPUTS
#   * node -- node id
# RESULT
#   * part -- cloud parts
#****
proc getCloudParts { node } {
  upvar 0 ::cf::[set ::curcfg]::$node $node

  set part [lindex [lsearch -inline [set $node] "num_parts *"] 1];
  return $part;
}

#****f* nodecfg.tcl/registerModule
# NAME
#   registerModule -- register module
# SYNOPSIS
#   registerModule $module
# FUNCTION
#   Adds a module to all_modules_list.
# INPUTS
#   * module -- module to add
#****
proc registerModule { module } {
    global all_modules_list
    lappend all_modules_list $module
}

#****f* nodecfg.tcl/deregisterModule
# NAME
#   deregisterModule -- deregister module
# SYNOPSIS
#   deregisterModule $module
# FUNCTION
#   Removes a module from all_modules_list.
# INPUTS
#   * module -- module to remove
#****
proc deregisterModule { module } {
    global all_modules_list
    set ind [lsearch $all_modules_list $module]
    set all_modules_list [lreplace $all_modules_list $ind $ind]
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
proc getIfcVlanDev { node ifc } {
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] == "vlan-dev" } {
	    return [lindex $line 1]
	}
    }
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
proc setIfcVlanDev { node ifc dev } {
    set ifcfg [list "interface $ifc"]
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] != "vlan-dev" } {
	    lappend ifcfg $line
	}
    }
    if { $dev in [ifcList $node] } {
	lappend ifcfg " vlan-dev $dev"
    }
    netconfInsertSection $node $ifcfg
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
proc getIfcVlanTag { node ifc } {
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] == "vlan-tag" } {
	    return [lindex $line 1]
	}
    }
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
proc setIfcVlanTag { node ifc tag } {
    set ifcfg [list "interface $ifc"]
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] != "vlan-tag" } {
	    lappend ifcfg $line
	}
    }
    if { $tag >= 1 && $tag <= 4094 } {
	lappend ifcfg " vlan-tag $tag"
    }
    netconfInsertSection $node $ifcfg
}

#****f* nodecfg.tcl/setEtherVlanEnabled
# NAME
#   setEtherVlanEnabled -- set node rj45 vlan.
# SYNOPSIS
#   setEtherVlanEnabled $node $value
# FUNCTION
#   Sets rj45 node vlan setting.
# INPUTS
#   * node -- node id
#   * value -- vlan enabled
#****
proc setEtherVlanEnabled { node value } {
    set vlancfg [list "vlan"]
    lappend vlancfg " enabled $value"
    foreach line [netconfFetchSection $node "vlan"] {
	if { [lindex $line 0] != "enabled" } {
	    lappend vlancfg $line
	}
    }
    netconfInsertSection $node $vlancfg
}

#****f* nodecfg.tcl/getEtherVlanEnabled
# NAME
#   getEtherVlanEnabled -- get node rj45 vlan.
# SYNOPSIS
#   set value [getEtherVlanEnabled $node]
# FUNCTION
#   Returns whether the rj45 node is vlan enabled.
# INPUTS
#   * node -- node id
# RESULT
#   * value -- vlan enabled
#****
proc getEtherVlanEnabled { node } {
    foreach line [netconfFetchSection $node "vlan"] {
	if { [lindex $line 0] == "enabled" } {
	    return [lindex $line 1]
	}
    }
    return 0
}

#****f* nodecfg.tcl/setEtherVlanTag
# NAME
#   setEtherVlanTag -- set node rj45 vlan tag.
# SYNOPSIS
#   setEtherVlanTag $node $value
# FUNCTION
#   Sets rj45 node vlan tag.
# INPUTS
#   * node -- node id
#   * value -- vlan tag
#****
proc setEtherVlanTag { node value } {
    set vlancfg [list "vlan"]
    foreach line [netconfFetchSection $node "vlan"] {
	if { [lindex $line 0] != "tag" } {
	    lappend vlancfg $line
	}
    }
    lappend vlancfg " tag $value"
    netconfInsertSection $node $vlancfg
}

#****f* nodecfg.tcl/getEtherVlanTag
# NAME
#   getEtherVlanTag -- get node rj45 vlan tag.
# SYNOPSIS
#   set value [getEtherVlanTag $node]
# FUNCTION
#   Returns rj45 node vlan tag.
# INPUTS
#   * node -- node id
# RESULT
#   * value -- vlan tag
#****
proc getEtherVlanTag { node } {
    foreach line [netconfFetchSection $node "vlan"] {
	if { [lindex $line 0] == "tag" } {
	    return [lindex $line 1]
	}
    }
}

#****f* nodecfg.tcl/getNodeServices
# NAME
#   getNodeServices -- get node active services.
# SYNOPSIS
#   set services [getNodeServices $node]
# FUNCTION
#   Returns node's selected services.
# INPUTS
#   * node -- node id
# RESULT
#   * services -- active services
#****
proc getNodeServices { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    return [lindex [lsearch -inline [set $node] "services *"] 1]
}

#****f* nodecfg.tcl/setNodeServices
# NAME
#   setNodeServices -- set node active services.
# SYNOPSIS
#   setNodeServices $node $services
# FUNCTION
#   Sets node selected services.
# INPUTS
#   * node -- node id
#   * services -- list of services
#****
proc setNodeServices { node services } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set i [lsearch [set $node] "services *"]
    if { $i >= 0 } {
        set $node [lreplace [set $node] $i $i "services {$services}"]
    } else {
        set $node [linsert [set $node] end "services {$services}"]
    }
}

#****f* nodecfg.tcl/getNodeDockerImage
# NAME
#   getNodeDockerImage -- get node docker image.
# SYNOPSIS
#   set value [getNodeDockerImage $node]
# FUNCTION
#   Returns node docker image setting.
# INPUTS
#   * node -- node id
# RESULT
#   * status -- docker image identifier
#****
proc getNodeDockerImage { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    return [lindex [lsearch -inline [set $node] "docker-image *"] 1]
}

#****f* nodecfg.tcl/setNodeDockerImage
# NAME
#   setNodeDockerImage -- set node docker image.
# SYNOPSIS
#   setNodeDockerImage $node $img
# FUNCTION
#   Sets node docker image.
# INPUTS
#   * node -- node id
#   * img -- image identifier
#****
proc setNodeDockerImage { node img } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set i [lsearch [set $node] "docker-image *"]
    if { $i >= 0 } {
	set $node [lreplace [set $node] $i $i]
    }
    if { $img != "" } {
	lappend $node [list docker-image $img]
    }
}

#****f* nodecfg.tcl/getNodeDockerAttach
# NAME
#   getNodeDockerAttach -- get node docker ext ifc attach.
# SYNOPSIS
#   set value [getNodeDockerAttach $node]
# FUNCTION
#   Returns node docker ext ifc attach setting.
# INPUTS
#   * node -- node id
# RESULT
#   * status -- attach enabled
#****
#elle vérifie si on a coché
proc getNodeDockerAttach { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    if { [lindex [lsearch -inline [set $node] "docker-attach *"] 1] == true } {
	return true
    } else {
	return false
    }
}

#****f* nodecfg.tcl/setNodeDockerAttach
# NAME
#   setNodeDockerAttach -- set node docker ext ifc attach.
# SYNOPSIS
#   setNodeDockerAttach $node $enabled
# FUNCTION
#   Sets node docker ext ifc attach status.
# INPUTS
#   * node -- node id
#   * enabled -- attach status
#****
proc setNodeDockerAttach { node enabled } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set i [lsearch [set $node] "docker-attach *"]
    if { $i >= 0 } {
	set $node [lreplace [set $node] $i $i]
    }
    if { $enabled == true } {
	lappend $node [list docker-attach $enabled]
    }
}

#****f* nodecfg.tcl/registerRouterModule
# NAME
#   registerRouterModule -- register module
# SYNOPSIS
#   registerRouterModule $module
# FUNCTION
#   Adds a module to router_modules_list.
# INPUTS
#   * module -- module to add
#****
proc registerRouterModule { module } {
    global router_modules_list
    lappend router_modules_list $module
}

#****f* nodecfg.tcl/isNodeRouter
# NAME
#   isNodeRouter -- check whether a node is registered as a router
# SYNOPSIS
#   isNodeRouter $node
# FUNCTION
#   Checks if a node is a router.
# INPUTS
#   * node -- node to check
#****
proc isNodeRouter { node } {
    global router_modules_list
    if { [nodeType $node] in $router_modules_list } {
	return 1
    }
    return 0
}

#****f* nodecfg.tcl/nodeCfggenIfcIPv4
# NAME
#   nodeCfggenIfcIPv4 -- generate interface IPv4 configuration
# SYNOPSIS
#   nodeCfggenIfcIPv4 $node
# FUNCTION
#   Generate configuration for all IPv4 addresses on all node
#   interfaces.
# INPUTS
#   * node -- node to generate configuration for
# RESULT
#   * value -- interface IPv4 configuration script
#****
proc nodeCfggenIfcIPv4 { node } {
    set cfg {}
    foreach ifc [allIfcList $node] {
	set primary 1
	foreach addr [getIfcIPv4addrs $node $ifc] {
	    if { $addr != "" } {
		if { $primary } {
		    lappend cfg [getIPv4IfcCmd $ifc $addr $primary]
		    set primary 0
		} else {
		    lappend cfg [getIPv4IfcCmd $ifc $addr $primary]
		}
	    }
	}
    }
    return $cfg
}

#****f* nodecfg.tcl/nodeCfggenIfcIPv6
# NAME
#   nodeCfggenIfcIPv6 -- generate interface IPv6 configuration
# SYNOPSIS
#   nodeCfggenIfcIPv6 $node
# FUNCTION
#   Generate configuration for all IPv6 addresses on all node
#   interfaces.
# INPUTS
#   * node -- node to generate configuration for
# RESULT
#   * value -- interface IPv6 configuration script
#****
proc nodeCfggenIfcIPv6 { node } {
    set cfg {}
    foreach ifc [allIfcList $node] {
	set primary 1
	foreach addr [getIfcIPv6addrs $node $ifc] {
	    if { $addr != "" } { 
		if { $primary } {
		    lappend cfg [getIPv6IfcCmd $ifc $addr $primary]
		    set primary 0
		} else {
		    lappend cfg [getIPv6IfcCmd $ifc $addr $primary]
		}
	    }
	}
    }
    return $cfg
}

#****f* nodecfg.tcl/nodeCfggenRouteIPv4
# NAME
#   nodeCfggenRouteIPv4 -- generate ifconfig IPv4 configuration
# SYNOPSIS
#   nodeCfggenRouteIPv4 $node
# FUNCTION
#   Generate IPv4 route configuration.
# INPUTS
#   * node -- node to generate configuration for
# RESULT
#   * value -- route IPv4 configuration script
#****
proc nodeCfggenRouteIPv4 { node } {
    set cfg {}
    foreach statrte [getStatIPv4routes $node] {
	lappend cfg [getIPv4RouteCmd $statrte]
    }
    return $cfg
}

#****f* nodecfg.tcl/nodeCfggenRouteIPv6
# NAME
#   nodeCfggenRouteIPv6 -- generate ifconfig IPv6 configuration
# SYNOPSIS
#   nodeCfggenRouteIPv6 $node
# FUNCTION
#   Generate IPv6 route configuration.
# INPUTS
#   * node -- node to generate configuration for
# RESULT
#   * value -- route IPv6 configuration script
#****
proc nodeCfggenRouteIPv6 { node } {
    set cfg {}
    foreach statrte [getStatIPv6routes $node] {
	lappend cfg [getIPv6RouteCmd $statrte]
    }
    return $cfg
}

#****f* nodecfg.tcl/getAllNodesType
# NAME
#   getAllNodesType -- get list of all nodes of a certain type
# SYNOPSIS
#   getAllNodesType $type
# FUNCTION
#   Passes through the list of all nodes and returns a list of nodes of the
#   specified type.
# INPUTS
#   * type -- node type
# RESULT
#   * list -- list of all nodes of the type
#****
proc getAllNodesType { type } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    set type_list ""
    foreach node $node_list {
	if { [string match "$type*" [typemodel $node]] } {
	    lappend type_list $node
	}
    }
    return $type_list
}

#****f* nodecfg.tcl/getNewNodeNameType
# NAME
#   getNewNodeNameType -- get a new node name for a certain type
# SYNOPSIS
#   getNewNodeNameType $type $namebase
# FUNCTION
#   Returns a new node name for the type and namebase, e.g. pc0 for pc.
# INPUTS
#   * type -- node type
#   * namebase -- base for the node name
# RESULT
#   * name -- new node name to be assigned
#****
proc getNewNodeNameType { type namebase } {
    upvar 0 ::cf::[set ::curcfg]::num$type num$type

    #if the variable pcnodes isn't set we need to check through all the nodes
    #to assign a non duplicate name
    if {! [info exists num$type] } {
	recalculateNumType $type $namebase
    }

    incr num$type
    return $namebase[set num$type]
}

#****f* nodecfg.tcl/recalculateNumType
# NAME
#   recalculateNumType -- recalculate number for type
# SYNOPSIS
#   recalculateNumType $type $namebase
# FUNCTION
#   Calculates largest number for the given type
# INPUTS
#   * type -- node type
#   * namebase -- base for the node name
#****
proc recalculateNumType { type namebase } {
    upvar 0 ::cf::[set ::curcfg]::num$type num$type

    set num$type 0
    foreach n [getAllNodesType $type] {
	set name [getNodeName $n]
	if {[string match "$namebase*" $name]} {
	    set rest [string trimleft $name $namebase]
	    if { [string is integer $rest] && $rest > [set num$type] } {
		set num$type $rest
	    }
	}
    }
}

#****f* nodecfg.tcl/transformNodes
# NAME
#   transformNode -- transform nodes
# SYNOPSIS
#   transformNodes $type $namebase
# FUNCTION
#   Returns a new node name for the type and namebase, e.g. pc0 for pc.
# INPUTS
#   * type -- node type
#   * namebase -- base for the node name
# RESULT
#   * name -- new node name to be assigned
#****
proc transformNodes { nodes type } {
    foreach node $nodes {
	if { [[typemodel $node].layer] == "NETWORK" } {
	    upvar 0 ::cf::[set ::curcfg]::$node nodecfg
	    global changed

	    if { $type == "pc" || $type == "host" } {
		# replace type
		set typeIndex [lsearch $nodecfg "type *"]
		set nodecfg [lreplace $nodecfg $typeIndex $typeIndex "type $type" ]
		# if router, remove model
		set modelIndex [lsearch $nodecfg "model *"]
		set nodecfg [lreplace $nodecfg $modelIndex $modelIndex]

		# add default routes
		foreach iface [ifcList $node] {
		    autoIPv4defaultroute $node $iface
		    autoIPv6defaultroute $node $iface
		}

		# delete router stuff in netconf
		foreach model "rip ripng ospf ospf6" {
		    netconfClearSection $node "router $model"
		}

		set changed 1
	    } elseif { [nodeType $node] != "router" && $type == "router" } {
		# replace type
		set typeIndex [lsearch $nodecfg "type *"]
		set nodecfg [lreplace $nodecfg $typeIndex $typeIndex "type $type"]

		# set router model and default protocols
		setNodeModel $node "quagga"
		setNodeProtocolRip $node 1
		setNodeProtocolRipng $node 1
		# clear default static routes
		netconfClearSection $node "ip route [lindex [getStatIPv4routes $node] 0]"
		netconfClearSection $node "ipv6 route [lindex [getStatIPv6routes $node] 0]"

		set changed 1
	    }
	}
    }

    if { $changed == 1 } {
	redrawAll
	updateUndoLog
    }
}

#****f* nodecfg.tcl/pseudo.layer
# NAME
#   pseudo.layer -- pseudo layer
# SYNOPSIS
#   set layer [pseudo.layer]
# FUNCTION
#   Returns the layer on which the pseudo node operates
#   i.e. returns no layer.
# RESULT
#   * layer -- returns an empty string
#****
proc pseudo.layer {} {
}

#****f* nodecfg.tcl/pseudo.virtlayer
# NAME
#   pseudo.virtlayer -- pseudo virtlayer
# SYNOPSIS
#   set virtlayer [pseudo.virtlayer]
# FUNCTION
#   Returns the virtlayer on which the pseudo node operates
#   i.e. returns no layer.
# RESULT
#   * virtlayer -- returns an empty string
#****
proc pseudo.virtlayer {} {
}
