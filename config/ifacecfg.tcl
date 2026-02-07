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

#****f* ifacecfg.tcl/getIfcPeer
# NAME
#   getIfcPeer -- get node's peer by interface.
# SYNOPSIS
#   set peer_id [getIfcPeer $node_id $iface_id]
# FUNCTION
#   Returns id of the node on the other side of the interface. If the node on
#   the other side of the interface is situated on the other canvas or
#   connected via split link, this function returns a pseudo node.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
# RESULT
#   * peer_id -- node id of the node on the other side of the interface
#****
proc getIfcPeer { node_id iface_id } {
	set link_id [getIfcLink $node_id $iface_id]

	return [removeFromList [getLinkPeers $link_id] $node_id]
}

#****f* ifacecfg.tcl/getIfcLinkLocalIPv6addr
# NAME
#   getIfcLinkLocalIPv6addr -- get interface link-local IPv6 address.
# SYNOPSIS
#   set addr [getIfcLinkLocalIPv6addr $node_id $iface_id]
# FUNCTION
#   Returns link-local IPv6 addresses that is calculated from the interface
#   MAC address. This can be done only for physical interfaces, or interfaces
#   with a MAC address assigned.
# INPUTS
#   * node_id -- the node id of the node whose link-local IPv6 address is returned.
#   * iface_id -- interface id.
# RESULT
#   * addr -- The link-local IPv6 address that will be assigned to the
#     specified interface.
#****
proc getIfcLinkLocalIPv6addr { node_id iface_id } {
	if { [isIfcLogical $node_id $iface_id] } {
		return ""
	}

	set mac [getIfcMACaddr $node_id $iface_id]

	set bytes [split $mac :]
	set bytes [linsert $bytes 3 fe]
	set bytes [linsert $bytes 3 ff]

	set first [expr 0x[lindex $bytes 0]]
	set xored [expr $first^2]
	set result [format %02x $xored]

	set bytes [lreplace $bytes 0 0 $result]

	set i 0
	lappend final fe80::
	foreach b $bytes {
		lappend final $b
		if { [expr $i%2] == 1 && $i < 7 } {
			lappend final :
		}
		incr i
	}
	lappend final /64

	return [ip::normalize [join $final ""]]
}

#****f* ifacecfg.tcl/ifcList
# NAME
#   ifcList -- get list of all interfaces
# SYNOPSIS
#   set ifcs [ifcList $node_id]
# FUNCTION
#   Returns a list of all interfaces present in a node.
# INPUTS
#   * node_id -- node id
# RESULT
#   * interfaces -- list of all node's interfaces
#****
proc ifcList { node_id } {
	return [getIfacesByType $node_id "phys" "stolen"]
}

proc ifacesNames { node_id } {
	return [getIfacesNamesByType $node_id "phys" "stolen"]
}

proc getIfacesByType { node_id args } {
	set all_ifaces [cfgGet "nodes" $node_id "ifaces"]
	if { $all_ifaces == {} } {
		return
	}

	set iface_ids {}
	foreach type $args {
		set filtered_ifaces [dict keys [dict filter $all_ifaces "value" "*type $type*"]]
		if { $filtered_ifaces != {} } {
			lappend iface_ids {*}$filtered_ifaces
		}
	}

	return $iface_ids
}

proc getIfacesNamesByType { node_id args } {
	set filtered_ifaces [getIfacesByType $node_id {*}$args]

	set iface_names {}
	foreach iface_id $filtered_ifaces {
		lappend iface_names [getIfcName $node_id $iface_id]
	}

	return $iface_names
}

#****f* ifacecfg.tcl/logIfcList
# NAME
#   logIfcList -- logical interfaces list
# SYNOPSIS
#   logIfcList $node_id
# FUNCTION
#   Returns the list of all the node's logical interfaces.
# INPUTS
#   * node_id -- node id
# RESULT
#   * interfaces -- list of node's logical interfaces
#****
proc logIfcList { node_id } {
	return [getIfacesByType $node_id "lo" "vlan"]
}

proc logIfacesNames { node_id } {
	return [getIfacesNamesByType $node_id "lo" "vlan"]
}

#****f* ifacecfg.tcl/isIfcLogical
# NAME
#   isIfcLogical -- is given interface logical
# SYNOPSIS
#   isIfcLogical $node_id $iface_id
# FUNCTION
#   Returns true or false whether the node's interface is logical or not.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
# RESULT
#   * check -- true if the interface is logical, otherwise false.
#****
proc isIfcLogical { node_id iface_id } {
	if { $iface_id in [logIfcList $node_id] } {
		return true
	}

	return false
}

#****f* ifacecfg.tcl/allIfcList
# NAME
#   allIfcList -- all interfaces list
# SYNOPSIS
#   allIfcList $node_id
# FUNCTION
#   Returns the list of all node's interfaces.
# INPUTS
#   * node_id -- node id
# RESULT
#   * interfaces -- list of node's interfaces
#****
proc allIfcList { node_id } {
	return [dict keys [cfgGet "nodes" $node_id "ifaces"]]
}

proc allIfacesNames { node_id } {
	set iface_names {}
	foreach {iface_id iface_cfg} [cfgGet "nodes" $node_id "ifaces"] {
		lappend iface_names [dictGet $iface_cfg "name"]
	}

	return $iface_names
}

#****f* ifacecfg.tcl/logicalPeerByIfc
# NAME
#   logicalPeerByIfc -- get node's peer by interface.
# SYNOPSIS
#   set peer_id [logicalPeerByIfc $node_id $iface_id]
# FUNCTION
#   Returns id of the node on the other side of the interface. If the node on
#   the other side of the interface is connected via normal link (not split)
#   this function acts the same as the function getIfcPeer, but if the nodes
#   are connected via split links or situated on different canvases this
#   function returns the logical peer node.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface id
# RESULT
#   * peer_id -- node id of the node on the other side of the interface
#****
proc logicalPeerByIfc { node_id iface_id } {
	set link_id [getIfcLink $node_id $iface_id]
	if { $link_id == "" } {
		return
	}

	set peer_id [removeFromList [getLinkPeers $link_id] $node_id "keep_doubles"]
	set peer_iface_id [removeFromList [getLinkPeersIfaces $link_id] $iface_id "keep_doubles"]

	return "$peer_id $peer_iface_id"
}

proc ifaceIdFromName { node_id iface_name } {
	foreach {iface_id iface_cfg} [cfgGet "nodes" $node_id "ifaces"] {
		if { $iface_name == [dictGet $iface_cfg "name"] } {
			return $iface_id
		}
	}

	return ""
}

#****f* ifacecfg.tcl/hasIPv4Addr
# NAME
#   hasIPv4Addr -- has IPv4 address.
# SYNOPSIS
#   set check [hasIPv4Addr $node_id]
# FUNCTION
#   Returns true if at least one interface has an IPv4 address configured,
#   otherwise returns false.
# INPUTS
#   * node_id -- node id
# RESULT
#   * check -- true if at least one interface has an IPv4 address, otherwise
#     false.
#****
proc hasIPv4Addr { node_id } {
	foreach iface_id [ifcList $node_id] {
		if { [getIfcIPv4addrs $node_id $iface_id] != {} } {
			return true
		}
	}

	return false
}

#****f* ifacecfg.tcl/hasIPv6Addr
# NAME
#   hasIPv6Addr -- has IPv6 address.
# SYNOPSIS
#   set check [hasIPv6Addr $node_id]
# FUNCTION
#   Retruns true if at least one interface has an IPv6 address configured,
#   otherwise returns false.
# INPUTS
#   * node_id -- node id
# RESULT
#   * check -- true if at least one interface has an IPv6 address, otherwise
#     false.
#****
proc hasIPv6Addr { node_id } {
	foreach iface_id [ifcList $node_id] {
		if { [getIfcIPv6addrs $node_id $iface_id] != {} } {
			return true
		}
	}

	return false
}

#****f* ifacecfg.tcl/nodeCfggenIfcIPv4
# NAME
#   nodeCfggenIfcIPv4 -- generate interface IPv4 configuration
# SYNOPSIS
#   nodeCfggenIfcIPv4 $node_id
# FUNCTION
#   Generate configuration for all IPv4 addresses on all node
#   interfaces.
# INPUTS
#   * node_id -- node to generate configuration for
# RESULT
#   * value -- interface IPv4 configuration script
#****
proc nodeCfggenIfcIPv4 { node_id iface_id } {
	set cfg {}
	set primary 1
	foreach addr [getIfcIPv4addrs $node_id $iface_id] {
		lappend cfg [getIPv4IfcCmd [getIfcName $node_id $iface_id] $addr $primary]
		set primary 0
	}

	return $cfg
}

#****f* ifacecfg.tcl/nodeCfggenIfcIPv6
# NAME
#   nodeCfggenIfcIPv6 -- generate interface IPv6 configuration
# SYNOPSIS
#   nodeCfggenIfcIPv6 $node_id
# FUNCTION
#   Generate configuration for all IPv6 addresses on all node
#   interfaces.
# INPUTS
#   * node_id -- node to generate configuration for
# RESULT
#   * value -- interface IPv6 configuration script
#****
proc nodeCfggenIfcIPv6 { node_id iface_id } {
	set cfg {}
	set primary 1
	foreach addr [getIfcIPv6addrs $node_id $iface_id] {
		lappend cfg [getIPv6IfcCmd [getIfcName $node_id $iface_id] $addr $primary]
		set primary 0
	}

	return $cfg
}

#****f* ifacecfg.tcl/newIface
# NAME
#   newIface -- new interface
# SYNOPSIS
#   set iface_id [newIface $type $node_id]
# FUNCTION
#   Returns the first available name for a new interface of the specified type.
# INPUTS
#   * node_id -- node id
#   * type -- interface type
#   * auto_config -- enable auto iface configuration
#   * stolen_iface -- if stolen, interface name
# RESULT
#   * iface_id -- the first available name for a interface of the specified type
#****
proc newIface { node_id iface_type auto_config { stolen_iface "" } } {
	set iface_id [newObjectId [allIfcList $node_id] "ifc"]

	switch -exact $iface_type {
		"lo" -
		"vlan" {
			set iface_name [newObjectId [allIfacesNames $node_id] $iface_type]
		}
		"phys" {
			set iface_name [newObjectId [allIfacesNames $node_id] [invokeNodeProc $node_id "ifacePrefix"]]
		}
		"stolen" {
			if { $stolen_iface != "UNASSIGNED" && $stolen_iface in [allIfacesNames $node_id] } {
				return ""
			}

			set iface_name $stolen_iface
		}
	}

	if { [getFromRunning "${node_id}|${iface_id}_running"] == "" } {
		setToRunning "${node_id}|${iface_id}_running" "false"
	}

	setNodeIface $node_id $iface_id {}

	setIfcType $node_id $iface_id $iface_type
	setIfcName $node_id $iface_id $iface_name

	if { $auto_config } {
		invokeNodeProc $node_id "confNewIfc" $node_id $iface_id
	}

	trigger_ifaceCreate $node_id $iface_id

	return $iface_id
}

#****f* ifacecfg.tcl/newLogIface
# NAME
#   newLogIface -- new logical interface
# SYNOPSIS
#   newLogIface $type $node_id
# FUNCTION
#   Returns the first available name for a new logical interface of the
#   specified type.
# INPUTS
#   * node_id -- node id
#   * type -- interface type
#****
proc newLogIface { node_id logiface_type } {
	return [newIface $node_id $logiface_type 0]
}

proc removeIface { node_id iface_id { keep_other_ifaces 1} } {
	trigger_ifaceDestroy $node_id $iface_id

	set link_id [getIfcLink $node_id $iface_id]
	if { $link_id != "" } {
		cfgUnset "nodes" $node_id "ifaces" $iface_id "link"

		removeLink $link_id $keep_other_ifaces
	}

	setToRunning "ipv4_used_list" [removeFromList [getFromRunning "ipv4_used_list"] [getIfcIPv4addrs $node_id $iface_id] "keep_doubles"]
	setToRunning "ipv6_used_list" [removeFromList [getFromRunning "ipv6_used_list"] [getIfcIPv6addrs $node_id $iface_id] "keep_doubles"]
	setToRunning "mac_used_list" [removeFromList [getFromRunning "mac_used_list"] [getIfcMACaddr $node_id $iface_id] "keep_doubles"]

	set iface_name [getIfcName $node_id $iface_id]

	cfgUnset "nodes" $node_id "ifaces" $iface_id
	if { [getFromRunning "${node_id}|${iface_id}_running"] == "true" } {
		setToRunning "${node_id}|${iface_id}_running" "delete"
	} else {
		unsetRunning "${node_id}|${iface_id}_running"
	}

	foreach {logiface_id iface_cfg} [cfgGet "nodes" $node_id "ifaces"] {
		switch -exact [dictGet $iface_cfg "type"] {
			vlan {
				if { [dictGet $iface_cfg "vlan_dev"] == $iface_name } {
					cfgUnset "nodes" $node_id "ifaces" $logiface_id
				}
			}
		}
	}

	set node_type [getNodeType $node_id]
	if { $node_type in "filter" } {
		foreach other_iface_id [ifcList $node_id] {
			foreach rule_num [ifcFilterRuleList $node_id $other_iface_id] {
				if { [getFilterIfcActionData $node_id $other_iface_id $rule_num] == $iface_name } {
					removeFilterIfcRule $node_id $other_iface_id $rule_num
				}
			}
		}
	} elseif { $node_type in "ext" && [getNodeNATIface $node_id] != "UNASSIGNED" } {
		trigger_nodeUnconfig $node_id
	} elseif { $node_type in "lanswitch" && [getNodeVlanFiltering $node_id] } {
		foreach other_iface_id [ifcList $node_id] {
			if { $iface_id != $other_iface_id && [getIfcVlanType $node_id $other_iface_id] == "trunk" } {
				trigger_ifaceReconfig $node_id $other_iface_id
			}
		}
	}
}

proc nodeCfggenIfc { node_id iface_id } {
	global isOSlinux

	if { [getIfcType $node_id $iface_id] == "vlan" } {
		if {
			[getIfcVlanTag $node_id $iface_id] == "" ||
			[getIfcVlanDev $node_id $iface_id] == ""
		} {
			return
		}
	}

	set cfg {}

	set iface_name [getIfcName $node_id $iface_id]

	set mac_addr [getIfcMACaddr $node_id $iface_id]
	if { $mac_addr != "" } {
		lappend cfg [getMacIfcCmd $iface_name $mac_addr]
	}

	set mtu [getIfcMTU $node_id $iface_id]
	lappend cfg [getMtuIfcCmd $iface_name $mtu]

	if { [getIfcNatState $node_id $iface_id] == "on" } {
		lappend cfg [getNatIfcCmd $iface_name]
	}

	set primary 1
	set addrs4 [getIfcIPv4addrs $node_id $iface_id]
	setToRunning "${node_id}|${iface_id}_old_ipv4_addrs" $addrs4
	foreach addr $addrs4 {
		if { $addr != "" } {
			lappend cfg [getIPv4IfcCmd $iface_name $addr $primary]
			set primary 0
		}
	}

	set primary 1
	set addrs6 [getIfcIPv6addrs $node_id $iface_id]
	setToRunning "${node_id}|${iface_id}_old_ipv6_addrs" $addrs6
	if { $isOSlinux } {
		# Linux is prioritizing IPv6 addresses in reversed order
		set addrs6 [lreverse $addrs6]
	}
	foreach addr $addrs6 {
		if { $addr != "" } {
			lappend cfg [getIPv6IfcCmd $iface_name $addr $primary]
			set primary 0
		}
	}

	set state [getIfcOperState $node_id $iface_id]
	if { $state == "" } {
		set state "up"
	}

	lappend cfg [getStateIfcCmd $iface_name $state]

	return $cfg
}

proc nodeUncfggenIfc { node_id iface_id } {
	set cfg {}

	set iface_name [getIfcName $node_id $iface_id]

	set addrs4 [getFromRunning "${node_id}|${iface_id}_old_ipv4_addrs"]
	foreach addr $addrs4 {
		if { $addr != "" } {
			lappend cfg [getDelIPv4IfcCmd $iface_name $addr]
		}
	}
	unsetRunning "${node_id}|${iface_id}_old_ipv4_addrs"

	set addrs4 [getFromRunning "${node_id}|${iface_id}_old_ipv6_addrs"]
	foreach addr $addrs4 {
		if { $addr != "" } {
			lappend cfg [getDelIPv6IfcCmd $iface_name $addr]
		}
	}
	unsetRunning "${node_id}|${iface_id}_old_ipv6_addrs"

	return $cfg
}

proc routerCfggenIfc { node_id iface_id } {
	set ospf_enabled [getNodeProtocol $node_id "ospf"]
	set ospf6_enabled [getNodeProtocol $node_id "ospf6"]

	set cfg {}

	set model [getNodeModel $node_id]
	set iface_name [getIfcName $node_id $iface_id]
	if { $iface_name == "lo0" } {
		set model "static"
	}

	switch -exact -- $model {
		"quagga" -
		"frr" {
			set mac_addr [getIfcMACaddr $node_id $iface_id]
			if { $mac_addr != "" } {
				lappend cfg [getMacIfcCmd $iface_name $mac_addr]
			}

			set mtu [getIfcMTU $node_id $iface_id]
			lappend cfg [getMtuIfcCmd $iface_name $mtu]

			if { [getIfcNatState $node_id $iface_id] == "on" } {
				lappend cfg [getNatIfcCmd $iface_name]
			}

			lappend cfg "vtysh << __EOF__"
			lappend cfg "conf term"
			lappend cfg "interface $iface_name"

			set addrs4 [getIfcIPv4addrs $node_id $iface_id]
			setToRunning "${node_id}|${iface_id}_old_ipv4_addrs" $addrs4
			if { $addrs4 != "dhcp" } {
				foreach addr $addrs4 {
					if { $addr != "" } {
						lappend cfg " ip address $addr"
					}
				}
			}

			if { $ospf_enabled } {
				if { ! [isIfcLogical $node_id $iface_id] } {
					lappend cfg " ip ospf area 0.0.0.0"
				}
			}

			set addrs6 [getIfcIPv6addrs $node_id $iface_id]
			setToRunning "${node_id}|${iface_id}_old_ipv6_addrs" $addrs6
			foreach addr $addrs6 {
				if { $addr != "" } {
					lappend cfg " ipv6 address $addr"
				}
			}

			if { $model == "frr" && $ospf6_enabled } {
				if { ! [isIfcLogical $node_id $iface_id] } {
					lappend cfg " ipv6 ospf6 area 0.0.0.0"
				}
			}

			if { [getIfcOperState $node_id $iface_id] == "down" } {
				lappend cfg " shutdown"
			} else {
				lappend cfg " no shutdown"
			}

			lappend cfg "!"
			lappend cfg "__EOF__"

			if { $addrs4 == "dhcp" } {
				lappend cfg "[getIPv4IfcCmd $iface_name $addrs4 1]"
			}
		}
		"static" {
			set cfg [concat $cfg [nodeCfggenIfc $node_id $iface_id]]
		}
	}

	return $cfg
}

proc routerUncfggenIfc { node_id iface_id } {
	set ospf_enabled [getNodeProtocol $node_id "ospf"]
	set ospf6_enabled [getNodeProtocol $node_id "ospf6"]

	set cfg {}

	set model [getNodeModel $node_id]
	set iface_name [getIfcName $node_id $iface_id]
	if { $iface_name == "lo0" } {
		set model "static"
	}

	switch -exact -- $model {
		"quagga" -
		"frr" {
			lappend cfg "vtysh << __EOF__"
			lappend cfg "conf term"
			lappend cfg "interface $iface_name"

			set addrs4 [getFromRunning "${node_id}|${iface_id}_old_ipv4_addrs"]
			if { $addrs4 != "dhcp" } {
				foreach addr $addrs4 {
					if { $addr != "" } {
						lappend cfg " no ip address $addr"
					}
				}
			}

			if { $ospf_enabled } {
				if { ! [isIfcLogical $node_id $iface_id] } {
					lappend cfg " no ip ospf area 0.0.0.0"
				}
			}

			set addrs6 [getFromRunning "${node_id}|${iface_id}_old_ipv6_addrs"]
			foreach addr $addrs6 {
				if { $addr != "" } {
					lappend cfg " no ipv6 address $addr"
				}
			}

			if { $model == "frr" && $ospf6_enabled } {
				if { ! [isIfcLogical $node_id $iface_id] } {
					lappend cfg " no ipv6 ospf6 area 0.0.0.0"
				}
			}

			lappend cfg " shutdown"

			lappend cfg "!"
			lappend cfg "__EOF__"

			if { $addrs4 == "dhcp" } {
				lappend cfg "[getDelIPv4IfcCmd $iface_name $addrs4]"
			}
		}
		"static" {
			set cfg [concat $cfg [nodeUncfggenIfc $node_id $iface_id]]
		}
	}

	return $cfg
}

proc updateIface { node_id iface_id old_iface_cfg new_iface_cfg } {
	global changed

	dputs ""
	dputs "= /UPDATE IFACE $node_id $iface_id START ="

	if { $old_iface_cfg == "*" } {
		set old_iface_cfg [cfgGet "nodes" $node_id "ifaces" $iface_id]
	}

	dputs "OLD : '$old_iface_cfg'"
	dputs "NEW : '$new_iface_cfg'"

	set cfg_diff [dictDiff $old_iface_cfg $new_iface_cfg]
	dputs "= cfg_diff: '$cfg_diff'"
	if { $cfg_diff == "" || [lsort -uniq [dict values $cfg_diff]] == "copy" } {
		dputs "= NO CHANGE"
		dputs "= /UPDATE IFACE $node_id $iface_id END ="
		return $new_iface_cfg
	}

	if { $new_iface_cfg == "" } {
		return $old_iface_cfg
	}

	if { [getFromRunning "cfg_deployed"] && [getFromRunning "auto_execution"] } {
		setToExecuteVars "terminate_cfg" [cfgGet]
	}

	dict for {iface_prop_key iface_prop_change} $cfg_diff {
		if { $iface_prop_change == "copy" } {
			continue
		}

		# trigger undo log
		set changed 1

		set iface_prop_old_value [_cfgGet $old_iface_cfg $iface_prop_key]
		set iface_prop_new_value [_cfgGet $new_iface_cfg $iface_prop_key]
		dputs "============ $iface_prop_change: '$iface_prop_key'"
		if { $iface_prop_change in "changed" } {
			dputs "============ OLD: '$iface_prop_old_value'"
		}
		if { $iface_prop_change in "new changed" } {
			dputs "============ NEW: '$iface_prop_new_value'"
		}

		switch -exact $iface_prop_key {
			"link" {
				# link cannot be changed, only removed
				if { $iface_prop_change == "removed" } {
					removeLink $iface_prop_old_value 1
				}
			}

			"type" {
				setIfcType $node_id $iface_id $iface_prop_new_value
			}

			"name" {
				setIfcName $node_id $iface_id $iface_prop_new_value
			}

			"oper_state" {
				setIfcOperState $node_id $iface_id $iface_prop_new_value
			}

			"nat_state" {
				setIfcNatState $node_id $iface_id $iface_prop_new_value
			}

			"mtu" {
				setIfcMTU $node_id $iface_id $iface_prop_new_value
			}

			"ifc_qdisc" {
				setIfcQDisc $node_id $iface_id $iface_prop_new_value
			}

			"ifc_qdrop" {
				setIfcQDrop $node_id $iface_id $iface_prop_new_value
			}

			"queue_len" {
				setIfcQLen $node_id $iface_id $iface_prop_new_value
			}

			"vlan_dev" {
				setIfcVlanDev $node_id $iface_id $iface_prop_new_value
			}

			"vlan_tag" {
				setIfcVlanTag $node_id $iface_id $iface_prop_new_value
			}

			"vlan_type" {
				setIfcVlanType $node_id $iface_id $iface_prop_new_value
			}

			"mac" {
				if { $iface_prop_new_value == "auto" } {
					autoMACaddr $node_id $iface_id
				} else {
					setIfcMACaddr $node_id $iface_id $iface_prop_new_value
				}
			}

			"ipv4_addrs" {
				if { $iface_prop_new_value == "auto" } {
					autoIPv4addr $node_id $iface_id
				} else {
					setIfcIPv4addrs $node_id $iface_id $iface_prop_new_value
				}
			}

			"ipv6_addrs" {
				if { $iface_prop_new_value == "auto" } {
					autoIPv6addr $node_id $iface_id
				} else {
					setIfcIPv6addrs $node_id $iface_id $iface_prop_new_value
				}
			}

			"filter_rules" {
				clearFilterIfcRules $node_id $iface_id

				foreach {rule_id rule_cfg} $iface_prop_new_value {
					addFilterIfcRule $node_id $iface_id $rule_id $rule_cfg
				}
			}

			"stp_discover" {
				setBridgeIfcDiscover $node_id $iface_id $iface_prop_new_value
			}

			"stp_learn" {
				setBridgeIfcLearn $node_id $iface_id $iface_prop_new_value
			}

			"stp_sticky" {
				setBridgeIfcSticky $node_id $iface_id $iface_prop_new_value
			}

			"stp_private" {
				setBridgeIfcPrivate $node_id $iface_id $iface_prop_new_value
			}

			"stp_snoop" {
				setBridgeIfcSnoop $node_id $iface_id $iface_prop_new_value
			}

			"stp_enabled" {
				setBridgeIfcStp $node_id $iface_id $iface_prop_new_value
			}

			"stp_edge" {
				setBridgeIfcEdge $node_id $iface_id $iface_prop_new_value
			}

			"stp_autoedge" {
				setBridgeIfcAutoedge $node_id $iface_id $iface_prop_new_value
			}

			"stp_ptp" {
				setBridgeIfcPtp $node_id $iface_id $iface_prop_new_value
			}

			"stp_autoptp" {
				setBridgeIfcAutoptp $node_id $iface_id $iface_prop_new_value
			}

			"stp_priority" {
				setBridgeIfcPriority $node_id $iface_id $iface_prop_new_value
			}

			"stp_path_cost" {
				setBridgeIfcPathcost $node_id $iface_id $iface_prop_new_value
			}

			"stp_max_addresses" {
				setBridgeIfcMaxaddr $node_id $iface_id $iface_prop_new_value
			}

			default {
				# do nothing
			}
		}
	}

	if { $changed } {
		# will reset 'changed' to 0
		updateUndoLog

		# changed needs to be 1 to trigger redrawing
		set changed 1
	}

	dputs "= /UPDATE IFACE $node_id $iface_id END ="
	dputs ""

	return $new_iface_cfg
}
