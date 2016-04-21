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

#****h* imunes/packgen.tcl
# NAME
#  packgen.tcl -- defines packgen.specific procedures
# FUNCTION
#  This module is used to define all the packgen.specific procedures.
# NOTES
#  Procedures in this module start with the keyword packgen and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE packgen 

registerModule $MODULE

proc $MODULE.prepareSystem {} {
    catch {exec kldload ng_source}
}

proc $MODULE.confNewIfc { node ifc } {
}

proc $MODULE.confNewNode { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node
    global nodeNamingBase
    
    set nconfig [list \
	"hostname [getNewNodeNameType packgen $nodeNamingBase(packgen)]" \
	! ]
    lappend $node "network-config [list $nconfig]"
}

proc $MODULE.icon {size} {
    global ROOTDIR LIBDIR
    switch $size {
      normal {
	return $ROOTDIR/$LIBDIR/icons/normal/packgen.gif
      }
      small {
	return $ROOTDIR/$LIBDIR/icons/small/packgen.gif
      }
      toolbar {
	return $ROOTDIR/$LIBDIR/icons/tiny/packgen.gif
      }
    }
}

proc $MODULE.toolbarIconDescr {} {
    return "Add new Packet generator"
}

proc $MODULE.notebookDimensions { wi } { 
    set h 430 
    set w 652
		    
    return [list $h $w] 
}

proc $MODULE.ifcName {l r} {
    return e
}

#****f* packgen.tcl/packgen.layer
# NAME
#   packgen.layer  
# SYNOPSIS
#   set layer [packgen.layer]
# FUNCTION
#   Returns the layer on which the packgen.communicates
#   i.e. returns LINK. 
# RESULT
#   * layer -- set to LINK 
#****

proc $MODULE.layer {} {
    return LINK
}

#****f* packgen.tcl/packgen.virtlayer
# NAME
#   packgen.virtlayer  
# SYNOPSIS
#   set layer [packgen.virtlayer]
# FUNCTION
#   Returns the layer on which the packgen is instantiated
#   i.e. returns NETGRAPH. 
# RESULT
#   * layer -- set to NETGRAPH
#****

proc $MODULE.virtlayer {} {
    return NETGRAPH
}

#****f* packgen.tcl/packgen.instantiate
# NAME
#   packgen.instantiate
# SYNOPSIS
#   packgen.instantiate $eid $node_id
# FUNCTION
#   Procedure instantiate creates a new virtaul node
#   for a given node in imunes. 
#   Procedure packgen.instantiate cretaes a new virtual node
#   with all the interfaces and CPU parameters as defined
#   in imunes. 
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node (type of the node is packgen.
#****

proc $MODULE.instantiate { eid node } {
    upvar 0 ::cf::[set ::curcfg]::ngnodemap ngnodemap

    set t [exec printf "mkpeer source x input\nmsg .x setpersistent\nshow ." | jexec $eid ngctl -f -]
    set tlen [string length $t]
    set id [string range $t [expr $tlen - 31] [expr $tlen - 24]]
    catch {exec jexec $eid ngctl name \[$id\]: $node}
    set ngnodemap($eid\.$node) $node
}


#****f* packgen.tcl/packgen.start
# NAME
#   packgen.start
# SYNOPSIS
#   packgen.start $eid $node_id
# FUNCTION
#   Starts a new packgen. The node can be started if it is instantiated. 
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node (type of the node is packgen)
#****
proc $MODULE.start { eid node } {
    upvar 0 ::cf::[set ::curcfg]::ngnodemap ngnodemap

    set ngid $ngnodemap($eid\.$node)

    # Bypass ng_pipe module for rj45 peers
    set peer [peerByIfc $node [lindex [ifcList $node] 0]]
    if { $peer != "" && [nodeType $peer] == "rj45"} {
	set peerngid $ngnodemap([getNodeName $peer])
	exec jexec $eid ngctl rmhook $ngid: output
	exec jexec $eid ngctl rmhook $peerngid: lower
	exec jexec $eid ngctl connect $ngid: $peerngid: output lower
    }

    foreach packet [packgenPackets $node] {
	set pdata [getPackgenPacketData $node [lindex $packet 0]]
	
	set fd [open "| jexec $eid nghook $ngid: input" w]
	set bin [binary format H* $pdata]
	puts -nonewline $fd $bin
	catch {close $fd}
    }

    set pps [getPackgenPacketRate $node]

    exec jexec $eid ngctl msg $ngid: setpps $pps
    catch {exec jexec $eid ngctl msg $ngid: start [expr 2**63]}
}

#****f* packgen.tcl/packgen.shutdown
# NAME
#   packgen.shutdown
# SYNOPSIS
#   packgen.shutdown $eid $node_id
# FUNCTION
#   Shutdowns a packgen. Simulates the shutdown proces of a packgen. 
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node (type of the node is packgen) 
#****
proc $MODULE.shutdown { eid node } {
    upvar 0 ::cf::[set ::curcfg]::ngnodemap ngnodemap

    set ngid $ngnodemap($eid\.$node)
    exec jexec $eid ngctl msg $ngid: clrdata
    exec jexec $eid ngctl msg $ngid: stop
}


#****f* packgen.tcl/packgen.destroy
# NAME
#   packgen.destroy
# SYNOPSIS
#   packgen.destroy $eid $node_id
# FUNCTION
#   Destroys a packgen. Destroys all the interfaces of the packgen.
# INPUTS
#   * eid - experiment id
#   * node_id - id of the node (type of the node is packgen) 
#****
proc $MODULE.destroy { eid node } {
    catch { nexec jexec $eid ngctl msg $node: shutdown }
}


#****f* packgen.tcl/packgen.nghook
# NAME
#   packgen.nghook
# SYNOPSIS
#   packgen.nghook $eid $node_id $ifc 
# FUNCTION
#   Returns the id of the netgraph node and the name of the 
#   netgraph hook which is used for connecting two netgraph 
#   nodes.
# INPUTS
#   * eid - experiment id
#   * node_id - node id
#   * ifc - interface name
# RESULT
#   * nghook - the list containing netgraph node id and the 
#     netgraph hook (ngNode ngHook).
#****

proc $MODULE.nghook { eid node ifc } {
    return [list $eid\.$node output]
}


#****f* packgen.tcl/packgen.configGUI
# NAME
#   packgen.configGUI
# SYNOPSIS
#   packgen.configGUI $c $node
# FUNCTION
#   Defines the structure of the packgen configuration window
#   by calling procedures for creating and organising the 
#   window, as well as procedures for adding certain modules
#   to that window.
# INPUTS
#   * c - tk canvas
#   * node - node id
#****
proc $MODULE.configGUI { c node } {
    global wi
    global packgenguielements packgentreecolumns curnode
    set curnode $node
    set packgenguielements {}

    configGUI_createConfigPopupWin $c
    wm title $wi "packet generator configuration"
    configGUI_nodeName $wi $node "Node name:"

    set tabs [configGUI_addNotebookPackgen $wi $node]

    configGUI_packetRate [lindex $tabs 0] $node

    set packgentreecolumns {"Data Data"}
    foreach tab $tabs {
	configGUI_addTreePackgen $tab $node
    }
    
    configGUI_buttonsACPackgenNode $wi $node
}

#****f* packgen.tcl/packgen.configInterfacesGUI
# NAME
#   packgen.configInterfacesGUI
# SYNOPSIS
#   packgen.configInterfacesGUI $wi $node $ifc
# FUNCTION
#   Defines which modules for changing interfaces parameters
#   are contained in the packgen.configuration window. It is done
#   by calling procedures for adding certain modules to the window.
# INPUTS
#   * wi - widget
#   * node - node id
#   * ifc - interface id
#****
proc $MODULE.configPacketsGUI { wi node pac } {
    global packgenguielements

    configGUI_packetConfig $wi $node $pac
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
