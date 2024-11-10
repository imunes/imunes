proc getTunIPv4Addr { node_id } {
    foreach line [netconfFetchSection $node_id "nat64"] {
	if { [lindex $line 0] == "tunIPv4addr" } {
	   return [lindex $line 1]
	}
    }

    return ""
}

proc setTunIPv4Addr { node_id addr } {
    set cfg [list "nat64"]
    foreach line [netconfFetchSection $node_id "nat64"] {
	if { [lindex $line 0] != "tunIPv4addr" } {
	    lappend cfg $line
	}
    }

    lappend cfg " tunIPv4addr $addr"
    netconfInsertSection $node_id $cfg
}


proc getTunIPv6Addr { node_id } {
    foreach line [netconfFetchSection $node_id "nat64"] {
	if { [lindex $line 0] == "tunIPv6addr" } {
	   return [lindex $line 1]
	}
    }

    return ""
}

proc setTunIPv6Addr { node_id addr } {
    set cfg [list "nat64"]
    foreach line [netconfFetchSection $node_id "nat64"] {
	if { [lindex $line 0] != "tunIPv6addr" } {
	    lappend cfg $line
	}
    }

    lappend cfg " tunIPv6addr $addr"
    netconfInsertSection $node_id $cfg
}

proc getTaygaIPv4Addr { node_id } {
    foreach line [netconfFetchSection $node_id "nat64"] {
	if { [lindex $line 0] == "taygaIPv4addr" } {
	   return [lindex $line 1]
	}
    }

    return ""
}

proc setTaygaIPv4Addr { node_id addr } {
    set cfg [list "nat64"]
    foreach line [netconfFetchSection $node_id "nat64"] {
	if { [lindex $line 0] != "taygaIPv4addr" } {
	    lappend cfg $line
	}
    }

    lappend cfg " taygaIPv4addr $addr"
    netconfInsertSection $node_id $cfg
}

proc getTaygaIPv6Prefix { node_id } {
    foreach line [netconfFetchSection $node_id "nat64"] {
	if { [lindex $line 0] == "taygaIPv6prefix" } {
	   return [lindex $line 1]
	}
    }

    return ""
}

proc setTaygaIPv6Prefix { node_id addr } {
    set cfg [list "nat64"]
    foreach line [netconfFetchSection $node_id "nat64"] {
	if { [lindex $line 0] != "taygaIPv6prefix" } {
	    lappend cfg $line
	}
    }

    lappend cfg " taygaIPv6prefix $addr"
    netconfInsertSection $node_id $cfg
}

proc getTaygaIPv4DynPool { node_id } {
    foreach line [netconfFetchSection $node_id "nat64"] {
	if { [lindex $line 0] == "taygaIPv4pool" } {
	   return [lindex $line 1]
	}
    }

    return ""
}

proc setTaygaIPv4DynPool { node_id addr } {
    set cfg [list "nat64"]
    foreach line [netconfFetchSection $node_id "nat64"] {
	if { [lindex $line 0] != "taygaIPv4pool" } {
	    lappend cfg $line
	}
    }

    lappend cfg " taygaIPv4pool $addr"
    netconfInsertSection $node_id $cfg
}

proc getTaygaMappings { node_id } {
    set mps {}
    foreach line [netconfFetchSection $node_id "nat64"] {
	if { [lindex $line 0] == "taygaMapping" } {
	    lappend mps [lrange $line 1 end]
	}
    }

    return $mps
}

proc setTaygaMappings { node_id mps } {
    set cfg [list "nat64"]
    foreach line [netconfFetchSection $node_id "nat64"] {
	if { [lindex $line 0] != "taygaMapping" } {
	    lappend cfg $line
	}
    }

    foreach map $mps {
	lappend cfg " taygaMapping $map"
    }

    netconfInsertSection $node_id $cfg
}
