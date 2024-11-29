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

    set selected_nodes [selectedRealNodes]
    set selected_annotations [selectedAnnotations]
    if { $selected_nodes == {} && $selected_annotations == {} } {
	return
    }

    catch { namespace delete ::cf::clipboard }
    namespace eval ::cf::clipboard {}
    upvar 0 ::cf::clipboard::node_list node_list
    upvar 0 ::cf::clipboard::link_list link_list
    upvar 0 ::cf::clipboard::annotation_list annotation_list

    set annotation_list $selected_annotations
    foreach annotation $selected_annotations {
	set ::cf::clipboard::$annotation [set ::cf::[set ::curcfg]::$annotation]
    }

    # Copy selected nodes and interconnecting links to the clipboard
    set node_list $selected_nodes
    set link_list {}
    foreach node_id $node_list {
	set ::cf::clipboard::$node_id [set ::cf::[set ::curcfg]::$node_id]
	foreach iface_id [ifcList $node_id] {
	    set peer_id [getIfcPeer $node_id $iface_id]
	    if { [lsearch $node_list $peer_id] < 0 } {
		continue
	    }

	    foreach link_id [linksByPeers $node_id $peer_id] {
		if { [lsearch $link_list $link_id] >= 0 } {
		    continue
		}
		lappend link_list $link_id
		set ::cf::clipboard::$link_id [set ::cf::[set ::curcfg]::$link_id]
	    }
	}
    }

    # Prune stale interface data from copied nodes
    set savedcurcfg $curcfg
    set curcfg clipboard
    foreach node_id $node_list {
        upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

	foreach iface_id [ifcList $node_id] {
	    set peer_id [getIfcPeer $node_id $iface_id]
	    if { [lsearch $node_list $peer_id] < 0 } {
		netconfClearSection $node_id "interface $iface_id"
		set i [lsearch [set $node_id] "interface-peer {$iface_id $peer_id}"]
		set $node_id [lreplace [set $node_id] $i $i]
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
    set new_annotations ""

    # Paste annotations from the clipboard and rename them on the fly
    foreach annotation_orig [set ::cf::clipboard::annotation_list] {
	set annotation_copy [newObjectId $annotation_list "a"]
	lappend new_annotations $annotation_copy
	set annotation_map($annotation_orig) $annotation_copy
	upvar 0 ::cf::[set ::curcfg]::$annotation_copy $annotation_copy
	set $annotation_copy [set ::cf::clipboard::$annotation_orig]
	lappend annotation_list $annotation_copy

	setNodeCanvas $annotation_copy $curcanvas
    }

    # Nothing to do if clipboard is empty
    if { [set ::cf::clipboard::node_list] == {} && [set ::cf::clipboard::annotation_list] == {} } {
	return
    }

    # Paste nodes from the clipboard and rename them on the fly
    foreach node_orig [set ::cf::clipboard::node_list] {
	set new_node_id [newObjectId $node_list "n"]
	set node_map($node_orig) $new_node_id
	upvar 0 ::cf::[set ::curcfg]::$new_node_id $new_node_id
	set $new_node_id [set ::cf::clipboard::$node_orig]
	lappend node_list $new_node_id
	lappend copypaste_list $new_node_id

	set node_type [getNodeType $node_orig]
	if { $node_type in [array names nodeNamingBase] } {
	    setNodeName $new_node_id [getNewNodeNameType $node_type $nodeNamingBase($node_type)]
	} else {
	    setNodeName $new_node_id $new_node_id
	}

	setNodeCanvas $new_node_id $curcanvas
    }

    #
    # Remap interface peerings to match new node names and
    # adjust node positions so that all fit in the target canvas
    #
    set delta 128
    set curx [expr $delta / 2]
    set cury [expr $delta / 2]
    foreach node_orig [set ::cf::clipboard::node_list] {
	set new_node_id $node_map($node_orig)

	foreach iface_id [ifcList $new_node_id] {
	    set old_peer [getIfcPeer $new_node_id $iface_id]
	    set i [lsearch [set $new_node_id] "interface-peer {$iface_id $old_peer}"]
	    set $new_node_id [lreplace [set $new_node_id] $i $i \
		"interface-peer {$iface_id $node_map($old_peer)}"]

	    if { $cutNodes == 0 } {
		autoMACaddr $new_node_id $iface_id
	    }
	}

	set nodecoords [getNodeCoords $new_node_id]
	if { [lindex $nodecoords 0] >= $sizex || [lindex $nodecoords 1] >= $sizey } {
	    setNodeCoords $new_node_id "$curx $cury"
	    setNodeLabelCoords $new_node_id "$curx [expr $cury + $delta / 4]"

	    incr curx $delta
	    if { $curx > $sizex } {
		incr cury $delta
		set curx [expr $delta / 2]
	    }
	}
    }

    # Paste links from the clipboard and rename them on the fly
    foreach link_orig [set ::cf::clipboard::link_list] {
	set new_link_id [newObjectId $link_list "l"]
	upvar 0 ::cf::[set ::curcfg]::$new_link_id $new_link_id
	set $new_link_id [set ::cf::clipboard::$link_orig]
	lappend link_list $new_link_id

	set old_peers [getLinkPeers $new_link_id]
	set new_peers \
	    "$node_map([lindex $old_peers 0]) $node_map([lindex $old_peers 1])"

	set i [lsearch [set $new_link_id] "nodes {$old_peers}"]
	set $new_link_id [lreplace [set $new_link_id] $i $i "nodes {$new_peers}"]
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
    selectNodes [concat $copypaste_list $new_annotations]
}
