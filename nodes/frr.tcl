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

# $Id: frr.tcl 128 2014-12-19 11:59:09Z denis $


#****h* imunes/frr.tcl
# NAME
#  router.frr.tcl -- defines specific procedures for router 
#  using frr routing model
# FUNCTION
#  This module defines all the specific procedures for a router
#  which uses frr routing model.
# NOTES
#  Procedures in this module start with the keyword router.frr and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE router.frr

#****f* frr.tcl/router.frr.layer
# NAME
#   router.frr.layer -- layer
# SYNOPSIS
#   set layer [router.frr.layer]
# FUNCTION
#   Returns the layer on which the router using frr model
#   operates, i.e. returns NETWORK. 
# RESULT
#   * layer -- set to NETWORK
#****
proc $MODULE.layer {} {
    return NETWORK
}

#****f* frr.tcl/router.frr.virtlayer
# NAME
#   router.frr.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [router.frr.virtlayer]
# FUNCTION
#   Returns the layer on which the router using model frr is instantiated,
#   i.e. returns VIRTUALIZED. 
# RESULT
#   * layer -- set to VIRTUALIZED
#****
proc $MODULE.virtlayer {} {
    return VIRTUALIZED
}

#****f* frr.tcl/router.frr.cfggen
# NAME
#   router.frr.cfggen -- configuration generator
# SYNOPSIS
#   set config [router.frr.cfggen $node]
# FUNCTION
#   Generates configuration. This configuration represents the default
#   configuration loaded on the booting time of the virtual nodes and it is
#   closly related to the procedure router.frr.bootcmd.
#   Generated configuration comprises the ip addresses (both ipv4 and ipv6)
#   and interface states (up or down) for each interface of a given node.
#   Static routes are also included.
# INPUTS
#   * node - node id (type of the node is router and routing model is frr)
# RESULT
#   * congif -- generated configuration 
#****
proc $MODULE.cfggen { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set cfg {}

    foreach ifc [allIfcList $node] {
	lappend cfg "interface $ifc"
	set addrs [getIfcIPv4addrs $node $ifc]
	foreach addr $addrs {
	    if { $addr != "" } {
		lappend cfg " ip address $addr"
	    }
	}
	set addrs [getIfcIPv6addrs $node $ifc]
	foreach addr $addrs {
	    if { $addr != "" } {
		lappend cfg " ipv6 address $addr"
	    }
	}
	if { [getIfcOperState $node $ifc] == "down" } {
	    lappend cfg " shutdown"
	}
	lappend cfg "!"
    }

    foreach proto { rip ripng ospf ospf6 bgp } {
	set protocfg [netconfFetchSection $node "router $proto"]
	if { $protocfg != "" } {
	    lappend cfg "router $proto"
	    foreach line $protocfg {
		lappend cfg "$line"
	    }
	    if {$proto == "ospf6"} {
		foreach ifc [allIfcList $node] {
		    if {$ifc == "lo0"} {
			continue
		    }
		    lappend cfg " interface $ifc area 0.0.0.0"
		}
	    }
	    lappend cfg "!"
	}
    }

    foreach statrte [getStatIPv4routes $node] {
	lappend cfg "ip route $statrte"
    }
    foreach statrte [getStatIPv6routes $node] {
	lappend cfg "ipv6 route $statrte"
    }

    if { [getAutoDefaultRoutesStatus $node] == "enabled" } {
	foreach statrte [getDefaultIPv4routes $node] {
	    lappend cfg "ip route $statrte"
	}
	foreach statrte [getDefaultIPv6routes $node] {
	    lappend cfg "ipv6 route $statrte"
	}
	setDefaultIPv4routes $node {}
	setDefaultIPv6routes $node {}
    }

    return $cfg
}

#****f* frr.tcl/router.frr.bootcmd
# NAME
#   router.frr.bootcmd -- boot command
# SYNOPSIS
#   set appl [router.frr.bootcmd $node]
# FUNCTION
#   Procedure bootcmd returns the defaut application that reads and employes
#   the configuration generated in router.frr.cfggen.
#   In this case (procedure router.frr.bootcmd) specific application
#   is frrboot.sh
# INPUTS
#   * node - node id (type of the node is router and routing model is frr)
# RESULT
#   * appl -- application that reads the configuration (frrboot.sh) 
#****
proc $MODULE.bootcmd { node } {

    return "/usr/local/bin/frrboot.sh"
}

#****f* frr.tcl/router.frr.shellcmds
# NAME
#   router.frr.shellcmds -- shell commands
# SYNOPSIS
#   set shells [router.frr.shellcmds]
# FUNCTION
#   Procedure shellcmds returns the shells that can be opened
#   as a default shell for the system. 
# RESULT
#   * shells -- default shells for the router.frr
#****
proc $MODULE.shellcmds {} {
    return "csh bash vtysh sh tcsh"
}

#****f* frr.tcl/router.frr.instantiate
# NAME
#   router.frr.instantiate -- instantiate
# SYNOPSIS
#   router.frr.instantiate $eid $node
# FUNCTION
#   Creates a new virtual node for a given node in imunes. 
#   Procedure router.frr.instantiate cretaes a new virtual node with all
#   the interfaces and CPU parameters as defined in imunes. It sets the
#   net.inet.ip.forwarding and net.inet6.ip6.forwarding kernel variables to 1.
# INPUTS
#   * eid - experiment id
#   * node - node id (type of the node is router and routing model is frr)
#****
proc $MODULE.instantiate { eid node } {
    l3node.instantiate $eid $node
}

proc $MODULE.setupNamespace { eid node } {
    l3node.setupNamespace $eid $node
}

proc $MODULE.initConfigure { eid node } {
    l3node.initConfigure $eid $node

    enableIPforwarding $eid $node
}

proc $MODULE.createIfcs { eid node ifcs } {
    l3node.createIfcs $eid $node $ifcs
}

#****f* frr.tcl/router.frr.start
# NAME
#   router.frr.start -- start
# SYNOPSIS
#   router.frr.start $eid $node
# FUNCTION
#   Starts a new router.frr. The node can be started if it is instantiated. 
#   Simulates the booting proces of a router.frr, by calling l3node.start 
#   procedure.
# INPUTS
#   * eid - experiment id
#   * node - node id (type of the node is router.frr)
#****
proc $MODULE.start { eid node } {
    l3node.start $eid $node
}

#****f* frr.tcl/router.frr.shutdown
# NAME
#   router.frr.shutdown -- shutdown
# SYNOPSIS
#   router.frr.shutdown $eid $node
# FUNCTION
#   Shutdowns a router.frr. Simulates the shutdown proces of a
#   router.frr, by calling the l3node.shutdown procedure.
# INPUTS
#   * eid - experiment id
#   * node - node id (type of the node is router.frr)
#****
proc $MODULE.shutdown { eid node } {
    l3node.shutdown $eid $node
}

proc $MODULE.destroyIfcs { eid node ifcs } {
    l3node.destroyIfcs $eid $node $ifcs
}

#****f* frr.tcl/router.frr.destroy
# NAME
#   router.frr.destroy -- destroy
# SYNOPSIS
#   router.frr.destroy $eid $node
# FUNCTION
#   Destroys a router.frr. Destroys all the interfaces of the router.frr 
#   and the vimage itself by calling l3node.destroy procedure. 
# INPUTS
#   * eid - experiment id
#   * node - node id (type of the node is router.frr)
#****
proc $MODULE.destroy { eid node } {
    l3node.destroy $eid $node
}

#****f* frr.tcl/router.frr.nghook
# NAME
#   router.frr.nghook -- nghook
# SYNOPSIS
#   router.frr.nghook $eid $node $ifc 
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

