proc getFilterIfcRule { node_id iface id } {
    return [cfgGet "nodes" $node_id "ifaces" $iface "filter_rules" $id]
}

proc addFilterIfcRule { node_id iface id rule } {
    cfgSet "nodes" $node_id "ifaces" $iface "filter_rules" $id $rule
}

proc removeFilterIfcRule { node_id iface id } {
    cfgUnset "nodes" $node_id "ifaces" $iface "filter_rules" $id
}

proc getFilterIfcAction { node_id iface id } {
    return [cfgGet "nodes" $node_id "ifaces" $iface "filter_rules" $id "action"]
}

proc setFilterIfcAction { node_id iface id action } {
    cfgSet "nodes" $node_id "ifaces" $iface "filter_rules" $id "action" $action
}

proc getFilterIfcPattern { node_id iface id } {
    return [cfgGet "nodes" $node_id "ifaces" $iface "filter_rules" $id "pattern"]
}

proc setFilterIfcPattern { node_id iface id pattern } {
    cfgSet "nodes" $node_id "ifaces" $iface "filter_rules" $id "pattern" $pattern
}

proc getFilterIfcMask { node_id iface id } {
    return [cfgGet "nodes" $node_id "ifaces" $iface "filter_rules" $id "mask"]
}

proc setFilterIfcMask { node_id iface id mask } {
    cfgSet "nodes" $node_id "ifaces" $iface "filter_rules" $id "mask" $mask
}

proc getFilterIfcOffset { node_id iface id } {
    return [cfgGet "nodes" $node_id "ifaces" $iface "filter_rules" $id "offset"]
}

proc setFilterIfcOffset { node_id iface id offset } {
    cfgSet "nodes" $node_id "ifaces" $iface "filter_rules" $id "offset" $offset
}

proc getFilterIfcActionData { node_id iface id } {
    return [cfgGet "nodes" $node_id "ifaces" $iface "filter_rules" $id "action_data"]
}

proc setFilterIfcActionData { node_id iface id action_data } {
    cfgSet "nodes" $node_id "ifaces" $iface "filter_rules" $id "action_data" $action_data
}

proc ifcFilterRuleList { node_id iface } {
    return [dict keys [cfgGet "nodes" $node_id "ifaces" $iface "filter_rules"]]
}

proc getFilterIfcRuleAsString { node_id iface id } {
    set rule_dict [getFilterIfcRule $node_id $iface $id]

    set action [dictGet $rule_dict "action"]
    set pattern [dictGet $rule_dict "pattern"]
    set mask [dictGet $rule_dict "mask"]
    set offset [dictGet $rule_dict "offset"]
    set action_data [dictGet $rule_dict "action_data"]

    if { $offset != "" } {
	return "${id}:${action}:${pattern}/${mask}@${offset}:${action_data}"
    }

    return "${id}:${action}::${action_data}"
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
