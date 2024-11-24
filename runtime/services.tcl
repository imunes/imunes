#****h* imunes/runtime/services.tcl
# NAME
#  services.tcl -- file used for defining services that start on virtual node
#  at a specific point in the experiment startup process and are stopped at a
#  certain point of experiment termination. These points are defined as hooks
#  in the exec.tcl file within the deployCfg and undeployCfg procedures.
# FUNCTION
#  This module is used to setup default variables an procedures for service
#  management. After that specific services are defined along with their
#  startup commands.
#****

#
# Define global variable that will hold the list of all services, to enable
# dynamic loading of services into the gui.
#
global all_services_list
set all_services_list ""

#
# Define 6 global variables (one for each hook). The following hooks are
# defined in the startup and termination process:
# * experiment startup hooks:
#   - NODEINST - after all nodes are created
#   - LINKINST - after all links are created
#   - NODECONF - after all nodes are configured
# * experiment termination hooks:
#   - NODESTOP - before all nodes are stopped
#   - LINKDEST - before all links are destroyed
#   - NODEDEST - before all nodes are destroyed
# 
# These global variables are filled with the list of services that are started
# on the specific hook.
#
foreach type { NODEINST LINKINST NODECONF NODESTOP LINKDEST NODEDEST } {
    global services$type
    set services$type ""
}

#****f* services.tcl/regService
# NAME
#   regService -- register service globally inside the system
# SYNOPSIS
#   regService $service $hooks
# FUNCTION
#   Register service in the system to enable for dynamic loading of services
#   into the gui.
# INPUTS
#   * service -- service name
#****
proc regService { service } {
    global all_services_list
    lappend all_services_list $service
}

#****f* services.tcl/regHooks
# NAME
#   regHooks -- register service for certain startup or termination hooks
# SYNOPSIS
#   regHooks $service $hooks
# FUNCTION
#   Append the service to the appropriate global hook variable. This is called
#   upon definition of a new service in this file.
# INPUTS
#   * service -- service name
#   * hooks -- hooks to register for
#****
proc regHooks { service hooks } {
    foreach hook $hooks {
	global services$hook
	lappend services$hook $service
    }
    # register service here
    regService $service
}

#****f* services.tcl/service
# NAME
#   service -- executes the appropriate service action for the defined hook
# SYNOPSIS
#   service $action $hook
# FUNCTION
#   Search for all the services in the appropriate hook variable and execute
#   the service for all nodes that have that service enabled.
# INPUTS
#   * action -- action to perform, can be start, stop or restart
#   * hooks -- hooks for which the service is executed
#****
proc services { action hook bkg args } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    global services$hook

    set iterlist $node_list
    if { $args != "" && $args != "*" } {
	set iterlist {*}$args
    }

    set servlist [set services$hook]
    pipesCreate
    foreach node $iterlist {
        set nodeserv [getNodeServices $node]
        foreach nserv $nodeserv {
            if { $nserv in $servlist } {
                $nserv.$action $node $bkg
            }
        }
    }
    pipesClose
}

######################################################################
#
# SSH service
#
set service ssh
# register for hooks and globally
regHooks $service {NODECONF NODESTOP}

proc $service.start { node { bkg "" } } {
    if { $bkg == "" } {
	set output [execCmdsNode $node [sshServiceStartCmds]]
	writeDataToNodeFile $node "ssh_service.log" $output
    } else {
	execCmdsNodeBkg $node [sshServiceStartCmds] "ssh_service.log 2>&1"
    }
}

proc $service.stop { node { bkg "" } } {
    if { $bkg == "" } {
	set output [execCmdsNode $node [sshServiceStopCmds]]
	writeDataToNodeFile $node "ssh_service.log" $output
    } else {
	execCmdsNodeBkg $node [sshServiceStopCmds] "ssh_service.log 2>&1"
    }
}

proc $service.restart { node } {
    ssh.stop $node    
    ssh.start $node    
}
#
######################################################################

######################################################################
#
# tcpdump service
#
set service tcpdump
# register for hooks and globally
regHooks $service {LINKINST NODESTOP}

proc $service.start { node { bkg "" } } {
    foreach ifc [allIfcList $node] {
	if { [string match "lo*" $ifc] } {
	    continue
	}
	lappend cmds "ifconfig $ifc up"
	lappend cmds "nohup tcpdump -Uni $ifc -w /tmp/$ifc.pcap > /dev/null 2> /dev/null &"
    }
    
    if { $bkg == "" } {
	set output [execCmdsNode $node $cmds]
	writeDataToNodeFile $node "tcpdump_start.log" $output
    } else {
	execCmdsNodeBkg $node $cmds "tcpdump_start.log 2>&1"
    }
}

proc $service.stop { node { bkg "" } } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    lappend cmds "pkill tcpdump"
    
    if { $bkg == "" } {
	set output [execCmdsNode $node $cmds]
	writeDataToNodeFile $node "tcpdump_stop.log" $output
    } else {
	execCmdsNodeBkg $node $cmds "tcpdump_stop.log 2>&1"
    }

    set ext_dir /tmp/$eid/
    file mkdir $ext_dir
    foreach ifc [allIfcList $node] {
	if { [string match "lo*" $ifc] } {
	    continue
	}
	moveFileFromNode $node /tmp/$ifc.pcap $ext_dir/[getNodeName $node]\_$node\_$ifc.pcap
    }
}

proc $service.restart { node } {
    tcpdump.stop $node
    tcpdump.start $node
}
######################################################################

######################################################################
#
# inetd services helper functions
#
proc inetd.start { service node insecure { bkg "" } } {
    if { $insecure } {
	lappend cmds "sed -i -e \"s/^#<off># $service/$service/\" /etc/inetd.conf"
    } else {
	lappend cmds "sed -i -e \"s/^#$service/$service/\" /etc/inetd.conf"
    }

    lappend cmds [inetdServiceRestartCmds]

    if { $bkg == "" } {
	set output [execCmdsNode $node $cmds]
	writeDataToNodeFile $node "$service\_start.log" $output
    } else {
	execCmdsNodeBkg $node $cmds "$service\_start.log"
    }
}

proc inetd.stop { service node insecure { bkg "" } } {
    if { $insecure } {
	lappend cmds "sed -i -e \"s/^$service/#<off># $service/\" /etc/inetd.conf"
    } else {
	lappend cmds "sed -i -e \"s/^$service/#$service/\" /etc/inetd.conf"
    }

    lappend cmds [inetdServiceRestartCmds]

    if { $bkg == "" } {
	set output [execCmdsNode $node $cmds]
	writeDataToNodeFile $node "$service\_stop.log" $output
    } else {
	execCmdsNodeBkg $node $cmds "$service\_stop.log"
    }
}

######################################################################
#
# ftp inetd service
#
set service ftp
regHooks $service {NODECONF NODESTOP}

proc $service.start { node { bkg "" } } {
    global service
    inetd.start ftp $node false $bkg
}

proc $service.stop { node { bkg "" } } {
    inetd.stop ftp $node false $bkg
}

proc $service.restart { node } {
    global service
    inetd.stop ftp $node false
    inetd.start ftp $node false
}
######################################################################

######################################################################
#
# telnet inetd service
#
set service telnet
regHooks $service {NODECONF NODESTOP}

proc $service.start { node { bkg "" } } {
    global service isOSlinux
    inetd.start telnet $node $isOSlinux $bkg
}

proc $service.stop { node { bkg "" } } {
    global isOSlinux
    inetd.stop telnet $node $isOSlinux $bkg
}

proc $service.restart { node } {
    global service isOSlinux
    inetd.stop telnet $node $isOSlinux
    inetd.start telnet $node $isOSlinux
}
######################################################################

######################################################################
#
# ipsec service
#
set service ipsec
regHooks $service {NODECONF NODESTOP}

proc $service.start { node { bkg "" } } {
    nodeIpsecInit $node
    if { $bkg == "" } {
	set output [execCmdNode $node "ipsec start"]
	writeDataToNodeFile $node "ipsec_service.log" $output
    } else {
	execCmdNodeBkg $node "ipsec start >> ipsec_service.log"
    }
}

proc $service.stop { node { bkg "" } } {
    if { $bkg == "" } {
	set output [execCmdNode $node "ipsec stop"]
	writeDataToNodeFile $node "ipsec_service.log" $output
    } else {
	execCmdNodeBkg $node "ipsec stop >> ipsec_service.log"
    }
}

proc $service.restart { node } {
    set output [execCmdNode $node "ipsec restart"]
    writeDataToNodeFile $node "ipsec_service.log" $output
}
######################################################################
