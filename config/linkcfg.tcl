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
# getLinkPeers { link_id }
#	Returns nodes of link endpoints
#
# linksByPeers { node1 node2 }
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

#****f* linkcfg.tcl/linksByPeers
# NAME
#   linksByPeers -- get link id from peer nodes
# SYNOPSIS
#   set link_id [linksByPeers $node1_id $node2_id]
# FUNCTION
#   Returns links whose peers are node1 and node2.
#   The order of input nodes is irrelevant.
# INPUTS
#   * node1_id -- node id of the first node
#   * node2_id -- node id of the second node
# RESULT
#   * link_ids -- returns ids of links connecting endpoints node1 and node2
#****
proc linksByPeers { node1_id node2_id } {
    upvar 0 ::cf::[set ::curcfg]::link_list link_list

    set link_ids {}
    foreach link_id $link_list {
	set peers [getLinkPeers $link_id]
	if { $peers == "$node1_id $node2_id" || $peers == "$node2_id $node1_id" } {
	    lappend link_ids $link_id
	}
    }

    return $link_ids
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
proc removeLink { link_id } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    upvar 0 ::cf::[set ::curcfg]::link_list link_list
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id
    upvar 0 ::cf::[set ::curcfg]::IPv4UsedList IPv4UsedList
    upvar 0 ::cf::[set ::curcfg]::IPv6UsedList IPv6UsedList
    upvar 0 ::cf::[set ::curcfg]::MACUsedList MACUsedList

    set pnodes [getLinkPeers $link_id]
    foreach node_id $pnodes iface_id [getLinkPeersIfaces $link_id] {
	upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

	set peer_id [removeFromList $pnodes $node_id "keep_doubles"]

	if { [getNodeType $node_id] in "extelem" } {
	    set old [getNodeStolenIfaces $node_id]
	    set idx [lsearch -exact -index 0 $old "$iface_id"]
	    setNodeStolenIfaces $node_id [lreplace $old $idx $idx]
	    set i [lsearch [set $node_id] "interface-peer {$iface_id $peer_id}"]
	    set $node_id [lreplace [set $node_id] $i $i]
	    continue
	}

	set IPv4UsedList [removeFromList $IPv4UsedList [getIfcIPv4addrs $node_id $iface_id] "keep_doubles"]
	set IPv6UsedList [removeFromList $IPv6UsedList [getIfcIPv6addrs $node_id $iface_id] "keep_doubles"]
	set MACUsedList [removeFromList $MACUsedList [getIfcMACaddr $node_id $iface_id] "keep_doubles"]
	netconfClearSection $node_id "interface $iface_id"
	set i [lsearch [set $node_id] "interface-peer {$iface_id $peer_id}"]
	set $node_id [lreplace [set $node_id] $i $i]
	foreach lifc [logIfcList $node_id] {
	    switch -exact [getLogIfcType $node_id $lifc] {
		vlan {
		    if { [getIfcVlanDev $node_id $lifc] == $iface_id } {
			netconfClearSection $node_id "interface $lifc"
		    }
		}
	    }
	}
    }

    set mirror_link_id [getLinkMirror $link_id]
    if { $mirror_link_id != "" } {
	setLinkMirror $mirror_link_id ""
	removeLink $mirror_link_id
    }

    foreach node_id $pnodes {
	if { [getNodeType $node_id] == "pseudo" } {
	    set node_list [removeFromList $node_list $node_id]
	}
    }

    set link_list [removeFromList $link_list $link_id]
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    set entry [lsearch -inline [set $link_id] "direct *"]
    if { $entry == "" } {
	return 0
    }

    return [lindex $entry 1]
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    set i [lsearch [set $link_id] "direct *"]
    if { $direct == 0 } {
	set $link_id [lreplace [set $link_id] $i $i]
    } else {
	set $link_id [lreplace [set $link_id] $i $i "direct $direct"]
    }

    set mirror_link_id [getLinkMirror $link_id]
    if { $mirror_link_id != "" } {
	upvar 0 ::cf::[set ::curcfg]::$mirror_link_id $mirror_link_id

	set i [lsearch [set $mirror_link_id] "direct *"]
	if { $value == 0 } {
	    set $mirror_link_id [lreplace [set $mirror_link_id] $i $i]
	} else {
	    set $mirror_link_id [lreplace [set $mirror_link_id] $i $i "direct $value"]
	}
    }
}

#****f* linkcfg.tcl/getLinkPeers
# NAME
#   getLinkPeers -- get link's peer nodes
# SYNOPSIS
#   set link_peers [getLinkPeers $link_id]
# FUNCTION
#   Returns nodes of link endpoints.
# INPUTS
#   * link_id -- link id
# RESULT
#   * link_peers -- returns nodes of a link endpoints in a list {node1_id node2_id}
#****
proc getLinkPeers { link_id } {
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    set entry [lsearch -inline [set $link_id] "nodes {*}"]

    return [lindex $entry 1]
}

#****f* linkcfg.tcl/setLinkPeers
# NAME
#   setLinkPeers -- set link's peer nodes
# SYNOPSIS
#   setLinkPeers $link_id $peers
# FUNCTION
#   Sets nodes of link endpoints.
# INPUTS
#   * link_id -- link id
#   * peers -- nodes of a link endpoints as a list {node1_id node2_id}
#****
proc setLinkPeers { link_id peers } {
}

#****f* linkcfg.tcl/getLinkPeersIfaces
# NAME
#   getLinkPeersIfaces -- get link's peer interfaces
# SYNOPSIS
#   set link_ifaces [getLinkPeersIfaces $link_id]
# FUNCTION
#   Returns ifaces of link endpoints.
# INPUTS
#   * link_id -- link id
# RESULT
#   * link_ifaces -- returns interfaces of a link endpoints in a list {iface1_id iface2_id}
#****
proc getLinkPeersIfaces { link_id } {
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    set entry [lsearch -inline [set $link_id] "ifaces {*}"]
    return [lindex $entry 1]
}

#****f* linkcfg.tcl/setLinkPeersIfaces
# NAME
#   setLinkPeersIfaces -- set link's peer interfaces
# SYNOPSIS
#   setLinkPeersIfaces $link_id $peers_ifaces
# FUNCTION
#   Sets interfaces of link endpoints.
# INPUTS
#   * link_id -- link id
#   * peers_ifaces -- interfaces of a link endpoints as a list {iface1_id iface2_id}
#****
proc setLinkPeersIfaces { link_id peers_ifaces } {
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    set entry [lsearch -inline [set $link_id] "bandwidth *"]

    return [lindex $entry 1]
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    set i [lsearch [set $link_id] "bandwidth *"]
    if { $bandwidth <= 0 } {
	set $link_id [lreplace [set $link_id] $i $i]
    } else {
	set $link_id [lreplace [set $link_id] $i $i "bandwidth $bandwidth"]
    }

    set mirror_link_id [getLinkMirror $link_id]
    if { $mirror_link_id != "" } {
	upvar 0 ::cf::[set ::curcfg]::$mirror_link_id $mirror_link_id

	set i [lsearch [set $mirror_link_id] "bandwidth *"]
	if { $value <= 0 } {
	    set $mirror_link_id [lreplace [set $mirror_link_id] $i $i]
	} else {
	    set $mirror_link_id [lreplace [set $mirror_link_id] $i $i "bandwidth $value"]
	}
    }
}


#****f* linkcfg.tcl/getLinkColor
# NAME
#   getLinkColor -- get link color
# SYNOPSIS
#   getLinkColor $link_id
# FUNCTION
#   Returns the color of the link.
# INPUTS
#   * link_id -- link id
# RESULT
#   * color -- link color
#****
proc getLinkColor { link_id } {
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id
    global defLinkColor

    set entry [lsearch -inline [set $link_id] "color *"]
    if { $entry == "" } {
	return $defLinkColor
    }

    return [lindex $entry 1]
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    set i [lsearch [set $link_id] "color *"]
    set $link_id [lreplace [set $link_id] $i $i "color $color"]
}

#****f* linkcfg.tcl/getLinkWidth
# NAME
#   getLinkWidth -- get link width
# SYNOPSIS
#   getLinkWidth $link_id
# FUNCTION
#   Returns the link width on canvas.
# INPUTS
#   * link_id -- link id
#****
proc getLinkWidth { link_id } {
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id
    global defLinkWidth

    set entry [lsearch -inline [set $link_id] "width *"]
    if { $entry == "" } {
	return $defLinkWidth
    }

    return [lindex $entry 1]
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    set i [lsearch [set $link_id] "width *"]
    set $link_id [lreplace [set $link_id] $i $i "width $width"]
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    set entry [lsearch -inline [set $link_id] "delay *"]

    return [lindex $entry 1]
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    set delay [getLinkDelay $link_id]
    if { "$delay" != "" } {
	if { $delay >= 10000 } {
	    set delstr "[expr {$delay / 1000}] ms"
	} elseif { $delay >= 1000 } {
	    set delstr "[format "%.3f" [expr {$delay * .001}]] ms"
	} else {
	    set delstr "$delay us"
	}
    } else {
	set delstr ""
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    set i [lsearch [set $link_id] "delay *"]
    if { $delay <= 0 } {
	set $link_id [lreplace [set $link_id] $i $i]
    } else {
	set $link_id [lreplace [set $link_id] $i $i "delay $delay"]
    }

    set mirror_link_id [getLinkMirror $link_id]
    if { $mirror_link_id != "" } {
	upvar 0 ::cf::[set ::curcfg]::$mirror_link_id $mirror_link_id

	set i [lsearch [set $mirror_link_id] "delay *"]
	if { $value <= 0 } {
	    set $mirror_link_id [lreplace [set $mirror_link_id] $i $i]
	} else {
	    set $mirror_link_id [lreplace [set $mirror_link_id] $i $i "delay $value"]
	}
    }
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    return [lindex [lsearch -inline [set $link_id] "jitter-upstream *"] 1]
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    set i [lsearch [set $link_id] "jitter-upstream *"]
    if { $jitter_upstream == "" } {
	set $link_id [lreplace [set $link_id] $i $i]
    } else {
	set $link_id [lreplace [set $link_id] $i $i "jitter-upstream {$jitter_upstream}"]
    }

    set mirror_link_id [getLinkMirror $link_id]
    if { $mirror_link_id != "" } {
	upvar 0 ::cf::[set ::curcfg]::$mirror_link_id $mirror_link_id

	set i [lsearch [set $mirror_link_id] "jitter-upstream *"]
	if { $values == "" } {
	    set $mirror_link_id [lreplace [set $mirror_link_id] $i $i]
	} else {
	    set $mirror_link_id [lreplace [set $mirror_link_id] $i $i "jitter-upstream {$values}"]
	}
    }
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    return [lindex [lsearch -inline [set $link_id] "jitter-upstream-mode *"] 1]
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    set i [lsearch [set $link_id] "jitter-upstream-mode *"]
    if { $jitter_upstream_mode == "" } {
	set $link_id [lreplace [set $link_id] $i $i]
    } else {
	set $link_id [lreplace [set $link_id] $i $i "jitter-upstream-mode $jitter_upstream_mode"]
    }

    set mirror_link_id [getLinkMirror $link_id]
    if { $mirror_link_id != "" } {
	upvar 0 ::cf::[set ::curcfg]::$mirror_link_id $mirror_link_id

	set i [lsearch [set $mirror_link_id] "jitter-upstream-mode *"]
	if { $value == "" } {
	    set $mirror_link_id [lreplace [set $mirror_link_id] $i $i]
	} else {
	    set $mirror_link_id [lreplace [set $mirror_link_id] $i $i "jitter-upstream-mode $value"]
	}
    }
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    return [lindex [lsearch -inline [set $link_id] "jitter-upstream-hold *"] 1]
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    set i [lsearch [set $link_id] "jitter-upstream-hold *"]
    if { $jitter_upstream_hold == "" } {
	set $link_id [lreplace [set $link_id] $i $i]
    } else {
	set $link_id [lreplace [set $link_id] $i $i "jitter-upstream-hold $jitter_upstream_hold"]
    }

    set mirror_link_id [getLinkMirror $link_id]
    if { $mirror_link_id != "" } {
	upvar 0 ::cf::[set ::curcfg]::$mirror_link_id $mirror_link_id

	set i [lsearch [set $mirror_link_id] "jitter-upstream-hold *"]
	if { $value == "" } {
	    set $mirror_link_id [lreplace [set $mirror_link_id] $i $i]
	} else {
	    set $mirror_link_id [lreplace [set $mirror_link_id] $i $i "jitter-upstream-hold $value"]
	}
    }
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    return [lindex [lsearch -inline [set $link_id] "jitter-downstream *"] 1]
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    set i [lsearch [set $link_id] "jitter-downstream *"]
    if { $jitter_downstream == "" } {
	set $link_id [lreplace [set $link_id] $i $i]
    } else {
	set $link_id [lreplace [set $link_id] $i $i "jitter-downstream {$jitter_downstream}"]
    }

    set mirror_link_id [getLinkMirror $link_id]
    if { $mirror_link_id != "" } {
	upvar 0 ::cf::[set ::curcfg]::$mirror_link_id $mirror_link_id

	set i [lsearch [set $mirror_link_id] "jitter-downstream *"]
	if { $values == "" } {
	    set $mirror_link_id [lreplace [set $mirror_link_id] $i $i]
	} else {
	    set $mirror_link_id [lreplace [set $mirror_link_id] $i $i "jitter-downstream {$values}"]
	}
    }
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    return [lindex [lsearch -inline [set $link_id] "jitter-downstream-mode *"] 1]
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    set i [lsearch [set $link_id] "jitter-downstream-mode *"]
    if { $jitter_downstream_mode  == "" } {
	set $link_id [lreplace [set $link_id] $i $i]
    } else {
	set $link_id [lreplace [set $link_id] $i $i "jitter-downstream-mode $jitter_downstream_mode"]
    }

    set mirror_link_id [getLinkMirror $link_id]
    if { $mirror_link_id != "" } {
	upvar 0 ::cf::[set ::curcfg]::$mirror_link_id $mirror_link_id

	set i [lsearch [set $mirror_link_id] "jitter-downstream-mode *"]
	if { $value  == "" } {
	    set $mirror_link_id [lreplace [set $mirror_link_id] $i $i]
	} else {
	    set $mirror_link_id [lreplace [set $mirror_link_id] $i $i "jitter-downstream-mode $value"]
	}
    }
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    return [lindex [lsearch -inline [set $link_id] "jitter-downstream-hold *"] 1]
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    set i [lsearch [set $link_id] "jitter-downstream-hold *"]
    if { $jitter_downstream_hold == "" } {
	set $link_id [lreplace [set $link_id] $i $i]
    } else {
	set $link_id [lreplace [set $link_id] $i $i "jitter-downstream-hold $jitter_downstream_hold"]
    }

    set mirror_link_id [getLinkMirror $link_id]
    if { $mirror_link_id != "" } {
	upvar 0 ::cf::[set ::curcfg]::$mirror_link_id $mirror_link_id

	set i [lsearch [set $mirror_link_imirror_link_id] "jitter-downstream-hold *"]
	if { $value == "" } {
	    set $mirror_link_id [lreplace [set $mirror_link_id] $i $i]
	} else {
	    set $mirror_link_id [lreplace [set $mirror_link_id] $i $i "jitter-downstream-hold $value"]
	}
    }
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    set entry [lsearch -inline [set $link_id] "ber *"]

    return [lindex $entry 1]
}

#****f* linkcfg.tcl/setLinkBER
# NAME
#   setLinkBER -- set link BER
# SYNOPSIS
#   setLinkBER $link_id $ber
# FUNCTION
#   Sets the BER value of the link.
# INPUTS
#   * link_id -- link id
#   * ber -- The value of 1/BER of the link.
#****
proc setLinkBER { link_id ber } {
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    set i [lsearch [set $link_id] "ber *"]
    if { $ber <= 0 } {
	set $link_id [lreplace [set $link_id] $i $i]
    } else {
	set $link_id [lreplace [set $link_id] $i $i "ber $ber"]
    }

    set mirror_link_id [getLinkMirror $link_id]
    if { $mirror_link_id != "" } {
	upvar 0 ::cf::[set ::curcfg]::$mirror_link_id $mirror_link_id

	set i [lsearch [set $mirror_link_id] "ber *"]
	if { $value <= 0 } {
	    set $mirror_link_id [lreplace [set $mirror_link_id] $i $i]
	} else {
	    set $mirror_link_id [lreplace [set $mirror_link_id] $i $i "ber $value"]
	}
    }
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    set entry [lsearch -inline [set $link_id] "loss *"]

    return [lindex $entry 1]
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    set i [lsearch [set $link_id] "loss *"]
    if { $loss <= 0 } {
	set $link_id [lreplace [set $link_id] $i $i]
    } else {
	set $link_id [lreplace [set $link_id] $i $i "loss $loss"]
    }

    set mirror_link_id [getLinkMirror $link_id]
    if { $mirror_link_id != "" } {
	upvar 0 ::cf::[set ::curcfg]::$mirror_link_id $mirror_link_id

	set i [lsearch [set $mirror_link_id] "loss *"]
	if { $value <= 0 } {
	    set $mirror_link_id [lreplace [set $mirror_link_id] $i $i]
	} else {
	    set $mirror_link_id [lreplace [set $mirror_link_id] $i $i "loss $value"]
	}
    }
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    set entry [lsearch -inline [set $link_id] "duplicate *"]

    return [lindex $entry 1]
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    set i [lsearch [set $link_id] "duplicate *"]
    if { $duplicate <= 0 || $duplicate > 50 } {
	set $link_id [lreplace [set $link_id] $i $i]
    } else {
	set $link_id [lreplace [set $link_id] $i $i "duplicate $duplicate"]
    }

    set mirror_link_id [getLinkMirror $link_id]
    if { $mirror_link_id != "" } {
	upvar 0 ::cf::[set ::curcfg]::$mirror_link_id $mirror_link_id

	set i [lsearch [set $mirror_link_id] "duplicate *"]
	if { $value <= 0 } {
	    set $mirror_link_id [lreplace [set $mirror_link_id] $i $i]
	} else {
	    set $mirror_link_id [lreplace [set $mirror_link_id] $i $i "duplicate $value"]
	}
    }
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
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode

    setLinkBandwidth $link_id ""
    setLinkBER $link_id ""
    setLinkLoss $link_id ""
    setLinkDelay $link_id ""
    setLinkDup $link_id ""

    if { $oper_mode == "exec" } {
	upvar 0 ::cf::[set ::curcfg]::eid eid
	execSetLinkParams $eid $link_id
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    set entry [lsearch -inline [set $link_id] "mirror *"]

    return [lindex $entry 1]
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
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id

    set i [lsearch [set $link_id] "mirror *"]
    if { $mirror == "" } {
	set $link_id [lreplace [set $link_id] $i $i]
    } else {
	set $link_id [lreplace [set $link_id] $i $i "mirror $mirror"]
    }
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
    upvar 0 ::cf::[set ::curcfg]::link_list link_list
    upvar 0 ::cf::[set ::curcfg]::$orig_link_id $orig_link_id

    set orig_nodes [getLinkPeers $orig_link_id]
    lassign $orig_nodes orig_node1_id orig_node2_id
    upvar 0 ::cf::[set ::curcfg]::$orig_node1_id $orig_node1_id
    upvar 0 ::cf::[set ::curcfg]::$orig_node2_id $orig_node2_id

    set orig_ifaces [getLinkPeersIfaces $orig_link_id]

    # create mirror link and copy the properties from the original
    set mirror_link_id [newObjectId $link_list "l"]
    upvar 0 ::cf::[set ::curcfg]::$mirror_link_id $mirror_link_id
    set $mirror_link_id [set $orig_link_id]
    lappend link_list $mirror_link_id
    set links "$orig_link_id $mirror_link_id"

    # create pseudo nodes
    set new_node1_id [newNode "pseudo"]
    set new_node2_id [newNode "pseudo"]
    upvar 0 ::cf::[set ::curcfg]::$new_node1_id $new_node1_id
    upvar 0 ::cf::[set ::curcfg]::$new_node2_id $new_node2_id
    set pseudo_nodes "$new_node1_id $new_node2_id"

    foreach orig_node_id $orig_nodes orig_node_iface_id $orig_ifaces pseudo_node_id $pseudo_nodes link_id $links {
	set other_orig_node_id [removeFromList $orig_nodes $orig_node_id "keep_doubles"]

	# change peer for original node interface
	set i [lsearch [set $orig_node_id] "interface-peer {$orig_node_iface_id $other_orig_node_id}"]
	set $orig_node_id [lreplace [set $orig_node_id] $i $i \
	    "interface-peer {$orig_node_iface_id $pseudo_node_id}"]

	# setup new pseudo node properties
	setNodeMirror $pseudo_node_id [removeFromList $pseudo_nodes $pseudo_node_id "keep_doubles"]
	setNodeCanvas $pseudo_node_id [getNodeCanvas $orig_node_id]
	setNodeCoords $pseudo_node_id [getNodeCoords $other_orig_node_id]
	setNodeLabelCoords $pseudo_node_id [getNodeCoords $other_orig_node_id]

	# setup both link properties
	lappend $pseudo_node_id "interface-peer {0 $orig_node_id}"
	set i [lsearch [set $link_id] "nodes *"]
	set $link_id [lreplace [set $link_id] $i $i \
	    "nodes {$orig_node_id $pseudo_node_id}"]
	set i [lsearch [set $link_id] "ifaces *"]
	set $link_id [lreplace [set $link_id] $i $i \
	    "ifaces {$orig_node_iface_id 0}"]
	setLinkMirror $link_id [removeFromList $links $link_id "keep_doubles"]
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
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    upvar 0 ::cf::[set ::curcfg]::link_list link_list

    set mirror_link_id [getLinkMirror $link_id]
    if { $mirror_link_id == "" } {
	return
    }

    # recycle the first pseudo link ID
    lassign [lsort "$link_id $mirror_link_id"] link_id mirror_link_id

    lassign [getLinkPeers $link_id] orig_node1_id pseudo_node1_id
    lassign [getLinkPeers $mirror_link_id] orig_node2_id pseudo_node2_id

    if { $orig_node1_id == $orig_node2_id } {
	return
    }

    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id
    upvar 0 ::cf::[set ::curcfg]::$mirror_link_id $mirror_link_id
    upvar 0 ::cf::[set ::curcfg]::$orig_node1_id $orig_node1_id
    upvar 0 ::cf::[set ::curcfg]::$orig_node2_id $orig_node2_id

    lassign [getLinkPeersIfaces $link_id] orig_node1_iface -
    lassign [getLinkPeersIfaces $mirror_link_id] orig_node2_iface -

    set i [lsearch [set $orig_node1_id] "interface-peer {$orig_node1_iface_id $pseudo_node1_id}"]
    set $orig_node1_id [lreplace [set $orig_node1_id] $i $i \
			"interface-peer {$orig_node1_iface_id $orig_node2_id}"]
    set i [lsearch [set $orig_node2_id] "interface-peer {$orig_node2_iface_id $pseudo_node2_id}"]
    set $orig_node2_id [lreplace [set $orig_node2_id] $i $i \
			"interface-peer {$orig_node2_iface_id $orig_node1_id}"]

    set i [lsearch [set $link_id] "nodes *"]
    set $link_id [lreplace [set $link_id] $i $i \
			"nodes {$orig_node1_id $orig_node2_id}"]
    set i [lsearch [set $link_id] "ifaces *"]
    set $link_id [lreplace [set $link_id] $i $i \
			"ifaces {$orig_node1_iface_id $orig_node2_iface_id}"]

    setLinkMirror $link_id ""

    set node_list [removeFromList $node_list "$pseudo_node1_id $pseudo_node2_id"]
    set link_list [removeFromList $link_list $mirror_link_id]

    return $link_id
}

#****f* linkcfg.tcl/numOfLinks
# NAME
#   numOfLinks -- returns the number of links on a node
# SYNOPSIS
#   set totalLinks [numOfLinks $node_id]
# FUNCTION
#   Counts and returns the total number of links connected to a node.
# INPUTS
#   * node_id -- node id
# RESULT
#   * totalLinks -- a number of links.
#****
proc numOfLinks { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    return [llength [lsearch -all [set $node_id] "interface-peer*"]]
}

#****f* linkcfg.tcl/newLink
# NAME
#   newLink -- create new link
# SYNOPSIS
#   set new_link_id [newLink $node1_id $node2_id]
# FUNCTION
#   Creates a new link between nodes node1 and node2. The order of nodes is
#   irrelevant.
# INPUTS
#   * node1_id -- node id of the peer node
#   * node2_id -- node id of the second peer node
# RESULT
#   * new_link_id -- new link id.
#****
proc newLink { node1_id node2_id } {
    upvar 0 ::cf::[set ::curcfg]::link_list link_list
    upvar 0 ::cf::[set ::curcfg]::$node1_id $node1_id
    upvar 0 ::cf::[set ::curcfg]::$node2_id $node2_id
    global defEthBandwidth defSerBandwidth defSerDelay

    foreach node_id "$node1_id $node2_id" {
	set type [getNodeType $node_id]
	if { $type == "pseudo" } {
	    return
	}

	if { [info procs $type.maxLinks] != "" } {
	    if { [numOfLinks $node_id] == [$type.maxLinks] } {
		tk_dialog .dialog1 "IMUNES warning" \
		   "Warning: Maximum links connected to the node $node_id" \
		   info 0 Dismiss

		return
	    }
	}
    }

    set link_id [newObjectId $link_list "l"]
    upvar 0 ::cf::[set ::curcfg]::$link_id $link_id
    set $link_id {}

    set ifname1 [chooseIfName $node1_id $node2_id]
    lappend $node1_id "interface-peer {$ifname1 $node2_id}"
    set ifname2 [chooseIfName $node2_id $node1_id]
    lappend $node2_id "interface-peer {$ifname2 $node1_id}"

    lappend $link_id "nodes {$node1_id $node2_id}"
    lappend $link_id "ifaces {$ifname1 $ifname2}"
    if { ([getNodeType $node1_id] == "lanswitch" || \
	[getNodeType $node2_id] == "lanswitch" || \
	[string first eth "$ifname1 $ifname2"] != -1) && \
	[getNodeType $node1_id] != "rj45" && \
	[getNodeType $node2_id] != "rj45" &&
	$defEthBandwidth != 0 } {

	lappend $link_id "bandwidth $defEthBandwidth"
    } elseif { [string first ser "$ifname1 $ifname2"] != -1 } {
	lappend $link_id "bandwidth $defSerBandwidth"
	lappend $link_id "delay $defSerDelay"
    }

    lappend link_list $link_id

    if { [info procs [getNodeType $node1_id].confNewIfc] != "" } {
	[getNodeType $node1_id].confNewIfc $node1_id $ifname1
    }

    if { [info procs [getNodeType $node2_id].confNewIfc] != "" } {
	[getNodeType $node2_id].confNewIfc $node2_id $ifname2
    }

    return $link_id
}

#****f* linkcfg.tcl/linkDirection
# NAME
#   linkByIfg -- get direction of link in regards to the node's interface
# SYNOPSIS
#   set link [linkDirection $node_id $iface_id]
# FUNCTION
#   Returns the direction of the link connecting the node's interface.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface
# RESULT
#   * direction -- upstream/downstream
#****
proc linkDirection { node_id iface_id } {
    set link_id [getIfcLink $node_id $iface_id]

    if { $node_id == [lindex [getLinkPeers $link_id] 0] } {
	set direction downstream
    } else {
	set direction upstream
    }

    return $direction
}
