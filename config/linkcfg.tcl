#
# Copyright 2004- University of Zagreb.
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
	set links [cfgGet "links"]
	set link_ids {}
	foreach {link_id link_cfg} $links {
		set peers [dictGet $links $link_id "peers"]
		if { $node1_id in $peers && $node2_id in $peers } {
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
proc removeLink { link_id { keep_ifaces 0 } } {
	trigger_linkDestroy $link_id

	lassign [getLinkPeers $link_id] node1_id node2_id
	lassign [getLinkPeersIfaces $link_id] iface1_id iface2_id

	# save old subnet data for comparation
	lassign [getSubnetData $node1_id $iface1_id {} {} 0] old_subnet1_gws old_subnet1_data
	lassign [getSubnetData $node2_id $iface2_id {} {} 0] old_subnet2_gws old_subnet2_data

	foreach node_id "$node1_id $node2_id" iface_id "$iface1_id $iface2_id" {
		set node_type [getNodeType $node_id]
		if { $node_type in "packgen" } {
			trigger_nodeUnconfig $node_id
		} elseif { $node_type in "filter" } {
			trigger_nodeReconfig $node_id
		}

		if { $keep_ifaces } {
			cfgUnset "nodes" $node_id "ifaces" $iface_id "link"
			continue
		}

		removeIface $node_id $iface_id
	}

	set mirror_link_id [getLinkMirror $link_id]
	if { $mirror_link_id != "" } {
		setLinkMirror $mirror_link_id ""
		removeLink $mirror_link_id $keep_ifaces
	}

	foreach node_id "$node1_id $node2_id" {
		if { [getNodeType $node_id] == "pseudo" } {
			setToRunning "node_list" [removeFromList [getFromRunning "node_list"] $node_id]
			cfgUnset "nodes" $node_id
		}
	}

	setToRunning "link_list" [removeFromList [getFromRunning "link_list"] $link_id]

	cfgUnset "links" $link_id

	# after deleting the link, refresh nodes auto default routes
	lassign [getSubnetData $node1_id $iface1_id {} {} 0] new_subnet1_gws new_subnet1_data
	lassign [getSubnetData $node2_id $iface2_id {} {} 0] new_subnet2_gws new_subnet2_data

	if { $new_subnet1_gws != "" } {
		set diff [removeFromList {*}$old_subnet1_gws {*}$new_subnet1_gws]
		if { $diff ni "{} {||}" } {
			# there was a change in subnet1, go through its new nodes and attach new data
			set has_extnat [string match "*ext*" $diff]
			foreach subnet_node [dict keys $new_subnet1_data] {
				if { [getNodeAutoDefaultRoutesStatus $subnet_node] != "enabled" } {
					continue
				}

				set subnet_node_type [getNodeType $subnet_node]
				if { $subnet_node_type == "ext" || [$subnet_node_type.netlayer] != "NETWORK" } {
					# skip extnat and L2 nodes
					continue
				}

				if { ! $has_extnat && [getNodeType $subnet_node] in "router nat64" } {
					# skip routers if there is no extnats
					continue
				}

				trigger_nodeReconfig $subnet_node
			}
		}
	}

	if { $new_subnet2_gws != "" } {
		set diff [removeFromList {*}$old_subnet2_gws {*}$new_subnet2_gws]
		if { $diff ni "{} {||}" } {
			# change in subnet1, go through its new nodes and attach new data
			set has_extnat [string match "*ext*" $diff]
			foreach subnet_node [dict keys $new_subnet2_data] {
				if { [getNodeAutoDefaultRoutesStatus $subnet_node] != "enabled" } {
					continue
				}

				set subnet_node_type [getNodeType $subnet_node]
				if { $subnet_node_type == "ext" || [$subnet_node_type.netlayer] != "NETWORK" } {
					# skip extnat and L2 nodes
					continue
				}

				if { ! $has_extnat && [getNodeType $subnet_node] in "router nat64" } {
					# skip routers if there is no extnats
					continue
				}

				trigger_nodeReconfig $subnet_node
			}
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
	setLinkBandwidth $link_id ""
	setLinkBER $link_id ""
	setLinkLoss $link_id ""
	setLinkDelay $link_id ""
	setLinkDup $link_id ""

	if { [getFromRunning "oper_mode"] == "exec" } {
		execSetLinkParams [getFromRunning "eid"] $link_id
	}
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
	set num 0
	foreach {iface_id iface_cfg} [cfgGet "nodes" $node_id "ifaces"] {
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
	return [newLinkWithIfaces $node1_id "" $node2_id ""]
}

proc newLinkWithIfaces { node1_id iface1_id node2_id iface2_id } {
	foreach node_id "$node1_id $node2_id" iface_id "\"$iface1_id\" \"$iface2_id\"" {
		set type [getNodeType $node_id]
		if { $type == "pseudo" } {
			return
		}

		# maximum number of ifaces on a node
		if { $iface_id == "" } {
			if { [info procs $type.maxLinks] != "" } {
				# TODO: maxIfaces would be a better name
				if { [llength [ifcList $node_id]] >= [$type.maxLinks] } {
					after idle {.dialog1.msg configure -wraplength 4i}
					tk_dialog .dialog1 "IMUNES warning" \
						"Warning: Maximum links connected to the node $node_id" \
						info 0 Dismiss

					return
				}
			}

			continue
		}

		# iface does not exist
		if { [getNodeIface $node_id $iface_id] == "" } {
			after idle {.dialog1.msg configure -wraplength 4i}
			tk_dialog .dialog1 "IMUNES warning" \
				"Warning: Interface '[getIfcName $node_id $iface_id]' on node '[getNodeName $node_id]' does not exist" \
				info 0 Dismiss

			return
		}

		# iface already connected to a link
		if { [getIfcLink $node_id $iface_id] != "" } {
			after idle {.dialog1.msg configure -wraplength 4i}
			tk_dialog .dialog1 "IMUNES warning" \
				"Warning: Interface '[getIfcName $node_id $iface_id]' already connected to a link" \
				info 0 Dismiss

			return
		}
	}

	set config_iface1 0
	if { $iface1_id == "" } {
		set config_iface1 1
		if { [getNodeType $node1_id] == "rj45" } {
			set iface1_id [newIface $node1_id "stolen" 0 "UNASSIGNED"]
		} else {
			set iface1_id [newIface $node1_id "phys" 0]
		}
	}

	set config_iface2 0
	if { $iface2_id == "" } {
		set config_iface2 1
		if { [getNodeType $node2_id] == "rj45" } {
			set iface2_id [newIface $node2_id "stolen" 0 "UNASSIGNED"]
		} else {
			set iface2_id [newIface $node2_id "phys" 0]
		}
	}

	foreach node_id "$node1_id $node2_id" {
		set node_type [getNodeType $node_id]
		if { $node_type in "packgen" } {
			trigger_nodeConfig $node_id
		} elseif { $node_type in "filter" } {
			trigger_nodeReconfig $node_id
		}
	}

	# save old subnet data for comparation
	lassign [getSubnetData $node1_id $iface1_id {} {} 0] old_subnet1_gws old_subnet1_data
	lassign [getSubnetData $node2_id $iface2_id {} {} 0] old_subnet2_gws old_subnet2_data

	set link_id [newObjectId [getFromRunning "link_list"] "l"]
	setToRunning "${link_id}_running" false

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

	trigger_linkCreate $link_id

	lassign [getSubnetData $node1_id $iface1_id {} {} 0] new_subnet1_gws new_subnet1_data
	lassign [getSubnetData $node2_id $iface2_id {} {} 0] new_subnet2_gws new_subnet2_data

	if { $old_subnet1_gws != "" } {
		set diff [removeFromList {*}$new_subnet1_gws {*}$old_subnet1_gws]
		if { $diff ni "{} {||}" } {
			# there was a change in subnet1, go through its old nodes and attach new data
			set has_extnat [string match "*ext*" $diff]
			foreach subnet_node [dict keys $old_subnet1_data] {
				if { [getNodeAutoDefaultRoutesStatus $subnet_node] != "enabled" } {
					continue
				}

				set subnet_node_type [getNodeType $subnet_node]
				if { $subnet_node_type == "ext" || [$subnet_node_type.netlayer] != "NETWORK" } {
					# skip extnat and L2 nodes
					continue
				}

				if { ! $has_extnat && [getNodeType $subnet_node] in "router nat64" } {
					# skip routers if there is no extnats
					continue
				}

				trigger_nodeReconfig $subnet_node
			}
		}
	}

	if { $old_subnet2_gws != "" } {
		set diff [removeFromList {*}$new_subnet2_gws {*}$old_subnet2_gws]
		if { $diff ni "{} {||}" } {
			# change in subnet1, go through its old nodes and attach new data
			set has_extnat [string match "*ext*" $diff]
			foreach subnet_node [dict keys $old_subnet2_data] {
				if { [getNodeAutoDefaultRoutesStatus $subnet_node] != "enabled" } {
					continue
				}

				set subnet_node_type [getNodeType $subnet_node]
				if { $subnet_node_type == "ext" || [$subnet_node_type.netlayer] != "NETWORK" } {
					# skip extnat and L2 nodes
					continue
				}

				if { ! $has_extnat && [getNodeType $subnet_node] in "router nat64" } {
					# skip routers if there is no extnats
					continue
				}

				trigger_nodeReconfig $subnet_node
			}
		}
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
