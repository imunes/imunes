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

#****h* imunes/filter.tcl
# NAME
#  filter.tcl -- defines filter.specific procedures
# FUNCTION
#  This module is used to define all the filter.specific procedures.
# NOTES
#  Procedures in this module start with the keyword filter.and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE filter
registerModule $MODULE

################################################################################
########################### CONFIGURATION PROCEDURES ###########################
################################################################################

proc $MODULE.confNewNode { node_id } {
    global nodeNamingBase

    setNodeName $node_id [getNewNodeNameType filter $nodeNamingBase(filter)]
}

proc $MODULE.confNewIfc { node_id iface } {
}

proc $MODULE.generateConfigIfaces { node_id ifaces } {
}

proc $MODULE.generateUnconfigIfaces { node_id ifaces } {
}

proc $MODULE.generateConfig { node_id } {
}

proc $MODULE.generateUnconfig { node_id } {
}

proc $MODULE.ifcName {l r} {
    return e
}

#****f* filter.tcl/filter.ifacePrefix
# NAME
#   filter.ifacePrefix -- interface name
# SYNOPSIS
#   filter.ifacePrefix
# FUNCTION
#   Returns filter interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifacePrefix {} {
    return "e"
}

proc $MODULE.IPAddrRange {} {
}

#****f* filter.tcl/filter.netlayer
# NAME
#   filter.netlayer
# SYNOPSIS
#   set layer [filter.netlayer]
# FUNCTION
#   Returns the layer on which the filter.communicates
#   i.e. returns LINK.
# RESULT
#   * layer -- set to LINK
#****
proc $MODULE.netlayer {} {
    return LINK
}

#****f* filter.tcl/filter.virtlayer
# NAME
#   filter.virtlayer
# SYNOPSIS
#   set layer [filter.virtlayer]
# FUNCTION
#   Returns the layer on which the filter is instantiated
#   i.e. returns NATIVE.
# RESULT
#   * layer -- set to NATIVE
#****
proc $MODULE.virtlayer {} {
    return NATIVE
}

proc $MODULE.bootcmd { node_id } {
}

proc $MODULE.shellcmds {} {
}

#****f* filter.tcl/filter.nghook
# NAME
#   filter.nghook
# SYNOPSIS
#   filter.nghook $eid $node_id $iface
# FUNCTION
#   Returns the id of the netgraph node and the name of the
#   netgraph hook which is used for connecting two netgraph
#   nodes. This procedure calls l3node.hook procedure and
#   passes the result of that procedure.
# INPUTS
#   * eid - experiment id
#   * node_id - node id
#   * iface - interface name
# RESULT
#   * nghook - the list containing netgraph node id and the
#     netgraph hook (ngNode ngHook).
#****
proc $MODULE.nghook { eid node_id iface } {
    return [list $node_id [getIfcName $node_id $iface]]
}

################################################################################
############################ INSTANTIATE PROCEDURES ############################
################################################################################

proc $MODULE.prepareSystem {} {
    catch { exec kldload ng_patmat }
}

#****f* filter.tcl/filter.nodeCreate
# NAME
#   filter.nodeCreate
# SYNOPSIS
#   filter.nodeCreate $eid $node_id
# FUNCTION
#   Procedure instantiate creates a new virtaul node
#   for a given node in imunes.
#   Procedure filter.nodeCreate creates a new virtual node
#   with all the interfaces and CPU parameters as defined
#   in imunes.
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node
#****
proc $MODULE.nodeCreate { eid node_id } {
    pipesExec "printf \"
    mkpeer . patmat tmp tmp \n
    name .:tmp $node_id
    \" | jexec $eid ngctl -f -" "hold"
}

proc $MODULE.nodeSetupNamespace { eid node_id } {
}

proc $MODULE.nodeInitConfigure { eid node_id } {
}

proc $MODULE.nodePhysIfacesCreate { eid node_id ifaces } {
}

proc $MODULE.nodeLogIfacesCreate { eid node_id ifaces } {
}

#****f* filter.tcl/filter.nodeIfacesConfigure
# NAME
#   filter.nodeIfacesConfigure -- configure filter node interfaces
# SYNOPSIS
#   filter.nodeIfacesConfigure $eid $node_id $ifaces
# FUNCTION
#   Configure interfaces on a filter. Set MAC, MTU, queue parameters, assign the IP
#   addresses to the interfaces, etc. This procedure can be called if the node
#   is instantiated.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifaces -- list of interface ids
#****
proc $MODULE.nodeIfacesConfigure { eid node_id ifaces } {
}

#****f* filter.tcl/filter.nodeConfigure
# NAME
#   filter.nodeConfigure
# SYNOPSIS
#   filter.nodeConfigure $eid $node_id
# FUNCTION
#   Starts a new filter. The node can be started if it is instantiated.
#   Simulates the booting proces of a filter. by calling l3node.nodeConfigure
#   procedure.
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node
#****
proc $MODULE.nodeConfigure { eid node_id } {
    foreach iface_id [ifcList $node_id] {
	set ngcfgreq "shc [getIfcName $node_id $iface_id]"
	foreach rule_num [lsort -dictionary [ifcFilterRuleList $node_id $iface_id]] {
	    set rule [getFilterIfcRuleAsString $node_id $iface_id $rule_num]
	    set ngcfgreq "${ngcfgreq} ${rule}"
	}

	pipesExec "jexec $eid ngctl msg $node_id: $ngcfgreq" "hold"
    }
}

################################################################################
############################# TERMINATE PROCEDURES #############################
################################################################################

proc $MODULE.nodeIfacesUnconfigure { eid node_id ifaces } {
}

proc $MODULE.nodeIfacesDestroy { eid node_id ifaces } {
    destroyNodeIfaces $eid $node_id $ifaces
}

proc $MODULE.nodeUnconfigure { eid node_id } {
}

#****f* filter.tcl/filter.nodeShutdown
# NAME
#   filter.nodeShutdown
# SYNOPSIS
#   filter.nodeShutdown $eid $node_id
# FUNCTION
#   Shutdowns a filter node.
#   Simulates the shutdown proces of a node, kills all the services and
#   processes.
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node
#****
proc $MODULE.nodeShutdown { eid node_id } {
    foreach iface [ifcList $node_id] {
	set ngcfgreq "shc $iface"

	pipesExec "jexec $eid ngctl msg $node_id: $ngcfgreq" "hold"
    }
}

#****f* filter.tcl/filter.nodeDestroy
# NAME
#   filter.nodeDestroy
# SYNOPSIS
#   filter.nodeDestroy $eid $node_id
# FUNCTION
#   Destroys a filter node.
#   It issues the shutdown command to ngctl.
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node
#****
proc $MODULE.nodeDestroy { eid node_id } {
    pipesExec "jexec $eid ngctl msg $node_id: shutdown" "hold"
}
