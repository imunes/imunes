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

################################################################################
########################### CONFIGURATION PROCEDURES ###########################
################################################################################

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
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id
    global nodeNamingBase

    set nconfig [list \
	"hostname [getNewNodeNameType host $nodeNamingBase(host)]" \
	! ]
    lappend $node_id "network-config [list $nconfig]"

    setAutoDefaultRoutesStatus $node_id "enabled"
    setLogIfcType $node_id lo0 lo
    setIfcIPv4addrs $node_id lo0 "127.0.0.1/8"
    setIfcIPv6addrs $node_id lo0 "::1/128"
}

#****f* host.tcl/host.confNewIfc
# NAME
#   host.confNewIfc -- configure new interface
# SYNOPSIS
#   host.confNewIfc $node_id $iface_id
# FUNCTION
#   Configures new interface for the specified node.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface name
#****
proc $MODULE.confNewIfc { node_id iface_id } {
    autoIPv4addr $node_id $iface_id
    autoIPv6addr $node_id $iface_id
    autoMACaddr $node_id $iface_id
}

proc $MODULE.generateConfigIfaces { node_id ifaces } {
    set all_ifaces "[ifcList $node_id] [logIfcList $node_id]"
    if { $ifaces == "*" } {
	set ifaces $all_ifaces
    } else {
	# sort physical ifaces before logical ones (because of vlans)
	set negative_ifaces [removeFromList $all_ifaces $ifaces]
	set ifaces [removeFromList $all_ifaces $negative_ifaces]
    }

    set cfg {}
    foreach iface_id $ifaces {
	set cfg [concat $cfg [nodeCfggenIfc $node_id $iface_id]]

	lappend cfg ""
    }

    return $cfg
}

proc $MODULE.generateUnconfigIfaces { node_id ifaces } {
    set all_ifaces "[ifcList $node_id] [logIfcList $node_id]"
    if { $ifaces == "*" } {
	set ifaces $all_ifaces
    } else {
	# sort physical ifaces before logical ones
	set negative_ifaces [removeFromList $all_ifaces $ifaces]
	set ifaces [removeFromList $all_ifaces $negative_ifaces]
    }

    set cfg {}
    foreach iface_id $ifaces {
	set cfg [concat $cfg [nodeUncfggenIfc $node_id $iface_id]]

	lappend cfg ""
    }

    return $cfg
}

#****f* host.tcl/host.generateConfig
# NAME
#   host.generateConfig -- configuration generator
# SYNOPSIS
#   set config [host.generateConfig $node_id]
# FUNCTION
#   Returns the generated configuration. This configuration represents
#   the configuration loaded on the booting time of the virtual nodes
#   and it is closly related to the procedure host.bootcmd.
#   Foreach interface in the interface list of the node ip address is
#   configured and each static route from the simulator is added. portmap
#   and inetd are also started.
# INPUTS
#   * node_id -- node id
# RESULT
#   * config -- generated configuration
#****
proc $MODULE.generateConfig { node_id } {
    set cfg {}

    if { [getCustomEnabled $node_id] != true } {
	set cfg [concat $cfg [nodeCfggenStaticRoutes4 $node_id]]
	set cfg [concat $cfg [nodeCfggenStaticRoutes6 $node_id]]

	lappend cfg ""
    }

    set subnet_gws {}
    set nodes_l2data [dict create]
    if { [getAutoDefaultRoutesStatus $node_id] == "enabled" } {
	lassign [getDefaultGateways $node_id $subnet_gws $nodes_l2data] my_gws subnet_gws nodes_l2data
	lassign [getDefaultRoutesConfig $node_id $my_gws] all_routes4 all_routes6

	setDefaultIPv4routes $node_id $all_routes4
	setDefaultIPv6routes $node_id $all_routes6
    } else {
	setDefaultIPv4routes $node_id {}
	setDefaultIPv6routes $node_id {}
    }

    set cfg [concat $cfg [nodeCfggenAutoRoutes4 $node_id]]
    set cfg [concat $cfg [nodeCfggenAutoRoutes6 $node_id]]

    lappend cfg ""

    lappend cfg "rpcbind"
    lappend cfg "inetd"

    return $cfg
}

proc $MODULE.generateUnconfig { node_id } {
    set cfg {}

    set cfg [concat $cfg [nodeUncfggenStaticRoutes4 $node_id]]
    set cfg [concat $cfg [nodeUncfggenStaticRoutes6 $node_id]]

    lappend cfg ""

    set cfg [concat $cfg [nodeUncfggenAutoRoutes4 $node_id]]
    set cfg [concat $cfg [nodeUncfggenAutoRoutes6 $node_id]]

    lappend cfg ""

    # TODO: check
    lappend cfg "killall rpcbind"
    lappend cfg "killall inetd"

    return $cfg
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

#****f* host.tcl/host.ifacePrefix
# NAME
#   host.ifacePrefix -- interface name
# SYNOPSIS
#   host.ifacePrefix
# FUNCTION
#   Returns host interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifacePrefix {} {
    return "eth"
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

#****f* host.tcl/host.netlayer
# NAME
#   host.netlayer -- layer
# SYNOPSIS
#   set layer [host.netlayer]
# FUNCTION
#   Returns the layer on which the host operates i.e. returns NETWORK.
# RESULT
#   * layer -- set to NETWORK
#****
proc $MODULE.netlayer {} {
    return NETWORK
}

#****f* host.tcl/host.virtlayer
# NAME
#   host.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [host.virtlayer]
# FUNCTION
#   Returns the layer on which the host is instantiated i.e. returns VIRTUALIZED.
# RESULT
#   * layer -- set to VIRTUALIZED
#****
proc $MODULE.virtlayer {} {
    return VIRTUALIZED
}

#****f* host.tcl/host.bootcmd
# NAME
#   host.bootcmd -- boot command
# SYNOPSIS
#   set appl [host.bootcmd $node_id]
# FUNCTION
#   Procedure bootcmd returns the application that reads and employes the
#   configuration generated in host.generateConfig.
#   In this case (procedure host.bootcmd) specific application is /bin/sh
# INPUTS
#   * node_id -- node id
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

#****f* host.tcl/host.nghook
# NAME
#   host.nghook -- nghook
# SYNOPSIS
#   host.nghook $eid $node_id $iface_id
# FUNCTION
#   Returns the id of the netgraph node and the name of the netgraph hook
#   which is used for connecting two netgraph nodes. This procedure calls
#   l3node.hook procedure and passes the result of that procedure.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * iface_id -- interface id
# RESULT
#   * nghook -- the list containing netgraph node id and the
#     netgraph hook (ngNode ngHook).
#****
proc $MODULE.nghook { eid node_id iface_id } {
    return [list $node_id-[getIfcName $node_id $iface_id] ether]
}

################################################################################
############################ INSTANTIATE PROCEDURES ############################
################################################################################

#****f* host.tcl/host.prepareSystem
# NAME
#   host.prepareSystem -- prepare system
# SYNOPSIS
#   host.prepareSystem
# FUNCTION
#   Does nothing
#****
proc $MODULE.prepareSystem {} {
    # nothing to do
}

#****f* host.tcl/host.nodeCreate
# NAME
#   host.nodeCreate -- instantiate
# SYNOPSIS
#   host.nodeCreate $eid $node_id
# FUNCTION
#   Creates a new virtualized host node (using jails/docker).
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeCreate { eid node_id } {
    prepareFilesystemForNode $node_id
    createNodeContainer $node_id
}

proc $MODULE.nodeNamespaceSetup { eid node_id } {
    attachToL3NodeNamespace $node_id
}

proc $MODULE.nodeInitConfigure { eid node_id } {
    configureICMPoptions $node_id
}

proc $MODULE.nodePhysIfacesCreate { eid node_id ifaces } {
    nodePhysIfacesCreate $node_id $ifaces
}

proc $MODULE.nodeLogIfacesCreate { eid node_id ifaces } {
    nodeLogIfacesCreate $node_id $ifaces
}

#****f* host.tcl/host.nodeIfacesConfigure
# NAME
#   host.nodeIfacesConfigure -- configure host node interfaces
# SYNOPSIS
#   host.nodeIfacesConfigure $eid $node_id $ifaces
# FUNCTION
#   Configure interfaces on a host. Set MAC, MTU, queue parameters, assign the IP
#   addresses to the interfaces, etc. This procedure can be called if the node
#   is instantiated.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifaces -- list of interface ids
#****
proc $MODULE.nodeIfacesConfigure { eid node_id ifaces } {
    startNodeIfaces $node_id $ifaces
}

#****f* host.tcl/host.nodeConfigure
# NAME
#   host.nodeConfigure -- start
# SYNOPSIS
#   host.nodeConfigure $eid $node_id
# FUNCTION
#   Starts a new host. The node can be started if it is instantiated.
#   Simulates the booting proces of a host, by calling l3node.nodeConfigure procedure.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeConfigure { eid node_id } {
    runConfOnNode $node_id
}

################################################################################
############################# TERMINATE PROCEDURES #############################
################################################################################

#****f* host.tcl/host.nodeIfacesUnconfigure
# NAME
#   host.nodeIfacesUnconfigure -- unconfigure host node interfaces
# SYNOPSIS
#   host.nodeIfacesUnconfigure $eid $node_id $ifaces
# FUNCTION
#   Unconfigure interfaces on a host to a default state. Set name to iface_id,
#   flush IP addresses to the interfaces, etc. This procedure can be called if
#   the node is instantiated.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifaces -- list of interface ids
#****
proc $MODULE.nodeIfacesUnconfigure { eid node_id ifaces } {
    unconfigNodeIfaces $eid $node_id $ifaces
}

proc $MODULE.nodeIfacesDestroy { eid node_id ifaces } {
    nodeIfacesDestroy $eid $node_id $ifaces
}

proc $MODULE.nodeUnconfigure { eid node_id } {
    unconfigNode $eid $node_id
}

#****f* host.tcl/host.nodeShutdown
# NAME
#   host.nodeShutdown -- shutdown
# SYNOPSIS
#   host.nodeShutdown $eid $node_id
# FUNCTION
#   Shutdowns a host node.
#   Simulates the shutdown proces of a node, kills all the services and
#   processes.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeShutdown { eid node_id } {
    killExtProcess "wireshark.*[getNodeName $node_id].*\\($eid\\)"
    killAllNodeProcesses $eid $node_id
}

#****f* host.tcl/host.nodeDestroy
# NAME
#   host.nodeDestroy -- layer 3 node destroy
# SYNOPSIS
#   host.nodeDestroy $eid $node_id
# FUNCTION
#   Destroys a host node.
#   First, it destroys all remaining virtual ifaces (vlans, tuns, etc).
#   Then, it destroys the jail/container with its namespaces and FS.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeDestroy { eid node_id } {
    destroyNodeVirtIfcs $eid $node_id
    removeNodeContainer $eid $node_id
    destroyNamespace $eid-$node_id
    removeNodeFS $eid $node_id
}

################################################################################
################################ GUI PROCEDURES ################################
################################################################################

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

    set tabs [configGUI_addNotebook $wi $node_id { "Configuration" "Interfaces" }]
    set configtab [lindex $tabs 0]
    set ifctab [lindex $tabs 1]

    set treecolumns { "OperState State" "NatState Nat" "IPv4addrs IPv4 addrs" "IPv6addrs IPv6 addrs" \
	"MACaddr MAC addr" "MTU MTU" "QLen Queue len" "QDisc Queue disc" "QDrop Queue drop" }
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
#   host.configInterfacesGUI $wi $node_id $iface_id
# FUNCTION
#   Defines which modules for changing interfaces parameters are contained in
#   the host configuration window. It is done by calling procedures for adding
#   certain modules to the window.
# INPUTS
#   * wi -- widget
#   * node_id -- node id
#   * iface_id -- interface id
#****
proc $MODULE.configInterfacesGUI { wi node_id iface_id } {
    global guielements

    configGUI_ifcEssentials $wi $node_id $iface_id
    configGUI_ifcQueueConfig $wi $node_id $iface_id
    configGUI_ifcMACAddress $wi $node_id $iface_id
    configGUI_ifcIPv4Address $wi $node_id $iface_id
    configGUI_ifcIPv6Address $wi $node_id $iface_id
}
