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

# $Id: xorp.tcl 128 2014-12-19 11:59:09Z denis $


#****h* imunes/xorp.tcl
# NAME
#  router.xorp.tcl -- defines specific procedures for routers 
#  using xorp routing model
# FUNCTION
#  This module defines all the specific procedures for a router
#  which uses xorp routing model.
# NOTES
#  Procedures in this module start with the keyword router.xorp and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE router.xorp

#****f* xorp.tcl/router.xorp.layer
# NAME
#   router.xorp.layer -- layer
# SYNOPSIS
#   set layer [router.xorp.layer]
# FUNCTION
#   Returns the layer on which the router using xorp model
#   operates, i.e. returns NETWORK. 
# RESULT
#   * layer -- set to NETWORK
#****
proc $MODULE.layer {} {
    return NETWORK
}

#****f* xorp.tcl/router.xorp.virtlayer
# NAME
#   router.xorp.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [router.xorp.virtlayer]
# FUNCTION
#   Returns the layer on which the router using model xorp
#   is instantiated, i.e. returns VIMAGE. 
# RESULT
#   * layer -- set to VIMAGE
#****
proc $MODULE.virtlayer {} {
    return VIMAGE
}

#****f* xorp.tcl/router.xorp.cfggen
# NAME
#   router.xorp.cfggen -- configuration generator
# SYNOPSIS
#   set config [router.xorp.cfggen $node]
# FUNCTION
#   Generates configuration. This configuration represents the default
#   configuration loaded on the booting time of the virtual nodes and it is
#   closely related to the procedure router.xorp.bootcmd.
#   Generated configuration comprises the ip addresses (both ipv4 and ipv6)
#   for each interface of a given node. Static routes are also included as
#   well as rip support for ipv4 and ipv6.
# INPUTS
#   * node - node id (type of the node is router
#     and the routing model is xorp)
# RESULT
#   * congif -- generated configuration 
#****
proc $MODULE.cfggen { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node
    
    set cfg {}

    lappend cfg "interfaces {"
    foreach ifc [ifcList $node] {
	set ipv4addr "[lindex [split [getIfcIPv4addr $node $ifc] /] 0]"
	set ipv4mask "[lindex [split [getIfcIPv4addr $node $ifc] /] 1]"
	set ipv6addr "[lindex [split [getIfcIPv6addr $node $ifc] /] 0]"
	set ipv6mask "[lindex [split [getIfcIPv6addr $node $ifc] /] 1]"
	set ipv6addr2 "[lindex [split [getIfcLinkLocalIPv6addr $node $ifc] /] 0]"
	set ipv6mask2 "[lindex [split [getIfcLinkLocalIPv6addr $node $ifc] /] 1]"
	lappend cfg "    interface $ifc {"
	lappend cfg "	 vif $ifc {"
	lappend cfg "	    disable: false"
	if { $ipv4addr != "" } {
	    lappend cfg "	    address $ipv4addr {"
	    lappend cfg "		prefix-length: $ipv4mask"
	    lappend cfg "	    }"
	}
	if { $ipv6addr != "" } {
	    lappend cfg "	    address $ipv6addr {"
	    lappend cfg "		prefix-length: $ipv6mask"
	    lappend cfg "	    }"
	}
	if { $ipv6addr2 != "" } {
	    lappend cfg "	    address $ipv6addr2 {"
	    lappend cfg "		prefix-length: $ipv6mask2"
	    lappend cfg "	    }"
	}
	lappend cfg "	}"
	lappend cfg "    }"
    }
    lappend cfg "}"
    lappend cfg ""

    lappend cfg "protocols {"
    lappend cfg "    static {"
    foreach rte [getStatIPv4routes $node] {
	set dest [lindex $rte 0]
	set gw [lindex $rte 1]
	set metric [lindex $rte 2]
	lappend cfg "	route4 $dest {"
	lappend cfg "	    next-hop: $gw"
	if { $metric != "" } {
	    lappend cfg "	    metric: $metric"
	}
	lappend cfg "	}"
    }
    foreach rte [getStatIPv6routes $node] {
	set dest [lindex $rte 0]
	set gw [lindex $rte 1]
	set metric [lindex $rte 2]
	lappend cfg "	route6 $dest {"
	lappend cfg "	    next-hop: $gw"
	if { $metric == "" } {
	    lappend cfg "	    metric: $metric"
	}
	lappend cfg "	}"
    }
    lappend cfg "    }"

    if { [netconfFetchSection $node "router rip"] != "" } {
	lappend cfg "    rip {"
	lappend cfg "	export: \"static4\""
	lappend cfg "	export: \"connected4\""
	foreach ifc [ifcList $node] {
	    set addr "[lindex [split [getIfcIPv4addr $node $ifc] /] 0]"
	    if { $addr != "" } {
		lappend cfg "	interface $ifc {"
		lappend cfg "	    vif $ifc {"
		lappend cfg "		address $addr {"
		lappend cfg "		}"
		lappend cfg "	    }"
		lappend cfg "	}"
	    }
	}
	lappend cfg "    }"
    }

    if { [netconfFetchSection $node "router ripng"] != "" } {
	lappend cfg "    ripng {"
	lappend cfg "	export: \"static6\""
	lappend cfg "	export: \"connected6\""
	foreach ifc [ifcList $node] {
	    set addr "[lindex [split [getIfcLinkLocalIPv6addr $node $ifc] /] 0]"
	    if { $addr != "" } {
		lappend cfg "	interface $ifc {"
		lappend cfg "	    vif $ifc {"
		lappend cfg "		address $addr {"
		lappend cfg "		    disable: false"
		lappend cfg "		}"
		lappend cfg "	    }"
		lappend cfg "	}"
	    }
	}
	lappend cfg "    }"
    }

    if { [netconfFetchSection $node "router ospf"] != "" } {
	lappend cfg "    ospf4 {"
	lappend cfg "	export: \"static4\""
	lappend cfg "	export: \"connected4\""
	set addr "[lindex [split [getIfcIPv4addr $node [lindex [ifcList $node] 0]] /] 0]"
	if { $addr != "" } {
	    lappend cfg "	router-id: $addr"
	}
	lappend cfg "	area 0.0.0.0 {"
	foreach ifc [ifcList $node] {
	    set addr "[lindex [split [getIfcIPv4addr $node $ifc] /] 0]"	
	    if { $addr != "" } {
		lappend cfg "	    interface $ifc {"
		lappend cfg "	        vif $ifc {"
		lappend cfg "	            address $addr {"
		lappend cfg "	            }"
		lappend cfg "	        }"
		lappend cfg "	    }"
	    }
	}
	lappend cfg "	}"  
	lappend cfg "    }"
    }

    if { [netconfFetchSection $node "router ospf6"] != "" } {
	lappend cfg "    ospf6 0 {"
	lappend cfg "	export: \"static6\""
	lappend cfg "	export: \"connected6\""
	set addr "[lindex [split [getIfcIPv4addr $node [lindex [ifcList $node] 0]] /] 0]"
	if { $addr != "" } {
	    lappend cfg "	router-id: $addr"
	}
	lappend cfg "	area 0.0.0.0 {"
	foreach ifc [ifcList $node] {
	    set addr "[lindex [split [getIfcLinkLocalIPv6addr $node $ifc] /] 0]"
	    if { $addr != "" } {
		lappend cfg "	    interface $ifc {"
		lappend cfg "	        vif $ifc {"
		lappend cfg "	            address $addr {"
		lappend cfg "	            }"
		lappend cfg "	        }"
		lappend cfg "	    }"
	    }
	}
	lappend cfg "	}"  
	lappend cfg "    }"
    }

    lappend cfg "}"
    lappend cfg ""

    lappend cfg "policy {"
    if { [netconfFetchSection $node "router rip"] != "" || \
	[netconfFetchSection $node "router ospf"] != "" } {
	lappend cfg "    policy-statement connected4 {"
	lappend cfg "	term export {"
	lappend cfg "	    from {"
	lappend cfg "		protocol: \"connected\""
	lappend cfg "		network4 <= 0.0.0.0/0"
	lappend cfg "	    }"
	lappend cfg "	}"
	lappend cfg "    }"
	lappend cfg "    policy-statement static4 {"
	lappend cfg "	term export {"
	lappend cfg "	    from {"
	lappend cfg "		protocol: \"static\""
	lappend cfg "		network4 <= 0.0.0.0/0"
	lappend cfg "	    }"
	lappend cfg "	}"
	lappend cfg "    }"
    }
    if { [netconfFetchSection $node "router ripng"] != "" || \
	[netconfFetchSection $node "router ospf6"] != "" } {
	lappend cfg "    policy-statement connected6 {"
	lappend cfg "	term export {"
	lappend cfg "	    from {"
	lappend cfg "		protocol: \"connected\""
	lappend cfg "		network6 <= ::/0"
	lappend cfg "	    }"
	lappend cfg "	}"
	lappend cfg "    }"
	lappend cfg "    policy-statement static6 {"
	lappend cfg "	term export {"
	lappend cfg "	    from {"
	lappend cfg "		protocol: \"static\""
	lappend cfg "		network6 <= ::/0"
	lappend cfg "	    }"
	lappend cfg "	}"
	lappend cfg "    }"
    }
    lappend cfg "}"

    return $cfg
}

#****f* xorp.tcl/router.xorp.bootcmd
# NAME
#   router.xorp.bootcmd -- boot command
# SYNOPSIS
#   set appl [router.xorp.bootcmd $node]
# FUNCTION
#   Procedure bootcmd returns the defaut application that reads and
#   employes the configuration generated in router.xorp.cfggen.
#   In this case (procedure router.xorp.bootcmd) specific application
#   is xorp_rtrmgr used in batch mode. (in /usr/local/xorp/bin folder)
# INPUTS
#   * node - node id (type of the node is router and routing model is xorp)
# RESULT
#   * appl -- application that reads the configuration (xorp_rtrmgr) 
#****
proc $MODULE.bootcmd { node } {
    return "/usr/local/bin/xorp_rtrmgr -b"
}

#****f* xorp.tcl/router.xorp.shellcmds
# NAME
#   router.xorp.shellcmds -- shell commands
# SYNOPSIS
#   set shells [router.xorp.shellcmds]
# FUNCTION
#   Procedure shellcmds returns the shells that can be opened
#   as a default shell for the system. 
# RESULT
#   * shells -- default shells for the router.xorp
#****
proc $MODULE.shellcmds {} {
    return "csh bash xorpsh sh tcsh"
}

#****f* xorp.tcl/router.xorp.instantiate
# NAME
#   router.xorp.instantiate -- instantiate
# SYNOPSIS
#   router.xorp.instantiate $eid $node
# FUNCTION
#   Procedure instantiate creates a new virtaul node for a given node. 
#   Procedure router.xorp.instantiate cretaes a new virtual node with all the
#   interfaces and CPU parameters as defined in imunes. It sets the
#   net.inet.ip.forwarding and net.inet6.ip6.forwarding kernel variables to 1.
# INPUTS
#   * eid - experiment id
#   * node - node id (type of the node is router and routing model is xorp)
#****
proc $MODULE.instantiate { eid node } {
    l3node.instantiate $eid $node
    
    enableIPforwarding $eid $node

    configDefaultLoIfc $eid $node
}

#****f* xorp.tcl/router.xorp.start
# NAME
#   router.xorp.start -- start
# SYNOPSIS
#   router.xorp.start $eid $node
# FUNCTION
#   Starts a new router.xorp. The node can be started if it is instantiated. 
#   Simulates the booting proces of a router.xorp, by calling l3node.start 
#   procedure.
# INPUTS
#   * eid - experiment id
#   * node - node id (type of the node is router.xorp)
#****
proc $MODULE.start { eid node } {
    l3node.start $eid $node
}

#****f* xorp.tcl/router.xorp.shutdown
# NAME
#   router.xorp.shutdown -- shutdown
# SYNOPSIS
#   router.xorp.shutdown $eid $node
# FUNCTION
#   Shutdowns a router.xorp. Simulates the shutdown proces of a router.xorp, 
#   by calling the l3node.shutdown procedure.
# INPUTS
#   * eid - experiment id
#   * node - node id (type of the node is router.xorp)
#****
proc $MODULE.shutdown { eid node } {
    l3node.shutdown $eid $node
}

#****f* xorp.tcl/router.xorp.destroy
# NAME
#   router.xorp.destroy -- destroy
# SYNOPSIS
#   router.xorp.destroy $eid $node
# FUNCTION
#   Destroys a router.xorp. Destroys all the interfaces of the router.xorp 
#   and the vimage itself by calling l3node.destroy procedure. 
# INPUTS
#   * eid - experiment id
#   * node - node id (type of the node is router.xorp)
#****
proc $MODULE.destroy { eid node } {
    l3node.destroy $eid $node
}

#****f* xorp.tcl/router.xorp.nghook
# NAME
#   router.xorp.nghook -- nghook
# SYNOPSIS
#   router.xorp.nghook $eid $node $ifc 
# FUNCTION
#   Returns the id of the netgraph node and the name of the netgraph hook
#   which is used for connecting two netgraph nodes. This procedure calls
#   l3node.hook procedure and passes the result of that procedure.
# INPUTS
#   * eid - experiment id
#   * node - node id
#   * ifc - interface name
# RESULT
#   * nghook - the list containing netgraph node id and the
#     netgraph hook (ngNode ngHook).
#****
proc $MODULE.nghook { eid node ifc } {
    return [l3node.nghook $eid $node $ifc]
}
