proc getTunIPv4Addr { node_id } {
    return [cfgGet "nodes" $node_id "nat64" "tunIPv4addr"]
}

proc setTunIPv4Addr { node_id addr } {
    cfgSet "nodes" $node_id "nat64" "tunIPv4addr" $addr
}

proc getTunIPv6Addr { node_id } {
    return [cfgGet "nodes" $node_id "nat64" "tunIPv6addr"]
}

proc setTunIPv6Addr { node_id addr } {
    cfgSet "nodes" $node_id "nat64" "tunIPv6addr" $addr
}

proc getTaygaIPv4Addr { node_id } {
    return [cfgGet "nodes" $node_id "nat64" "taygaIPv4addr"]
}

proc setTaygaIPv4Addr { node_id addr } {
    cfgSet "nodes" $node_id "nat64" "taygaIPv4addr" $addr
}

proc getTaygaIPv6Prefix { node_id } {
    return [cfgGet "nodes" $node_id "nat64" "taygaIPv6prefix"]
}

proc setTaygaIPv6Prefix { node_id addr } {
    cfgSet "nodes" $node_id "nat64" "taygaIPv6prefix" $addr
}

proc getTaygaIPv4DynPool { node_id } {
    return [cfgGet "nodes" $node_id "nat64" "taygaIPv4pool"]
}

proc setTaygaIPv4DynPool { node_id addr } {
    cfgSet "nodes" $node_id "nat64" "taygaIPv4pool" $addr
}

proc getTaygaMappings { node_id } {
    return [cfgGet "nodes" $node_id "nat64" "taygaMappings"]
}

proc setTaygaMappings { node_id mps } {
    cfgSet "nodes" $node_id "nat64" "taygaMappings" $mps
}
