proc getBridgeProtocol { node_id } {
	return [cfgGet $node_id "bridge" "protocol"]
}

proc setBridgeProtocol { node_id protocol } {
	cfgSet "nodes" $node_id "bridge" "protocol" $protocol
}

proc getBridgePriority { node_id } {
	return [cfgGetWithDefault 32768 "nodes" $node_id "bridge" "priority"]
}

proc setBridgePriority { node_id priority } {
	cfgSet "nodes" $node_id "bridge" "priority" $priority
}

proc getBridgeHoldCount { node_id } {
	return [cfgGetWithDefault 6 "nodes" $node_id "bridge" "hold_count"]
}

proc setBridgeHoldCount { node_id hold_count } {
	cfgSet "nodes" $node_id "bridge" "hold_count" $hold_count
}

proc getBridgeMaxAge { node_id } {
	return [cfgGetWithDefault 20 "nodes" $node_id "bridge" "max_age"]
}

proc setBridgeMaxAge { node_id max_age } {
	cfgSet "nodes" $node_id "bridge" "max_age" $max_age
}

proc getBridgeFwdDelay { node_id } {
	return [cfgGetWithDefault 15 "nodes" $node_id "bridge" "forwarding_delay"]
}

proc setBridgeFwdDelay { node_id forwarding_delay } {
	cfgSet "nodes" $node_id "bridge" "forwarding_delay" $forwarding_delay
}

proc getBridgeHelloTime { node_id } {
	return [cfgGetWithDefault 2 "nodes" $node_id "bridge" "hello_time"]
}

proc setBridgeHelloTime { node_id hello_time } {
	cfgSet "nodes" $node_id "bridge" "hello_time" $hello_time
}

proc getBridgeMaxAddr { node_id } {
	return [cfgGetWithDefault 100 "nodes" $node_id "bridge" "max_addresses"]
}

proc setBridgeMaxAddr { node_id max_addresses } {
	cfgSet "nodes" $node_id "bridge" "max_addresses" $max_addresses
}

proc getBridgeTimeout { node_id } {
	return [cfgGetWithDefault 240 "nodes" $node_id "bridge" "address_timeout"]
}

proc setBridgeTimeout { node_id address_timeout } {
	cfgSet "nodes" $node_id "bridge" "address_timeout" $address_timeout
}

#####
#####BridgeIfcSettings
#####

proc getBridgeIfcDiscover { node_id iface_id } {
	return [cfgGetWithDefault 0 "nodes" $node_id "ifaces" $iface_id "stp_discover"]
}

proc setBridgeIfcDiscover { node_id iface_id stp_discover } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "stp_discover" $stp_discover
}

proc getBridgeIfcLearn { node_id iface_id } {
	return [cfgGetWithDefault 0 "nodes" $node_id "ifaces" $iface_id "stp_learn"]
}

proc setBridgeIfcLearn { node_id iface_id stp_learn } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "stp_learn" $stp_learn
}

proc getBridgeIfcSticky { node_id iface_id } {
	return [cfgGetWithDefault 0 "nodes" $node_id "ifaces" $iface_id "stp_sticky"]
}

proc setBridgeIfcSticky { node_id iface_id stp_sticky } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "stp_sticky" $stp_sticky
}

proc getBridgeIfcPrivate { node_id iface_id } {
	return [cfgGetWithDefault 0 "nodes" $node_id "ifaces" $iface_id "stp_private"]
}

proc setBridgeIfcPrivate { node_id iface_id stp_private } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "stp_private" $stp_private
}

proc getBridgeIfcSnoop { node_id iface_id } {
	return [cfgGetWithDefault 0 "nodes" $node_id "ifaces" $iface_id "stp_snoop"]
}

proc setBridgeIfcSnoop { node_id iface_id stp_snoop } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "stp_snoop" $stp_snoop
}

proc getBridgeIfcStp { node_id iface_id } {
	return [cfgGetWithDefault 0 "nodes" $node_id "ifaces" $iface_id "stp_enabled"]
}

proc setBridgeIfcStp { node_id iface_id stp_enabled } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "stp_enabled" $stp_enabled
}

proc getBridgeIfcEdge { node_id iface_id } {
	return [cfgGetWithDefault 0 "nodes" $node_id "ifaces" $iface_id "stp_edge"]
}

proc setBridgeIfcEdge { node_id iface_id stp_edge } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "stp_edge" $stp_edge
}

proc getBridgeIfcAutoedge { node_id iface_id } {
	return [cfgGetWithDefault 0 "nodes" $node_id "ifaces" $iface_id "stp_autoedge"]
}

proc setBridgeIfcAutoedge { node_id iface_id stp_autoedge } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "stp_autoedge" $stp_autoedge
}

proc getBridgeIfcPtp { node_id iface_id } {
	return [cfgGetWithDefault 0 "nodes" $node_id "ifaces" $iface_id "stp_ptp"]
}

proc setBridgeIfcPtp { node_id iface_id stp_ptp } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "stp_ptp" $stp_ptp
}

proc getBridgeIfcAutoptp { node_id iface_id } {
	return [cfgGetWithDefault 0 "nodes" $node_id "ifaces" $iface_id "stp_autoptp"]
}

proc setBridgeIfcAutoptp { node_id iface_id stp_autoptp } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "stp_autoptp" $stp_autoptp
}

####IfcParameters

proc getBridgeIfcPriority { node_id iface_id } {
	return [cfgGet "nodes" $node_id "ifaces" $iface_id "stp_priority"]
}

proc setBridgeIfcPriority { node_id iface_id stp_priority } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "stp_priority" $stp_priority
}

proc getBridgeIfcPathcost { node_id iface_id } {
	return [cfgGet "nodes" $node_id "ifaces" $iface_id "stp_path_cost"]
}

proc setBridgeIfcPathcost { node_id iface_id stp_path_cost } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "stp_path_cost" $stp_path_cost
}

proc getBridgeIfcMaxaddr { node_id iface_id } {
	return [cfgGet "nodes" $node_id "ifaces" $iface_id "stp_max_addresses"]
}

proc setBridgeIfcMaxaddr { node_id iface_id stp_max_addresses } {
	cfgSet "nodes" $node_id "ifaces" $iface_id "stp_max_addresses" $stp_max_addresses
}
