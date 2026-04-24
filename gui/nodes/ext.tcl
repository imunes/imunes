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

# $Id: ext.tcl 63 2013-10-03 12:17:50Z valter $


#****h* imunes/ext.tcl
# NAME
#  ext.tcl -- defines ext specific procedures
# FUNCTION
#  This module is used to define all the ext specific procedures.
# NOTES
#  Procedures in this module start with the keyword ext and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE ext

namespace eval ${MODULE}::gui {
	namespace import ::genericL3::gui::*
	namespace export *

	#****f* ext.tcl/ext.toolbarIconDescr
	# NAME
	#   ext.toolbarIconDescr -- toolbar icon description
	# SYNOPSIS
	#   ext.toolbarIconDescr
	# FUNCTION
	#   Returns this module's toolbar icon description.
	# RESULT
	#   * descr -- string describing the toolbar icon
	#****
	proc toolbarIconDescr {} {
		return "Add new External connection"
	}

	proc _confNewIfc { node_cfg iface_id } {
		global mac_byte4 mac_byte5
		global node_existing_mac node_existing_ipv4 node_existing_ipv6

		set min_ip [_invokeNodeProc $node_cfg "IPAddrRange"]

		if { [getActiveOption "IPv4autoAssign"] } {
			set template_ipv4 [findFreeIPv4Subnet "" $node_existing_ipv4]
			set ipv4addr [nextAddrInSubnet "ipv4" $template_ipv4 $node_existing_ipv4 $min_ip]
			if { $ipv4addr != "" } {
				lappend node_existing_ipv4 $ipv4addr
				set node_cfg [_setIfcIPv4addrs $node_cfg $iface_id $ipv4addr]
			}
		}

		if { [getActiveOption "IPv6autoAssign"] } {
			set template_ipv6 [findFreeIPv6Subnet "" $node_existing_ipv6]
			set ipv6addr [nextAddrInSubnet "ipv6" $template_ipv6 $node_existing_ipv6 $min_ip]
			if { $ipv6addr != "" } {
				lappend node_existing_ipv6 $ipv6addr
				set node_cfg [_setIfcIPv6addrs $node_cfg $iface_id $ipv6addr]
			}
		}

		set bkp_mac_byte4 $mac_byte4
		set bkp_mac_byte5 $mac_byte5
		randomizeMACbytes
		set macaddr [getNextMACaddr $node_existing_mac]
		lappend node_existing_mac $macaddr
		set node_cfg [_setIfcMACaddr $node_cfg $iface_id $macaddr]
		set mac_byte4 $bkp_mac_byte4
		set mac_byte5 $bkp_mac_byte5

		return $node_cfg
	}

	#****f* ext.tcl/ext.icon
	# NAME
	#   ext.icon -- icon
	# SYNOPSIS
	#   ext.icon $size
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
				return $ROOTDIR/$LIBDIR/icons/normal/ext.gif
			}
			small {
				return $ROOTDIR/$LIBDIR/icons/small/ext.gif
			}
			toolbar {
				return $ROOTDIR/$LIBDIR/icons/tiny/ext.gif
			}
		}
	}

	#****f* ext.tcl/ext.configGUI
	# NAME
	#   ext.configGUI -- configuration GUI
	# SYNOPSIS
	#   ext.configGUI $node_id
	# FUNCTION
	#   Defines the structure of the ext configuration window by calling
	#   procedures for creating and organising the window, as well as
	#   procedures for adding certain modules to that window.
	# INPUTS
	#   * node_id -- node id
	#****
	proc configGUI { node_id } {
		set iface_id [lindex [ifcList $node_id] 0]
		if { "$iface_id" == "" } {
			return
		}

		global wi
		#
		#guielements - the list of modules contained in the configuration window
		#		(each element represents the name of the procedure which creates
		#		that module)
		#
		#treecolumns - the list of columns in the interfaces tree (each element
		#		consists of the column id and the column name)
		#
		global guielements treecolumns
		global node_cfg node_cfg_gui node_existing_mac node_existing_ipv4 node_existing_ipv6

		set guielements {}
		set treecolumns {}
		set node_cfg [cfgGet "nodes" $node_id]
		set node_cfg_gui [cfgGet "gui" "nodes" $node_id]
		set node_existing_mac [getFromRunning "mac_used_list"]
		set node_existing_ipv4 [getFromRunning "ipv4_used_list"]
		set node_existing_ipv6 [getFromRunning "ipv6_used_list"]

		configGUI_createConfigPopupWin
		wm title $wi "ext configuration"

		configGUI_nodeName $wi $node_id "Node name:"

		configGUI_externalIfcs $wi $node_id

		configGUI_nodeRestart $wi $node_id
		configGUI_buttonsACNode $wi $node_id
	}

	proc doubleClick { node_id control } {
		nodeConfigGUI $node_id
	}

	proc rightClickMenus {} {
		set menu_list {
			menu_selectAdjacent
			menu_configureNode
			menu_nodeIcons
			menu_createLink
			menu_connectIface
			menu_moveTo
			menu_deleteSelection
			menu_deleteSelectionKeepIfaces
			menu_addSeparator
			menu_nodeSettings
			menu_ifacesSettings
			menu_addSeparator
			menu_autoExecute
		}

		if { [getFromRunning "oper_mode"] == "exec" } {
			set exec_list {
				menu_nodeExecute
				menu_addSeparator
				menu_wiresharkNode
				menu_tcpdumpNode
			}

			lappend menu_list {*}$exec_list
		}

		return $menu_list
	}
}
