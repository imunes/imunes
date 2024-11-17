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
#   * node_id -- id of the node (type of the node is either lanswitch or hub)
#****
proc l2node.nodeCreate { eid node_id } {
    set type [getNodeType $node_id]

    set ageing_time ""
    if { $type == "hub" } {
	set ageing_time "ageing_time 0"
    }

    set nodeNs [getNodeNetns $eid $node_id]
    pipesExec "ip netns exec $nodeNs ip link add name $node_id type bridge $ageing_time" "hold"
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
        puts "To run X applications on the node, install socat on your host."
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
    set existing []
    foreach shell $shells {
        set cmd "docker exec [getFromRunning "eid"].$node_id which $shell"
        set err [catch { eval exec $cmd } res]
        if  { ! $err } {
            lappend existing $res
        }
    }

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
                    puts "Docker image for some virtual nodes:
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
#   getHostIfcVlanExists $node_id $ifname
# FUNCTION
#   Returns 1 if VLAN interface with the name $ifname for the given node cannot
#   be created.
# INPUTS
#   * node_id -- node id
#   * ifname -- interface name
# RESULT
#   * check -- 1 if interface exists, 0 otherwise
#****
proc getHostIfcVlanExists { node_id ifname } {
    global execMode

    # check if VLAN ID is already taken
    # this can be only done by trying to create it, as it's possible that the same
    # VLAN interface already exists in some other namespace
    set vlan [getEtherVlanTag $node_id]
    try {
	exec ip link add link $ifname name $ifname.$vlan type vlan id $vlan
    } on ok {} {
	exec ip link del $ifname.$vlan
	return 0
    } on error err {
	set msg "Unable to create external interface '$ifname.$vlan':\n$err\n\nPlease\
	    verify that VLAN ID $vlan with parent interface $ifname is not already\
	    assigned to another VLAN interface, potentially in a different namespace."
    }

    if { $execMode == "batch" } {
	puts $msg
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
    if { $node_id in "" || [getNodeType $node_id] in "rj45 extelem" } {
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

    # VIRTUALIZED nodes use docker netns
    set cmds "docker_ns=\$(docker inspect -f '{{.State.Pid}}' $eid.$node_id)"
    set cmds "$cmds; ip netns del \$docker_ns > /dev/null 2>&1"
    set cmds "$cmds; ip netns attach $eid-$node_id \$docker_ns"
    set cmds "$cmds; docker exec -d $eid.$node_id umount /etc/resolv.conf /etc/hosts"

    pipesExec "sh -c \'$cmds\'" "hold"
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

    pipesExec "mkdir -p $VROOT_RUNTIME" "hold"
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
    global VROOT_MASTER ULIMIT_FILE ULIMIT_PROC debug

    set docker_id "[getFromRunning "eid"].$node_id"

    set network "none"
    if { [getNodeDockerAttach $node_id] == 1 } {
	set network "bridge"
    }

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

    if { $debug } {
	puts "Node $node_id -> '$docker_cmd'"
    }

    pipesExec "$docker_cmd" "hold"
}

proc isNodeStarted { node_id } {
    set docker_id "[getFromRunning "eid"].$node_id"

    catch { exec docker inspect --format '{{.State.Running}}' $docker_id } status

    return [string match 'true' $status]
}

proc isNodeNamespaceCreated { node_id } {
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

    if { [getNodeType $node_id] in "extelem" } {
	return
    }

    set nodeNs [getNodeNetns $eid $node_id]
    set node_type [getNodeType $node_id]

    # Create "physical" network interfaces
    foreach iface_id $ifaces {
	set iface_name $iface_id
	set prefix [string trimright $iface_name "0123456789"]
	if { $node_type in "ext extnat" } {
	    set iface_name $eid-$node_id
	}

	# direct link, simulate capturing the host interface into the node,
	# without bridges between them
	set peer [getIfcPeer $node_id $iface_id]
	if { $peer != "" } {
	    set link [linkByPeers $node_id $peer]
	    if { $link != "" && [getLinkDirect $link] } {
		continue
	    }
	}

	switch -exact $prefix {
	    e -
	    ext -
	    eth {
		# Create a veth pair - private hook in node netns and public hook
		# in the experiment netns
		createNsVethPair $iface_name $nodeNs $node_id-$iface_name $eid
	    }
	}

	switch -exact $prefix {
	    e {
		# bridge private hook with L2 node
		setNsIfcMaster $nodeNs $iface_name $node_id "up"
	    }
	    ext {
		# bridge private hook with ext node
		#setNsIfcMaster $nodeNs $iface_name $eid-$node_id "up"
	    }
	    eth {
		set ether [getIfcMACaddr $node_id $iface_id]
                if { $ether == "" } {
                    autoMACaddr $node_id $iface_id
		    set ether [getIfcMACaddr $node_id $iface_id]
                }

		set nsstr ""
		if { $nodeNs != "" } {
		    set nsstr "-n $nodeNs"
		}
		pipesExec "ip $nsstr link set $iface_name address $ether" "hold"
	    }
	    default {
		# capture physical interface directly into the node, without using a bridge
		# we don't know the name, so make sure all other options cover other IMUNES
		# 'physical' interfaces
		# XXX not yet implemented
		pipesExec "ip link set $iface_name netns $nodeNs" "hold"
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
    set docker_id "[getFromRunning "eid"].$node"

    foreach iface_id $ifaces {
	set iface_name $iface_id
	switch -exact [getLogIfcType $node_id $iface_id] {
	    vlan {
		# physical interfaces are created when creating links, so VLANs
		# must be created after links
	    }
	    lo {
		if { $iface_name != "lo0" } {
		    pipesExec "docker exec -d $docker_id ip link add $iface_name type dummy" "hold"
		    pipesExec "docker exec -d $docker_id ip link set $iface_name up" "hold"
		} else {
		    pipesExec "docker exec -d $docker_id ip link set dev lo down 2>/dev/null" "hold"
		    pipesExec "docker exec -d $docker_id ip link set dev lo name lo0 2>/dev/null" "hold"
		    pipesExec "docker exec -d $docker_id ip a flush lo0 2>/dev/null" "hold"
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
    pipesExec "ip $nsstr1x link set $eid-$ifname1 name $ifname1" "hold"
    pipesExec "ip $nsstr2x link set $eid-$ifname2 name $ifname2" "hold"

    if { $netNs2 == $eid } {
	pipesExec "ip netns exec $eid ip link set $ifname2 multicast off" "hold"
	pipesExec "ip netns exec $eid sysctl net.ipv6.conf.$ifname2.disable_ipv6=1" "hold"
    }
}

proc setNsIfcMaster { netNs ifname master state } {
    set nsstr ""
    if { $netNs != "" } {
	set nsstr "-n $netNs"
    }
    pipesExec "ip $nsstr link set $ifname master $master $state" "hold"
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

    if { [getNodeType $node1_id] in "rj45 extelem" || [getNodeType $node2_id] in "rj45 extelem" } {
	if { [getNodeType $node1_id] in "rj45 extelem" } {
	    set physical_ifc [getNodeName $node1_id]
	    if { [getNodeType $node1_id] == "extelem" } {
		set ifcs [getNodeExternalIfcs $node1_id]
		set physical_ifc [lindex [lsearch -inline -exact -index 0 $ifcs "$iface1_id"] 1]
	    } elseif { [getEtherVlanEnabled $node1_id] } {
		set vlan [getEtherVlanTag $node1_id]
		set physical_ifc $physical_ifc.$vlan
	    }
	    set nodeNs [getNodeNetns $eid $node2_id]
	    set full_virtual_ifc $eid-$node2_id-$iface2_id
	    set virtual_ifc $iface2_id
	    set ether [getIfcMACaddr $node2_id $virtual_ifc]

	    if { [[typemodel $node2_id].virtlayer] == "NATIVE" } {
		pipesExec "ip link set $physical_ifc netns $nodeNs" "hold"
		setNsIfcMaster $nodeNs $physical_ifc $node2_id "up"
		return
	    }
	} else {
	    set physical_ifc [getNodeName $node2_id]
	    if { [getNodeType $node2_id] == "extelem" } {
		set ifcs [getNodeExternalIfcs $node2_id]
		set physical_ifc [lindex [lsearch -inline -exact -index 0 $ifcs "$iface2_id"] 1]
	    } elseif { [getEtherVlanEnabled $node2_id] } {
		set vlan [getEtherVlanTag $node2_id]
		set physical_ifc $physical_ifc.$vlan
	    }
	    set nodeNs [getNodeNetns $eid $node1_id]
	    set full_virtual_ifc $eid-$node1_id-$iface1_id
	    set virtual_ifc $iface1_id
	    set ether [getIfcMACaddr $node1_id $virtual_ifc]

	    if { [[typemodel $node1_id].virtlayer] == "NATIVE" } {
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
	set iface1_id $eid-$node1_id
    }

    if { [getNodeType $node2_id] in "ext extnat" } {
	set iface2_id $eid-$node2_id
    }

    set node1Ns [getNodeNetns $eid $node1_id]
    set node2Ns [getNodeNetns $eid $node2_id]
    createNsVethPair $iface1_id $node1Ns $iface2_id $node2Ns

    # add nodes iface hooks to link bridge and bring them up
    foreach node_id [list $node1_id $node2_id] iface_id [list $iface1_id $iface2_id] ns [list $node1Ns $node2Ns] {
	if { [[typemodel $node_id].virtlayer] != "NATIVE" || [getNodeType $node_id] in "ext extnat" } {
	    continue
	}

	set iface_name $iface_id
	setNsIfcMaster $ns $iface_name $node_id "up"
    }
}

proc createLinkBetween { node1_id node2_id iface1_id iface2_id link_id } {
    set eid [getFromRunning "eid"]

    # create link bridge in experiment netns
    createNsLinkBridge $eid $link_id

    # add nodes iface hooks to link bridge and bring them up
    foreach node_id "$node1_id $node2_id" iface_id "$iface1_id $iface2_id" {
	set ifname $node_id-$iface_id
	if { [getNodeType $node_id] == "rj45" } {
	    set ifname [getNodeName $node_id]
	    if { [getEtherVlanEnabled $node_id] } {
		set vlan [getEtherVlanTag $node_id]
		set ifname $ifname.$vlan
	    }
	} elseif { [getNodeType $node_id] == "extelem" } {
	    # won't work if a node is a wireless interface
	    # because netns is not changed
	    set ifcs [getNodeExternalIfcs $node_id]
	    set ifname [lindex [lsearch -inline -exact -index 0 $ifcs "$iface_id"] 1]
	}

	setNsIfcMaster $eid $ifname $link_id "up"
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
	if { [getNodeType $node_id] in "rj45 extelem" } {
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

#****f* linux.tcl/startIfcsNode
# NAME
#   startIfcsNode -- start interfaces on node
# SYNOPSIS
#   startIfcsNode $node_id
# FUNCTION
#  Starts all interfaces on the given node.
# INPUTS
#   * node_id -- node id
#****
proc startIfcsNode { node_id } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set nodeNs [getNodeNetns $eid $node_id]
    pipesExec "ip -n $nodeNs link set dev lo down 2>/dev/null" "hold"
    pipesExec "ip -n $nodeNs link set dev lo name lo0 2>/dev/null" "hold"
    foreach iface_id [allIfcList $node_id] {
	set iface_name $iface_id
	set mtu [getIfcMTU $node_id $iface_id]
	if { [getLogIfcType $node_id $iface_id] == "vlan" } {
	    set tag [getIfcVlanTag $node_id $iface_id]
	    set dev [getIfcVlanDev $node_id $iface_id]
	    if { $tag != "" && $dev != "" } {
		pipesExec "ip -n $nodeNs link add link $dev name $iface_name type vlan id $tag" "hold"
	    }
	}
	if { [getIfcOperState $node_id $iface_id] == "up" } {
	    pipesExec "ip -n $nodeNs link set dev $iface_name up mtu $mtu" "hold"
	} else {
	    pipesExec "ip -n $nodeNs link set dev $iface_name mtu $mtu" "hold"
	}
	if { [getIfcNatState $node_id $iface_id] == "on" } {
	    pipesExec "ip netns exec $nodeNs iptables -t nat -A POSTROUTING -o $iface_name -j MASQUERADE" "hold"
	}
    }
}

proc isNodeConfigured { node_id } {
    set docker_id "[getFromRunning "eid"].$node_id"

    if { [[typemodel $node_id].virtlayer] == "NATIVE" } {
	return true
    }

    try {
	# docker exec sometimes hangs, so don't use it while we have other pipes opened
	exec docker inspect -f "{{.GraphDriver.Data.MergedDir}}" $docker_id
    } on ok mergedir {
	try {
	    exec test -f ${mergedir}/out.log
	} on error {} {
	    return false
	} on ok {} {
	    return true
	}
    } on error err {
	puts "Error on docker inspect: '$err'"
    }

    return false
}

proc isNodeError { node_id } {
    set docker_id "[getFromRunning "eid"].$node_id"

    if { [[typemodel $node_id].virtlayer] == "NATIVE" } {
	return false
    }

    try {
	# docker exec sometimes hangs, so don't use it while we have other pipes opened
	exec docker inspect -f "{{.GraphDriver.Data.MergedDir}}" $docker_id
    } on ok mergedir {
	try {
	    exec test -s ${mergedir}/err.log
	} on error {} {
	    return false
	} on ok {} {
	    return true
	}
    } on error err {
	puts "Error on docker inspect: '$err'"
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

proc removeExperimentContainer { eid widget } {
    removeNetns $eid
}

proc removeExperimentFiles { eid widget } {
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

proc runConfOnNode { node_id } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set docker_id "$eid.$node_id"

    if { [getCustomEnabled $node_id] == true } {
        set selected [getCustomConfigSelected $node_id]

        set bootcmd [getCustomConfigCommand $node_id $selected]
        set bootcfg [getCustomConfig $node_id $selected]
	if { [getAutoDefaultRoutesStatus $node_id] == "enabled" } {
	    foreach statrte [getDefaultIPv4routes $node_id] {
		lappend bootcfg [getIPv4RouteCmd $statrte]
	    }
	    foreach statrte [getDefaultIPv6routes $node_id] {
		lappend bootcfg [getIPv6RouteCmd $statrte]
	    }
	}
        set confFile "custom.conf"
    } else {
        set bootcfg [[typemodel $node_id].generateConfig $node_id]
        set bootcmd [[typemodel $node_id].bootcmd $node_id]
        set confFile "boot.conf"
    }

    generateHostsFile $node_id

    set nodeNs [getNodeNetns $eid $node_id]
    foreach ifc [allIfcList $node_id] {
	if { [getIfcOperState $node_id $ifc] == "down" } {
	    pipesExec "ip -n $nodeNs link set dev $ifc down"
	}
    }

    set cfg [join "{ip a flush dev lo0} $bootcfg" "\n"]
    writeDataToNodeFile $node_id /$confFile $cfg
    set cmds "$bootcmd /$confFile >> /tout.log 2>> /terr.log ;"
    # renaming the file signals that we're done
    set cmds "$cmds mv /tout.log /out.log ;"
    set cmds "$cmds mv /terr.log /err.log"
    pipesExec "docker exec -d $docker_id sh -c '$cmds'" "hold"
}

proc destroyDirectLinkBetween { eid node1_id node2_id } {
    if { [getNodeType $node1_id] in "ext extnat" } {
	pipesExec "ip link del $eid-$node1_id"
    } elseif { [getNodeType $node2_id] in "ext extnat" } {
	pipesExec "ip link del $eid-$node2_id"
    }
}

proc destroyLinkBetween { eid node1_id node2_id link_id } {
    pipesExec "ip -n $eid link del $link_id"
}

#****f* linux.tcl/destroyNodeIfaces
# NAME
#   destroyNodeIfaces -- destroy virtual node interfaces
# SYNOPSIS
#   destroyNodeIfaces $eid $vimages
# FUNCTION
#   Destroys all virtual node interfaces.
# INPUTS
#   * eid -- experiment id
#   * node_id -- virtual node id
#   * ifaces -- list of iface ids
#****
proc destroyNodeIfaces { eid node_id ifaces } {
    if { [getNodeType $node_id] in "ext extnat" } {
	pipesExec "ip link del $eid-$node_id" "hold"
	return
    }

    foreach iface_id $ifaces {
	set iface_name $iface_id
	pipesExec "ip $eid link del $node_id-$iface_name" "hold"
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
#   enableIPforwarding $eid $node_id
# FUNCTION
#   Enables IPv4 and IPv6 forwarding on the given node.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc enableIPforwarding { eid node_id } {
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

    pipesExec "docker exec -d $eid.$node_id sh -c \'$cmds\'" "hold"
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
#   captureExtIfc $eid $node_id
# FUNCTION
#   Captures the external interface given by the given rj45 node.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc captureExtIfc { eid node_id } {
    global execMode

    set ifname [getNodeName $node_id]
    if { [getEtherVlanEnabled $node_id] } {
	set vlan [getEtherVlanTag $node_id]
	try {
	    exec ip link add link $ifname name $ifname.$vlan type vlan id $vlan
	} on error err {
	    set msg "Error: VLAN $vlan on external interface $ifname can't be\
		created.\n($err)"

	    if { $execMode == "batch" } {
		puts $msg
	    } else {
		after idle { .dialog1.msg configure -wraplength 4i }
		tk_dialog .dialog1 "IMUNES error" $msg \
		    info 0 Dismiss
	    }

	    return -code error
	} on ok {} {
	    set ifname $ifname.$vlan
	}
    }

    if { [getLinkDirect [lindex [linkByIfc $node_id 0] 0]] } {
	return
    }

    captureExtIfcByName $eid $ifname
}

#****f* linux.tcl/captureExtIfcByName
# NAME
#   captureExtIfcByName -- capture external interface
# SYNOPSIS
#   captureExtIfcByName $eid $ifname
# FUNCTION
#   Captures the external interface given by the ifname.
# INPUTS
#   * eid -- experiment id
#   * ifname -- physical interface name
#****
proc captureExtIfcByName { eid ifname } {
    # won't work if the node is a wireless interface
    pipesExec "ip link set $ifname netns $eid" "hold"
}

#****f* linux.tcl/releaseExtIfc
# NAME
#   releaseExtIfc -- release external interface
# SYNOPSIS
#   releaseExtIfc $eid $node_id
# FUNCTION
#   Releases the external interface captured by the given rj45 node.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc releaseExtIfc { eid node_id } {
    set ifname [getNodeName $node_id]
    if { [getEtherVlanEnabled $node_id] } {
	set vlan [getEtherVlanTag $node_id]
	set ifname $ifname.$vlan
	catch { exec ip link del $ifname }

	return
    }

    if { [getLinkDirect [lindex [linkByIfc $node_id 0] 0]] } {
	return
    }

    releaseExtIfcByName $eid $ifname
}

#****f* linux.tcl/releaseExtIfc
# NAME
#   releaseExtIfc -- release external interface
# SYNOPSIS
#   releaseExtIfc $eid $node_id
# FUNCTION
#   Releases the external interface with the name ifname.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc releaseExtIfcByName { eid ifname } {
    global devfs_number

    pipesExec "ip -n $eid link set $ifname netns imunes_$devfs_number" "hold"

    return
}

proc getIPv4RouteCmd { statrte } {
    set route [lindex $statrte 0]
    set addr [lindex $statrte 1]
    set cmd "ip route append $route via $addr"
    return $cmd
}

proc getIPv6RouteCmd { statrte } {
    set route [lindex $statrte 0]
    set addr [lindex $statrte 1]
    set cmd "ip -6 route append $route via $addr"

    return $cmd
}

proc getIPv4IfcCmd { iface_name addr primary } {
    return "ip addr add $addr dev $iface_name"
}

proc getIPv6IfcCmd { iface_name addr primary } {
    return "ip -6 addr add $addr dev $iface_name"
}

#****f* linux.tcl/getRunningNodeIfcList
# NAME
#   getRunningNodeIfcList -- get interfaces list from the node
# SYNOPSIS
#   getRunningNodeIfcList $node_id
# FUNCTION
#   Returns the list of all network interfaces for the given node.
# INPUTS
#   * node_id -- node id
# RESULT
#   * list -- list in the form of {netgraph_node_name hook}
#****
proc getRunningNodeIfcList { node_id } {
    catch { exec docker exec [getFromRunning "eid"].$node_id ifconfig } full
    set lines [split $full "\n"]

    return $lines
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
#   execSetIfcQDisc $eid $node_id $iface $qdisc
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
    set target [linkByIfc $node_id $iface_id]
    set peers [getLinkPeers [lindex $target 0]]
    set dir [lindex $target 1]
    set lnode1 [lindex $peers 0]
    set lnode2 [lindex $peers 1]
    if { [getNodeType $lnode2] == "pseudo" } {
        set mirror_link [getLinkMirror [lindex $target 0]]
        set lnode2 [lindex [getLinkPeers $mirror_link] 0]
    }
    switch -exact $qdisc {
        FIFO { set qdisc fifo_fast }
        WFQ { set qdisc sfq }
        DRR { set qdisc drr }
    }

    set iface_name $iface_id
    pipesExec "ip netns exec $eid-$node_id tc qdisc add dev $iface_name root $qdisc" "hold"
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
#   iface_id -- interface name
#   qlen -- new queue's length
#****
proc execSetIfcQLen { eid node_id iface_id qlen } {
    set iface_name $iface_id
    pipesExec "ip -n $eid-$node_id l set $iface_name txqueuelen $qlen" "hold"
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

proc configureIfcLinkParams { eid node_id ifname bandwidth delay ber loss dup } {
    global debug

    set devname $node_id-$ifname
    if { [getNodeType $node_id] == "rj45" } {
        set devname [getNodeName $node_id]
    } elseif { [getNodeType $node_id] == "extelem" } {
	set ifcs [getNodeExternalIfcs $node_id]
	set devname [lindex [lsearch -inline -exact -index 0 $ifcs "$ifname"] 1]
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
    set iface1_id [ifcByLogicalPeer $node1_id $node2_id]
    set iface2_id [ifcByLogicalPeer $node2_id $node1_id]

    if { [getLinkMirror $link_id] != "" } {
	set mirror_link [getLinkMirror $link_id]
	if { [getNodeType $node1_id] == "pseudo" } {
	    set p_lnode1 $node1_id
	    set node1_id [lindex [getLinkPeers $mirror_link] 0]
	    set iface1_id [ifcByPeer $node1_id [getNodeMirror $p_lnode1]]
	} else {
	    set p_lnode2 $node2_id
	    set node2_id [lindex [getLinkPeers $mirror_link] 0]
	    set iface2_id [ifcByPeer $node2_id [getNodeMirror $p_lnode2]]
	}
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

proc ipsecFilesToNode { node_id local_cert ipsecret_file } {
    global ipsecConf ipsecSecrets

    if { $local_cert != "" } {
	set trimmed_local_cert [lindex [split $local_cert /] end]

	set fileId [open $trimmed_local_cert "r"]
	set trimmed_local_cert_data [read $fileId]
	close $fileId

	writeDataToNodeFile $node_id /etc/ipsec.d/certs/$trimmed_local_cert $trimmed_local_cert_data
    }

    if { $ipsecret_file != "" } {
	set trimmed_local_key [lindex [split $ipsecret_file /] end]

	set fileId [open $trimmed_local_key "r"]
	set trimmed_local_key_data "# /etc/ipsec.secrets - strongSwan IPsec secrets file\n"
	set trimmed_local_key_data "$trimmed_local_key_data[read $fileId]\n"
	set trimmed_local_key_data "$trimmed_local_key_data: RSA $trimmed_local_key"
	close $fileId

	writeDataToNodeFile $node_id /etc/ipsec.d/private/$trimmed_local_key $trimmed_local_key_data
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

# XXX NAT64 procedures
proc createStartTunIfc { eid node_id } {
    # create and start tun interface and return its name
    exec docker exec -i $eid.$node_id ip tuntap add mode tun
    catch "exec docker exec $eid.$node_id ip l | grep tun | tail -n1 | cut -d: -f2" tun
    set tun [string trim $tun]
    exec docker exec -i $eid.$node_id ip l set $tun up

    return $tun
}

proc prepareTaygaConf { eid node_id data datadir } {
    exec docker exec -i $eid.$node_id mkdir -p $datadir
    writeDataToNodeFile $node_id "/etc/tayga.conf" $data
}

proc taygaShutdown { eid node_id } {
    catch "exec docker exec $eid.$node_id killall5 -9 tayga"
    catch "exec docker exec $eid.$node_id rm -rf /var/db/tayga"
}

proc taygaDestroy { eid node_id } {
    global nat64ifc_$eid.$node_id
    catch { exec docker exec $eid.$node_id ip l delete [set nat64ifc_$eid.$node_id] }
}

proc startExternalConnection { eid node_id } {
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

    set ipv4 [getIfcIPv4addr $node_id $ifc]
    if { $ipv4 != "" } {
	set cmds "$cmds\n ip a add $ipv4 dev $outifc"
    }

    set ipv6 [getIfcIPv6addr $node_id $ifc]
    if { $ipv6 != "" } {
	set cmds "$cmds\n ip a add $ipv6 dev $outifc"
    }

    set cmds "$cmds\n ip l set $outifc up"

    pipesExec "$cmds" "hold"
}

proc stopExternalConnection { eid node_id } {
    pipesExec "ip link set $eid-$node_id down" "hold"
}

proc setupExtNat { eid node_id ifc } {
    set extIfc [getNodeName $node_id]
    set extIp [getIfcIPv4addrs $node_id $ifc]
    set prefixLen [lindex [split $extIp "/"] 1]
    set subnet "[ip::prefix $extIp]/$prefixLen"

    set cmds "iptables -t nat -A POSTROUTING -o $extIfc -j MASQUERADE -s $subnet"
    set cmds "$cmds\n iptables -A FORWARD -i $eid-$node_id -o $extIfc -j ACCEPT"
    set cmds "$cmds\n iptables -A FORWARD -o $eid-$node_id -j ACCEPT"

    pipesExec "$cmds" "hold"
}

proc unsetupExtNat { eid node_id ifc } {
    set extIfc [getNodeName $node_id]
    set extIp [getIfcIPv4addrs $node_id $ifc]
    set prefixLen [lindex [split $extIp "/"] 1]
    set subnet "[ip::prefix $extIp]/$prefixLen"

    set cmds "iptables -t nat -D POSTROUTING -o $extIfc -j MASQUERADE -s $subnet"
    set cmds "$cmds\n iptables -D FORWARD -i $eid-$node_id -o $extIfc -j ACCEPT"
    set cmds "$cmds\n iptables -D FORWARD -o $eid-$node_id -j ACCEPT"

    pipesExec "$cmds" "hold"
}
