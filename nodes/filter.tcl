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

proc $MODULE.prepareSystem {} {
    catch { exec kldload ng_patmat }
}

proc $MODULE.confNewIfc { node_id iface_id } {
}

proc $MODULE.confNewNode { node_id } {
    global nodeNamingBase

    setNodeName $node_id [getNewNodeNameType filter $nodeNamingBase(filter)]
}

proc $MODULE.ifacePrefix { l r } {
    return e
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

#****f* filter.tcl/filter.nodeCreate
# NAME
#   filter.nodeCreate
# SYNOPSIS
#   filter.nodeCreate $eid $node_id
# FUNCTION
#   Procedure filter.nodeCreate cretaes a new virtual node
#   with all the interfaces and CPU parameters as defined
#   in imunes.
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node (type of the node is filter).
#****
proc $MODULE.nodeCreate { eid node_id } {
    pipesExec "printf \"
    mkpeer . patmat tmp tmp \n
    name .:tmp $node_id
    \" | jexec $eid ngctl -f -" "hold"
}

#****f* filter.tcl/filter.start
# NAME
#   filter.start
# SYNOPSIS
#   filter.start $eid $node_id
# FUNCTION
#   Starts a new filter. The node can be started if it is instantiated.
#   Simulates the booting proces of a filter. by calling l3node.start
#   procedure.
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node (type of the node is filter.
#****
proc $MODULE.start { eid node_id } {
    foreach iface_id [ifcList $node_id] {
	set ngcfgreq "shc $iface_id"
	foreach rule_num [lsort -dictionary [ifcFilterRuleList $node_id $iface_id]] {
	    set rule [getFilterIfcRuleAsString $node_id $iface_id $rule_num]
	    set ngcfgreq "${ngcfgreq} ${rule}"
	}

	pipesExec "jexec $eid ngctl msg $node_id: $ngcfgreq" "hold"
    }
}

#****f* filter.tcl/filter.shutdown
# NAME
#   filter.shutdown
# SYNOPSIS
#   filter.shutdown $eid $node_id
# FUNCTION
#   Shutdowns a filter. Simulates the shutdown proces of a filter.
#   by calling the l3node.shutdown procedure.
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node (type of the node is filter.
#****
proc $MODULE.shutdown { eid node_id } {
    foreach iface_id [ifcList $node_id] {
	set ngcfgreq "shc $iface_id"

	pipesExec "jexec $eid ngctl msg $node_id: $ngcfgreq" "hold"
    }
}

proc $MODULE.destroyIfcs { eid node_id ifaces } {
    l2node.destroyIfcs $eid $node_id $ifaces
}

#****f* filter.tcl/filter.destroy
# NAME
#   filter.destroy
# SYNOPSIS
#   filter.destroy $eid $node_id
# FUNCTION
#   Destroys a filter. Destroys all the interfaces of the filter.
#   and the vimage itself by calling l3node.destroy procedure.
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node (type of the node is filter.
#****
proc $MODULE.destroy { eid node_id } {
    pipesExec "jexec $eid ngctl msg $node_id: shutdown" "hold"
}

#****f* filter.tcl/filter.nghook
# NAME
#   filter.nghook
# SYNOPSIS
#   filter.nghook $eid $node_id $iface_id
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
    return [list $node_id $iface_id]
}
