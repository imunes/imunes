#****f* annotationscfg.tcl/addAnnotation
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
#****
proc deleteAnnotation { annotation_id } {
    global changed

    setToRunning "annotation_list" [removeFromList [getFromRunning "annotation_list"] $annotation_id]
    cfgUnset "annotations" $annotation_id

    set changed 1
    updateUndoLog
    redrawAll
}

#****f* annotationscfg.tcl/getAnnotationType
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
    return [cfgGet "annotations" $annotation_id "type"]
}

#****f* annotationscfg.tcl/setAnnotationType
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
    cfgSet "annotations" $annotation_id "type" $type
}

#****f* annotationscfg.tcl/getAnnotationCanvas
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
    return [cfgGet "annotations" $annotation_id "canvas"]
}

#****f* annotationscfg.tcl/setAnnotationCanvas
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
    cfgSet "annotations" $annotation_id "canvas" $canvas_id
}

#****f* annotationscfg.tcl/getAnnotationColor
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

#****f* annotationscfg.tcl/setAnnotationColor
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

#****f* annotationscfg.tcl/getAnnotationLabel
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
    return [cfgGet "annotations" $annotation_id "label"]
}

#****f* annotationscfg.tcl/setAnnotationLabel
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

#****f* annotationscfg.tcl/getAnnotationLabelColor
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
    return [cfgGet "annotations" $annotation_id "labelcolor"]
}

#****f* annotationscfg.tcl/setAnnotationLabelColor
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
    cfgSet "annotations" $annotation_id "labelcolor" $labelcolor
}

#****f* annotationscfg.tcl/getAnnotationBorderColor
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

#****f* annotationscfg.tcl/setAnnotationBorderColor
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

#****f* annotationscfg.tcl/getAnnotationWidth
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

#****f* annotationscfg.tcl/setAnnotationWidth
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

#****f* annotationscfg.tcl/getAnnotationRad
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

#****f* annotationscfg.tcl/setAnnotationRad
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

#****f* annotationscfg.tcl/getAnnotationFont
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

#****f* annotationscfg.tcl/setAnnotationFont
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

#****f* annotationscfg.tcl/getAnnotationCoords
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
    return [cfgGet "annotations" $annotation_id "iconcoords"]
}

#****f* annotationscfg.tcl/setAnnotationCoords
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
