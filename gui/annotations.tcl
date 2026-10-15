#
# Copyright 2007-2013 University of Zagreb.
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

# $Id: annotations.tcl 91 2014-04-02 09:32:43Z valter $


#****h* imunes/annotations.tcl
# NAME
#  annotations.tcl -- oval, rectangle, text, background, ...
# FUNCTION
#  This module is used for configuration/image annotations, such as oval,
#  rectangle, text, background or some other.
#****

#****f* annotations.tcl/popupAnnotationDialog
# NAME
#   popupAnnotationDialog -- popup dialog for annotation
# SYNOPSIS
#   popupAnnotationDialog $target $modify
# FUNCTION
#   Shows a dialog to create a new or modifiy an existing annotation.
# INPUTS
#   * target -- 'new' or an existing annotation ID
#   * modify -- modify existing or newly created
#****
proc popupAnnotationDialog { target new_type modify } {
	global main_canvas_elem all_annotation_types
	global node_cfg_gui
	global new$new_type

	foreach annotation_type [removeFromList $all_annotation_types $new_type] {
		destroyNewAnnotation $annotation_type
	}

	if { $target == "new" } {
		# return if new annotation coords are empty
		if { [$main_canvas_elem coords "[set new$new_type]"] == "" } {
			return
		}

		set node_cfg_gui {}
		set node_cfg_gui [_setAnnotationType $node_cfg_gui $new_type]
		set annotation_type $new_type
		set annotation_coords [$main_canvas_elem bbox "[set new$new_type]"]

		# default values
		if { $annotation_type == "freeform" } {
			set annotation_color "blue"
			set border_width 2
		} else {
			set annotation_color ""
			set border_width 1
		}
		set border_color ""
		set corner_radius 25
		set label_text ""
		set label_color ""
		set label_font ""
	} else {
		set node_cfg_gui [cfgGet "gui" "annotations" $target]
		set annotation_type [_getAnnotationType $node_cfg_gui]
		set annotation_coords [_getAnnotationCoords $node_cfg_gui]

		set annotation_color [_getAnnotationColor $node_cfg_gui]
		set border_width [_getAnnotationWidth $node_cfg_gui]
		set border_color [_getAnnotationBorderColor $node_cfg_gui]
		set corner_radius [_getAnnotationRad $node_cfg_gui]
		set label_text [_getAnnotationLabel $node_cfg_gui]
		set label_color [_getAnnotationLabelColor $node_cfg_gui]
		set label_font [_getAnnotationFont $node_cfg_gui]
	}

	if { $annotation_color == "" } { set annotation_color [getActiveOption "default_fill_color"] }
	if { $border_color == "" } { set border_color "black" }
	if { $border_width == "" } { set border_width 1 }
	if { $label_color == "" } { set label_color [getActiveOption "default_text_color"] }
	if { $label_font == "" } { set label_font "TkTextFont" }

	set top_window .popup
	catch { destroy $top_window }
	toplevel $top_window

	wm transient $top_window .
	wm resizable $top_window 0 0

	if { $modify == "true" } {
		set windowtitle "Configure $annotation_type $target"
	} else {
		set windowtitle "Add a new '$annotation_type' annotation"
	}
	wm title $top_window $windowtitle

	set callback_elems [dict create]
	dict set callback_elems "parent_widget" $top_window

	switch -exact -- $annotation_type {
		"oval" -
		"rectangle" {
			# fill color, border color
			set colors_frame "$top_window.colors"
			ttk::frame $colors_frame -relief groove -borderwidth 2 -padding 2

			# color selection controls
			set colors_label_elem "$colors_frame.label"
			ttk::label $colors_label_elem -text "Fill color:"

			set color_preview_elem "$colors_frame.preview"
			ttk::label $color_preview_elem -width 8 \
				-text $annotation_color \
				-background $annotation_color
			dict set callback_elems "annotation_color" $color_preview_elem

			set colors_button_elem "$colors_frame.bg_chooser"
			ttk::button $colors_button_elem -text "Color" \
				-command "popupColor background $color_preview_elem true $colors_frame"

			pack $colors_label_elem $color_preview_elem $colors_button_elem \
				-side left -padx 2 -pady 2 -anchor w -fill x
			pack $colors_frame -side top -fill x

			# border selection controls
			set border_frame "$top_window.border"
			ttk::frame $border_frame -relief groove -borderwidth 2 -padding 2

			set border_label_elem "$border_frame.label"
			ttk::label $border_label_elem -text "Border color:"

			set border_color_label_elem "$border_frame.color"
			ttk::label $border_color_label_elem -text $border_color -width 8
			dict set callback_elems "border_color" $border_color_label_elem

			set border_width_label_elem "$border_frame.width_label"
			ttk::label $border_width_label_elem -text "Border width:"

			set border_width_elem "$border_frame.width"
			ttk::combobox $border_width_elem -width 3
			$border_width_elem configure -values [list 0 1 2 3 4 5 6 7 8 9 10]
			$border_width_elem set $border_width
			dict set callback_elems "border_width" $border_width_elem

			set border_button_elem "$border_frame.fb_chooser"
			ttk::button $border_button_elem -text "Color" \
				-command "popupColor foreground $border_color_label_elem true $colors_frame"

			pack $border_label_elem $border_color_label_elem $border_button_elem \
				$border_width_label_elem $border_width_elem \
				-side left -padx 2 -pady 2 -anchor w -fill x
			pack $border_frame -side top -fill x

			if { $annotation_type == "rectangle" } {
				lassign [lmap n $annotation_coords {expr int($n / [getActiveOption "zoom"])}] x1 y1 x2 y2
				set dx [expr { abs($x2 - $x1) }]
				set dy [expr { abs($y2 - $y1) }]
				if { $dx > $dy } {
					set max_rad [expr { int($dy * 3.0 / 8.0) }]
				} else {
					set max_rad [expr { int($dx * 3.0 / 8.0) }]
				}

				if { $corner_radius > $max_rad } {
					set corner_radius $max_rad
				}

				set radius_frame "$top_window.radius"
				ttk::frame $radius_frame -relief groove -borderwidth 2 -padding 2

				set radius_label_elem "$radius_frame.radius_label"
				ttk::label $radius_label_elem -text "Radius of the bend at the corners: "

				set radius_scale_elem "$radius_frame.radius_scale"
				ttk::scale $radius_scale_elem -length 400 -orient horizontal \
					-from 0 -to $max_rad
				$radius_scale_elem set $corner_radius
				dict set callback_elems "corner_radius" $radius_scale_elem

				pack $radius_frame -side top -fill x
				pack $radius_label_elem -side top -fill x
				pack $radius_scale_elem -side left -padx 2 -pady 2 -anchor w -fill x -expand 1
			}
		}

		"freeform" {
			set colors_frame "$top_window.colors"
			ttk::frame $colors_frame -relief groove -borderwidth 2 -padding 2

			# color selection controls
			set colors_label_elem "$colors_frame.label"
			ttk::label $colors_label_elem -text "Fill color:"

			set color_preview_elem "$colors_frame.preview"
			ttk::label $color_preview_elem -width 8 \
				-text $annotation_color \
				-background $annotation_color
			dict set callback_elems "annotation_color" $color_preview_elem

			set colors_button_elem "$colors_frame.bg_chooser"
			ttk::button $colors_button_elem -text "Color" \
				-command "popupColor background $color_preview_elem true $colors_frame"

			pack $colors_label_elem $color_preview_elem $colors_button_elem \
				-side left -padx 2 -pady 2 -anchor w -fill x
			pack $colors_frame -side top -fill x

			set width_frame "$top_window.width_frame"
			ttk::frame $width_frame -relief groove -borderwidth 2 -padding 2

			set width_label_elem "$width_frame.label"
			ttk::label $width_label_elem -text "Width:"

			set width_elem "$width_frame.width"
			ttk::combobox $width_elem -width 3
			$width_elem configure -values [list 0 1 2 3 4 5 6 7 8 9 10]
			$width_elem set $border_width
			dict set callback_elems "border_width" $width_elem

			pack $width_frame $width_label_elem $width_elem \
				-side left -padx 2 -pady 2 -anchor w -fill x
			pack $width_frame -side top -fill x
		}

		"text" {
			set input_frame "$top_window.input"
			ttk::frame $input_frame -relief groove -borderwidth 2 -padding 2

			set label_frame "$input_frame.label_frame"
			ttk::frame $label_frame

			set input_label "$label_frame.label"
			ttk::label $input_label -text "Text:"

			set input_entry_elem "$label_frame.entry"
			ttk::entry $input_entry_elem -width 32 -background white \
				-foreground $label_color \
				-font $label_font
			$input_entry_elem insert 0 $label_text
			dict set callback_elems "label_elem" $input_entry_elem

			pack $input_label $input_entry_elem \
				-side left -anchor w -padx 2 -pady 2 -fill x
			pack $label_frame -side top -fill x
			pack $input_frame -side top -fill x

			set design_frame "$top_window.colors"
			ttk::frame $design_frame -borderwidth 2 -padding 2

			# color selection
			set colors_button_elem "$design_frame.fg_chooser"
			ttk::button $colors_button_elem -text "Text color" \
				-command "popupColor foreground $input_entry_elem false $design_frame"

			# font selection
			tk fontchooser configure -parent $top_window

			set font_button_elem "$design_frame.font_chooser"
			ttk::button $font_button_elem -text "Font" \
				-command "fontchooserFocus $input_entry_elem; fontchooserToggle"

			pack $colors_button_elem -side left -pady 2
			pack $font_button_elem -side left -pady 2 -padx 10
			pack $design_frame -side top -fill x
		}
	}

	set apply_cmd "popupAnnotationApply $target [list $callback_elems]"
	# Modify existing annotation or add a new one?
	if { $modify == "true" } {
		set cancel_cmd "destroy $top_window"
		set apply_text "Modify $annotation_type"
	} else {
		set cancel_cmd "destroy $top_window; destroyNewAnnotation $annotation_type"
		set apply_text "Add $annotation_type"
	}

	set buttons_frame "$top_window.buttons_frame"
	ttk::frame $buttons_frame -borderwidth 6 -padding 2
	pack $buttons_frame -fill both -expand 1

	set apply_button_elem "$buttons_frame.apply"
	ttk::button $apply_button_elem \
		-text $apply_text \
		-command $apply_cmd

	set cancel_button_elem "$buttons_frame.cancel"
	ttk::button $cancel_button_elem \
		-text "Cancel" \
		-command $cancel_cmd

	pack $apply_button_elem -side left -expand 1 -anchor e
	pack $cancel_button_elem -side right -expand 1 -anchor w
	pack $buttons_frame -side bottom

	bind $top_window <Key-Escape> $cancel_cmd
	bind $top_window <Key-Return> $apply_cmd

	return
}

#****f* annotations.tcl/popupAnnotationApply
# NAME
#   popupAnnotationApply -- popup oval apply
# SYNOPSIS
#   popupAnnotationApply $wi $target
# FUNCTION
#   Creates a new annotation on the canvas from the popup dialog.
# INPUTS
#   * wi -- widget
#   * target -- existing or a new annotation
#****
proc popupAnnotationApply { target callback_elems } {
	global main_canvas_elem changed
	global node_cfg_gui

	set annotation_type [_getAnnotationType $node_cfg_gui]
	global new$annotation_type

	set curcanvas [getFromRunning_gui "curcanvas"]
	# subtract 5 from each value and assign to variables sizex sizey
	lassign [lmap n [getCanvasSize $curcanvas] {expr $n - 5}] sizex sizey

	# default values
	set annotation_color ""
	set border_width 1
	set border_color ""
	set corner_radius 25
	set label_text ""
	set label_color ""
	set label_font ""

	set annotation_color_elem [dictGet $callback_elems "annotation_color"]
	if { $annotation_color_elem != "" } {
		set annotation_color [$annotation_color_elem cget -text]
	}

	set border_color_elem [dictGet $callback_elems "border_color"]
	if { $border_color_elem != "" } {
		set border_color [$border_color_elem cget -text]
	}

	set border_width_elem [dictGet $callback_elems "border_width"]
	if { $border_width_elem != "" } {
		set border_width [$border_width_elem get]
		if { ! [string is integer $border_width] || $border_width < 0 } {
			set border_width 1
		}
	}

	set corner_radius_elem [dictGet $callback_elems "corner_radius"]
	if { $corner_radius_elem != "" } {
		set corner_radius [$corner_radius_elem get]
	}

	set label_elem [dictGet $callback_elems "label_elem"]
	if { $label_elem != "" } {
		set label_text [string trim [$label_elem get]]
		set label_color [$label_elem cget -foreground]
		set label_font [$label_elem cget -font]
	}

	# just quit if text is empty
	if { $annotation_type == "text" && $label_text == "" } {
		destroyNewAnnotation $annotation_type

		redrawAll
		destroy [dict get $callback_elems "parent_widget"]

		return
	}

	if { $target == "new" } {
		# Create a new annotation object
		set target [newObjectId [getFromRunning_gui "annotation_list"] "a"]
		addAnnotation $target $annotation_type

		# pop this annotation to the top
		set new_order [removeFromList [getCanvasAnnotationOrder $curcanvas] $target]
		if { $new_order == {} } {
			set new_order "grid"
		}

		lappend new_order $target
		setCanvasAnnotationOrder $curcanvas $new_order

		set annotation_coords [lmap n [$main_canvas_elem coords [set new$annotation_type]] {
			expr int($n / [getActiveOption "zoom"])
		}]

		switch -exact -- $annotation_type {
			"oval" -
			"rectangle" {
				if { [lindex $annotation_coords 0] < 0 } {
					set annotation_coords [lreplace $annotation_coords 0 0 5]
				}
				if { [lindex $annotation_coords 1] < 0 } {
					set annotation_coords [lreplace $annotation_coords 1 1 5]
				}
				if { [lindex $annotation_coords 2] > $sizex } {
					set annotation_coords [lreplace $annotation_coords 2 2 $sizex]
				}
				if { [lindex $annotation_coords 3] > $sizey } {
					set annotation_coords [lreplace $annotation_coords 3 3 $sizey]
				}
			}

			"freeform" {
			}

			"text" {
			}
		}
	} else {
		# if annotation has moved or deleted while being edited
		set annotation_coords [getAnnotationCoords $target]
		if { $annotation_coords == {} } {
			destroy [dict get $callback_elems "parent_widget"]

			return
		}
	}

	set node_cfg_gui [_setAnnotationCoords $node_cfg_gui $annotation_coords]

	switch -exact -- $annotation_type {
		"oval" -
		"rectangle" -
		"freeform" {
			set node_cfg_gui [_setAnnotationColor $node_cfg_gui $annotation_color]
			set node_cfg_gui [_setAnnotationWidth $node_cfg_gui $border_width]

			if { $annotation_type in "oval rectangle" } {
				set node_cfg_gui [_setAnnotationBorderColor $node_cfg_gui $border_color]
			}

			if { $annotation_type == "rectangle" } {
				set node_cfg_gui [_setAnnotationRad $node_cfg_gui $corner_radius]
			}
		}

		"text" {
			set node_cfg_gui [_setAnnotationLabel $node_cfg_gui $label_text]
			set node_cfg_gui [_setAnnotationLabelColor $node_cfg_gui $label_color]
			set node_cfg_gui [_setAnnotationFont $node_cfg_gui $label_font]
		}
	}

	set node_cfg_gui [_setAnnotationCanvas $node_cfg_gui $curcanvas]

	destroyNewAnnotation $annotation_type

	updateAnnotationGUI $target "*" $node_cfg_gui
	set node_cfg_gui [cfgGet "gui" "annotations" $target]

	redrawAll
	destroy [dict get $callback_elems "parent_widget"]
}

#****f* annotations.tcl/drawAnnotation
# NAME
#   drawAnnotation -- draw annotation
# SYNOPSIS
#   drawAnnotation $annotation_id
# FUNCTION
#   Draws a specified annotation.
# INPUTS
#   * annotation_id -- annotation ID
#****
proc drawAnnotation { annotation_id } {
	global main_canvas_elem all_annotation_types

	set annotation_type [getAnnotationType $annotation_id]
	if { $annotation_type ni $all_annotation_types } {
		sputs stderr "No such annotation type '$annotation_type'"

		return
	}

	set annotation_coords [getAnnotationCoords $annotation_id]
	set annotation_color [getAnnotationColor $annotation_id]
	set border_color [getAnnotationBorderColor $annotation_id]
	set border_width [getAnnotationWidth $annotation_id]

	if { $annotation_color == "" } { set annotation_color [getActiveOption "default_fill_color"] }
	if { $border_color == "" } { set border_color black }
	if { $border_width == "" && $annotation_type != "freeform" } { set border_width 1 }

	set zoom [getActiveOption "zoom"]

	# multiply each coordinate with $zoom and assign to variables x1, y1, x2, y2
	lassign [lmap n $annotation_coords {expr $n * $zoom}] x1 y1 x2 y2

	switch -exact -- $annotation_type {
		"oval" {
			set new_annotation [$main_canvas_elem create oval $x1 $y1 $x2 $y2 \
				-fill $annotation_color \
				-width [expr int($border_width * $zoom)] \
				-outline $border_color]
		}

		"rectangle" {
			set corner_radius [getAnnotationRad $annotation_id]
			if { $corner_radius == "" } { set corner_radius 25 }

			set new_annotation [roundRectangle $main_canvas_elem $x1 $y1 $x2 $y2 [expr int($corner_radius * $zoom)] \
				-fill $annotation_color]

			if { $border_width != 0 } {
				$main_canvas_elem itemconfigure $new_annotation \
					-width [expr int($border_width * $zoom)] \
					-outline $border_color
			}
		}

		"freeform" {
			if { $border_width == "" } { set border_width 2 }

			set coords_length [expr { [llength $annotation_coords] - 2 }]
			if { $coords_length < 0 } {
				return
			}

			set new_annotation [$main_canvas_elem create line $x1 $y1 $x2 $y2 \
				-fill $annotation_color \
				-width $border_width]
			
			set iter 2
			while { $iter <= $coords_length } {
				lassign [lmap n [lrange $annotation_coords $iter $iter+1] {expr $n * $zoom}] x1 y1
				xpos $new_annotation $x1 $y1 $border_width $annotation_color

				incr iter 2
			}
		}

		"text" {
			set label_color [getAnnotationLabelColor $annotation_id]
			set label_text [getAnnotationLabel $annotation_id]
			set label_font [getAnnotationFont $annotation_id]

			if { $label_color == "" } { set label_color [getActiveOption "default_text_color"] }
			if { $label_font == "" } { set label_font TkTextFont }
			set label_font [font actual $label_font]

			dict set label_font "-size" [expr int([dict get [font actual $label_font] "-size"] * $zoom)]
			set new_annotation [$main_canvas_elem create text $x1 $y1 \
				-anchor w -justify left \
				-text $label_text \
				-font $label_font \
				-fill $label_color]
		}
	}

	$main_canvas_elem itemconfigure $new_annotation -tags "$annotation_type $annotation_id"
	$main_canvas_elem raise $new_annotation
}

#****f* annotations.tcl/destroyNewAnnotation
# NAME
#   destroyNewAnnotation -- destroy new oval
# SYNOPSIS
#   destroyNewAnnotation
# FUNCTION
#   Destroys newly made (or abandoned) annotation template.
#****
proc destroyNewAnnotation { annotation_type } {
	global main_canvas_elem
	global new$annotation_type

	$main_canvas_elem delete -withtags "new$annotation_type"
	set new$annotation_type ""
}

#****f* annotations.tcl/annotationConfigGUI
# NAME
#   annotationConfigGUI -- annotation configuration GUI
# SYNOPSIS
#   annotationConfigGUI
# FUNCTION
#   Creates a GUI for specified annotation on the canvas.
#****
proc annotationConfigGUI {} {
	global main_canvas_elem

	set annotation_id [lindex [$main_canvas_elem gettags current] 1]
	annotationConfig $annotation_id

	return
}

#****f* annotations.tcl/annotationConfig
# NAME
#   annotationConfig -- annotation configuration
# SYNOPSIS
#   annotationConfig $target
# FUNCTION
#   Creates new or modifies existing annotation configuration on the canvas.
# INPUTS
#   * target -- existing or a new annotation
#****
proc annotationConfig { target } {
	global all_annotation_types

	set annotation_type [getAnnotationType $target]
	if { $annotation_type ni $all_annotation_types } {
		# should not happen
		set err "Unknown type $annotation_type for target $target"
		after idle { .dialog1.msg configure -wraplength 5i }
		tk_dialog .dialog1 "IMUNES error" \
			$err \
			info 0 Dismiss
	}

	popupAnnotationDialog $target $annotation_type "true"
}

#****f* annotations.tcl/button3annotation
# NAME
#   button3annotation -- button3 annotation
# SYNOPSIS
#   button3annotation $type $x $y
# FUNCTION
#   Shows the annotation menu when an annotation right clicked.
# INPUTS
#   * type -- type of annotation
#   * x -- x coordinate
#   * y -- y coordinate
#****
proc button3annotation { type x y } {
	global main_canvas_elem all_annotation_types

	if { $type ni "label $all_annotation_types" } {
		return
	}

	set annotation_id [lindex [$main_canvas_elem gettags "$type && current"] 1]
	if { $annotation_id == "" } {
		return
	}

	set wasselected [expr {$annotation_id in [selectedAnnotations]}]
	if { ! $wasselected } {
		foreach node_type "node $all_annotation_types" {
			$main_canvas_elem dtag $node_type selected
		}
		$main_canvas_elem delete -withtags selectmark
	}

	selectNode [$main_canvas_elem find withtag "current"]

	.button3menu delete 0 end

	set menutext "$type $annotation_id"
	.button3menu add command -label "Configure $menutext" \
		-command "annotationConfig $annotation_id"
	.button3menu add command -label "Delete $menutext" \
		-command "deleteSelection"

	.button3menu add separator

	#
	# Annotation order
	#
	set curcanvas [getFromRunning_gui "curcanvas"]
	set annotation_order [getCanvasAnnotationOrder $curcanvas]

	if { $annotation_id != [lindex $annotation_order end] } {
		.button3menu add command -label "Bring to top" \
			-command "setAnnotationOrderGUI $annotation_id top"
		.button3menu add command -label "Level up" \
			-command "setAnnotationOrderGUI $annotation_id up"
	} else {
		.button3menu add command -label "Bring to top" \
			-state disabled
		.button3menu add command -label "Level up" \
			-state disabled
	}

	if { $annotation_id != [lindex $annotation_order 0] } {
		.button3menu add command -label "Level down" \
			-command "setAnnotationOrderGUI $annotation_id down"
		.button3menu add command -label "Send to bottom" \
			-command "setAnnotationOrderGUI $annotation_id bottom"
	} else {
		.button3menu add command -label "Level down" \
			-state disabled
		.button3menu add command -label "Send to bottom" \
			-state disabled
	}

	.button3menu add separator

	#
	# Move to another canvas
	#
	.button3menu.moveto delete 0 end
	.button3menu add cascade -label "Move to" \
		-menu .button3menu.moveto
	.button3menu.moveto add command -label "Canvas:" -state disabled

	foreach canvas_id [getFromRunning_gui "canvas_list"] {
		if { $canvas_id != $curcanvas } {
			.button3menu.moveto add command \
				-label [getCanvasName $canvas_id] \
				-command "moveToCanvas $canvas_id"
		} else {
			.button3menu.moveto add command \
				-label [getCanvasName $canvas_id] -state disabled
		}
	}

	set x [winfo pointerx .]
	set y [winfo pointery .]
	tk_popup .button3menu $x $y
}

#****f* annotations.tcl/roundRectangle
# NAME
#   roundRectangle -- round rectangle
# SYNOPSIS
#   roundRectangle $w $x0 $y0 $x3 $y3 $radius $args
# FUNCTION
#   Creates a round rectangle annotation.
# INPUTS
#   * w -- width
#   * x0 -- top left x coordinate
#   * y0 -- top left y coordinate
#   * x3 -- bottom right x coordinate
#   * y3 -- bottom left x coordinate
#   * radius -- radius for rounded edges
#   * args -- additional arguments
# RESULT
#   * rectangle -- the resulting  rounded rectangle annotation
#****
proc roundRectangle { w x0 y0 x3 y3 radius args } {
	set r [winfo pixels $w $radius]
	set d [expr { 2 * $r }]

	# Make sure that the radius of the curve is less than 3/8 size of the box
	set maxr 0.75

	if { $d > $maxr * ( $x3 - $x0 ) } {
		set d [expr { $maxr * ( $x3 - $x0 ) }]
	}
	if { $d > $maxr * ( $y3 - $y0 ) } {
		set d [expr { $maxr * ( $y3 - $y0 ) }]
	}

	set x1 [expr { $x0 + $d }]
	set x2 [expr { $x3 - $d }]
	set y1 [expr { $y0 + $d }]
	set y2 [expr { $y3 - $d }]

	set cmd [list $w create polygon]
	lappend cmd $x0 $y0 $x1 $y0 $x2 $y0 $x3 $y0 $x3 $y1 $x3 $y2
	lappend cmd $x3 $y3 $x2 $y3 $x1 $y3 $x0 $y3 $x0 $y2 $x0 $y1
	lappend cmd -smooth 1

	return [eval $cmd $args]
}

#****f* annotations.tcl/fontchooserToggle
# NAME
#   fontchooserToggle -- font chooser toggle
# SYNOPSIS
#   fontchooserToggle
# FUNCTION
#   Shows or hides the font chooser dialog.
#****
proc fontchooserToggle {} {
	tk fontchooser [expr {[tk fontchooser configure -visible] ? "hide" : "show"}]
}

#****f* annotations.tcl/fontchooserFocus
# NAME
#   fontchooserFocus -- font chooser focus
# SYNOPSIS
#   fontchooserFocus $w
# FUNCTION
#   Calls the procedure to change the font.
# INPUTS
#   * w -- widget
#****
proc fontchooserFocus { w } {
	tk fontchooser configure -font [$w cget -font] \
		-command [list fontchooserFontSelection $w]
}

#****f* annotations.tcl/fontchooserFontSelection
# NAME
#   fontchooserFontSelection -- font chooser font selection
# SYNOPSIS
#   fontchooserFontSelection $w $font $args
# FUNCTION
#   Sets font.
# INPUTS
#   * w -- widget
#   * font -- font
#   * args -- font arguments
#****
proc fontchooserFontSelection { w font args } {
	$w configure -font [font actual $font]
}

#****f* annotations.tcl/popupColor
# NAME
#   popupColor -- popup color
# SYNOPSIS
#   popupColor $type $l $settext
# FUNCTION
#   Color chooser popup for annotations,
# INPUTS
#   * type -- foreground or background color
#   * l -- label which background color is changed
#   * settext -- variable that defines if the text needs to be set to the color
#****
proc popupColor { type l settext parent_widget } {
	# popup color selection dialog with current color
	if { $type == "foreground" } {
		set initcolor [$l cget -foreground]
	} else {
		set initcolor [$l cget -background]
	}

	if { $initcolor == "" } {
		set initcolor #808080
	}

	set newcolor [tk_chooseColor -parent $parent_widget -initialcolor $initcolor]

	# set fg or bg of the "l" label control
	if { $newcolor == "" } {
		return
	}

	if { $settext == "true" } {
		$l configure -text $newcolor -$type $newcolor
	} else {
		$l configure -$type $newcolor
	}
}

#****f* annotations.tcl/selectmarkEnter
# NAME
#   selectmarkEnter -- select mark enter
# SYNOPSIS
#   selectmarkEnter $x $y
# FUNCTION
#   Changes the mouse cursor for resizing annotations.
# INPUTS
#   * x -- cursor x coordinate
#   * y -- cursor y coordinate
#****
proc selectmarkEnter { x y } {
	global main_canvas_elem

	if { [getActiveTool] != "select" } {
		return
	}

	set obj [lindex [$main_canvas_elem gettags current] 1]
	set type [getAnnotationType $obj]

	if { $type ni "oval rectangle" } {
		return
	}

	set bbox [$main_canvas_elem bbox $obj]
	set x1 [lindex $bbox 0]
	set y1 [lindex $bbox 1]
	set x2 [lindex $bbox 2]
	set y2 [lindex $bbox 3]
	set l 0 ;# left
	set r 0 ;# right
	set u 0 ;# up
	set d 0 ;# down

	set x [$main_canvas_elem canvasx $x]
	set y [$main_canvas_elem canvasy $y]

	if { $x < [expr $x1+($x2-$x1)/8.0]} { set l 1 }
	if { $x > [expr $x2-($x2-$x1)/8.0]} { set r 1 }
	if { $y < [expr $y1+($y2-$y1)/8.0]} { set u 1 }
	if { $y > [expr $y2-($y2-$y1)/8.0]} { set d 1 }

	if { $l==1 } {
		if { $u==1 } {
			$main_canvas_elem config -cursor top_left_corner
		} elseif { $d==1 } {
			$main_canvas_elem config -cursor bottom_left_corner
		} else {
			$main_canvas_elem config -cursor left_side
		}
	} elseif { $r==1 } {
		if { $u==1 } {
			$main_canvas_elem config -cursor top_right_corner
		} elseif { $d==1 } {
			$main_canvas_elem config -cursor bottom_right_corner
		} else {
			$main_canvas_elem config -cursor right_side
		}
	} elseif { $u==1 } {
		$main_canvas_elem config -cursor top_side
	} elseif { $d==1 } {
		$main_canvas_elem config -cursor bottom_side
	} else {
		$main_canvas_elem config -cursor left_ptr
	}
}

#****f* annotations.tcl/selectmarkLeave
# NAME
#   selectmarkLeave -- selet mark leave
# SYNOPSIS
#   selectmarkLeave $x $y
# FUNCTION
#   Resets the mouse cursor when leaving the annotation.
# INPUTS
#   * x -- cursor x coordinate
#   * y -- cursor y coordinate
#****
proc selectmarkLeave { x y } {
	global main_canvas_elem

	.bottom.textbox config -text {}
	$main_canvas_elem config -cursor left_ptr
}

#****f* annotations.tcl/backgroundImage
# NAME
#   backgroundImage -- set canvas background image
# SYNOPSIS
#   backgroundImage $img_data
# FUNCTION
#   Load and draw a background image on the specified canvas.
# INPUTS
#   * img -- variable that contains the image data in the memory
#****
proc backgroundImage { img } {
	global sizex sizey main_canvas_elem

	set zoom [getActiveOption "zoom"]
	set e_sizex [expr {int($sizex * $zoom)}]
	set e_sizey [expr {int($sizey * $zoom)}]

	if { "$img" == "" } {
		return
	}

	set img_data [getImageData $img]

	image create photo Photo -data $img_data

	set image_h [image height Photo]
	set image_w [image width Photo]

	set rx [expr $e_sizex * 1.0 / $image_w]
	set ry [expr $e_sizey  * 1.0/ $image_h]

	if { $rx < $ry } {
		set factor [expr $rx * 100]
	} else {
		set factor [expr $ry * 100]
	}

	set factor [expr int($factor)]

	if { $factor != 100 } {
		if { [getImageZoomData $img $factor] != "" } {
			image create photo Photo -data [getImageZoomData $img $factor]
			set image Photo
		} else {
			set image [image% Photo $factor $img]
		}
	} else {
		set image Photo
	}

	$main_canvas_elem create image 0 0 -anchor nw -image $image -tags "background"
}

#****f* annotations.tcl/image%
# NAME
#   image% -- image percentage
# SYNOPSIS
#   image% $image $percent $img_name
# FUNCTION
#   Scales the background image to the specified percentage.
# INPUTS
#   * image -- image data
#   * percent -- percantage
#   * img_name -- image name
#****
proc image% { image percent img_name } {
	global hasIM winOS

	set image_h [image height $image]
	set image_w [image width $image]
	if { $hasIM && [expr {$image_h > 100 || $image_w > 100}] } {
		set fname "original.gif"
		$image write $fname
		if { ! $winOS } {
			exec magick $fname -resize $percent\% zoom_$percent.gif
		} else {
			exec cmd /c magick $fname -resize $percent\% zoom_$percent.gif
		}

		set im2 [image create photo -file zoom_$percent.gif]
		setImageZoomData $img_name zoom_$percent.gif $percent
		if { ! $winOS } {
			exec rm $fname zoom_$percent.gif
		} else {
			catch { exec cmd /c del $fname zoom_$percent.gif } err
		}
	} else {
		set deno [gcd $percent 100]
		set zoom [expr {$percent/$deno}]
		set subsample [expr {100/$deno}]

		set im1 [image create photo]
		$im1 copy $image -zoom $zoom

		set im2 [image create photo]
		$im2 copy $im1 -subsample $subsample

		image delete $im1
	}

	set im2
}

#****f* annotations.tcl/gcd
# NAME
#   gcd -- greatest common divisor
# SYNOPSIS
#   gcd $u $v
# FUNCTION
#   Returns the greatest common divisor of two specified whole numbers.
# INPUTS
#   * u -- first number
#   * v -- second number
#****
proc gcd { u v } {
	expr { $u ? [gcd [expr $v%$u] $u] : $v }
}

#****f* editor.tcl/xpos
# NAME
#   xpos -- interpolates data for freeform annotations
# SYNOPSIS
#   xpos $tempfree $x $y $width $color
# FUNCTION
#   This procedure is used to interpolate data for freeform annotations to
#   reduce the amount of fixed points that need to be saved for freeform
#   annotations.
# INPUTS
#   * tempfree -- temporary freefrom when drawing
#   * x -- endpoint x coordinate
#   * y -- endpoint y coordinate
#   * width -- freeform width
#   * color -- freeform color
#****
proc xpos { tempfree x y width color } {
	global main_canvas_elem

	set all_dots [$main_canvas_elem coords $tempfree]
	set len [llength $all_dots]

	# Remove dots one very close to another
	set d 1.5
	set i [expr $len - 20]
	if { $i < 2 } {
		set i 2
	}

	for {} { $i < $len } { incr i 2 } {
		set a_x [lindex $all_dots [expr $i - 2]]
		set a_y [lindex $all_dots [expr $i - 1]]
		set b_x [lindex $all_dots $i]
		set b_y [lindex $all_dots [expr $i + 1]]
		if { [expr abs($a_x - $b_x)] < $d && [expr abs($a_y - $b_y)] < $d } {
			set all_dots [lreplace $all_dots $i [expr $i + 1]]
			incr len -2
		}
	}

	# Remove dots which can be safely linearly interpolated
	set d 1.5
	set i [expr $len - 20]
	if { $i < 2 } {
		set i 2
	}

	for {} { $i < $len } { incr i 2 } {
		set a_x [lindex $all_dots [expr $i - 4]]
		set a_y [lindex $all_dots [expr $i - 3]]
		set b_x [lindex $all_dots [expr $i - 2]]
		set b_y [lindex $all_dots [expr $i - 1]]
		set c_x [lindex $all_dots $i]
		set c_y [lindex $all_dots [expr $i + 1]]
		if {
			[expr abs(($a_x + $c_x) / 2 - $b_x)] < $d &&
			[expr abs(($a_y + $c_y) / 2 - $b_y)] < $d
		} {
			set all_dots [lreplace $all_dots [expr $i - 2] [expr $i - 1]]
			incr len -2
		}
	}

	$main_canvas_elem coords $tempfree [concat $all_dots $x $y]
	$main_canvas_elem itemconfigure $tempfree -fill $color -width $width -capstyle round
}
