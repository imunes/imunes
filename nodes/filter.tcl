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

#****h* imunes/filter.tcl
# NAME
#  filter.tcl -- defines filter.specific procedures
# FUNCTION
#  This module is used to define all the filter.specific procedures.
# NOTES
#  Procedures in this module start with the keyword filter.and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE filter
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
		return "filter"
	}

	proc getHookData { node_id iface_id } {
		# FreeBSD - stolen interface name of the node (attached to netgraph node in EID jail)
		set private_elem [getIfcName $node_id $iface_id]

		# name of public netgraph peer
		set public_elem $node_id

		# FreeBSD - hook for connecting to netgraph node
		set hook_name $private_elem

		return [list $private_elem $public_elem $hook_name]
	}

	################################################################################
	############################ INSTANTIATE PROCEDURES ############################
	################################################################################

	proc prepareSystem {} {
		catch { rexec kldload ng_patmat }
	}

	#****f* filter.tcl/filter.nodeCreate
	# NAME
	#   filter.nodeCreate
	# SYNOPSIS
	#   filter.nodeCreate $eid $node_id
	# FUNCTION
	#   Procedure filter.nodeCreate creates a new virtual node
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
		mkpeer . patmat tmp tmp \n
		name .:tmp $node_id
		\" | jexec $private_ns ngctl -f -" "hold"
	}

	proc nodePhysIfacesCreate { eid node_id ifaces } {
		foreach iface_id $ifaces {
			if { [getIfcLink $node_id $iface_id] == "" } {
				removeStateNodeIface $node_id $iface_id "running"

				continue
			}

			addStateNodeIface $node_id $iface_id "running"
		}
	}

	proc nodePhysIfacesDirectCreate { eid node_id ifaces } {
		return [invokeNodeProc $node_id "nodePhysIfacesCreate" $eid $node_id $ifaces]
	}

	#****f* filter.tcl/filter.nodeConfigure
	# NAME
	#   filter.nodeConfigure
	# SYNOPSIS
	#   filter.nodeConfigure $eid $node_id
	# FUNCTION
	#   Starts a new filter. The node can be started if it is instantiated.
	#   Simulates the booting proces of a filter.
	#   procedure.
	# INPUTS
	#   * eid - experiment id
	#   * node_id - id of the node
	#****
	proc nodeConfigure { eid node_id } {
		set ifaces [ifcList $node_id]
		foreach iface_id $ifaces {
			if { ! [isRunningNodeIface $node_id $iface_id] } {
				set ifaces [removeFromList $ifaces $iface_id]
			}
		}

		if { $ifaces == {} } {
			return
		}

		addStateNode $node_id "node_configuring"

		foreach iface_id $ifaces {
			set ng_cfg_req "shc [getIfcName $node_id $iface_id]"
			foreach rule_num [lsort -dictionary [ifcFilterRuleList $node_id $iface_id]] {
				set rule [getFilterIfcRuleAsString $node_id $iface_id $rule_num]

				set action [getFilterIfcAction $node_id $iface_id $rule_num]
				if { $action == "match_drop" } {
					set ng_cfg_req "${ng_cfg_req} ${rule}"

					continue
				}

				set action_data [getFilterIfcActionData $node_id $iface_id $rule_num]
				set other_iface_id [ifaceIdFromName $node_id $action_data]
				if { [isRunningNodeIface $node_id $other_iface_id] } {
					set ng_cfg_req "${ng_cfg_req} ${rule}"
				}
			}

			pipesExec "jexec $eid ngctl msg $node_id: $ng_cfg_req" "hold"
		}
	}

	proc nodeConfigure_check { eid node_id } {
		set ifaces [ifcList $node_id]
		foreach iface_id $ifaces {
			if { ! [isRunningNodeIface $node_id $iface_id] } {
				set ifaces [removeFromList $ifaces $iface_id]
			}
		}

		if { $ifaces == {} } {
			return true
		}

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

		set cmds ""
		foreach iface_id $ifaces {
			lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] iface_name - -

			set ng_cfg_req "Args.*$iface_name.*"
			foreach rule_num [lsort -dictionary [ifcFilterRuleList $node_id $iface_id]] {
				set rule [getFilterIfcRuleAsString $node_id $iface_id $rule_num]

				set action [getFilterIfcAction $node_id $iface_id $rule_num]
				if { $action == "match_drop" } {
					set ng_cfg_req "${ng_cfg_req}.*${rule}"

					continue
				}

				set action_data [getFilterIfcActionData $node_id $iface_id $rule_num]
				set other_iface_id [ifaceIdFromName $node_id $action_data]
				if { [getIfcLink $node_id $other_iface_id] != "" } {
					set ng_cfg_req "${ng_cfg_req}.*${rule}"
				}
			}

			append cmds "ngctl msg $node_id: ghc $iface_name | grep -q '$ng_cfg_req' && echo $iface_name; "
		}

		set cmds "jexec $private_ns sh -c '$cmds'"

		set cmds [getTimeoutCmd "ifacesconf_timeout" $cmds]

		try {
			rexec $cmds
		} on ok ifaces_all {
			if { [string trim $ifaces_all "\n "] == "" } {
				return false
			}

			set ifaces_created {}
			foreach iface_id $ifaces {
				lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] iface_name - -
				if {
					[isRunningNodeIface $node_id $iface_id] ||
					("creating" in [getStateNodeIface $node_id $iface_id] &&
					$iface_name in $ifaces_all)
				} {
					lappend ifaces_created $iface_id

					removeStateNodeIface $node_id $iface_id "error creating"
					setStateErrorMsgNodeIface $node_id $iface_id ""
					addStateNodeIface $node_id $iface_id "running"
				} else {
					addStateNodeIface $node_id $iface_id "error"
					if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
						setStateErrorMsgNodeIface $node_id $iface_id "Interface '$iface_id' ($iface_name) not created."
					}
				}
			}

			if { [llength $ifaces] == [llength $ifaces_created] } {
				return true
			}

			return false
		} on error {} {
			return false
		}

		return false
	}

	################################################################################
	############################# TERMINATE PROCEDURES #############################
	################################################################################

	proc nodeUnconfigure { eid node_id } {
		set ifaces [ifcList $node_id]
		foreach iface_id $ifaces {
			if { ! [isRunningNodeIface $node_id $iface_id] } {
				set ifaces [removeFromList $ifaces $iface_id]
			}
		}

		if { $ifaces == {} } {
			return
		}

		addStateNode $node_id "node_unconfiguring"

		foreach iface_id $ifaces {
			set ngcfgreq "shc [getIfcName $node_id $iface_id]"
			pipesExec "jexec $eid ngctl msg $node_id: $ngcfgreq" "hold"
		}
	}

	proc nodeUnconfigure_check { eid node_id } {
		set ifaces [ifcList $node_id]
		foreach iface_id $ifaces {
			if { ! [isRunningNodeIface $node_id $iface_id] } {
				set ifaces [removeFromList $ifaces $iface_id]
			}
		}

		if { $ifaces == {} } {
			return true
		}

		set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

		set cmds ""
		foreach iface_id $ifaces {
			lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] iface_name - -

			append cmds "ngctl msg $node_id: ghc $iface_name | grep 'Args' | grep -qv 'match' && echo $iface_name; "
		}

		set cmds "jexec $private_ns sh -c '$cmds'"

		set cmds [getTimeoutCmd "ifacesconf_timeout" $cmds]

		try {
			rexec $cmds
		} on ok ifaces_all {
			if { [string trim $ifaces_all "\n "] == "" } {
				return false
			}

			set ifaces_created {}
			foreach iface_id $ifaces {
				lassign [invokeNodeProc $node_id "getHookData" $node_id $iface_id] iface_name - -
				if {
					[isRunningNodeIface $node_id $iface_id] ||
					("creating" in [getStateNodeIface $node_id $iface_id] &&
					$iface_name in $ifaces_all)
				} {
					lappend ifaces_created $iface_id

					removeStateNodeIface $node_id $iface_id "error creating"
					setStateErrorMsgNodeIface $node_id $iface_id ""
					addStateNodeIface $node_id $iface_id "running"
				} else {
					addStateNodeIface $node_id $iface_id "error"
					if { [getStateErrorMsgNodeIface $node_id $iface_id] == "" } {
						setStateErrorMsgNodeIface $node_id $iface_id "Interface '$iface_id' ($iface_name) not created."
					}
				}
			}

			if { [llength $ifaces] == [llength $ifaces_created] } {
				return true
			}

			return false
		} on error {} {
			return false
		}

		return false
	}
}
