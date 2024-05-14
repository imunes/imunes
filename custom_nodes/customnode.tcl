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

# $Id: customnode.tcl 63 2013-10-03 12:17:50Z valter $


#****h* imunes/customnode.tcl
# NAME
#  customnode.tcl -- defines customnode specific procedures
# FUNCTION
#  This module is used to define all the customnode specific procedures.
# NOTES
#  Procedures in this module start with the keyword customnode and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

# CUSTOMNODE change custom node type
set MODULE customnode
registerModule $MODULE

################################################################################
########################### CONFIGURATION PROCEDURES ###########################
################################################################################

global nodeNamingBase
# CUSTOMNODE change this (used for naming new nodes: 'node-type name-prefix')
array set nodeNamingBase {
    customnode cn
}

#****f* customnode.tcl/customnode.confNewNode
# NAME
#   customnode.confNewNode -- configure new node
# SYNOPSIS
#   customnode.confNewNode $node_id
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node_id -- node id
#****
proc $MODULE.confNewNode { node_id } {
    global nodeNamingBase

    # CUSTOMNODE change this (used for naming new nodes: 'node-type name-prefix')
    setNodeName $node_id [getNewNodeNameType customnode $nodeNamingBase(customnode)]
    setAutoDefaultRoutesStatus $node_id "enabled"

    set logiface_id [newLogIface $node_id "lo"]
    setIfcIPv4addrs $node_id $logiface_id "127.0.0.1/8"
    setIfcIPv6addrs $node_id $logiface_id "::1/128"

    # CUSTOMNODE the only functional difference from the PC node
    setNodeCustomImage $node_id "imunes/template:some-other-tag"
}

#****f* customnode.tcl/customnode.confNewIfc
# NAME
#   customnode.confNewIfc -- configure new interface
# SYNOPSIS
#   customnode.confNewIfc $node_id $iface_id
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

#****f* customnode.tcl/customnode.generateConfig
# NAME
#   customnode.generateConfig -- configuration generator
# SYNOPSIS
#   set config [customnode.generateConfig $node_id]
# FUNCTION
#   Returns the generated configuration. This configuration represents
#   the configuration loaded on the booting time of the virtual nodes
#   and it is closly related to the procedure customnode.bootcmd.
#   For each interface in the interface list of the node, ip address is
#   configured and each static route from the simulator is added.
# INPUTS
#   * node_id -- node id
# RESULT
#   * config -- generated configuration
#****
proc $MODULE.generateConfig { node_id } {
    set cfg {}

    if { [getCustomEnabled $node_id] != true || [getCustomConfigSelected $node_id "NODE_CONFIG"] in "\"\" DISABLED" } {
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

    return $cfg
}

#****f* customnode.tcl/customnode.ifacePrefix
# NAME
#   customnode.ifacePrefix -- interface name prefix
# SYNOPSIS
#   customnode.ifacePrefix
# FUNCTION
#   Returns customnode interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifacePrefix {} {
    return "eth"
}

#****f* customnode.tcl/customnode.IPAddrRange
# NAME
#   customnode.IPAddrRange -- IP address range
# SYNOPSIS
#   customnode.IPAddrRange
# FUNCTION
#   Returns customnode IP address range
# RESULT
#   * range -- customnode IP address range
#****
proc $MODULE.IPAddrRange {} {
    return 20
}

#****f* customnode.tcl/customnode.layer
# NAME
#   customnode.layer -- layer
# SYNOPSIS
#   set layer [customnode.layer]
# FUNCTION
#   Returns the layer on which the customnode communicates, i.e. returns NETWORK.
# RESULT
#   * layer -- set to NETWORK
#****
proc $MODULE.netlayer {} {
    return NETWORK
}

#****f* customnode.tcl/customnode.virtlayer
# NAME
#   customnode.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [customnode.virtlayer]
# FUNCTION
#   Returns the layer on which the customnode is instantiated i.e. returns VIMAGE.
# RESULT
#   * layer -- set to VIMAGE
#****
proc $MODULE.virtlayer {} {
    return VIRTUALIZED
}

#****f* customnode.tcl/customnode.bootcmd
# NAME
#   customnode.bootcmd -- boot command
# SYNOPSIS
#   set appl [customnode.bootcmd $node_id]
# FUNCTION
#   Procedure bootcmd returns the application that reads and employes the
#   configuration generated in customnode.cfggen.
#   In this case (procedure customnode.bootcmd) specific application is /bin/sh
# INPUTS
#   * node_id -- node id (type of the node is customnode)
# RESULT
#   * appl -- application that reads the configuration (/bin/sh)
#****
proc $MODULE.bootcmd { node_id } {
    return "/bin/sh"
}

#****f* customnode.tcl/customnode.shellcmds
# NAME
#   customnode.shellcmds -- shell commands
# SYNOPSIS
#   set shells [customnode.shellcmds]
# FUNCTION
#   Procedure shellcmds returns the shells that can be opened
#   as a default shell for the system.
# RESULT
#   * shells -- default shells for the customnode node
#****
proc $MODULE.shellcmds {} {
    return "csh bash sh tcsh"
}

#****f* customnode.tcl/customnode.nghook
# NAME
#   customnode.nghook -- nghook
# SYNOPSIS
#   customnode.nghook $eid $node_id $iface_id
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

#****f* customnode.tcl/customnode.prepareSystem
# NAME
#   customnode.prepareSystem -- prepare system
# SYNOPSIS
#   customnode.prepareSystem
# FUNCTION
#   Does nothing
#****
proc $MODULE.prepareSystem {} {
}

#****f* customnode.tcl/customnode.nodeCreate
# NAME
#   customnode.nodeCreate -- nodeCreate
# SYNOPSIS
#   customnode.nodeCreate $eid $node_id
# FUNCTION
#   Creates a new virtualized customnode node (using jails/docker).
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeCreate { eid node_id } {
    prepareFilesystemForNode $node_id
    createNodeContainer $node_id
}

#****f* customnode.tcl/customnode.nodeNamespaceSetup
# NAME
#   customnode.nodeNamespaceSetup -- customnode node nodeNamespaceSetup
# SYNOPSIS
#   customnode.nodeNamespaceSetup $eid $node_id
# FUNCTION
#   Linux only. Attaches the existing Docker netns to a new one.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeNamespaceSetup { eid node_id } {
    attachToL3NodeNamespace $node_id
}

#****f* customnode.tcl/customnode.nodeInitConfigure
# NAME
#   customnode.nodeInitConfigure -- customnode node nodeInitConfigure
# SYNOPSIS
#   customnode.nodeInitConfigure $eid $node_id
# FUNCTION
#   Runs initial L3 configuration, such as creating logical interfaces and
#   configuring sysctls.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeInitConfigure { eid node_id } {
    configureICMPoptions $node_id
}

proc $MODULE.nodePhysIfacesCreate { eid node_id ifaces } {
    nodePhysIfacesCreate $node_id $ifaces
}

proc $MODULE.nodeLogIfacesCreate { eid node_id ifaces } {
    nodeLogIfacesCreate $node_id $ifaces
}

#****f* customnode.tcl/customnode.nodeIfacesConfigure
# NAME
#   customnode.nodeIfacesConfigure -- configure customnode node interfaces
# SYNOPSIS
#   customnode.nodeIfacesConfigure $eid $node_id $ifaces
# FUNCTION
#   Configure interfaces on a customnode. Set MAC, MTU, queue parameters, assign the IP
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

#****f* customnode.tcl/customnodcustomnode.nodeConfigure
# NAME
#   customnode.nodeConfigure -- configure customnode node
# SYNOPSIS
#   customnode.nodeConfigure $eid $node_id
# FUNCTION
#   Starts a new customnode. Simulates the booting proces of a node, starts all the
#   services, etc.
#   This procedure can be called if it is instantiated.
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

#****f* customnode.tcl/customnode.nodeIfacesUnconfigure
# NAME
#   customnode.nodeIfacesUnconfigure -- unconfigure customnode node interfaces
# SYNOPSIS
#   customnode.nodeIfacesUnconfigure $eid $node_id $ifaces
# FUNCTION
#   Unconfigure interfaces on a customnode to a default state. Set name to iface_id,
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

#****f* customnode.tcl/customnode.nodeShutdown
# NAME
#   customnode.nodeShutdown -- layer 3 node shutdown
# SYNOPSIS
#   customnode.nodeShutdown $eid $node_id
# FUNCTION
#   Shutdowns a customnode node.
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

#****f* customnode.tcl/customnode.nodeDestroy
# NAME
#   customnode.nodeDestroy -- layer 3 node destroy
# SYNOPSIS
#   customnode.nodeDestroy $eid $node_id
# FUNCTION
#   Destroys a customnode node.
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

#****f* customnode.tcl/customnode.toolbarIconDescr
# NAME
#   customnode.toolbarIconDescr -- toolbar icon description
# SYNOPSIS
#   customnode.toolbarIconDescr
# FUNCTION
#   Returns this module's toolbar icon description.
# RESULT
#   * descr -- string describing the toolbar icon
#****
proc $MODULE.toolbarIconDescr {} {
    # CUSTOMNODE change custom node GUI description
    return "Add new customnode"
}

proc $MODULE._confNewIfc { node_cfg iface_id } {
    global node_existing_mac node_existing_ipv4 node_existing_ipv6

    set ipv4addr [getNextIPv4addr [_getNodeType $node_cfg] $node_existing_ipv4]
    lappend node_existing_ipv4 $ipv4addr
    set node_cfg [_setIfcIPv4addrs $node_cfg $iface_id $ipv4addr]

    set ipv6addr [getNextIPv6addr [_getNodeType $node_cfg] $node_existing_ipv6]
    lappend node_existing_ipv6 $ipv6addr
    set node_cfg [_setIfcIPv6addrs $node_cfg $iface_id $ipv6addr]

    set macaddr [getNextMACaddr $node_existing_mac]
    lappend node_existing_mac $macaddr
    set node_cfg [_setIfcMACaddr $node_cfg $iface_id $macaddr]

    return $node_cfg
}

#****f* customnode.tcl/customnode.icon
# NAME
#   customnode.icon -- icon
# SYNOPSIS
#   customnode.icon $size
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
	    # CUSTOMNODE change custom node icon
	    return $ROOTDIR/$LIBDIR/custom_nodes/icons/normal/customnode.gif
	}
	small {
	    # CUSTOMNODE change custom node icon
	    return $ROOTDIR/$LIBDIR/custom_nodes/icons/small/customnode.gif
	}
	toolbar {
	    # CUSTOMNODE change custom node icon
	    return $ROOTDIR/$LIBDIR/custom_nodes/icons/tiny/customnode.gif
	}
    }
}

#****f* customnode.tcl/customnode.notebookDimensions
# NAME
#   customnode.notebookDimensions -- notebook dimensions
# SYNOPSIS
#   customnode.notebookDimensions $wi
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
	set h 350
	set w 507
    }
    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Interfaces" } {
	set h 370
	set w 507
    }

    return [list $h $w]
}

#****f* customnode.tcl/customnode.configGUI
# NAME
#   customnode.configGUI -- configuration GUI
# SYNOPSIS
#   customnode.configGUI $c $node_id
# FUNCTION
#   Defines the structure of the customnode configuration window by calling
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
    #              that module)
    #
    #treecolumns - the list of columns in the interfaces tree (each element
    #              consists of the column id and the column name)
    #
    global guielements treecolumns
    global node_cfg node_existing_mac node_existing_ipv4 node_existing_ipv6

    set guielements {}
    set treecolumns {}
    set node_cfg [cfgGet "nodes" $node_id]
    set node_existing_mac [getFromRunning "mac_used_list"]
    set node_existing_ipv4 [getFromRunning "ipv4_used_list"]
    set node_existing_ipv6 [getFromRunning "ipv6_used_list"]

    configGUI_createConfigPopupWin $c
    # CUSTOMNODE change custom node GUI window title
    wm title $wi "customnode configuration"

    configGUI_nodeName $wi $node_id "Node name:"

    lassign [configGUI_addNotebook $wi $node_id {"Configuration" "Interfaces"}] configtab ifctab

    configGUI_customImage $configtab $node_id
    configGUI_attachDockerToExt $configtab $node_id
    configGUI_servicesConfig $configtab $node_id
    configGUI_staticRoutes $configtab $node_id
    configGUI_snapshots $configtab $node_id
    configGUI_customConfig $configtab $node_id

    set treecolumns {"OperState State" "NatState Nat" "IPv4addrs IPv4 addrs" "IPv6addrs IPv6 addrs" \
	"MACaddr MAC addr" "MTU MTU" "QLen Queue len" "QDisc Queue disc" "QDrop Queue drop"}
    configGUI_addTree $ifctab $node_id

    configGUI_nodeRestart $wi $node_id
    configGUI_buttonsACNode $wi $node_id
}

#****f* customnode.tcl/customnode.configInterfacesGUI
# NAME
#   customnode.configInterfacesGUI -- configuration of interfaces GUI
# SYNOPSIS
#   customnode.configInterfacesGUI $wi $node_id $iface_id
# FUNCTION
#   Defines which modules for changing interfaces parameters are contained in
#   the customnode configuration window. It is done by calling procedures for adding
#   certain modules to the window.
# INPUTS
#   * wi -- widget
#   * node_id -- node id
#   * iface_id -- interface name
#****
proc $MODULE.configInterfacesGUI { wi node_id iface_id } {
    global guielements

    configGUI_ifcEssentials $wi $node_id $iface_id
    configGUI_ifcQueueConfig $wi $node_id $iface_id
    configGUI_ifcMACAddress $wi $node_id $iface_id
    configGUI_ifcIPv4Address $wi $node_id $iface_id
    configGUI_ifcIPv6Address $wi $node_id $iface_id
}
