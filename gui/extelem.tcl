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

# $Id: extelem.tcl 129 2015-02-13 11:14:44Z valter $


#****h* imunes/extelem.tcl
# NAME
#  extelem.tcl -- defines extelem specific procedures
# FUNCTION
#  This module is used to define all the extelem specific procedures.
# NOTES
#  Procedures in this module start with the keyword extelem and
#  end with function specific part that is the same for all the
#  node types that work on the same layer.
#****

set MODULE extelem

#****f* extelem.tcl/extelem.toolbarIconDescr
# NAME
#   extelem.toolbarIconDescr -- toolbar icon description
# SYNOPSIS
#   extelem.toolbarIconDescr
# FUNCTION
#   Returns this module's toolbar icon description.
# RESULT
#   * descr -- string describing the toolbar icon
#****
proc $MODULE.toolbarIconDescr {} {
    return "Add new External element"
}

#****f* extelem.tcl/extelem.icon
# NAME
#   extelem.icon -- icon
# SYNOPSIS
#   extelem.icon $size
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
	    return $ROOTDIR/$LIBDIR/icons/normal/cloud.gif
	}
	small {
	    return $ROOTDIR/$LIBDIR/icons/small/cloud.gif
	}
	toolbar {
	    return $ROOTDIR/$LIBDIR/icons/tiny/cloud.gif
	}
    }
}

#****f* extelem.tcl/extelem.configGUI
# NAME
#   extelem.configGUI -- configuration GUI
# SYNOPSIS
#   extelem.configGUI $c $node_id
# FUNCTION
#   Defines the structure of the extelem configuration window by calling
#   procedures for creating and organising the window, as well as procedures
#   for adding certain modules to that window.
# INPUTS
#   * c -- tk canvas
#   * node_id -- node id
#****
proc $MODULE.configGUI { c node_id } {
    global wi
    global guielements treecolumns
    set guielements {}
    set treecolumns {}

    configGUI_createConfigPopupWin $c
    wm title $wi "External element configuration"
    configGUI_nodeName $wi $node_id "External element name:"

    configGUI_addPanedWin $wi
    configGUI_rj45s $wi $node_id

    configGUI_buttonsACNode $wi $node_id
}

#****f* extelem.tcl/extelem.configInterfacesGUI
# NAME
#   extelem.configInterfacesGUI -- configuration of interfaces GUI
# SYNOPSIS
#   extelem.configInterfacesGUI $wi $node_id $iface_id
# FUNCTION
#   Defines which modules for changing interfaces parameters are contained in
#   the extelem configuration window. It is done by calling procedures for adding
#   certain modules to the window.
# INPUTS
#   * wi -- widget
#   * node_id -- node id
#   * iface_id -- interface id
#****
proc $MODULE.configInterfacesGUI { wi node_id iface_id } {
    global guielements

    configGUI_ifcQueueConfig $wi $node_id $iface_id
}
