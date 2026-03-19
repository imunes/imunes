# updateNode cases

addCase "updateNode" "nat64" {
	upvar ::switch_cases::updateNode_nat64 switch_cases_nat64_var

	set nat64_diff [dictDiff $old_value $new_value]
	dict for {nat64_key nat64_change} $nat64_diff {
		if { $nat64_change == "copy" } {
			continue
		}

		dputs "======== $nat64_change: '$nat64_key'"

		set nat64_old_value [_cfgGet $old_value $nat64_key]
		set nat64_new_value [_cfgGet $new_value $nat64_key]
		if { $nat64_change in "changed" } {
			dputs "======== OLD: '$nat64_old_value'"
		}
		if { $nat64_change in "new changed" } {
			dputs "======== NEW: '$nat64_new_value'"
		}

		switch -exact $nat64_key [list {*}$switch_cases_nat64_var default {}]
	}
} "inner_dictionary"

addCase "updateNode_nat64" "tun_ipv4_addr" {
	setTunIPv4Addr $node_id $nat64_new_value
}

addCase "updateNode_nat64" "tun_ipv6_addr" {
	setTunIPv6Addr $node_id $nat64_new_value
}

addCase "updateNode_nat64" "tayga_ipv4_addr" {
	setTaygaIPv4Addr $node_id $nat64_new_value
}

addCase "updateNode_nat64" "tayga_ipv6_prefix" {
	setTaygaIPv6Prefix $node_id $nat64_new_value
}

addCase "updateNode_nat64" "tayga_ipv4_pool" {
	setTaygaIPv4DynPool $node_id $nat64_new_value
}

addCase "updateNode_nat64" "tayga_mappings" {
	setTaygaMappings $node_id $nat64_new_value
} "array"

# node-specific procedures

proc getTunIPv4Addr { node_id } {
	return [cfgGet "nodes" $node_id "nat64" "tun_ipv4_addr"]
}

proc setTunIPv4Addr { node_id addr } {
	cfgSet "nodes" $node_id "nat64" "tun_ipv4_addr" $addr

	# TODO: not used
	trigger_nodeReconfig $node_id
}

proc getTunIPv6Addr { node_id } {
	return [cfgGet "nodes" $node_id "nat64" "tun_ipv6_addr"]
}

proc setTunIPv6Addr { node_id addr } {
	cfgSet "nodes" $node_id "nat64" "tun_ipv6_addr" $addr

	# TODO: not used
	trigger_nodeReconfig $node_id
}

proc getTaygaIPv4Addr { node_id } {
	return [cfgGet "nodes" $node_id "nat64" "tayga_ipv4_addr"]
}

proc setTaygaIPv4Addr { node_id addr } {
	cfgSet "nodes" $node_id "nat64" "tayga_ipv4_addr" $addr

	# TODO: not used
	trigger_nodeReconfig $node_id
}

proc getTaygaIPv6Prefix { node_id } {
	return [cfgGet "nodes" $node_id "nat64" "tayga_ipv6_prefix"]
}

proc setTaygaIPv6Prefix { node_id addr } {
	cfgSet "nodes" $node_id "nat64" "tayga_ipv6_prefix" $addr

	trigger_nodeReconfig $node_id
}

proc getTaygaIPv4DynPool { node_id } {
	return [cfgGet "nodes" $node_id "nat64" "tayga_ipv4_pool"]
}

proc setTaygaIPv4DynPool { node_id addr } {
	cfgSet "nodes" $node_id "nat64" "tayga_ipv4_pool" $addr

	trigger_nodeReconfig $node_id
}

proc getTaygaMappings { node_id } {
	return [cfgGet "nodes" $node_id "nat64" "tayga_mappings"]
}

proc setTaygaMappings { node_id mps } {
	cfgSet "nodes" $node_id "nat64" "tayga_mappings" $mps

	trigger_nodeReconfig $node_id
}
