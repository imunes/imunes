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

proc $MODULE._confNewIfc { node_cfg iface_id } {
    global changeAddressRange changeAddressRange6
    global node_existing_mac node_existing_ipv4 node_existing_ipv6

    set changeAddressRange 0
    set changeAddressRange6 0

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
    #
    #guielements - the list of modules contained in the configuration window
    #              (each element represents the name of the procedure which creates
    #              that module)
    #
    #treecolumns - the list of columns in the interfaces tree (each element
    #              consists of the column id and the column name)
    #
    global guielements treecolumns ipsecEnable
    global node_cfg node_existing_mac node_existing_ipv4 node_existing_ipv6

    set guielements {}
    set treecolumns {}
    set node_cfg [cfgGet "nodes" $node_id]
    set node_existing_mac [getFromRunning "mac_used_list"]
    set node_existing_ipv4 [getFromRunning "ipv4_used_list"]
    set node_existing_ipv6 [getFromRunning "ipv6_used_list"]

    configGUI_createConfigPopupWin $c
    wm title $wi "router configuration"

    configGUI_nodeName $wi $node_id "Node name:"

    lassign [configGUI_addNotebook $wi $node_id {"Configuration" "Interfaces" "IPsec"}] configtab ifctab ipsectab

    configGUI_routingModel $configtab $node_id
    configGUI_customImage $configtab $node_id
    configGUI_attachDockerToExt $configtab $node_id
    configGUI_servicesConfig $configtab $node_id
    configGUI_staticRoutes $configtab $node_id
    configGUI_snapshots $configtab $node_id
    configGUI_customConfig $configtab $node_id
    configGUI_ipsec $ipsectab $node_id

    set treecolumns {"OperState State" "NatState Nat" "IPv4addr IPv4 addr" "IPv6addr IPv6 addr" \
	"MACaddr MAC addr" "MTU MTU" "QLen Queue len" "QDisc Queue disc" "QDrop Queue drop" }
    configGUI_addTree $ifctab $node_id

    configGUI_nodeRestart $wi $node_id
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