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

proc setBridgeProtocol { node_id bridge proto } {
    set ifcfg [list "bridge $bridge"]
    foreach line [netconfFetchSection $node_id "bridge $bridge"] {
	if { [lindex $line 0] != "stp" && [lindex $line 0] != "rstp" } {
	    lappend ifcfg $line
	}
    }
    if { $proto == "stp" || $proto == "rstp" } {
	lappend ifcfg " $proto"
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

proc setBridgeHoldCount { node_id bridge holdcnt } {
    set ifcfg [list "bridge $bridge"]
    foreach line [netconfFetchSection $node_id "bridge $bridge"] {
	if { [lindex $line 0] != "holdcnt" } {
	    lappend ifcfg $line
	}
    }
    if { $holdcnt >= 1 || $holdcnt <= 10 } {
	lappend ifcfg " holdcnt $holdcnt"
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

proc setBridgeMaxAge { node_id bridge maxage } {
    set ifcfg [list "bridge $bridge"]
    foreach line [netconfFetchSection $node_id "bridge $bridge"] {
	if { [lindex $line 0] != "maxage" } {
	    lappend ifcfg $line
	}
    }
    if { $maxage >= 6 || $maxage <= 40 } {
	lappend ifcfg " maxage $maxage"
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

proc setBridgeFwdDelay { node_id bridge fwddelay } {
    set ifcfg [list "bridge $bridge"]
    foreach line [netconfFetchSection $node_id "bridge $bridge"] {
	if { [lindex $line 0] != "fwddelay" } {
	    lappend ifcfg $line
	}
    }
    if { $fwddelay >= 4 || $fwddelay <= 30 } {
	lappend ifcfg " fwddelay $fwddelay"
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

proc setBridgeHelloTime { node_id bridge hellotime } {
    set ifcfg [list "bridge $bridge"]
    foreach line [netconfFetchSection $node_id "bridge $bridge"] {
	if { [lindex $line 0] != "hellotime" } {
	    lappend ifcfg $line
	}
    }
    if { $hellotime >= 1 || $hellotime <= 2 } {
	lappend ifcfg " hellotime $hellotime"
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

proc setBridgeMaxAddr { node_id bridge maxaddr } {
    set ifcfg [list "bridge $bridge"]
    foreach line [netconfFetchSection $node_id "bridge $bridge"] {
	if { [lindex $line 0] != "maxaddr" } {
	    lappend ifcfg $line
	}
    }
    if { $maxaddr >= 0 || $maxaddr <= 10000 } {
	lappend ifcfg " maxaddr $maxaddr"
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

proc setBridgeTimeout { node_id bridge timeout } {
    set ifcfg [list "bridge $bridge"]
    foreach line [netconfFetchSection $node_id "bridge $bridge"] {
	if { [lindex $line 0] != "timeout" } {
	    lappend ifcfg $line
	}
    }
    if { $timeout >= 0 || $timeout <= 3600 } {
	lappend ifcfg " timeout $timeout"
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

proc setBridgeIfcDiscover { node_id iface_id value } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "spanning-tree" || \
	[lindex $line 1] != "discover" } {
	    lappend ifcfg $line
	}
    }
    if { $value == 1 } {
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

proc setBridgeIfcLearn { node_id iface_id value } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "spanning-tree" || \
	[lindex $line 1] != "learn" } {
	    lappend ifcfg $line
	}
    }
    if { $value == 1 } {
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

proc setBridgeIfcSticky { node_id iface_id value } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "spanning-tree" || \
	[lindex $line 1] != "sticky" } {
	    lappend ifcfg $line
	}
    }
    if { $value == 1 } {
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

proc setBridgeIfcPrivate { node_id iface_id value } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "spanning-tree" || \
	[lindex $line 1] != "private" } {
	    lappend ifcfg $line
	}
    }
    if { $value == 1 } {
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

proc setBridgeIfcSnoop { node_id iface_id value } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "spanning-tree" || \
	[lindex $line 1] != "snoop" } {
	    lappend ifcfg $line
	}
    }
    if { $value == 1 } {
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

proc setBridgeIfcStp { node_id iface_id value } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "spanning-tree" || \
	[lindex $line 1] != "stp" } {
	    lappend ifcfg $line
	}
    }
    if { $value == 1 } {
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

proc setBridgeIfcEdge { node_id iface_id value } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "spanning-tree" || \
	[lindex $line 1] != "edge" } {
	    lappend ifcfg $line
	}
    }
    if { $value == 1 } {
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

proc setBridgeIfcAutoedge { node_id iface_id value } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "spanning-tree" || \
	[lindex $line 1] != "autoedge" } {
	    lappend ifcfg $line
	}
    }
    if { $value == 1 } {
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

proc setBridgeIfcPtp { node_id iface_id value } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "spanning-tree" || \
	[lindex $line 1] != "ptp" } {
	    lappend ifcfg $line
	}
    }
    if { $value == 1 } {
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

proc setBridgeIfcAutoptp { node_id iface_id value } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "spanning-tree" || \
	[lindex $line 1] != "autoptp" } {
	    lappend ifcfg $line
	}
    }
    if { $value == 1 } {
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

proc setBridgeIfcPriority { node_id iface_id value } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "spanning-tree" || \
	[lindex $line 1] != "priority" } {
	    lappend ifcfg $line
	}
    }
    if { $value >= 0 && $value <= 240 } {
	lappend ifcfg " spanning-tree priority $value"
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

proc setBridgeIfcPathcost { node_id iface_id value } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "spanning-tree" || \
	[lindex $line 1] != "pathcost" } {
	    lappend ifcfg $line
	}
    }
    if { $value >= 0 && $value <= 200000000 } {
	lappend ifcfg " spanning-tree pathcost $value"
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

proc setBridgeIfcMaxaddr { node_id iface_id value } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [lindex $line 0] != "spanning-tree" || \
	[lindex $line 1] != "maxaddr" } {
	    lappend ifcfg $line
	}
    }
    if { $value >= 0 && $value <= 10000 } {
	lappend ifcfg " spanning-tree maxaddr $value"
    }
    netconfInsertSection $node_id $ifcfg
}
