#
# Copyright 2005-2010 University of Zagreb, Croatia.
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
# This work was supported in part by Croatian Ministry of Science
# and Technology through the research contract #IP-2003-143.
#

#****h* imunes/packgen.tcl
# NAME
#  packgen.tcl -- defines packgen.specific procedures
# FUNCTION
#  This module is used to define all the packgen.specific procedures.
# NOTES
#  Procedures in this module start with the keyword packgen and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE packgen
registerModule $MODULE "freebsd"

namespace eval $MODULE {
	# Define all node-specific procedures. All non-defined procedures will call
	# genericL2.* procedure from nodes/generic_l2.tcl
	namespace import ::genericL2::*
	namespace export *

	################################################################################
	########################### CONFIGURATION PROCEDURES ###########################
	################################################################################

	proc namingBase {} {
		return "packgen"
	}

	#****f* packgen.tcl/packgen.maxIfaces
	# NAME
	#   packgen.maxIfaces -- maximum number of links
	# SYNOPSIS
	#   packgen.maxIfaces
	# FUNCTION
	#   Returns packgen maximum number of links.
	# RESULT
	#   * maximum number of links.
	#****
	proc maxIfaces {} {
		return 1
	}

	proc getHookData { node_id iface_id } {
		global isOSlinux isOSfreebsd

		# FreeBSD - stolen interface name of the node (attached to netgraph node in EID jail)
		set private_elem [getIfcName $node_id $iface_id]

		# name of public netgraph peer
		set public_elem $node_id

		# FreeBSD - hook for connecting to netgraph node
		set hook_name "output"

		return [list $private_elem $public_elem $hook_name]
	}

	################################################################################
	############################ INSTANTIATE PROCEDURES ############################
	################################################################################

	proc prepareSystem {} {
		catch { rexec kldload ng_source }
	}

	#****f* packgen.tcl/packgen.nodeCreate
	# NAME
	#   packgen.nodeCreate
	# SYNOPSIS
	#   packgen.nodeCreate $eid $node_id
	# FUNCTION
	#   Procedure packgen.nodeCreate creates a new virtual node
	#   with all the interfaces and CPU parameters as defined
	#   in imunes.
	# INPUTS
	#   * eid - experiment id
	#   * node_id - id of the node
	#****
	proc nodeCreate { eid node_id } {
		addStateNode $node_id "node_creating"

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

		pipesExec "printf \"
		mkpeer . source inhook input \n
		msg .inhook setpersistent \n name .:inhook $node_id
		\" | jexec $private_ns ngctl -f -" "hold"
	}

	proc nodePhysIfacesCreate { eid node_id ifaces } {
		foreach iface_id $ifaces {
			if { [getIfcLink $node_id $iface_id] == "" } {
				removeStateNodeIface $node_id $iface_id "running"

				continue
			}

			setStateNodeIface $node_id $iface_id "running"
		}
	}

	proc nodePhysIfacesDirectCreate { eid node_id ifaces } {
		return [invokeNodeProc $node_id "nodePhysIfacesCreate" $eid $node_id $ifaces]
	}

	#****f* packgen.tcl/packgen.nodeConfigure
	# NAME
	#   packgen.nodeConfigure
	# SYNOPSIS
	#   packgen.nodeConfigure $eid $node_id
	# FUNCTION
	#   Starts a new packgen. The node can be started if it is instantiated.
	# INPUTS
	#   * eid - experiment id
	#   * node_id - id of the node
	#****
	proc nodeConfigure { eid node_id } {
		global remote rcmd

		set ifaces [ifcList $node_id]
		foreach iface_id $ifaces {
			if { ! [isRunningNodeIface $node_id $iface_id] } {
				set ifaces [removeFromList $ifaces $iface_id]
			}
		}

		if { $ifaces == {} } {
			return
		}

		set cmd ""
		if { $remote != "" } {
			set cmd $rcmd
		}

		addStateNode $node_id "node_configuring"

		foreach packet [packgenPackets $node_id] {
			set fd [open "| $cmd jexec $eid nghook $node_id: input" w]
			fconfigure $fd -encoding binary

			set pdata [getPackgenPacketData $node_id [lindex $packet 0]]
			set bin [binary format H* $pdata]
			puts -nonewline $fd $bin

			catch { close $fd }
		}

		set pps [getPackgenPacketRate $node_id]

		pipesExec "jexec $eid ngctl msg $node_id: setpps $pps" "hold"

		# don't start traffic without a link
		if { [getIfcLink $node_id [lindex $ifaces 0]] != "" } {
			pipesExec "jexec $eid ngctl msg $node_id: start [expr 2**63]" "hold"
		}
	}

	proc nodeConfigure_check { eid node_id } {
		global isOSlinux isOSfreebsd

		set iface_id [lindex [ifcList $node_id] 0]

		# ignore ifaces without a link
		if { [getIfcLink $node_id $iface_id] == "" } {
			return true
		}

		set has_data 0
		foreach packet [packgenPackets $node_id] {
			set pdata [getPackgenPacketData $node_id [lindex $packet 0]]
			if { $pdata != "" } {
				set has_data 1
				break
			}
		}

		if { ! $has_data } {
			return true
		}

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		set cmds "ngctl msg $node_id: getstats | grep -q \"queueFrames=\""
		set cmds "jexec $private_ns sh -c '$cmds'"

		set cmds [getTimeoutCmd "nodeconf_timeout" $cmds]

		set node_configured [isOk $cmds]
		if { $node_configured } {
			removeStateNode $node_id "error"
		} else {
			addStateNode $node_id "error"
		}

		return $node_configured
	}

	################################################################################
	############################# TERMINATE PROCEDURES #############################
	################################################################################

	proc nodeUnconfigure { eid node_id } {
		set ifaces [ifcList $node_id]
		if { $ifaces == {} } {
			return
		}

		addStateNode $node_id "node_unconfiguring"

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		pipesExec "jexec $private_ns ngctl msg $node_id: clrdata" "hold"

		# ifaces without links don't need to be stopped
		if { [getIfcLink $node_id [lindex $ifaces 0]] != "" } {
			pipesExec "jexec $private_ns ngctl msg $node_id: stop" "hold"
		}
	}

	proc nodeUnconfigure_check { eid node_id } {
		global isOSlinux isOSfreebsd

		# ignore ifaces without a link
		if { [getIfcLink $node_id [lindex [ifcList $node_id] 0]] == "" } {
			return true
		}

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]
		set cmds "ngctl msg $node_id: getstats | grep -q \"elapsedTime=\""
		set cmds "jexec $private_ns sh -c '$cmds'"

		set cmds [getTimeoutCmd "nodeconf_timeout" $cmds]

		set node_unconfigured [isOk $cmds]
		if { $node_unconfigured } {
			removeStateNode $node_id "error"
		} else {
			addStateNode $node_id "error"
		}

		return $node_unconfigured
	}
}
