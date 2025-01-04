#
# Copyright 2005-2010 University of Zagreb, Croatia.
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

#****h* imunes/packgen.tcl
# NAME
#  packgen.tcl -- defines packgen.specific procedures
# FUNCTION
#  This module is used to define all the packgen.specific procedures.
# NOTES
#  Procedures in this module start with the keyword packgen and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE packgen
registerModule $MODULE

################################################################################
########################### CONFIGURATION PROCEDURES ###########################
################################################################################

#****f* packgen.tcl/packgen.confNewNode
# NAME
#   packgen.confNewNode -- configure new node
# SYNOPSIS
#   packgen.confNewNode $node_id
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node_id -- node id
#****
proc $MODULE.confNewNode { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id
    global nodeNamingBase

    set nconfig [list \
	"hostname [getNewNodeNameType packgen $nodeNamingBase(packgen)]" \
	! ]
    lappend $node_id "network-config [list $nconfig]"
}

#****f* packgen.tcl/packgen.confNewIfc
# NAME
#   packgen.confNewIfc -- configure new interface
# SYNOPSIS
#   packgen.confNewIfc $node_id $iface_id
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

#****f* packgen.tcl/packgen.ifacePrefix
# NAME
#   packgen.ifacePrefix -- interface name prefix
# SYNOPSIS
#   packgen.ifacePrefix
# FUNCTION
#   Returns packgen interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifacePrefix {} {
    return "e"
}

proc $MODULE.IPAddrRange {} {
}

#****f* packgen.tcl/packgen.netlayer
# NAME
#   packgen.netlayer
# SYNOPSIS
#   set layer [packgen.netlayer]
# FUNCTION
#   Returns the layer on which the packgen.communicates
#   i.e. returns LINK.
# RESULT
#   * layer -- set to LINK
#****
proc $MODULE.netlayer {} {
    return LINK
}

#****f* packgen.tcl/packgen.virtlayer
# NAME
#   packgen.virtlayer
# SYNOPSIS
#   set layer [packgen.virtlayer]
# FUNCTION
#   Returns the layer on which the packgen is instantiated
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

#****f* packgen.tcl/packgen.nghook
# NAME
#   packgen.nghook
# SYNOPSIS
#   packgen.nghook $eid $node_id $iface_id
# FUNCTION
#   Returns the id of the netgraph node and the name of the
#   netgraph hook which is used for connecting two netgraph
#   nodes.
# INPUTS
#   * eid - experiment id
#   * node_id - node id
#   * iface_id - interface id
# RESULT
#   * nghook - the list containing netgraph node id and the
#     netgraph hook (ngNode ngHook).
#****
proc $MODULE.nghook { eid node_id iface_id } {
    return [list $node_id output]
}

#****f* packgen.tcl/packgen.maxLinks
# NAME
#   packgen.maxLinks -- maximum number of links
# SYNOPSIS
#   packgen.maxLinks
# FUNCTION
#   Returns packgen maximum number of links.
# RESULT
#   * maximum number of links.
#****
proc $MODULE.maxLinks {} {
    return 1
}

################################################################################
############################ INSTANTIATE PROCEDURES ############################
################################################################################

proc $MODULE.prepareSystem {} {
    catch { exec kldload ng_source }
}

#****f* packgen.tcl/packgen.nodeCreate
# NAME
#   packgen.nodeCreate
# SYNOPSIS
#   packgen.nodeCreate $eid $node_id
# FUNCTION
#   Procedure packgen.nodeCreate creates a new virtual node
#   with all the interfaces and CPU parameters as defined
#   in imunes.
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node
#****
proc $MODULE.nodeCreate { eid node_id } {
    pipesExec "printf \"
    mkpeer . source inhook input \n
    msg .inhook setpersistent \n name .:inhook $node_id
    \" | jexec $eid ngctl -f -" "hold"
}

proc $MODULE.nodeNamespaceSetup { eid node_id } {
}

proc $MODULE.nodeInitConfigure { eid node_id } {
}

proc $MODULE.nodePhysIfacesCreate { eid node_id ifaces } {
    nodePhysIfacesCreate $node_id $ifaces
}

proc $MODULE.nodeLogIfacesCreate { eid node_id ifaces } {
}

#****f* packgen.tcl/packgen.nodeIfacesConfigure
# NAME
#   packgen.nodeIfacesConfigure -- configure packgen node interfaces
# SYNOPSIS
#   packgen.nodeIfacesConfigure $eid $node_id $ifaces
# FUNCTION
#   Configure interfaces on a packgen. Set MAC, MTU, queue parameters, assign the IP
#   addresses to the interfaces, etc. This procedure can be called if the node
#   is instantiated.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifaces -- list of interface ids
#****
proc $MODULE.nodeIfacesConfigure { eid node_id ifaces } {
}

#****f* packgen.tcl/packgen.nodeConfigure
# NAME
#   packgen.nodeConfigure
# SYNOPSIS
#   packgen.nodeConfigure $eid $node_id
# FUNCTION
#   Starts a new packgen. The node can be started if it is instantiated.
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node
#****
proc $MODULE.nodeConfigure { eid node_id } {
    foreach packet [packgenPackets $node_id] {
	set fd [open "| jexec $eid nghook $node_id: input" w]
	fconfigure $fd -encoding binary

	set pdata [getPackgenPacketData $node_id [lindex $packet 0]]
	set bin [binary format H* $pdata]
	puts -nonewline $fd $bin

	catch { close $fd }
    }

    set pps [getPackgenPacketRate $node_id]

    pipesExec "jexec $eid ngctl msg $node_id: setpps $pps" "hold"

    set iface_id [lindex [ifcList $node_id] 0]
    if { $iface_id != "" && [getIfcLink $node_id $iface_id] != "" } {
	pipesExec "jexec $eid ngctl msg $node_id: start [expr 2**63]" "hold"
    }
}

################################################################################
############################# TERMINATE PROCEDURES #############################
################################################################################

proc $MODULE.nodeIfacesUnconfigure { eid node_id ifaces } {
}

proc $MODULE.nodeIfacesDestroy { eid node_id ifaces } {
    nodeIfacesDestroy $eid $node_id $ifaces
}

proc $MODULE.nodeUnconfigure { eid node_id } {
    pipesExec "jexec $eid ngctl msg $node_id: clrdata" "hold"
    pipesExec "jexec $eid ngctl msg $node_id: stop" "hold"
}

#****f* packgen.tcl/packgen.nodeShutdown
# NAME
#   packgen.nodeShutdown
# SYNOPSIS
#   packgen.nodeShutdown $eid $node_id
# FUNCTION
#   Shutdowns a packgen. Simulates the shutdown proces of a packgen.
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node
#****
proc $MODULE.nodeShutdown { eid node_id } {
}

#****f* packgen.tcl/packgen.nodeDestroy
# NAME
#   packgen.nodeDestroy
# SYNOPSIS
#   packgen.nodeDestroy $eid $node_id
# FUNCTION
#   Destroys a packgen. Destroys all the interfaces of the packgen.
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node
#****
proc $MODULE.nodeDestroy { eid node_id } {
    pipesExec "jexec $eid ngctl msg $node_id: shutdown" "hold"
}

################################################################################
################################ GUI PROCEDURES ################################
################################################################################

proc $MODULE.icon { size } {
    global ROOTDIR LIBDIR

    switch $size {
	normal {
	    return $ROOTDIR/$LIBDIR/icons/normal/packgen.gif
	}
	small {
	    return $ROOTDIR/$LIBDIR/icons/small/packgen.gif
	}
	toolbar {
	    return $ROOTDIR/$LIBDIR/icons/tiny/packgen.gif
	}
    }
}

proc $MODULE.toolbarIconDescr {} {
    return "Add new Packet generator"
}

proc $MODULE.notebookDimensions { wi } {
    set h 430
    set w 652

    return [list $h $w]
}

#****f* packgen.tcl/packgen.configGUI
# NAME
#   packgen.configGUI
# SYNOPSIS
#   packgen.configGUI $c $node_id
# FUNCTION
#   Defines the structure of the packgen configuration window
#   by calling procedures for creating and organising the
#   window, as well as procedures for adding certain modules
#   to that window.
# INPUTS
#   * c - tk canvas
#   * node_id - node id
#****
proc $MODULE.configGUI { c node_id } {
    global wi
    global packgenguielements packgentreecolumns curnode

    set curnode $node_id
    set packgenguielements {}

    configGUI_createConfigPopupWin $c
    wm title $wi "packet generator configuration"
    configGUI_nodeName $wi $node_id "Node name:"

    set tabs [configGUI_addNotebookPackgen $wi $node_id]

    configGUI_packetRate [lindex $tabs 0] $node_id

    set packgentreecolumns { "Data Data" }
    foreach tab $tabs {
	configGUI_addTreePackgen $tab $node_id
    }

    configGUI_buttonsACPackgenNode $wi $node_id
}

#****f* packgen.tcl/packgen.configInterfacesGUI
# NAME
#   packgen.configInterfacesGUI
# SYNOPSIS
#   packgen.configInterfacesGUI $wi $node_id $pac
# FUNCTION
#   Defines which modules for changing interfaces parameters
#   are contained in the packgen.configuration window. It is done
#   by calling procedures for adding certain modules to the window.
# INPUTS
#   * wi - widget
#   * node_id - node_id id
#   * pac - packet id
#****
proc $MODULE.configPacketsGUI { wi node_id pac } {
    global packgenguielements

    configGUI_packetConfig $wi $node_id $pac
}
