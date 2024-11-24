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

#****f* nodecfg.tcl/loadCfgLegacy
# NAME
#   loadCfgLegacy -- loads the current configuration.
# SYNOPSIS
#   loadCfgLegacy $cfg
# FUNCTION
#   Loads the configuration written in the cfg string to a current
#   configuration.
# INPUTS
#   * cfg -- string containing the new working configuration.
#****
proc loadCfgLegacy { cfg } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    upvar 0 ::cf::[set ::curcfg]::link_list link_list
    upvar 0 ::cf::[set ::curcfg]::annotation_list annotation_list
    upvar 0 ::cf::[set ::curcfg]::canvas_list canvas_list
    upvar 0 ::cf::[set ::curcfg]::zoom zoom
    upvar 0 ::cf::[set ::curcfg]::image_list image_list
    upvar 0 ::cf::[set ::curcfg]::ipv6_used_list ipv6_used_list
    upvar 0 ::cf::[set ::curcfg]::ipv4_used_list ipv4_used_list
    upvar 0 ::cf::[set ::curcfg]::mac_used_list mac_used_list
    upvar 0 ::cf::[set ::curcfg]::etchosts etchosts
    global show_interface_names show_node_labels show_link_labels
    global show_interface_ipv4 show_interface_ipv6
    global show_background_images show_grid show_annotations
    global icon_size
    global auto_etc_hosts
    global execMode all_modules_list

    upvar 0 ::cf::[set ::curcfg]::dict_run dict_run
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg
    set dict_cfg [dict create]
    set dict_run [dict create]

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
	if { "$class" == "" } {
	    set class $entry
	    continue
	} elseif { "$object" == "" } {
	    set object $entry
	    upvar 0 ::cf::[set ::curcfg]::$object $object
	    set $object {}
	    set dict_object "${class}s"
	    if { "$class" == "node" } {
		lappend node_list $object
	    } elseif { "$class" == "link" } {
		lappend link_list $object
	    } elseif { "$class" == "canvas" } {
		set dict_object "canvases"
		lappend canvas_list $object
	    } elseif { "$class" == "option" } {
		# do nothing
	    } elseif { "$class" == "annotation" } {
		lappend annotation_list $object
	    } elseif { "$class" == "image" } {
		lappend image_list $object
	    } else {
		puts "configuration parsing error: unknown object class $class"
		exit 1
	    }
	    continue
	} else {
	    set line [concat $entry]
	    while { [llength $line] >= 2 } {
		set field [lindex $line 0]
		if { "$field" == "" } {
		    set line [lreplace $line 0 0]
		    continue
		}

		set value [lindex $line 1]
		set line [lreplace $line 0 1]

		cfgSet $dict_object $object $field $value
		if { "$class" == "node" } {
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
			    cfgUnset $dict_object $object $field
			    lassign $value iface peer
			    cfgSet $dict_object $object "ifaces" $iface "peer" $peer
			    cfgSet $dict_object $object "ifaces" $iface "peer_iface" $iface
			    lappend $object "interface-peer {$value}"
			}
			external-ifcs {
			    lappend $object "external-ifcs {$value}"
			}
			network-config {
			    cfgUnset $dict_object $object $field
			    set cfg ""
			    set ifname ""
			    set all_ifaces [dict create]
			    set ipv4_addrs {}
			    set ipv6_addrs {}
			    set croutes4 {}
			    set croutes6 {}
			    set vlan false
			    set bridge_name ""
			    set nat64 false
			    set tayga_mappings {}
			    set packgen false
			    foreach zline [split $value {
}] {
				if { [string index "$zline" 0] == "	" } {
				    set zline [string replace "$zline" 0 0]
				}
				if { $ifname != "" } {
				    switch -regexp -- $zline {
					" type *" {
					    dict set all_ifaces $ifname "type" [lindex $zline end]
					}
					" mac address *" {
					    dict set all_ifaces $ifname "mac" [lindex $zline end]
					}
					" ip address *" {
					    lappend ipv4_addrs [lindex $zline end]
					}
					" ipv6 address *" {
					    lappend ipv6_addrs [lindex $zline end]
					}
					" nat" -
					" !nat" {
					    dict set all_ifaces $ifname "nat_state" "on"
					}
					" shutdown" {
					    dict set all_ifaces $ifname "oper_state" "down"
					}
					" fair-queue" {
					    dict set all_ifaces $ifname "ifc_qdisc" "WFQ"
					}
					" drr-queue" {
					    dict set all_ifaces $ifname "ifc_qdisc" "DRR"
					}
					" fifo-queue" {
					    dict set all_ifaces $ifname "ifc_qdisc" "FIFO"
					}
					" drop-head" {
					    dict set all_ifaces $ifname "ifc_qdrop" "drop-head"
					}
					" drop-tail" {
					    dict set all_ifaces $ifname "ifc_qdrop" "drop-tail"
					}
					" queue-len *" {
					    dict set all_ifaces $ifname "queue_len" [lindex $zline end]
					}
					" mtu *" {
					    dict set all_ifaces $ifname "mtu" [lindex $zline end]
					}
					" vlan-dev *" {
					    dict set all_ifaces $ifname "vlan_dev" [lindex $zline end]
					}
					" vlan-tag *" {
					    dict set all_ifaces $ifname "vlan_tag" [lindex $zline end]
					}
					" ([1-9])([0-9])*:(no)?match_.*" {
					    set rule [split [string trim $zline] ":"]

					    set rule_num [lindex $rule 0]
					    set action [lindex $rule 1]
					    set pat_mask_off [lindex $rule 2]
					    set pattern [lindex [split $pat_mask_off "/"] 0]
					    set mask_off [lindex [split $pat_mask_off "/"] 1]
					    set mask [lindex [split $mask_off "@"] 0]
					    set offset [lindex [split $mask_off "@"] 1]
					    set action_data [lindex $rule 3]

					    set ruleline [list \
						"action" $action \
						"pattern" $pattern \
						"mask" $mask \
						"offset" $offset \
						"action_data" $action_data \
					    ]

					    addFilterIfcRule $object $ifname $rule_num $ruleline
					}
					" spanning-tree *" {
					    set stp_param ""
					    set trimmed [string trim $zline]
					    set stp_value 0
					    switch -glob -- $trimmed {
						"* stp" {
						    set stp_param "stp_enabled"
						    set stp_value 1
						}
						"* snoop" -
						"* discover" -
						"* learn" -
						"* sticky" -
						"* private" -
						"* edge" -
						"* autoedge" -
						"* ptp" -
						"* autoptp" {
						    set stp_param "stp_[lindex $trimmed 1]"
						    set stp_value 1
						}
						"* priority *" {
						    set stp_param "stp_priority"
						    set stp_value [lindex $trimmed 2]
						}
						"* maxaddr *" {
						    set stp_param "stp_max_addresses"
						    set stp_value [lindex $trimmed 2]
						}
						"* pathcost *" {
						    set stp_param "stp_path_cost"
						    set stp_value [lindex $trimmed 2]
						}
					    }

					    if { $stp_param != "" } {
						dict set all_ifaces $ifname $stp_param $stp_value
					    }
					}
					"!" {
					    if { [llength $ipv4_addrs] > 0 } {
						dict set all_ifaces $ifname "ipv4_addrs" $ipv4_addrs
					    }
					    if { [llength $ipv6_addrs] > 0 } {
						dict set all_ifaces $ifname "ipv6_addrs" $ipv6_addrs
					    }

					    set ifname ""
					}
				    }
				}

				if { $vlan } {
				    switch -glob -- $zline {
					" enabled *" {
					    cfgSet $dict_object $object "vlan" "enabled" [lindex $zline end]
					}
					" tag *" {
					    cfgSet $dict_object $object "vlan" "tag" [lindex $zline end]
					}
					"!" {
					    set vlan false
					}
				    }
				}

				if { $nat64 } {
				    switch -glob -- $zline {
					" taygaMapping *" {
					    lappend tayga_mappings [lrange $zline 1 end]
					}
					"!" {
					    if { $tayga_mappings != {} } {
						cfgSet $dict_object $object "nat64" "tayga_mappings" $tayga_mappings
					    }
					    set nat64 false
					}
					default {
					    set key ""
					    switch -exact -- [lindex $zline 0] {
						"tunIPv4addr" {
						    set key "tun_ipv4_addr"
						}
						"tunIPv6addr" {
						    set key "tun_ipv6_addr"
						}
						"taygaIPv4addr" {
						    set key "tayga_ipv4_addr"
						}
						"taygaIPv6prefix" {
						    set key "tayga_ipv6_prefix"
						}
						"taygaIPv4pool" {
						    set key "tayga_ipv4_pool"
						}
					    }

					    if { $key != "" } {
						cfgSet $dict_object $object "nat64" $key [lrange $zline 1 end]
					    }
					}
				    }
				}

				if { $packgen } {
				    switch -glob -- $zline {
					" packetrate *" {
					    cfgSet $dict_object $object "packgen" [lindex $zline 0] [lrange $zline 1 end]
					}
					"!" {
					    set packgen false
					}
					default {
					    lassign [split $zline ':'] id packet_data
					    set id [string trim $id]
					    set packet_data [string trim $packet_data]
					    cfgSet $dict_object $object "packgen" "packets" $id $packet_data
					}
				    }
				}

				if { $bridge_name != "" } {
				    switch -glob -- $zline {
					" stp" -
					" rstp" {
					    cfgSet $dict_object $object "bridge" "protocol" [lindex $zline end]
					}
					" priority *" {
					    cfgSet $dict_object $object "bridge" "priority" [lindex $zline end]
					}
					" holdcnt *" {
					    cfgSet $dict_object $object "bridge" "hold_count" [lindex $zline end]
					}
					" maxage *" {
					    cfgSet $dict_object $object "bridge" "max_age" [lindex $zline end]
					}
					" fwddelay *" {
					    cfgSet $dict_object $object "bridge" "forwarding_delay" [lindex $zline end]
					}
					" hellotime *" {
					    cfgSet $dict_object $object "bridge" "hello_time" [lindex $zline end]
					}
					" maxaddr *" {
					    cfgSet $dict_object $object "bridge" "max_addresses" [lindex $zline end]
					}
					" timeout *" {
					    cfgSet $dict_object $object "bridge" "address_timeout" [lindex $zline end]
					}
					"!" {
					    set bridge_name ""
					}
				    }
				}

				switch -glob -- $zline {
				    "hostname *" {
					cfgSet $dict_object $object "name" [lindex $zline end]
				    }
				    "interface *" {
					set ifname [lindex $zline end]
					set ipv4_addrs {}
					set ipv6_addrs {}
				    }
				    "ip route *" {
					lappend croutes4 [lrange $zline 2 end]
				    }
				    "ipv6 route *" {
					lappend croutes6 [lrange $zline 2 end]
				    }
				    "vlan" {
					set vlan true
				    }
				    "bridge *" {
					set bridge_name [lindex $zline end]
					cfgSet $dict_object $object "bridge" "name" $bridge_name
				    }
				    "stp-enabled *" {
					cfgSet $dict_object $object "stp_enabled" [lindex $zline end]
				    }
				    "nat64" {
					set nat64 true
					cfgSet $dict_object $object "model" "frr"
				    }
				    "packets" -
				    "packet generator" {
					set packgen true
				    }
				    "router *" {
					cfgSet $dict_object $object "router_config" [lindex $zline 1] 1
				    }
				}

				lappend cfg $zline
			    }
			    set cfg [lrange $cfg 1 [expr {[llength $cfg] - 2}]]
			    lappend $object "network-config {$cfg}"

			    foreach iface [dict keys $all_ifaces] {
				set group "ifaces"

				catch { dict get $all_ifaces $iface "type" } type
				if { $type in "lo vlan tun" } {
				    set group "logifaces"
				}

				cfgSet $dict_object $object $group "$iface" [dict get $all_ifaces $iface]
			    }

			    cfgSet $dict_object $object "croutes4" $croutes4
			    cfgSet $dict_object $object "croutes6" $croutes6
			}
			ipsec-config {
			    cfgUnset $dict_object $object $field
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
				    cfgSet $dict_object $object "ipsec" [lindex $zline 0] [lindex $zline end]
				} elseif { [string first "ipsec-logging" $zline] != -1 } {
				    lappend cfg "$zline"
				    cfgSet $dict_object $object "ipsec" "ipsec_logging" [lindex $zline end]
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
					set name [lindex $conn_name end]
					lassign [split $zline '='] ipsec_field ipsec_value
					cfgSet $dict_object $object "ipsec" "ipsec_configs" $name $ipsec_field $ipsec_value
				    }
				}
			    }
			    lappend $object "ipsec-config {$cfg}"
			}
			custom-enabled {
			    cfgUnset $dict_object $object $field
			    cfgSet $dict_object $object "custom_enabled" $value
			    lappend $object "custom-enabled $value"
			}
			custom-selected {
			    cfgUnset $dict_object $object $field
			    cfgSet $dict_object $object "custom_selected" $value
			    lappend $object "custom-selected $value"
			}
			custom-command {
			    cfgUnset $dict_object $object $field
			    cfgSet $dict_object $object "custom_command" $value
			    lappend $object "custom-command {$value}"
			}
			custom-config {
			    cfgUnset $dict_object $field
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
			    cfgUnset $dict_object $object $field
			    set cfgs ""
			    for { set x 0 } { $x<[llength $value] } { incr x 3 } {
				set custom_config_id [lindex $value $x+1]
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
				set custom_command [lindex $cfg_pconf 1]
				set custom_config $cfg
				set cfg [lreplace [lrange $value $x $x+2] 2 2 $cfg_pconf]
				lappend cfgs $cfg

				cfgSet $dict_object $object "custom_configs" $custom_config_id "custom_command" $custom_command
				cfgSet $dict_object $object "custom_configs" $custom_config_id "custom_config" $custom_config
			    }
			    lappend $object "custom-configs {$cfgs}"
			}
			iconcoords {
			    set new_value {}
			    foreach v $value {
				lappend new_value [expr int($v)]
			    }
			    set value $new_value
			    cfgSet $dict_object $object $field $value
			    lappend $object "iconcoords {$value}"
			}
			labelcoords {
			    set new_value {}
			    foreach v $value {
				lappend new_value [expr int($v)]
			    }
			    set value $new_value
			    cfgSet $dict_object $object $field $value
			    lappend $object "labelcoords {$value}"
			}
			auto_default_routes {
			    lappend $object "auto_default_routes $value"
			}
			canvas {
			    lappend $object "canvas $value"
			}
			services {
			    lappend $object "services {$value}"
			}
			docker-attach {
			    cfgUnset $dict_object $object $field
			    set docker_enable_str [string map {false "" true 1} $value]
			    cfgSet $dict_object $object "docker_attach" $docker_enable_str
			    lappend $object "docker-attach $value"
			}
			# for backwards compatibility
			docker-image -
			custom-image {
			    cfgUnset $dict_object $object $field
			    cfgSet $dict_object $object "custom_image" $value
			    lappend $object "custom-image $value"
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
			    cfgUnset $dict_object $object $field
			    cfgSet $dict_object $object "custom_icon" $value
			    lappend $object "customIcon $value"
			}
		    }
		} elseif { "$class" == "link" } {
		    switch -exact -- $field {
			direct {
			    lappend $object "direct $value"
			}
			nodes {
			    cfgUnset $dict_object $object $field
			    cfgSet $dict_object $object "peers" $value
			    lappend $object "nodes {$value}"
			    set ifaces {}
			    foreach node $value {
				set other_node [removeFromList $value $node]
				dict for {iface if_value} [cfgGet "nodes" $node "ifaces"] {
				    if { [dictGet $if_value "peer"] == "$other_node" } {
					lappend ifaces $iface
					cfgUnset "nodes" $node "ifaces" $iface "peer"
					cfgUnset "nodes" $node "ifaces" $iface "peer_iface"
					cfgSet "nodes" $node "ifaces" $iface "link" $object

					break
				    }
				}
			    }

			    cfgSet $dict_object $object "peers_ifaces" $ifaces
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
			    cfgUnset $dict_object $object $field
			    cfgSet $dict_object $object "jitter_upstream" $value
			    lappend $object "jitter-upstream {$value}"
			}
			jitter-upstream-mode {
			    cfgUnset $dict_object $object $field
			    cfgSet $dict_object $object "jitter_upstream_mode" $value
			    lappend $object "jitter-upstream-mode $value"
			}
			jitter-upstream-hold {
			    cfgUnset $dict_object $object $field
			    cfgSet $dict_object $object "jitter_upstream_hold" $value
			    lappend $object "jitter-upstream-hold $value"
			}
			jitter-downstream {
			    cfgUnset $dict_object $object $field
			    cfgSet $dict_object $object "jitter_downstream" $value
			    lappend $object "jitter-downstream {$value}"
			}
			jitter-downstream-mode {
			    cfgUnset $dict_object $object $field
			    cfgSet $dict_object $object "jitter_downstream_mode" $value
			    lappend $object "jitter-downstream-mode $value"
			}
			jitter-downstream-hold {
			    cfgUnset $dict_object $object $field
			    cfgSet $dict_object $object "jitter_downstream_hold" $value
			    lappend $object "jitter-downstream-hold $value"
			}
			ber {
			    lappend $object "ber $value"
			}
			loss {
			    lappend $object "loss $value"
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
		} elseif { "$class" == "canvas" } {
		    switch -exact -- $field {
			name {
			    lappend $object "name {$value}"
			}
			size {
			    lappend $object "size {$value}"
			}
			bkgImage {
			    cfgSet $dict_object $object "bkg_image" $value
			    lappend $object "bkgImage {$value}"
			}
		    }
		} elseif { "$class" == "option" } {
		    cfgUnset $dict_object $object
		    switch -exact -- $field {
			interface_names {
			    if { $value == "no" } {
				set show_interface_names 0
			    } elseif { $value == "yes" } {
				set show_interface_names 1
			    }
			    cfgSet $dict_object "show_interface_names" $show_interface_names
			}
			ip_addresses {
			    if { $value == "no" } {
				set show_interface_ipv4 0
			    } elseif { $value == "yes" } {
				set show_interface_ipv4 1
			    }
			    cfgSet $dict_object "show_interface_ipv4" $show_interface_ipv4
			}
			ipv6_addresses {
			    if { $value == "no" } {
				set show_interface_ipv6 0
			    } elseif { $value == "yes" } {
				set show_interface_ipv6 1
			    }
			    cfgSet $dict_object "show_interface_ipv6" $show_interface_ipv6
			}
			node_labels {
			    if { $value == "no" } {
				set show_node_labels 0
			    } elseif { $value == "yes" } {
				set show_node_labels 1
			    }
			    cfgSet $dict_object "show_node_labels" $show_node_labels
			}
			link_labels {
			    if { $value == "no" } {
				set show_link_labels 0
			    } elseif { $value == "yes" } {
				set show_link_labels 1
			    }
			    cfgSet $dict_object "show_link_labels" $show_link_labels
			}
			background_images {
			    if { $value == "no" } {
				set show_background_images 0
			    } elseif { $value == "yes" } {
				set show_background_images 1
			    }
			    cfgSet $dict_object "show_background_images" $show_background_images
			}
			annotations {
			    if { $value == "no" } {
				set show_annotations 0
			    } elseif { $value == "yes" } {
				set show_annotations 1
			    }
			    cfgSet $dict_object "show_annotations" $show_annotations
			}
			grid {
			    if { $value == "no" } {
				set show_grid 0
			    } elseif { $value == "yes" } {
				set show_grid 1
			    }
			    cfgSet $dict_object "show_grid" $show_grid
			}
			hostsAutoAssign {
			    if { $value == "no" } {
				set auto_etc_hosts 0
			    } elseif { $value == "yes" } {
				set auto_etc_hosts 1
			    }
			    cfgSet $dict_object "auto_etc_hosts" $auto_etc_hosts
			}
			zoom {
			    set zoom $value
			    cfgSet $dict_object "zoom" $zoom
			}
			iconSize {
			    set icon_size $value
			    cfgSet $dict_object "icon_size" $icon_size
			}
		    }
		} elseif { "$class" == "annotation" } {
		    switch -exact -- $field {
			type {
			    lappend $object "type $value"
			}
			iconcoords {
			    set new_value {}
			    foreach v $value {
				lappend new_value [expr int($v)]
			    }
			    set value $new_value
			    cfgSet $dict_object $object $field $value
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
		} elseif { "$class" == "image" } {
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
			    set enc [string trim $value \{\}]
			    set enc [string trim $enc " "]
			    set enc [string map {"\n" {}} $enc]
			    set data [base64::decode $enc]
			    set enc_data [base64::encode -maxlen 0 $data]
			    cfgSet $dict_object $object $field $enc_data

			    lappend $object "data {$value}"
			}
		    }
		}
	    }
	}
	set class ""
	set object ""
    }
    global CFG_VERSION
    setOption "version" $CFG_VERSION

    setToRunning "node_list" $node_list
    setToRunning "link_list" $link_list
    setToRunning "canvas_list" $canvas_list
    setToRunning "annotation_list" $annotation_list

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
    set ipv6_used_list {}
    set ipv4_used_list {}
    set mac_used_list {}
    foreach node $node_list {
	set node_type [getNodeType $node]
	if { $node_type in "extelem" } {
	    continue
	}
	if { $node_type ni [concat $all_modules_list "pseudo"] && \
	    ! [string match "router.*" $node_type] } {
	    set msg "Unknown node type: '$node_type'."
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
	    [[getNodeType $node].netlayer] == "NETWORK"} {

	    setLogIfcType $node lo0 lo
	    setIfcIPv4addrs $node lo0 "127.0.0.1/8"
	    setIfcIPv6addrs $node lo0 "::1/128"
	}
	# Speeding up auto renumbering of MAC, IPv4 and IPv6 addresses by remembering
	# used addresses in lists.
	foreach iface [ifcList $node] {
	    lassign [split [getIfcIPv6addr $node $iface] "/"] addr mask
	    if { $addr != "" } { lappend ipv6_used_list "[ip::contract [ip::prefix $addr]]/$mask" }
	    set addr [getIfcIPv4addr $node $iface]
	    if { $addr != "" } { lappend ipv4_used_list $addr }
	    set addr [getIfcMACaddr $node $iface]
	    if { $addr != "" } { lappend mac_used_list [getIfcMACaddr $node $iface] }
	}
    }

    # reverse order of pseudo peers/ifaces
    foreach link_id $link_list {
	set mirror_link_id [getLinkMirror $link_id]
	if { $mirror_link_id == "" } {
	    continue
	}

	lassign [getLinkPeers $link_id] peer1 peer2
	if { [getNodeMirror $peer1] != "" } {
	    continue
	}

	lassign [getLinkPeersIfaces $link_id] peer1_iface peer2_iface

	setLinkPeers $link_id "$peer2 $peer1"
	setLinkPeersIfaces $link_id "$peer2_iface $peer1_iface"
    }

    setToRunning "ipv4_used_list" $ipv4_used_list
    setToRunning "ipv6_used_list" $ipv6_used_list
    setToRunning "mac_used_list" $mac_used_list
}

#****f* nodecfg.tcl/newObjectId
# NAME
#   newObjectId -- new object Id
# SYNOPSIS
#   set obj_id [newObjectId $elem_list $prefix]
# FUNCTION
#   Returns the ID for a new object of with the defined $prefix. The ID is in
#   the form $prefix$number. $number is the first available number from the
#   given list (all the elements of the list share the same prefix and the list
#   does not need to be sorted beforehand).
# INPUTS
#   * elem_list -- the list of existing elements
#   * prefix -- the prefix of the new object.
# RESULT
#   * obj_id -- object ID in the form $prefix$number
#****
proc newObjectId { elem_list prefix } {
    set len [llength $elem_list]
    if { $len == 0 } {
	return ${prefix}0
    }

    set sorted_list [lsort -dictionary $elem_list]

    # Initial interval - the start to the middle of the list
    set start 0
    set end [expr $len - 1]
    set mid [expr $len / 2]
    set lastmid -1

    if { "$prefix$end" == [lindex $sorted_list end] } {
	return $prefix[expr $end + 1]
    }

    while { $mid != $lastmid } {
	set val [lindex $sorted_list $mid]
	set idx [lsearch -dictionary -bisect $sorted_list $val]
	regsub $prefix $val "" val

	if { [expr $mid < $val] } {
	    set end $mid
	} else {
	    set start [expr $mid + 1]
	}

	set lastmid $mid
	set mid [expr ($start + $end ) / 2]
    }

    return $prefix$mid
}

#########################################################################

proc loadCfgJson { json_cfg } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    set dict_cfg [json::json2dict $json_cfg]

    setToRunning "canvas_list" [getCanvasList]
    setToRunning "node_list" [getNodeList]
    setToRunning "link_list" [getLinkList]
    setToRunning "annotation_list" [getAnnotationList]
    setToRunning "image_list" [getImageList]

    applyOptions

    # Speeding up auto renumbering of MAC, IPv4 and IPv6 addresses by remembering
    # used addresses in lists.
    set ipv4_used_list {}
    set ipv6_used_list {}
    set mac_used_list {}
    foreach node_id [getFromRunning "node_list"] {
	foreach iface [ifcList $node_id] {
	    lassign [split [getIfcIPv6addr $node_id $iface] "/"] addr mask
	    if { $addr != "" } { lappend ipv6_used_list "[ip::contract [ip::prefix $addr]]/$mask" }
	    set addr [getIfcIPv4addr $node_id $iface]
	    if { $addr != "" } { lappend ipv4_used_list $addr }
	    lappend mac_used_list [getIfcMACaddr $node_id $iface]
	}
    }

    setToRunning ipv4_used_list $ipv4_used_list
    setToRunning ipv6_used_list $ipv6_used_list
    setToRunning mac_used_list $mac_used_list

    return $dict_cfg
}

proc handleVersionMismatch { cfg_version file_name } {
    global CFG_VERSION

    if { $cfg_version == "" } {
	puts "Loading legacy .imn configuration..."
	puts "This configuration will be saved as a new version (version $CFG_VERSION)."

	set fileId [open $file_name r]
	set cfg ""
	foreach entry [read $fileId] {
	    lappend cfg $entry
	}
	close $fileId

	loadCfgLegacy $cfg
	setToRunning "current_file" $file_name
    } elseif { $cfg_version < $CFG_VERSION } {
	puts "Loading older .imn configuration (version $cfg_version)..."
	puts "This configuration will be saved as a new version ($CFG_VERSION)."
	puts "Please check if everything is loaded/saved successfully."
    } elseif { $cfg_version > $CFG_VERSION } {
	puts "Your IMUNES version is too old for this configuration (version $cfg_version > $CFG_VERSION)."
	puts "Please install newer IMUNES or risk corrupting your topology."
    }
}

# use this to read IMUNES json file
proc readCfgJson { fname } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    set fd [open $fname r]
    set json_cfg [read $fd]
    close $fd

    set dict_cfg [loadCfgJson $json_cfg]
    handleVersionMismatch [getOption "version"] $fname

    return $dict_cfg
}

proc saveCfgJson { fname } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    saveOptions

    set json_cfg [createJson "dictionary" $dict_cfg]
    set fd [open $fname w+]
    puts $fd $json_cfg
    close $fd

    return $json_cfg
}

#########################################################################

proc getWithDefault { default_value dictionary args } {
    try {
	return [dict get $dictionary {*}$args]
    } on error {} {
	return $default_value
    }
}

proc dictGet { dictionary args } {
    try {
	dict get $dictionary {*}$args
    } on error {} {
	return {}
    } on ok retv {
	return $retv
    }
}

proc dictSet { dictionary args } {
    try {
	dict set dictionary {*}$args
    } on error {} {
	return $dictionary
    } on ok retv {
	return $retv
    }
}

proc dictLappend { dictionary args } {
    try {
	dict lappend dictionary {*}$args
    } on error {} {
	return $dictionary
    } on ok retv {
	return $retv
    }
}

proc dictUnset { dictionary args } {
    try {
	dict unset dictionary {*}$args
    } on error {} {
	return $dictionary
    } on ok retv {
	return $retv
    }
}

proc cfgGet { args } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    return [dictGet $dict_cfg {*}$args]
}

proc cfgGetWithDefault { default_value args } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    return [getWithDefault $default_value $dict_cfg {*}$args]
}

proc cfgSet { args } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    if { [lindex $args end] in {{} ""} } {
	for {set i 1} {$i < [llength $args]} {incr i} {
	    set dict_cfg [dictUnset $dict_cfg {*}[lrange $args 0 end-$i]]

	    set new_upper [dictGet $dict_cfg {*}[lrange $args 0 end-[expr $i+1]]]
	    if { $new_upper != "" } {
		break
	    }
	}
    } else {
	set dict_cfg [dictSet $dict_cfg {*}$args]
    }

    return $dict_cfg
}

# to forcefully set empty values to a dictionary key
proc cfgSetEmpty { args } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    set dict_cfg [dictSet $dict_cfg {*}$args]
}

# to forcefully set empty values to a dictionary key
proc _cfgSetEmpty { node_cfg args } {
    set node_cfg [dictSet $node_cfg {*}$args]

    return $node_cfg
}

proc cfgLappend { args } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    set dict_cfg [dictLappend $dict_cfg {*}$args]

    return $dict_cfg
}

proc cfgUnset { args } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    for {set i 0} {$i < [llength $args]} {incr i} {
	set dict_cfg [dictUnset $dict_cfg {*}[lrange $args 0 end-$i]]

	set new_upper [dictGet $dict_cfg {*}[lrange $args 0 end-[expr $i+1]]]
	if { $new_upper != "" } {
	    break
	}
    }

    return $dict_cfg
}

proc _cfgUnset { node_cfg args } {
    for {set i 0} {$i < [llength $args]} {incr i} {
	set node_cfg [dictUnset $node_cfg {*}[lrange $args 0 end-$i]]

	set new_upper [dictGet $node_cfg {*}[lrange $args 0 end-[expr $i+1]]]
	if { $new_upper != "" } {
	    break
	}
    }

    return $node_cfg
}

proc clipboardGet { args } {
    upvar 0 ::cf::clipboard::dict_cfg dict_cfg

    return [dictGet $dict_cfg {*}$args]
}

proc clipboardSet { args } {
    upvar 0 ::cf::clipboard::dict_cfg dict_cfg

    if { [lindex $args end] in {{} ""} } {
	for {set i 1} {$i < [llength $args]} {incr i} {
	    set dict_cfg [dictUnset $dict_cfg {*}[lrange $args 0 end-$i]]

	    set new_upper [dictGet $dict_cfg {*}[lrange $args 0 end-[expr $i+1]]]
	    if { $new_upper != "" } {
		break
	    }
	}
    } elseif { [dict exists $dict_cfg {*}$args] } {
	set dict_cfg [dictUnset $dict_cfg {*}$args]
    } else {
	set dict_cfg [dictSet $dict_cfg {*}$args]
    }

    return $dict_cfg
}

proc clipboardLappend { args } {
    upvar 0 ::cf::clipboard::dict_cfg dict_cfg

    set dict_cfg [dictLappend $dict_cfg {*}$args]

    return $dict_cfg
}

proc clipboardUnset { args } {
    upvar 0 ::cf::clipboard::dict_cfg dict_cfg

    for {set i 0} {$i < [llength $args]} {incr i} {
	set dict_cfg [dictUnset $dict_cfg {*}[lrange $args 0 end-$i]]

	set new_upper [dictGet $dict_cfg {*}[lrange $args 0 end-[expr $i+1]]]
	if { $new_upper != "" } {
	    break
	}
    }

    return $dict_cfg
}

#########################################################################

proc getFromRunning { key { config "" } } {
    if { $config == "" } {
	set config [set ::curcfg]
    }
    upvar 0 ::cf::${config}::dict_run dict_run

    return [dictGet $dict_run $key]
}

proc setToRunning { key value } {
    upvar 0 ::cf::[set ::curcfg]::dict_run dict_run

    set dict_run [dictSet $dict_run $key $value]

    return $dict_run
}

proc unsetRunning { key } {
    upvar 0 ::cf::[set ::curcfg]::dict_run dict_run

    set dict_run [dictUnset $dict_run $key]

    return $dict_run
}

proc lappendToRunning { key value } {
    upvar 0 ::cf::[set ::curcfg]::dict_run dict_run

    set dict_run [dictLappend $dict_run $key $value]

    return $dict_run
}

proc getFromUndolog { undolevel } {
    upvar 0 ::cf::[set ::curcfg]::dict_run dict_run

    return [dictGet $dict_run "undolog" $undolevel]
}

proc setToUndolog { undolevel { value "" } } {
    upvar 0 ::cf::[set ::curcfg]::dict_run dict_run
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    if { $value == "" } {
	set value $dict_cfg
    }

    set dict_run [dictSet $dict_run "undolog" $undolevel $value]

    return $dict_run
}

#########################################################################

proc getOption { property } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    return [dictGet $dict_cfg "options" $property]
}

proc setOption { property value } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    set dict_cfg [dictSet $dict_cfg "options" $property $value]

    return $dict_cfg
}

proc unsetOption { property } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    set dict_cfg [dictUnset $dict_cfg "options" $property]

    return $dict_cfg
}

proc getCanvasList { } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    return [dict keys [dictGet $dict_cfg "canvases"]]
}

proc getCanvasProperty { canvas_id property } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    return [dictGet $dict_cfg "canvases" $canvas_id $property]
}

proc getNodeList { } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    return [dict keys [dictGet $dict_cfg "nodes"]]
}

proc getNodeProperty { node_id property } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    return [dictGet $dict_cfg "nodes" $node_id $property]
}

proc getLinkList { } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    return [dict keys [dictGet $dict_cfg "links"]]
}

proc getLinkProperty { link_id property } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    return [dictGet $dict_cfg "links" $link_id $property]
}

proc getAnnotationList { } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    return [dict keys [dictGet $dict_cfg "annotations"]]
}

proc getAnnotationProperty { annotation_id property } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    return [dictGet $dict_cfg "annotations" $annotation_id $property]
}

proc getImageList { } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    return [dict keys [dictGet $dict_cfg "images"]]
}

proc getImageProperty { image_id property } {
    upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

    return [dictGet $dict_cfg "images" $image_id $property]
}

#########################################################################

# returns the type of key 'key_name' (defined by values it hold)
# * dictionary - holds objects with unique keys
# * object - regular 'key-value' pair
# * array - JSON array
# * inner_dictionary - dictionary inside of an object
proc getJsonType { key_name } {
    if { $key_name in "canvases nodes links annotations images custom_configs ipsec_configs logifaces ifaces" } {
	return "dictionary"
    } elseif { $key_name in "custom_config croutes4 croutes6 ipv4_addrs ipv6_addrs services events tayga_mappings" } {
	return "array"
    } elseif { $key_name in "vlan ipsec nat64 packgen packets" } {
	return "inner_dictionary"
    }

    return "object"
}

proc createJson { value_type dictionary } {
    set retv {}

    switch -exact -- $value_type {
	"dictionary" {
	    set retv [json::write object {*}[dict map {k v} $dictionary {
		createJson [getJsonType $k] $v
	    }]]
	}
	"object" {
	    set retv [json::write object {*}[dict map {k v} $dictionary {
		set k_type [getJsonType $k]
		if { $k_type in "dictionary array" } {
		    createJson $k_type $v
		} elseif { $k_type in "inner_dictionary" } {
		    createJson "object" $v
		} else {
		    ::json::write string $v
		}
	    }]]
	}
	"array" {
	    set json_list {}
	    foreach line $dictionary {
		lappend json_list [::json::write string $line]
	    }

	    set retv [::json::write array {*}$json_list]
	}
	"inner_dictionary" {
	    set retv [createJson "object" $dictionary]
	}
    }

    return $retv
}
