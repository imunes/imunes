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
# This work was supported in part by the Croatian Ministry of Science
# and Technology through the research contract #IP-2003-143.
#

# $Id: cfgparse.tcl 127 2014-12-18 15:10:09Z denis $


#****h* imunes/cfgparse.tcl
# NAME
#  cfgparse.tcl -- file used for parsing the configuration
# FUNCTION
#  This module is used for parsing the configuration, i.e. reading the 
#  configuration from a file or a string and writing the configuration 
#  to a file or a string. This module also contains a function for returning 
#  a new ID for nodes, links and canvases.
#****

#****f* nodecfg.tcl/dumpputs
# NAME
#   dumpputs -- puts a string to a file or a string configuration 
# SYNOPSIS
#   dumpputs $method $destination $string
# FUNCTION
#   Puts a sting to the file or appends the string configuration (used for 
#   undo functions), the choice depends on the value of method parameter.
# INPUTS
#   * method -- method used. Possiable values are file (if saving the string 
#     to the file) and string (if appending the string configuration)
#   * dest -- destination used. File_id for files, and string name for string 
#     configuration
#   * string -- the string that is inserted to a file or appended to the string
#     configuartion
#****
proc dumpputs { method dest string } {
    switch -exact -- $method {
	file {
	    puts $dest $string
	}
	string {
	    global $dest
	    append $dest "$string
"
	}
    }
}

#****f* nodecfg.tcl/dumpCfg
# NAME
#   dumpCfg -- puts the current configuraton to a file or a string 
# SYNOPSIS
#   dumpCfg $method $destination
# FUNCTION
#   Writes the working (current) configuration to a file or a string.
# INPUTS
#   * method -- used method. Possiable values are file (saving current congif
#     to the file) and string (saving current config in a string)
#   * dest -- destination used. File_id for files, and string name for string 
#     configurations
#****
proc dumpCfg { method dest } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    upvar 0 ::cf::[set ::curcfg]::link_list link_list
    upvar 0 ::cf::[set ::curcfg]::annotation_list annotation_list
    upvar 0 ::cf::[set ::curcfg]::canvas_list canvas_list
    upvar 0 ::cf::[set ::curcfg]::zoom zoom
    upvar 0 ::cf::[set ::curcfg]::image_list image_list
    # the globals bellow should be placed in a namespace as well
    global showIfNames showNodeLabels showLinkLabels
    global showIfIPaddrs showIfIPv6addrs
    global showBkgImage showGrid showAnnotations
    global iconSize
    global hostsAutoAssign

    foreach node $node_list {
	upvar 0 ::cf::[set ::curcfg]::$node lnode
	dumpputs $method $dest "node $node \{"
	foreach element $lnode {
	    if { "[lindex $element 0]" == "network-config" } {
		dumpputs $method $dest "    network-config \{"
		foreach line [lindex $element 1] {
		    dumpputs $method $dest "	$line"
		}
		dumpputs $method $dest "    \}"
	    } elseif { "[lindex $element 0]" == "ipsec-config" } {
		dumpputs $method $dest "    ipsec-config \{"
		foreach line [lindex $element 1] {
		    set header [lindex $line 0]
		    if { $header == "local_cert" || $header == "local_key_file" || $header == "ipsec-logging"} {
			dumpputs $method $dest "        $line"
		    } elseif { $header == "configuration" } {
			dumpputs $method $dest "        configuration \{"
			foreach confline [lindex $line 1] {
			    set item [lindex $confline 0]
			    dumpputs $method $dest "            $item"
			    foreach element [lindex $confline 1] {
				dumpputs $method $dest "                $element"
			    }
			}
			dumpputs $method $dest "        \}"
		    }
		}
		dumpputs $method $dest "    \}"
	    } elseif { "[lindex $element 0]" == "custom-config" } {
		dumpputs $method $dest "    custom-config \{"
		foreach line [lindex $element 1] {
		    if { $line != {} } {
			set str [lindex $line 0]
			if { $str == "custom-config" } {
			    dumpputs $method $dest "    config \{"
			    foreach element [lindex $line 1] {
				dumpputs $method $dest "    $element"
			    }
			    dumpputs $method $dest "    \}"
			} else {
			    dumpputs $method $dest "	$line"
			}
		    }
		}
		dumpputs $method $dest "    \}"
	    } elseif { "[lindex $element 0]" == "custom-configs" } {
		dumpputs $method $dest "    custom-configs \{"
		foreach line [lindex $element 1] {
		    for {set x 0} {$x<[llength $line]} {incr x 3} {
			if { $x != {} } {
			    dumpputs $method $dest "        [lindex $line $x] [lindex $line $x+1] \{"
			    dumpputs $method $dest "            [lrange [lindex $line $x+2] 0 1]"
			    dumpputs $method $dest "            [lindex [lindex $line $x+2] 2] \{"
			    foreach l [lindex [lindex $line $x+2] 3] {
				dumpputs $method $dest "                $l"
			    }
			    dumpputs $method $dest "            \}"
			    dumpputs $method $dest "        \}"
			}
		    }
		}
		dumpputs $method $dest "    \}"
	    } elseif { "[lindex $element 0]" == "events" } { 
		dumpputs $method $dest "    events \{"
		foreach line [lindex $element 1] {
		    if { $line != {} } {
			dumpputs $method $dest "	$line"
		    }
		}
		dumpputs $method $dest "    \}"
	    } else {
		dumpputs $method $dest "    $element"
	    }
	}
	dumpputs $method $dest "\}"
	dumpputs $method $dest ""
    }

    foreach obj "link annotation canvas" {
	upvar 0 ::cf::[set ::curcfg]::${obj}_list obj_list
	foreach elem $obj_list {
	    upvar 0 ::cf::[set ::curcfg]::$elem lelem
	    dumpputs $method $dest "$obj $elem \{"
	    foreach element $lelem {
		if { "[lindex $element 0]" == "events" } { 
		    dumpputs $method $dest "    events \{"
		    foreach line [lindex $element 1] {
			if { $line != {} } {
			    dumpputs $method $dest "	$line"
			}
		    }
		    dumpputs $method $dest "    \}"
		} else {
		    dumpputs $method $dest "    $element"
		}
	    }
	    dumpputs $method $dest "\}"
	    dumpputs $method $dest ""
	}
    }

    dumpputs $method $dest "option show \{"

    # XXX - this needs to be refactored.
    if {$showIfNames == 0} { 
	dumpputs $method $dest "    interface_names no" 
    } else {
	dumpputs $method $dest "    interface_names yes" }
    if {$showIfIPaddrs == 0} { 
	dumpputs $method $dest "    ip_addresses no" 
    } else {
	dumpputs $method $dest "    ip_addresses yes" }
    if {$showIfIPv6addrs == 0} { 
	dumpputs $method $dest "    ipv6_addresses no" 
    } else {
	dumpputs $method $dest "    ipv6_addresses yes" }
    if {$showNodeLabels == 0} { 
	dumpputs $method $dest "    node_labels no" 
    } else {
	dumpputs $method $dest "    node_labels yes" }
    if {$showLinkLabels == 0} { 
	dumpputs $method $dest "    link_labels no" 
    } else {
	dumpputs $method $dest "    link_labels yes" }
    if {$showBkgImage == 0} {
	dumpputs $method $dest "    background_images no"
    } else {
	dumpputs $method $dest "    background_images yes" }
    if {$showAnnotations == 0} {
	dumpputs $method $dest "    annotations no"
    } else {
	dumpputs $method $dest "    annotations yes" }
    if {$hostsAutoAssign == 0} {
	dumpputs $method $dest "    hostsAutoAssign no"
    } else {
	dumpputs $method $dest "    hostsAutoAssign yes" }
    if {$showGrid == 0} {
	dumpputs $method $dest "    grid no"
    } else {
	dumpputs $method $dest "    grid yes" }
    dumpputs $method $dest "    iconSize $iconSize"
    dumpputs $method $dest "    zoom $zoom"
    dumpputs $method $dest "\}"
    dumpputs $method $dest ""

    foreach elem $image_list {
	if {[getImageReferences $elem] != ""} {
	    upvar 0 ::cf::[set ::curcfg]::$elem lelem
	    dumpputs $method $dest "image $elem \{"
	    foreach element $lelem {
		if {[string match "*zoom_*" $element] != 1} {
		    dumpputs $method $dest "    $element"
		}
	    }
	    dumpputs $method $dest "\}"
	    dumpputs $method $dest ""
	}
    }
}

#****f* nodecfg.tcl/loadCfg
# NAME
#   loadCfg -- loads the current configuration.
# SYNOPSIS
#   loadCfg $cfg
# FUNCTION
#   Loads the configuration written in the cfg string to a current 
#   configuration. 
# INPUTS
#   * cfg -- string containing the new working configuration.
#****
proc loadCfg { cfg } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    upvar 0 ::cf::[set ::curcfg]::link_list link_list
    upvar 0 ::cf::[set ::curcfg]::annotation_list annotation_list
    upvar 0 ::cf::[set ::curcfg]::canvas_list canvas_list
    upvar 0 ::cf::[set ::curcfg]::zoom zoom
    upvar 0 ::cf::[set ::curcfg]::image_list image_list
    upvar 0 ::cf::[set ::curcfg]::IPv6UsedList IPv6UsedList
    upvar 0 ::cf::[set ::curcfg]::IPv4UsedList IPv4UsedList
    upvar 0 ::cf::[set ::curcfg]::MACUsedList MACUsedList
    upvar 0 ::cf::[set ::curcfg]::etchosts etchosts
    global showIfNames showNodeLabels showLinkLabels
    global showIfIPaddrs showIfIPv6addrs
    global showBkgImage showGrid showAnnotations
    global iconSize
    global hostsAutoAssign
    global execMode all_modules_list

    # Cleanup first
    set node_list {}
    set link_list {}
    set annotation_list {}
    set canvas_list {}
    set image_list {}
    set etchosts ""
    set class ""
    set object ""
    foreach entry $cfg {
	if {"$class" == ""} {
	    set class $entry
	    continue
	} elseif {"$object" == ""} {
	    set object $entry
	    upvar 0 ::cf::[set ::curcfg]::$object $object
	    set $object {}
	    if {"$class" == "node"} {
		lappend node_list $object
	    } elseif {"$class" == "link"} {
		lappend link_list $object
	    } elseif {"$class" == "link"} {
		lappend link_list $object
	    } elseif {"$class" == "canvas"} {
		lappend canvas_list $object
	    } elseif {"$class" == "option"} {
		# do nothing
	    } elseif {"$class" == "annotation"} {
		lappend annotation_list $object
	    } elseif {"$class" == "image"} {
		lappend image_list $object
	    } else {
		puts "configuration parsing error: unknown object class $class"
		exit 1
	    }
	    continue
	} else {
	    set line [concat $entry]
	    while {[llength $line] >= 2} {
		set field [lindex $line 0]
		if {"$field" == ""} {
		    set line [lreplace $line 0 0]
		    continue
		}

		set value [lindex $line 1]
		set line [lreplace $line 0 1]
    
		if {"$class" == "node"} {
		    switch -exact -- $field {
			type {
			    lappend $object "type $value"
			}
			mirror {
			    lappend $object "mirror $value"
			}
			model {
			    lappend $object "model $value"
			}
			snapshot {
			    lappend $object "snapshot $value"
			}
			cpu {
			    lappend $object "cpu {$value}"
			}
			interface-peer {
			    lappend $object "interface-peer {$value}"
			}
			network-config {
			    set cfg ""
			    foreach zline [split $value {
}] {
				if { [string index "$zline" 0] == "	" } {
				    set zline [string replace "$zline" 0 0]
				}
				lappend cfg $zline
			    }
			    set cfg [lrange $cfg 1 [expr {[llength $cfg] - 2}]]
			    lappend $object "network-config {$cfg}"
			}
			ipsec-config {
			    set cfg ""
			    set conf_indicator 0
			    set cset_indicator 0
			    set conn_indicator 0
			    set conf_list ""
			    set conn_list ""
			    set cset_list ""
			    set conn_name ""
			    foreach zline [split $value {
}] {
				set zline [string trimleft "$zline"]
				if { [string first "local_cert" $zline] != -1 || [string first "local_key_file" $zline] != -1 } {
				    lappend cfg $zline
				} elseif { [string first "ipsec-logging" $zline] != -1 } {
				    lappend cfg "$zline"
				} elseif { [string first "configuration" $zline] != -1 } {
				    set conf_indicator 1
				} elseif { [string first "\}" $zline] != -1 } {
				    set conf_indicator 0
				    set cset_indicator 0
				    if { $conn_indicator } {
					lappend conf_list "{$conn_name} {$conn_list}"
				    }
				    lappend cfg "configuration {$conf_list}"
				} elseif { $conf_indicator } {
				    if { [string first "config setup" $zline] != -1 } {
					set conn_indicator 0
					set cset_indicator 1
				    } elseif { $cset_indicator } {
					if { [string first "conn" $zline] != -1 } {
					    set cset_indicator 0
					    lappend conf_list "{config setup} {$cset_list}"
					} else {
					    lappend cset_list $zline
					}
				    }

				    if { [string first "conn" $zline] != -1 } {
					if { $conn_indicator } {
					    lappend conf_list "{$conn_name} {$conn_list}"
					} else {
					    set conn_indicator 1
					}
					set conn_name "$zline"
					set conn_list ""
				    } elseif { $conn_indicator } {
					lappend conn_list $zline
				    }
				}
			    }
			    lappend $object "ipsec-config {$cfg}"
			}
			custom-enabled {
			    lappend $object "custom-enabled $value"
			}
			custom-selected {
			    lappend $object "custom-selected $value"
			}
			custom-command {
			    lappend $object "custom-command {$value}"
			}
			custom-config {
			    set cfg ""
			
			    foreach zline [split $value {
}] {
				if { [string index "$zline" 0] == "	" } {
				    set zline [string replace "$zline" 0 0]
				}
				lappend cfg $zline
			    }
			    set cfg [lrange $cfg 1 [expr {[llength $cfg] - 2}]]
			    lappend $object "custom-config {$cfg}"
			}
			custom-configs {
			    set cfgs ""
			    for {set x 0} {$x<[llength $value]} {incr x 3} {
				set cfg ""
				set config [lindex [lindex $value $x+2] 3]
				set empty 0
				set config_split [split $config {
}]
				set config_split [lrange $config_split 1 end-1]
				set line1 [lindex $config_split 0]
				set empty [expr {[string length $line1]-\
				    [string length [string trimleft $line1]]}]
				set empty_str [string repeat " " $empty]
				foreach zline $config_split {
				    while { [string range $zline 0 $empty-1] != "$empty_str" } {
					set zline [regsub {\t} $zline "        "]
				    }
				    set zline [string range $zline $empty end]
				    lappend cfg $zline
				}
				set cfg_pconf [lreplace [lindex $value $x+2] 3 3 $cfg]
				set cfg [lreplace [lrange $value $x $x+2] 2 2 $cfg_pconf]
				lappend cfgs $cfg
			    }
			    lappend $object "custom-configs {$cfgs}"
			}
			iconcoords {
			    lappend $object "iconcoords {$value}"
			}
			labelcoords {
			    lappend $object "labelcoords {$value}"
			}
			canvas {
			    lappend $object "canvas $value"
			}
			services {
			    lappend $object "services {$value}"
			}
			docker-attach {
			    lappend $object "docker-attach $value"
			}
			docker-image {
			    lappend $object "docker-image $value"
			}
			events {
			    set cfg ""
			    foreach zline [split $value {
}] {
				if { [string index "$zline" 0] == "	" } {
				    set zline [string replace "$zline" 0 0]
				}
				set zline [string trim $zline]
				lappend cfg $zline
			    }
			    set cfg [lrange $cfg 1 [expr {[llength $cfg] - 2}]]
			    lappend $object "events {$cfg}"
			}
			customIcon {
			    lappend $object "customIcon $value"
			}
		    }
		} elseif {"$class" == "link"} {
		    switch -exact -- $field {
			nodes {
			    lappend $object "nodes {$value}"
			}
			mirror {
			    lappend $object "mirror $value"
			}
			bandwidth {
			    lappend $object "bandwidth $value"
			}
			delay {
			    lappend $object "delay $value"
			}
			jitter-upstream {
			    lappend $object "jitter-upstream {$value}"
			}
			jitter-upstream-mode {
			    lappend $object "jitter-upstream-mode $value"
			}
			jitter-upstream-hold {
			    lappend $object "jitter-upstream-hold $value"
			}
			jitter-downstream {
			    lappend $object "jitter-downstream {$value}"
			}
			jitter-downstream-mode {
			    lappend $object "jitter-downstream-mode $value"
			}
			jitter-downstream-hold {
			    lappend $object "jitter-downstream-hold $value"
			}
			ber {
			    lappend $object "ber $value"
			}
			duplicate {
			    lappend $object "duplicate $value"
			}
			color {
			    lappend $object "color $value"
			}
			width {
			    lappend $object "width $value"
			}
			events {
			    set cfg ""
			    foreach zline [split $value {
}] {
				if { [string index "$zline" 0] == "	" } {
				    set zline [string replace "$zline" 0 0]
				}
				set zline [string trim $zline]
				lappend cfg $zline
			    }
			    set cfg [lrange $cfg 1 [expr {[llength $cfg] - 2}]]
			    lappend $object "events {$cfg}"
			}
		    }
		} elseif {"$class" == "canvas"} {
		    switch -exact -- $field {
			name {
			    lappend $object "name {$value}"
			}
			size {
			    lappend $object "size {$value}"
			}
			bkgImage {
			    lappend $object "bkgImage {$value}"
			}
		    }
		} elseif {"$class" == "option"} {
		    switch -exact -- $field {
			interface_names {
			    if { $value == "no" } {
				set showIfNames 0
			    } elseif { $value == "yes" } {
				set showIfNames 1
			    }
			}
			ip_addresses {
			    if { $value == "no" } {
				set showIfIPaddrs 0
			    } elseif { $value == "yes" } {
				set showIfIPaddrs 1
			    }
			}
			ipv6_addresses {
			    if { $value == "no" } {
				set showIfIPv6addrs 0
			    } elseif { $value == "yes" } {
				set showIfIPv6addrs 1
			    }
			}
			node_labels {
			    if { $value == "no" } {
				set showNodeLabels 0
			    } elseif { $value == "yes" } {
				set showNodeLabels 1
			    }
			}
			link_labels {
			    if { $value == "no" } {
				set showLinkLabels 0
			    } elseif { $value == "yes" } {
				set showLinkLabels 1
			    }
			}
			background_images {
			    if { $value == "no" } {
				set showBkgImage 0
			    } elseif { $value == "yes" } {
				set showBkgImage 1
			    }
			}
			annotations {
			    if { $value == "no" } {
				set showAnnotations 0
			    } elseif { $value == "yes" } {
				set showAnnotations 1
			    }
			}
			grid {
			    if { $value == "no" } {
				set showGrid 0
			    } elseif { $value == "yes" } {
				set showGrid 1
			    }
			}
			hostsAutoAssign {
			    if { $value == "no" } {
				set hostsAutoAssign 0
			    } elseif { $value == "yes" } {
				set hostsAutoAssign 1
			    }
			}
			zoom {
			    set zoom $value
			}
			iconSize {
			    set iconSize $value
			}
		    }
		} elseif {"$class" == "annotation"} {
		    switch -exact -- $field {
			type {
			    lappend $object "type $value"
			}
			iconcoords {
			    lappend $object "iconcoords {$value}"
			}
			color {
			    lappend $object "color $value"
			}
			label {
			    lappend $object "label {$value}"
			}
			labelcolor {
			    lappend $object "labelcolor $value"
			}
			size {
			    lappend $object "size $value"
			}
			canvas {
			    lappend $object "canvas $value"
			}
			font {
			    lappend $object "font {$value}"
			}
			fontfamily {
			    lappend $object "fontfamily {$value}"
			}
			fontsize {
			    lappend $object "fontsize {$value}"
			}
			effects {
			    lappend $object "effects {$value}"
			}
			width {
			    lappend $object "width $value"
			}
			bordercolor {
			    lappend $object "bordercolor $value"
			}
		    }
		} elseif {"$class" == "image"} {
		    upvar 0 ::cf::[set ::curcfg]::$object $object
		    switch -glob -- $field {
			referencedBy {
			    lappend $object "referencedBy {$value}"
			}
			file {
			    lappend $object "file {$value}"
			}
			type {
			    lappend $object "type {$value}"
			}
			data {
			    lappend $object "data {$value}"
			}
		    }
		}
	    }
	}
	set class ""
	set object ""
    }

    #
    # Hack for comaptibility with old format files (no canvases)
    #
    if { $canvas_list == "" } {
	set curcanvas [newCanvas ""]
	foreach node $node_list {
	    setNodeCanvas $node $curcanvas
	}
    }
    #
    # Hack for comaptibility with old format files (no lo0 on nodes)
    #
    set IPv6UsedList ""
    set IPv4UsedList ""
    set MACUsedList ""
    foreach node $node_list {
	set nodeType [typemodel $node]
	if { $nodeType ni [concat $all_modules_list "pseudo"] && \
	    ! [string match "router.*" $nodeType] } {
	    set msg "Unknown node type: '$nodeType'."
	    if { $execMode == "batch" } {
		statline $msg
	    } else {
		tk_dialog .dialog1 "IMUNES warning" \
		    "Error: $msg" \
		info 0 Dismiss
	    }
	    exit
	}
	if { "lo0" ni [logIfcList $node] && \
		[[typemodel $node].layer] == "NETWORK"} {
	    setLogIfcType $node lo0 lo
	    setIfcIPv4addr $node lo0 "127.0.0.1/8"
	    setIfcIPv6addr $node lo0 "::1/128"
	}
	# Speeding up auto renumbering of MAC, IPv4 and IPv6 addresses by remembering
	# used addresses in lists.
	foreach iface [ifcList $node] {
	    set addr [getIfcIPv6addr $node $iface]
	    if { $addr != "" } { lappend IPv6UsedList [ip::contract [ip::prefix $addr]] }
	    set addr [getIfcIPv4addr $node $iface]
	    if { $addr != "" } { lappend IPv4UsedList $addr }
	    lappend MACUsedList [getIfcMACaddr $node $iface]
	}
    }
}

#****f* nodecfg.tcl/newObjectId
# NAME
#   newObjectId -- new object Id 
# SYNOPSIS
#   set obj_id [newObjectId $type]
# FUNCTION
#   Returns the Id for a new object of the defined type. Supported types
#   are node, link and canvas. The Id is in the form $mark$number. $mark is
#   the first letter of the given type and $number is the first available
#   number to that can be used for id. 
# INPUTS
#   * type -- the type of the new object. Can be node, link or canvas.
# RESULT
#   * obj_id -- object Id in the form $mark$number. $mark is the 
#     first letter of the given type and $number is the first available number
#     to that can be used for id. 
#****
proc newObjectId { type } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    upvar 0 ::cf::[set ::curcfg]::link_list link_list
    upvar 0 ::cf::[set ::curcfg]::annotation_list annotation_list
    upvar 0 ::cf::[set ::curcfg]::canvas_list canvas_list
    global cfg_list

    set mark [string range [set type] 0 0]
    set id 0
    while {[lsearch [set [set type]_list] "$mark$id"]  != -1} {
	incr id
    }
    return $mark$id
}
