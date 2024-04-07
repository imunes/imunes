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
    global execMode isOSlinux

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

	    if { $isOSlinux } {
		try {
		    exec test -d /sys/class/net/$name/wireless
		} on error {} {
		} on ok {} {
		    set link [lindex [linkByIfc $node 0] 0]
		    if { [getLinkDirect $link] } {
			after idle {.dialog1.msg configure -wraplength 4i}
			tk_dialog .dialog1 "IMUNES warning" "Interface '$name' is\
			    a wireless interface, so its peer cannot change its MAC\
			    address in this mode!" \
			    info 0 Dismiss
		    } else {
			after idle {.dialog1.msg configure -wraplength 4i}
			tk_dialog .dialog1 "IMUNES error" "Namespace of wireless\
			    interface '$name' cannot be changed, use 'Direct link'\
			    to connect to this interface!" \
			    info 0 Dismiss

			return 1
		    }
		}
	    }
	}
    }
    return 0
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

#****f* freebsd.tcl/l3node.nghook
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
    switch -exact [string trim $ifc 0123456789] {
	wlan -
	ext -
	eth {
	    return [list $node-$ifc ether]
	}
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

proc l3node.createIfcs { eid node ifcs } {
    createNodePhysIfcs $node $ifcs
}

proc l2node.createIfcs { eid node ifcs } {
    createNodePhysIfcs $node $ifcs
}

#****f* exec.tcl/l3node.setupNamespace
# NAME
#   l3node.setupNamespace -- layer 3 node setupNamespace
# SYNOPSIS
#   l3node.setupNamespace $eid $node
# FUNCTION
#   Linux only. Attaches the existing Docker netns to a new one.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc l3node.setupNamespace { eid node } {
    attachToL3NodeNamespace $node
}

#****f* exec.tcl/l3node.initConfigure
# NAME
#   l3node.initConfigure -- layer 3 node initConfigure
# SYNOPSIS
#   l3node.initConfigure $eid $node
# FUNCTION
#   Runs initial L3 configuration, such as creating logical interfaces and
#   configuring sysctls.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc l3node.initConfigure { eid node } {
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

#****f* exec.tcl/l2node.setupNamespace
# NAME
#   l2node.setupNamespace -- layer 2 node setupNamespace
# SYNOPSIS
#   l2node.setupNamespace $eid $node
# FUNCTION
#   Linux only. Creates a new netns.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc l2node.setupNamespace { eid node } {
    createNamespace $eid-$node
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
    set maxProgressbasCount [expr {5*$allNodeCount + 1*$l2nodeCount + 5*$l3nodeCount + 2*$linkCount}]

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
	statline "Instantiating L3 nodes..."
	pipesCreate
	instantiateNodes $l3nodes $l3nodeCount $w
	statline "Waiting for $l3nodeCount L3 node(s) to start..."
	waitForInstantiateNodes $l3nodes $l3nodeCount $w
	pipesClose

	statline "Setting up namespaces for all nodes..."
	pipesCreate
	setupNodeNamespaces $allNodes $allNodeCount $w
	statline "Waiting on namespaces for $allNodeCount node(s)..."
	waitForNamespaces $allNodes $allNodeCount $w
	pipesClose

	statline "Starting initial configuration on L3 nodes..."
	pipesCreate
	initConfigureNodes $l3nodes $l3nodeCount $w
	statline "Waiting for initial configuration on $l3nodeCount L3 node(s)..."
	waitForInitConf $l3nodes $l3nodeCount $w
	pipesClose

	statline "Instantiating L2 nodes..."
	pipesCreate
	instantiateNodes $l2nodes $l2nodeCount $w
	statline "Waiting for $l2nodeCount L2 node(s) to start..."
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
    createExperimentFiles $eid
}

proc instantiateNodes { nodes nodeCount w } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global progressbarCount execMode

    set batchStep 0
    foreach node $nodes {
	displayBatchProgress $batchStep $nodeCount

	if { [info procs [typemodel $node].instantiate] != "" } {
	    try {
		[typemodel $node].instantiate $eid $node
	    } on error err {
		return -code error "Error in '[typemodel $node].instantiate $eid $node': $err"
	    }
	    pipesExec ""
	}

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

proc setupNodeNamespaces { nodes nodeCount w } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global progressbarCount execMode

    set batchStep 0
    foreach node $nodes {
	displayBatchProgress $batchStep $nodeCount

	if { [info procs [typemodel $node].setupNamespace] != "" } {
	    try {
		[typemodel $node].setupNamespace $eid $node
	    } on error err {
		return -code error "Error in '[typemodel $node].setupNamespace $eid $node': $err"
	    }
	    pipesExec ""
	}

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

proc initConfigureNodes { nodes nodeCount w } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global progressbarCount execMode

    set batchStep 0
    foreach node $nodes {
	displayBatchProgress $batchStep $nodeCount

	try {
	    [typemodel $node].initConfigure $eid $node
	} on error err {
	    return -code error "Error in '[typemodel $node].initConfigure $eid $node': $err"
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

	if {[info procs [typemodel $node].createIfcs] != ""} {
	    set ifcs [ifcList $node]
	    try {
		[typemodel $node].createIfcs $eid $node $ifcs
	    } on error err {
		return -code error "Error in '[typemodel $node].createIfcs $eid $node $ifcs': $err"
	    }
	    pipesExec ""
	}

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
	    if { [getLinkDirect $link] || [nodeType $lnode1] == "wlan" || [nodeType $lnode2] == "wlan" } {
		createDirectLinkBetween $lnode1 $lnode2 $ifname1 $ifname2
	    } else {
		createLinkBetween $lnode1 $lnode2 $ifname1 $ifname2 $link
	    }
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

