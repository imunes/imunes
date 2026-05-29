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

namespace eval genericL3 {
	namespace export *

	################################################################################
	########################### CONFIGURATION PROCEDURES ###########################
	################################################################################

	proc netlayer {} {
		return NETWORK
	}

	proc virtlayer {} {
		return VIRTUALIZED
	}

	proc namingBase {} {
		return "l3"
	}

	proc confNewNode { node_id } {
		invokeTypeProc "genericL2" "confNewNode" $node_id
		setNodeAutoDefaultRoutesStatus $node_id "enabled"

		set logiface_id [newLogIface $node_id "lo"]
		setIfcIPv4addrs $node_id $logiface_id "127.0.0.1/8"
		setIfcIPv6addrs $node_id $logiface_id "::1/128"
	}

	proc confNewIfc { node_id iface_id } {
		autoIPAddr "ipv4" $node_id $iface_id
		autoIPAddr "ipv6" $node_id $iface_id
		autoMACaddr $node_id $iface_id
	}

	proc generateConfigIfaces { node_id ifaces } {
		# sort physical ifaces before logical ones (because of vlans)
		set all_ifaces "[ifcList $node_id] [logIfcList $node_id]"

		if { $ifaces == "*" } {
			set ifaces $all_ifaces
		} else {
			set negative_ifaces [removeFromList $all_ifaces $ifaces]
			set ifaces [removeFromList $all_ifaces $negative_ifaces]
		}

		set cfg {}
		foreach iface_id $ifaces {
			set cfg [concat $cfg [nodeCfggenIfc $node_id $iface_id]]

			lappend cfg ""
		}

		return $cfg
	}

	proc generateUnconfigIfaces { node_id ifaces } {
		# sort physical ifaces before logical ones
		set all_ifaces "[ifcList $node_id] [logIfcList $node_id]"

		if { $ifaces == "*" } {
			set ifaces $all_ifaces
		} else {
			set negative_ifaces [removeFromList $all_ifaces $ifaces]
			set ifaces [removeFromList $all_ifaces $negative_ifaces]
		}

		set cfg {}
		foreach iface_id $ifaces {
			set cfg [concat $cfg [nodeUncfggenIfc $node_id $iface_id]]

			lappend cfg ""
		}

		return $cfg
	}

	proc generateConfig { node_id } {
		set cfg {}

		if {
			[getNodeCustomEnabled $node_id] != true ||
			[getNodeCustomConfigSelected $node_id "NODE_CONFIG"] in "\"\" DISABLED"
		} {
			set cfg [concat $cfg [nodeCfggenStaticRoutes4 $node_id]]
			set cfg [concat $cfg [nodeCfggenStaticRoutes6 $node_id]]

			lappend cfg ""
		}

		set all_routes4 {}
		set all_routes6 {}
		if { [getNodeAutoDefaultRoutesStatus $node_id] == "enabled" } {
			lassign [getDefaultRoutesConfig $node_id] all_routes4 all_routes6
		}

		setDefaultIPv4routes $node_id $all_routes4
		setDefaultIPv6routes $node_id $all_routes6

		set cfg [concat $cfg [nodeCfggenAutoRoutes4 $node_id]]
		set cfg [concat $cfg [nodeCfggenAutoRoutes6 $node_id]]

		lappend cfg ""

		return $cfg
	}

	proc generateUnconfig { node_id } {
		set cfg {}

		set cfg [concat $cfg [nodeUncfggenStaticRoutes4 $node_id]]
		set cfg [concat $cfg [nodeUncfggenStaticRoutes6 $node_id]]

		lappend cfg ""

		set cfg [concat $cfg [nodeUncfggenAutoRoutes4 $node_id]]
		set cfg [concat $cfg [nodeUncfggenAutoRoutes6 $node_id]]

		lappend cfg ""

		return $cfg
	}

	proc transformNode { node_id to_type } {
	}

	proc maxIfaces {} {
		return ""
	}

	proc ifacePrefix {} {
		return "eth"
	}

	proc IPAddrRange {} {
		return 20
	}

	proc collectIfcUppers { node_id iface_id } {
		set uppers {}
		set iface_name [getIfcName $node_id $iface_id]
		set my_prio [invokeNodeProc $node_id "getSubnetPriority" $node_id $iface_id]
		foreach other_iface_id [removeFromList [allIfcList $node_id] $iface_id] {
			if { $iface_name == [getIfcVlanDev $node_id $other_iface_id] } {
				set vlan_id [getIfcVlanTag $node_id $other_iface_id]
				if { $vlan_id != "" } {
					lappend uppers "$my_prio $node_id $other_iface_id $vlan_id"
				}
			}
		}

		return $uppers
	}

	proc collectIfcLowers { node_id iface_id } {
		set lowers {}
		if { [getIfcType $node_id $iface_id] == "phys" } {
			return $lowers
		}

		set vlan_id [getIfcVlanTag $node_id $iface_id]
		set dev_name [getIfcVlanDev $node_id $iface_id]
		if { $dev_name == "" || $vlan_id == "" } {
			return $lowers
		}

		set lower_iface_id [ifaceIdFromName $node_id $dev_name]
		if { [getIfcType $node_id $lower_iface_id] == "phys" } {
			set lower_vlan_id 0
		} else {
			set lower_vlan_id [getIfcVlanTag $node_id $lower_iface_id]
			set lower_dev_name [getIfcVlanDev $node_id $lower_iface_id]
			if { $lower_vlan_id == "" || $lower_dev_name == "" } {
				return $lowers
			}
		}

		set my_prio [invokeNodeProc $node_id "getSubnetPriority" $node_id $lower_iface_id]
		lappend lowers "$my_prio $node_id $lower_iface_id $lower_vlan_id"

		return $lowers
	}

	proc collectIfcPeers { node_id iface_id } {
		set peers {}
		set link_id [getIfcLink $node_id $iface_id]
		if { $link_id == "" } {
			return $peers
		}

		lassign [logicalPeerByIfc $node_id $iface_id] peer_id peer_iface_id peer_vlan_id
		set peer_prio [invokeNodeProc $peer_id "getSubnetPriority" $peer_id $peer_iface_id]

		set peers [linsert $peers 0 "$peer_prio $peer_id $peer_iface_id $peer_vlan_id"]

		return $peers
	}

	proc getSubnetPriority { node_id iface_id } {
		return 0
	}

	proc bootcmd { node_id } {
		return "/bin/sh"
	}

	proc shellcmds {} {
		return "csh bash sh tcsh"
	}

	proc getExecCommand { eid node_id { flags "" } } {
		global isOSlinux isOSfreebsd

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		if { $isOSlinux } {
			return "docker exec $flags $private_ns"
		}

		if { $isOSfreebsd } {
			return "jexec $private_ns"
		}
	}

	proc getPrivateNs { eid node_id } {
		global isOSlinux isOSfreebsd

		if { $isOSlinux } {
			return $eid.$node_id
		}

		if { $isOSfreebsd } {
			return $eid.$node_id
		}
	}

	proc getPublicNs { eid node_id } {
		global isOSlinux isOSfreebsd

		if { $isOSlinux } {
			return $eid
		}

		if { $isOSfreebsd } {
			# nothing
			return
		}
	}

	proc getHookData { node_id iface_id } {
		global isOSlinux isOSfreebsd

		# Linux - interface name of the node (inside node namespace)
		# FreeBSD - interface name of the node (inside node jail)
		set private_elem [getIfcName $node_id $iface_id]

		# Linux - public part of veth pair (inside EID namespace)
		# FreeBSD - name of public netgraph peer (inside EID jail)
		set public_elem "$node_id-$iface_id"

		# Linux - not used
		# FreeBSD - hook for connecting to netgraph node
		set hook_name "ether"

		return [list $private_elem $public_elem $hook_name]
	}

	################################################################################
	############################ INSTANTIATE PROCEDURES ############################
	################################################################################

	proc prepareSystem {} {
	}

	proc checkNodePrerequisites { eid node_id } {
		global isOSlinux isOSfreebsd

		setStateErrorMsgNode $node_id ""
		if { $isOSlinux } {
			set private_ns_exists [invokeNodeProc $node_id "nodeNamespaceSetup_check" $eid $node_id]
			if { $private_ns_exists } {
				addStateNode $node_id "error"
				setStateErrorMsgNode $node_id "Namespace for node '$node_id' in experiment '$eid' already exists!"

				return false
			}
		}

		set node_exists [invokeNodeProc $node_id "nodeCreate_check" $eid $node_id]
		if { $node_exists } {
			addStateNode $node_id "error"

			if { $isOSlinux } {
				set elem "Docker container"
			} elseif { $isOSfreebsd } {
				set elem "Jail"
			}
			setStateErrorMsgNode $node_id "$elem '$eid.$node_id' already exists!"

			return false
		}

		foreach import_file_entry [getNodeGenericOptions $node_id "imported_files"] {
			if { [dict get $import_file_entry "enabled"] == 0 } {
				continue
			}

			set import_file_path [dict get $import_file_entry "path"]
			if { [string index $import_file_path 0] == "@" } {
				# remove @ and split by :
				set import_file_path [join [lassign [split [string range $import_file_path 1 end] ":"] linked_node_id] ":"]
				if { $linked_node_id ni [getFromRunning "node_list"] } {
					addStateNode $node_id "error"
					setStateErrorMsgNode $node_id "WARNING: linked node '$linked_node_id' does not exist, cannot link file '$import_file_path'."

					return false
				}
			}
		}

		foreach import_dir_entry [getNodeGenericOptions $node_id "imported_dirs"] {
			if { [dict get $import_dir_entry "enabled"] == 0 } {
				continue
			}

			set import_dir_path [dict get $import_dir_entry "path"]
			if { [string index $import_dir_path 0] == "@" } {
				# remove @ and split by :
				set import_dir_path [join [lassign [split [string range $import_dir_path 1 end] ":"] linked_node_id] ":"]
				if { $linked_node_id ni [getFromRunning "node_list"] } {
					addStateNode $node_id "error"
					setStateErrorMsgNode $node_id "WARNING: linked node '$linked_node_id' does not exist, cannot link directory '$import_dir_path'."

					return false
				}
			}
		}

		foreach iface_id [allIfcList $node_id] {
			setStateNodeIface $node_id $iface_id ""
		}

		removeStateNode $node_id "error"

		return true
	}

	proc checkIfacesPrerequisites { eid node_id ifaces } {
		return [invokeTypeProc "genericL2" "checkIfacesPrerequisites" $eid $node_id $ifaces]
	}

	proc nodeCreate { eid node_id } {
		global isOSlinux isOSfreebsd

		addStateNode $node_id "node_creating"

		set VROOTDIR [getVrootDir]
		set VROOT_RUNTIME $VROOTDIR/$eid/$node_id

		if { $isOSlinux } {
			# prepare filesystem for node
			pipesExec "mkdir -p $VROOT_RUNTIME &" "hold"

			# create node container
			global VROOT_MASTER ULIMIT_FILE ULIMIT_PROC

			set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

			set vroot [getNodeDockerOptions $node_id "custom_image"]
			if { $vroot == "" } {
				# use default IMUNES docker image
				set vroot $VROOT_MASTER
			}

			if { $ULIMIT_FILE != "" } {
				set ulimit_file_str "--ulimit nofile=$ULIMIT_FILE"
			} else {
				set ulimit_file_str ""
			}

			if { $ULIMIT_PROC != "" } {
				set ulimit_proc_str "--ulimit nproc=$ULIMIT_PROC"
			} else {
				set ulimit_proc_str ""
			}

			set cpus [getNodeDockerOptions $node_id "cpus_count"]
			if { $cpus != "" } {
				set cpus_str "--cpus=$cpus"
			} else {
				set cpus_str ""
			}

			set volumes_mounts_str ""
			foreach volume_entry [getNodeDockerOptions $node_id "volumes_mounts"] {
				if { [dict get $volume_entry "enabled"] == 0 } {
					continue
				}

				set mount_type [dict get $volume_entry "type"]
				set mount_src [dict get $volume_entry "src"]
				set mount_dst [dict get $volume_entry "dst"]
				set mount_ro [dict get $volume_entry "readonly"]

				if { $mount_type == "bind" } {
					# if src is a relative path, convert to absolute path
					set mount_src "\$(readlink -f \"$mount_src\")"

					# if path does not exist, assume we want to create a directory
					if { [isNotOk "test -e $mount_src"] } {
						setStateErrorMsgNode $node_id "Created '$mount_src' on the host."
						rexec mkdir -p $mount_src
					}
				}

				set tmpstr "--mount type=$mount_type,src=\"$mount_src\",dst=\"$mount_dst\""
				if { $mount_ro } {
					append tmpstr ",ro"
				}

				append volumes_mounts_str "$tmpstr "
			}

			set port_forwards_str ""
			foreach port_forward_entry [getNodeDockerOptions $node_id "port_forwards"] {
				if { [dict get $port_forward_entry "enabled"] == 0 } {
					continue
				}

				set host_ip [dict get $port_forward_entry "host_ip"]
				if { $host_ip == "" } {
					set tmpstr ""
				} else {
					set tmpstr "$host_ip:"
				}

				set host_port [dict get $port_forward_entry "host_port"]
				set node_port [dict get $port_forward_entry "node_port"]
				set protocol [dict get $port_forward_entry "protocol"]

				append tmpstr "$host_port:$node_port"
				if { $protocol != "" } {
					append tmpstr "/$protocol"
				}

				append port_forwards_str "-p $tmpstr "
			}

			set env_vars_str ""
			foreach env_var_entry [getNodeDockerOptions $node_id "env_vars"] {
				if { [dict get $env_var_entry "enabled"] == 0 } {
					continue
				}

				set env_name [dict get $env_var_entry "env_name"]
				set env_value [dict get $env_var_entry "env_value"]

				append env_vars_str "--env $env_name=\"$env_value\" "
			}

			set custom_flags_str [getNodeDockerOptions $node_id "custom_flags"]

			set docker_cmd "docker run --detach --init --tty \
				--privileged --cap-add=ALL --net=imunes-bridge \
				--name $private_ns --hostname=[getNodeName $node_id] \
				--volume /tmp/.X11-unix:/tmp/.X11-unix \
				--sysctl net.ipv6.conf.all.disable_ipv6=0 \
				$cpus_str $volumes_mounts_str $env_vars_str $port_forwards_str \
				$custom_flags_str $ulimit_file_str $ulimit_proc_str $vroot"

			dputs "Node $node_id -> '$docker_cmd'"

			pipesExec "$docker_cmd" "hold"
		}

		if { $isOSfreebsd } {
			global vroot_unionfs vroot_linprocfs devfs_number

			# Prepare a copy-on-write filesystem root
			if { $vroot_unionfs } {
				# UNIONFS
				set VROOT_OVERLAY $VROOTDIR/$eid/upper/$node_id
				set VROOT_RUNTIME_DEV $VROOT_RUNTIME/dev

				pipesExec "mkdir -p $VROOT_RUNTIME" "hold"
				pipesExec "mkdir -p $VROOT_OVERLAY" "hold"

				set vroot [lindex [split [getNodeJailOptions $node_id "custom_vroot"] " "] end]
				if { $vroot == "" } {
					set vroot "$VROOTDIR/vroot"
				}

				pipesExec "mount_nullfs -o ro $vroot $VROOT_RUNTIME" "hold"
				pipesExec "mount_unionfs -o noatime $VROOT_OVERLAY $VROOT_RUNTIME" "hold"
			} else {
				# ZFS
				set VROOT_ZFS vroot/$eid/$node_id
				set VROOT_RUNTIME /$VROOT_ZFS
				set VROOT_RUNTIME_DEV $VROOT_RUNTIME/dev

				set snapshot [getNodeSnapshot $node_id]
				if { $snapshot == "" } {
					set snapshot "vroot/vroot@clean"
				}

				pipesExec "zfs clone $snapshot $VROOT_ZFS" "hold"
			}

			if { $vroot_linprocfs } {
				pipesExec "mount -t linprocfs linprocfs $VROOT_RUNTIME/compat/linux/proc" "hold"
				#HACK - linux_sun_jdk16 - java hack, won't work if proc isn't accessed
				#before execution, so we need to cd to it.
				pipesExec "cd $VROOT_RUNTIME/compat/linux/proc" "hold"
			}

			# Mount and configure a restricted /dev
			pipesExec "mount -t devfs devfs $VROOT_RUNTIME_DEV" "hold"
			pipesExec "devfs -m $VROOT_RUNTIME_DEV ruleset $devfs_number" "hold"
			pipesExec "devfs -m $VROOT_RUNTIME_DEV rule applyset" "hold"

			set custom_flags_str [getNodeJailOptions $node_id "custom_flags"]

			# create node jail
			set jail_cmd "jail -c name=$eid.$node_id path=$VROOT_RUNTIME securelevel=1 \
				host.hostname=\"[getNodeName $node_id]\" $custom_flags_str vnet persist"

			dputs "Node $node_id -> '$jail_cmd'"

			pipesExec "$jail_cmd" "hold"
		}
	}

	proc nodeCreate_check { eid node_id } {
		global isOSlinux isOSfreebsd

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		if { $isOSlinux } {
			set cmds "docker inspect --format '{{.State.Running}}' $private_ns"
		}

		if { $isOSfreebsd } {
			set cmds "jls -j $private_ns"
		}

		set cmds [getTimeoutCmd "nodecreate_timeout" $cmds]

		set created "false"
		try {
			rexec $cmds
		} on error {} {
		} on ok status {
			if { $isOSlinux } {
				set created [string match "*true*" $status]
			}

			if { $isOSfreebsd } {
				set created "true"
			}
		}

		if { $created } {
			removeStateNode $node_id "error"
		} else {
			addStateNode $node_id "error"
		}

		return $created
	}

	proc nodeNamespaceSetup { eid node_id } {
		global isOSlinux isOSfreebsd

		addStateNode $node_id "ns_creating"

		if { $isOSlinux } {
			set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
			if { [getNodeDockerOptions $node_id "external_attach"] != "true" } {
				pipesExec "docker network disconnect imunes-bridge $private_ns &" "hold"
			}

			# VIRTUALIZED nodes use docker netns
			set cmds "docker_ns=\$(docker inspect -f '{{.State.Pid}}' $private_ns)"
			set cmds "$cmds; ip netns del \$docker_ns > /dev/null 2>/dev/null"
			set cmds "$cmds; ip netns attach $private_ns \$docker_ns"
			set cmds "$cmds; docker exec -d $private_ns umount /etc/resolv.conf /etc/hosts"

			pipesExec "sh -c \'$cmds\' &" "hold"

			return
		}

		if { $isOSfreebsd } {
			# nothing
			return
		}
	}

	proc nodeNamespaceSetup_check { eid node_id } {
		global isOSlinux isOSfreebsd

		set created false
		if { $isOSlinux } {
			set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
			set cmds "ip netns exec $private_ns true"

			set cmds [getTimeoutCmd "nodecreate_timeout" $cmds]

			set created [isOk $cmds]
		}

		if { $isOSfreebsd } {
			set created true
		}

		if { $created } {
			if { "ns_creating" in [getStateNode $node_id] } {
				addStateNode $node_id "running"
			}
			removeStateNode $node_id "error"
		} else {
			addStateNode $node_id "error"
		}

		return $created
	}

	proc nodeInitConfigure { eid node_id } {
		global isOSlinux isOSfreebsd

		addStateNode $node_id "init_configuring"

		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id
		set init_fname "$VROOT_RUNTIME/init"

		set cmd {}
		foreach import_dir_entry [getNodeGenericOptions $node_id "imported_dirs"] {
			if { [dict get $import_dir_entry "enabled"] == 0 } {
				continue
			}

			set import_dir_path [dict get $import_dir_entry "path"]

			# overwrite with linked node dir if it exists
			if { [string index $import_dir_path 0] == "@" } {
				# remove @ and split by :
				set import_dir_path [join [lassign [split [string range $import_dir_path 1 end] ":"] linked_node_id] ":"]
				if { $linked_node_id ni [getFromRunning "node_list"] } {
					continue
				}
			}

			if { [string index $import_dir_path 0] == "#" } {
				global trigger_hook_names

				# remove # and split by :
				set import_dir_path [join [lassign [split [string range $import_dir_path 1 end] ":"] hook_name] ":"]
				set import_dir_path "/var/imunes/$hook_name/$import_dir_path"
			}

			lappend cmd "mkdir -p $import_dir_path"
			lappend cmd "tar xf ${import_dir_path}.tar -C $import_dir_path"
			lappend cmd "rm -f ${import_dir_path}.tar"
		}

		if { $isOSlinux } {
			array set sysctls {
				net.ipv4.icmp_ratelimit					0
				net.ipv4.icmp_echo_ignore_broadcasts	1
			}

			foreach {name val} [array get sysctls] {
				lappend cmd "sysctl $name=$val"
			}
			set cmds [join $cmd "; "]
		}

		if { $isOSfreebsd } {
			array set sysctls {
				net.inet.icmp.bmcastecho		1
				net.inet.icmp.icmplim			0
				net.inet.ip.maxfragsperpacket	64000
			}

			foreach {name val} [array get sysctls] {
				lappend cmd "sysctl $name=$val"
			}
			set cmds [join $cmd "; "]
		}

		set cmds "test -d $VROOT_RUNTIME || mkdir -p $VROOT_RUNTIME ; $cmds"

		set os_cmd [invokeNodeProc $node_id "getExecCommand" $eid $node_id "-d"]
		runNodeHook $os_cmd "pre-init_config"
		pipesExec "$os_cmd sh -c '$cmds ; touch $init_fname'" "hold"
		runNodeHook $os_cmd "post-init_config"
	}

	proc nodeInitConfigure_check { eid node_id } {
		global isOSlinux isOSfreebsd

		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id
		set init_fname "$VROOT_RUNTIME/init"

		set os_cmd [invokeNodeProc $node_id "getExecCommand" $eid $node_id]
		if { $isOSlinux } {
			set cmds "$os_cmd ls $init_fname >/dev/null"
		}

		if { $isOSfreebsd } {
			set cmds "$os_cmd rm $init_fname >/dev/null"
		}

		set cmds [getTimeoutCmd "nodecreate_timeout" $cmds]

		set created [isOk $cmds]
		if { $created } {
			removeStateNode $node_id "error"
		} else {
			addStateNode $node_id "error"
		}

		return $created
	}

	proc nodePhysIfacesCreate { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		addStateNode $node_id "pifaces_creating"

		set os_cmd [invokeNodeProc $node_id "getExecCommand" $eid $node_id "-d"]
		runNodeHook $os_cmd "pre-pifaces_create"

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		set public_ns [invokeNodeProc $node_id "getPublicNs" $eid $node_id]
		foreach iface_id $ifaces {
			addStateNodeIface $node_id $iface_id "creating"

			lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] iface_name public_iface -

			if { $isOSlinux } {
				if { [getIfcType $node_id $iface_id] == "stolen" } {
					# private hook is interface name in this case
					captureExtIfcByName $eid $iface_name $node_id
					setToRunning "${node_id}|${iface_id}_active_name" $iface_name
				} else {

					# Create a veth pair - private hook in node NS and public hook
					# in the experiment NS
					createNsVethPair \
						"$eid-$node_id-$iface_id" $iface_name $private_ns "" \
						"$eid-$public_iface" $public_iface $public_ns "config"
				}
			}

			if { $isOSfreebsd } {
				if { [getIfcType $node_id $iface_id] == "stolen" } {
					# private hook is interface name in this case
					captureExtIfcByName $eid $iface_name $node_id
					setToRunning "${node_id}|${iface_id}_active_name" $iface_name
				} else {
					# save newly created ngnodeX into a shell variable ifid and
					# rename the ng node to $public_iface (unique to this experiment)
					set cmds "ifid=\$(printf \"mkpeer . eiface $public_iface ether \n"
					set cmds "$cmds show .:$public_iface\" | jexec $eid ngctl -f - | head -n1 | cut -d' ' -f4)"
					set cmds "$cmds; jexec $eid ifconfig \$ifid name $public_iface"
					set cmds "$cmds; jexec $eid ngctl name \$ifid: $public_iface"

					pipesExec $cmds "hold"
					pipesExec "jexec $eid ifconfig $public_iface vnet $node_id" "hold"
					pipesExec "jexec $private_ns ifconfig $public_iface name $iface_name" "hold"

					set ether [getIfcMACaddr $node_id $iface_id]
					if { $ether == "" } {
						set ether [autoMACaddr $node_id $iface_id]
					}

					global ifc_dad_disable
					if { $ifc_dad_disable } {
						pipesExec "jexec $private_ns sysctl net.inet6.ip6.dad_count=0" "hold"
					}

					pipesExec "jexec $private_ns ifconfig $iface_name link $ether" "hold"
				}
			}
		}

		runNodeHook $os_cmd "post-pifaces_create"
	}

	proc nodePhysIfacesDirectCreate { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		set public_ns [invokeNodeProc $node_id "getPublicNs" $eid $node_id]

		set os_cmd [invokeNodeProc $node_id "getExecCommand" $eid $node_id "-d"]
		runNodeHook $os_cmd "pre-pifaces_dcreate"

		if { $isOSlinux } {
			foreach iface_id $ifaces {
				lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] iface_name public_iface -
				lassign [logicalPeerByIfc $node_id $iface_id] peer_id peer_iface_id

				if {
					"creating" in [getStateNodeIface $node_id $iface_id]
				} {
					set peer_public_ns [invokeNodeProc $peer_id "getPublicNs" $eid $peer_id]

					if { [getNodeType $peer_id] == "rj45" } {
						# non-VLAN rj45 interfaces are left in the default netns
						if { [getIfcVlanTag $peer_id $peer_iface_id] == "" || [getIfcVlanDev $peer_id $peer_iface_id] == "" } {
							global devfs_number

							set peer_public_ns "imunes_$devfs_number"
						}

						lassign [invokeNodeProc $peer_id "getHookData" $peer_id $peer_iface_id] peer_iface_name - -

						set full_virtual_ifc $eid-$node_id-$iface_id
						set cmds "ip -n $peer_public_ns link add link $peer_iface_name name $full_virtual_ifc netns $private_ns type"

						if { "wireless" ni [getStateNodeIface $peer_id $peer_iface_id] } {
							# not wireless, so MAC address can be changed
							set ether [getIfcMACaddr $node_id $iface_id]

							# you can set macvlan mode to bridge to enable bridging of nodes in the same experiment
							set cmds "$cmds macvlan mode private"
							set cmds "$cmds ; ip -n $private_ns link set $full_virtual_ifc address $ether"
						} else {
							# we cannot use macvlan on wireless interfaces, so MAC address cannot be changed
							set cmds "$cmds ipvlan mode l2"
						}
						pipesExec "$cmds" "hold"

						set cmds "ip -n $peer_public_ns link set $peer_iface_name up"

						# assign the name of our interface to the created macvlan/ipvlan
						set cmds "$cmds ; ip -n $private_ns link set $full_virtual_ifc name $iface_name up"

						pipesExec "$cmds" "hold"

						continue
					}

					# skip creating our iface since it's already being created by peer,
					# just pull it in our netns and rename it
					pipesExec "ip -n $peer_public_ns link set $eid-$node_id-$iface_id netns $private_ns name $iface_name up" "hold"

					continue
				}

				if { [getNodeType $peer_id] == "rj45" } {
					# rj45 will call us - or sort rj45 nodes before rest of the node types?
					continue
				}

				addStateNode $node_id "pifaces_creating"
				addStateNodeIface $node_id $iface_id "creating"

				set public_ns [invokeNodeProc $node_id "getPublicNs" $eid $node_id]

				set peer_running [isRunningNode $peer_id]
				if { ! [isRunningNodeIface $peer_id $peer_iface_id] } {
					if { $peer_running } {
						addStateNode $peer_id "pifaces_creating"
						addStateNodeIface $peer_id $peer_iface_id "creating"

						# Create a veth pair - private hook in node NS and other hook
						# in the other node NS
						createNsVethPair \
							"$eid-$node_id-$iface_id" $iface_name $private_ns "" \
							"$eid-$peer_id-$peer_iface_id" "$eid-$peer_id-$peer_iface_id" $public_ns ""
					} else {
						createNsVethPair \
							"$eid-$node_id-$iface_id" $iface_name $private_ns "" \
							"$eid-$node_id-$iface_id" "$node_id-$iface_id" $public_ns ""
					}
				}

				# invoke other node
				if { $peer_running } {
					invokeNodeProc $peer_id "nodePhysIfacesDirectCreate" $eid $peer_id $peer_iface_id
				}
			}
		}

		if { $isOSfreebsd } {
			# same as regular interfaces
			return [invokeNodeProc $node_id "nodePhysIfacesCreate" $eid $node_id $ifaces]
		}

		runNodeHook $os_cmd "post-pifaces_dcreate"
	}

	proc nodeLogIfacesCreate { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		foreach iface_id $ifaces {
			if { ! [isIfcLogical $node_id $iface_id] } {
				set ifaces [removeFromList $ifaces $iface_id]
			}
		}

		# mark interfaces to skip
		invokeNodeProc $node_id "checkIfacesPrerequisites" $eid $node_id $ifaces

		addStateNode $node_id "lifaces_creating"

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		set cmds ""
		foreach iface_id $ifaces {
			if { [isErrorNodeIface $node_id $iface_id] } {
				continue
			}

			set iface_name [getIfcName $node_id $iface_id]
			if { $isOSlinux } {
				switch -exact [getIfcType $node_id $iface_id] {
					vlan {
						set tag [getIfcVlanTag $node_id $iface_id]
						set dev_name [getIfcVlanDev $node_id $iface_id]
						set dev_id [ifaceIdFromName $node_id $dev_name]
						if {
							$tag != "" && $dev_name != "" &&
							([isRunningNodeIface $node_id $dev_id] ||
							"creating" in [getStateNodeIface $node_id $dev_id]) &&
							"destroying" ni [getStateNodeIface $node_id $dev_id]
						} {
							append cmds "[getVlanTagIfcCmd $iface_name $dev_name $tag]; "
							addStateNodeIface $node_id $iface_id "creating"
						}
					}
					lo {
						if { $iface_name != "lo0" } {
							addStateNodeIface $node_id $iface_id "creating"
							append cmds "ip link add $iface_name type dummy; "
							append cmds "ip link set $iface_name up; "
						} else {
							addStateNodeIface $node_id $iface_id "running"
							append cmds "ip link set dev lo down 2>/dev/null; "
							append cmds "ip link set dev lo name lo0 2>/dev/null; "
							append cmds "ip a flush lo0 2>/dev/null; "
						}
					}
					default {
					}
				}
			}

			if { $isOSfreebsd } {
				switch -exact [getIfcType $node_id $iface_id] {
					vlan {
						set tag [getIfcVlanTag $node_id $iface_id]
						set dev_name [getIfcVlanDev $node_id $iface_id]
						set dev_id [ifaceIdFromName $node_id $dev_name]
						if {
							$tag != "" && $dev_name != "" &&
							([isRunningNodeIface $node_id $dev_id] ||
							"creating" in [getStateNodeIface $node_id $dev_id])
						} {
							append cmds "[getVlanTagIfcCmd $iface_name $dev_name $tag]; "
							addStateNodeIface $node_id $iface_id "creating"
						}
					}
					lo {
						if { $iface_name != "lo0" } {
							addStateNodeIface $node_id $iface_id "creating"
							append cmds "ifconfig $iface_name create; "
						} else {
							addStateNodeIface $node_id $iface_id "running"
						}
					}
					default {
					}
				}
			}
		}

		set os_cmd [invokeNodeProc $node_id "getExecCommand" $eid $node_id "-d"]
		runNodeHook $os_cmd "pre-lifaces_create"

		if { $cmds != "" } {
			if { $isOSlinux } {
				pipesExec "ip netns exec $private_ns sh -c '$cmds' &" "hold"
			}

			if { $isOSfreebsd } {
				pipesExec "jexec $private_ns sh -c '$cmds'" "hold"
			}
		}

		runNodeHook $os_cmd "post-lifaces_create"
	}

	proc nodePhysIfacesCreate_check { eid node_id ifaces } {
		# same as L2
		return [invokeTypeProc "genericL2" "nodePhysIfacesCreate_check" $eid $node_id $ifaces]
	}

	proc nodeIfacesConfigure { eid node_id ifaces } {
		addStateNode $node_id "ifaces_configuring"

		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id
		set startup_fname "$VROOT_RUNTIME/IFACES_CONFIG.pid"
		set out_ifaces_log "$VROOT_RUNTIME/out_ifaces.log"
		set err_ifaces_log "$VROOT_RUNTIME/err_ifaces.log"

		foreach iface_id $ifaces {
			if { [isRunningNodeIface $node_id $iface_id] } {
				continue
			}
			set ifaces [removeFromList $ifaces $iface_id]

			if { ! [isErrorNodeIface $node_id $iface_id] } {
				continue
			}

			addStateNodeIface $node_id $iface_id "error"
			if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
				setStateErrorMsgNodeIface $node_id $iface_id "Interface $iface_id '[getIfcName $node_id $iface_id]' not created, skip configuration."
			}
		}

		set custom_selected [getNodeCustomConfigSelected $node_id "IFACES_CONFIG"]
		if { [getNodeCustomEnabled $node_id] == true && $custom_selected ni "\"\" DISABLED" } {
			set bootcmd [getNodeCustomConfigCommand $node_id "IFACES_CONFIG" $custom_selected]
			set bootcfg [getNodeCustomConfig $node_id "IFACES_CONFIG" $custom_selected]
			set confFile "$VROOT_RUNTIME/custom_ifaces.conf"
		} else {
			set bootcfg [invokeNodeProc $node_id "generateConfigIfaces" $node_id $ifaces]
			set bootcmd [invokeNodeProc $node_id "bootcmd" $node_id]
			set confFile "$VROOT_RUNTIME/boot_ifaces.conf"
		}

		writeDataToNodeFile $node_id $startup_fname ""

		set cfg "set -x\necho $$ > $startup_fname\n[join $bootcfg "\n"]"
		writeDataToNodeFile $node_id $confFile $cfg

		set cmds "test -d $VROOT_RUNTIME || mkdir -p $VROOT_RUNTIME ;"
		set cmds "$cmds rm -f $out_ifaces_log $err_ifaces_log ;"
		set cmds "$cmds $bootcmd $confFile > $out_ifaces_log 2> $err_ifaces_log ;"

		set os_cmd [invokeNodeProc $node_id "getExecCommand" $eid $node_id "-d"]

		runNodeHook $os_cmd "pre-ifaces_config"
		pipesExec "$os_cmd sh -c '$cmds' &" "hold"
		runNodeHook $os_cmd "post-ifaces_config"
	}

	proc nodeIfacesConfigure_check { eid node_id ifaces } {
		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id
		set startup_fname "$VROOT_RUNTIME/IFACES_CONFIG.pid"

		set cmds "test -n \"\$(cat $startup_fname 2>/dev/null)\" && ! kill -0 \$(cat $startup_fname) 2>/dev/null"

		set os_cmd [invokeNodeProc $node_id "getExecCommand" $eid $node_id "-t"]
		set cmds "$os_cmd sh -c '$cmds'"

		set cmds [getTimeoutCmd "ifacesconf_timeout" $cmds]

		set ifaces_configured [isOk $cmds]
		if { $ifaces_configured } {
			removeStateNode $node_id "error"
		} else {
			addStateNode $node_id "error"
		}

		return $ifaces_configured
	}

	proc attachToLink { eid node_id iface_id link_id direct } {
		global isOSlinux isOSfreebsd

		if { $isOSlinux } {
			if { $direct } {
				# link already created, except in some cases

				return
			}

			lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] - public_iface -
			setNsIfcMaster $eid $public_iface $link_id "up"

			return
		}

		if { $isOSfreebsd } {
			# nothing to do, createLinkBetween does everything
			return
		}
	}

	proc nodeConfigure { eid node_id } {
		addStateNode $node_id "node_configuring"

		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id
		set startup_fname "$VROOT_RUNTIME/NODE_CONFIG.pid"
		set out_log "$VROOT_RUNTIME/out.log"
		set err_log "$VROOT_RUNTIME/err.log"

		set custom_selected [getNodeCustomConfigSelected $node_id "NODE_CONFIG"]
		if { [getNodeCustomEnabled $node_id] == true && $custom_selected ni "\"\" DISABLED" } {
			set bootcmd [getNodeCustomConfigCommand $node_id "NODE_CONFIG" $custom_selected]
			set bootcfg [getNodeCustomConfig $node_id "NODE_CONFIG" $custom_selected]
			set bootcfg [concat $bootcfg [invokeNodeProc $node_id "generateConfig" $node_id]]
			set confFile "$VROOT_RUNTIME/custom.conf"
		} else {
			set bootcfg [invokeNodeProc $node_id "generateConfig" $node_id]
			set bootcmd [invokeNodeProc $node_id "bootcmd" $node_id]
			set confFile "$VROOT_RUNTIME/boot.conf"
		}

		generateHostsFile $node_id

		writeDataToNodeFile $node_id $startup_fname ""

		set cfg "set -x\necho $$ > $startup_fname\n[join $bootcfg "\n"]"
		writeDataToNodeFile $node_id $confFile $cfg

		set cmds "test -d $VROOT_RUNTIME || mkdir -p $VROOT_RUNTIME ;"
		set cmds "$cmds rm -f $out_log $err_log ;"
		set cmds "$cmds $bootcmd $confFile > $out_log 2> $err_log ;"

		set os_cmd [invokeNodeProc $node_id "getExecCommand" $eid $node_id "-d"]

		runNodeHook $os_cmd "pre-node_config"
		pipesExec "$os_cmd sh -c '$cmds' &" "hold"
		runNodeHook $os_cmd "post-node_config"
	}

	proc nodeConfigure_check { eid node_id } {
		set os_cmd [invokeNodeProc $node_id "getExecCommand" $eid $node_id "-t"]

		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id
		set startup_fname "$VROOT_RUNTIME/NODE_CONFIG.pid"

		set cmds "test -n \"\$(cat $startup_fname 2>/dev/null)\" && ! kill -0 \$(cat $startup_fname) 2>/dev/null"
		set cmds "$os_cmd sh -c '$cmds'"

		set cmds [getTimeoutCmd "nodeconf_timeout" $cmds]

		set node_configured [isOk $cmds]
		if { $node_configured } {
			removeStateNode $node_id "error"
		} else {
			addStateNode $node_id "error"
		}

		return $node_configured
	}

	proc isNodeError { eid node_id } {
		set os_cmd [invokeNodeProc $node_id "getExecCommand" $eid $node_id]

		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id
		set err_log "$VROOT_RUNTIME/err.log"

		set cmds "test ! -f $err_log || sed \"/^+ /d\" $err_log"
		set cmds "$os_cmd sh -c '$cmds'"

		set cmds [getTimeoutCmd "nodeconf_timeout" $cmds]

		try {
			rexec $cmds
		} on error {} {
			return "timeout"
		} on ok errlog {
			if { $errlog == "" } {
				return false
			}

			return true
		}
	}

	proc isNodeErrorIfaces { eid node_id } {
		set os_cmd [invokeNodeProc $node_id "getExecCommand" $eid $node_id]

		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id
		set err_ifaces_log "$VROOT_RUNTIME/err_ifaces.log"

		set cmds "test ! -f $err_ifaces_log || sed \"/^+ /d\" $err_ifaces_log"
		set cmds "$os_cmd sh -c '$cmds'"

		set cmds [getTimeoutCmd "ifacesconf_timeout" $cmds]

		try {
			rexec $cmds
		} on error {} {
			return "timeout"
		} on ok errlog {
			if { $errlog == "" } {
				return false
			}

			return true
		}
	}

	################################################################################
	############################# TERMINATE PROCEDURES #############################
	################################################################################

	proc nodeUnconfigure { eid node_id } {
		addStateNode $node_id "node_unconfiguring"

		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id
		set startup_fname "$VROOT_RUNTIME/NODE_UNCONFIG.pid"
		set confFile "$VROOT_RUNTIME/unboot.conf"
		set out_log "$VROOT_RUNTIME/out.log"
		set err_log "$VROOT_RUNTIME/err.log"

		set custom_selected [getNodeCustomConfigSelected $node_id "NODE_CONFIG"]
		if { [getNodeCustomEnabled $node_id] == true && $custom_selected ni "\"\" DISABLED" } {
			return
		}

		set bootcfg [invokeNodeProc $node_id "generateUnconfig" $node_id]
		set bootcmd [invokeNodeProc $node_id "bootcmd" $node_id]

		writeDataToNodeFile $node_id $startup_fname ""

		set cfg "set -x\necho $$ > $startup_fname\n[join $bootcfg "\n"]"
		writeDataToNodeFile $node_id $confFile $cfg

		set cmds "test -d $VROOT_RUNTIME || mkdir -p $VROOT_RUNTIME ;"
		set cmds "$cmds rm -f $out_log $err_log ;"
		set cmds "$cmds $bootcmd $confFile > $out_log 2> $err_log ;"

		set os_cmd [invokeNodeProc $node_id "getExecCommand" $eid $node_id "-d"]
		runNodeHook $os_cmd "pre-node_unconfig"
		pipesExec "$os_cmd sh -c '$cmds'" "hold"
		runNodeHook $os_cmd "post-node_unconfig"
	}

	proc nodeUnconfigure_check { eid node_id } {
		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id
		set startup_fname "$VROOT_RUNTIME/NODE_UNCONFIG.pid"

		set custom_selected [getNodeCustomConfigSelected $node_id "NODE_CONFIG"]
		if { [getNodeCustomEnabled $node_id] == true && $custom_selected ni "\"\" DISABLED" } {
			removeStateNode $node_id "error"

			return true
		}

		set os_cmd [invokeNodeProc $node_id "getExecCommand" $eid $node_id "-t"]

		set cmds "test -n \"\$(cat $startup_fname 2>/dev/null)\" && ! kill -0 \$(cat $startup_fname) 2>/dev/null"
		set cmds "$os_cmd sh -c '$cmds'"

		set cmds [getTimeoutCmd "nodeconf_timeout" $cmds]

		set node_unconfigured [isOk $cmds]
		if { $node_unconfigured } {
			removeStateNode $node_id "error"
		} else {
			addStateNode $node_id "error"
		}

		return $node_unconfigured
	}

	proc nodeShutdown { eid node_id } {
		global isOSlinux isOSfreebsd

		addStateNode $node_id "node_shutting"

		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id
		set shut_fname "$VROOT_RUNTIME/shut"

		killExtProcess "wireshark.*[getNodeName $node_id].*\\($eid\\)"
		killExtProcess "socat.*$eid/$node_id.*"

		set os_cmd [invokeNodeProc $node_id "getExecCommand" $eid $node_id "-d"]
		runNodeHook $os_cmd "pre-node_shutdown"

		pipesExec "$os_cmd sh -c 'test -d $VROOT_RUNTIME || mkdir -p $VROOT_RUNTIME'" "hold"
		if { $isOSlinux } {
			# kill all processes except pid 1 and its child(ren)
			pipesExec "$os_cmd sh -c 'killall5 -9 -o 1 -o \$(pgrep -P 1) ; touch $shut_fname'" "hold"
		}

		if { $isOSfreebsd } {
			pipesExec "$os_cmd kill -9 -1 2> /dev/null" "hold"
			pipesExec "$os_cmd tcpdrop -a 2> /dev/null" "hold"

			pipesExec "$os_cmd touch $shut_fname" "hold"
		}

		runNodeHook $os_cmd "post-node_shutdown"
	}

	proc nodeShutdown_check { eid node_id } {
		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id
		set shut_fname "$VROOT_RUNTIME/shut"

		set os_cmd [invokeNodeProc $node_id "getExecCommand" $eid $node_id]
		set cmds "rm $shut_fname >/dev/null"
		set cmds "$os_cmd sh -c '$cmds'"

		set cmds [getTimeoutCmd "nodeconf_timeout" $cmds]

		set shut [isOk $cmds]
		if { $shut } {
			removeStateNode $node_id "error"
		} else {
			addStateNode $node_id "error"
		}

		return $shut
	}

	proc detachFromLink { eid node_id iface_id link_id { direct "" } } {
		global isOSlinux isOSfreebsd

		if { $isOSlinux } {
			if { $direct } {
				# actually destroying phys interfaces

				return
			}

			lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] - public_iface -
			pipesExec "ip -n $eid link set $public_iface nomaster down"

			return
		}

		if { $isOSfreebsd } {
			# nothing to do, destroyLinkBetween does everything
			return
		}
	}

	proc nodeIfacesUnconfigure { eid node_id ifaces } {
		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id
		set startup_fname "$VROOT_RUNTIME/IFACES_UNCONFIG.pid"
		set confFile "$VROOT_RUNTIME/unboot_ifaces.conf"
		set out_ifaces_log "$VROOT_RUNTIME/out_ifaces.log"
		set err_ifaces_log "$VROOT_RUNTIME/err_ifaces.log"

		set custom_selected [getNodeCustomConfigSelected $node_id "IFACES_CONFIG"]
		if { [getNodeCustomEnabled $node_id] == true && $custom_selected ni "\"\" DISABLED" } {
			return
		}

		# skip interfaces in error state
		foreach iface_id $ifaces {
			if { ! [isRunningNodeIface $node_id $iface_id] } {
				set ifaces [removeFromList $ifaces $iface_id]
			}
		}

		if { $ifaces == {} } {
			return
		}

		addStateNode $node_id "ifaces_unconfiguring"

		set bootcfg [invokeNodeProc $node_id "generateUnconfigIfaces" $node_id $ifaces]
		set bootcmd [invokeNodeProc $node_id "bootcmd" $node_id]

		writeDataToNodeFile $node_id $startup_fname ""

		set cfg "set -x\necho $$ > $startup_fname\n[join $bootcfg "\n"]"
		writeDataToNodeFile $node_id $confFile $cfg

		set cmds "test -d $VROOT_RUNTIME || mkdir -p $VROOT_RUNTIME ;"
		set cmds "$cmds rm -f $out_ifaces_log $err_ifaces_log ;"
		set cmds "$cmds $bootcmd $confFile > $out_ifaces_log 2> $err_ifaces_log ;"

		set os_cmd [invokeNodeProc $node_id "getExecCommand" $eid $node_id "-d"]
		runNodeHook $os_cmd "pre-ifaces_unconfig"
		pipesExec "$os_cmd sh -c '$cmds'" "hold"
		runNodeHook $os_cmd "post-ifaces_unconfig"
	}

	proc nodeIfacesUnconfigure_check { eid node_id ifaces } {
		set os_cmd [invokeNodeProc $node_id "getExecCommand" $eid $node_id "-t"]

		set VROOT_RUNTIME [getVrootDir]/$eid/$node_id
		set startup_fname "$VROOT_RUNTIME/IFACES_UNCONFIG.pid"

		set cmds "test -n \"\$(cat $startup_fname 2>/dev/null)\" && ! kill -0 \$(cat $startup_fname) 2>/dev/null"
		set cmds "$os_cmd sh -c '$cmds'"

		set cmds [getTimeoutCmd "ifacesconf_timeout" $cmds]

		set ifaces_unconfigured [isOk $cmds]
		if { $ifaces_unconfigured } {
			removeStateNode $node_id "error"
		} else {
			addStateNode $node_id "error"
		}

		return $ifaces_unconfigured
	}

	proc nodeLogIfacesDestroy { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		foreach iface_id $ifaces {
			# skip lo0 as it cannot be deleted
			if { [getIfcName $node_id $iface_id] == "lo0" } {
				set ifaces [removeFromList $ifaces $iface_id]
				removeStateNodeIface $node_id $iface_id "running"
			}
		}

		if { $ifaces == {} } {
			return
		}

		addStateNode $node_id "lifaces_destroying"

		set os_cmd [invokeNodeProc $node_id "getExecCommand" $eid $node_id "-d"]
		runNodeHook $os_cmd "pre-lifaces_destroy"

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		foreach iface_id $ifaces {
			addStateNodeIface $node_id $iface_id "destroying"

			set iface_name [getIfcName $node_id $iface_id]
			if { $isOSlinux } {
				pipesExec "ip -n $private_ns link del $iface_name" "hold"
			}

			if { $isOSfreebsd } {
				pipesExec "jexec $private_ns ifconfig $iface_name destroy" "hold"
			}
		}

		runNodeHook $os_cmd "post-lifaces_destroy"
	}

	proc nodePhysIfacesDestroy { eid node_id ifaces { are_direct "" } } {
		global isOSlinux isOSfreebsd

		set os_cmd [invokeNodeProc $node_id "getExecCommand" $eid $node_id "-d"]

		if { $isOSlinux } {
			runNodeHook $os_cmd "pre-pifaces_destroy"

			# same as L2
			set retv [invokeTypeProc "genericL2" "nodePhysIfacesDestroy" $eid $node_id $ifaces]

			runNodeHook $os_cmd "post-pifaces_destroy"

			return $retv
		}

		addStateNode $node_id "pifaces_destroying"

		if { $isOSfreebsd } {
			if { $are_direct == "" } {
				runNodeHook $os_cmd "pre-pifaces_destroy"
			}

			set ngcmds ""
			foreach iface_id $ifaces {
				addStateNodeIface $node_id $iface_id "destroying"

				if { [getIfcType $node_id $iface_id] == "stolen" } {
					set iface_name [getIfcName $node_id $iface_id]
					releaseExtIfcByName $eid $iface_name $node_id
					unsetRunning "${node_id}|${iface_id}_active_name"
				} else {
					lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] - public_iface -

					set ngcmds "$ngcmds rmnode $public_iface:\n"
				}
			}

			if { $ngcmds != "" } {
				pipesExec "printf \"$ngcmds\" | jexec $eid ngctl -f -" "hold"
			}

			if { $are_direct == "" } {
				runNodeHook $os_cmd "post-pifaces_destroy"
			}
		}
	}

	proc nodePhysIfacesDirectDestroy { eid node_id ifaces } {
		global isOSlinux isOSfreebsd

		set os_cmd [invokeNodeProc $node_id "getExecCommand" $eid $node_id "-d"]
		runNodeHook $os_cmd "pre-pifaces_ddestroy"

		if { $isOSlinux } {
			# same as L2
			set retv [invokeTypeProc "genericL2" "nodePhysIfacesDirectDestroy" $eid $node_id $ifaces]
		}

		if { $isOSfreebsd } {
			# same as regular interfaces
			set retv [invokeNodeProc $node_id "nodePhysIfacesDestroy" $eid $node_id $ifaces "are_direct"]
		}

		runNodeHook $os_cmd "post-pifaces_ddestroy"

		return $retv
	}

	proc nodeIfacesDestroy_check { eid node_id ifaces } {
		# same as L2
		return [invokeTypeProc "genericL2" "nodeIfacesDestroy_check" $eid $node_id $ifaces]
	}

	proc nodeDestroy { eid node_id } {
		global isOSlinux isOSfreebsd

		addStateNode $node_id "node_destroying"

		set os_cmd [invokeNodeProc $node_id "getExecCommand" $eid $node_id "-d"]
		runNodeHook $os_cmd "pre-node_destroy"

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		if { $isOSlinux } {
			# remove node virtual interfaces
			pipesExec "$os_cmd sh -c 'for iface in `ls /sys/class/net` ; do ip link del \$iface; done'" "hold"

			# remove node container
			pipesExec "docker kill $private_ns" "hold"
			pipesExec "docker rm $private_ns" "hold"
		}

		if { $isOSfreebsd } {
			# see runtime/terminate.tcl - undeployCfg procedure for explanation
			# on why do we remove interfaces here

			# remove node virtual interfaces and rename remaining ngeth
			# interfaces so they are unique for later deletion
			pipesExec "$os_cmd sh -c 'for iface in \$(ifconfig -l); do test \"\$iface\" == \"lo0\" && continue ; ifconfig \$iface destroy || ifconfig \$iface name $node_id-\$iface; done'" "hold"

			# ---- no point of waiting for interfaces to be destroyed ----
			# wait for existing ng commands to finish to prevent crash in FreeBSD
			#set maxcnt [expr [getTimeout "ifacesconf_timeout"] * 10]
			#pipesExec "$os_cmd sh -c 'for i in \$(seq 1 $maxcnt); do sleep 0.1 ; x=\$(ngctl l | grep \"ngctl\" | wc -l) ; test \$x -eq 1 && break ; done'" "hold"

			# remove node jail
			pipesExec "jail -r $private_ns" "hold"

			# delete remaining ngeth interfaces from eid jail
			set ngcmds ""
			foreach iface_id [ifcList $node_id] {
				set ngcmds "$ngcmds rmnode $node_id-[getIfcName $node_id $iface_id]:\n"
				set ngcmds "$ngcmds rmnode $node_id-$iface_id:\n"
			}

			pipesExec "printf \"$ngcmds\" | jexec $eid ngctl -f -" "hold"
		}
	}

	proc nodeDestroy_check { eid node_id } {
		global isOSlinux isOSfreebsd

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		if { $isOSlinux } {
			set cmds "docker inspect --format '{{.State.Running}}' $private_ns"
		}

		if { $isOSfreebsd } {
			set cmds "jls -d -j $private_ns"
		}

		set cmds [getTimeoutCmd "nodecreate_timeout" $cmds]

		set destroyed false
		try {
			rexec $cmds
		} on ok {} {
			return false
		} on error status {
			if { $isOSlinux } {
				set destroyed [string match -nocase "*Error: No such object: $private_ns*" $status]
			}

			if { $isOSfreebsd } {
				set destroyed true
			}
		}

		if { $destroyed } {
			removeStateNode $node_id "error"
		} else {
			addStateNode $node_id "error"
		}

		return $destroyed
	}

	proc nodeDestroyFS { eid node_id } {
		global isOSlinux isOSfreebsd

		addStateNode $node_id "node_destroying_fs"

		if { $isOSlinux } {
			set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
			pipesExec "ip netns del $private_ns" "hold"

			pipesExec "rm -fr [getVrootDir]/$eid/$node_id" "hold"
		}

		if { $isOSfreebsd } {
			global vroot_unionfs vroot_linprocfs

			set VROOTDIR [getVrootDir]
			set VROOT_RUNTIME $VROOTDIR/$eid/$node_id
			set VROOT_OVERLAY $VROOTDIR/$eid/upper/$node_id
			set VROOT_RUNTIME_DEV $VROOT_RUNTIME/dev
			pipesExec "umount -f $VROOT_RUNTIME_DEV" "hold"
			if { $vroot_unionfs } {
				# 1st: unionfs RW overlay
				pipesExec "umount -f $VROOT_RUNTIME" "hold"
				# 2nd: nullfs RO loopback
				pipesExec "umount -f $VROOT_RUNTIME" "hold"
				pipesExec "rm -rf $VROOT_RUNTIME" "hold"
				# 3rd: node unionfs upper
				pipesExec "rm -rf $VROOT_OVERLAY" "hold"
			}

			if { $vroot_linprocfs } {
				pipesExec "umount -f $VROOT_RUNTIME/compat/linux/proc" "hold"
			}
		}
	}

	proc nodeDestroyFS_check { eid node_id } {
		global isOSlinux isOSfreebsd

		set destroyed_ns true
		if { $isOSlinux } {
			set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
			if { [isOk ip netns exec $private_ns true] } {
				set destroyed_ns false
			}
		}

		set destroyed_fs true
		if { $destroyed_ns } {
			if { [isOk ls -d [getVrootDir]/$eid/$node_id] } {
				set destroyed_fs false
			}
		}

		if { $destroyed_fs } {
			removeStateNode $node_id "error running"
		} else {
			addStateNode $node_id "error"
		}

		return $destroyed_fs
	}
}
