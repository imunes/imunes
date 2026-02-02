proc addMenu { menu_root menu_label menu_command menu_enabled { hide_disabled "" } } {
	if { $menu_enabled } {
		$menu_root add command \
			-label "$menu_label" \
			-command "$menu_command"
	} elseif { $hide_disabled == "" } {
		$menu_root add command \
			-label "$menu_label" \
			-state disabled
	}
}

proc addCascadeMenu { menu_root menu_label menu_submenu menu_enabled { hide_disabled "" } } {
	$menu_submenu delete 0 end

	if { $menu_enabled } {
		$menu_root add cascade \
			-label "$menu_label" \
			-menu "$menu_submenu"
	} elseif { $hide_disabled == "" } {
		$menu_root add cascade \
			-label "$menu_label" \
			-state disabled
	}
}

set available_menus {}

proc menu_addSeparator { node_id root_menu } {
	global available_menus
	lappend available_menus "menu_addSeparator"

	$root_menu add separator
}

proc menu_mergeNodes { node_id root_menu } {
	global available_menus
	lappend available_menus "menu_mergeNodes"

	#
	# Merge two pseudo nodes / links
	#
	set node_mirror_id [getNodeMirror $node_id]
	lassign [nodeFromPseudoNode $node_id] real_node1_id -
	lassign [nodeFromPseudoNode $node_mirror_id] real_node2_id -

	set menu_enabled [expr {
		$real_node1_id != $real_node2_id &&
		[getNodeCanvas $node_mirror_id] == [getFromRunning_gui "curcanvas"]
	}]
	addMenu $root_menu \
		"Merge" \
		"mergeNodeGUI $node_id" \
		$menu_enabled
}

proc menu_selectAdjacent { node_id root_menu } {
	global available_menus
	lappend available_menus "menu_selectAdjacent"

	#
	# Select adjacent
	#
	addMenu $root_menu \
		"Select adjacent" \
		"selectAdjacent" \
		"true"
}

proc menu_configureNode { node_id root_menu } {
	global available_menus
	lappend available_menus "menu_configureNode"

	#
	# Configure node
	#
	addMenu $root_menu \
		"Configure" \
		"nodeConfigGUI $node_id" \
		"true"
}

proc menu_nodeIcons { node_id root_menu } {
	global available_menus
	lappend available_menus "menu_nodeIcons"

	#
	# Node icon preferences
	#
	set sub_menu "$root_menu.icon"
	addCascadeMenu $root_menu \
		"Node icon" \
		$sub_menu \
		"true"

	addMenu $sub_menu \
		"Change node icon" \
		"changeIconPopup" \
		"true"

	addMenu $sub_menu \
		"Set default icon" \
		"setDefaultIcon" \
		"true"
}

proc menu_createLink { node_id root_menu } {
	global available_menus
	lappend available_menus "menu_createLink"

	#
	# Create a new link - can be between different canvases
	#
	set sub_menu "$root_menu.connect"
	addCascadeMenu $root_menu \
		"Create link to" \
		$sub_menu \
		"true"

	set selected_sub_menu "$sub_menu.selected"
	destroy $selected_sub_menu
	menu $selected_sub_menu -tearoff 0

	addCascadeMenu $sub_menu \
		"Selected" \
		$selected_sub_menu \
		"true"

	# Selected sub menu
	addMenu $selected_sub_menu \
		"Chain" \
		{ P [selectedRealNodes] } \
		"true"

	set tmp_command [list apply {
		{ node_id } {
			Kb $node_id [removeFromList [selectedRealNodes] $node_id]
		}
	} \
		$node_id
	]
	addMenu $selected_sub_menu \
		"Star" \
		$tmp_command \
		"true"

	addMenu $selected_sub_menu \
		"Cycle" \
		{ C [selectedRealNodes] } \
		"true"

	addMenu $selected_sub_menu \
		"Clique" \
		{ K [selectedRealNodes] } \
		"true"

	set tmp_command {
		set real_nodes [selectedRealNodes]
		R $real_nodes [expr [llength $real_nodes] - 1]
	}
	addMenu $selected_sub_menu \
		"Random" \
		$tmp_command \
		"true"

	$sub_menu add separator

	# Canvas sub menu
	foreach canvas_id [getFromRunning_gui "canvas_list"] {
		set canvas_sub_menu "$sub_menu.$canvas_id"
		destroy $canvas_sub_menu
		menu $canvas_sub_menu -tearoff 0

		addCascadeMenu $sub_menu \
			"[getCanvasName $canvas_id]" \
			$canvas_sub_menu \
			"true"
	}

	foreach peer_id [getFromRunning "node_list"] {
		set canvas_id [getNodeCanvas $peer_id]
		set canvas_sub_menu "$sub_menu.$canvas_id"
		if { $node_id == $peer_id } {
			addMenu $canvas_sub_menu \
				"[getNodeName $peer_id]" \
				"newLinkGUI $node_id $peer_id" \
				"true"
		} elseif { ! [isPseudoNode $peer_id] } {
			addMenu $canvas_sub_menu \
				"[getNodeName $peer_id]" \
				"connectWithNode \"[selectedRealNodes]\" $peer_id" \
				"true"
		}
	}
}

proc menu_connectIface { node_id root_menu } {
	global available_menus
	lappend available_menus "menu_connectIface"

	#
	# Connect interface - can be between different canvases
	#
	$root_menu.connect_iface delete 0 end
	$root_menu add cascade -label "Connect interface" \
		-menu $root_menu.connect_iface

	foreach this_iface_id [concat "new_iface" [ifcList $node_id]] {
		if { [getIfcLink $node_id $this_iface_id] != "" } {
			continue
		}

		set from_iface_id $this_iface_id
		if { [getIfcType $node_id $this_iface_id] == "stolen" } {
			if { [getNodeType $node_id] != "rj45" } {
				continue
			}

			set from_iface_label "$this_iface_id - \[[getIfcName $node_id $this_iface_id]\]"
		} else {
			set from_iface_label [getIfcName $node_id $this_iface_id]
		}
		if { $this_iface_id == "new_iface" } {
			set from_iface_id {}
			set from_iface_label "Create new interface"
		}

		destroy $root_menu.connect_iface.$this_iface_id
		menu $root_menu.connect_iface.$this_iface_id -tearoff 0
		$root_menu.connect_iface add cascade -label $from_iface_label \
			-menu $root_menu.connect_iface.$this_iface_id

		foreach canvas_id [getFromRunning_gui "canvas_list"] {
			destroy $root_menu.connect_iface.$this_iface_id.$canvas_id
			menu $root_menu.connect_iface.$this_iface_id.$canvas_id -tearoff 0
			$root_menu.connect_iface.$this_iface_id add cascade -label [getCanvasName $canvas_id] \
				-menu $root_menu.connect_iface.$this_iface_id.$canvas_id
		}

		foreach peer_id [getFromRunning "node_list"] {
			set canvas_id [getNodeCanvas $peer_id]
			if { ! [isPseudoNode $peer_id] } {
				destroy $root_menu.connect_iface.$this_iface_id.$canvas_id.$peer_id
				menu $root_menu.connect_iface.$this_iface_id.$canvas_id.$peer_id -tearoff 0
				$root_menu.connect_iface.$this_iface_id.$canvas_id add cascade -label [getNodeName $peer_id] \
					-menu $root_menu.connect_iface.$this_iface_id.$canvas_id.$peer_id

				foreach other_iface_id [concat "new_peer_iface" [ifcList $peer_id]] {
					if { $node_id == $peer_id && $this_iface_id == $other_iface_id } {
						continue
					}

					if { [getIfcLink $peer_id $other_iface_id] != "" } {
						continue
					}

					set to_iface_id $other_iface_id
					if { [getIfcType $peer_id $other_iface_id] == "stolen" } {
						if { [getNodeType $peer_id] != "rj45" } {
							continue
						}

						set to_iface_label "$other_iface_id - \[[getIfcName $peer_id $other_iface_id]\]"
					} else {
						set to_iface_label [getIfcName $peer_id $other_iface_id]
					}
					if { $other_iface_id == "new_peer_iface" } {
						set to_iface_id {}
						set to_iface_label "Create new interface"
					}

					$root_menu.connect_iface.$this_iface_id.$canvas_id.$peer_id add command \
						-label $to_iface_label \
						-command "newLinkWithIfacesGUI $node_id \"$from_iface_id\" $peer_id \"$to_iface_id\""
				}
			}
		}
	}
}

proc menu_moveTo { node_id root_menu } {
	global available_menus
	lappend available_menus "menu_moveTo"

	#
	# Move to another canvas
	#
	$root_menu.moveto delete 0 end
	$root_menu add cascade \
		-label "Move to" \
		-menu $root_menu.moveto

	$root_menu.moveto add command \
		-label "Canvas:" -state disabled

	foreach canvas_id [getFromRunning_gui "canvas_list"] {
		if { $canvas_id != [getFromRunning_gui "curcanvas"] } {
			$root_menu.moveto add command \
				-label [getCanvasName $canvas_id] \
				-command "moveToCanvas $canvas_id"
		} else {
			$root_menu.moveto add command \
				-label [getCanvasName $canvas_id] \
				-state disabled
		}
	}
}

proc menu_deleteSelection { node_id root_menu } {
	global available_menus
	lappend available_menus "menu_deleteSelection"

	#
	# Delete selection
	#
	set menu_enabled [expr {
		[getFromRunning "oper_mode"] == "edit" ||
		[getFromRunning "stop_sched"]
	}]
	addMenu $root_menu \
		"Delete" \
		"deleteSelection" \
		$menu_enabled
}

proc menu_deleteSelectionKeepIfaces { node_id root_menu } {
	global available_menus
	lappend available_menus "menu_deleteSelectionKeepIfaces"

	#
	# Delete selection (keep linked interfaces)
	#
	set menu_enabled [expr {
		[getFromRunning "oper_mode"] == "edit" ||
		[getFromRunning "stop_sched"]
	}]
	addMenu $root_menu \
		"Delete (keep interfaces)" \
		"deleteSelection 1" \
		$menu_enabled
}

proc menu_autoExecute { node_id root_menu } {
	global available_menus
	lappend available_menus "menu_autoExecute"

	#
	# Enable/disable 'auto execute'
	#
	if { $node_id in [getFromRunning "no_auto_execute_nodes"] } {
		$root_menu add command \
			-label "Enable auto execute" \
			-command "removeFromRunning \"no_auto_execute_nodes\" \[selectedNodes\]"
	} else {
		set tmp_command {
			foreach node_id [selectedNodes] {
				if { $node_id ni [getFromRunning "no_auto_execute_nodes"] } {
					lappendToRunning "no_auto_execute_nodes" $node_id
				}
			}
		}
		$root_menu add command \
			-label "Disable auto execute" \
			-command $tmp_command
	}
}

proc menu_transformTo { node_id root_menu } {
	global available_menus
	lappend available_menus "menu_transformTo"

	#
	# Transform
	#
	set menu_enabled [expr {
		[getNodeType $node_id] in "router pc host"
	}]

	set sub_menu "$root_menu.transform"
	addCascadeMenu $root_menu \
		"Transform to" \
		$sub_menu \
		$menu_enabled \
		"hide"

	foreach to_type "Router PC Host" {
		addMenu $sub_menu \
			"$to_type" \
			"transformNodesGUI \"[selectedRealNodes]\" [string tolower $to_type]" \
			"true"
	}
}

proc menu_services { node_id root_menu } {
	global available_menus
	lappend available_menus "menu_services"

	#
	# Services menu
	#
	set menu_enabled [expr {
		[isRunningNode $node_id]
	}]

	set sub_menu "$root_menu.services"
	addCascadeMenu $root_menu \
		"Services" \
		$sub_menu \
		$menu_enabled

	if { $menu_enabled } {
		global all_services_list

		foreach service $all_services_list {
			set service_menu $sub_menu.$service
			if { ! [winfo exists $service_menu] } {
				menu $service_menu -tearoff 0
			} else {
				$service_menu delete 0 end
			}

			addCascadeMenu $sub_menu \
				"$service" \
				$service_menu \
				$menu_enabled

			foreach action { "Start" "Stop" "Restart" } {
				addMenu $service_menu \
					"$action" \
					"$service.[string tolower $action] $node_id" \
					"true"
			}
		}
	}
}

proc menu_nodeExecute { node_id root_menu } {
	global available_menus
	lappend available_menus "menu_nodeExecute"

	set tmp_command [list apply {
		{ action } {
			foreach node_id [selectedNodes] {
				if { [getNodeType $node_id] == "pseudo" } {
					continue
				}

				if {
					! [isRunningNode $node_id] &&
					($action in "node_destroy" ||
					$action in "node_config node_unconfig node_reconfig" ||
					$action in "ifaces_config ifaces_unconfig ifaces_reconfig")
				} {
					continue
				}

				switch -exact -- $action {
					"node_create" {
						if { ! [isRunningNode $node_id] } {
							trigger_nodeCreate $node_id
						}
					}
					"node_destroy" {
						trigger_nodeDestroy $node_id
					}
					"node_recreate" {
						trigger_nodeRecreate $node_id
					}
					"node_config" {
						trigger_nodeConfig $node_id
					}
					"node_unconfig" {
						trigger_nodeUnconfig $node_id
					}
					"node_reconfig" {
						trigger_nodeReconfig $node_id
					}
					"ifaces_config" {
						foreach iface_id [allIfcList $node_id] {
							trigger_ifaceConfig $node_id $iface_id
						}
					}
					"ifaces_unconfig" {
						foreach iface_id [allIfcList $node_id] {
							trigger_ifaceUnconfig $node_id $iface_id
						}
					}
					"ifaces_reconfig" {
						foreach iface_id [allIfcList $node_id] {
							trigger_ifaceReconfig $node_id $iface_id
						}
					}
				}
			}

			if { [getFromRunning "stop_sched"] } {
				redeployCfg
			}

			redrawAll
		}
	} \
		""
	]

	set menu_enabled [expr {
		[getFromRunning "oper_mode"] == "exec"
	}]

	#
	# Node execution menu
	#
	set sub_menu "$root_menu.node_execute"
	$sub_menu delete 0 end

	if { $menu_enabled } {
		addCascadeMenu $root_menu \
			"Node execution" \
			$sub_menu \
			[getFromRunning "auto_execution"]

		set actions [dict create]
		dict set actions "Start"	"node_create"
		dict set actions "Stop"		"node_destroy"
		dict set actions "Restart"	"node_recreate"

		dict for {label action} $actions {
			addMenu $sub_menu \
				"$label" \
				[lreplace $tmp_command end end $action] \
				"true"
		}
	}

	#
	# Node config menu
	#
	set sub_menu "$root_menu.node_config"
	$sub_menu delete 0 end

	if { $menu_enabled } {
		addCascadeMenu $root_menu \
			"Node configuration" \
			$sub_menu \
			[getFromRunning "auto_execution"]

		set actions [dict create]
		dict set actions "Configure"	"node_config"
		dict set actions "Unconfigure"	"node_unconfig"
		dict set actions "Reconfigure"	"node_reconfig"

		dict for {label action} $actions {
			addMenu $sub_menu \
				"$label" \
				[lreplace $tmp_command end end $action] \
				"true"
		}
	}

	#
	# Ifaces config menu
	#
	set sub_menu "$root_menu.ifaces_config"
	$sub_menu delete 0 end

	if { $menu_enabled } {
		addCascadeMenu $root_menu \
			"Ifaces configuration" \
			$sub_menu \
			[getFromRunning "auto_execution"]

		set actions [dict create]
		dict set actions "Configure"	"ifaces_config"
		dict set actions "Unconfigure"	"ifaces_unconfig"
		dict set actions "Reconfigure"	"ifaces_reconfig"

		dict for {label action} $actions {
			addMenu $sub_menu \
				"$label" \
				[lreplace $tmp_command end end $action] \
				"true"
		}
	}
}

proc menu_nodeSettings { node_id root_menu } {
	global available_menus
	lappend available_menus "menu_nodeSettings"

	set menu_enabled [expr {
		[getFromRunning "oper_mode"] == "exec"
	}]

	#
	# Node settings
	#
	set sub_menu "$root_menu.sett"
	$sub_menu delete 0 end

	addCascadeMenu $root_menu \
		"Settings" \
		$sub_menu \
		"true"

	#
	# Import Running Configuration
	#
	addMenu $sub_menu \
		"Import Running Configuration" \
		"fetchNodesConfiguration" \
		$menu_enabled \
		"hide"

	#
	# Remove IPv4/IPv6 addresses
	#
	addMenu $sub_menu \
		"Remove IPv4 addresses" \
		"removeIPv4Nodes \[selectedNodes\] *" \
		"true"

	addMenu $sub_menu \
		"Remove IPv6 addresses" \
		"removeIPv6Nodes \[selectedNodes\] *" \
		"true"
}

proc menu_ifacesSettings { node_id root_menu } {
	global available_menus
	lappend available_menus "menu_ifacesSettings"

	set menu_enabled [expr {
		[getFromRunning "oper_mode"] == "exec"
	}]

	#
	# Interface settings
	#
	set sub_menu "$root_menu.iface_settings"
	$sub_menu delete 0 end

	addCascadeMenu $root_menu \
		"Interface settings" \
		$sub_menu \
		"true"

	set sorted_ifaces {}
	foreach iface_type "phys stolen" {
		set ifaces [getIfacesNamesByType $node_id $iface_type]
		if { $ifaces != {} } {
			lappend sorted_ifaces {*}[lsort -dictionary $ifaces]
		}
	}

	foreach iface_name $sorted_ifaces {
		set iface_id [ifaceIdFromName $node_id $iface_name]
		set iface_menu $sub_menu.$iface_id
		if { ! [winfo exists $iface_menu] } {
			menu $iface_menu -tearoff 0
		} else {
			$iface_menu delete 0 end
		}

		set iface_label $iface_name
		if { [getIfcType $node_id $iface_id] == "stolen" } {
			set iface_label "\[$iface_label\]"
		}

		addCascadeMenu $sub_menu \
			"$iface_label" \
			$iface_menu \
			"true"

		#
		# IP autorenumber
		#
		set tmp_command [list apply {
			{ node_id iface_id ip_version } {
				global main_canvas_elem

				if { [getFromRunning "cfg_deployed"] && [getFromRunning "auto_execution"] } {
					setToExecuteVars "terminate_cfg" [cfgGet]
				}

				switch -exact -- $ip_version {
					"ipv4" {
						set tmp [getActiveOption "IPv4autoAssign"]
						setGlobalOption "IPv4autoAssign" 1
						addressChangeDialog "ipv4" $node_id $iface_id
						setGlobalOption "IPv4autoAssign" $tmp
					}
					"ipv6" {
						set tmp [getActiveOption "IPv6autoAssign"]
						setGlobalOption "IPv6autoAssign" 1
						addressChangeDialog "ipv6" $node_id $iface_id
						setGlobalOption "IPv6autoAssign" $tmp
					}
				}

				if { [getFromRunning "stop_sched"] } {
					redeployCfg
				}

				$main_canvas_elem config -cursor left_ptr
			}
		} \
			$node_id \
			$iface_id \
			""
		]

		set sub4 [lindex [getSubnetAddrsByPrio "ipv4" $node_id $iface_id] 0]
		set sub6 [lindex [getSubnetAddrsByPrio "ipv6" $node_id $iface_id] 0]

		if { $sub4 == "" || $sub6 == "" } {
			foreach node_subnet_data [getSubnetIfaces $node_id $iface_id] {
				lassign $node_subnet_data prio subnet_node_id subnet_iface_id

				#skip current node
				if { $node_id == $subnet_node_id && $iface_id == $subnet_iface_id } {
					continue
				}

				set cur_addrs [getIfcIPv4addrs $subnet_node_id $subnet_iface_id]
				if { $sub4 == "" && $cur_addrs != {} } {
					set sub4 [lindex $cur_addrs 0]
				}

				set cur_addrs [getIfcIPv6addrs $subnet_node_id $subnet_iface_id]
				if { $sub6 == "" && $cur_addrs != {} } {
					set sub6 [lindex $cur_addrs 0]
				}

				if { $sub4 != "" && $sub6 != "" } {
					break
				}
			}
		}

		set actions [list \
			"Remove IPv4 addresses"		"removeIPv4Nodes $node_id {$node_id $iface_id}"	"true" \
			"Remove IPv6 addresses"		"removeIPv6Nodes $node_id {$node_id $iface_id}"	"true" \
			"IPv4 autorenumber"			"[lreplace $tmp_command end end "ipv4"]"		"true" \
			"IPv6 autorenumber"			"[lreplace $tmp_command end end "ipv6"]"		"true" \
			"Match IPv4 subnet ($sub4)"	"matchSubnet ipv4 $node_id $iface_id $sub4"		[expr { $sub4 != {} }] \
			"Match IPv6 subnet ($sub6)"	"matchSubnet ipv6 $node_id $iface_id $sub6"		[expr { $sub6 != {} }] \
			]

		foreach {action command enabled} $actions {
			addMenu $iface_menu \
				"$action" \
				"$command" \
				"$enabled"
		}
	}
}

proc menu_shellSelection { node_id root_menu } {
	global available_menus
	lappend available_menus "menu_shellSelection"

	set all_shells [invokeNodeProc $node_id "shellcmds"]

	set menu_enabled [expr {
		[isRunningNode $node_id] &&
		$all_shells != {}
	}]

	#
	# Shell selection
	#
	set sub_menu "$root_menu.shell"
	$sub_menu delete 0 end

	addCascadeMenu $root_menu \
		"Shell window" \
		$sub_menu \
		$menu_enabled

	if { $menu_enabled } {
		set existing_shells_cmds [existingShells $all_shells $node_id]
		set existing_shells [lmap cmd $existing_shells_cmds { lindex [split $cmd "/"] end }]

		foreach shell $all_shells {
			set cmd [lindex $existing_shells_cmds [lsearch -exact $existing_shells $shell]]
			addMenu $sub_menu \
				"$shell" \
				"spawnShell $node_id $cmd" \
				[expr {$shell in $existing_shells}] \
				"hide"
		}
	}
}

proc menu_wiresharkNode { node_id root_menu } {
	global available_menus
	lappend available_menus "menu_wiresharkNode"

	#
	# Wireshark
	#
	set wireshark_command ""
	foreach wireshark "wireshark wireshark-gtk wireshark-qt" {
		if { [checkForExternalApps $wireshark] == 0 } {
			set wireshark_command $wireshark
			break
		}
	}

	addMenu $root_menu \
		"Wireshark" \
		"captureOnExtIfc $node_id $wireshark_command" \
		[expr { $wireshark_command != "" }]
}

proc menu_tcpdumpNode { node_id root_menu } {
	global available_menus
	lappend available_menus "menu_tcpdumpNode"

	#
	# tcpdump
	#
	addMenu $root_menu \
		"tcpdump" \
		"captureOnExtIfc $node_id tcpdump" \
		[expr { [checkForExternalApps "tcpdump"] == 0 }]
}

proc menu_wiresharkIfaces { node_id root_menu } {
	global available_menus isOSlinux
	lappend available_menus "menu_wiresharkIfaces"

	set menu_enabled [expr {
		[isRunningNode $node_id]
	}]

	#
	# Wireshark
	#
	set sub_menu "$root_menu.wireshark"
	$sub_menu delete 0 end

	addCascadeMenu $root_menu \
		"Wireshark" \
		$sub_menu \
		$menu_enabled

	if { $menu_enabled } {
		if { $isOSlinux } {
			addMenu $sub_menu \
				"%any" \
				"startWiresharkOnNodeIfc $node_id any" \
				"true"
		}

		set sorted_ifaces {}
		foreach iface_type "lo phys vlan stolen" {
			set ifaces [getIfacesNamesByType $node_id $iface_type]
			if { $ifaces != {} } {
				lappend sorted_ifaces {*}[lsort -dictionary $ifaces]
			}
		}

		foreach iface_name $sorted_ifaces {
			set iface_id [ifaceIdFromName $node_id $iface_name]
			set iface_label "$iface_name"
			set addrs [getIfcIPv4addrs $node_id $iface_id]

			if { $addrs != {} } {
				set iface_label "$iface_label ([lindex $addrs 0]"
				if { [llength $addrs] > 1 } {
					set iface_label "$iface_label ...)"
				} else {
					set iface_label "$iface_label)"
				}
			}

			set addrs [getIfcIPv6addrs $node_id $iface_id]
			if { $addrs != {} } {
				set iface_label "$iface_label ([lindex $addrs 0]"
				if { [llength $addrs] > 1 } {
					set iface_label "$iface_label ...)"
				} else {
					set iface_label "$iface_label)"
				}
			}

			addMenu $sub_menu \
				"$iface_label" \
				"startWiresharkOnNodeIfc $node_id $iface_name" \
				[isRunningNodeIface $node_id $iface_id]
		}
	}
}

proc menu_tcpdumpIfaces { node_id root_menu } {
	global available_menus isOSlinux
	lappend available_menus "menu_tcpdumpIfaces"

	set menu_enabled [expr {
		[isRunningNode $node_id]
	}]

	#
	# tcpdump
	#
	set sub_menu "$root_menu.tcpdump"
	$sub_menu delete 0 end

	addCascadeMenu $root_menu \
		"tcpdump" \
		$sub_menu \
		$menu_enabled

	if { $menu_enabled } {
		if { $isOSlinux } {
			addMenu $sub_menu \
				"%any" \
				"startTcpdumpOnNodeIfc $node_id any" \
				"true"
		}

		set sorted_ifaces {}
		foreach iface_type "lo phys vlan stolen" {
			set ifaces [getIfacesNamesByType $node_id $iface_type]
			if { $ifaces != {} } {
				lappend sorted_ifaces {*}[lsort -dictionary $ifaces]
			}
		}

		foreach iface_name $sorted_ifaces {
			set iface_id [ifaceIdFromName $node_id $iface_name]
			set iface_label "$iface_name"
			set addrs [getIfcIPv4addrs $node_id $iface_id]
			if { $addrs != {} } {
				set iface_label "$iface_label ([lindex $addrs 0]"
				if { [llength $addrs] > 1 } {
					set iface_label "$iface_label ...)"
				} else {
					set iface_label "$iface_label)"
				}
			}

			set addrs [getIfcIPv6addrs $node_id $iface_id]
			if { $addrs != {} } {
				set iface_label "$iface_label ([lindex $addrs 0]"
				if { [llength $addrs] > 1 } {
					set iface_label "$iface_label ...)"
				} else {
					set iface_label "$iface_label)"
				}
			}

			addMenu $sub_menu \
				"$iface_label" \
				"startTcpdumpOnNodeIfc $node_id $iface_name" \
				[isRunningNodeIface $node_id $iface_id]
		}
	}
}

proc menu_browser { node_id root_menu } {
	global available_menus
	lappend available_menus "menu_browser"

	set menu_enabled [expr {
		[isRunningNode $node_id] &&
		[checkForExternalApps "startxcmd"] == 0 &&
		[checkForApplications $node_id "firefox"] == 0
	}]

	#
	# Sylpheed mail client
	#
	set x_cmd "firefox"
	set x_args "-no-remote -setDefaultBrowser about:blank"
	addMenu $root_menu \
		"Web browser" \
		"startXappOnNode $node_id \"$x_cmd $x_args\"" \
		$menu_enabled
}

proc menu_mailClient { node_id root_menu } {
	global available_menus
	lappend available_menus "menu_mailClient"

	set menu_enabled [expr {
		[isRunningNode $node_id] &&
		[checkForExternalApps "startxcmd"] == 0 &&
		[checkForApplications $node_id "sylpheed"] == 0
	}]

	#
	# Sylpheed mail client
	#
	set x_cmd "G_FILENAME_ENCODING=UTF-8 sylpheed"
	set x_args ""
	addMenu $root_menu \
		"Mail client" \
		"startXappOnNode $node_id \"$x_cmd $x_args\"" \
		$menu_enabled
}
