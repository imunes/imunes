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

# $Id: rj45.tcl 130 2015-02-24 09:52:19Z valter $


#****h* imunes/rj45.tcl
# NAME
#  rj45.tcl -- defines rj45 specific procedures
# FUNCTION
#  This module is used to define all the rj45 specific procedures.
# NOTES
#  Procedures in this module start with the keyword rj45 and
#  end with function specific part that is the same for all the
#  node types that work on the same layer.
#****

set MODULE rj45
registerModule $MODULE

################################################################################
########################### CONFIGURATION PROCEDURES ###########################
################################################################################

#****f* rj45.tcl/rj45.confNewNode
# NAME
#   rj45.confNewNode -- configure new node
# SYNOPSIS
#   rj45.confNewNode $node
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

#****f* rj45.tcl/rj45.ifacePrefix
# NAME
#   rj45.ifacePrefix -- interface name prefix
# SYNOPSIS
#   rj45.ifacePrefix
# FUNCTION
#   Returns rj45 interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifacePrefix { l r } {
    return ""
}

#****f* rj45.tcl/rj45.netlayer
# NAME
#   rj45.netlayer -- layer
# SYNOPSIS
#   set layer [rj45.netlayer]
# FUNCTION
#   Returns the layer on which the rj45 operates, i.e. returns LINK.
# RESULT
#   * layer -- set to LINK
#****
proc $MODULE.netlayer {} {
    return LINK
}

#****f* rj45.tcl/rj45.virtlayer
# NAME
#   rj45.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [rj45.virtlayer]
# FUNCTION
#   Returns the layer on which the rj45 node is instantiated,
#   i.e. returns NATIVE.
# RESULT
#   * layer -- set to NATIVE
#****
proc $MODULE.virtlayer {} {
    return NATIVE
}

#****f* rj45.tcl/rj45.nghook
# NAME
#   rj45.nghook
# SYNOPSIS
#   rj45.nghook $eid $node $ifc
# FUNCTION
#   Returns the id of the netgraph node and the netgraph hook name. In this
#   case netgraph node name correspondes to the name of the physical interface.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#   * ifc -- interface id
# RESULT
#   * nghook -- the list containing netgraph node name and
#     the netraph hook name (in this case: lower).
#****
proc $MODULE.nghook { eid node ifc } {
    set ifname [getNodeName $node]
    if { [getEtherVlanEnabled $node] } {
	set vlan [getEtherVlanTag $node]
	set ifname ${ifname}_$vlan
    }

    return [list $ifname lower]
}

#****f* rj45.tcl/rj45.maxLinks
# NAME
#   rj45.maxLinks -- maximum number of links
# SYNOPSIS
#   rj45.maxLinks
# FUNCTION
#   Returns rj45 maximum number of links.
# RESULT
#   * maximum number of links.
#****
proc $MODULE.maxLinks {} {
    return 1
}

################################################################################
############################ INSTANTIATE PROCEDURES ############################
################################################################################

#****f* rj45.tcl/rj45.prepareSystem
# NAME
#   rj45.prepareSystem -- prepare system
# SYNOPSIS
#   rj45.prepareSystem
# FUNCTION
#   Loads ng_ether into the kernel.
#****
proc $MODULE.prepareSystem {} {
    catch { exec kldload ng_ether }
}

#****f* rj45.tcl/rj45.nodeCreate
# NAME
#   rj45.nodeCreate -- instantiate
# SYNOPSIS
#   rj45.nodeCreate $eid $node
# FUNCTION
#   Procedure rj45.nodeCreate puts real interface into promiscuous mode.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc $MODULE.nodeCreate { eid node } {
    captureExtIfc $eid $node
}

################################################################################
############################# TERMINATE PROCEDURES #############################
################################################################################

#****f* rj45.tcl/rj45.nodeDestroy
# NAME
#   rj45.nodeDestroy -- destroy
# SYNOPSIS
#   rj45.nodeDestroy $eid $node
# FUNCTION
#   Destroys an rj45 emulation interface.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc $MODULE.nodeDestroy { eid node } {
    releaseExtIfc $eid $node
}

################################################################################
################################ GUI PROCEDURES ################################
################################################################################

#****f* rj45.tcl/rj45.icon
# NAME
#   rj45.icon -- icon
# SYNOPSIS
#   rj45.icon $size
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
	    return $ROOTDIR/$LIBDIR/icons/normal/rj45.gif
	}
	small {
	    return $ROOTDIR/$LIBDIR/icons/small/rj45.gif
	}
	toolbar {
	    return $ROOTDIR/$LIBDIR/icons/tiny/rj45.gif
	}
    }
}

#****f* rj45.tcl/rj45.toolbarIconDescr
# NAME
#   rj45.toolbarIconDescr -- toolbar icon description
# SYNOPSIS
#   rj45.toolbarIconDescr
# FUNCTION
#   Returns this module's toolbar icon description.
# RESULT
#   * descr -- string describing the toolbar icon
#****
proc $MODULE.toolbarIconDescr {} {
    return "Add new External interface"
}

#****f* rj45.tcl/rj45.configGUI
# NAME
#   rj45.configGUI -- configuration GUI
# SYNOPSIS
#   rj45.configGUI $c $node
# FUNCTION
#   Defines the structure of the rj45 configuration window by calling
#   procedures for creating and organising the window, as well as procedures
#   for adding certain modules to that window.
# INPUTS
#   * c -- tk canvas
#   * node -- node id
#****
proc $MODULE.configGUI { c node } {
    global wi
    global guielements treecolumns

    set guielements {}
    set treecolumns {}

    configGUI_createConfigPopupWin $c
    wm title $wi "rj45 configuration"
    configGUI_nodeName $wi $node "Physical interface:"
    configGUI_etherVlan $wi $node
    configGUI_buttonsACNode $wi $node
}
