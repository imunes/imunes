#****h* imunes/runtime/services.tcl
# NAME
#  services.tcl -- file used for defining services that start on virtual node
#  at a specific point in the experiment startup process and are stopped at a
#  certain point of experiment termination. These points are defined as hooks
#  in the exec.tcl file within the deployCfg and terminateAllNodes procedures.
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
proc services { action hook args } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    global services$hook

    set iterlist $node_list
    if { $args != "" } {
	set iterlist $args
    }

    set servlist [set services$hook]
    foreach node $iterlist {
        set nodeserv [getNodeServices $node]
        foreach nserv $nodeserv {
            if { $nserv in $servlist } {
                $nserv.$action $node
            }
        }
    }
}

######################################################################
#
# SSH service
#
set service ssh
# register for hooks and globally
regHooks $service {NODECONF NODESTOP}

proc $service.start { node } {
    set output [execCmdsNode $node [sshServiceStartCmds]]
    writeDataToNodeFile $node "ssh_service.log" $output
}

proc $service.stop { node } {
    set output [execCmdsNode $node [sshServiceStopCmds]]
    writeDataToNodeFile $node "ssh_service.log" $output
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
if { $isOSlinux } {
    regHooks $service {LINKINST NODESTOP}
} else {
    regHooks $service {NODEINST NODESTOP}
}

proc $service.start { node } {
    foreach ifc [allIfcList $node] {
	if { [string match "lo*" $ifc] } {
	    continue
	}
	lappend cmds "ifconfig $ifc up"
	lappend cmds "nohup tcpdump -Uni $ifc -w /tmp/$ifc.pcap > /dev/null 2> /dev/null &"
    }
    
    set output [execCmdsNode $node $cmds]
    writeDataToNodeFile $node "tcpdump_start.log" $output
}

proc $service.stop { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    lappend cmds "pkill tcpdump"
    
    set output [execCmdsNode $node $cmds]
    writeDataToNodeFile $node "tcpdump_stop.log" $output

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
proc inetd.start { service node } {
    lappend cmds "sed -i -e \"s/#$service/$service/\" /etc/inetd.conf"
    lappend cmds [inetdServiceRestartCmds]

    set output [execCmdsNode $node $cmds]
    writeDataToNodeFile $node "$service\_start.log" $output
}

proc inetd.stop { service node } {
    lappend cmds "sed -i -e \"s/$service/#$service/\" /etc/inetd.conf"
    lappend cmds [inetdServiceRestartCmds]

    set output [execCmdsNode $node $cmds]
    writeDataToNodeFile $node "$service\_stop.log" $output
}

######################################################################
#
# ftp inetd service
#
set service ftp
regHooks $service {NODECONF NODESTOP}

proc $service.start { node } {
    global service
    inetd.start ftp $node
}

proc $service.stop { node } {
    inetd.stop ftp $node
}

proc $service.restart { node } {
    global service
    inetd.stop ftp $node
    inetd.start ftp $node
}
######################################################################

######################################################################
#
# telnet inetd service
#
set service telnet
regHooks $service {NODECONF NODESTOP}

proc $service.start { node } {
    global service
    inetd.start telnet $node
}

proc $service.stop { node } {
    inetd.stop telnet $node
}

proc $service.restart { node } {
    global service
    inetd.stop telnet $node
    inetd.start telnet $node
}
######################################################################

######################################################################
#
# ipsec service
#
set service ipsec
regHooks $service {NODECONF NODESTOP}

proc $service.start { node } {
    l3node.ipsecInit $node
    set output [execCmdNode $node "ipsec start"]
    writeDataToNodeFile $node "ipsec_service.log" $output
}

proc $service.stop { node } {
    set output [execCmdNode $node "ipsec stop"]
    writeDataToNodeFile $node "ipsec_service.log" $output
}

proc $service.restart { node } {
    set output [execCmdNode $node "ipsec restart"]
    writeDataToNodeFile $node "ipsec_service.log" $output
}
######################################################################
