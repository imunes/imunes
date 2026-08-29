# updateNode cases

addCase "updateNode" "croutes4" {
	setNodeStatIPv4routes $node_id $new_value
} "array"

addCase "updateNode" "croutes6" {
	setNodeStatIPv6routes $node_id $new_value
} "array"

addCase "updateNode" "auto_default_routes" {
	setNodeAutoDefaultRoutesStatus $node_id $new_value
}

addCase "updateNode" "services" {
	setNodeServices $node_id $new_value
} "array"

global cfg_types_dictionary

lappend cfg_types_dictionary "NODE_CONFIG"
lappend cfg_types_dictionary "IFACES_CONFIG"

addCase "updateNode" "custom_configs" {
	set custom_configs_diff [dictDiff $old_value $new_value]
	dict for {custom_configs_key custom_configs_change} $custom_configs_diff {
		if { $custom_configs_change == "copy" } {
			continue
		}

		dputs "======== $custom_configs_change: '$custom_configs_key'"

		set custom_configs_old_value [_cfgGet $old_value $custom_configs_key]
		set custom_configs_new_value [_cfgGet $new_value $custom_configs_key]
		if { $custom_configs_change in "changed" } {
			dputs "======== OLD: '$custom_configs_old_value'"
		}
		if { $custom_configs_change in "new changed" } {
			dputs "======== NEW: '$custom_configs_new_value'"
		}

		set hook_diff [dictDiff $custom_configs_old_value $custom_configs_new_value]
		dict for {hook_key hook_change} $hook_diff {
			if { $hook_change == "copy" } {
				continue
			}

			dputs "============ $hook_change: '$hook_key'"

			set hook_old_value [_cfgGet $custom_configs_old_value $hook_key]
			set hook_new_value [_cfgGet $custom_configs_new_value $hook_key]
			if { $hook_change in "changed" } {
				dputs "============ OLD: '$hook_old_value'"
			}
			if { $hook_change in "new changed" } {
				dputs "============ NEW: '$hook_new_value'"
			}

			if { $hook_change == "removed" } {
				removeNodeCustomConfig $node_id $custom_configs_key $hook_key
			} else {
				try {
					dict get $hook_new_value "custom_command"
				} on ok cmd {
				} on error {} {
					set cmd [dict get $hook_old_value "custom_command"]
				}

				try {
					dict get $hook_new_value "custom_config"
				} on ok cfg {
				} on error {} {
					set cfg [dict get $hook_old_value "custom_config"]
				}

				setNodeCustomConfig $node_id $custom_configs_key $hook_key $cmd $cfg
			}
		}
	}
} "dictionary"

addCase "updateNode" "custom_enabled" {
	setNodeCustomEnabled $node_id $new_value
}

addCase "updateNode" "custom_selected" {
	set custom_selected_diff [dictDiff $old_value $new_value]
	dict for {custom_selected_key custom_selected_change} $custom_selected_diff {
		if { $custom_selected_change == "copy" } {
			continue
		}

		dputs "======== $custom_selected_change: '$custom_selected_key'"

		set custom_selected_old_value [_cfgGet $old_value $custom_selected_key]
		set custom_selected_new_value [_cfgGet $new_value $custom_selected_key]
		if { $custom_selected_change in "changed" } {
			dputs "======== OLD: '$custom_selected_old_value'"
		}
		if { $custom_selected_change in "new changed" } {
			dputs "======== NEW: '$custom_selected_new_value'"
		}

		setNodeCustomConfigSelected $node_id $custom_selected_key $custom_selected_new_value
	}
}

addCase "updateNode" "advanced_options" {
	upvar ::switch_cases::updateNode_advanced_options switch_cases_advanced_options_var

	set advanced_options_diff [dictDiff $old_value $new_value]
	dict for {advanced_options_key advanced_options_change} $advanced_options_diff {
		if { $advanced_options_change == "copy" } {
			continue
		}

		dputs "======== $advanced_options_change: '$advanced_options_key'"

		set advanced_options_old_value [_cfgGet $old_value $advanced_options_key]
		set advanced_options_new_value [_cfgGet $new_value $advanced_options_key]
		if { $advanced_options_change in "changed" } {
			dputs "======== OLD: '$advanced_options_old_value'"
		}
		if { $advanced_options_change in "new changed" } {
			dputs "======== NEW: '$advanced_options_new_value'"
		}

		set platform_option_diff [dictDiff $advanced_options_old_value $advanced_options_new_value]
		dict for {platform_option_key platform_option_change} $platform_option_diff {
			if { $platform_option_change == "copy" } {
				continue
			}

			dputs "============ $platform_option_change: '$platform_option_key'"

			set platform_option_old_value [_cfgGet $advanced_options_old_value $platform_option_key]
			set platform_option_new_value [_cfgGet $advanced_options_new_value $platform_option_key]
			if { $platform_option_change in "changed" } {
				dputs "============ OLD: '$platform_option_old_value'"
			}
			if { $platform_option_change in "new changed" } {
				dputs "============ NEW: '$platform_option_new_value'"
			}

			switch -exact $advanced_options_key [list {*}$switch_cases_advanced_options_var default {}]
		}
	}
} "dictionary"

addCase "updateNode_advanced_options" "generic_options" {
	if { $platform_option_change == "removed" } {
		setNodeGenericOptions $node_id $platform_option_key ""
	} else {
		setNodeGenericOptions $node_id $platform_option_key $platform_option_new_value
	}
} "inner_dictionary"

addCase "updateNode_advanced_options" "jail_options" {
	if { $platform_option_change == "removed" } {
		setNodeJailOptions $node_id $platform_option_key ""
	} else {
		setNodeJailOptions $node_id $platform_option_key $platform_option_new_value
	}
} "inner_dictionary"

addCase "updateNode_advanced_options" "docker_options" {
	if { $platform_option_change == "removed" } {
		setNodeDockerOptions $node_id $platform_option_key ""
	} else {
		setNodeDockerOptions $node_id $platform_option_key $platform_option_new_value
	}
} "inner_dictionary"

# updateIface cases

addCase "updateIface" "oper_state" {
	setIfcOperState $node_id $iface_id $iface_prop_new_value
}

addCase "updateIface" "nat_state" {
	setIfcNatState $node_id $iface_id $iface_prop_new_value
}

addCase "updateIface" "mtu" {
	setIfcMTU $node_id $iface_id $iface_prop_new_value
}

addCase "updateIface" "vlan_dev" {
	setIfcVlanDev $node_id $iface_id $iface_prop_new_value
}

addCase "updateIface" "mac" {
	if { $iface_prop_new_value == "auto" } {
		autoMACaddr $node_id $iface_id
	} else {
		setIfcMACaddr $node_id $iface_id $iface_prop_new_value
	}
}

addCase "updateIface" "ipv4_addrs" {
	if { $iface_prop_new_value == "auto" } {
		autoIPAddr "ipv4" $node_id $iface_id
	} else {
		setIfcIPv4addrs $node_id $iface_id $iface_prop_new_value
	}
} "array"

addCase "updateIface" "ipv6_addrs" {
	if { $iface_prop_new_value == "auto" } {
		autoIPAddr "ipv6" $node_id $iface_id
	} else {
		setIfcIPv6addrs $node_id $iface_id $iface_prop_new_value
	}
} "array"
