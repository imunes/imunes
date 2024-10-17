proc getTunIPv4Addr { node } {
    foreach line [netconfFetchSection $node "nat64"] {
	if { [lindex $line 0] == "tunIPv4addr" } {
	   return [lindex $line 1] 
	}
    }
    return ""
}
proc setTunIPv4Addr { node addr } {
    set cfg [list "nat64"]
    foreach line [netconfFetchSection $node "nat64"] {
	if { [lindex $line 0] != "tunIPv4addr" } {
	    lappend cfg $line
	}
    }
    lappend cfg " tunIPv4addr $addr"
    netconfInsertSection $node $cfg
}


proc getTunIPv6Addr { node } {
    foreach line [netconfFetchSection $node "nat64"] {
	if { [lindex $line 0] == "tunIPv6addr" } {
	   return [lindex $line 1] 
	}
    }
    return ""
}
proc setTunIPv6Addr { node addr } {
    set cfg [list "nat64"]
    foreach line [netconfFetchSection $node "nat64"] {
	if { [lindex $line 0] != "tunIPv6addr" } {
	    lappend cfg $line
	}
    }
    lappend cfg " tunIPv6addr $addr"
    netconfInsertSection $node $cfg
}


proc getTaygaIPv4Addr { node } {
    foreach line [netconfFetchSection $node "nat64"] {
	if { [lindex $line 0] == "taygaIPv4addr" } {
	   return [lindex $line 1] 
	}
    }
    return ""
}
proc setTaygaIPv4Addr { node addr } {
    set cfg [list "nat64"]
    foreach line [netconfFetchSection $node "nat64"] {
	if { [lindex $line 0] != "taygaIPv4addr" } {
	    lappend cfg $line
	}
    }
    lappend cfg " taygaIPv4addr $addr"
    netconfInsertSection $node $cfg
}


proc getTaygaIPv6Prefix { node } {
    foreach line [netconfFetchSection $node "nat64"] {
	if { [lindex $line 0] == "taygaIPv6prefix" } {
	   return [lindex $line 1] 
	}
    }
    return ""
}
proc setTaygaIPv6Prefix { node addr } {
    set cfg [list "nat64"]
    foreach line [netconfFetchSection $node "nat64"] {
	if { [lindex $line 0] != "taygaIPv6prefix" } {
	    lappend cfg $line
	}
    }
    lappend cfg " taygaIPv6prefix $addr"
    netconfInsertSection $node $cfg
}


proc getTaygaIPv4DynPool { node } {
    foreach line [netconfFetchSection $node "nat64"] {
	if { [lindex $line 0] == "taygaIPv4pool" } {
	   return [lindex $line 1] 
	}
    }
    return ""
}
proc setTaygaIPv4DynPool { node addr } {
    set cfg [list "nat64"]
    foreach line [netconfFetchSection $node "nat64"] {
	if { [lindex $line 0] != "taygaIPv4pool" } {
	    lappend cfg $line
	}
    }
    lappend cfg " taygaIPv4pool $addr"
    netconfInsertSection $node $cfg
}


proc getTaygaMappings { node } {
    set mps {}
    foreach line [netconfFetchSection $node "nat64"] {
	if { [lindex $line 0] == "taygaMapping" } {
	    lappend mps [lrange $line 1 end]
	}
    }
    return $mps
}
proc setTaygaMappings { node mps } {
    set cfg [list "nat64"]
    foreach line [netconfFetchSection $node "nat64"] {
	if { [lindex $line 0] != "taygaMapping" } {
	    lappend cfg $line
	}
    }
    foreach map $mps { 
	lappend cfg " taygaMapping $map"
    }
    netconfInsertSection $node $cfg
}
