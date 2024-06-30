proc getPackgenPacketRate { node } {
    return [cfgGetWithDefault 100 "nodes" $node "packgen" "packetrate"]
}

proc setPackgenPacketRate { node value } {
    cfgSet "nodes" $node "packgen" "packetrate" $value
}

proc getPackgenPacket { node id } {
    return [cfgGet "nodes" $node "packgen" "packets" $id]
}

proc addPackgenPacket { node id value } {
    cfgSetEmpty "nodes" $node "packgen" "packets" $id $value
}

proc removePackgenPacket { node id } {
    cfgUnset "nodes" $node "packgen" "packets" $id
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
