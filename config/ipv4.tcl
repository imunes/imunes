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
global ipv4 numbits

set ipv4 10.0.0.0/24
set numbits 24

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

	while { $dec > 0 } {
		set res [expr {$dec % 2}]$res
		set dec [expr {$dec / 2}]
	}

	if { $res == "" } {
		set res 0
	}

	if { [string length $res] < 8 } {
		set n [expr {8-[string length $res]}]
		for { set i 0 } { $i < $n } { incr i } {
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
	if { ! [checkIPv4Addr [lindex [split $str /] 0]] } {
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

#****f* ipv4.tcl/checkIPv4NetsDHCP
# NAME
#   checkIPv4NetsDHCP -- check the IPv4 networks (including 'dhcp')
# SYNOPSIS
#   set valid [checkIPv4NetsDHCP $str]
# FUNCTION
#   Checks if the provided string is a valid IPv4 networks or 'dhcp'.
# INPUTS
#   * str -- string to be evaluated. Valid IPv4 networks are writen in form
#     a.b.c.d; e.f.g.h or a single string: dhcp
# RESULT
#   * valid -- function returns 0 if the input string is not in the form
#     of a valid IP network or 'dhcp', 1 otherwise
#****
proc checkIPv4NetsDHCP { str } {
	if { $str == "dhcp" } {
		return 1
	}

	return [checkIPv4Nets $str]
}

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

	set newipv4 [$w.ipv4frame.e1 get]

	if { [checkIPv4Net $newipv4] == 0 } {
		focusAndFlash .entry1.ipv4frame.e1
		return
	}
	destroy $w

	if { $newipv4 != $ipv4 } {
		set changed 1
	}
	set ipv4 $newipv4
	set numbits [lindex [split $ipv4 /] 1]
}

#****f* ipv4.tcl/findFreeIPv4Subnet
# NAME
#   findFreeIPv4Subnet -- find free IPv4 network
# SYNOPSIS
#   set ipnet [findFreeIPv4Subnet $mask]
# FUNCTION
#   Finds a free IPv4 network. Network is concidered to be free
#   if there are no simulated nodes attached to it.
# INPUTS
#   * mask -- this parameter is left unused for now
# RESULT
#   * ipnet -- returns the free IPv4 network address in the form a.b.c.d
#****
proc findFreeIPv4Subnet { mask { ipv4_used_list {} } } {
	global ipv4
	global numbits

	if { $mask == "" } {
		set mask $numbits
	}

	# get zeroed-out address and mask, both as hex
	set addr [::ip::prefix $ipv4]
	lassign [::ip::prefixToNative "$addr/$mask"] addr mask
	set ipnet [::ip::nativeToPrefix [list $addr $mask]]

	if { $ipv4_used_list == {} } {
		return $ipnet
	}

	set used_ipnets {}
	foreach used_addr $ipv4_used_list {
		set used_prefix [::ip::prefix $used_addr]
		set used_mask [::ip::mask $used_addr]
		set used_ipnet "$used_prefix/$used_mask"

		if { $used_ipnet ni $used_ipnets } {
			lappend used_ipnets $used_ipnet
		}
	}

	while { $ipnet in "\"\" $used_ipnets" } {
		set ipnet [::ip::nativeToPrefix [list [::ip::nextNet $addr $mask] $mask]]
		set addr $ipnet
	}

	return $ipnet
}
