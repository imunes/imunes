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

# $Id: frr.tcl 128 2014-12-19 11:59:09Z denis $


#****h* imunes/frr.tcl
# NAME
#  router.frr.tcl -- defines specific procedures for router
#  using frr routing model
# FUNCTION
#  This module defines all the specific procedures for a router
#  which uses frr routing model.
# NOTES
#  Procedures in this module start with the keyword router.frr and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE router
registerModule $MODULE

#****f* genericrouter.tcl/router.confNewIfc
# NAME
#   router.confNewIfc -- configure new interface
# SYNOPSIS
#   router.confNewIfc $node_id $iface_id
# FUNCTION
#   Configures new interface for the specified node.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface name
#****
proc $MODULE.confNewIfc { node_id iface_id } {
    global changeAddressRange changeAddressRange6

    set changeAddressRange 0
    set changeAddressRange6 0
    autoIPv4addr $node_id $iface_id
    autoIPv6addr $node_id $iface_id
    autoMACaddr $node_id $iface_id

    if { [getNodeType [lindex [logicalPeerByIfc $node_id $iface_id] 0]] == "extnat" } {
	setIfcNatState $node_id $iface_id "on"
    }
}

#****f* genericrouter.tcl/router.confNewNode
# NAME
#   router.confNewNode -- configure new node
# SYNOPSIS
#   router.confNewNode $node_id
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node_id -- node id
#****
proc $MODULE.confNewNode { node_id } {
    global ripEnable ripngEnable ospfEnable ospf6Enable bgpEnable
    global rdconfig router_model router_ConfigModel
    global def_router_model
    global nodeNamingBase

    lassign $rdconfig ripEnable ripngEnable ospfEnable ospf6Enable bgpEnable
    set router_ConfigModel $router_model

    setNodeName $node_id [getNewNodeNameType router $nodeNamingBase(router)]
    setNodeModel $node_id $router_model

    setNodeProtocol $node_id "rip" $ripEnable
    setNodeProtocol $node_id "ripng" $ripngEnable
    setNodeProtocol $node_id "ospf" $ospfEnable
    setNodeProtocol $node_id "ospf6" $ospf6Enable
    setNodeProtocol $node_id "bgp" $bgpEnable

    setAutoDefaultRoutesStatus $node_id "enabled"

    set logiface_id [newLogIface $node_id "lo"]
    setIfcIPv4addrs $node_id $logiface_id "127.0.0.1/8"
    setIfcIPv6addrs $node_id $logiface_id "::1/128"
}

#****f* genericrouter.tcl/router.icon
# NAME
#   router.icon -- icon
# SYNOPSIS
#   router.icon $size
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
	    return $ROOTDIR/$LIBDIR/icons/normal/router.gif
	}
	small {
	    return $ROOTDIR/$LIBDIR/icons/small/router.gif
	}
	toolbar {
	    return $ROOTDIR/$LIBDIR/icons/tiny/router.gif
	}
    }
}

#****f* frr.tcl/router.frr.netlayer
# NAME
#   router.frr.netlayer -- layer
# SYNOPSIS
#   set layer [router.frr.netlayer]
# FUNCTION
#   Returns the layer on which the router using frr model
#   operates, i.e. returns NETWORK.
# RESULT
#   * layer -- set to NETWORK
#****
proc $MODULE.netlayer {} {
    return NETWORK
}

#****f* frr.tcl/router.frr.virtlayer
# NAME
#   router.frr.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [router.frr.virtlayer]
# FUNCTION
#   Returns the layer on which the router using model frr is instantiated,
#   i.e. returns VIRTUALIZED.
# RESULT
#   * layer -- set to VIRTUALIZED
#****
proc $MODULE.virtlayer {} {
    return VIRTUALIZED
}

#****f* frr.tcl/router.frr.generateConfig
# NAME
#   router.frr.generateConfig -- configuration generator
# SYNOPSIS
#   set config [router.frr.generateConfig $node_id]
# FUNCTION
#   Generates configuration. This configuration represents the default
#   configuration loaded on the booting time of the virtual nodes and it is
#   closly related to the procedure router.frr.bootcmd.
#   Generated configuration comprises the ip addresses (both ipv4 and ipv6)
#   and interface states (up or down) for each interface of a given node.
#   Static routes are also included.
# INPUTS
#   * node_id - node id (type of the node is router and routing model is frr)
# RESULT
#   * config -- generated configuration
#****
proc $MODULE.generateConfig { node_id } {
    set cfg {}

    # setup interfaces
    set cfg [concat $cfg [getRouterInterfaceCfg $node_id]]

    # setup routing protocols
    foreach protocol { rip ripng ospf ospf6 bgp } {
	set cfg [concat $cfg [getRouterProtocolCfg $node_id $protocol]]
    }

    # setup IPv4/IPv6 static routes
    set cfg [concat $cfg [getRouterStaticRoutes4Cfg $node_id]]
    set cfg [concat $cfg [getRouterStaticRoutes6Cfg $node_id]]

    return $cfg
}

#****f* frr.tcl/router.frr.bootcmd
# NAME
#   router.frr.bootcmd -- boot command
# SYNOPSIS
#   set appl [router.frr.bootcmd $node_id]
# FUNCTION
#   Procedure bootcmd returns the defaut application that reads and employes
#   the configuration generated in router.frr.generateConfig.
#   In this case (procedure router.frr.bootcmd) specific application
#   is frrboot.sh
# INPUTS
#   * node_id - node id (type of the node is router and routing model is frr)
# RESULT
#   * appl -- application that reads the configuration (frrboot.sh)
#****
proc $MODULE.bootcmd { node_id } {
    switch -exact -- [getNodeModel $node_id] {
	"quagga" {
	    return "/usr/local/bin/quaggaboot.sh"
	}
	"frr" {
	    return "/usr/local/bin/frrboot.sh"
	}
	"static" {
	    return "/bin/sh"
	}
    }
}

#****f* frr.tcl/router.frr.shellcmds
# NAME
#   router.frr.shellcmds -- shell commands
# SYNOPSIS
#   set shells [router.frr.shellcmds]
# FUNCTION
#   Procedure shellcmds returns the shells that can be opened
#   as a default shell for the system.
# RESULT
#   * shells -- default shells for the router.frr
#****
proc $MODULE.shellcmds {} {
    return "csh bash vtysh sh tcsh"
}

#****f* frr.tcl/router.frr.nodeCreate
# NAME
#   router.frr.nodeCreate -- instantiate
# SYNOPSIS
#   router.frr.nodeCreate $eid $node_id
# FUNCTION
#   Creates a new virtual node for a given node in imunes. 
#   Procedure router.frr.nodeCreate cretaes a new virtual node with all
#   the interfaces and CPU parameters as defined in imunes. It sets the
#   net.inet.ip.forwarding and net.inet6.ip6.forwarding kernel variables to 1.
# INPUTS
#   * eid - experiment id
#   * node_id - node id (type of the node is router and routing model is frr)
#****
proc $MODULE.nodeCreate { eid node_id } {
    l3node.nodeCreate $eid $node_id
}

proc $MODULE.nodeNamespaceSetup { eid node_id } {
    l3node.nodeNamespaceSetup $eid $node_id
}

proc $MODULE.nodeInitConfigure { eid node_id } {
    l3node.nodeInitConfigure $eid $node_id
    enableIPforwarding $eid $node_id
}

proc $MODULE.nodePhysIfacesCreate { eid node_id ifaces } {
    l3node.nodePhysIfacesCreate $eid $node_id $ifaces
}

#****f* frr.tcl/router.frr.start
# NAME
#   router.frr.start -- start
# SYNOPSIS
#   router.frr.start $eid $node_id
# FUNCTION
#   Starts a new router.frr. The node can be started if it is instantiated.
#   Simulates the booting proces of a router.frr, by calling l3node.start
#   procedure.
# INPUTS
#   * eid - experiment id
#   * node_id - node id (type of the node is router.frr)
#****
proc $MODULE.start { eid node_id } {
    l3node.start $eid $node_id
}

#****f* frr.tcl/router.frr.shutdown
# NAME
#   router.frr.shutdown -- shutdown
# SYNOPSIS
#   router.frr.shutdown $eid $node_id
# FUNCTION
#   Shutdowns a router.frr. Simulates the shutdown proces of a
#   router.frr, by calling the l3node.shutdown procedure.
# INPUTS
#   * eid - experiment id
#   * node_id - node id (type of the node is router.frr)
#****
proc $MODULE.shutdown { eid node_id } {
    l3node.shutdown $eid $node_id
}

proc $MODULE.destroyIfcs { eid node_id ifaces } {
    l3node.destroyIfcs $eid $node_id $ifaces
}

#****f* frr.tcl/router.frr.destroy
# NAME
#   router.frr.destroy -- destroy
# SYNOPSIS
#   router.frr.destroy $eid $node_id
# FUNCTION
#   Destroys a router.frr. Destroys all the interfaces of the router.frr
#   and the vimage itself by calling l3node.destroy procedure.
# INPUTS
#   * eid - experiment id
#   * node_id - node id (type of the node is router.frr)
#****
proc $MODULE.destroy { eid node_id } {
    l3node.destroy $eid $node_id
}

#****f* frr.tcl/router.frr.nghook
# NAME
#   router.frr.nghook -- nghook
# SYNOPSIS
#   router.frr.nghook $eid $node_id $iface_id
# FUNCTION
#   Returns the id of the netgraph node and the name of the netgraph hook
#   which is used for connecting two netgraph nodes. This procedure calls
#   l3node.hook procedure and passes the result of that procedure.
# INPUTS
#   * eid - experiment id
#   * node_id - node id
#   * iface_id - interface name
# RESULT
#   * nghook - the list containing netgraph node id and the
#     netgraph hook (ngNode ngHook).
#****
proc $MODULE.nghook { eid node_id iface_id } {
    return [l3node.nghook $eid $node_id $iface_id]
}

#****f* genericrouter.tcl/router.toolbarIconDescr
# NAME
#   router.toolbarIconDescr -- toolbar icon description
# SYNOPSIS
#   router.toolbarIconDescr
# FUNCTION
#   Returns this module's toolbar icon description.
# RESULT
#   * descr -- string describing the toolbar icon
#****
proc $MODULE.toolbarIconDescr {} {
    return "Add new Router"
}

#****f* genericrouter.tcl/router.notebookDimensions
# NAME
#   router.notebookDimensions -- notebook dimensions
# SYNOPSIS
#   router.notebookDimensions $wi
# FUNCTION
#   Returns the specified notebook height and width.
# INPUTS
#   * wi -- widget
# RESULT
#   * size -- notebook size as {height width}
#****
proc $MODULE.notebookDimensions { wi } {
    set h 250
    set w 507

    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Configuration" } {
	set h 360
	set w 507
    }

    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Interfaces" } {
	set h 370
	set w 507
    }

    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "IPsec" } {
	set h 320
	set w 507
    }

    return [list $h $w]
}

#****f* genericrouter.tcl/router.ifacePrefix
# NAME
#   router.ifacePrefix -- interface name
# SYNOPSIS
#   router.ifacePrefix
# FUNCTION
#   Returns router interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifacePrefix { l r } {
    return [l3IfcName $l $r]
}

#****f* genericrouter.tcl/router.layer
# NAME
#   router..layer -- layer
# SYNOPSIS
#   set layer [router.layer]
# FUNCTION
#   Returns the layer on which the router operates, i.e. returns NETWORK.
# RESULT
#   * layer -- set to NETWORK
#****
proc $MODULE.layer {} {
    return NETWORK
}

#****f* genericrouter.tcl/router.IPAddrRange
# NAME
#   router.IPAddrRange -- IP address range
# SYNOPSIS
#   router.IPAddrRange
# FUNCTION
#   Returns router IP address range
# RESULT
#   * range -- router IP address range
#****
proc $MODULE.IPAddrRange {} {
    return 1
}

#****f* genericrouter.tcl/router.configGUI
# NAME
#   router.configGUI -- configuration GUI
# SYNOPSIS
#   router.configGUI $c $node_id
# FUNCTION
#   Defines the structure of the router configuration window by calling
#   procedures for creating and organising the window, as well as procedures
#   for adding certain modules to that window.
# INPUTS
#   * c -- tk canvas
#   * node_id -- node id
#****
proc $MODULE.configGUI { c node_id } {
    global wi
    global guielements treecolumns ipsecEnable

    set guielements {}

    configGUI_createConfigPopupWin $c
    wm title $wi "router configuration"
    configGUI_nodeName $wi $node_id "Node name:"

    lassign [configGUI_addNotebook $wi $node_id { "Configuration" "Interfaces" "IPsec" }] configtab ifctab ipsectab

    set treecolumns { "OperState State" "NatState Nat" "IPv4addr IPv4 addr" "IPv6addr IPv6 addr" \
	    "MACaddr MAC addr" "MTU MTU" "QLen Queue len" "QDisc Queue disc" "QDrop Queue drop" }
    configGUI_addTree $ifctab $node_id

    configGUI_routingModel $configtab $node_id
    configGUI_customImage $configtab $node_id
    configGUI_attachDockerToExt $configtab $node_id
    configGUI_servicesConfig $configtab $node_id
    configGUI_staticRoutes $configtab $node_id
    configGUI_snapshots $configtab $node_id
    configGUI_customConfig $configtab $node_id
    configGUI_ipsec $ipsectab $node_id

    configGUI_buttonsACNode $wi $node_id
}

#****f* genericrouter.tcl/router.configInterfacesGUI
# NAME
#   router.configInterfacesGUI -- configuration of interfaces GUI
# SYNOPSIS
#   router.configInterfacesGUI $wi $node_id $iface_id
# FUNCTION
#   Defines which modules for changing interfaces parameters are contained in
#   the router configuration window. It is done by calling procedures for
#   adding certain modules to the window.
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
