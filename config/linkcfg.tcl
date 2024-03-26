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
# linkPeers { link }
#	Returns nodes of link endpoints
#
# linkByPeers { node1 node2 }
#	Returns link whose peers are node1 and node2
#
# removeLink { link }
#	Removes the link and related entries in peering node's configs
#
# getLinkBandwidth { link }
#	... in bits per second
#
# getLinkBandwidthString { link }
#	... as string
#
# getLinkDelay { link }
#	... in microseconds
#
# getLinkDelayString { link }
#	... as sting
#
# setLinkBandwidth { link bandwidth }
#	... in bits per second
#
# setLinkDelay { link delay }
#	... in microseconds
#
# All of the above functions are independent to any Tk objects. This means
# they can be used for implementing tasks external to GUI, yet inside the
# GUI any updating of related Tk objects (such as text labels etc.) will
# have to be implemented by additional Tk code.
#****

#****f* linkcfg.tcl/linkPeers
# NAME
#   linkPeers -- get link's peer nodes
# SYNOPSIS
#   set link_peers [linkPeers $link]
# FUNCTION
#   Returns nodes of link endpoints.
# INPUTS
#   * link -- link id
# RESULT
#   * link_peers -- returns nodes of a link endpoints in a list {node1 node2}
#****
proc linkPeers { link } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set entry [lsearch -inline [set $link] "nodes {*}"]
    return [lindex $entry 1]
}

#****f* linkcfg.tcl/linkByPeers
# NAME
#   linkByPeers -- get link id from peer nodes
# SYNOPSIS
#   set link [linkByPeers $node1 $node2]
# FUNCTION
#   Returns link whose peers are node1 and node2.
#   The order of input nodes is irrelevant.
# INPUTS
#   * node1 -- node id of the first node
#   * node2 -- node id of the second node
# RESULT
#   * link -- returns id of a link connecting endpoints node1 and node2
#****
proc linkByPeers { node1 node2 } {
    upvar 0 ::cf::[set ::curcfg]::link_list link_list

    foreach link $link_list {
	set peers [linkPeers $link]
	if { $peers == "$node1 $node2" || $peers == "$node2 $node1" } {
	   
	    return $link 	
	}
    }
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
    upvar 0 ::cf::[set ::curcfg]::link_list link_list
    upvar 0 ::cf::[set ::curcfg]::$link $link
    upvar 0 ::cf::[set ::curcfg]::IPv4UsedList IPv4UsedList
    upvar 0 ::cf::[set ::curcfg]::IPv6UsedList IPv6UsedList
    upvar 0 ::cf::[set ::curcfg]::MACUsedList MACUsedList

    set pnodes [linkPeers $link]
    foreach node $pnodes {
	upvar 0 ::cf::[set ::curcfg]::$node $node

	set i [lsearch $pnodes $node]
	set peer [lreplace $pnodes $i $i]
	set ifc [ifcByPeer $node $peer]
	set index [lsearch -exact $IPv4UsedList [getIfcIPv4addr $node $ifc]]
	set IPv4UsedList [lreplace $IPv4UsedList $index $index]
	set index [lsearch -exact $IPv6UsedList [getIfcIPv6addr $node $ifc]]
	set IPv6UsedList [lreplace $IPv6UsedList $index $index]
	set index [lsearch -exact $MACUsedList [getIfcMACaddr $node $ifc]]
	set MACUsedList [lreplace $MACUsedList $index $index]
	netconfClearSection $node "interface $ifc"
	set i [lsearch [set $node] "interface-peer {$ifc $peer}"]
	set $node [lreplace [set $node] $i $i]
	if { [[typemodel $node].layer] == "NETWORK" } {
	    set ifcs [ifcList $node]
	    foreach iface $ifcs {
		autoIPv4defaultroute $node $iface
	    }
	}
	foreach lifc [logIfcList $node] {
	    switch -exact [getLogIfcType $node $lifc] {
		vlan {
		    if {[getIfcVlanDev $node $lifc] == $ifc} {
			netconfClearSection $node "interface $lifc"
		    }
		}
	    }
	}
    }
    set i [lsearch -exact $link_list $link]
    set link_list [lreplace $link_list $i $i]
}

#****f* linkcfg.tcl/getLinkBandwidth
# NAME
#   getLinkBandwidth -- get link bandwidth
# SYNOPSIS
#   set bandwidth [getLinkBandwidth $link]
# FUNCTION
#   Returns the link bandwidth expressed in bits per second.
# INPUTS
#   * link -- link id
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
#   set bandwidth_str [getLinkBandwidthString $link]
# FUNCTION
#   Returns the link bandwidth in form of a number an a mesure unit.
#   Measure unit is automaticaly asigned depending on the value of bandwidth.
# INPUTS
#   * link -- link id
# RESULT
#   * bandstr -- The value of link bandwidth formated in a sting containing a
#     measure unit.
#****
proc getLinkBandwidthString { link } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

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
#   setLinkBandwidth $link $value
# FUNCTION
#   Sets the link bandwidth in a bits per second.
# INPUTS
#   * link -- link id
#   * value -- link bandwidth in bits per second.
#****
proc setLinkBandwidth { link value } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set i [lsearch [set $link] "bandwidth *"]
    if { $value <= 0 } {
	set $link [lreplace [set $link] $i $i]
    } else {
	set $link [lreplace [set $link] $i $i "bandwidth $value"]
    }
}

#
# Marko - XXX document!
#

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
    } else {
	return [lindex $entry 1]
    }
}

#****f* linkcfg.tcl/setLinkColor
# NAME
#   setLinkColor -- set link color
# SYNOPSIS
#   setLinkColor $link $value
# FUNCTION
#   Sets the color of the link.
# INPUTS
#   * link -- link id
#   * value -- link color
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
    } else {
	return [lindex $entry 1]
    }
}

#****f* linkcfg.tcl/setLinkWidth
# NAME
#   setLinkWidth -- set link width
# SYNOPSIS
#   setLinkWidth $link $value
# FUNCTION
#   Sets the link width on canvas.
# INPUTS
#   * link -- link id
#   * value -- link width
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
#   set delay [getLinkDelay $link]
# FUNCTION
#   Returns the link delay expressed in microseconds.
# INPUTS
#   * link -- link id
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
#   set delay [getLinkDelayString $link]
# FUNCTION
#   Returns the link delay as a string with avalue and measure unit.
#   Measure unit is automaticaly asigned depending on the value of delay.
# INPUTS
#   * link -- link id
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
#   setLinkDelay $link $value
# FUNCTION
#   Sets the link delay in microseconds.
# INPUTS
#   * link -- link id
#   * value -- link delay value in microseconds.
#****
proc setLinkDelay { link value } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set i [lsearch [set $link] "delay *"]
    if { $value <= 0 } {
	set $link [lreplace [set $link] $i $i]
    } else {
	set $link [lreplace [set $link] $i $i "delay $value"]
    }
}

#****f* linkcfg.tcl/getLinkJitterUpstream
# NAME
#   getLinkJitterUpstream -- get link upstream Jitter
# SYNOPSIS
#   set delay [getLinkJitterUpstream $link]
# FUNCTION
#   Returns the list of upstream link jitter values expressed in microseconds.
# INPUTS
#   * link -- link id
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
#   setLinkJitterUpstream $link $values
# FUNCTION
#   Sets the link upstream jitter in microseconds.
# INPUTS
#   * link -- link id
#   * values -- link upstream jitter values in microseconds.
#****
proc setLinkJitterUpstream { link values } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set i [lsearch [set $link] "jitter-upstream *"]
    if { $values == "" } {
	set $link [lreplace [set $link] $i $i]
    } else {
	set $link [lreplace [set $link] $i $i "jitter-upstream {$values}"]
    }
}

#****f* linkcfg.tcl/getLinkJitterModeUpstream
# NAME
#   getLinkJitterModeUpstream -- get link upstream jitter mode
# SYNOPSIS
#   set delay [getLinkJitterModeUpstream $link]
# FUNCTION
#   Returns the upstream link jitter mode.
# INPUTS
#   * link -- link id
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
#   setLinkJitterModeUpstream $link $value
# FUNCTION
#   Sets the link upstream jitter mode.
# INPUTS
#   * link -- link id
#   * value -- link upstream jitter mode.
#****
proc setLinkJitterModeUpstream { link value } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set i [lsearch [set $link] "jitter-upstream-mode *"]
    if { $value == "" } {
	set $link [lreplace [set $link] $i $i]
    } else {
	set $link [lreplace [set $link] $i $i "jitter-upstream-mode $value"]
    }
}

#****f* linkcfg.tcl/getLinkJitterHoldUpstream
# NAME
#   getLinkJitterHoldUpstream -- get link upstream jitter hold
# SYNOPSIS
#   set delay [getLinkJitterHoldUpstream $link]
# FUNCTION
#   Returns the upstream link jitter hold.
# INPUTS
#   * link -- link id
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
#   setLinkJitterHoldUpstream $link $value
# FUNCTION
#   Sets the link upstream jitter hold.
# INPUTS
#   * link -- link id
#   * value -- link upstream jitter hold.
#****
proc setLinkJitterHoldUpstream { link value } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set i [lsearch [set $link] "jitter-upstream-hold *"]
    if { $value == "" } {
	set $link [lreplace [set $link] $i $i]
    } else {
	set $link [lreplace [set $link] $i $i "jitter-upstream-hold $value"]
    }
}

#****f* linkcfg.tcl/getLinkJitterDownstream
# NAME
#   getLinkJitterDownstream -- get link downstream Jitter
# SYNOPSIS
#   set delay [getLinkJitterDownstream $link]
# FUNCTION
#   Returns the downstream link jitter values expressed in microseconds in a
#   list.
# INPUTS
#   * link -- link id
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
#   setLinkJitterDownstream $link $values
# FUNCTION
#   Sets the link downstream jitter in microseconds.
# INPUTS
#   * link -- link id
#   * values -- link downstream jitter values in microseconds.
#****
proc setLinkJitterDownstream { link values } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set i [lsearch [set $link] "jitter-downstream *"]
    if { $values == "" } {
	set $link [lreplace [set $link] $i $i]
    } else {
	set $link [lreplace [set $link] $i $i "jitter-downstream {$values}"]
    }
}

#****f* linkcfg.tcl/getLinkJitterModeDownstream
# NAME
#   getLinkJitterModeDownstream -- get link downstream jitter mode
# SYNOPSIS
#   set delay [getLinkJitterModeDownstream $link]
# FUNCTION
#   Returns the downstream link jitter mode.
# INPUTS
#   * link -- link id
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
#   setLinkJitterModeDownstream $link $value
# FUNCTION
#   Sets the link downstream jitter mode.
# INPUTS
#   * link -- link id
#   * value -- link downstream jitter mode.
#****
proc setLinkJitterModeDownstream { link value } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set i [lsearch [set $link] "jitter-downstream-mode *"]
    if { $value  == "" } {
	set $link [lreplace [set $link] $i $i]
    } else {
	set $link [lreplace [set $link] $i $i "jitter-downstream-mode $value"]
    }
}

#****f* linkcfg.tcl/getLinkJitterHoldDownstream
# NAME
#   getLinkJitterHoldDownstream -- get link downstream jitter hold
# SYNOPSIS
#   set delay [getLinkJitterHoldDownstream $link]
# FUNCTION
#   Returns the downstream link jitter hold.
# INPUTS
#   * link -- link id
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
#   setLinkJitterHoldDownstream $link $value
# FUNCTION
#   Sets the link downstream jitter hold.
# INPUTS
#   * link -- link id
#   * value -- link downstream jitter hold.
#****
proc setLinkJitterHoldDownstream { link value } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set i [lsearch [set $link] "jitter-downstream-hold *"]
    if { $value == "" } {
	set $link [lreplace [set $link] $i $i]
    } else {
	set $link [lreplace [set $link] $i $i "jitter-downstream-hold $value"]
    }
}

#****f* linkcfg.tcl/getLinkBER
# NAME
#   getLinkBER -- get link BER
# SYNOPSIS
#   set BER [getLinkBER $link]
# FUNCTION
#   Returns 1/BER value of the link.
# INPUTS
#   * link -- link id
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
}

#****f* linkcfg.tcl/getLinkDup
# NAME
#   getLinkDup -- get link packet duplicate value
# SYNOPSIS
#   set duplicate [getLinkDup $link]
# FUNCTION
#   Returns the value of the link duplicate percentage.
# INPUTS
#   * link -- link id
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
#   setLinkDup $link $value
# FUNCTION
#   Set link packet duplicate percentage.
# INPUTS
#   * link -- link id
#   * value -- The percentage of the link packet duplicate value.
#****
proc setLinkDup { link value } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set i [lsearch [set $link] "duplicate *"]
    if { $value <= 0 || $value > 50 } {
	set $link [lreplace [set $link] $i $i]
    } else {
	set $link [lreplace [set $link] $i $i "duplicate $value"]
    }
}

#****f* linkcfg.tcl/linkResetConfig
# NAME
#   linkResetConfig -- reset link configuration
# SYNOPSIS
#   linkResetConfig $link
# FUNCTION
#   Reset link configuration to default values.
# INPUTS
#   * link -- link id
#****
proc linkResetConfig { link } {
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode

    setLinkBandwidth $link ""
    setLinkBER $link ""
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
#   set mirror_link_id [getLinkMirror $link]
# FUNCTION
#   Returns the value of the link's mirror link. Mirror link is the other part
#   of the link connecting node to a pseudo node. Two mirror links present
#   only one physical link.
# INPUTS
#   * link -- link id
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
#   setLinkMirror $link $mirror_link_id
# FUNCTION
#   Sets the value of the link's mirror link. Mirror link is the other part of
#   the link connecting node to a pseudo node. Two mirror links present only
#   one physical link.
# INPUTS
#   * link -- link id
# RESULT
#   * mirror_link_id -- mirror link id
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
#   splitLink -- slit the link
# SYNOPSIS
#   set nodes [splitLink  $link $nodetype]
# FUNCTION
#   Splits the link in two parts. Each part of the split link is one pseudo
#   link.
# INPUTS
#   * link -- link id
#   * nodetype -- type of the new nodes connecting split links.
#     Usual value is pseudo.
# RESULT
#   * nodes -- list of node ids of new nodes.
#****
proc splitLink { link nodetype } {
    upvar 0 ::cf::[set ::curcfg]::link_list link_list
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set orig_nodes [linkPeers $link]
    set orig_node1 [lindex $orig_nodes 0]
    set orig_node2 [lindex $orig_nodes 1]
    set new_node1 [newNode $nodetype]
    set new_node2 [newNode $nodetype]
    set new_link1 [newObjectId link]
    lappend link_list $new_link1
    set new_link2 [newObjectId link]
    lappend link_list $new_link2
    set ifc1 [ifcByPeer $orig_node1 $orig_node2]
    set ifc2 [ifcByPeer $orig_node2 $orig_node1]

    upvar 0 ::cf::[set ::curcfg]::$orig_node1 $orig_node1
    upvar 0 ::cf::[set ::curcfg]::$orig_node2 $orig_node2
    upvar 0 ::cf::[set ::curcfg]::$new_node1 $new_node1
    upvar 0 ::cf::[set ::curcfg]::$new_node2 $new_node2
    upvar 0 ::cf::[set ::curcfg]::$new_link1 $new_link1
    upvar 0 ::cf::[set ::curcfg]::$new_link2 $new_link2
    set $new_link1 {}
    set $new_link2 {}

    set i [lsearch [set $orig_node1] "interface-peer {* $orig_node2}"]
    set $orig_node1 [lreplace [set $orig_node1] $i $i \
			"interface-peer {$ifc1 $new_node1}"]
    set i [lsearch [set $orig_node2] "interface-peer {* $orig_node1}"]
    set $orig_node2 [lreplace [set $orig_node2] $i $i \
			"interface-peer {$ifc2 $new_node2}"]

    lappend $new_link1 "nodes {$orig_node1 $new_node1}"
    lappend $new_link2 "nodes {$orig_node2 $new_node2}"

    setNodeCanvas $new_node1 [getNodeCanvas $orig_node1]
    setNodeCanvas $new_node2 [getNodeCanvas $orig_node2]
    setNodeCoords $new_node1 [getNodeCoords $orig_node2]
    setNodeCoords $new_node2 [getNodeCoords $orig_node1]
    if { $nodetype != "pseudo" } {
	setNodeLabelCoords $new_node1 [getNodeLabelCoords $orig_node2]
	setNodeLabelCoords $new_node2 [getNodeLabelCoords $orig_node1]
    } else {
	setNodeLabelCoords $new_node1 [getNodeCoords $orig_node2]
	setNodeLabelCoords $new_node2 [getNodeCoords $orig_node1]
    }
    lappend $new_node1 "interface-peer {0 $orig_node1}"
    lappend $new_node2 "interface-peer {0 $orig_node2}"

    setLinkBandwidth $new_link1 [getLinkBandwidth $link]
    setLinkBandwidth $new_link2 [getLinkBandwidth $link]
    setLinkDelay $new_link1 [getLinkDelay $link]
    setLinkDelay $new_link2 [getLinkDelay $link]
    setLinkBER $new_link1 [getLinkBER $link]
    setLinkBER $new_link2 [getLinkBER $link]
    setLinkDup $new_link1 [getLinkDup $link]
    setLinkDup $new_link2 [getLinkDup $link]

    set i [lsearch -exact $link_list $link]
    set link_list [lreplace $link_list $i $i]

    return "$new_node1 $new_node2"
}

#****f* linkcfg.tcl/mergeLink
# NAME
#   mergeLink -- merge the link
# SYNOPSIS
#   set new_link_id [mergeLink $link]
# FUNCTION
#   Rebuilts a link from two pseudo links.
# INPUTS
#   * link -- pseudo link id
# RESULT
#   * new_link_id -- rebuilt link id
#****
proc mergeLink { link } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    upvar 0 ::cf::[set ::curcfg]::link_list link_list

    set mirror_link [getLinkMirror $link]
    if { $mirror_link == "" } {
	puts "XXX mergeLink called for non-pseudo link!!!"
	return
    }
    set link1_peers [linkPeers $link]
    set link2_peers [linkPeers $mirror_link]
    set orig_node1 [lindex $link1_peers 0]
    set orig_node2 [lindex $link2_peers 0]
    set pseudo_node1 [lindex $link1_peers 1]
    set pseudo_node2 [lindex $link2_peers 1]
    set new_link [newObjectId link]
    upvar 0 ::cf::[set ::curcfg]::$orig_node1 $orig_node1
    upvar 0 ::cf::[set ::curcfg]::$orig_node2 $orig_node2
    upvar 0 ::cf::[set ::curcfg]::$new_link $new_link

    set ifc1 [ifcByPeer $orig_node1 $pseudo_node1]
    set ifc2 [ifcByPeer $orig_node2 $pseudo_node2]
    set i [lsearch [set $orig_node1] "interface-peer {* $pseudo_node1}"]
    set $orig_node1 [lreplace [set $orig_node1] $i $i \
			"interface-peer {$ifc1 $orig_node2}"]
    set i [lsearch [set $orig_node2] "interface-peer {* $pseudo_node2}"]
    set $orig_node2 [lreplace [set $orig_node2] $i $i \
			"interface-peer {$ifc2 $orig_node1}"]

    set $new_link {}
    lappend $new_link "nodes {$orig_node1 $orig_node2}"

    setLinkBandwidth $new_link [getLinkBandwidth $link]
    setLinkDelay $new_link [getLinkDelay $link]
    setLinkBER $new_link [getLinkBER $link]
    setLinkDup $new_link [getLinkDup $link]

    set i [lsearch -exact $link_list $link]
    set link_list [lreplace $link_list $i $i]
    set i [lsearch -exact $link_list $mirror_link]
    set link_list [lreplace $link_list $i $i]
    lappend link_list $new_link

    set i [lsearch -exact $node_list $pseudo_node1]
    set node_list [lreplace $node_list $i $i]
    set i [lsearch -exact $node_list $pseudo_node2]
    set node_list [lreplace $node_list $i $i]

    return $new_link
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
	if {[info procs [nodeType $node].maxLinks] != "" } {
	    if { [ numOfLinks $node ] == [[nodeType $node].maxLinks] } {
		tk_dialog .dialog1 "IMUNES warning" \
		   "Warning: Maximum links connected to the node $node" \
		   info 0 Dismiss
		return
	    }
	}
    }

    set link [newObjectId link]
    upvar 0 ::cf::[set ::curcfg]::$link $link
    set $link {}

    set ifname1 [newIfc [chooseIfName $lnode1 $lnode2] $lnode1]
    lappend $lnode1 "interface-peer {$ifname1 $lnode2}"
    set ifname2 [newIfc [chooseIfName $lnode2 $lnode1] $lnode2]
    lappend $lnode2 "interface-peer {$ifname2 $lnode1}"

    lappend $link "nodes {$lnode1 $lnode2}"
    if { ([nodeType $lnode1] == "lanswitch" || \
	[nodeType $lnode2] == "lanswitch" || \
	[string first eth "$ifname1 $ifname2"] != -1) && \
	[nodeType $lnode1] != "rj45" && \
	[nodeType $lnode2] != "rj45" } {
	lappend $link "bandwidth $defEthBandwidth"
    } elseif { [string first ser "$ifname1 $ifname2"] != -1 } {
	lappend $link "bandwidth $defSerBandwidth"
	lappend $link "delay $defSerDelay"
    }

    lappend link_list $link

    if {[isNodeRouter $lnode1]} {
	if {[info procs [nodeType $lnode1].confNewIfc] != ""} {
	    [nodeType $lnode1].confNewIfc $lnode1 $ifname1
	}
	if {[info procs [nodeType $lnode2].confNewIfc] != ""} {
	    [nodeType $lnode2].confNewIfc $lnode2 $ifname2
	}
    } else {
	if {[info procs [nodeType $lnode2].confNewIfc] != ""} {
	    [nodeType $lnode2].confNewIfc $lnode2 $ifname2
	}
	if {[info procs [nodeType $lnode1].confNewIfc] != ""} {
	    [nodeType $lnode1].confNewIfc $lnode1 $ifname1
	}
    }

    return $link
}

#****f* linkcfg.tcl/linkByIfc
# NAME
#   linkByIfg -- get link by interface
# SYNOPSIS
#   set link [linkByIfc $node $fc]
# FUNCTION
#   Returns the link id of the link connecting the node's interface.
# INPUTS
#   * node -- node id
#   * ifc -- interface
# RESULT
#   * link -- link id.
#****
proc linkByIfc { node ifc } {
    upvar 0 ::cf::[set ::curcfg]::link_list link_list

    set peer [peerByIfc $node $ifc]
    foreach link $link_list {
	set endpoints [linkPeers $link]
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
