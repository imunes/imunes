#
# Copyright 2005-2013 University of Zagreb.
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

#****h* imunes/ipv6.tcl
# NAME
#   ipv6.tcl -- file for handeling IPv6
#****
global ipv6 changeAddrRange6 changeAddressRange6

set ipv6 fc00::/64
set changeAddrRange6 0
set changeAddressRange6 0

#****f* ipv6.tcl/IPv6AddrApply
# NAME
#   IPv6AddrApply -- IPv6 address apply
# SYNOPSIS
#   IPv6AddrApply $w
# FUNCTION
#   Sets new IPv6 address from widget.
# INPUTS
#   * w -- widget
#****
proc IPv6AddrApply { w } {
   global ipv6
   global changed
   global control

   set newipv6 [$w.ipv6frame.e1 get]

   if { [checkIPv6Net $newipv6] == 0 } {
        focusAndFlash .entry1.ipv6frame.e1
	return
   }
   destroy $w

   if { $newipv6 != $ipv6 } {
	set changed 1
        set control 1
   }
   set ipv6 $newipv6
}

#****f* ipv6.tcl/findFreeIPv6Net
# NAME
#   findFreeIPv6Net -- find free IPv6 network
# SYNOPSIS
#   set ipnet [findFreeIPv4Net $mask]
# FUNCTION
#   Finds a free IPv6 network. Network is concidered to be free
#   if there are no simulated nodes attached to it. 
# INPUTS
#   * mask -- this parameter is left unused for now
# RESULT
#   * ipnet -- returns the free IPv6 network address in the form "a $i". 
#****
proc findFreeIPv6Net { mask } {
    upvar 0 ::cf::[set ::curcfg]::IPv6UsedList IPv6UsedList
    global ipv6

    if { $IPv6UsedList == "" } {
	set defip6net [ip::contract [ip::prefix $ipv6]]
	set testnet [ip::contract "[string trimright $defip6net :]::"]
	return $testnet
    } else {
	set defip6net [ip::contract [ip::prefix $ipv6]]
	for { set i 0 } { $i <= 65535 } { incr i } {
	    set testnet [ip::contract "[string trimright $defip6net :]:[format %x $i]::"]
	    if { $testnet ni $IPv6UsedList } {
		return $testnet
	    }
	}
    }
}

#****f* ipv6.tcl/autoIPv6addr 
# NAME
#   autoIPv6addr -- automaticaly assign an IPv6 address
# SYNOPSIS
#   autoIPv6addr $node $iface 
# FUNCTION
#   automaticaly assignes an IPv6 address to the interface $iface of 
#   of the node $node.
# INPUTS
#   * node -- the node containing the interface to witch a new 
#     IPv6 address should be assigned
#   * iface -- the interface to witch a new, automatilacy generated, IPv6  
#     address will be assigned
#****
proc autoIPv6addr { node iface } {
    upvar 0 ::cf::[set ::curcfg]::IPv6UsedList IPv6UsedList
    global IPv6autoAssign
    if {!$IPv6autoAssign} {
	return
    }
    global changeAddrRange6 control changeAddressRange6 autorenumbered_ifcs6
    set peer_ip6addrs {}


    if { [[typemodel $node].layer] != "NETWORK" } { 
	#
	# Shouldn't get called at all for link-layer nodes
	#
	#puts "autoIPv6 called for a [[typemodel $node].layer] layer node"
	return
    }  

    setIfcIPv6addr $node $iface ""
    set peer_node [logicalPeerByIfc $node $iface]

    if { [[typemodel $peer_node].layer] == "LINK" } {
	foreach l2node [listLANnodes $peer_node {}] {
	    foreach ifc [ifcList $l2node] {
		set peer [logicalPeerByIfc $l2node $ifc]
		set peer_if [ifcByLogicalPeer $peer $l2node]
		set peer_ip6addr [getIfcIPv6addr $peer $peer_if]
		if { $changeAddressRange6 == 1 } {
		    if { [lsearch $autorenumbered_ifcs6 "$peer $peer_if"] != -1 } {
			if { $peer_ip6addr != "" } {
			    lappend peer_ip6addrs $peer_ip6addr
			}   
		    }
		} else {
		    if { $peer_ip6addr != "" } {
			lappend peer_ip6addrs $peer_ip6addr
		    }
		}
	    }
	}
    } else {
	set peer_if [ifcByLogicalPeer $peer_node $node]
	set peer_ip6addr [getIfcIPv6addr $peer_node $peer_if]
	set peer_ip6addrs $peer_ip6addr
    }

    set targetbyte [expr 0x[[nodeType $node].IPAddrRange]]

    if { $peer_ip6addrs != "" && $changeAddrRange6 == 0 } {
	set ipaddr  [nextFreeIP6Addr [lindex $peer_ip6addrs 0] $targetbyte $peer_ip6addrs]
	setIfcIPv6addr $node $iface $ipaddr
    } else {
	setIfcIPv6addr $node $iface "[findFreeIPv6Net 64][format %x $targetbyte]/64"
	lappend IPv6UsedList [ip::contract [ip::prefix [getIfcIPv6addr $node $iface]]]
    }
}

#****f* ipv6.tcl/nextFreeIP6Addr
# NAME
#   nextFreeIP6Addr -- automaticaly assign an IPv6 address
# SYNOPSIS
#   nextFreeIP6Addr $addr $start $peers 
# FUNCTION
#   Automaticaly searches for free IPv6 addresses within a given range
#   defined by $addr, containing $peers 
# INPUTS
#   * $addr -- address of a node within the range
#   * $start -- starting host address for a specified node type
#   * $peers -- list of peers in the current network
#****
proc nextFreeIP6Addr { addr start peers } { 
    global execMode
    set mask 64

    set prefix [ip::prefix $addr] 
    set ipnums [split $prefix :]

    set lastpart [expr [lindex $ipnums 7] + $start]
    set ipnums [lreplace $ipnums 7 7 [format %x $lastpart]]
    set ipaddr [ip::contract [join $ipnums :]]/$mask
    while { $ipaddr in $peers } {
	set lastpart [expr $lastpart + 1 ]
	set ipnums [lreplace $ipnums 7 7 [format %x $lastpart]]
	set ipaddr [ip::contract [join $ipnums :]]/$mask
    }

    set x [ip::prefix $addr] 
    set y [ip::prefix $ipaddr] 

    if { $x != $y } { 
	if { $execMode != "batch" } {
	    after idle {.dialog1.msg configure -wraplength 4i}
	    tk_dialog .dialog1 "IMUNES warning" \
		"You have depleted the current pool of addresses ([ip::contract $x]/$mask). Please choose a new pool from Tools->IPV6 address pool or delete nodes to free the address space." \
	    info 0 Dismiss
	}
	return ""
    }   

    return $ipaddr
}

#****f* ipv6.tcl/autoIPv6defaultroute 
# NAME
#   autoIPv6defaultroute -- automaticaly assign a default route 
# SYNOPSIS
#   autoIPv6defaultroute $node $iface 
# FUNCTION
#   searches the interface of the node for a router, if a router is found
#   then it is a new default gateway. 
# INPUTS
#   * node -- default gateway is provided for this node 
#   * iface -- the interface on witch we search for a new default gateway
#****
proc autoIPv6defaultroute { node iface } {
    global IPv6autoAssign
    if {!$IPv6autoAssign} {
	return
    }
    if { [[typemodel $node].layer] != "NETWORK" || \
	[isNodeRouter $node] } {
	#
	# Shouldn't get called at all for link-layer nodes
	#
	#puts "autoIPv6defaultroute called for [[typemodel $node].layer] node"
	return
    }

    set peer_node [logicalPeerByIfc $node $iface]

    if { [[typemodel $peer_node].layer] == "LINK" } {
	foreach l2node [listLANnodes $peer_node {}] {
	    foreach ifc [ifcList $l2node] {
		set peer [logicalPeerByIfc $l2node $ifc]
		if {! [isNodeRouter $peer] } {
		    continue
		}
		set peer_if [ifcByLogicalPeer $peer $l2node]
		set peer_ip6addr [getIfcIPv6addr $peer $peer_if]
		if { $peer_ip6addr != "" } {
		    set gw [lindex [split $peer_ip6addr /] 0]
		    setStatIPv6routes $node [list "::/0 $gw"]
		    return
		}
	    }
	}
    } else {
	if {! [isNodeRouter $peer_node] } {
	    return
	}
	set peer_if [ifcByLogicalPeer $peer_node $node]
	set peer_ip6addr [getIfcIPv6addr $peer_node $peer_if]
	if { $peer_ip6addr != "" } {
	    set gw [lindex [split $peer_ip6addr /] 0]
	    setStatIPv6routes $node [list "::/0 $gw"]
	    return
	}
    }
}

#****f* ipv6.tcl/checkIPv6Addr 
# NAME
#   checkIPv6Addr -- check the IPv6 address 
# SYNOPSIS
#   set valid [checkIPv6Addr $str]
# FUNCTION
#   Checks if the provided string is a valid IPv6 address. 
# INPUTS
#   * str -- string to be evaluated.
# RESULT
#   * valid -- function returns 0 if the input string is not in the form
#     of a valid IP address, 1 otherwise
#****
proc checkIPv6Addr { str } {
    set doublec false
    set wordlist [split $str :]
    set wordcnt [expr [llength $wordlist] - 1]
    if { $wordcnt < 2 || $wordcnt > 7 } {
	return 0
    }
    if { [lindex $wordlist 0] == "" } {
	set wordlist [lreplace $wordlist 0 0 0]
    }
    if { [lindex $wordlist $wordcnt] == "" } {
	set wordlist [lreplace $wordlist $wordcnt $wordcnt 0]
    }
    for { set i 0 } { $i <= $wordcnt } { incr i } {
	set word [lindex $wordlist $i]
	if { $word == "" } {
	    if { $doublec == "true" } {
		return 0
	    }
	    set doublec true
	}
	if { [string length $word] > 4 } {
	    if { $i == $wordcnt } {
		return [checkIPv4Addr $word]
	    } else {
		return 0
	    }
	}
	if { [string is xdigit $word] == 0 } {
	    return 0
	}
    }
    return 1
}

#****f* ipv6.tcl/checkIPv6Net 
# NAME
#   checkIPv6Net -- check the IPv6 network 
# SYNOPSIS
#   set valid [checkIPv6Net $str]
# FUNCTION
#   Checks if the provided string is a valid IPv6 network. 
# INPUTS
#   * str -- string to be evaluated. Valid string is in form ipv6addr/m 
# RESULT
#   * valid -- function returns 0 if the input string is not in the form
#     of a valid IP address, 1 otherwise.
#****
proc checkIPv6Net { str } {
    if { $str == "" } {
	return 1
    }
    if { ![checkIPv6Addr [lindex [split $str /] 0]]} {
	return 0
    }
    set net [string trim [lindex [split $str /] 1]]
    if { [string length $net] == 0 } {
	return 0
    }
    return [checkIntRange $net 0 128]
}

#****f* ipv6.tcl/checkIPv6Nets
# NAME
#   checkIPv6Nets -- check the IPv6 networks
# SYNOPSIS
#   set valid [checkIPv6Nets $str]
# FUNCTION
#   Checks if the provided string is a valid IPv6 networks. 
# INPUTS
#   * str -- string to be evaluated. Valid IPv6 networks are writen in form
#     a.b.c.d; e.f.g.h 
# RESULT
#   * valid -- function returns 0 if the input string is not in the form
#     of a valid IP network, 1 otherwise
#****
proc checkIPv6Nets { str } {
    foreach net [split $str ";"] {
	set net [string trim $net]
	if { ![checkIPv6Net $net] } {
	    return 0
	}
    }
    return 1
}
