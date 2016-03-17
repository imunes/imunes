#****f* annotations_cfg.tcl/addAnnotation
# NAME
#   addAnnotation -- add annotation object
# SYNOPSIS
#   addAnnotation $target $type
# FUNCTION
#   Adds annotation object to annotation list.
# INPUTS
#   * target -- new annotation id
#   * type -- annotation type
#****
proc addAnnotation { target type } {
    upvar 0 ::cf::[set ::curcfg]::annotation_list annotation_list
    upvar 0 ::cf::[set ::curcfg]::$target $target
    lappend annotation_list $target
    lappend $target "type $type"
}

#****f* annotations.tcl/deleteAnnotation
# NAME
#   deleteAnnotation -- delete annotation
# SYNOPSIS
#   deleteAnnotation $c $type $target
# FUNCTION
#   Deletes annotation from canvas.
# INPUTS
#   * c -- tk canvas
#   * type -- type of annimation
#   * target -- existing annotation
#****
proc deleteAnnotation { c type target } {
    upvar 0 ::cf::[set ::curcfg]::annotation_list annotation_list
    upvar 0 ::cf::[set ::curcfg]::$target $target
    global changed

    set $target {}
    
    set i [lsearch -exact $annotation_list $target]
    set annotation_list [lreplace $annotation_list $i $i]
    
    set changed 1
    updateUndoLog
    redrawAll
}

#****f* annotations.tcl/isAnnotation
# NAME
#   isAnnotation -- is annotation
# SYNOPSIS
#   isAnnotation $node
# FUNCTION
#   Checks if the node is annotation.
# INPUTS
#   * node -- node id
# RESULT
#   * check -- 1 if the node is annotation, otherwise 0
#****
proc isAnnotation { node } {
    if { [nodeType $node] in {"text" "oval" "rectangle" "freeform"} } {
	return 1
    }
    return 0
}

#****f* annotations_cfg.tcl/getAnnotationColor
# NAME
#   getAnnotationColor -- get annotation color
# SYNOPSIS
#   getAnnotationColor $object
# FUNCTION
#   Returns the specified annotation's color.
# INPUTS
#   * object -- annotation object
# RESULT
#   * color -- annotation color
#****
proc getAnnotationColor { object } {
    upvar 0 ::cf::[set ::curcfg]::$object $object
    return [lindex [lsearch -inline [set $object] "color *"] 1]
}

#****f* annotations_cfg.tcl/getAnnotationLabel
# NAME
#   getAnnotationLabel -- get annotation label
# SYNOPSIS
#   getAnnotationLabel $object
# FUNCTION
#   Returns the specified annotation label
# INPUTS
#   * object -- annotation object
# RESULT
#   * label -- annotation label
#****
proc getAnnotationLabel { object } {
    upvar 0 ::cf::[set ::curcfg]::$object $object
    return [lindex [lsearch -inline [set $object] "label *"] 1]
}

#****f* annotations_cfg.tcl/getAnnotationLColor
# NAME
#   getAnnotationLColor -- get annotation label color
# SYNOPSIS
#   getAnnotationLColor $object
# FUNCTION
#   Returns the specified annotation's label color.
# INPUTS
#   * object -- annotation object
# RESULT
#   * lcolor -- annotation label color
#****
proc getAnnotationLColor { object } {
    upvar 0 ::cf::[set ::curcfg]::$object $object
    return [lindex [lsearch -inline [set $object] "labelcolor *"] 1]
}

#****f* annotations_cfg.tcl/getAnnotationBorderColor
# NAME
#   getAnnotationBorderColor -- get annotation border color
# SYNOPSIS
#   getAnnotationBorderColor $object
# FUNCTION
#   Returns the specified annotation's border color.
# INPUTS
#   * object -- annotation object
# RESULT
#   * bcolor -- annotation border color
#****
proc getAnnotationBorderColor { object } {
    upvar 0 ::cf::[set ::curcfg]::$object $object
    return [lindex [lsearch -inline [set $object] "bordercolor *"] 1]
}

#****f* annotations_cfg.tcl/getAnnotationWidth
# NAME
#   getAnnotationWidth -- get annotation width
# SYNOPSIS
#   getAnnotationWidth $object
# FUNCTION
#   Returns the specified annotation's width.
# INPUTS
#   * object -- annotation object
# RESULT
#   * width -- annotation width
#****
proc getAnnotationWidth { object } {
    upvar 0 ::cf::[set ::curcfg]::$object $object
    return [lindex [lsearch -inline [set $object] "width *"] 1]
}

#****f* annotations_cfg.tcl/getAnnotationRad
# NAME
#   getAnnotationRad -- get annotation radius
# SYNOPSIS
#   getAnnotationRad $object
# FUNCTION
#   Returns the specified annotation's radius.
# INPUTS
#   * object -- annotation object
# RESULT
#   * rad -- annotation radius
#****
proc getAnnotationRad { object } {
    upvar 0 ::cf::[set ::curcfg]::$object $object
    return [lindex [lsearch -inline [set $object] "rad *"] 1]
}

#****f* annotations_cfg.tcl/getAnnotationFont
# NAME
#   getAnnotationFont -- get annotation font
# SYNOPSIS
#   getAnnotationFont $object
# FUNCTION
#   Returns the specified annotation's font.
# INPUTS
#   * object -- annotation object
# RESULT
#   * font -- annotation font
#****
proc getAnnotationFont { object } {
    upvar 0 ::cf::[set ::curcfg]::$object $object
    return [lindex [lsearch -inline [set $object] "font *"] 1]
}


#****f* annotations_cfg.tcl/setAnnotationCoords
# NAME
#   setAnnotationCoords -- set annotation coordinates
# SYNOPSIS
#   setAnnotationCoords $target $coords
# FUNCTION
#   Sets annotation coordinates.
# INPUTS
#   * target -- annotation id
#   * coords -- coordinates
#****
proc setAnnotationCoords { target coords } {
    upvar 0 ::cf::[set ::curcfg]::$target $target
    set iconcoords "iconcoords"

    foreach c $coords {
	set x [expr round($c)]
	lappend roundcoords $x
    }

    lappend $iconcoords $roundcoords
    set i [lsearch [set $target] "iconcoords *"]
    if {$i>=0} {
	set $target [lreplace [set $target] $i $i $iconcoords]
    } else {
	lappend $target $iconcoords
    }
}

#****f* annotations_cfg.tcl/setAnnotationColor
# NAME
#   setAnnotationColor -- set annotation color
# SYNOPSIS
#   setAnnotationColor $target $color
# FUNCTION
#   Sets annotation color.
# INPUTS
#   * target -- annotation id
#   * color -- color
#****
proc setAnnotationColor { target color } {
    upvar 0 ::cf::[set ::curcfg]::$target $target
    set i [lsearch [set $target] "color *"]
    if {$i>=0} {
	set $target [lreplace [set $target] $i $i "color $color"]
    } else { 
	lappend $target "color $color"
    }
}

#****f* annotations_cfg.tcl/setAnnotationBorderColor
# NAME
#   setAnnotationBorderColor -- set annotation border color
# SYNOPSIS
#   setAnnotationBorderColor $target $bordercolor
# FUNCTION
#   Sets annotation border color
# INPUTS
#   * target -- annotation id
#   * bordercolor -- border color
#****
proc setAnnotationBorderColor { target bordercolor } {
    upvar 0 ::cf::[set ::curcfg]::$target $target
    set i [lsearch [set $target] "bordercolor *"]
    if {$i>=0} {
	set $target [lreplace [set $target] $i $i "bordercolor $bordercolor"]
    } else { 
	lappend $target "bordercolor $bordercolor"
    }
}

#****f* annotations_cfg.tcl/setAnnotationWidth
# NAME
#   setAnnotationWidth -- set annotation width
# SYNOPSIS
#   setAnnotationWidth $target $width
# FUNCTION
#   Sets annotation width.
# INPUTS
#   * target -- annotation id
#   * width -- width
#****
proc setAnnotationWidth { target width } {
    upvar 0 ::cf::[set ::curcfg]::$target $target
    set i [lsearch [set $target] "width *"]
    if {$i>=0} {
	set $target [lreplace [set $target] $i $i "width $width"]
    } else { 
	lappend $target "width $width"
    }
}

#****f* annotations_cfg.tcl/setAnnotationRad
# NAME
#   setAnnotationRad -- set annotation radius
# SYNOPSIS
#   setAnnotationRad $target $rad
# FUNCTION
#   Sets annotation radius.
# INPUTS
#   * target -- annotation id
#   * rad -- radius
#****
proc setAnnotationRad { target rad } {
    upvar 0 ::cf::[set ::curcfg]::$target $target
    set i [lsearch [set $target] "rad *"]
    if {$i>=0} {
	set $target [lreplace [set $target] $i $i "rad $rad"]
    } else { 
	lappend $target "rad $rad"
    }
}

#****f* annotations_cfg.tcl/setAnnotationLabel
# NAME
#   setAnnotationLabel -- set annotation label
# SYNOPSIS
#   setAnnotationLabel $target $label
# FUNCTION
#   Sets annotation label.
# INPUTS
#   * target -- annotation id
#   * label -- label text
#****
proc setAnnotationLabel { target label } {
    upvar 0 ::cf::[set ::curcfg]::$target $target
    set i [lsearch [set $target] "label *"]
    if {$i>=0} {
	set $target [lreplace [set $target] $i $i "label {$label}"]
    } else { 
	lappend $target "label {$label}"
    }
}

#****f* annotations_cfg.tcl/setAnnotationLColor
# NAME
#   setAnnotationLColor -- set annotation's label color
# SYNOPSIS
#   setAnnotationLColor $target $lcolor
# FUNCTION
#   Sets annotation's label color.
# INPUTS
#   * target -- annotation id
#   * lcolor -- label color
#****
proc setAnnotationLColor { target lcolor } {
    upvar 0 ::cf::[set ::curcfg]::$target $target
    set i [lsearch [set $target] "labelcolor *"]
    if {$i>=0} {
	set $target [lreplace [set $target] $i $i "labelcolor $lcolor"]
    } else { 
	lappend $target "labelcolor $lcolor"
    }
}

#****f* annotations_cfg.tcl/setAnnotationFont
# NAME
#   setAnnotationFont -- set annotation font
# SYNOPSIS
#   setAnnotationFont $target $font
# FUNCTION
#   Sets annotation font.
# INPUTS
#   * target -- annotation id
#   * font -- font
#****
proc setAnnotationFont { target font } {
    upvar 0 ::cf::[set ::curcfg]::$target $target
    set i [lsearch [set $target] "font *"]
    if {$i>=0} {
	set $target [lreplace [set $target] $i $i "font {$font}"]
    } else { 
	lappend $target "font {$font}"
    }
}
