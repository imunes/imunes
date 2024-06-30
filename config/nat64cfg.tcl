proc getTunIPv4Addr { node } {
    return [cfgGet "nodes" $node "nat64" "tunIPv4addr"]
}

proc setTunIPv4Addr { node addr } {
    cfgSet "node" $node "nat64" "tunIPv4addr" $addr
}

proc getTunIPv6Addr { node } {
    return [cfgGet "nodes" $node "nat64" "tunIPv6addr"]
}

proc setTunIPv6Addr { node addr } {
    cfgSet "node" $node "nat64" "tunIPv6addr" $addr
}

proc getTaygaIPv4Addr { node } {
    return [cfgGet "nodes" $node "nat64" "taygaIPv4addr"]
}

proc setTaygaIPv4Addr { node addr } {
    cfgSet "nodes" $node "nat64" "taygaIPv4addr" $addr
}

proc getTaygaIPv6Prefix { node } {
    return [cfgGet "nodes" $node "nat64" "taygaIPv6prefix"]
}

proc setTaygaIPv6Prefix { node addr } {
    cfgSet "nodes" $node "nat64" "taygaIPv6prefix" $addr
}

proc getTaygaIPv4DynPool { node } {
    return [cfgGet "nodes" $node "nat64" "taygaIPv4pool"]
}

proc setTaygaIPv4DynPool { node addr } {
    cfgSet "nodes" $node "nat64" "taygaIPv4pool" $addr
}

proc getTaygaMappings { node } {
    return [cfgGet "nodes" $node "nat64" "taygaMappings"]
}

proc setTaygaMappings { node mps } {
    cfgSet "nodes" $node "nat64" "taygaMappings" $mps
}
