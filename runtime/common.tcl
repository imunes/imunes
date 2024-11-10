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
    devfs_number auto_etc_hosts linkJitterConfiguration ipsecSecrets \
    ipsecConf ipFastForwarding

set linkJitterConfiguration 0
set vroot_unionfs 1
set vroot_linprocfs 0
set ifc_dad_disable 0
set regular_termination 1
set devfs_number 46837
set auto_etc_hosts 0
set ipFastForwarding 0

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

    if { $execMode == "batch" } {
	puts $line
	flush stdout
    } else {
	global debug

	if { $debug } {
	    puts $line
	    flush stdout
	}

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
    global execMode debug

    if { $debug || $execMode == "batch" } {
	puts -nonewline "\r                                                "
	puts -nonewline "\r> $prgs/$tot "
	flush stdout
    }
}

#****f* exec.tcl/pipesCreate
# NAME
#   pipesCreate -- pipes create
# SYNOPSIS
#   pipesCreate
# FUNCTION
#   Create pipes for parallel execution to the shell.
#****
proc pipesCreate {} {
    global inst_pipes last_inst_pipe

    set ncpus [getCpuCount]
    for { set i 0 } { $i < $ncpus } { incr i } {
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

    pipesExec "printf \"RUN: \" >> $logfile ; cat >> $logfile 2>&1 <<\"IMUNESEOF\"\n$line\nIMUNESEOF" "hold"
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
    if { $last_inst_pipe >= [llength [array names inst_pipes]] } {
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
proc pipesClose {} {
    global inst_pipes last_inst_pipe

    foreach i [array names inst_pipes] {
	close $inst_pipes($i) w
	# A dummy read, just to flush the output from the command pipeline
	read $inst_pipes($i)
	catch { close $inst_pipes($i) }
    }
}

#****f* exec.tcl/setOperMode
# NAME
#   setOperMode -- set operating mode
# SYNOPSIS
#   setOperMode $new_oper_mode
# FUNCTION
#   Sets imunes operating mode to the value of the parameter new_oper_mode.
#   The mode can be set only to edit or exec.
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
#   * new_oper_mode -- the new operating mode. Can be edit or exec.
#****
proc setOperMode { new_oper_mode } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    upvar 0 ::cf::[set ::curcfg]::undolevel undolevel
    upvar 0 ::cf::[set ::curcfg]::redolevel redolevel
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    upvar 0 ::cf::[set ::curcfg]::cfgDeployed cfgDeployed
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global all_modules_list editor_only execMode isOSfreebsd isOSlinux

    if { $new_oper_mode == "exec" && $node_list == "" } {
	statline "Empty topologies can't be executed."
	.panwin.f1.c config -cursor left_ptr

	return
    }

    if { ! $cfgDeployed && $new_oper_mode == "exec" } {
	if { ! $isOSlinux && ! $isOSfreebsd } {
	    after idle { .dialog1.msg configure -wraplength 4i }
	    tk_dialog .dialog1 "IMUNES error" \
		"Error: To execute experiment, run IMUNES on FreeBSD or Linux." \
	    info 0 Dismiss
	    return
	}

	catch { exec id -u } uid
	if { $uid != "0" } {
	    after idle { .dialog1.msg configure -wraplength 4i }
	    tk_dialog .dialog1 "IMUNES error" \
		"Error: To execute experiment, run IMUNES with root permissions." \
	    info 0 Dismiss
	    return
	}

	set err [checkSysPrerequisites]
	if { $err != "" } {
	    after idle { .dialog1.msg configure -wraplength 4i }
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
	if { "$new_oper_mode" == "exec" } {
	    .panwin.f1.left.$b configure -state disabled
	} else {
	    .panwin.f1.left.$b configure -state normal
	}
    }

    .bottom.oper_mode configure -text "$new_oper_mode mode"
    setActiveTool select
    #.panwin.f1.left.select configure -state active
    if { "$new_oper_mode" == "exec" && [exec id -u] == 0 } {
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

	if { ! $cfgDeployed } {
	    deployCfg
	    set cfgDeployed true
	}

	wm protocol . WM_DELETE_WINDOW {
	    exit
	}

	.bottom.experiment_id configure -text "Experiment ID = $eid"
    } else {
	if { $oper_mode != "edit" } {
	    global regular_termination

	    wm protocol . WM_DELETE_WINDOW {
	    }

	    if { $regular_termination } {
		undeployCfg $eid
	    } else {
		vimageCleanup $eid
	    }

	    pipesCreate
	    killExtProcess "socat.*$eid"
	    pipesClose

	    set cfgDeployed false

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
    set node_id [lindex [.panwin.f1.c gettags {node && current}] 1]
    if { $node_id == "" } {
	set node_id [lindex [.panwin.f1.c gettags {nodelabel && current}] 1]
	if { $node_id == "" } {
	    return
	}
    }

    if { [[getNodeType $node_id].virtlayer] != "VIRTUALIZED" } {
	nodeConfigGUI .panwin.f1.c $node_id
    } else {
	set cmd [lindex [existingShells [[getNodeType $node_id].shellcmds] $node_id] 0]
	if { $cmd == "" } {
	    return
	}

	spawnShell $node_id $cmd
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
    global isOSfreebsd
    set ip6Set 0
    set ip4Set 0

    foreach node_id [selectedNodes] {
	set lines [getRunningNodeIfcList $node_id]
	# XXX - here we parse ifconfig output, maybe require virtual nodes on
	# linux to have ifconfig, or create different parsing procedures for ip
	# and ifconfig that will have the same output
	if ($isOSfreebsd) {
	    foreach line $lines {
		if { [regexp {^([[:alnum:]]+):.*mtu ([^$]+)$} $line \
		     -> ifc mtuvalue] } {
		    setIfcMTU $node_id $ifc $mtuvalue
		    set ip6Set 0
		    set ip4Set 0
		} elseif { [regexp {^\tether ([^ ]+)} $line -> macaddr] } {
		    setIfcMACaddr $node_id $ifc $macaddr
		} elseif { [regexp {^\tinet6 (?!fe80:)([^ ]+) prefixlen ([^ ]+)} $line -> ip6addr mask] } {
		    if { $ip6Set == 0 } {
			setIfcIPv6addrs $node_id $ifc $ip6addr/$mask
			set ip6Set 1
		    }
		} elseif { [regexp {^\tinet ([^ ]+) netmask ([^ ]+) } $line \
		     -> ip4addr netmask] } {
		    if { $ip4Set == 0 } {
			set length [ip::maskToLength $netmask]
			setIfcIPv4addrs $node_id $ifc $ip4addr/$length
			set ip4Set 1
		    }
		}
	    }
	} else {
	    foreach line $lines {
		if { [regexp {^([[:alnum:]]+)} $line -> ifc] } {
		    set ip6Set 0
		    set ip4Set 0
		}
		if { [regexp {^([[:alnum:]]+)\s.*HWaddr ([^$]+)$} $line \
		     -> ifc macaddr] } {
		    setIfcMACaddr $node_id $ifc $macaddr
		} elseif { [regexp {^\s*inet addr:([^ ]+)\s.*\sMask:([^ ]+)} $line \
		     -> ip4addr netmask] } {
		    if { $ip4Set == 0 } {
			set length [ip::maskToLength $netmask]
			setIfcIPv4addrs $node_id $ifc $ip4addr/$length
			set ip4Set 1
		    }
		} elseif { [regexp {^\s*inet6 addr:\s(?!fe80:)([^ ]+)} $line -> ip6addr] } {
		    if { $ip6Set == 0 } {
			setIfcIPv6addrs $node_id $ifc $ip6addr
			set ip6Set 1
		    }
		} elseif { [regexp {MTU:([^ ]+)} $line -> mtuvalue] } {
		    setIfcMTU $node_id $ifc $mtuvalue
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

    if { [info exists eid] } {
	set curr_eid $eid
	if { $curr_eid == $exp } {
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

    foreach link_id $link_list {
	if { $link_id in $skipLinks } {
	    continue
	}

	lassign [getLinkPeers $link_id] node1_id node2_id
	lassign [getLinkPeersIfaces $link_id] iface1_id iface2_id

	set mirror_link_id [getLinkMirror $link_id]
	if { $mirror_link_id != "" } {
	    lappend skipLinks $mirror_link_id

	    lassign "[lindex [getLinkPeers $mirror_link_id] 0] $node1_id" node1_id node2_id
	    lassign "[lindex [getLinkPeersIfaces $mirror_link_id] 0] $iface1_id" iface1_id iface2_id
	}

	set name1 [getNodeName $node1_id]
	set name2 [getNodeName $node2_id]

	set linkname "$name1$linkDelim$name2"

	set lpair [list $node1_id [getIfcName $node1_id $iface1_id]]
	set rpair [list $node2_id [getIfcName $node2_id $iface2_id]]
	if { [getNodeType $node1_id] in "rj45 extelem" } {
	    if { [getNodeType $node1_id] == "rj45" } {
		set lpair $name1
	    } else {
		set ifaces [getNodeStolenIfaces $node1_id]
		set lpair [lindex [lsearch -inline -exact -index 0 $ifaces "$iface1_id"] 1]
	    }
	}
	if { [getNodeType $node2_id] in "rj45 extelem" } {
	    if { [getNodeType $node2_id] == "rj45" } {
		set rpair $name2
	    } else {
		set ifaces [getNodeStolenIfaces $node2_id]
		set rpair [lindex [lsearch -inline -exact -index 0 $ifaces "$iface2_id"] 1]
	    }
	}

	set line "$link_id {$node1_id-$node2_id {{$lpair} {$rpair}} $linkname}\n"
	set data "$data$line"
    }

    set data [string trimright $data "\n"]

    writeDataToFile $path $data
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
    if { $exp_files != "" } {
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
	if { $exp in $exp_folders } {
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
    if { [file exists $pathToFile] } {
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
    if { [file exists $pathToFile] } {
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
    if { [file exists $pathToFile] } {
	set file $pathToFile
    }

    return $file
}

#****f* exec.tcl/captureOnExtIfc
# NAME
#   captureOnExtIfc -- start wireshark on an interface
# SYNOPSIS
#   captureOnExtIfc $node_id $command
# FUNCTION
#   Start tcpdump or Wireshark on the specified external interface.
# INPUTS
#   * node_id -- node id
#   * command -- tcpdump or wireshark
#****
proc captureOnExtIfc { node_id command } {
    set ifc [lindex [ifcList $node_id] 0]
    if { "$ifc" == "" } {
	return
    }

    upvar 0 ::cf::[set ::curcfg]::eid eid

    if { $command == "tcpdump" } {
	exec xterm -name imunes-terminal -T "Capturing $eid-$node_id" -e "tcpdump -ni $eid-$node_id" 2> /dev/null &
    } else {
	exec $command -o "gui.window_title:[getNodeName $node_id] ($eid)" -k -i $eid-$node_id 2> /dev/null &
    }
}
