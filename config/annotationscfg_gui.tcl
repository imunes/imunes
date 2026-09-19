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

#****f* annotationscfg_gui.tcl/addAnnotation
# NAME
#   addAnnotation -- add annotation object
# SYNOPSIS
#   addAnnotation $annotation_id $type
# FUNCTION
#   Adds annotation object to annotation list.
# INPUTS
#   * annotation_id -- new annotation id
#   * type -- annotation type
#****
proc addAnnotation { annotation_id type } {
	lappendToRunning_gui "annotation_list" $annotation_id
	setAnnotationType $annotation_id $type
}

#****f* annotationscfg_gui.tcl/deleteAnnotation
# NAME
#   deleteAnnotation -- delete annotation
# SYNOPSIS
#   deleteAnnotation $annotation_id $type
# FUNCTION
#   Deletes annotation from canvas.
# INPUTS
#   * annotation_id -- existing annotation
#****
proc deleteAnnotation { annotation_id } {
	setToRunning_gui "annotation_list" [removeFromList [getFromRunning_gui "annotation_list"] $annotation_id]
	cfgUnset "gui" "annotations" $annotation_id

	set curcanvas [getFromRunning_gui "curcanvas"]
	set new_order [removeFromList [getCanvasAnnotationOrder $curcanvas] $annotation_id]
	if { $new_order == "grid" } {
		cfgUnset "gui" "canvases" $curcanvas "annotation_order"
	} else {
		setCanvasAnnotationOrder $curcanvas $new_order
	}
}

addCase "updateAnnotationGUI" "type" {
	setAnnotationType $annotation_id $new_value
}

addCase "updateAnnotationGUI" "canvas" {
	setAnnotationCanvas $annotation_id $new_value
}

addCase "updateAnnotationGUI" "color" {
	setAnnotationColor $annotation_id $new_value
}

addCase "updateAnnotationGUI" "label" {
	setAnnotationLabel $annotation_id $new_value
}

addCase "updateAnnotationGUI" "labelcolor" {
	setAnnotationLabelColor $annotation_id $new_value
}

addCase "updateAnnotationGUI" "bordercolor" {
	setAnnotationBorderColor $annotation_id $new_value
}

addCase "updateAnnotationGUI" "width" {
	setAnnotationWidth $annotation_id $new_value
}

addCase "updateAnnotationGUI" "rad" {
	setAnnotationRad $annotation_id $new_value
}

addCase "updateAnnotationGUI" "font" {
	setAnnotationFont $annotation_id $new_value
}

addCase "updateAnnotationGUI" "iconcoords" {
	setAnnotationCoords $annotation_id $new_value
}

proc updateAnnotationGUI { annotation_id old_annotation_cfg_gui new_annotation_cfg_gui } {
	upvar ::switch_cases::updateAnnotationGUI switch_cases_var

	global changed

	dputs ""
	dputs "= /UPDATE ANNOTATION GUI $annotation_id START ="

	if { $old_annotation_cfg_gui == "*" } {
		set old_annotation_cfg_gui [cfgGet "gui" "annotations" $annotation_id]
	}

	dputs "OLD : '$old_annotation_cfg_gui'"
	dputs "NEW : '$new_annotation_cfg_gui'"

	set cfg_diff [dictDiff $old_annotation_cfg_gui $new_annotation_cfg_gui]
	dputs "= cfg_diff: '$cfg_diff'"
	if { $cfg_diff == "" || [lsort -uniq [dict values $cfg_diff]] == "copy" } {
		dputs "= NO CHANGE"
		dputs "= /UPDATE ANNOTATION GUI $annotation_id END ="
		return $new_annotation_cfg_gui
	}

	if { $new_annotation_cfg_gui == "" } {
		return $old_annotation_cfg_gui
	}

	dict for {key change} $cfg_diff {
		if { $change == "copy" } {
			continue
		}

		# trigger undo log
		set changed 1

		dputs "==== $change: '$key'"

		set old_value [_cfgGet $old_annotation_cfg_gui $key]
		set new_value [_cfgGet $new_annotation_cfg_gui $key]
		if { $change in "changed" } {
			dputs "==== OLD: '$old_value'"
		}
		if { $change in "new changed" } {
			dputs "==== NEW: '$new_value'"
		}

		switch -exact $key [list {*}$switch_cases_var default {}]
	}

	if { $changed } {
		# will reset 'changed' to 0
		updateUndoLog

		# changed needs to be 1 to trigger redrawing
		set changed 1
	}

	dputs "= /UPDATE ANNOTATION GUI $annotation_id END ="
	dputs ""

	return $new_annotation_cfg_gui
}
