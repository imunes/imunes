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

# $Id: router.tcl 128 2014-12-19 11:59:09Z denis $


#****h* imunes/router.tcl
# NAME
#  router.tcl -- defines specific procedures for router
#  using frr/quagga/static routing model
# FUNCTION
#  This module defines all the specific procedures for a router
#  which uses any routing model.
# NOTES
#  Procedures in this module start with the keyword router and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE router
registerModule $MODULE

################################################################################
########################### CONFIGURATION PROCEDURES ###########################
################################################################################

#****f* router.tcl/router.confNewNode
# NAME
#   router.confNewNode -- configure new node
# SYNOPSIS
#   router.confNewNode $node
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node -- node id
#****
proc $MODULE.confNewNode { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node
    global ripEnable ripngEnable ospfEnable ospf6Enable bgpEnable
    global rdconfig router_model router_ConfigModel
    global def_router_model
    global nodeNamingBase

    set ripEnable [lindex $rdconfig 0]
    set ripngEnable [lindex $rdconfig 1]
    set ospfEnable [lindex $rdconfig 2]
    set ospf6Enable [lindex $rdconfig 3]
    set bgpEnable [lindex $rdconfig 4]
    set router_ConfigModel $router_model

    if { $router_model != $def_router_model } {
	lappend $node "model $router_model"
    } else {
	lappend $node "model $def_router_model"
    }

    set nconfig [list \
	"hostname [getNewNodeNameType router $nodeNamingBase(router)]" \
	! ]
    lappend $node "network-config [list $nconfig]"

    setNodeProtocolRip $node $ripEnable
    setNodeProtocolRipng $node $ripngEnable
    setNodeProtocolOspfv2 $node $ospfEnable
    setNodeProtocolOspfv3 $node $ospf6Enable
    setNodeProtocolBgp $node $bgpEnable

    setAutoDefaultRoutesStatus $node "enabled"
    setLogIfcType $node lo0 lo
    setIfcIPv4addrs $node lo0 "127.0.0.1/8"
    setIfcIPv6addrs $node lo0 "::1/128"
}

#****f* router.tcl/router.confNewIfc
# NAME
#   router.confNewIfc -- configure new interface
# SYNOPSIS
#   router.confNewIfc $node $ifc
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

    lassign [logicalPeerByIfc $node $ifc] peer_node -
    if { [getNodeType $peer_node] == "extnat" } {
	setIfcNatState $node $ifc "on"
    }
}

#****f* router.tcl/router.generateConfig
# NAME
#   router.generateConfig -- configuration generator
# SYNOPSIS
#   set config [router.generateConfig $node]
# FUNCTION
#   Generates configuration. This configuration represents the default
#   configuration loaded on the booting time of the virtual nodes and it is
#   closly related to the procedure router.bootcmd.
#   Generated configuration comprises the ip addresses (both ipv4 and ipv6)
#   and interface states (up or down) for each interface of a given node.
#   Static routes are also included.
# INPUTS
#   * node - node id
# RESULT
#   * congif -- generated configuration
#****
proc $MODULE.generateConfig { node } {
    set cfg {}

    switch -exact -- [getNodeModel $node] {
	"quagga" -
	"frr" {
	    upvar 0 ::cf::[set ::curcfg]::$node $node

	    foreach ifc [allIfcList $node] {
		lappend cfg "interface $ifc"
		set addrs [getIfcIPv4addrs $node $ifc]
		foreach addr $addrs {
		    if { $addr != "" } {
			lappend cfg " ip address $addr"
		    }
		}
		set addrs [getIfcIPv6addrs $node $ifc]
		foreach addr $addrs {
		    if { $addr != "" } {
			lappend cfg " ipv6 address $addr"
		    }
		}
		if { [getIfcOperState $node $ifc] == "down" } {
		    lappend cfg " shutdown"
		}
		lappend cfg "!"
	    }

	    foreach proto { rip ripng ospf ospf6 bgp } {
		if { $proto == "bgp" } {
		    set proto "bgp 1000"
		}

		set protocfg [netconfFetchSection $node "router $proto"]
		if { $protocfg != "" } {
		    lappend cfg "router $proto"
		    foreach line $protocfg {
			lappend cfg "$line"
		    }
		    if {$proto == "ospf6"} {
			foreach ifc [allIfcList $node] {
			    if {$ifc == "lo0"} {
				continue
			    }
			    lappend cfg " interface $ifc area 0.0.0.0"
			}
		    }
		    lappend cfg "!"
		}
	    }

	    foreach statrte [getStatIPv4routes $node] {
		lappend cfg "ip route $statrte"
	    }
	    foreach statrte [getStatIPv6routes $node] {
		lappend cfg "ipv6 route $statrte"
	    }

	    if { [getAutoDefaultRoutesStatus $node] == "enabled" } {
		foreach statrte [getDefaultIPv4routes $node] {
		    lappend cfg "ip route $statrte"
		}
		foreach statrte [getDefaultIPv6routes $node] {
		    lappend cfg "ipv6 route $statrte"
		}
		setDefaultIPv4routes $node {}
		setDefaultIPv6routes $node {}
	    }
	}
	"static" {
	    set cfg [concat $cfg [nodeCfggenIfcIPv4 $node]]
	    set cfg [concat $cfg [nodeCfggenIfcIPv6 $node]]
	    lappend cfg ""

	    set cfg [concat $cfg [nodeCfggenRouteIPv4 $node]]
	    set cfg [concat $cfg [nodeCfggenRouteIPv6 $node]]
	}
    }

    return $cfg
}

#****f* router.tcl/router.ifacePrefix
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

#****f* router.tcl/router.IPAddrRange
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

#****f* router.tcl/router.netlayer
# NAME
#   router.netlayer -- layer
# SYNOPSIS
#   set layer [router.netlayer]
# FUNCTION
#   Returns the layer on which the router operates, i.e. returns NETWORK.
# RESULT
#   * layer -- set to NETWORK
#****
proc $MODULE.netlayer {} {
    return NETWORK
}

#****f* router.tcl/router.virtlayer
# NAME
#   router.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [router.virtlayer]
# FUNCTION
#   Returns the layer on which the router is instantiated, i.e. returns
#   VIRTUALIZED.
# RESULT
#   * layer -- set to VIRTUALIZED
#****
proc $MODULE.virtlayer {} {
    return VIRTUALIZED
}

#****f* router.tcl/router.bootcmd
# NAME
#   router.bootcmd -- boot command
# SYNOPSIS
#   set appl [router.bootcmd $node]
# FUNCTION
#   Procedure bootcmd returns the defaut application that reads and employes
#   the configuration generated in router.generateConfig.
# INPUTS
#   * node - node id
# RESULT
#   * appl -- application that reads the configuration
#****
proc $MODULE.bootcmd { node } {
    switch -exact -- [getNodeModel $node] {
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

#****f* router.tcl/router.shellcmds
# NAME
#   router.shellcmds -- shell commands
# SYNOPSIS
#   set shells [router.shellcmds]
# FUNCTION
#   Procedure shellcmds returns the shells that can be opened
#   as a default shell for the system.
# RESULT
#   * shells -- default shells for the router
#****
proc $MODULE.shellcmds {} {
    return "csh bash vtysh sh tcsh"
}

#****f* router.tcl/router.nghook
# NAME
#   router.nghook -- nghook
# SYNOPSIS
#   router.nghook $eid $node $ifc
# FUNCTION
#   Returns the id of the netgraph node and the name of the netgraph hook
#   which is used for connecting two netgraph nodes. This procedure calls
#   l3node.hook procedure and passes the result of that procedure.
# INPUTS
#   * eid - experiment id
#   * node - node id
#   * ifc - interface name
# RESULT
#   * nghook - the list containing netgraph node id and the
#     netgraph hook (ngNode ngHook).
#****
proc $MODULE.nghook { eid node ifc } {
    return [l3node.nghook $eid $node $ifc]
}

################################################################################
############################ INSTANTIATE PROCEDURES ############################
################################################################################

#****f* router.tcl/router.nodeCreate
# NAME
#   router.nodeCreate -- instantiate
# SYNOPSIS
#   router.nodeCreate $eid $node
# FUNCTION
#   Creates a new virtual node for a given node in imunes.
#   Procedure router.nodeCreate creates a new virtual node with all
#   the interfaces and CPU parameters as defined in imunes. It sets the
#   net.inet.ip.forwarding and net.inet6.ip6.forwarding kernel variables to 1.
# INPUTS
#   * eid - experiment id
#   * node - node id
#****
proc $MODULE.nodeCreate { eid node } {
    l3node.nodeCreate $eid $node
}

#****f* router.tcl/router.nodeNamespaceSetup
# NAME
#   router.nodeNamespaceSetup -- router node nodeNamespaceSetup
# SYNOPSIS
#   router.nodeNamespaceSetup $eid $node
# FUNCTION
#   Linux only. Attaches the existing Docker netns to a new one.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc $MODULE.nodeNamespaceSetup { eid node } {
    l3node.nodeNamespaceSetup $eid $node
}

#****f* router.tcl/router.nodeInitConfigure
# NAME
#   router.nodeInitConfigure -- router node nodeInitConfigure
# SYNOPSIS
#   router.nodeInitConfigure $eid $node
# FUNCTION
#   Runs initial L3 configuration, such as creating logical interfaces and
#   configuring sysctls.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc $MODULE.nodeInitConfigure { eid node } {
    l3node.nodeInitConfigure $eid $node
    enableIPforwarding $eid $node
}

proc $MODULE.nodePhysIfacesCreate { eid node ifcs } {
    l3node.nodePhysIfacesCreate $eid $node $ifcs
}

#****f* router.tcl/router.nodeConfigure
# NAME
#   router.nodeConfigure -- start
# SYNOPSIS
#   router.nodeConfigure $eid $node
# FUNCTION
#   Starts a new router. The node can be started if it is instantiated.
#   Simulates the booting proces of a router.
# INPUTS
#   * eid - experiment id
#   * node - node id
#****
proc $MODULE.nodeConfigure { eid node } {
    l3node.nodeConfigure $eid $node
}

################################################################################
############################# TERMINATE PROCEDURES #############################
################################################################################

proc $MODULE.nodeIfacesDestroy { eid node ifcs } {
    l3node.nodeIfacesDestroy $eid $node $ifcs
}

#****f* router.tcl/router.nodeShutdown
# NAME
#   router.nodeShutdown -- shutdown
# SYNOPSIS
#   router.nodeShutdown $eid $node
# FUNCTION
#   Shutdowns a router node.
#   Simulates the shutdown proces of a node, kills all the services and
# INPUTS
#   * eid - experiment id
#   * node - node id
#****
proc $MODULE.nodeShutdown { eid node } {
    l3node.nodeShutdown $eid $node
}

#****f* router.tcl/router.nodeDestroy
# NAME
#   router.nodeDestroy -- layer 3 node destroy
# SYNOPSIS
#   router.nodeDestroy $eid $node
# FUNCTION
#   Destroys a router node.
#   First, it destroys all remaining virtual ifaces (vlans, tuns, etc).
#   Then, it destroys the jail/container with its namespaces and FS.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc $MODULE.nodeDestroy { eid node } {
    l3node.nodeDestroy $eid $node
}

################################################################################
################################ GUI PROCEDURES ################################
################################################################################

#****f* router.tcl/router.icon
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

#****f* router.tcl/router.toolbarIconDescr
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

#****f* router.tcl/router.notebookDimensions
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

#****f* router.tcl/router.configGUI
# NAME
#   router.configGUI -- configuration GUI
# SYNOPSIS
#   router.configGUI $c $node
# FUNCTION
#   Defines the structure of the router configuration window by calling
#   procedures for creating and organising the window, as well as procedures
#   for adding certain modules to that window.
# INPUTS
#   * c -- tk canvas
#   * node -- node id
#****
proc $MODULE.configGUI { c node } {
    global wi
    global guielements treecolumns ipsecEnable

    set guielements {}

    configGUI_createConfigPopupWin $c
    wm title $wi "router configuration"
    configGUI_nodeName $wi $node "Node name:"

    lassign [configGUI_addNotebook $wi $node { "Configuration" "Interfaces" "IPsec" }] configtab ifctab ipsectab

    set treecolumns { "OperState State" "NatState Nat" "IPv4addrs IPv4 addrs" "IPv6addrs IPv6 addrs" \
	"MACaddr MAC addr" "MTU MTU" "QLen Queue len" "QDisc Queue disc" "QDrop Queue drop" }
    configGUI_addTree $ifctab $node

    configGUI_routingModel $configtab $node
    configGUI_customImage $configtab $node
    configGUI_attachDockerToExt $configtab $node
    configGUI_servicesConfig $configtab $node
    configGUI_staticRoutes $configtab $node
    configGUI_snapshots $configtab $node
    configGUI_customConfig $configtab $node
    configGUI_ipsec $ipsectab $node

    configGUI_buttonsACNode $wi $node
}

#****f* router.tcl/router.configInterfacesGUI
# NAME
#   router.configInterfacesGUI -- configuration of interfaces GUI
# SYNOPSIS
#   router.configInterfacesGUI $wi $node $ifc
# FUNCTION
#   Defines which modules for changing interfaces parameters are contained in
#   the router configuration window. It is done by calling procedures for
#   adding certain modules to the window.
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
