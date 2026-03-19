# updateNode cases

addCase "updateNode" "packgen" {
	upvar ::switch_cases::updateNode_packgen switch_cases_packgen_var

	set packgen_diff [dictDiff $old_value $new_value]
	dict for {packgen_key packgen_change} $packgen_diff {
		if { $packgen_change == "copy" } {
			continue
		}

		dputs "======== $packgen_change: '$packgen_key'"

		set packgen_old_value [_cfgGet $old_value $packgen_key]
		set packgen_new_value [_cfgGet $new_value $packgen_key]
		if { $packgen_change in "changed" } {
			dputs "======== OLD: '$packgen_old_value'"
		}
		if { $packgen_change in "new changed" } {
			dputs "======== NEW: '$packgen_new_value'"
		}

		switch -exact $packgen_key [list {*}$switch_cases_packgen_var default {}]
	}
} "inner_dictionary"

addCase "updateNode_packgen" "packetrate" {
	setPackgenPacketRate $node_id $packgen_new_value
}

addCase "updateNode_packgen" "packets" {
	set packets_diff [dictDiff $packgen_old_value $packgen_new_value]
	foreach {packets_key packets_change} $packets_diff {
		if { $packets_change == "copy" } {
			continue
		}

		dputs "============ $packets_change: '$packets_key'"

		set packet_old_value [_cfgGet $packgen_old_value $packets_key]
		set packet_new_value [_cfgGet $packgen_new_value $packets_key]
		if { $packets_change in "changed" } {
			dputs "============ OLD: '$packet_old_value'"
		}
		if { $packets_change in "new changed" } {
			dputs "============ NEW: '$packet_new_value'"
		}

		switch -exact $packets_change {
			"removed" {
				removePackgenPacket $node_id $packets_key
			}

			"new" {
				addPackgenPacket $node_id $packets_key $packet_new_value
			}

			"changed" {
				removePackgenPacket $node_id $packets_key
				addPackgenPacket $node_id $packets_key $packet_new_value
			}
		}
	}
} "inner_dictionary"

# node-specific procedures

proc getPackgenPacketRate { node_id } {
	return [cfgGetWithDefault 100 "nodes" $node_id "packgen" "packetrate"]
}

proc setPackgenPacketRate { node_id rate } {
	cfgSet "nodes" $node_id "packgen" "packetrate" $rate

	trigger_nodeReconfig $node_id
}

proc getPackgenPacket { node_id id } {
	return [cfgGet "nodes" $node_id "packgen" "packets" $id]
}

proc addPackgenPacket { node_id id new_value } {
	cfgSetEmpty "nodes" $node_id "packgen" "packets" $id $new_value

	trigger_nodeReconfig $node_id
}

proc removePackgenPacket { node_id id } {
	cfgUnset "nodes" $node_id "packgen" "packets" $id

	trigger_nodeReconfig $node_id
}

proc getPackgenPacketData { node_id id } {
	return [cfgGet "nodes" $node_id "packgen" "packets" $id]
}

proc packgenPackets { node_id } {
	return [cfgGet "nodes" $node_id "packgen" "packets"]
}

proc checkPacketNum { str } {
	return [regexp {^([1-9])([0-9])*$} $str]
}

proc checkPacketData { str } {
	set str [string map { " " "." ":" "." } $str]
	if { $str != "" } {
		return [regexp {^([0-9a-f][0-9a-f])*$} $str]
	}

	return 1
}
