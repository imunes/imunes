#
# Copyright 2025- University of Zagreb.
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

#****f* nodes_gui.tcl/getNodeCoords
# NAME
#   getNodeCoords -- get node icon coordinates.
# SYNOPSIS
#   set coords [getNodeCoords $node_id]
# FUNCTION
#   Returns node's icon coordinates.
# INPUTS
#   * node_id -- node id
# RESULT
#   * coords -- coordinates of the node's icon in form of {Xcoord Ycoord}
#****
proc getNodeCoords { node_id } {
	return [cfgGet "gui" "nodes" $node_id "iconcoords"]
}

#****f* nodes_gui.tcl/setNodeCoords
# NAME
#   setNodeCoords -- set node's icon coordinates.
# SYNOPSIS
#   setNodeCoords $node_id $coords
# FUNCTION
#   Sets node's icon coordinates.
# INPUTS
#   * node_id -- node id
#   * coords -- coordinates of the node's icon in form of {Xcoord Ycoord}
#****
proc setNodeCoords { node_id coords } {
	foreach c $coords {
		set x [expr round($c)]
		lappend roundcoords $x
	}

	if { $coords == {} } {
		set roundcoords "0 0"
	}

	cfgSet "gui" "nodes" $node_id "iconcoords" $roundcoords
}

proc getNodeLabel { node_id } {
	return [cfgGet "gui" "nodes" $node_id "label"]
}

proc setNodeLabel { node_id label_str } {
	cfgSetEmpty "gui" "nodes" $node_id "label" $label_str
}

#****f* nodes_gui.tcl/getNodeLabelCoords
# NAME
#   getNodeLabelCoords -- get node's label coordinates.
# SYNOPSIS
#   set coords [getNodeLabelCoords $node_id]
# FUNCTION
#   Returns node's label coordinates.
# INPUTS
#   * node_id -- node id
# RESULT
#   * coords -- coordinates of the node's label in form of {Xcoord Ycoord}
#****
proc getNodeLabelCoords { node_id } {
	return [cfgGet "gui" "nodes" $node_id "labelcoords"]
}

#****f* nodes_gui.tcl/setNodeLabelCoords
# NAME
#   setNodeLabelCoords -- set node's label coordinates.
# SYNOPSIS
#   setNodeLabelCoords $node_id $coords
# FUNCTION
#   Sets node's label coordinates.
# INPUTS
#   * node_id -- node id
#   * coords -- coordinates of the node's label in form of Xcoord Ycoord
#****
proc setNodeLabelCoords { node_id coords } {
	foreach c $coords {
		set x [expr round($c)]
		lappend roundcoords $x
	}

	if { $coords == {} } {
		set roundcoords "0 0"
	}

	cfgSet "gui" "nodes" $node_id "labelcoords" $roundcoords
}

#****f* nodes_gui.tcl/getNodeCanvas
# NAME
#   getNodeCanvas -- get node canvas id
# SYNOPSIS
#   set canvas_id [getNodeCanvas $node_id]
# FUNCTION
#   Returns node's canvas affinity.
# INPUTS
#   * node_id -- node id
# RESULT
#   * canvas_id -- canvas id
#****
proc getNodeCanvas { node_id } {
	return [cfgGet "gui" "nodes" $node_id "canvas"]
}

#****f* nodes_gui.tcl/setNodeCanvas
# NAME
#   setNodeCanvas -- set node canvas
# SYNOPSIS
#   setNodeCanvas $node_id $canvas
# FUNCTION
#   Sets node's canvas affinity.
# INPUTS
#   * node_id -- node id
#   * canvas_id -- canvas id
#****
proc setNodeCanvas { node_id canvas_id } {
	cfgSet "gui" "nodes" $node_id "canvas" $canvas_id
}

#****f* nodes_gui.tcl/setNodeCustomIcon
# NAME
#   setNodeCustomIcon -- set custom icon
# SYNOPSIS
#   setNodeCustomIcon $node_id $icon_name
# FUNCTION
#   Sets the custom icon to a node.
# INPUTS
#   * node_id -- node to change
#   * icon_name -- icon name
#****
proc setNodeCustomIcon { node_id icon_name } {
	cfgSet "gui" "nodes" $node_id "custom_icon" $icon_name
}

#****f* nodes_gui.tcl/getNodeCustomIcon
# NAME
#   getNodeCustomIcon -- get custom icon
# SYNOPSIS
#   getNodeCustomIcon $node_id
# FUNCTION
#   Returns the custom icon from a node.
# INPUTS
#   * node_id -- node to get the icon from
#****
proc getNodeCustomIcon { node_id } {
	return [cfgGet "gui" "nodes" $node_id "custom_icon"]
}

#****f* nodes_gui.tcl/removeNodeCustomIcon
# NAME
#   removeNodeCustomIcon -- remove custom icon
# SYNOPSIS
#   removeNodeCustomIcon $node_id
# FUNCTION
#   Removes the custom icon from a node.
# INPUTS
#   * node_id -- node to remove the icon from
#****
proc removeNodeCustomIcon { node_id } {
	cfgUnset "gui" "nodes" $node_id "custom_icon"
}

#****f* nodes_gui.tcl/getNodeMirror
# NAME
#   getNodeMirror -- get node mirror
# SYNOPSIS
#   set mirror_node_id [getNodeMirror $node_id]
# FUNCTION
#   Returns the node id of a mirror pseudo node of the node. Mirror node is
#   the corresponding pseudo node. The pair of pseudo nodes, node and his
#   mirror node, are introduced to form a split in a link. This split can be
#   used for avoiding crossed links or for displaying a link between the nodes
#   on a different canvas.
# INPUTS
#   * node_id -- node id
# RESULT
#   * mirror_node_id -- node id of a mirror node
#****
proc getNodeMirror { node_id } {
	return [cfgGet "gui" "nodes" $node_id "mirror"]
}

#****f* nodes_gui.tcl/setNodeMirror
# NAME
#   setNodeMirror -- set node mirror
# SYNOPSIS
#   setNodeMirror $node_id $value
# FUNCTION
#   Sets the node id of a mirror pseudo node of the specified node. Mirror
#   node is the corresponding pseudo node. The pair of pseudo nodes, node and
#   his mirror node, are introduced to form a split in a link. This split can
#   be used for avoiding crossed links or for displaying a link between the
#   nodes on a different canvas.
# INPUTS
#   * node_id -- node id
#   * value -- node id of a mirror node
#****
proc setNodeMirror { node_id value } {
	cfgSet "gui" "nodes" $node_id "mirror" $value
}
