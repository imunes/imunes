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

# $Id: extnat.tcl 63 2023-11-01 17:45:50Z dsalopek $


#****h* imunes/extnat.tcl
# NAME
#  extnat.tcl -- defines extnat specific procedures
# FUNCTION
#  This module is used to define all the extnat specific procedures.
# NOTES
#  Procedures in this module start with the keyword extnat and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE extnat

registerModule $MODULE

#****f* extnat.tcl/extnat.prepareSystem
# NAME
#   extnat.prepareSystem -- prepare system
# SYNOPSIS
#   extnat.prepareSystem
# FUNCTION
#   Loads ipfilter into the kernel.
#****
proc $MODULE.prepareSystem {} {
    catch { exec kldload ipfilter }
}

#****f* extnat.tcl/extnat.confNewIfc
# NAME
#   extnat.confNewIfc -- configure new interface
# SYNOPSIS
#   extnat.confNewIfc $node_id $iface_id
# FUNCTION
#   Configures new interface for the specified node.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
#****
proc $MODULE.confNewIfc { node_id iface_id } {
    global changeAddressRange changeAddressRange6 mac_byte4 mac_byte5

    set changeAddressRange 0
    set changeAddressRange6 0
    autoIPv4addr $node_id $iface_id
    autoIPv6addr $node_id $iface_id
    randomizeMACbytes
    autoMACaddr $node_id $iface_id
}

#****f* extnat.tcl/extnat.confNewNode
# NAME
#   extnat.confNewNode -- configure new node
# SYNOPSIS
#   extnat.confNewNode $node_id
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node_id -- node id
#****
proc $MODULE.confNewNode { node_id } {
    setNodeName $node_id "UNASSIGNED"
}

#****f* extnat.tcl/extnat.ifacePrefix
# NAME
#   extnat.ifacePrefix -- interface name prefix
# SYNOPSIS
#   extnat.ifacePrefix
# FUNCTION
#   Returns pc interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifacePrefix { l r } {
    return [l3IfcName $l $r]
}

#****f* extnat.tcl/extnat.IPAddrRange
# NAME
#   extnat.IPAddrRange -- IP address range
# SYNOPSIS
#   extnat.IPAddrRange
# FUNCTION
#   Returns pc IP address range
# RESULT
#   * range -- pc IP address range
#****
proc $MODULE.IPAddrRange {} {
    return 20
}

#****f* extnat.tcl/extnat.netlayer
# NAME
#   extnat.netlayer -- layer
# SYNOPSIS
#   set layer [extnat.netlayer]
# FUNCTION
#   Returns the layer on which the pc communicates, i.e. returns NETWORK.
# RESULT
#   * layer -- set to NETWORK
#****
proc $MODULE.netlayer {} {
    return NETWORK
}

#****f* extnat.tcl/extnat.virtlayer
# NAME
#   extnat.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [extnat.virtlayer]
# FUNCTION
#   Returns the layer on which the pc is instantiated i.e. returns NATIVE.
# RESULT
#   * layer -- set to NATIVE
#****
proc $MODULE.virtlayer {} {
    return NATIVE
}

#****f* extnat.tcl/extnat.shellcmds
# NAME
#   extnat.shellcmds -- shell commands
# SYNOPSIS
#   set shells [extnat.shellcmds]
# FUNCTION
#   Procedure shellcmds returns the shells that can be opened
#   as a default shell for the system.
# RESULT
#   * shells -- default shells for the pc node
#****
proc $MODULE.shellcmds {} {
}

#****f* extnat.tcl/extnat.nodeCreate
# NAME
#   extnat.nodeCreate -- instantiate
# SYNOPSIS
#   extnat.nodeCreate $eid $node_id
# FUNCTION
#   Procedure instantiate creates a new virtaul node
#   for a given node in imunes.
#   Procedure extnat.nodeCreate cretaes a new virtual node with
#   all the interfaces and CPU parameters as defined in imunes.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id (type of the node is pc)
#****
proc $MODULE.nodeCreate { eid node_id } {}

proc $MODULE.nodePhysIfacesCreate { eid node_id ifaces } {
    l2node.nodePhysIfacesCreate $eid $node_id $ifaces
}

#****f* extnat.tcl/extnat.nodeConfigure
# NAME
#   extnat.nodeConfigure -- start
# SYNOPSIS
#   extnat.nodeConfigure $eid $node_id
# FUNCTION
#   Starts a new extnat. The node can be started if it is instantiated.
#   Simulates the booting proces of a pc, by calling l3node.nodeConfigure procedure.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id (type of the node is pc)
#****
proc $MODULE.nodeConfigure { eid node_id } {
    set iface_id [lindex [ifcList $node_id] 0]
    if { "$iface_id" != "" } {
	startExternalConnection $eid $node_id
	setupExtNat $eid $node_id $iface_id
    }
}

#****f* extnat.tcl/extnat.nodeShutdown
# NAME
#   extnat.nodeShutdown -- shutdown
# SYNOPSIS
#   extnat.nodeShutdown $eid $node_id
# FUNCTION
#   Shutdowns a extnat. Simulates the shutdown proces of a pc,
#   by calling the l3node.nodeShutdown procedure.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id (type of the node is pc)
#****
proc $MODULE.nodeShutdown { eid node_id } {
    set iface_id [lindex [ifcList $node_id] 0]
    if { "$iface_id" != "" } {
	killExtProcess "wireshark.*[getNodeName $node_id].*\\($eid\\)"
	killExtProcess "xterm -name imunes-terminal -T Capturing $eid-$node_id -e tcpdump -ni $eid-$node_id"
	stopExternalConnection $eid $node_id
	unsetupExtNat $eid $node_id $iface_id
    }
}

proc $MODULE.destroyIfcs { eid node_id ifaces } {
    l2node.destroyIfcs $eid $node_id $ifaces
}

#****f* extnat.tcl/extnat.nodeDestroy
# NAME
#   extnat.nodeDestroy -- destroy
# SYNOPSIS
#   extnat.nodeDestroy $eid $node_id
# FUNCTION
#   Destroys a extnat. Destroys all the interfaces of the pc
#   and the vimage itself by calling l3node.nodeDestroy procedure.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id (type of the node is pc)
#****
proc $MODULE.nodeDestroy { eid node_id } {
}

#****f* extnat.tcl/extnat.nghook
# NAME
#   extnat.nghook -- nghook
# SYNOPSIS
#   extnat.nghook $eid $node_id $iface_id
# FUNCTION
#   Returns the id of the netgraph node and the name of the netgraph hook
#   which is used for connecting two netgraph nodes. This procedure calls
#   l3node.hook procedure and passes the result of that procedure.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * iface_id -- interface id
# RESULT
#   * nghook -- the list containing netgraph node id and the
#     netgraph hook (ngNode ngHook).
#****
proc $MODULE.nghook { eid node_id iface_id } {
    return [l3node.nghook $eid $node_id $iface_id]
}

#****f* extnat.tcl/extnat.maxLinks
# NAME
#   extnat.maxLinks -- maximum number of links
# SYNOPSIS
#   extnat.maxLinks
# FUNCTION
#   Returns extnat node maximum number of links.
# RESULT
#   * maximum number of links.
#****
proc $MODULE.maxLinks {} {
    return 1
}
