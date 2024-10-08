proc getPackgenPacketRate { node } {
    return [cfgGetWithDefault 100 "nodes" $node "packgen" "packetrate"]
}

proc setPackgenPacketRate { node value } {
    cfgSet "nodes" $node "packgen" "packetrate" $value

    # TODO: check
    trigger_nodeRecreate $node
}

proc getPackgenPacket { node id } {
    return [cfgGet "nodes" $node "packgen" "packets" $id]
}

proc addPackgenPacket { node id value } {
    cfgSetEmpty "nodes" $node "packgen" "packets" $id $value

    # TODO: check
    trigger_nodeRecreate $node
}

proc removePackgenPacket { node id } {
    cfgUnset "nodes" $node "packgen" "packets" $id

    # TODO: check
    trigger_nodeRecreate $node
}

proc getPackgenPacketData { node id } {
    return [cfgGet "nodes" $node "packgen" "packets" $id]
}

proc packgenPackets { node } {
    return [cfgGet "nodes" $node "packgen" "packets"]
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

proc _setPackgenPacketRate { node_cfg value } {
    return [_cfgSet $node_cfg "packgen" "packetrate" $value]
}

proc _getPackgenPacket { node_cfg id } {
    return [_cfgGet $node_cfg "packgen" "packets" $id]
}

proc _addPackgenPacket { node_cfg id value } {
    return [_cfgSetEmpty $node_cfg "packgen" "packets" $id $value]
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
