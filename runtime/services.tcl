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
    global services$hook

    set iterlist [getFromRunning "node_list"]
    if { $args != "" && $args != "*" } {
	set iterlist {*}$args
    }

    set servlist [set services$hook]
    pipesCreate
    foreach node_id $iterlist {
        set nodeserv [getNodeServices $node_id]
        foreach nserv $nodeserv {
            if { $nserv in $servlist } {
                $nserv.$action $node_id $bkg
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

proc $service.start { node_id { bkg "" } } {
    if { $bkg == "" } {
	set output [execCmdsNode $node_id [sshServiceStartCmds]]
	writeDataToNodeFile $node_id "ssh_service.log" $output
    } else {
	execCmdsNodeBkg $node_id [sshServiceStartCmds] "ssh_service.log 2>&1"
    }
}

proc $service.stop { node_id { bkg "" } } {
    if { $bkg == "" } {
	set output [execCmdsNode $node_id [sshServiceStopCmds]]
	writeDataToNodeFile $node_id "ssh_service.log" $output
    } else {
	execCmdsNodeBkg $node_id [sshServiceStopCmds] "ssh_service.log 2>&1"
    }
}

proc $service.restart { node_id } {
    ssh.stop $node_id
    ssh.start $node_id
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

proc $service.start { node_id { bkg "" } } {
    foreach iface_id [allIfcList $node_id] {
	set iface_name [getIfcName $node_id $iface_id]
	if { [string match "lo*" $iface_name] } {
	    continue
	}
	lappend cmds "ifconfig $iface_name up"
	lappend cmds "nohup tcpdump -Uni $iface_name -w /tmp/$iface_name.pcap > /dev/null 2> /dev/null &"
    }

    if { $bkg == "" } {
	set output [execCmdsNode $node_id $cmds]
	writeDataToNodeFile $node_id "tcpdump_start.log" $output
    } else {
	execCmdsNodeBkg $node_id $cmds "tcpdump_start.log 2>&1"
    }
}

proc $service.stop { node_id { bkg "" } } {
    lappend cmds "pkill tcpdump"

    if { $bkg == "" } {
	set output [execCmdsNode $node_id $cmds]
	writeDataToNodeFile $node_id "tcpdump_stop.log" $output
    } else {
	execCmdsNodeBkg $node_id $cmds "tcpdump_stop.log 2>&1"
    }

    set ext_dir /tmp/[getFromRunning "eid"]/
    file mkdir $ext_dir
    foreach iface_id [allIfcList $node_id] {
	set iface_name [getIfcName $node_id $iface_id]
	if { [string match "lo*" $iface_name] } {
	    continue
	}
	moveFileFromNode $node_id /tmp/$iface_name.pcap $ext_dir/[getNodeName $node_id]\_$node_id\_$iface_name.pcap
    }
}

proc $service.restart { node_id } {
    tcpdump.stop $node_id
    tcpdump.start $node_id
}
######################################################################

######################################################################
#
# inetd services helper functions
#
proc inetd.start { service node_id insecure { bkg "" } } {
    if { $insecure } {
	lappend cmds "sed -i -e \"s/^#<off># $service/$service/\" /etc/inetd.conf"
    } else {
	lappend cmds "sed -i -e \"s/^#$service/$service/\" /etc/inetd.conf"
    }

    lappend cmds [inetdServiceRestartCmds]

    if { $bkg == "" } {
	set output [execCmdsNode $node_id $cmds]
	writeDataToNodeFile $node_id "$service\_start.log" $output
    } else {
	execCmdsNodeBkg $node_id $cmds "$service\_start.log"
    }
}

proc inetd.stop { service node_id insecure { bkg "" } } {
    if { $insecure } {
	lappend cmds "sed -i -e \"s/^$service/#<off># $service/\" /etc/inetd.conf"
    } else {
	lappend cmds "sed -i -e \"s/^$service/#$service/\" /etc/inetd.conf"
    }

    lappend cmds [inetdServiceRestartCmds]

    if { $bkg == "" } {
	set output [execCmdsNode $node_id $cmds]
	writeDataToNodeFile $node_id "$service\_stop.log" $output
    } else {
	execCmdsNodeBkg $node_id $cmds "$service\_stop.log"
    }
}

######################################################################
#
# ftp inetd service
#
set service ftp
regHooks $service {NODECONF NODESTOP}

proc $service.start { node_id { bkg "" } } {
    global service
    inetd.start ftp $node_id false $bkg
}

proc $service.stop { node_id { bkg "" } } {
    inetd.stop ftp $node_id false $bkg
}

proc $service.restart { node_id } {
    global service
    inetd.stop ftp $node_id false
    inetd.start ftp $node_id false
}
######################################################################

######################################################################
#
# telnet inetd service
#
set service telnet
regHooks $service {NODECONF NODESTOP}

proc $service.start { node_id { bkg "" } } {
    global service isOSlinux
    inetd.start telnet $node_id $isOSlinux $bkg
}

proc $service.stop { node_id { bkg "" } } {
    global isOSlinux
    inetd.stop telnet $node_id $isOSlinux $bkg
}

proc $service.restart { node_id } {
    global service isOSlinux
    inetd.stop telnet $node_id $isOSlinux
    inetd.start telnet $node_id $isOSlinux
}
######################################################################

######################################################################
#
# ipsec service
#
set service ipsec
regHooks $service {NODECONF NODESTOP}

proc $service.start { node_id { bkg "" } } {
    nodeIpsecInit $node_id
    if { $bkg == "" } {
	set output [execCmdNode $node_id "ipsec start"]
	writeDataToNodeFile $node_id "ipsec_service.log" $output
    } else {
	execCmdNodeBkg $node_id "ipsec start >> ipsec_service.log"
    }
}

proc $service.stop { node_id { bkg "" } } {
    if { $bkg == "" } {
	set output [execCmdNode $node_id "ipsec stop"]
	writeDataToNodeFile $node_id "ipsec_service.log" $output
    } else {
	execCmdNodeBkg $node_id "ipsec stop >> ipsec_service.log"
    }
}

proc $service.restart { node_id } {
    set output [execCmdNode $node_id "ipsec restart"]
    writeDataToNodeFile $node_id "ipsec_service.log" $output
}
######################################################################
