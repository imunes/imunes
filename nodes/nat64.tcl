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

################################################################################
########################### CONFIGURATION PROCEDURES ###########################
################################################################################

proc $MODULE.confNewNode { node_id } {
    global nodeNamingBase

    router.confNewNode $node_id

    setNodeName $node_id [getNewNodeNameType nat64 $nodeNamingBase(nat64)]
    setTaygaIPv4DynPool $node_id "192.168.64.0/24"
    setTaygaIPv6Prefix $node_id "2001::/96"
}

proc $MODULE.confNewIfc { node_id ifc } {
    router.confNewIfc $node_id $ifc
}

proc $MODULE.generateConfigIfaces { node_id ifaces } {
    return [router.generateConfigIfaces $node_id $ifaces]
}

proc $MODULE.generateUnconfigIfaces { node_id ifaces } {
    return [router.generateUnconfigIfaces $node_id $ifaces]
}

proc $MODULE.generateConfig { node_id } {
    set cfg [router.generateConfig $node_id]

    lappend cfg ""

    set tayga4pool [getTaygaIPv4DynPool $node_id]
    setToRunning "${node_id}_old_tayga_ipv4_pool" $tayga4pool
    set tayga6prefix [getTaygaIPv6Prefix $node_id]
    setToRunning "${node_id}_old_tayga_ipv6_prefix" $tayga6prefix

    set tun_dev "tun64"
    if { $tayga4pool != "" } {
	lappend cfg "vtysh << __EOF__"
	lappend cfg "conf term"

	lappend cfg "!"
	lappend cfg "ip route $tayga4pool $tun_dev"

	lappend cfg "!"
	lappend cfg "__EOF__"
    }

    if { $tayga6prefix != "" } {
	lappend cfg "vtysh << __EOF__"
	lappend cfg "conf term"

	lappend cfg "ipv6 route $tayga6prefix $tun_dev"

	lappend cfg "!"
	lappend cfg "__EOF__"
    }

    set tayga4addr [lindex [split [getTaygaIPv4DynPool $node_id] "/"] 0]
    set tayga4pool [getTaygaIPv4DynPool $node_id]
    set tayga6prefix [getTaygaIPv6Prefix $node_id]

    set conf_file "/usr/local/etc/tayga.conf"
    set datadir "/var/db/tayga"

    lappend cfg "mkdir -p $datadir"
    lappend cfg "cat << __EOF__ > $conf_file"
    lappend cfg "tun-device\t$tun_dev"
    lappend cfg " ipv4-addr\t$tayga4addr"
    lappend cfg " dynamic-pool\t$tayga4pool"
    lappend cfg " prefix\t\t$tayga6prefix"
    lappend cfg " data-dir\t$datadir"
    lappend cfg ""
    foreach map [getTaygaMappings $node_id] {
	lappend cfg " map\t\t$map"
    }
    lappend cfg "__EOF__"

    lappend cfg ""

    lappend cfg "tayga -c $conf_file --mktun"
    set cfg "[concat $cfg [configureTunIface $tayga4pool $tayga6prefix]]"

    lappend cfg "tayga -c $conf_file"

    return $cfg
}

proc $MODULE.generateUnconfig { node_id } {
    set tayga4pool [getFromRunning "${node_id}_old_tayga_ipv4_pool"]
    set tayga6prefix [getFromRunning "${node_id}_old_tayga_ipv6_prefix"]

    set cfg ""

    set tun_dev "tun64"
    if { $tayga4pool != "" } {
	lappend cfg "vtysh << __EOF__"
	lappend cfg "conf term"

	lappend cfg "!"
	lappend cfg "no ip route $tayga4pool $tun_dev"

	lappend cfg "!"
	lappend cfg "__EOF__"
    }

    if { $tayga6prefix != "" } {
	lappend cfg "vtysh << __EOF__"
	lappend cfg "conf term"

	lappend cfg "no ipv6 route $tayga6prefix $tun_dev"

	lappend cfg "!"
	lappend cfg "__EOF__"
    }

    set conf_file "/usr/local/etc/tayga.conf"
    set datadir "/var/db/tayga"

    lappend cfg "killall tayga >/dev/null 2>&1"
    lappend cfg "[getStateIfcCmd "tun64" "down"]"
    lappend cfg "tayga -c $conf_file --rmtun"
    lappend cfg "rm -rf $datadir"

    set cfg [concat $cfg [router.generateUnconfig $node_id]]

    return $cfg
}

proc $MODULE.ifcName { l r } {
    return [router.ifcName $l $r]
}

#****f* nat64.tcl/nat64.ifacePrefix
# NAME
#   nat64.ifacePrefix -- interface name
# SYNOPSIS
#   nat64.ifacePrefix
# FUNCTION
#   Returns nat64 interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifacePrefix {} {
    return [router.ifacePrefix]
}

proc $MODULE.IPAddrRange {} {
    return [router.IPAddrRange]
}

proc $MODULE.netlayer {} {
    return [router.netlayer]
}

proc $MODULE.virtlayer {} {
    return [router.virtlayer]
}

proc $MODULE.bootcmd { node_id } {
    return [router.bootcmd $node_id]
}

proc $MODULE.shellcmds {} {
    return [router.shellcmds]
}

proc $MODULE.nghook { eid node_id ifc } {
    return [router.nghook $eid $node_id $ifc]
}

################################################################################
############################ INSTANTIATE PROCEDURES ############################
################################################################################

#****f* nat64.tcl/nat64.prepareSystem
# NAME
#   nat64.prepareSystem -- prepare system
# SYNOPSIS
#   nat64.prepareSystem
# FUNCTION
#   Does nothing
#****
proc $MODULE.prepareSystem {} {
    router.prepareSystem
}

proc $MODULE.nodeCreate { eid node_id } {
    router.nodeCreate $eid $node_id
}

proc $MODULE.nodeSetupNamespace { eid node_id } {
    router.nodeSetupNamespace $eid $node_id
}

proc $MODULE.nodeInitConfigure { eid node } {
    router.nodeInitConfigure $eid $node
}

proc $MODULE.nodePhysIfacesCreate { eid node_id ifaces } {
    router.nodePhysIfacesCreate $eid $node_id $ifaces
}

proc $MODULE.nodeLogIfacesCreate { eid node_id ifaces } {
    router.nodeLogIfacesCreate $eid $node_id $ifaces
}

#****f* exec.tcl/nat64.nodeIfacesConfigure
# NAME
#   nat64.nodeIfacesConfigure -- configure nat64 node interfaces
# SYNOPSIS
#   nat64.nodeIfacesConfigure $eid $node_id $ifaces
# FUNCTION
#   Configure interfaces on a nat64. Set MAC, MTU, queue parameters, assign the IP
#   addresses to the interfaces, etc. This procedure can be called if the node
#   is instantiated.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifaces -- list of interface ids
#****
proc $MODULE.nodeIfacesConfigure { eid node_id ifaces } {
    router.nodeIfacesConfigure $eid $node_id $ifaces
}

proc $MODULE.nodeConfigure { eid node_id } {
    router.nodeConfigure $eid $node_id
}

################################################################################
############################# TERMINATE PROCEDURES #############################
################################################################################

#****f* exec.tcl/nat64.nodeIfacesUnconfigure
# NAME
#   nat64.nodeIfacesUnconfigure -- unconfigure nat64 node interfaces
# SYNOPSIS
#   nat64.nodeIfacesUnconfigure $eid $node_id $ifaces
# FUNCTION
#   Unconfigure interfaces on a nat64 to a default state. Set name to iface_id,
#   flush IP addresses to the interfaces, etc. This procedure can be called if
#   the node is instantiated.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifaces -- list of interface ids
#****
proc $MODULE.nodeIfacesUnconfigure { eid node_id ifaces } {
    router.nodeIfacesUnconfigure $eid $node_id $ifaces
}

proc $MODULE.nodeIfacesDestroy { eid node_id ifaces } {
    router.nodeIfacesDestroy $eid $node_id $ifaces
}

proc $MODULE.nodeUnconfigure { eid node_id } {
    router.nodeUnconfigure $eid $node_id
}

proc $MODULE.nodeShutdown { eid node_id } {
    router.nodeShutdown $eid $node_id
}

proc $MODULE.nodeDestroy { eid node_id } {
    router.nodeDestroy $eid $node_id
}
