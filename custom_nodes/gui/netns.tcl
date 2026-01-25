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

set MODULE netns

namespace eval ${MODULE}::gui {
	namespace import ::genericL3::gui::*
	namespace export *

	proc toolbarIconDescr {} {
		return "Add new netns"
	}

	proc icon { size } {
		global ROOTDIR LIBDIR

		switch $size {
			normal {
				return $ROOTDIR/$LIBDIR/custom_nodes/icons/normal/netns.gif
			}
			small {
				return $ROOTDIR/$LIBDIR/custom_nodes/icons/small/netns.gif
			}
			toolbar {
				return $ROOTDIR/$LIBDIR/custom_nodes/icons/tiny/netns.gif
			}
		}
	}

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
		wm title $wi "[_getNodeType $node_cfg] ($node_id) configuration"

		configGUI_nodeName $wi $node_id "Node name:"

		set labels {
			"Configuration"
			"Interfaces"
		}
		lassign [configGUI_addNotebook $wi $node_id $labels] \
			configtab ifctab

		configGUI_staticRoutes $configtab $node_id
		configGUI_customConfig $configtab $node_id

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
				menu_shellSelection
				menu_wiresharkIfaces
				menu_tcpdumpIfaces
			}

			lappend menu_list {*}$exec_list
		}

		return $menu_list
	}
}
