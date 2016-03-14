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

# $Id: ipfirewall.tcl 63 2013-10-03 12:17:50Z valter $



#****h* imunes/ipfirewall.tcl
# NAME
#  ipfirewall.tcl -- defines IP firewall specific procedures
# FUNCTION
#  This module is used to define all the IP firewall specific procedures.
# NOTES
#  Procedures in this module start with the keyword ipfirewall and
#  end with function specific part that is the same for all the
#  node types that work on the same layer.
#****


set MODULE ipfirewall

registerModule $MODULE

#****f* ipfirewall.tcl/ipfirewall.icon
# NAME
#   ipfirewall.icon -- icon
# SYNOPSIS
#   ipfirewall.icon $size
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
	return $ROOTDIR/$LIBDIR/icons/normal/ipfirewall.gif
      }
      small {
	return $ROOTDIR/$LIBDIR/icons/small/ipfirewall.gif
      }
      toolbar {
	return $ROOTDIR/$LIBDIR/icons/tiny/ipfirewall.gif
      }
    }
}

#****f* ipfirewall.tcl/ipfirewall.toolbarIconDescr
# NAME
#   ipfirewall.toolbarIconDescr -- toolbar icon description
# SYNOPSIS
#   ipfirewall.toolbarIconDescr
# FUNCTION
#   Returns this module's toolbar icon description.
# RESULT
#   * descr -- string describing the toolbar icon
#****
proc $MODULE.toolbarIconDescr {} {
    return "Add new IP firewall"
}

#****f* ipfirewall.tcl/ipfirewall.notebookDimensions
# NAME
#   ipfirewall.notebookDimensions -- notebook dimensions
# SYNOPSIS
#   ipfirewall.notebookDimensions $wi
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
	set h 320
	set w 507
    }

    return [list $h $w] 
}

#****f* ipfirewall.tcl/ipfirewall.ifcName
# NAME
#   ipfirewall.ifcName -- interface name
# SYNOPSIS
#   ipfirewall.ifcName
# FUNCTION
#   Returns ipfirewall interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifcName {l r} {
    return [l3IfcName $l $r]
}

#****f* ipfirewall.tcl/ipfirewall.IPAddrRange
# NAME
#   ipfirewall.IPAddrRange -- IP address range
# SYNOPSIS
#   ipfirewall.IPAddrRange
# FUNCTION
#   Returns ipfirewall IP address range
# RESULT
#   * range -- ipfirewall IP address range
#****
proc $MODULE.IPAddrRange {} {
    return 30
}

#****f* ipfirewall.tcl/ipfirewall.layer
# NAME
#   ipfirewall.layer -- layer
# SYNOPSIS
#   set layer [ipfirewall.layer]
# FUNCTION
#   Returns the layer on which the ipfirewall operates i.e. returns NETWORK. 
# RESULT
#   * layer -- set to NETWORK
#****
proc $MODULE.layer {} {
    return NETWORK
}

#****f* ipfirewall.tcl/ipfirewall.cfggen
# NAME
#   ipfirewall.cfggen -- configuration generator
# SYNOPSIS
#   set config [ipfirewall.cfggen $node]
# FUNCTION
#   Returns the generated configuration. This configuration represents
#   the configuration loaded on the booting time of the virtual nodes
#   and it is closly related to the procedure host.bootcmd.
#   Foreach interface in the interface list of the node ip address is
#   configured and each static route from the simulator is added.
# INPUTS
#   * node -- node id (type of the node is ipfirewall)
# RESULT
#   * congif -- generated configuration 
#****
proc $MODULE.cfggen { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set cfg {}

    foreach ifc [ifcList $node] {
	set addr [getIfcIPv4addr $node $ifc]
	if { $addr != "" } {
	    lappend cfg "ifconfig $ifc inet $addr"
	}
	set addr [getIfcIPv6addr $node $ifc]
	if { $addr != "" } {
	    lappend cfg "ifconfig $ifc inet6 $addr"
	}
    }
    lappend cfg ""

    foreach statrte [getStatIPv4routes $node] {
	lappend cfg "route -q add -inet $statrte"
    }
    foreach statrte [getStatIPv6routes $node] {
	lappend cfg "route -q add -inet6 $statrte"
    }

    return $cfg
}

#****f* ipfirewall.tcl/ipfirewall.bootcmd
# NAME
#   ipfirewall.bootcmd -- boot command
# SYNOPSIS
#   set appl [ipfirewall.bootcmd $node]
# FUNCTION
#   Procedure bootcmd returns the application that reads and employes the
#   configuration generated in ipfirewall.cfggen.
#   In this case (procedure ipfirewall.bootcmd) specific application is /bin/sh
# INPUTS
#   * node -- node id (type of the node is ipfirewall)
# RESULT
#   * appl -- application that reads the configuration (/bin/sh) 
#****
proc $MODULE.bootcmd { node } {
    return "/bin/sh"
}

#****f* ipfirewall.tcl/ipfirewall.shellcmds
# NAME
#   ipfirewall.shellcmds -- shell commands
# SYNOPSIS
#   set shells [ipfirewall.shellcmds]
# FUNCTION
#   Procedure shellcmds returns the shells that can be opened
#   as a default shell for the system. 
# RESULT
#   * shells -- default shells for the ipfirewall
#****
proc $MODULE.shellcmd { node } {
    set ret [nexec whereis -b bash]
    if { [llength $ret] == 2 } {
	return [lindex $ret 1]
    } else {
	set ret [nexec whereis -b tcsh]
	if { [llength $ret] == 2 } {
	    return [lindex $ret 1]
	} else {
	    return "/bin/csh"
	}
    }
}

#****f* ipfirewall.tcl/ipfirewall.instantiate
# NAME
#   ipfirewall.instantiate -- instantiate
# SYNOPSIS
#   ipfirewall.instantiate $eid $node
# FUNCTION
#   Procedure instantiate creates a new virtaul node
#   for a given node in imunes. 
#   Procedure ipfirewall.instantiate cretaes a new virtual node with
#   all the interfaces and CPU parameters as defined in imunes.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is ipfirewall)
#****
proc $MODULE.instantiate { eid node } {
    l3node.instantiate $eid $node
}

#****f* ipfirewall.tcl/ipfirewall.start
# NAME
#   ipfirewall.start -- start
# SYNOPSIS
#   ipfirewall.start $eid $node
# FUNCTION
#   Starts a new ipfirewall. The node can be started if it is instantiated. 
#   Simulates the booting proces of an ipfirewall, by calling l3node.start 
#   procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is ipfirewall)
#****
proc $MODULE.start { eid node } {
    l3node.start $eid $node
}

#****f* ipfirewall.tcl/ipfirewall.shutdown
# NAME
#   ipfirewall.shutdown -- shutdown
# SYNOPSIS
#   ipfirewall.shutdown $eid $node
# FUNCTION
#   Shutdowns an ipfirewall. Simulates the shutdown proces of an ipfirewall, 
#   by calling the l3node.shutdown procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is ipfirewall)
#****
proc $MODULE.shutdown { eid node } {
    l3node.shutdown $eid $node
}

#****f* ipfirewall.tcl/ipfirewall.destroy
# NAME
#   ipfirewall.destroy -- destroy
# SYNOPSIS
#   ipfirewall.destroy $eid $node
# FUNCTION
#   Destroys an ipfirewall. Destroys all the interfaces of the ipfirewall 
#   and the vimage itself by calling l3node.destroy procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is ipfirewall)
#****
proc $MODULE.destroy { eid node } {
    l3node.destroy $eid $node
}

#****f* ipfirewall.tcl/ipfirewall.nghook
# NAME
#   ipfirewall.nghook -- nghook
# SYNOPSIS
#   ipfirewall.nghook $eid $node $ifc 
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

#****f* ipfirewall.tcl/ipfirewall.configGUI
# NAME
#   ipfirewall.configGUI -- configuration GUI
# SYNOPSIS
#   ipfirewall.configGUI $c $node
# FUNCTION
#   Defines the structure of the ipfirewall configuration window by calling
#   procedures for creating and organising the window, as well as procedures
#   for adding certain modules to that window.
# INPUTS
#   * c - tk canvas
#   * node - node id
#****
proc $MODULE.configGUI { c node } {
    global wi
    global guielements treecolumns
    set guielements {}

    configGUI_createConfigPopupWin $c
    wm title $wi "IP firewall configuration"
    configGUI_nodeName $wi $node "Node name:"

    set tabs [configGUI_addNotebook $wi $node {"Configuration" "Interfaces"}]
    set configtab [lindex $tabs 0]
    set ifctab [lindex $tabs 1]

    set treecolumns {"OperState State" "Direct Direction" "IPv4addr IPv4 addr" "IPv6addr IPv6 addr" \
	    "MACaddr MAC addr" "MTU MTU" "QDisc Queue disc" "QDrop Queue drop" "QLen Queue len"}
    configGUI_addTree $ifctab $node

    configGUI_staticRoutes $configtab $node
    configGUI_ipfirewallRuleset $configtab $node

    configGUI_buttonsACNode $wi $node
}

#****f* ipfirewall.tcl/ipfirewall.configInterfacesGUI
# NAME
#   ipfirewall.configInterfacesGUI -- configuration of interfaces GUI
# SYNOPSIS
#   ipfirewall.configInterfacesGUI $wi $node $ifc
# FUNCTION
#   Defines which modules for changing interfaces parameters are contained in
#   the ipfirewall configuration window. It is done by calling procedures for
#   adding certain modules to the window.
# INPUTS
#   * wi - widget
#   * node - node id
#   * ifc - interface id
#****
proc $MODULE.configInterfacesGUI { wi node ifc } {
    global guielements

    configGUI_ifcEssentials $wi $node $ifc
    configGUI_ifcDirection $wi $node $ifc
    configGUI_ifcQueueConfig $wi $node $ifc
    configGUI_ifcMACAddress $wi $node $ifc
    configGUI_ifcIPv4Address $wi $node $ifc
    configGUI_ifcIPv6Address $wi $node $ifc
}
