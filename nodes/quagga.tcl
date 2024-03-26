# 2019-2020 Sorbonne University
# In this version of imunes we added a full integration of emulation of 
# Linux namespaces and CISCO routers, saving of parameters, VLANs, WiFi 
# emulation and other features
# This work was developed by Benadji Hanane and Oulad Said Chawki
# Supervised and maintained by Naceur Malouch - LIP6/SU
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

# $Id: quagga.tcl 128 2014-12-19 11:59:09Z denis $


#****h* imunes/quagga.tcl
# NAME
#  router.quagga.tcl -- defines specific procedures for router 
#  using quagga routing model
# FUNCTION
#  This module defines all the specific procedures for a router
#  which uses quagga routing model.
# NOTES
#  Procedures in this module start with the keyword router.quagga and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE router.quagga

#****f* quagga.tcl/router.quagga.layer
# NAME
#   router.quagga.layer -- layer
# SYNOPSIS
#   set layer [router.quagga.layer]
# FUNCTION
#   Returns the layer on which the router using quagga model
#   operates, i.e. returns NETWORK. 
# RESULT
#   * layer -- set to NETWORK
#****
proc $MODULE.layer {} {
    return NETWORK
}

#****f* quagga.tcl/router.quagga.virtlayer
# NAME
#   router.quagga.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [router.quagga.virtlayer]
# FUNCTION
#   Returns the layer on which the router using model quagga is instantiated,
#   i.e. returns VIMAGE. 
# RESULT
#   * layer -- set to VIMAGE
#****
proc $MODULE.virtlayer {} {
    return VIMAGE
}

#****f* quagga.tcl/router.quagga.cfggen
# NAME
#   router.quagga.cfggen -- configuration generator
# SYNOPSIS
#   set config [router.quagga.cfggen $node]
# FUNCTION
#   Generates configuration. This configuration represents the default
#   configuration loaded on the booting time of the virtual nodes and it is
#   closly related to the procedure router.quagga.bootcmd.
#   Generated configuration comprises the ip addresses (both ipv4 and ipv6)
#   and interface states (up or down) for each interface of a given node.
#   Static routes are also included.
# INPUTS
#   * node - node id (type of the node is router and routing model is quagga)
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

    return $cfg
}

#****f* quagga.tcl/router.quagga.bootcmd
# NAME
#   router.quagga.bootcmd -- boot command
# SYNOPSIS
#   set appl [router.quagga.bootcmd $node]
# FUNCTION
#   Procedure bootcmd returns the defaut application that reads and employes
#   the configuration generated in router.quagga.cfggen.
#   In this case (procedure router.quagga.bootcmd) specific application
#   is quaggaboot.sh
# INPUTS
#   * node - node id (type of the node is router and routing model is quagga)
# RESULT
#   * appl -- application that reads the configuration (quaggaboot.sh) 
#****
proc $MODULE.bootcmd { node } {

    return "/usr/local/bin/quaggaboot.sh"
}

#****f* quagga.tcl/router.quagga.shellcmds
# NAME
#   router.quagga.shellcmds -- shell commands
# SYNOPSIS
#   set shells [router.quagga.shellcmds]
# FUNCTION
#   Procedure shellcmds returns the shells that can be opened
#   as a default shell for the system. 
# RESULT
#   * shells -- default shells for the router.quagga
#****
proc $MODULE.shellcmds {} {
    return "csh bash vtysh sh tcsh"
}

#****f* quagga.tcl/router.quagga.instantiate
# NAME
#   router.quagga.instantiate -- instantiate
# SYNOPSIS
#   router.quagga.instantiate $eid $node
# FUNCTION
#   Creates a new virtual node for a given node in imunes. 
#   Procedure router.quagga.instantiate cretaes a new virtual node with all
#   the interfaces and CPU parameters as defined in imunes. It sets the
#   net.inet.ip.forwarding and net.inet6.ip6.forwarding kernel variables to 1.
# INPUTS
#   * eid - experiment id
#   * node - node id (type of the node is router and routing model is quagga)
#****
proc $MODULE.instantiate { eid node } {
    global inst_pipes last_inst_pipe

    l3node.instantiate $eid $node

    enableIPforwarding $eid $node
}

#****f* quagga.tcl/router.quagga.start
# NAME
#   router.quagga.start -- start
# SYNOPSIS
#   router.quagga.start $eid $node
# FUNCTION
#   Starts a new router.quagga. The node can be started if it is instantiated. 
#   Simulates the booting proces of a router.quagga, by calling l3node.start 
#   procedure.
# INPUTS
#   * eid - experiment id
#   * node - node id (type of the node is router.quagga)
#****
proc $MODULE.start { eid node } {
    l3node.start $eid $node
}

#****f* quagga.tcl/router.quagga.shutdown
# NAME
#   router.quagga.shutdown -- shutdown
# SYNOPSIS
#   router.quagga.shutdown $eid $node
# FUNCTION
#   Shutdowns a router.quagga. Simulates the shutdown proces of a
#   router.quagga, by calling the l3node.shutdown procedure.
# INPUTS
#   * eid - experiment id
#   * node - node id (type of the node is router.quagga)
#****
proc $MODULE.shutdown { eid node } {
    l3node.shutdown $eid $node
}

#****f* quagga.tcl/router.quagga.destroy
# NAME
#   router.quagga.destroy -- destroy
# SYNOPSIS
#   router.quagga.destroy $eid $node
# FUNCTION
#   Destroys a router.quagga. Destroys all the interfaces of the router.quagga 
#   and the vimage itself by calling l3node.destroy procedure. 
# INPUTS
#   * eid - experiment id
#   * node - node id (type of the node is router.quagga)
#****
proc $MODULE.destroy { eid node } {
    l3node.destroy $eid $node
}

#****f* quagga.tcl/router.quagga.nghook
# NAME
#   router.quagga.nghook -- nghook
# SYNOPSIS
#   router.quagga.nghook $eid $node $ifc 
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

#****f* quagga.tcl/configureVTYSHquagga
# NAME
#   configureVTYSHquagga
# SYNOPSIS
#   configureVTYSHquagga $eid $node
# FUNCTION
#   create vtysh.conf 
#****
#
# Modification for save.tcl
#*****
proc configureVTYSHquagga {eid node} {

   set node_id "$eid\.$node"
   exec docker exec $node_id bash -c "echo 'service integrated-vtysh-config' >> /etc/quagga/vtysh.conf"
}
