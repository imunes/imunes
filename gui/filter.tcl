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

proc $MODULE.toolbarIconDescr {} {
    return "Add new Filter node"
}

proc $MODULE.icon {size} {
    global ROOTDIR LIBDIR

    switch $size {
	normal {
	    return $ROOTDIR/$LIBDIR/icons/normal/filter.gif
	}
	small {
	    return $ROOTDIR/$LIBDIR/icons/small/filter.gif
	}
	toolbar {
	    return $ROOTDIR/$LIBDIR/icons/tiny/filter.gif
	}
    }
}

proc $MODULE.notebookDimensions { wi } {
    set h 370
    set w 667

    return [list $h $w]
}

#****f* filter.tcl/filter.configGUI
# NAME
#   filter.configGUI
# SYNOPSIS
#   filter.configGUI $c $node_id
# FUNCTION
#   Defines the structure of the filter.configuration window
#   by calling procedures for creating and organising the
#   window, as well as procedures for adding certain modules
#   to that window.
# INPUTS
#   * c - tk canvas
#   * node_id - node id
#****
proc $MODULE.configGUI { c node_id } {
    global wi
    global filterguielements filtertreecolumns curnode
    global node_cfg node_existing_mac node_existing_ipv4 node_existing_ipv6

    set node_cfg [cfgGet "nodes" $node_id]
    set node_existing_mac [getFromRunning "mac_used_list"]
    set node_existing_ipv4 [getFromRunning "ipv4_used_list"]
    set node_existing_ipv6 [getFromRunning "ipv6_used_list"]

    set curnode $node_id
    set filterguielements {}

    if { [_ifcList $node_cfg] == "" } {
	tk_dialog .dialog1 "IMUNES warning" \
	    "This node has no interfaces." \
	    info 0 Dismiss

	return
    }

    configGUI_createConfigPopupWin $c
    wm title $wi "filter configuration"

    configGUI_nodeName $wi $node_id "Node name:"

    set tabs [configGUI_addNotebookFilter $wi $node_id [lsort [_ifcList $node_cfg]]]

    set filtertreecolumns {"Action Action" "Pattern Pattern" "Mask Mask" \
	"Offset Offset" "ActionData ActionData"}
    foreach tab $tabs {
	configGUI_addTreeFilter $tab $node_id
    }

    configGUI_nodeRestart $wi $node_id
    configGUI_buttonsACFilterNode $wi $node_id
}

#****f* filter.tcl/filter.configInterfacesGUI
# NAME
#   filter.configInterfacesGUI
# SYNOPSIS
#   filter.configInterfacesGUI $wi $node_id $iface_id
# FUNCTION
#   Defines which modules for changing interfaces parameters
#   are contained in the filter.configuration window. It is done
#   by calling procedures for adding certain modules to the window.
# INPUTS
#   * wi - widget
#   * node_id - node id
#   * iface_id - interface id
#   * rule_num - rule number
#****
proc $MODULE.configIfcRulesGUI { wi node_id iface_id rule_num } {
    global filterguielements

    configGUI_ifcRuleConfig $wi $node_id $iface_id $rule_num
}
