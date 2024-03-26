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

# $Id: click_l3.tcl 63 2013-10-03 12:17:50Z valter $


#****h* imunes/click_l3.tcl
# NAME
#  click_l3.tcl -- defines click_l3 specific procedures
# FUNCTION
#  This module is used to define all the click_l3 specific procedures.
# NOTES
#  Procedures in this module start with the keyword click_l3 and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE click_l3

registerModule $MODULE
registerRouterModule $MODULE

#****f* click_l3.tcl/click_l3.confNewIfc
# NAME
#   click_l3.confNewIfc -- configure new interface
# SYNOPSIS
#   click_l3.confNewIfc $node $ifc
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
    #    autoIPv6addr $node $ifc
    autoMACaddr $node $ifc
}

#****f* click_l3.tcl/click_l3.confNewNode
# NAME
#   click_l3.confNewNode -- configure new node
# SYNOPSIS
#   click_l3.confNewNode $node
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node -- node id
#****
proc $MODULE.confNewNode { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node
    global nodeNamingBase

    set nconfig [list \
	"hostname [getNewNodeNameType click_l3 $nodeNamingBase(click_l3)]" \
	! ]
    lappend $node "network-config [list $nconfig]"

    setLogIfcType $node lo0 lo 
    setIfcIPv4addr $node lo0 "127.0.0.1/8"
    setIfcIPv6addr $node lo0 "::1/128"
}

#****f* click_l3.tcl/click_l3.icon
# NAME
#   click_l3.icon -- icon
# SYNOPSIS
#   click_l3.icon $size
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
	    return $ROOTDIR/$LIBDIR/icons/normal/click_l3.gif
	}
	small {
	    return $ROOTDIR/$LIBDIR/icons/small/click_l3.gif
	}
	toolbar {
	    return $ROOTDIR/$LIBDIR/icons/tiny/click_l3.gif
	}
    }
}

#****f* click_l3.tcl/click_l3.toolbarIconDescr
# NAME
#   click_l3.toolbarIconDescr -- toolbar icon description
# SYNOPSIS
#   click_l3.toolbarIconDescr
# FUNCTION
#   Returns this module's toolbar icon description.
# RESULT
#   * descr -- string describing the toolbar icon
#****
proc $MODULE.toolbarIconDescr {} {
    return "Add new Click Router"
}

#****f* click_l3.tcl/click_l3.notebookDimensions
# NAME
#   click_l3.notebookDimensions -- notebook dimensions
# SYNOPSIS
#   click_l3.notebookDimensions $wi
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

#****f* click_l3.tcl/click_l3.ifcName
# NAME
#   click_l3.ifcName -- interface name
# SYNOPSIS
#   click_l3.ifcName
# FUNCTION
#   Returns click_l3 interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifcName {l r} {
    return [l3IfcName $l $r]
}

#****f* click_l3.tcl/click_l3.IPAddrRange
# NAME
#   click_l3.IPAddrRange -- IP address range
# SYNOPSIS
#   click_l3.IPAddrRange
# FUNCTION
#   Returns click_l3 IP address range
# RESULT
#   * range -- click_l3 IP address range
#****
proc $MODULE.IPAddrRange {} {
    return 20
}

#****f* click_l3.tcl/click_l3.layer
# NAME
#   click_l3.layer -- layer
# SYNOPSIS
#   set layer [click_l3.layer]
# FUNCTION
#   Returns the layer on which the click_l3 communicates, i.e. returns NETWORK. 
# RESULT
#   * layer -- set to NETWORK
#****
proc $MODULE.layer {} {
    return NETWORK
}

#****f* click_l3.tcl/click_l3.virtlayer
# NAME
#   click_l3.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [click_l3.virtlayer]
# FUNCTION
#   Returns the layer on which the click_l3 is instantiated i.e. returns VIMAGE. 
# RESULT
#   * layer -- set to VIMAGE
#****
proc $MODULE.virtlayer {} {
    return VIMAGE
}

#****f* click_l3.tcl/click_l3.cfggen
# NAME
#   click_l3.cfggen -- configuration generator
# SYNOPSIS
#   set config [click_l3.cfggen $node]
# FUNCTION
#   Returns the generated configuration. This configuration represents
#   the configuration loaded on the booting time of the virtual nodes
#   and it is closly related to the procedure click_l3.bootcmd.
#   For each interface in the interface list of the node, ip address is
#   configured and each static route from the simulator is added.
# INPUTS
#   * node -- node id (type of the node is click_l3)
# RESULT
#   * congif -- generated configuration 
#****
proc $MODULE.cfggen { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set cfg {}

    set ifcAddrs {}
    set routes [getStatIPv4routes $node]
    lappend cfg "// routing"
    lappend cfg "rt :: StaticIPLookup("
    foreach ifc [ifcList $node] {
	set addr [getIfcIPv4addr $node $ifc]
	set host [lindex [split $addr /] 0]
	set broadcast [ip::broadcastAddress $addr]
	set prefix [ip::prefix $addr]
	set mask [ip::mask $addr]
	regexp {[0-9]+} $ifc ifNum1
	incr ifNum1
	if { $addr != ""} {
	    lappend cfg "\t$host/32 0,"
	    lappend cfg "\t$broadcast/32 0,"
	    lappend cfg "\t$prefix/$mask $ifNum1,"
	    foreach route $routes {
		set routePrefix [lindex [split $route] 0]
		set nextHop "[lindex [split $route] 1]/32"
		if {[ip::isOverlap $addr $nextHop]} {
		    lappend cfg "\t\t$routePrefix [lindex [split $nextHop /] 0] $ifNum1,"
		}
	    }
	    append ifcAddrs " $addr"
	}
	lappend cfg ""
    }
    lappend cfg "\t255.255.255.255/32 0.0.0.0 0);"
    lappend cfg "ip :: Strip(14)"
    lappend cfg "\t-> CheckIPHeader(INTERFACES$ifcAddrs)"
    lappend cfg "\t-> GetIPAddress(16)"
    lappend cfg "\t-> \[0\]rt;"
    lappend cfg ""
    lappend cfg "ipClass :: IPClassifier(icmp type echo, -);"
    lappend cfg "rt\[0\] -> IPReassembler -> ipClass;"
    lappend cfg "ipClass\[0\] -> ICMPPingResponder -> \[0\]rt;"
    lappend cfg "ipClass\[1\] -> Print(\"to host\") -> Discard;"
    foreach ifc [ifcList $node] {
	set addr [getIfcIPv4addr $node $ifc]
	set host [lindex [split $addr /] 0]
	set mac [getIfcMACaddr $node $ifc]
	set mtu [getIfcMTU $node $ifc]
	regexp {[0-9]+} $ifc ifNum0
	set ifNum1 [expr {$ifNum0 + 1}]
	if { $addr != ""} {
	    lappend cfg "//------------------------------------------------------------------"
	    lappend cfg ""
	    lappend cfg "// $ifc - elements"
	    lappend cfg "in$ifNum0 :: FromDevice($ifc);"
	    lappend cfg "out$ifNum0 :: Queue(256) -> ToDevice($ifc);"
	    lappend cfg "c$ifNum0 :: Classifier(12/0806 20/0001,"
	    lappend cfg "\t\t12/0806 20/0002,"
	    lappend cfg "\t\t12/0800,"
	    lappend cfg "\t\t-);"
	    lappend cfg "arpr$ifNum0 :: ARPResponder($host $mac);"
	    lappend cfg "arpq$ifNum0 :: ARPQuerier($host, $mac);"
	    lappend cfg "cp$ifNum0 :: PaintTee($ifNum1);"
	    lappend cfg "ipgwOptions$ifNum0 :: IPGWOptions($host);"
	    lappend cfg "ttlDec$ifNum0 :: DecIPTTL;"
	    lappend cfg "fragment$ifNum0 :: IPFragmenter($mtu);"
	    lappend cfg ""
	    lappend cfg "// $ifc - input and output"
	    lappend cfg "in$ifNum0 -> \[0\]c$ifNum0;"
	    lappend cfg "c$ifNum0\[0\] -> arpr$ifNum0 -> out$ifNum0;\t\t\t\t\t\t// ARP queries"
	    lappend cfg "c$ifNum0\[1\] -> \[1\]arpq$ifNum0 -> out$ifNum0;\t\t\t\t\t// ARP replies"
	    lappend cfg "c$ifNum0\[2\] -> Paint($ifNum1) -> ip;\t\t\t\t\t// IPv4"
	    lappend cfg "c$ifNum0\[3\] -> Print(\"$ifc other\") -> Discard;\t// not IPv4"
	    lappend cfg ""
	    lappend cfg "// $ifc - forwarding path"
	    lappend cfg "rt\[$ifNum1\] -> DropBroadcasts"
	    lappend cfg "\t-> cp$ifNum0\[0\]"
	    lappend cfg "\t-> ipgwOptions$ifNum0\[0\]"
	    lappend cfg "\t-> FixIPSrc($host)"
	    lappend cfg "\t-> ttlDec$ifNum0\[0\]"
	    lappend cfg "\t-> fragment$ifNum0\[0\]"
	    lappend cfg "\t-> \[0\]arpq$ifNum0;"
	    lappend cfg "cp$ifNum0\[1\] -> ICMPError($host, redirect, host) -> rt;"
	    lappend cfg "ipgwOptions$ifNum0\[1\] -> ICMPError($host, parameterproblem) -> rt;"
	    lappend cfg "ttlDec$ifNum0\[1\] -> ICMPError($host, timeexceeded) -> rt;"
	    lappend cfg "fragment$ifNum0\[1\] -> ICMPError($host, unreachable, needfrag) -> rt;"
	    lappend cfg ""
	}
    }

    return $cfg
}

#****f* click_l3.tcl/click_l3.bootcmd
# NAME
#   click_l3.bootcmd -- boot command
# SYNOPSIS
#   set appl [click_l3.bootcmd $node]
# FUNCTION
#   Procedure bootcmd returns the application that reads and employes the
#   configuration generated in click_l3.cfggen.
#   In this case (procedure click_l3.bootcmd) specific application is /usr/local/bin/click
# INPUTS
#   * node -- node id (type of the node is click_l3)
# RESULT
#   * appl -- application that reads the configuration (/usr/local/bin/click) 
#****
proc $MODULE.bootcmd { node } {
    return "/usr/local/bin/click"
}

#****f* click_l3.tcl/click_l3.shellcmds
# NAME
#   click_l3.shellcmds -- shell commands
# SYNOPSIS
#   set shells [click_l3.shellcmds]
# FUNCTION
#   Procedure shellcmds returns the shells that can be opened
#   as a default shell for the system.
# RESULT
#   * shells -- default shells for the click_l3 node
#****
proc $MODULE.shellcmds {} {
    return "csh bash sh tcsh"
}

#****f* click_l3.tcl/click_l3.instantiate
# NAME
#   click_l3.instantiate -- instantiate
# SYNOPSIS
#   click_l3.instantiate $eid $node
# FUNCTION
#   Procedure instantiate creates a new virtaul node
#   for a given node in imunes.
#   Procedure click_l3.instantiate cretaes a new virtual node with
#   all the interfaces and CPU parameters as defined in imunes. 
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is click_l3)
#****
proc $MODULE.instantiate { eid node } {
    l3node.instantiate $eid $node
}

#****f* click_l3.tcl/click_l3.start
# NAME
#   click_l3.start -- start
# SYNOPSIS
#   click_l3.start $eid $node
# FUNCTION
#   Starts a new click_l3. The node can be started if it is instantiated.
#   Simulates the booting proces of a click_l3, by calling l3node.start procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is click_l3)
#****
proc $MODULE.start { eid node } {
    l3node.start $eid $node
}

#****f* click_l3.tcl/click_l3.shutdown
# NAME
#   click_l3.shutdown -- shutdown
# SYNOPSIS
#   click_l3.shutdown $eid $node
# FUNCTION
#   Shutdowns a click_l3. Simulates the shutdown proces of a click_l3, 
#   by calling the l3node.shutdown procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is click_l3)
#****
proc $MODULE.shutdown { eid node } {
    l3node.shutdown $eid $node
}

#****f* click_l3.tcl/click_l3.destroy
# NAME
#   click_l3.destroy -- destroy
# SYNOPSIS
#   click_l3.destroy $eid $node
# FUNCTION
#   Destroys a click_l3. Destroys all the interfaces of the click_l3 
#   and the vimage itself by calling l3node.destroy procedure. 
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is click_l3)
#****
proc $MODULE.destroy { eid node } {
    l3node.destroy $eid $node
}

#****f* click_l3.tcl/click_l3.nghook
# NAME
#   click_l3.nghook -- nghook
# SYNOPSIS
#   click_l3.nghook $eid $node $ifc 
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

#****f* click_l3.tcl/click_l3.configGUI
# NAME
#   click_l3.configGUI -- configuration GUI
# SYNOPSIS
#   click_l3.configGUI $c $node
# FUNCTION
#   Defines the structure of the click_l3 configuration window by calling
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
    wm title $wi "click_l3 configuration"
    configGUI_nodeName $wi $node "Node name:"

    set tabs [configGUI_addNotebook $wi $node {"Configuration" "Interfaces"}]
    set configtab [lindex $tabs 0]
    set ifctab [lindex $tabs 1]

    set treecolumns {"OperState State" "IPv4addr IPv4 addr" "IPv6addr IPv6 addr" \
	"MACaddr MAC addr" "MTU MTU" "QLen Queue len" "QDisc Queue disc" "QDrop Queue drop"}
    configGUI_addTree $ifctab $node

    configGUI_servicesConfig $configtab $node
    configGUI_staticRoutes $configtab $node
    configGUI_snapshots $configtab $node
    configGUI_customConfig $configtab $node

    configGUI_buttonsACNode $wi $node
}

#****f* click_l3.tcl/click_l3.configInterfacesGUI
# NAME
#   click_l3.configInterfacesGUI -- configuration of interfaces GUI
# SYNOPSIS
#   click_l3.configInterfacesGUI $wi $node $ifc
# FUNCTION
#   Defines which modules for changing interfaces parameters are contained in
#   the click_l3 configuration window. It is done by calling procedures for adding
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
