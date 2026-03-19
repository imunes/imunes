# updateNode cases

addCase "updateNode" "name" {
	setNodeName $node_id $new_value
}

addCase "updateNode" "vlan_filtering" {
	setNodeVlanFiltering $node_id $new_value
}

addCase "updateNode" "nat_iface" {
	setNodeNATIface $node_id $new_value
}

addCase "updateNode" "ifaces" {
	set ifaces_diff [dictDiff $old_value $new_value]
	dict for {iface_key iface_change} $ifaces_diff {
		if { $iface_change == "copy" } {
			continue
		}

		dputs "======== $iface_change: '$iface_key'"

		set iface_old_value [_cfgGet $old_value $iface_key]
		set iface_new_value [_cfgGet $new_value $iface_key]
		if { $iface_change in "changed" } {
			dputs "======== OLD: '$iface_old_value'"
		}
		if { $iface_change in "new changed" } {
			dputs "======== NEW: '$iface_new_value'"
		}

		switch -exact $iface_change {
			"removed" {
				removeIface $node_id $iface_key
			}

			"new" -
			"changed" {
				set iface_type [_cfgGet $iface_new_value "type"]
				if { $iface_change == "new" } {
					set iface_id [newIface $node_id $iface_type 0]
				} else {
					set iface_id $iface_key
				}

				updateIface $node_id $iface_id $iface_old_value $iface_new_value
			}
		}
	}
} "dictionary"

addCase "updateNode" "events" {
	setElementEvents $node_id $new_value
} "array"

# updateIface cases

addCase "updateIface" "type" {
	setIfcType $node_id $iface_id $iface_prop_new_value
}

addCase "updateIface" "name" {
	setIfcName $node_id $iface_id $iface_prop_new_value
}

addCase "updateIface" "link" {
	# link cannot be changed, only removed
	if { $iface_prop_change == "removed" } {
		removeLink $iface_prop_old_value 1
	}
}

addCase "updateIface" "ifc_qdisc" {
	setIfcQDisc $node_id $iface_id $iface_prop_new_value
}

addCase "updateIface" "ifc_qdrop" {
	setIfcQDrop $node_id $iface_id $iface_prop_new_value
}

addCase "updateIface" "queue_len" {
	setIfcQLen $node_id $iface_id $iface_prop_new_value
}

addCase "updateIface" "vlan_tag" {
	setIfcVlanTag $node_id $iface_id $iface_prop_new_value
}

addCase "updateIface" "vlan_type" {
	setIfcVlanType $node_id $iface_id $iface_prop_new_value
}
