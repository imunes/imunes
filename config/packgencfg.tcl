proc getPackgenPacketRate { node_id } {
    return [cfgGetWithDefault 100 "nodes" $node_id "packgen" "packetrate"]
}

proc setPackgenPacketRate { node_id rate } {
    cfgSet "nodes" $node_id "packgen" "packetrate" $rate

    # TODO: check
    trigger_nodeRecreate $node_id
}

proc getPackgenPacket { node_id id } {
    return [cfgGet "nodes" $node_id "packgen" "packets" $id]
}

proc addPackgenPacket { node_id id new_value } {
    cfgSetEmpty "nodes" $node_id "packgen" "packets" $id $new_value

    # TODO: check
    trigger_nodeRecreate $node_id
}

proc removePackgenPacket { node_id id } {
    cfgUnset "nodes" $node_id "packgen" "packets" $id

    # TODO: check
    trigger_nodeRecreate $node_id
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

proc _getPackgenPacketRate { node_cfg } {
    return [_cfgGetWithDefault 100 $node_cfg "packgen" "packetrate"]
}

proc _setPackgenPacketRate { node_cfg rate } {
    return [_cfgSet $node_cfg "packgen" "packetrate" $rate]
}

proc _getPackgenPacket { node_cfg id } {
    return [_cfgGet $node_cfg "packgen" "packets" $id]
}

proc _addPackgenPacket { node_cfg id new_value } {
    return [_cfgSetEmpty $node_cfg "packgen" "packets" $id $new_value]
}

proc _removePackgenPacket { node_cfg id } {
    return [_cfgUnset $node_cfg "packgen" "packets" $id]
}

proc _getPackgenPacketData { node_cfg id } {
    return [_cfgGet $node_cfg "packgen" "packets" $id]
}

proc _packgenPackets { node_cfg } {
    return [_cfgGet $node_cfg "packgen" "packets"]
}
