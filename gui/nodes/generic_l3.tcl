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

namespace eval genericL3::gui {
	namespace export *

	proc toolbarIconDescr {} {
		return "Add new L3 node"
	}

	proc toolbarLocation {} {
		return "net_layer"
	}

	proc _confNewIfc { node_cfg iface_id } {
		global node_existing_mac node_existing_ipv4 node_existing_ipv6

		set ipv4addr [getNextIPv4addr [_getNodeType $node_cfg] $node_existing_ipv4]
		lappend node_existing_ipv4 $ipv4addr
		set node_cfg [_setIfcIPv4addrs $node_cfg $iface_id $ipv4addr]

		set ipv6addr [getNextIPv6addr [_getNodeType $node_cfg] $node_existing_ipv6]
		lappend node_existing_ipv6 $ipv6addr
		set node_cfg [_setIfcIPv6addrs $node_cfg $iface_id $ipv6addr]

		set macaddr [getNextMACaddr $node_existing_mac]
		lappend node_existing_mac $macaddr
		set node_cfg [_setIfcMACaddr $node_cfg $iface_id $macaddr]

		return $node_cfg
	}

	proc icon { size } {
		global ROOTDIR LIBDIR

		switch $size {
			normal {
				return $ROOTDIR/$LIBDIR/icons/normal/gl3.gif
			}
			small {
				return $ROOTDIR/$LIBDIR/icons/small/gl3.gif
			}
			toolbar {
				return $ROOTDIR/$LIBDIR/icons/tiny/gl3.gif
			}
		}
	}

	proc notebookDimensions { wi } {
		set h 210
		set w 507

		if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] == "Configuration" } {
			set h 350
			set w 507
		}
		if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] == "Interfaces" } {
			set h 370
			set w 507
		}

		return [list $h $w]
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

		configGUI_customImage $configtab $node_id
		configGUI_attachDockerToExt $configtab $node_id
		configGUI_servicesConfig $configtab $node_id
		configGUI_staticRoutes $configtab $node_id
		configGUI_snapshots $configtab $node_id
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

	proc configInterfacesGUI { wi node_id iface_id } {
		global guielements

		configGUI_ifcEssentials $wi $node_id $iface_id
		configGUI_ifcQueueConfig $wi $node_id $iface_id
		configGUI_ifcMACAddress $wi $node_id $iface_id
		configGUI_ifcIPv4Address $wi $node_id $iface_id
		configGUI_ifcIPv6Address $wi $node_id $iface_id
	}

	proc doubleClick { node_id control } {
		invokeTypeProc "genericL2" "gui::doubleClick" $node_id $control
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
			menu_transformTo
			menu_addSeparator
			menu_autoExecute
		}

		if { [getFromRunning "oper_mode"] == "exec" } {
			set exec_list {
				menu_nodeExecute
				menu_addSeparator
				menu_shellSelection
				menu_services
				menu_wiresharkIfaces
				menu_tcpdumpIfaces
				menu_addSeparator
				menu_browser
				menu_mailClient
			}

			lappend menu_list {*}$exec_list
		}

		return $menu_list
	}
}
