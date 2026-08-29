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

#****f* nodes.tcl/getNodeCustomEnabled
# NAME
#   getNodeCustomEnabled -- get custom configuration enabled state
# SYNOPSIS
#   set enabled [getNodeCustomEnabled $node_id]
# FUNCTION
#   For input node this procedure returns true if custom configuration is
#   enabled for the specified node.
# INPUTS
#   * node_id -- node id
# RESULT
#   * state -- returns true if custom configuration is enabled
#****
proc getNodeCustomEnabled { node_id } {
	return [cfgGetWithDefault "false" "nodes" $node_id "custom_enabled"]
}

#****f* nodes.tcl/setNodeCustomEnabled
# NAME
#   setNodeCustomEnabled -- set custom configuration enabled state
# SYNOPSIS
#   setNodeCustomEnabled $node_id $state
# FUNCTION
#   For input node this procedure enables or disables custom configuration.
# INPUTS
#   * node_id -- node id
#   * state -- true if enabling custom configuration, false if disabling
#****
proc setNodeCustomEnabled { node_id state } {
	cfgSet "nodes" $node_id "custom_enabled" $state

	if { [getNodeCustomConfigSelected $node_id "NODE_CONFIG"] ni "\"\" DISABLED" } {
		trigger_nodeReconfig $node_id
	}

	if { [getNodeCustomConfigSelected $node_id "IFACES_CONFIG"] ni "\"\" DISABLED" } {
		foreach iface_id [allIfcList $node_id] {
			trigger_ifaceReconfig $node_id $iface_id
		}
	}
}

#****f* nodes.tcl/getNodeCustomConfigSelected
# NAME
#   getNodeCustomConfigSelected -- get default custom configuration
# SYNOPSIS
#   getNodeCustomConfigSelected $node_id
# FUNCTION
#   For input node this procedure returns ID of a default configuration
# INPUTS
#   * node_id -- node id
# RESULT
#   * cfg_id -- returns default custom configuration ID
#****
proc getNodeCustomConfigSelected { node_id hook } {
	return [cfgGet "nodes" $node_id "custom_selected" $hook]
}

#****f* nodes.tcl/setNodeCustomConfigSelected
# NAME
#   setNodeCustomConfigSelected -- set default custom configuration
# SYNOPSIS
#   setNodeCustomConfigSelected $node_id
# FUNCTION
#   For input node this procedure sets ID of a default configuration
# INPUTS
#   * node_id -- node id
#   * cfg_id -- custom-config id
#****
proc setNodeCustomConfigSelected { node_id hook cfg_id } {
	cfgSet "nodes" $node_id "custom_selected" $hook $cfg_id

	if { ! [getNodeCustomEnabled $node_id] } {
		return
	}

	if { [getNodeCustomEnabled $node_id] } {
		if { $hook == "NODE_CONFIG" } {
			trigger_nodeReconfig $node_id
		} elseif { $hook == "IFACES_CONFIG" } {
			foreach iface_id [allIfcList $node_id] {
				trigger_ifaceReconfig $node_id $iface_id
			}
		}
	}
}

#****f* nodes.tcl/getNodeCustomConfig
# NAME
#   getNodeCustomConfig -- get custom configuration
# SYNOPSIS
#   getNodeCustomConfig $node_id $cfg_id
# FUNCTION
#   For input node and configuration ID this procedure returns custom
#   configuration.
# INPUTS
#   * node_id -- node id
#   * cfg_id -- configuration id
# RESULT
#   * customConfig -- returns custom configuration
#****
proc getNodeCustomConfig { node_id hook cfg_id } {
	return [cfgGet "nodes" $node_id "custom_configs" $hook $cfg_id "custom_config"]
}

#****f* nodes.tcl/setNodeCustomConfig
# NAME
#   setNodeCustomConfig -- set custom configuration
# SYNOPSIS
#   setNodeCustomConfig $node_id $cfg_id $cmd $config
# FUNCTION
#   For input node this procedure sets custom configuration section in input
#   node.
# INPUTS
#   * node_id -- node id
#   * cfg_id -- custom-config id
#   * cmd -- custom command
#   * config -- custom configuration section
#****
proc setNodeCustomConfig { node_id hook cfg_id cmd config } {
	# XXX cannot be empty
	cfgSetEmpty "nodes" $node_id "custom_configs" $hook $cfg_id "custom_command" $cmd
	cfgSetEmpty "nodes" $node_id "custom_configs" $hook $cfg_id "custom_config" $config

	if { ! [getNodeCustomEnabled $node_id] || [getNodeCustomConfigSelected $node_id $hook] != $cfg_id } {
		return
	}

	if { [getNodeCustomEnabled $node_id] } {
		if { $hook == "NODE_CONFIG" } {
			trigger_nodeReconfig $node_id
		} elseif { $hook == "IFACES_CONFIG" } {
			foreach iface_id [allIfcList $node_id] {
				trigger_ifaceReconfig $node_id $iface_id
			}
		}
	}
}

#****f* nodes.tcl/removeNodeCustomConfig
# NAME
#   removeNodeCustomConfig -- remove custom configuration
# SYNOPSIS
#   removeNodeCustomConfig $node_id $cfg_id
# FUNCTION
#   For input node and configuration ID this procedure removes custom
#   configuration from node.
# INPUTS
#   * node_id -- node id
#   * cfg_id -- configuration id
#****
proc removeNodeCustomConfig { node_id hook cfg_id } {
	cfgUnset "nodes" $node_id "custom_configs" $hook $cfg_id
}

#****f* nodes.tcl/getNodeCustomConfigCommand
# NAME
#   getNodeCustomConfigCommand -- get custom configuration boot command
# SYNOPSIS
#   getNodeCustomConfigCommand $node_id $cfg_id
# FUNCTION
#   For input node and configuration ID this procedure returns custom
#   configuration boot command.
# INPUTS
#   * node_id -- node id
#   * cfg_id -- configuration id
# RESULT
#   * customCmd -- returns custom configuration boot command
#****
proc getNodeCustomConfigCommand { node_id hook cfg_id } {
	return [cfgGet "nodes" $node_id "custom_configs" $hook $cfg_id "custom_command"]
}

#****f* nodes.tcl/getNodeStatIPv4routes
# NAME
#   getNodeStatIPv4routes -- get static IPv4 routes.
# SYNOPSIS
#   set routes [getNodeStatIPv4routes $node_id]
# FUNCTION
#   Returns a list of all static IPv4 routes as a list of
#   {destination gateway {metric}} pairs.
# INPUTS
#   * node_id -- node id
# RESULT
#   * routes -- list of all static routes defined for the specified node
#****
proc getNodeStatIPv4routes { node_id } {
	return [cfgGet "nodes" $node_id "croutes4"]
}

#****f* nodes.tcl/setNodeStatIPv4routes
# NAME
#   setNodeStatIPv4routes -- set static IPv4 routes.
# SYNOPSIS
#   setNodeStatIPv4routes $node_id $routes
# FUNCTION
#   Replace all current static route entries with a new one, in form of a list
#   of {destination gateway {metric}} pairs.
# INPUTS
#   * node_id -- the node id of the node whose static routes are set.
#   * routes -- list of all static routes defined for the specified node
#****
proc setNodeStatIPv4routes { node_id routes } {
	cfgSet "nodes" $node_id "croutes4" $routes

	if {
		[getNodeCustomEnabled $node_id] &&
		[getNodeCustomConfigSelected $node_id "NODE_CONFIG"] ni "\"\" DISABLED"
	} {
		return
	}

	trigger_nodeReconfig $node_id
}

#****f* nodes.tcl/getNodeStatIPv6routes
# NAME
#   getNodeStatIPv6routes -- get static IPv6 routes.
# SYNOPSIS
#   set routes [getNodeStatIPv6routes $node_id]
# FUNCTION
#   Returns a list of all static IPv6 routes as a list of
#   {destination gateway {metric}} pairs.
# INPUTS
#   * node_id -- node id
# RESULT
#   * routes -- list of all static routes defined for the specified node
#****
proc getNodeStatIPv6routes { node_id } {
	return [cfgGet "nodes" $node_id "croutes6"]
}

#****f* nodes.tcl/setNodeStatIPv6routes
# NAME
#   setNodeStatIPv6routes -- set static IPv6 routes.
# SYNOPSIS
#   setNodeStatIPv6routes $node_id $routes
# FUNCTION
#   Replace all current static route entries with a new one, in form of a list
#   of {destination gateway {metric}} pairs.
# INPUTS
#   * node_id -- node id
#   * routes -- list of all static routes defined for the specified node
#****
proc setNodeStatIPv6routes { node_id routes } {
	cfgSet "nodes" $node_id "croutes6" $routes

	if {
		[getNodeCustomEnabled $node_id] &&
		[getNodeCustomConfigSelected $node_id "NODE_CONFIG"] ni "\"\" DISABLED"
	} {
		return
	}

	trigger_nodeReconfig $node_id
}

#****f* nodes.tcl/getNodeName
# NAME
#   getNodeName -- get node name.
# SYNOPSIS
#   set name [getNodeName $node_id]
# FUNCTION
#   Returns node's logical name.
# INPUTS
#   * node_id -- node id
# RESULT
#   * name -- logical name of the node
#****
proc getNodeName { node_id } {
	return [cfgGet "nodes" $node_id "name"]
}

#****f* nodes.tcl/setNodeName
# NAME
#   setNodeName -- set node name.
# SYNOPSIS
#   setNodeName $node_id $name
# FUNCTION
#   Sets node's logical name.
# INPUTS
#   * node_id -- node id
#   * name -- logical name of the node
#****
proc setNodeName { node_id name } {
	cfgSet "nodes" $node_id "name" $name

	set node_type [getNodeType $node_id]
	recalculateNumType $node_type [invokeTypeProc $node_type "namingBase"]

	if { [invokeNodeProc $node_id "virtlayer"] == "NATIVE" } {
		return
	}

	trigger_nodeRecreate $node_id
}

#****f* nodes.tcl/setNodeNATIface
# NAME
#   setNodeNATIface -- set node NAT interface.
# SYNOPSIS
#   setNodeNATIface $node_id $name
# FUNCTION
#   Sets node's nat interface.
# INPUTS
#   * node_id -- node id
#   * nat_iface -- nat interface
#****
proc setNodeNATIface { node_id nat_iface } {
	set iface_id [lindex [ifcList $node_id] 0]

	set old_interface [getNodeNATIface $node_id]
	set old_priority [invokeNodeProc $node_id "getSubnetPriority" $node_id $iface_id]

	cfgSet "nodes" $node_id "nat_iface" $nat_iface
	trigger_nodeReconfig $node_id

	set new_priority [invokeNodeProc $node_id "getSubnetPriority" $node_id $iface_id]

	if {
		$old_interface != "UNASSIGNED" && $nat_iface != "UNASSIGNED" ||
		$old_interface == "UNASSIGNED" && $nat_iface == "UNASSIGNED"
	} {
		return
	}

	if { $old_priority > $new_priority } {
		set my_priority $old_priority
	} else {
		set my_priority $new_priority
	}
	foreach node_subnet_data [getSubnetIfaces $node_id $iface_id] {
		lassign $node_subnet_data node_priority subnet_node_id - -

		if {
			[getNodeAutoDefaultRoutesStatus $subnet_node_id] == "enabled" &&
			$my_priority > $node_priority
		} {
			trigger_nodeReconfig $subnet_node_id
		}
	}
}

#****f* nodes.tcl/getNodeNATIface
# NAME
#   getNodeNAtIface -- get node nat interface.
# SYNOPSIS
#   getNodeNATIface $node_id
# FUNCTION
#   Gets node's nat interface.
# INPUTS
#   * node_id -- node id
#****
proc getNodeNATIface { node_id } {
	set nat_iface [cfgGet "nodes" $node_id "nat_iface"]

	if { [string index $nat_iface 0] == "\$" } {
		set saved_nat_iface [getFromRunning "envvars::[string range $nat_iface 1 end]"]
		if { $saved_nat_iface != "" } {
			set nat_iface $saved_nat_iface
		}
	}

	return $nat_iface
}

#****f* nodes.tcl/getNodeType
# NAME
#   getNodeType -- get node type.
# SYNOPSIS
#   set type [getNodeType $node_id]
# FUNCTION
#   Returns node's type.
# INPUTS
#   * node_id -- node id
# RESULT
#   * type -- type of the node
#****
proc getNodeType { node_id } {
	return [cfgGet "nodes" $node_id "type"]
}

#****f* nodes.tcl/setNodeType
# NAME
#   setNodeType -- set node's type.
# SYNOPSIS
#   setNodeType $node_id $type
# FUNCTION
#   Sets node's type.
# INPUTS
#   * node_id -- node id
#   * type -- type of node
#****
proc setNodeType { node_id type } {
	set old_type [getNodeType $node_id]
	if { [getFromRunning "cfg_deployed"] } {
		set old_routes [appendNodeSubnetRoutes $node_id {}]
	}

	cfgSet "nodes" $node_id "type" $type

	trigger_nodeRecreate $node_id

	if { $old_type == "" || $old_type == $type } {
		return
	}

	# trigger other nodes reconfiguration if this node is/was a router
	if { $old_type == "router" || $type == "router" } {
		if { [getFromRunning "cfg_deployed"] } {
			set new_routes [appendNodeSubnetRoutes $node_id {}]
			triggerChangedDefaultRoutes $old_routes $new_routes
		}
	}
}

#****f* nodes.tcl/getNodeModel
# NAME
#   getNodeModel -- get node routing model.
# SYNOPSIS
#   set model [getNodeModel $node_id]
# FUNCTION
#   Returns node's optional routing model. Currently supported models are
#   frr, quagga and static and only nodes of type router have a defined model.
# INPUTS
#   * node_id -- node id
# RESULT
#   * model -- routing model of the specified node
#****
proc getNodeModel { node_id } {
	return [cfgGet "nodes" $node_id "model"]
}

#****f* nodes.tcl/setNodeModel
# NAME
#   setNodeModel -- set node routing model.
# SYNOPSIS
#   setNodeModel $node_id $model
# FUNCTION
#   Sets an optional routing model to the node. Currently supported models are
#   frr, quagga and static and only nodes of type router have a defined model.
# INPUTS
#   * node_id -- node id
#   * model -- routing model of the specified node
#****
proc setNodeModel { node_id model } {
	cfgSet "nodes" $node_id "model" $model

	trigger_nodeRecreate $node_id
}

#****f* nodes.tcl/getNodeSnapshot
# NAME
#   getNodeSnapshot -- get node snapshot image name.
# SYNOPSIS
#   set snapshot [getNodeSnapshot $node_id]
# FUNCTION
#   Returns node's snapshot name.
# INPUTS
#   * node_id -- node id
# RESULT
#   * snapshot -- snapshot name for the specified node
#****
proc getNodeSnapshot { node_id } {
	return [cfgGet "nodes" $node_id "snapshot"]
}

#****f* nodes.tcl/setNodeSnapshot
# NAME
#   setNodeSnapshot -- set node snapshot image name.
# SYNOPSIS
#   setNodeSnapshot $node_id $snapshot
# FUNCTION
#   Sets node's snapshot name.
# INPUTS
#   * node_id -- node id
#   * snapshot -- snapshot name for the specified node
#****
proc setNodeSnapshot { node_id snapshot } {
	cfgSet "nodes" $node_id "snapshot" $snapshot
}

#****f* nodes.tcl/getNodeCPUConf
# NAME
#   getNodeCPUConf -- get node's CPU configuration
# SYNOPSIS
#   set conf [getNodeCPUConf $node_id]
# FUNCTION
#   Returns node's CPU scheduling parameters { minp maxp weight }.
# INPUTS
#   * node_id -- node id
# RESULT
#   * conf -- node's CPU scheduling parameters { minp maxp weight }
#****
proc getNodeCPUConf { node_id } {
	return [cfgGet "nodes" $node_id "cpu"]
}

#****f* nodes.tcl/setNodeCPUConf
# NAME
#   setNodeCPUConf -- set node's CPU configuration
# SYNOPSIS
#   setNodeCPUConf $node_id $param_list
# FUNCTION
#   Sets the node's CPU scheduling parameters.
# INPUTS
#   * node_id -- node id
#   * param_list -- node's CPU scheduling parameters { minp maxp weight }
#****
proc setNodeCPUConf { node_id param_list } {
	cfgSet "nodes" $node_id "cpu" $param_list
}

proc getNodeAutoDefaultRoutesStatus { node_id } {
	return [cfgGetWithDefault "disabled" "nodes" $node_id "auto_default_routes"]
}

proc setNodeAutoDefaultRoutesStatus { node_id state } {
	cfgSet "nodes" $node_id "auto_default_routes" $state

	if { [getNodeCustomEnabled $node_id] == "true" } {
		return
	}

	trigger_nodeReconfig $node_id
}

#****f* nodes.tcl/getNodeProtocol
# NAME
#   getNodeProtocol
# SYNOPSIS
#   getNodeProtocol $node_id $protocol
# FUNCTION
#   Checks if node's protocol is enabled.
# INPUTS
#   * node_id -- node id
#   * protocol -- protocol to check
# RESULT
#   * check -- 1 if it is rip, otherwise 0
#****
proc getNodeProtocol { node_id protocol } {
	return [cfgGetWithDefault 0 "nodes" $node_id "router_config" $protocol]
}

#****f* nodes.tcl/setNodeProtocol
# NAME
#   setNodeProtocol
# SYNOPSIS
#   setNodeProtocol $node_id $protocol $state
# FUNCTION
#   Sets node's protocol state.
# INPUTS
#   * node_id -- node id
#   # protocol -- protocol to enable/disable
#   * state -- 1 if enabling protocol, 0 if disabling
#****
proc setNodeProtocol { node_id protocol state } {
	cfgSet "nodes" $node_id "router_config" $protocol $state

	# TODO: move [startRoutingDaemons] proc from [router.nodeInitConfigure]
	# and replace this with [trigger_nodeFullReconfig]
	if { [getNodeModel $node_id] != "static" } {
		trigger_nodeRecreate $node_id
	}
}

#****f* nodes.tcl/getNodeServices
# NAME
#   getNodeServices -- get node active services.
# SYNOPSIS
#   set services [getNodeServices $node_id]
# FUNCTION
#   Returns node's selected services.
# INPUTS
#   * node_id -- node id
# RESULT
#   * services -- active services
#****
proc getNodeServices { node_id } {
	return [cfgGet "nodes" $node_id "services"]
}

#****f* nodes.tcl/setNodeServices
# NAME
#   setNodeServices -- set node active services.
# SYNOPSIS
#   setNodeServices $node_id $services
# FUNCTION
#   Sets node selected services.
# INPUTS
#   * node_id -- node id
#   * services -- list of services
#****
proc setNodeServices { node_id services } {
	cfgSet "nodes" $node_id "services" $services
}

proc getNodeVlanFiltering { node_id } {
	return [cfgGetWithDefault 0 "nodes" $node_id "vlan_filtering"]
}

proc setNodeVlanFiltering { node_id state } {
	cfgSet "nodes" $node_id "vlan_filtering" $state

	trigger_nodeRecreate $node_id
}

proc getNodeIface { node_id iface_id } {
	return [cfgGet "nodes" $node_id "ifaces" $iface_id]
}

proc setNodeIface { node_id iface_id new_iface } {
	cfgSetEmpty "nodes" $node_id "ifaces" $iface_id $new_iface
}

#****f* nodes.tcl/getNodeIPsec
# NAME
#   getNodeIPsec -- retreives IPsec configuration for selected node
# SYNOPSIS
#   getNodeIPsec $node_id
# FUNCTION
#   Retreives all IPsec connections for current node
# INPUTS
#   node - node id
#****
proc getNodeIPsec { node_id } {
	return [cfgGet "nodes" $node_id "ipsec" "ipsec_configs"]
}

proc setNodeIPsec { node_id new_value } {
	cfgSet "nodes" $node_id "ipsec" "ipsec_configs" $new_value
}

#****f* nodes.tcl/getNodeIPsecItem
# NAME
#   getNodeIPsecItem -- get node IPsec item
# SYNOPSIS
#   getNodeIPsecItem $node_id $item
# FUNCTION
#   Retreives an item from IPsec configuration of given node
# INPUTS
#   node - node id
#   item - search item
proc getNodeIPsecItem { node_id item } {
	return [cfgGet "nodes" $node_id "ipsec" $item]
}

#****f* nodes.tcl/setNodeIPsecItem
# NAME
#   setNodeIPsecItem -- set node IPsec item
# SYNOPSIS
#   setNodeIPsecItem $node $item
# FUNCTION
#   Sets an item from IPsec configuration of given node
# INPUTS
#   node - node id
#   item - search item
proc setNodeIPsecItem { node_id item new_value } {
	cfgSet "nodes" $node_id "ipsec" $item $new_value

	# TODO: check services
	trigger_nodeRecreate $node_id
}

proc setNodeIPsecConnection { node_id connection new_value } {
	cfgSet "nodes" $node_id "ipsec" "ipsec_configs" $connection $new_value

	# TODO: check services
	trigger_nodeRecreate $node_id
}

proc delNodeIPsecConnection { node_id connection } {
	cfgUnset "nodes" $node_id "ipsec" "ipsec_configs" $connection

	if { $connection != "%default" } {
		# TODO: check services
		trigger_nodeRecreate $node_id
	}
}

proc getNodeIPsecSetting { node_id connection setting } {
	return [cfgGet "nodes" $node_id "ipsec" "ipsec_configs" $connection $setting]
}

proc setNodeIPsecSetting { node_id connection setting new_value } {
	cfgSet "nodes" $node_id "ipsec" "ipsec_configs" $connection $setting $new_value
}

proc getNodeGenericOptions { node_id type } {
    return [cfgGet "nodes" $node_id "advanced_options" "generic_options" $type]
}

proc setNodeGenericOptions { node_id type new_value } {
    cfgSet "nodes" $node_id "advanced_options" "generic_options" $type $new_value

	trigger_nodeRecreate $node_id
}

proc getNodeJailOptions { node_id type } {
    return [cfgGet "nodes" $node_id "advanced_options" "jail_options" $type]
}

proc setNodeJailOptions { node_id type new_value } {
    cfgSet "nodes" $node_id "advanced_options" "jail_options" $type $new_value

	trigger_nodeRecreate $node_id
}

proc getNodeDockerOptions { node_id type } {
    return [cfgGet "nodes" $node_id "advanced_options" "docker_options" $type]
}

proc setNodeDockerOptions { node_id type new_value } {
    cfgSet "nodes" $node_id "advanced_options" "docker_options" $type $new_value

	trigger_nodeRecreate $node_id
}
