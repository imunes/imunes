#
# Copyright 2004-2013 University of Zagreb.
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

# $Id: linkcfg.tcl 129 2015-02-13 11:14:44Z valter $


#****h* imunes/linkcfg.tcl
# NAME
#  linkcfg.tcl -- file used for manipultaion with links in IMUNES
# FUNCTION
#  This module is used to define all the actions used for configuring
#  links in IMUNES.
#
# NOTES
#
# linkByPeers { node1 node2 }
#	Returns link whose peers are node1 and node2
#
# removeLink { link_id }
#	Removes the link and related entries in peering node's configs
#
# getLinkBandwidth { link_id }
#	... in bits per second
#
# getLinkBandwidthString { link_id }
#	... as string
#
# getLinkDelay { link_id }
#	... in microseconds
#
# getLinkDelayString { link_id }
#	... as sting
#
# setLinkBandwidth { link_id bandwidth }
#	... in bits per second
#
# setLinkDelay { link_id delay }
#	... in microseconds
#
# All of the above functions are independent to any Tk objects. This means
# they can be used for implementing tasks external to GUI, yet inside the
# GUI any updating of related Tk objects (such as text labels etc.) will
# have to be implemented by additional Tk code.
#****

#****f* linkcfg.tcl/linkByPeers
# NAME
#   linkByPeers -- get link id from peer nodes
# SYNOPSIS
#   set link_id [linkByPeers $node1 $node2]
# FUNCTION
#   Returns link whose peers are node1 and node2.
#   The order of input nodes is irrelevant.
# INPUTS
#   * node1 -- node id of the first node
#   * node2 -- node id of the second node
# RESULT
#   * link_id -- returns id of a link connecting endpoints node1 and node2
#****
proc linkByPeers { node1 node2 } {
    set links [cfgGet "links"]
    foreach {link_id link_cfg} $links {
	set peers [dictGet $links $link_id "peers"]
	if { $node1 in $peers && $node2 in $peers } {
	    return $link_id
	}
    }

    return {}
}

#****f* linkcfg.tcl/removeLink
# NAME
#   removeLink -- removes a link.
# SYNOPSIS
#   removeLink $link_id
# FUNCTION
#   Removes the link and related entries in peering node's configs.
#   Updates the default route for peer nodes.
# INPUTS
#   * link_id -- link id
#****
proc removeLink { link_id { keep_ifaces 0 } } {
    # direct links handling in edit/exec mode?
    if { [getLinkDirect $link_id] && [getFromRunning "oper_mode"] == "exec" } {
	set keep_ifaces 0
    }

    # move to removeIfaces procedure
    set pnodes [getLinkPeers $link_id]
    foreach node_id $pnodes iface [getLinkPeersIfaces $link_id] {
	if { $keep_ifaces } {
	    cfgUnset "nodes" $node_id "ifaces" $iface "link"
	    continue
	}

	if { [getNodeType $node_id] in "extelem" } {
	    cfgUnset "nodes" $node_id "ifaces" $iface
	    continue
	}

	setToRunning "ipv4_used_list" [removeFromList [getFromRunning "ipv4_used_list"] [getIfcIPv4addr $node_id $iface] 1]
	setToRunning "ipv6_used_list" [removeFromList [getFromRunning "ipv6_used_list"] [getIfcIPv6addr $node_id $iface] 1]
	setToRunning "mac_used_list" [removeFromList [getFromRunning "mac_used_list"] [getIfcMACaddr $node_id $iface] 1]

	cfgUnset "nodes" $node_id "ifaces" $iface

	foreach lifc [logIfcList $node_id] {
	    switch -exact [getLogIfcType $node_id $lifc] {
		vlan {
		    if { [getIfcVlanDev $node_id $lifc] == $iface } {
			cfgUnset "nodes" $node_id "logifaces" $lifc
		    }
		}
	    }
	}
    }

    set mirror_link_id [getLinkMirror $link_id]
    if { $mirror_link_id != "" } {
	setLinkMirror $mirror_link_id ""
	removeLink $mirror_link_id $keep_ifaces
    }

    # move to removeIfaces procedure
    foreach node_id $pnodes {
	if { [getNodeType $node_id] == "pseudo" } {
	    setToRunning "node_list" [removeFromList [getFromRunning "node_list"] $node_id]
	    cfgUnset "nodes" $node_id
	}
    }

    setToRunning "link_list" [removeFromList [getFromRunning "link_list"] $link_id]
    cfgUnset "links" $link_id
}

#****f* linkcfg.tcl/getLinkDirect
# NAME
#   getLinkDirect -- get if link is direct
# SYNOPSIS
#   set link_direct [getLinkDirect $link_id]
# FUNCTION
#   Returns boolean - link is direct.
# INPUTS
#   * link_id -- link id
# RESULT
#   * link_direct -- returns 0 if link is not a direct link and 1 if it is
#****
proc getLinkDirect { link_id } {
    return [cfgGetWithDefault 0 "links" $link_id "direct"]
}

#****f* linkcfg.tcl/setLinkDirect
# NAME
#   setLinkDirect -- set link bandwidth
# SYNOPSIS
#   setLinkDirect $link_id $direct
# FUNCTION
#   Sets the link bandwidth in a bits per second.
# INPUTS
#   * link_id -- link id
#   * direct -- link bandwidth in bits per second.
#****
proc setLinkDirect { link_id direct } {
    cfgSet "links" $link_id "direct" $direct
}

#****f* linkcfg.tcl/getLinkBandwidth
# NAME
#   getLinkBandwidth -- get link bandwidth
# SYNOPSIS
#   set bandwidth [getLinkBandwidth $link_id]
# FUNCTION
#   Returns the link bandwidth expressed in bits per second.
# INPUTS
#   * link_id -- link id
# RESULT
#   * bandwidth -- The value of link bandwidth in bits per second.
#****
proc getLinkBandwidth { link_id } {
    return [cfgGet "links" $link_id "bandwidth"]
}

#****f* linkcfg.tcl/getLinkBandwidthString
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

#****f* linkcfg.tcl/setLinkBandwidth
# NAME
#   setLinkBandwidth -- set link bandwidth
# SYNOPSIS
#   setLinkBandwidth $link_id $bandwidth
# FUNCTION
#   Sets the link bandwidth in a bits per second.
# INPUTS
#   * link_id -- link id
#   * bandwidth -- link bandwidth in bits per second.
#****
proc setLinkBandwidth { link_id bandwidth } {
    if { $bandwidth == 0 } {
	set bandwidth ""
    }

    cfgSet "links" $link_id "bandwidth" $bandwidth
}

#****f* linkcfg.tcl/getLinkColor
# NAME
#   getLinkColor -- get link color
# SYNOPSIS
#   getLinkColor $link
# FUNCTION
#   Returns the color of the link.
# INPUTS
#   * link -- link id
# RESULT
#   * color -- link color
#****
proc getLinkColor { link_id } {
    global defLinkColor

    return [cfgGetWithDefault $defLinkColor "links" $link_id "color"]
}

#****f* linkcfg.tcl/setLinkColor
# NAME
#   setLinkColor -- set link color
# SYNOPSIS
#   setLinkColor $link_id $color
# FUNCTION
#   Sets the color of the link.
# INPUTS
#   * link_id -- link id
#   * color -- link color
#****
proc setLinkColor { link_id color } {
    if { $color == "Red" } {
	set color ""
    }

    cfgSet "links" $link_id "color" $color
}

#****f* linkcfg.tcl/getLinkWidth
# NAME
#   getLinkWidth -- get link width
# SYNOPSIS
#   getLinkWidth $link
# FUNCTION
#   Returns the link width on canvas.
# INPUTS
#   * link -- link id
#****
proc getLinkWidth { link_id } {
    global defLinkWidth

    return [cfgGetWithDefault $defLinkWidth "links" $link_id "width"]
}

#****f* linkcfg.tcl/setLinkWidth
# NAME
#   setLinkWidth -- set link width
# SYNOPSIS
#   setLinkWidth $link_id $width
# FUNCTION
#   Sets the link width on canvas.
# INPUTS
#   * link_id -- link id
#   * width -- link width
#****
proc setLinkWidth { link_id width } {
    global defLinkWidth

    if { $width == $defLinkWidth } {
	set width ""
    }

    cfgSet "links" $link_id "width" $width
}

#****f* linkcfg.tcl/getLinkDelay
# NAME
#   getLinkDelay -- get link delay
# SYNOPSIS
#   set delay [getLinkDelay $link_id]
# FUNCTION
#   Returns the link delay expressed in microseconds.
# INPUTS
#   * link_id -- link id
# RESULT
#   * delay -- The value of link delay in microseconds.
#****
proc getLinkDelay { link_id } {
    return [cfgGet "links" $link_id "delay"]
}

#****f* linkcfg.tcl/getLinkDelayString
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

#****f* linkcfg.tcl/setLinkDelay
# NAME
#   setLinkDelay -- set link delay
# SYNOPSIS
#   setLinkDelay $link_id $delay
# FUNCTION
#   Sets the link delay in microseconds.
# INPUTS
#   * link_id -- link id
#   * delay -- link delay delay in microseconds.
#****
proc setLinkDelay { link_id delay } {
    if { $delay == 0 } {
	set delay ""
    }

    cfgSet "links" $link_id "delay" $delay
}

#****f* linkcfg.tcl/getLinkJitterUpstream
# NAME
#   getLinkJitterUpstream -- get link upstream Jitter
# SYNOPSIS
#   set delay [getLinkJitterUpstream $link_id]
# FUNCTION
#   Returns the list of upstream link jitter values expressed in microseconds.
# INPUTS
#   * link_id -- link id
# RESULT
#   * jitter -- the list of values for jitter in microseconds
#****
proc getLinkJitterUpstream { link_id } {
    return [cfgGet "links" $link_id "jitter_upstream"]
}

#****f* linkcfg.tcl/setLinkJitterUpstream
# NAME
#   setLinkJitterUpstream -- set link upstream jitter
# SYNOPSIS
#   setLinkJitterUpstream $link_id $jitter_upstream
# FUNCTION
#   Sets the link upstream jitter in microseconds.
# INPUTS
#   * link_id -- link id
#   * jitter_upstream -- link upstream jitter values in microseconds.
#****
proc setLinkJitterUpstream { link_id jitter_upstream } {
    if { $jitter_upstream == 0 } {
	set jitter_upstream ""
    }

    cfgSet "links" $link_id "jitter_upstream" $jitter_upstream
}

#****f* linkcfg.tcl/getLinkJitterModeUpstream
# NAME
#   getLinkJitterModeUpstream -- get link upstream jitter mode
# SYNOPSIS
#   set delay [getLinkJitterModeUpstream $link_id]
# FUNCTION
#   Returns the upstream link jitter mode.
# INPUTS
#   * link_id -- link id
# RESULT
#   * jitter_mode -- The jitter mode for upstream direction.
#****
proc getLinkJitterModeUpstream { link_id } {
    return [cfgGet "links" $link_id "jitter_upstream_mode"]
}

#****f* linkcfg.tcl/setLinkJitterModeUpstream
# NAME
#   setLinkJitterModeUpstream -- set link upstream jitter mode
# SYNOPSIS
#   setLinkJitterModeUpstream $link_id $jitter_upstream_mode
# FUNCTION
#   Sets the link upstream jitter mode.
# INPUTS
#   * link_id -- link id
#   * jitter_upstream_mode -- link upstream jitter mode.
#****
proc setLinkJitterModeUpstream { link_id jitter_upstream_mode } {
    if { $jitter_upstream_mode == 0 } {
	set jitter_upstream_mode ""
    }

    cfgSet "links" $link_id "jitter_upstream_mode" $jitter_upstream_mode
}

#****f* linkcfg.tcl/getLinkJitterHoldUpstream
# NAME
#   getLinkJitterHoldUpstream -- get link upstream jitter hold
# SYNOPSIS
#   set delay [getLinkJitterHoldUpstream $link_id]
# FUNCTION
#   Returns the upstream link jitter hold.
# INPUTS
#   * link_id -- link id
# RESULT
#   * jitter_hold -- The jitter hold for upstream direction.
#****
proc getLinkJitterHoldUpstream { link_id } {
    return [cfgGet "links" $link_id "jitter_upstream_hold"]
}

#****f* linkcfg.tcl/setLinkJitterHoldUpstream
# NAME
#   setLinkJitterHoldUpstream -- set link upstream jitter hold
# SYNOPSIS
#   setLinkJitterHoldUpstream $link_id $jitter_upstream_hold
# FUNCTION
#   Sets the link upstream jitter hold.
# INPUTS
#   * link_id -- link id
#   * jitter_upstream_hold -- link upstream jitter hold.
#****
proc setLinkJitterHoldUpstream { link_id jitter_upstream_hold } {
    if { $jitter_upstream_hold == 0 } {
	set jitter_upstream_hold ""
    }

    cfgSet "links" $link_id "jitter_upstream_hold" $jitter_upstream_hold
}

#****f* linkcfg.tcl/getLinkJitterDownstream
# NAME
#   getLinkJitterDownstream -- get link downstream Jitter
# SYNOPSIS
#   set delay [getLinkJitterDownstream $link_id]
# FUNCTION
#   Returns the downstream link jitter values expressed in microseconds in a
#   list.
# INPUTS
#   * link_id -- link id
# RESULT
#   * jitter -- The list of values for jitter in microseconds.
#****
proc getLinkJitterDownstream { link_id } {
    return [cfgGet "links" $link_id "jitter_downstream"]
}

#****f* linkcfg.tcl/setLinkJitterDownstream
# NAME
#   setLinkJitterDownstream -- set link downstream jitter
# SYNOPSIS
#   setLinkJitterDownstream $link_id $jitter_downstream
# FUNCTION
#   Sets the link downstream jitter in microseconds.
# INPUTS
#   * link_id -- link id
#   * jitter_downstream -- link downstream jitter values in microseconds.
#****
proc setLinkJitterDownstream { link_id jitter_downstream } {
    if { $jitter_downstream == 0 } {
	set jitter_downstream ""
    }

    cfgSet "links" $link_id "jitter_downstream" $jitter_downstream
}

#****f* linkcfg.tcl/getLinkJitterModeDownstream
# NAME
#   getLinkJitterModeDownstream -- get link downstream jitter mode
# SYNOPSIS
#   set delay [getLinkJitterModeDownstream $link_id]
# FUNCTION
#   Returns the downstream link jitter mode.
# INPUTS
#   * link_id -- link id
# RESULT
#   * jitter_mode -- The jitter mode for downstream direction.
#****
proc getLinkJitterModeDownstream { link_id } {
    return [cfgGet "links" $link_id "jitter_downstream_mode"]
}

#****f* linkcfg.tcl/setLinkJitterModeDownstream
# NAME
#   setLinkJitterModeDownstream -- set link downstream jitter mode
# SYNOPSIS
#   setLinkJitterModeDownstream $link_id $jitter_downstream_mode
# FUNCTION
#   Sets the link downstream jitter mode.
# INPUTS
#   * link_id -- link id
#   * jitter_downstream_mode -- link downstream jitter mode.
#****
proc setLinkJitterModeDownstream { link_id jitter_downstream_mode } {
    if { $jitter_downstream_mode == 0 } {
	set jitter_downstream_mode ""
    }

    cfgSet "links" $link_id "jitter_downstream_mode" $jitter_downstream_mode
}

#****f* linkcfg.tcl/getLinkJitterHoldDownstream
# NAME
#   getLinkJitterHoldDownstream -- get link downstream jitter hold
# SYNOPSIS
#   set delay [getLinkJitterHoldDownstream $link_id]
# FUNCTION
#   Returns the downstream link jitter hold.
# INPUTS
#   * link_id -- link id
# RESULT
#   * jitter_hold -- The jitter hold for downstream direction.
#****
proc getLinkJitterHoldDownstream { link_id } {
    return [cfgGet "links" $link_id "jitter_downstream_hold"]
}

#****f* linkcfg.tcl/setLinkJitterHoldDownstream
# NAME
#   setLinkJitterHoldDownstream -- set link downstream jitter hold
# SYNOPSIS
#   setLinkJitterHoldDownstream $link_id $jitter_downstream_hold
# FUNCTION
#   Sets the link downstream jitter hold.
# INPUTS
#   * link_id -- link id
#   * jitter_downstream_hold -- link downstream jitter hold.
#****
proc setLinkJitterHoldDownstream { link_id jitter_downstream_hold } {
    if { $jitter_downstream_hold == 0 } {
	set jitter_downstream_hold ""
    }

    cfgSet "links" $link_id "jitter_downstream_hold" $jitter_downstream_hold
}

#****f* linkcfg.tcl/getLinkBER
# NAME
#   getLinkBER -- get link BER
# SYNOPSIS
#   set BER [getLinkBER $link_id]
# FUNCTION
#   Returns 1/BER value of the link.
# INPUTS
#   * link_id -- link id
# RESULT
#   * BER -- The value of 1/BER of the link.
#****
proc getLinkBER { link_id } {
    return [cfgGet "links" $link_id "ber"]
}

#****f* linkcfg.tcl/setLinkBER
# NAME
#   setLinkBER -- set link BER
# SYNOPSIS
#   setLinkBER $link_id ber
# FUNCTION
#   Sets the BER value of the link.
# INPUTS
#   * link_id -- link id
#   * ber -- The value of 1/BER of the link.
#****
proc setLinkBER { link_id ber } {
    if { $ber == 0 } {
	set ber ""
    }

    cfgSet "links" $link_id "ber" $ber
}

#****f* linkcfg.tcl/getLinkLoss
# NAME
#   getLinkLoss -- get link loss
# SYNOPSIS
#   set loss [getLinkLoss $link_id]
# FUNCTION
#   Returns loss percentage of the link.
# INPUTS
#   * link_id -- link id
# RESULT
#   * loss -- The loss percentage of the link.
#****
proc getLinkLoss { link_id } {
    return [cfgGet "links" $link_id "loss"]
}

#****f* linkcfg.tcl/setLinkLoss
# NAME
#   setLinkLoss -- set link loss
# SYNOPSIS
#   setLinkLoss $link_id loss
# FUNCTION
#   Sets the loss percentage of the link.
# INPUTS
#   * link_id -- link id
#   * loss -- The loss percentage of the link.
#****
proc setLinkLoss { link_id loss } {
    if { $loss == 0 } {
	set loss ""
    }

    cfgSet "links" $link_id "loss" $loss
}

#****f* linkcfg.tcl/getLinkDup
# NAME
#   getLinkDup -- get link packet duplicate value
# SYNOPSIS
#   set duplicate [getLinkDup $link_id]
# FUNCTION
#   Returns the value of the link duplicate percentage.
# INPUTS
#   * link_id -- link id
# RESULT
#   * duplicate -- The percentage of the link packet duplicate value.
#****
proc getLinkDup { link_id } {
    return [cfgGet "links" $link_id "duplicate"]
}

#****f* linkcfg.tcl/setLinkDup
# NAME
#   setLinkDup -- set link packet duplicate value
# SYNOPSIS
#   setLinkDup $link_id $duplicate
# FUNCTION
#   Set link packet duplicate percentage.
# INPUTS
#   * link_id -- link id
#   * duplicate -- The percentage of the link packet duplicate value.
#****
proc setLinkDup { link_id duplicate } {
    if { $duplicate == 0 } {
	set duplicate ""
    }

    cfgSet "links" $link_id "duplicate" $duplicate
}

#****f* linkcfg.tcl/linkResetConfig
# NAME
#   linkResetConfig -- reset link configuration
# SYNOPSIS
#   linkResetConfig $link_id
# FUNCTION
#   Reset link configuration to default values.
# INPUTS
#   * link_id -- link id
#****
proc linkResetConfig { link_id } {
    setLinkBandwidth $link_id ""
    setLinkBER $link_id ""
    setLinkLoss $link_id ""
    setLinkDelay $link_id ""
    setLinkDup $link_id ""

    if { [getFromRunning "oper_mode"] == "exec" } {
	execSetLinkParams [getFromRunning "eid"] $link_id
    }

    redrawAll
}

#****f* linkcfg.tcl/getLinkMirror
# NAME
#   getLinkMirror -- get link's mirror link
# SYNOPSIS
#   set mirror_link_id [getLinkMirror $link_id]
# FUNCTION
#   Returns the value of the link's mirror link. Mirror link is the other part
#   of the link connecting node to a pseudo node. Two mirror links present
#   only one physical link.
# INPUTS
#   * link_id -- link id
# RESULT
#   * mirror_link_id -- mirror link id
#****
proc getLinkMirror { link_id } {
    return [cfgGet "links" $link_id "mirror"]
}

#****f* linkcfg.tcl/setLinkMirror
# NAME
#   setLinkMirror -- set link's mirror link
# SYNOPSIS
#   setLinkMirror $link_id $mirror
# FUNCTION
#   Sets the value of the link's mirror link. Mirror link is the other part of
#   the link connecting node to a pseudo node. Two mirror links present only
#   one physical link.
# INPUTS
#   * link_id -- link id
#   * mirror -- mirror link's id
#****
proc setLinkMirror { link_id mirror } {
    cfgSet "links" $link_id "mirror" $mirror
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
    lassign $orig_ifaces orig_node1_iface orig_node2_iface

    # create pseudo link by duplicating the original
    set pseudo_link_id [newObjectId "link"]
    cfgSet "links" $pseudo_link_id [cfgGet "links" $orig_link_id]
    lappendToRunning "link_list" $pseudo_link_id
    set links "$orig_link_id $pseudo_link_id"

    # create pseudo nodes
    set pseudo_nodes [newNode "pseudo"]
    lappend pseudo_nodes [newNode "pseudo"]

    foreach pseudo_node_id $pseudo_nodes orig_node_id $orig_nodes orig_node_iface $orig_ifaces link_id $links {
	# change peer for original node interface
	setIfcLink $orig_node_id $orig_node_iface $link_id

	# setup new pseudo node properties
	set other_orig_node_id [removeFromList $orig_nodes $orig_node_id 1]
	setNodeMirror $pseudo_node_id [removeFromList $pseudo_nodes $pseudo_node_id 1]
	setNodeCanvas $pseudo_node_id [getNodeCanvas $orig_node_id]
	setNodeCoords $pseudo_node_id [getNodeCoords $other_orig_node_id]
	setNodeLabelCoords $pseudo_node_id [getNodeCoords $other_orig_node_id]
	setIfcLink $pseudo_node_id "0" $link_id

	# setup both link properties
	setLinkPeers $link_id "$pseudo_node_id $orig_node_id"
	setLinkPeersIfaces $link_id "0 $orig_node_iface"
	setLinkMirror $link_id [removeFromList $links $link_id 1]
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

    # recycle the first pseudo link ID
    lassign [lsort "$link_id $mirror_link_id"] link_id mirror_link_id

    lassign [getLinkPeers $link_id] pseudo_node1 orig_node1
    lassign [getLinkPeers $mirror_link_id] pseudo_node2 orig_node2

    if { $orig_node1 == $orig_node2 } {
	return
    }

    lassign [getLinkPeersIfaces $link_id] - orig_node1_iface
    lassign [getLinkPeersIfaces $mirror_link_id] - orig_node2_iface

    setIfcLink $orig_node1 $orig_node1_iface $link_id
    setIfcLink $orig_node2 $orig_node2_iface $link_id

    setLinkMirror $link_id ""
    setLinkPeers $link_id "$orig_node1 $orig_node2"
    setLinkPeersIfaces $link_id "$orig_node1_iface $orig_node2_iface"

    setToRunning "node_list" [removeFromList [getFromRunning "node_list"] "$pseudo_node1 $pseudo_node2"]
    cfgUnset "nodes" $pseudo_node1
    cfgUnset "nodes" $pseudo_node2

    setToRunning "link_list" [removeFromList [getFromRunning "link_list"] $mirror_link_id]
    cfgUnset "links" $mirror_link_id

    return $link_id
}

#****f* linkcfg.tcl/numOfLinks
# NAME
#   numOfLinks -- returns the number of links on a node
# SYNOPSIS
#   set totalLinks [numOfLinks $node]
# FUNCTION
#   Counts and returns the total number of links connected to a node.
# INPUTS
#   * node -- node id
# RESULT
#   * totalLinks -- a number of links.
#****
proc numOfLinks { node_id } {
    set num 0
    foreach {iface iface_cfg} [cfgGet "nodes" $node_id "ifaces"] {
	catch { dictGet $iface_cfg "link" } link_id
	if { $link_id != "" } {
	    incr num
	}
    }

    return $num
}

#****f* linkcfg.tcl/newLink
# NAME
#   newLink -- create new link
# SYNOPSIS
#   set new_link_id [newLink $node1 $node2]
# FUNCTION
#   Creates a new link between nodes node1 and node2. The order of nodes is
#   irrelevant.
# INPUTS
#   * node1 -- node id of the peer node
#   * node2 -- node id of the second peer node
# RESULT
#   * new_link_id -- new link id.
#****
proc newLink { node1_id node2_id } {
    return [newLinkWithIfaces $node1_id "" $node2_id ""]
}

proc newLinkWithIfaces { node1_id iface1_id node2_id iface2_id } {
    global defEthBandwidth defSerBandwidth defSerDelay

    set config_iface1 0
    if { $iface1_id == "" } {
	set config_iface1 1
	set iface1_id [newIface $node1_id "phys" 0]
    }

    set config_iface2 0
    if { $iface2_id == "" } {
	set config_iface2 1
	set iface2_id [newIface $node2_id "phys" 0]
    }

    foreach node_id "$node1_id $node2_id" iface "$iface1_id $iface2_id" {
	# iface already connected to a link
	if { [getNodeIface $node_id $iface] == "" } {
	    after idle {.dialog1.msg configure -wraplength 4i}
	    tk_dialog .dialog1 "IMUNES warning" \
		"Warning: Interface '$iface' on node '$node_id' does not exist" \
		info 0 Dismiss

	    return
	}

	if { [getIfcLink $node_id $iface] != "" } {
	    after idle {.dialog1.msg configure -wraplength 4i}
	    tk_dialog .dialog1 "IMUNES warning" \
		"Warning: Interface $iface already connected to a link" \
		info 0 Dismiss

	    return
	}

	set type [getNodeType $node_id]
	if { $type == "pseudo" } {
	    return
	}

	if { [info procs $type.maxLinks] != "" } {
	    if { [ numOfLinks $node_id ] == [$type.maxLinks] } {
		after idle {.dialog1.msg configure -wraplength 4i}
		tk_dialog .dialog1 "IMUNES warning" \
		   "Warning: Maximum links connected to the node $node_id" \
		   info 0 Dismiss

		return
	    }
	}
    }

    set link_id [newObjectIdAlt [getFromRunning "link_list"] "l"]

    setIfcLink $node1_id $iface1_id $link_id
    setIfcLink $node2_id $iface2_id $link_id

    setLinkPeers $link_id "$node1_id $node2_id"
    setLinkPeersIfaces $link_id "$iface1_id $iface2_id"
    lappendToRunning "link_list" $link_id

    if { $config_iface1 && [info procs [getNodeType $node1_id].confNewIfc] != "" } {
	[getNodeType $node1_id].confNewIfc $node1_id $iface1_id
    }

    if { $config_iface2 && [info procs [getNodeType $node2_id].confNewIfc] != "" } {
	[getNodeType $node2_id].confNewIfc $node2_id $iface2_id
    }

    return $link_id
}

proc getLinkPeers { link_id } {
    return [cfgGet "links" $link_id "peers"]
}

#****f* linkcfg.tcl/linkDirection
# NAME
#   linkByIfg -- get direction of link in regards to the node's interface
# SYNOPSIS
#   set link [linkDirection $node_id $iface]
# FUNCTION
#   Returns the direction of the link connecting the node's interface.
# INPUTS
#   * node_id -- node id
#   * iface -- interface
# RESULT
#   * direction -- upstream/downstream
#****
proc linkDirection { node_id iface } {
    set link_id [getIfcLink $node_id $iface]

    set direction upstream
    if { $node_id == [lindex [getLinkPeers $link_id] 0] } {
	set direction downstream
    }

    return $direction
}

proc setLinkPeers { link_id peers } {
    cfgSet "links" $link_id "peers" $peers
}

proc getLinkPeersIfaces { link_id } {
    return [cfgGet "links" $link_id "peers_ifaces"]
}

proc setLinkPeersIfaces { link_id peers_ifaces } {
    cfgSet "links" $link_id "peers_ifaces" $peers_ifaces
}
