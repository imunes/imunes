#
# Copyright 2010-2013 University of Zagreb.
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

# $Id: genericrouter.tcl 130 2015-02-24 09:52:19Z valter $



#****h* imunes/genericrouter.tcl
# NAME
#  genericrouter.tcl -- defines router specific procedures
# FUNCTION
#  This module is used to define all the router specific procedures.
#  All the specific procedures for a router which uses specific routing model
#  (quaga, xorp, static) are defined in quagga.tcl, xorp.tcl, static.tcl.
# NOTES
#  Procedures in this module start with the keyword router and
#  end with function specific part that is the same for all the
#  node types that work on the same layer.
#****


set MODULE router

registerModule $MODULE
registerRouterModule $MODULE

#****f* genericrouter.tcl/router.confNewIfc
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
}

#****f* genericrouter.tcl/router.confNewNode
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
    global ripEnable ripngEnable ospfEnable ospf6Enable
    global rdconfig router_model router_ConfigModel
    global def_router_model
    global nodeNamingBase

    set ripEnable [lindex $rdconfig 0]
    set ripngEnable [lindex $rdconfig 1]
    set ospfEnable [lindex $rdconfig 2]
    set ospf6Enable [lindex $rdconfig 3]
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

    setLogIfcType $node lo0 lo
    setIfcIPv4addr $node lo0 "127.0.0.1/8"
    setIfcIPv6addr $node lo0 "::1/128"
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
	set h 310
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

#****f* genericrouter.tcl/router.ifcName
# NAME
#   router.ifcName -- interface name
# SYNOPSIS
#   router.ifcName
# FUNCTION
#   Returns router interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifcName {l r} {
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

    set tabs [configGUI_addNotebook $wi $node {"Configuration" "Interfaces" "IPsec"}]
    set configtab [lindex $tabs 0]
    set ifctab [lindex $tabs 1]
    set ipsectab [lindex $tabs 2]

    set treecolumns {"OperState State" "IPv4addr IPv4 addr" "IPv6addr IPv6 addr" \
	    "MACaddr MAC addr" "MTU MTU" "QLen Queue len" "QDisc Queue disc" "QDrop Queue drop" }
    configGUI_addTree $ifctab $node

    configGUI_routingModel $configtab $node
    configGUI_dockerImage $configtab $node
    configGUI_attachDockerToExt $configtab $node
    configGUI_servicesConfig $configtab $node
    configGUI_staticRoutes $configtab $node
    configGUI_snapshots $configtab $node
    configGUI_customConfig $configtab $node
    configGUI_ipsec $ipsectab $node

    configGUI_buttonsACNode $wi $node
}

#****f* genericrouter.tcl/router.configInterfacesGUI
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
