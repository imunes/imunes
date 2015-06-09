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

# $Id: static.tcl 128 2014-12-19 11:59:09Z denis $


#****h* imunes/static.tcl
# NAME
#  router.static.tcl -- defines specific procedures for router 
#  using static routing model
# FUNCTION
#  This module defines all the specific procedures for a router
#  which uses static routing model.
# NOTES
#  Procedures in this module start with the keyword router.static and
#  end with function specific part that is the same for all the nodes
#  that work on the same layer.
#****

set MODULE router.static

#****f* static.tcl/router.static.layer
# NAME
#   router.static.layer -- layer
# SYNOPSIS
#   set layer [router.static.layer]
# FUNCTION
#   Returns the layer on which the router using static routing model
#   operates, i.e. returns NETWORK. 
# RESULT
#   * layer -- set to NETWORK
#****
proc $MODULE.layer {} {
    return NETWORK
}

#****f* static.tcl/router.static.virtlayer
# NAME
#   router.static.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [router.static.virtlayer]
# FUNCTION
#   Returns the layer on which the router using static routing model is
#   instantiated, i.e. returns VIMAGE. 
# RESULT
#   * layer -- set to VIMAGE
#****
proc $MODULE.virtlayer {} {
    return VIMAGE
}

#****f* static.tcl/router.static.cfggen
# NAME
#   router.static.cfggen -- configuration generator
# SYNOPSIS
#   set config [router.static.cfggen $node]
# FUNCTION
#   Generates configuration. This configuration represents the default
#   configuration loaded on the booting time of the virtual nodes and it is
#   closly related to the procedure router.static.bootcmd.
#   Generated configuration comprises the ip addresses (both ipv4 and ipv6)
#   for each interface of a given node. Static routes are also included in
#   configuration.
# INPUTS
#   * node -- node id (type of the node is router
#     and routing model is set to static)
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

#****f* static.tcl/router.static.bootcmd
# NAME
#   router.static.bootcmd -- boot command
# SYNOPSIS
#   set appl [router.static.bootcmd $node]
# FUNCTION
#   Procedure bootcmd returns the defaut application that reads and employes
#   the configuration generated in router.static.cfggen. In this case
#   (procedure router.static.bootcmd) specific application is /bin/sh
# INPUTS
#   * node -- node id (type of the node is router and the
#     routing model is set to static)
# RESULT
#   * appl -- application that reads the configuration (/bin/sh) 
#****
proc $MODULE.bootcmd { node } {
    return "/bin/sh"
}

#****f* static.tcl/router.static.shellcmds
# NAME
#   router.static.shellcmds -- shell commands
# SYNOPSIS
#   set shells [router.static.shellcmds]
# FUNCTION
#   Procedure shellcmds returns the shells that can be opened
#   as a default shell for the system. 
# RESULT
#   * shells -- default shells for the router.static
#****
proc $MODULE.shellcmds {} {
    return "csh bash sh tcsh"
}

#****f* static.tcl/router.static.instantiate
# NAME
#   router.static.instantiate -- instantiate
# SYNOPSIS
#   router.static.instantiate $eid $node
# FUNCTION
#   Procedure instantiate creates a new virtual node 
#   for a given node in imunes. 
#   Procedure router.static.instantiate cretaes a new virtual
#   node with all the interfaces and CPU parameters as defined
#   in imunes.  It sets the net.inet.ip.forwarding and
#   net.inet6.ip6.forwarding kernel variables to 1.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is router and routing model is static)
#****
proc $MODULE.instantiate { eid node } {
    global inst_pipes last_inst_pipe

    l3node.instantiate $eid $node

    enableIPforwarding $eid $node
}

#****f* static.tcl/router.static.start
# NAME
#   router.static.start -- start
# SYNOPSIS
#   router.static.start $eid $node
# FUNCTION
#   Starts a new router.static. The node can be started if it is instantiated. 
#   Simulates the booting proces of a router.static, by calling l3node.start 
#   procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is router.static)
#****
proc $MODULE.start { eid node } {
    l3node.start $eid $node
}

#****f* static.tcl/router.static.shutdown
# NAME
#   router.static.shutdown -- shutdown
# SYNOPSIS
#   router.static.shutdown $eid $node
# FUNCTION
#   Shutdowns a router.static. Simulates the shutdown proces of a
#   router.static, by calling the l3node.shutdown procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is router.static)
#****
proc $MODULE.shutdown { eid node } {
    l3node.shutdown $eid $node
}

#****f* static.tcl/router.static.destroy
# NAME
#   router.static.destroy -- destroy
# SYNOPSIS
#   router.static.destroy $eid $node
# FUNCTION
#   Destroys a router.static. Destroys all the interfaces of the router.static 
#   and the vimage itself by calling l3node.destroy procedure. 
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is router.static)
#****
proc $MODULE.destroy { eid node } {
    l3node.destroy $eid $node
}

#****f* static.tcl/router.static.nghook
# NAME
#   router.static.nghook -- nghook
# SYNOPSIS
#   router.static.nghook $eid $node $ifc 
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
