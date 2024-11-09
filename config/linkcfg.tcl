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
# getLinkPeers { link }
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
#   set link_id [linksByPeers $node1 $node2]
# FUNCTION
#   Returns links whose peers are node1 and node2.
#   The order of input nodes is irrelevant.
# INPUTS
#   * node1 -- node id of the first node
#   * node2 -- node id of the second node
# RESULT
#   * links -- returns ids of links connecting endpoints node1 and node2
#****
proc linksByPeers { node1 node2 } {
    upvar 0 ::cf::[set ::curcfg]::link_list link_list

    set links {}
    foreach link $link_list {
	set peers [getLinkPeers $link]
	if { $peers == "$node1 $node2" || $peers == "$node2 $node1" } {
	    lappend links $link
	}
    }

    return $links
}

#****f* linkcfg.tcl/removeLink
# NAME
#   removeLink -- removes a link.
# SYNOPSIS
#   removeLink $link
# FUNCTION
#   Removes the link and related entries in peering node's configs.
#   Updates the default route for peer nodes.
# INPUTS
#   * link -- link id
#****
proc removeLink { link } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    upvar 0 ::cf::[set ::curcfg]::link_list link_list
    upvar 0 ::cf::[set ::curcfg]::$link $link
    upvar 0 ::cf::[set ::curcfg]::IPv4UsedList IPv4UsedList
    upvar 0 ::cf::[set ::curcfg]::IPv6UsedList IPv6UsedList
    upvar 0 ::cf::[set ::curcfg]::MACUsedList MACUsedList

    set pnodes [getLinkPeers $link]
    set pifaces [getLinkPeersIfaces $link]
    foreach node $pnodes ifc $pifaces {
	upvar 0 ::cf::[set ::curcfg]::$node $node

	set peer [removeFromList $pnodes $node "keep_doubles"]

	if { [getNodeType $node] in "extelem"} {
	    set old [getNodeStolenIfaces $node]
	    set idx [lsearch -exact -index 0 $old "$ifc"]
	    setNodeStolenIfaces $node [lreplace $old $idx $idx]
	    set i [lsearch [set $node] "interface-peer {$ifc $peer}"]
	    set $node [lreplace [set $node] $i $i]
	    continue
	}

	set IPv4UsedList [removeFromList $IPv4UsedList [getIfcIPv4addrs $node $ifc] "keep_doubles"]
	set IPv6UsedList [removeFromList $IPv6UsedList [getIfcIPv6addrs $node $ifc] "keep_doubles"]
	set MACUsedList [removeFromList $MACUsedList [getIfcMACaddr $node $ifc] "keep_doubles"]
	netconfClearSection $node "interface $ifc"
	set i [lsearch [set $node] "interface-peer {$ifc $peer}"]
	set $node [lreplace [set $node] $i $i]
	foreach lifc [logIfcList $node] {
	    switch -exact [getLogIfcType $node $lifc] {
		vlan {
		    if { [getIfcVlanDev $node $lifc] == $ifc } {
			netconfClearSection $node "interface $lifc"
		    }
		}
	    }
	}
    }

    set mirror_link_id [getLinkMirror $link]
    if { $mirror_link_id != "" } {
	setLinkMirror $mirror_link_id ""
	removeLink $mirror_link_id
    }

    foreach node_id $pnodes {
	if { [getNodeType $node_id] == "pseudo" } {
	    set node_list [removeFromList $node_list $node_id]
	}
    }

    set link_list [removeFromList $link_list $link]
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
proc getLinkDirect { link } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set entry [lsearch -inline [set $link] "direct *"]
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
proc setLinkDirect { link value } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set i [lsearch [set $link] "direct *"]
    if { $value == 0 } {
	set $link [lreplace [set $link] $i $i]
    } else {
	set $link [lreplace [set $link] $i $i "direct $value"]
    }

    set mirror_link_id [getLinkMirror $link]
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
#   set link_peers [getLinkPeers $link]
# FUNCTION
#   Returns nodes of link endpoints.
# INPUTS
#   * link -- link id
# RESULT
#   * link_peers -- returns nodes of a link endpoints in a list {node1 node2}
#****
proc getLinkPeers { link } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set entry [lsearch -inline [set $link] "nodes {*}"]

    return [lindex $entry 1]
}

#****f* linkcfg.tcl/getLinkPeersIfaces
# NAME
#   getLinkPeersIfaces -- get link's peer interfaces
# SYNOPSIS
#   set link_ifaces [getLinkPeersIfaces $link]
# FUNCTION
#   Returns ifaces of link endpoints.
# INPUTS
#   * link -- link id
# RESULT
#   * link_ifaces -- returns interfaces of a link endpoints in a list {iface1 iface2}
#****
proc getLinkPeersIfaces { link } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set entry [lsearch -inline [set $link] "ifaces {*}"]
    return [lindex $entry 1]
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
proc getLinkBandwidth { link } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set entry [lsearch -inline [set $link] "bandwidth *"]

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
proc getLinkBandwidthString { link } {
    set bandstr ""
    set bandwidth [getLinkBandwidth $link]
    if { $bandwidth > 0 } {
	if { $bandwidth >= 660000000 } {
	    set bandstr "[format %.2f [expr {$bandwidth / 1000000000.0}]] Gbps"
	} elseif { $bandwidth >= 99000000 } {
	    set bandstr "[format %d [expr {$bandwidth / 1000000}]] Mbps"
	} elseif { $bandwidth >= 9900000 } {
	    set bandstr "[format %.2f [expr {$bandwidth / 1000000.0}]] Mbps"
	} elseif { $bandwidth >= 990000 } {
	    set bandstr "[format %d [expr {$bandwidth / 1000}]] Kbps"
	} elseif { $bandwidth >= 9900 } {
	    set bandstr "[format %.2f [expr {$bandwidth / 1000.0}]] Kbps"
	} else {
	    set bandstr "$bandwidth bps"
	}
    }

    return $bandstr
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
proc setLinkBandwidth { link value } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set i [lsearch [set $link] "bandwidth *"]
    if { $value <= 0 } {
	set $link [lreplace [set $link] $i $i]
    } else {
	set $link [lreplace [set $link] $i $i "bandwidth $value"]
    }

    set mirror_link_id [getLinkMirror $link]
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
#   getLinkColor $link
# FUNCTION
#   Returns the color of the link.
# INPUTS
#   * link -- link id
# RESULT
#   * color -- link color
#****
proc getLinkColor { link } {
    upvar 0 ::cf::[set ::curcfg]::$link $link
    global defLinkColor

    set entry [lsearch -inline [set $link] "color *"]
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
proc setLinkColor { link value } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set i [lsearch [set $link] "color *"]
    set $link [lreplace [set $link] $i $i "color $value"]
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
proc getLinkWidth { link } {
    upvar 0 ::cf::[set ::curcfg]::$link $link
    global defLinkWidth

    set entry [lsearch -inline [set $link] "width *"]
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
proc setLinkWidth { link value } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set i [lsearch [set $link] "width *"]
    set $link [lreplace [set $link] $i $i "width $value"]
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
proc getLinkDelay { link } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set entry [lsearch -inline [set $link] "delay *"]

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
proc getLinkDelayString { link } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set delay [getLinkDelay $link]
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
proc setLinkDelay { link value } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set i [lsearch [set $link] "delay *"]
    if { $value <= 0 } {
	set $link [lreplace [set $link] $i $i]
    } else {
	set $link [lreplace [set $link] $i $i "delay $value"]
    }

    set mirror_link_id [getLinkMirror $link]
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
proc getLinkJitterUpstream { link } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    return [lindex [lsearch -inline [set $link] "jitter-upstream *"] 1]
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
proc setLinkJitterUpstream { link values } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set i [lsearch [set $link] "jitter-upstream *"]
    if { $values == "" } {
	set $link [lreplace [set $link] $i $i]
    } else {
	set $link [lreplace [set $link] $i $i "jitter-upstream {$values}"]
    }

    set mirror_link_id [getLinkMirror $link]
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
proc getLinkJitterModeUpstream { link } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    return [lindex [lsearch -inline [set $link] "jitter-upstream-mode *"] 1]
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
proc setLinkJitterModeUpstream { link value } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set i [lsearch [set $link] "jitter-upstream-mode *"]
    if { $value == "" } {
	set $link [lreplace [set $link] $i $i]
    } else {
	set $link [lreplace [set $link] $i $i "jitter-upstream-mode $value"]
    }

    set mirror_link_id [getLinkMirror $link]
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
proc getLinkJitterHoldUpstream { link } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    return [lindex [lsearch -inline [set $link] "jitter-upstream-hold *"] 1]
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
proc setLinkJitterHoldUpstream { link value } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set i [lsearch [set $link] "jitter-upstream-hold *"]
    if { $value == "" } {
	set $link [lreplace [set $link] $i $i]
    } else {
	set $link [lreplace [set $link] $i $i "jitter-upstream-hold $value"]
    }

    set mirror_link_id [getLinkMirror $link]
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
proc getLinkJitterDownstream { link } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    return [lindex [lsearch -inline [set $link] "jitter-downstream *"] 1]
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
proc setLinkJitterDownstream { link values } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set i [lsearch [set $link] "jitter-downstream *"]
    if { $values == "" } {
	set $link [lreplace [set $link] $i $i]
    } else {
	set $link [lreplace [set $link] $i $i "jitter-downstream {$values}"]
    }

    set mirror_link_id [getLinkMirror $link]
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
proc getLinkJitterModeDownstream { link } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    return [lindex [lsearch -inline [set $link] "jitter-downstream-mode *"] 1]
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
proc setLinkJitterModeDownstream { link value } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set i [lsearch [set $link] "jitter-downstream-mode *"]
    if { $value  == "" } {
	set $link [lreplace [set $link] $i $i]
    } else {
	set $link [lreplace [set $link] $i $i "jitter-downstream-mode $value"]
    }

    set mirror_link_id [getLinkMirror $link]
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
proc getLinkJitterHoldDownstream { link } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    return [lindex [lsearch -inline [set $link] "jitter-downstream-hold *"] 1]
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
proc setLinkJitterHoldDownstream { link value } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set i [lsearch [set $link] "jitter-downstream-hold *"]
    if { $value == "" } {
	set $link [lreplace [set $link] $i $i]
    } else {
	set $link [lreplace [set $link] $i $i "jitter-downstream-hold $value"]
    }

    set mirror_link_id [getLinkMirror $link]
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
proc getLinkBER { link } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set entry [lsearch -inline [set $link] "ber *"]

    return [lindex $entry 1]
}

#****f* linkcfg.tcl/setLinkBER
# NAME
#   setLinkBER -- set link BER
# SYNOPSIS
#   setLinkBER $link value
# FUNCTION
#   Sets the BER value of the link.
# INPUTS
#   * link -- link id
#   * value -- The value of 1/BER of the link.
#****
proc setLinkBER { link value } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set i [lsearch [set $link] "ber *"]
    if { $value <= 0 } {
	set $link [lreplace [set $link] $i $i]
    } else {
	set $link [lreplace [set $link] $i $i "ber $value"]
    }

    set mirror_link_id [getLinkMirror $link]
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
#   set loss [getLinkLoss $link]
# FUNCTION
#   Returns loss percentage of the link.
# INPUTS
#   * link -- link id
# RESULT
#   * loss -- The loss percentage of the link.
#****
proc getLinkLoss { link } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set entry [lsearch -inline [set $link] "loss *"]

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
proc setLinkLoss { link value } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set i [lsearch [set $link] "loss *"]
    if { $value <= 0 } {
	set $link [lreplace [set $link] $i $i]
    } else {
	set $link [lreplace [set $link] $i $i "loss $value"]
    }

    set mirror_link_id [getLinkMirror $link]
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
proc getLinkDup { link } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set entry [lsearch -inline [set $link] "duplicate *"]

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
proc setLinkDup { link value } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set i [lsearch [set $link] "duplicate *"]
    if { $value <= 0 || $value > 50 } {
	set $link [lreplace [set $link] $i $i]
    } else {
	set $link [lreplace [set $link] $i $i "duplicate $value"]
    }

    set mirror_link_id [getLinkMirror $link]
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
proc linkResetConfig { link } {
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode

    setLinkBandwidth $link ""
    setLinkBER $link ""
    setLinkLoss $link ""
    setLinkDelay $link ""
    setLinkDup $link ""

    if { $oper_mode == "exec" } {
	upvar 0 ::cf::[set ::curcfg]::eid eid
	execSetLinkParams $eid $link
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
proc getLinkMirror { link } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set entry [lsearch -inline [set $link] "mirror *"]

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
proc setLinkMirror { link value } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set i [lsearch [set $link] "mirror *"]
    if { $value == "" } {
	set $link [lreplace [set $link] $i $i]
    } else {
	set $link [lreplace [set $link] $i $i "mirror $value"]
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
proc splitLink { link nodetype } {
    upvar 0 ::cf::[set ::curcfg]::link_list link_list
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set orig_nodes [getLinkPeers $link]
    lassign $orig_nodes orig_node1_id orig_node2_id
    upvar 0 ::cf::[set ::curcfg]::$orig_node1_id $orig_node1_id
    upvar 0 ::cf::[set ::curcfg]::$orig_node2_id $orig_node2_id

    set orig_ifaces [getLinkPeersIfaces $link]

    # create mirror link and copy the properties from the original
    set mirror_link_id [newObjectId $link_list "l"]
    upvar 0 ::cf::[set ::curcfg]::$mirror_link_id $mirror_link_id
    set $mirror_link_id [set $link]
    lappend link_list $mirror_link_id
    set links "$link $mirror_link_id"

    # create pseudo nodes
    set new_node1_id [newNode $nodetype]
    set new_node2_id [newNode $nodetype]
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
proc mergeLink { link } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    upvar 0 ::cf::[set ::curcfg]::link_list link_list

    set mirror_link [getLinkMirror $link]
    if { $mirror_link == "" } {
	return
    }

    # recycle the first pseudo link ID
    lassign [lsort "$link $mirror_link"] link mirror_link

    lassign [getLinkPeers $link] orig_node1_id pseudo_node1_id
    lassign [getLinkPeers $mirror_link] orig_node2_id pseudo_node2_id

    if { $orig_node1_id == $orig_node2_id } {
	return
    }

    upvar 0 ::cf::[set ::curcfg]::$link $link
    upvar 0 ::cf::[set ::curcfg]::$mirror_link $mirror_link
    upvar 0 ::cf::[set ::curcfg]::$orig_node1_id $orig_node1_id
    upvar 0 ::cf::[set ::curcfg]::$orig_node2_id $orig_node2_id

    lassign [getLinkPeersIfaces $link] orig_node1_iface -
    lassign [getLinkPeersIfaces $mirror_link] orig_node2_iface -

    set i [lsearch [set $orig_node1_id] "interface-peer {$orig_node1_iface $pseudo_node1_id}"]
    set $orig_node1_id [lreplace [set $orig_node1_id] $i $i \
			"interface-peer {$orig_node1_iface $orig_node2_id}"]
    set i [lsearch [set $orig_node2_id] "interface-peer {$orig_node2_iface $pseudo_node2_id}"]
    set $orig_node2_id [lreplace [set $orig_node2_id] $i $i \
			"interface-peer {$orig_node2_iface $orig_node1_id}"]

    set i [lsearch [set $link] "nodes *"]
    set $link [lreplace [set $link] $i $i \
			"nodes {$orig_node1_id $orig_node2_id}"]
    set i [lsearch [set $link] "ifaces *"]
    set $link [lreplace [set $link] $i $i \
			"ifaces {$orig_node1_iface $orig_node2_iface}"]

    setLinkMirror $link ""

    set node_list [removeFromList $node_list "$pseudo_node1_id $pseudo_node2_id"]
    set link_list [removeFromList $link_list $mirror_link]

    return $link
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
proc numOfLinks { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    return [llength [lsearch -all [set $node] "interface-peer*"]]
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
proc newLink { lnode1 lnode2 } {
    upvar 0 ::cf::[set ::curcfg]::link_list link_list
    upvar 0 ::cf::[set ::curcfg]::$lnode1 $lnode1
    upvar 0 ::cf::[set ::curcfg]::$lnode2 $lnode2
    global defEthBandwidth defSerBandwidth defSerDelay

    foreach node "$lnode1 $lnode2" {
	set type [getNodeType $node]
	if { $type == "pseudo" } {
	    return
	}

	if { [info procs $type.maxLinks] != "" } {
	    if { [numOfLinks $node] == [$type.maxLinks] } {
		tk_dialog .dialog1 "IMUNES warning" \
		   "Warning: Maximum links connected to the node $node" \
		   info 0 Dismiss

		return
	    }
	}
    }

    set link [newObjectId $link_list "l"]
    upvar 0 ::cf::[set ::curcfg]::$link $link
    set $link {}

    set ifname1 [newIface [chooseIfName $lnode1 $lnode2] $lnode1]
    lappend $lnode1 "interface-peer {$ifname1 $lnode2}"
    set ifname2 [newIface [chooseIfName $lnode2 $lnode1] $lnode2]
    lappend $lnode2 "interface-peer {$ifname2 $lnode1}"

    lappend $link "nodes {$lnode1 $lnode2}"
    lappend $link "ifaces {$ifname1 $ifname2}"
    if { ([getNodeType $lnode1] == "lanswitch" || \
	[getNodeType $lnode2] == "lanswitch" || \
	[string first eth "$ifname1 $ifname2"] != -1) && \
	[getNodeType $lnode1] != "rj45" && \
	[getNodeType $lnode2] != "rj45" } {

	lappend $link "bandwidth $defEthBandwidth"
    } elseif { [string first ser "$ifname1 $ifname2"] != -1 } {
	lappend $link "bandwidth $defSerBandwidth"
	lappend $link "delay $defSerDelay"
    }

    lappend link_list $link

    if { [info procs [getNodeType $lnode1].confNewIfc] != "" } {
	[getNodeType $lnode1].confNewIfc $lnode1 $ifname1
    }

    if { [info procs [getNodeType $lnode2].confNewIfc] != "" } {
	[getNodeType $lnode2].confNewIfc $lnode2 $ifname2
    }

    return $link
}

#****f* linkcfg.tcl/getIfcLink
# NAME
#   getIfcLink -- get link by interface
# SYNOPSIS
#   set link [getIfcLink $node $fc]
# FUNCTION
#   Returns the link id of the link connected to the node's interface.
# INPUTS
#   * node -- node id
#   * ifc -- interface id
# RESULT
#   * link -- link id
#****
proc getIfcLink { node ifc } {
    upvar 0 ::cf::[set ::curcfg]::link_list link_list

    set peer [getIfcPeer $node $ifc]
    foreach link $link_list {
	set endpoints [getLinkPeers $link]
	if { $endpoints == "$node $peer" } {
	    set dir downstream
	    break
	}

	if { $endpoints == "$peer $node" } {
	    set dir upstream
	    break
	}
    }

    return [list $link $dir]
}
