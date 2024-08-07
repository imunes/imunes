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

# $Id: pc.tcl 63 2013-10-03 12:17:50Z valter $


#****h* imunes/pc.tcl
# NAME
#  pc.tcl -- defines pc specific procedures
# FUNCTION
#  This module is used to define all the pc specific procedures.
# NOTES
#  Procedures in this module start with the keyword pc and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE pc
registerModule $MODULE

#****f* pc.tcl/pc.confNewIfc
# NAME
#   pc.confNewIfc -- configure new interface
# SYNOPSIS
#   pc.confNewIfc $node_id $ifc
# FUNCTION
#   Configures new interface for the specified node.
# INPUTS
#   * node_id -- node id
#   * ifc -- interface name
#****
proc $MODULE.confNewIfc { node_id ifc } {
    global changeAddressRange changeAddressRange6

    set changeAddressRange 0
    set changeAddressRange6 0
    autoIPv4addr $node_id $ifc
    autoIPv6addr $node_id $ifc
    autoMACaddr $node_id $ifc
}

#****f* pc.tcl/pc.confNewNode
# NAME
#   pc.confNewNode -- configure new node
# SYNOPSIS
#   pc.confNewNode $node_id
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node_id -- node id
#****
proc $MODULE.confNewNode { node_id } {
    global nodeNamingBase

    setNodeName $node_id [getNewNodeNameType pc $nodeNamingBase(pc)]
    setAutoDefaultRoutesStatus $node_id "enabled"

    set logiface_id [newLogIface $node_id "lo"]
    setIfcIPv4addrs $node_id $logiface_id "127.0.0.1/8"
    setIfcIPv6addrs $node_id $logiface_id "::1/128"
}

# NAME
# SYNOPSIS
# FUNCTION
# INPUTS
#****
}






}

# NAME
# SYNOPSIS
# FUNCTION
# INPUTS
# RESULT
#****
    }

}

#****f* pc.tcl/pc.ifcName
# NAME
#   pc.ifcName -- interface name
# SYNOPSIS
#   pc.ifcName
# FUNCTION
#   Returns pc interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifcName { l r } {
    return [l3IfcName $l $r]
}

#****f* pc.tcl/pc.ifacePrefix
# NAME
#   pc.ifacePrefix -- interface name
# SYNOPSIS
#   pc.ifacePrefix
# FUNCTION
#   Returns pc interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifacePrefix {} {
    return "eth"
}

#****f* pc.tcl/pc.IPAddrRange
# NAME
#   pc.IPAddrRange -- IP address range
# SYNOPSIS
#   pc.IPAddrRange
# FUNCTION
#   Returns pc IP address range
# RESULT
#   * range -- pc IP address range
#****
proc $MODULE.IPAddrRange {} {
    return 20
}

#****f* pc.tcl/pc.netlayer
# NAME
#   pc.netlayer -- layer
# SYNOPSIS
#   set layer [pc.netlayer]
# FUNCTION
#   Returns the layer on which the pc communicates, i.e. returns NETWORK.
# RESULT
#   * layer -- set to NETWORK
#****
proc $MODULE.netlayer {} {
    return NETWORK
}

#****f* pc.tcl/pc.virtlayer
# NAME
#   pc.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [pc.virtlayer]
# FUNCTION
#   Returns the layer on which the pc is instantiated i.e. returns VIMAGE.
# RESULT
#   * layer -- set to VIMAGE
#****
proc $MODULE.virtlayer {} {
    return VIMAGE
}

#****f* pc.tcl/pc.cfggen
# NAME
#   pc.cfggen -- configuration generator
# SYNOPSIS
#   set config [pc.cfggen $node_id]
# FUNCTION
#   Returns the generated configuration. This configuration represents
#   the configuration loaded on the booting time of the virtual nodes
#   and it is closly related to the procedure pc.bootcmd.
#   For each interface in the interface list of the node, ip address is
#   configured and each static route from the simulator is added.
# INPUTS
#   * node_id -- node id (type of the node is pc)
# RESULT
#   * congif -- generated configuration
#****
proc $MODULE.cfggen { node_id } {
    set cfg {}
    foreach iface [allIfcList $node_id] {
	set cfg [concat $cfg [nodeCfggenIfcIPv4 $node_id $iface]]
	set cfg [concat $cfg [nodeCfggenIfcIPv6 $node_id $iface]]
    }
    lappend cfg ""

    set cfg [concat $cfg [nodeCfggenRouteIPv4 $node_id]]
    set cfg [concat $cfg [nodeCfggenRouteIPv6 $node_id]]

    return $cfg
}

#****f* pc.tcl/pc.bootcmd
# NAME
#   pc.bootcmd -- boot command
# SYNOPSIS
#   set appl [pc.bootcmd $node_id]
# FUNCTION
#   Procedure bootcmd returns the application that reads and employes the
#   configuration generated in pc.cfggen.
#   In this case (procedure pc.bootcmd) specific application is /bin/sh
# INPUTS
#   * node_id -- node id (type of the node is pc)
# RESULT
#   * appl -- application that reads the configuration (/bin/sh)
#****
proc $MODULE.bootcmd { node_id } {
    return "/bin/sh"
}

#****f* pc.tcl/pc.shellcmds
# NAME
#   pc.shellcmds -- shell commands
# SYNOPSIS
#   set shells [pc.shellcmds]
# FUNCTION
#   Procedure shellcmds returns the shells that can be opened
#   as a default shell for the system.
# RESULT
#   * shells -- default shells for the pc node
#****
proc $MODULE.shellcmds {} {
    return "csh bash sh tcsh"
}

#****f* pc.tcl/pc.instantiate
# NAME
#   pc.instantiate -- instantiate
# SYNOPSIS
#   pc.instantiate $eid $node_id
# FUNCTION
#   Procedure instantiate creates a new virtaul node
#   for a given node in imunes.
#   Procedure pc.instantiate cretaes a new virtual node with
#   all the interfaces and CPU parameters as defined in imunes.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id (type of the node is pc)
#****
proc $MODULE.instantiate { eid node_id } {
    l3node.instantiate $eid $node_id
}

proc $MODULE.setupNamespace { eid node_id } {
    l3node.setupNamespace $eid $node_id
}

proc $MODULE.initConfigure { eid node_id } {
    l3node.initConfigure $eid $node_id
}

proc $MODULE.createIfcs { eid node_id ifcs } {
    l3node.createIfcs $eid $node_id $ifcs
}

#****f* pc.tcl/pc.start
# NAME
#   pc.start -- start
# SYNOPSIS
#   pc.start $eid $node_id
# FUNCTION
#   Starts a new pc. The node can be started if it is instantiated.
#   Simulates the booting proces of a pc, by calling l3node.start procedure.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id (type of the node is pc)
#****
proc $MODULE.start { eid node_id } {
    l3node.start $eid $node_id
}

#****f* pc.tcl/pc.shutdown
# NAME
#   pc.shutdown -- shutdown
# SYNOPSIS
#   pc.shutdown $eid $node_id
# FUNCTION
#   Shutdowns a pc. Simulates the shutdown proces of a pc,
#   by calling the l3node.shutdown procedure.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id (type of the node is pc)
#****
proc $MODULE.shutdown { eid node_id } {
    l3node.shutdown $eid $node_id
}

proc $MODULE.destroyIfcs { eid node_id ifcs } {
    l3node.destroyIfcs $eid $node_id $ifcs
}

#****f* pc.tcl/pc.destroy
# NAME
#   pc.destroy -- destroy
# SYNOPSIS
#   pc.destroy $eid $node_id
# FUNCTION
#   Destroys a pc. Destroys all the interfaces of the pc
#   and the vimage itself by calling l3node.destroy procedure.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id (type of the node is pc)
#****
proc $MODULE.destroy { eid node_id } {
    l3node.destroy $eid $node_id
}

#****f* pc.tcl/pc.nghook
# NAME
#   pc.nghook -- nghook
# SYNOPSIS
#   pc.nghook $eid $node_id $ifc
# FUNCTION
#   Returns the id of the netgraph node and the name of the netgraph hook
#   which is used for connecting two netgraph nodes. This procedure calls
#   l3node.hook procedure and passes the result of that procedure.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifc -- interface name
# RESULT
#   * nghook -- the list containing netgraph node id and the
#     netgraph hook (ngNode ngHook).
#****
proc $MODULE.nghook { eid node_id ifc } {
    return [l3node.nghook $eid $node_id $ifc]
}

# NAME
# SYNOPSIS
# FUNCTION
# INPUTS
#****
}

# NAME
# SYNOPSIS
# FUNCTION
# INPUTS
#****
}
