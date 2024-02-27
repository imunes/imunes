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
#   extnat.confNewIfc $node $ifc
# FUNCTION
#   Configures new interface for the specified node.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
#****
proc $MODULE.confNewIfc { node ifc } {
    global changeAddressRange changeAddressRange6 mac_byte4 mac_byte5
    set changeAddressRange 0
    set changeAddressRange6 0
    autoIPv4addr $node $ifc
    autoIPv6addr $node $ifc
    randomizeMACbytes
    autoMACaddr $node $ifc
}

#****f* extnat.tcl/extnat.confNewNode
# NAME
#   extnat.confNewNode -- configure new node
# SYNOPSIS
#   extnat.confNewNode $node
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node -- node id
#****
proc $MODULE.confNewNode { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set nconfig [list \
	"hostname UNASSIGNED" \
	! ]
    lappend $node "network-config [list $nconfig]"
}

#****f* extnat.tcl/extnat.icon
# NAME
#   extnat.icon -- icon
# SYNOPSIS
#   extnat.icon $size
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
	return $ROOTDIR/$LIBDIR/icons/normal/extnat.gif
      }
      small {
	return $ROOTDIR/$LIBDIR/icons/small/extnat.gif
      }
      toolbar {
	return $ROOTDIR/$LIBDIR/icons/tiny/extnat.gif
      }
    }
}

#****f* extnat.tcl/extnat.toolbarIconDescr
# NAME
#   extnat.toolbarIconDescr -- toolbar icon description
# SYNOPSIS
#   extnat.toolbarIconDescr
# FUNCTION
#   Returns this module's toolbar icon description.
# RESULT
#   * descr -- string describing the toolbar icon
#****
proc $MODULE.toolbarIconDescr {} {
    return "Add new External NAT connection"
}

#****f* extnat.tcl/extnat.ifcName
# NAME
#   extnat.ifcName -- interface name
# SYNOPSIS
#   extnat.ifcName
# FUNCTION
#   Returns pc interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifcName {l r} {
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

#****f* extnat.tcl/extnat.layer
# NAME
#   extnat.layer -- layer
# SYNOPSIS
#   set layer [extnat.layer]
# FUNCTION
#   Returns the layer on which the pc communicates, i.e. returns NETWORK. 
# RESULT
#   * layer -- set to NETWORK
#****
proc $MODULE.layer {} {
    return NETWORK
}

#****f* extnat.tcl/extnat.virtlayer
# NAME
#   extnat.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [extnat.virtlayer]
# FUNCTION
#   Returns the layer on which the pc is instantiated i.e. returns NETGRAPH.
# RESULT
#   * layer -- set to NETGRAPH
#****
proc $MODULE.virtlayer {} {
    return NETGRAPH
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

#****f* extnat.tcl/extnat.instantiate
# NAME
#   extnat.instantiate -- instantiate
# SYNOPSIS
#   extnat.instantiate $eid $node
# FUNCTION
#   Procedure instantiate creates a new virtaul node
#   for a given node in imunes.
#   Procedure extnat.instantiate cretaes a new virtual node with
#   all the interfaces and CPU parameters as defined in imunes. 
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is pc)
#****
proc $MODULE.instantiate { eid node } {}

#****f* extnat.tcl/extnat.start
# NAME
#   extnat.start -- start
# SYNOPSIS
#   extnat.start $eid $node
# FUNCTION
#   Starts a new extnat. The node can be started if it is instantiated.
#   Simulates the booting proces of a pc, by calling l3node.start procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is pc)
#****
proc $MODULE.start { eid node } {
    set ifc [lindex [ifcList $node] 0]
    if { "$ifc" != "" } {
	startExternalConnection $eid $node
	setupExtNat $eid $node $ifc
    }
}

#****f* extnat.tcl/extnat.shutdown
# NAME
#   extnat.shutdown -- shutdown
# SYNOPSIS
#   extnat.shutdown $eid $node
# FUNCTION
#   Shutdowns a extnat. Simulates the shutdown proces of a pc, 
#   by calling the l3node.shutdown procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is pc)
#****
proc $MODULE.shutdown { eid node } {
    set ifc [lindex [ifcList $node] 0]
    if { "$ifc" != "" } {
	killExtProcess "wireshark.*[getNodeName $node].*\\($eid\\)"
	killExtProcess "xterm -T Capturing $eid-$node -e tcpdump -ni $eid-$node"
	stopExternalConnection $eid $node
	unsetupExtNat $eid $node $ifc
    }
}

#****f* extnat.tcl/extnat.destroy
# NAME
#   extnat.destroy -- destroy
# SYNOPSIS
#   extnat.destroy $eid $node
# FUNCTION
#   Destroys a extnat. Destroys all the interfaces of the pc 
#   and the vimage itself by calling l3node.destroy procedure. 
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is pc)
#****
proc $MODULE.destroy { eid node } {
    set ifc [lindex [ifcList $node] 0]
    if { "$ifc" != "" } {
	destroyNetgraphNode $eid $node
    }
}

#****f* extnat.tcl/extnat.nghook
# NAME
#   extnat.nghook -- nghook
# SYNOPSIS
#   extnat.nghook $eid $node $ifc 
# FUNCTION
#   Returns the id of the netgraph node and the name of the netgraph hook
#   which is used for connecting two netgraph nodes. This procedure calls
#   l3node.hook procedure and passes the result of that procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#   * ifc -- interface name
# RESULT
#   * nghook -- the list containing netgraph node id and the 
#     netgraph hook (ngNode ngHook).
#****
proc $MODULE.nghook { eid node ifc } {
    return [l3node.nghook $eid $node $ifc]
}

#****f* extnat.tcl/extnat.configGUI
# NAME
#   extnat.configGUI -- configuration GUI
# SYNOPSIS
#   extnat.configGUI $c $node
# FUNCTION
#   Defines the structure of the pc configuration window by calling
#   procedures for creating and organising the window, as well as
#   procedures for adding certain modules to that window.
# INPUTS
#   * c -- tk canvas
#   * node -- node id
#****
proc $MODULE.configGUI { c node } {
    set ifc [lindex [ifcList $node] 0]
    if { "$ifc" == "" } {
	return
    }

    global wi
    global guielements treecolumns
    set guielements {}
    set treecolumns {}

    configGUI_createConfigPopupWin $c
    wm title $wi "extnat configuration"
    configGUI_nodeName $wi $node "Host interface:"

    configGUI_externalIfcs $wi $node

    configGUI_buttonsACNode $wi $node
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
