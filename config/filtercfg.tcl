proc getFilterIfcRule { node_id iface_id id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [string trim [lindex [split $line :] 0]] == $id } {
		    return [string trim $line]
	}
    }
}

proc addFilterIfcRule { node_id iface_id id rule } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [string trim [lindex [split $line :] 0]] != $id } {
	    lappend ifcfg $line
	}
    }
    lappend ifcfg " $rule"
    netconfInsertSection $node_id $ifcfg
}

proc removeFilterIfcRule { node_id iface_id id } {
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [string trim [lindex [split $line :] 0]] != $id } {
	    lappend ifcfg $line
	}
    }
    netconfInsertSection $node_id $ifcfg
}


proc getFilterIfcAction { node_id iface_id id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [string trim [lindex [split $line :] 0]] == $id } {
		    return [lindex [string trim [split $line :]] 1]
	}
    }
}

proc getFilterIfcPattern { node_id iface_id id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [string trim [lindex [split $line :] 0]] == $id } {
		    return [lindex [split [lindex [string trim [split $line :]] 2] /] 0]
	}
    }
}

proc getFilterIfcMask { node_id iface_id id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [string trim [lindex [split $line :] 0]] == $id } {
		    return [lindex [split [lindex [split [lindex [string trim [split $line :]] 2] /] 1] @] 0]
	}
    }
}

proc getFilterIfcOffset { node_id iface_id id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [string trim [lindex [split $line :] 0]] == $id } {
		    return [lindex [split [lindex [split [lindex [string trim [split $line :]] 2] /] 1] @] 1]
	}
    }
}

proc getFilterIfcActionData { node_id iface_id id } {
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	if { [string trim [lindex [split $line :] 0]] == $id } {
		    return [lindex [string trim [split $line :]] 3]
	}
    }
}

proc ifcFilterRuleList { node_id iface_id } {
    set ruleList ""
    set ifcfg [list "interface $iface_id"]
    foreach line [netconfFetchSection $node_id "interface $iface_id"] {
	lappend ruleList [string trim [lindex [split $line :] 0]]
    }
    return $ruleList
}

proc checkRuleNum { str } {
    return [regexp {^([1-9])([0-9])*$} $str]
}

proc checkPatternMask { str } {
    set str [string map { " " "." ":" "." } $str]
    if { $str != "" } {
	return [regexp {^([0-9a-f][0-9a-f]\.)*([0-9a-f][0-9a-f])$} $str]
    }

    return 1
}

proc checkOffset { str } {
    set syn [regexp {^((0|(([1-9])([0-9])*))((\.)+(([1-9])([0-9])*)+)?)?$} $str]
    if { $syn == 1 } {
	set l [split $str .]
	if { $l == $str } {
	    return 1
	}
	set a [lindex $l 0]
	set b [lindex $l end]
	if { $a < $b } {
	    return 1
	} else {
	    return 0
	}
    }

    return 0
}

proc checkAction { str } {
    if { $str in [list match_hook match_dupto match_skipto match_drop \
	nomatch_hook nomatch_dupto nomatch_skipto nomatch_drop] } {
	    return 1
    }

    return 0
}
