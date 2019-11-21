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

proc $MODULE.confNewIfc { node ifc } {
    router.confNewIfc $node $ifc
}

proc $MODULE.confNewNode { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node
    global ripEnable ripngEnable ospfEnable ospf6Enable
    global rdconfig
    global nodeNamingBase

    set ripEnable [lindex $rdconfig 0]
    set ripngEnable [lindex $rdconfig 1]
    set ospfEnable [lindex $rdconfig 2]
    set ospf6Enable [lindex $rdconfig 3]	
    
    set nconfig [list \
	"hostname [getNewNodeNameType nat64 $nodeNamingBase(nat64)]" \
	! ]
    lappend $node "network-config [list $nconfig]"
    
    setNodeProtocolRip $node $ripEnable
    setNodeProtocolRipng $node $ripngEnable
    setNodeProtocolOspfv2 $node $ospfEnable 
    setNodeProtocolOspfv3 $node $ospf6Enable
    
    foreach proto { rip ripng ospf ospf6 bgp } {
	set protocfg [netconfFetchSection $node "router $proto"]
	if { $protocfg != "" } {
	    set protocfg [linsert $protocfg 0 "router $proto"]
	    set protocfg [linsert $protocfg end "!"]
	    set protocfg [linsert $protocfg [lsearch $protocfg " network *"] " redistribute kernel" ]
	    netconfClearSection $node "router $proto"
	    netconfInsertSection $node $protocfg
	}
    }

    setLogIfcType $node lo0 lo
    setIfcIPv4addr $node lo0 "127.0.0.1/8"
    setIfcIPv6addr $node lo0 "::1/128"

    setTaygaIPv4DynPool $node "192.168.64.0/24"
    setTaygaIPv6Prefix $node "2001::/96"
}

proc $MODULE.icon {size} {
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
	set w 507 
    }
    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Interfaces" } { 
	set h 320 
	set w 507 
    }

    return [list $h $w] 
}

proc $MODULE.ifcName {l r} {
    return [l3IfcName $l $r]
}

proc $MODULE.IPAddrRange {} {
    return 20
}

proc $MODULE.layer {} {
    return NETWORK
}

proc $MODULE.virtlayer {} {
    return VIMAGE 
}

proc $MODULE.cfggen { node } {
    set cfg [router.quagga.cfggen $node]

    upvar 0 ::cf::[set ::curcfg]::eid eid
    global nat64ifc_$eid.$node
    if { [info exists nat64ifc_$eid.$node] == 0 } {
	set nat64ifc_$eid.$node "tun0"
    }
    set tun [set nat64ifc_$eid.$node]
    if { $tun != "" } {
	set tayga4pool [getTaygaIPv4DynPool $node]
	set tayga6prefix [getTaygaIPv6Prefix $node]

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

proc $MODULE.bootcmd { node } {
    return [router.quagga.bootcmd $node] 
}

proc $MODULE.shellcmds { } {
    return [router.quagga.shellcmds]
}

proc $MODULE.instantiate { eid node } {
    router.quagga.instantiate $eid $node
}

proc $MODULE.start { eid node } {
    global nat64ifc_$eid.$node

    set tun [createStartTunIfc $eid $node]
    set nat64ifc_$eid.$node $tun

    router.quagga.start $eid $node

    set datadir "/var/db/tayga"

    set tayga4addr [lindex [split [getTaygaIPv4DynPool $node] "/"] 0]
    set tayga4pool [getTaygaIPv4DynPool $node]
    set tayga6prefix [getTaygaIPv6Prefix $node]

    set fd "tun-device\t$tun\n"
    set fd "$fd ipv4-addr\t$tayga4addr\n"
    set fd "$fd dynamic-pool\t$tayga4pool\n"
    set fd "$fd prefix\t\t$tayga6prefix\n"
    set fd "$fd data-dir\t$datadir\n"
    set fd "$fd\n"
    foreach map [getTaygaMappings $node] {
	set fd "$fd map\t\t$map\n"
    }

    prepareTaygaConf $eid $node $fd $datadir

    # XXX
    # Even though this routes should be added here, we add them in the
    # router.quagga.start procedure which invokes nat64.cfggen where we define
    # them with:
    # lappend cfg "ip route $tayga4pool $tun"
    # lappend cfg "ipv6 route $tayga6prefix $tun"
    # This is done in order for quagga to redistribute these routes.
    # FreeBSD:
    # exec jexec $eid.$node route -n add -inet $tayga4pool -interface $tun
    # exec jexec $eid.$node route -n add -inet6 $tayga6prefix -interface $tun
    # Linux:
    # exec docker exec $eid.$node ip route add $tayga4pool dev $tun
    # exec docker exec $eid.$node ip route add $tayga6prefix dev $tun

    execCmdNode $node tayga
}

proc $MODULE.shutdown { eid node } {
    router.quagga.shutdown $eid $node
    taygaShutdown $eid $node
}

proc $MODULE.destroy { eid node } {
    taygaDestroy $eid $node
    router.quagga.destroy $eid $node
}

proc $MODULE.nghook { eid node ifc } {
    return [router.quagga.nghook $eid $node $ifc] 
}


proc $MODULE.configGUI { c node } {
    global wi
    global guielements treecolumns
    set guielements {}

    configGUI_createConfigPopupWin $c
    wm title $wi "nat64 configuration"
    configGUI_nodeName $wi $node "Node name:"

    set tabs [configGUI_addNotebook $wi $node {"Configuration" "Interfaces" "NAT64"}]
    set configtab [lindex $tabs 0]
    set ifctab [lindex $tabs 1]
    set nat64tab [lindex $tabs 2]

    set treecolumns {"OperState State" "IPv4addr IPv4 addr" "IPv6addr IPv6 addr" \
            "MACaddr MAC addr" "MTU MTU" "QLen Queue len" "QDisc Queue disc" "QDrop Queue drop" }
    configGUI_addTree $ifctab $node

    configGUI_routingProtocols $configtab $node
    configGUI_dockerImage $configtab $node
    configGUI_attachDockerToExt $configtab $node
    configGUI_servicesConfig $configtab $node
    configGUI_staticRoutes $configtab $node
    configGUI_snapshots $configtab $node
    configGUI_customConfig $configtab $node
    configGUI_nat64Config $nat64tab $node

    configGUI_buttonsACNode $wi $node
}

proc $MODULE.configInterfacesGUI { wi node ifc } {
    global guielements

    configGUI_ifcEssentials $wi $node $ifc
    configGUI_ifcQueueConfig $wi $node $ifc
    configGUI_ifcMACAddress $wi $node $ifc
    configGUI_ifcIPv4Address $wi $node $ifc
    configGUI_ifcIPv6Address $wi $node $ifc
}
