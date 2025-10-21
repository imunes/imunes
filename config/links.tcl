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

#****f* links.tcl/getLinkDirect
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

#****f* links.tcl/setLinkDirect
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
	global isOSlinux

	cfgSet "links" $link_id "direct" $direct

	if { $isOSlinux } {
		lassign [getLinkPeers $link_id] node1_id node2_id
		lassign [getLinkPeersIfaces $link_id] iface1_id iface2_id

		trigger_ifaceRecreate $node1_id $iface1_id
		if { [getNodeAutoDefaultRoutesStatus $node1_id] == "enabled" } {
			trigger_nodeReconfig $node1_id
		}

		trigger_ifaceRecreate $node2_id $iface2_id
		if { [getNodeAutoDefaultRoutesStatus $node2_id] == "enabled" } {
			trigger_nodeReconfig $node2_id
		}
	}

	trigger_linkRecreate $link_id
}

#****f* links.tcl/getLinkPeers
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
	return [cfgGet "links" $link_id "peers"]
}

#****f* links.tcl/setLinkPeers
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
	cfgSet "links" $link_id "peers" $peers
}

#****f* links.tcl/getLinkPeersIfaces
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
	return [cfgGet "links" $link_id "peers_ifaces"]
}

#****f* links.tcl/setLinkPeersIfaces
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
	cfgSet "links" $link_id "peers_ifaces" $peers_ifaces
}

#****f* links.tcl/getLinkBandwidth
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

#****f* links.tcl/setLinkBandwidth
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

	trigger_linkConfig $link_id

	cfgSet "links" $link_id "bandwidth" $bandwidth
}

#****f* links.tcl/getLinkDelay
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

#****f* links.tcl/setLinkDelay
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

	trigger_linkConfig $link_id

	cfgSet "links" $link_id "delay" $delay
}

#****f* links.tcl/getLinkJitterUpstream
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

#****f* links.tcl/setLinkJitterUpstream
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

	trigger_linkConfig $link_id

	cfgSet "links" $link_id "jitter_upstream" $jitter_upstream
}

#****f* links.tcl/getLinkJitterModeUpstream
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

#****f* links.tcl/setLinkJitterModeUpstream
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

	trigger_linkConfig $link_id

	cfgSet "links" $link_id "jitter_upstream_mode" $jitter_upstream_mode
}

#****f* links.tcl/getLinkJitterHoldUpstream
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

#****f* links.tcl/setLinkJitterHoldUpstream
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

	trigger_linkConfig $link_id

	cfgSet "links" $link_id "jitter_upstream_hold" $jitter_upstream_hold
}

#****f* links.tcl/getLinkJitterDownstream
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

#****f* links.tcl/setLinkJitterDownstream
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

	trigger_linkConfig $link_id

	cfgSet "links" $link_id "jitter_downstream" $jitter_downstream
}

#****f* links.tcl/getLinkJitterModeDownstream
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

#****f* links.tcl/setLinkJitterModeDownstream
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

	trigger_linkConfig $link_id

	cfgSet "links" $link_id "jitter_downstream_mode" $jitter_downstream_mode
}

#****f* links.tcl/getLinkJitterHoldDownstream
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

#****f* links.tcl/setLinkJitterHoldDownstream
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

	trigger_linkConfig $link_id

	cfgSet "links" $link_id "jitter_downstream_hold" $jitter_downstream_hold
}

#****f* links.tcl/getLinkBER
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

#****f* links.tcl/setLinkBER
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
	if { $ber == 0 } {
		set ber ""
	}

	trigger_linkConfig $link_id

	cfgSet "links" $link_id "ber" $ber
}

#****f* links.tcl/getLinkLoss
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

#****f* links.tcl/setLinkLoss
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

	trigger_linkConfig $link_id

	cfgSet "links" $link_id "loss" $loss
}

#****f* links.tcl/getLinkDup
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

#****f* links.tcl/setLinkDup
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

	trigger_linkConfig $link_id

	cfgSet "links" $link_id "duplicate" $duplicate
}
