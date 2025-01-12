proc getTunIPv4Addr { node_id } {
    return [cfgGet "nodes" $node_id "nat64" "tun_ipv4_addr"]
}

proc setTunIPv4Addr { node_id addr } {
    cfgSet "nodes" $node_id "nat64" "tun_ipv4_addr" $addr
}

proc getTunIPv6Addr { node_id } {
    return [cfgGet "nodes" $node_id "nat64" "tun_ipv6_addr"]
}

proc setTunIPv6Addr { node_id addr } {
    cfgSet "nodes" $node_id "nat64" "tun_ipv6_addr" $addr
}

proc getTaygaIPv4Addr { node_id } {
    return [cfgGet "nodes" $node_id "nat64" "tayga_ipv4_addr"]
}

proc setTaygaIPv4Addr { node_id addr } {
    cfgSet "nodes" $node_id "nat64" "tayga_ipv4_addr" $addr
}

proc getTaygaIPv6Prefix { node_id } {
    return [cfgGet "nodes" $node_id "nat64" "tayga_ipv6_prefix"]
}

proc setTaygaIPv6Prefix { node_id addr } {
    cfgSet "nodes" $node_id "nat64" "tayga_ipv6_prefix" $addr
}

proc getTaygaIPv4DynPool { node_id } {
    return [cfgGet "nodes" $node_id "nat64" "tayga_ipv4_pool"]
}

proc setTaygaIPv4DynPool { node_id addr } {
    cfgSet "nodes" $node_id "nat64" "tayga_ipv4_pool" $addr
}

proc getTaygaMappings { node_id } {
    return [cfgGet "nodes" $node_id "nat64" "tayga_mappings"]
}

proc setTaygaMappings { node_id mps } {
    cfgSet "nodes" $node_id "nat64" "tayga_mappings" $mps
}
