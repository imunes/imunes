proc _getFilterIfcRule { node_cfg iface id } {
	return [_cfgGet $node_cfg "ifaces" $iface "filter_rules" $id]
}

proc _addFilterIfcRule { node_cfg iface id rule } {
	return [_cfgSet $node_cfg "ifaces" $iface "filter_rules" $id $rule]
}

proc _removeFilterIfcRule { node_cfg iface id } {
	return [_cfgUnset $node_cfg "ifaces" $iface "filter_rules" $id]
}

proc _getFilterIfcAction { node_cfg iface id } {
	return [_cfgGet $node_cfg "ifaces" $iface "filter_rules" $id "action"]
}

proc _setFilterIfcAction { node_cfg iface id action } {
	return [_cfgSet $node_cfg "ifaces" $iface "filter_rules" $id "action" $action]
}

proc _getFilterIfcPattern { node_cfg iface id } {
	return [_cfgGet $node_cfg "ifaces" $iface "filter_rules" $id "pattern"]
}

proc _setFilterIfcPattern { node_cfg iface id pattern } {
	return [_cfgSet $node_cfg "ifaces" $iface "filter_rules" $id "pattern" $pattern]
}

proc _getFilterIfcMask { node_cfg iface id } {
	return [_cfgGet $node_cfg "ifaces" $iface "filter_rules" $id "mask"]
}

proc _setFilterIfcMask { node_cfg iface id mask } {
	return [_cfgSet $node_cfg "ifaces" $iface "filter_rules" $id "mask" $mask]
}

proc _getFilterIfcOffset { node_cfg iface id } {
	return [_cfgGet $node_cfg "ifaces" $iface "filter_rules" $id "offset"]
}

proc _setFilterIfcOffset { node_cfg iface id offset } {
	return [_cfgSet $node_cfg "ifaces" $iface "filter_rules" $id "offset" $offset]
}

proc _getFilterIfcActionData { node_cfg iface id } {
	return [_cfgGet $node_cfg "ifaces" $iface "filter_rules" $id "action_data"]
}

proc _setFilterIfcActionData { node_cfg iface id action_data } {
	return [_cfgSet $node_cfg "ifaces" $iface "filter_rules" $id "action_data" $action_data]
}

proc _ifcFilterRuleList { node_cfg iface } {
	return [dict keys [_cfgGet $node_cfg "ifaces" $iface "filter_rules"]]
}

proc _getFilterIfcRuleAsString { node_cfg iface id } {
	set rule_dict [_getFilterIfcRule $node_cfg $iface $id]

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
