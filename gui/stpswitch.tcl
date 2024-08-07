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

#****h* imunes/stpswitch.tcl
# NAME
#  stpswitch.tcl -- defines stpswitch specific procedures
# FUNCTION
#  This module is used to define all the stpswitch specific procedures.
# NOTES
#  Procedures in this module start with the keyword stpswitch and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE stpswitch

proc $MODULE.toolbarIconDescr {} {
    return "Add new RSTP switch"
}

proc $MODULE.icon { size } {
    global ROOTDIR LIBDIR

    switch $size {
	normal {
	    return $ROOTDIR/$LIBDIR/icons/normal/stpswitch.gif
	}
	small {
	    return $ROOTDIR/$LIBDIR/icons/small/stpswitch.gif
	}
	toolbar {
	    return $ROOTDIR/$LIBDIR/icons/tiny/stpswitch.gif
	}
    }
}

proc $MODULE.notebookDimensions { wi } {
    set h 340
    set w 507

    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Interfaces" } {
	set h 320
    }
    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Bridge" } {
	set h 370
	set w 513
    }

    return [list $h $w]
}

#****f* stpswitch.tcl/stpswitch.configGUI
# NAME
#   stpswitch.configGUI
# SYNOPSIS
#   stpswitch.configGUI $c $node_id
# FUNCTION
#   Defines the structure of the stpswitch configuration window
#   by calling procedures for creating and organising the
#   window, as well as procedures for adding certain modules
#   to that window.
# INPUTS
#   * c - tk canvas
#   * node_id - node id
#****
proc $MODULE.configGUI { c node_id } {
    global wi
    global guielements treecolumns
    global brguielements
    global brtreecolumns

    set guielements {}
    set brguielements {}

    configGUI_createConfigPopupWin $c
    wm title $wi "stpswitch configuration"
    configGUI_nodeName $wi $node_id "Node name:"

    set tabs [configGUI_addNotebook $wi $node_id {"Configuration" "Interfaces" \
    "Bridge"}]
    set configtab [lindex $tabs 0]
    set ifctab [lindex $tabs 1]
    set bridgeifctab [lindex $tabs 2]

    set treecolumns { "OperState State" "NatState Nat" "IPv4addr IPv4 addr" \
	"IPv6addr IPv6 addr" "MACaddr MAC addr" "MTU MTU" \
	"QLen Queue len" "QDisc Queue disc" "QDrop Queue drop"}
    configGUI_addTree $ifctab $node_id

    set brtreecolumns { "Snoop Snoop" "Stp STP" "Priority Priority" \
	"Discover Discover" "Learn Learn" "Sticky Sticky" "Private Private" \
	"Edge Edge" "Autoedge AutoEdge" "Ptp Ptp" "Autoptp AutoPtp" \
	"Maxaddr Max addr" "Pathcost Pathcost" }
    configGUI_addBridgeTree $bridgeifctab $node_id

    configGUI_bridgeConfig $configtab $node_id
    # TODO: are these needed?
    configGUI_staticRoutes $configtab $node_id
    configGUI_customConfig $configtab $node_id

    configGUI_buttonsACNode $wi $node_id
}


#****f* stpswitch.tcl/stpswitch.configInterfacesGUI
# NAME
#   stpswitch.configInterfacesGUI
# SYNOPSIS
#   stpswitch.configInterfacesGUI $wi $node_id $iface_id
# FUNCTION
#   Defines which modules for changing interfaces parameters
#   are contained in the stpswitch configuration window. It is done
#   by calling procedures for adding certain modules to the window.
# INPUTS
#   * wi - widget
#   * node_id - node id
#   * iface_id - interface id
#****
proc $MODULE.configInterfacesGUI { wi node_id iface_id } {
    global guielements

    configGUI_ifcEssentials $wi $node_id $iface_id
    configGUI_ifcQueueConfig $wi $node_id $iface_id
    configGUI_ifcMACAddress $wi $node_id $iface_id
    configGUI_ifcIPv4Address $wi $node_id $iface_id
    configGUI_ifcIPv6Address $wi $node_id $iface_id
}

proc $MODULE.configBridgeInterfacesGUI { wi node_id iface_id } {
    global guielements

    configGUI_ifcBridgeAttributes $wi $node_id $iface_id
}
