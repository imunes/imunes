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

# $Id: lanswitch.tcl 129 2015-02-13 11:14:44Z valter $


#****h* imunes/lanswitch.tcl
# NAME
#  lanswitch.tcl -- defines lanswitch specific procedures
# FUNCTION
#  This module is used to define all the lanswitch specific procedures.
# NOTES
#  Procedures in this module start with the keyword lanswitch and
#  end with function specific part that is the same for all the
#  node types that work on the same layer.
#****

set MODULE lanswitch

registerModule $MODULE

#****f* lanswitch.tcl/lanswitch.prepareSystem
# NAME
#   lanswitch.prepareSystem -- prepare system
# SYNOPSIS
#   lanswitch.prepareSystem
# FUNCTION
#   Loads ng_bridge into the kernel.
#****
proc $MODULE.prepareSystem {} {
    catch { exec sysctl net.bridge.bridge-nf-call-arptables=0 }
    catch { exec sysctl net.bridge.bridge-nf-call-iptables=0 }
    catch { exec sysctl net.bridge.bridge-nf-call-ip6tables=0 }

    catch { exec kldload ng_bridge }
}

#****f* lanswitch.tcl/lanswitch.confNewIfc
# NAME
#   lanswitch.confNewIfc -- configure new interface
# SYNOPSIS
#   lanswitch.confNewIfc $node_id $iface_id
# FUNCTION
#   Configures new interface for the specified node.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface name
#****
proc $MODULE.confNewIfc { node_id iface_id } {
}

#****f* lanswitch.tcl/lanswitch.confNewNode
# NAME
#   lanswitch.confNewNode -- configure new node
# SYNOPSIS
#   lanswitch.confNewNode $node_id
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node_id -- node id
#****
proc $MODULE.confNewNode { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id
    global nodeNamingBase

    set nconfig [list \
	"hostname [getNewNodeNameType lanswitch $nodeNamingBase(lanswitch)]" \
	! ]
    lappend $node_id "network-config [list $nconfig]"
}

#****f* lanswitch.tcl/lanswitch.icon
# NAME
#   lanswitch.icon --
# SYNOPSIS
#   lanswitch.icon $size
# FUNCTION
#   Returns path to node icon, depending on the specified size.
# INPUTS
#   * size -- "normal", "small" or "toolbar"
# RESULT
#   * path -- path to icon
#****
proc $MODULE.icon { size } {
    global ROOTDIR LIBDIR

    switch $size {
	normal {
	    return $ROOTDIR/$LIBDIR/icons/normal/lanswitch.gif
	}
	small {
	    return $ROOTDIR/$LIBDIR/icons/small/lanswitch.gif
	}
	toolbar {
	    return $ROOTDIR/$LIBDIR/icons/tiny/lanswitch.gif
	}
    }
}

#****f* lanswitch.tcl/lanswitch.toolbarIconDescr
# NAME
#   lanswitch.toolbarIconDescr -- toolbar icon description
# SYNOPSIS
#   lanswitch.toolbarIconDescr
# FUNCTION
#   Returns this module's toolbar icon description.
# RESULT
#   * descr -- string describing the toolbar icon
#****
proc $MODULE.toolbarIconDescr {} {
    return "Add new LAN switch"
}

#****f* lanswitch.tcl/lanswitch.ifacePrefix
# NAME
#   lanswitch.ifacePrefix -- interface name
# SYNOPSIS
#   lanswitch.ifacePrefix
# FUNCTION
#   Returns lanswitch interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifacePrefix { l r } {
    return e
}

#****f* lanswitch.tcl/lanswitch.netlayer
# NAME
#   lanswitch.netlayer -- layer
# SYNOPSIS
#   set layer [lanswitch.netlayer]
# FUNCTION
#   Returns the layer on which the lanswitch operates, i.e. returns LINK.
# RESULT
#   * layer -- set to LINK
#****
proc $MODULE.netlayer {} {
    return LINK
}

#****f* lanswitch.tcl/lanswitch.virtlayer
# NAME
#   lanswitch.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [lanswitch.virtlayer]
# FUNCTION
#   Returns the layer on which the lanswitch node is instantiated
#   i.e. returns NATIVE.
# RESULT
#   * layer -- set to NATIVE
#****
proc $MODULE.virtlayer {} {
    return NATIVE
}

#****f* lanswitch.tcl/lanswitch.nodeCreate
# NAME
#   lanswitch.nodeCreate -- instantiate
# SYNOPSIS
#   lanswitch.nodeCreate $eid $node_id
# FUNCTION
#   Procedure lanswitch.nodeCreate creates a new netgraph node of the type
#   bridge. The name of the netgraph node is in the form of exprimentId_nodeId.
# INPUTS
#   * eid -- experiment id
#   * node_id -- id of the node (type of the node is lanswitch)
#****
proc $MODULE.nodeCreate { eid node_id } {
    l2node.nodeCreate $eid $node_id
}

proc $MODULE.nodeNamespaceSetup { eid node_id } {
    l2node.nodeNamespaceSetup $eid $node_id
}

proc $MODULE.nodePhysIfacesCreate { eid node_id ifcs } {
    l2node.nodePhysIfacesCreate $eid $node_id $ifcs
}

proc $MODULE.destroyIfcs { eid node_id ifcs } {
    l2node.destroyIfcs $eid $node_id $ifcs
}

#****f* lanswitch.tcl/lanswitch.destroy
# NAME
#   lanswitch.destroy -- destroy
# SYNOPSIS
#   lanswitch.destroy $eid $node_id
# FUNCTION
#   Destroys a lanswitch. Destroys the netgraph node that represents
#   the lanswitch by sending a shutdown message.
# INPUTS
#   * eid -- experiment id
#   * node_id -- id of the node (type of the node is lanswitch)
#****
proc $MODULE.destroy { eid node_id } {
    l2node.destroy $eid $node_id
}

#****f* lanswitch.tcl/lanswitch.nghook
# NAME
#   lanswitch.nghook -- nghook
# SYNOPSIS
#   set nghook [lanswitch.nghook $eid $node_id $iface_id]
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
    set ifunit [string range $iface_id 1 end]
    return [list $node_id link$ifunit]
}

#****f* lanswitch.tcl/lanswitch.configGUI
# NAME
#   lanswitch.configGUI -- configuration GUI
# SYNOPSIS
#   lanswitch.configGUI $c $node_id
# FUNCTION
#   Defines the structure of the lanswitch configuration window by calling
#   procedures for creating and organising the window, as well as procedures
#   for adding certain modules to that window.
# INPUTS
#   * c -- tk canvas
#   * node_id -- node id
#****
proc $MODULE.configGUI { c node_id } {
    global wi
    global guielements treecolumns
    set guielements {}

    configGUI_createConfigPopupWin $c
    wm title $wi "lanswitch configuration"
    configGUI_nodeName $wi $node_id "Node name:"

    configGUI_addPanedWin $wi
    set treecolumns { "QLen Queue len" "QDisc Queue disc" "QDrop Queue drop" }
    configGUI_addTree $wi $node_id

    configGUI_buttonsACNode $wi $node_id
}

#****f* lanswitch.tcl/lanswitch.configInterfacesGUI
# NAME
#   lanswitch.configInterfacesGUI -- configuration of interfaces GUI
# SYNOPSIS
#   lanswitch.configInterfacesGUI $wi $node_id $iface_id
# FUNCTION
#   Defines which modules for changing interfaces parameters are contained in
#   the lanswitch configuration window. It is done by calling procedures for
#   adding certain modules to the window.
# INPUTS
#   * wi -- widget
#   * node_id -- node id
#   * iface_id -- interface id
#****
proc $MODULE.configInterfacesGUI { wi node_id iface_id } {
    global guielements

    configGUI_ifcQueueConfig $wi $node_id $iface_id
}

#****f* lanswitch.tcl/lanswitch.maxLinks
# NAME
#   lanswitch.maxLinks -- maximum number of links
# SYNOPSIS
#   lanswitch.maxLinks
# FUNCTION
#   Returns lanswitch maximum number of links.
# RESULT
#   * maximum number of links.
#****
proc $MODULE.maxLinks {} {
    return 32
}
