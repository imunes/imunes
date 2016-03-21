global VROOT_MASTER
set VROOT_MASTER "imunes/vroot"

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
    set node_dir [getVrootDir]/$eid/$node

    writeDataToFile $node_dir/$path $data
    exec docker exec -i $node_id sh -c "cat > $path" < $node_dir/$path
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

    catch {eval [concat "nexec docker exec " $eid.$node $cmd] } output
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
    nexec xterm -sb -rightbar \
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
    global VROOT_MASTER execMode
    catch {exec docker images} images

    if {[lsearch $images "*$VROOT_MASTER"] != -1} {
        return 1
    } else {
        if {$execMode == "batch"} {
            puts "Docker template for virtual nodes:
    $VROOT_MASTER
is missing.
Run 'imunes -p' to pull the template."
        } else {
            tk_dialog .dialog1 "IMUNES error" \
        "Docker template for virtual nodes:
    $VROOT_MASTER
is missing.
Run 'imunes -p' to pull the template." \
            info 0 Dismiss
        }
        return 0
    }
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

proc createExperimentContainer {} {}

proc loadKernelModules {} {
    global all_modules_list

    foreach module $all_modules_list {
        if {[info procs $module.prepareSystem] == "$module.prepareSystem"} {
            $module.prepareSystem
        }
    }
}

proc prepareVirtualFS {} {}

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
    pipesExec "mkdir -p /var/run/netns" "hold"
}

#XXX-comment
proc createNodeContainer { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global VROOT_MASTER debug

    set node_id "$eid.$node"

    set network "'none'"
    if { [getNodeDockerAttach $node] } {
	set network "'bridge'"
    }

    catch {exec docker run -d --privileged --cap-add=ALL --net=$network -h [getNodeName $node] \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        --name $node_id $VROOT_MASTER } err
    if { $debug } {
        puts "'exec docker run' ($node_id) caught:\n$err"
    }
    if { [getNodeDockerAttach $node] } {
	catch "exec docker exec $node_id ip l set eth0 down"
	catch "exec docker exec $node_id ip l set eth0 name ext0"
	catch "exec docker exec $node_id ip l set ext0 up"
    }

    set status ""
    while { [string match 'true' $status] != 1 } {
        catch {exec docker inspect --format '{{.State.Running}}' $node_id} status
    }

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
proc createNodePhysIfcs { node } {}

proc createNodeLogIfcs { node } {}

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

    pipesExec "docker exec $eid.$node sh -c \'$cmds\'" "hold"
}

proc createLinkBetween { lnode1 lnode2 ifname1 ifname2 } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set ether1 [getIfcMACaddr $lnode1 $ifname1]
    if {$ether1 == ""} {
        autoMACaddr $lnode1 $ifname1
    }
    set ether1 [getIfcMACaddr $lnode1 $ifname1]

    set ether2 [getIfcMACaddr $lnode2 $ifname2]
    if {$ether2 == ""} {
        autoMACaddr $lnode2 $ifname2
    }
    set ether2 [getIfcMACaddr $lnode2 $ifname2]

    if {[nodeType $lnode1] == "rj45"} {
        set lname1 [getNodeName $lnode1]
    } else {
        set lname1 $lnode1
    }

    if {[nodeType $lnode2] == "rj45"} {
        set lname2 [getNodeName $lnode2]
    } else {
        set lname2 $lnode2
    }

    switch -exact "[[typemodel $lnode1].virtlayer]-[[typemodel $lnode2].virtlayer]" {
	NETGRAPH-NETGRAPH {
	    if { [nodeType $lnode1] == "ext" } {
		catch "exec ovs-vsctl add-br $eid-$lnode1"
	    }
	    if { [nodeType $lnode2] == "ext" } {
		catch "exec ovs-vsctl add-br $eid-$lnode2"
	    }
	    # generate interface names
	    set hostIfc1 "$eid-$lname1-$ifname1"
	    set hostIfc2 "$eid-$lname2-$ifname2"
	    # create veth pair
	    catch {exec ip link add name "$hostIfc1" type veth peer name "$hostIfc2"}
	    # add veth interfaces to bridges
	    catch "exec ovs-vsctl add-port $eid-$lname1 $hostIfc1"
	    catch "exec ovs-vsctl add-port $eid-$lname2 $hostIfc2"
	    # set bridge interfaces up
	    exec ip link set dev $hostIfc1 up
	    exec ip link set dev $hostIfc2 up
	}
	VIMAGE-VIMAGE {
	    # prepare namespace files
	    set lnode1Ns [createNetNs $lnode1]
	    set lnode2Ns [createNetNs $lnode2]
	    # generate temporary interface names
	    set hostIfc1 "v${ifname1}pn${lnode1Ns}"
	    set hostIfc2 "v${ifname2}pn${lnode2Ns}"
	    # create veth pair
	    exec ip link add name "$hostIfc1" type veth peer name "$hostIfc2"
	    # move veth pair sides to node namespaces
	    setIfcNetNs $lnode1 $hostIfc1 $ifname1
	    setIfcNetNs $lnode2 $hostIfc2 $ifname2
	    # set mac addresses of node ifcs
	    exec nsenter -n -t $lnode1Ns ip link set dev "$ifname1" \
		address "$ether1"
	    exec nsenter -n -t $lnode2Ns ip link set dev "$ifname2" \
		address "$ether2"
	    # delete net namespace reference files
	    exec ip netns del $lnode1Ns
	    exec ip netns del $lnode2Ns
	}
	NETGRAPH-VIMAGE {
	    addNodeIfcToBridge $lname1 $ifname1 $lnode2 $ifname2 $ether2
	}
	VIMAGE-NETGRAPH {
	    addNodeIfcToBridge $lname2 $ifname2 $lnode1 $ifname1 $ether1
	}
    }
}

proc configureLinkBetween { lnode1 lnode2 ifname1 ifname2 link } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    # FIXME: merge this with execSet* commands
    execSetLinkParams $eid $link

    # if {[nodeType $lnode1] != "rj45" && [nodeType $lnode2] != "rj45"} {
    #     set qdisc [getIfcQDisc $lnode1 $ifname1]
    #     if {$qdisc ne "FIFO"} {
    #         execSetIfcQDisc $eid $lnode1 $ifname2 $qdisc
    #     }

    #     set qdisc [getIfcQDisc $lnode2 $ifname2]
    #     if {$qdisc ne "FIFO"} {
    #         execSetIfcQDisc $eid $lnode2 $ifname2 $qdisc
    #     }
    #     set qdrop [getIfcQDrop $node $ifc]
    #     if {$qdrop ne "drop-tail"} {
    #         execSetIfcQDrop $eid $node $ifc $qdrop
    #     }
    #     set qlen [getIfcQLen $node $ifc]
    #     if {$qlen ne 50} {
    #         execSetIfcQLen $eid $node $ifc $qlen
    #     }
    # }
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

    set cmds ""
    set nodeNs [getNodeNamespace $node]
    foreach ifc [allIfcList $node] {
        # FIXME: should also work for loopback
        if {$ifc != "lo0"} {
            set mtu [getIfcMTU $node $ifc]
            if {[getIfcOperState $node $ifc] == "up"} {
                set cmds "$cmds\n nsenter -n -t $nodeNs ip link set dev $ifc up mtu $mtu"
            } else {
                set cmds "$cmds\n nsenter -n -t $nodeNs ip link set dev $ifc mtu $mtu"
            }
        }
    }
    exec sh << $cmds
}

proc removeExperimentContainer { eid widget } {}

proc removeNodeContainer { eid node } {
    set node_id $eid.$node

    catch "exec docker kill $node_id"
    catch "exec docker rm $node_id"
}

proc killAllNodeProcesses { eid node } {
    set node_id "$eid.$node"

    catch "exec docker exec $node_id killall5 -9"
}

proc destroyVirtNodeIfcs { eid vimages } {}

proc runConfOnNode { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global execMode

    set node_dir [getVrootDir]/$eid/$node
    set node_id "$eid.$node"

    catch {exec docker exec $node_id umount /etc/resolv.conf /etc/hosts}

    if { [getCustomEnabled $node] == true } {
        set selected [getCustomConfigSelected $node]

        set bootcmd [getCustomConfigCommand $node $selected]
        set bootcfg [getCustomConfig $node $selected]
        set confFile "custom.conf"
    } else {
        set bootcfg [[typemodel $node].cfggen $node]
        set bootcmd [[typemodel $node].bootcmd $node]
        set confFile "boot.conf"
    }

    writeDataToFile $node_dir/$confFile [join $bootcfg "\n"]
    exec docker exec -i $node_id sh -c "cat > $confFile" < $node_dir/$confFile
    exec docker exec $node_id $bootcmd $confFile >& $node_dir/out.log &
    exec docker exec -i $node_id sh -c "cat > out.log" < $node_dir/out.log

    set nodeNs [getNodeNamespace $node]
    foreach ifc [allIfcList $node] {
        # FIXME: should also work for loopback
        if {$ifc != "lo0"} {
            if {[getIfcOperState $node $ifc] == "down"} {
                exec nsenter -n -t $nodeNs ip link set dev $ifc down
            }
        }
    }

    generateHostsFile $node
}

proc destroyLinkBetween { eid lnode1 lnode2 } {
    set ifname1 [ifcByLogicalPeer $lnode1 $lnode2]
    catch {exec ip link del dev $eid-$lnode1-$ifname1}
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
        # FIXME: make this work for loopback
        if {$ifc != "lo0"} {
            catch "exec docker exec $node_id ip addr flush dev $ifc"
        }
    }
}

proc removeExperimentContainer { eid widget } {
    set VROOT_BASE [getVrootDir]
    catch "exec rm -fr $VROOT_BASE/$eid &"
}

proc createNetgraphNode { eid node } {
    catch {exec ovs-vsctl add-br $eid-$node}
}

proc destroyNetgraphNode { eid node } {
    catch {exec ovs-vsctl del-br $eid-$node}
}

proc destroyNetgraphNodes { eid switches widget } {
    global execMode

    # destroying openvswitch nodes
    if { $switches != "" } {
        statline "Shutting down netgraph nodes..."
        set i 0
        foreach node $switches {
            incr i
            # statline "Shutting down openvswitch node $node ([typemodel $node])"
            [typemodel $node].destroy $eid $node
            if {$execMode != "batch"} {
                $widget.p step -1
            }
            displayBatchProgress $i [ llength $switches ]
        }
        statline ""
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
    createNetgraphNode $eid $node
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
    destroyNetgraphNode $eid $node
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

    pipesExec "docker exec $eid.$node sh -c \'$cmds\'" "hold"
}

#****f* linux.tcl/configDefaultLoIfc
# NAME
#   configDefaultLoIfc -- configure default logical interface
# SYNOPSIS
#   configDefaultLoIfc $eid $node
# FUNCTION
#   Configures the default logical interface address for the given node.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc configDefaultLoIfc { eid node } {
    pipesExec "docker exec $eid\.$node ifconfig lo 127.0.0.1/24" "hold"
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
    set ifname [getNodeName $node]
    createNetgraphNode $eid $ifname
    catch {exec ovs-vsctl add-port $eid-$ifname $ifname}
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
    set ifname [getNodeName $node]
    catch "destroyNetgraphNode $eid $ifname"
}

proc getIPv4RouteCmd { statrte } {
    set route [lindex $statrte 0]
    set addr [lindex $statrte 1]
    if {$route == "0.0.0.0/0"} {
        set cmd "ip route add $route via $addr"
    } else {
        set cmd "ip route add default via $addr"
    }
    return $cmd
}

proc getIPv6RouteCmd { statrte } {
    set route [lindex $statrte 0]
    set addr [lindex $statrte 1]
    if {$route == "::/0"} {
        set cmd "ip -6 route add $route via $addr"
    } else {
        set cmd "ip -6 route add default via $addr"
    }
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

proc hub.start { eid node } {
    set node_id "$eid-$node"
    catch {exec ovs-vsctl list-ports $node_id} ports
    foreach port $ports {
        catch {exec ovs-vsctl -- add bridge $node_id mirrors @m \
        -- --id=@p get port $port \
        -- --id=@m create mirror name=$port select-all=true output-port=@p}
    }
}

proc getNodeNamespace { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set node_id "$eid.$node"
    catch {exec docker inspect -f "{{.State.Pid}}" $node_id} ns
    return $ns
}

proc addNodeIfcToBridge { bridge brifc node ifc mac } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set nodeNs [createNetNs $node]
    # create bridge
    catch "exec ovs-vsctl add-br $eid-$bridge"

    # generate interface names
    set hostIfc "$eid-$bridge-$brifc"
    set guestIfc "$eid-$node-$ifc"

    # create veth pair
    exec ip link add name "$hostIfc" type veth peer name "$guestIfc"
    # add host side of veth pair to bridge
    catch "exec ovs-vsctl add-port $eid-$bridge $hostIfc"

    exec ip link set "$hostIfc" up

    # move guest side of veth pair to node namespace
    setIfcNetNs $node $guestIfc $ifc
    # set mac address
    exec nsenter -n -t $nodeNs ip link set dev "$ifc" address "$mac"
    # delete net namespace reference file
    exec ip netns del $nodeNs
}

proc checkSysPrerequisites {} {
    set msg ""
    if { [catch {exec docker ps } err] } {
        set msg "Cannot start experiment. Is docker installed and running (check the output of 'docker ps')?\n"
    }

    if { [catch {exec pgrep ovs-vswitchd } err ] } {
        set msg "Cannot start experiment. Is ovs-vswitchd installed and running (check the output of 'pgrep ovs-vswitchd')?\n"
    }

    if { [catch {exec nsenter --version}] } {
        set msg "Cannot start experiment. Is nsenter installed (check the output of 'nsenter --version')?\n"
    }

    if { [catch {exec xterm -version}] } {
        set msg "Cannot start experiment. Is xterm installed (check the output of 'xterm -version')?\n"
    }

    if { $msg != "" } {
        return "$msg\nIMUNES needs docker and ovs-vswitchd services running and\
xterm and nsenter installed."
    }

    return ""
}

proc createNetNs { node } {
    set nodeNs [getNodeNamespace $node]
    exec rm -f "/var/run/netns/$nodeNs"
    exec ln -s "/proc/$nodeNs/ns/net" "/var/run/netns/$nodeNs"
    return $nodeNs
}

proc setIfcNetNs { node oldIfc newIfc } {
    set nodeNs [getNodeNamespace $node]
    exec ip link set "$oldIfc" netns "$nodeNs"
    exec nsenter -n -t $nodeNs ip link set "$oldIfc" name "$newIfc"
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
        WFQ { set qdisc wfq }
        DRR { set qdisc drr }
    }
    exec docker exec $eid.$node tc qdisc add dev $ifc root $qdisc
}


proc configureIfcLinkParams { eid node ifname bandwidth delay ber dup } {
    global debug

    if {[nodeType $node] == "rj45"} {
        set lname [getNodeName $node]
    } else {
        set lname $node
    }

    # average packet size in the Internet is 576 bytes
    # XXX: maybe migrate to PER (packet error rate), on FreeBSD we calculate
    # BER with the magic number 576 and on Linux we take the value directly
    if { $ber != 0 } {
	set loss [expr (1 / double($ber)) * 576 * 8 * 100]
	if { $loss > 100 } {
	    set loss 100
	}
    } else {
	set loss 0
    }

    if { [[typemodel $node].virtlayer] == "NETGRAPH" } {
        catch {exec tc qdisc del dev $eid-$lname-$ifname root}

	# XXX: currently we have loss, but we can easily have
	# corrupt, add a tickbox to GUI, default behaviour
	# should be loss because we don't do corrupt on FreeBSD
	# set confstring "netem corrupt ${loss}%"
	# corrupt ${loss}%
	catch { exec tc qdisc add dev $eid-$lname-$ifname root netem \
	    rate ${bandwidth}bit \
	    loss random ${loss}% \
	    delay ${delay}us \
	    duplicate ${dup}% } err

	if { $debug && $err != "" } {
	    puts stderr "tc ERROR: $eid-$lname-$ifname, $err"
	    puts stderr "gui settings: bw $bandwidth loss $loss delay $delay dup $dup"
	    catch { exec tc qdisc show dev $eid-$lname-$ifname } status
	    puts stderr $status
	}

    }
    if { [[typemodel $node].virtlayer] == "VIMAGE" } {
        set nodeNs [getNodeNamespace $node]
        catch {exec nsenter -n -t $nodeNs tc qdisc del dev $ifname root}

	# XXX: same as the above
	exec nsenter -n -t $nodeNs tc qdisc add dev $ifname root netem \
	    rate ${bandwidth}bit \
	    loss random ${loss}% \
	    delay ${delay}us \
	    duplicate ${dup}%

    }

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
    global debug

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

    configureIfcLinkParams $eid $lnode1 $ifname1 $bandwidth $delay $ber $dup
    configureIfcLinkParams $eid $lnode2 $ifname2 $bandwidth $delay $ber $dup
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
    exec docker exec $eid.$node rm -rf /var/db/tayga
}

proc taygaDestroy { eid node } {
    global nat64ifc_$eid.$node
    catch {exec docker exec $eid.$node ip l delete [set nat64ifc_$eid.$node]}
}

# XXX External connection procedures
proc extInstantiate { node } {
}

proc startExternalIfc { eid node } {
    set cmds ""
    set ifc [lindex [ifcList $node] 0]
    set outifc "$eid-$node"

    set ether [getIfcMACaddr $node $ifc]
    if {$ether == ""} {
       autoMACaddr $node $ifc
    }
    set ether [getIfcMACaddr $node $ifc]
    set cmds "ip l set $outifc address $ether"

    set cmds "$cmds\n ip a flush dev $outifc"

    set ipv4 [getIfcIPv4addr $node $ifc]
    if {$ipv4 == ""} {
       autoIPv4addr $node $ifc
    }
    set ipv4 [getIfcIPv4addr $node $ifc]
    set cmds "$cmds\n ip a add $ipv4 dev $outifc"

    set ipv6 [getIfcIPv6addr $node $ifc]
    if {$ipv6 == ""} {
       autoIPv6addr $node $ifc
    }
    set ipv6 [getIfcIPv6addr $node $ifc]
    set cmds "$cmds\n ip a add $ipv6 dev $outifc"

    set cmds "$cmds\n ip l set $outifc up"

    exec sh << $cmds &
}

proc  stopExternalIfc { eid node } {
    exec ip l set $eid-$node down
}

proc destroyExtInterface { eid node } {
    destroyNetgraphNode $eid $node
}
