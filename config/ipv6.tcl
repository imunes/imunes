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
global ipv6 change_subnet6

set ipv6 fc00::/64
set change_subnet6 0

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

	set newipv6 [$w.ipv6frame.e1 get]

	if { [checkIPv6Net $newipv6] == 0 } {
		focusAndFlash .entry1.ipv6frame.e1
		return
	}
	destroy $w

	if { $newipv6 != $ipv6 } {
		set changed 1
	}
	set ipv6 $newipv6
}

proc ip6_toInteger { subnet } {
	set subnet [ip::normalize $subnet]
    set subnet_prefix [lindex [split $subnet "/"] 0]

    set ipv6_int 0
    foreach part [split $subnet_prefix ":"] {
        scan $part %x value
        set ipv6_int [expr { ($ipv6_int << 16) + $value }]
    }

    return $ipv6_int
}

proc ip6_intToString { ipv6_int } {
    set parts {}
    for { set i 0 } { $i < 8 } { incr i } {
        set part [expr { ($ipv6_int >> (16 * (7 - $i))) & 0xffff }]
        lappend parts [format %x $part]
    }

	return [ip::normalize [join $parts ":"]]
}

proc nextFreeIPv6InSubnet { subnet used_addrs { min_ip 0 } } {
	set mask [ip::mask $subnet]
	set subnet [ip::prefix $subnet]

	set addr_int [expr [ip6_toInteger $subnet] + 0x$min_ip]
	set addr "[ip::contract [ip6_intToString $addr_int]]/$mask"

	if { ! [ip6_isOverlap $subnet $addr] } {
		# out of prefix range, start from first
		set addr_int [expr $addr_int - 0x$min_ip]
		set addr "[ip::contract [ip6_intToString $addr_int]]/$mask"
	}

	while { $addr in $used_addrs } {
		incr addr_int
		set addr "[ip::contract [ip6_intToString $addr_int]]/$mask"

		if { ! [ip6_isOverlap $subnet $addr] } {
			# out of prefix range
			return ""
		}
	}

	return $addr
}

proc ip6_getBinary { subnet } {
	set subnet_mask [lindex [split $subnet "/"] 1]
	if { $subnet_mask == "" } {
		set subnet_mask 64
	}

	set full_subnet [ip::normalize $subnet]
	set subnet_prefix [lindex [split $full_subnet "/"] 0]

	set sub_bin_tmp ""
	foreach sub_segment [split $subnet_prefix ":"] {
		append sub_bin_tmp [format %016b 0x$sub_segment]
	}

	return $sub_bin_tmp
}

proc ip6_isOverlap { subnet address } {
	set subnet_mask [lindex [split $subnet "/"] 1]
	if { $subnet_mask == "" } {
		set subnet_mask 64
	}

	set address_mask [lindex [split $address "/"] 1]
	if { $address_mask == "" } {
		set address_mask 128
	}

	set subnet_bin [ip6_getBinary $subnet]
	set address_bin [ip6_getBinary $address]

	if { $subnet_mask > $address_mask } {
		set bigger_mask $subnet_mask
	} else {
		set bigger_mask $address_mask
	}

	if { [string range $subnet_bin 0 $bigger_mask] == [string range $address_bin 0 $bigger_mask] } {
		return true
	}

	return false
}

proc assignIPv6Subnet { node_id iface_id selected { subnet "" } } {
	if { $subnet == "" } {
		lassign [getSubnetNextIpAndGateways "ipv6" $node_id $iface_id] subnet -
	}

	set nodes_ifaces [getSubnetIfaces $node_id $iface_id]

	# first, get all non-selected used addresses from this subnet
	set used_addrs {}
	foreach node_subnet_data $nodes_ifaces {
		lassign $node_subnet_data priority subnet_node_id subnet_iface_id
		set cur_addrs [getIfcIPv6addrs $subnet_node_id $subnet_iface_id]

		if { $priority >= 0 && $subnet_node_id in $selected } {
			# skip if we're the main gateway
			foreach cur_addr $cur_addrs {
				if { [ip6_isOverlap $subnet $cur_addr] } {
					lappend used_addrs {*}$cur_addrs
					set nodes_ifaces [removeFromList $nodes_ifaces [list $node_subnet_data]]

					break
				}
			}

			continue
		}

		if { $priority >= 0 } {
			lappend used_addrs {*}$cur_addrs
		}

		set nodes_ifaces [removeFromList $nodes_ifaces [list $node_subnet_data]]
	}

	# change selected nodes interfaces to new subnet
	foreach node_subnet_data $nodes_ifaces {
		lassign $node_subnet_data - subnet_node_id subnet_iface_id

		# skip if we're the main gateway and subnet matches
		set cur_addrs [getIfcIPv6addrs $subnet_node_id $subnet_iface_id]
		foreach cur_addr $cur_addrs {
			if { [ip6_isOverlap $subnet $cur_addr] } {
				lappend used_addrs {*}$cur_addrs
				set nodes_ifaces [removeFromList $nodes_ifaces [list $node_subnet_data]]

				continue
			}
		}

		set addr [nextFreeIPv6InSubnet $subnet $used_addrs [invokeNodeProc $subnet_node_id "IPAddrRange"]]
		if { $addr == "" } {
			continue
		}

		lappend used_addrs $addr

		setToRunning "ipv6_used_list" \
			[removeFromList [getFromRunning "ipv6_used_list"] $cur_addrs "keep_doubles"]
		setIfcIPv6addrs $subnet_node_id $subnet_iface_id $addr
		lappendToRunning "ipv6_used_list" $addr
	}
}

#****f* ipv6.tcl/findFreeIPv6Net
# NAME
#   findFreeIPv6Net -- find free IPv6 network
# SYNOPSIS
#   set ipnet [findFreeIPv6Net $mask]
# FUNCTION
#   Finds a free IPv6 network. Network is concidered to be free
#   if there are no simulated nodes attached to it.
# INPUTS
#   * mask -- this parameter is left unused for now
# RESULT
#   * ipnet -- returns the free IPv6 network address in the form "a $i".
#****
proc findFreeIPv6Net { mask { ipv6_used_list "" } } {
	global ipv6

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
#   autoIPv6addr $node_id $iface_id
# FUNCTION
#   automaticaly assignes an IPv6 address to the interface $iface_id of
#   of the node $node_id.
# INPUTS
#   * node_id -- the node containing the interface to witch a new
#     IPv6 address should be assigned
#   * iface_id -- the interface to witch a new, automatically generated, IPv6
#     address will be assigned
#****
proc autoIPv6addr { node_id iface_id { nodes "*" } } {
	if { ! [getActiveOption "IPv6autoAssign"] } {
		return
	}

	lassign [getSubnetNextIpAndGateways "ipv6" $node_id $iface_id $nodes] addr -
	setIfcIPv6addrs $node_id $iface_id $addr
	lappendToRunning "ipv6_used_list" $addr
}

proc getNextIPv6addr { node_type existing_addrs } {
	if { ! [getActiveOption "IPv6autoAssign"] } {
		return
	}

	set targetbyte 0
	if { $node_type != "" } {
		set targetbyte [invokeTypeProc $node_type "IPAddrRange"]
		if { $targetbyte == "" } {
			return
		}
	}
	set targetbyte [expr 0x$targetbyte]

	# TODO: enable changing IPv6 pool mask
	return "[findFreeIPv6Net 64 $existing_addrs][format %x $targetbyte]/64"
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
	global execMode gui

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
		if { $gui && $execMode != "batch" } {
			after idle { .dialog1.msg configure -wraplength 4i }
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
	try {
		ip::prefix $str
	} on error {} {
		return 0
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
	if { ![checkIPv6Addr [lindex [split $str /] 0]] } {
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
