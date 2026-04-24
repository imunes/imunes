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
#   ipv6.tcl -- file for handling IPv6
#****
global ipv6 numbits6

set ipv6 fc00::/64
set numbits6 32

proc ip6_strToInt { subnet } {
	set subnet [ip::normalize $subnet]
    set subnet_prefix [lindex [split $subnet "/"] 0]

    set ipv6_int 0
    foreach part [split $subnet_prefix ":"] {
        scan $part %x value
        set ipv6_int [expr { ($ipv6_int << 16) + $value }]
    }

    return $ipv6_int
}

proc ip6_intToStr { ipv6_int } {
    set parts {}
    for { set i 0 } { $i < 8 } { incr i } {
        set part [expr { ($ipv6_int >> (16 * (7 - $i))) & 0xffff }]
        lappend parts [format %x $part]
    }

	return [ip::normalize [join $parts ":"]]
}

proc ip6_strToBin { subnet } {
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

proc ip6_binToStr { ipv6_bin { mask "" } } {
	set len [string length $ipv6_bin]
    if { $len > 128 } {
		set ipv6_bin [string range $ipv6_bin 0 127]
    } elseif { $len < 128 } {
		set diff [expr { 128 - $len }]
		set ipv6_bin "$ipv6_bin[string repeat "0" $diff]"
	}

    set hextets {}

    # split into 16-bit chunks and convert to hex
    for {set i 0} {$i < 128} {incr i 16} {
        set hex_chunk [string range $ipv6_bin $i [expr { $i + 15 }]]
        scan $hex_chunk %b val
        lappend hextets [format "%x" $val]
    }

    set ipv6 [join $hextets ":"]

    if { $mask != "" } {
        append ipv6 "/$mask"
    }

    return $ipv6
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

	set subnet_bin [ip6_strToBin $subnet]
	set address_bin [ip6_strToBin $address]

	if { $subnet_mask > $address_mask } {
		set bigger_mask $subnet_mask
	} else {
		set bigger_mask $address_mask
	}

	if { [string range $subnet_bin 0 [expr { $bigger_mask - 1 }]] == [string range $address_bin 0 [expr { $bigger_mask - 1 }]] } {
		return true
	}

	return false
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
	global numbits6
	global changed

	set newipv6 [$w.ipv6frame.e1 get]
	set newbits [$w.ipv6frame.steps.stepv get]

	if { [checkIPv6Net $newipv6] == 0 } {
		focusAndFlash .entry1.ipv6frame.e1
		return
	}

	if { [checkIntRange $newbits 1 128] == 0 } {
		focusAndFlash .entry1.ipv6frame.steps.stepv
		return
	}
	destroy $w

	if { $newipv6 != $ipv6 } {
		set changed 1
	}
	set ipv6 $newipv6

	set mask [::ip::mask $ipv6]
	if { $newbits > $mask } {
		global gui execMode
		set newbits $mask

		if { $gui && $execMode != "batch" } {
			after idle { .dialog1.msg configure -wraplength 4i }
			tk_dialog .dialog1 "IMUNES warning" \
				"Step size cannot be larger then mask size, setting to '$mask'." \
				info 0 Dismiss
		}
	}

	if { $newbits != $numbits6 } {
		set changed 1
	}
	set numbits6 $newbits
}

proc ip6_nextNet { subnet step_size } {
	set mask [::ip::mask $subnet]
	if { $mask == "" } {
		set mask $step_size
	}

    set addr_bin [ip6_strToBin $subnet]

	# subnet hextet index
	set step_idx [expr $step_size*8/(128+1)]

	set overflow 0
    set hextets {}

    # split into 16-bit chunks and convert to hex
    for {set i 112} {$i >= 0} {incr i -16} {
		set cur_idx [expr (1 + $i)*8/(128+1)]
        set hex_chunk [string range $addr_bin $i [expr { $i + 15 }]]
		scan $hex_chunk %b val
		incr val $overflow
		if { $step_idx == $cur_idx } {
			set incrby [expr { 1 << ((16 - ($step_size % 16)) % 16) }]
			set val [expr $val + $incrby]
		}

		# overflow, overflow to upper hextets
		if { $val >= [expr { 1 << 16 }] } {
			set val 0
			set overflow 1
		} else {
			set overflow 0
		}

        lappend hextets [format "%x" $val]
    }

    set ipv6 [::ip::contract [join [lreverse $hextets] ":"]]
	append ipv6 "/$mask"

	return $ipv6
}

#****f* ipv6.tcl/findFreeIPv6Subnet
# NAME
#   findFreeIPv6Subnet -- find free IPv6 network
# SYNOPSIS
#   set ipnet [findFreeIPv6Subnet $mask]
# FUNCTION
#   Finds a free IPv6 network. Network is concidered to be free
#   if there are no simulated nodes attached to it.
# INPUTS
#   * mask -- this parameter is left unused for now
# RESULT
#   * ipnet -- returns the free IPv6 network address in the form "a $i".
#****
proc findFreeIPv6Subnet { mask { ipv6_used_list "" } } {
    global ipv6
    global numbits6

	if { $mask == "" } {
		set mask [::ip::mask $ipv6]
	}

	if { $mask < $numbits6 } {
		set numbits6 $mask
	}

	# get zeroed-out address and mask
	set addr [::ip::prefix $ipv6]
	set ipnet "[::ip::contract $addr]/$mask"

	if { $ipv6_used_list == {} } {
		return $ipnet
	}

	set used_ipnets {}
	foreach used_addr $ipv6_used_list {
		set used_prefix [::ip::contract [::ip::prefix $used_addr]]
		set used_mask [::ip::mask $used_addr]
		set used_ipnet "$used_prefix/$used_mask"

		if { $used_ipnet ni $used_ipnets } {
			lappend used_ipnets $used_ipnet
		}
	}

	while { $ipnet in "\"\" $used_ipnets" } {
		set ipnet [ip6_nextNet $ipnet $numbits6]
		set prefix [::ip::contract [::ip::prefix $ipnet]]
		set ipnet "$prefix/$mask"
	}

	return $ipnet
}
