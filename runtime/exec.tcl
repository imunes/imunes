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

# $Id: exec.tcl 147 2015-03-27 14:37:19Z denis $

set vroot_unionfs 1
set vroot_linprocfs 0
set ifc_dad_disable 0
set regular_termination 1
set devfs_number 46837

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

#****f* exec.tcl/allSnapshotsAvailable
# NAME
#   allSnapshotsAvailable -- all snapshots available
# SYNOPSIS
#   allSnapshotsAvailable
# FUNCTION
#   Procedure that checks wheter all node ZFS snapshots are available on the
#   current system.
#****
proc allSnapshotsAvailable {} {
    global execMode vroot_unionfs
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    set vroot "/var/imunes/vroot"

    if {$vroot_unionfs} {
	if { [file exist $vroot] } {
	    return 1
	} else {
	    if {$execMode == "batch"} {
		puts "The root filesystem for virtual nodes ($vroot) is missing.
Run 'make' or 'make vroot' to create the root filesystem."
	    } else {
		tk_dialog .dialog1 "IMUNES error" \
		"The root filesystem for virtual nodes ($vroot) is missing.
Run 'make' or 'make vroot' to create the root filesystem." \
		info 0 Dismiss
	    }
	    return 0
	}
    }

    catch { exec zfs list -t snapshot | awk {{print $1}} | sed "1 d" } out
    set snapshotList [ split $out {
}]
    foreach node $node_list {
	set snapshot [getNodeSnapshot $node]
	if { $snapshot == "" } {
	    set snapshot "vroot/vroot@clean"
	}
	if { [llength [lsearch -inline $snapshotList $snapshot]] == 0} {
	    if {$execMode == "batch"} {
		if { $snapshot == "vroot/vroot@clean" } {
		    puts "The main snapshot for virtual nodes is missing.
Run 'make' or 'make vroot' to create the main ZFS snapshot."
		} else {
		    puts "Error: ZFS snapshot image \"$snapshot\" for node \"$node\" is missing."
		}
		return 0
	    } else {
		after idle {.dialog1.msg configure -wraplength 6i}
		if { $snapshot == "vroot/vroot@clean" } {
		    tk_dialog .dialog1 "IMUNES error" \
		    "The main snapshot for virtual nodes is missing.
Run 'make' or 'make vroot' to create the main ZFS snapshot." \
		    info 0 Dismiss
		    return 0
		} else {
		    tk_dialog .dialog1 "IMUNES error" \
		    "Error: ZFS snapshot image \"$snapshot\" for node \"$node\" is missing." \
		    info 0 Dismiss
		    return 0
		}
	    }
	}
    }
    return 1
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
#   simulation/Terminate button, that is enabled) and procedure deployCfg is #   called.
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
    global all_modules_list editor_only execMode

    if {$mode == "exec" && $node_list == ""} {
	statline "Empty topologies can't be executed."
	.panwin.f1.c config -cursor left_ptr
	return
    }

    if { !$cfgDeployed } {
	    if { $mode == "exec" } { ;# let's try something, sockets should be opened
		set os [platform::identify]
		if { [string match -nocase "*freebsd*" $os] != 1 } {
		    after idle {.dialog1.msg configure -wraplength 4i}
		    tk_dialog .dialog1 "IMUNES error" \
			"Error: To execute experiment, run IMUNES on FreeBSD." \
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
		if { $editor_only } { ;# if set in exec or open_exec_sockets
		    .menubar.experiment entryconfigure "Execute" -state disabled
		    return
		}
	    }

	    if { [allSnapshotsAvailable] == 0 } {
		return
	    }

	    # Verify that links to external interfaces are properly configured
	    if { $mode == "exec" } {
		if { [checkExternalInterfaces] } {
		    return
		}
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
	if {!$cfgDeployed} {
	    deployCfg
	    set cfgDeployed true
	    createExperimentFiles $eid
	}
	.bottom.experiment_id configure -text "Experiment ID = $eid"
    } else {
	if {$oper_mode != "edit"} {
	    global regular_termination
	    if { $regular_termination } {
		terminateAllNodes $eid
	    } else {
		vimageCleanup $eid
	    }
	    catch "exec pkill -f socat.*$eid"
	    set cfgDeployed false
	    deleteExperimentFiles $eid
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

#****f* exec.tcl/execCmdNode
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

    catch {eval [concat "nexec jexec " $eid.$node $cmd] } output
    return $output
}

#****f* exec.tcl/checkForApplications
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
	set exists [ catch { exec jexec $eid.$node which $app } err ]
	if { $exists } {
	    return 1
	}
    }
    return 0
}

#****f* exec.tcl/startWiresharkOnNodeIfc
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
	exec startxcmd [getNodeName $node]@$eid wireshark -ki $ifc > /dev/null 2>&1 &
    } else {
	exec jexec $eid.$node tcpdump -s 0 -U -w - -i $ifc 2>/dev/null |\
	    wireshark -o "gui.window_title:$ifc@[getNodeName $node] ($eid)" -k -i - &
    }
}

#****f* exec.tcl/startXappOnNode
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

    eval exec startxcmd [getNodeName $node]@$eid $app > /dev/null 2>&1 &
}

#****f* exec.tcl/startTcpdumpOnNodeIfc
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

#****f* exec.tcl/existingShells
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

    set cmd "jexec $eid.$node which $shells"

    set err [catch {eval exec $cmd} res]
    if  { $err } {
	return ""
    }

    return $res
}

#****f* exec.tcl/spawnShell
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

    nexec xterm -sb -rightbar \
	-T "IMUNES: [getNodeName $node] (console) [lindex [split $cmd /] end]" \
	-e "jexec $node_id $cmd" &
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
    global gui_unix

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
    set ip6Set 0
    set ip4Set 0

    foreach node [selectedNodes] {
	catch {exec jexec $eid.$node ifconfig} full
	set lines [split $full "\n"]

	foreach line $lines {
	    if {[regexp {^([[:alnum:]]+):.*mtu ([^$]+)$} $line \
		 -> ifc mtuvalue]} {
		setIfcMTU $node $ifc $mtuvalue
		set ip6Set 0
		set ip4Set 0
	    } elseif {[regexp {^\tether ([^ ]+)} $line -> macaddr]} {
		setIfcMACaddr $node $ifc $macaddr
	    } elseif {[regexp {^\tinet6 (?!fe80:)([^ ]+) } $line -> ip6addr]} {
		if {$ip6Set == 0} {
		    setIfcIPv6addr $node $ifc $ip6addr
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
    }
    redrawAll
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

    # fetch interface list from the system
    set extifcs [exec ifconfig -l]
    # exclude loopback interface
    set ilo [lsearch $extifcs lo0]
    set extifcs [lreplace $extifcs $ilo $ilo]

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
		# check if the VLAN is available
		set ifname [getNodeName $node]
		set vlan [lindex [split [getNodeName $node] .] 1]
		# if the VLAN is available then it can be created
		if { [catch {exec ifconfig $ifname create} err] } {
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
		} else {
		    # destroy it, if it was created
		    catch {exec ifconfig $ifname destroy}
		}
	    }
	}
    }
    return 0
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
    upvar 0 ::cf::[set ::curcfg]::ngnodemap ngnodemap
    global currentFileBatch execMode
    file mkdir /var/run/imunes/$eid

    set fileName "/var/run/imunes/$eid/timestamp"
    set fileId [open $fileName w]
    puts $fileId [clock format [clock seconds]]
    close $fileId

    set fileName "/var/run/imunes/$eid/ngnodemap"
    set fileId [open $fileName w]
    puts $fileId [array get ngnodemap]
    close $fileId

    if { $execMode == "interactive" } {
	if { $currentFile != "" } {
	    set fileName "/var/run/imunes/$eid/name"
	    set fileId [open $fileName w]
	    puts $fileId [file tail $currentFile]
	    close $fileId
	}
    } elseif { $execMode == "batch" } {
	if { $currentFileBatch != "" } {
	    set fileName "/var/run/imunes/$eid/name"
	    set fileId [open $fileName w]
	    puts $fileId [file tail $currentFileBatch]
	    close $fileId
	}
    }

    if { $execMode == "interactive" } {
	saveRunningConfigurationInteractive $eid
    } elseif { $execMode == "batch" } {
	saveRunningConfigurationBatch $eid
    }

    if { $execMode == "interactive" } {
	createExperimentScreenshot $eid
    }
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
    set fileName "/var/run/imunes/$eid/config.imn"
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
    global currentFileBatch
    set fileName "/var/run/imunes/$eid/config.imn"
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
    set fileName "/var/run/imunes/$eid/screenshot.png"
    set error [catch {eval image create photo screenshot -format window \
	-data .panwin.f1.c} err]
    if { ($error == 0) } {
	screenshot write $fileName -format png
#	exec convert $fileName -resize 300x210\! $fileName\2
#	exec mv $fileName\2 $fileName
    } else {
	#puts "ERROR: code $error"
	#puts "$err"
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
    set folderName "/var/run/imunes/$eid"
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

#****f* exec.tcl/fetchRunningExperiments
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
    catch {exec jls -n name | cut -d "=" -f 2 | cut -d "." -f 1 | sort | uniq} exp_list
    set exp_list [split $exp_list "
"]
    return $exp_list
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
    set exp_list ""
    set exp_files [glob -nocomplain -directory /var/run/imunes -type d *]
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
    set pathToFile "/var/run/imunes/$eid/timestamp"
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
    set pathToFile "/var/run/imunes/$eid/name"
    set name ""
    if {[file exists $pathToFile]} {
	set fileId [open $pathToFile r]
	set name [string trim [read $fileId]]
	close $fileId
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
    set pathToFile "/var/run/imunes/$eid/config.imn"
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
	puts -nonewline [format "\r%.1f" "[expr {100.0 * $prgs/$tot}]"]%
	flush stdout
    }
}

#****f* exec.tcl/createIfc
# NAME
#   createIfc -- create interface
# SYNOPSIS
#   set name [createIfc $eid $type $hook]
# FUNCTION
#   Creates a new netgraph interface, of the type $type.
#   Returns the name of the newly created interface.
# INPUTS
#   * eid -- experiment id
#   * type -- new interface type. In imunes are used only eiface or iface
#     types. Additional specification on this types can be found in manual
#     pages for netgraph nodes.
#   * hook -- parameter specific for every netgraph node. For iface hook hook
#     is inet, and for eiface type the hook is ether.
# RESULT
#   * name -- the name of the new interface
#****
proc createIfc { eid type hook } {
    catch { exec printf "mkpeer $type $hook $hook \n show .$hook" | jexec $eid ngctl -f - } nglist
    return [lindex $nglist 1]
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
    global vroot_unionfs vroot_linprocfs devfs_number
    global inst_pipes last_inst_pipe
    upvar 0 ::cf::[set ::curcfg]::ngnodemap ngnodemap

    set node_id "$eid\.$node"

    # Prepare a copy-on-write filesystem root
    if {$vroot_unionfs} {
	# UNIONFS
	set VROOTDIR /var/imunes
	set VROOT_RUNTIME $VROOTDIR/$eid/$node
	set VROOT_OVERLAY $VROOTDIR/$eid/upper/$node
	set VROOT_RUNTIME_DEV $VROOT_RUNTIME/dev
	pipesExec "mkdir -p $VROOT_RUNTIME" "hold"
	pipesExec "mkdir -p $VROOT_OVERLAY" "hold"
	pipesExec "mount_nullfs -o ro $VROOTDIR/vroot $VROOT_RUNTIME" "hold"
	pipesExec "mount_unionfs -o noatime $VROOT_OVERLAY $VROOT_RUNTIME" "hold"
    } else {
	# ZFS
	set VROOT_ZFS vroot/$eid/$node
	set VROOT_RUNTIME /$VROOT_ZFS
	set VROOT_RUNTIME_DEV $VROOT_RUNTIME/dev

	set snapshot [getNodeSnapshot $node]
	if {$snapshot == ""} {
	    set snapshot "vroot/vroot@clean"
	}
	pipesExec "zfs clone $snapshot $VROOT_ZFS" "hold"
    }

    if {$vroot_linprocfs} {
	pipesExec "mount -t linprocfs linprocfs $VROOT_RUNTIME/compat/linux/proc" "hold"
	#XXX - linux_sun_jdk16 - java hack, won't work if proc isn't accessed
	#before execution, so we need to cd to it.
	pipesExec "cd $VROOT_RUNTIME/compat/linux/proc" "hold"
    }

    # Mount and configure a restricted /dev
    pipesExec "mount -t devfs devfs $VROOT_RUNTIME_DEV" "hold"
    pipesExec "devfs -m $VROOT_RUNTIME_DEV ruleset $devfs_number" "hold"
    pipesExec "devfs -m $VROOT_RUNTIME_DEV rule applyset" "hold"

    pipesExec "jail -c name=$node_id path=$VROOT_RUNTIME securelevel=1 \
      host.hostname=[getNodeName $node] vnet persist" "hold"

    # Create a vimage
    # Create "physical" network interfaces
    foreach ifc [ifcList $node] {
	switch -exact [string range $ifc 0 2] {
	    eth {
		set ifid [createIfc $eid eiface ether]
		pipesExec "jexec $eid ifconfig $ifid vnet $node" "hold"
		pipesExec "jexec $node_id ifconfig $ifid name $ifc" "hold"

		# XXX ng renaming is automatic in FBSD 8.4 and 9.2, remove this!
		pipesExec "jexec $node_id ngctl name [set ifid]: $ifc" "hold"

		set peer [peerByIfc $node $ifc]
		set ether [getIfcMACaddr $node $ifc]
                if {$ether == ""} {
                    autoMACaddr $node $ifc
                }
                set ether [getIfcMACaddr $node $ifc]
		global ifc_dad_disable
		if {$ifc_dad_disable} {
		    pipesExec "jexec $node_id sysctl net.inet6.ip6.dad_count=0" "hold"
		}
		pipesExec "jexec $node_id ifconfig $ifc link $ether" "hold"
		set ngnodemap($ifc@$node_id) $ifid
	    }
	    ser {
		set ifnum [string range $ifc 3 end]
		set ifid [createIfc $eid iface inet]
		pipesExec "jexec $eid ngctl mkpeer $ifid: cisco inet inet" "hold"
		pipesExec "jexec $eid ngctl connect $ifid: $ifid:inet inet6 inet6" "hold"
		pipesExec "jexec $eid ngctl msg $ifid: broadcast" "hold"
		pipesExec "jexec $eid ngctl name $ifid:inet hdlc$ifnum\@$node" "hold"
		pipesExec "jexec $eid ifconfig $ifid vnet $node" "hold"
		pipesExec "jexec $node_id ifconfig $ifid name $ifc" "hold"
		set ngnodemap(hdlc$ifnum@$node_id) hdlc$ifnum\@$node"
	    }
	}
    }

    # Create logical network interfaces
    foreach ifc [logIfcList $node] {
	switch -exact [getLogIfcType $node $ifc] {
	    vlan {
		set tag [getIfcVlanTag $node $ifc]
		set dev [getIfcVlanDev $node $ifc]
                if {$tag != "" && $dev != ""} {
		    pipesExec "jexec $node_id ifconfig $ifc create" "hold"
                    pipesExec "jexec $node_id ifconfig $ifc vlan $tag vlandev $dev" "hold"
                }
	    }
	    lo {
		if {$ifc != "lo0"} {
		    pipesExec "jexec $node_id ifconfig $ifc create" "hold"
		}
	    }
	}
    }

    pipesExec "jexec $node_id sysctl net.inet.icmp.bmcastecho=1" "hold"
    pipesExec "jexec $node_id sysctl net.inet.icmp.icmplim=0" "hold"
}

#****f* exec.tcl/l3node.nghook
# NAME
#   l3node.nghook -- layer 3 node netgraph hook
# SYNOPSIS
#   l3node.nghook $eid $node $ifc
# FUNCTION
#   Returns the netgraph node name and the hook name for a given experiment
#   id, node id, and interface name.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#   * ifc -- interface name
# RESULT
#   * list -- list in the form of {netgraph_node_name hook}
#****
proc l3node.nghook { eid node ifc } {
    set ifnum [string range $ifc 3 end]
    set node_id "$eid\.$node"
    switch -exact [string range $ifc 0 2] {
	eth {
	    return [list $ifc@$node_id ether]
	}
	ser {
	    return [list hdlc$ifnum@$node_id downstream]
	}
    }
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
    global viewcustomid vroot_unionfs

    set node_id "$eid\.$node"

    if {$vroot_unionfs} {
	set node_dir /var/imunes/$eid/$node
    } else {
	set node_dir /vroot/$eid/$node
    }

    set cmds ""
    foreach ifc [allIfcList $node] {
	set mtu [getIfcMTU $node $ifc]
	if {[getIfcOperState $node $ifc] == "up"} {
	    set cmds "$cmds\n jexec $node_id ifconfig $ifc mtu $mtu up"
	} else {
	    set cmds "$cmds\n jexec $node_id ifconfig $ifc mtu $mtu"
	}
    }
    exec sh << $cmds &

    if { [getCustomEnabled $node] == true } {
	set selected [getCustomConfigSelected $node]

	set bootcmd [getCustomConfigCommand $node $selected]
	set bootcfg [getCustomConfig $node $selected]
	set fileId [open $node_dir/custom.conf w]
	foreach line $bootcfg {
	    puts $fileId $line
	}
	close $fileId
    } else {
	set bootcmd ""
	set bootcfg ""
    }

    set bootcfg_def [[typemodel $node].cfggen $node]
    set bootcmd_def [[typemodel $node].bootcmd $node]
    set fileId [open $node_dir/boot.conf w]
    foreach line $bootcfg_def {
	puts $fileId $line
    }
    close $fileId

    if { $bootcmd == "" || $bootcfg =="" } {
	catch "exec jexec $node_id $bootcmd_def boot.conf >& $node_dir/out.log &"
    } else {
	catch "exec jexec $node_id $bootcmd custom.conf >& $node_dir/out.log &"
    }

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
    set node_id "$eid\.$node"
    catch "exec pkill -f wireshark.*$node.*\\($eid\\)"
    catch "exec jexec $node_id kill -9 -1 2> /dev/null"
    catch "exec jexec $node_id tcpdrop -a 2> /dev/null"
    foreach ifc [ifcList $node] {
	foreach ipv4 [getIfcIPv4addr $node $ifc] {
	    catch "exec jexec $node_id ifconfig $ifc $ipv4 -alias"
	}
	foreach ipv6 [getIfcIPv6addr $node $ifc] {
	    catch "exec jexec $node_id ifconfig $ifc inet6 $ipv6 -alias"
	}
    }
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
    global vroot_unionfs
    global vroot_linprocfs

    set node_id $eid.$node
    # Destroy any virtual interfaces (tun, vlan, gif, ..) before removing the
    # jail. This is to avoid possible kernel panics.
    pipesExec "for iface in `jexec $node_id ifconfig -l`; do jexec $node_id ifconfig \$iface destroy; done" "hold"

    pipesExec "jail -r $node_id" "hold"
    if {$vroot_unionfs} {
	set VROOTDIR /var/imunes
    } else {
	set VROOTDIR /vroot
    }

    set VROOT_RUNTIME $VROOTDIR/$eid/$node
    set VROOT_RUNTIME_DEV $VROOT_RUNTIME/dev
    pipesExec "umount -f $VROOT_RUNTIME_DEV" "hold"
    if {$vroot_unionfs} {
	# 1st: unionfs RW overlay
	pipesExec "umount -f $VROOT_RUNTIME" "hold"
	# 2nd: nullfs RO loopback
	pipesExec "umount -f $VROOT_RUNTIME" "hold"
	pipesExec "rmdir $VROOT_RUNTIME" "hold"
    }
    if {$vroot_linprocfs} {
	pipesExec "umount -f $VROOT_RUNTIME/compat/linux/proc" "hold"
    }

    pipesExec ""
}

proc prepareDevfs {} {
    global devfs_number

    catch {exec devfs rule showsets} devcheck
    if { $devfs_number ni $devcheck } {
	# Prepare a devfs ruleset for L3 vnodes
	exec devfs ruleset $devfs_number
	exec devfs rule delset
	exec devfs rule add hide
	exec devfs rule add path null unhide
	exec devfs rule add path zero unhide
	exec devfs rule add path random unhide
	exec devfs rule add path urandom unhide
	exec devfs rule add path crypto unhide
	exec devfs rule add path ptyp* unhide
	exec devfs rule add path ptyq* unhide
	exec devfs rule add path ptyr* unhide
	exec devfs rule add path ptys* unhide
	exec devfs rule add path ptyp* unhide
	exec devfs rule add path ptyq* unhide
	exec devfs rule add path ptyr* unhide
	exec devfs rule add path ptys* unhide
	exec devfs rule add path ttyp* unhide
	exec devfs rule add path ttyq* unhide
	exec devfs rule add path ttyr* unhide
	exec devfs rule add path ttys* unhide
	exec devfs rule add path ttyp* unhide
	exec devfs rule add path ttyq* unhide
	exec devfs rule add path ttyr* unhide
	exec devfs rule add path ttys* unhide
	exec devfs rule add path ptmx unhide
	exec devfs rule add path pts unhide
	exec devfs rule add path pts/* unhide
	exec devfs rule add path fd unhide
	exec devfs rule add path fd/* unhide
	exec devfs rule add path stdin unhide
	exec devfs rule add path stdout unhide
	exec devfs rule add path stderr unhide
	exec devfs rule add path mem unhide
	exec devfs rule add path kmem unhide
	exec devfs rule add path bpf* unhide
	exec devfs rule add path tun* unhide
	exec devfs ruleset 0
    }
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
    upvar 0 ::cf::[set ::curcfg]::ngnodemap ngnodemap
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global supp_router_models
    global eid_base
    global all_modules_list
    global vroot_unionfs devfs_number
    global inst_pipes last_inst_pipe
    global execMode
    global debug

    set running_eids [getResumableExperiments]
    if {$execMode != "batch"} {
	set eid ${eid_base}[string range $::curcfg 1 end]
	while { $eid in $running_eids } {
	    set eid_base i[format %04x [expr {[pid] + [expr { round( rand()*10000 ) }]}]]
	    set eid ${eid_base}[string range $::curcfg 1 end]
	}
    } else {
	set eid $eid_base
	while { $eid in $running_eids } {
	    puts -nonewline "Experiment ID $eid_base already in use, trying "
	    set eid i[format %04x [expr {[pid] + [expr { round( rand()*10000 ) }]}]]
	    puts "$eid."
	}
    }

    set t_start [clock milliseconds]

    catch {exec kldload nullfs}
    catch {exec kldload unionfs}

    catch {exec kldload ng_eiface}
    catch {exec kldload ng_pipe}
    catch {exec kldload ng_socket}
    catch {exec kldload if_tun}
    catch {exec kldload vlan}
#   catch {exec kldload ng_iface}
#   catch {exec kldload ng_cisco}

    foreach module $all_modules_list {
	if {[info procs $module.prepareSystem] == "$module.prepareSystem"} {
	    $module.prepareSystem
	}
    }

    if {$vroot_unionfs} {
	# UNIONFS - anything to do here?
    } else {
	# Prepare a ZFS pool with vroot template snapshot, if not present
	set ZFS_SNAPSHOT vroot/vroot@clean
	if {[catch {exec zfs list -t snapshot $ZFS_SNAPSHOT}]} {
	    statline "Creating ZFS pool and vroot template snapshot"
	    set ZPOOL_TMP_DISK /dev/[exec mdconfig -a -t swap -s 384m]
	    exec zpool create -o cachefile=none vroot $ZPOOL_TMP_DISK
	    exec zfs set atime=off vroot
	    exec zfs create vroot/vroot
	    exec tar -xf /usr/local/share/imunes/vroot.tar -C /vroot
	    exec zfs snapshot $ZFS_SNAPSHOT
        }
	exec zfs create vroot/$eid
    }

    prepareDevfs

    # Create top-level vimage
    exec jail -c name=$eid vnet children.max=[llength $node_list] persist

    set nodeCount [llength $node_list]
    set linkCount [llength $link_list]
    set count [expr {$nodeCount + $linkCount}]
    set startedCount 0
    if {$execMode != "batch"} {
	set w .startup
	catch {destroy $w}
	toplevel $w -takefocus 1
	wm transient $w .
	wm title $w "Starting experiment..."
	message $w.msg -justify left -aspect 1200 \
	    -text "Starting up virtual nodes and links."
	pack $w.msg
	update
	ttk::progressbar $w.p -orient horizontal -length 250 \
	-mode determinate -maximum $count -value $startedCount
	pack $w.p
	update
    }

    statline "Creating nodes..."
    set step 0
    set allNodes [ llength $node_list ]

    pipesCreate

    foreach node $node_list {
	incr step
	set node_id "$eid\.$node"
	set type [nodeType $node]
	set name [getNodeName $node]
	if {$type != "pseudo"} {
	    if {$execMode != "batch"} {
		statline "Creating node $name"
		$w.p configure -value $startedCount
		update
	    }
	    displayBatchProgress $step $allNodes
	    [typemodel $node].instantiate $eid $node
	    pipesExec ""
	    incr startedCount
	}
    }

    statline ""
    pipesClose

    statline "Creating links..."
    set step 0
    set allLinks [ llength $link_list ]
    for {set pending_links $link_list} {$pending_links != ""} {} {
	set link [lindex $pending_links 0]
	set i [lsearch -exact $pending_links $link]
	set pending_links [lreplace $pending_links $i $i]

	set lnode1 [lindex [linkPeers $link] 0]
	set lnode2 [lindex [linkPeers $link] 1]
	set ifname1 [ifcByPeer $lnode1 $lnode2]
	set ifname2 [ifcByPeer $lnode2 $lnode1]

	if { [getLinkMirror $link] != "" } {
	    set mirror_link [getLinkMirror $link]
	    set i [lsearch -exact $pending_links $mirror_link]
	    set pending_links [lreplace $pending_links $i $i]

	    if {$execMode != "batch"} {
		statline "Creating link $link/$mirror_link"
	    }

	    set p_lnode2 $lnode2
	    set lnode2 [lindex [linkPeers $mirror_link] 0]
	    set ifname2 [ifcByPeer $lnode2 [getNodeMirror $p_lnode2]]
	} else {
	    if {$execMode != "batch"} {
		statline "Creating link $link"
	    }
	}
	incr step
	displayBatchProgress $step $allLinks

	incr startedCount
	if {$execMode != "batch"} {
	    $w.p configure -value $startedCount
	    update
	}

	set lname $lnode1-$lnode2
	set bandwidth [expr [getLinkBandwidth $link] + 0]
	set delay [expr [getLinkDelay $link] + 0]
	set ber [expr [getLinkBER $link] + 0]
	set dup [expr [getLinkDup $link] + 0]

	set peer1 \
	    [lindex [[typemodel $lnode1].nghook $eid $lnode1 $ifname1] 0]
	set peer2 \
	    [lindex [[typemodel $lnode2].nghook $eid $lnode2 $ifname2] 0]
	set ngpeer1 $ngnodemap($peer1)
	set ngpeer2 $ngnodemap($peer2)
	set nghook1 \
	    [lindex [[typemodel $lnode1].nghook $eid $lnode1 $ifname1] 1]
	set nghook2 \
	    [lindex [[typemodel $lnode2].nghook $eid $lnode2 $ifname2] 1]

	set cmds ""

	set cmds "$cmds\n mkpeer $ngpeer1: pipe $nghook1 upper"
	set cmds "$cmds\n name $ngpeer1:$nghook1 $lname"
	set cmds "$cmds\n connect $lname: $ngpeer2: lower $nghook2"

	# Ethernet frame has a 14-byte header - this is a temp. hack!!!
	set cmds "$cmds\n msg $lname: setcfg {header_offset=14}"

	# Link parameters
	set cmds "$cmds\n msg $lname: setcfg {bandwidth=$bandwidth delay=$delay upstream={BER=$ber duplicate=$dup} downstream={BER=$ber duplicate=$dup}}"

	catch {exec jexec $eid ngctl -f - << $cmds} err
	if { $debug && $err != "" } {
	    puts $err
	}

	# Queues
	foreach node [list $lnode1 $lnode2] {
	    if {$node == $lnode1} {
		set ifc $ifname1
	    } else {
		set ifc $ifname2
	    }

	    if {[nodeType $lnode1] != "rj45" && [nodeType $lnode2] != "rj45"} {
		set qdisc [getIfcQDisc $node $ifc]
		if {$qdisc ne "FIFO"} {
		    execSetIfcQDisc $eid $node $ifc $qdisc
		}
		set qdrop [getIfcQDrop $node $ifc]
		if {$qdrop ne "drop-tail"} {
		    execSetIfcQDrop $eid $node $ifc $qdrop
		}
		set qlen [getIfcQLen $node $ifc]
		if {$qlen ne 50} {
		    execSetIfcQLen $eid $node $ifc $qlen
		}
	    }
	}

	global linkJitterConfiguration
	if  { $linkJitterConfiguration } {
	    execSetLinkJitter $eid $link
	}
    }

    statline ""
    statline "Configuring nodes..."

    set step 0
    foreach node $node_list {
	upvar 0 ::cf::[set ::curcfg]::$node $node
	set type [nodeType $node]
	if {$type == "pseudo"} {
	    continue
	}
	if {$execMode != "batch"} {
	    statline "Configuring node [getNodeName $node]"
	}
	incr step
	displayBatchProgress $step $allNodes

	if {[info procs [typemodel $node].start] != ""} {
	    [typemodel $node].start $eid $node
	}
    }
    statline ""

    statline "Network topology instantiated in [expr ([clock milliseconds] - $t_start)/1000.0] seconds ($allNodes nodes and $allLinks links)."

    statline "Experiment ID = $eid"
    global execMode
    if {$execMode != "batch"} {
	destroy $w
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
    upvar 0 ::cf::[set ::curcfg]::ngnodemap ngnodemap
    global execMode
    global vroot_unionfs vroot_linprocfs

    #preparing counters for GUI
    if {$execMode != "batch"} {
	set count [expr {[llength $node_list]+[llength $link_list]}]
	set w .termWait
	catch {destroy $w}
	toplevel $w -takefocus 1
	wm transient $w .
	wm title $w "Terminating experiment ..."
	message $w.msg -justify left -aspect 1200 \
	    -text "Deleting virtual nodes and links."
	pack $w.msg
	ttk::progressbar $w.p -orient horizontal -length 250 \
	    -mode determinate -maximum $count -value $count
	pack $w.p
	update
    }

    set t_start [clock milliseconds]

    # XXX - pipeline everything to make it faster.
    # Termination is done in the following order:
    # 1. call shutdown on all ng nodes because of the packgen node.
    # 2. call shutdown on all virtual nodes.
    # 3. remove all links to prevent packets flowing into the interfaces.
    # 4. destroy all netgraph nodes.
    # 5. destroy all ngeth interfaces from vimage nodes.
    # 6. destroy all vimage nodes.

    # divide nodes into two lists
    set ngraphs ""
    set vimages ""
    foreach node $node_list {
	if { [[typemodel $node].virtlayer] == "NETGRAPH" } {
	    lappend ngraphs $node
	} elseif { [[typemodel $node].virtlayer] == "VIMAGE" } {
	    lappend vimages $node
	}
    }

    statline "Stopping ngraphs and vimages..."
    foreach node [ concat $ngraphs $vimages ] {
	incr step
	if { [info procs [typemodel $node].shutdown] != "" } {
#	    statline "Stopping [string tolower [[typemodel $node].virtlayer]] node $node ([typemodel $node])"
	    displayBatchProgress $step [ llength [ concat $ngraphs $vimages ] ]
	    [typemodel $node].shutdown $eid $node
	} else {
	    #puts "$node [typemodel $node] doesn't have a shutdown procedure"
	}
    }
    statline ""

    # destroying links
    statline "Destroying links..."
    pipesCreate
    set i 0
    foreach link $link_list {
	incr i
        set lnode1 [lindex [linkPeers $link] 0]
        set lnode2 [lindex [linkPeers $link] 1]
#	statline "Shutting down link $link ($lnode1-$lnode2)"
	displayBatchProgress $i [ llength $link_list ]
	pipesExec "jexec $eid ngctl msg $lnode1-$lnode2: shutdown"
        if {$execMode != "batch"} {
            $w.p step -1
        }
    }
    pipesClose
    statline ""

    # destroying netgraph nodes
    if { $ngraphs != "" } {
	statline "Shutting down netgraph nodes..."
	set i 0
	foreach node $ngraphs {
	    incr i
    #	statline "Shutting down netgraph node $node ([typemodel $node])"
	    [typemodel $node].destroy $eid $node
	    if {$execMode != "batch"} {
		$w.p step -1
	    }
	    displayBatchProgress $i [ llength $ngraphs ]
	}
	statline ""
    }

    # destroying virtual interfaces
    statline "Destroying virtual interfaces..."
    set i 0
    pipesCreate
    foreach node $vimages {
	incr i
	foreach ifc [ifcList $node] {
	    set ngnode $ngnodemap($ifc@$eid\.$node)
	    pipesExec "jexec $eid ngctl shutdown $ngnode:"
	}
	displayBatchProgress $i [ llength $vimages ]
    }
    pipesClose
    statline ""

    # timeout patch
    timeoutPatch $eid $node_list

    # destroying vimages
    statline "Shutting down vimages..."
    pipesCreate
    set i 0
    foreach node $vimages {
#	statline "Shutting down vimage $node ([typemodel $node])"
	incr i
	[typemodel $node].destroy $eid $node
        if {$execMode != "batch"} {
            $w.p step -1
        }
	displayBatchProgress $i [ llength $vimages ]
    }
    pipesClose
    statline ""

    # Remove the main vimage which contained all other nodes, hopefully we
    # cleaned everything.
    if {$vroot_unionfs} {
        set VROOT_BASE /var/imunes
    } else {
        set VROOT_BASE /vroot
    }

    if {$vroot_unionfs} {
	# UNIONFS
	catch "exec jexec $eid kill -9 -1 2> /dev/null"
	exec jail -r $eid
	catch "exec rm -fr $VROOT_BASE/$eid &"
    } else {
	# ZFS
	if {$execMode == "batch"} {
	    exec jail -r $eid
	    exec zfs destroy -fr vroot/$eid
	} else {
	    exec jail -r $eid &
	    exec zfs destroy -fr vroot/$eid &

	    catch {exec zfs list | grep -c "$eid"} output
	    set zfsCount [lindex [split $output] 0]

	    while {$zfsCount != 0} {
		catch {exec zfs list | grep -c "$eid/"} output
		set zfsCount [lindex [split $output] 0]
		$w.p configure -value $zfsCount
		update
		after 200
	    }
	}
    }

    if {$execMode != "batch"} {
	destroy $w
    }

    statline "Cleanup completed in [expr ([clock milliseconds] - $t_start)/1000.0] seconds."
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

    set ncpus [lindex [exec sysctl kern.smp.cpus] 1]
    for {set i 0} {$i < $ncpus} {incr i} {
	set inst_pipes($i) [open "| sh" r+]
    }
    set last_inst_pipe 0
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

#****f* exec.tcl/vimageCleanup
# NAME
#   vimageCleanup -- vimage cleanup
# SYNOPSIS
#   vimageCleanup
# FUNCTION
#   Called in special circumstances only. If cleans all the imunes objects
#   from the kernel (vimages and netgraph nodes).
#****
proc vimageCleanup { eid } {
    global .c
    global execMode
    global vroot_unionfs vroot_linprocfs

    #check whether a jail with eid actually exists
    if {[catch {exec jls -v | grep "$eid *ACTIVE"}]} {
	statline "Experiment with eid $eid doesn't exist."
	return
    }

    if {$execMode != "batch"} {
	upvar 0 ::cf::[set ::curcfg]::node_list node_list
	set nodeCount [llength $node_list]
	set count [expr {$nodeCount}]
	set w .termWait
	catch {destroy $w}
	toplevel $w -takefocus 1
	wm transient $w .
	wm title $w "Terminating experiment ..."
	message $w.msg -justify left -aspect 1200 \
	-text "Deleting virtual nodes and links."
	pack $w.msg
	ttk::progressbar $w.p -orient horizontal -length 250 \
	-mode determinate -maximum $count -value $count
	pack $w.p
	update
    }

    statline "Terminating experiment with experiment id: $eid."

    set t_start [clock milliseconds]
    if {[catch {exec jexec $eid jls -v | fgrep ACTIVE | cut -c9-32} res] \
	!= 0 } {
	set res ""
    }
    set vimages [join $res]
    set defindex [lsearch $vimages .]
    set vimages [lreplace $vimages $defindex $defindex]

    if { [lindex [split [exec uname -r] "-"] 0] < 9.0 } {
	# Kill all processes in all vimages
	statline "Terminating processes..."

	set step 0
	set allVimages [ llength $vimages ]
	foreach node $vimages {
	    if {$execMode != "batch"} {
		statline "Terminating processes in vimage $node"
	    }
	    incr step
	    displayBatchProgress $step $allVimages

	    [typemodel $node].shutdown $eid $node
	}

	statline ""
	timeoutPatch $eid $vimages
    }

    statline "Shutting down netgraph nodes..."

    pipesCreate

    # Detach / destroy / reassign interfaces pipe, eiface, iface, bridge
    set i 0
    catch "exec sh -c {jexec $eid ngctl t | grep eiface | awk '{print \$2}'}" maxi
    set res [catch "exec jexec $eid ngctl l"]
    while { $res } {
	#This should never, ever happen.
	if { $i > $maxi } {
	    statline ""
	#    statline "Couldn't terminate all ngeth interfaces. Skipping..."
	    break
	}
	if {[expr {$i%240} == 0]} {
	    if { $execMode == "batch" } {
		puts -nonewline "."
		flush stdout
	    }
	    set res [catch "exec jexec $eid ngctl l"]
	}

	# Attempt to kill hubs & bridges
	set ngnode "n$i"
	if { $ngnode ni $vimages } {
	    pipesExec "jexec $eid ngctl shutdown $ngnode" "hold"
	}
	# Attempt to kill ngeth interfaces
	set ngnode "ngeth$i"
	pipesExec "jexec $eid ngctl shutdown $ngnode:" "hold"
	incr i

	pipesExec ""
    }
    pipesClose

    catch "exec jexec $eid ngctl l | tail -n +2 | grep -v socket" output

    set ngnodes [split $output "
"]

    pipesCreate
    set allNgnodes [llength $ngnodes]
    set step 0
    foreach ngline $ngnodes {
	incr step
	if { $execMode != "batch" } {
	    statline "Shutting down netgraph node $ngline"
	}
	displayBatchProgress $step $allNgnodes
	set ngnode [lindex [eval list $ngline] 1]

	pipesExec "jexec $eid ngctl shutdown $ngnode:"
    }
    pipesClose

    statline ""

    # Shut down all vimages
    if {$vroot_unionfs} {
	set VROOT_BASE /var/imunes
    } else {
	set VROOT_BASE /vroot
    }

    statline "Shutting down vimages..."

    set step 0
    set steps [expr {[llength $vimages]} ]

    pipesCreate
    foreach node $vimages {
	if {$execMode != "batch"} {
	    statline "Shutting down vimage $node"
	    $w.p step -1
	}

	incr step
	displayBatchProgress $step $steps

	pipesExec "jexec $eid.$node kill -9 -1 2> /dev/null" "hold"
	pipesExec "jexec $eid.$node tcpdrop -a 2> /dev/null" "hold"
	pipesExec "for iface in `jexec $eid.$node ifconfig -l`; do jexec $eid.$node ifconfig \$iface destroy; done" "hold"

	set VROOT_RUNTIME $VROOT_BASE/$eid/$node
	set VROOT_RUNTIME_DEV $VROOT_RUNTIME/dev
	pipesExec "umount -f $VROOT_RUNTIME_DEV" "hold"
	if {$vroot_unionfs} {
	    # 1st: unionfs RW overlay
	    pipesExec "umount -f $VROOT_RUNTIME" "hold"
	    # 2nd: nullfs RO loopback
	    pipesExec "umount -f $VROOT_RUNTIME" "hold"
	}
	if {$vroot_linprocfs} {
	    pipesExec "umount -f $VROOT_RUNTIME/compat/linux/proc" "hold"
	}
	pipesExec ""
    }
    pipesClose

    statline ""

    # remeber all vlan interfaces in the experiment to destroy them later
    set vlanlist ""
    catch {exec jexec $eid ifconfig -l} ifclist
    foreach ifc $ifclist {
	if { [string match "*.*" $ifc]} {
	    lappend vlanlist $ifc
	}
    }

    if {$vroot_unionfs} {
	# UNIONFS
	exec jail -r $eid
	exec rm -fr $VROOT_BASE/$eid &
    } else {
	# ZFS
	if {$execMode == "batch"} {
	    exec jail -r $eid
	    exec zfs destroy -fr vroot/$eid
	} else {
	    exec jail -r $eid &
	    exec zfs destroy -fr vroot/$eid &
	
	    catch {exec zfs list | grep -c "$eid"} output
	    set zfsCount [lindex [split $output] 0]

	    while {$zfsCount != 0} {
		catch {exec zfs list | grep -c "$eid/"} output
		set zfsCount [lindex [split $output] 0]
		$w.p configure -value $zfsCount
		update
		after 200
	    }
	}
    }

    foreach ifc $vlanlist {
	catch {exec ifconfig $ifc destroy}
    }

    if {$execMode != "batch"} {
	destroy $w
    }

    statline "Cleanup completed in [expr ([clock milliseconds] - $t_start)/1000.0] seconds."
}

#****f* exec.tcl/timeoutPatch
# NAME
#   timeoutPatch -- timeout patch
# SYNOPSIS
#   timeoutPatch $eid $vimages
# FUNCTION
#   Timeout patch that is applied for hanging TCP connections. We need to wait
#   for TCP connections to close regularly because we can't terminate them in
#   FreeBSD 8. In FreeBSD that should be possible with the tcpdrop command.
# INPUTS
#   * eid -- experiment ID
#   * vimages -- list of current vimages
#****
proc timeoutPatch { eid vimages } {
    global execMode
    set vrti 1
    set sec 60

    if { [lindex [split [exec uname -r] "-"] 0] >= 9.0 } {
	return
    }

    set timeoutNeeded 0
    foreach vimage $vimages {
	if { [catch {exec jexec $eid.$vimage netstat -an -f inet | fgrep "WAIT"} odg] == 0} {
	    set timeoutNeeded 1
	    break
	}
    }

    if { $timeoutNeeded == 0 } {
	return
    }

    if { $execMode == "batch" } {
        puts "We must wait for TIME_WAIT expiration on virtual nodes (up to 60 sec). "
        puts "Please don't try killing the process."
    } else {
        set w .timewait
        catch {destroy $w}
        toplevel $w -takefocus 1
        wm transient $w .
        wm title $w "Please wait ..."
        message $w.msg -justify left -aspect 1200 \
         -text "We must wait for TIME_WAIT expiration on virtual nodes (up to 60 sec).
Please don't try killing the process.
(countdown on status line)"
       pack $w.msg
	ttk::progressbar $w.p -orient horizontal -length 350 \
	-mode determinate -maximum $sec -value $sec
        pack $w.p
        update
        grab $w
    }

    while { $vrti == 1 } {
        set vrti 0
        foreach vimage $vimages {
            # puts "vimage $vimage...\n"
            while { [catch {exec jexec $eid.$vimage netstat -an -f inet | fgrep "WAIT"} odg] == 0} {
                set vrti 1
                # puts "vimage $vimage: \n$odg\n"
                after 1000
                set sec [expr $sec - 1]
                if { $execMode == "batch" } {
                    puts -nonewline "."
                    flush stdout
                } else {
                    statline "~ $sec seconds ..."
		    $w.p step -1
                    update
                }
            }
        }
    }
    if { $execMode != "batch" } {
        destroy .timewait
    }
    statline ""
}

#****f* exec.tcl/execSetIfcQDisc
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
	FIFO { set qdisc fifo }
	WFQ { set qdisc wfq }
	DRR { set qdisc drr }
    }
    set ngnode "$lnode1-$lnode2"
    if { [catch { exec jexec $eid ngctl msg $ngnode: setcfg "{ $dir={ $qdisc=1 } }" }] } {
	set ngnode "$lnode2-$lnode1"
	exec jexec $eid ngctl msg $ngnode: setcfg "{ $dir={ $qdisc=1 } }"
    }
}

#****f* exec.tcl/execSetIfcQDrop
# NAME
#   execSetIfcQDrop -- in exec mode set interface queue drop
# SYNOPSIS
#   execSetIfcQDrop $eid $node $ifc $qdrop
# FUNCTION
#   Sets the queue dropping policy during the simulation.
#   New queue dropping policy is defined in qdrop parameter.
#   Queue dropping policy can be set to drop-head or drop-tail.
# INPUTS
#   eid -- experiment id
#   node -- node id
#   ifc -- interface name
#   qdrop -- queue dropping policy
#****
proc execSetIfcQDrop { eid node ifc qdrop } {
    set target [linkByIfc $node $ifc]
    set peers [linkPeers [lindex $target 0]]
    set dir [lindex $target 1]
    set lnode1 [lindex $peers 0]
    set lnode2 [lindex $peers 1]
    if { [nodeType $lnode2] == "pseudo" } {
	set mirror_link [getLinkMirror [lindex $target 0]]
	set lnode2 [lindex [linkPeers $mirror_link] 0]
    }
    switch -exact $qdrop {
	drop-head { set qdrop drophead }
	drop-tail { set qdrop droptail }
    }
    set ngnode "$lnode1-$lnode2"
    if { [catch { exec jexec $eid ngctl msg $ngnode: setcfg "{ $dir={ $qdrop=1 } }" }] } {
	# XXX dir should be reversed!
	set ngnode "$lnode2-$lnode1"
	exec jexec $eid ngctl msg $ngnode: setcfg "{ $dir={ $qdrop=1 } }"
    }
}

#****f* exec.tcl/execSetIfcQLen
# NAME
#   execSetIfcQLen -- in exec mode set interface queue length
# SYNOPSIS
#   execSetIfcQDrop $eid $node $ifc $qlen
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
    set target [linkByIfc $node $ifc]
    set peers [linkPeers [lindex $target 0]]
    set dir [lindex $target 1]
    set lnode1 [lindex $peers 0]
    set lnode2 [lindex $peers 1]
    if { [nodeType $lnode2] == "pseudo" } {
	set mirror_link [getLinkMirror [lindex $target 0]]
	set lnode2 [lindex [linkPeers $mirror_link] 0]
    }
    set ngnode "$lnode1-$lnode2"
    if { $qlen == 0 } {
	set qlen -1
    }
    if { [catch { exec jexec $eid ngctl msg $ngnode: setcfg "{ $dir={ queuelen=$qlen } }" }] } {
	set ngnode "$lnode2-$lnode1"
	exec jexec $eid ngctl msg $ngnode: setcfg "{ $dir={ queuelen=$qlen } }"
    }
}

#****f* exec.tcl/execSetLinkParams
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
    set lname $lnode1-$lnode2

    set bandwidth [expr [getLinkBandwidth $link] + 0]
    set delay [expr [getLinkDelay $link] + 0]
    set ber [expr [getLinkBER $link] + 0]
    set dup [expr [getLinkDup $link] + 0]

    if { $bandwidth == 0 } {
	set bandwidth -1
    }
    if { $delay == 0 } {
	set delay -1
    }
    if { $ber == 0 } {
	set ber -1
    }
    if { $dup == 0 } {
	set dup -1
    }

    catch {exec jexec $eid ngctl msg $lname: setcfg \
	"{ bandwidth=$bandwidth delay=$delay \
	upstream={ BER=$ber duplicate=$dup } \
	downstream={ BER=$ber duplicate=$dup } }"} err
    if { $debug && $err != "" } {
	puts $err
    }
}

#****f* exec.tcl/execSetLinkJitter
# NAME
#   execSetLinkJitter -- in exec mode set link jitter
# SYNOPSIS
#   execSetLinkJitter $eid $link
# FUNCTION
#   Sets the link jitter parameters during the simulation.
#   All the parameters are set at the same time.
# INPUTS
#   eid -- experiment id
#   link -- link id
#****
proc execSetLinkJitter { eid link } {
    set lnode1 [lindex [linkPeers $link] 0]
    set lnode2 [lindex [linkPeers $link] 1]
    set lname $lnode1-$lnode2

    set jitter_up [getLinkJitterUpstream $link]
    set jitter_mode_up [getLinkJitterModeUpstream $link]
    set jitter_hold_up [expr [getLinkJitterHoldUpstream $link] + 0]

    set jitter_down [getLinkJitterDownstream $link]
    set jitter_mode_down [getLinkJitterModeDownstream $link]
    set jitter_hold_down [expr [getLinkJitterHoldDownstream $link] + 0]

    if {$jitter_mode_up in {"sequential" ""}} {
	set jit_mode_up 1
    } else {
	set jit_mode_up 2
    }

    if {$jitter_mode_down in {"sequential" ""}} {
	set jit_mode_down 1
    } else {
	set jit_mode_down 2
    }

    set exec_pipe [open "| jexec $eid ngctl -f -" r+]

    if {$jitter_up != ""} {
	puts $exec_pipe "msg $lname: setcfg {upstream={jitmode=-1}}"
	foreach val $jitter_up {
	    puts $exec_pipe "msg $lname: setcfg {upstream={addjitter=[expr round($val*1000)]}}"
	}
	puts $exec_pipe "msg $lname: setcfg {upstream={jitmode=$jit_mode_up}}"
	puts $exec_pipe "msg $lname: setcfg {upstream={jithold=[expr round($jitter_hold_up*1000)]}}"
    }

    if {$jitter_down != ""} {
	puts $exec_pipe "msg $lname: setcfg {downstream={jitmode=-1}}"
	foreach val $jitter_down {
	    puts $exec_pipe "msg $lname: setcfg {downstream={addjitter=[expr round($val*1000)]}}"
	}
	puts $exec_pipe "msg $lname: setcfg {downstream={jitmode=$jit_mode_down}}"
	puts $exec_pipe "msg $lname: setcfg {downstream={jithold=[expr round($jitter_hold_down*1000)]}}"
    }

    close $exec_pipe
}

#****f* exec.tcl/execResetLinkJitter
# NAME
#   execResetLinkJitter -- in exec mode reset link jitter
# SYNOPSIS
#   execResetLinkJitter $eid $link
# FUNCTION
#   Resets the link jitter parameters to defaults during the simulation.
#   All the parameters are set at the same time.
# INPUTS
#   * eid -- experiment id
#   * link -- link id
#****
proc execResetLinkJitter { eid link } {
    set lnode1 [lindex [linkPeers $link] 0]
    set lnode2 [lindex [linkPeers $link] 1]
    set lname $lnode1-$lnode2

    exec jexec $eid ngctl msg $lname: setcfg \
	"{upstream={jitmode=-1} downstream={jitmode=-1}}"
}

