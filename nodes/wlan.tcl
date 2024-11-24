#
# Copyright 2015 University of Zagreb.
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

set MODULE wlan

registerModule $MODULE

proc $MODULE.prepareSystem {} {
    catch { exec kldload ng_rfee }
}

proc $MODULE.confNewIfc { node_id iface_id } {
}

proc $MODULE.confNewNode { node_id } {
    global nodeNamingBase

    setNodeName $node_id [getNewNodeNameType wlan $nodeNamingBase(wlan)]
}

proc $MODULE.ifacePrefix { l r } {
    return e
}

proc $MODULE.netlayer {} {
    return LINK
}

proc $MODULE.virtlayer {} {
    return NATIVE
}

proc $MODULE.nodeCreate { eid node_id } {
    upvar 0 ::cf::[set ::curcfg]::ngnodemap

    set t [exec printf "mkpeer rfee link0 link0\nshow ." | jexec $eid ngctl -f -]
    set tlen [string length $t]
    set id [string range $t [expr $tlen - 31] [expr $tlen - 24]]
    catch { exec jexec $eid ngctl name \[$id\]: $node_id }
    set ngnodemap($eid\.$node_id) $node_id
}

proc $MODULE.nodeConfigure { eid node_id } {
    upvar 0 ::cf::[set ::curcfg]::ngnodemap ngnodemap

    set ngid $ngnodemap($eid\.$node_id)
    set wlan_epids ""
    foreach iface_id [ifcList $node_id] {
	lappend wlan_epids [string range [lindex [logicalPeerByIfc $node_id $iface_id] 0] 1 end]
    }

    foreach iface_id [ifcList $node_id] {
	set local_linkname link[string range $iface_id 1 end]
	set local_epid [string range [lindex [logicalPeerByIfc $node_id $iface_id] 0] 1 end]
	set tx_bandwidth 54000000
	set tx_jitter 1.5
	set tx_duplicate 5
	set tx_qlen 20

	set visible_epids ""
	set local_x [lindex [getNodeCoords n$local_epid] 0]
	set local_y [lindex [getNodeCoords n$local_epid] 1]
	foreach epid $wlan_epids {
	    if { $epid == $local_epid } {
		continue
	    }
	    set x [lindex [getNodeCoords n$epid] 0]
	    set y [lindex [getNodeCoords n$epid] 1]
	    set d [expr sqrt(($local_x - $x) ** 2 + ($local_y - $y) ** 2)]
	    set ber [format %1.0E [expr 1 - 0.99999999 / (1 + ($d / 500) ** 30)]]
	    if { $ber == "1E+00" } {
		continue
	    }
	    lappend visible_epids $epid:ber$ber
	}

	exec jexec $eid ngctl msg [set ngid]: setlinkcfg $local_linkname $local_epid:jit$tx_jitter:dup$tx_duplicate:bw$tx_bandwidth $visible_epids
    }
}

proc $MODULE.nodeDestroy { eid node_id } {
    catch { exec jexec $eid ngctl msg $node_id: shutdown }
}

proc $MODULE.nghook { eid node_id iface_id } {
    set ifunit [string range $iface_id 1 end]
    return [list $eid\.$node_id link$ifunit]
}

proc $MODULE.maxLinks {} {
    return 2048
}
