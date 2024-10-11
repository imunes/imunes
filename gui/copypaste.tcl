#
# Copyright 2008-2013 University of Zagreb.
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

# $Id: copypaste.tcl 124 2014-12-15 14:02:25Z denis $

#****f* copypaste.tcl/cutSelection
# NAME
#   cutSelection -- cut selection
# SYNOPSIS
#   cutSelection
# FUNCTION
#   Cuts selected nodes.
#****
proc cutSelection {} {
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    global cutNodes

    if { $oper_mode == "exec" } {
	return
    }

    set cutNodes 1
    copySelection
    deleteSelection
}

#****f* copypaste.tcl/copySelection
# NAME
#   copySelection -- copy selection
# SYNOPSIS
#   copySelection
# FUNCTION
#   Copies selected nodes.
#****
proc copySelection {} {
    global curcfg
	
    if {[string equal [selectedNodes] {}]} {
      return
    }

    catch { namespace delete ::cf::clipboard }
    namespace eval ::cf::clipboard {}
    upvar 0 ::cf::clipboard::node_list node_list
    upvar 0 ::cf::clipboard::link_list link_list
    upvar 0 ::cf::clipboard::annotation_list annotation_list

    set annotation_list {}
    
    foreach annotation [selectedNodes] {
	if { $annotation ni [selectedRealNodes] } {
	    lappend annotation_list $annotation
	    set ::cf::clipboard::$annotation [set ::cf::[set ::curcfg]::$annotation]
	}
    }

    # Copy selected nodes and interconnecting links to the clipboard
    set node_list [selectedRealNodes]
    set link_list {}
    foreach node $node_list {
	set ::cf::clipboard::$node [set ::cf::[set ::curcfg]::$node]
	foreach ifc [ifcList $node] {
	    set peer [peerByIfc $node $ifc]
	    if { [lsearch $node_list $peer] < 0 } {
		continue
	    }
	    set link [linkByPeers $node $peer]
	    if { [lsearch $link_list $link] >= 0 } {
		continue
	    }
	    lappend link_list $link
	    set ::cf::clipboard::$link [set ::cf::[set ::curcfg]::$link]
	}
    }

    # Prune stale interface data from copied nodes
    set savedcurcfg $curcfg
    set curcfg clipboard
    foreach node $node_list {
        upvar 0 ::cf::[set ::curcfg]::$node $node

	foreach ifc [ifcList $node] {
	    set peer [peerByIfc $node $ifc]
	    if { [lsearch $node_list $peer] < 0 } {
		netconfClearSection $node "interface $ifc"
		set i [lsearch [set $node] "interface-peer {$ifc $peer}"]
		set $node [lreplace [set $node] $i $i]
	    }
	}
    }
    set curcfg $savedcurcfg
}

#****f* copypaste.tcl/paste
# NAME
#   paste -- paste
# SYNOPSIS
#   paste
# FUNCTION
#   Pastes nodes from clipboard.
#****
proc paste {} {
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    upvar 0 ::cf::[set ::curcfg]::link_list link_list
    upvar 0 ::cf::[set ::curcfg]::annotation_list annotation_list
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    upvar 0 ::cf::[set ::curcfg]::MACUsedList MACUsedList
    global sizex sizey
    global changed copypaste_list cutNodes copypaste_nodes
    global nodeNamingBase

    if { $oper_mode == "exec" } {
	return
    }

    set copypaste_list ""

    # Paste annotations from the clipboard and rename them on the fly
    foreach annotation_orig [set ::cf::clipboard::annotation_list] {
	set annotation_copy [newObjectId annotation]
	set annotation_map($annotation_orig) $annotation_copy
	upvar 0 ::cf::[set ::curcfg]::$annotation_copy $annotation_copy
	set $annotation_copy [set ::cf::clipboard::$annotation_orig]
	lappend annotation_list $annotation_copy
	setNodeCanvas $annotation_copy $curcanvas
	drawAnnotation $annotation_copy
    }
    raiseAll .panwin.f1.c

    # Nothing to do if clipboard is empty
    if {[set ::cf::clipboard::node_list] == {}} {
	return
    }

    # Paste nodes from the clipboard and rename them on the fly
    foreach node_orig [set ::cf::clipboard::node_list] {
	set node_copy [newObjectId node]
	set node_map($node_orig) $node_copy
	upvar 0 ::cf::[set ::curcfg]::$node_copy $node_copy
	set $node_copy [set ::cf::clipboard::$node_orig]
	lappend node_list $node_copy
	lappend copypaste_list $node_copy
	set node_type [nodeType $node_orig]
	if { $node_type in [array names nodeNamingBase] } {
	    setNodeName $node_copy [getNewNodeNameType $node_type $nodeNamingBase($node_type)]
	} else {
	    setNodeName $node_copy $node_copy
	}
	setNodeCanvas $node_copy $curcanvas
    }

    #
    # Remap interface peerings to match new node names and
    # adjust node positions so that all fit in the target canvas
    #
    set delta 128
    set curx [expr $delta / 2]
    set cury [expr $delta / 2]
    foreach node_orig [set ::cf::clipboard::node_list] {
	set node_copy $node_map($node_orig)
	foreach ifc [ifcList $node_copy] {
	    set old_peer [peerByIfc $node_copy $ifc]
	    set i [lsearch [set $node_copy] "interface-peer {$ifc $old_peer}"]
	    set $node_copy [lreplace [set $node_copy] $i $i \
		"interface-peer {$ifc $node_map($old_peer)}"]
	    if { $cutNodes == 0 } {
		autoMACaddr $node_copy $ifc
	    }
	}

	set nodecoords [getNodeCoords $node_copy]
	if { [lindex $nodecoords 0] >= $sizex ||
	    [lindex $nodecoords 1] >= $sizey } {
	    setNodeCoords $node_copy "$curx $cury"
	    setNodeLabelCoords $node_copy "$curx [expr $cury + $delta / 4]"
	    incr curx $delta
	    if { $curx > $sizex } {
		incr cury $delta
		set curx [expr $delta / 2]
	    }
	}
    }

    # Paste links from the clipboard and rename them on the fly
    foreach link_orig [set ::cf::clipboard::link_list] {
	set link_copy [newObjectId link]
	upvar 0 ::cf::[set ::curcfg]::$link_copy $link_copy
	set $link_copy [set ::cf::clipboard::$link_orig]
	lappend link_list $link_copy
	set old_peers [linkPeers $link_copy]
	set new_peers \
	    "$node_map([lindex $old_peers 0]) $node_map([lindex $old_peers 1])"
	set i [lsearch [set $link_copy] "nodes {$old_peers}"]
	set $link_copy [lreplace [set $link_copy] $i $i "nodes {$new_peers}"]
    }

    updateCustomIconReferences

    if { $cutNodes == 0 } {
	set copypaste_nodes 1
	changeAddressRange
	set copypaste_nodes 1
	changeAddressRange6
    }
    set cutNodes 0

    set changed 1
    updateUndoLog
    redrawAll
    setActiveTool select
    selectNodes $copypaste_list
}
