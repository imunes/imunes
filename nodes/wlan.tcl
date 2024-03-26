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

proc $MODULE.confNewIfc { node ifc } {
    foreach l2node [listLANnodes $node ""] {
	foreach ifc [ifcList $l2node] {
	    set peer [peerByIfc $l2node $ifc]
	    if { ! [isNodeRouter $peer] &&
		[[typemodel $peer].layer] == "NETWORK" } {
		set ifname [ifcByPeer $peer $l2node]
		autoIPv4defaultroute $peer $ifname
		autoIPv6defaultroute $peer $ifname
	    }
	}
    }
}

proc $MODULE.confNewNode { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node
    
    set nconfig [list \
	"hostname $node" \
	! ]
    lappend $node "network-config [list $nconfig]"
}

proc $MODULE.icon {size} {
    global ROOTDIR LIBDIR
    switch $size {
      normal {
	return $ROOTDIR/$LIBDIR/icons/normal/cloud.gif
      }
      small {
	return $ROOTDIR/$LIBDIR/icons/small/cloud.gif
      }
      toolbar {
	return $ROOTDIR/$LIBDIR/icons/tiny/cloud.gif
      }
    }
}

proc $MODULE.toolbarIconDescr {} {
    return "Add new WLAN domain"
}

proc $MODULE.ifcName {l r} {
    return e
}

proc $MODULE.layer {} {
    return LINK
}

proc $MODULE.virtlayer {} {
    return NETGRAPH
}

proc $MODULE.instantiate { eid node } {
    upvar 0 ::cf::[set ::curcfg]::ngnodemap ngnodemap

    set t [exec printf "mkpeer rfee link0 link0\nshow ." | jexec $eid ngctl -f -]
    set tlen [string length $t]
    set id [string range $t [expr $tlen - 31] [expr $tlen - 24]]
    catch {exec jexec $eid ngctl name \[$id\]: $node}
    set ngnodemap($eid\.$node) $node
}

proc $MODULE.start { eid node } {
    upvar 0 ::cf::[set ::curcfg]::ngnodemap ngnodemap

    set ngid $ngnodemap($eid\.$node)
    set wlan_epids ""
    foreach ifc [ifcList $node] {
	lappend wlan_epids [string range [logicalPeerByIfc $node $ifc] 1 end]
    }

    foreach ifc [ifcList $node] {
	set local_linkname link[string range $ifc 1 end]
	set local_epid [string range [logicalPeerByIfc $node $ifc] 1 end]
	set tx_bandwidth 54000000
	set tx_jitter 1.5
	set tx_duplicate 5
	set tx_qlen 20

	set visible_epids ""
	set local_x [lindex [getNodeCoords n$local_epid] 0]
	set local_y [lindex [getNodeCoords n$local_epid] 1]
	foreach epid $wlan_epids {
	    if {$epid == $local_epid} {
		continue
	    }
	    set x [lindex [getNodeCoords n$epid] 0]
	    set y [lindex [getNodeCoords n$epid] 1]
	    set d [expr sqrt(($local_x - $x) ** 2 + ($local_y - $y) ** 2)]
	    set ber [format %1.0E [expr 1 - 0.99999999 / (1 + ($d / 500) ** 30)]]
	    if {$ber == "1E+00"} {
		continue
	    }
	    lappend visible_epids $epid:ber$ber
	}

	exec jexec $eid ngctl msg [set ngid]: setlinkcfg $local_linkname $local_epid:jit$tx_jitter:dup$tx_duplicate:bw$tx_bandwidth $visible_epids
    }
}

proc $MODULE.destroy { eid node } {
    catch { nexec jexec $eid ngctl msg $node: shutdown }
}

proc $MODULE.nghook { eid node ifc } {
    set ifunit [string range $ifc 1 end]
    return [list $eid\.$node link$ifunit]
}

proc $MODULE.configGUI { c node } {
    global wi
    global guielements treecolumns
    set guielements {}

    configGUI_createConfigPopupWin $c
    wm title $wi "WLAN configuration"
    configGUI_nodeName $wi $node "Node name:"

    configGUI_buttonsACNode $wi $node
}

proc $MODULE.configInterfacesGUI { wi node ifc } {
    global guielements

    configGUI_ifcQueueConfig $wi $node $ifc
}

proc $MODULE.maxLinks {} {
    return 2048
}
