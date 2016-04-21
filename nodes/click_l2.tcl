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

# $Id: click_l2.tcl 63 2013-10-03 12:17:50Z valter $


#****h* imunes/click_l2.tcl
# NAME
#  click_l2.tcl -- defines click_l2 specific procedures
# FUNCTION
#  This module is used to define all the click_l2 specific procedures.
# NOTES
#  Procedures in this module start with the keyword click_l2 and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE click_l2

registerModule $MODULE

#****f* click_l2.tcl/click_l2.confNewIfc
# NAME
#   click_l2.confNewIfc -- configure new interface
# SYNOPSIS
#   click_l2.confNewIfc $node $ifc
# FUNCTION
#   Configures new interface for the specified node.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
#****
proc $MODULE.confNewIfc { node ifc } {
    foreach l2node [listLANnodes $node ""] {
	foreach ifc [ifcList $l2node] {
	    set peer [peerByIfc $l2node $ifc]
	    if { ! [isNodeRouter $peer] && \
		[[typemodel $peer].layer] == "NETWORK" } {
		set ifname [ifcByPeer $peer $l2node]
		autoIPv4defaultroute $peer $ifname
		autoIPv6defaultroute $peer $ifname
	    }
	}
    }
}

#****f* click_l2.tcl/click_l2.confNewNode
# NAME
#   click_l2.confNewNode -- configure new node
# SYNOPSIS
#   click_l2.confNewNode $node
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node -- node id
#****
proc $MODULE.confNewNode { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node
    global nodeNamingBase

    set nconfig [list \
	"hostname [getNewNodeNameType click_l2 $nodeNamingBase(click_l2)]" \
	! ]
    lappend $node "network-config [list $nconfig]"
}

#****f* click_l2.tcl/click_l2.icon
# NAME
#   click_l2.icon -- icon
# SYNOPSIS
#   click_l2.icon $size
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
	    return $ROOTDIR/$LIBDIR/icons/normal/click_l2.gif
	}
	small {
	    return $ROOTDIR/$LIBDIR/icons/small/click_l2.gif
	}
	toolbar {
	    return $ROOTDIR/$LIBDIR/icons/tiny/click_l2.gif
	}
    }
}

#****f* click_l2.tcl/click_l2.toolbarIconDescr
# NAME
#   click_l2.toolbarIconDescr -- toolbar icon description
# SYNOPSIS
#   click_l2.toolbarIconDescr
# FUNCTION
#   Returns this module's toolbar icon description.
# RESULT
#   * descr -- string describing the toolbar icon
#****
proc $MODULE.toolbarIconDescr {} {
    return "Add new Click Switch"
}

#****f* click_l2.tcl/click_l2.notebookDimensions
# NAME
#   click_l2.notebookDimensions -- notebook dimensions
# SYNOPSIS
#   click_l2.notebookDimensions $wi
# FUNCTION
#   Returns the specified notebook height and width.
# INPUTS
#   * wi -- widget
# RESULT
#   * size -- notebook size as {height width}
#****
proc $MODULE.notebookDimensions { wi } {
    set h 210
    set w 507

    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Configuration" } {
	set w 507
    }
    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Interfaces" } {
	set h 370
	set w 507
    }

    return [list $h $w] 
}

#****f* click_l2.tcl/click_l2.ifcName
# NAME
#   click_l2.ifcName -- interface name
# SYNOPSIS
#   click_l2.ifcName
# FUNCTION
#   Returns click_l2 interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifcName {l r} {
    return [l3IfcName $l $r]
}

#****f* click_l2.tcl/click_l2.layer
# NAME
#   click_l2.layer -- layer
# SYNOPSIS
#   set layer [click_l2.layer]
# FUNCTION
#   Returns the layer on which the click_l2 communicates, i.e. returns LINK. 
# RESULT
#   * layer -- set to LINK
#****
proc $MODULE.layer {} {
    return LINK
}

#****f* click_l2.tcl/click_l2.virtlayer
# NAME
#   click_l2.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [click_l2.virtlayer]
# FUNCTION
#   Returns the layer on which the click_l2 is instantiated i.e. returns VIMAGE. 
# RESULT
#   * layer -- set to VIMAGE
#****
proc $MODULE.virtlayer {} {
    return VIMAGE
}

#****f* click_l2.tcl/click_l2.cfggen
# NAME
#   click_l2.cfggen -- configuration generator
# SYNOPSIS
#   set config [click_l2.cfggen $node]
# FUNCTION
#   Returns the generated configuration. This configuration represents
#   the configuration loaded on the booting time of the virtual nodes
#   and it is closly related to the procedure click_l2.bootcmd.
#   For each interface in the interface list of the node, ip address is
#   configured and each static route from the simulator is added.
# INPUTS
#   * node -- node id (type of the node is click_l2)
# RESULT
#   * congif -- generated configuration 
#****
proc $MODULE.cfggen { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set cfg {}
    set stpEnable [getStpEnabled $node]
    if { $stpEnable == true } {
	set mac ""
	foreach ifc [allIfcList $node] {
	    if { $ifc == "[click_l2.ifcName]0" } {
		set mac [getIfcMACaddr $node $ifc]
		break
	    }
	}
	lappend cfg "stp :: EtherSpanTree($mac, in_supp, out_supp, sw);"
	lappend cfg "in_supp, out_supp :: Suppressor;"
    }
    lappend cfg "sw :: EtherSwitch(TIMEOUT 300);"
    lappend cfg ""
    foreach ifc [allIfcList $node] {
	regexp {[0-9]+} $ifc ifNum
	lappend cfg "in$ifNum :: FromDevice($ifc);"
	lappend cfg "out$ifNum :: Queue(64) -> ToDevice($ifc);"
	if { $stpEnable == true } {
	    lappend cfg "c$ifNum :: Classifier(14/4242, -);"
	    lappend cfg "in$ifNum -> c$ifNum\[0\] ->\[$ifNum\]stp\[$ifNum\] -> out$ifNum;"
	    lappend cfg "in$ifNum -> c$ifNum\[1\] -> \[$ifNum\]in_supp\[$ifNum\] -> \[$ifNum\]sw\[$ifNum\] -> \[$ifNum\]out_supp\[$ifNum\] -> out$ifNum;"
	} else {
	    lappend cfg "in$ifNum -> \[$ifNum\]sw\[$ifNum\] -> out$ifNum;"
	}
	lappend cfg ""
    }
    return $cfg
}

#****f* click_l2.tcl/click_l2.bootcmd
# NAME
#   click_l2.bootcmd -- boot command
# SYNOPSIS
#   set appl [click_l2.bootcmd $node]
# FUNCTION
#   Procedure bootcmd returns the application that reads and employes the
#   configuration generated in click_l2.cfggen.
#   In this case (procedure click_l2.bootcmd) specific application is /bin/sh
# INPUTS
#   * node -- node id (type of the node is click_l2)
# RESULT
#   * appl -- application that reads the configuration (/bin/sh) 
#****
proc $MODULE.bootcmd { node } {
    return "/usr/local/bin/click"
}

#****f* click_l2.tcl/click_l2.shellcmds
# NAME
#   click_l2.shellcmds -- shell commands
# SYNOPSIS
#   set shells [click_l2.shellcmds]
# FUNCTION
#   Procedure shellcmds returns the shells that can be opened
#   as a default shell for the system.
# RESULT
#   * shells -- default shells for the click_l2 node
#****
proc $MODULE.shellcmds {} {
    return "csh bash sh tcsh"
}

#****f* click_l2.tcl/click_l2.instantiate
# NAME
#   click_l2.instantiate -- instantiate
# SYNOPSIS
#   click_l2.instantiate $eid $node
# FUNCTION
#   Procedure instantiate creates a new virtaul node
#   for a given node in imunes.
#   Procedure click_l2.instantiate cretaes a new virtual node with
#   all the interfaces and CPU parameters as defined in imunes. 
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is click_l2)
#****
proc $MODULE.instantiate { eid node } {
    l3node.instantiate $eid $node
}

#****f* click_l2.tcl/click_l2.start
# NAME
#   click_l2.start -- start
# SYNOPSIS
#   click_l2.start $eid $node
# FUNCTION
#   Starts a new click_l2. The node can be started if it is instantiated.
#   Simulates the booting proces of a click_l2, by calling l3node.start procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is click_l2)
#****
proc $MODULE.start { eid node } {
    l3node.start $eid $node
}

#****f* click_l2.tcl/click_l2.shutdown
# NAME
#   click_l2.shutdown -- shutdown
# SYNOPSIS
#   click_l2.shutdown $eid $node
# FUNCTION
#   Shutdowns a click_l2. Simulates the shutdown proces of a click_l2, 
#   by calling the l3node.shutdown procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is click_l2)
#****
proc $MODULE.shutdown { eid node } {
    l3node.shutdown $eid $node
}

#****f* click_l2.tcl/click_l2.destroy
# NAME
#   click_l2.destroy -- destroy
# SYNOPSIS
#   click_l2.destroy $eid $node
# FUNCTION
#   Destroys a click_l2. Destroys all the interfaces of the click_l2 
#   and the vimage itself by calling l3node.destroy procedure. 
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is click_l2)
#****
proc $MODULE.destroy { eid node } {
    l3node.destroy $eid $node
}

#****f* click_l2.tcl/click_l2.nghook
# NAME
#   click_l2.nghook -- nghook
# SYNOPSIS
#   click_l2.nghook $eid $node $ifc 
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

#****f* click_l2.tcl/click_l2.configGUI
# NAME
#   click_l2.configGUI -- configuration GUI
# SYNOPSIS
#   click_l2.configGUI $c $node
# FUNCTION
#   Defines the structure of the click_l2 configuration window by calling
#   procedures for creating and organising the window, as well as
#   procedures for adding certain modules to that window.
# INPUTS
#   * c -- tk canvas
#   * node -- node id
#****
proc $MODULE.configGUI { c node } {
    global wi
    global guielements treecolumns
    set guielements {}

    configGUI_createConfigPopupWin $c
    wm title $wi "click_l2 configuration"
    configGUI_nodeName $wi $node "Node name:"

    set tabs [configGUI_addNotebook $wi $node {"Configuration" "Interfaces"}]
    set configtab [lindex $tabs 0]
    set ifctab [lindex $tabs 1]

    set treecolumns {"QLen Queue len" "QDisc Queue disc" "QDrop Queue drop"}
    configGUI_addTree $ifctab $node

    configGUI_snapshots $configtab $node
    configGUI_stp $configtab $node
    configGUI_customConfig $configtab $node

    configGUI_buttonsACNode $wi $node
}

#****f* click_l2.tcl/click_l2.configInterfacesGUI
# NAME
#   click_l2.configInterfacesGUI -- configuration of interfaces GUI
# SYNOPSIS
#   click_l2.configInterfacesGUI $wi $node $ifc
# FUNCTION
#   Defines which modules for changing interfaces parameters are contained in
#   the click_l2 configuration window. It is done by calling procedures for adding
#   certain modules to the window.
# INPUTS
#   * wi -- widget
#   * node -- node id
#   * ifc -- interface name
#****
proc $MODULE.configInterfacesGUI { wi node ifc } {
    global guielements

    configGUI_ifcQueueConfig $wi $node $ifc
}
