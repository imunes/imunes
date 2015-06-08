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
#   popupAnnotationDialog -- popup annotation dialog
# SYNOPSIS
#   popupAnnotationDialog $c $target $modify
# FUNCTION
#   Checks the active tool and depending which one is selected, show a dialog
#   to create a new or to modify an existing annotation.
# INPUTS
#   * c -- tk canvas
#   * target -- existing or a new annotation
#   * modify -- modify existing or newly created
#****
proc popupAnnotationDialog { c target modify } {
    global activetool
    switch $activetool {
	oval {
	    popupOvalDialog $c $target $modify
	}
	rectangle {
	    popupRectangleDialog $c $target $modify
	}
	text {
	    popupTextDialog $c $target $modify
	}
	freeform {
	    popupFreeformDialog $c $target $modify
	}
    }
}

#****f* annotations.tcl/drawAnnotation
# NAME
#   drawAnnotation -- draw annotation
# SYNOPSIS
#   drawAnnotation $obj
# FUNCTION
#   Draws annotation on canvas.
# INPUTS
#   * obj -- type of annotation to draw
#****
proc drawAnnotation { obj } {
    switch -exact -- [nodeType $obj] {
	oval {
	    drawOval $obj
	}
	rectangle {
	    drawRect $obj
	}
	text {
	    drawText $obj
	}
	freeform {
	    drawFreeform $obj
	}
    }
}

#****f* annotations.tcl/popupOvalDialog
# NAME
#   popupOvalDialog -- popup dialog for oval annotation
# SYNOPSIS
#   popupOvalDialog $c $target $modify
# FUNCTION
#   Shows a dialog to create a new or modifiy an existing oval annotation.
# INPUTS
#   * c -- tk canvas
#   * target -- existing or a new annotation
#   * modify -- modify existing or newly created
#****
proc popupOvalDialog { c target modify } {
    global newrect newoval 
    global width rad 
    global defFillColor defTextColor 

    # do nothing, return, if coords are empty
    if { $target == 0 && [$c coords "$newoval"] == "" } {
	return
    }
    if { $target == 0 } {
	set width 1
	set rad 25
	set coords [$c bbox "$newoval"]
	set annotationType "oval"
	set color ""
	set bordercolor ""
    } else {
	set width [getAnnotationWidth $target]
	set coords [$c bbox "$target"]
	set color [getAnnotationColor $target]
	set bordercolor [getAnnotationBorderColor $target]
	set annotationType [nodeType $target]
    }

    if { $color == "" } { set color $defFillColor }
    if { $bordercolor == "" } { set bordercolor black }
    if { $width == "" } { set width 1 }
    
    set wi .popup
    catch {destroy $wi}
    toplevel $wi

    wm transient $wi .
    wm resizable $wi 0 0
    
    tk fontchooser configure -parent $wi

    if { $modify == "true" } {
	set windowtitle "Configure $annotationType $target"
    } else {
	set windowtitle "Add a new $annotationType"
    }
    wm title $wi $windowtitle
    
    # fill color, border color
    ttk::frame $wi.colors -relief groove -borderwidth 2 -padding 2
    # color selection controls
    ttk::label $wi.colors.label -text "Fill color:"

    ttk::label $wi.colors.color -text $color -width 8 \
      -background $color
    ttk::button $wi.colors.bg -text "Color" -command \
	"popupColor background $wi.colors.color true"
    pack $wi.colors.label $wi.colors.color $wi.colors.bg \
	-side left -padx 2 -pady 2 -anchor w -fill x
    pack $wi.colors -side top -fill x

    # border selection controls
    ttk::frame $wi.border -relief groove -borderwidth 2 -padding 2
    ttk::label $wi.border.label -text "Border color:"
    ttk::label $wi.border.color -text $bordercolor -width 8
    ttk::label $wi.border.width_label -text "Border width:"
    ttk::combobox $wi.border.width -textvariable width -width 3
    $wi.border.width configure -values [list 0 1 2 3 4 5 6 7 8 9 10]
    ttk::button $wi.border.fg -text "Color" -command \
	"popupColor foreground $wi.border.color true"
    pack $wi.border.label $wi.border.color $wi.border.fg \
	$wi.border.width_label $wi.border.width $wi.border.width \
	$wi.border.fg $wi.border.color $wi.border.label \
	-side left -padx 2 -pady 2 -anchor w -fill x
    pack $wi.border -side top -fill x
    
    # Add new oval or modify old one?
    if { $modify == "true"  } {
	set cancelcmd "destroy $wi"
	set applytext "Modify $annotationType"
    } else {
	set cancelcmd "destroy $wi; destroyNewOval $c"
	set applytext "Add $annotationType"
    }
    
    ttk::frame $wi.butt -borderwidth 6 -padding 2
    pack $wi.butt -fill both -expand 1
    ttk::button $wi.butt.apply -text $applytext -command \
      "popupOvalApply $c $wi $target"

    ttk::button $wi.butt.cancel -text "Cancel" -command $cancelcmd
    bind $wi <Key-Escape> "$cancelcmd" 
    bind $wi <Key-Return> "popupOvalApply $c $wi $target"
    pack $wi.butt.apply -side left -expand 1 -anchor e
    pack $wi.butt.cancel -side right -expand 1 -anchor w
    pack $wi.butt -side bottom

    return
}

#****f* annotations.tcl/popupOvalApply
# NAME
#   popupOvalApply -- popup oval apply
# SYNOPSIS
#   popupOvalApply $c $wi $target
# FUNCTION
#   Creates a new oval annotation on the canvas from the popup dialog.
# INPUTS
#   * c -- tk canvas
#   * wi -- widget
#   * target -- existing or a new annotation
#****
proc popupOvalApply { c wi target } {
    upvar 0 ::cf::[set ::curcfg]::annotation_list annotation_list
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    global newrect newoval
    global changed
    global width rad

    # attributes
    #set iconcoords "iconcoords"

    set sizex [expr [lindex [getCanvasSize $curcanvas] 0] - 5]
    set sizey [expr [lindex [getCanvasSize $curcanvas] 1] - 5]

    set color [$wi.colors.color cget -text]
    set bordercolor [$wi.border.color cget -text]
    

    if { $target == 0 } {
	# Create a new annotation object
	set target [newObjectId annotation]
	addAnnotation $target oval
	set coords [$c coords $newoval]
	if { [lindex $coords 0] < 0 } {
	    set coords [lreplace $coords 0 0 5]
	}
	if { [lindex $coords 1] < 0 } {
	    set coords [lreplace $coords 1 1 5]
	}
	if { [lindex $coords 2] > $sizex} {
	    set coords [lreplace $coords 2 2 $sizex]
	}
	if { [lindex $coords 3] > $sizey} {
	    set coords [lreplace $coords 3 3 $sizey]
	}
    } else {
	set coords [getNodeCoords $target]
    }

    setAnnotationCoords $target $coords
    setAnnotationColor $target $color
    setAnnotationBorderColor $target $bordercolor
    setAnnotationWidth $target $width
    
    destroyNewOval $c
    #setType $target "oval"
    setNodeCanvas $target $curcanvas
    set changed 1
    updateUndoLog
    redrawAll
    destroy $wi 
}

#****f* annotations.tcl/drawOval
# NAME
#   drawOval -- draw oval
# SYNOPSIS
#   drawOval $oval
# FUNCTION
#   Draws a specified oval annotation.
# INPUTS
#   * oval -- oval annotation
#****
proc drawOval { oval } {
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    upvar 0 ::cf::[set ::curcfg]::zoom zoom
    global defFillColor 

    set coords [getNodeCoords $oval]
    set x1 [expr {[lindex $coords 0] * $zoom}]
    set y1 [expr {[lindex $coords 1] * $zoom}]
    set x2 [expr {[lindex $coords 2] * $zoom}]
    set y2 [expr {[lindex $coords 3] * $zoom}]
    set color [getAnnotationColor $oval]
    set bordercolor [getAnnotationBorderColor $oval]
    set width [getAnnotationWidth $oval]
    
    if { $color == "" } { set color $defFillColor }
    if { $width == "" } { set width 1 }
    if { $bordercolor == "" } { set bordercolor black }

    set newoval [.panwin.f1.c create oval $x1 $y1 $x2 $y2 \
	-fill $color -width $width -outline $bordercolor -tags "oval $oval"]
    .panwin.f1.c raise $newoval background
}

#****f* annotations.tcl/popupRectangleDialog
# NAME
#   popupRectangleDialog -- popup dialog for rectangle annotation
# SYNOPSIS
#   popupRectangleDialog $c $target $modify
# FUNCTION
#   Shows a dialog to create a new or modifiy an existing rectangle annotation.
# INPUTS
#   * c -- tk canvas
#   * target -- existing or a new annotation
#   * modify -- modify existing or newly created
#****
proc popupRectangleDialog { c target modify } {
    global newrect newoval 
    global width rad 
    global defFillColor defTextColor 

    # do nothing, return, if coords are empty
    if { $target == 0 && [$c coords "$newrect"] == "" } {
	return
    }
    if { $target == 0 } {
	set width 1
	set rad 25
	set coords [$c bbox "$newrect"]
	set annotationType "rectangle"
	set color ""
	set bordercolor ""
    } else {
	set width [getAnnotationWidth $target]
	set coords [$c bbox "$target"]
	set color [getAnnotationColor $target]
	set bordercolor [getAnnotationBorderColor $target]
	set annotationType [nodeType $target]
	set rad [getAnnotationRad $target]
    }

    if { $color == "" } { set color $defFillColor }
    if { $bordercolor == "" } { set bordercolor black }
    if { $width == "" } { set width 1 }
    
    set x1 [lindex $coords 0] 
    set y1 [lindex $coords 1]
    set x2 [lindex $coords 2]
    set y2 [lindex $coords 3]
    set xx [expr {abs($x2 - $x1)}] 
    set yy [expr {abs($y2 - $y1)}] 
    if { $xx > $yy } {
	set maxrad [expr $yy * 3.0 / 8.0]
    } else {
	set maxrad [expr $xx * 3.0 / 8.0]
    }

    set wi .popup
    catch {destroy $wi}
    toplevel $wi

    wm transient $wi .
    wm resizable $wi 0 0
    
    tk fontchooser configure -parent $wi

    if { $modify == "true" } {
	set windowtitle "Configure $annotationType $target"
    } else {
	set windowtitle "Add a new $annotationType"
    }
    wm title $wi $windowtitle
    
    # fill color, border color
    ttk::frame $wi.colors -relief groove -borderwidth 2 -padding 2
    # color selection controls
    ttk::label $wi.colors.label -text "Fill color:"

    ttk::label $wi.colors.color -text $color -width 8 \
      -background $color
    ttk::button $wi.colors.bg -text "Color" -command \
	"popupColor background $wi.colors.color true"
    pack $wi.colors.label $wi.colors.color $wi.colors.bg \
	-side left -padx 2 -pady 2 -anchor w -fill x
    pack $wi.colors -side top -fill x

    # border selection controls
    ttk::frame $wi.border -relief groove -borderwidth 2 -padding 2
    ttk::label $wi.border.label -text "Border color:"
    ttk::label $wi.border.color -text $bordercolor -width 8
    ttk::label $wi.border.width_label -text "Border width:"
    ttk::combobox $wi.border.width -textvariable width -width 3
    $wi.border.width configure -values [list 0 1 2 3 4 5 6 7 8 9 10]
    ttk::button $wi.border.fg -text "Color" -command \
	"popupColor foreground $wi.border.color true"
    pack $wi.border.label $wi.border.color $wi.border.fg \
	$wi.border.width_label $wi.border.width $wi.border.width \
	$wi.border.fg $wi.border.color $wi.border.label \
	-side left -padx 2 -pady 2 -anchor w -fill x
    pack $wi.border -side top -fill x
    
    ttk::frame $wi.radius -relief groove -borderwidth 2 -padding 2
    ttk::label $wi.radius.scale_label -text "Radius of the bend at the corners: " 
    ttk::scale $wi.radius.rad -from 0 -to [expr int($maxrad)] \
	-length 400 -variable rad \
	-orient horizontal
    pack $wi.radius -side top -fill x
    pack $wi.radius.scale_label -side top -fill x
    pack $wi.radius.rad -side left -padx 2 -pady 2 -anchor w -fill x -expand 1
    
    # Add new rectangle or modify old one?
    if { $modify == "true"  } {
	set cancelcmd "destroy $wi"
	set applytext "Modify $annotationType"
    } else {
	set cancelcmd "destroy $wi; destroyNewRect $c"
	set applytext "Add $annotationType"
    }
    
    ttk::frame $wi.butt -borderwidth 6 -padding 2
    pack $wi.butt -fill both -expand 1
    ttk::button $wi.butt.apply -text $applytext -command \
      "popupRectangleApply $c $wi $target"

    ttk::button $wi.butt.cancel -text "Cancel" -command $cancelcmd
    bind $wi <Key-Escape> "$cancelcmd" 
    bind $wi <Key-Return> "popupRectangleApply $c $wi $target"
    pack $wi.butt.apply -side left -expand 1 -anchor e
    pack $wi.butt.cancel -side right -expand 1 -anchor w
    pack $wi.butt -side bottom

    return
}

#****f* annotations.tcl/popupRectangleApply
# NAME
#   popupRectangleApply -- popup rectangle apply
# SYNOPSIS
#   popupRectangleApply $c $wi $target
# FUNCTION
#   Creates a new rectangle annotation on the canvas from the popup dialog.
# INPUTS
#   * c -- tk canvas
#   * wi -- widget
#   * target -- existing or a new annotation
#****
proc popupRectangleApply { c wi target } {
    upvar 0 ::cf::[set ::curcfg]::annotation_list annotation_list
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    global newrect newoval
    global changed
    global width rad

    set sizex [expr [lindex [getCanvasSize $curcanvas] 0] - 5]
    set sizey [expr [lindex [getCanvasSize $curcanvas] 1] - 5]

    set color [$wi.colors.color cget -text]
    set bordercolor [$wi.border.color cget -text]

    if { $target == 0 } {
	# Create a new annotation object
	set target [newObjectId annotation]
	addAnnotation $target rectangle
	set coords [$c coords $newrect]
	if { [lindex $coords 0] < 0 } {
	    set coords [lreplace $coords 0 0 5]
	}
	if { [lindex $coords 1] < 0 } {
	    set coords [lreplace $coords 1 1 5]
	}
	if { [lindex $coords 2] > $sizex} {
	    set coords [lreplace $coords 2 2 $sizex]
	}
	if { [lindex $coords 3] > $sizey} {
	    set coords [lreplace $coords 3 3 $sizey]
	}
    } else {
	set coords [getNodeCoords $target]
    }
    setAnnotationCoords $target $coords
    setAnnotationColor $target $color
    setAnnotationBorderColor $target $bordercolor
    setAnnotationWidth $target $width
    setAnnotationRad $target $rad
           
    destroyNewRect $c
    setNodeCanvas $target $curcanvas
    set changed 1
    updateUndoLog
    redrawAll
    destroy $wi 
}

#****f* annotations.tcl/drawRect
# NAME
#   drawRect -- draw rectangle
# SYNOPSIS
#   drawRect $rectangle
# FUNCTION
#   Draws a specified rectangle annotation.
# INPUTS
#   * rectangle -- rectangle annotation
#****
proc drawRect { rectangle } {
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    upvar 0 ::cf::[set ::curcfg]::zoom zoom
    global defFillColor 

    set coords [getNodeCoords $rectangle]
    set x1 [expr {[lindex $coords 0] * $zoom}]
    set y1 [expr {[lindex $coords 1] * $zoom}]
    set x2 [expr {[lindex $coords 2] * $zoom}]
    set y2 [expr {[lindex $coords 3] * $zoom}]
    set color [getAnnotationColor $rectangle]
    set bordercolor [getAnnotationBorderColor $rectangle]
    set width [getAnnotationWidth $rectangle]
    set rad [getAnnotationRad $rectangle]

    if { $color == "" } { set color $defFillColor }
    if { $width == "" } { set width 1 }
    if { $bordercolor == "" } { set bordercolor black }
    # rounded-rectangle radius
    if { $rad == "" } { set rad 25 }

    if { $width == 0 } {
	set newrect [roundRect .panwin.f1.c $x1 $y1 $x2 $y2 $rad \
	    -fill $color -tags "rectangle $rectangle"]
    } else {
	set newrect [roundRect .panwin.f1.c $x1 $y1 $x2 $y2 $rad \
	    -fill $color -outline $bordercolor -width $width \
	    -tags "rectangle $rectangle"]
    }
    .panwin.f1.c raise $newrect background
}

#****f* annotations.tcl/popupTextDialog
# NAME
#   popupTextDialog -- popup dialog for text annotation
# SYNOPSIS
#   popupTextDialog $c $target $modify
# FUNCTION
#   Shows a dialog to create a new or modifiy an existing text annotation.
# INPUTS
#   * c -- tk canvas
#   * target -- existing or a new annotation
#   * modify -- modify existing or newly created
#****
proc popupTextDialog { c target modify } {
    global newrect newoval newtext
    global width rad 
    global defFillColor defTextColor 

    # do nothing, return, if coords are empty
    if { $target == 0 && [$c coords "$newtext"] == "" } {
	return
    }
    if { $target == 0 } {
	set coords [$c bbox "$newtext"]
	set annotationType "text"
	set lcolor ""
	set font ""
	set label ""
    } else {
	set coords [$c bbox "$target"]
	set annotationType [nodeType $target]
	set label [getAnnotationLabel $target]
	set lcolor [getAnnotationLColor $target]
	set font [getAnnotationFont $target]
    }
    if { $lcolor == "" } { set lcolor black }
    if { $font == "" } { set font TkTextFont }
    
    set wi .popup
    catch {destroy $wi}
    toplevel $wi

    wm transient $wi .
    wm resizable $wi 0 0
    
    tk fontchooser configure -parent $wi

    if { $modify == "true" } {
	set windowtitle "Configure $annotationType $target"
    } else {
	set windowtitle "Add a new $annotationType"
    }
    wm title $wi $windowtitle

    ttk::frame $wi.text -relief groove -borderwidth 2 -padding 2
    ttk::frame $wi.text.lab
    ttk::label $wi.text.lab.name_label -text "Text:"
    ttk::entry $wi.text.lab.name  -width 32 -background white -foreground \
	$lcolor -font $font
    $wi.text.lab.name insert 0 $label
    pack $wi.text.lab.name_label $wi.text.lab.name -side left -anchor w \
	-padx 2 -pady 2 -fill x
    pack $wi.text.lab -side top -fill x
    pack $wi.text -side top -fill x

    ttk::frame $wi.colors -borderwidth 2 -padding 2    

    # color selection 
    
    ttk::button $wi.colors.fg -text "Text color" -command \
	"popupColor foreground $wi.text.lab.name false"
    ttk::button $wi.colors.font -text "Font" -command \
	"fontchooserFocus $wi.text.lab.name; fontchooserToggle"

    pack $wi.colors.fg -side left  -pady 2
    pack $wi.colors.font -side left -pady 2 -padx 10
    pack $wi.colors -side top -fill x
    
    # Add new oval or modify old one?
    if { $modify == "true"  } {
	set cancelcmd "destroy $wi"
	set applytext "Modify $annotationType"
    } else {
	set cancelcmd "destroy $wi; destroyNewText $c"
	set applytext "Add $annotationType"
    }
    
    ttk::frame $wi.butt -borderwidth 6 -padding 2
    pack $wi.butt -fill both -expand 1
    ttk::button $wi.butt.apply -text $applytext -command \
      "popupTextApply $c $wi $target"

    ttk::button $wi.butt.cancel -text "Cancel" -command $cancelcmd
    bind $wi <Key-Escape> "$cancelcmd" 
    bind $wi <Key-Return> "popupTextApply $c $wi $target"
    pack $wi.butt.apply -side left -expand 1 -anchor e
    pack $wi.butt.cancel -side right -expand 1 -anchor w
    pack $wi.butt -side bottom

    return
}

#****f* annotations.tcl/popupTextApply
# NAME
#   popupTextApply -- popup text apply
# SYNOPSIS
#   popupTextApply $c $wi $target
# FUNCTION
#   Creates a new text annotation on the canvas from the popup dialog.
# INPUTS
#   * c -- tk canvas
#   * wi -- widget
#   * target -- existing or a new annotation
#****
proc popupTextApply { c wi target } {
    upvar 0 ::cf::[set ::curcfg]::annotation_list annotation_list
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    global newrect newoval newtext
    global changed

    set label [string trim [$wi.text.lab.name get]]
    set labelcolor [$wi.text.lab.name cget -foreground]
    set font [$wi.text.lab.name cget -font] 
    
    if { $label != "" } {
	if { $target == 0 } {
	    # Create a new annotation object
	    set target [newObjectId annotation]
	    addAnnotation $target text
	    set coords [$c coords $newtext]
	} else {
	    set coords [getNodeCoords $target]
	}
	setAnnotationCoords $target $coords
	setAnnotationLabel $target $label
	setAnnotationLColor $target $labelcolor
	setAnnotationFont $target $font

	destroyNewText $c
	setNodeCanvas $target $curcanvas
	set changed 1
	updateUndoLog
    }
    redrawAll
    destroy $wi 
}

#****f* annotations.tcl/drawText
# NAME
#   drawText -- draw text
# SYNOPSIS
#   drawText $text
# FUNCTION
#   Draws a specified text annotation.
# INPUTS
#   * text -- text annotation
#****
proc drawText { text } {
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    upvar 0 ::cf::[set ::curcfg]::zoom zoom
    global defTextColor

    set coords [getNodeCoords $text]
    if {$coords == ""} {
	puts "Empty coordinates for text $text" ;# MM debug
	return
    }
    set x [expr {[lindex $coords 0] * $zoom}]
    set y [expr {[lindex $coords 1] * $zoom}]
    set labelcolor [getAnnotationLColor $text]
    set label [getAnnotationLabel $text]
    set font [getAnnotationFont $text]
    
    if { $labelcolor == "" } { set labelcolor $defTextColor }
    if { $font == "" } { set font TkTextFont }

    set newtext [.panwin.f1.c create text $x $y -text $label -anchor w \
	-font "$font" -justify left -fill $labelcolor -tags "text $text"]
	.panwin.f1.c raise $newtext background
}

#****f* annotations.tcl/popupFreeformDialog
# NAME
#   popupFreeformDialog -- popup dialog for freeform annotation
# SYNOPSIS
#   popupFreeformDialog $c $target $modify
# FUNCTION
#   Shows a dialog to create a new or modifiy an existing freeform annotation.
# INPUTS
#   * c -- tk canvas
#   * target -- existing or a new annotation
#   * modify -- modify existing or newly created
#****
proc popupFreeformDialog { c target modify } {
    global newfree 
    global width 
    global defFillColor 

    # do nothing, return, if coords are empty
    if { $target == 0 && [$c coords "$newfree"] == "" } {
	return
    }
    if { $target == 0 } {
	set width 2
	set color blue
	set annotationType "freeform"
    } else {
	set coords [$c bbox "$target"]
	set annotationType [nodeType $target]
	set color [getAnnotationColor $target]
	set width [getAnnotationWidth $target]
    }
	
    set wi .popup
    catch {destroy $wi}
    toplevel $wi

    wm transient $wi .
    wm resizable $wi 0 0
    
    tk fontchooser configure -parent $wi

    if { $modify == "true" } {
	set windowtitle "Configure $annotationType $target"
    } else {
	set windowtitle "Add a new $annotationType"
    }
    wm title $wi $windowtitle
    
    ttk::frame $wi.colors -relief groove -borderwidth 2 -padding 2
    # color selection controls
    ttk::label $wi.colors.label -text "Line color:"

    ttk::label $wi.colors.color -text $color -width 8 \
      -background $color
    ttk::button $wi.colors.bg -text "Color" -command \
	"popupColor background $wi.colors.color true"
    pack $wi.colors.label $wi.colors.color $wi.colors.bg \
	-side left -padx 2 -pady 2 -anchor w -fill x
    pack $wi.colors -side top -fill x
    
    ttk::frame $wi.width -relief groove -borderwidth 2 -padding 2
    ttk::label $wi.width.label -text "Width:"
    ttk::combobox $wi.width.number -textvariable width -width 3
    $wi.width.number configure -values [list 0 1 2 3 4 5 6 7 8 9 10]
    pack $wi.width $wi.width.label $wi.width.number \
	-side left -padx 2 -pady 2 -anchor w -fill x
    pack $wi.width -side top -fill x
    
    # Add new oval or modify old one?
    if { $modify == "true"  } {
	set cancelcmd "destroy $wi"
	set applytext "Modify $annotationType"
    } else {
	set cancelcmd "destroy $wi; destroyNewFree $c"
	set applytext "Add $annotationType"
    }
    
    ttk::frame $wi.butt -borderwidth 6 -padding 2
    pack $wi.butt -fill both -expand 1
    ttk::button $wi.butt.apply -text $applytext -command \
      "popupFreeformApply $c $wi $target"

    ttk::button $wi.butt.cancel -text "Cancel" -command $cancelcmd
    bind $wi <Key-Escape> "$cancelcmd" 
    bind $wi <Key-Return> "popupFreeformApply $c $wi $target"
    pack $wi.butt.apply -side left -expand 1 -anchor e
    pack $wi.butt.cancel -side right -expand 1 -anchor w
    pack $wi.butt -side bottom

    return
}

#****f* annotations.tcl/popupFreeformApply
# NAME
#   popupFreeformApply -- popup freeform apply
# SYNOPSIS
#   popupFreeformApply $c $wi $target
# FUNCTION
#   Creates a new freeform annotation on the canvas from the popup dialog.
# INPUTS
#   * c -- tk canvas
#   * wi -- widget
#   * target -- existing or a new annotation
#****
proc popupFreeformApply { c wi target } {
    upvar 0 ::cf::[set ::curcfg]::annotation_list annotation_list
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    global newfree
    global changed
    global width

    set color [$wi.colors.color cget -text]

    if { $target == 0 } {
	# Create a new annotation object
	set target [newObjectId annotation]
	addAnnotation $target freeform
	set coords [$c coords $newfree]
    } else {
	set coords [getNodeCoords $target]
    }

    setAnnotationCoords $target $coords
    setAnnotationColor $target $color
    setAnnotationWidth $target $width
    
    destroyNewFree $c
    
    setNodeCanvas $target $curcanvas
    set changed 1
    updateUndoLog
    redrawAll
    destroy $wi 
}

#****f* annotations.tcl/drawFreeform
# NAME
#   drawFreeform -- draw freeform
# SYNOPSIS
#   drawFreeform $freeform
# FUNCTION
#   Draws a specified freeform annotation.
# INPUTS
#   * freeform -- freeform annotation
#****
proc drawFreeform { freeform } {
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    upvar 0 ::cf::[set ::curcfg]::zoom zoom

    set coords [getNodeCoords $freeform]
    set color [getAnnotationColor $freeform]
    set width [getAnnotationWidth $freeform]
    
    if { $color == "" } { set color $defFillColor }
    if { $width == "" } { set width 2 }
    
    set l [expr {[llength $coords]-2}]
    set i 0
    while {$i<=$l} {
	if {$i==0} {
	    set x1 [expr {[lindex $coords $i] * $zoom}]
	    set y1 [expr {[lindex $coords $i+1] * $zoom}]
	    set x2 [expr {[lindex $coords $i+2] * $zoom}]
	    set y2 [expr {[lindex $coords $i+3] * $zoom}]
	    set newfree [.panwin.f1.c create line $x1 $y1 $x2 $y2 \
		-fill $color -width $width \
		-tags "freeform $freeform"]
	} else { 
	    set x1 [expr {[lindex $coords $i] * $zoom}]
	    set y1 [expr {[lindex $coords $i+1] * $zoom}]
	    xpos $newfree $x1 $y1 $width $color
	}
	    set i [expr {$i+2}]
    }
    
    .panwin.f1.c raise $newfree background    
}

#****f* annotations.tcl/destroyNewOval
# NAME
#   destroyNewOval -- destroy new oval
# SYNOPSIS
#   destroyNewOval $c
# FUNCTION
#   Destroys newly made oval annotation.
# INPUTS
#   * c -- tk canvas
#****
proc destroyNewOval { c } {
    global newoval
    $c delete -withtags newoval
    set newoval ""
}

#****f* annotations.tcl/destroyNewRect
# NAME
#   destroyNewRect -- destroy new rectangle
# SYNOPSIS
#   destroyNewRect $c
# FUNCTION
#   Destroys newly made rectangle annotation.
# INPUTS
#   * c -- tk canvas
#****
proc destroyNewRect { c } {
    global newrect
    $c delete -withtags newrect
    set newrect ""
}

#****f* annotations.tcl/destroyNewText
# NAME
#   destroyNewText -- destroy new text
# SYNOPSIS
#   destroyNewText $c
# FUNCTION
#   Destroys newly made text annotation.
# INPUTS
#   * c -- tk canvas
#****
proc destroyNewText { c } {
    global newtext
    $c delete -withtags newtext
    set newtext ""
}

#****f* annotations.tcl/destroyNewFree
# NAME
#   destroyNewFree -- destroy new freeform
# SYNOPSIS
#   destroyNewFree $c
# FUNCTION
#   Destroys newly made freeform annotation.
# INPUTS
#   * c -- tk canvas
#****
proc destroyNewFree { c } {
    global newfree
    $c delete -withtags newfree
    set newfree ""
}

#****f* annotations.tcl/annotationConfigGUI
# NAME
#   annotationConfigGUI -- annotation configuration GUI
# SYNOPSIS
#   annotationConfigGUI $c
# FUNCTION
#   Creates a GUI for specified annotation on the canvas.
# INPUTS
#   * c -- tk canvas
#****
proc annotationConfigGUI { c } {
    set annotation [lindex [$c gettags current] 1]
    annotationConfig $c $annotation
    return
}

#****f* annotations.tcl/annotationConfig
# NAME
#   annotationConfig -- annotation configuration
# SYNOPSIS
#   annotationConfig $c $target
# FUNCTION
#   Creates new or modifies existing annotation configuration on the canvas.
# INPUTS
#   * c -- tk canvas
#   * target -- existing or a new annotation
#****
proc annotationConfig { c target } {
    switch -exact -- [nodeType $target] {
	oval {
	    popupOvalDialog $c $target "true"
	}
	rectangle {
	    popupRectangleDialog $c $target "true"
	}
	text {
	    popupTextDialog $c $target "true"
	}
	freeform {
	    popupFreeformDialog $c $target "true"
	}
	default {
	    puts "Unknown type [nodeType $target] for target $target"
	}
    }
    redrawAll
}

#****f* annotations.tcl/button3annotation
# NAME
#   button3annotation -- button3 annotation
# SYNOPSIS
#   button3annotation $type $c $x $y
# FUNCTION
#   Shows the annotation menu when an annotation right clicked.
# INPUTS
#   * type -- type of annotation (oval/rectangle/text/freeform)
#   * c -- tk canvas
#   * x -- x coordinate
#   * y -- y coordinate
#****
proc button3annotation { type c x y } {
    if { $type == "oval" } {
	set procname "Oval"
	set item [lindex [$c gettags {oval && current}] 1]
    } elseif { $type == "rectangle" } {
	set procname "Rectangle"
	set item [lindex [$c gettags {rectangle && current}] 1]
    } elseif { $type == "label" } {
	set procname "Label"
	set item [lindex [$c gettags {label && current}] 1]
    } elseif { $type == "text" } {
	set procname "Text"
	set item [lindex [$c gettags {text && current}] 1]
    } elseif { $type == "freeform" } {
	set procname "Freeform"
	set item [lindex [$c gettags {freeform && current}] 1]
    } else {
	# ???
	return
    }
    
    if { $item == "" } {
	return
    }
    set menutext "$type $item"

    .button3menu delete 0 end

    .button3menu add command -label "Configure $menutext" \
	-command "annotationConfig $c $item"
    .button3menu add command -label "Delete $menutext" \
	-command "deleteAnnotation $c $type $item"

    set x [winfo pointerx .]
    set y [winfo pointery .]
    tk_popup .button3menu $x $y
}

#****f* annotations.tcl/roundRect
# NAME
#   roundRect -- round rectangle
# SYNOPSIS
#   roundRect $w $x0 $y0 $x3 $y3 $radius $args
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
proc roundRect { w x0 y0 x3 y3 radius args } {
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
    tk fontchooser [expr {
            [tk fontchooser configure -visible] ?
            "hide" : "show"}]
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
proc popupColor { type l settext } {
    # popup color selection dialog with current color
    if { $type == "foreground" } {
	set initcolor [$l cget -foreground]
    } else {
	set initcolor [$l cget -background]
    }
    if {$initcolor == ""} {
	set initcolor #808080
    }
    set newcolor [tk_chooseColor -parent .popup.colors -initialcolor $initcolor]

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
#   selectmarkEnter $c $x $y
# FUNCTION
#   Changes the mouse cursor for resizing annotations.
# INPUTS
#   * c -- annotation object 
#   * x -- cursor x coordinate
#   * y -- cursor y coordinate
#****
proc selectmarkEnter { c x y } {
    set obj [lindex [$c gettags current] 1]
    set type [nodeType $obj]

    if {$type != "oval" && $type != "rectangle"} { return }

    set bbox [$c bbox $obj]
    set x1 [lindex $bbox 0]
    set y1 [lindex $bbox 1]
    set x2 [lindex $bbox 2]
    set y2 [lindex $bbox 3]
    set l 0 ;# left
    set r 0 ;# right
    set u 0 ;# up
    set d 0 ;# down

    set x [$c canvasx $x]
    set y [$c canvasy $y]

    if { $x < [expr $x1+($x2-$x1)/8.0]} { set l 1 }
    if { $x > [expr $x2-($x2-$x1)/8.0]} { set r 1 }
    if { $y < [expr $y1+($y2-$y1)/8.0]} { set u 1 }
    if { $y > [expr $y2-($y2-$y1)/8.0]} { set d 1 }

    if {$l==1} {
	if {$u==1} { 
	    $c config -cursor top_left_corner
	} elseif {$d==1} { 
	    $c config -cursor bottom_left_corner
	} else { 
	    $c config -cursor left_side
	} 
    } elseif {$r==1} {
	if {$u==1} { 
	    $c config -cursor top_right_corner
	} elseif {$d==1} { 
	    $c config -cursor bottom_right_corner
	} else { 
	    $c config -cursor right_side
	} 
    } elseif {$u==1} { 
	$c config -cursor top_side
    } elseif {$d==1} {
	$c config -cursor bottom_side
    } else {
	$c config -cursor left_ptr
    }
}

#****f* annotations.tcl/selectmarkLeave
# NAME
#   selectmarkLeave -- selet mark leave
# SYNOPSIS
#   selectmarkLeave $c $x $y
# FUNCTION
#   Resets the mouse cursor when leaving the annotation.
# INPUTS
#   * c -- annotation object 
#   * x -- cursor x coordinate
#   * y -- cursor y coordinate
#****
proc selectmarkLeave { c x y } {
    .bottom.textbox config -text {}
    $c config -cursor left_ptr
}

#****f* annotations.tcl/backgroundImage
# NAME
#   backgroundImage -- set canvas background image
# SYNOPSIS
#   backgroundImage $c $img_data
# FUNCTION
#   Load and draw a background image on the specified canvas.
# INPUTS
#   * c -- tk canvas
#   * img -- variable that contains the image data in the memory
#****
proc backgroundImage { c img } {
    upvar 0 ::cf::[set ::curcfg]::zoom zoom
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    global sizex sizey

    set e_sizex [expr {int($sizex * $zoom)}]
    set e_sizey [expr {int($sizey * $zoom)}]

    if {"$img" == ""} {
	return
    }
    
    set img_data [getImageData $img]
     
    image create photo Photo -data $img_data
    
    set image_h [image height Photo]
    set image_w [image width Photo]
    
    set rx [expr $e_sizex * 1.0 / $image_w]
    set ry [expr $e_sizey  * 1.0/ $image_h]
    
    if { $rx < $ry } {
	set faktor [expr $rx * 100]
    } else {
	set faktor [expr $ry * 100]
    }
    
    set faktor [expr int($faktor)]
    
    if { $faktor != 100 } {
	if { [getImageZoomData $img $faktor] != "" } {
	    image create photo Photo -data [getImageZoomData $img $faktor]
	    set image Photo
	} else {
	    set image [image% Photo $faktor $img]
	}
    } else {
	set image Photo
    }
    $c create image 0 0 -anchor nw -image $image -tags "background"
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
    if {$hasIM && [expr { $image_h > 100 || $image_w > 100 }] } {
	set fname "original.gif"
	$image write $fname
	if {!$winOS} {
	    exec convert $fname -resize $percent\% zoom_$percent.gif
	} else {
	    exec cmd /c convert $fname -resize $percent\% zoom_$percent.gif
	}
	set im2 [image create photo -file zoom_$percent.gif]
	setImageZoomData $img_name zoom_$percent.gif $percent
	if {!$winOS} {
	    exec rm $fname zoom_$percent.gif
	} else {
	    catch { exec cmd /c del $fname zoom_$percent.gif } err
	}
    } else {
	set deno      [gcd $percent 100]
	set zoom      [expr {$percent/$deno}]
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
proc gcd { u v } {expr {$u? [gcd [expr $v%$u] $u]: $v}}

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

    set all_dots [.panwin.f1.c coords $tempfree]
    set len [llength $all_dots]

    # Remove dots one very close to another
    set d 1.5
    set i [expr $len - 20]
    if {$i < 2} {
	set i 2
    }
    for {} {$i < $len} {incr i 2} {
	set a_x [lindex $all_dots [expr $i - 2]]
	set a_y [lindex $all_dots [expr $i - 1]]
	set b_x [lindex $all_dots $i]
	set b_y [lindex $all_dots [expr $i + 1]]
	if {[expr abs($a_x - $b_x)] < $d && [expr abs($a_y - $b_y)] < $d} {
	    set all_dots [lreplace $all_dots $i [expr $i + 1]]
	    incr len -2
	}
    }

    # Remove dots which can be safely linearly interpolated
    set d 1.5
    set i [expr $len - 20]
    if {$i < 2} {
	set i 2
    }
    for {} {$i < $len} {incr i 2} {
	set a_x [lindex $all_dots [expr $i - 4]]
	set a_y [lindex $all_dots [expr $i - 3]]
	set b_x [lindex $all_dots [expr $i - 2]]
	set b_y [lindex $all_dots [expr $i - 1]]
	set c_x [lindex $all_dots $i]
	set c_y [lindex $all_dots [expr $i + 1]]
	if {[expr abs(($a_x + $c_x) / 2 - $b_x)] < $d &&
	    [expr abs(($a_y + $c_y) / 2 - $b_y)] < $d} {
	    set all_dots [lreplace $all_dots [expr $i - 2] [expr $i - 1]]
	    incr len -2
	}
    }

    .panwin.f1.c coords $tempfree [concat $all_dots $x $y]
    .panwin.f1.c itemconfigure $tempfree -fill $color -width $width -capstyle round
}
