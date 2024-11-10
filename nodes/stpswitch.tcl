#
# Copyright 2005-2010 University of Zagreb, Croatia.
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

#****h* imunes/stpswitch.tcl
# NAME
#  stpswitch.tcl -- defines stpswitch specific procedures
# FUNCTION
#  This module is used to define all the stpswitch specific procedures.
# NOTES
#  Procedures in this module start with the keyword stpswitch and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE stpswitch
registerModule $MODULE

################################################################################
########################### CONFIGURATION PROCEDURES ###########################
################################################################################

proc $MODULE.confNewNode { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id
    global nodeNamingBase

    set nconfig [list \
	"hostname [getNewNodeNameType stpswitch $nodeNamingBase(stpswitch)]" \
	! ]
    lappend $node_id "network-config [list $nconfig]"

    setBridgeProtocol $node_id "rstp"
    setBridgePriority $node_id "32768"
    setBridgeHoldCount $node_id "6"
    setBridgeMaxAge $node_id "20"
    setBridgeFwdDelay $node_id "15"
    setBridgeHelloTime $node_id "2"
    setBridgeMaxAddr $node_id "100"
    setBridgeTimeout $node_id "240"

    setLogIfcType $node_id lo0 lo
    setIfcIPv4addrs $node_id lo0 "127.0.0.1/8"
    setIfcIPv6addrs $node_id lo0 "::1/128"
}

proc $MODULE.confNewIfc { node_id iface_id } {
    autoMACaddr $node_id $iface_id

    setBridgeIfcDiscover $node_id $iface_id 1
    setBridgeIfcLearn $node_id $iface_id 1
    setBridgeIfcStp $node_id $iface_id 1
    setBridgeIfcAutoedge $node_id $iface_id 1
    setBridgeIfcAutoptp $node_id $iface_id 1
    setBridgeIfcPriority $node_id $iface_id 128
    setBridgeIfcPathcost $node_id $iface_id 0
    setBridgeIfcMaxaddr $node_id $iface_id 0
}

#****f* stpswitch.tcl/stpswitch.generateConfig
# NAME
#   stpswitch.generateConfig
# SYNOPSIS
#   set config [stpswitch.generateConfig $node_id]
# FUNCTION
#   Returns the generated configuration. This configuration represents
#   the configuration loaded on the booting time of the virtual nodes
#   and it is closly related to the procedure stpswitch.bootcmd
#   Foreach interface in the interface list of the node ip address is
#   configured and each static route from the simulator is added.
# INPUTS
#   * node_id - id of the node
# RESULT
#   * config -- generated configuration
#****
proc $MODULE.generateConfig { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set cfg {}

    foreach iface_id [ifcList $node_id] {
	foreach addr [getIfcIPv4addrs $node_id $iface_id] {
	    lappend cfg "ifconfig $iface_id inet $addr"
	}
	foreach addr [getIfcIPv6addrs $node_id $iface_id] {
	    lappend cfg "ifconfig $iface_id inet6 $addr"
	}
    }

    lappend cfg ""

    lappend cfg "bridgeName=`ifconfig bridge create`"

    set bridgeProtocol [getBridgeProtocol $node_id]
    if { $bridgeProtocol != "" } {
	lappend cfg "ifconfig \$bridgeName proto $bridgeProtocol"
    }

    set bridgePriority [getBridgePriority $node_id]
    if { $bridgePriority != "" } {
	lappend cfg "ifconfig \$bridgeName priority $bridgePriority"
    }

    set bridgeMaxAge [getBridgeMaxAge $node_id]
    if { $bridgeMaxAge != "" } {
	lappend cfg "ifconfig \$bridgeName maxage $bridgeMaxAge"
    }

    set bridgeFwdDelay [getBridgeFwdDelay $node_id]
    if { $bridgeFwdDelay != "" } {
	lappend cfg "ifconfig \$bridgeName fwddelay $bridgeFwdDelay"
    }

    set bridgeHoldCnt [getBridgeHoldCount $node_id]
    if { $bridgeHoldCnt != "" } {
	lappend cfg "ifconfig \$bridgeName holdcnt $bridgeHoldCnt"
    }

    set bridgeHelloTime [getBridgeHelloTime $node_id]
    if { $bridgeHelloTime != "" && $bridgeProtocol == "stp" } {
	lappend cfg "ifconfig \$bridgeName hellotime $bridgeHelloTime"
    }

    set bridgeMaxAddr [getBridgeMaxAddr $node_id]
    if { $bridgeMaxAddr != "" } {
	lappend cfg "ifconfig \$bridgeName maxaddr $bridgeMaxAddr"
    }

    set bridgeTimeout [getBridgeTimeout $node_id]
    if { $bridgeTimeout != "" } {
	lappend cfg "ifconfig \$bridgeName timeout $bridgeTimeout"
    }

    lappend cfg ""

    foreach iface_id [ifcList $node_id] {

	if { [getIfcOperState $node_id $iface_id] == "down" } {
	    lappend cfg "ifconfig $iface_id down"
	} else {
	    lappend cfg "ifconfig $iface_id up"
	}

	if { [getBridgeIfcSnoop $node_id $iface_id] == "1" } {
	    lappend cfg "ifconfig \$bridgeName span $iface_id"
	    lappend cfg ""
	    continue
	}

	lappend cfg "ifconfig \$bridgeName addm $iface_id up"

	if { [getBridgeIfcStp $node_id $iface_id] == "1" } {
	    lappend cfg "ifconfig \$bridgeName stp $iface_id"
	} else {
	    lappend cfg "ifconfig \$bridgeName -stp $iface_id"
	}

	if { [getBridgeIfcDiscover $node_id $iface_id] == "1" } {
	    lappend cfg "ifconfig \$bridgeName discover $iface_id"
	} else {
	    lappend cfg "ifconfig \$bridgeName -discover $iface_id"
	}

	if { [getBridgeIfcLearn $node_id $iface_id] == "1" } {
	    lappend cfg "ifconfig \$bridgeName learn $iface_id"
	} else {
	    lappend cfg "ifconfig \$bridgeName -learn $iface_id"
	}

	if { [getBridgeIfcSticky $node_id $iface_id] == "1" } {
	    lappend cfg "ifconfig \$bridgeName sticky $iface_id"
	} else {
	    lappend cfg "ifconfig \$bridgeName -sticky $iface_id"
	}

	if { [getBridgeIfcPrivate $node_id $iface_id] == "1" } {
	    lappend cfg "ifconfig \$bridgeName private $iface_id"
	} else {
	    lappend cfg "ifconfig \$bridgeName -private $iface_id"
	}

	if { [getBridgeIfcEdge $node_id $iface_id] == "1" } {
	    lappend cfg "ifconfig \$bridgeName edge $iface_id"
	} else {
	    lappend cfg "ifconfig \$bridgeName -edge $iface_id"
	}

	if { [getBridgeIfcAutoedge $node_id $iface_id] == "1" } {
	    lappend cfg "ifconfig \$bridgeName autoedge $iface_id"
	} else {
	    lappend cfg "ifconfig \$bridgeName -autoedge $iface_id"
	}

	if { [getBridgeIfcPtp $node_id $iface_id] == "1" } {
	    lappend cfg "ifconfig \$bridgeName ptp $iface_id"
	} else {
	    lappend cfg "ifconfig \$bridgeName -ptp $iface_id"
	}

	if { [getBridgeIfcAutoptp $node_id $iface_id] == "1" } {
	    lappend cfg "ifconfig \$bridgeName autoptp $iface_id"
	} else {
	    lappend cfg "ifconfig \$bridgeName -autoptp $iface_id"
	}

	set priority [getBridgeIfcPriority $node_id $iface_id]
	lappend cfg "ifconfig \$bridgeName ifpriority $iface_id $priority"

	set pathcost [getBridgeIfcPathcost $node_id $iface_id]
	lappend cfg "ifconfig \$bridgeName ifpathcost $iface_id $pathcost"

	set maxaddr [getBridgeIfcMaxaddr $node_id $iface_id]
	lappend cfg "ifconfig \$bridgeName ifmaxaddr $iface_id $maxaddr"

	lappend cfg ""
    }

    return $cfg
}

#****f* stpswitch.tcl/stpswitch.ifacePrefix
# NAME
#   stpswitch.ifacePrefix -- interface name
# SYNOPSIS
#   stpswitch.ifacePrefix
# FUNCTION
#   Returns stpswitch interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifacePrefix { l r } {
    return [l3IfcName $l $r]
}

#****f* stpswitch.tcl/stpswitch.IPAddrRange
# NAME
#   stpswitch.IPAddrRange -- IP address range
# SYNOPSIS
#   stpswitch.IPAddrRange
# FUNCTION
#   Returns stpswitch IP address range
# RESULT
#   * range -- stpswitch IP address range
#****
proc $MODULE.IPAddrRange {} {
    return 20
}

#****f* stpswitch.tcl/stpswitch.netlayer
# NAME
#   stpswitch.netlayer
# SYNOPSIS
#   set layer [stpswitch.netlayer]
# FUNCTION
#   Returns the layer on which the stpswitch communicates
#   i.e. returns LINK.
# RESULT
#   * layer -- set to LINK
#****
proc $MODULE.netlayer {} {
    return LINK
}

#****f* stpswitch.tcl/stpswitch.virtlayer
# NAME
#   stpswitch.virtlayer
# SYNOPSIS
#   set layer [stpswitch.virtlayer]
# FUNCTION
#   Returns the layer on which the stpswitch is instantiated
#   i.e. returns VIRTUALIZED.
# RESULT
#   * layer -- set to VIRTUALIZED
#****
proc $MODULE.virtlayer {} {
    return VIRTUALIZED
}

#****f* stpswitch.tcl/stpswitch.bootcmd
# NAME
#   stpswitch.bootcmd
# SYNOPSIS
#   set appl [stpswitch.bootcmd $node_id]
# FUNCTION
#   Procedure bootcmd returns the application that reads and
#   employes the configuration generated in stpswitch.generateConfig.
#   In this case (procedure stpswitch.bootcmd) specific application
#   is /bin/sh
# INPUTS
#   * node_id - id of the node
# RESULT
#   * appl -- application that reads the configuration (/bin/sh)
#****
proc $MODULE.bootcmd { node_id } {
    return "/bin/sh"
}

#****f* stpswitch.tcl/stpswitch.shellcmds
# NAME
#   stpswitch.shellcmds
# SYNOPSIS
#   set shells [stpswitch.shellcmds]
# FUNCTION
#   Procedure shellcmds returns the shells that can be opened
#   as a default shell for the system.
# RESULT
#   * shells -- default shells for the stpswitch
#****
proc $MODULE.shellcmds {} {
    return "csh bash sh tcsh"
}

#****f* stpswitch.tcl/stpswitch.nghook
# NAME
#   stpswitch.nghook
# SYNOPSIS
#   stpswitch.nghook $eid $node_id $iface_id
# FUNCTION
#   Returns the id of the netgraph node and the name of the
#   netgraph hook which is used for connecting two netgraph
#   nodes. This procedure calls l3node.hook procedure and
#   passes the result of that procedure.
# INPUTS
#   * eid - experiment id
#   * node_id - node id
#   * iface_id - interface id
# RESULT
#   * nghook - the list containing netgraph node id and the
#     netgraph hook (ngNode ngHook).
#****
proc $MODULE.nghook { eid node_id iface_id } {
    return [l3node.nghook $eid $node_id $iface_id]
}

################################################################################
############################ INSTANTIATE PROCEDURES ############################
################################################################################

proc $MODULE.prepareSystem {} {
    catch { exec kldload if_bridge }
    catch { exec kldload bridgestp }
#   catch { exec jexec sysctl net.link.bridge.log_stp=1 }
    catch { exec jexec sysctl net.link.bridge.pfil_member=0 }
    catch { exec jexec sysctl net.link.bridge.pfil_bridge=0 }
    catch { exec jexec sysctl net.link.bridge.pfil_onlyip=0 }
}

#****f* stpswitch.tcl/stpswitch.nodeCreate
# NAME
#   stpswitch.nodeCreate
# SYNOPSIS
#   stpswitch.nodeCreate $eid $node_id
# FUNCTION
#   Procedure stpswitch.nodeCreate creates a new virtual node
#   for a given node in imunes.
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node
#****
proc $MODULE.nodeCreate { eid node_id } {
    l3node.nodeCreate $eid $node_id
}

proc $MODULE.nodeNamespaceSetup { eid node_id } {
    l3node.nodeNamespaceSetup $eid $node_id
}

proc $MODULE.nodeInitConfigure { eid node_id } {
    l3node.nodeInitConfigure $eid $node_id
}

proc $MODULE.nodePhysIfacesCreate { eid node_id ifaces } {
    l3node.nodePhysIfacesCreate $eid $node_id $ifaces
}

#****f* stpswitch.tcl/stpswitch.nodeConfigure
# NAME
#   stpswitch.nodeConfigure
# SYNOPSIS
#   stpswitch.nodeConfigure $eid $node_id
# FUNCTION
#   Starts a new stpswitch. The node can be started if it is instantiated.
#   Simulates the booting proces of a stpswitch, by calling l3node.nodeConfigure
#   procedure.
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node
#****
proc $MODULE.nodeConfigure { eid node_id } {
    l3node.nodeConfigure $eid $node_id
}

################################################################################
############################# TERMINATE PROCEDURES #############################
################################################################################

proc $MODULE.nodeIfacesDestroy { eid node_id ifaces } {
    l3node.nodeIfacesDestroy $eid $node_id $ifaces
}

#****f* stpswitch.tcl/stpswitch.nodeShutdown
# NAME
#   stpswitch.nodeShutdown
# SYNOPSIS
#   stpswitch.nodeShutdown $eid $node_id
# FUNCTION
#   Shutdowns an stpswitch node.
#   Simulates the shutdown proces of a node, kills all the services and
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node
#****
proc $MODULE.nodeShutdown { eid node_id } {
    l3node.nodeShutdown $eid $node_id
    catch { exec jexec $eid.$node_id ifconfig | grep bridge | cut -d : -f1 } br
    set bridges [split $br]
    foreach bridge $bridges {
	catch { exec jexec $eid.$node_id ifconfig $bridge destroy }
    }
}

#****f* stpswitch.tcl/stpswitch.nodeDestroy
# NAME
#   stpswitch.nodeDestroy
# SYNOPSIS
#   stpswitch.nodeDestroy $eid $node_id
# FUNCTION
#   Destroys an stpswitch node.
#   First, it destroys all remaining virtual ifaces (vlans, tuns, etc).
#   Then, it destroys the jail/container with its namespaces and FS.
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node
#****
proc $MODULE.nodeDestroy { eid node_id } {
    l3node.nodeDestroy $eid $node_id
}

################################################################################
################################ GUI PROCEDURES ################################
################################################################################

proc $MODULE.icon { size } {
    global ROOTDIR LIBDIR

    switch $size {
	normal {
	    return $ROOTDIR/$LIBDIR/icons/normal/stpswitch.gif
	}
	small {
	    return $ROOTDIR/$LIBDIR/icons/small/stpswitch.gif
	}
	toolbar {
	    return $ROOTDIR/$LIBDIR/icons/tiny/stpswitch.gif
	}
    }
}

proc $MODULE.toolbarIconDescr {} {
    return "Add new RSTP switch"
}

proc $MODULE.notebookDimensions { wi } {
    set h 340
    set w 507

    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Interfaces" } {
	set h 320
    }
    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Bridge" } {
	set h 370
	set w 513
    }

    return [list $h $w]
}

#****f* stpswitch.tcl/stpswitch.configGUI
# NAME
#   stpswitch.configGUI
# SYNOPSIS
#   stpswitch.configGUI $c $node_id
# FUNCTION
#   Defines the structure of the stpswitch configuration window
#   by calling procedures for creating and organising the
#   window, as well as procedures for adding certain modules
#   to that window.
# INPUTS
#   * c - tk canvas
#   * node_id - node id
#****
proc $MODULE.configGUI { c node_id } {
    global wi
    global guielements treecolumns
    global brguielements
    global brtreecolumns

    set guielements {}
    set brguielements {}

    configGUI_createConfigPopupWin $c
    wm title $wi "stpswitch configuration"
    configGUI_nodeName $wi $node_id "Node name:"

    set tabs [configGUI_addNotebook $wi $node_id { "Configuration" "Interfaces" \
    "Bridge" }]
    set configtab [lindex $tabs 0]
    set ifctab [lindex $tabs 1]
    set bridgeifctab [lindex $tabs 2]

    set treecolumns { "OperState State" "NatState Nat" "IPv4addrs IPv4 addrs" \
	"IPv6addrs IPv6 addrs" "MACaddr MAC addr" "MTU MTU" \
	"QLen Queue len" "QDisc Queue disc" "QDrop Queue drop" }
    configGUI_addTree $ifctab $node_id

    set brtreecolumns { "Snoop Snoop" "Stp STP" "Priority Priority" \
	"Discover Discover" "Learn Learn" "Sticky Sticky" "Private Private" \
	"Edge Edge" "Autoedge AutoEdge" "Ptp Ptp" "Autoptp AutoPtp" \
	"Maxaddr Max addr" "Pathcost Pathcost" }
    configGUI_addBridgeTree $bridgeifctab $node_id

    configGUI_bridgeConfig $configtab $node_id
    # TODO: are these needed?
    configGUI_staticRoutes $configtab $node_id
    configGUI_customConfig $configtab $node_id

    configGUI_buttonsACNode $wi $node_id
}

#****f* stpswitch.tcl/stpswitch.configInterfacesGUI
# NAME
#   stpswitch.configInterfacesGUI
# SYNOPSIS
#   stpswitch.configInterfacesGUI $wi $node_id $iface_id
# FUNCTION
#   Defines which modules for changing interfaces parameters
#   are contained in the stpswitch configuration window. It is done
#   by calling procedures for adding certain modules to the window.
# INPUTS
#   * wi - widget
#   * node_id - node id
#   * iface_id - interface id
#****
proc $MODULE.configInterfacesGUI { wi node_id iface_id } {
    global guielements

    configGUI_ifcEssentials $wi $node_id $iface_id
    configGUI_ifcQueueConfig $wi $node_id $iface_id
    configGUI_ifcMACAddress $wi $node_id $iface_id
    configGUI_ifcIPv4Address $wi $node_id $iface_id
    configGUI_ifcIPv6Address $wi $node_id $iface_id
}

proc $MODULE.configBridgeInterfacesGUI { wi node_id iface_id } {
    global guielements

    configGUI_ifcBridgeAttributes $wi $node_id $iface_id
}
