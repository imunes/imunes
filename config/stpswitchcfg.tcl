proc getBridgeProtocol { node_id } {
    return [_cfgGet $node_id "bridge" "protocol"]
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

proc getBridgeIfcDiscover { node_id iface } {
    return [cfgGetWithDefault 0 "nodes" $node_id "ifaces" $iface "stp_discover"]
}

proc setBridgeIfcDiscover { node_id iface stp_discover } {
    cfgSet "nodes" $node_id "ifaces" $iface "stp_discover" $stp_discover
}

proc getBridgeIfcLearn { node_id iface } {
    return [cfgGetWithDefault 0 "nodes" $node_id "ifaces" $iface "stp_learn"]
}

proc setBridgeIfcLearn { node_id iface stp_learn } {
    cfgSet "nodes" $node_id "ifaces" $iface "stp_learn" $stp_learn
}

proc getBridgeIfcSticky { node_id iface } {
    return [cfgGetWithDefault 0 "nodes" $node_id "ifaces" $iface "stp_sticky"]
}

proc setBridgeIfcSticky { node_id iface stp_sticky } {
    cfgSet "nodes" $node_id "ifaces" $iface "stp_sticky" $stp_sticky
}

proc getBridgeIfcPrivate { node_id iface } {
    return [cfgGetWithDefault 0 "nodes" $node_id "ifaces" $iface "stp_private"]
}

proc setBridgeIfcPrivate { node_id iface stp_private } {
    cfgSet "nodes" $node_id "ifaces" $iface "stp_private" $stp_private
}

proc getBridgeIfcSnoop { node_id iface } {
    return [cfgGetWithDefault 0 "nodes" $node_id "ifaces" $iface "stp_snoop"]
}

proc setBridgeIfcSnoop { node_id iface stp_snoop } {
    cfgSet "nodes" $node_id "ifaces" $iface "stp_snoop" $stp_snoop
}

proc getBridgeIfcStp { node_id iface } {
    return [cfgGetWithDefault 0 "nodes" $node_id "ifaces" $iface "stp_enabled"]
}

proc setBridgeIfcStp { node_id iface stp_enabled } {
    cfgSet "nodes" $node_id "ifaces" $iface "stp_enabled" $stp_enabled
}

proc getBridgeIfcEdge { node_id iface } {
    return [cfgGetWithDefault 0 "nodes" $node_id "ifaces" $iface "stp_edge"]
}

proc setBridgeIfcEdge { node_id iface stp_edge } {
    cfgSet "nodes" $node_id "ifaces" $iface "stp_edge" $stp_edge
}

proc getBridgeIfcAutoedge { node_id iface } {
    return [cfgGetWithDefault 0 "nodes" $node_id "ifaces" $iface "stp_autoedge"]
}

proc setBridgeIfcAutoedge { node_id iface stp_autoedge } {
    cfgSet "nodes" $node_id "ifaces" $iface "stp_autoedge" $stp_autoedge
}

proc getBridgeIfcPtp { node_id iface } {
    return [cfgGetWithDefault 0 "nodes" $node_id "ifaces" $iface "stp_ptp"]
}

proc setBridgeIfcPtp { node_id iface stp_ptp } {
    cfgSet "nodes" $node_id "ifaces" $iface "stp_ptp" $stp_ptp
}

proc getBridgeIfcAutoptp { node_id iface } {
    return [cfgGetWithDefault 0 "nodes" $node_id "ifaces" $iface "stp_autoptp"]
}

proc setBridgeIfcAutoptp { node_id iface stp_autoptp } {
    cfgSet "nodes" $node_id "ifaces" $iface "stp_autoptp" $stp_autoptp
}

####IfcParameters

proc getBridgeIfcPriority { node_id iface } {
    return [cfgGet "nodes" $node_id "ifaces" $iface "stp_priority"]
}

proc setBridgeIfcPriority { node_id iface stp_priority } {
    cfgSet "nodes" $node_id "ifaces" $iface "stp_priority" $stp_priority
}

proc getBridgeIfcPathcost { node_id iface } {
    return [cfgGet "nodes" $node_id "ifaces" $iface "stp_path_cost"]
}

proc setBridgeIfcPathcost { node_id iface stp_path_cost } {
    cfgSet "nodes" $node_id "ifaces" $iface "stp_path_cost" $stp_path_cost
}

proc getBridgeIfcMaxaddr { node_id iface } {
    return [cfgGet "nodes" $node_id "ifaces" $iface "stp_max_addresses"]
}

proc setBridgeIfcMaxaddr { node_id iface stp_max_addresses } {
    cfgSet "nodes" $node_id "ifaces" $iface "stp_max_addresses" $stp_max_addresses
}

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
