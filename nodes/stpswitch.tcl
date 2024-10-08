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
    global nodeNamingBase

    setNodeName $node_id [getNewNodeNameType stpswitch $nodeNamingBase(stpswitch)]

    setBridgeProtocol $node_id "rstp"
    setBridgePriority $node_id "32768"
    setBridgeHoldCount $node_id "6"
    setBridgeMaxAge $node_id "20"
    setBridgeFwdDelay $node_id "15"
    setBridgeHelloTime $node_id "2"
    setBridgeMaxAddr $node_id "100"
    setBridgeTimeout $node_id "240"

    set logiface_id [newLogIface $node_id "lo"]
    setIfcIPv4addrs $node_id $logiface_id "127.0.0.1/8"
    setIfcIPv6addrs $node_id $logiface_id "::1/128"
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

proc $MODULE.generateConfigIfaces { node_id ifaces } {
    set cfg {}

    if { $ifaces == "*" } {
	set ifaces [ifcList $node_id]
    } else {
	# sort physical ifaces before logical ones (because of vlans)
	set ifaces [lsort -dictionary $ifaces]
    }

    set bridge_name "stp_br"
    foreach iface_id $ifaces {
	set cfg [concat $cfg [nodeCfggenIfc $node_id $iface_id]]

	lappend cfg ""

	if { [isIfcLogical $node_id $iface_id] } {
	    continue
	}

	set iface_name [getIfcName $node_id $iface_id]

	if { [getBridgeIfcSnoop $node_id $iface_id] == "1" } {
	    lappend cfg "ifconfig $bridge_name span $iface_name"
	    lappend cfg ""
	    continue
	}

	lappend cfg "ifconfig $bridge_name addm $iface_name up"

	if { [getBridgeIfcStp $node_id $iface_id] == "1" } {
	    lappend cfg "ifconfig $bridge_name stp $iface_name"
	} else {
	    lappend cfg "ifconfig $bridge_name -stp $iface_name"
	}

	if { [getBridgeIfcDiscover $node_id $iface_id] == "1" } {
	    lappend cfg "ifconfig $bridge_name discover $iface_name"
	} else {
	    lappend cfg "ifconfig $bridge_name -discover $iface_name"
	}

	if { [getBridgeIfcLearn $node_id $iface_id] == "1" } {
	    lappend cfg "ifconfig $bridge_name learn $iface_name"
	} else {
	    lappend cfg "ifconfig $bridge_name -learn $iface_name"
	}

	if { [getBridgeIfcSticky $node_id $iface_id] == "1" } {
	    lappend cfg "ifconfig $bridge_name sticky $iface_name"
	} else {
	    lappend cfg "ifconfig $bridge_name -sticky $iface_name"
	}

	if { [getBridgeIfcPrivate $node_id $iface_id] == "1" } {
	    lappend cfg "ifconfig $bridge_name private $iface_name"
	} else {
	    lappend cfg "ifconfig $bridge_name -private $iface_name"
	}

	if { [getBridgeIfcEdge $node_id $iface_id] == "1" } {
	    lappend cfg "ifconfig $bridge_name edge $iface_name"
	} else {
	    lappend cfg "ifconfig $bridge_name -edge $iface_name"
	}

	if { [getBridgeIfcAutoedge $node_id $iface_id] == "1" } {
	    lappend cfg "ifconfig $bridge_name autoedge $iface_name"
	} else {
	    lappend cfg "ifconfig $bridge_name -autoedge $iface_name"
	}

	if { [getBridgeIfcPtp $node_id $iface_id] == "1" } {
	    lappend cfg "ifconfig $bridge_name ptp $iface_name"
	} else {
	    lappend cfg "ifconfig $bridge_name -ptp $iface_name"
	}

	if { [getBridgeIfcAutoptp $node_id $iface_id] == "1" } {
	    lappend cfg "ifconfig $bridge_name autoptp $iface_name"
	} else {
	    lappend cfg "ifconfig $bridge_name -autoptp $iface_name"
	}

	set priority [getBridgeIfcPriority $node_id $iface_id]
	lappend cfg "ifconfig $bridge_name ifpriority $iface_name $priority"

	set pathcost [getBridgeIfcPathcost $node_id $iface_id]
	lappend cfg "ifconfig $bridge_name ifpathcost $iface_name $pathcost"

	set maxaddr [getBridgeIfcMaxaddr $node_id $iface_id]
	lappend cfg "ifconfig $bridge_name ifmaxaddr $iface_name $maxaddr"

	lappend cfg ""
    }

    return $cfg
}

proc $MODULE.generateUnconfigIfaces { node_id ifaces } {
    if { $ifaces == "*" } {
	set ifaces "[ifcList $node_id] [logIfcList $node_id]"
    } else {
	# sort physical ifaces before logical ones
	set ifaces [lsort -dictionary $ifaces]
    }

    set cfg {}

    set bridge_name "stp_br"
    foreach iface_id $ifaces {
	set iface_name [getIfcName $node_id $iface_id]
	lappend cfg "ifconfig $bridge_name deletem $iface_name"

	set cfg [concat $cfg [nodeUncfggenIfc $node_id $iface_id]]

	lappend cfg ""
    }

    return $cfg
}

#****f* stpswitch.tcl/stpswitch.cfggen
# NAME
#   stpswitch.cfggen
# SYNOPSIS
#   set config [stpswitch.cfggen $node_id]
# FUNCTION
#   Returns the generated configuration. This configuration represents
#   the configuration loaded on the booting time of the virtual nodes
#   and it is closly related to the procedure stpswitch.bootcmd
#   Foreach interface in the interface list of the node ip address is
#   configured and each static route from the simulator is added.
# INPUTS
#   * node_id - id of the node
# RESULT
#   * congif -- generated configuration
#****
proc $MODULE.generateConfig { node_id } {
    set cfg {}

    set bridge_name "stp_br"

    set bridgeProtocol [getBridgeProtocol $node_id]
    if { $bridgeProtocol != "" } {
	lappend cfg "ifconfig $bridge_name proto $bridgeProtocol"
    }

    set bridgePriority [getBridgePriority $node_id]
    if { $bridgePriority != "" } {
	lappend cfg "ifconfig $bridge_name priority $bridgePriority"
    }

    set bridgeMaxAge [getBridgeMaxAge $node_id]
    if { $bridgeMaxAge != "" } {
	lappend cfg "ifconfig $bridge_name maxage $bridgeMaxAge"
    }

    set bridgeFwdDelay [getBridgeFwdDelay $node_id]
    if { $bridgeFwdDelay != "" } {
	lappend cfg "ifconfig $bridge_name fwddelay $bridgeFwdDelay"
    }

    set bridgeHoldCnt [getBridgeHoldCount $node_id]
    if { $bridgeHoldCnt != "" } {
	lappend cfg "ifconfig $bridge_name holdcnt $bridgeHoldCnt"
    }

    set bridgeHelloTime [getBridgeHelloTime $node_id]
    if { $bridgeHelloTime != "" && $bridgeProtocol == "stp" } {
	lappend cfg "ifconfig $bridge_name hellotime $bridgeHelloTime"
    }

    set bridgeMaxAddr [getBridgeMaxAddr $node_id]
    if { $bridgeMaxAddr != "" } {
	lappend cfg "ifconfig $bridge_name maxaddr $bridgeMaxAddr"
    }

    set bridgeTimeout [getBridgeTimeout $node_id]
    if { $bridgeTimeout != "" } {
	lappend cfg "ifconfig $bridge_name timeout $bridgeTimeout"
    }

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

proc $MODULE.ifcName {l r} {
    return [l3IfcName $l $r]
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
proc $MODULE.ifacePrefix {} {
    return "eth"
}

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
#   employes the configuration generated in stpswitch.cfggen.
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

proc $MODULE.shellcmds { } {
    return "csh bash sh tcsh"
}

proc $MODULE.nghook { eid node_id iface_id } {
    return [list $node_id-[getIfcName $node_id $iface_id] ether]
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
#   Procedure instantiate creates a new virtaul node
#   for a given node in imunes.
#   Procedure stpswitch.nodeCreate creates a new virtual node
#   with all the interfaces and CPU parameters as defined
#   in imunes.
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node
#****
proc $MODULE.nodeCreate { eid node_id } {
    prepareFilesystemForNode $node_id
    createNodeContainer $node_id

    set bridge_name "stp_br"
    pipesExec "jexec $eid.$node_id ifconfig bridge create name $bridge_name" "hold"
}

proc $MODULE.nodeSetupNamespace { eid node_id } {
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

proc $MODULE.nodeIfacesConfigure { eid node_id ifaces } {
    startNodeIfaces $node_id $ifaces
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
    runConfOnNode $node_id
}

################################################################################
############################# TERMINATE PROCEDURES #############################
################################################################################

proc $MODULE.nodeIfacesUnconfigure { eid node_id ifaces } {
    unconfigNodeIfaces $eid $node_id $ifaces
}

proc $MODULE.nodeIfacesDestroy { eid node_id ifaces } {
    destroyNodeIfaces $eid $node_id $ifaces
}

proc $MODULE.nodeUnconfigure { eid node_id } {
    unconfigNode $eid $node_id
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
    killExtProcess "wireshark.*[getNodeName $node_id].*\\($eid\\)"
    killAllNodeProcesses $eid $node_id
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
    set bridge_name "stp_br"
    pipesExec "jexec $eid.$node_id ifconfig $bridge_name destroy" "hold"

    destroyNodeVirtIfcs $eid $node_id
    removeNodeContainer $eid $node_id
    destroyNamespace $eid-$node_id
    removeNodeFS $eid $node_id
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
