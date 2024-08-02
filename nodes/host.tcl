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

# $Id: host.tcl 63 2013-10-03 12:17:50Z valter $


#****h* imunes/host.tcl
# NAME
#  host.tcl -- defines host specific procedures
# FUNCTION
#  This module is used to define all the host specific procedures.
# NOTES
#  Procedures in this module start with the keyword host and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE host

registerModule $MODULE

#****f* host.tcl/host.confNewIfc
# NAME
#   host.confNewIfc -- configure new interface
# SYNOPSIS
#   host.confNewIfc $node_id $ifc
# FUNCTION
#   Configures new interface for the specified node.
# INPUTS
#   * node_id -- node id
#   * ifc -- interface name
#****
proc $MODULE.confNewIfc { node_id ifc } {
    global changeAddressRange changeAddressRange6

    set changeAddressRange 0
    set changeAddressRange6 0
    autoIPv4addr $node_id $ifc
    autoIPv6addr $node_id $ifc
    autoMACaddr $node_id $ifc
}

#****f* host.tcl/host.confNewNode
# NAME
#   host.confNewNode -- configure new node
# SYNOPSIS
#   host.confNewNode $node_id
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node_id -- node id
#****
proc $MODULE.confNewNode { node_id } {
    global nodeNamingBase

    setNodeName $node_id [getNewNodeNameType host $nodeNamingBase(host)]
    setAutoDefaultRoutesStatus $node_id "enabled"

    set logiface_id [newLogIface $node_id "lo"]
    setIfcIPv4addrs $node_id $logiface_id "127.0.0.1/8"
    setIfcIPv6addrs $node_id $logiface_id "::1/128"
}

#****f* host.tcl/host.icon
# NAME
#   host.icon -- icon
# SYNOPSIS
#   host.icon $size
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
	    return $ROOTDIR/$LIBDIR/icons/normal/host.gif
	}
	small {
	    return $ROOTDIR/$LIBDIR/icons/small/host.gif
	}
	toolbar {
	    return $ROOTDIR/$LIBDIR/icons/tiny/host.gif
	}
    }
}

#****f* host.tcl/host.toolbarIconDescr
# NAME
#   host.toolbarIconDescr -- toolbar icon description
# SYNOPSIS
#   host.toolbarIconDescr
# FUNCTION
#   Returns this module's toolbar icon description.
# RESULT
#   * descr -- string describing the toolbar icon
#****
proc $MODULE.toolbarIconDescr {} {
    return "Add new Host"
}

#****f* host.tcl/host.notebookDimensions
# NAME
#   host.notebookDimensions -- notebook dimensions
# SYNOPSIS
#   host.notebookDimensions $wi
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
	set h 320
	set w 507
    }
    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Interfaces" } {
	set h 370
	set w 507
    }

    return [list $h $w]
}

#****f* host.tcl/host.ifcName
# NAME
#   host.ifcName -- interface name
# SYNOPSIS
#   host.ifcName
# FUNCTION
#   Returns host interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifcName {l r} {
    return [l3IfcName $l $r]
}

#****f* host.tcl/host.IPAddrRange
# NAME
#   host.IPAddrRange -- IP address range
# SYNOPSIS
#   host.IPAddrRange
# FUNCTION
#   Returns host IP address range
# RESULT
#   * range -- host IP address range
#****
proc $MODULE.IPAddrRange {} {
    return 10
}

#****f* host.tcl/host.layer
# NAME
#   host.layer -- layer
# SYNOPSIS
#   set layer [host.layer]
# FUNCTION
#   Returns the layer on which the host operates i.e. returns NETWORK.
# RESULT
#   * layer -- set to NETWORK
#****
proc $MODULE.layer {} {
    return NETWORK
}

#****f* host.tcl/host.virtlayer
# NAME
#   host.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [host.virtlayer]
# FUNCTION
#   Returns the layer on which the host is instantiated i.e. returns VIMAGE.
# RESULT
#   * layer -- set to VIMAGE
#****
proc $MODULE.virtlayer {} {
    return VIMAGE
}

#****f* host.tcl/host.cfggen
# NAME
#   host.cfggen -- configuration generator
# SYNOPSIS
#   set config [host.cfggen $node_id]
# FUNCTION
#   Returns the generated configuration. This configuration represents
#   the configuration loaded on the booting time of the virtual nodes
#   and it is closly related to the procedure host.bootcmd.
#   Foreach interface in the interface list of the node ip address is
#   configured and each static route from the simulator is added. portmap
#   and inetd are also started.
# INPUTS
#   * node_id -- node id (type of the node is host)
# RESULT
#   * congif -- generated configuration
#****
proc $MODULE.cfggen { node_id } {
    set cfg {}
    foreach iface [allIfcList $node_id] {
	set cfg [concat $cfg [nodeCfggenIfcIPv4 $node_id $iface]]
	set cfg [concat $cfg [nodeCfggenIfcIPv6 $node_id $iface]]
    }
    lappend cfg ""

    set cfg [concat $cfg [nodeCfggenRouteIPv4 $node_id]]
    set cfg [concat $cfg [nodeCfggenRouteIPv6 $node_id]]
    lappend cfg ""

    lappend cfg "rpcbind"
    lappend cfg "inetd"

    return $cfg
}

#****f* host.tcl/host.bootcmd
# NAME
#   host.bootcmd -- boot command
# SYNOPSIS
#   set appl [host.bootcmd $node_id]
# FUNCTION
#   Procedure bootcmd returns the application that reads and employes the
#   configuration generated in host.cfggen.
#   In this case (procedure host.bootcmd) specific application is /bin/sh
# INPUTS
#   * node_id -- node id (type of the node is host)
# RESULT
#   * appl -- application that reads the configuration (/bin/sh)
#****
proc $MODULE.bootcmd { node_id } {
    return "/bin/sh"
}

#****f* host.tcl/host.shellcmds
# NAME
#   host.shellcmds -- shell commands
# SYNOPSIS
#   set shells [host.shellcmds]
# FUNCTION
#   Procedure shellcmds returns the shells that can be opened
#   as a default shell for the system.
# RESULT
#   * shells -- default shells for the host
#****
proc $MODULE.shellcmds {} {
    return "csh bash sh tcsh"
}

#****f* host.tcl/host.instantiate
# NAME
#   host.instantiate -- instantiate
# SYNOPSIS
#   host.instantiate $eid $node_id
# FUNCTION
#   Procedure instantiate creates a new virtaul node
#   for a given node in imunes.
#   Procedure host.instantiate cretaes a new virtual node with
#   all the interfaces and CPU parameters as defined in imunes.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id (type of the node is host)
#****
proc $MODULE.instantiate { eid node_id } {
    l3node.instantiate $eid $node_id
}

proc $MODULE.setupNamespace { eid node_id } {
    l3node.setupNamespace $eid $node_id
}

proc $MODULE.initConfigure { eid node_id } {
    l3node.initConfigure $eid $node_id
}

proc $MODULE.createIfcs { eid node_id ifcs } {
    l3node.createIfcs $eid $node_id $ifcs
}

#****f* host.tcl/host.start
# NAME
#   host.start -- start
# SYNOPSIS
#   host.start $eid $node_id
# FUNCTION
#   Starts a new host. The node can be started if it is instantiated.
#   Simulates the booting proces of a host, by calling l3node.start procedure.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id (type of the node is host)
#****
proc $MODULE.start { eid node_id } {
    l3node.start $eid $node_id
}


#****f* host.tcl/host.shutdown
# NAME
#   host.shutdown -- shutdown
# SYNOPSIS
#   host.shutdown $eid $node_id
# FUNCTION
#   Shutdowns a host. Simulates the shutdown proces of a host,
#   by calling the l3node.shutdown procedure.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id (type of the node is host)
#****
proc $MODULE.shutdown { eid node_id } {
    l3node.shutdown $eid $node_id
}

proc $MODULE.destroyIfcs { eid node_id ifcs } {
    l3node.destroyIfcs $eid $node_id $ifcs
}

#****f* host.tcl/host.destroy
# NAME
#   host.destroy -- destroy
# SYNOPSIS
#   host.destroy $eid $node_id
# FUNCTION
#   Destroys a host. Destroys all the interfaces of the host
#   and the vimage itself by calling l3node.destroy procedure.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id (type of the node is host)
#****
proc $MODULE.destroy { eid node_id } {
    l3node.destroy $eid $node_id
}

#****f* host.tcl/host.nghook
# NAME
#   host.nghook -- nghook
# SYNOPSIS
#   host.nghook $eid $node_id $ifc
# FUNCTION
#   Returns the id of the netgraph node and the name of the netgraph hook
#   which is used for connecting two netgraph nodes. This procedure calls
#   l3node.hook procedure and passes the result of that procedure.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifc -- interface name
# RESULT
#   * nghook -- the list containing netgraph node id and the
#     netgraph hook (ngNode ngHook).
#****
proc $MODULE.nghook { eid node_id ifc } {
    return [l3node.nghook $eid $node_id $ifc]
}

#****f* host.tcl/host.configGUI
# NAME
#   host.configGUI -- configuration GUI
# SYNOPSIS
#   host.configGUI $c $node_id
# FUNCTION
#   Defines the structure of the host configuration window by calling
#   procedures for creating and organising the window, as well as
#   procedures for adding certain modules to that window.
# INPUTS
#   * c -- tk canvas
#   * node_id -- node id
#****
proc $MODULE.configGUI { c node_id } {
    global wi
    #
    #guielements - the list of modules contained in the configuration window
    #              (each element represents the name of the procedure which creates
    #               that module)
    #
    #treecolumns - the list of columns in the interfaces tree (each element
    #              consists of the column id and the column name)
    #
    global guielements treecolumns
    set guielements {}

    configGUI_createConfigPopupWin $c
    wm title $wi "host configuration"
    configGUI_nodeName $wi $node_id "Node name:"

    set tabs [configGUI_addNotebook $wi $node_id {"Configuration" "Interfaces"}]
    set configtab [lindex $tabs 0]
    set ifctab [lindex $tabs 1]

    set treecolumns {"OperState State" "NatState Nat" "IPv4addr IPv4 addr" "IPv6addr IPv6 addr" \
	    "MACaddr MAC addr" "MTU MTU" "QLen Queue len" "QDisc Queue disc" "QDrop Queue drop"}
    configGUI_addTree $ifctab $node_id

    configGUI_customImage $configtab $node_id
    configGUI_attachDockerToExt $configtab $node_id
    configGUI_servicesConfig $configtab $node_id
    configGUI_staticRoutes $configtab $node_id
    configGUI_snapshots $configtab $node_id
    configGUI_customConfig $configtab $node_id

    configGUI_buttonsACNode $wi $node_id
}

#****f* host.tcl/host.configInterfacesGUI
# NAME
#   host.configInterfacesGUI -- configuration of interfaces GUI
# SYNOPSIS
#   host.configInterfacesGUI $wi $node_id $ifc
# FUNCTION
#   Defines which modules for changing interfaces parameters are contained in
#   the host configuration window. It is done by calling procedures for adding
#   certain modules to the window.
# INPUTS
#   * wi -- widget
#   * node_id -- node id
#   * ifc -- interface id
#****
proc $MODULE.configInterfacesGUI { wi node_id ifc } {
    global guielements

    configGUI_ifcEssentials $wi $node_id $ifc
    configGUI_ifcQueueConfig $wi $node_id $ifc
    configGUI_ifcMACAddress $wi $node_id $ifc
    configGUI_ifcIPv4Address $wi $node_id $ifc
    configGUI_ifcIPv6Address $wi $node_id $ifc
}
