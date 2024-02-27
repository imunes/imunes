#
# Copyright 2004-2013 University of Zagreb.
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

global vroot_unionfs vroot_linprocfs ifc_dad_disable regular_termination \
    devfs_number hostsAutoAssign linkJitterConfiguration ipsecSecrets \
    ipsecConf ipFastForwarding

set linkJitterConfiguration 0
set vroot_unionfs 1
set vroot_linprocfs 0
set ifc_dad_disable 0
set regular_termination 1
set devfs_number 46837
set hostsAutoAssign 0
set ipFastForwarding 0

#****f* exec.tcl/nexec
# NAME
#   nexec -- execute program
# SYNOPSIS
#   set result [nexec $args]
# FUNCTION
#   Executes the string given in args variable. The sting is not executed if
#   IMUNES is running in editor only mode.
# INPUTS
#   * args -- the string that should be executed.
# RESULT
#   * result -- the standard output of the executed string.
#****
proc nexec { args } {
    global editor_only

    if { $editor_only } {
	tk_messageBox -title "Editor only" \
	    -message "Running in editor only mode." \
	    -type ok
	return
    }

    eval exec $args
}

#****f* exec.tcl/genExperimentId
# NAME
#   genExperimentId -- generate experiment ID
# SYNOPSIS
#   set eid [genExperimentId]
# FUNCTION
#   Generates a new random experiment ID that will be used when the experiment
#   is started.
# RESULT
#   * eid -- a new generated experiment ID
#****
proc genExperimentId { } {
    global isOSlinux

    if { $isOSlinux } {
        return i[string range [format %04x [expr {[pid] + [expr { round( rand()*10000 ) }]}]] 0 2]
    } else {
        return i[format %04x [expr {[pid] + [expr { round( rand()*10000 ) }]}]]
    }
}

#****f* exec.tcl/setOperMode
# NAME
#   setOperMode -- set operating mode
# SYNOPSIS
#   setOperMode $mode
# FUNCTION
#   Sets imunes operating mode to the value of the parameter mode. The mode
#   can be set only to edit or exec.
#   When changing the mode to exec all the emulation interfaces are checked
#   (if they are nonexistent the message is displayed, and mode is not
#   changed), all the required buttons are disabled (except the
#   simulation/Terminate button, that is enabled) and procedure deployCfg is
#   called.
#   The mode can not be changed to exec if imunes operates only in editor mode
#   (editor_only variable is set).
#   When changing the mode to edit, all required buttons are enabled (except
#   for simulation/Terminate button that is disabled) and procedure
#   vimageCleanup is called.
# INPUTS
#   * mode -- the new operating mode. Can be edit or exec.
#****
proc setOperMode { mode } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    upvar 0 ::cf::[set ::curcfg]::undolevel undolevel
    upvar 0 ::cf::[set ::curcfg]::redolevel redolevel
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    upvar 0 ::cf::[set ::curcfg]::cfgDeployed cfgDeployed
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global all_modules_list editor_only execMode isOSfreebsd isOSlinux

    if {$mode == "exec" && $node_list == ""} {
	statline "Empty topologies can't be executed."
	.panwin.f1.c config -cursor left_ptr
	return
    }

    if { !$cfgDeployed && $mode == "exec" } {
	if { !$isOSlinux && !$isOSfreebsd } {
	    after idle {.dialog1.msg configure -wraplength 4i}
	    tk_dialog .dialog1 "IMUNES error" \
		"Error: To execute experiment, run IMUNES on FreeBSD or Linux." \
	    info 0 Dismiss
	    return
	}
	catch {exec id -u} uid
	if { $uid != "0" } {
	    after idle {.dialog1.msg configure -wraplength 4i}
	    tk_dialog .dialog1 "IMUNES error" \
		"Error: To execute experiment, run IMUNES with root permissions." \
	    info 0 Dismiss
	    return
	}
	set err [checkSysPrerequisites]
	if { $err != "" } {
	    after idle {.dialog1.msg configure -wraplength 4i}
	    tk_dialog .dialog1 "IMUNES error" \
		"$err" \
		info 0 Dismiss
	    return
	}
	if { $editor_only } {
	    .menubar.experiment entryconfigure "Execute" -state disabled
	    return
	}
	if { [allSnapshotsAvailable] == 0 } {
	    return
	}
	# Verify that links to external interfaces are properly configured
	if { [checkExternalInterfaces] } {
	    return
	}
    }

    foreach b { link link_layer net_layer } {
	if { "$mode" == "exec" } {
	    .panwin.f1.left.$b configure -state disabled
	} else {
	    .panwin.f1.left.$b configure -state normal
	}
    }
    .bottom.oper_mode configure -text "$mode mode"
    setActiveTool select
    #.panwin.f1.left.select configure -state active
    if { "$mode" == "exec" && [exec id -u] == 0} {
	global autorearrange_enabled
	set autorearrange_enabled 0
	.menubar.tools entryconfigure "Auto rearrange all" -state disabled
	.menubar.tools entryconfigure "Auto rearrange selected" -state disabled
	.menubar.experiment entryconfigure "Execute" -state disabled
	.menubar.experiment entryconfigure "Terminate" -state normal
	.menubar.experiment entryconfigure "Restart" -state normal
	.menubar.edit entryconfigure "Undo" -state disabled
	.menubar.edit entryconfigure "Redo" -state disabled
	.menubar.tools entryconfigure "Routing protocol defaults" -state disabled
	.panwin.f1.c bind node <Double-1> "spawnShellExec"
	.panwin.f1.c bind nodelabel <Double-1> "spawnShellExec"
	set oper_mode exec
	wm protocol . WM_DELETE_WINDOW {
	}
	if {!$cfgDeployed} {
	    deployCfg
	    set cfgDeployed true
	    createExperimentFiles $eid
	}
	wm protocol . WM_DELETE_WINDOW {
	    exit
	}
	.bottom.experiment_id configure -text "Experiment ID = $eid"
    } else {
	if {$oper_mode != "edit"} {
	    global regular_termination
	    wm protocol . WM_DELETE_WINDOW {
	    }
	    if { $regular_termination } {
		terminateAllNodes $eid
	    } else {
		vimageCleanup $eid
	    }
	    pipesCreate
	    killExtProcess "socat.*$eid"
	    pipesClose
	    set cfgDeployed false
	    #deleteExperimentFiles $eid
	    wm protocol . WM_DELETE_WINDOW {
		exit
	    }
	    .menubar.tools entryconfigure "Auto rearrange all" -state normal
	    .menubar.tools entryconfigure "Auto rearrange selected" -state normal
	    .menubar.tools entryconfigure "Routing protocol defaults" -state normal
	}
	if { $editor_only } {
	    .menubar.experiment entryconfigure "Execute" -state disabled
 	} else {
	    .menubar.experiment entryconfigure "Execute" -state normal
	}
	.menubar.experiment entryconfigure "Terminate" -state disabled
	.menubar.experiment entryconfigure "Restart" -state disabled
	if { $undolevel > 0 } {
	    .menubar.edit entryconfigure "Undo" -state normal
	} else {
	    .menubar.edit entryconfigure "Undo" -state disabled
	}
	if { $redolevel > $undolevel } {
	    .menubar.edit entryconfigure "Redo" -state normal
	} else {
	    .menubar.edit entryconfigure "Redo" -state disabled
	}
	.panwin.f1.c bind node <Double-1> "nodeConfigGUI .panwin.f1.c {}"
	.panwin.f1.c bind nodelabel <Double-1> "nodeConfigGUI .panwin.f1.c {}"
	set oper_mode edit
	.bottom.experiment_id configure -text ""
    }
    .panwin.f1.c config -cursor left_ptr
}

#****f* exec.tcl/spawnShellExec
# NAME
#   spawnShellExec -- spawn shell in exec mode on double click
# SYNOPSIS
#   spawnShellExec
# FUNCTION
#   This procedure spawns a new shell on a selected and current
#   node.
#****
proc spawnShellExec {} {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set node [lindex [.panwin.f1.c gettags {node && current}] 1]
    if { $node == "" } {
	set node [lindex [.panwin.f1.c gettags {nodelabel && current}] 1]
	if { $node == "" } {
	    return
	}
    }
    if { [[typemodel $node].virtlayer] != "VIMAGE" } {
	nodeConfigGUI .panwin.f1.c $node
    } else {
	set cmd [lindex [existingShells [[typemodel $node].shellcmds] $node] 0]
	if { $cmd == "" } {
	    return
	}
	spawnShell $node $cmd
    }
}

#****f* exec.tcl/fetchNodeConfiguration
# NAME
#   fetchNodeConfiguration -- fetches current node configuration
# SYNOPSIS
#   fetchNodeConfiguration
# FUNCTION
#   This procedure is called when the button3.menu.sett->Fetch Node
#   Configurations button is pressed. It is used to update the selected nodes
#   configurations from the running experiment settings.
#****
proc fetchNodeConfiguration {} {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global isOSfreebsd
    set ip6Set 0
    set ip4Set 0

    foreach node [selectedNodes] {
	set lines [getRunningNodeIfcList $node]
	# XXX - here we parse ifconfig output, maybe require virtual nodes on
	# linux to have ifconfig, or create different parsing procedures for ip
	# and ifconfig that will have the same output
	if ($isOSfreebsd) {
	    foreach line $lines {
		if {[regexp {^([[:alnum:]]+):.*mtu ([^$]+)$} $line \
		     -> ifc mtuvalue]} {
		    setIfcMTU $node $ifc $mtuvalue
		    set ip6Set 0
		    set ip4Set 0
		} elseif {[regexp {^\tether ([^ ]+)} $line -> macaddr]} {
		    setIfcMACaddr $node $ifc $macaddr
		} elseif {[regexp {^\tinet6 (?!fe80:)([^ ]+) prefixlen ([^ ]+)} $line -> ip6addr mask]} {
		    if {$ip6Set == 0} {
			setIfcIPv6addr $node $ifc $ip6addr/$mask
			set ip6Set 1
		    }
		} elseif {[regexp {^\tinet ([^ ]+) netmask ([^ ]+) } $line \
		     -> ip4addr netmask]} {
		    if {$ip4Set == 0} {
			set length [ip::maskToLength $netmask]
			setIfcIPv4addr $node $ifc $ip4addr/$length
			set ip4Set 1
		    }
		}
	    }
	} else {
	    foreach line $lines {
		if {[regexp {^([[:alnum:]]+)} $line -> ifc]} {
		    set ip6Set 0
		    set ip4Set 0
		}
		if {[regexp {^([[:alnum:]]+)\s.*HWaddr ([^$]+)$} $line \
		     -> ifc macaddr]} {
		    setIfcMACaddr $node $ifc $macaddr
		} elseif {[regexp {^\s*inet addr:([^ ]+)\s.*\sMask:([^ ]+)} $line \
		     -> ip4addr netmask]} {
		    if {$ip4Set == 0} {
			set length [ip::maskToLength $netmask]
			setIfcIPv4addr $node $ifc $ip4addr/$length
			set ip4Set 1
		    }
		} elseif {[regexp {^\s*inet6 addr:\s(?!fe80:)([^ ]+)} $line -> ip6addr]} {
		    if {$ip6Set == 0} {
			setIfcIPv6addr $node $ifc $ip6addr
			set ip6Set 1
		    }
		} elseif {[regexp {MTU:([^ ]+)} $line -> mtuvalue]} {
		    setIfcMTU $node $ifc $mtuvalue
		}
	    }
	}
    }
    redrawAll
}

# helper func
proc writeDataToFile { path data } {
    file mkdir [file dirname $path]
    set fileId [open $path w]
    puts $fileId $data
    close $fileId
}

# helper func
proc readDataFromFile { path } {
    set fileId [open $path r]
    set data [string trim [read $fileId]]
    close $fileId

    return $data
}

#****f* exec.tcl/checkExternalInterfaces
# NAME
#   checkExternalInterfaces -- check external interfaces in the topology
# SYNOPSIS
#   checkExternalInterfaces
# FUNCTION
#   Check whether external interfaces are available in the running system.
# RESULT
#   * returns 0 if everything is ok, otherwise it returns 1.
#****
proc checkExternalInterfaces {} {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    global execMode

    set extifcs [getHostIfcList]

    foreach node $node_list {
	if { [nodeType $node] == "rj45" } {
	    # check if the interface exists
	    set name [lindex [split [getNodeName $node] .] 0]
	    set i [lsearch $extifcs $name]
	    if { $i < 0 } {
		set msg "Error: external interface $name non-existant."
		if { $execMode == "batch" } {
		    puts $msg
		} else {
		    after idle {.dialog1.msg configure -wraplength 4i}
			tk_dialog .dialog1 "IMUNES error" $msg \
			info 0 Dismiss
		}
		return 1
	    }
	    if { [getEtherVlanEnabled $node] && [getEtherVlanTag $node] != "" } {
		if { [getHostIfcVlanExists $node $name] } {
		    return 1
		}
	    }
	}
    }
    return 0
}

#****f* editor.tcl/resumeSelectedExperiment
# NAME
#   resumeSelectedExperiment -- resume selected experiment
# SYNOPSIS
#   resumeSelectedExperiment $exp
# FUNCTION
#   Resumes selected experiment.
# INPUTS
#   * exp -- experiment id
#****
proc resumeSelectedExperiment { exp } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global runtimeDir
    if {[info exists eid]} {
	set curr_eid $eid
	if {$curr_eid == $exp} {
	    return
	}
    }
    newProject

    upvar 0 ::cf::[set ::curcfg]::currentFile currentFile
    upvar 0 ::cf::[set ::curcfg]::cfgDeployed cfgDeployed
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set currentFile [getExperimentConfigurationFromFile $exp]
    openFile

    set eid $exp
    set cfgDeployed true
    setOperMode exec
}

#****f* exec.tcl/createExperimentFiles
# NAME
#   createExperimentFiles -- create experiment files
# SYNOPSIS
#   createExperimentFiles $eid
# FUNCTION
#   Creates all needed files to run the specified experiment.
# INPUTS
#   * eid -- experiment id
#****
proc createExperimentFiles { eid } {
    upvar 0 ::cf::[set ::curcfg]::currentFile currentFile
    global currentFileBatch execMode runtimeDir
    set basedir "$runtimeDir/$eid"
    file mkdir $basedir
    
    writeDataToFile $basedir/timestamp [clock format [clock seconds]]
    
    dumpLinksToFile $basedir/links

    if { $execMode == "interactive" } {
	if { $currentFile != "" } {
	    writeDataToFile $basedir/name [file tail $currentFile]
	}
    } else {
	if { $currentFileBatch != "" } {
	    writeDataToFile $basedir/name [file tail $currentFileBatch]
	}
    }

    if { $execMode == "interactive" } {
	saveRunningConfigurationInteractive $eid
	createExperimentScreenshot $eid
    } else {
	saveRunningConfigurationBatch $eid
    }
}

#****f* exec.tcl/dumpLinksToFile
# NAME
#   dumpLinksToFile -- dump formatted link list to file
# SYNOPSIS
#   dumpLinksToFile $path
# FUNCTION
#   Saves the list of all links to $path.
# INPUTS
#   * path -- absolute path of the file
#****
proc dumpLinksToFile { path } {
    upvar 0 ::cf::[set ::curcfg]::link_list link_list

    set data ""
    set linkDelim ":"
    set skipLinks ""

    foreach link $link_list {
	if { $link in $skipLinks } {
	    continue
	}
	set lnode1 [lindex [linkPeers $link] 0]
	set lnode2 [lindex [linkPeers $link] 1]
	set ifname1 [ifcByPeer $lnode1 $lnode2]
	set ifname2 [ifcByPeer $lnode2 $lnode1]

	if { [getLinkMirror $link] != "" } {
	    set mirror_link [getLinkMirror $link]
	    lappend skipLinks $mirror_link

	    set p_lnode2 $lnode2
	    set lnode2 [lindex [linkPeers $mirror_link] 0]
	    set ifname2 [ifcByPeer $lnode2 [getNodeMirror $p_lnode2]]
	}

	set name1 [getNodeName $lnode1]
	set name2 [getNodeName $lnode2]

	set linkname "$name1$linkDelim$name2"

	set line "$link {$lnode1-$lnode2 {{$lnode1 $ifname1} {$lnode2 $ifname2}} $linkname}\n"
	set data "$data$line"
    }

    set data [string trimright $data "\n"]

    writeDataToFile $path $data
}

#****f* exec.tcl/saveRunningConfigurationInteractive
# NAME
#   saveRunningConfigurationInteractive -- save running configuration in
#       interactive
# SYNOPSIS
#   saveRunningConfigurationInteractive $eid
# FUNCTION
#   Saves running configuration of the specified experiment if running in
#   interactive mode.
# INPUTS
#   * eid -- experiment id
#****
proc saveRunningConfigurationInteractive { eid } {
    global runtimeDir
    set fileName "$runtimeDir/$eid/config.imn"
    set fileId [open $fileName w]
    dumpCfg file $fileId
    close $fileId
}

#****f* exec.tcl/saveRunningConfigurationBatch
# NAME
#   saveRunningConfigurationBatch -- save running configuration in batch
# SYNOPSIS
#   saveRunningConfigurationBatch $eid
# FUNCTION
#   Saves running configuration of the specified experiment if running in
#   batch mode.
# INPUTS
#   * eid -- experiment id
#****
proc saveRunningConfigurationBatch { eid } {
    global currentFileBatch runtimeDir
    set fileName "$runtimeDir/$eid/config.imn"
    exec cp $currentFileBatch $fileName
}

#****f* exec.tcl/createExperimentScreenshot
# NAME
#   createExperimentScreenshot -- create experiment screenshot
# SYNOPSIS
#   createExperimentScreenshot $eid
# FUNCTION
#   Creates a screenshot for the specified experiment and saves it as an image #   in png format.
# INPUTS
#   * eid -- experiment id
#****
proc createExperimentScreenshot { eid } {
    global runtimeDir
    set fileName "$runtimeDir/$eid/screenshot.png"
    set error [catch {eval image create photo screenshot -format window \
	-data .panwin.f1.c} err]
    if { ($error == 0) } {
	screenshot write $fileName -format png
	catch {exec convert $fileName -resize 300x210\! $fileName\2}
	catch {exec mv $fileName\2 $fileName}
    }
}

#****f* exec.tcl/deleteExperimentFiles
# NAME
#   deleteExperimentFiles -- delete experiment files
# SYNOPSIS
#   deleteExperimentFiles $eid
# FUNCTION
#   Deletes experiment files for the specified experiment.
# INPUTS
#   * eid -- experiment id
#****
proc deleteExperimentFiles { eid } {
    global runtimeDir
    set folderName "$runtimeDir/$eid"
    file delete -force $folderName
}

#****f* exec.tcl/createExperimentFilesFromBatch
# NAME
#   createExperimentFilesFromBatch -- create experiment files from batch
# SYNOPSIS
#   createExperimentFilesFromBatch
# FUNCTION
#   Creates all needed files to run the experiments in batch mode.
#****
proc createExperimentFilesFromBatch {} {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    createExperimentFiles $eid
}

#****f* exec.tcl/fetchExperimentFolders
# NAME
#   fetchExperimentFolders -- fetch experiment folders
# SYNOPSIS
#   fetchExperimentFolders
# FUNCTION
#   Returns folders of all running experiments as a list.
# RESULT
#   * exp_list -- experiment folder list
#****
proc fetchExperimentFolders {} {
    global runtimeDir
    set exp_list ""
    set exp_files [glob -nocomplain -directory $runtimeDir -type d *]
    if {$exp_files != ""} {
	foreach file $exp_files {
	    lappend exp_list [file tail $file]
	}
    }
    return $exp_list
}

#****f* exec.tcl/getResumableExperiments
# NAME
#   getResumableExperiments -- get resumable experiments
# SYNOPSIS
#   getResumableExperiments
# FUNCTION
#   Returns IDs of all experiments which can be resumed as a list.
# RESULT
#   * exp_list -- experiment id list
#****
proc getResumableExperiments {} {
    set exp_list ""
    set exp_folders [fetchExperimentFolders]
    foreach exp [fetchRunningExperiments] {
	if {$exp in $exp_folders} {
	    lappend exp_list $exp
	}
    }
    return $exp_list
}

#****f* exec.tcl/getExperimentTimestampFromFile
# NAME
#   getExperimentTimestampFromFile -- get experiment timestamp from file
# SYNOPSIS
#   getExperimentTimestampFromFile $eid
# FUNCTION
#   Returns the specified experiment timestamp from file.
# INPUTS
#   * eid -- experiment id
# RESULT
#   * timestamp -- experiment timestamp
#****
proc getExperimentTimestampFromFile { eid } {
    global runtimeDir
    set pathToFile "$runtimeDir/$eid/timestamp"
    set timestamp ""
    if {[file exists $pathToFile]} {
	set fileId [open $pathToFile r]
	set timestamp [string trim [read $fileId]]
	close $fileId
    }
    return $timestamp
}

#****f* exec.tcl/getExperimentNameFromFile
# NAME
#   getExperimentNameFromFile -- get experiment name from file
# SYNOPSIS
#   getExperimentNameFromFile $eid
# FUNCTION
#   Returns the specified experiment name from file.
# INPUTS
#   * eid -- experiment id
# RESULT
#   * name -- experiment name
#****
proc getExperimentNameFromFile { eid } {
    global runtimeDir
    set pathToFile "$runtimeDir/$eid/name"
    set name ""
    if {[file exists $pathToFile]} {
	set name [readDataFromFile $pathToFile]
    }
    return $name
}

#****f* exec.tcl/getExperimentConfigurationFromFile
# NAME
#   getExperimentConfigurationFromFile -- get experiment configuration from
#       file
# SYNOPSIS
#   getExperimentConfigurationFromFile $eid
# FUNCTION
#   Returns the specified experiment configuration from file.
# INPUTS
#   * eid -- experiment id
# RESULT
#   * file -- experiment configuration
#****
proc getExperimentConfigurationFromFile { eid } {
    global runtimeDir
    set pathToFile "$runtimeDir/$eid/config.imn"
    set file ""
    if {[file exists $pathToFile]} {
	set file $pathToFile
    }
    return $file
}

#****f* exec.tcl/statline
# NAME
#   statline -- status line
# SYNOPSIS
#   statline $line
# FUNCTION
#   Sets the string of the status line. If the execution mode is set to batch
#   the line is just printed on the standard output.
# INPUTS
#   * line -- line to be displayed
#****
proc statline { line } {
    global execMode

    if {$execMode == "batch"} {
	puts $line
	flush stdout
    } else {
	.bottom.textbox config -text "$line"
	animateCursor
    }
}

#****f* exec.tcl/displayBatchProgress
# NAME
#   displayBatchProgress - display progress percentage in batch mode
# SYNOPSIS
#   displayBatchProgress $progress $total
# FUNCTION
#   Updates the progress percentage when starting an experiment in batch mode.
# INPUTS
#   * progress -- current step
#   * total -- total number of steps
#****
proc displayBatchProgress { prgs tot } {
    global execMode
    if {$execMode == "batch"} {
	puts -nonewline "\r                                                "
	puts -nonewline "\r> $prgs/$tot"
	flush stdout
    }
}

#****f* exec.tcl/l3node.instantiate
# NAME
#   l3node.instantiate -- layer 3 node instantiate
# SYNOPSIS
#   l3node.instantiate $eid $node
# FUNCTION
#   Instantiates the specified node. This means that it creates a new vimage
#   node, all the required interfaces (for serial interface a new netgraph
#   interface of type iface; for ethernet of type eiface, using createIfc
#   procedure) including loopback interface, and sets kernel variables.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc l3node.instantiate { eid node } {
    prepareFilesystemForNode $node
    createNodeContainer $node
}

proc l3node.configureInitNet { eid node } {
    createNodeLogIfcs $node
    configureICMPoptions $node
}

#****f* exec.tcl/l3node.start
# NAME
#   l3node.start -- layer 3 node start
# SYNOPSIS
#   l3node.start $eid $node
# FUNCTION
#   Starts a new layer 3 node (pc, host or router). The node can be started if
#   it is instantiated.
#   Simulates the booting proces of a node, starts all the services and
#   assignes the ip addresses to the interfaces.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc l3node.start { eid node } {
    startIfcsNode $node
    runConfOnNode $node
}

#****f* exec.tcl/l3node.shutdown
# NAME
#   l3node.shutdown -- layer 3 node shutdown
# SYNOPSIS
#   l3node.shutdown $eid $node
# FUNCTION
#   Shutdowns a layer 3 node (pc, host or router).
#   Simulates the shutdown proces of a node, kills all the services and
#   deletes ip addresses of all interfaces.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc l3node.shutdown { eid node } {
    killExtProcess "wireshark.*[getNodeName $node].*\\($eid\\)"
    killAllNodeProcesses $eid $node
    removeNodeIfcIPaddrs $eid $node
}

#****f* exec.tcl/l3node.destroy
# NAME
#   l3node.destroy -- layer 3 node destroy
# SYNOPSIS
#   l3node.destroy $eid $node
# FUNCTION
#   Destroys a layer 3 node (pc, host or router).
#   Destroys all the interfaces of the node by sending a shutdown message to
#   netgraph nodes and on the end destroys the vimage itself.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc l3node.destroy { eid node } {
    destroyNodeVirtIfcs $eid $node
    removeNodeContainer $eid $node
    destroyNodeNamespace $eid $node
    removeNodeFS $eid $node
}

#****f* exec.tcl/deployCfg
# NAME
#   deployCfg -- deploy working configuration
# SYNOPSIS
#   deployCfg
# FUNCTION
#   Deploys a current working configuration. It creates all the nodes and link
#   as defined in configuration file of in GUI of imunes. Before deploying new
#   configuration the old one is removed (vimageCleanup procedure).
#****
proc deployCfg {} {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    upvar 0 ::cf::[set ::curcfg]::link_list link_list
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global progressbarCount execMode

    set progressbarCount 0
    set nodeCount [llength $node_list]
    set linkCount [llength $link_list]

    set t_start [clock milliseconds]

    try {
	prepareSystem
    } on error err {
	statline "ERROR in 'prepareSystem': '$err'"
	if { $execMode != "batch" } {
	    after idle {.dialog1.msg configure -wraplength 4i}
	    tk_dialog .dialog1 "IMUNES error" \
		"$err \nTerminate the experiment and report the bug!" info 0 Dismiss
	}
	return
    }

    statline "Preparing for initialization..."
    set l2nodes {}
    set l3nodes {}
    set allNodes {}
    set pseudoNodesCount 0
    foreach node $node_list {
	if { [nodeType $node] != "pseudo" } {
	    if { [[typemodel $node].virtlayer] != "VIMAGE" } {
		lappend l2nodes $node
	    } else {
		lappend l3nodes $node
	    }
	} else {
	    incr pseudoNodesCount
	}
    }
    set l2nodeCount [llength $l2nodes]
    set l3nodeCount [llength $l3nodes]
    set allNodes [concat $l2nodes $l3nodes]
    set allNodeCount [llength $allNodes]
    incr linkCount [expr -$pseudoNodesCount/2]
    set maxProgressbasCount [expr {4*$allNodeCount + 1*$l2nodeCount + 6*$l3nodeCount + 2*$linkCount}]

    set w ""
    if {$execMode != "batch"} {
	set w .startup
	catch {destroy $w}
	toplevel $w -takefocus 1
	wm transient $w .
	wm title $w "Starting experiment $eid..."
	message $w.msg -justify left -aspect 1200 \
	    -text "Starting up virtual nodes and links."
	pack $w.msg
	update
	ttk::progressbar $w.p -orient horizontal -length 250 \
	    -mode determinate -maximum $maxProgressbasCount -value $progressbarCount
	pack $w.p
	update

	grab $w
	wm protocol $w WM_DELETE_WINDOW {
	}
    }

    try {
	statline "Instantiating L2 nodes..."
	pipesCreate
	instantiateNodes $l2nodes $l2nodeCount $w
	statline "Waiting for $l2nodeCount L2 node(s) to start..."
	pipesClose

	statline "Instantiating L3 nodes..."
	pipesCreate
	instantiateNodes $l3nodes $l3nodeCount $w
	statline "Waiting for $l3nodeCount L3 node(s) to start..."
	waitForInstantiateNodes $l3nodes $l3nodeCount $w
	pipesClose

	statline "Creating namespaces for L3 nodes..."
	pipesCreate
	createNodeNamespaces $l3nodes $l3nodeCount $w
	statline "Waiting on namespaces for $l3nodeCount node(s)..."
	waitForNamespaces $l3nodes $l3nodeCount $w
	pipesClose

	statline "Starting initial configuration on L3 nodes..."
	pipesCreate
	initConfigurationNodes $l3nodes $l3nodeCount $w
	statline "Waiting for initial configuration on $l3nodeCount L3 node(s)..."
	waitForInitConf $l3nodes $l3nodeCount $w
	pipesClose

	#statline "Copying host files to $l3nodeCount L3 node(s)..."
	#copyFilesToNodes $l3nodes $l3nodeCount $w

	statline "Starting services for NODEINST hook..."
	services start "NODEINST"

	statline "Creating interfaces on nodes..."
	pipesCreate
	createNodesInterfaces $allNodes $allNodeCount $w
	statline "Waiting for interfaces on $allNodeCount node(s) to be created..."
	pipesClose

	statline "Creating links..."
	pipesCreate
	createLinks $link_list $linkCount $w
	statline "Waiting for $linkCount link(s) to be created..."
	pipesClose

	pipesCreate
	statline "Configuring links..."
	configureLinks $link_list $linkCount $w
	statline "Waiting for $linkCount link(s) to be configured..."
	pipesClose

	statline "Starting services for LINKINST hook..."
	services start "LINKINST"

	pipesCreate
	statline "Configuring node(s)..."
	executeConfNodes $allNodes $allNodeCount $w
	statline "Waiting for configuration on $l3nodeCount node(s)..."
	waitForConfStart $l3nodes $l3nodeCount $w
	pipesClose

	statline "Starting services for NODECONF hook..."
	services start "NODECONF"
    } on error err {
	finishExecuting 0 "$err" $w
	return
    }

    statline "Checking for errors on $allNodeCount node(s)..."
    checkForErrors $allNodes $allNodeCount $w

    finishExecuting 1 "" $w

    statline "Network topology instantiated in [expr ([clock milliseconds] - $t_start)/1000.0] seconds ($allNodeCount nodes and $linkCount links)."

    if { $execMode == "batch" } {
	puts "Experiment ID = $eid"
    }
}

proc prepareSystem {} {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global eid_base
    global execMode

    set running_eids [getResumableExperiments]
    if {$execMode != "batch"} {
	set eid ${eid_base}[string range $::curcfg 1 end]
	while { $eid in $running_eids } {
	    set eid_base [genExperimentId]
	    set eid ${eid_base}[string range $::curcfg 1 end]
	}
    } else {
	set eid $eid_base
	while { $eid in $running_eids } {
	    puts -nonewline "Experiment ID $eid_base already in use, trying "
	    set eid [genExperimentId]
	    puts "$eid."
	}
    }

    loadKernelModules
    prepareVirtualFS
    prepareDevfs
    createExperimentContainer
}

proc instantiateNodes { nodes nodeCount w } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global progressbarCount execMode

    set batchStep 0
    foreach node $nodes {
	displayBatchProgress $batchStep $nodeCount

	try {
	    [typemodel $node].instantiate $eid $node
	} on error err {
	    return -code error "Error in '[typemodel $node].instantiate $eid $node': $err"
	}
	pipesExec ""

	incr batchStep
	incr progressbarCount

	if {$execMode != "batch"} {
	    statline "Instantiating node [getNodeName $node]"
	    $w.p configure -value $progressbarCount
	    update
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if {$execMode == "batch"} {
	    statline ""
	}
    }
}

proc waitForInstantiateNodes { nodes nodeCount w } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global progressbarCount execMode

    set batchStep 0
    set nodes_left $nodes
    while { [llength $nodes_left] > 0 } {
	displayBatchProgress $batchStep $nodeCount
	foreach node $nodes_left {
	    if { ! [isNodeStarted $node] } {
		continue
	    }

	    incr batchStep
	    incr progressbarCount

	    set name [getNodeName $node]
	    if {$execMode != "batch"} {
		statline "Node $name started"
		$w.p configure -value $progressbarCount
		update
	    }
	    displayBatchProgress $batchStep $nodeCount

	    set nodes_left [removeFromList $nodes_left $node]
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if {$execMode == "batch"} {
	    statline ""
	}
    }
}

proc createNodeNamespaces { nodes nodeCount w } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global progressbarCount execMode

    set batchStep 0
    foreach node $nodes {
	displayBatchProgress $batchStep $nodeCount

	try {
	    createNodeNamespace $node
	} on error err {
	    return -code error "Error in 'createNodeNamespace $node': $err"
	}
	pipesExec ""

	incr batchStep
	incr progressbarCount

	if {$execMode != "batch"} {
	    statline "Creating namespace for [getNodeName $node]"
	    $w.p configure -value $progressbarCount
	    update
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if {$execMode == "batch"} {
	    statline ""
	}
    }
}

proc waitForNamespaces { nodes nodeCount w } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global progressbarCount execMode

    set batchStep 0
    set nodes_left $nodes
    while { [llength $nodes_left] > 0 } {
	displayBatchProgress $batchStep $nodeCount
	foreach node $nodes_left {
	    if { ! [isNodeNamespaceCreated $node] } {
		continue
	    }

	    incr batchStep
	    incr progressbarCount

	    set name [getNodeName $node]
	    if {$execMode != "batch"} {
		statline "Namespace for $name created"
		$w.p configure -value $progressbarCount
		update
	    }
	    displayBatchProgress $batchStep $nodeCount

	    set nodes_left [removeFromList $nodes_left $node]
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if {$execMode == "batch"} {
	    statline ""
	}
    }
}

proc initConfigurationNodes { nodes nodeCount w } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global progressbarCount execMode

    set batchStep 0
    foreach node $nodes {
	displayBatchProgress $batchStep $nodeCount

	try {
	    [typemodel $node].configureInitNet $eid $node
	} on error err {
	    return -code error "Error in '[typemodel $node].configureInitNet $eid $node': $err"
	}
	pipesExec ""

	incr batchStep
	incr progressbarCount

	if {$execMode != "batch"} {
	    statline "Starting initial configuration on [getNodeName $node]"
	    $w.p configure -value $progressbarCount
	    update
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if {$execMode == "batch"} {
	    statline ""
	}
    }
}

proc waitForInitConf { nodes nodeCount w } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global progressbarCount execMode

    set batchStep 0
    set nodes_left $nodes
    while { [llength $nodes_left] > 0 } {
	displayBatchProgress $batchStep $nodeCount
	foreach node $nodes_left {
	    if { ! [isNodeInitNet $node] } {
		continue
	    }

	    incr batchStep
	    incr progressbarCount

	    set name [getNodeName $node]
	    if {$execMode != "batch"} {
		statline "Initial networking on $name configured"
		$w.p configure -value $progressbarCount
		update
	    }
	    displayBatchProgress $batchStep $nodeCount

	    set nodes_left [removeFromList $nodes_left $node]
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if {$execMode == "batch"} {
	    statline ""
	}
    }
}

proc copyFilesToNodes { nodes nodeCount w } {}

proc createNodesInterfaces { nodes nodeCount w } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global progressbarCount execMode

    set batchStep 0
    foreach node $nodes {
	displayBatchProgress $batchStep $nodeCount

	try {
	    createNodePhysIfcs $node
	} on error err {
	    return -code error "Error in 'createNodePhysIfcs $node': $err"
	}
	pipesExec ""

	incr batchStep
	incr progressbarCount

	if {$execMode != "batch"} {
	    statline "Creating physical ifcs on node [getNodeName $node]"
	    $w.p configure -value $progressbarCount
	    update
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if {$execMode == "batch"} {
	    statline ""
	}
    }
}

proc createLinks { links linkCount w } {
    global progressbarCount execMode

    set batchStep 0
    for {set pending_links $links} {$pending_links != ""} {} {
	set link [lindex $pending_links 0]
	set i [lsearch -exact $pending_links $link]
	set pending_links [lreplace $pending_links $i $i]

	set lnode1 [lindex [linkPeers $link] 0]
	set lnode2 [lindex [linkPeers $link] 1]
	set ifname1 [ifcByPeer $lnode1 $lnode2]
	set ifname2 [ifcByPeer $lnode2 $lnode1]

	set msg "Creating link $link"
	set mirror_link [getLinkMirror $link]
	if { $mirror_link != "" } {
	    set i [lsearch -exact $pending_links $mirror_link]
	    set pending_links [lreplace $pending_links $i $i]

	    set msg "Creating link $link/$mirror_link"

	    set p_lnode2 $lnode2
	    set lnode2 [lindex [linkPeers $mirror_link] 0]
	    set ifname2 [ifcByPeer $lnode2 [getNodeMirror $p_lnode2]]
	}

	displayBatchProgress $batchStep $linkCount

	try {
	    createLinkBetween $lnode1 $lnode2 $ifname1 $ifname2 $link
	} on error err {
	    return -code error "Error in 'createLinkBetween $lnode1 $lnode2 $ifname1 $ifname2 $link': $err"
	}

	incr batchStep
	incr progressbarCount

	if {$execMode != "batch"} {
	    statline $msg
	    $w.p configure -value $progressbarCount
	    update
	}
    }

    pipesExec ""

    if { $linkCount > 0 } {
	displayBatchProgress $batchStep $linkCount
	if {$execMode == "batch"} {
	    statline ""
	}
    }
}

proc configureLinks { links linkCount w } {
    global progressbarCount execMode

    set batchStep 0
    for {set pending_links $links} {$pending_links != ""} {} {
	set link [lindex $pending_links 0]
	set i [lsearch -exact $pending_links $link]
	set pending_links [lreplace $pending_links $i $i]

	set lnode1 [lindex [linkPeers $link] 0]
	set lnode2 [lindex [linkPeers $link] 1]
	set ifname1 [ifcByPeer $lnode1 $lnode2]
	set ifname2 [ifcByPeer $lnode2 $lnode1]

	set msg "Configuring link $link"
	if { [getLinkMirror $link] != "" } {
	    set mirror_link [getLinkMirror $link]
	    set i [lsearch -exact $pending_links $mirror_link]
	    set pending_links [lreplace $pending_links $i $i]

	    set msg "Configuring link $link/$mirror_link"

	    set p_lnode2 $lnode2
	    set lnode2 [lindex [linkPeers $mirror_link] 0]
	    set ifname2 [ifcByPeer $lnode2 [getNodeMirror $p_lnode2]]
	}

	displayBatchProgress $batchStep $linkCount

	try {
	    configureLinkBetween $lnode1 $lnode2 $ifname1 $ifname2 $link
	} on error err {
	    return -code error "Error in 'configureLinkBetween $lnode1 $lnode2 $ifname1 $ifname2 $link': $err"
	}

	incr batchStep
	incr progressbarCount

	if {$execMode != "batch"} {
	    statline $msg
	    $w.p configure -value $progressbarCount
	    update
	}
    }

    pipesExec ""

    if { $linkCount > 0 } {
	displayBatchProgress $batchStep $linkCount
	if {$execMode == "batch"} {
	    statline ""
	}
    }
}

proc executeConfNodes { nodes nodeCount w } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global progressbarCount execMode

    set batchStep 0
    set subnet_gws {}
    set nodes_l2data [dict create]
    foreach node $nodes {
	upvar 0 ::cf::[set ::curcfg]::$node $node

	displayBatchProgress $batchStep $nodeCount

	if { [getAutoDefaultRoutesStatus $node] == "enabled" } {
	    lassign [getDefaultGateways $node $subnet_gws $nodes_l2data] my_gws subnet_gws nodes_l2data
	    lassign [getDefaultRoutesConfig $node $my_gws] all_routes4 all_routes6

	    setDefaultIPv4routes $node $all_routes4
	    setDefaultIPv6routes $node $all_routes6
	}

	if {[info procs [typemodel $node].start] != ""} {
	    try {
		[typemodel $node].start $eid $node
	    } on error err {
		return -code error "Error in '[typemodel $node].start $eid $node': $err"
	    }
	}
	pipesExec ""

	incr batchStep
	incr progressbarCount

	if {$execMode != "batch"} {
	    $w.p configure -value $progressbarCount
	    statline "Starting configuration on node [getNodeName $node]"
	    update
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if {$execMode == "batch"} {
	    statline ""
	}
    }
}

proc waitForConfStart { nodes nodeCount w } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global progressbarCount execMode

    set batchStep 0
    set nodes_left $nodes
    while { [llength $nodes_left] > 0 } {
	displayBatchProgress $batchStep $nodeCount
	foreach node $nodes_left {
	    if { ! [isNodeConfigured $node] } {
		continue
	    }

	    incr batchStep
	    incr progressbarCount

	    set name [getNodeName $node]
	    if {$execMode != "batch"} {
		statline "Node $name configured"
		$w.p configure -value $progressbarCount
		update
	    }
	    displayBatchProgress $batchStep $nodeCount

	    set nodes_left [removeFromList $nodes_left $node]
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if {$execMode == "batch"} {
	    statline ""
	}
    }
}


proc finishExecuting { status msg w } {
    global progressbarCount execMode

    catch {pipesClose}
    if {$execMode == "batch"} {
	puts $msg
    } else {
	catch {destroy $w}
	set progressbarCount 0
	if { ! $status } {
	    after idle {.dialog1.msg configure -wraplength 4i}
	    tk_dialog .dialog1 "IMUNES error" \
		"$msg \nTerminate the experiment and report the bug!" info 0 Dismiss
	}
    }
}

proc checkForErrors { nodes nodeCount w } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global progressbarCount execMode

    set batchStep 0
    set err_nodes ""
    foreach node $nodes {
	set msg "no error"
	if { [isNodeError $node] } {
	    set msg "error found"
	    append err_nodes "[getNodeName $node] ($node), "
	}

	incr batchStep
	incr progressbarCount

	set name [getNodeName $node]
	if {$execMode != "batch"} {
	    statline "Node $name checked - $msg"
	    $w.p configure -value $progressbarCount
	    update
	}
	displayBatchProgress $batchStep $nodeCount
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if {$execMode == "batch"} {
	    statline ""
	}
    }

    if { $err_nodes != "" } {
	set err_nodes [string trimright $err_nodes ", "]
	set msg "Issues encountered while configuring nodes:\n$err_nodes\nCheck their /err.log, /out.log and /boot.conf (/custom.conf) files." \

	if { $execMode != "batch" } {
	    after idle {.dialog1.msg configure -wraplength 4i}
	    tk_dialog .dialog1 "IMUNES warning" \
		"$msg" \
		info 0 Dismiss
	} else {
	    puts "\nIMUNES warning - $msg\n"
	}
    }
}

proc checkTerminate {} {}

proc terminateL2L3Nodes { eid nodes nodeCount w } {
    global progressbarCount execMode

    set batchStep 0
    foreach node $nodes {
	displayBatchProgress $batchStep $nodeCount

	if { [info procs [typemodel $node].shutdown] != "" } {
	    try {
		[typemodel $node].shutdown $eid $node
	    } on error err {
		return -code error "Error in '[typemodel $node].shutdown $eid $node': $err"
	    }
	}
	pipesExec ""

	incr batchStep
	incr progressbarCount -1

	if {$execMode != "batch"} {
	    statline "Shutting down node [getNodeName $node]"
	    $w.p configure -value $progressbarCount
	    update
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if {$execMode == "batch"} {
	    statline ""
	}
    }
}

proc releaseExternalIfcs { eid extifcs extifcsCount w } {
    global progressbarCount execMode

    set batchStep 0
    foreach node $extifcs {
	displayBatchProgress $batchStep $extifcsCount

	try {
	    [typemodel $node].destroy $eid $node
	} on error err {
	    return -code error "Error in '[typemodel $node].destroy $eid $node': $err"
	}
	pipesExec ""

	incr batchStep
	incr progressbarCount -1

	if {$execMode != "batch"} {
	    statline "Destroying external connection [getNodeName $node]"
	    $w.p configure -value $progressbarCount
	    update
	}
    }

    if { $extifcsCount > 0 } {
	displayBatchProgress $batchStep $extifcsCount
	if {$execMode == "batch"} {
	    statline ""
	}
    }
}

proc destroyLinks { eid links linkCount w } {
    global progressbarCount execMode

    set batchStep 0
    set skipLinks ""
    foreach link $links {
	displayBatchProgress $batchStep $linkCount

	if { $link in $skipLinks } {
	    continue
	}

	set lnode1 [lindex [linkPeers $link] 0]
	set lnode2 [lindex [linkPeers $link] 1]

	set msg "Destroying link $link"
	set mirror_link [getLinkMirror $link]
	if { $mirror_link != "" } {
	    lappend skipLinks $mirror_link

	    set msg "Destroying link $link/$mirror_link"

	    set lnode2 [lindex [linkPeers $mirror_link] 0]
	}

	try {
	    destroyLinkBetween $eid $lnode1 $lnode2 $link
	} on error err {
	    return -code error "Error in 'destroyLinkBetween $eid $lnode1 $lnode2 $link': $err"
	}

	incr batchStep
	incr progressbarCount -1

	if {$execMode != "batch"} {
	    statline $msg
	    $w.p configure -value $progressbarCount
	    update
	}
    }
    pipesExec ""

    if { $linkCount > 0 } {
	displayBatchProgress $batchStep $linkCount
	if {$execMode == "batch"} {
	    statline ""
	}
    }
}

proc destroyL2Nodes { eid nodes nodeCount w } {
    global progressbarCount execMode

    set batchStep 0
    foreach node $nodes {
	displayBatchProgress $batchStep $nodeCount

	try {
	    [typemodel $node].destroy $eid $node
	} on error err {
	    return -code error "Error in '[typemodel $node].destroy $eid $node': $err"
	}

	incr batchStep
	incr progressbarCount -1

	if {$execMode != "batch"} {
	    statline "Destroying L2 node [getNodeName $node]"
	    $w.p configure -value $progressbarCount
	    update
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if {$execMode == "batch"} {
	    statline ""
	}
    }
}

proc destroyL3Nodes { eid nodes nodeCount w } {
    global progressbarCount execMode

    set batchStep 0
    foreach node $nodes {
	displayBatchProgress $batchStep $nodeCount

	try {
	    [typemodel $node].destroy $eid $node
	} on error err {
	    return -code error "Error in '[typemodel $node].destroy $eid $node': $err"
	}
	pipesExec ""

	incr batchStep
	incr progressbarCount -1

	if {$execMode != "batch"} {
	    statline "Destroying L3 node [getNodeName $node]"
	    $w.p configure -value $progressbarCount
	    update
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if {$execMode == "batch"} {
	    statline ""
	}
    }
}

proc finishTerminating { status msg w } {
    global progressbarCount execMode

    catch {pipesClose}
    if {$execMode == "batch"} {
	puts $msg
    } else {
	catch {destroy $w}
	set progressbarCount 0
	if { ! $status } {
	    after idle {.dialog1.msg configure -wraplength 4i}
	    tk_dialog .dialog1 "IMUNES error" \
		"$msg \nCleanup the experiment and report the bug!" info 0 Dismiss
	}
    }
}

#****f* exec.tcl/terminateAllNodes
# NAME
#   terminateAllNodes -- shutdown and destroy all nodes in experiment
# SYNOPSIS
#   terminateAllNodes
# FUNCTION
#
#****
proc terminateAllNodes { eid } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    upvar 0 ::cf::[set ::curcfg]::link_list link_list
    global progressbarCount execMode

    set nodeCount [llength $node_list]
    set linkCount [llength $link_list]

    set t_start [clock milliseconds]

    try {
	checkTerminate
    } on error err {
	statline "ERROR in 'checkTerminate': '$err'"
	if { $execMode != "batch" } {
	    after idle {.dialog1.msg configure -wraplength 4i}
	    tk_dialog .dialog1 "IMUNES error" \
		"$err \nCleanup the experiment and report the bug!" info 0 Dismiss
	}
	return
    }

    statline "Preparing for termination..."
    set extifcs {}
    set l2nodes {}
    set l3nodes {}
    set allNodes {}
    set pseudoNodesCount 0
    foreach node $node_list {
	if { [nodeType $node] != "pseudo" } {
	    if { [[typemodel $node].virtlayer] == "NETGRAPH" } {
		if { [typemodel $node] == "rj45" } {
		    lappend extifcs $node
		} elseif { [typemodel $node] == "extnat" } {
		    lappend l3nodes $node
		} else {
		    lappend l2nodes $node
		}
	    } else {
		lappend l3nodes $node
	    }
	} else {
	    incr pseudoNodesCount
	}
    }
    set l2nodeCount [llength $l2nodes]
    set l3nodeCount [llength $l3nodes]
    set allNodes [concat $l2nodes $l3nodes]
    set allNodeCount [llength $allNodes]
    set extifcsCount [llength $extifcs]
    incr linkCount [expr -$pseudoNodesCount/2]
    set maxProgressbasCount [expr {1*$allNodeCount + $extifcsCount + $linkCount + $l2nodeCount + 3*$l3nodeCount}]
    set progressbarCount $maxProgressbasCount

    set w ""
    if {$execMode != "batch"} {
	set w .startup
	catch {destroy $w}
	toplevel $w -takefocus 1
	wm transient $w .
	wm title $w "Terminating experiment $eid..."
	message $w.msg -justify left -aspect 1200 \
	    -text "Deleting virtual nodes and links."
	pack $w.msg
	update
	ttk::progressbar $w.p -orient horizontal -length 250 \
	    -mode determinate -maximum $maxProgressbasCount -value $progressbarCount
	pack $w.p
	update

	grab $w
	wm protocol $w WM_DELETE_WINDOW {
	}
    }

    try {
	statline "Stopping services for NODESTOP hook..."
	services stop "NODESTOP"

	statline "Stopping all nodes..."
	pipesCreate
	terminateL2L3Nodes $eid $allNodes $allNodeCount $w
	statline "Waiting for processes on $allNodeCount node(s) to shutdown..."
	pipesClose

	statline "Releasing external interfaces..."
	pipesCreate
	releaseExternalIfcs $eid $extifcs $extifcsCount $w
	statline "Waiting for $extifcsCount external interface(s) to be released..."
	pipesClose

	statline "Stopping services for LINKDEST hook..."
	services stop "LINKDEST"

	statline "Destroying links..."
	pipesCreate
	destroyLinks $eid $link_list $linkCount $w
	statline "Waiting for $linkCount link(s) to be destroyed..."
	pipesClose

	statline "Destroying physical interfaces on L3 nodes..."
	pipesCreate
	destroyNodesIfcs $eid $l3nodes $l3nodeCount $w
	statline "Waiting for physical interfaces on $l3nodeCount L3 node(s) to be destroyed..."
	pipesClose

	statline "Destroying L2 nodes..."
	pipesCreate
	destroyL2Nodes $eid $l2nodes $l2nodeCount $w
	statline "Waiting for $l2nodeCount L2 node(s) to be destroyed..."
	pipesClose

	statline "Checking for hanging TCP connections on L3 node(s)..."
	pipesCreate
	timeoutPatch $eid $l3nodes $l3nodeCount $w
	statline "Waiting for hanging TCP connections on $l3nodeCount L3 node(s)..."
	pipesClose

	statline "Stopping services for NODEDEST hook..."
	services stop "NODEDEST"

	statline "Destroying L3 nodes..."
	pipesCreate
	destroyL3Nodes $eid $l3nodes $l3nodeCount $w
	statline "Waiting for $l3nodeCount L3 node(s) to be destroyed..."
	pipesClose

	statline "Removing experiment top-level container/netns..."
	pipesCreate
	removeExperimentContainer $eid $w
	pipesClose

	statline "Removing experiment files..."
	pipesCreate
	removeExperimentFiles $eid $w
    } on error err {
	finishTerminating 0 "$err" $w
	return
    }

    finishTerminating 1 "" $w

    statline "Cleanup completed in [expr ([clock milliseconds] - $t_start)/1000.0] seconds."

    if { $execMode == "batch" } {
	puts "Terminated experiment ID = $eid"
    }
}

proc timeoutPatch { eid nodes nodeCount w } {
    global progressbarCount execMode

    set batchStep 0
    set nodes_left $nodes
    while { [llength $nodes_left] > 0 } {
	displayBatchProgress $batchStep $nodeCount
	foreach node $nodes_left {
	    checkHangingTCPs $eid $node

	    incr batchStep
	    incr progressbarCount -1

	    set name [getNodeName $node]
	    if {$execMode != "batch"} {
		statline "Node $name stopped"
		$w.p configure -value $progressbarCount
		update
	    }
	    displayBatchProgress $batchStep $nodeCount

	    set nodes_left [removeFromList $nodes_left $node]
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if {$execMode == "batch"} {
	    statline ""
	}
    }
}

proc destroyNodesIfcs { eid nodes nodeCount w } {
    global progressbarCount execMode

    set batchStep 0
    foreach node $nodes {
	displayBatchProgress $batchStep $nodeCount

	try {
	    destroyNodeIfcs $eid $node
	} on error err {
	    return -code error "Error in 'destroyNodeIfcs $eid $node': $err"
	}

	incr batchStep
	incr progressbarCount -1

	if {$execMode != "batch"} {
	    statline "Destroying physical interfaces on node [getNodeName $node]"
	    $w.p configure -value $progressbarCount
	    update
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if {$execMode == "batch"} {
	    statline ""
	}
    }
}

#****f* exec.tcl/execCmdsNode
# NAME
#   execCmdsNode -- execute a set of commands on virtual node
# SYNOPSIS
#   execCmdsNode $node $cmds
# FUNCTION
#   Executes commands on a virtual node and returns the output.
# INPUTS
#   * node -- virtual node id
#   * cmds -- list of commands to execute
# RESULT
#   * returns the execution output
#****
proc execCmdsNode { node cmds } {
    set output ""
    foreach cmd $cmds {
        set result [execCmdNode $node $cmd]
	append output "\n" $result
    }
    return $output
}

#****f* exec.tcl/startNodeFromMenu
# NAME
#   startNodeFromMenu -- start node from button3menu
# SYNOPSIS
#   startNodeFromMenu $node
# FUNCTION
#   Invokes the [typmodel $node].start procedure, along with services startup.
# INPUTS
#   * node -- node id
#****
proc startNodeFromMenu { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global progressbarCount execMode

    set progressbarCount 0
    set w ""
    if {$execMode != "batch"} {
	set w .startup
	catch {destroy $w}
	toplevel $w -takefocus 1
	wm transient $w .
	wm title $w "Starting node $node..."
	message $w.msg -justify left -aspect 1200 \
	    -text "Starting up virtual nodes and links."
	pack $w.msg
	update
	ttk::progressbar $w.p -orient horizontal -length 250 \
	    -mode determinate -maximum 1 -value $progressbarCount
	pack $w.p
	update

	grab $w
	wm protocol $w WM_DELETE_WINDOW {
	}
    }

    pipesCreate
    services start "NODEINST" $node
    services start "LINKINST" $node
    set allNodeCount 1
    try {
	executeConfNodes $node 1 $w
	statline "Waiting for configuration on $allNodeCount node(s)..."
	waitForConfStart $node $allNodeCount $w
    } on error err {
	finishExecuting 0 "$err" $w
	return
    }
    services start "NODECONF" $node
    pipesClose

    finishExecuting 1 "" $w
}

#****f* exec.tcl/stopNodeFromMenu
# NAME
#   stopNodeFromMenu -- stop node from button3menu
# SYNOPSIS
#   stopNodeFromMenu $node
# FUNCTION
#   Invokes the [typmodel $node].shutdown procedure, along with services shutdown.
# INPUTS
#   * node -- node id
#****
proc stopNodeFromMenu { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global progressbarCount execMode

    set progressbarCount 1
    set w ""
    if {$execMode != "batch"} {
	set w .startup
	catch {destroy $w}
	toplevel $w -takefocus 1
	wm transient $w .
	wm title $w "Stopping node $node..."
	message $w.msg -justify left -aspect 1200 \
	    -text "Deleting virtual nodes and links."
	pack $w.msg
	update
	ttk::progressbar $w.p -orient horizontal -length 250 \
	    -mode determinate -maximum 1 -value $progressbarCount
	pack $w.p
	update

	grab $w
	wm protocol $w WM_DELETE_WINDOW {
	}
    }

    pipesCreate
    services stop "NODESTOP" $node
    try {
	terminateL2L3Nodes $eid $node 1 $w
    } on error err {
	finishTerminating 0 "$err" $w
	return
    }
    services stop "LINKDEST" $node
    services stop "NODEDEST"
    pipesClose

    finishTerminating 1 "" $w
}

#****f* exec.tcl/pipesCreate
# NAME
#   pipesCreate -- pipes create
# SYNOPSIS
#   pipesCreate
# FUNCTION
#   Create pipes for parallel execution to the shell.
#****
proc pipesCreate { } {
    global inst_pipes last_inst_pipe

    set ncpus [getCpuCount]
    for {set i 0} {$i < $ncpus} {incr i} {
	set inst_pipes($i) [open "| sh" r+]
    }
    set last_inst_pipe 0
}

proc pipesExecLog { line args } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    if { $line == "" } {
	return
    }

    set logfile "/tmp/$eid.log"

    pipesExec "printf \"RUN: \" >> $logfile ; cat >> $logfile 2>&1 <<\"EOF\"\n$line\nEOF" "hold"
    pipesExec "$line >> $logfile 2>&1" "$args"
}

#****f* exec.tcl/pipesExec
# NAME
#   pipesExec -- pipes execute
# SYNOPSIS
#   pipesExec line hold
# FUNCTION
#   Puts the shell command to the pipe.
# INPUTS
#   * line -- shell command
#   * args -- if empty, increment last pipe
#****
proc pipesExec { line args } {
    global inst_pipes last_inst_pipe

    set pipe $inst_pipes($last_inst_pipe)
    puts $pipe $line

    flush $pipe
    if { $args != "hold" } {
	incr last_inst_pipe
    }
    if {$last_inst_pipe >= [llength [array names inst_pipes]]} {
	set last_inst_pipe 0
    }
}

#****f* exec.tcl/pipesClose
# NAME
#   pipesClose -- pipes close
# SYNOPSIS
#   pipesClose
# FUNCTION
#   Close pipes.
#****
proc pipesClose { } {
    global inst_pipes last_inst_pipe

    foreach i [array names inst_pipes] {
	close $inst_pipes($i) w
	# A dummy read, just to flush the output from the command pipeline
	read $inst_pipes($i)
	catch {close $inst_pipes($i)}
    }
}

#****f* exec.tcl/l3node.ipsecInit
# NAME
#   l3node.ipsecInit -- IPsec initialization
# SYNOPSIS
#   l3node.ipsecInit $node
# FUNCTION
#   Creates ipsec.conf and ipsec.secrets files from IPsec configuration of given node
#   and copies certificates to desired folders (if there are any certificates)
# INPUTS
#   * node -- node id
#****
set ipsecConf ""
set ipsecSecrets ""
proc l3node.ipsecInit { node } {
    global ipsecConf ipsecSecrets isOSfreebsd

    set config_content [getNodeIPsec $node]
    if { $config_content != "" } {
	setNodeIPsecSetting $node "configuration" "conn %default" "keyexchange" "ikev2"
	set ipsecConf "# /etc/ipsec.conf - strongSwan IPsec configuration file\n"
    } else {
	return
    }

    set config_content [getNodeIPsecItem $node "configuration"]

    foreach item $config_content {
	set element [lindex $item 0]
	set settings [lindex $item 1]
	set ipsecConf "$ipsecConf$element\n"
	set hasKey 0
	set hasRight 0
	foreach setting $settings {
	    if { [string match "peersname=*" $setting] } {
		continue
	    }
	    if { [string match "sharedkey=*" $setting] } {
		set hasKey 1
		set psk_key [lindex [split $setting =] 1]
		continue
	    }
	    if { [string match "right=*" $setting] } {
		set hasRight 1
		set right [lindex [split $setting =] 1]
	    }
	    set ipsecConf "$ipsecConf        $setting\n"
	}
	if { $hasKey && $hasRight } {
	    set ipsecSecrets "$right : PSK $psk_key"
	}
    }

    delNodeIPsecElement $node "configuration" "conn %default"

    set local_cert [getNodeIPsecItem $node "local_cert"]
    set ipsecret_file [getNodeIPsecItem $node "local_key_file"]
    ipsecFilesToNode $node $local_cert $ipsecret_file

    set ipsec_log_level [getNodeIPsecItem $node "ipsec-logging"]
    if { $ipsec_log_level != "" } {
	execCmdNode $node "touch /tmp/charon.log"
	set charon "charon {\n\
	\tfilelog {\n\
	\t\t/tmp/charon.log {\n\
	\t\t\tappend = yes\n\
	\t\t\tflush_line = yes\n\
	\t\t\tdefault = $ipsec_log_level\n\
	\t\t}\n\
	\t}\n\
	}"

	set prefix ""
	if { $isOSfreebsd } {
	    set prefix "/usr/local"
	}
	writeDataToNodeFile $node "$prefix/etc/strongswan.d/charon-logging.conf" $charon
    }
}

#****f* exec.tcl/generateHostsFile
# NAME
#   generateHostsFile -- generate hosts file
# SYNOPSIS
#   generateHostsFile $node
# FUNCTION
#   Generates /etc/hosts file on the given node containing all the nodes in the
#   topology.
# INPUTS
#   * node -- node id
#****
proc generateHostsFile { node } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    upvar 0 ::cf::[set ::curcfg]::etchosts etchosts
    global hostsAutoAssign

    if { $hostsAutoAssign == 1 } {
	if { [[typemodel $node].virtlayer] == "VIMAGE" } {
	    if { $etchosts == "" } {
		foreach iter $node_list {
		    if { [[typemodel $iter].virtlayer] == "VIMAGE" } {
			foreach ifc [ifcList $iter] {
			    if { $ifc != "" } {
				set ipv4 [lindex [split [getIfcIPv4addr $iter $ifc] "/"] 0]
				set ipv6 [lindex [split [getIfcIPv6addr $iter $ifc] "/"] 0]
				set ifname [getNodeName $iter]
				if { $ipv4 != "" } {
				    set etchosts "$etchosts$ipv4	$ifname\n"
				}
				if { $ipv6 != "" } {
				    set etchosts "$etchosts$ipv6	$ifname\n"
				}
				break
			    }
			}
		    }
		}
	    }
	    writeDataToNodeFile $node /etc/hosts $etchosts
	}
    }
}

#****f* exec.tcl/captureOnExtIfc
# NAME
#   captureOnExtIfc -- start wireshark on an interface
# SYNOPSIS
#   captureOnExtIfc $node $command
# FUNCTION
#   Start tcpdump or Wireshark on the specified external interface.
# INPUTS
#   * node -- node id
#   * command -- tcpdump or wireshark
#****
proc captureOnExtIfc { node command } {
    set ifc [lindex [ifcList $node] 0]
    if { "$ifc" == "" } {
	return
    }

    upvar 0 ::cf::[set ::curcfg]::eid eid

    if { $command == "tcpdump" } {
	exec xterm -T "Capturing $eid-$node" -e "tcpdump -ni $eid-$node" 2> /dev/null &
    } else {
	exec $command -o "gui.window_title:[getNodeName $node] ($eid)" -k -i $eid-$node 2> /dev/null &
    }
}
