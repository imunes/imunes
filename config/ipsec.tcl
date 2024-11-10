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

#****f* ipsec.tcl/getNodeIPsec
# NAME
#   getNodeIPsec -- retreives IPsec configuration for selected node
# SYNOPSIS
#   getNodeIPsec $node_id
# FUNCTION
#   Retreives all IPsec connections for current node
# INPUTS
#   node_id - node id
#****
proc getNodeIPsec { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    return [lindex [lsearch -inline [set $node_id] "ipsec-config *"] 1]
}

proc setNodeIPsec { node_id new_value } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set ipsecCfgIndex [lsearch -index 0 [set $node_id] "ipsec-config"]

    if { $ipsecCfgIndex != -1 } {
	set $node_id [lreplace [set $node_id] $ipsecCfgIndex $ipsecCfgIndex "ipsec-config {$new_value}"]
    } else {
	set $node_id [linsert [set $node_id] end "ipsec-config {$new_value}"]
    }
}

proc delNodIPsec { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set ipsecCfgIndex [lsearch -index 0 [set $node_id] "ipsec-config"]

    if { $ipsecCfgIndex != -1 } {
	set $node_id [lreplace [set $node_id] $ipsecCfgIndex $ipsecCfgIndex]
    }
}

#****f* ipsec.tcl/getNodeIPsecItem
# NAME
#   getNodeIPsecItem -- get node IPsec item
# SYNOPSIS
#   getNodeIPsecItem $node_id $item
# FUNCTION
#   Retreives an item from IPsec configuration of given node
# INPUTS
#   node_id - node id
#   item - search item
proc getNodeIPsecItem { node_id item } {
    set cfg [getNodeIPsec $node_id]
    if { [lsearch $cfg "$item *"] != -1 } {
	return [lindex [lsearch -inline $cfg "$item *"] 1]
    }
    return ""
}

#****f* ipsec.tcl/setNodeIPsecItem
# NAME
#   setNodeIPsecItem -- set node IPsec item
# SYNOPSIS
#   setNodeIPsecItem $node_id $item
# FUNCTION
#   Sets an item from IPsec configuration of given node
# INPUTS
#   node_id - node id
#   item - search item
proc setNodeIPsecItem { node_id item new_value } {
    set ipsecCfg [getNodeIPsec $node_id]

    set itemIndex [lsearch -index 0 $ipsecCfg $item]
    if { $itemIndex != -1 } {
	set newIpsecCfg [lreplace $ipsecCfg $itemIndex $itemIndex "$item {$new_value}"]
    } else {
	set newIpsecCfg [linsert $ipsecCfg end "$item {$new_value}"]
    }

    setNodeIPsec $node_id $newIpsecCfg
}

proc delNodeIPsecItem { node_id item } {
    set ipsecCfg [getNodeIPsec $node_id]

    set itemIndex [lsearch -index 0 $ipsecCfg $item]
    if { $itemIndex != -1 } {
	set newIpsecCfg [lreplace $ipsecCfg $itemIndex $itemIndex]
    }

    setNodeIPsec $node_id $newIpsecCfg
}

#****f* ipsec.tcl/getNodeIPsecElement
# NAME
#   getNodeIPsecElement -- get node IPsec element item
# SYNOPSIS
#   getNodeIPsecElement $node_id $item
# FUNCTION
#   Retreives an element from IPsec configuration of given node from the
#   given item.
# INPUTS
#   node_id - node id
#   item - search item
#   element  - search element
proc getNodeIPsecElement { node_id item element } {
    set itemCfg [getNodeIPsecItem $node_id $item]

    if { [lsearch $itemCfg "{$element} *"] != -1 } {
	return [lindex [lsearch -inline $itemCfg "{$element} *"] 1]
    }
    return ""
}

proc setNodeIPsecElement { node_id item element new_value } {
    set itemCfg [getNodeIPsecItem $node_id $item]

    set elementIndex [lsearch -index 0 $itemCfg $element]
    if { $elementIndex != -1 } {
	set newItemCfg [lreplace $itemCfg $elementIndex $elementIndex "{$element} {$new_value}"]
    } else {
	set newItemCfg [linsert $itemCfg end "{$element} {$new_value}"]
    }

    setNodeIPsecItem $node_id $item $newItemCfg
}

proc delNodeIPsecElement { node_id item element } {
    set itemCfg [getNodeIPsecItem $node_id $item]

    set elementIndex [lsearch -index 0 $itemCfg $element]
    if { $elementIndex != -1 } {
	set newItemCfg [lreplace $itemCfg $elementIndex $elementIndex]
    } else {
	return
    }

    setNodeIPsecItem $node_id $item $newItemCfg

    if { [getNodeIPsecConnList $node_id] == "" } {
	delNodIPsec $node_id
    }
}

proc getNodeIPsecSetting { node_id item element setting } {
    set elementCfg [getNodeIPsecElement $node_id $item $element]

    if { [lsearch $elementCfg "$setting=*"] != -1 } {
	return [lindex [split [lsearch -inline $elementCfg "$setting=*"] =] 1]
    }
    return ""
}

proc setNodeIPsecSetting { node_id item element setting new_value } {
    set elementCfg [getNodeIPsecElement $node_id $item $element]

    set settingIndex [lsearch $elementCfg "$setting=*"]
    if { $new_value == "" } {
	if { $settingIndex != -1 } {
	    set newElementCfg [lreplace $elementCfg $settingIndex $settingIndex]
	} else {
	    return
	}
    } else {
	if { $settingIndex != -1 } {
	    set newElementCfg [lreplace $elementCfg $settingIndex $settingIndex "$setting=$new_value"]
	} else {
	    set newElementCfg [linsert $elementCfg end "$setting=$new_value"]
	}
    }

    setNodeIPsecElement $node_id $item $element $newElementCfg
}

proc createEmptyIPsecCfg { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    setNodeIPsec $node_id ""
    setNodeIPsecItem $node_id "configuration" ""
    setNodeIPsecElement $node_id "configuration" "config setup" ""
}

proc getNodeIPsecConnList { node_id } {
    set cfg [getNodeIPsecItem $node_id "configuration"]
    set indices [lsearch -index 0 -all $cfg "conn *"]

    set connList ""
    if { $indices != -1 } {
	foreach ind $indices {
	    lappend connList [lindex [lindex [lindex $cfg $ind] 0] 1]
	}
    }

    return $connList
}

#****f* ipsec.tcl/nodeIPsecConnExists
# NAME
#   nodeIPsecConnExists -- checks if connection already exists
# SYNOPSIS
#   nodeIPsecConnExists $node_id $connection_name
# FUNCTION
#   Checks if given connection already exists in IPsec configuration of given node
# INPUTS
#   node_id - node id
#   connection_name - name of IPsec connection
#****
proc nodeIPsecConnExists { node_id connection_name } {
    if { $connection_name in [getNodeIPsecConnList $node_id] } {
        return 1
    }

    return 0
}

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
    upvar 0 ::cf::[set ::curcfg]::node_list node_list

    set nodes_list [removeFromList $node_list $my_node_id]

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

proc getNodeFromHostname { hostname } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list

    foreach node_id $node_list {
	if { $hostname == [getNodeName $node_id] } {
	    return $node_id
	}
    }

    return ""
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
	set auto [getNodeIPsecSetting $peer "configuration" "conn $conn" "auto"]
	if { "$auto" == "start" } {
	    set right [getNodeIPsecSetting $peer "configuration" "conn $conn" "right"]
	    if { "$right" == "$local_ip" } {
		set rightsubnet [getNodeIPsecSetting $peer "configuration" "conn $conn" "rightsubnet"]
		if { "$rightsubnet" == "$local_subnet" } {
		    set rightid [getNodeIPsecSetting $peer "configuration" "conn $conn" "rightid"]
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
