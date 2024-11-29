proc getBridgeProtocol { node_id bridge } {
    foreach line [netconfFetchSection $node_id "bridge $bridge"] {
	if { [lindex $line 0] == "rstp" } {
	    return "rstp"
	}

	if { [lindex $line 0] == "stp" } {
	    return "stp"
	}
    }

    return rstp
}

proc setBridgeProtocol { node_id bridge protocol } {
    set ifcfg [list "bridge $bridge"]
    foreach line [netconfFetchSection $node_id "bridge $bridge"] {
	if { [lindex $line 0] != "stp" && [lindex $line 0] != "rstp" } {
	    lappend ifcfg $line
	}
    }

    if { $protocol in "stp rstp" } {
	lappend ifcfg " $protocol"
    }

    netconfInsertSection $node_id $ifcfg
}

proc getBridgePriority { node_id bridge } {
    foreach line [netconfFetchSection $node_id "bridge $bridge"] {
	if { [lindex $line 0] == "priority" } {
	    return [lindex $line 1]
	}
    }

    return 32768
}

proc setBridgePriority { node_id bridge priority } {
    set ifcfg [list "bridge $bridge"]
    foreach line [netconfFetchSection $node_id "bridge $bridge"] {
	if { [lindex $line 0] != "priority" } {
	    lappend ifcfg $line
	}
    }

    if { $priority >= 0 || $priority <= 61440 } {
	lappend ifcfg " priority $priority"
    }

    netconfInsertSection $node_id $ifcfg
}

proc getBridgeHoldCount { node_id bridge } {
    foreach line [netconfFetchSection $node_id "bridge $bridge"] {
	if { [lindex $line 0] == "holdcnt" } {
	    return [lindex $line 1]
	}
    }

    return 6
}

proc setBridgeHoldCount { node_id bridge hold_count } {
    set ifcfg [list "bridge $bridge"]
    foreach line [netconfFetchSection $node_id "bridge $bridge"] {
	if { [lindex $line 0] != "holdcnt" } {
	    lappend ifcfg $line
	}
    }

    if { $hold_count >= 1 || $hold_count <= 10 } {
	lappend ifcfg " holdcnt $hold_count"
    }

    netconfInsertSection $node_id $ifcfg
}

proc getBridgeMaxAge { node_id bridge } {
    foreach line [netconfFetchSection $node_id "bridge $bridge"] {
	if { [lindex $line 0] == "maxage" } {
	    return [lindex $line 1]
	}
    }

    return 20
}

proc setBridgeMaxAge { node_id bridge max_age } {
    set ifcfg [list "bridge $bridge"]
    foreach line [netconfFetchSection $node_id "bridge $bridge"] {
	if { [lindex $line 0] != "maxage" } {
	    lappend ifcfg $line
	}
    }

    if { $max_age >= 6 || $max_age <= 40 } {
	lappend ifcfg " maxage $max_age"
    }

    netconfInsertSection $node_id $ifcfg
}

proc getBridgeFwdDelay { node_id bridge } {
    foreach line [netconfFetchSection $node_id "bridge $bridge"] {
	if { [lindex $line 0] == "fwddelay" } {
	    return [lindex $line 1]
	}
    }

    return 15
}

proc setBridgeFwdDelay { node_id bridge forwarding_delay } {
    set ifcfg [list "bridge $bridge"]
    foreach line [netconfFetchSection $node_id "bridge $bridge"] {
	if { [lindex $line 0] != "fwddelay" } {
	    lappend ifcfg $line
	}
    }

    if { $forwarding_delay >= 4 || $forwarding_delay <= 30 } {
	lappend ifcfg " fwddelay $forwarding_delay"
    }

    netconfInsertSection $node_id $ifcfg
}

proc getBridgeHelloTime { node_id bridge } {
    foreach line [netconfFetchSection $node_id "bridge $bridge"] {
	if { [lindex $line 0] == "hellotime" } {
	    return [lindex $line 1]
	}
    }

    return 2
}

proc setBridgeHelloTime { node_id bridge hello_time } {
    set ifcfg [list "bridge $bridge"]
    foreach line [netconfFetchSection $node_id "bridge $bridge"] {
	if { [lindex $line 0] != "hellotime" } {
	    lappend ifcfg $line
	}
    }

    if { $hello_time >= 1 || $hello_time <= 2 } {
	lappend ifcfg " hellotime $hello_time"
    }

    netconfInsertSection $node_id $ifcfg
}

proc getBridgeMaxAddr { node_id bridge } {
    foreach line [netconfFetchSection $node_id "bridge $bridge"] {
	if { [lindex $line 0] == "maxaddr" } {
	    return [lindex $line 1]
	}
    }

    return 100
}

proc setBridgeMaxAddr { node_id bridge max_addresses } {
    set ifcfg [list "bridge $bridge"]
    foreach line [netconfFetchSection $node_id "bridge $bridge"] {
	if { [lindex $line 0] != "maxaddr" } {
	    lappend ifcfg $line
	}
    }

    if { $max_addresses >= 0 || $max_addresses <= 10000 } {
	lappend ifcfg " maxaddr $max_addresses"
    }

    netconfInsertSection $node_id $ifcfg
}

proc getBridgeTimeout { node_id bridge } {
    foreach line [netconfFetchSection $node_id "bridge $bridge"] {
	if { [lindex $line 0] == "timeout" } {
	    return [lindex $line 1]
	}
    }

    return 240
}

proc setBridgeTimeout { node_id bridge address_timeout } {
    set ifcfg [list "bridge $bridge"]
    foreach line [netconfFetchSection $node_id "bridge $bridge"] {
	if { [lindex $line 0] != "timeout" } {
	    lappend ifcfg $line
	}
    }

    if { $address_timeout >= 0 || $address_timeout <= 3600 } {
	lappend ifcfg " timeout $address_timeout"
    }

    netconfInsertSection $node_id $ifcfg
}

#####
#####BridgeIfcSettings
#####

proc getBridgeIfcDiscover { node_id iface_id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "spanning-tree" } {
	    if { [lindex $line 1] == "discover" } {
		    return 1
	    }
	}
    }

    return 0
}

proc setBridgeIfcDiscover { node_id iface_id stp_discover } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "spanning-tree" || \
	    [lindex $line 1] != "discover" } {

	    lappend ifcfg $line
	}
    }

    if { $stp_discover == 1 } {
	lappend ifcfg " spanning-tree discover"
    }

    netconfInsertSection $node_id $ifcfg
}

proc getBridgeIfcLearn { node_id iface_id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "spanning-tree" } {
	    if { [lindex $line 1] == "learn" } {
		    return 1
	    }
	}
    }

    return 0
}

proc setBridgeIfcLearn { node_id iface_id stp_learn } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "spanning-tree" || \
	    [lindex $line 1] != "learn" } {

	    lappend ifcfg $line
	}
    }

    if { $stp_learn == 1 } {
	lappend ifcfg " spanning-tree learn"
    }

    netconfInsertSection $node_id $ifcfg
}

proc getBridgeIfcSticky { node_id iface_id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "spanning-tree" } {
	    if { [lindex $line 1] == "sticky" } {
		    return 1
	    }
	}
    }

    return 0
}

proc setBridgeIfcSticky { node_id iface_id stp_sticky } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "spanning-tree" || \
	    [lindex $line 1] != "sticky" } {

	    lappend ifcfg $line
	}
    }

    if { $stp_sticky == 1 } {
	lappend ifcfg " spanning-tree sticky"
    }

    netconfInsertSection $node_id $ifcfg
}

proc getBridgeIfcPrivate { node_id iface_id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "spanning-tree" } {
	    if { [lindex $line 1] == "private" } {
		    return 1
	    }
	}
    }

    return 0
}

proc setBridgeIfcPrivate { node_id iface_id stp_private } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "spanning-tree" || \
	    [lindex $line 1] != "private" } {

	    lappend ifcfg $line
	}
    }

    if { $stp_private == 1 } {
	lappend ifcfg " spanning-tree private"
    }

    netconfInsertSection $node_id $ifcfg
}

proc getBridgeIfcSnoop { node_id iface_id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "spanning-tree" } {
	    if { [lindex $line 1] == "snoop" } {
		    return 1
	    }
	}
    }

    return 0
}

proc setBridgeIfcSnoop { node_id iface_id stp_snoop } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "spanning-tree" || \
	    [lindex $line 1] != "snoop" } {

	    lappend ifcfg $line
	}
    }

    if { $stp_snoop == 1 } {
	lappend ifcfg " spanning-tree snoop"
    }

    netconfInsertSection $node_id $ifcfg
}

proc getBridgeIfcStp { node_id iface_id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "spanning-tree" } {
	    if { [lindex $line 1] == "stp" } {
		    return 1
	    }
	}
    }

    return 0
}

proc setBridgeIfcStp { node_id iface_id stp_enabled } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "spanning-tree" || \
	    [lindex $line 1] != "stp" } {

	    lappend ifcfg $line
	}
    }

    if { $stp_enabled == 1 } {
	lappend ifcfg " spanning-tree stp"
    }

    netconfInsertSection $node_id $ifcfg
}

proc getBridgeIfcEdge { node_id iface_id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "spanning-tree" } {
	    if { [lindex $line 1] == "edge" } {
		    return 1
	    }
	}
    }

    return 0
}

proc setBridgeIfcEdge { node_id iface_id stp_edge } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "spanning-tree" || \
	    [lindex $line 1] != "edge" } {

	    lappend ifcfg $line
	}
    }

    if { $stp_edge == 1 } {
	lappend ifcfg " spanning-tree edge"
    }

    netconfInsertSection $node_id $ifcfg
}

proc getBridgeIfcAutoedge { node_id iface_id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "spanning-tree" } {
	    if { [lindex $line 1] == "autoedge" } {
		    return 1
	    }
	}
    }

    return 0
}

proc setBridgeIfcAutoedge { node_id iface_id stp_autoedge } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "spanning-tree" || \
	    [lindex $line 1] != "autoedge" } {

	    lappend ifcfg $line
	}
    }

    if { $stp_autoedge == 1 } {
	lappend ifcfg " spanning-tree autoedge"
    }

    netconfInsertSection $node_id $ifcfg
}

proc getBridgeIfcPtp { node_id iface_id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "spanning-tree" } {
	    if { [lindex $line 1] == "ptp" } {
		    return 1
	    }
	}
    }

    return 0
}

proc setBridgeIfcPtp { node_id iface_id stp_ptp } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "spanning-tree" || \
	    [lindex $line 1] != "ptp" } {

	    lappend ifcfg $line
	}
    }

    if { $stp_ptp == 1 } {
	lappend ifcfg " spanning-tree ptp"
    }

    netconfInsertSection $node_id $ifcfg
}

proc getBridgeIfcAutoptp { node_id iface_id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "spanning-tree" } {
	    if { [lindex $line 1] == "autoptp" } {
		    return 1
	    }
	}
    }

    return 0
}

proc setBridgeIfcAutoptp { node_id iface_id stp_autoptp } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "spanning-tree" || \
	    [lindex $line 1] != "autoptp" } {

	    lappend ifcfg $line
	}
    }

    if { $stp_autoptp == 1 } {
	lappend ifcfg " spanning-tree autoptp"
    }

    netconfInsertSection $node_id $ifcfg
}

####IfcParameters

proc getBridgeIfcPriority { node_id iface_id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "spanning-tree" } {
	    if { [lindex $line 1] == "priority" } {
		    return [lindex $line 2]
	    }
	}
    }
}

proc setBridgeIfcPriority { node_id iface_id stp_priority } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "spanning-tree" || \
	    [lindex $line 1] != "priority" } {

	    lappend ifcfg $line
	}
    }

    if { $stp_priority >= 0 && $stp_priority <= 240 } {
	lappend ifcfg " spanning-tree priority $stp_priority"
    }

    netconfInsertSection $node_id $ifcfg
}

proc getBridgeIfcPathcost { node_id iface_id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "spanning-tree" } {
	    if { [lindex $line 1] == "pathcost" } {
		    return [lindex $line 2]
	    }
	}
    }
}

proc setBridgeIfcPathcost { node_id iface_id stp_path_cost } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "spanning-tree" || \
	    [lindex $line 1] != "pathcost" } {

	    lappend ifcfg $line
	}
    }

    if { $stp_path_cost >= 0 && $stp_path_cost <= 200000000 } {
	lappend ifcfg " spanning-tree pathcost $stp_path_cost"
    }

    netconfInsertSection $node_id $ifcfg
}

proc getBridgeIfcMaxaddr { node_id iface_id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] == "spanning-tree" } {
	    if { [lindex $line 1] == "maxaddr" } {
		    return [lindex $line 2]
	    }
	}
    }
}

proc setBridgeIfcMaxaddr { node_id iface_id stp_max_addresses } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "spanning-tree" || \
	    [lindex $line 1] != "maxaddr" } {

	    lappend ifcfg $line
	}
    }

    if { $stp_max_addresses >= 0 && $stp_max_addresses <= 10000 } {
	lappend ifcfg " spanning-tree maxaddr $stp_max_addresses"
    }

    netconfInsertSection $node_id $ifcfg
}
