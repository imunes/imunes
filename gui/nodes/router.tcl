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
# This work was supported in part by Croatian Ministry of Science
# and Technology through the research contract #IP-2003-143.
#

# $Id: frr.tcl 128 2014-12-19 11:59:09Z denis $


#****h* imunes/frr.tcl
# NAME
#  router.frr.tcl -- defines specific procedures for router
#  using frr routing model
# FUNCTION
#  This module defines all the specific procedures for a router
#  which uses frr routing model.
# NOTES
#  Procedures in this module start with the keyword router.frr and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE router

namespace eval ${MODULE}::gui {
	namespace import ::genericL3::gui::*
	namespace export *

	#****f* genericrouter.tcl/router.toolbarIconDescr
	# NAME
	#   router.toolbarIconDescr -- toolbar icon description
	# SYNOPSIS
	#   router.toolbarIconDescr
	# FUNCTION
	#   Returns this module's toolbar icon description.
	# RESULT
	#   * descr -- string describing the toolbar icon
	#****
	proc toolbarIconDescr {} {
		return "Add new Router"
	}

	#****f* genericrouter.tcl/router.icon
	# NAME
	#   router.icon -- icon
	# SYNOPSIS
	#   router.icon $size
	# FUNCTION
	#   Returns path to node icon, depending on the specified size.
	# INPUTS
	#   * size -- "normal", "small" or "toolbar"
	# RESULT
	#   * path -- path to icon
	#****
	proc icon { size } {
		global ROOTDIR LIBDIR

		switch $size {
			normal {
				return $ROOTDIR/$LIBDIR/icons/normal/router.gif
			}
			small {
				return $ROOTDIR/$LIBDIR/icons/small/router.gif
			}
			toolbar {
				return $ROOTDIR/$LIBDIR/icons/tiny/router.gif
			}
		}
	}

	#****f* genericrouter.tcl/router.notebookDimensions
	# NAME
	#   router.notebookDimensions -- notebook dimensions
	# SYNOPSIS
	#   router.notebookDimensions $wi
	# FUNCTION
	#   Returns the specified notebook height and width.
	# INPUTS
	#   * wi -- widget
	# RESULT
	#   * size -- notebook size as {height width}
	#****
	proc notebookDimensions { wi } {
		set h 250
		set w 507

		if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] == "Configuration" } {
			set h 400
			set w 507
		}

		if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] == "Interfaces" } {
			set h 370
			set w 507
		}

		if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] == "IPsec" } {
			set h 320
			set w 507
		}

		return [list $h $w]
	}

	#****f* genericrouter.tcl/router.configGUI
	# NAME
	#   router.configGUI -- configuration GUI
	# SYNOPSIS
	#   router.configGUI $node_id
	# FUNCTION
	#   Defines the structure of the router configuration window by calling
	#   procedures for creating and organising the window, as well as procedures
	#   for adding certain modules to that window.
	# INPUTS
	#   * node_id -- node id
	#****
	proc configGUI { node_id } {
		global wi
		#
		#guielements - the list of modules contained in the configuration window
		#		(each element represents the name of the procedure which creates
		#		that module)
		#
		#treecolumns - the list of columns in the interfaces tree (each element
		#		consists of the column id and the column name)
		#
		global guielements treecolumns ipsecEnable
		global node_cfg node_cfg_gui node_existing_mac node_existing_ipv4 node_existing_ipv6

		set guielements {}
		set treecolumns {}
		set node_cfg [cfgGet "nodes" $node_id]
		set node_cfg_gui [cfgGet "gui" "nodes" $node_id]
		set node_existing_mac [getFromRunning "mac_used_list"]
		set node_existing_ipv4 [getFromRunning "ipv4_used_list"]
		set node_existing_ipv6 [getFromRunning "ipv6_used_list"]

		configGUI_createConfigPopupWin
		wm title $wi "[_getNodeType $node_cfg] ($node_id) configuration"

		configGUI_nodeName $wi $node_id "Node name:"

		set labels {
			"Configuration"
			"Interfaces"
			"IPsec"
		}
		lassign [configGUI_addNotebook $wi $node_id $labels] \
			configtab ifctab ipsectab

		configGUI_routingModel $configtab $node_id
		configGUI_customImage $configtab $node_id
		configGUI_attachDockerToExt $configtab $node_id
		configGUI_servicesConfig $configtab $node_id
		configGUI_staticRoutes $configtab $node_id
		configGUI_snapshots $configtab $node_id
		configGUI_customConfig $configtab $node_id
		configGUI_ipsec $ipsectab $node_id

		set treecolumns {
			"OperState State"
			"NatState Nat"
			"IPv4addrs IPv4 addrs"
			"IPv6addrs IPv6 addrs"
			"MACaddr MAC addr"
			"MTU MTU"
			"QLen Queue len"
			"QDisc Queue disc"
			"QDrop Queue drop"
		}
		configGUI_addTree $ifctab $node_id

		configGUI_nodeRestart $wi $node_id
		configGUI_buttonsACNode $wi $node_id
	}
}
