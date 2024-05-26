global VROOT_MASTER ULIMIT_FILE ULIMIT_PROC
set VROOT_MASTER "imunes/template"
set ULIMIT_FILE "1024:16384"
set ULIMIT_PROC "512:1024"

#****f* linux.tcl/l2node.instantiate
# NAME
#   l2node.instantiate -- instantiate
# SYNOPSIS
#   l2node.instantiate $eid $node
# FUNCTION
#   Procedure l2node.instantiate creates a new netgraph node of the appropriate type.
# INPUTS
#   * eid -- experiment id
#   * node -- id of the node (type of the node is either lanswitch or hub)
#****
proc l2node.instantiate { eid node } {
    set type [nodeType $node]

    set ageing_time ""
    if { $type == "hub" } {
	set ageing_time "ageing_time 0"
    }

    set nodeNs [getNodeNetns $eid $node]
    pipesExec "ip netns exec $nodeNs ip link add name $node type bridge $ageing_time" "hold"
    pipesExec "ip netns exec $nodeNs ip link set $node up" "hold"
}

#****f* linux.tcl/l2node.destroy
# NAME
#   l2node.destroy -- destroy
# SYNOPSIS
#   l2node.destroy $eid $node
# FUNCTION
#   Destroys a l2 node.
# INPUTS
#   * eid -- experiment id
#   * node -- id of the node
#****
proc l2node.destroy { eid node } {
    set type [nodeType $node]

    set nodeNs [getNodeNetns $eid $node]

    set nsstr ""
    if { $nodeNs != "" } {
	set nsstr "-n $nodeNs"
    }
    pipesExec "ip $nsstr link delete $node" "hold"

    removeNodeNetns $eid $node
}

#****f* linux.tcl/writeDataToNodeFile
# NAME
#   writeDataToNodeFile -- write data to virtual node
# SYNOPSIS
#   writeDataToNodeFile $node $path $data
# FUNCTION
#   Writes data to a file on the specified virtual node.
# INPUTS
#   * node -- virtual node id
#   * path -- path to file in node
#   * data -- data to write
#****
proc writeDataToNodeFile { node path data } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set node_id "$eid.$node"
    catch { exec docker inspect -f "{{.GraphDriver.Data.MergedDir}}" $node_id } node_dir

    writeDataToFile $node_dir/$path $data
}

#****f* linux.tcl/execCmdNode
# NAME
#   execCmdNode -- execute command on virtual node
# SYNOPSIS
#   execCmdNode $node $cmd
# FUNCTION
#   Executes a command on a virtual node and returns the output.
# INPUTS
#   * node -- virtual node id
#   * cmd -- command to execute
# RESULT
#   * returns the execution output
#****
proc execCmdNode { node cmd } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    catch {eval [concat "exec docker exec " $eid.$node $cmd] } output
    return $output
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
    upvar 0 ::cf::[set ::curcfg]::eid eid
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
#   checkForApplications $node $app_list
# FUNCTION
#   Checks whether a list of applications exist on the virtual node by using
#   the which command.
# INPUTS
#   * node -- virtual node id
#   * app_list -- list of applications
# RESULT
#   * returns 0 if the applications exist, otherwise it returns 1.
#****
proc checkForApplications { node app_list } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    foreach app $app_list {
    set status [ catch { exec docker exec $eid.$node which $app } err ]
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
#   startWiresharkOnNodeIfc $node $ifc
# FUNCTION
#   Start Wireshark on a virtual node on the specified interface.
# INPUTS
#   * node -- virtual node id
#   * ifc -- virtual node interface
#****
proc startWiresharkOnNodeIfc { node ifc } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    if {[checkForExternalApps "startxcmd"] == 0 && \
    [checkForApplications $node "wireshark"] == 0} {
        startXappOnNode $node "wireshark -ki $ifc"
    } else {
	set wiresharkComm ""
	foreach wireshark "wireshark wireshark-gtk wireshark-qt" {
	    if {[checkForExternalApps $wireshark] == 0} {
		set wiresharkComm $wireshark
		break
	    }
	}

	if { $wiresharkComm != "" } {
	    exec docker exec $eid.$node tcpdump -s 0 -U -w - -i $ifc 2>/dev/null |\
	    $wiresharkComm -o "gui.window_title:$ifc@[getNodeName $node] ($eid)" -k -i - &
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
#   startXappOnNode $node $app
# FUNCTION
#   Start X application on virtual node
# INPUTS
#   * node -- virtual node id
#   * app -- application to start
#****
proc startXappOnNode { node app } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global debug
    if {[checkForExternalApps "socat"] != 0 } {
        puts "To run X applications on the node, install socat on your host."
        return
    }

    set logfile "/dev/null"
    if {$debug} {
        set logfile "/tmp/startxcmd_$eid\_$node.log"
    }

    eval exec startxcmd [getNodeName $node]@$eid $app > $logfile 2>> $logfile &
}

#****f* linux.tcl/startTcpdumpOnNodeIfc
# NAME
#   startTcpdumpOnNodeIfc -- start tcpdump on an interface
# SYNOPSIS
#   startTcpdumpOnNodeIfc $node $ifc
# FUNCTION
#   Start tcpdump in xterm on a virtual node on the specified interface.
# INPUTS
#   * node -- virtual node id
#   * ifc -- virtual node interface
#****
proc startTcpdumpOnNodeIfc { node ifc } {
    if {[checkForApplications $node "tcpdump"] == 0} {
        spawnShell $node "tcpdump -ni $ifc"
    }
}

#****f* linux.tcl/existingShells
# NAME
#   existingShells -- check which shells exist in a node
# SYNOPSIS
#   existingShells $shells $node
# FUNCTION
#   This procedure checks which of the provided shells are available
#   in a running node.
# INPUTS
#   * shells -- list of shells.
#   * node -- node id of the node for which the check is performed.
#****
proc existingShells { shells node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set existing []
    foreach shell $shells {
        set cmd "docker exec $eid.$node which $shell"
        set err [catch {eval exec $cmd} res]
        if  {!$err} {
            lappend existing $res
        }
    }
    return $existing
}

#****f* linux.tcl/spawnShell
# NAME
#   spawnShell -- spawn shell
# SYNOPSIS
#   spawnShell $node $cmd
# FUNCTION
#   This procedure spawns a new shell for a specified node.
#   The shell is specified in cmd parameter.
# INPUTS
#   * node -- node id of the node for which the shell is spawned.
#   * cmd -- the path to the shell.
#****
proc spawnShell { node cmd } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set node_id $eid\.$node

    # FIXME make this modular
    exec xterm -sb -rightbar \
    -T "IMUNES: [getNodeName $node] (console) [string trim [lindex [split $cmd /] end] ']" \
    -e "docker exec -it $node_id $cmd" 2> /dev/null &
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
    catch {exec himage -l | cut -d " " -f 1} exp_list
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
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    global VROOT_MASTER execMode

    set snapshots $VROOT_MASTER
    foreach node $node_list {
	set img [getNodeCustomImage $node]
	if {$img != ""} {
	    lappend snapshots $img
	}
    }
    set snapshots [lsort -uniq $snapshots]
    set missing 0

    foreach template $snapshots {
	set search_template $template
	if {[string match "*:*" $template] != 1} {
	    append search_template ":latest"
	}

	catch {exec docker images -q $search_template} images
	if {[llength $images] > 0} {
	    continue
	} else {
	    # be nice to the user and see whether there is an image id matching
	    if {[string length $template] == 12} {
                catch {exec docker images -q} all_images
		if {[lsearch $all_images $template] == -1} {
		    incr missing
		}
	    } else {
		incr missing
	    }
	    if {$missing} {
                if {$execMode == "batch"} {
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

proc prepareDevfs {} {}

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
#   getHostIfcVlanExists $node $name
# FUNCTION
#   Returns 1 if VLAN interface with the name $name for the given node cannot
#   be created.
# INPUTS
#   * node -- node id
#   * name -- interface name
# RESULT
#   * check -- 1 if interface exists, 0 otherwise
#****
proc getHostIfcVlanExists { node name } {
    global execMode

    # check if the VLAN is available
    set ifname [getNodeName $node]
    set vlan [lindex [split [getNodeName $node] .] 1]
    # if the VLAN is available then it can be created
    if { [catch {exec ip l show $ifname} err] } {
	return 0
    }

    set msg "Error: external interface $name can't be\
	created.\nVLAN $vlan is already in use. \n($err)"
    if { $execMode == "batch" } {
	puts $msg
    } else {
	after idle {.dialog1.msg configure -wraplength 4i}
	tk_dialog .dialog1 "IMUNES error" $msg \
	    info 0 Dismiss
    }

    return 1
}

proc removeNodeFS { eid node } {
    set VROOT_BASE [getVrootDir]

    pipesExec "rm -fr $VROOT_BASE/$eid/$node" "hold"
}

proc getNodeNetns { eid node } {
    global devfs_number

    # Top-level experiment netns
    if { $node in "" || [nodeType $node] in "rj45 extelem" } {
	return $eid
    }

    # Global netns
    if { [nodeType $node] in "ext extnat" } {
	return ""
    }

    # Node netns
    return $eid-$node
}

proc destroyNodeVirtIfcs { eid node } {
    set node_id "$eid.$node"

    pipesExec "docker exec -d $node_id sh -c 'for iface in `ls /sys/class/net` ; do ip link del \$iface; done'" "hold"
}

proc loadKernelModules {} {
    global all_modules_list

    foreach module $all_modules_list {
        if {[info procs $module.prepareSystem] == "$module.prepareSystem"} {
            $module.prepareSystem
        }
    }
}

proc prepareVirtualFS {} {
    exec mkdir -p /var/run/netns
}

proc attachToL3NodeNamespace { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    # VIMAGE nodes use docker netns
    set cmds "docker_ns=\$(docker inspect -f '{{.State.Pid}}' $eid.$node)"
    set cmds "$cmds; ip netns del \$docker_ns > /dev/null 2>&1"
    set cmds "$cmds; ip netns attach $eid-$node \$docker_ns"
    set cmds "$cmds; docker exec -d $eid.$node umount /etc/resolv.conf /etc/hosts"

    pipesExec "sh -c \'$cmds\'" "hold"
}

proc createNamespace { ns } {
    pipesExec "ip netns add $ns" "hold"
}

proc destroyNamespace { ns } {
    pipesExec "ip netns del $ns" "hold"
}

proc createExperimentContainer {} {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global devfs_number

    catch {exec ip netns attach imunes_$devfs_number 1}

    # Top-level experiment netns
    exec ip netns add $eid

}

#****f* linux.tcl/prepareFilesystemForNode
# NAME
#   prepareFilesystemForNode -- prepare node filesystem
# SYNOPSIS
#   prepareFilesystemForNode $node
# FUNCTION
#   Prepares the node virtual filesystem.
# INPUTS
#   * node -- node id
#****
proc prepareFilesystemForNode { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set VROOTDIR /var/imunes
    set VROOT_RUNTIME $VROOTDIR/$eid/$node
    pipesExec "mkdir -p $VROOT_RUNTIME" "hold"
}

#****f* linux.tcl/createNodeContainer
# NAME
#   createNodeContainer -- creates a virtual node container
# SYNOPSIS
#   createNodeContainer $node
# FUNCTION
#   Creates a docker instance using the defined template and
#   assigns the hostname. Waits for the node to be up.
# INPUTS
#   * node -- node id
#****
proc createNodeContainer { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global VROOT_MASTER ULIMIT_FILE ULIMIT_PROC debug

    set node_id "$eid.$node"

    set network "none"
    if { [getNodeDockerAttach $node] } {
	set network "bridge"
    }
    set vroot [getNodeCustomImage $node]
    if { $vroot == "" } {
        set vroot $VROOT_MASTER
    }

    pipesExec "docker run --detach --init --tty \
	--privileged --cap-add=ALL --net=$network \
	--name $node_id --hostname=[getNodeName $node] \
	--volume /tmp/.X11-unix:/tmp/.X11-unix \
	--sysctl net.ipv6.conf.all.disable_ipv6=0 \
	--ulimit nofile=$ULIMIT_FILE --ulimit nproc=$ULIMIT_PROC \
	$vroot &" "hold"
}

proc isNodeStarted { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    set node_id "$eid.$node"

    catch {exec docker inspect --format '{{.State.Running}}' $node_id} status

    return [string match 'true' $status]
}

proc isNodeNamespaceCreated { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    set nodeNs [getNodeNetns $eid $node]

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

#****f* linux.tcl/createNodePhysIfcs
# NAME
#   createNodePhysIfcs -- create node physical interfaces
# SYNOPSIS
#   createNodePhysIfcs $node
# FUNCTION
#   Creates physical interfaces for the given node.
# INPUTS
#   * node -- node id
#****
proc createNodePhysIfcs { node ifcs } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    if { [nodeType $node] in "extelem" } {
	return
    }

    set nodeNs [getNodeNetns $eid $node]
    set node_type [nodeType $node]

    # Create "physical" network interfaces
    foreach ifc $ifcs {
	set ifname $ifc
	set prefix [string trimright $ifc "0123456789"]
	if { $node_type in "ext extnat" } {
	    set ifname $eid-$node
	}

	# direct link, simulate capturing the host interface into the node,
	# without bridges between them
	set peer [peerByIfc $node $ifc]
	if { $peer != "" } {
	    set link [linkByPeers $node $peer]
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
		createNsVethPair $ifname $nodeNs $node-$ifc $eid
	    }
	}

	switch -exact $prefix {
	    e {
		# bridge private hook with L2 node
		setNsIfcMaster $nodeNs $ifname $node "up"
	    }
	    ext {
		# bridge private hook with ext node
		#setNsIfcMaster $nodeNs $ifname $eid-$node "up"
	    }
	    eth {
		set ether [getIfcMACaddr $node $ifc]
                if {$ether == ""} {
                    autoMACaddr $node $ifc
		    set ether [getIfcMACaddr $node $ifc]
                }

		set nsstr ""
		if { $nodeNs != "" } {
		    set nsstr "-n $nodeNs"
		}
		pipesExec "ip $nsstr link set $ifc address $ether" "hold"
	    }
	    default {
		# capture physical interface directly into the node, without using a bridge
		# we don't know the name, so make sure all other options cover other IMUNES
		# 'physical' interfaces
		# XXX not yet implemented
		pipesExec "ip link set $ifc netns $nodeNs" "hold"
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

#****f* linux.tcl/createNodeLogIfcs
# NAME
#   createNodeLogIfcs -- create node logical interfaces
# SYNOPSIS
#   createNodeLogIfcs $node
# FUNCTION
#   Creates logical interfaces for the given node.
# INPUTS
#   * node -- node id
#****
proc createNodeLogIfcs { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set node_id "$eid.$node"

    foreach ifc [logIfcList $node] {
	switch -exact [getLogIfcType $node $ifc] {
	    vlan {
		# physical interfaces are created when creating links, so VLANs
		# must be created after links
	    }
	    lo {
		if {$ifc != "lo0"} {
		    pipesExec "docker exec -d $node_id ip link add $ifc type dummy" "hold"
		    pipesExec "docker exec -d $node_id ip link set $ifc up" "hold"
		}
	    }
	}
    }

    # docker interface is created before other ones, so let's rename it to something that's not used by IMUNES
    if { [getNodeDockerAttach $node] } {
	set cmds "ip r save > /tmp/routes"
	set cmds "$cmds ; ip l set eth0 down"
	set cmds "$cmds ; ip l set eth0 name docker0"
	set cmds "$cmds ; ip l set docker0 up"
	set cmds "$cmds ; ip r restore < /tmp/routes"
	set cmds "$cmds ; rm -f /tmp/routes"
	pipesExec "docker exec -d $node_id sh -c '$cmds'" "hold"
    }
}

#****f* linux.tcl/configureICMPoptions
# NAME
#   configureICMPoptions -- configure ICMP options
# SYNOPSIS
#   configureICMPoptions $node
# FUNCTION
#  Configures the necessary ICMP sysctls in the given node.
# INPUTS
#   * node -- node id
#****
proc configureICMPoptions { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    array set sysctl_icmp {
	net.ipv4.icmp_ratelimit			0
	net.ipv4.icmp_echo_ignore_broadcasts	1
    }

    foreach {name val} [array get sysctl_icmp] {
	lappend cmd "sysctl $name=$val"
    }
    set cmds [join $cmd "; "]

    pipesExec "docker exec -d $eid.$node sh -c '$cmds ; touch /tmp/init'" "hold"
}

proc isNodeInitNet { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    set node_id "$eid.$node"

    try {
	exec docker inspect -f "{{.GraphDriver.Data.MergedDir}}" $node_id
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
    pipesExec "ip $nsstr link add name $link type bridge ageing_time 0" "hold"
    pipesExec "ip $nsstr link set $link up" "hold"
}

proc createNsVethPair { ifname1 netNs1 ifname2 netNs2 } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

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
#   createDirectLinkBetween $lnode1 $lnode2 $ifname1 $ifname2
# FUNCTION
#   Creates direct link between two given nodes. Direct link connects the host
#   interface into the node, without ng_node between them.
# INPUTS
#   * lnode1 -- node id of the first node
#   * lnode2 -- node id of the second node
#   * iname1 -- interface name on the first node
#   * iname2 -- interface name on the second node
#****
proc createDirectLinkBetween { lnode1 lnode2 ifname1 ifname2 } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    if { [nodeType $lnode1] in "rj45 extelem" || [nodeType $lnode2] in "rj45 extelem" } {
	if { [nodeType $lnode1] in "rj45 extelem" } {
	    set physical_ifc [getNodeName $lnode1]
	    if { [nodeType $lnode1] == "extelem" } {
		set ifcs [getNodeExternalIfcs $lnode1]
		set physical_ifc [lindex [lsearch -inline -exact -index 0 $ifcs "$ifname1"] 1]
	    }
	    set nodeNs [getNodeNetns $eid $lnode2]
	    set full_virtual_ifc $eid-$lnode2-$ifname2
	    set virtual_ifc $ifname2
	    set ether [getIfcMACaddr $lnode2 $virtual_ifc]

	    if { [[typemodel $lnode2].virtlayer] == "NETGRAPH" } {
		pipesExec "ip link set $physical_ifc netns $nodeNs" "hold"
		setNsIfcMaster $nodeNs $physical_ifc $lnode2 "up"
		return
	    }
	} else {
	    set physical_ifc [getNodeName $lnode2]
	    if { [nodeType $lnode2] == "extelem" } {
		set ifcs [getNodeExternalIfcs $lnode2]
		set physical_ifc [lindex [lsearch -inline -exact -index 0 $ifcs "$ifname2"] 1]
	    }
	    set nodeNs [getNodeNetns $eid $lnode1]
	    set full_virtual_ifc $eid-$lnode1-$ifname1
	    set virtual_ifc $ifname1
	    set ether [getIfcMACaddr $lnode1 $virtual_ifc]

	    if { [[typemodel $lnode1].virtlayer] == "NETGRAPH" } {
		pipesExec "ip link set $physical_ifc netns $nodeNs" "hold"
		setNsIfcMaster $nodeNs $physical_ifc $lnode1 "up"
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

    if { [nodeType $lnode1] in "ext extnat" } {
	set ifname1 $eid-$lnode1
    }

    if { [nodeType $lnode2] in "ext extnat" } {
	set ifname2 $eid-$lnode2
    }

    set node1Ns [getNodeNetns $eid $lnode1]
    set node2Ns [getNodeNetns $eid $lnode2]
    createNsVethPair $ifname1 $node1Ns $ifname2 $node2Ns

    # add nodes ifc hooks to link bridge and bring them up
    foreach node [list $lnode1 $lnode2] ifc [list $ifname1 $ifname2] ns [list $node1Ns $node2Ns] {
	if { [[typemodel $node].virtlayer] != "NETGRAPH" || [nodeType $node] in "ext extnat" } {
	    continue
	}

	setNsIfcMaster $ns $ifc $node "up"
    }
}

proc createLinkBetween { lnode1 lnode2 ifname1 ifname2 link } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    # create link bridge in experiment netns
    createNsLinkBridge $eid $link

    # add nodes ifc hooks to link bridge and bring them up
    foreach node "$lnode1 $lnode2" ifc "$ifname1 $ifname2" {
	set ifname $node-$ifc
	if { [nodeType $node] == "rj45" } {
	    set ifname [getNodeName $node]
	} elseif { [nodeType $node] == "extelem" } {
	    # won't work if the node is a wireless interface
	    # because netns is not changed
	    set ifcs [getNodeExternalIfcs $node]
	    set ifname [lindex [lsearch -inline -exact -index 0 $ifcs "$ifc"] 1]
	}

	setNsIfcMaster $eid $ifname $link "up"
    }
}

proc configureLinkBetween { lnode1 lnode2 ifname1 ifname2 link } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set bandwidth [expr [getLinkBandwidth $link] + 0]
    set delay [expr [getLinkDelay $link] + 0]
    set ber [expr [getLinkBER $link] + 0]
    set dup [expr [getLinkDup $link] + 0]

    configureIfcLinkParams $eid $lnode1 $ifname1 $bandwidth $delay $ber $dup
    configureIfcLinkParams $eid $lnode2 $ifname2 $bandwidth $delay $ber $dup

    # FIXME: remove this to interface configuration?
    foreach node "$lnode1 $lnode2" ifc "$ifname1 $ifname2" {
	if { [nodeType $node] in "rj45 extelem" } {
	    continue
	}

	set qdisc [getIfcQDisc $node $ifc]
	if { $qdisc != "FIFO" } {
	    execSetIfcQDisc $eid $node $ifc $qdisc
	}
	set qlen [getIfcQLen $node $ifc]
	if { $qlen != 1000 } {
	    execSetIfcQLen $eid $node $ifc $qlen
	}
    }
}

#****f* linux.tcl/startIfcsNode
# NAME
#   startIfcsNode -- start interfaces on node
# SYNOPSIS
#   startIfcsNode $node
# FUNCTION
#  Starts all interfaces on the given node.
# INPUTS
#   * node -- node id
#****
proc startIfcsNode { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set nodeNs [getNodeNetns $eid $node]
    pipesExec "ip -n $nodeNs link set dev lo down 2>/dev/null" "hold"
    pipesExec "ip -n $nodeNs link set dev lo name lo0 2>/dev/null" "hold"
    foreach ifc [allIfcList $node] {
	set mtu [getIfcMTU $node $ifc]
	if { [getLogIfcType $node $ifc] == "vlan" } {
	    set tag [getIfcVlanTag $node $ifc]
	    set dev [getIfcVlanDev $node $ifc]
	    if {$tag != "" && $dev != ""} {
		pipesExec "ip -n $nodeNs link add link $dev name $ifc type vlan id $tag" "hold"
	    }
	}
	if {[getIfcOperState $node $ifc] == "up"} {
	    pipesExec "ip -n $nodeNs link set dev $ifc up mtu $mtu" "hold"
	} else {
	    pipesExec "ip -n $nodeNs link set dev $ifc mtu $mtu" "hold"
	}
	if {[getIfcNatState $node $ifc] == "on"} {
	    pipesExec "ip netns exec $nodeNs iptables -t nat -A POSTROUTING -o $ifc -j MASQUERADE" "hold"
	}
    }
}

proc isNodeConfigured { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    set node_id "$eid.$node"

    if { [[typemodel $node].virtlayer] == "NETGRAPH" } {
	return true
    }

    try {
	# docker exec sometimes hangs, so don't use it while we have other pipes opened
	exec docker inspect -f "{{.GraphDriver.Data.MergedDir}}" $node_id
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

proc isNodeError { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    set node_id "$eid.$node"

    if { [[typemodel $node].virtlayer] == "NETGRAPH" } {
	return false
    }

    try {
	# docker exec sometimes hangs, so don't use it while we have other pipes opened
	exec docker inspect -f "{{.GraphDriver.Data.MergedDir}}" $node_id
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

proc removeNodeNetns { eid node } {
    set netns [getNodeNetns $eid $node]

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

proc removeNodeContainer { eid node } {
    set node_id $eid.$node

    pipesExec "docker kill $node_id" "hold"
    pipesExec "docker rm $node_id" "hold"
}

proc killAllNodeProcesses { eid node } {
    set node_id "$eid.$node"

    # kill all processes except pid 1 and its child(ren)
    pipesExec "docker exec -d $node_id sh -c 'killall5 -9 -o 1 -o \$(pgrep -P 1)'" "hold"
}

proc runConfOnNode { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set node_id "$eid.$node"

    if { [getCustomEnabled $node] == true } {
        set selected [getCustomConfigSelected $node]

        set bootcmd [getCustomConfigCommand $node $selected]
        set bootcfg [getCustomConfig $node $selected]
	if { [getAutoDefaultRoutesStatus $node] == "enabled" } {
	    foreach statrte [getDefaultIPv4routes $node] {
		lappend bootcfg [getIPv4RouteCmd $statrte]
	    }
	    foreach statrte [getDefaultIPv6routes $node] {
		lappend bootcfg [getIPv6RouteCmd $statrte]
	    }
	}
        set confFile "custom.conf"
    } else {
        set bootcfg [[typemodel $node].cfggen $node]
        set bootcmd [[typemodel $node].bootcmd $node]
        set confFile "boot.conf"
    }

    generateHostsFile $node

    set nodeNs [getNodeNetns $eid $node]
    foreach ifc [allIfcList $node] {
	if {[getIfcOperState $node $ifc] == "down"} {
	    pipesExec "ip -n $nodeNs link set dev $ifc down"
	}
    }

    set cfg [join "{ip a flush dev lo0} $bootcfg" "\n"]
    writeDataToNodeFile $node /$confFile $cfg
    set cmds "$bootcmd /$confFile >> /tout.log 2>> /terr.log ;"
    # renaming the file signals that we're done
    set cmds "$cmds mv /tout.log /out.log ;"
    set cmds "$cmds mv /terr.log /err.log"
    pipesExec "docker exec -d $node_id sh -c '$cmds'" "hold"
}

proc destroyDirectLinkBetween { eid lnode1 lnode2 } {
    if { [nodeType $lnode1] in "ext extnat" } {
	pipesExec "ip link del $eid-$lnode1"
    } elseif { [nodeType $lnode2] in "ext extnat" } {
	pipesExec "ip link del $eid-$lnode2"
    }
}

proc destroyLinkBetween { eid lnode1 lnode2 link } {
    pipesExec "ip -n $eid link del $link"
}

#****f* linux.tcl/destroyNodeIfcs
# NAME
#   destroyNodeIfcs -- destroy virtual node interfaces
# SYNOPSIS
#   destroyNodeIfcs $eid $vimages
# FUNCTION
#   Destroys all virtual node interfaces.
# INPUTS
#   * eid -- experiment id
#   * vimages -- list of virtual nodes
#****
proc destroyNodeIfcs { eid node ifcs } {
    if { [nodeType $node] in "ext extnat" } {
	pipesExec "ip link del $eid-$node" "hold"
	return
    }

    foreach ifc $ifcs {
	pipesExec "ip $eid link del $node-$ifc" "hold"
    }
}

#****f* linux.tcl/removeNodeIfcIPaddrs
# NAME
#   removeNodeIfcIPaddrs -- remove node iterfaces' IP addresses
# SYNOPSIS
#   removeNodeIfcIPaddrs $eid $node
# FUNCTION
#   Remove all IPv4 and IPv6 addresses from interfaces on the given node.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc removeNodeIfcIPaddrs { eid node } {
    set node_id "$eid.$node"
    foreach ifc [allIfcList $node] {
	pipesExec "docker exec -d $node_id sh -c 'ip addr flush dev $ifc'" "hold"
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
#   enableIPforwarding $eid $node
# FUNCTION
#   Enables IPv4 and IPv6 forwarding on the given node.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc enableIPforwarding { eid node } {
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

    pipesExec "docker exec -d $eid.$node sh -c \'$cmds\'" "hold"
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
proc getExtIfcs { } {
    catch { exec ls /sys/class/net } ifcs
    foreach ignore "lo* ipfw* tun*" {
        set ifcs [ lsearch -all -inline -not $ifcs $ignore ]
    }
    return "$ifcs"
}

#****f* linux.tcl/captureExtIfc
# NAME
#   captureExtIfc -- capture external interfaces
# SYNOPSIS
#   captureExtIfc $eid $node
# FUNCTION
#   Captures the external interfaces given by the given rj45 node.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc captureExtIfc { eid node } {
    if { [getLinkDirect [lindex [linkByIfc $node 0] 0]] } {
	return
    }

    set ifname [getNodeName $node]
    pipesExec "ip link set $ifname netns $eid" "hold"
}

proc captureExtIfcByName { eid ifname } {
    global execMode

    set ifc [lindex [split $ifname .] 0]
    set vlan [lindex [split $ifname .] 1]
    if { $vlan != "" } {
	catch {exec ip link add link $ifc name $ifname type vlan id $vlan} err
	if { $err != "" } {
	    set msg "Error: VLAN $vlan on external interface $ifc can't be\
		created.\n($err)"
	    if { $execMode == "batch" } {
		puts $msg
	    } else {
		after idle {.dialog1.msg configure -wraplength 4i}
		tk_dialog .dialog1 "IMUNES error" $msg \
		    info 0 Dismiss
	    }
	} else {
	    catch {exec ip link set $ifname up} err
	}
    }

    # won't work if the node is a wireless interface
    pipesExec "ip link set $ifname netns $eid" "hold"
}

#****f* linux.tcl/releaseExtIfc
# NAME
#   releaseExtIfc -- release external interfaces
# SYNOPSIS
#   releaseExtIfc $eid $node
# FUNCTION
#   Releases the external interfaces captured by the given rj45 node.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc releaseExtIfc { eid node } {
    if { [getLinkDirect [lindex [linkByIfc $node 0] 0]] } {
	return
    }

    global devfs_number

    set ifname [getNodeName $node]
    pipesExec "ip -n $eid link set $ifname netns imunes_$devfs_number" "hold"
}

proc releaseExtIfcByName { eid ifname } {
    global devfs_number

    set ifc [lindex [split $ifname .] 0]
    set vlan [lindex [split $ifname .] 1]
    if { $vlan != "" } {
	catch { exec ip link del $ifname }
    }

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

proc getIPv4IfcCmd { ifc addr primary } {
    return "ip addr add $addr dev $ifc"
}

proc getIPv6IfcCmd { ifc addr primary } {
    return "ip -6 addr add $addr dev $ifc"
}

#****f* linux.tcl/getRunningNodeIfcList
# NAME
#   getRunningNodeIfcList -- get interfaces list from the node
# SYNOPSIS
#   getRunningNodeIfcList $node
# FUNCTION
#   Returns the list of all network interfaces for the given node.
# INPUTS
#   * node -- node id
# RESULT
#   * list -- list in the form of {netgraph_node_name hook}
#****
proc getRunningNodeIfcList { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    catch {exec docker exec $eid.$node ifconfig} full
    set lines [split $full "\n"]

    return $lines
}

proc checkSysPrerequisites {} {
    set msg ""
    if { [catch {exec docker ps } err] } {
        set msg "Cannot start experiment. Is docker installed and running (check the output of 'docker ps')?\n"
    }

    if { [catch {exec nsenter --version}] } {
        set msg "Cannot start experiment. Is nsenter installed (check the output of 'nsenter --version')?\n"
    }

    if { [catch {exec xterm -version}] } {
        set msg "Cannot start experiment. Is xterm installed (check the output of 'xterm -version')?\n"
    }

    if { $msg != "" } {
	return "$msg\nIMUNES needs docker service running and xterm and nsenter installed."
    }

    return ""
}

#****f* linux.tcl/execSetIfcQDisc
# NAME
#   execSetIfcQDisc -- in exec mode set interface queuing discipline
# SYNOPSIS
#   execSetIfcQDisc $eid $node $ifc $qdisc
# FUNCTION
#   Sets the queuing discipline during the simulation.
#   New queuing discipline is defined in qdisc parameter.
#   Queueing discipline can be set to fifo, wfq or drr.
# INPUTS
#   eid -- experiment id
#   node -- node id
#   ifc -- interface name
#   qdisc -- queuing discipline
#****
proc execSetIfcQDisc { eid node ifc qdisc } {
    set target [linkByIfc $node $ifc]
    set peers [linkPeers [lindex $target 0]]
    set dir [lindex $target 1]
    set lnode1 [lindex $peers 0]
    set lnode2 [lindex $peers 1]
    if { [nodeType $lnode2] == "pseudo" } {
        set mirror_link [getLinkMirror [lindex $target 0]]
        set lnode2 [lindex [linkPeers $mirror_link] 0]
    }
    switch -exact $qdisc {
        FIFO { set qdisc fifo_fast }
        WFQ { set qdisc sfq }
        DRR { set qdisc drr }
    }
    pipesExec "ip netns exec $eid-$node tc qdisc add dev $ifc root $qdisc" "hold"
}

#****f* linux.tcl/execSetIfcQLen
# NAME
#   execSetIfcQLen -- in exec mode set interface TX queue length
# SYNOPSIS
#   execSetIfcQLen $eid $node $ifc $qlen
# FUNCTION
#   Sets the queue length during the simulation.
#   New queue length is defined in qlen parameter.
# INPUTS
#   eid -- experiment id
#   node -- node id
#   ifc -- interface name
#   qlen -- new queue's length
#****
proc execSetIfcQLen { eid node ifc qlen } {
    pipesExec "ip -n $eid-$node l set $ifc txqueuelen $qlen" "hold"
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

proc configureIfcLinkParams { eid node ifname bandwidth delay ber dup } {
    global debug

    set devname $node-$ifname
    if { [nodeType $node] == "rj45" } {
        set devname [getNodeName $node]
    } elseif { [nodeType $node] == "extelem" } {
	set ifcs [getNodeExternalIfcs $node]
	set devname [lindex [lsearch -inline -exact -index 0 $ifcs "$ifname"] 1]
    }

    # Linux does not have BER, only PER, so we calculate it by using the average packet
    # size in the Internet (576 bytes): BER values lower than 4608 will have 100%
    # loss rate
    set loss 0
    if { $ber != 0 } {
	set loss [expr (1 / double($ber)) * 576 * 8 * 100]
	if { $loss > 100 } {
	    set loss 100
	}
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
#   execSetLinkParams $eid $link
# FUNCTION
#   Sets the link parameters during the simulation.
#   All the parameters are set at the same time.
# INPUTS
#   eid -- experiment id
#   link -- link id
#****
proc execSetLinkParams { eid link } {
    set lnode1 [lindex [linkPeers $link] 0]
    set lnode2 [lindex [linkPeers $link] 1]
    set ifname1 [ifcByLogicalPeer $lnode1 $lnode2]
    set ifname2 [ifcByLogicalPeer $lnode2 $lnode1]

    if { [getLinkMirror $link] != "" } {
	set mirror_link [getLinkMirror $link]
	if { [nodeType $lnode1] == "pseudo" } {
	    set p_lnode1 $lnode1
	    set lnode1 [lindex [linkPeers $mirror_link] 0]
	    set ifname1 [ifcByPeer $lnode1 [getNodeMirror $p_lnode1]]
	} else {
	    set p_lnode2 $lnode2
	    set lnode2 [lindex [linkPeers $mirror_link] 0]
	    set ifname2 [ifcByPeer $lnode2 [getNodeMirror $p_lnode2]]
	}
    }

    set bandwidth [expr [getLinkBandwidth $link] + 0]
    set delay [expr [getLinkDelay $link] + 0]
    set ber [expr [getLinkBER $link] + 0]
    set dup [expr [getLinkDup $link] + 0]

    pipesCreate
    configureIfcLinkParams $eid $lnode1 $ifname1 $bandwidth $delay $ber $dup
    configureIfcLinkParams $eid $lnode2 $ifname2 $bandwidth $delay $ber $dup
    pipesClose
}

proc ipsecFilesToNode { node local_cert ipsecret_file } {
    global ipsecConf ipsecSecrets

    if { $local_cert != "" } {
	set trimmed_local_cert [lindex [split $local_cert /] end]
	set fileId [open $trimmed_local_cert "r"]
	set trimmed_local_cert_data [read $fileId]
	writeDataToNodeFile $node /etc/ipsec.d/certs/$trimmed_local_cert $trimmed_local_cert_data
	close $fileId
    }

    if { $ipsecret_file != "" } {
	set trimmed_local_key [lindex [split $ipsecret_file /] end]
	set fileId [open $trimmed_local_key "r"]
	set trimmed_local_key_data "# /etc/ipsec.secrets - strongSwan IPsec secrets file\n"
	set trimmed_local_key_data "$trimmed_local_key_data[read $fileId]\n"
	set trimmed_local_key_data "$trimmed_local_key_data: RSA $trimmed_local_key"
	writeDataToNodeFile $node /etc/ipsec.d/private/$trimmed_local_key $trimmed_local_key_data
	close $fileId
    }

    writeDataToNodeFile $node /etc/ipsec.conf $ipsecConf
    writeDataToNodeFile $node /etc/ipsec.secrets $ipsecSecrets
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

proc moveFileFromNode { node path ext_path } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    catch {exec hcp [getNodeName $node]@$eid:$path $ext_path}
    catch {exec docker exec $eid.$node rm -fr $path}
}

# XXX NAT64 procedures
proc createStartTunIfc { eid node } {
    # create and start tun interface and return its name
    exec docker exec -i $eid.$node ip tuntap add mode tun
    catch "exec docker exec $eid.$node ip l | grep tun | tail -n1 | cut -d: -f2" tun
    set tun [string trim $tun]
    exec docker exec -i $eid.$node ip l set $tun up

    return $tun
}

proc prepareTaygaConf { eid node data datadir } {
    exec docker exec -i $eid.$node mkdir -p $datadir
    writeDataToNodeFile $node "/etc/tayga.conf" $data
}

proc taygaShutdown { eid node } {
    catch "exec docker exec $eid.$node killall5 -9 tayga"
    catch "exec docker exec $eid.$node rm -rf /var/db/tayga"
}

proc taygaDestroy { eid node } {
    global nat64ifc_$eid.$node
    catch {exec docker exec $eid.$node ip l delete [set nat64ifc_$eid.$node]}
}

proc startExternalConnection { eid node } {
    set cmds ""
    set ifc [lindex [ifcList $node] 0]
    set outifc "$eid-$node"

    set ether [getIfcMACaddr $node $ifc]
    if { $ether == "" } {
	autoMACaddr $node $ifc
	set ether [getIfcMACaddr $node $ifc]
    }
    set cmds "ip l set $outifc address $ether"

    set cmds "$cmds\n ip a flush dev $outifc"

    set ipv4 [getIfcIPv4addr $node $ifc]
    if { $ipv4 != "" } {
	set cmds "$cmds\n ip a add $ipv4 dev $outifc"
    }

    set ipv6 [getIfcIPv6addr $node $ifc]
    if { $ipv6 != "" } {
	set cmds "$cmds\n ip a add $ipv6 dev $outifc"
    }

    set cmds "$cmds\n ip l set $outifc up"

    pipesExec "$cmds" "hold"
}

proc stopExternalConnection { eid node } {
    pipesExec "ip link set $eid-$node down" "hold"
}

proc setupExtNat { eid node ifc } {
    set extIfc [getNodeName $node]
    set extIp [getIfcIPv4addrs $node $ifc]
    set prefixLen [lindex [split $extIp "/"] 1]
    set subnet "[ip::prefix $extIp]/$prefixLen"

    set cmds "iptables -t nat -A POSTROUTING -o $extIfc -j MASQUERADE -s $subnet"
    set cmds "$cmds\n iptables -A FORWARD -i $eid-$node -o $extIfc -j ACCEPT"
    set cmds "$cmds\n iptables -A FORWARD -o $eid-$node -j ACCEPT"

    pipesExec "$cmds" "hold"
}

proc unsetupExtNat { eid node ifc } {
    set extIfc [getNodeName $node]
    set extIp [getIfcIPv4addrs $node $ifc]
    set prefixLen [lindex [split $extIp "/"] 1]
    set subnet "[ip::prefix $extIp]/$prefixLen"

    set cmds "iptables -t nat -D POSTROUTING -o $extIfc -j MASQUERADE -s $subnet"
    set cmds "$cmds\n iptables -D FORWARD -i $eid-$node -o $extIfc -j ACCEPT"
    set cmds "$cmds\n iptables -D FORWARD -o $eid-$node -j ACCEPT"

    pipesExec "$cmds" "hold"
}
