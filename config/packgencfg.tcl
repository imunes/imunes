proc getPackgenPacketRate { node } {
    foreach line [netconfFetchSection $node "packet generator"] {
	if { [lindex $line 0] == "packetrate" } {
		return [lindex $line 1]
	}
    }
    return 100
}

proc setPackgenPacketRate { node value } {
    set ifcfg [list "packet generator"]
    foreach line [netconfFetchSection $node "packet generator"] {
	if { [lindex $line 0] != "packetrate" } {
	    lappend ifcfg $line
	}
    }
    if { $value >= 0 } {
	lappend ifcfg " packetrate $value"
    }
    netconfInsertSection $node $ifcfg
}

proc getPackgenPacket { node id } {
    foreach line [netconfFetchSection $node "packets"] {
	if { [string trim [lindex [split $line :] 0]] == $id } {
		    return [string trim $line]
	}
    }
}

proc addPackgenPacket { node id value } {
    set ifcfg [list "packets"]
    foreach line [netconfFetchSection $node "packets"] {
	if { [string trim [lindex [split $line :] 0]] != $id } {
	    lappend ifcfg $line
	}
    }
    lappend ifcfg " $value"
    netconfInsertSection $node $ifcfg
}

proc removePackgenPacket { node id } {
    set ifcfg [list "packets"]
    foreach line [netconfFetchSection $node "packets"] {
	if { [string trim [lindex [split $line :] 0]] != $id } {
	    lappend ifcfg $line
	}
    }
    netconfInsertSection $node $ifcfg
}

proc getPackgenPacketData { node id } {
    foreach line [netconfFetchSection $node "packets"] {
	if { [string trim [lindex [split $line :] 0]] == $id } {
		    return [lindex [string trim [split $line :]] 1]
	}
    }
}

proc packgenPackets { node } {
    set packetList ""
    foreach line [netconfFetchSection $node "packets"] {
	lappend packetList [string trim [lindex [split $line :] 0]]
    }
    return $packetList
}

proc checkRuleNum { str } {
    return [regexp {^([1-9])([0-9])*$} $str]
}

proc checkPacketData { str } {
    set str [string map { " " "." ":" "." } $str]
    if { $str != "" } {
	return [regexp {^([0-9a-f])*$} $str]
    }
    return 1
}
