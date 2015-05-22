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

# XXX - comment procedure
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
    set ilo [lsearch $extifcs lo0]
    set extifcs [lreplace $extifcs $ilo $ilo]

    return $extifcs
}

proc createExperimentContainer {} {}

#****f* linux.tcl/pipesCreate
# NAME
#   pipesCreate -- pipes create
# SYNOPSIS
#   pipesCreate
# FUNCTION
#   Create pipes for parallel execution to the shell.
#****
proc pipesCreate {} {
    global inst_pipes last_inst_pipe

    set ncpus [exec grep -c processor /proc/cpuinfo]
    for {set i 0} {$i < $ncpus} {incr i} {
    set inst_pipes($i) [open "| sh" r+]
    }
    set last_inst_pipe 0
}

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
    set VROOT_OVERLAY $VROOTDIR/$eid/upper/$node
    pipesExec "mkdir -p $VROOT_RUNTIME" "hold"
    pipesExec "mkdir -p $VROOT_OVERLAY" "hold"
}

proc createNodeContainer { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    catch {exec docker create --cap-add=NET_ADMIN --net='none' -h [getNodeName $node] \
        --name $eid.$node phusion/baseimage /sbin/my_init 2> /dev/null}
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
proc createNodePhysIfcs { node } {
    # FIXME: implement in Linux
}

proc createNodeLogIfcs { node } {
    # FIXME: implement in Linux
}

proc configureICMPoptions { node } {
    # FIXME: implement in Linux
}

proc createLinkBetween { lnode1 lnode2 ifname1 ifname2 link } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    # FIXME: max bridgename length is 15
    exec ovs-vsctl add-br $eid.$link
}

proc configureLinkBetween { lnode1 lnode2 ifname1 ifname2 link } {}

proc startIfcsNode { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set node_id "$eid.$node"

    foreach ifc [allIfcList $node] {
        if { $ifc != "lo0" } {
            set mtu [getIfcMTU $node $ifc]
            if {[getIfcOperState $node $ifc] == "up"} {
                set peer_node [logicalPeerByIfc $node $ifc]
                set link [linkByPeers $node $peer_node]
                exec pipework $eid.$link -i $ifc $node_id 0/0
            }
        }
    }
}

proc runNode { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set node_id "$eid.$node"

    set rc [catch {exec docker inspect --format '{{.Created}}' $node_id} status]
    while { [string match 0 $rc] != 1 } {
        set rc [catch {exec docker inspect --format '{{.Created}}' $node_id} status]
    }

    exec docker start $node_id > /dev/null &
    catch {exec docker inspect --format '{{.State.ExitCode}}' $node_id} status
    while { [string match '0' $status] != 1 } {
        exec docker start $node_id > /dev/null &
        catch {exec docker inspect --format '{{.State.ExitCode}}' $node_id} status
    }
}

proc removeExperimentContainer { eid widget } {}

proc removeNodeContainer { eid node } {
    set node_id $eid.$node

    catch "exec docker rm $node_id" "hold"
}

proc killAllNodeProcesses { eid node } {
    set node_id "$eid.$node"

    catch "exec docker stop $node_id"
}

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

    nexec gnome-terminal -e "docker exec -it $node_id $cmd" &
}

#****f* freebsd.tcl/startWiresharkOnNodeIfc
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
    exec jexec $eid.$node tcpdump -s 0 -U -w - -i $ifc 2>/dev/null |\
        wireshark -o "gui.window_title:$ifc@[getNodeName $node] ($eid)" -k -i - &
    }
}

proc destroyVirtNodeIfcs { eid vimages } {}

proc runConfOnNode { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global vroot_unionfs
    global viewcustomid vroot_unionfs

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
    # exec "cat $node_dir/$confFile | docker exec -i $node_id sh -c 'cat > $confFile'"
    # exec docker exec -it $node_id bash -c 'cat > $confFile' < $node_dir/$confFile
    # exec docker exec $node_id $bootcmd $confFile >& $node_dir/out.log &
}

proc destroyLinkBetween { eid lnode1 lnode2 } {
    set lname [linkByPeers $lnode1 $lnode2]
    pipesExec "exec ovs-vsctl del-br $eid.$lname"
}

proc removeNodeIfcIPaddrs { eid node } {
    set node_id "$eid.$node"

    foreach ifc [ifcList $node] {
    foreach ipv4 [getIfcIPv4addr $node $ifc] {
        catch "exec jexec $node_id ifconfig $ifc $ipv4 -alias"
    }
    foreach ipv6 [getIfcIPv6addr $node $ifc] {
        catch "exec jexec $node_id ifconfig $ifc inet6 $ipv6 -alias"
    }
    }
}
