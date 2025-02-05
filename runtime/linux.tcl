global VROOT_MASTER ULIMIT_FILE ULIMIT_PROC
set VROOT_MASTER "imunes/template"
set ULIMIT_FILE "1024:16384"
set ULIMIT_PROC "1024:2048"

#****f* linux.tcl/l2node.nodeCreate
# NAME
#   l2node.nodeCreate -- nodeCreate
# SYNOPSIS
#   l2node.nodeCreate $eid $node_id
# FUNCTION
#   Procedure l2node.nodeCreate creates a new netgraph node of the appropriate type.
# INPUTS
#   * eid -- experiment id
#   * node_id -- id of the node (type of the node is either lanswitch, vlanswitch or hub)
#****
proc l2node.nodeCreate { eid node_id } {
    set type [getNodeType $node_id]

    set ageing_time ""
    set vlanfiltering ""

    if { $type == "hub" } {
	set ageing_time "ageing_time 0"
    } elseif { $type == "vlanswitch" } {
	set vlanfiltering "vlan_filtering 1"
    }

    set nodeNs [getNodeNetns $eid $node_id]
    pipesExec "ip netns exec $nodeNs ip link add name $node_id type bridge $vlanfiltering $ageing_time" "hold"
    pipesExec "ip netns exec $nodeNs ip link set $node_id up" "hold"
}

#****f* linux.tcl/l2node.nodeDestroy
# NAME
#   l2node.nodeDestroy -- destroy
# SYNOPSIS
#   l2node.nodeDestroy $eid $node_id
# FUNCTION
#   Destroys a l2 node.
# INPUTS
#   * eid -- experiment id
#   * node_id -- id of the node
#****
proc l2node.nodeDestroy { eid node_id } {
    set type [getNodeType $node_id]

    set nodeNs [getNodeNetns $eid $node_id]

    set nsstr ""
    if { $nodeNs != "" } {
	set nsstr "-n $nodeNs"
    }
    pipesExec "ip $nsstr link delete $node_id" "hold"

    removeNodeNetns $eid $node_id
}

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
    catch { exec docker inspect -f "{{.GraphDriver.Data.MergedDir}}" $docker_id } node_dir

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
    catch { eval [concat "exec docker exec " [getFromRunning "eid"].$node_id $cmd] } output

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
	set status [ catch { exec which $app } err ]
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
#   the which command.
# INPUTS
#   * node_id -- virtual node id
#   * app_list -- list of applications
# RESULT
#   * returns 0 if the applications exist, otherwise it returns 1.
#****
proc checkForApplications { node_id app_list } {
    foreach app $app_list {
    set status [ catch { exec docker exec [getFromRunning "eid"].$node_id which $app } err ]
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
    set eid [getFromRunning "eid"]

    if { [checkForExternalApps "startxcmd"] == 0 && \
	[checkForApplications $node_id "wireshark"] == 0 } {

        startXappOnNode $node_id "wireshark -ki $iface_name"
    } else {
	set wiresharkComm ""
	foreach wireshark "wireshark wireshark-gtk wireshark-qt" {
	    if { [checkForExternalApps $wireshark] == 0 } {
		set wiresharkComm $wireshark
		break
	    }
	}

	if { $wiresharkComm != "" } {
	    exec docker exec $eid.$node_id tcpdump -s 0 -U -w - -i $iface_name 2>/dev/null |\
		$wiresharkComm -o "gui.window_title:$iface_name@[getNodeName $node_id] ($eid)" -k -i - &
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
    global debug

    set eid [getFromRunning "eid"]
    if { [checkForExternalApps "socat"] != 0 } {
        puts stderr "To run X applications on the node, install socat on your host."
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
#   Start tcpdump in xterm on a virtual node on the specified interface.
# INPUTS
#   * node_id -- virtual node id
#   * iface_name -- virtual node interface
#****
proc startTcpdumpOnNodeIfc { node_id iface_name } {
    if { [checkForApplications $node_id "tcpdump"] == 0 } {
        spawnShell $node_id "tcpdump -ni $iface_name"
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
proc existingShells { shells node_id } {
    set cmds "
	retval=\"\"\

	for s in \"$shells\"; do
	    x=\$(which \$s 2> /dev/null)
	    test -n \"\$x\" && retval=\"\$retval \$x\"
	done
	echo \"\$retval\""

    catch { exec docker exec [getFromRunning "eid"].$node_id sh -c "$cmds" } existing

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
    if { [catch { exec xterm -version }] } {
	tk_dialog .dialog1 "IMUNES error" \
	    "Cannot open terminal. Is xterm installed?" \
            info 0 Dismiss

	return
    }

    set docker_id [getFromRunning "eid"]\.$node_id

    # FIXME make this modular
    exec xterm -name imunes-terminal -sb -rightbar \
    -T "IMUNES: [getNodeName $node_id] (console) [string trim [lindex [split $cmd /] end] ']" \
    -e "docker exec -it $docker_id $cmd" 2> /dev/null &
}

#****f* linux.tcl/fetchRunningExperiments
# NAME
#   fetchRunningExperiments -- fetch running experiments
# SYNOPSIS
#   fetchRunningExperiments
# FUNCTION
#   Returns IDs of all running experiments as a list.
# RESULT
#   * exp_list -- experiment id list
#****
proc fetchRunningExperiments {} {
    catch { exec himage -l | cut -d " " -f 1 } exp_list
    set exp_list [split $exp_list "
"]
    return "$exp_list"
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
    global VROOT_MASTER execMode

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

	catch { exec docker images -q $search_template } images
	if { [llength $images] > 0 } {
	    continue
	} else {
	    # be nice to the user and see whether there is an image id matching
	    if { [string length $template] == 12 } {
                catch { exec docker images -q } all_images
		if { [lsearch $all_images $template] == -1 } {
		    incr missing
		}
	    } else {
		incr missing
	    }
	    if { $missing } {
                if { $execMode == "batch" } {
                    puts stderr "Docker image for some virtual nodes:
    $template
is missing.
Run 'docker pull $template' to pull the template."
	        } else {
                   tk_dialog .dialog1 "IMUNES error" \
	    "Docker image for some virtual nodes:
    $template
is missing.
Run 'docker pull $template' to pull the template." \
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
proc getHostIfcList {} {
    # fetch interface list from the system
    set extifcs [exec ls /sys/class/net]
    # exclude loopback interface
    set ilo [lsearch $extifcs lo]
    set extifcs [lreplace $extifcs $ilo $ilo]

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
    global execMode

    # check if VLAN ID is already taken
    # this can be only done by trying to create it, as it's possible that the same
    # VLAN interface already exists in some other namespace
    set iface_id [ifaceIdFromName $node_id $iface_name]
    set vlan [getIfcVlanTag $node_id $iface_id]
    try {
	exec ip link add link $iface_name name $iface_name.$vlan type vlan id $vlan
    } on ok {} {
	exec ip link del $iface_name.$vlan
	return 0
    } on error err {
	set msg "Unable to create external interface '$iface_name.$vlan':\n$err\n\nPlease\
	    verify that VLAN ID $vlan with parent interface $iface_name is not already\
	    assigned to another VLAN interface, potentially in a different namespace."
    }

    if { $execMode == "batch" } {
	puts stderr $msg
    } else {
	after idle { .dialog1.msg configure -wraplength 4i }
	tk_dialog .dialog1 "IMUNES error" $msg \
	    info 0 Dismiss
    }

    return 1
}

proc removeNodeFS { eid node_id } {
    set VROOT_BASE [getVrootDir]

    pipesExec "rm -fr $VROOT_BASE/$eid/$node_id" "hold"
}

proc getNodeNetns { eid node_id } {
    global devfs_number

    # Top-level experiment netns
    if { $node_id in "" || [getNodeType $node_id] == "rj45" } {
	return $eid
    }

    # Global netns
    if { [getNodeType $node_id] in "ext extnat" } {
	return ""
    }

    # Node netns
    return $eid-$node_id
}

proc destroyNodeVirtIfcs { eid node_id } {
    set docker_id "$eid.$node_id"

    pipesExec "docker exec -d $docker_id sh -c 'for iface in `ls /sys/class/net` ; do ip link del \$iface; done'" "hold"
}

proc loadKernelModules {} {
    global all_modules_list

    foreach module $all_modules_list {
        if { [info procs $module.prepareSystem] == "$module.prepareSystem" } {
            $module.prepareSystem
        }
    }
}

proc prepareVirtualFS {} {
    exec mkdir -p /var/run/netns
}

proc attachToL3NodeNamespace { node_id } {
    set eid [getFromRunning "eid"]

    if { [getNodeDockerAttach $node_id] != "true" } {
	pipesExec "docker network disconnect imunes-bridge $eid.$node_id &" "hold"
    }

    # VIRTUALIZED nodes use docker netns
    set cmds "docker_ns=\$(docker inspect -f '{{.State.Pid}}' $eid.$node_id)"
    set cmds "$cmds; ip netns del \$docker_ns > /dev/null 2>&1"
    set cmds "$cmds; ip netns attach $eid-$node_id \$docker_ns"
    set cmds "$cmds; docker exec -d $eid.$node_id umount /etc/resolv.conf /etc/hosts"

    pipesExec "sh -c \'$cmds\' &" "hold"
}

proc createNamespace { ns } {
    pipesExec "ip netns add $ns" "hold"
}

proc destroyNamespace { ns } {
    pipesExec "ip netns del $ns" "hold"
}

proc createExperimentContainer {} {
    global devfs_number

    catch { exec ip netns attach imunes_$devfs_number 1 }
    catch { exec docker network create --opt com.docker.network.container_iface_prefix=dext imunes-bridge }

    # Top-level experiment netns
    exec ip netns add [getFromRunning "eid"]
}

#****f* linux.tcl/prepareFilesystemForNode
# NAME
#   prepareFilesystemForNode -- prepare node filesystem
# SYNOPSIS
#   prepareFilesystemForNode $node_id
# FUNCTION
#   Prepares the node virtual filesystem.
# INPUTS
#   * node_id -- node id
#****
proc prepareFilesystemForNode { node_id } {
    set VROOTDIR /var/imunes
    set VROOT_RUNTIME $VROOTDIR/[getFromRunning "eid"]/$node_id

    pipesExec "mkdir -p $VROOT_RUNTIME &" "hold"
}

#****f* linux.tcl/createNodeContainer
# NAME
#   createNodeContainer -- creates a virtual node container
# SYNOPSIS
#   createNodeContainer $node_id
# FUNCTION
#   Creates a docker instance using the defined template and
#   assigns the hostname. Waits for the node to be up.
# INPUTS
#   * node_id -- node id
#****
proc createNodeContainer { node_id } {
    global VROOT_MASTER ULIMIT_FILE ULIMIT_PROC

    set docker_id "[getFromRunning "eid"].$node_id"

    set network "imunes-bridge"
    #if { [getNodeDockerAttach $node_id] == "true" } {
	#set network "bridge"
    #}

    set vroot [getNodeCustomImage $node_id]
    if { $vroot == "" } {
        set vroot $VROOT_MASTER
    }

    set docker_cmd "docker run --detach --init --tty \
	--privileged --cap-add=ALL --net=$network \
	--name $docker_id --hostname=[getNodeName $node_id] \
	--volume /tmp/.X11-unix:/tmp/.X11-unix \
	--sysctl net.ipv6.conf.all.disable_ipv6=0 \
	--ulimit nofile=$ULIMIT_FILE --ulimit nproc=$ULIMIT_PROC \
	$vroot &"

    dputs "Node $node_id -> '$docker_cmd'"

    pipesExec "$docker_cmd" "hold"
}

proc isNodeStarted { node_id } {
    set node_type [getNodeType $node_id]
    if { [$node_type.virtlayer] != "VIRTUALIZED" } {
	if { $node_type in "rj45 ext extnat" } {
	    return true
	}

	set nodeNs "[getFromRunning "eid"]-$node_id"

	try {
	    exec ip netns exec $nodeNs ip link show $node_id
	} on error {} {
	    return false
	}

	return true
    }

    set docker_id "[getFromRunning "eid"].$node_id"

    catch { exec docker inspect --format '{{.State.Running}}' $docker_id } status

    return [string match 'true' $status]
}

proc isNodeNamespaceCreated { node_id } {
    global skip_nodes

    if { $node_id in $skip_nodes } {
	return true
    }

    set nodeNs [getNodeNetns [getFromRunning "eid"] $node_id]

    if { $nodeNs == "" } {
	return true
    }

    try {
       exec ip netns exec $nodeNs true
    } on error {} {
       return false
    }

    return true
}

#****f* linux.tcl/nodePhysIfacesCreate
# NAME
#   nodePhysIfacesCreate -- create node physical interfaces
# SYNOPSIS
#   nodePhysIfacesCreate $node_id
# FUNCTION
#   Creates physical interfaces for the given node.
# INPUTS
#   * node_id -- node id
#****
proc nodePhysIfacesCreate { node_id ifaces } {
    set eid [getFromRunning "eid"]

    set nodeNs [getNodeNetns $eid $node_id]
    set node_type [getNodeType $node_id]

    # Create "physical" network interfaces
    foreach iface_id $ifaces {
	setToRunning "${node_id}|${iface_id}_running" true

	set iface_name [getIfcName $node_id $iface_id]
	set public_hook $node_id-$iface_name
	set prefix [string trimright $iface_name "0123456789"]
	if { $node_type in "ext extnat" } {
	    set iface_name $node_id
	}

	# direct link, simulate capturing the host interface into the node,
	# without bridges between them
	set this_link_id [getIfcLink $node_id $iface_id]
	if { $this_link_id != "" && [getLinkDirect $this_link_id] } {
	    continue
	}

	switch -exact $prefix {
	    e -
	    ext -
	    eth {
		# Create a veth pair - private hook in node netns and public hook
		# in the experiment netns
		createNsVethPair $iface_name $nodeNs $public_hook $eid
	    }
	}

	switch -exact $prefix {
	    e {
		# bridge private hook with L2 node
		setNsIfcMaster $nodeNs $iface_name $node_id "up"
		if { [getNodeType $node_id] in "vlanswitch" } {
		    set vlantag [getIfcVlanTag $node_id $iface_id]
		    set vlantype [getIfcVlanType $node_id $iface_id]
		    execSetIfcVlanConfig $eid $node_id $iface_id $vlantag $vlantype
		}
	    }
	    ext {
		# bridge private hook with ext node
		#setNsIfcMaster $nodeNs $iface_name $eid-$node_id "up"
	    }
	    eth {
		#set ether [getIfcMACaddr $node_id $iface_id]
		#if { $ether == "" } {
		#    autoMACaddr $node_id $iface_id
		#    set ether [getIfcMACaddr $node_id $iface_id]
		#}

		#set nsstr ""
		#if { $nodeNs != "" } {
		#    set nsstr "-n $nodeNs"
		#}
		#pipesExec "ip $nsstr link set $iface_name address $ether" "hold"
	    }
	    default {
		# capture physical interface directly into the node, without using a bridge
		# we don't know the name, so make sure all other options cover other IMUNES
		# 'physical' interfaces
		# XXX not yet implemented
		if { [getIfcType $node_id $iface_id] == "stolen" } {
		    captureExtIfcByName $eid $iface_name $node_id
		    if { [getNodeType $node_id] in "hub lanswitch vlanswitch" } {
			setNsIfcMaster $nodeNs $iface_name $node_id "up"
		    }
		}
	    }
	}
    }

    pipesExec ""
}

#****f* linux.tcl/killProcess
# NAME
#   killProcess -- kill processes with the given regex
# SYNOPSIS
#   killProcess $regex
# FUNCTION
#   Executes a pkill command to kill all processes with a corresponding regex.
# INPUTS
#   * regex -- regularl expression of the processes
#****
proc killExtProcess { regex } {
    pipesExec "pkill -f \"$regex\"" "hold"
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

    foreach iface_id $ifaces {
	setToRunning "${node_id}|${iface_id}_running" true

	set iface_name [getIfcName $node_id $iface_id]
	switch -exact [getIfcType $node_id $iface_id] {
	    vlan {
		set tag [getIfcVlanTag $node_id $iface_id]
		set dev [getIfcVlanDev $node_id $iface_id]
		if { $tag != "" && $dev != "" } {
		    pipesExec "docker exec -d $docker_id [getVlanTagIfcCmd $iface_name $dev $tag]" "hold"
		}
	    }
	    lo {
		if { $iface_name != "lo0" } {
		    pipesExec "docker exec -d $docker_id ip link add $iface_name type dummy" "hold"
		    pipesExec "docker exec -d $docker_id ip link set $iface_name up" "hold"
		} else {
		    pipesExec "docker exec -d $docker_id ip link set dev lo down 2>/dev/null" "hold"
		    pipesExec "docker exec -d $docker_id ip link set dev lo name lo0 2>/dev/null" "hold"
		    pipesExec "docker exec -d $docker_id ip a flush lo0 2>/dev/null &" "hold"
		}
	    }
	}
    }

#    # docker interface is created before other ones, so let's rename it to something that's not used by IMUNES
#    if { [getNodeDockerAttach $node_id] == 1 } {
#	set cmds "ip r save > /tmp/routes"
#	set cmds "$cmds ; ip l set eth0 down"
#	set cmds "$cmds ; ip l set eth0 name docker0"
#	set cmds "$cmds ; ip l set docker0 up"
#	set cmds "$cmds ; ip r restore < /tmp/routes"
#	set cmds "$cmds ; rm -f /tmp/routes"
#	pipesExec "docker exec -d $docker_id sh -c '$cmds'" "hold"
#    }
}

#****f* linux.tcl/configureICMPoptions
# NAME
#   configureICMPoptions -- configure ICMP options
# SYNOPSIS
#   configureICMPoptions $node_id
# FUNCTION
#  Configures the necessary ICMP sysctls in the given node.
# INPUTS
#   * node_id -- node id
#****
proc configureICMPoptions { node_id } {
    array set sysctl_icmp {
	net.ipv4.icmp_ratelimit			0
	net.ipv4.icmp_echo_ignore_broadcasts	1
    }

    foreach {name val} [array get sysctl_icmp] {
	lappend cmd "sysctl $name=$val"
    }
    set cmds [join $cmd "; "]

    pipesExec "docker exec -d [getFromRunning "eid"].$node_id sh -c '$cmds ; touch /tmp/init'" "hold"
}

proc isNodeInitNet { node_id } {
    global skip_nodes

    if { $node_id in $skip_nodes } {
	return true
    }

    set docker_id "[getFromRunning "eid"].$node_id"

    try {
	exec docker inspect -f "{{.GraphDriver.Data.MergedDir}}" $docker_id
    } on ok mergedir {
	try {
	    exec test -f ${mergedir}/tmp/init
	} on error {} {
	    return false
	}
    } on error {} {
	return false
    }

    return true
}

proc createNsLinkBridge { netNs link } {
    set nsstr ""
    if { $netNs != "" } {
	set nsstr "-n $netNs"
    }

    pipesExec "ip $nsstr link add name $link type bridge ageing_time 0 mcast_snooping 0" "hold"
    pipesExec "ip $nsstr link set $link multicast off" "hold"
    pipesExec "ip netns exec $netNs sysctl net.ipv6.conf.$link.disable_ipv6=1" "hold"
    pipesExec "ip $nsstr link set $link up" "hold"
}

proc createNsVethPair { ifname1 netNs1 ifname2 netNs2 } {
    set eid [getFromRunning "eid"]

    set nsstr1 ""
    set nsstr1x ""
    if { $netNs1 != "" } {
	set nsstr1 "netns $netNs1"
	set nsstr1x "-n $netNs1"
    }

    set nsstr2 ""
    set nsstr2x ""
    if { $netNs2 != "" } {
	set nsstr2 "netns $netNs2"
	set nsstr2x "-n $netNs2"
    }

    pipesExec "ip link add name $eid-$ifname1 $nsstr1 type veth peer name $eid-$ifname2 $nsstr2" "hold"

    if { $nsstr1x != "" } {
	pipesExec "ip $nsstr1x link set $eid-$ifname1 name $ifname1" "hold"
    }

    if { $nsstr2x != "" } {
	pipesExec "ip $nsstr2x link set $eid-$ifname2 name $ifname2" "hold"
    }

    if { $netNs2 == $eid } {
	pipesExec "ip netns exec $eid ip link set $ifname2 multicast off" "hold"
	pipesExec "ip netns exec $eid sysctl net.ipv6.conf.$ifname2.disable_ipv6=1" "hold"
    }
}

proc setNsIfcMaster { netNs iface_name master state } {
    set nsstr ""
    if { $netNs != "" } {
	set nsstr "-n $netNs"
    }

    pipesExec "ip $nsstr link set $iface_name master $master $state" "hold"
}

#****f* linux.tcl/createDirectLinkBetween
# NAME
#   createDirectLinkBetween -- create direct link between
# SYNOPSIS
#   createDirectLinkBetween $node1_id $node2_id $iface1_id $iface2_id
# FUNCTION
#   Creates direct link between two given nodes. Direct link connects the host
#   interface into the node, without ng_node between them.
# INPUTS
#   * node1_id -- node id of the first node
#   * node2_id -- node id of the second node
#   * iface1_id -- interface id on the first node
#   * iface2_id -- interface id on the second node
#****
proc createDirectLinkBetween { node1_id node2_id iface1_id iface2_id } {
    set eid [getFromRunning "eid"]

    if { "rj45" in "[getNodeType $node1_id] [getNodeType $node2_id]" } {
	if { [getNodeType $node1_id] == "rj45" } {
	    set physical_ifc [getIfcName $node1_id $iface1_id]
	    set vlan [getIfcVlanTag $node1_id $iface1_id]
	    if { $vlan != "" && [getIfcVlanDev $node1_id $iface1_id] != "" } {
		set physical_ifc $physical_ifc.$vlan
	    }
	    set nodeNs [getNodeNetns $eid $node2_id]
	    set iface2_name [getIfcName $node2_id $iface2_id]
	    set full_virtual_ifc $eid-$node2_id-$iface2_name
	    set virtual_ifc $iface2_name
	    set ether [getIfcMACaddr $node2_id $iface2_id]

	    if { [[getNodeType $node2_id].virtlayer] == "NATIVE" } {
		pipesExec "ip link set $physical_ifc netns $nodeNs" "hold"
		setNsIfcMaster $nodeNs $physical_ifc $node2_id "up"
		return
	    }
	} else {
	    set physical_ifc [getIfcName $node2_id $iface2_id]
	    set vlan [getIfcVlanTag $node2_id $iface2_id]
	    if { $vlan != "" && [getIfcVlanDev $node2_id $iface2_id] != "" } {
		set physical_ifc $physical_ifc.$vlan
	    }
	    set nodeNs [getNodeNetns $eid $node1_id]
	    set iface1_name [getIfcName $node1_id $iface1_id]
	    set full_virtual_ifc $eid-$node1_id-$iface1_name
	    set virtual_ifc $iface1_name
	    set ether [getIfcMACaddr $node1_id $iface1_id]

	    if { [[getNodeType $node1_id].virtlayer] == "NATIVE" } {
		pipesExec "ip link set $physical_ifc netns $nodeNs" "hold"
		setNsIfcMaster $nodeNs $physical_ifc $node1_id "up"
		return
	    }
	}

	try {
	    exec test -d /sys/class/net/$physical_ifc/wireless
	} on error {} {
	    # not wireless
	    set cmds "ip link add link $physical_ifc name $full_virtual_ifc netns $nodeNs type macvlan mode private"
	    set cmds "$cmds ; ip -n $nodeNs link set $full_virtual_ifc address $ether"
	} on ok {} {
	    # we cannot use macvlan on wireless interfaces, so MAC address cannot be changed
	    set cmds "ip link add link $physical_ifc name $full_virtual_ifc netns $nodeNs type ipvlan mode l2"
	}

	set cmds "$cmds ; ip link set $physical_ifc up"
	set cmds "$cmds ; ip -n $nodeNs link set $full_virtual_ifc name $virtual_ifc"
	set cmds "$cmds ; ip -n $nodeNs link set $virtual_ifc up"
	pipesExec "$cmds" "hold"

	return
    }

    if { [getNodeType $node1_id] in "ext extnat" } {
	set iface1_name $node1_id
    } else {
	set iface1_name [getIfcName $node1_id $iface1_id]
    }

    if { [getNodeType $node2_id] in "ext extnat" } {
	set iface2_name $node2_id
    } else {
	set iface2_name [getIfcName $node2_id $iface2_id]
    }

    set node1Ns [getNodeNetns $eid $node1_id]
    set node2Ns [getNodeNetns $eid $node2_id]
    createNsVethPair $iface1_name $node1Ns $iface2_name $node2Ns

    # add nodes iface hooks to link bridge and bring them up
    foreach node_id [list $node1_id $node2_id] iface_name [list $iface1_name $iface2_name] ns [list $node1Ns $node2Ns] {
	if { [[getNodeType $node_id].virtlayer] != "NATIVE" || [getNodeType $node_id] in "ext extnat" } {
	    continue
	}

	setNsIfcMaster $ns $iface_name $node_id "up"
    }
}

proc createLinkBetween { node1_id node2_id iface1_id iface2_id link_id } {
    set eid [getFromRunning "eid"]

    # create link bridge in experiment netns
    createNsLinkBridge $eid $link_id

    # add nodes iface hooks to link bridge and bring them up
    foreach node_id "$node1_id $node2_id" iface_id "$iface1_id $iface2_id" {
	if { [getNodeType $node_id] == "rj45" } {
	    set iface_name [getIfcName $node_id $iface_id]
	    if { [getIfcVlanDev $node_id $iface_id] != "" } {
		set vlan [getIfcVlanTag $node_id $iface_id]
		set iface_name $iface_name.$vlan
	    }
	} else {
	    set iface_name $node_id-[getIfcName $node_id $iface_id]
	}

	setNsIfcMaster $eid $iface_name $link_id "up"
    }
}

proc configureLinkBetween { node1_id node2_id iface1_id iface2_id link_id } {
    set eid [getFromRunning "eid"]

    set bandwidth [expr [getLinkBandwidth $link_id] + 0]
    set delay [expr [getLinkDelay $link_id] + 0]
    set ber [expr [getLinkBER $link_id] + 0]
    set loss [expr [getLinkLoss $link_id] + 0]
    set dup [expr [getLinkDup $link_id] + 0]

    configureIfcLinkParams $eid $node1_id $iface1_id $bandwidth $delay $ber $loss $dup
    configureIfcLinkParams $eid $node2_id $iface2_id $bandwidth $delay $ber $loss $dup

    # FIXME: remove this to interface configuration?
    foreach node_id "$node1_id $node2_id" iface_id "$iface1_id $iface2_id" {
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

#****f* linux.tcl/runConfOnNode
# NAME
#   runConfOnNode -- run configuration script on node
# SYNOPSIS
#   runConfOnNode $node_id
# FUNCTION
#   Run startup configuration file on the given node.
# INPUTS
#   * node_id -- node id
#****
proc runConfOnNode { node_id } {
    set eid [getFromRunning "eid"]

    set docker_id "$eid.$node_id"

    set custom_selected [getCustomConfigSelected $node_id "NODE_CONFIG"]
    if { [getCustomEnabled $node_id] == true && $custom_selected ni "\"\" DISABLED" } {
        set bootcmd [getCustomConfigCommand $node_id "NODE_CONFIG" $custom_selected]
        set bootcfg [getCustomConfig $node_id "NODE_CONFIG" $custom_selected]
	set bootcfg "$bootcfg\n[join [[getNodeType $node_id].generateConfig $node_id] "\n"]"
        set confFile "custom.conf"
    } else {
        set bootcfg [join [[getNodeType $node_id].generateConfig $node_id] "\n"]
        set bootcmd [[getNodeType $node_id].bootcmd $node_id]
        set confFile "boot.conf"
    }

    generateHostsFile $node_id

    set cfg "set -x\n$bootcfg"
    writeDataToNodeFile $node_id /tout.log ""
    writeDataToNodeFile $node_id /$confFile $cfg
    set cmds "rm -f /out.log /err.log ;"
    set cmds "$cmds $bootcmd /$confFile >> /tout.log 2>> /terr.log ;"
    # renaming the file signals that we're done
    set cmds "$cmds mv /tout.log /out.log ;"
    set cmds "$cmds mv /terr.log /err.log"
    pipesExec "docker exec -d $docker_id sh -c '$cmds'" "hold"
}

proc startNodeIfaces { node_id ifaces } {
    set eid [getFromRunning "eid"]

    set docker_id "$eid.$node_id"

    set custom_selected [getCustomConfigSelected $node_id "IFACES_CONFIG"]
    if { [getCustomEnabled $node_id] == true && $custom_selected ni "\"\" DISABLED" } {
        set bootcmd [getCustomConfigCommand $node_id "IFACES_CONFIG" $custom_selected]
        set bootcfg [getCustomConfig $node_id "IFACES_CONFIG" $custom_selected]
        set confFile "custom_ifaces.conf"
    } else {
	set bootcfg [join [[getNodeType $node_id].generateConfigIfaces $node_id $ifaces] "\n"]
	set bootcmd [[getNodeType $node_id].bootcmd $node_id]
	set confFile "boot_ifaces.conf"
    }

    set cfg "set -x\n$bootcfg"
    writeDataToNodeFile $node_id /tout_ifaces.log ""
    writeDataToNodeFile $node_id /$confFile $cfg
    set cmds "rm -f /out_ifaces.log /err_ifaces.log ;"
    set cmds "$cmds $bootcmd /$confFile >> /tout_ifaces.log 2>> /terr_ifaces.log ;"
    # renaming the file signals that we're done
    set cmds "$cmds mv /tout_ifaces.log /out_ifaces.log ;"
    set cmds "$cmds mv /terr_ifaces.log /err_ifaces.log"
    pipesExec "docker exec -d $docker_id sh -c '$cmds'" "hold"
}

proc unconfigNode { eid node_id } {
    set docker_id "$eid.$node_id"

    set custom_selected [getCustomConfigSelected $node_id "NODE_CONFIG"]
    if { [getCustomEnabled $node_id] == true && $custom_selected ni "\"\" DISABLED" } {
	return
    }

    set bootcfg [join [[getNodeType $node_id].generateUnconfig $node_id] "\n"]
    set bootcmd [[getNodeType $node_id].bootcmd $node_id]
    set confFile "unboot.conf"

    set cfg "set -x\n$bootcfg"
    writeDataToNodeFile $node_id /tout.log ""
    writeDataToNodeFile $node_id /$confFile $cfg
    set cmds "rm -f /out.log /err.log ;"
    set cmds "$cmds $bootcmd /$confFile >> /tout.log 2>> /terr.log ;"
    # renaming the file signals that we're done
    set cmds "$cmds mv /tout.log /out.log ;"
    set cmds "$cmds mv /terr.log /err.log"
    pipesExec "docker exec -d $docker_id sh -c '$cmds'" "hold"
}

proc unconfigNodeIfaces { eid node_id ifaces } {
    set docker_id "$eid.$node_id"

    set custom_selected [getCustomConfigSelected $node_id "IFACES_CONFIG"]
    if { [getCustomEnabled $node_id] == true && $custom_selected ni "\"\" DISABLED" } {
	return
    }

    set bootcfg [join [[getNodeType $node_id].generateUnconfigIfaces $node_id $ifaces] "\n"]
    set bootcmd [[getNodeType $node_id].bootcmd $node_id]
    set confFile "unboot_ifaces.conf"

    set cfg "set -x\n$bootcfg"
    writeDataToNodeFile $node_id /tout_ifaces.log ""
    writeDataToNodeFile $node_id /$confFile $cfg
    set cmds "rm -f /out_ifaces.log /err_ifaces.log ;"
    set cmds "$cmds $bootcmd /$confFile >> /tout_ifaces.log 2>> /terr_ifaces.log ;"
    # renaming the file signals that we're done
    set cmds "$cmds mv /tout_ifaces.log /out_ifaces.log ;"
    set cmds "$cmds mv /terr_ifaces.log /err_ifaces.log"
    pipesExec "docker exec -d $docker_id sh -c '$cmds'" "hold"
}

proc isNodeIfacesConfigured { node_id } {
    global skip_nodes

    if { $node_id in $skip_nodes } {
	return true
    }

    set docker_id "[getFromRunning "eid"].$node_id"

    if { [[getNodeType $node_id].virtlayer] == "NATIVE" } {
	return true
    }

    try {
	# docker exec sometimes hangs, so don't use it while we have other pipes opened
	exec docker inspect -f "{{.GraphDriver.Data.MergedDir}}" $docker_id
    } on ok mergedir {
	catch { exec test ! -f ${mergedir}/tout_ifaces.log } err1
	catch { exec test -f ${mergedir}/out_ifaces.log } err2
	if { $err1 == "" && $err2 == "" } {
	    return true
	}

	return false
    } on error err {
	puts stderr "Error on docker inspect: '$err'"
    }

    return false
}

proc isNodeConfigured { node_id } {
    global skip_nodes

    if { $node_id in $skip_nodes } {
	return true
    }

    set docker_id "[getFromRunning "eid"].$node_id"

    if { [[getNodeType $node_id].virtlayer] == "NATIVE" } {
	return true
    }

    try {
	# docker exec sometimes hangs, so don't use it while we have other pipes opened
	exec docker inspect -f "{{.GraphDriver.Data.MergedDir}}" $docker_id
    } on ok mergedir {
	catch { exec test ! -f ${mergedir}/tout.log } err1
	catch { exec test -f ${mergedir}/out.log } err2
	if { $err1 == "" && $err2 == "" } {
	    return true
	}

	return false
    } on error err {
	puts stderr "Error on docker inspect: '$err'"
    }

    return false
}

proc isNodeError { node_id } {
    global skip_nodes

    if { $node_id in $skip_nodes } {
	return false
    }

    if { [[getNodeType $node_id].virtlayer] == "NATIVE" } {
	return false
    }

    set docker_id "[getFromRunning "eid"].$node_id"

    try {
	# docker exec sometimes hangs, so don't use it while we have other pipes opened
	exec docker inspect -f "{{.GraphDriver.Data.MergedDir}}" $docker_id
    } on ok mergedir {
	if { ! [file exists ${mergedir}/err.log] } {
	    return ""
	}

	catch { exec sed "/^+ /d" ${mergedir}/err.log } errlog
	if { $errlog == "" } {
	    return false
	}

	return true
    } on error err {
	puts stderr "Error on docker inspect: '$err'"
    }

    return true
}

proc isNodeErrorIfaces { node_id } {
    global skip_nodes

    if { $node_id in $skip_nodes } {
	return false
    }

    if { [[getNodeType $node_id].virtlayer] == "NATIVE" } {
	return false
    }

    set docker_id "[getFromRunning "eid"].$node_id"

    try {
	# docker exec sometimes hangs, so don't use it while we have other pipes opened
	exec docker inspect -f "{{.GraphDriver.Data.MergedDir}}" $docker_id
    } on ok mergedir {
	if { ! [file exists ${mergedir}/err_ifaces.log] } {
	    return ""
	}

	catch { exec sed "/^+ /d" ${mergedir}/err_ifaces.log } errlog
	if { $errlog == "" } {
	    return false
	}

	return true
    } on error err {
	puts stderr "Error on docker inspect: '$err'"
    }

    return true
}

proc removeNetns { netns } {
    if { $netns != "" } {
	exec ip netns del $netns
    }
}

proc removeNodeNetns { eid node_id } {
    set netns [getNodeNetns $eid $node_id]

    if { $netns != "" } {
	pipesExec "ip netns del $netns" "hold"
    }
}

proc terminate_removeExperimentContainer { eid } {
    removeNetns $eid
}

proc terminate_removeExperimentFiles { eid } {
    set VROOT_BASE [getVrootDir]
    catch "exec rm -fr $VROOT_BASE/$eid &"
}

proc removeNodeContainer { eid node_id } {
    set docker_id $eid.$node_id

    pipesExec "docker kill $docker_id" "hold"
    pipesExec "docker rm $docker_id" "hold"
}

proc killAllNodeProcesses { eid node_id } {
    set docker_id "$eid.$node_id"

    # kill all processes except pid 1 and its child(ren)
    pipesExec "docker exec -d $docker_id sh -c 'killall5 -9 -o 1 -o \$(pgrep -P 1)'" "hold"
}

proc destroyDirectLinkBetween { eid node1_id node2_id } {
}

proc destroyLinkBetween { eid node1_id node2_id link_id } {
    pipesExec "ip -n $eid link del $link_id" "hold"
}

#****f* linux.tcl/nodeIfacesDestroy
# NAME
#   nodeIfacesDestroy -- destroy virtual node interfaces
# SYNOPSIS
#   nodeIfacesDestroy $eid $node_id $ifaces
# FUNCTION
#   Destroys all virtual node interfaces.
# INPUTS
#   * eid -- experiment id
#   * node_id -- virtual node id
#   * ifaces -- list of iface ids
#****
proc nodeIfacesDestroy { eid node_id ifaces } {
    set node_type [getNodeType $node_id]
    if { $node_type in "ext extnat" } {
	foreach iface_id $ifaces {
	    set link_id [getIfcLink $node_id $iface_id]
	    if { $link_id != "" && [getLinkDirect $link_id] } {
		pipesExec "ip link del $eid-$node_id" "hold"
	    } else {
		pipesExec "ip -n $eid link del $node_id-[getIfcName $node_id $iface_id]" "hold"
	    }
	}
    } elseif { $node_type == "rj45" } {
	foreach iface_id $ifaces {
	    releaseExtIfcByName $eid [getIfcName $node_id $iface_id] $node_id
	}
    } else {
	foreach iface_id $ifaces {
	    set iface_name [getIfcName $node_id $iface_id]
	    set link_id [getIfcLink $node_id $iface_id]
	    if { [getIfcType $node_id $iface_id] == "stolen" } {
		releaseExtIfcByName $eid $iface_name $node_id
	    } elseif { $link_id != "" && [getLinkDirect $link_id] } {
		pipesExec "ip -n [getNodeNetns $eid $node_id] link del $iface_name" "hold"
	    } else {
		pipesExec "ip -n $eid link del $node_id-$iface_name" "hold"
	    }
	}
    }

    foreach iface_id $ifaces {
	setToRunning "${node_id}|${iface_id}_running" false
    }
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
    foreach ifc [allIfcList $node_id] {
	pipesExec "docker exec -d $docker_id sh -c 'ip addr flush dev $ifc'" "hold"
    }
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
    return [lindex [exec grep -c processor /proc/cpuinfo] 0]
}

#****f* linux.tcl/enableIPforwarding
# NAME
#   enableIPforwarding -- enable IP forwarding
# SYNOPSIS
#   enableIPforwarding $node_id
# FUNCTION
#   Enables IPv4 and IPv6 forwarding on the given node.
# INPUTS
#   * node_id -- node id
#****
proc enableIPforwarding { node_id } {
    array set sysctl_ipfwd {
	net.ipv6.conf.all.forwarding	1
	net.ipv4.conf.all.forwarding	1
	net.ipv4.conf.default.rp_filter	0
	net.ipv4.conf.all.rp_filter	0
    }

    foreach {name val} [array get sysctl_ipfwd] {
	lappend cmd "sysctl $name=$val"
    }
    set cmds [join $cmd "; "]

    pipesExec "docker exec -d [getFromRunning "eid"].$node_id sh -c \'$cmds\'" "hold"
}

#****f* linux.tcl/getExtIfcs
# NAME
#   getExtIfcs -- get external interfaces
# SYNOPSIS
#   getExtIfcs
# FUNCTION
#   Returns the list of all available external interfaces except those defined
#   in the ignore loop.
# RESULT
#   * ifsc - list of interfaces
#****
proc getExtIfcs {} {
    catch { exec ls /sys/class/net } ifcs
    foreach ignore "lo* ipfw* tun*" {
        set ifcs [ lsearch -all -inline -not $ifcs $ignore ]
    }
    return "$ifcs"
}

#****f* linux.tcl/captureExtIfc
# NAME
#   captureExtIfc -- capture external interface
# SYNOPSIS
#   captureExtIfc $eid $node_id $iface_id
# FUNCTION
#   Captures the external interface given by the given rj45 node.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * iface_id -- interface id
#****
proc captureExtIfc { eid node_id iface_id } {
    global execMode

    set iface_name [getIfcName $node_id $iface_id]
    if { [getIfcVlanDev $node_id $iface_id] != "" } {
	set vlan [getIfcVlanTag $node_id $iface_id]
	try {
	    exec ip link set $iface_name up
	    exec ip link add link $iface_name name $iface_name.$vlan type vlan id $vlan
	} on error err {
	    set msg "Error: VLAN $vlan on external interface $iface_name can't be\
		created.\n($err)"

	    if { $execMode == "batch" } {
		puts stderr $msg
	    } else {
		after idle { .dialog1.msg configure -wraplength 4i }
		tk_dialog .dialog1 "IMUNES error" $msg \
		    info 0 Dismiss
	    }

	    return -code error
	} on ok {} {
	    set iface_name $iface_name.$vlan
	}
    }

    if { [getLinkDirect [getIfcLink $node_id $iface_id]] } {
	return
    }

    captureExtIfcByName $eid $iface_name $node_id
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
    set nodeNs [getNodeNetns $eid $node_id]

    # won't work if the node is a wireless interface
    pipesExec "ip link set $iface_name netns $nodeNs" "hold"
}

#****f* linux.tcl/releaseExtIfc
# NAME
#   releaseExtIfc -- release external interface
# SYNOPSIS
#   releaseExtIfc $eid $node_id $iface_id
# FUNCTION
#   Releases the external interface captured by the given rj45 node.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * iface_id -- interface id
#****
proc releaseExtIfc { eid node_id iface_id } {
    set iface_name [getIfcName $node_id $iface_id]
    set vlan [getIfcVlanTag $node_id $iface_id]
    if { $vlan != "" && [getIfcVlanDev $node_id $iface_id] != "" } {
	set iface_name $iface_name.$vlan

	if { [getLinkDirect [getIfcLink $node_id $iface_id]] } {
	    catch {exec ip link del $iface_name}
	} else {
	    catch {exec ip -n [getNodeNetns $eid $node_id] link del $iface_name}
	}

	return
    }

    if { [getLinkDirect [getIfcLink $node_id $iface_id]] } {
	return
    }

    releaseExtIfcByName $eid $iface_name $node_id
}

#****f* linux.tcl/releaseExtIfc
# NAME
#   releaseExtIfc -- release external interface
# SYNOPSIS
#   releaseExtIfc $eid $node_id
# FUNCTION
#   Releases the external interface with the name iface_name.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc releaseExtIfcByName { eid iface_name node_id } {
    global devfs_number

    set nodeNs [getNodeNetns $eid $node_id]
    pipesExec "ip -n $nodeNs link set $iface_name netns imunes_$devfs_number" "hold"
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
    return "ip addr add $addr dev $ifc"
}

proc getIPv6IfcCmd { iface_name addr primary } {
    return "ip -6 addr add $addr dev $iface_name"
}

proc getDelIPv4IfcCmd { ifc addr } {
    return "ip addr del $addr dev $ifc"
}

proc getDelIPv6IfcCmd { ifc addr } {
    return "ip -6 addr del $addr dev $ifc"
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

    set ifaces_names "[logIfaceNames $node_id] [ifaceNames $node_id]"

    catch { exec docker exec [getFromRunning "eid"].$node_id sh -c "ip --json a" } json
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

    catch { exec docker exec [getFromRunning "eid"].$node_id sh -c "ip -4 --json r" } json
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

    set old_croutes4 [lsort [_getStatIPv4routes $cur_node_cfg]]
    set new_croutes4 [lsort $croutes4]
    if { $old_croutes4 != $new_croutes4 } {
	setToRunning "${node_id}_old_croutes4" $new_croutes4
	set cur_node_cfg [_setStatIPv4routes $cur_node_cfg $new_croutes4]
    }

    catch { exec docker exec [getFromRunning "eid"].$node_id sh -c "ip -6 --json r" } json
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

    set old_croutes6 [lsort [_getStatIPv6routes $cur_node_cfg]]
    set new_croutes6 [lsort $croutes6]
    if { $old_croutes6 != $new_croutes6 } {
	setToRunning "${node_id}_old_croutes6" $new_croutes6
	set cur_node_cfg [_setStatIPv6routes $cur_node_cfg $new_croutes6]
    }

    # don't trigger anything new - save variables state
    prepareInstantiateVars
    prepareTerminateVars

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
    if { [catch { exec docker ps }] } {
        set msg "Cannot start experiment. Is docker installed and running (check the output of 'docker ps')?"
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

    pipesExec "ip netns exec $eid-$node_id tc qdisc add dev [getIfcName $node_id $iface_id] root $qdisc" "hold"
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
    pipesExec "ip -n $eid-$node_id l set [getIfcName $node_id $iface_id] txqueuelen $qlen" "hold"
}

#****f* linux.tcl/execSetIfcVlanConfig
# NAME
#   execSetIfcVlanConfig -- in exec mode set interface vlan configuration
# SYNOPSIS
#   execSetIfcVlanConfig $eid $node_id $iface_id $vlantag $vlantype
# FUNCTION
#   Configures VLAN tag and type during the simulation.
#   VLAN tag and type are defined in vlantag and vlantype parameters.
# INPUTS
#   eid -- experiment id
#   node_id -- node id
#   iface_id -- interface name
#   vlantag -- vlan tag number
#   vlantype -- vlan type (access/trunk)
#****
proc execSetIfcVlanConfig { eid node_id iface_id vlantag vlantype } {
    set iface_name [getIfcName $node_id $iface_id]
    set nsstr "netns exec $eid-$node_id"

    if { $vlantag != 1 || $vlantype == "trunk"} {
        pipesExec "ip $nsstr bridge vlan del dev $iface_name vid 1" "hold"
    }

    if { $vlantype == "trunk" } {
        foreach id [ifcList $node_id] {
            set ifc_vlantype [getIfcVlanType $node_id $id]
            if { $ifc_vlantype eq "access" } {
                set id_vlantag [getIfcVlanTag $node_id $id]
                pipesExec "ip $nsstr bridge vlan add dev $iface_name vid $id_vlantag tagged" "hold"
            }
        }
    } else {
        # Default is access
        pipesExec "ip $nsstr bridge vlan add dev $iface_name vid $vlantag pvid untagged" "hold"
    }
}


#****f* linux.tcl/execDelIfcVlanConfig
# NAME
#   execDelIfcVlanConfig -- in exec mode restore interface vlan configuration
# SYNOPSIS
#   execDelIfcVlanConfig $eid $node_id $iface_id
# FUNCTION
#   Restores VLAN configuration to the default state during the simulation.
# INPUTS
#   eid -- experiment id
#   node_id -- node id
#   iface_id -- interface name
#****
proc execDelIfcVlanConfig { eid node_id iface_id } {
    set iface_name [getIfcName $node_id $iface_id]
    set nsstr "netns exec $eid-$node_id"

    set vlantag [getIfcVlanTag $node_id $iface_id]
    set vlantype [getIfcVlanType $node_id $iface_id]

    if { $vlantag != 1 || $vlantype != "access"} {
        pipesExec "ip $nsstr bridge vlan del dev $iface_name vid 1-4094" "hold"
        pipesExec "ip $nsstr bridge vlan add dev $iface_name vid 1 pvid untagged" "hold"
    }
}

proc getNetemConfigLine { bandwidth delay loss dup } {
    array set netem {
	bandwidth	"rate Xbit"
	loss		"loss random X%"
	delay		"delay Xus"
	dup		"duplicate X%"
    }
    set cmd ""

    foreach { val ctemplate } [array get netem] {
	if { [set $val] != 0 } {
	    set confline "[lindex [split $ctemplate "X"] 0][set $val][lindex [split $ctemplate "X"] 1]"
	    append cmd " $confline"
	}
    }

    return $cmd
}

proc configureIfcLinkParams { eid node_id iface_id bandwidth delay ber loss dup } {
    set devname [getIfcName $node_id $iface_id]

    if { [getNodeType $node_id] != "rj45" } {
	set devname $node_id-$devname
    }

    set netem_cfg [getNetemConfigLine $bandwidth $delay $loss $dup]

    pipesExec "ip netns exec $eid tc qdisc del dev $devname root" "hold"
    pipesExec "ip netns exec $eid tc qdisc add dev $devname root netem $netem_cfg" "hold"

    # XXX: Now on Linux we don't care about queue lengths and we don't limit
    # maximum data and burst size.
    # in the future we can use something like this: (based on the qlen
    # parameter)
    # set confstring "tbf rate ${bandwidth}bit limit 10mb burst 1540"
}

#****f* linux.tcl/execSetLinkParams
# NAME
#   execSetLinkParams -- in exec mode set link parameters
# SYNOPSIS
#   execSetLinkParams $eid $link_id
# FUNCTION
#   Sets the link parameters during the simulation.
#   All the parameters are set at the same time.
# INPUTS
#   eid -- experiment id
#   link_id -- link id
#****
proc execSetLinkParams { eid link_id } {
    lassign [getLinkPeers $link_id] node1_id node2_id
    lassign [getLinkPeersIfaces $link_id] iface1_id iface2_id

    set mirror_link_id [getLinkMirror $link_id]
    if { $mirror_link_id != "" } {
	# pseudo nodes are always peer1
	set node1_id [lindex [getLinkPeers $mirror_link_id] 1]
	set iface1_id [lindex [getLinkPeersIfaces $mirror_link_id] 1]
    }

    set bandwidth [expr [getLinkBandwidth $link_id] + 0]
    set delay [expr [getLinkDelay $link_id] + 0]
    set ber [expr [getLinkBER $link_id] + 0]
    set loss [expr [getLinkLoss $link_id] + 0]
    set dup [expr [getLinkDup $link_id] + 0]

    pipesCreate
    configureIfcLinkParams $eid $node1_id $iface1_id $bandwidth $delay $ber $loss $dup
    configureIfcLinkParams $eid $node2_id $iface2_id $bandwidth $delay $ber $loss $dup
    pipesClose
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
    return {"service ssh stop"}
}

proc inetdServiceRestartCmds {} {
    return "service openbsd-inetd restart"
}

proc moveFileFromNode { node_id path ext_path } {
    set eid [getFromRunning "eid"]

    catch { exec hcp [getNodeName $node_id]@$eid:$path $ext_path }
    catch { exec docker exec $eid.$node_id rm -fr $path }
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

proc configureExternalConnection { eid node_id } {
    set cmds ""
    set ifc [lindex [ifcList $node_id] 0]
    set outifc "$eid-$node_id"

    set ether [getIfcMACaddr $node_id $ifc]
    if { $ether == "" } {
	autoMACaddr $node_id $ifc
	set ether [getIfcMACaddr $node_id $ifc]
    }
    set cmds "ip l set $outifc address $ether"

    set cmds "$cmds\n ip a flush dev $outifc"

    foreach ipv4 [getIfcIPv4addrs $node_id $ifc] {
	set cmds "$cmds\n ip a add $ipv4 dev $outifc"
    }

    foreach ipv6 [getIfcIPv6addrs $node_id $ifc] {
	set cmds "$cmds\n ip a add $ipv6 dev $outifc"
    }

    set cmds "$cmds\n ip l set $outifc up"

    pipesExec "$cmds" "hold"
}

proc unconfigureExternalConnection { eid node_id } {
    set cmds ""
    set ifc [lindex [ifcList $node_id] 0]
    set outifc "$eid-$node_id"

    set cmds "ip a flush dev $outifc"
    set cmds "$cmds\n ip -6 a flush dev $outifc"

    pipesExec "$cmds" "hold"
}

proc stopExternalConnection { eid node_id } {
    pipesExec "ip link set $eid-$node_id down" "hold"
}

proc setupExtNat { eid node_id ifc } {
    set extIfc [getNodeName $node_id]
    if { $extIfc == "UNASSIGNED" } {
	return
    }

    set extIp [lindex [getIfcIPv4addrs $node_id $ifc] 0]
    if { $extIp == "" } {
	return
    }
    set prefixLen [lindex [split $extIp "/"] 1]
    set subnet "[ip::prefix $extIp]/$prefixLen"

    set cmds "iptables -t nat -A POSTROUTING -o $extIfc -j MASQUERADE -s $subnet"
    set cmds "$cmds\n iptables -A FORWARD -i $eid-$node_id -o $extIfc -j ACCEPT"
    set cmds "$cmds\n iptables -A FORWARD -o $eid-$node_id -j ACCEPT"

    pipesExec "$cmds" "hold"
}

proc unsetupExtNat { eid node_id ifc } {
    set extIfc [getNodeName $node_id]
    if { $extIfc == "UNASSIGNED" } {
	return
    }

    set extIp [lindex [getIfcIPv4addrs $node_id $ifc] 0]
    if { $extIp == "" } {
	return
    }
    set prefixLen [lindex [split $extIp "/"] 1]
    set subnet "[ip::prefix $extIp]/$prefixLen"

    set cmds "iptables -t nat -D POSTROUTING -o $extIfc -j MASQUERADE -s $subnet"
    set cmds "$cmds\n iptables -D FORWARD -i $eid-$node_id -o $extIfc -j ACCEPT"
    set cmds "$cmds\n iptables -D FORWARD -o $eid-$node_id -j ACCEPT"

    pipesExec "$cmds" "hold"
}

proc startRoutingDaemons { node_id } {
    set run_dir "/run/frr"
    set cmds "mkdir -p $run_dir ; chown frr:frr $run_dir"

    set conf_dir "/etc/frr"

    foreach protocol { rip ripng ospf ospf6 } {
	if { [getNodeProtocol $node_id $protocol] != 1 } {
	    continue
	}

	set cmds "$cmds; sed -i'' \"s/${protocol}d=no/${protocol}d=yes/\" $conf_dir/daemons"
    }

    foreach protocol { ldp bfd } {
	if { [getNodeProtocol $node_id $protocol] != 1 } {
	    continue
	}

	set cmds "$cmds; sed -i'' \"s/${protocol}d=no/${protocol}d=yes/\" $conf_dir/daemons"
    }

    foreach protocol { bgp isis } {
	if { [getNodeProtocol $node_id $protocol] != 1 } {
	    continue
	}

	set cmds "$cmds; sed -i'' \"s/${protocol}d=no/${protocol}d=yes/\" $conf_dir/daemons"
    }

    set init_file "/etc/init.d/frr"
    set cmds "$cmds; if \[ -f $init_file \]; then $init_file restart ; fi"

    pipesExec "docker exec -d [getFromRunning "eid"].$node_id sh -c '$cmds'" "hold"
}
