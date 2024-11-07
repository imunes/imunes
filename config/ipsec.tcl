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
#   getNodeIPsec $node
# FUNCTION
#   Retreives all IPsec connections for current node
# INPUTS
#   node - node id
#****
proc getNodeIPsec { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    return [lindex [lsearch -inline [set $node] "ipsec-config *"] 1]
}

proc setNodeIPsec { node newValue } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set ipsecCfgIndex [lsearch -index 0 [set $node] "ipsec-config"]

    if { $ipsecCfgIndex != -1 } {
	set $node [lreplace [set $node] $ipsecCfgIndex $ipsecCfgIndex "ipsec-config {$newValue}"]
    } else {
	set $node [linsert [set $node] end "ipsec-config {$newValue}"]
    }
}

proc delNodIPsec { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set ipsecCfgIndex [lsearch -index 0 [set $node] "ipsec-config"]

    if { $ipsecCfgIndex != -1 } {
	set $node [lreplace [set $node] $ipsecCfgIndex $ipsecCfgIndex]
    }
}

#****f* ipsec.tcl/getNodeIPsecItem
# NAME
#   getNodeIPsecItem -- get node IPsec item
# SYNOPSIS
#   getNodeIPsecItem $node $item
# FUNCTION
#   Retreives an item from IPsec configuration of given node
# INPUTS
#   node - node id
#   item - search item
proc getNodeIPsecItem { node item } {
    set cfg [getNodeIPsec $node]
    if { [lsearch $cfg "$item *"] != -1 } {
	return [lindex [lsearch -inline $cfg "$item *"] 1]
    }
    return ""
}

#****f* ipsec.tcl/setNodeIPsecItem
# NAME
#   setNodeIPsecItem -- set node IPsec item
# SYNOPSIS
#   setNodeIPsecItem $node $item
# FUNCTION
#   Sets an item from IPsec configuration of given node
# INPUTS
#   node - node id
#   item - search item
proc setNodeIPsecItem { node item newValue } {
    set ipsecCfg [getNodeIPsec $node]

    set itemIndex [lsearch -index 0 $ipsecCfg $item]
    if { $itemIndex != -1 } {
	set newIpsecCfg [lreplace $ipsecCfg $itemIndex $itemIndex "$item {$newValue}"]
    } else {
	set newIpsecCfg [linsert $ipsecCfg end "$item {$newValue}"]
    }

    setNodeIPsec $node $newIpsecCfg
}

proc delNodeIPsecItem { node item } {
    set ipsecCfg [getNodeIPsec $node]

    set itemIndex [lsearch -index 0 $ipsecCfg $item]
    if { $itemIndex != -1 } {
	set newIpsecCfg [lreplace $ipsecCfg $itemIndex $itemIndex]
    }

    setNodeIPsec $node $newIpsecCfg
}

#****f* ipsec.tcl/getNodeIPsecElement
# NAME
#   getNodeIPsecElement -- get node IPsec element item
# SYNOPSIS
#   getNodeIPsecElement $node $item
# FUNCTION
#   Retreives an element from IPsec configuration of given node from the
#   given item.
# INPUTS
#   node - node id
#   item - search item
#   element  - search element
proc getNodeIPsecElement { node item element } {
    set itemCfg [getNodeIPsecItem $node $item]

    if { [lsearch $itemCfg "{$element} *"] != -1 } {
	return [lindex [lsearch -inline $itemCfg "{$element} *"] 1]
    }
    return ""
}

proc setNodeIPsecElement { node item element newValue } {
    set itemCfg [getNodeIPsecItem $node $item]

    set elementIndex [lsearch -index 0 $itemCfg $element]
    if { $elementIndex != -1 } {
	set newItemCfg [lreplace $itemCfg $elementIndex $elementIndex "{$element} {$newValue}"]
    } else {
	set newItemCfg [linsert $itemCfg end "{$element} {$newValue}"]
    }

    setNodeIPsecItem $node $item $newItemCfg
}

proc delNodeIPsecElement { node item element } {
    set itemCfg [getNodeIPsecItem $node $item]

    set elementIndex [lsearch -index 0 $itemCfg $element]
    if { $elementIndex != -1 } {
	set newItemCfg [lreplace $itemCfg $elementIndex $elementIndex]
    } else {
	return
    }

    setNodeIPsecItem $node $item $newItemCfg

    if { [getNodeIPsecConnList $node] == "" } {
	delNodIPsec $node
    }
}

proc getNodeIPsecSetting { node item element setting } {
    set elementCfg [getNodeIPsecElement $node $item $element]

    if { [lsearch $elementCfg "$setting=*"] != -1 } {
	return [lindex [split [lsearch -inline $elementCfg "$setting=*"] =] 1]
    }
    return ""
}

proc setNodeIPsecSetting { node item element setting newValue } {
    set elementCfg [getNodeIPsecElement $node $item $element]

    set settingIndex [lsearch $elementCfg "$setting=*"]
    if { $newValue == "" } {
	if { $settingIndex != -1 } {
	    set newElementCfg [lreplace $elementCfg $settingIndex $settingIndex]
	} else {
	    return
	}
    } else {
	if { $settingIndex != -1 } {
	    set newElementCfg [lreplace $elementCfg $settingIndex $settingIndex "$setting=$newValue"]
	} else {
	    set newElementCfg [linsert $elementCfg end "$setting=$newValue"] 
	}
    }

    setNodeIPsecElement $node $item $element $newElementCfg
}

proc createEmptyIPsecCfg { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    setNodeIPsec $node ""
    setNodeIPsecItem $node "configuration" ""
    setNodeIPsecElement $node "configuration" "config setup" ""
}

proc getNodeIPsecConnList { node } {
    set cfg [getNodeIPsecItem $node "configuration"]
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
#   nodeIPsecConnExists $node $connection_name
# FUNCTION
#   Checks if given connection already exists in IPsec configuration of given node
# INPUTS
#   node - node id
#   connection_name - name of IPsec connection
#****
proc nodeIPsecConnExists { node connection_name } {
    set connList [getNodeIPsecConnList $node]
    if { [ lsearch $connList $connection_name ] != -1 } {
        return 1
    }
    return 0
}

#****f* ipsec.tcl/getListOfOtherNodes
# NAME
#   getListOfOtherNodes -- retreives list of all nodes
# SYNOPSIS
#   getListOfOtherNodes $node
# FUNCTION
#   Retreives list of all nodes created in current topology
# INPUTS
#   node - node id
#****
proc getListOfOtherNodes { node } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list

    set listOfNodes [removeFromList $node_list $node]

    set listOfNames ""
    foreach node $listOfNodes {
	if { [getNodeType $node] == "pseudo" } {
	    continue
	}

	lappend listOfNames "[getNodeName $node] - $node"
    }

    return $listOfNames
}

#****f* ipsec.tcl/getIPAddressForPeer
# NAME
#   getIPAddressForPeer -- retreives list of IP addresses for peer
# SYNOPSIS
#   getIPAddressForPeer $node
# FUNCTION
#   Refreshes list of IP addresses for peer's dropdown selection list
# INPUTS
#   node - node id
#****
proc getIPAddressForPeer { node curIP } {
    set listOfInterfaces [ifcList $node]
    foreach logifc [logIfcList $node] {
	if { [string match "vlan*" $logifc]} {
	    lappend listOfInterfaces $logifc
	}
    }

    set listOfIPs ""
    if { $curIP == "" } {
	set IPversion 4
    } else {
	set IPversion [ ::ip::version $curIP ] 
    }
    if { $IPversion == 4 } {
	foreach item $listOfInterfaces {
	    set ifcIP [getIfcIPv4addrs $node $item]
	    if { $ifcIP != "" } {
		lappend listOfIPs {*}$ifcIP
	    }
	}
    } else {
	foreach item $listOfInterfaces {
	    set ifcIP [getIfcIPv6addrs $node $item]
	    if { $ifcIP != "" } {
		lappend listOfIPs {*}$ifcIP
	    }
	}
    }

    return $listOfIPs
}

proc getNodeFromHostname { hostname } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list

    foreach node $node_list {
	if { $hostname == [getNodeName $node] } {
	    return $node
	}
    }

    return ""
}

#****f* ipsec.tcl/getLocalSubnets
# NAME
#   getLocalSubnets -- creates and retreives local subnets
# SYNOPSIS
#   getLocalSubnets $listOfIPs
# FUNCTION
#   Creates and retreives local subnets from given list of IP addresses
# INPUTS
#   listOfIPs - list of IP addresses
#****
proc getSubnetsFromIPs { listOfIPs } {
    set total_string ""
    set total_list ""
    foreach item $listOfIPs {
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
	    if { "$right" == "$local_ip"} {
		set rightsubnet [getNodeIPsecSetting $peer "configuration" "conn $conn" "rightsubnet"]
		if { "$rightsubnet" == "$local_subnet"} {
		    set rightid [getNodeIPsecSetting $peer "configuration" "conn $conn" "rightid"]
		    if { $rightid == "" || $local_id == "" } {
			return 1
		    } else {
			if { "$rightid" == "$local_id"} {
			    return 1
			}
		    }
		}
	    }
	}
    }

    return 0
}
