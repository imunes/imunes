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

	set selected_nodes [selectedRealNodes]
	set selected_annotations [selectedAnnotations]
	if { $selected_nodes == {} && $selected_annotations == {} } {
		return
	}

	catch { namespace delete ::cf::clipboard }
	namespace eval ::cf::clipboard {}
	upvar 0 ::cf::clipboard::dict_cfg dict_cfg
	set dict_cfg [dict create]

	clipboardSet "annotation_list" {}
	foreach annotation_id $selected_annotations {
		clipboardLappend "annotation_list" $annotation_id
		clipboardSet "gui" "annotations" $annotation_id [cfgGet "gui" "annotations" $annotation_id]
	}

	# Copy selected nodes and interconnecting links to the clipboard
	clipboardSet "node_list" $selected_nodes
	set clipboard_link_list {}
	foreach node_id $selected_nodes {
		clipboardSet "nodes" $node_id [cfgGet "nodes" $node_id]
		clipboardSet "gui" "nodes" $node_id [cfgGet "gui" "nodes" $node_id]

		foreach iface_id [ifcList $node_id] {
			set peer_id [getIfcPeer $node_id $iface_id]
			if { $peer_id != "" && $peer_id ni $selected_nodes } {
				clipboardUnset "nodes" $node_id "ifaces" $iface_id
				clipboardUnset "gui" "nodes" $node_id "ifaces" $iface_id
				continue
			}

			foreach link_id [linksByPeers $node_id $peer_id] {
				if { $link_id ni $clipboard_link_list } {
					lappend clipboard_link_list $link_id
					clipboardSet "links" $link_id [cfgGet "links" $link_id]
					clipboardSet "gui" "links" $link_id [cfgGet "gui" "links" $link_id]
				}
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

	# Nothing to do if clipboards are empty
	set clipboard_node_list [clipboardGet "node_list"]
	set clipboard_annotations [clipboardGet "gui" "annotations"]
	if { $clipboard_node_list == {} && $clipboard_annotations == {} } {
		return
	}

	set new_annotations {}
	set curcanvas [getFromRunning_gui "curcanvas"]
	# Paste annotations from the clipboard and rename them on the fly
	foreach {annotation_orig annotation_orig_cfg} $clipboard_annotations {
		set new_annotation_id [newObjectId [getFromRunning_gui "annotation_list"] "a"]

		cfgSet "gui" "annotations" $new_annotation_id $annotation_orig_cfg
		lappendToRunning_gui "annotation_list" $new_annotation_id
		lappend new_annotations $new_annotation_id

		setAnnotationCanvas $new_annotation_id $curcanvas
	}

	set naming_list {}
	foreach node_id [getFromRunning "node_list"] {
		if { [getNodeType $node_id] ni "pseudo" } {
			lappend naming_list [getNodeName $node_id]
		}
	}

	set copypaste_list {}
	array set node_map {}
	# Paste nodes from the clipboard and rename them on the fly
	foreach {node_orig node_orig_cfg} [clipboardGet "nodes"] {
		set new_node_id [newObjectId [getFromRunning "node_list"] "n"]
		set node_map($node_orig) $new_node_id
		cfgSet "nodes" $new_node_id $node_orig_cfg
		setToRunning "${new_node_id}_running" "false"
		lappendToRunning "node_list" $new_node_id
		lappend copypaste_list $new_node_id

		set node_type [getNodeType $new_node_id]
		if { $node_type ni [array names nodeNamingBase] } {
			# fallback
			setNodeName $new_node_id $new_node_id
		}

		set node_name [getNodeName $new_node_id]
		if { $node_name in $naming_list } {
			# if name already exists, get the next one
			setNodeName $new_node_id [getNewNodeNameType $node_type $nodeNamingBase($node_type)]
		} else {
			recalculateNumType $node_type $nodeNamingBase($node_type)
		}

		lappend naming_list $node_name
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

		foreach iface_id [ifcList $new_node_id] {
			setToRunning "${new_node_id}|${iface_id}_running" "false"
			#set new_peer_id $node_map([getIfcPeer $new_node_id $iface_id])
			#cfgSet "nodes" $new_node_id "ifaces" $iface_id "peer" $new_link_id

			if { $cutNodes == 0 } {
				setIfcMACaddr $new_node_id $iface_id ""
				autoMACaddr $new_node_id $iface_id
			} else {
				set mac_address [getIfcMACaddr $new_node_id $iface_id]
				if { $mac_address != "" } {
					lappendToRunning "mac_used_list" $mac_address
				}
			}

			set addrs4 [getIfcIPv4addrs $new_node_id $iface_id]
			if { $addrs4 != "" } {
				lappendToRunning "ipv4_used_list" [getIfcIPv4addrs $new_node_id $iface_id]
			}

			set addrs6 [getIfcIPv6addrs $new_node_id $iface_id]
			if { $addrs6 != "" } {
				lappendToRunning "ipv6_used_list" [getIfcIPv6addrs $new_node_id $iface_id]
			}
		}
	}

	# node GUI stuff
	foreach node_orig $clipboard_node_list {
		set new_node_id $node_map($node_orig)
		cfgSet "gui" "nodes" $new_node_id [clipboardGet "gui" "nodes" $node_orig]

		setNodeCanvas $new_node_id $curcanvas
		setNodeLabel $new_node_id [getNodeName $new_node_id]

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
	foreach {link_orig link_orig_cfg} [clipboardGet "links"] {
		set new_link_id [newObjectId [getFromRunning "link_list"] "l"]
		cfgSet "links" $new_link_id $link_orig_cfg
		cfgSet "gui" "links" $new_link_id [cfgGet "gui" "links" $link_orig]
		lappendToRunning "link_list" $new_link_id
		if { [getFromRunning "${new_link_id}_running"] == "" } {
			setToRunning "${new_link_id}_running" "false"
		}

		set old_peers [getLinkPeers $new_link_id]
		set new_peers \
			"$node_map([lindex $old_peers 0]) $node_map([lindex $old_peers 1])"

		foreach node_id $new_peers iface_id [getLinkPeersIfaces $new_link_id] {
			cfgSet "nodes" $node_id "ifaces" $iface_id "link" $new_link_id
		}

		cfgSet "links" $new_link_id "peers" $new_peers
		cfgSet "gui" "links" $new_link_id "peers" $new_peers
	}

	updateCustomIconReferences

	if { $cutNodes == 0 } {
		global IPv4autoAssign IPv6autoAssign

		if { $IPv4autoAssign } {
			set copypaste_nodes 1
			changeAddressRange
		}

		if { $IPv6autoAssign } {
			set copypaste_nodes 1
			changeAddressRange6
		}
	}
	set cutNodes 0

	set changed 1
	updateUndoLog

	redrawAll
	setActiveToolGroup select
	selectNodes [concat $copypaste_list $new_annotations]
}
