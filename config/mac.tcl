# 2019-2020 Sorbonne University
# In this version of imunes we added a full integration of emulation of 
# Linux namespaces and CISCO routers, saving of parameters, VLANs, WiFi 
# emulation and other features
# This work was developed by Benadji Hanane and Oulad Said Chawki
# Supervised and maintained by Naceur Malouch - LIP6/SU
#
# Copyright 2010-2013 University of Zagreb.
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
#

global mac_byte4 mac_byte5 mac_byte6

set mac_byte4 0
set mac_byte5 0
set mac_byte6 0

#****f* mac.tcl/randomizeMACbytes
# NAME
#   randomizeMACbytes -- randomize MAC bytes
# SYNOPSIS
#   randomizeMACbytes
# FUNCTION
#   Randomizes MAC bytes.
#****
proc randomizeMACbytes {} {
    global mac_byte4 mac_byte5
    
    set mac_byte4 [expr { (round(rand()*10000))%255 }]
    set mac_byte5 [expr { (round(rand()*10000))%255 }]

    return
}

#****f* mac.tcl/autoMACaddr
# NAME
#   autoMACaddr -- automaticaly assign an MAC address
# SYNOPSIS
#   autoMACaddr $node $ifc 
# FUNCTION
#   Automaticaly assignes an MAC address to the interface $ifc of 
#   of the node $node.  
# INPUTS
#   * node -- the node containing the interface to witch a new 
#     MAC address should be assigned
#   * iface -- the interface to witch a new, automatilacy generated, MAC  
#     address will be assigned
#****
#Modification for namespace and router CISCO
proc autoMACaddr { node ifc } {
    upvar 0 ::cf::[set ::curcfg]::MACUsedList MACUsedList
    global mac_byte4 mac_byte5 mac_byte6

    if { [nodeType $node] != "ext" && [[typemodel $node].virtlayer] != "VIMAGE" && [[typemodel $node].virtlayer] != "NAMESPACE" && [[typemodel $node].virtlayer] != "WIFIAP" && [[typemodel $node].virtlayer] != "WIFISTA"} {
	return
    }

    set mac_byte6 0
    set macaddr [MACaddrAddZeros 42:00:aa:[format %x $mac_byte4]:[format %x $mac_byte5]:[format %x $mac_byte6]]
    while { $macaddr in $MACUsedList } {
	incr mac_byte6
	if { $mac_byte6 > 255 } {
            if { $mac_byte5 > 255 } {
                set mac_byte6 0
	        set mac_byte5 0
	        incr mac_byte4
		if { $mac_byte4 > 255 } {
		    set macaddr "00:00:00:00:00:00"
		}
	    } else {
	        set mac_byte6 0
	        incr mac_byte5
            }
	}
	set macaddr [MACaddrAddZeros 42:00:aa:[format %x $mac_byte4]:[format %x $mac_byte5]:[format %x $mac_byte6]]
    }

    lappend MACUsedList $macaddr
    setIfcMACaddr $node $ifc $macaddr
}

#****f* mac.tcl/MACaddrAddZeros
# NAME
#   MACaddrAddZeros -- automaticaly assign an MAC address
# SYNOPSIS
#   set addr [MACaddrAddZeros $node $ifc] 
# FUNCTION
#   Adds zeros to automatically assigned MAC address, 
#   e.g 42:00:aa:aa:0:0 --> 42:00:aa:aa:00:00
# INPUTS
#   * str -- string
# RESULT
#   * addr -- function returns MAC address
#****
proc MACaddrAddZeros { str } {
    set n 0
    set newstr ""
    while { $n < 6 } {
	if { $n < 5 } {
	    set i [string first : $str]
	} else {
	    set i [string length $str]
	}
	set part [string range $str 0 [expr $i - 1]]
	if { [string length [string trim $part]] != 2 } {
	    set part "0$part"
	}
	set str [string range $str [expr $i + 1] end]
        if { $n < 5 } {
            set newstr "$newstr$part:"
        } else {
            set newstr "$newstr$part"
        }
	incr n
    } 

    return $newstr
}

#****f* mac.tcl/checkMACAddr
# NAME
#   checkMACAddr -- check the MAC address 
# SYNOPSIS
#   set valid [checkMACAddr $str]
# FUNCTION
#   Checks if the provided string is a valid MAC address. 
# INPUTS
#   * str -- string to be evaluated. Valid MAC address is writen in form
#     a:b:c:d:e:f, where each part (a,b,c,...) consists of two hexadecimal
#     digits.
# RESULT
#   * valid -- function returns 0 if the input string is not in the form
#     of a valid MAC address, 1 otherwise
#****
proc checkMACAddr { str } {
    set n 0
    if { $str == "" } {
	return 1
    }
    while { $n < 6 } {
	if { $n < 5 } {
	    set i [string first : $str]
	} else {
	    set i [string length $str]
	}
	if { $i < 1 } {
	    return 0
	}
	set part [string range $str 0 [expr $i - 1]]
	if { [string length [string trim $part]] != 1 && [string length [string trim $part]] != 2} {         
	    return 0
	}
	if { ![string is xdigit $part] } {
	    return 0
	}
	set str [string range $str [expr $i + 1] end]
	incr n
    } 

    return 1
}
