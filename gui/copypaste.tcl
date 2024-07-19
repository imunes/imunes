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
    global cutNodes

    if { [getFromRunning "oper_mode"] == "exec" } {
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

    if { [selectedNodes] == {} } {
	return
    }

    catch { namespace delete ::cf::clipboard }
    namespace eval ::cf::clipboard {}
    upvar 0 ::cf::clipboard::dict_cfg dict_cfg
    set dict_cfg [dict create]

    upvar 0 ::cf::clipboard::annotation_list clipboard_annotation_list

    clipboardSet "annotation_list" {}
    foreach annotation_id [selectedNodes] {
	if { $annotation_id ni [selectedRealNodes] } {
	    clipboardLappend "annotation_list" $annotation_id
	    clipboardSet "annotations" $annotation_id [cfgGet "annotations" $annotation_id]
	}
    }

    # Copy selected nodes and interconnecting links to the clipboard
    clipboardSet "node_list" [set clipboard_node_list [selectedRealNodes]]
    set clipboard_link_list {}
    foreach node_id $clipboard_node_list {
	clipboardSet "nodes" $node_id [cfgGet "nodes" $node_id]

	foreach iface [ifcList $node_id] {
	    set peer [getIfcPeer $node_id $iface]
	    if { $peer ni $clipboard_node_list } {
		clipboardUnset "nodes" $node_id "ifaces" $iface
		continue
	    }

	    set link_id [linkByPeers $node_id $peer]
	    if { $link_id ni $clipboard_link_list } {
		lappend clipboard_link_list $link_id
		clipboardSet "links" $link_id [cfgGet "links" $link_id]
	    }
	}
    }

    clipboardSet "link_list" $clipboard_link_list
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
    global sizex sizey
    global changed copypaste_list cutNodes copypaste_nodes
    global nodeNamingBase

    if { [getFromRunning "oper_mode"] == "exec" } {
	return
    }

    set curcanvas [getFromRunning "curcanvas"]
    # Paste annotations from the clipboard and rename them on the fly
    foreach {annotation_orig annotation_orig_cfg} [clipboardGet "annotations"] {
	set new_annotation_id [newObjectId "annotation"]

	cfgSet "annotations" $new_annotation_id $annotation_orig_cfg
	lappendToRunning "annotation_list" $new_annotation_id

	setAnnotationCanvas $new_annotation_id $curcanvas
	drawAnnotation $new_annotation_id
    }
    raiseAll .panwin.f1.c

    # Nothing to do if clipboard is empty
    set clipboard_node_list [clipboardGet "node_list"]
    if { $clipboard_node_list == {} } {
	return
    }

    set copypaste_list {}
    array set node_map {}
    # Paste nodes from the clipboard and rename them on the fly
    foreach {node_orig node_orig_cfg} [clipboardGet "nodes"] {
	set new_node_id [newObjectId "node"]

	set node_map($node_orig) $new_node_id
	cfgSet "nodes" $new_node_id $node_orig_cfg
	lappendToRunning "node_list" $new_node_id

	lappend copypaste_list $new_node_id
	set node_type [getNodeType $node_orig]
	if { $node_type in [array names nodeNamingBase] } {
	    setNodeName $new_node_id [getNewNodeNameType $node_type $nodeNamingBase($node_type)]
	} elseif { $node_type in "ext extnat rj45" } {
	    setNodeName $new_node_id "UNASSIGNED"
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
    foreach node_orig $clipboard_node_list {
	set new_node_id $node_map($node_orig)

	foreach iface [ifcList $new_node_id] {
	    #set new_peer_id $node_map([getIfcPeer $new_node_id $iface])
	    #cfgSet "nodes" $new_node_id "ifaces" $iface "peer" $new_link_id

	    if { $cutNodes == 0 } {
		autoMACaddr $new_node_id $iface
	    }
	}

	set nodecoords [getNodeCoords $new_node_id]
	if { [lindex $nodecoords 0] >= $sizex ||
	    [lindex $nodecoords 1] >= $sizey } {
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
    foreach {link_orig link_orig_cfg} [clipboardGet "links"] {
	set new_link_id [newObjectId "link"]
	cfgSet "links" $new_link_id $link_orig_cfg
	lappendToRunning "link_list" $new_link_id

	set old_peers [getLinkPeers $new_link_id]
	set new_peers \
	    "$node_map([lindex $old_peers 0]) $node_map([lindex $old_peers 1])"

	foreach node_id $new_peers iface [getLinkPeersIfaces $new_link_id] {
	    cfgSet "nodes" $node_id "ifaces" $iface "link" $new_link_id
	}

	cfgSet "links" $new_link_id "peers" $new_peers
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
