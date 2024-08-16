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

################################################################################
########################### CONFIGURATION PROCEDURES ###########################
################################################################################

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

#****f* pc.tcl/pc.nghook
# NAME
#   pc.nghook -- nghook
# SYNOPSIS
#   pc.nghook $eid $node_id $iface_id
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
	return [list $node-[getIfcName $node_id $iface_id] ether]
}

################################################################################
############################ INSTANTIATE PROCEDURES ############################
################################################################################

#****f* pc.tcl/pc.prepareSystem
# NAME
#   pc.prepareSystem -- prepare system
# SYNOPSIS
#   pc.prepareSystem
# FUNCTION
#   Does nothing
#****
proc $MODULE.prepareSystem {} {
	# nothing to do
}

#****f* pc.tcl/pc.nodeCreate
# NAME
#   pc.nodeCreate -- nodeCreate
# SYNOPSIS
#   pc.nodeCreate $eid $node_id
# FUNCTION
#   Creates a new virtualized pc node (using jails/docker).
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeCreate { eid node_id } {
    prepareFilesystemForNode $node_id
    createNodeContainer $node_id
}

#****f* pc.tcl/pc.nodeSetupNamespace
# NAME
#   pc.nodeSetupNamespace -- pc node nodeSetupNamespace
# SYNOPSIS
#   pc.nodeSetupNamespace $eid $node_id
# FUNCTION
#   Linux only. Attaches the existing Docker netns to a new one.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeSetupNamespace { eid node_id } {
    disconnectFromDocker $node_id
    attachToL3NodeNamespace $node_id
}

#****f* pc.tcl/pc.nodeInitConfigure
# NAME
#   pc.nodeInitConfigure -- pc node nodeInitConfigure
# SYNOPSIS
#   pc.nodeInitConfigure $eid $node_id
# FUNCTION
#   Runs initial L3 configuration, such as creating logical interfaces and
#   configuring sysctls.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeInitConfigure { eid node_id } {
    createNodeLogIfcs $node_id
    configureICMPoptions $node_id
}

proc $MODULE.nodeIfacesCreate { eid node_id ifaces } {
    createNodePhysIfcs $node_id $ifaces
}

#****f* pc.tcl/pc.nodeIfacesConfigure
# NAME
#   pc.nodeIfacesConfigure -- configure pc node interfaces
# SYNOPSIS
#   pc.nodeIfacesConfigure $eid $node_id $ifaces
# FUNCTION
#   Configure interfaces on a pc. Set MAC, MTU, queue parameters, assign the IP
#   addresses to the interfaces, etc. This procedure can be called if the node
#   is instantiated.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifaces -- list of interface ids
#****
proc $MODULE.nodeIfacesConfigure { eid node_id ifaces } {
    startNodeIfaces $node_id $ifaces
}

#****f* pc.tcl/pc.nodeConfigure
# NAME
#   pc.nodeConfigure -- configure pc node
# SYNOPSIS
#   pc.nodeConfigure $eid $node_id
# FUNCTION
#   Starts a new pc. Simulates the booting proces of a node, starts all the
#   services, etc.
#   This procedure can be called if it is instantiated.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifaces -- list of interface ids
#****
proc $MODULE.nodeConfigure { eid node_id } {
    runConfOnNode $node_id
}

################################################################################
############################# TERMINATE PROCEDURES #############################
################################################################################

#****f* pc.tcl/pc.nodeIfacesUnconfigure
# NAME
#   pc.nodeIfacesUnconfigure -- unconfigure pc node interfaces
# SYNOPSIS
#   pc.nodeIfacesUnconfigure $eid $node_id $ifaces
# FUNCTION
#   Unconfigure interfaces on a pc to a default state. Set name to iface_id,
#   flush IP addresses to the interfaces, etc. This procedure can be called if
#   the node is instantiated.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifaces -- list of interface ids
#****
proc $MODULE.nodeIfacesUnconfigure { eid node_id ifaces } {
    unconfigNodeIfaces $eid $node_id $ifaces
}

proc $MODULE.destroyIfcs { eid node_id ifaces } {
    destroyNodeIfaces $eid $node_id $ifaces
}

proc $MODULE.nodeUnconfigure { eid node_id } {
    unconfigNode $eid $node_id
}

#****f* pc.tcl/pc.nodeShutdown
# NAME
#   pc.nodeShutdown -- layer 3 node nodeShutdown
# SYNOPSIS
#   pc.nodeShutdown $eid $node
# FUNCTION
#   Shutdowns a pc node.
#   Simulates the shutdown proces of a node, kills all the services and
#   processes.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc $MODULE.nodeShutdown { eid node_id } {
    killExtProcess "wireshark.*[getNodeName $node].*\\($eid\\)"
    killAllNodeProcesses $eid $node
}

#****f* pc.tcl/pc.nodeDestroy
# NAME
#   pc.nodeDestroy -- layer 3 node destroy
# SYNOPSIS
#   pc.nodeDestroy $eid $node
# FUNCTION
#   Destroys a pc node.
#   First, it destroys all remaining virtual ifaces (vlans, tuns, etc).
#   Then, it destroys the jail/container with its namespaces and FS.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc $MODULE.nodeDestroy { eid node_id } {
    destroyNodeVirtIfcs $eid $node
    removeNodeContainer $eid $node
    destroyNamespace $eid-$node
    removeNodeFS $eid $node
}
