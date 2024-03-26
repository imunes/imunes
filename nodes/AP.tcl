# 2019-2020 Sorbonne University
# In this version of imunes we added a full integration of emulation of 
# Linux namespaces and CISCO routers, saving of parameters, VLANs, WiFi 
# emulation and other features
# This work was developed by Benadji Hanane and Oulad Said Chawki
# Supervised and maintained by Naceur Malouch - LIP6/SU
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

# $Id: quagga.tcl 128 2014-12-19 11:59:09Z denis $


#****h* imunes/quagga.tcl
# NAME
#  router.quagga.tcl -- defines specific procedures for router 
#  using quagga routing model
# FUNCTION
#  This module defines all the specific procedures for a router
#  which uses quagga routing model.
# NOTES
#  Procedures in this module start with the keyword router.quagga and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE wifiAP

registerModule $MODULE

registerRouterModule $MODULE

#****f* quagga.tcl/router.quagga.layer
# NAME
#   router.quagga.layer -- layer
# SYNOPSIS
#   set layer [router.quagga.layer]
# FUNCTION
#   Returns the layer on which the router using quagga model
#   operates, i.e. returns NETWORK. 
# RESULT
#   * layer -- set to NETWORK
#****
proc $MODULE.layer {} {
    return NETWORK
}

#****f* quagga.tcl/router.quagga.virtlayer
# NAME
#   router.quagga.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [router.quagga.virtlayer]
# FUNCTION
#   Returns the layer on which the router using model quagga is instantiated,
#   i.e. returns VIMAGE. 
# RESULT
#   * layer -- set to VIMAGE
#****
proc $MODULE.virtlayer {} {
    return WIFIAP
}

#****f* quagga.tcl/router.quagga.cfggen
# NAME
#   router.quagga.cfggen -- configuration generator
# SYNOPSIS
#   set config [router.quagga.cfggen $node]
# FUNCTION
#   Generates configuration. This configuration represents the default
#   configuration loaded on the booting time of the virtual nodes and it is
#   closly related to the procedure router.quagga.bootcmd.
#   Generated configuration comprises the ip addresses (both ipv4 and ipv6)
#   and interface states (up or down) for each interface of a given node.
#   Static routes are also included.
# INPUTS
#   * node - node id (type of the node is router and routing model is quagga)
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

#****f* quagga.tcl/router.quagga.shellcmds
# NAME
#   router.quagga.shellcmds -- shell commands
# SYNOPSIS
#   set shells [router.quagga.shellcmds]
# FUNCTION
#   Procedure shellcmds returns the shells that can be opened
#   as a default shell for the system. 
# RESULT
#   * shells -- default shells for the router.quagga
#****
proc $MODULE.shellcmds {} {
    return "csh bash sh tcsh"
}

#****f* quagga.tcl/router.quagga.instantiate
# NAME
#   router.quagga.instantiate -- instantiate
# SYNOPSIS
#   router.quagga.instantiate $eid $node
# FUNCTION
#   Creates a new virtual node for a given node in imunes. 
#   Procedure router.quagga.instantiate cretaes a new virtual node with all
#   the interfaces and CPU parameters as defined in imunes. It sets the
#   net.inet.ip.forwarding and net.inet6.ip6.forwarding kernel variables to 1.
# INPUTS
#   * eid - experiment id
#   * node - node id (type of the node is router and routing model is quagga)
#****
proc $MODULE.instantiate { eid node } {
    global inst_pipes last_inst_pipe

    l3node.instantiateAP $eid $node

    enableIPforwarding $eid $node
}

#****f* quagga.tcl/router.quagga.start
# NAME
#   router.quagga.start -- start
# SYNOPSIS
#   router.quagga.start $eid $node
# FUNCTION
#   Starts a new router.quagga. The node can be started if it is instantiated. 
#   Simulates the booting proces of a router.quagga, by calling l3node.start 
#   procedure.
# INPUTS
#   * eid - experiment id
#   * node - node id (type of the node is router.quagga)
#****
proc $MODULE.start { eid node } {
    l3node.start $eid $node
}

#****f* quagga.tcl/router.quagga.shutdown
# NAME
#   router.quagga.shutdown -- shutdown
# SYNOPSIS
#   router.quagga.shutdown $eid $node
# FUNCTION
#   Shutdowns a router.quagga. Simulates the shutdown proces of a
#   router.quagga, by calling the l3node.shutdown procedure.
# INPUTS
#   * eid - experiment id
#   * node - node id (type of the node is router.quagga)
#****
proc $MODULE.shutdown { eid node } {
    l3node.shutdown $eid $node
}

#****f* quagga.tcl/router.quagga.destroy
# NAME
#   router.quagga.destroy -- destroy
# SYNOPSIS
#   router.quagga.destroy $eid $node
# FUNCTION
#   Destroys a router.quagga. Destroys all the interfaces of the router.quagga 
#   and the vimage itself by calling l3node.destroy procedure. 
# INPUTS
#   * eid - experiment id
#   * node - node id (type of the node is router.quagga)
#****
proc $MODULE.destroy { eid node } {
    l3node.destroy $eid $node
}

#****f* quagga.tcl/router.quagga.nghook
# NAME
#   router.quagga.nghook -- nghook
# SYNOPSIS
#   router.quagga.nghook $eid $node $ifc 
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
 if {[[typemodel $node].virtlayer] == "WIFIAP"} {
    configGUI_createConfigPopupWin $c
    wm title $wi "AP configuration"
    configGUI_nodeName $wi $node "Node name:"

    set tabs [configGUI_addNotebook $wi $node {"Configuration" "Interfaces"}]
    set configtab [lindex $tabs 0]
    set ifctab [lindex $tabs 1]

    set treecolumns {"OperState State" "IPv4addr IPv4 addr" "IPv6addr IPv6 addr" \
	    "MACaddr MAC addr" "MTU MTU" "QLen Queue len" "QDisc Queue disc" "QDrop Queue drop"}
    configGUI_addTree $ifctab $node

    configGUI_WIFIAP $configtab $node

     
    configGUI_buttonsACNode $wi $node

   

    
}
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

proc $MODULE.icon { size } {
    global ROOTDIR LIBDIR
    switch $size {
      normal {
	return $ROOTDIR/$LIBDIR/icons/normal/wifiAP.png
      }
      small {
	return $ROOTDIR/$LIBDIR/icons/small/wifiAP.png
      }
      toolbar {
	return $ROOTDIR/$LIBDIR/icons/tiny/wifiAP.png
      }
    }
}

#****f* nouveauRouteur.tcl/nouveauRouteur.toolbarIconDescr
# NAME
#   nouveauRouteur.toolbarIconDescr -- toolbar icon description
# SYNOPSIS
#   nouveauRouteur.toolbarIconDescr
# FUNCTION
#   Returns this module's toolbar icon description.
# RESULT
#   * descr -- string describing the toolbar icon
#****
# modification for cisco router 
proc $MODULE.toolbarIconDescr {} {
    return "Add new AP"
}

proc $MODULE.confNewNode { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node
    global nodeNamingBase

    set nconfig [list \
	"hostname [getNewNodeNameType wifiAP $nodeNamingBase(wifiAP)]" \
	! ]
    lappend $node "network-config [list $nconfig]"

    setLogIfcType $node lo0 lo
    setIfcIPv4addr $node lo0 "127.0.0.1/8"
    setIfcIPv6addr $node lo0 "::1/128"
    
   # setLogIfcType $node wlan0 wlan0
   # setIfcIPv4addr $node wlan0 "192.168.0.1/24"
   # setIfcIPv6addr $node wlan0 "::1/128"

}

proc $MODULE.notebookDimensions { wi } {
    set h 390
    set w 507

    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Configuration" } {
	set h 420
	set w 507
    }
    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Interfaces" } {
	set h 370
	set w 507
    }

    return [list $h $w]
}

proc $MODULE.ifcName {l r} {
    return [l3IfcName $l $r]
}


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

proc $MODULE.IPAddrRange {} {
    return 20
}
