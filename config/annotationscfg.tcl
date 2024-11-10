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
    upvar 0 ::cf::[set ::curcfg]::annotation_list annotation_list
    upvar 0 ::cf::[set ::curcfg]::$annotation_id $annotation_id
    lappend annotation_list $annotation_id
    lappend $annotation_id "type $type"
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
    upvar 0 ::cf::[set ::curcfg]::annotation_list annotation_list
    upvar 0 ::cf::[set ::curcfg]::$annotation_id $annotation_id
    global changed

    set $annotation_id {}

    set annotation_list [removeFromList $annotation_list $annotation_id]

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
    upvar 0 ::cf::[set ::curcfg]::$annotation_id $annotation_id

    return [lindex [lsearch -inline [set $annotation_id] "type *"] 1]
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
    upvar 0 ::cf::[set ::curcfg]::$annotation_id $annotation_id

    set i [lsearch [set $annotation_id] "type *"]
    if { $i >= 0 } {
	set $annotation_id [lreplace [set $annotation_id] $i $i "type $type"]
    } else {
	set $annotation_id [linsert [set $annotation_id] end "type $type"]
    }
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
    upvar 0 ::cf::[set ::curcfg]::$annotation_id $annotation_id

    return [lindex [lsearch -inline [set $annotation_id] "canvas *"] 1]
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
    upvar 0 ::cf::[set ::curcfg]::$annotation_id $annotation_id

    set i [lsearch [set $annotation_id] "canvas *"]
    if { $i >= 0 } {
	set $annotation_id [lreplace [set $annotation_id] $i $i "canvas $canvas_id"]
    } else {
	set $annotation_id [linsert [set $annotation_id] end "canvas $canvas_id"]
    }
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
    upvar 0 ::cf::[set ::curcfg]::$annotation_id $annotation_id
    return [lindex [lsearch -inline [set $annotation_id] "color *"] 1]
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
    upvar 0 ::cf::[set ::curcfg]::$annotation_id $annotation_id
    set i [lsearch [set $annotation_id] "color *"]
    if { $i>=0 } {
	set $annotation_id [lreplace [set $annotation_id] $i $i "color $color"]
    } else {
	lappend $annotation_id "color $color"
    }
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
    upvar 0 ::cf::[set ::curcfg]::$annotation_id $annotation_id
    return [lindex [lsearch -inline [set $annotation_id] "label *"] 1]
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
    upvar 0 ::cf::[set ::curcfg]::$annotation_id $annotation_id
    set i [lsearch [set $annotation_id] "label *"]
    if { $i>=0 } {
	set $annotation_id [lreplace [set $annotation_id] $i $i "label {$labeltext}"]
    } else {
	lappend $annotation_id "label {$labeltext}"
    }
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
    upvar 0 ::cf::[set ::curcfg]::$annotation_id $annotation_id
    return [lindex [lsearch -inline [set $annotation_id] "labelcolor *"] 1]
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
    upvar 0 ::cf::[set ::curcfg]::$annotation_id $annotation_id
    set i [lsearch [set $annotation_id] "labelcolor *"]
    if { $i>=0 } {
	set $annotation_id [lreplace [set $annotation_id] $i $i "labelcolor $labelcolor"]
    } else {
	lappend $annotation_id "labelcolor $labelcolor"
    }
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
    upvar 0 ::cf::[set ::curcfg]::$annotation_id $annotation_id
    return [lindex [lsearch -inline [set $annotation_id] "bordercolor *"] 1]
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
    upvar 0 ::cf::[set ::curcfg]::$annotation_id $annotation_id
    set i [lsearch [set $annotation_id] "bordercolor *"]
    if { $i>=0 } {
	set $annotation_id [lreplace [set $annotation_id] $i $i "bordercolor $bordercolor"]
    } else {
	lappend $annotation_id "bordercolor $bordercolor"
    }
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
    upvar 0 ::cf::[set ::curcfg]::$annotation_id $annotation_id
    return [lindex [lsearch -inline [set $annotation_id] "width *"] 1]
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
    upvar 0 ::cf::[set ::curcfg]::$annotation_id $annotation_id
    set i [lsearch [set $annotation_id] "width *"]
    if { $i>=0 } {
	set $annotation_id [lreplace [set $annotation_id] $i $i "width $width"]
    } else {
	lappend $annotation_id "width $width"
    }
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
    upvar 0 ::cf::[set ::curcfg]::$annotation_id $annotation_id
    return [lindex [lsearch -inline [set $annotation_id] "rad *"] 1]
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
    upvar 0 ::cf::[set ::curcfg]::$annotation_id $annotation_id
    set i [lsearch [set $annotation_id] "rad *"]
    if { $i>=0 } {
	set $annotation_id [lreplace [set $annotation_id] $i $i "rad $rad"]
    } else {
	lappend $annotation_id "rad $rad"
    }
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
    upvar 0 ::cf::[set ::curcfg]::$annotation_id $annotation_id
    return [lindex [lsearch -inline [set $annotation_id] "font *"] 1]
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
    upvar 0 ::cf::[set ::curcfg]::$annotation_id $annotation_id
    set i [lsearch [set $annotation_id] "font *"]
    if { $i>=0 } {
	set $annotation_id [lreplace [set $annotation_id] $i $i "font {$font}"]
    } else {
	lappend $annotation_id "font {$font}"
    }
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
    upvar 0 ::cf::[set ::curcfg]::$annotation_id $annotation_id
    return [lindex [lsearch -inline [set $annotation_id] "iconcoords *"] 1]
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
    upvar 0 ::cf::[set ::curcfg]::$annotation_id $annotation_id
    set iconcoords "iconcoords"

    set roundcoords {}
    foreach c $coords {
	set x [expr int($c)]
	lappend roundcoords $x
    }

    lappend $iconcoords $roundcoords
    set i [lsearch [set $annotation_id] "iconcoords *"]
    if { $i>=0 } {
	set $annotation_id [lreplace [set $annotation_id] $i $i $iconcoords]
    } else {
	lappend $annotation_id $iconcoords
    }
}
