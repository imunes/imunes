proc getTunIPv4Addr { node } {
    return [cfgGet "nodes" $node "nat64" "tun_ipv4_addr"]
}

proc setTunIPv4Addr { node addr } {
    cfgSet "node" $node "nat64" "tun_ipv4_addr" $addr

    # TODO: not used
    trigger_nodeReconfig $node
}

proc getTunIPv6Addr { node } {
    return [cfgGet "nodes" $node "nat64" "tun_ipv6_addr"]
}

proc setTunIPv6Addr { node addr } {
    cfgSet "node" $node "nat64" "tun_ipv6_addr" $addr

    # TODO: not used
    trigger_nodeReconfig $node
}

proc getTaygaIPv4Addr { node } {
    return [cfgGet "nodes" $node "nat64" "tayga_ipv4_addr"]
}

proc setTaygaIPv4Addr { node addr } {
    cfgSet "nodes" $node "nat64" "tayga_ipv4_addr" $addr

    # TODO: not used
    trigger_nodeReconfig $node
}

proc getTaygaIPv6Prefix { node } {
    return [cfgGet "nodes" $node "nat64" "tayga_ipv6_prefix"]
}

proc setTaygaIPv6Prefix { node addr } {
    cfgSet "nodes" $node "nat64" "tayga_ipv6_prefix" $addr

    # TODO: check
    trigger_nodeReconfig $node
}

proc getTaygaIPv4DynPool { node } {
    return [cfgGet "nodes" $node "nat64" "tayga_ipv4_pool"]
}

proc setTaygaIPv4DynPool { node addr } {
    cfgSet "nodes" $node "nat64" "tayga_ipv4_pool" $addr

    # TODO: check
    trigger_nodeReconfig $node
}

proc getTaygaMappings { node } {
    return [cfgGet "nodes" $node "nat64" "tayga_mappings"]
}

proc setTaygaMappings { node mps } {
    cfgSet "nodes" $node "nat64" "tayga_mappings" $mps

    # TODO: check
    trigger_nodeReconfig $node
}

proc _getTunIPv4Addr { node } {
    return [_cfgGet $node "nat64" "tun_ipv4_addr"]
}

proc _setTunIPv4Addr { node addr } {
    return [_cfgSet "node" $node "nat64" "tun_ipv4_addr" $addr]
}

proc _getTunIPv6Addr { node } {
    return [_cfgGet $node "nat64" "tun_ipv6_addr"]
}

proc _setTunIPv6Addr { node addr } {
    return [_cfgSet "node" $node "nat64" "tun_ipv6_addr" $addr]
}

proc _getTaygaIPv4Addr { node } {
    return [_cfgGet $node "nat64" "tayga_ipv4_addr"]
}

proc _setTaygaIPv4Addr { node addr } {
    return [_cfgSet $node "nat64" "tayga_ipv4_addr" $addr]
}

proc _getTaygaIPv6Prefix { node } {
    return [_cfgGet $node "nat64" "tayga_ipv6_prefix"]
}

proc _setTaygaIPv6Prefix { node addr } {
    return [_cfgSet $node "nat64" "tayga_ipv6_prefix" $addr]
}

proc _getTaygaIPv4DynPool { node } {
    return [_cfgGet $node "nat64" "tayga_ipv4_pool"]
}

proc _setTaygaIPv4DynPool { node addr } {
    return [_cfgSet $node "nat64" "tayga_ipv4_pool" $addr]
}

proc _getTaygaMappings { node } {
    return [_cfgGet $node "nat64" "tayga_mappings"]
}

proc _setTaygaMappings { node mps } {
    return [_cfgSet $node "nat64" "tayga_mappings" $mps]
}
