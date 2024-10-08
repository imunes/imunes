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
#  ext.tcl -- defines pc specific procedures
# FUNCTION
#  This module is used to define all the pc specific procedures.
# NOTES
#  Procedures in this module start with the keyword pc and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE ext

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
proc $MODULE.toolbarIconDescr {} {
    return "Add new External connection"
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
proc $MODULE.icon { size } {
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
#   ext.configGUI $c $node_id
# FUNCTION
#   Defines the structure of the pc configuration window by calling
#   procedures for creating and organising the window, as well as
#   procedures for adding certain modules to that window.
# INPUTS
#   * c -- tk canvas
#   * node_id -- node id
#****
proc $MODULE.configGUI { c node_id } {
    set iface_id [lindex [ifcList $node_id] 0]
    if { "$iface_id" == "" } {
	return
    }

    global wi
    global guielements treecolumns
    global node_cfg

    set guielements {}
    set treecolumns {}
    set node_cfg [cfgGet "nodes" $node_id]

    configGUI_createConfigPopupWin $c
    wm title $wi "ext configuration"
    configGUI_nodeName $wi $node_id "Node name:"

    configGUI_externalIfcs $wi $node_id

    configGUI_buttonsACNode $wi $node_id
}
