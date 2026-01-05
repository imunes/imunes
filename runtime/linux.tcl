global VROOT_MASTER ULIMIT_FILE ULIMIT_PROC
set VROOT_MASTER "imunes/template"
set ULIMIT_FILE "1024:16384"
set ULIMIT_PROC "1024:16384"

#****f* linux.tcl/writeDataToNodeFile
# NAME
#   writeDataToNodeFile -- write data to virtual node
# SYNOPSIS
#   writeDataToNodeFile $node_id $path $data
# FUNCTION
#   Writes data to a file on the specified virtual node.
# INPUTS
#   * node_id -- virtual node id
#   * path -- path to file in node
#   * data -- data to write
#****
proc writeDataToNodeFile { node_id path data } {
	set docker_id "[getFromRunning "eid"].$node_id"

	if { [catch { rexec docker inspect -f "{{.GraphDriver.Data.MergedDir}}" $docker_id } node_dir] } {
		if { [catch { rexec docker inspect -f '{{.State.Pid}}' $docker_id } node_pid] } {
			return
		}

		if { $node_pid == 0 } {
			return
		}

		set node_dir "/proc/$node_pid/root"
	} elseif { [string match "*No such object:*" $node_dir] } {
		return
	}

	writeDataToFile $node_dir/$path $data
}

#****f* linux.tcl/execCmdNode
# NAME
#   execCmdNode -- execute command on virtual node
# SYNOPSIS
#   execCmdNode $node_id $cmd
# FUNCTION
#   Executes a command on a virtual node and returns the output.
# INPUTS
#   * node_id -- virtual node id
#   * cmd -- command to execute
# RESULT
#   * returns the execution output
#****
proc execCmdNode { node_id cmd } {
	catch { eval [concat "rexec docker exec " [getFromRunning "eid"].$node_id $cmd] } output

	return $output
}

#****f* linux.tcl/execCmdNodeBkg
# NAME
#   execCmdNodeBkg -- execute command on virtual node
# SYNOPSIS
#   execCmdNodeBkg $node_id $cmd
# FUNCTION
#   Executes a command on a virtual node (in the background).
# INPUTS
#   * node_id -- virtual node id
#   * cmd -- command to execute
#****
proc execCmdNodeBkg { node_id cmd } {
	pipesExec "docker exec -d [getFromRunning "eid"].$node_id sh -c '$cmd'" "hold"
}

#****f* linux.tcl/checkForExternalApps
# NAME
#   checkForExternalApps -- check whether external applications exist
# SYNOPSIS
#   checkForExternalApps $app_list
# FUNCTION
#   Checks whether a list of applications exist on the machine running IMUNES
#   by using the which command.
# INPUTS
#   * app_list -- list of applications
# RESULT
#   * returns 0 if the applications exist, otherwise it returns 1.
#****
proc checkForExternalApps { app_list } {
	foreach app $app_list {
		set cmds "command -v $app"
		set status [ catch { exec sh -c $cmds } err ]
		if { $status } {
			return 1
		}
	}

	return 0
}

#****f* linux.tcl/checkForApplications
# NAME
#   checkForApplications -- check whether applications exist
# SYNOPSIS
#   checkForApplications $node_id $app_list
# FUNCTION
#   Checks whether a list of applications exist on the virtual node by using
#   the 'command' command.
# INPUTS
#   * node_id -- virtual node id
#   * app_list -- list of applications
# RESULT
#   * returns 0 if the applications exist, otherwise it returns 1.
#****
proc checkForApplications { node_id app_list } {
	set private_ns [invokeNodeProc $node_id "getPrivateNs" [getFromRunning "eid"] $node_id]
	set os_cmd "docker exec $private_ns sh -c"

	foreach app $app_list {
		set os_cmd "$os_cmd 'command -v $app'"
		set status [ catch { rexec {*}$os_cmd } err ]
		if { $status } {
			return 1
		}
	}

	return 0
}

#****f* linux.tcl/startWiresharkOnNodeIfc
# NAME
#   startWiresharkOnNodeIfc -- start wireshark on an interface
# SYNOPSIS
#   startWiresharkOnNodeIfc $node_id $iface_name
# FUNCTION
#   Start Wireshark on a virtual node on the specified interface.
# INPUTS
#   * node_id -- virtual node id
#   * iface_name -- virtual node interface
#****
proc startWiresharkOnNodeIfc { node_id iface_name } {
	global remote rcmd escalation_comm

	set eid [getFromRunning "eid"]

	if {
		$remote == "" &&
		[checkForExternalApps "startxcmd"] == 0 &&
		[checkForApplications $node_id "wireshark"] == 0 &&
		[invokeNodeProc $node_id "virtlayer"] == "VIRTUALIZED"
	} {
		startXappOnNode $node_id "wireshark -ki $iface_name"
	} else {
		set wireshark_comm ""
		foreach wireshark "wireshark wireshark-gtk wireshark-qt" {
			if { [checkForExternalApps $wireshark] == 0 } {
				set wireshark_comm $wireshark
				break
			}
		}

		if { $remote != "" } {
			set wireshark_comm [concat $escalation_comm $wireshark_comm]
		}

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		set os_cmd "docker exec $private_ns"

		if { $wireshark_comm != "" } {
			if { $remote != "" } {
				exec -- echo -e "$os_cmd tcpdump -s 0 -U -w - -i $iface_name 2>/dev/null" | {*}$rcmd | \
					{*}$wireshark_comm -o "gui.window_title:$iface_name@[getNodeName $node_id] ($eid)" -k -i - &
			} else {
				exec {*}$os_cmd tcpdump -s 0 -U -w - -i $iface_name 2>/dev/null |\
					{*}$wireshark_comm -o "gui.window_title:$iface_name@[getNodeName $node_id] ($eid)" -k -i - &
			}
		} else {
			tk_dialog .dialog1 "IMUNES error" \
				"IMUNES could not find an installation of Wireshark.\
				If you have Wireshark installed, submit a bug report." \
				info 0 Dismiss
		}
	}
}

#****f* linux.tcl/startXappOnNode
# NAME
#   startXappOnNode -- start X application in a virtual node
# SYNOPSIS
#   startXappOnNode $node_id $app
# FUNCTION
#   Start X application on virtual node
# INPUTS
#   * node_id -- virtual node id
#   * app -- application to start
#****
proc startXappOnNode { node_id app } {
	global debug remote

	if { $remote != "" } {
		sputs stderr "Running X applications in nodes on remote host is not supported."

		return
	}

	set eid [getFromRunning "eid"]
	if { [checkForExternalApps "socat"] != 0 } {
		sputs stderr "To run X applications on the node, install socat on your host."

		return
	}

	set logfile "/dev/null"
	if { $debug } {
		set logfile "/tmp/startxcmd_$eid\_$node_id.log"
	}

	eval exec startxcmd [getNodeName $node_id]@$eid $app > $logfile 2>> $logfile &
}

#****f* linux.tcl/startTcpdumpOnNodeIfc
# NAME
#   startTcpdumpOnNodeIfc -- start tcpdump on an interface
# SYNOPSIS
#   startTcpdumpOnNodeIfc $node_id $iface_name
# FUNCTION
#   Start tcpdump in a terminal on a virtual node on the specified interface.
# INPUTS
#   * node_id -- virtual node id
#   * iface_name -- virtual node interface
#****
proc startTcpdumpOnNodeIfc { node_id iface_name } {
	if { [checkForApplications $node_id "tcpdump"] == 0 } {
		spawnShell $node_id "tcpdump -leni $iface_name"
	}
}

#****f* linux.tcl/existingShells
# NAME
#   existingShells -- check which shells exist in a node
# SYNOPSIS
#   existingShells $shells $node_id
# FUNCTION
#   This procedure checks which of the provided shells are available
#   in a running node.
# INPUTS
#   * shells -- list of shells.
#   * node_id -- node id of the node for which the check is performed.
#****
proc existingShells { shells node_id { first_only "" } } {
	set preferred_shell [getActiveOption "preferred_shell"]
	set shells "$preferred_shell [removeFromList $shells $preferred_shell]"

	set cmds "retval=\"\" ;\n"
	append cmds "\n"
	append cmds "for s in $shells; do\n"
	append cmds "	x=\"\$(command -v \$s)\" ;\n"
	append cmds "	test \$? -eq 0 && retval=\"\$retval \$x\" "
	if { $first_only != "" } {
		append cmds "&& break; \n"
	} else {
		append cmds "; \n"
	}
	append cmds "done ;\n"
	append cmds "echo \"\$retval\"\n"

	set cmds "\'$cmds\'"

	set private_ns [invokeNodeProc $node_id "getPrivateNs" [getFromRunning "eid"] $node_id]
	set os_cmd "docker exec $private_ns"

	catch { rexec {*}$os_cmd sh -c {*}$cmds } existing

	return $existing
}

#****f* linux.tcl/spawnShell
# NAME
#   spawnShell -- spawn shell
# SYNOPSIS
#   spawnShell $node_id $cmd
# FUNCTION
#   This procedure spawns a new shell for a specified node.
#   The shell is specified in cmd parameter.
# INPUTS
#   * node_id -- node id of the node for which the shell is spawned.
#   * cmd -- the path to the shell.
#****
proc spawnShell { node_id cmd } {
	global ttyrcmd

	if { [checkTerminalMissing] } {
		return
	}

	set docker_id [getFromRunning "eid"]\.$node_id

	exec {*}[getActiveOption "terminal_command"] \
		-T "IMUNES: [getNodeName $node_id] (console) [string trim [lindex [split $cmd /] end] ']" \
		-e {*}$ttyrcmd "docker exec -it $docker_id $cmd" 2> /dev/null &
}

#****f* linux.tcl/allSnapshotsAvailable
# NAME
#   allSnapshotsAvailable -- all snapshots available
# SYNOPSIS
#   allSnapshotsAvailable
# FUNCTION
#   Procedure that checks whether all node snapshots are available on the
#   current system.
#****
proc allSnapshotsAvailable {} {
	global VROOT_MASTER execMode gui

	set snapshots $VROOT_MASTER
	foreach node_id [getFromRunning "node_list"] {
		# TODO: create another field for other jail/docker arguments
		set img [lindex [split [getNodeCustomImage $node_id] " "] end]
		if { $img != "" } {
			lappend snapshots $img
		}
	}
	set snapshots [lsort -uniq $snapshots]
	set missing 0

	foreach template $snapshots {
		set search_template $template
		if { [string match "*:*" $template] != 1 } {
			append search_template ":latest"
		}

		catch { rexec docker images -q $search_template } images
		if { [llength $images] > 0 } {
			continue
		} else {
			# be nice to the user and see whether there is an image id matching
			if { [string length $template] == 12 } {
				catch { rexec docker images -q } all_images
				if { [lsearch $all_images $template] == -1 } {
					incr missing
				}
			} else {
				incr missing
			}
			if { $missing } {
				set msg "Docker image for some virtual nodes:\n$template\nis missing.\n"
				append msg "Run 'docker pull $template' to pull the template."

				if { ! $gui || $execMode == "batch" } {
					sputs stderr $msg
				} else {
					tk_dialog .dialog1 "IMUNES error" \
						$msg \
						info 0 Dismiss
				}

				return 0
			}
		}
	}

	return 1
}

proc prepareDevfs { { force 0 } } {}

#****f* linux.tcl/getHostIfcList
# NAME
#   getHostIfcList -- get interfaces list from host
# SYNOPSIS
#   getHostIfcList
# FUNCTION
#   Returns the list of all network interfaces on the host.
# RESULT
#   * extifcs -- list of all external interfaces
#****
proc getHostIfcList { { filter_list "lo" } } {
	# fetch interface list from the system
	if { [catch { rexec ls /sys/class/net } extifcs] } {
		return ""
	}

	# exclude loopback interface
	foreach ignore $filter_list {
		set extifcs [lsearch -all -inline -not $extifcs $ignore]
	}

	return $extifcs
}

#****f* linux.tcl/getHostIfcVlanExists
# NAME
#   getHostIfcVlanExists -- check if host VLAN interface exists
# SYNOPSIS
#   getHostIfcVlanExists $node_id $iface_name
# FUNCTION
#   Returns 1 if VLAN interface with the name iface_name for the given node cannot
#   be created.
# INPUTS
#   * node_id -- node id
#   * iface_name -- interface id
# RESULT
#   * check -- 1 if interface exists, 0 otherwise
#****
proc getHostIfcVlanExists { node_id iface_name } {
	global execMode gui

	# check if VLAN ID is already taken
	# this can be only done by trying to create it, as it's possible that the same
	# VLAN interface already exists in some other namespace
	set iface_id [ifaceIdFromName $node_id $iface_name]
	set vlan [getIfcVlanTag $node_id $iface_id]
	try {
		rexec ip link add link $iface_name name ${iface_name}_$vlan type vlan id $vlan
	} on ok {} {
		rexec ip link del ${iface_name}_$vlan

		return 0
	} on error err {
		set msg "Unable to create external interface '${iface_name}_$vlan':\n$err\n\nPlease\
			verify that VLAN ID $vlan with parent interface $iface_name is not already\
			assigned to another VLAN interface, potentially in a different namespace."
	}

	if { ! $gui || $execMode == "batch" } {
		sputs stderr $msg
	} else {
		after idle { .dialog1.msg configure -wraplength 4i }
		tk_dialog .dialog1 "IMUNES error" $msg \
			info 0 Dismiss
	}

	return 1
}

proc loadKernelModules {} {
	global all_modules_list

	foreach node_type $all_modules_list {
		invokeTypeProc $node_type "prepareSystem"
	}
}

proc prepareVirtualFS {} {
	rexec mkdir -p /var/run/netns
}

proc createExperimentContainer {} {
	global devfs_number

	catch { rexec ip netns attach imunes_$devfs_number 1 }
	catch { rexec docker network create --opt com.docker.network.container_iface_prefix=dext imunes-bridge }

	# Top-level experiment netns
	rexec ip netns add [getFromRunning "eid"]
}

proc checkHangingTCPs { eid nodes } {}

#****f* linux.tcl/nodeLogIfacesCreate
# NAME
#   nodeLogIfacesCreate -- create node logical interfaces
# SYNOPSIS
#   nodeLogIfacesCreate $node_id
# FUNCTION
#   Creates logical interfaces for the given node.
# INPUTS
#   * node_id -- node id
#****
proc nodeLogIfacesCreate { node_id ifaces } {
	set docker_id "[getFromRunning "eid"].$node_id"

	set cmds ""
	foreach iface_id $ifaces {
		set iface_name [getIfcName $node_id $iface_id]
		switch -exact [getIfcType $node_id $iface_id] {
			vlan {
				set tag [getIfcVlanTag $node_id $iface_id]
				set dev [getIfcVlanDev $node_id $iface_id]
				if { $tag != "" && $dev != "" } {
					append cmds "[getVlanTagIfcCmd $iface_name $dev $tag]\n"
					addStateNodeIface $node_id $iface_id "creating"
				} else {
					removeStateNodeIface $node_id $iface_id "running"
				}
			}
			lo {
				addStateNodeIface $node_id $iface_id "creating"
				if { $iface_name != "lo0" } {
					append cmds "ip link add $iface_name type dummy\n"
					append cmds "ip link set $iface_name up\n"
				} else {
					append cmds "ip link set dev lo down 2>/dev/null\n"
					append cmds "ip link set dev lo name lo0 2>/dev/null\n"
					append cmds "ip a flush lo0 2>/dev/null\n"
				}
			}
		}
	}

	pipesExec "docker exec -d $docker_id sh -c '$cmds'" "hold"

	## docker interface is created before other ones, so let's rename it to something that's not used by IMUNES
	#if { [getNodeDockerAttach $node_id] == 1 } {
	#	set cmds "ip r save > /tmp/routes"
	#	set cmds "$cmds ; ip l set eth0 down"
	#	set cmds "$cmds ; ip l set eth0 name docker0"
	#	set cmds "$cmds ; ip l set docker0 up"
	#	set cmds "$cmds ; ip r restore < /tmp/routes"
	#	set cmds "$cmds ; rm -f /tmp/routes"
	#	pipesExec "docker exec -d $docker_id sh -c '$cmds'" "hold"
	#}
}

proc createNsLinkBridge { node_ns link } {
	pipesExec "ip -n $node_ns link add name $link type bridge ageing_time 0 mcast_snooping 0" "hold"
	pipesExec "ip -n $node_ns link set $link multicast off" "hold"
	pipesExec "ip netns exec $node_ns sysctl net.ipv6.conf.$link.disable_ipv6=1" "hold"
	pipesExec "ip -n $node_ns link set $link up" "hold"
}

proc createNsVethPair { full_ifname1 ifname1 netns1 config1 full_ifname2 ifname2 netns2 config2 } {
	global devfs_number

	set eid [getFromRunning "eid"]

	pipesExec "ip link add name $full_ifname1 netns $netns1 type veth peer name $full_ifname2 netns $netns2" "hold"

	if { $full_ifname1 != $ifname1 } {
		pipesExec "ip -n $netns1 link set $full_ifname1 name $ifname1" "hold"
	}

	if { $full_ifname2 != $ifname2 } {
		pipesExec "ip -n $netns2 link set $full_ifname2 name $ifname2" "hold"
	}

	if { $config1 != "" } {
		pipesExec "ip netns exec $netns1 ip link set $ifname1 multicast off" "hold"
		pipesExec "ip netns exec $netns1 sysctl net.ipv6.conf.$ifname1.disable_ipv6=1" "hold"
	}
	
	if { $config2 != "" } {
		pipesExec "ip netns exec $netns2 ip link set $ifname2 multicast off" "hold"
		pipesExec "ip netns exec $netns2 sysctl net.ipv6.conf.$ifname2.disable_ipv6=1" "hold"
	}
}

proc setNsIfcMaster { node_ns iface_name master state } {
	pipesExec "ip -n $node_ns link set $iface_name master $master $state" "hold"
}

proc createLinkBetween { node1_id node2_id iface1_id iface2_id link_id } {
	set eid [getFromRunning "eid"]

	addStateLink $link_id "creating"

	set direct [getLinkDirect $link_id]
	if {
		! $direct &&
		"wlan" ni "[getNodeType $node1_id] [getNodeType $node2_id]"
	} {
		# create link bridge in experiment netns
		createNsLinkBridge $eid $link_id
	}

	# add nodes iface hooks to link bridge and bring them up
	foreach node_id "$node1_id $node2_id" iface_id "$iface1_id $iface2_id" {
		invokeNodeProc $node_id "attachToLink" $eid $node_id $iface_id $link_id $direct
	}
}

proc configureLinkBetween { node1_id node2_id iface1_id iface2_id link_id } {
	set eid [getFromRunning "eid"]

	set bandwidth [expr [getLinkBandwidth $link_id] + 0]
	set delay [expr [getLinkDelay $link_id] + 0]
	set ber [expr [getLinkBER $link_id] + 0]
	set loss [expr [getLinkLoss $link_id] + 0]
	set dup [expr [getLinkDup $link_id] + 0]

	foreach node_id "$node1_id $node2_id" iface_id "$iface1_id $iface2_id" {
		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] iface_name - -
		if { [getNodeType $node_id] == "rj45" } {
			set vlan [getIfcVlanTag $node_id $iface_id]
			set dev [getIfcVlanDev $node_id $iface_id]
			if { $vlan != "" && $dev != "" } {
				set iface_name ${dev}_$vlan
			}
		}

		set netem_cfg [getNetemConfigLine $bandwidth $delay $loss $dup]
		pipesExec "ip netns exec $private_ns tc qdisc replace dev $iface_name root netem $netem_cfg" "hold"

		# XXX: Now on Linux we don't care about queue lengths and we don't limit
		# maximum data and burst size.
		# in the future we can use something like this: (based on the qlen
		# parameter)
		# set confstring "tbf rate ${bandwidth}bit limit 10mb burst 1540"

		# FIXME: remove this to interface configuration?
		if { [getNodeType $node_id] == "rj45" } {
			continue
		}

		set qdisc [getIfcQDisc $node_id $iface_id]
		if { $qdisc != "FIFO" } {
			execSetIfcQDisc $eid $node_id $iface_id $qdisc
		}

		set qlen [getIfcQLen $node_id $iface_id]
		if { $qlen != 1000 } {
			execSetIfcQLen $eid $node_id $iface_id $qlen
		}
	}
}

proc unconfigureLinkBetween { eid node1_id node2_id iface1_id iface2_id link_id } {
	foreach node_id "$node1_id $node2_id" iface_id "$iface1_id $iface2_id" {
		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] iface_name - -

		pipesExec "ip netns exec $private_ns tc qdisc del dev $iface_name root" "hold"
	}
}

proc removeNetns { netns } {
	if { $netns != "" } {
		catch { rexec ip netns del $netns }
	}
}

proc terminate_removeExperimentContainer { eid } {
	removeNetns $eid
}

proc terminate_removeExperimentFiles { eid } {
	set VROOT_BASE [getVrootDir]
	catch { rexec rm -fr $VROOT_BASE/$eid & }
}

proc destroyLinkBetween { eid node1_id node2_id iface1_id iface2_id link_id } {
	addStateLink $link_id "destroying"

	set direct [getFromRunning "${link_id}_destroy_type"]
	foreach node_id "$node1_id $node2_id" iface_id "$iface1_id $iface2_id" {
		invokeNodeProc $node_id "detachFromLink" $eid $node_id $iface_id $link_id $direct
	}

	if {
		! $direct &&
		"wlan" ni "[getNodeType $node1_id] [getNodeType $node2_id]"
	} {
		pipesExec "ip -n $eid link del $link_id" "hold"
	}

	#if { "[getNodeType $node1_id] [getNodeType $node2_id]" == "rj45 rj45" } {
	#	global devfs_number

	#	pipesExec "ip -n imunes_$devfs_number link del $eid-$link_id" "hold"
	#}
}

#****f* linux.tcl/removeNodeIfcIPaddrs
# NAME
#   removeNodeIfcIPaddrs -- remove node iterfaces' IP addresses
# SYNOPSIS
#   removeNodeIfcIPaddrs $eid $node_id
# FUNCTION
#   Remove all IPv4 and IPv6 addresses from interfaces on the given node.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc removeNodeIfcIPaddrs { eid node_id } {
	set docker_id "$eid.$node_id"
	set cmds ""
	foreach ifc [allIfcList $node_id] {
		append cmds "ip addr flush dev $ifc\n"
	}
	pipesExec "docker exec -d $docker_id sh -c '$cmds'" "hold"
}

#****f* linux.tcl/getCpuCount
# NAME
#   getCpuCount -- get CPU count
# SYNOPSIS
#   getCpuCount
# FUNCTION
#   Gets a CPU count of the host machine.
# RESULT
#   * cpucount - CPU count
#****
proc getCpuCount {} {
	global remote max_jobs

	if { $max_jobs == "h" } {
		set max_jobs [expr round([lindex [rexec grep -c processor /proc/cpuinfo] 0]/2)]
	}

	if { $remote == "" } {
		if { $max_jobs > 0 } {
			return $max_jobs
		}
	} else {
		# buffer for non-closed SSH connections
		set remote_jobs [expr round($max_jobs/3)]
		if { $remote_jobs == 0 } {
			set remote_jobs 1
		}

		return $remote_jobs
	}

	return [lindex [rexec grep -c processor /proc/cpuinfo] 0]
}

#****f* linux.tcl/captureExtIfcByName
# NAME
#   captureExtIfcByName -- capture external interface
# SYNOPSIS
#   captureExtIfcByName $eid $iface_name
# FUNCTION
#   Captures the external interface given by the iface_name.
# INPUTS
#   * eid -- experiment id
#   * iface_name -- physical interface name
#****
proc captureExtIfcByName { eid iface_name node_id } {
	set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

	# won't work if the node is a wireless interface
	pipesExec "ip link set $iface_name netns $private_ns" "hold"
}

#****f* linux.tcl/releaseExtIfcByName
# NAME
#   releaseExtIfcByName -- release external interface
# SYNOPSIS
#   releaseExtIfcByName $eid $node_id
# FUNCTION
#   Releases the external interface with the name iface_name.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc releaseExtIfcByName { eid iface_name node_id } {
	global devfs_number

	set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
	pipesExec "ip -n $private_ns link set $iface_name netns imunes_$devfs_number" "hold"
}

proc getStateIfcCmd { iface_name state } {
	return "ip link set dev $iface_name $state"
}

proc getNameIfcCmd { iface_name name } {
	return "ip link set dev $iface_name name $name"
}

proc getMacIfcCmd { iface_name mac_addr } {
	return "ip link set dev $iface_name address $mac_addr"
}

proc getVlanTagIfcCmd { iface_name dev_name tag } {
	return "ip link add link $dev_name name $iface_name type vlan id $tag"
}

proc getMtuIfcCmd { iface_name mtu } {
	return "ip link set dev $iface_name mtu $mtu"
}

proc getNatIfcCmd { iface_name } {
	return "iptables -t nat -A POSTROUTING -o $iface_name -j MASQUERADE"
}

proc getRemoveNatIfcCmd { iface_name } {
	return "iptables -t nat -D POSTROUTING -o $iface_name -j MASQUERADE"
}

proc getIPv4RouteCmd { statrte } {
	set route [lindex $statrte 0]
	set addr [lindex $statrte 1]
	set cmd "ip route append $route via $addr"

	return $cmd
}

proc getRemoveIPv4RouteCmd { statrte } {
	set route [lindex $statrte 0]
	set addr [lindex $statrte 1]
	set cmd "ip route delete $route via $addr"

	return $cmd
}

proc getIPv6RouteCmd { statrte } {
	set route [lindex $statrte 0]
	set addr [lindex $statrte 1]
	set cmd "ip -6 route append $route via $addr"

	return $cmd
}

proc getRemoveIPv6RouteCmd { statrte } {
	set route [lindex $statrte 0]
	set addr [lindex $statrte 1]
	set cmd "ip -6 route delete $route via $addr"

	return $cmd
}

proc getIPv4IfcRouteCmd { subnet iface_name } {
	return "ip route add $subnet dev $iface_name"
}

proc getRemoveIPv4IfcRouteCmd { subnet iface_name } {
	return "ip route del $subnet dev $iface_name"
}

proc getIPv6IfcRouteCmd { subnet iface_name } {
	return "ip -6 route add $subnet dev $iface_name"
}

proc getRemoveIPv6IfcRouteCmd { subnet iface_name } {
	return "ip -6 route del $subnet dev $iface_name"
}

proc getFlushIPv4IfcCmd { iface_name } {
	return "ip -4 a flush dev $iface_name"
}

proc getFlushIPv6IfcCmd { iface_name } {
	return "ip -6 a flush dev $iface_name"
}

proc getIPv4IfcCmd { ifc addr primary } {
	if { $addr == "dhcp" } {
		return "dhclient -nw $ifc 2>/dev/null &"
	}

	return "ip addr add $addr dev $ifc"
}

proc getIPv6IfcCmd { iface_name addr primary } {
	return "ip -6 addr add $addr dev $iface_name"
}

proc getDelIPv4IfcCmd { ifc addr } {
	if { $addr == "dhcp" } {
		return "pkill -f 'dhclient -nw $ifc\\>'"
	}

	return "ip addr del $addr dev $ifc"
}

proc getDelIPv6IfcCmd { ifc addr } {
	return "ip -6 addr del $addr dev $ifc"
}

proc fetchInterfaceData { node_id iface_id } {
	global node_existing_mac node_existing_ipv4 node_existing_ipv6
	set node_existing_mac [getFromRunning "mac_used_list"]
	set node_existing_ipv4 [getFromRunning "ipv4_used_list"]
	set node_existing_ipv6 [getFromRunning "ipv6_used_list"]

	global node_cfg

	set iface_name [_getIfcName $node_cfg $iface_id]
	if { $iface_name ni [getHostIfcList "lo* tun*"] } {
		sputs "No interface $iface_name."

		return
	}

	set new_cfg $node_cfg

	catch { rexec ip --json a show $iface_name } json
	set elem {*}[json::json2dict $json]

	if { "UP" in [dictGet $elem "flags"] } {
		set oper_state ""
	} else {
		set oper_state "down"
	}
	set new_cfg [_setIfcOperState $new_cfg $iface_id $oper_state]

	set link_type [dictGet $elem "link_type"]
	if { $link_type != "loopback" } {
		set old_mac [_getIfcMACaddr $new_cfg $iface_id]
		set new_mac [dictGet $elem "address"]

		if { $old_mac != $new_mac } {
			set node_existing_mac [removeFromList $node_existing_mac $old_mac "keep_doubles"]
			lappend node_existing_mac $new_mac

			set new_cfg [_setIfcMACaddr $new_cfg $iface_id $new_mac]
		}
	}

	set mtu [dictGet $elem "mtu"]
	if { $mtu != "" && [_getIfcMTU $new_cfg $iface_id] != $mtu} {
		set new_cfg [_setIfcMTU $new_cfg $iface_id $mtu]
	}

	set ipv4_addrs {}
	set ipv6_addrs {}
	foreach addr_cfg [dictGet $elem "addr_info"] {
		set family [dictGet $addr_cfg "family"]
		set addr [dictGet $addr_cfg "local"]
		set mask [dictGet $addr_cfg "prefixlen"]
		if { $family == "inet" } {
			lappend ipv4_addrs "$addr/$mask"
		} elseif { $family == "inet6" && [dictGet $addr_cfg "scope"] in "global host" } {
			lappend ipv6_addrs "$addr/$mask"
		}
	}

	set old_ipv4_addrs [lsort [_getIfcIPv4addrs $new_cfg $iface_id]]
	set new_ipv4_addrs [lsort $ipv4_addrs]
	if { $old_ipv4_addrs != $new_ipv4_addrs } {
		set node_existing_ipv4 [removeFromList $node_existing_ipv4 $old_ipv4_addrs "keep_doubles"]
		lappend node_existing_ipv4 {*}$new_ipv4_addrs

		setToRunning "${node_id}|${iface_id}_old_ipv4_addrs" $ipv4_addrs
		set new_cfg [_setIfcIPv4addrs $new_cfg $iface_id $ipv4_addrs]
	}

	set old_ipv6_addrs [lsort [_getIfcIPv6addrs $new_cfg $iface_id]]
	set new_ipv6_addrs [lsort $ipv6_addrs]
	if { $old_ipv6_addrs != $new_ipv6_addrs } {
		set node_existing_ipv6 [removeFromList $node_existing_ipv6 $old_ipv6_addrs "keep_doubles"]
		lappend node_existing_ipv6 {*}$new_ipv6_addrs

		setToRunning "${node_id}|${iface_id}_old_ipv6_addrs" $ipv6_addrs
		set new_cfg [_setIfcIPv6addrs $new_cfg $iface_id $ipv6_addrs]
	}

	if { $new_cfg == $node_cfg } {
		return
	}

	return $new_cfg
}

#****f* linux.tcl/fetchNodeRunningConfig
# NAME
#   fetchNodeRunningConfig -- get interfaces list from the node
# SYNOPSIS
#   fetchNodeRunningConfig $node_id
# FUNCTION
#   Returns the list of all network interfaces for the given node.
# INPUTS
#   * node_id -- node id
# RESULT
#   * list -- list in the form of {netgraph_node_name hook}
#****
proc fetchNodeRunningConfig { node_id } {
	global node_existing_mac node_existing_ipv4 node_existing_ipv6
	set node_existing_mac [getFromRunning "mac_used_list"]
	set node_existing_ipv4 [getFromRunning "ipv4_used_list"]
	set node_existing_ipv6 [getFromRunning "ipv6_used_list"]

	# overwrite any unsaved changes to this node
	set cur_node_cfg [cfgGet "nodes" $node_id]
	set cur_node_cfg_gui [cfgGet "gui" "nodes" $node_id]

	set ifaces_names [allIfacesNames $node_id]

	catch { rexec docker exec [getFromRunning "eid"].$node_id sh -c 'ip --json a' } json
	foreach elem [json::json2dict $json] {
		set iface_name [dictGet $elem "ifname"]
		if { $iface_name ni $ifaces_names } {
			continue
		}

		set iface_id [ifaceIdFromName $node_id $iface_name]

		if { "UP" in [dictGet $elem "flags"] } {
			set oper_state ""
		} else {
			set oper_state "down"
		}
		set cur_node_cfg [_setIfcOperState $cur_node_cfg $iface_id $oper_state]

		set link_type [dictGet $elem "link_type"]
		if { $link_type != "loopback" } {
			set old_mac [_getIfcMACaddr $cur_node_cfg $iface_id]
			set new_mac [dictGet $elem "address"]

			if { $old_mac != $new_mac } {
				set node_existing_mac [removeFromList $node_existing_mac $old_mac "keep_doubles"]
				lappend node_existing_mac $new_mac

				set cur_node_cfg [_setIfcMACaddr $cur_node_cfg $iface_id $new_mac]
			}
		}

		set mtu [dictGet $elem "mtu"]
		if { $mtu != "" && [_getIfcMTU $cur_node_cfg $iface_id] != $mtu} {
			set cur_node_cfg [_setIfcMTU $cur_node_cfg $iface_id $mtu]
		}

		set ipv4_addrs {}
		set ipv6_addrs {}
		foreach addr_cfg [dictGet $elem "addr_info"] {
			set family [dictGet $addr_cfg "family"]
			set addr [dictGet $addr_cfg "local"]
			set mask [dictGet $addr_cfg "prefixlen"]
			if { $family == "inet" } {
				lappend ipv4_addrs "$addr/$mask"
			} elseif { $family == "inet6" && [dictGet $addr_cfg "scope"] in "global host" } {
				lappend ipv6_addrs "$addr/$mask"
			}
		}

		set old_ipv4_addrs [lsort [_getIfcIPv4addrs $cur_node_cfg $iface_id]]
		set new_ipv4_addrs [lsort $ipv4_addrs]
		if { $old_ipv4_addrs != $new_ipv4_addrs } {
			set node_existing_ipv4 [removeFromList $node_existing_ipv4 $old_ipv4_addrs "keep_doubles"]
			lappend node_existing_ipv4 {*}$new_ipv4_addrs

			setToRunning "${node_id}|${iface_id}_old_ipv4_addrs" $ipv4_addrs
			set cur_node_cfg [_setIfcIPv4addrs $cur_node_cfg $iface_id $ipv4_addrs]
		}

		set old_ipv6_addrs [lsort [_getIfcIPv6addrs $cur_node_cfg $iface_id]]
		set new_ipv6_addrs [lsort $ipv6_addrs]
		if { $old_ipv6_addrs != $new_ipv6_addrs } {
			set node_existing_ipv6 [removeFromList $node_existing_ipv6 $old_ipv6_addrs "keep_doubles"]
			lappend node_existing_ipv6 {*}$new_ipv6_addrs

			setToRunning "${node_id}|${iface_id}_old_ipv6_addrs" $ipv6_addrs
			set cur_node_cfg [_setIfcIPv6addrs $cur_node_cfg $iface_id $ipv6_addrs]
		}
	}

	lassign [getDefaultGateways $node_id {} {}] my_gws {} {}
	lassign [getDefaultRoutesConfig $node_id $my_gws] default_routes4 default_routes6

	set croutes4 {}
	set croutes6 {}

	catch { rexec docker exec [getFromRunning "eid"].$node_id sh -c 'ip -4 --json r' } json
	foreach elem [json::json2dict $json] {
		if { [dictGet $elem "scope"] in "link" } {
			continue
		}

		set dst [dictGet $elem "dst"]
		if { $dst == "default" } {
			set dst "0.0.0.0/0"
		} elseif { [string first "/" $dst] == -1 } {
			set dst "$dst/32"
		}
		set gateway [dictGet $elem "gateway"]

		set new_route "$dst $gateway"
		if { $new_route in $default_routes4 } {
			continue
		}

		lappend croutes4 $new_route
	}

	set old_croutes4 [lsort [_getNodeStatIPv4routes $cur_node_cfg]]
	set new_croutes4 [lsort $croutes4]
	if { $old_croutes4 != $new_croutes4 } {
		setToRunning "${node_id}_old_croutes4" $new_croutes4
		set cur_node_cfg [_setNodeStatIPv4routes $cur_node_cfg $new_croutes4]
	}

	catch { rexec docker exec [getFromRunning "eid"].$node_id sh -c 'ip -6 --json r' } json
	foreach elem [json::json2dict $json] {
		if { [dictGet $elem "nexthops"] == "" && [dictGet $elem "gateway"] == "" } {
			continue
		}

		set dst [dictGet $elem "dst"]
		if { $dst == "default" } {
			set dst "::/0"
		} elseif { [string first "/" $dst] == -1 } {
			set dst "$dst/128"
		}
		set gateway [dictGet $elem "gateway"]

		if { $gateway != "" } {
			set new_route "$dst $gateway"
			if { $new_route in $default_routes6 } {
				continue
			}

			lappend croutes6 $new_route
		} else {
			foreach nexthop_elem [dictGet $elem "nexthops"] {
				set gateway [dictGet $nexthop_elem "gateway"]
				set new_route "$dst $gateway"
				if { $new_route in $default_routes6 } {
					continue
				}
			}
		}
	}

	set old_croutes6 [lsort [_getNodeStatIPv6routes $cur_node_cfg]]
	set new_croutes6 [lsort $croutes6]
	if { $old_croutes6 != $new_croutes6 } {
		setToRunning "${node_id}_old_croutes6" $new_croutes6
		set cur_node_cfg [_setNodeStatIPv6routes $cur_node_cfg $new_croutes6]
	}

	# don't trigger anything new - save variables state
	prepareInstantiateVars
	prepareTerminateVars

	updateNodeGUI $node_id "*" $cur_node_cfg_gui

	updateNode $node_id "*" $cur_node_cfg

	# don't trigger anything new - restore variables state
	updateInstantiateVars
	updateTerminateVars

	if { $node_existing_mac != [getFromRunning "mac_used_list"] } {
		setToRunning "mac_used_list" $node_existing_mac
	}

	if { $node_existing_ipv4 != [getFromRunning "ipv4_used_list"] } {
		setToRunning "ipv4_used_list" $node_existing_ipv4
	}

	if { $node_existing_ipv6 != [getFromRunning "ipv6_used_list"] } {
		setToRunning "ipv6_used_list" $node_existing_ipv6
	}

	return $cur_node_cfg
}

proc checkSysPrerequisites {} {
	set msg ""
	catch { rexec docker info } status
	if { ! [string match -nocase "*Storage Driver: overlay*" $status] } {
		set msg "Cannot start experiment.\nIs docker installed and running with overlay FS (check the output of 'docker info')?"
	}

	return $msg
}

#****f* linux.tcl/execSetIfcQDisc
# NAME
#   execSetIfcQDisc -- in exec mode set interface queuing discipline
# SYNOPSIS
#   execSetIfcQDisc $eid $node_id $iface_id $qdisc
# FUNCTION
#   Sets the queuing discipline during the simulation.
#   New queuing discipline is defined in qdisc parameter.
#   Queueing discipline can be set to fifo, wfq or drr.
# INPUTS
#   eid -- experiment id
#   node_id -- node id
#   iface_id -- interface id
#   qdisc -- queuing discipline
#****
proc execSetIfcQDisc { eid node_id iface_id qdisc } {
	switch -exact $qdisc {
		FIFO { set qdisc pfifo_fast }
		WFQ { set qdisc sfq }
		DRR { set qdisc drr }
	}

	pipesExec "ip netns exec $eid.$node_id tc qdisc add dev [getIfcName $node_id $iface_id] root $qdisc" "hold"
}

#****f* linux.tcl/execSetIfcQLen
# NAME
#   execSetIfcQLen -- in exec mode set interface TX queue length
# SYNOPSIS
#   execSetIfcQLen $eid $node_id $iface_id $qlen
# FUNCTION
#   Sets the queue length during the simulation.
#   New queue length is defined in qlen parameter.
# INPUTS
#   eid -- experiment id
#   node_id -- node id
#   iface_id -- interface id
#   qlen -- new queue's length
#****
proc execSetIfcQLen { eid node_id iface_id qlen } {
	set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
	lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] iface_name - -

	pipesExec "ip -n $private_ns l set $iface_name txqueuelen $qlen" "hold"
}

proc getNetemConfigLine { bandwidth delay loss dup } {
	array set netem {
		bandwidth	"rate Xbit"
		loss		"loss random X%"
		delay		"delay Xus"
		dup			"duplicate X%"
	}

	set cmd ""
	foreach { val ctemplate } [array get netem] {
		append cmd " [lindex [split $ctemplate "X"] 0][set $val][lindex [split $ctemplate "X"] 1]"
	}

	return $cmd
}

proc ipsecFilesToNode { node_id ca_cert local_cert ipsecret_file } {
	global ipsecConf ipsecSecrets

	if { $ca_cert != "" } {
		set trimmed_ca_cert [lindex [split $ca_cert /] end]

		set fileId [open $ca_cert "r"]
		set trimmed_ca_cert_data [read $fileId]
		close $fileId

		writeDataToNodeFile $node_id /etc/ipsec.d/cacerts/$trimmed_ca_cert $trimmed_ca_cert_data
	}

	if { $local_cert != "" } {
		set trimmed_local_cert [lindex [split $local_cert /] end]

		set fileId [open $local_cert "r"]
		set trimmed_local_cert_data [read $fileId]
		close $fileId

		writeDataToNodeFile $node_id /etc/ipsec.d/certs/$trimmed_local_cert $trimmed_local_cert_data
	}

	if { $ipsecret_file != "" } {
		set trimmed_local_key [lindex [split $ipsecret_file /] end]

		set fileId [open $ipsecret_file "r"]
		set local_key_data [read $fileId]
		close $fileId

		writeDataToNodeFile $node_id /etc/ipsec.d/private/$trimmed_local_key $local_key_data

		set ipsecSecrets "${ipsecSecrets}: RSA $trimmed_local_key"
	}

	writeDataToNodeFile $node_id /etc/ipsec.conf $ipsecConf
	writeDataToNodeFile $node_id /etc/ipsec.secrets $ipsecSecrets
}

proc sshServiceStartCmds {} {
	lappend cmds "dpkg-reconfigure openssh-server"
	lappend cmds "service ssh start"

	return $cmds
}

proc sshServiceStopCmds {} {
	return { "service ssh stop" }
}

proc inetdServiceRestartCmds {} {
	return "service openbsd-inetd restart"
}

proc moveFileFromNode { node_id path ext_path } {
	set eid [getFromRunning "eid"]

	catch { rexec hcp [getNodeName $node_id]@$eid:$path $ext_path }
	catch { rexec docker exec $eid.$node_id rm -fr $path }
}

# XXX nat64 procedures
proc configureTunIface { tayga4pool tayga6prefix } {
	set cfg {}

	set tun_dev "tun64"
	lappend cfg "ip tuntap add $tun_dev mode tun"
	lappend cfg "[getStateIfcCmd "$tun_dev" "up"]"

	if { $tayga4pool != "" } {
		lappend cfg "vtysh << __EOF__"
		lappend cfg "conf term"

		lappend cfg "!"
		lappend cfg "ip route $tayga4pool $tun_dev"

		lappend cfg "!"
		lappend cfg "__EOF__"
	}

	if { $tayga6prefix != "" } {
		lappend cfg "vtysh << __EOF__"
		lappend cfg "conf term"

		lappend cfg "ipv6 route $tayga6prefix $tun_dev"

		lappend cfg "!"
		lappend cfg "__EOF__"
	}

	return $cfg
}

proc unconfigureTunIface { tayga4pool tayga6prefix } {
	set cfg {}

	set tun_dev "tun64"
	if { $tayga4pool != "" } {
		lappend cfg "vtysh << __EOF__"
		lappend cfg "conf term"

		lappend cfg "!"
		lappend cfg "no ip route $tayga4pool $tun_dev"

		lappend cfg "!"
		lappend cfg "__EOF__"
	}

	if { $tayga6prefix != "" } {
		lappend cfg "vtysh << __EOF__"
		lappend cfg "conf term"

		lappend cfg "no ipv6 route $tayga6prefix $tun_dev"

		lappend cfg "!"
		lappend cfg "__EOF__"
	}

	lappend cfg "[getStateIfcCmd "$tun_dev" "down"]"

	return $cfg
}

proc startRoutingDaemons { node_id } {
	set run_dir "/run/frr"
	set cmds "mkdir -p $run_dir ; chown frr:frr $run_dir"

	set conf_dir "/etc/frr"

	foreach protocol { rip ripng ospf ospf6 } {
		if { [getNodeProtocol $node_id $protocol] != 1 } {
			# TODO: startRoutingDaemons should be unconfigurable - additional execute/terminate step
			#set cmds "$cmds; sed -i'' \"s/${protocol}d=yes/${protocol}d=no/\" $conf_dir/daemons"
			continue
		}

		set cmds "$cmds; sed -i'' \"s/${protocol}d=no/${protocol}d=yes/\" $conf_dir/daemons"
	}

	foreach protocol { ldp bfd } {
		if { [getNodeProtocol $node_id $protocol] != 1 } {
			# TODO: startRoutingDaemons should be unconfigurable - additional execute/terminate step
			#set cmds "$cmds; sed -i'' \"s/${protocol}d=yes/${protocol}d=no/\" $conf_dir/daemons"
			continue
		}

		set cmds "$cmds; sed -i'' \"s/${protocol}d=no/${protocol}d=yes/\" $conf_dir/daemons"
	}

	foreach protocol { bgp isis } {
		if { [getNodeProtocol $node_id $protocol] != 1 } {
			# TODO: startRoutingDaemons should be unconfigurable - additional execute/terminate step
			#set cmds "$cmds; sed -i'' \"s/${protocol}d=yes/${protocol}d=no/\" $conf_dir/daemons"
			continue
		}

		set cmds "$cmds; sed -i'' \"s/${protocol}d=no/${protocol}d=yes/\" $conf_dir/daemons"
	}

	set cmds "$cmds; touch $conf_dir/vtysh.conf"
	set cmds "$cmds; /usr/lib/frr/frrinit.sh restart"

	pipesExec "docker exec [getFromRunning "eid"].$node_id sh -c '$cmds'" "hold"
}
