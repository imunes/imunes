#
# Copyright 2007-2013 University of Zagreb.
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

# $Id: ipsec.tcl 60 2013-10-03 09:05:13Z denis $

#****f* ipsec.tcl/getListOfOtherNodes
# NAME
#   getListOfOtherNodes -- retreives list of all nodes
# SYNOPSIS
#   getListOfOtherNodes $node_id
# FUNCTION
#   Retreives list of all nodes created in current topology
# INPUTS
#   my_node_id - node id
#****
proc getListOfOtherNodes { my_node_id } {
	set nodes_list [removeFromList [getFromRunning "node_list"] $my_node_id]

	set names_list ""
	foreach node_id $nodes_list {
		if { [getNodeType $node_id] == "pseudo" } {
			continue
		}

		lappend names_list "[getNodeName $node_id] - $node_id"
	}

	return $names_list
}

#****f* ipsec.tcl/getIPAddressForPeer
# NAME
#   getIPAddressForPeer -- retreives list of IP addresses for peer
# SYNOPSIS
#   getIPAddressForPeer $node_id
# FUNCTION
#   Refreshes list of IP addresses for peer's dropdown selection list
# INPUTS
#   node_id - node id
#****
proc getIPAddressForPeer { node_id curIP } {
	set ifaces_list [ifcList $node_id]
	foreach logifc [logIfcList $node_id] {
		if { [string match "vlan*" $logifc] } {
			lappend ifaces_list $logifc
		}
	}

	set ips_list ""
	if { $curIP == "" } {
		set IPversion 4
	} else {
		set IPversion [ ::ip::version $curIP ]
	}

	if { $IPversion == 4 } {
		foreach item $ifaces_list {
			set ifcIP [getIfcIPv4addrs $node_id $item]
			if { $ifcIP != "" } {
				lappend ips_list {*}$ifcIP
			}
		}
	} else {
		foreach item $ifaces_list {
			set ifcIP [getIfcIPv6addrs $node_id $item]
			if { $ifcIP != "" } {
				lappend ips_list {*}$ifcIP
			}
		}
	}

	return $ips_list
}

#****f* ipsec.tcl/getLocalSubnets
# NAME
#   getLocalSubnets -- creates and retreives local subnets
# SYNOPSIS
#   getLocalSubnets $ips_list
# FUNCTION
#   Creates and retreives local subnets from given list of IP addresses
# INPUTS
#   ips_list - list of IP addresses
#****
proc getSubnetsFromIPs { ips_list } {
	set total_string ""
	set total_list ""
	foreach item $ips_list {
		set total_string [ip::prefix $item]
		if { [::ip::version $item ] == 6 } {
			set total_string [ip::contract $total_string]
		}

		append total_string "/"
		append total_string [::ip::mask $item]
		lappend total_list $total_string
	}

	return [lsort -unique $total_list]
}

proc checkIfPeerStartsSameConnection { peer local_ip local_subnet local_id } {
	set connList [getNodeIPsecConnList $peer]

	foreach conn $connList {
		set auto [getNodeIPsecSetting $peer $conn "auto"]
		if { "$auto" == "start" } {
			set right [getNodeIPsecSetting $peer $conn "right"]
			if { "$right" == "$local_ip" } {
				set rightsubnet [getNodeIPsecSetting $peer $conn "rightsubnet"]
				if { "$rightsubnet" == "$local_subnet" } {
					set rightid [getNodeIPsecSetting $peer $conn "rightid"]
					if { $rightid == "" || $local_id == "" } {
						return 1
					} else {
						if { "$rightid" == "$local_id" } {
							return 1
						}
					}
				}
			}
		}
	}

	return 0
}
