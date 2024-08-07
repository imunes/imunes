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

# $Id: rj45.tcl 130 2015-02-24 09:52:19Z valter $


#****h* imunes/rj45.tcl
# NAME
#  rj45.tcl -- defines rj45 specific procedures
# FUNCTION
#  This module is used to define all the rj45 specific procedures.
# NOTES
#  Procedures in this module start with the keyword rj45 and
#  end with function specific part that is the same for all the
#  node types that work on the same layer.
#****

set MODULE rj45

registerModule $MODULE

#****f* rj45.tcl/rj45.prepareSystem
# NAME
#   rj45.prepareSystem -- prepare system
# SYNOPSIS
#   rj45.prepareSystem
# FUNCTION
#   Loads ng_ether into the kernel.
#****
proc $MODULE.prepareSystem {} {
    catch { exec kldload ng_ether }
}

#****f* rj45.tcl/rj45.confNewNode
# NAME
#   rj45.confNewNode -- configure new node
# SYNOPSIS
#   rj45.confNewNode $node_id
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node_id -- node id
#****
proc $MODULE.confNewNode { node_id } {
    setNodeName $node_id "UNASSIGNED"
}

#****f* rj45.tcl/rj45.ifcName
# NAME
#   rj45.ifcName -- interface name
# SYNOPSIS
#   rj45.ifcName
# FUNCTION
#   Returns rj45 interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifcName {l r} {
    return ""
}

#****f* rj45.tcl/rj45.netlayer
# NAME
#   rj45.netlayer -- layer
# SYNOPSIS
#   set layer [rj45.netlayer]
# FUNCTION
#   Returns the layer on which the rj45 operates, i.e. returns LINK.
# RESULT
#   * layer -- set to LINK
#****
proc $MODULE.netlayer {} {
    return LINK
}

#****f* rj45.tcl/rj45.virtlayer
# NAME
#   rj45.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [rj45.virtlayer]
# FUNCTION
#   Returns the layer on which the rj45 node is instantiated,
#   i.e. returns NETGRAPH.
# RESULT
#   * layer -- set to NETGRAPH
#****
proc $MODULE.virtlayer {} {
    return NETGRAPH
}

#****f* rj45.tcl/rj45.instantiate
# NAME
#   rj45.instantiate -- instantiate
# SYNOPSIS
#   rj45.instantiate $eid $node_id
# FUNCTION
#   Procedure rj45.instantiate puts real interface into promiscuous mode.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id (type of the node is rj45)
#****
proc $MODULE.instantiate { eid node_id } {
    captureExtIfc $eid $node_id
}

#****f* rj45.tcl/rj45.destroy
# NAME
#   rj45.destroy -- destroy
# SYNOPSIS
#   rj45.destroy $eid $node_id
# FUNCTION
#   Destroys an rj45 emulation interface.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id (type of the node is rj45)
#****
proc $MODULE.destroy { eid node_id } {
    releaseExtIfc $eid $node_id
}

#****f* rj45.tcl/rj45.nghook
# NAME
#   rj45.nghook
# SYNOPSIS
#   rj45.nghook $eid $node_id $ifc
# FUNCTION
#   Returns the id of the netgraph node and the netgraph hook name. In this
#   case netgraph node name correspondes to the name of the physical interface.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifc -- interface name
# RESULT
#   * nghook -- the list containing netgraph node name and
#     the netraph hook name (in this case: lower).
#****
proc $MODULE.nghook { eid node_id ifc } {
    set ifname [getNodeName $node_id]
    if { [getEtherVlanEnabled $node_id] } {
	set vlan [getEtherVlanTag $node_id]
	set ifname ${ifname}_$vlan
    }

    return [list $ifname lower]
}

#****f* rj45.tcl/rj45.maxLinks
# NAME
#   rj45.maxLinks -- maximum number of links
# SYNOPSIS
#   rj45.maxLinks
# FUNCTION
#   Returns rj45 maximum number of links.
# RESULT
#   * maximum number of links.
#****
proc $MODULE.maxLinks {} {
    return 1
}
