# updateNode cases

addCase "updateNode" "model" {
	setNodeModel $node_id $new_value
}

addCase "updateNode" "router_config" {
	dict for {protocol_key protocol_change} [dictDiff $old_value $new_value] {
		if { $protocol_change == "copy" } {
			continue
		}

		setNodeProtocol $node_id $protocol_key [_cfgGet $new_value $protocol_key]
	}
}

addCase "updateNode" "ipsec" {
	upvar ::switch_cases::updateNode_ipsec switch_cases_ipsec_var

	set ipsec_diff [dictDiff $old_value $new_value]
	dict for {ipsec_key ipsec_change} $ipsec_diff {
		if { $ipsec_change == "copy" } {
			continue
		}

		dputs "======== $ipsec_change: '$ipsec_key'"

		set ipsec_old_value [_cfgGet $old_value $ipsec_key]
		set ipsec_new_value [_cfgGet $new_value $ipsec_key]
		if { $ipsec_change in "changed" } {
			dputs "======== OLD: '$ipsec_old_value'"
		}
		if { $ipsec_change in "new changed" } {
			dputs "======== NEW: '$ipsec_new_value'"
		}

		switch -exact $ipsec_key [list {*}$switch_cases_ipsec_var default {}]
	}
} "inner_dictionary"

addCase "updateNode_ipsec" "ca_cert" {
	setNodeIPsecItem $node_id $ipsec_key $ipsec_new_value
}

addCase "updateNode_ipsec" "local_cert" {
	setNodeIPsecItem $node_id $ipsec_key $ipsec_new_value
}

addCase "updateNode_ipsec" "local_key_file" {
	setNodeIPsecItem $node_id $ipsec_key $ipsec_new_value
}

addCase "updateNode_ipsec" "ipsec_logging" {
	setNodeIPsecItem $node_id $ipsec_key $ipsec_new_value
}

addCase "updateNode_ipsec" "ipsec_configs" {
	set ipsec_configs_diff [dictDiff $ipsec_old_value $ipsec_new_value]
	dict for {ipsec_configs_key ipsec_configs_change} $ipsec_configs_diff {
		if { $ipsec_configs_change == "copy" } {
			continue
		}

		dputs "============ $ipsec_configs_change: '$ipsec_configs_key'"

		set ipsec_configs_old_value [_cfgGet $ipsec_old_value $ipsec_configs_key]
		set ipsec_configs_new_value [_cfgGet $ipsec_new_value $ipsec_configs_key]
		if { $ipsec_configs_change in "changed" } {
			dputs "============ OLD: '$ipsec_configs_old_value'"
		}
		if { $ipsec_configs_change in "new changed" } {
			dputs "============ NEW: '$ipsec_configs_new_value'"
		}

		switch -exact $ipsec_configs_change {
			"removed" {
				delNodeIPsecConnection $node_id $ipsec_configs_key
			}

			"new" -
			"changed" {
				setNodeIPsecConnection $node_id $ipsec_configs_key $ipsec_configs_new_value
			}
		}
	}
} "dictionary"
