proc getBridgeProtocol { node bridge } {
    foreach line [netconfFetchSection $node "bridge $bridge"] {
	if { [lindex $line 0] == "rstp" } {
	    return "rstp" 
	} 
	if { [lindex $line 0] == "stp" } {
	    return "stp"
	}
    }
    return rstp
}

proc setBridgeProtocol { node bridge proto } {
    set ifcfg [list "bridge $bridge"]
    foreach line [netconfFetchSection $node "bridge $bridge"] {
	if { [lindex $line 0] != "stp" && [lindex $line 0] != "rstp" } {
	    lappend ifcfg $line
	}
    }
    if { $proto == "stp" || $proto == "rstp" } {
	lappend ifcfg " $proto"
    }
    netconfInsertSection $node $ifcfg
}

proc getBridgePriority { node bridge } {
    foreach line [netconfFetchSection $node "bridge $bridge"] {
	if { [lindex $line 0] == "priority" } {
		return [lindex $line 1]
	}
    }
    return 32768
}

proc setBridgePriority { node bridge priority } {
    set ifcfg [list "bridge $bridge"]
    foreach line [netconfFetchSection $node "bridge $bridge"] {
	if { [lindex $line 0] != "priority" } {
	    lappend ifcfg $line
	}
    }
    if { $priority >= 0 || $priority <= 61440 } {
	lappend ifcfg " priority $priority"
    }
    netconfInsertSection $node $ifcfg
}

proc getBridgeHoldCount { node bridge } {
    foreach line [netconfFetchSection $node "bridge $bridge"] {
	if { [lindex $line 0] == "holdcnt" } {
		return [lindex $line 1]
	}
    }
    return 6
}

proc setBridgeHoldCount { node bridge holdcnt } {
    set ifcfg [list "bridge $bridge"]
    foreach line [netconfFetchSection $node "bridge $bridge"] {
	if { [lindex $line 0] != "holdcnt" } {
	    lappend ifcfg $line
	}
    }
    if { $holdcnt >= 1 || $holdcnt <= 10 } {
	lappend ifcfg " holdcnt $holdcnt"
    }
    netconfInsertSection $node $ifcfg
}

proc getBridgeMaxAge { node bridge } {
    foreach line [netconfFetchSection $node "bridge $bridge"] {
	if { [lindex $line 0] == "maxage" } {
		return [lindex $line 1]
	}
    }
    return 20
}

proc setBridgeMaxAge { node bridge maxage } {
    set ifcfg [list "bridge $bridge"]
    foreach line [netconfFetchSection $node "bridge $bridge"] {
	if { [lindex $line 0] != "maxage" } {
	    lappend ifcfg $line
	}
    }
    if { $maxage >= 6 || $maxage <= 40 } {
	lappend ifcfg " maxage $maxage"
    }
    netconfInsertSection $node $ifcfg
}

proc getBridgeFwdDelay { node bridge } {
    foreach line [netconfFetchSection $node "bridge $bridge"] {
	if { [lindex $line 0] == "fwddelay" } {
		return [lindex $line 1]
	}
    }
    return 15
}

proc setBridgeFwdDelay { node bridge fwddelay } {
    set ifcfg [list "bridge $bridge"]
    foreach line [netconfFetchSection $node "bridge $bridge"] {
	if { [lindex $line 0] != "fwddelay" } {
	    lappend ifcfg $line
	}
    }
    if { $fwddelay >= 4 || $fwddelay <= 30 } {
	lappend ifcfg " fwddelay $fwddelay"
    }
    netconfInsertSection $node $ifcfg
}

proc getBridgeHelloTime { node bridge } {
    foreach line [netconfFetchSection $node "bridge $bridge"] {
	if { [lindex $line 0] == "hellotime" } {
		return [lindex $line 1]
	}
    }
    return 2
}

proc setBridgeHelloTime { node bridge hellotime } {
    set ifcfg [list "bridge $bridge"]
    foreach line [netconfFetchSection $node "bridge $bridge"] {
	if { [lindex $line 0] != "hellotime" } {
	    lappend ifcfg $line
	}
    }
    if { $hellotime >= 1 || $hellotime <= 2 } {
	lappend ifcfg " hellotime $hellotime"
    }
    netconfInsertSection $node $ifcfg
}

proc getBridgeMaxAddr { node bridge } {
    foreach line [netconfFetchSection $node "bridge $bridge"] {
	if { [lindex $line 0] == "maxaddr" } {
		return [lindex $line 1]
	}
    }
    return 100
}

proc setBridgeMaxAddr { node bridge maxaddr } {
    set ifcfg [list "bridge $bridge"]
    foreach line [netconfFetchSection $node "bridge $bridge"] {
	if { [lindex $line 0] != "maxaddr" } {
	    lappend ifcfg $line
	}
    }
    if { $maxaddr >= 0 || $maxaddr <= 10000 } {
	lappend ifcfg " maxaddr $maxaddr"
    }
    netconfInsertSection $node $ifcfg
}

proc getBridgeTimeout { node bridge } {
    foreach line [netconfFetchSection $node "bridge $bridge"] {
	if { [lindex $line 0] == "timeout" } {
		return [lindex $line 1]
	}
    }
    return 240
}

proc setBridgeTimeout { node bridge timeout } {
    set ifcfg [list "bridge $bridge"]
    foreach line [netconfFetchSection $node "bridge $bridge"] {
	if { [lindex $line 0] != "timeout" } {
	    lappend ifcfg $line
	}
    }
    if { $timeout >= 0 || $timeout <= 3600 } {
	lappend ifcfg " timeout $timeout"
    }
    netconfInsertSection $node $ifcfg
}

#####
#####BridgeIfcSettings
#####

proc getBridgeIfcDiscover { node ifc } {
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] == "spanning-tree" } {
	    if { [lindex $line 1] == "discover" } {
		    return 1
	    }
	}
    }
    return 0
}

proc setBridgeIfcDiscover { node ifc value } {
    set ifcfg [list "interface $ifc"]
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] != "spanning-tree" || \
	[lindex $line 1] != "discover" } {
	    lappend ifcfg $line
	}
    }
    if { $value == 1 } {
	lappend ifcfg " spanning-tree discover"
    }
    netconfInsertSection $node $ifcfg
}

proc getBridgeIfcLearn { node ifc } {
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] == "spanning-tree" } {
	    if { [lindex $line 1] == "learn" } {
		    return 1
	    }
	}
    }
    return 0
}

proc setBridgeIfcLearn { node ifc value } {
    set ifcfg [list "interface $ifc"]
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] != "spanning-tree" || \
	[lindex $line 1] != "learn" } {
	    lappend ifcfg $line
	}
    }
    if { $value == 1 } {
	lappend ifcfg " spanning-tree learn"
    }
    netconfInsertSection $node $ifcfg
}

proc getBridgeIfcSticky { node ifc } {
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] == "spanning-tree" } {
	    if { [lindex $line 1] == "sticky" } {
		    return 1
	    }
	}
    }
    return 0
}

proc setBridgeIfcSticky { node ifc value } {
    set ifcfg [list "interface $ifc"]
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] != "spanning-tree" || \
	[lindex $line 1] != "sticky" } {
	    lappend ifcfg $line
	}
    }
    if { $value == 1 } {
	lappend ifcfg " spanning-tree sticky"
    }
    netconfInsertSection $node $ifcfg
}

proc getBridgeIfcPrivate { node ifc } {
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] == "spanning-tree" } {
	    if { [lindex $line 1] == "private" } {
		    return 1
	    }
	}
    }
    return 0
}

proc setBridgeIfcPrivate { node ifc value } {
    set ifcfg [list "interface $ifc"]
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] != "spanning-tree" || \
	[lindex $line 1] != "private" } {
	    lappend ifcfg $line
	}
    }
    if { $value == 1 } {
	lappend ifcfg " spanning-tree private"
    }
    netconfInsertSection $node $ifcfg
}

proc getBridgeIfcSnoop { node ifc } {
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] == "spanning-tree" } {
	    if { [lindex $line 1] == "snoop" } {
		    return 1
	    }
	}
    }
    return 0
}

proc setBridgeIfcSnoop { node ifc value } {
    set ifcfg [list "interface $ifc"]
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] != "spanning-tree" || \
	[lindex $line 1] != "snoop" } {
	    lappend ifcfg $line
	}
    }
    if { $value == 1 } {
	lappend ifcfg " spanning-tree snoop"
    }
    netconfInsertSection $node $ifcfg
}

proc getBridgeIfcStp { node ifc } {
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] == "spanning-tree" } {
	    if { [lindex $line 1] == "stp" } {
		    return 1
	    }
	}
    }
    return 0
}

proc setBridgeIfcStp { node ifc value } {
    set ifcfg [list "interface $ifc"]
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] != "spanning-tree" || \
	[lindex $line 1] != "stp" } {
	    lappend ifcfg $line
	}
    }
    if { $value == 1 } {
	lappend ifcfg " spanning-tree stp"
    }
    netconfInsertSection $node $ifcfg
}

proc getBridgeIfcEdge { node ifc } {
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] == "spanning-tree" } {
	    if { [lindex $line 1] == "edge" } {
		    return 1
	    }
	}
    }
    return 0
}

proc setBridgeIfcEdge { node ifc value } {
    set ifcfg [list "interface $ifc"]
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] != "spanning-tree" || \
	[lindex $line 1] != "edge" } {
	    lappend ifcfg $line
	}
    }
    if { $value == 1 } {
	lappend ifcfg " spanning-tree edge"
    }
    netconfInsertSection $node $ifcfg
}

proc getBridgeIfcAutoedge { node ifc } {
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] == "spanning-tree" } {
	    if { [lindex $line 1] == "autoedge" } {
		    return 1
	    }
	}
    }
    return 0
}

proc setBridgeIfcAutoedge { node ifc value } {
    set ifcfg [list "interface $ifc"]
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] != "spanning-tree" || \
	[lindex $line 1] != "autoedge" } {
	    lappend ifcfg $line
	}
    }
    if { $value == 1 } {
	lappend ifcfg " spanning-tree autoedge"
    }
    netconfInsertSection $node $ifcfg
}

proc getBridgeIfcPtp { node ifc } {
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] == "spanning-tree" } {
	    if { [lindex $line 1] == "ptp" } {
		    return 1
	    }
	}
    }
    return 0
}

proc setBridgeIfcPtp { node ifc value } {
    set ifcfg [list "interface $ifc"]
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] != "spanning-tree" || \
	[lindex $line 1] != "ptp" } {
	    lappend ifcfg $line
	}
    }
    if { $value == 1 } {
	lappend ifcfg " spanning-tree ptp"
    }
    netconfInsertSection $node $ifcfg
}

proc getBridgeIfcAutoptp { node ifc } {
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] == "spanning-tree" } {
	    if { [lindex $line 1] == "autoptp" } {
		    return 1
	    }
	}
    }
    return 0
}

proc setBridgeIfcAutoptp { node ifc value } {
    set ifcfg [list "interface $ifc"]
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] != "spanning-tree" || \
	[lindex $line 1] != "autoptp" } {
	    lappend ifcfg $line
	}
    }
    if { $value == 1 } {
	lappend ifcfg " spanning-tree autoptp"
    }
    netconfInsertSection $node $ifcfg
}

####IfcParameters

proc getBridgeIfcPriority { node ifc } {
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] == "spanning-tree" } {
	    if { [lindex $line 1] == "priority" } {
		    return [lindex $line 2]
	    }
	}
    }
}

proc setBridgeIfcPriority { node ifc value } {
    set ifcfg [list "interface $ifc"]
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] != "spanning-tree" || \
	[lindex $line 1] != "priority" } {
	    lappend ifcfg $line
	}
    }
    if { $value >= 0 && $value <= 240 } {
	lappend ifcfg " spanning-tree priority $value"
    }
    netconfInsertSection $node $ifcfg
}

proc getBridgeIfcPathcost { node ifc } {
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] == "spanning-tree" } {
	    if { [lindex $line 1] == "pathcost" } {
		    return [lindex $line 2]
	    }
	}
    }
}

proc setBridgeIfcPathcost { node ifc value } {
    set ifcfg [list "interface $ifc"]
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] != "spanning-tree" || \
	[lindex $line 1] != "pathcost" } {
	    lappend ifcfg $line
	}
    }
    if { $value >= 0 && $value <= 200000000 } {
	lappend ifcfg " spanning-tree pathcost $value"
    }
    netconfInsertSection $node $ifcfg
}

proc getBridgeIfcMaxaddr { node ifc } {
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] == "spanning-tree" } {
	    if { [lindex $line 1] == "maxaddr" } {
		    return [lindex $line 2]
	    }
	}
    }
}

proc setBridgeIfcMaxaddr { node ifc value } {
    set ifcfg [list "interface $ifc"]
    foreach line [netconfFetchSection $node "interface $ifc"] {
	if { [lindex $line 0] != "spanning-tree" || \
	[lindex $line 1] != "maxaddr" } {
	    lappend ifcfg $line
	}
    }
    if { $value >= 0 && $value <= 10000 } {
	lappend ifcfg " spanning-tree maxaddr $value"
    }
    netconfInsertSection $node $ifcfg
}
