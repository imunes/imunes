set VROOT_MASTER "imunes/vroot:base"

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
#   * returns 0 if the application exists, otherwise it returns 1.
#****
proc checkForApplications { node app_list } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    foreach app $app_list {
    set exists [ catch { exec docker exec $eid.$node which $app } err ]
        if { $exists } {
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

    if {[file exists /usr/local/bin/startxcmd] == 1 && \
    [checkForApplications $node "wireshark"] == 0} {
        startXappOnNode $node "wireshark -ki $ifc"
    } else {
        exec docker exec $eid.$node tcpdump -s 0 -U -w - -i $ifc 2>/dev/null |\
        wireshark -o "gui.window_title:$ifc@[getNodeName $node] ($eid)" -k -i - &
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
    if {[file exists /usr/local/bin/socat] != 1 } {
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
    -T "IMUNES: [getNodeName $node] (console) [lindex [split $cmd /] end]" \
    -e "docker exec -it $node_id $cmd" &
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
proc fetchRunningExperiments {} {}
    # FIXME: make this work in Linux

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

proc createExperimentContainer {} {}

proc loadKernelModules {} {
    global all_modules_list

    # FIXME: prepareSystem isn't the same on Linux
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
}

#XXX-comment
proc createNodeContainer { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global VROOT_MASTER

    set node_id "$eid.$node"

    catch {exec docker run --privileged --cap-add=ALL --net='none' -h [getNodeName $node] \
        --name $node_id $VROOT_MASTER perl -e sleep 2> /dev/null &}

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

    set node_id "$eid.$node"

    pipesExec "docker exec $node_id sysctl net.ipv4.icmp_echo_ignore_broadcasts=1" "hold"
    pipesExec "docker exec $node_id sysctl net.ipv4.icmp_ratelimit=0" "hold"
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

    if { [[typemodel $lnode1].virtlayer] == "NETGRAPH" } {
        if { [[typemodel $lnode2].virtlayer] == "NETGRAPH" } {
            exec ovs-vsctl add-port $eid.$lnode1 $eid.$lnode1.$ifname1 -- \
                set interface $eid.$lnode1.$ifname1 type=patch options:peer=$eid.$lnode2.$ifname2
            exec ovs-vsctl add-port $eid.$lnode2 $eid.$lnode2.$ifname2 -- \
                set interface $eid.$lnode2.$ifname2 type=patch options:peer=$eid.$lnode1.$ifname1
        }
        if { [[typemodel $lnode2].virtlayer] == "VIMAGE" } {
            exec pipework $eid.$lnode1 -i $ifname2 $eid.$lnode2 0/0 $ether2
        }
    } elseif { [[typemodel $lnode1].virtlayer] == "VIMAGE" } {
        if  { [[typemodel $lnode2].virtlayer] == "VIMAGE" } {
            set link [linkByPeers $lnode1 $lnode2]
            exec ovs-vsctl add-br $eid.$link
            exec pipework $eid.$link -i $ifname1 $eid.$lnode1 0/0 $ether1
            exec pipework $eid.$link -i $ifname2 $eid.$lnode2 0/0 $ether2
        }
        if { [[typemodel $lnode2].virtlayer] == "NETGRAPH" } {
            exec pipework $eid.$lnode2 -i $ifname1 $eid.$lnode1 0/0 $ether1
        }
    }
}

proc configureLinkBetween { lnode1 lnode2 ifname1 ifname2 link } {}

proc startIfcsNode { node } {}

proc removeExperimentContainer { eid widget } {}

proc removeNodeContainer { eid node } {
    set node_id $eid.$node

    exec docker rm $node_id
}

proc killAllNodeProcesses { eid node } {
    set node_id "$eid.$node"

    catch "exec docker kill $node_id"
}

proc destroyVirtNodeIfcs { eid vimages } {}

proc runConfOnNode { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global execMode

    set node_dir [getVrootDir]/$eid/$node
    set node_id "$eid.$node"

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

    catch {exec docker inspect --format '{{.Id}}' $node_id} id
    writeDataToFile $node_dir/$confFile [join $bootcfg "\n"]
    exec docker exec -i $node_id sh -c "cat > $confFile" < $node_dir/$confFile
    exec docker exec $node_id $bootcmd $confFile >& $node_dir/out.log &

    foreach ifc [allIfcList $node] {
        if {[getIfcOperState $node $ifc] == "down"} {
            exec docker exec $node_id ifconfig $ifc down
        }
    }
}

proc destroyLinkBetween { eid lnode1 lnode2 } {
    set lname [linkByPeers $lnode1 $lnode2]
    catch {exec ovs-vsctl del-br $eid.$lname}
}

proc removeNodeIfcIPaddrs { eid node } {}

proc removeExperimentContainer { eid widget } {
    set VROOT_BASE [getVrootDir]
    catch "exec rm -fr $VROOT_BASE/$eid &"
}

proc createNetgraphNode { eid node } {
    catch {exec ovs-vsctl add-br $eid.$node}
}

proc destroyNetgraphNode { eid node } {
    exec ovs-vsctl del-br $eid.$node
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
    pipesExec "docker exec $eid\.$node sysctl net.ipv6.conf.all.forwarding=1" "hold"
    pipesExec "docker exec $eid\.$node sysctl net.ipv4.conf.all.forwarding=1" "hold"
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
    createNetgraphNode $eid $node
    catch {exec ovs-vsctl add-port $eid.$node $ifname}
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
    destroyNetgraphNode $eid $node
}

proc getNodeNamespace { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set node_id "$eid.$node"
    catch {exec docker inspect -f '{{.State.Pid}}' $node_id} ns
    set ns [string trim $ns "'"]
    return $ns
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
