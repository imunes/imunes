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
    global ipv6

    set ipv6_used_list [getFromRunning "ipv6_used_list"]
    if { $ipv6_used_list == {} } {
	set defip6net [ip::contract [ip::prefix $ipv6]]
	set testnet [ip::contract "[string trimright $defip6net :]::"]

	return $testnet
    } else {
	set defip6net [ip::contract [ip::prefix $ipv6]]
	set subnets [lsort -unique [lmap ip $ipv6_used_list {ip::contract [ip::prefix $ip]}]]
	for { set i 0 } { $i <= 65535 } { incr i } {
	    set testnet [ip::contract "[string trimright $defip6net :]:[format %x $i]::"]
	    if { $testnet ni $subnets } {
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
#   * iface -- the interface to witch a new, automatically generated, IPv6
#     address will be assigned
#****
proc autoIPv6addr { node iface } {
    global IPv6autoAssign

    if { ! $IPv6autoAssign } {
	return
    }

    global changeAddrRange6 control changeAddressRange6 autorenumbered_ifcs6
    #changeAddrRange6 - to change the subnet (1) or not (0)
    #changeAddressRange6 - is this procedure called from 'changeAddressRange' (1 if true, otherwise 0)
    #autorenumbered_ifcs6 - list of all interfaces that changed an address

    set node_type [getNodeType $node]
    if { [$node_type.netlayer] != "NETWORK" } {
	#
	# Shouldn't get called at all for link-layer nodes
	#
	return
    }

    setIfcIPv6addrs $node $iface ""

    lassign [logicalPeerByIfc $node $iface] peer_node peer_if
    set peer_ip6addrs {}
    if { $peer_node != "" } {
	if { [[getNodeType $peer_node].netlayer] == "LINK" } {
	    foreach l2node [listLANNodes $peer_node {}] {
		foreach ifc [ifcList $l2node] {
		    lassign [logicalPeerByIfc $l2node $ifc] peer peer_if
		    set peer_ip6addr [getIfcIPv6addr $peer $peer_if]
		    if { $peer_ip6addr == "" } {
			continue
		    }

		    if { $changeAddressRange6 == 1 } {
			if { "$peer $peer_if" in $autorenumbered_ifcs6 } {
			    lappend peer_ip6addrs $peer_ip6addr
			}
		    } else {
			lappend peer_ip6addrs $peer_ip6addr
		    }
		}
	    }
	} else {
	    set peer_ip6addrs [getIfcIPv6addr $peer_node $peer_if]
	}
    }

    # TODO: reduce with _getNextIPv6addr proc
    set targetbyte [expr 0x[$node_type.IPAddrRange]]

    if { $peer_ip6addrs != "" && $changeAddrRange6 == 0 } {
	setIfcIPv6addrs $node $iface [nextFreeIP6Addr [lindex $peer_ip6addrs 0] $targetbyte $peer_ip6addrs]
    } else {
	setIfcIPv6addrs $node $iface "[findFreeIPv6Net 64][format %x $targetbyte]/64"
    }

    lappendToRunning "ipv6_used_list" [getIfcIPv6addr $node $iface]
}

proc _getNextIPv6addr { node_type } {
    global IPv6autoAssign

    if { ! $IPv6autoAssign } {
	return
    }

    set targetbyte [expr 0x[$node_type.IPAddrRange]]

    return "[findFreeIPv6Net 64][format %x $targetbyte]/64"
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
