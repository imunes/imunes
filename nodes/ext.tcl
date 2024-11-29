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
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id
    global nodeNamingBase

    set nconfig [list \
	"hostname [getNewNodeNameType ext $nodeNamingBase(ext)]" \
	! ]
    lappend $node_id "network-config [list $nconfig]"
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
    global changeAddressRange changeAddressRange6 mac_byte4 mac_byte5

    set changeAddressRange 0
    set changeAddressRange6 0

    autoIPv4addr $node_id $iface_id
    autoIPv6addr $node_id $iface_id
    randomizeMACbytes
    autoMACaddr $node_id $iface_id
}

#****f* ext.tcl/ext.icon
# NAME
#   ext.icon -- icon
# SYNOPSIS
#   ext.icon $size
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
	    return $ROOTDIR/$LIBDIR/icons/normal/ext.gif
	}
	small {
	    return $ROOTDIR/$LIBDIR/icons/small/ext.gif
	}
	toolbar {
	    return $ROOTDIR/$LIBDIR/icons/tiny/ext.gif
	}
    }
}

#****f* ext.tcl/ext.toolbarIconDescr
# NAME
#   ext.toolbarIconDescr -- toolbar icon description
# SYNOPSIS
#   ext.toolbarIconDescr
# FUNCTION
#   Returns this module's toolbar icon description.
# RESULT
#   * descr -- string describing the toolbar icon
#****
proc $MODULE.toolbarIconDescr {} {
    return "Add new External connection"
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
proc $MODULE.ifacePrefix { l r } {
    return [l3IfcName $l $r]
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
    return [l3node.nghook $eid $node_id $iface_id]
}

#****f* ext.tcl/ext.configGUI
# NAME
#   ext.configGUI -- configuration GUI
# SYNOPSIS
#   ext.configGUI $c $node_id
# FUNCTION
#   Defines the structure of the ext configuration window by calling
#   procedures for creating and organising the window, as well as
#   procedures for adding certain modules to that window.
# INPUTS
#   * c -- tk canvas
#   * node_id -- node id
#****
proc $MODULE.configGUI { c node_id } {
    set iface_id [lindex [ifcList $node_id] 0]
    if { "$iface_id" == "" } {
	return
    }

    global wi
    global guielements treecolumns
    set guielements {}
    set treecolumns {}

    configGUI_createConfigPopupWin $c
    wm title $wi "ext configuration"
    configGUI_nodeName $wi $node_id "Node name:"

    configGUI_externalIfcs $wi $node_id

    configGUI_buttonsACNode $wi $node_id
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

proc $MODULE.nodePhysIfacesCreate { eid node_id ifaces } {
    l2node.nodePhysIfacesCreate $eid $node_id $ifaces
}

#****f* ext.tcl/ext.nodeConfigure
# NAME
#   ext.nodeConfigure -- start
# SYNOPSIS
#   ext.nodeConfigure $eid $node_id
# FUNCTION
#   Starts a new ext. The node can be started if it is instantiated.
#   Simulates the booting proces of a ext, by calling l3node.nodeConfigure procedure.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeConfigure { eid node_id } {
    set iface_id [lindex [ifcList $node_id] 0]
    if { "$iface_id" != "" } {
	configureExternalConnection $eid $node_id
    }
}

################################################################################
############################# TERMINATE PROCEDURES #############################
################################################################################

proc $MODULE.nodeIfacesDestroy { eid node_id ifaces } {
    l2node.nodeIfacesDestroy $eid $node_id $ifaces
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
