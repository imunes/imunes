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
