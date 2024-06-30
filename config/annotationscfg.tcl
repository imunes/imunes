#****f* annotations_cfg.tcl/addAnnotation
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
    lappendToRunning "annotation_list" $annotation_id
    setAnnotationType $annotation_id $type
}

#****f* annotations.tcl/deleteAnnotation
# NAME
#   deleteAnnotation -- delete annotation
# SYNOPSIS
#   deleteAnnotation $annotation_id $type
# FUNCTION
#   Deletes annotation from canvas.
# INPUTS
#   * annotation_id -- existing annotation
#   * type -- type of annimation
#****
proc deleteAnnotation { annotation_id type } {
    global changed

    setToRunning "annotation_list" [removeFromList [getFromRunning "annotation_list"] $annotation_id]
    cfgUnset "annotations" $annotation_id

    set changed 1
    updateUndoLog
    redrawAll
}

proc getAnnotationType { annotation_id } {
    return [cfgGet "annotations" $annotation_id "type"]
}

proc setAnnotationType { annotation_id type } {
    cfgSet "annotations" $annotation_id "type" $type
}

proc getAnnotationCanvas { annotation_id } {
    return [cfgGet "annotations" $annotation_id "canvas"]
}

proc setAnnotationCanvas { annotation_id canvas_id } {
    cfgSet "annotations" $annotation_id "canvas" $canvas_id
}

#****f* annotations_cfg.tcl/getAnnotationColor
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
    return [cfgGet "annotations" $annotation_id "color"]
}

#****f* annotations_cfg.tcl/setAnnotationColor
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
    cfgSet "annotations" $annotation_id "color" $color
}

#****f* annotations_cfg.tcl/getAnnotationLabel
# NAME
#   getAnnotationLabel -- get annotation label
# SYNOPSIS
#   getAnnotationLabel $annotation_id
# FUNCTION
#   Returns the specified annotation label
# INPUTS
#   * annotation_id -- annotation object
# RESULT
#   * label -- annotation label
#****
proc getAnnotationLabel { annotation_id } {
    return [cfgGet "annotations" $annotation_id "label"]
}

#****f* annotations_cfg.tcl/setAnnotationLabel
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
    cfgSet "annotations" $annotation_id "label" $labeltext
}

#****f* annotations_cfg.tcl/getAnnotationLColor
# NAME
#   getAnnotationLColor -- get annotation label color
# SYNOPSIS
#   getAnnotationLColor $annotation_id
# FUNCTION
#   Returns the specified annotation's label color.
# INPUTS
#   * annotation_id -- annotation object
# RESULT
#   * labelcolor -- annotation label color
#****
proc getAnnotationLColor { annotation_id } {
    return [cfgGet "annotations" $annotation_id "labelcolor"]
}

#****f* annotations_cfg.tcl/setAnnotationLColor
# NAME
#   setAnnotationLColor -- set annotation's label color
# SYNOPSIS
#   setAnnotationLColor $annotation_id $labelcolor
# FUNCTION
#   Sets annotation's label color.
# INPUTS
#   * annotation_id -- annotation id
#   * labelcolor -- label color
#****
proc setAnnotationLColor { annotation_id labelcolor } {
    cfgSet "annotations" $annotation_id "labelcolor" $labelcolor
}

#****f* annotations_cfg.tcl/getAnnotationBorderColor
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
    return [cfgGet "annotations" $annotation_id "bordercolor"]
}

#****f* annotations_cfg.tcl/setAnnotationBorderColor
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
    cfgSet "annotations" $annotation_id "bordercolor" $bordercolor
}

#****f* annotations_cfg.tcl/getAnnotationWidth
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
    return [cfgGet "annotations" $annotation_id "width"]
}

#****f* annotations_cfg.tcl/setAnnotationWidth
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
    cfgSet "annotations" $annotation_id "width" $width
}

#****f* annotations_cfg.tcl/getAnnotationRad
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
    return [cfgGet "annotations" $annotation_id "rad"]
}

#****f* annotations_cfg.tcl/setAnnotationRad
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
    cfgSet "annotations" $annotation_id "rad" $rad
}

#****f* annotations_cfg.tcl/getAnnotationFont
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
    return [cfgGet "annotations" $annotation_id "font"]
}

#****f* annotations_cfg.tcl/setAnnotationFont
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
    cfgSet "annotations" $annotation_id "font" $font
}

proc getAnnotationCoords { annotation_id } {
    return [cfgGet "annotations" $annotation_id "iconcoords"]
}

#****f* annotations_cfg.tcl/setAnnotationCoords
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
	set x [expr int($c)]
	lappend roundcoords $x
    }

    cfgSet "annotations" $annotation_id "iconcoords" $roundcoords
}
