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

#****f* linkcfg_gui.tcl/getLinkBandwidthString
# NAME
#   getLinkBandwidthString -- get link bandwidth string
# SYNOPSIS
#   set bandwidth_str [getLinkBandwidthString $link_id]
# FUNCTION
#   Returns the link bandwidth in form of a number an a mesure unit.
#   Measure unit is automaticaly asigned depending on the value of bandwidth.
# INPUTS
#   * link_id -- link id
# RESULT
#   * bandwidth_string -- The value of link bandwidth formated in a sting containing a
#     measure unit.
#****
proc getLinkBandwidthString { link_id } {
	set bandwidth_string ""
	set bandwidth [getLinkBandwidth $link_id]
	if { $bandwidth > 0 } {
		if { $bandwidth >= 660000000 } {
			set bandwidth_string "[format %.2f [expr {$bandwidth / 1000000000.0}]] Gbps"
		} elseif { $bandwidth >= 99000000 } {
			set bandwidth_string "[format %d [expr {$bandwidth / 1000000}]] Mbps"
		} elseif { $bandwidth >= 9900000 } {
			set bandwidth_string "[format %.2f [expr {$bandwidth / 1000000.0}]] Mbps"
		} elseif { $bandwidth >= 990000 } {
			set bandwidth_string "[format %d [expr {$bandwidth / 1000}]] Kbps"
		} elseif { $bandwidth >= 9900 } {
			set bandwidth_string "[format %.2f [expr {$bandwidth / 1000.0}]] Kbps"
		} else {
			set bandwidth_string "$bandwidth bps"
		}
	}

	return $bandwidth_string
}

#****f* linkcfg_gui.tcl/getLinkDelayString
# NAME
#   getLinkDelayString -- get link delay string
# SYNOPSIS
#   set delay [getLinkDelayString $link_id]
# FUNCTION
#   Returns the link delay as a string with avalue and measure unit.
#   Measure unit is automaticaly asigned depending on the value of delay.
# INPUTS
#   * link_id -- link id
# RESULT
#   * delay -- The value of link delay formated in a sting containing a
#     measure unit.
#****
proc getLinkDelayString { link_id } {
	set delstr ""
	set delay [getLinkDelay $link_id]
	if { "$delay" != "" } {
		if { $delay >= 10000 } {
			set delstr "[expr {$delay / 1000}] ms"
		} elseif { $delay >= 1000 } {
			set delstr "[format "%.3f" [expr {$delay * .001}]] ms"
		} else {
			set delstr "$delay us"
		}
	}

	return $delstr
}

proc getPseudoLinksFromLink { link_id } {
	lassign [getLinkPeers $link_id] node1_id node2_id
	lassign [getLinkPeersIfaces $link_id] iface1_id iface2_id
	set pseudo1_link_id "${link_id}.${node1_id}.${iface1_id}"
	set pseudo2_link_id "${link_id}.${node2_id}.${iface2_id}"
	
	if { [cfgGet "gui" "links" $pseudo1_link_id] != "" } {
		if { [cfgGet "gui" "links" $pseudo2_link_id] != "" } {
			return "$pseudo1_link_id $pseudo2_link_id"
		}
	}

	return ""
}

proc linkFromPseudoLink { pseudo_id } {
	return [split $pseudo_id "."]
}

#****f* linkcfg.tcl/splitLink
# NAME
#   splitLink -- split the link
# SYNOPSIS
#   set nodes [splitLink $orig_link_id]
# FUNCTION
#   Splits the link in two parts. Each part of the split link is one pseudo
#   link.
# INPUTS
#   * orig_link_id -- link id
# RESULT
#   * nodes -- list of node ids of new nodes.
#****
proc splitLink { orig_link_id } {
	set orig_nodes [getLinkPeers $orig_link_id]
	set orig_ifaces [getLinkPeersIfaces $orig_link_id]
	lassign $orig_nodes orig_node1_id orig_node2_id
	lassign $orig_ifaces orig_iface1_id orig_iface2_id

	set links "${orig_link_id}.${orig_node1_id}.${orig_iface1_id} ${orig_link_id}.${orig_node2_id}.${orig_iface2_id}"

	# create pseudo nodes
	set pseudo_nodes "${orig_node1_id}.${orig_iface1_id}"
	lappend pseudo_nodes "${orig_node2_id}.${orig_iface2_id}"

	foreach orig_node_id $orig_nodes orig_iface_id $orig_ifaces pseudo_node_id $pseudo_nodes link_id $links {
		set other_orig_node_id [removeFromList $orig_nodes $orig_node_id "keep_doubles"]
		set other_orig_iface_id [removeFromList $orig_ifaces $orig_iface_id "keep_doubles"]
		set other_link_id [removeFromList $links $link_id "keep_doubles"]

		# setup new pseudo node properties
		setNodeMirror $pseudo_node_id [removeFromList $pseudo_nodes $pseudo_node_id "keep_doubles"]
		setPseudoNodeLink $pseudo_node_id $link_id

		# pseudo node default values
		setNodeCoords $pseudo_node_id [getNodeCoords $other_orig_node_id]
		setNodeLabelCoords $pseudo_node_id [getNodeCoords $pseudo_node_id]
		setNodeCanvas $pseudo_node_id [getNodeCanvas $orig_node_id]

		# setup new pseudo link properties
		setLinkPeers_gui $link_id "$pseudo_node_id $orig_node_id"
		setLinkMirror $link_id $other_link_id
		setLinkWidth $link_id [getLinkWidth $orig_link_id]
		setLinkColor $link_id [getLinkColor $orig_link_id]
	}

	return $pseudo_nodes
}

#****f* linkcfg.tcl/mergeLink
# NAME
#   mergeLink -- merge the link
# SYNOPSIS
#   set new_link_id [mergeLink $link_id]
# FUNCTION
#   Rebuilts a link from two pseudo links.
# INPUTS
#   * link_id -- pseudo link id
# RESULT
#   * link_id -- rebuilt link id
#****
proc mergeLink { link_id } {
	set mirror_link_id [getLinkMirror $link_id]
	if { $mirror_link_id == "" } {
		return
	}

	lassign [getLinkPeers_gui $link_id] pseudo_node1_id orig_node1_id
	lassign [getLinkPeers_gui $mirror_link_id] pseudo_node2_id orig_node2_id

	cfgUnset "gui" "nodes" $pseudo_node1_id
	cfgUnset "gui" "nodes" $pseudo_node2_id

	cfgUnset "gui" "links" $link_id
	cfgUnset "gui" "links" $mirror_link_id

	lassign [linkFromPseudoLink $link_id] link_id - -

	return $link_id
}

proc updateLinkGUI { link_id old_link_cfg_gui new_link_cfg_gui } {
	dputs ""
	dputs "= /UPDATE LINK GUI $link_id START ="

	if { $old_link_cfg_gui == "*" } {
		set old_link_cfg_gui [cfgGet "gui" "links" $link_id]
	}

	dputs "OLD : '$old_link_cfg_gui'"
	dputs "NEW : '$new_link_cfg_gui'"

	set cfg_diff [dictDiff $old_link_cfg_gui $new_link_cfg_gui]
	dputs "= cfg_diff: '$cfg_diff'"
	if { $cfg_diff == "" || [lsort -uniq [dict values $cfg_diff]] == "copy" } {
		dputs "= NO CHANGE"
		dputs "= /UPDATE LINK GUI $link_id END ="
		return $new_link_cfg_gui
	}

	if { $new_link_cfg_gui == "" } {
		return $old_link_cfg_gui
	}

	dict for {key change} $cfg_diff {
		if { $change == "copy" } {
			continue
		}

		dputs "==== $change: '$key'"

		set old_value [_cfgGet $old_link_cfg_gui $key]
		set new_value [_cfgGet $new_link_cfg_gui $key]
		if { $change in "changed" } {
			dputs "==== OLD: '$old_value'"
		}
		if { $change in "new changed" } {
			dputs "==== NEW: '$new_value'"
		}

		switch -exact $key {
			"peers" {
				setLinkPeers_gui $link_id $new_value
			}

			"mirror" {
				setLinkMirror $link_id $new_value
			}

			"color" {
				setLinkColor $link_id $new_value
			}

			"width" {
				setLinkWidth $link_id $new_value
			}

			default {
				# do nothing
			}
		}
	}

	dputs "= /UPDATE LINK GUI $link_id END ="
	dputs ""

	return $new_link_cfg_gui
}
