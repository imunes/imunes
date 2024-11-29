proc getPackgenPacketRate { node_id } {
    foreach line [netconfFetchSection $node_id "packet generator"] {
	if { [lindex $line 0] == "packetrate" } {
		return [lindex $line 1]
	}
    }
    return 100
}

proc setPackgenPacketRate { node_id rate } {
    set ifcfg [list "packet generator"]
    foreach line [netconfFetchSection $node_id "packet generator"] {
	if { [lindex $line 0] != "packetrate" } {
	    lappend ifcfg $line
	}
    }
    if { $rate >= 0 } {
	lappend ifcfg " packetrate $rate"
    }
    netconfInsertSection $node_id $ifcfg
}

proc getPackgenPacket { node_id id } {
    foreach line [netconfFetchSection $node_id "packets"] {
	if { [string trim [lindex [split $line :] 0]] == $id } {
		    return [string trim $line]
	}
    }
}

proc addPackgenPacket { node_id id new_value } {
    set ifcfg [list "packets"]
    foreach line [netconfFetchSection $node_id "packets"] {
	if { [string trim [lindex [split $line :] 0]] != $id } {
	    lappend ifcfg $line
	}
    }
    lappend ifcfg " $new_value"
    netconfInsertSection $node_id $ifcfg
}

proc removePackgenPacket { node_id id } {
    set ifcfg [list "packets"]
    foreach line [netconfFetchSection $node_id "packets"] {
	if { [string trim [lindex [split $line :] 0]] != $id } {
	    lappend ifcfg $line
	}
    }
    netconfInsertSection $node_id $ifcfg
}

proc getPackgenPacketData { node_id id } {
    foreach line [netconfFetchSection $node_id "packets"] {
	if { [string trim [lindex [split $line :] 0]] == $id } {
		    return [lindex [string trim [split $line :]] 1]
	}
    }
}

proc packgenPackets { node_id } {
    set packetList ""
    foreach line [netconfFetchSection $node_id "packets"] {
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
