#
# Copyright 2005-2010 University of Zagreb, Croatia.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# This work was supported in part by Croatian Ministry of Science
# and Technology through the research contract #IP-2003-143.
#

set MODULE nat64

registerModule $MODULE

proc $MODULE.confNewIfc { node_id ifc } {
    router.confNewIfc $node_id $ifc
}

proc $MODULE.confNewNode { node_id } {
    global ripEnable ripngEnable ospfEnable ospf6Enable
    global rdconfig
    global nodeNamingBase

    lassign $rdconfig ripEnable ripngEnable ospfEnable ospf6Enable

    setNodeName $node_id [getNewNodeNameType nat64 $nodeNamingBase(nat64)]

    setNodeProtocol $node_id "rip" $ripEnable
    setNodeProtocol $node_id "ripng" $ripngEnable
    setNodeProtocol $node_id "ospf" $ospfEnable
    setNodeProtocol $node_id "ospf6" $ospf6Enable

    setAutoDefaultRoutesStatus $node_id "enabled"

    set logiface_id [newLogIface $node_id "lo"]
    setIfcIPv4addrs $node_id $logiface_id "127.0.0.1/8"
    setIfcIPv6addrs $node_id $logiface_id "::1/128"

    setTaygaIPv4DynPool $node_id "192.168.64.0/24"
    setTaygaIPv6Prefix $node_id "2001::/96"
}

proc $MODULE.icon { size } {
    global ROOTDIR LIBDIR

    switch $size {
	normal {
	    return $ROOTDIR/$LIBDIR/icons/normal/nat64.gif
	}
	small {
	    return $ROOTDIR/$LIBDIR/icons/small/nat64.gif
	}
	toolbar {
	    return $ROOTDIR/$LIBDIR/icons/tiny/nat64.gif
	}
    }
}

proc $MODULE.toolbarIconDescr {} {
    return "Add new NAT64"
}

proc $MODULE.notebookDimensions { wi } {
    set h 270
    set w 507

    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Configuration" } {
    set h 320
	set w 507
    }
    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Interfaces" } {
	set h 320
	set w 507
    }

    return [list $h $w]
}

proc $MODULE.ifcName { l r } {
    return [l3IfcName $l $r]
}

proc $MODULE.IPAddrRange {} {
    return 20
}

proc $MODULE.netlayer {} {
    return NETWORK
}

proc $MODULE.virtlayer {} {
    return VIMAGE
}

proc $MODULE.cfggen { node_id } {
    set cfg [router.frr.cfggen $node_id]

    set eid [getFromRunning "eid"]
    global nat64ifc_$eid.$node_id

    if { [info exists nat64ifc_$eid.$node_id] == 0 } {
	set nat64ifc_$eid.$node_id "tun0"
    }

    set tun [set nat64ifc_$eid.$node_id]
    if { $tun != "" } {
	set tayga4pool [getTaygaIPv4DynPool $node_id]
	set tayga6prefix [getTaygaIPv6Prefix $node_id]

	if { $tayga4pool != "" } {
	    lappend cfg "!"
	    lappend cfg "ip route $tayga4pool $tun"
	}
	if { $tayga6prefix != "" } {
	    lappend cfg "ipv6 route $tayga6prefix $tun"
	    lappend cfg "!"
	}
    }

    return $cfg
}

proc $MODULE.bootcmd { node_id } {
    return [router.frr.bootcmd $node_id]
}

proc $MODULE.shellcmds {} {
    return [router.frr.shellcmds]
}

proc $MODULE.instantiate { eid node_id } {
    router.frr.instantiate $eid $node_id
}

proc $MODULE.setupNamespace { eid node } {
    l3node.setupNamespace $eid $node
}

proc $MODULE.initConfigure { eid node } {
    l3node.initConfigure $eid $node

    enableIPforwarding $eid $node
}

proc $MODULE.createIfcs { eid node ifcs } {
    l3node.createIfcs $eid $node $ifcs
}

proc $MODULE.start { eid node_id } {
    global nat64ifc_$eid.$node_id

    set tun [createStartTunIfc $eid $node_id]
    set nat64ifc_$eid.$node_id $tun

    router.frr.start $eid $node_id

    set datadir "/var/db/tayga"

    set tayga4addr [lindex [split [getTaygaIPv4DynPool $node_id] "/"] 0]
    set tayga4pool [getTaygaIPv4DynPool $node_id]
    set tayga6prefix [getTaygaIPv6Prefix $node_id]

    set fd "tun-device\t$tun\n"
    set fd "$fd ipv4-addr\t$tayga4addr\n"
    set fd "$fd dynamic-pool\t$tayga4pool\n"
    set fd "$fd prefix\t\t$tayga6prefix\n"
    set fd "$fd data-dir\t$datadir\n"
    set fd "$fd\n"
    foreach map [getTaygaMappings $node_id] {
	set fd "$fd map\t\t$map\n"
    }

    prepareTaygaConf $eid $node_id $fd $datadir

    # XXX
    # Even though this routes should be added here, we add them in the
    # router.frr.start procedure which invokes nat64.cfggen where we define
    # them with:
    # lappend cfg "ip route $tayga4pool $tun"
    # lappend cfg "ipv6 route $tayga6prefix $tun"
    # This is done in order for frr to redistribute these routes.
    # FreeBSD:
    # exec jexec $eid.$node_id route -n add -inet $tayga4pool -interface $tun
    # exec jexec $eid.$node_id route -n add -inet6 $tayga6prefix -interface $tun
    # Linux:
    # exec docker exec $eid.$node_id ip route add $tayga4pool dev $tun
    # exec docker exec $eid.$node_id ip route add $tayga6prefix dev $tun

    execCmdNode $node_id tayga
}

proc $MODULE.shutdown { eid node_id } {
    router.frr.shutdown $eid $node_id
    taygaShutdown $eid $node_id
}

proc $MODULE.destroy { eid node_id } {
    taygaDestroy $eid $node_id
    router.frr.destroy $eid $node_id
}

proc $MODULE.nghook { eid node_id ifc } {
    return [router.frr.nghook $eid $node_id $ifc]
}

proc $MODULE.configGUI { c node_id } {
    global wi
    global guielements treecolumns
    set guielements {}

    configGUI_createConfigPopupWin $c
    wm title $wi "nat64 configuration"
    configGUI_nodeName $wi $node_id "Node name:"

    set tabs [configGUI_addNotebook $wi $node_id {"Configuration" "Interfaces" "NAT64"}]
    set configtab [lindex $tabs 0]
    set ifctab [lindex $tabs 1]
    set nat64tab [lindex $tabs 2]

    set treecolumns {"OperState State" "NatState Nat" "IPv4addr IPv4 addr" "IPv6addr IPv6 addr" \
            "MACaddr MAC addr" "MTU MTU" "QLen Queue len" "QDisc Queue disc" "QDrop Queue drop" }
    configGUI_addTree $ifctab $node_id

    configGUI_routingProtocols $configtab $node_id
    configGUI_customImage $configtab $node_id
    configGUI_attachDockerToExt $configtab $node_id
    configGUI_servicesConfig $configtab $node_id
    configGUI_staticRoutes $configtab $node_id
    configGUI_snapshots $configtab $node_id
    configGUI_customConfig $configtab $node_id
    configGUI_nat64Config $nat64tab $node_id

    configGUI_buttonsACNode $wi $node_id
}

proc $MODULE.configInterfacesGUI { wi node_id ifc } {
    global guielements

    configGUI_ifcEssentials $wi $node_id $ifc
    configGUI_ifcQueueConfig $wi $node_id $ifc
    configGUI_ifcMACAddress $wi $node_id $ifc
    configGUI_ifcIPv4Address $wi $node_id $ifc
    configGUI_ifcIPv6Address $wi $node_id $ifc
}
