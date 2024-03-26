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

#****f* pc.tcl/pc.confNewIfc
# NAME
#   pc.confNewIfc -- configure new interface
# SYNOPSIS
#   pc.confNewIfc $node $ifc
# FUNCTION
#   Configures new interface for the specified node.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
#****
proc $MODULE.confNewIfc { node ifc } {
    global changeAddressRange changeAddressRange6
    set changeAddressRange 0
    set changeAddressRange6 0
    autoIPv4addr $node $ifc
    autoIPv6addr $node $ifc
    autoMACaddr $node $ifc
    autoIPv4defaultroute $node $ifc
    autoIPv6defaultroute $node $ifc
}

#****f* pc.tcl/pc.confNewNode
# NAME
#   pc.confNewNode -- configure new node
# SYNOPSIS
#   pc.confNewNode $node
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node -- node id
#****
proc $MODULE.confNewNode { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node
    global nodeNamingBase

    set nconfig [list \
	"hostname [getNewNodeNameType pc $nodeNamingBase(pc)]" \
	! ]
    lappend $node "network-config [list $nconfig]"

    setLogIfcType $node lo0 lo
    setIfcIPv4addr $node lo0 "127.0.0.1/8"
    setIfcIPv6addr $node lo0 "::1/128"
}

#****f* pc.tcl/pc.icon
# NAME
#   pc.icon -- icon
# SYNOPSIS
#   pc.icon $size
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
	return $ROOTDIR/$LIBDIR/icons/normal/pc.gif
      }
      small {
	return $ROOTDIR/$LIBDIR/icons/small/pc.gif
      }
      toolbar {
	return $ROOTDIR/$LIBDIR/icons/tiny/pc.gif
      }
    }
}

#****f* pc.tcl/pc.toolbarIconDescr
# NAME
#   pc.toolbarIconDescr -- toolbar icon description
# SYNOPSIS
#   pc.toolbarIconDescr
# FUNCTION
#   Returns this module's toolbar icon description.
# RESULT
#   * descr -- string describing the toolbar icon
#****
proc $MODULE.toolbarIconDescr {} {
    return "Add new PC"
}

#****f* pc.tcl/pc.notebookDimensions
# NAME
#   pc.notebookDimensions -- notebook dimensions
# SYNOPSIS
#   pc.notebookDimensions $wi
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
	set h 270
	set w 507
    }
    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Interfaces" } {
	set h 370
	set w 507
    }

    return [list $h $w]
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
proc $MODULE.ifcName {l r} {
    return [l3IfcName $l $r]
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

#****f* pc.tcl/pc.layer
# NAME
#   pc.layer -- layer
# SYNOPSIS
#   set layer [pc.layer]
# FUNCTION
#   Returns the layer on which the pc communicates, i.e. returns NETWORK.
# RESULT
#   * layer -- set to NETWORK
#****
proc $MODULE.layer {} {
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

#****f* pc.tcl/pc.cfggen
# NAME
#   pc.cfggen -- configuration generator
# SYNOPSIS
#   set config [pc.cfggen $node]
# FUNCTION
#   Returns the generated configuration. This configuration represents
#   the configuration loaded on the booting time of the virtual nodes
#   and it is closly related to the procedure pc.bootcmd.
#   For each interface in the interface list of the node, ip address is
#   configured and each static route from the simulator is added.
# INPUTS
#   * node -- node id (type of the node is pc)
# RESULT
#   * congif -- generated configuration
#****
proc $MODULE.cfggen { node } {
    set cfg {}
    set cfg [concat $cfg [nodeCfggenIfcIPv4 $node]]
    set cfg [concat $cfg [nodeCfggenIfcIPv6 $node]]
    lappend cfg ""

    set cfg [concat $cfg [nodeCfggenRouteIPv4 $node]]
    set cfg [concat $cfg [nodeCfggenRouteIPv6 $node]]
    
    return $cfg
}

#****f* pc.tcl/pc.bootcmd
# NAME
#   pc.bootcmd -- boot command
# SYNOPSIS
#   set appl [pc.bootcmd $node]
# FUNCTION
#   Procedure bootcmd returns the application that reads and employes the
#   configuration generated in pc.cfggen.
#   In this case (procedure pc.bootcmd) specific application is /bin/sh
# INPUTS
#   * node -- node id (type of the node is pc)
# RESULT
#   * appl -- application that reads the configuration (/bin/sh)
#****

proc $MODULE.bootcmd { node } { 

	
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

#****f* pc.tcl/pc.instantiate
# NAME
#   pc.instantiate -- instantiate
# SYNOPSIS
#   pc.instantiate $eid $node
# FUNCTION
#   Procedure instantiate creates a new virtaul node
#   for a given node in imunes.
#   Procedure pc.instantiate cretaes a new virtual node with
#   all the interfaces and CPU parameters as defined in imunes.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is pc)
#****
proc $MODULE.instantiate { eid node } {
    l3node.instantiate $eid $node
}

#****f* pc.tcl/pc.start
# NAME
#   pc.start -- start
# SYNOPSIS
#   pc.start $eid $node
# FUNCTION
#   Starts a new pc. The node can be started if it is instantiated.
#   Simulates the booting proces of a pc, by calling l3node.start procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is pc)
#****
proc $MODULE.start { eid node } {
    l3node.start $eid $node
}

#****f* pc.tcl/pc.shutdown
# NAME
#   pc.shutdown -- shutdown
# SYNOPSIS
#   pc.shutdown $eid $node
# FUNCTION
#   Shutdowns a pc. Simulates the shutdown proces of a pc,
#   by calling the l3node.shutdown procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is pc)
#****
proc $MODULE.shutdown { eid node } {
    l3node.shutdown $eid $node
}

#****f* pc.tcl/pc.destroy
# NAME
#   pc.destroy -- destroy
# SYNOPSIS
#   pc.destroy $eid $node
# FUNCTION
#   Destroys a pc. Destroys all the interfaces of the pc
#   and the vimage itself by calling l3node.destroy procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is pc)
#****
proc $MODULE.destroy { eid node } {
    l3node.destroy $eid $node
}

#****f* pc.tcl/pc.nghook
# NAME
#   pc.nghook -- nghook
# SYNOPSIS
#   pc.nghook $eid $node $ifc
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

#****f* pc.tcl/pc.configGUI
# NAME
#   pc.configGUI -- configuration GUI
# SYNOPSIS
#   pc.configGUI $c $node
# FUNCTION
#   Defines the structure of the pc configuration window by calling
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
    wm title $wi "pc configuration"
    configGUI_nodeName $wi $node "Node name:"

    set tabs [configGUI_addNotebook $wi $node {"Configuration" "Interfaces"}]
    set configtab [lindex $tabs 0]
    set ifctab [lindex $tabs 1]

    set treecolumns {"OperState State" "IPv4addr IPv4 addr" "IPv6addr IPv6 addr" \
	    "MACaddr MAC addr" "MTU MTU" "QLen Queue len" "QDisc Queue disc" "QDrop Queue drop"}
    configGUI_addTree $ifctab $node

    configGUI_dockerImage $configtab $node
    configGUI_attachDockerToExt $configtab $node
    configGUI_servicesConfig $configtab $node
    configGUI_staticRoutes $configtab $node
    configGUI_snapshots $configtab $node
    configGUI_customConfig $configtab $node

    configGUI_buttonsACNode $wi $node
}

#****f* pc.tcl/pc.configInterfacesGUI
# NAME
#   pc.configInterfacesGUI -- configuration of interfaces GUI
# SYNOPSIS
#   pc.configInterfacesGUI $wi $node $ifc
# FUNCTION
#   Defines which modules for changing interfaces parameters are contained in
#   the pc configuration window. It is done by calling procedures for adding
#   certain modules to the window.
# INPUTS
#   * wi -- widget
#   * node -- node id
#   * ifc -- interface name
#****
proc $MODULE.configInterfacesGUI { wi node ifc } {
    global guielements

    configGUI_ifcEssentials $wi $node $ifc
    configGUI_ifcQueueConfig $wi $node $ifc
    configGUI_ifcMACAddress $wi $node $ifc
    configGUI_ifcIPv4Address $wi $node $ifc
    configGUI_ifcIPv6Address $wi $node $ifc
}
