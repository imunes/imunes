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

# $Id: ext.tcl 63 2013-10-03 12:17:50Z valter $


#****h* imunes/ext.tcl
# NAME
#  ext.tcl -- defines ext specific procedures
# FUNCTION
#  This module is used to define all the ext specific procedures.
# NOTES
#  Procedures in this module start with the keyword ext and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE ext
registerModule $MODULE

################################################################################
########################### CONFIGURATION PROCEDURES ###########################
################################################################################

#****f* ext.tcl/ext.confNewNode
# NAME
#   ext.confNewNode -- configure new node
# SYNOPSIS
#   ext.confNewNode $node_id
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node_id -- node id
#****
proc $MODULE.confNewNode { node_id } {
    global nodeNamingBase

    setNodeName $node_id [getNewNodeNameType ext $nodeNamingBase(ext)]
    setNodeNATIface $node_id "UNASSIGNED"
}

#****f* ext.tcl/ext.confNewIfc
# NAME
#   ext.confNewIfc -- configure new interface
# SYNOPSIS
#   ext.confNewIfc $node_id $iface_id
# FUNCTION
#   Configures new interface for the specified node.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface name
#****
proc $MODULE.confNewIfc { node_id iface_id } {
    global mac_byte4 mac_byte5

    autoIPv4addr $node_id $iface_id
    autoIPv6addr $node_id $iface_id

    set bkp_mac_byte4 $mac_byte4
    set bkp_mac_byte5 $mac_byte5
    randomizeMACbytes
    autoMACaddr $node_id $iface_id
    set mac_byte4 $bkp_mac_byte4
    set mac_byte5 $bkp_mac_byte5
}

proc $MODULE.generateConfigIfaces { node_id ifaces } {
}

proc $MODULE.generateUnconfigIfaces { node_id ifaces } {
}

proc $MODULE.generateConfig { node_id } {
}

proc $MODULE.generateUnconfig { node_id } {
}

#****f* ext.tcl/ext.ifacePrefix
# NAME
#   ext.ifacePrefix -- interface name
# SYNOPSIS
#   ext.ifacePrefix
# FUNCTION
#   Returns ext interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifacePrefix {} {
    return "ext"
}

#****f* ext.tcl/ext.IPAddrRange
# NAME
#   ext.IPAddrRange -- IP address range
# SYNOPSIS
#   ext.IPAddrRange
# FUNCTION
#   Returns ext IP address range
# RESULT
#   * range -- ext IP address range
#****
proc $MODULE.IPAddrRange {} {
    return 20
}

#****f* ext.tcl/ext.netlayer
# NAME
#   ext.netlayer -- layer
# SYNOPSIS
#   set layer [ext.netlayer]
# FUNCTION
#   Returns the layer on which the ext communicates, i.e. returns NETWORK.
# RESULT
#   * layer -- set to NETWORK
#****
proc $MODULE.netlayer {} {
    return NETWORK
}

#****f* ext.tcl/ext.virtlayer
# NAME
#   ext.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [ext.virtlayer]
# FUNCTION
#   Returns the layer on which the ext is instantiated i.e. returns NATIVE.
# RESULT
#   * layer -- set to NATIVE
#****
proc $MODULE.virtlayer {} {
    return NATIVE
}

proc $MODULE.bootcmd { node_id } {
}

#****f* ext.tcl/ext.shellcmds
# NAME
#   ext.shellcmds -- shell commands
# SYNOPSIS
#   set shells [ext.shellcmds]
# FUNCTION
#   Procedure shellcmds returns the shells that can be opened
#   as a default shell for the system.
# RESULT
#   * shells -- default shells for the ext node
#****
proc $MODULE.shellcmds {} {
}

#****f* ext.tcl/ext.nghook
# NAME
#   ext.nghook -- nghook
# SYNOPSIS
#   ext.nghook $eid $node_id $iface_id
# FUNCTION
#   Returns the id of the netgraph node and the name of the netgraph hook
#   which is used for connecting two netgraph nodes. This procedure calls
#   l3node.hook procedure and passes the result of that procedure.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * iface_id -- interface name
# RESULT
#   * nghook -- the list containing netgraph node id and the
#     netgraph hook (ngNode ngHook).
#****
proc $MODULE.nghook { eid node_id iface_id } {
    return [list $node_id-[getIfcName $node_id $iface_id] ether]
}

#****f* ext.tcl/ext.maxLinks
# NAME
#   ext.maxLinks -- maximum number of links
# SYNOPSIS
#   ext.maxLinks
# FUNCTION
#   Returns ext node maximum number of links.
# RESULT
#   * maximum number of links.
#****
proc $MODULE.maxLinks {} {
    return 1
}

################################################################################
############################ INSTANTIATE PROCEDURES ############################
################################################################################

#****f* ext.tcl/ext.prepareSystem
# NAME
#   ext.prepareSystem -- prepare system
# SYNOPSIS
#   ext.prepareSystem
# FUNCTION
#   Does nothing
#****
proc $MODULE.prepareSystem {} {
    catch { exec kldload ipfilter }
    catch { sysctl net.inet.ip.forwarding=1 }
}

#****f* ext.tcl/ext.nodeCreate
# NAME
#   ext.nodeCreate -- instantiate
# SYNOPSIS
#   ext.nodeCreate $eid $node_id
# FUNCTION
#   Creates an ext node.
#   Does nothing, as it is not created per se.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeCreate { eid node_id } {
}

#****f* ext.tcl/ext.nodeNamespaceSetup
# NAME
#   ext.nodeNamespaceSetup -- ext node nodeNamespaceSetup
# SYNOPSIS
#   ext.nodeNamespaceSetup $eid $node_id
# FUNCTION
#   Linux only. Attaches the existing Docker netns to a new one.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeNamespaceSetup { eid node_id } {
}

#****f* ext.tcl/ext.nodeInitConfigure
# NAME
#   ext.nodeInitConfigure -- ext node nodeInitConfigure
# SYNOPSIS
#   ext.nodeInitConfigure $eid $node_id
# FUNCTION
#   Runs initial L3 configuration, such as creating logical interfaces and
#   configuring sysctls.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeInitConfigure { eid node_id } {
}

proc $MODULE.nodePhysIfacesCreate { eid node_id ifaces } {
    nodePhysIfacesCreate $node_id $ifaces
}

proc $MODULE.nodeLogIfacesCreate { eid node_id ifaces } {
}

#****f* ext.tcl/ext.nodeIfacesConfigure
# NAME
#   ext.nodeIfacesConfigure -- configure ext node interfaces
# SYNOPSIS
#   ext.nodeIfacesConfigure $eid $node_id $ifaces
# FUNCTION
#   Configure interfaces on a ext. Set MAC, MTU, queue parameters, assign the IP
#   addresses to the interfaces, etc. This procedure can be called if the node
#   is instantiated.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifaces -- list of interface ids
#****
proc $MODULE.nodeIfacesConfigure { eid node_id ifaces } {
    set iface_id [lindex [ifcList $node_id] 0]
    if { "$iface_id" != "" } {
	configureExternalConnection $eid $node_id
    }
}

#****f* ext.tcl/ext.nodeConfigure
# NAME
#   ext.nodeConfigure -- start
# SYNOPSIS
#   ext.nodeConfigure $eid $node_id
# FUNCTION
#   Starts a new ext. The node can be started if it is instantiated.
#   Simulates the booting proces of a ext, by calling l3node.nodeConfigure procedure.
#   Sets up the NAT for the given interface if assigned.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeConfigure { eid node_id } {
    set iface_id [lindex [ifcList $node_id] 0]
    if { "$iface_id" != "" && [getNodeNATIface $node_id] != "UNASSIGNED" } {
        setupExtNat $eid $node_id $iface_id
    }
}

################################################################################
############################# TERMINATE PROCEDURES #############################
################################################################################

#****f* ext.tcl/ext.nodeIfacesUnconfigure
# NAME
#   ext.nodeIfacesUnconfigure -- unconfigure ext node interfaces
# SYNOPSIS
#   ext.nodeIfacesUnconfigure $eid $node_id $ifaces
# FUNCTION
#   Unconfigure interfaces on an ext to a default state. Set name to iface_id,
#   flush IP addresses to the interfaces, etc. This procedure can be called if
#   the node is instantiated.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifaces -- list of interface ids
#****
proc $MODULE.nodeIfacesUnconfigure { eid node_id ifaces } {
    set iface_id [lindex [ifcList $node_id] 0]
    if { "$iface_id" != "" } {
	unconfigureExternalConnection $eid $node_id
    }
}

proc $MODULE.nodeIfacesDestroy { eid node_id ifaces } {
    nodeIfacesDestroy $eid $node_id $ifaces
}

proc $MODULE.nodeUnconfigure { eid node_id } {
    set iface_id [lindex [ifcList $node_id] 0]
    if { "$iface_id" != "" && [getNodeNATIface $node_id] != "UNASSIGNED" } {
        unsetupExtNat $eid $node_id $iface_id
    }
}

#****f* ext.tcl/ext.nodeShutdown
# NAME
#   ext.nodeShutdown -- shutdown
# SYNOPSIS
#   ext.nodeShutdown $eid $node_id
# FUNCTION
#   Shutdowns an ext node.
#   It kills all external packet sniffers and sets the interface down.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeShutdown { eid node_id } {
    set iface_id [lindex [ifcList $node_id] 0]
    if { "$iface_id" != "" } {
	killExtProcess "wireshark.*[getNodeName $node_id].*\\($eid\\)"
	killExtProcess "xterm -name imunes-terminal -T Capturing $eid-$node_id -e tcpdump -ni $eid-$node_id"
	stopExternalConnection $eid $node_id
    }
}

#****f* ext.tcl/ext.nodeDestroy
# NAME
#   ext.nodeDestroy -- destroy
# SYNOPSIS
#   ext.nodeDestroy $eid $node_id
# FUNCTION
#   Destroys an ext node.
#   Does nothing, as it is not created.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeDestroy { eid node_id } {
}
