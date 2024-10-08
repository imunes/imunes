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

#****h* imunes/ipv4.tcl
# NAME
#   ipv4.tcl -- file for handling IPv4
#****
global ipv4 numbits control changeAddrRange changeAddressRange

set ipv4 10.0.0.0/24
set numbits [lindex [split $ipv4 /] 1]
set control 0
set changeAddrRange 0
set changeAddressRange 0

#****f* ipv4.tcl/IPv4AddrApply
# NAME
#   IPv4AddrApply -- IPv4 address apply
# SYNOPSIS
#   IPv4AddrApply $w
# FUNCTION
#   Sets new IPv4 address from widget.
# INPUTS
#   * w -- widget
#****
proc IPv4AddrApply { w } {
   global ipv4
   global numbits
   global changed
   global control

   set newipv4 [$w.ipv4frame.e1 get]

   if { [checkIPv4Net $newipv4] == 0 } {
        focusAndFlash .entry1.ipv4frame.e1
	return
   }
   destroy $w

   if { $newipv4 != $ipv4 } {
	set changed 1
        set control 1
   }
   set ipv4 $newipv4
   set numbits [lindex [split $ipv4 /] 1]
}

#****f* ipv4.tcl/dec2bin
# NAME
#   dec2bin -- decimal to binary
# SYNOPSIS
#   dec2bin $dec
# FUNCTION
#   Converts the specified decimal number to a binary number.
# INPUTS
#   * dec -- decimal number
#****
proc dec2bin { dec } {
    set res ""
    while {$dec > 0} {
	set res [expr {$dec % 2}]$res
	set dec [expr {$dec / 2}]
    }
    if {$res == ""} {set res 0}
    if {[string length $res] < 8} {
	set n [expr {8-[string length $res]}]
	for {set i 0} {$i < $n} {incr i} {
	    set res 0$res
	}
    }
    return $res
}

#****f* ipv4.tcl/bin2dec
# NAME
#   bin2dec -- binary to decimal
# SYNOPSIS
#   bin2dec $bin
# FUNCTION
#   Converts the specified binary number to a decimal number.
# INPUTS
#   * bin -- binary number
#****
proc bin2dec { bin } {
    set res 0
    foreach i $bin {
	set res [expr {$res*2 + $i}]
    }
    return $res
}

#****f* ipv4.tcl/findFreeIPv4Net
# NAME
#   findFreeIPv4Net -- find free IPv4 network
# SYNOPSIS
#   set ipnet [findFreeIPv4Net $mask]
# FUNCTION
#   Finds a free IPv4 network. Network is concidered to be free
#   if there are no simulated nodes attached to it.
# INPUTS
#   * mask -- this parameter is left unused for now
# RESULT
#   * ipnet -- returns the free IPv4 network address in the form a.b.c.d
#****
proc findFreeIPv4Net { mask } {
    global ipv4
    global numbits

    set numbits $mask

    set addr [lindex [split $ipv4 /] 0]

    set a [dec2bin [lindex [split $addr .] 0]]
    set b [dec2bin [lindex [split $addr .] 1]]
    set c [dec2bin [lindex [split $addr .] 2]]
    set d [dec2bin [lindex [split $addr .] 3]]

    set addr_bin $a$b$c$d

    set host_id [string range $addr_bin $numbits end]

    while {[string first 1 $host_id] != -1} {
	set i [string first 1 $host_id]
	set host_id [string replace $host_id $i $i 0]
    }

    set net_id [string range $addr_bin 0 [expr {$numbits-1}]]

    set sub_addr $net_id$host_id

    if {$numbits == 8 || $numbits == 16 || $numbits == 24} {
        set pot 0
    } else {
        set pot [expr {8 - ($numbits % 8)}]
    }

    set step [expr {1 << $pot}]

    set ipnets {}

    foreach addr [getFromRunning "ipv4_used_list"] {
	if {$numbits <= 8}  {
	    set ipnet [lindex [split $addr .] 0]
	} elseif {$numbits > 8 && $numbits <=16} {
	    set ipnet [lrange [split $addr .] 0 1]
	} elseif {$numbits > 16 && $numbits <=24} {
	    set ipnet [lrange [split $addr .] 0 2]
	} elseif {$numbits > 24}  {
	    set ifcaddr [lindex [split $addr /] 0]
	    if {[lindex [split $ifcaddr .] 3] != ""} {
		set x [expr {[lindex [split $ifcaddr .] 3] - \
		    ([lindex [split $ifcaddr .] 3] % $step)}]
		set ipnet [split $ifcaddr .]
		lset ipnet 3 $x
	    } else {
		set ipnet {}
	    }
	}
	if {[lsearch $ipnets $ipnet] == -1} {
	    lappend ipnets $ipnet
	}
    }

    set a_sub [bin2dec [split [string range $sub_addr 0 7] {}]]
    set b_sub [bin2dec [split [string range $sub_addr 8 15] {}]]
    set c_sub [bin2dec [split [string range $sub_addr 16 23] {}]]
    set d_sub [bin2dec [split [string range $sub_addr 24 31] {}]]

    if {$numbits <= 8} {
	for { set i $a_sub } { $i <= 255 } { incr i $step } {
	    if {[lsearch $ipnets "$i"] == -1} {
		set ipnet "$i"
		return $ipnet
	    }
	}
    } elseif {$numbits > 8 && $numbits <=16} {
	for { set i $a_sub } { $i <= 255 } { incr i } {
	    for { set j $b_sub } { $j <= 255 } { incr j $step } {
		if {[lsearch $ipnets "$i $j"] == -1} {
		    set ipnet "$i.$j"
		    return $ipnet
		}
	    }
	}
    } elseif {$numbits > 16 && $numbits <=24} {
	for { set i $a_sub } { $i <= 255 } { incr i } {
	    for { set j $b_sub } { $j <= 255 } { incr j } {
		for { set k $c_sub } { $k <= 255 } { incr k $step } {
		    if {[lsearch $ipnets "$i $j $k"] == -1} {
			set ipnet "$i.$j.$k"
			return $ipnet
		    }
		}
	    }
	}
    } elseif {$numbits > 24} {
	for { set i $a_sub } { $i <= 255 } { incr i } {
	    for { set j $b_sub } { $j <= 255 } { incr j } {
		for { set k $c_sub } { $k <= 255 } { incr k } {
		    for { set l $d_sub } { $l <= 255 } { incr l $step } {
			if {[lsearch $ipnets "$i $j $k $l"] == -1} {
			    set ipnet "$i.$j.$k.$l"
			    return $ipnet
			}
		    }
		}
	    }
	}
    }
}

#****f* ipv4.tcl/autoIPv4addr
# NAME
#   autoIPv4addr -- automaticaly assign an IPv4 address
# SYNOPSIS
#   autoIPv4addr $node $iface
# FUNCTION
#   automaticaly assignes an IPv4 address to the interface $iface of
#   of the node $node
# INPUTS
#   * node -- the node containing the interface to witch a new
#     IPv4 address should be assigned
#   * iface -- the interface to witch a new, automatically generated, IPv4
#     address will be assigned
#****
proc autoIPv4addr { node iface } {
    global IPv4autoAssign

    if { ! $IPv4autoAssign } {
	return
    }

    global numbits changeAddrRange control changeAddressRange autorenumbered_ifcs
    #changeAddrRange - to change the subnet (1) or not (0)
    #changeAddressRange - is this procedure called from 'changeAddressRange' (1 if true, otherwise 0)
    #autorenumbered_ifcs - list of all interfaces that changed an address

    set node_type [getNodeType $node]
    if { [$node_type.layer] != "NETWORK" } {
	#
	# Shouldn't get called at all for link-layer nodes
	#
	return
    }

    setIfcIPv4addrs $node $iface ""

    lassign [logicalPeerByIfc $node $iface] peer_node peer_if
    set peer_ip4addrs {}
    if { [[getNodeType $peer_node].layer] == "LINK"} {
	foreach l2node [listLANNodes $peer_node {}] {
	    foreach ifc [ifcList $l2node] {
		lassign [logicalPeerByIfc $l2node $ifc] peer peer_if
		set peer_ip4addr [getIfcIPv4addr $peer $peer_if]
		if { $peer_ip4addr == "" } {
		    continue
		}

		if { $changeAddressRange == 1 } {
		    if { "$peer $peer_if" in $autorenumbered_ifcs } {
			lappend peer_ip4addrs $peer_ip4addr
		    }
		} else {
		    lappend peer_ip4addrs $peer_ip4addr
		}
	    }
	}
    } else {
	set peer_ip4addrs [getIfcIPv4addr $peer_node $peer_if]
    }

    set targetbyte [$node_type.IPAddrRange]

    set targetbyte2 0

    if { $peer_ip4addrs != "" && $changeAddrRange == 0 } {
	setIfcIPv4addrs $node $iface [nextFreeIP4Addr [lindex $peer_ip4addrs 0] $targetbyte $peer_ip4addrs]
    } else {
        if {$numbits <= 8} {
	    setIfcIPv4addrs $node $iface "[findFreeIPv4Net $numbits].$targetbyte2.$targetbyte2.$targetbyte/$numbits"
	} elseif {$numbits > 8 && $numbits <=16} {
	    setIfcIPv4addrs $node $iface "[findFreeIPv4Net $numbits].$targetbyte2.$targetbyte/$numbits"
	} elseif {$numbits > 16 && $numbits <=24} {
	    setIfcIPv4addrs $node $iface "[findFreeIPv4Net $numbits].$targetbyte/$numbits"
	} elseif {$numbits > 24} {
            set lastbyte [lindex [split [findFreeIPv4Net $numbits] .] 3]
            set first3bytes [join [lrange [split [findFreeIPv4Net $numbits] .] 0 2] .]
            set targetbyte3 [expr {$lastbyte + 1}]
	    setIfcIPv4addrs $node $iface "$first3bytes.$targetbyte3/$numbits"
        }
    }

    lappendToRunning ipv4_used_list [getIfcIPv4addr $node $iface]
}

#****f* ipv4.tcl/nextFreeIP4Addr
# NAME
#   nextFreeIP4Addr -- automaticaly assign an IPv4 address
# SYNOPSIS
#   nextFreeIP4Addr $addr $start $peers
# FUNCTION
#   Automaticaly searches for free IPv4 addresses within a given range
#   defined by $addr, containing $peers
# INPUTS
#   * $addr -- address of a node within the range
#   * $start -- starting host address for a specified node type, ignored
#     if the netmask is bigger than 24
#   * $peers -- list of peers in the current network
#****
proc nextFreeIP4Addr { addr start peers } {
    global execMode
    set ipnums [ip::prefix $addr]
    set mask [lindex [split $addr /] 1]

    set ipnums [split $ipnums .]

    set ip1 [lindex $ipnums 0]
    set ip2 [lindex $ipnums 1]
    set ip3 [lindex $ipnums 2]

    if { $mask > 24 } {
	set ip4 [expr [lindex $ipnums 3] + 1]
    } else {
	set ip4 [expr [lindex $ipnums 3] + $start]
    }

    set ipaddr "$ip1.$ip2.$ip3.$ip4/$mask"

    while {$ipaddr in $peers} {
        incr ip4
        if { $ip4 > 254} {
            incr ip3
            set ip4 1
            if { $ip3 > 254} {
                incr ip2
                set ip3 0
                if { $ip2 > 254} {
                    incr ip1
                    set ip2 0
                }
            }
        }
        set ipaddr "$ip1.$ip2.$ip3.$ip4/$mask"
    }

    set x [ip::prefix $addr]
    set y [ip::prefix $ipaddr]

    if { $x != $y  || "$ip1.$ip2.$ip3.$ip4" == [ip::broadcastAddress $ipaddr] } {
	if { $execMode != "batch" } {
	    after idle {.dialog1.msg configure -wraplength 4i}
	    tk_dialog .dialog1 "IMUNES warning" \
		"You have depleted the current pool of addresses ($x/$mask). Please choose a new pool from Tools->IPV4 address pool or delete nodes to free the address space." \
	    info 0 Dismiss
	}
	return ""
    }

    return $ipaddr
}

#****f* ipv4.tcl/checkIPv4Addr
# NAME
#   checkIPv4Addr -- check the IPv4 address
# SYNOPSIS
#   set valid [checkIPv4Addr $str]
# FUNCTION
#   Checks if the provided string is a valid IPv4 address.
# INPUTS
#   * str -- string to be evaluated. Valid IPv4 address is writen in form
#     a.b.c.d
# RESULT
#   * valid -- function returns 0 if the input string is not in the form
#     of a valid IP address, 1 otherwise
#****
proc checkIPv4Addr { str } {
    set n 0
    if { $str == "" } {
	return 1
    }
    while { $n < 4 } {
	if { $n < 3 } {
	    set i [string first . $str]
	} else {
	    set i [string length $str]
	}
	if { $i < 1 } {
	    return 0
	}
	set part [string range $str 0 [expr $i - 1]]
	if { [string length [string trim $part]] != $i } {
	    return 0
	}
	if { ![string is integer $part] } {
	    return 0
	}
	if { $part < 0 || $part > 255 } {
	    return 0
	}
	set str [string range $str [expr $i + 1] end]
	incr n
    }
    return 1
}

#****f* ipv4.tcl/checkIPv4Net
# NAME
#   checkIPv4Net -- check the IPv4 network
# SYNOPSIS
#   set valid [checkIPv4Net $str]
# FUNCTION
#   Checks if the provided string is a valid IPv4 network.
# INPUTS
#   * str -- string to be evaluated. Valid string is in form a.b.c.d/m
# RESULT
#   * valid -- function returns 0 if the input string is not in the form
#     of a valid IP address, 1 otherwise
#****
proc checkIPv4Net { str } {
    if { $str == "" } {
	return 1
    }
    if { ![checkIPv4Addr [lindex [split $str /] 0]]} {
	return 0
    }
    set net [string trim [lindex [split $str /] 1]]
    if { [string length $net] == 0 } {
	return 0
    }
    return [checkIntRange $net 0 32]
}

#****f* ipv4.tcl/checkIPv4Nets
# NAME
#   checkIPv4Nets -- check the IPv4 networks
# SYNOPSIS
#   set valid [checkIPv4Nets $str]
# FUNCTION
#   Checks if the provided string is a valid IPv4 networks.
# INPUTS
#   * str -- string to be evaluated. Valid IPv4 networks are writen in form
#     a.b.c.d; e.f.g.h
# RESULT
#   * valid -- function returns 0 if the input string is not in the form
#     of a valid IP network, 1 otherwise
#****
proc checkIPv4Nets { str } {
    foreach net [split $str ";"] {
	set net [string trim $net]
	if { ![checkIPv4Net $net] } {
	    return 0
	}
    }
    return 1
}
