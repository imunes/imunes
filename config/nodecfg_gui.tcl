#
# Copyright 2025- University of Zagreb.
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

#****f* nodecfg_gui.tcl/pseudo.netlayer
# NAME
#   pseudo.netlayer -- pseudo layer
# SYNOPSIS
#   set layer [pseudo.netlayer]
# FUNCTION
#   Returns the layer on which the pseudo node operates
#   i.e. returns no layer.
# RESULT
#   * layer -- returns an empty string
#****
proc pseudo.netlayer {} {
}

#****f* nodecfg_gui.tcl/pseudo.virtlayer
# NAME
#   pseudo.virtlayer -- pseudo virtlayer
# SYNOPSIS
#   set virtlayer [pseudo.virtlayer]
# FUNCTION
#   Returns the virtlayer on which the pseudo node operates
#   i.e. returns no layer.
# RESULT
#   * virtlayer -- returns an empty string
#****
proc pseudo.virtlayer {} {
}

proc updateNodeGUI { node_id old_node_cfg_gui new_node_cfg_gui } {
	dputs ""
	dputs "= /UPDATE NODE GUI $node_id START ="

	if { $old_node_cfg_gui == "*" } {
		set old_node_cfg_gui [cfgGet "nodes" $node_id]
	}

	dputs "OLD : '$old_node_cfg_gui'"
	dputs "NEW : '$new_node_cfg_gui'"

	set cfg_diff [dictDiff $old_node_cfg_gui $new_node_cfg_gui]
	dputs "= cfg_diff: '$cfg_diff'"
	if { $cfg_diff == "" || [lsort -uniq [dict values $cfg_diff]] == "copy" } {
		dputs "= NO CHANGE"
		dputs "= /UPDATE NODE GUI $node_id END ="
		return $new_node_cfg_gui
	}

	if { $new_node_cfg_gui == "" } {
		return $old_node_cfg_gui
	}

	dict for {key change} $cfg_diff {
		if { $change == "copy" } {
			continue
		}

		dputs "==== $change: '$key'"

		set old_value [_cfgGet $old_node_cfg_gui $key]
		set new_value [_cfgGet $new_node_cfg_gui $key]
		if { $change in "changed" } {
			dputs "==== OLD: '$old_value'"
		}
		if { $change in "new changed" } {
			dputs "==== NEW: '$new_value'"
		}

		switch -exact $key {
			"label" {
				#setNodeLabel $node_id $new_value
			}

			"canvas" {
				setNodeCanvas $node_id $new_value
			}

			"iconcoords" {
				setNodeCoords $node_id $new_value
			}

			"labelcoords" {
				setNodeLabelCoords $node_id $new_value
			}

			"custom_icon" {
				setNodeCustomIcon $node_id $new_value
			}

			default {
				# do nothing
			}
		}
	}

	dputs "= /UPDATE NODE GUI $node_id END ="
	dputs ""

	return $new_node_cfg_gui
}
