# GUI procs
###########################
proc _getBridgeProtocol { node_cfg } {
	return [_cfgGet $node_cfg "bridge" "protocol"]
}

proc _setBridgeProtocol { node_cfg protocol } {
	return [_cfgSet $node_cfg "bridge" "protocol" $protocol]
}

proc _getBridgePriority { node_cfg } {
	return [_cfgGetWithDefault 32768 $node_cfg "bridge" "priority"]
}

proc _setBridgePriority { node_cfg priority } {
	return [_cfgSet $node_cfg "bridge" "priority" $priority]
}

proc _getBridgeHoldCount { node_cfg } {
	return [_cfgGetWithDefault 6 $node_cfg "bridge" "hold_count"]
}

proc _setBridgeHoldCount { node_cfg hold_count } {
	return [_cfgSet $node_cfg "bridge" "hold_count" $hold_count]
}

proc _getBridgeMaxAge { node_cfg } {
	return [_cfgGetWithDefault 20 $node_cfg "bridge" "max_age"]
}

proc _setBridgeMaxAge { node_cfg max_age } {
	return [_cfgSet $node_cfg "bridge" "max_age" $max_age]
}

proc _getBridgeFwdDelay { node_cfg } {
	return [_cfgGetWithDefault 15 $node_cfg "bridge" "forwarding_delay"]
}

proc _setBridgeFwdDelay { node_cfg forwarding_delay } {
	return [_cfgSet $node_cfg "bridge" "forwarding_delay" $forwarding_delay]
}

proc _getBridgeHelloTime { node_cfg } {
	return [_cfgGetWithDefault 2 $node_cfg "bridge" "hello_time"]
}

proc _setBridgeHelloTime { node_cfg hello_time } {
	return [_cfgSet $node_cfg "bridge" "hello_time" $hello_time]
}

proc _getBridgeMaxAddr { node_cfg } {
	return [_cfgGetWithDefault 100 $node_cfg "bridge" "max_addresses"]
}

proc _setBridgeMaxAddr { node_cfg max_addresses } {
	return [_cfgSet $node_cfg "bridge" "max_addresses" $max_addresses]
}

proc _getBridgeTimeout { node_cfg } {
	return [_cfgGetWithDefault 240 $node_cfg "bridge" "address_timeout"]
}

proc _setBridgeTimeout { node_cfg address_timeout } {
	return [_cfgSet $node_cfg "bridge" "address_timeout" $address_timeout]
}

#####
#####BridgeIfcSettings
#####

proc _getBridgeIfcDiscover { node_cfg iface } {
	return [_cfgGetWithDefault 0 $node_cfg "ifaces" $iface "stp_discover"]
}

proc _setBridgeIfcDiscover { node_cfg iface stp_discover } {
	return [_cfgSet $node_cfg "ifaces" $iface "stp_discover" $stp_discover]
}

proc _getBridgeIfcLearn { node_cfg iface } {
	return [_cfgGetWithDefault 0 $node_cfg "ifaces" $iface "stp_learn"]
}

proc _setBridgeIfcLearn { node_cfg iface stp_learn } {
	return [_cfgSet $node_cfg "ifaces" $iface "stp_learn" $stp_learn]
}

proc _getBridgeIfcSticky { node_cfg iface } {
	return [_cfgGetWithDefault 0 $node_cfg "ifaces" $iface "stp_sticky"]
}

proc _setBridgeIfcSticky { node_cfg iface stp_sticky } {
	return [_cfgSet $node_cfg "ifaces" $iface "stp_sticky" $stp_sticky]
}

proc _getBridgeIfcPrivate { node_cfg iface } {
	return [_cfgGetWithDefault 0 $node_cfg "ifaces" $iface "stp_private"]
}

proc _setBridgeIfcPrivate { node_cfg iface stp_private } {
	return [_cfgSet $node_cfg "ifaces" $iface "stp_private" $stp_private]
}

proc _getBridgeIfcSnoop { node_cfg iface } {
	return [_cfgGetWithDefault 0 $node_cfg "ifaces" $iface "stp_snoop"]
}

proc _setBridgeIfcSnoop { node_cfg iface stp_snoop } {
	return [_cfgSet $node_cfg "ifaces" $iface "stp_snoop" $stp_snoop]
}

proc _getBridgeIfcStp { node_cfg iface } {
	return [_cfgGetWithDefault 0 $node_cfg "ifaces" $iface "stp_enabled"]
}

proc _setBridgeIfcStp { node_cfg iface stp_enabled } {
	return [_cfgSet $node_cfg "ifaces" $iface "stp_enabled" $stp_enabled]
}

proc _getBridgeIfcEdge { node_cfg iface } {
	return [_cfgGetWithDefault 0 $node_cfg "ifaces" $iface "stp_edge"]
}

proc _setBridgeIfcEdge { node_cfg iface stp_edge } {
	return [_cfgSet $node_cfg "ifaces" $iface "stp_edge" $stp_edge]
}

proc _getBridgeIfcAutoedge { node_cfg iface } {
	return [_cfgGetWithDefault 0 $node_cfg "ifaces" $iface "stp_autoedge"]
}

proc _setBridgeIfcAutoedge { node_cfg iface stp_autoedge } {
	return [_cfgSet $node_cfg "ifaces" $iface "stp_autoedge" $stp_autoedge]
}

proc _getBridgeIfcPtp { node_cfg iface } {
	return [_cfgGetWithDefault 0 $node_cfg "ifaces" $iface "stp_ptp"]
}

proc _setBridgeIfcPtp { node_cfg iface stp_ptp } {
	return [_cfgSet $node_cfg "ifaces" $iface "stp_ptp" $stp_ptp]
}

proc _getBridgeIfcAutoptp { node_cfg iface } {
	return [_cfgGetWithDefault 0 $node_cfg "ifaces" $iface "stp_autoptp"]
}

proc _setBridgeIfcAutoptp { node_cfg iface stp_autoptp } {
	return [_cfgSet $node_cfg "ifaces" $iface "stp_autoptp" $stp_autoptp]
}

####IfcParameters

proc _getBridgeIfcPriority { node_cfg iface } {
	return [_cfgGet $node_cfg "ifaces" $iface "stp_priority"]
}

proc _setBridgeIfcPriority { node_cfg iface stp_priority } {
	return [_cfgSet $node_cfg "ifaces" $iface "stp_priority" $stp_priority]
}

proc _getBridgeIfcPathcost { node_cfg iface } {
	return [_cfgGet $node_cfg "ifaces" $iface "stp_path_cost"]
}

proc _setBridgeIfcPathcost { node_cfg iface stp_path_cost } {
	return [_cfgSet $node_cfg "ifaces" $iface "stp_path_cost" $stp_path_cost]
}

proc _getBridgeIfcMaxaddr { node_cfg iface } {
	return [_cfgGet $node_cfg "ifaces" $iface "stp_max_addresses"]
}

proc _setBridgeIfcMaxaddr { node_cfg iface stp_max_addresses } {
	return [_cfgSet $node_cfg "ifaces" $iface "stp_max_addresses" $stp_max_addresses]
}
