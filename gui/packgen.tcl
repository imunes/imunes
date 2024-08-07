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

proc $MODULE.toolbarIconDescr {} {
    return "Add new Packet generator"
}

proc $MODULE.icon { size } {
    global ROOTDIR LIBDIR

    switch $size {
	normal {
	    return $ROOTDIR/$LIBDIR/icons/normal/packgen.gif
	}
	small {
	    return $ROOTDIR/$LIBDIR/icons/small/packgen.gif
	}
	toolbar {
	    return $ROOTDIR/$LIBDIR/icons/tiny/packgen.gif
	}
    }
}

proc $MODULE.notebookDimensions { wi } {
    set h 430
    set w 652

    return [list $h $w]
}

#****f* packgen.tcl/packgen.configGUI
# NAME
#   packgen.configGUI
# SYNOPSIS
#   packgen.configGUI $c $node_id
# FUNCTION
#   Defines the structure of the packgen configuration window
#   by calling procedures for creating and organising the
#   window, as well as procedures for adding certain modules
#   to that window.
# INPUTS
#   * c - tk canvas
#   * node_id - node id
#****
proc $MODULE.configGUI { c node_id } {
    global wi
    global packgenguielements packgentreecolumns curnode

    set curnode $node_id
    set packgenguielements {}

    configGUI_createConfigPopupWin $c
    wm title $wi "packet generator configuration"
    configGUI_nodeName $wi $node_id "Node name:"

    set tabs [configGUI_addNotebookPackgen $wi $node_id]

    configGUI_packetRate [lindex $tabs 0] $node_id

    set packgentreecolumns {"Data Data"}
    foreach tab $tabs {
	configGUI_addTreePackgen $tab $node_id
    }

    configGUI_buttonsACPackgenNode $wi $node_id
}

#****f* packgen.tcl/packgen.configInterfacesGUI
# NAME
#   packgen.configInterfacesGUI
# SYNOPSIS
#   packgen.configInterfacesGUI $wi $node_id $iface
# FUNCTION
#   Defines which modules for changing interfaces parameters
#   are contained in the packgen.configuration window. It is done
#   by calling procedures for adding certain modules to the window.
# INPUTS
#   * wi - widget
#   * node_id - node id
#   * pac_id - packet id
#****
proc $MODULE.configPacketsGUI { wi node_id pac_id } {
    global packgenguielements

    configGUI_packetConfig $wi $node_id $pac_id
}
