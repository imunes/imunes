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

#****f* annotations_gui.tcl/getAnnotationType
# NAME
#   getAnnotationType -- get annotation type
# SYNOPSIS
#   getAnnotationType $annotation_id
# FUNCTION
#   Returns the specified annotation's type.
# INPUTS
#   * annotation_id -- annotation object
# RESULT
#   * type -- annotation type
#****
proc getAnnotationType { annotation_id } {
	return [cfgGet "gui" "annotations" $annotation_id "type"]
}

#****f* annotations_gui.tcl/setAnnotationType
# NAME
#   setAnnotationType -- set annotation type
# SYNOPSIS
#   setAnnotationType $annotation_id $type
# FUNCTION
#   Sets annotation type.
# INPUTS
#   * annotation_id -- annotation id
#   * type -- annotation type
#****
proc setAnnotationType { annotation_id type } {
	cfgSet "gui" "annotations" $annotation_id "type" $type
}

#****f* annotations_gui.tcl/getAnnotationCanvas
# NAME
#   getAnnotationCanvas -- get annotation canvas id
# SYNOPSIS
#   getAnnotationCanvas $annotation_id
# FUNCTION
#   Returns the specified annotation's canvas.
# INPUTS
#   * annotation_id -- annotation object
# RESULT
#   * canvas_id -- canvas id
#****
proc getAnnotationCanvas { annotation_id } {
	return [cfgGet "gui" "annotations" $annotation_id "canvas"]
}

#****f* annotations_gui.tcl/setAnnotationCanvas
# NAME
#   setAnnotationCanvas -- set annotation canvas
# SYNOPSIS
#   setAnnotationCanvas $annotation_id $canvas_id
# FUNCTION
#   Sets annotation canvas id.
# INPUTS
#   * annotation_id -- annotation id
#   * canvas_id -- canvas id
#****
proc setAnnotationCanvas { annotation_id canvas_id } {
	cfgSet "gui" "annotations" $annotation_id "canvas" $canvas_id
}

#****f* annotations_gui.tcl/getAnnotationColor
# NAME
#   getAnnotationColor -- get annotation color
# SYNOPSIS
#   getAnnotationColor $annotation_id
# FUNCTION
#   Returns the specified annotation's color.
# INPUTS
#   * annotation_id -- annotation object
# RESULT
#   * color -- annotation color
#****
proc getAnnotationColor { annotation_id } {
	return [cfgGet "gui" "annotations" $annotation_id "color"]
}

#****f* annotations_gui.tcl/setAnnotationColor
# NAME
#   setAnnotationColor -- set annotation color
# SYNOPSIS
#   setAnnotationColor $annotation_id $color
# FUNCTION
#   Sets annotation color.
# INPUTS
#   * annotation_id -- annotation id
#   * color -- color
#****
proc setAnnotationColor { annotation_id color } {
	cfgSet "gui" "annotations" $annotation_id "color" $color
}

#****f* annotations_gui.tcl/getAnnotationLabel
# NAME
#   getAnnotationLabel -- get annotation label
# SYNOPSIS
#   getAnnotationLabel $annotation_id
# FUNCTION
#   Returns the specified annotation label
# INPUTS
#   * annotation_id -- annotation object
# RESULT
#   * labeltext -- annotation label
#****
proc getAnnotationLabel { annotation_id } {
	return [cfgGet "gui" "annotations" $annotation_id "label"]
}

#****f* annotations_gui.tcl/setAnnotationLabel
# NAME
#   setAnnotationLabel -- set annotation label
# SYNOPSIS
#   setAnnotationLabel $annotation_id $labeltext
# FUNCTION
#   Sets annotation label.
# INPUTS
#   * annotation_id -- annotation id
#   * labeltext -- label text
#****
proc setAnnotationLabel { annotation_id labeltext } {
	cfgSet "gui" "annotations" $annotation_id "label" $labeltext
}

#****f* annotations_gui.tcl/getAnnotationLabelColor
# NAME
#   getAnnotationLabelColor -- get annotation label color
# SYNOPSIS
#   getAnnotationLabelColor $annotation_id
# FUNCTION
#   Returns the specified annotation's label color.
# INPUTS
#   * annotation_id -- annotation object
# RESULT
#   * labelcolor -- annotation label color
#****
proc getAnnotationLabelColor { annotation_id } {
	return [cfgGet "gui" "annotations" $annotation_id "labelcolor"]
}

#****f* annotations_gui.tcl/setAnnotationLabelColor
# NAME
#   setAnnotationLabelColor -- set annotation's label color
# SYNOPSIS
#   setAnnotationLabelColor $annotation_id $labelcolor
# FUNCTION
#   Sets annotation's label color.
# INPUTS
#   * annotation_id -- annotation id
#   * labelcolor -- label color
#****
proc setAnnotationLabelColor { annotation_id labelcolor } {
	cfgSet "gui" "annotations" $annotation_id "labelcolor" $labelcolor
}

#****f* annotations_gui.tcl/getAnnotationBorderColor
# NAME
#   getAnnotationBorderColor -- get annotation border color
# SYNOPSIS
#   getAnnotationBorderColor $annotation_id
# FUNCTION
#   Returns the specified annotation's border color.
# INPUTS
#   * annotation_id -- annotation object
# RESULT
#   * bcolor -- annotation border color
#****
proc getAnnotationBorderColor { annotation_id } {
	return [cfgGet "gui" "annotations" $annotation_id "bordercolor"]
}

#****f* annotations_gui.tcl/setAnnotationBorderColor
# NAME
#   setAnnotationBorderColor -- set annotation border color
# SYNOPSIS
#   setAnnotationBorderColor $annotation_id $bordercolor
# FUNCTION
#   Sets annotation border color
# INPUTS
#   * annotation_id -- annotation id
#   * bordercolor -- border color
#****
proc setAnnotationBorderColor { annotation_id bordercolor } {
	cfgSet "gui" "annotations" $annotation_id "bordercolor" $bordercolor
}

#****f* annotations_gui.tcl/getAnnotationWidth
# NAME
#   getAnnotationWidth -- get annotation width
# SYNOPSIS
#   getAnnotationWidth $annotation_id
# FUNCTION
#   Returns the specified annotation's width.
# INPUTS
#   * annotation_id -- annotation object
# RESULT
#   * width -- annotation width
#****
proc getAnnotationWidth { annotation_id } {
	return [cfgGet "gui" "annotations" $annotation_id "width"]
}

#****f* annotations_gui.tcl/setAnnotationWidth
# NAME
#   setAnnotationWidth -- set annotation width
# SYNOPSIS
#   setAnnotationWidth $annotation_id $width
# FUNCTION
#   Sets annotation width.
# INPUTS
#   * annotation_id -- annotation id
#   * width -- width
#****
proc setAnnotationWidth { annotation_id width } {
	cfgSet "gui" "annotations" $annotation_id "width" $width
}

#****f* annotations_gui.tcl/getAnnotationRad
# NAME
#   getAnnotationRad -- get annotation radius
# SYNOPSIS
#   getAnnotationRad $annotation_id
# FUNCTION
#   Returns the specified annotation's radius.
# INPUTS
#   * annotation_id -- annotation object
# RESULT
#   * rad -- annotation radius
#****
proc getAnnotationRad { annotation_id } {
	return [cfgGet "gui" "annotations" $annotation_id "rad"]
}

#****f* annotations_gui.tcl/setAnnotationRad
# NAME
#   setAnnotationRad -- set annotation radius
# SYNOPSIS
#   setAnnotationRad $annotation_id $rad
# FUNCTION
#   Sets annotation radius.
# INPUTS
#   * annotation_id -- annotation id
#   * rad -- radius
#****
proc setAnnotationRad { annotation_id rad } {
	cfgSet "gui" "annotations" $annotation_id "rad" $rad
}

#****f* annotations_gui.tcl/getAnnotationFont
# NAME
#   getAnnotationFont -- get annotation font
# SYNOPSIS
#   getAnnotationFont $annotation_id
# FUNCTION
#   Returns the specified annotation's font.
# INPUTS
#   * annotation_id -- annotation object
# RESULT
#   * font -- annotation font
#****
proc getAnnotationFont { annotation_id } {
	return [cfgGet "gui" "annotations" $annotation_id "font"]
}

#****f* annotations_gui.tcl/setAnnotationFont
# NAME
#   setAnnotationFont -- set annotation font
# SYNOPSIS
#   setAnnotationFont $annotation_id $font
# FUNCTION
#   Sets annotation font.
# INPUTS
#   * annotation_id -- annotation id
#   * font -- font
#****
proc setAnnotationFont { annotation_id font } {
	cfgSet "gui" "annotations" $annotation_id "font" $font
}

#****f* annotations_gui.tcl/getAnnotationCoords
# NAME
#   getAnnotationCoords -- get annotation coordinates
# SYNOPSIS
#   getAnnotationCoords $annotation_id
# FUNCTION
#   Returns the specified annotation's coordinates.
# INPUTS
#   * annotation_id -- annotation object
# RESULT
#   * coords -- annotation coordinates
#****
proc getAnnotationCoords { annotation_id } {
	return [cfgGet "gui" "annotations" $annotation_id "iconcoords"]
}

#****f* annotations_gui.tcl/setAnnotationCoords
# NAME
#   setAnnotationCoords -- set annotation coordinates
# SYNOPSIS
#   setAnnotationCoords $annotation_id $coords
# FUNCTION
#   Sets annotation coordinates.
# INPUTS
#   * annotation_id -- annotation id
#   * coords -- coordinates
#****
proc setAnnotationCoords { annotation_id coords } {
	set roundcoords {}
	foreach c $coords {
		set x [expr round($c)]
		lappend roundcoords $x
	}

	cfgSet "gui" "annotations" $annotation_id "iconcoords" $roundcoords
}
