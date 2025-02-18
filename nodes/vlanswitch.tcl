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


#****h* imunes/vlanswitch.tcl
# NAME
#  vlanswitch.tcl -- defines vlanswitch specific procedures
# FUNCTION
#  This module is used to define all the vlanswitch specific procedures.
# NOTES
#  Procedures in this module start with the keyword vlanswitch and
#  end with function specific part that is the same for all the
#  node types that work on the same layer.
#****

set MODULE vlanswitch
registerModule $MODULE

################################################################################
########################### CONFIGURATION PROCEDURES ###########################
################################################################################

#****f* vlanswitch.tcl/vlanswitch.confNewNode
# NAME
#   vlanswitch.confNewNode -- configure new node
# SYNOPSIS
#   vlanswitch.confNewNode $node_id
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node_id -- node id
#****
proc $MODULE.confNewNode { node_id } {
    global nodeNamingBase

    setNodeName $node_id [getNewNodeNameType vlanswitch $nodeNamingBase(vlanswitch)]
}

#****f* vlanswitch.tcl/vlanswitch.confNewIfc
# NAME
#   vlanswitch.confNewIfc -- configure new interface
# SYNOPSIS
#   vlanswitch.confNewIfc $node_id $iface_id
# FUNCTION
#   Configures new interface for the specified node.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface name
#****
proc $MODULE.confNewIfc { node_id iface_id } {
}

proc $MODULE.generateConfigIfaces { node_id ifaces } {
}

proc $MODULE.generateUnconfigIfaces { node_id ifaces } {
}

proc $MODULE.generateConfig { node_id } {
}

proc $MODULE.generateUnconfig { node_id } {
}

#****f* vlanswitch.tcl/vlanswitch.ifacePrefix
# NAME
#   vlanswitch.ifacePrefix -- interface name
# SYNOPSIS
#   vlanswitch.ifacePrefix
# FUNCTION
#   Returns vlanswitch interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifacePrefix {} {
    return "e"
}

proc $MODULE.IPAddrRange {} {
}

#****f* vlanswitch.tcl/vlanswitch.netlayer
# NAME
#   vlanswitch.netlayer -- layer
# SYNOPSIS
#   set layer [vlanswitch.netlayer]
# FUNCTION
#   Returns the layer on which the vlanswitch operates, i.e. returns LINK.
# RESULT
#   * layer -- set to LINK
#****
proc $MODULE.netlayer {} {
    return LINK
}

#****f* vlanswitch.tcl/vlanswitch.virtlayer
# NAME
#   vlanswitch.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [vlanswitch.virtlayer]
# FUNCTION
#   Returns the layer on which the vlanswitch node is instantiated
#   i.e. returns NATIVE.
# RESULT
#   * layer -- set to NATIVE
#****
proc $MODULE.virtlayer {} {
    return NATIVE
}

proc $MODULE.bootcmd { node_id } {
}

proc $MODULE.shellcmds {} {
}

#****f* vlanswitch.tcl/vlanswitch.nghook
# NAME
#   vlanswitch.nghook -- nghook
# SYNOPSIS
#   set nghook [vlanswitch.nghook $eid $node_id $iface_id]
# FUNCTION
#   Returns the id of the netgraph node and the name of the netgraph hook
#   which is used for connecting two netgraph nodes. Netgraph node name is in
#   format experimentId_nodeId and the netgraph hook is in the form of linkN,
#   where N is an interface number.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * iface_id -- interface name
# RESULT
#   * nghook -- the list containing netgraph node id and the
#     netgraph hook (ngNode ngHook).
#****
proc $MODULE.nghook { eid node_id iface_id } {
    set ifunit [expr [string range $iface_id 3 end] + 1]
    set vlantag [getIfcVlanTag $node_id $iface_id]
    set hook_name "v$vlantag"

    if { [getIfcVlanType $node_id $iface_id] == "trunk" } {
        return [list "$node_id-downstream" "link$ifunit"]
    } else {
        return [list "$node_id-$hook_name" "link$ifunit"]
    }
}

################################################################################
############################ INSTANTIATE PROCEDURES ############################
################################################################################

#****f* vlanswitch.tcl/vlanswitch.prepareSystem
# NAME
#   vlanswitch.prepareSystem -- prepare system
# SYNOPSIS
#   vlanswitch.prepareSystem
# FUNCTION
#   Loads ng_bridge into the kernel.
#****
proc $MODULE.prepareSystem {} {
    catch { exec sysctl net.bridge.bridge-nf-call-arptables=0 }
    catch { exec sysctl net.bridge.bridge-nf-call-iptables=0 }
    catch { exec sysctl net.bridge.bridge-nf-call-ip6tables=0 }

    catch { exec kldload ng_bridge }
    catch { exec kldload ng_vlan }
    catch { exec kldload ng_hole }
}

#****f* vlanswitch.tcl/vlanswitch.nodeCreate
# NAME
#   vlanswitch.nodeCreate -- instantiate
# SYNOPSIS
#   vlanswitch.nodeCreate $eid $node_id
# FUNCTION
#   Procedure vlanswitch.nodeCreate creates a new netgraph node of the type
#   bridge. The name of the netgraph node is in the form of exprimentId_nodeId.
# INPUTS
#   * eid -- experiment id
#   * node_id -- id of the node
#****
proc $MODULE.nodeCreate { eid node_id } {
    l2node.nodeCreate $eid $node_id
}

proc $MODULE.nodeNamespaceSetup { eid node_id } {
    createNamespace $eid-$node_id
}

proc $MODULE.nodeInitConfigure { eid node_id } {
}

proc $MODULE.nodePhysIfacesCreate { eid node_id ifaces } {
    nodePhysIfacesCreate $node_id $ifaces
}

proc $MODULE.nodeLogIfacesCreate { eid node_id ifaces } {
    #nodeLogIfacesCreate $node_id $ifaces
}

#****f* exec.tcl/vlanswitch.nodeIfacesConfigure
# NAME
#   vlanswitch.nodeIfacesConfigure -- configure vlanswitch node interfaces
# SYNOPSIS
#   vlanswitch.nodeIfacesConfigure $eid $node_id $ifaces
# FUNCTION
#   Configure interfaces on a vlanswitch. Set MAC, MTU, queue parameters, assign the IP
#   addresses to the interfaces, etc. This procedure can be called if the node
#   is instantiated.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifaces -- list of interface ids
#****
proc $MODULE.nodeIfacesConfigure { eid node_id ifaces } {
    #startNodeIfaces $node_id $ifaces
}

#****f* exec.tcl/vlanswitch.nodeConfigure
# NAME
#   vlanswitch.nodeConfigure -- configure vlanswitch node
# SYNOPSIS
#   vlanswitch.nodeConfigure $eid $node_id
# FUNCTION
#   Starts a new vlanswitch. Simulates the booting proces of a node, starts all the
#   services, etc.
#   This procedure can be called if it is instantiated.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifaces -- list of interface ids
#****
proc $MODULE.nodeConfigure { eid node_id } {
    #runConfOnNode $node_id
}

################################################################################
############################# TERMINATE PROCEDURES #############################
################################################################################

proc $MODULE.nodeIfacesUnconfigure { eid node_id ifaces } {
    #unconfigNodeIfaces $eid $node_id $ifaces

    foreach iface_id $ifaces {
        execDelIfcVlanConfig $eid $node_id $iface_id
    }
}

proc $MODULE.nodeIfacesDestroy { eid node_id ifaces } {
    nodeIfacesDestroy $eid $node_id $ifaces
}

proc $MODULE.nodeUnconfigure { eid node_id } {
    #unconfigNode $eid $node_id
}

proc $MODULE.nodeShutdown { eid node_id } {
}

#****f* vlanswitch.tcl/vlanswitch.nodeDestroy
# NAME
#   vlanswitch.nodeDestroy -- destroy
# SYNOPSIS
#   vlanswitch.nodeDestroy $eid $node_id
# FUNCTION
#   Destroys a vlanswitch. Destroys the netgraph node that represents
#   the vlanswitch by sending a shutdown message.
# INPUTS
#   * eid -- experiment id
#   * node_id -- id of the node
#****
proc $MODULE.nodeDestroy { eid node_id } {
    l2node.nodeDestroy $eid $node_id
}
