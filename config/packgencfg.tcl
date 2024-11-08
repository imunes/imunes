proc getPackgenPacketRate { node_id } {
    return [cfgGetWithDefault 100 "nodes" $node_id "packgen" "packetrate"]
}

proc setPackgenPacketRate { node_id rate } {
    cfgSet "nodes" $node_id "packgen" "packetrate" $rate
}

proc getPackgenPacket { node_id id } {
    return [cfgGet "nodes" $node_id "packgen" "packets" $id]
}

proc addPackgenPacket { node_id id new_value } {
    cfgSetEmpty "nodes" $node_id "packgen" "packets" $id $new_value
}

proc removePackgenPacket { node_id id } {
    cfgUnset "nodes" $node_id "packgen" "packets" $id
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
