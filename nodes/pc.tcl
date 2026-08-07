#
# Copyright 2005-2013 University of Zagreb.
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

# $Id: pc.tcl 63 2013-10-03 12:17:50Z valter $


#****h* imunes/pc.tcl
# NAME
#  pc.tcl -- defines pc specific procedures
# FUNCTION
#  This module is used to define all the pc specific procedures.
# NOTES
#  Procedures in this module start with the keyword pc and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE pc
registerModule $MODULE

namespace eval $MODULE {
	# Define all node-specific procedures. All non-defined procedures will call
	# genericL3.* procedures from nodes/generic_l3.tcl
	namespace import ::genericL3::*
	namespace export *

	################################################################################
	########################### CONFIGURATION PROCEDURES ###########################
	################################################################################

	proc namingBase {} {
		return "pc"
	}

	proc nodeInitConfigure { eid node_id } {
		global isOSlinux isOSfreebsd

		set cmd {}
		if { $isOSlinux } {
			array set sysctls {
				net.ipv6.conf.all.forwarding	0
				net.ipv4.conf.all.forwarding	0
			}

			foreach {name val} [array get sysctls] {
				lappend cmd "sysctl $name=$val"
			}
			set cmds [join $cmd "; "]
		}

		if { $isOSfreebsd } {
			array set sysctls {
				net.inet.ip.forwarding		0
				net.inet6.ip6.forwarding	0
			}

			foreach {name val} [array get sysctls] {
				lappend cmd "sysctl $name=$val"
			}
			set cmds [join $cmd "; "]
		}

		set os_cmd [invokeNodeProc $node_id "getExecCommand" $eid $node_id "-d"]
		pipesExec "$os_cmd sh -c '$cmds'" "hold"

		return [invokeTypeProc "genericL3" "nodeInitConfigure" $eid $node_id]
	}

	proc transformNode { node_id to_type } {
		if { $to_type ni "pc host router" } {
			return
		}

		# replace type
		setNodeType $node_id $to_type

		if { $to_type == "router" } {
			global router_protocols

			setNodeModel $node_id [getActiveOption "routerDefaultsModel"]

			foreach item $router_protocols {
				set protocol [lindex $item 0]
				set var_name "router[string totitle $protocol 0 0]Enable"

				setNodeProtocol $node_id $protocol [getActiveOption $var_name]
			}
		}
	}

	################################################################################
	############################ INSTANTIATE PROCEDURES ############################
	################################################################################

	################################################################################
	############################# TERMINATE PROCEDURES #############################
	################################################################################
}
