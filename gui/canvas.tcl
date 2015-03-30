#
# Copyright 2005-2013 University of Zagreb.
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

# $Id: canvas.tcl 63 2013-10-03 12:17:50Z valter $


#****h* imunes/canvas.tcl
# NAME
#  canvas.tcl -- file used for manipultaion with canvases in IMUNES
# FUNCTION
#  This module is used to define all the actions used for configuring 
#  canvases in IMUNES. On each canvas a part of the simulation is presented
#  If there is no additional canvas defined, simulation is presented on the 
#  defalut canvas.
#
#****

#****f* canvas.tcl/removeCanvas
# NAME
#   removeCanvas -- remove canvas 
# SYNOPSIS
#   removeCanvas $canvas
# FUNCTION
#   Removes the canvas from simulation. This function does not change the 
#   configuration of the nodes, i.e. nodes attached to the removed canvas 
#   remain attached to the same non existing canvas.
# INPUTS
#   * canvas -- canvas id
#****
proc removeCanvas { canvas } {
    upvar 0 ::cf::[set ::curcfg]::canvas_list canvas_list
    upvar 0 ::cf::[set ::curcfg]::$canvas $canvas

    set i [lsearch $canvas_list $canvas]
    set canvas_list [lreplace $canvas_list $i $i]
    set $canvas {}
}

#****f* canvas.tcl/newCanvas
# NAME
#   newCanvas -- create new canvas 
# SYNOPSIS
#   set canvas_id [newCanvas $name]
# FUNCTION
#   Creates new canvas. Returns the canvas_id of the new canvas.
#   If the canvas_name parameter is empty, the name of the new canvas
#   is set to CanvasN, where N represents the canvas_id of the new canvas.
# INPUTS
#   * name -- canvas name
# RESULT
#   * canvas_id -- canvas id
#****
proc newCanvas { name } {
    upvar 0 ::cf::[set ::curcfg]::canvas_list canvas_list

    set canvas [newObjectId canvas]
    upvar 0 ::cf::[set ::curcfg]::$canvas $canvas
    lappend canvas_list $canvas
    set $canvas {}
    if { $name != "" } {
	setCanvasName $canvas $name
    } else {
	setCanvasName $canvas Canvas[string range $canvas 1 end]
    }

    return $canvas
}

#****f* canvas.tcl/setCanvasSize
# NAME
#   setCanvasSize -- set canvas size
# SYNOPSIS
#   setCanvasSize $canvas $x $y
# FUNCTION
#   Sets the specified canvas size.
# INPUTS
#   * canvas -- canvas id
#   * x -- width
#   * y -- height
#****
proc setCanvasSize { canvas x y } {
    upvar 0 ::cf::[set ::curcfg]::$canvas $canvas

    set i [lsearch [set $canvas] "size *"]
    if { $i >= 0 } {
	set $canvas [lreplace [set $canvas] $i $i "size {$x $y}"]
    } else {
	set $canvas [linsert [set $canvas] 1 "size {$x $y}"]
    }
}

#****f* canvas.tcl/getCanvasSize
# NAME
#   getCanvasSize -- get canvas size
# SYNOPSIS
#   getCanvasSize $canvas
# FUNCTION
#   Returns the specified canvas size.
# INPUTS
#   * canvas -- canvas id
# RESULT
#   * size -- canvas size in the form of {x y}
#****
proc getCanvasSize { canvas } {
    upvar 0 ::cf::[set ::curcfg]::$canvas $canvas

    set entry [lrange [lsearch -inline [set $canvas] "size *"] 1 end]
    set size [string trim $entry \{\}]
    if { $size == "" } {
	return "900 620"
    } else {
	return $size
    }
}

#****f* canvas.tcl/getCanvasName
# NAME
#   getCanvasName -- get canvas name
# SYNOPSIS
#   set canvas_name [getCanvasName $canvas]
# FUNCTION
#   Returns the name of the canvas.
# INPUTS
#   * canvas -- canvas id
# RESULT
#   * canvas_name -- canvas name
#****
proc getCanvasName { canvas } {
    upvar 0 ::cf::[set ::curcfg]::$canvas $canvas

    set entry [lrange [lsearch -inline [set $canvas] "name *"] 1 end]
    return [string trim $entry \{\}]
}

#****f* canvas.tcl/setCanvasName
# NAME
#   setCanvasName -- set canvas name
# SYNOPSIS
#   setCanvasName $canvas $name
# FUNCTION
#   Sets the name of the canvas.
# INPUTS
#   * canvas -- canvas id
#   * name -- canvas name
#****
proc setCanvasName { canvas name } {
    upvar 0 ::cf::[set ::curcfg]::$canvas $canvas

    set i [lsearch [set $canvas] "name *"]
    if { $i >= 0 } {
	set $canvas [lreplace [set $canvas] $i $i "name {$name}"]
    } else {
	set $canvas [linsert [set $canvas] 1 "name {$name}"]
    }
}

#****f* canvas.tcl/getCanvasBkg
# NAME
#   getCanvasBkg -- get canvas background image file name
# SYNOPSIS
#   set canvasBkgImage [getCanvasBkg $canvas]
# FUNCTION
#   Returns the name of the canvas background image file.
# INPUTS
#   * canvas -- canvas id
# RESULT
#   * canvasBkgImage -- image variable name
#****
proc getCanvasBkg { canvas } {
    upvar 0 ::cf::[set ::curcfg]::$canvas $canvas

    set entry [lrange [lsearch -inline [set $canvas] "bkgImage *"] 1 end]
    return [string trim $entry \{\}]
}

#****f* canvas.tcl/setCanvasBkg
# NAME
#   setCanvasBkg -- set canvas background
# SYNOPSIS
#   setCanvasBkg $canvas $name
# FUNCTION
#   Sets the background image for the canvas.
# INPUTS
#   * canvas -- canvas id
#   * name -- image variable name
#****
proc setCanvasBkg { canvas name } {
    upvar 0 ::cf::[set ::curcfg]::$canvas $canvas

    set i [lsearch [set $canvas] "bkgImage *"]
    if { $i >= 0 } {
	set $canvas [lreplace [set $canvas] $i $i "bkgImage {$name}"]
    } else {
	set $canvas [linsert [set $canvas] 1 "bkgImage {$name}"]
    }
}

#****f* canvas.tcl/removeCanvasBkg
# NAME
#   removeCanvasBkg -- remove canvas background
# SYNOPSIS
#   removeCanvasBkg $canvas
# FUNCTION
#   Removes the background image for the current canvas.
# INPUTS
#   * canvas -- canvas id
#****
proc removeCanvasBkg { canvas } {
    upvar 0 ::cf::[set ::curcfg]::$canvas $canvas

    set i [lsearch [set $canvas] "bkgImage *"]
    if { $i >= 0 } {
	set $canvas [lreplace [set $canvas] $i $i ]
    }
}

#****f* canvas.tcl/setImageReference
# NAME
#   setImageReference -- set image reference
# SYNOPSIS
#   setImageReference $img $target
# FUNCTION
#   Sets the reference of the $target object to the
#   the image $img.
# INPUTS
#   * img -- image that is being used
#   * target -- the object that uses the image
#****
proc setImageReference { img target } {
    upvar 0 ::cf::[set ::curcfg]::$img $img
    
    set i [lsearch [set $img] "referencedBy *"]
    if { $i >= 0 } {
	set ref_list [getImageReferences $img]
	lappend ref_list $target
	set ref_list [lsort -unique $ref_list]
	set $img [lreplace [set $img] $i $i "referencedBy {$ref_list}"]
    } else {
	set $img [linsert [set $img] 0 "referencedBy {$target}"]
    }
}

#****f* canvas.tcl/getImageReferences
# NAME
#   getImageReferences -- get image reference
# SYNOPSIS
#   getImageReferences $img
# FUNCTION
#   Gets all the references to the image $img.
# INPUTS
#   * img -- image that can be referenced
# RESULT
#   * entry -- list of references to the image
#****
proc getImageReferences { img } {
    upvar 0 ::cf::[set ::curcfg]::$img $img
    
    set entry [lrange [lsearch -inline [set $img] "referencedBy *"] 1 end]
    set entry [string trim $entry \{\}]
    set entry [split $entry " "]
    
    return $entry
}

#****f* canvas.tcl/removeImageReference
# NAME
#   removeImageReference -- remove image reference
# SYNOPSIS
#   removeImageReference $img $target
# FUNCTION
#   Removes the reference of the $target object to the image $img.
# INPUTS
#   * img -- image that is referenced
#   * target -- the object that references the image
#****
proc removeImageReference { img target } {
    upvar 0 ::cf::[set ::curcfg]::$img $img
    
    set entry [lrange [lsearch -inline [set $img] "referencedBy *"] 1 end]
    set entry [string trim $entry \{\}]
    set entry [split $entry " "]
    
    set j [lsearch $entry "$target"]
    if { $j >= 0 } {
	set entry [lreplace $entry $j $j ]
    }
    
    set i [lsearch [set $img] "referencedBy *"]
    if { $i >= 0 } {
	set $img [lreplace [set $img] $i $i "referencedBy {$entry}"]
    }
}

#****f* canvas.tcl/setImageType
# NAME
#   setImageType -- set image type
# SYNOPSIS
#   setImageType $img $type
# FUNCTION
#   Sets the image type of the image $img to the type $type.
# INPUTS
#   * img -- image
#   * type -- type of the image
#****
proc setImageType { img type } {
    upvar 0 ::cf::[set ::curcfg]::$img $img
    
    set i [lsearch [set $img] "type *"]
    if { $i >= 0 } {
	set $img [lreplace [set $img] $i $i "type {$type}"]
    } else {
	set $img [linsert [set $img] 0 "type {$type}"]
    }
}

#****f* canvas.tcl/getImageType
# NAME
#   getImageType -- get the type of an image
# SYNOPSIS
#   getImageType $img
# FUNCTION
#   Gets the image type of the image $img.
# INPUTS
#   * img -- image
# RESULT
#   * imageType -- the type of the image
#****
proc getImageType { img } {
    upvar 0 ::cf::[set ::curcfg]::$img $img
    
    set entry [lrange [lsearch -inline [set $img] "type *"] 1 end]
    return [string trim $entry \{\}]
}

#****f* canvas.tcl/setImageData
# NAME
#   setImageData -- set image data
# SYNOPSIS
#   setImageData $img $path
# FUNCTION
#   Sets image data for variable img.
# INPUTS
#   * img -- image variable
#   * path -- path to image file
#****
proc setImageData { img path } {
    upvar 0 ::cf::[set ::curcfg]::$img $img
    
    set f [open $path]
    fconfigure $f -translation binary
    
    set data [read -nonewline $f]
    set enc_data [base64::encode $data]
    set enc_data [string map {"\n" "\n          "} $enc_data]
    set i [lsearch [set $img] "data *"]
    if { $i >= 0 } {
	set $img [lreplace [set $img] $i $i "data {$enc_data}"]
    } else {
	set $img [linsert [set $img] 0 "data {$enc_data}"]
    }
}

#****f* canvas.tcl/getImageData
# NAME
#   getImageData -- get image data
# SYNOPSIS
#   getImageData $img
# FUNCTION
#   Returns image data for img.
# INPUTS
#   * img -- image variable
# RESULT
#   * data -- image data
#****
proc getImageData { img } {
    upvar 0 ::cf::[set ::curcfg]::$img $img
    
    set entry [lrange [lsearch -inline [set $img] "data *"] 1 end]
    set enc [string trim $entry \{\}]
    set enc [string trim $enc " "]
    set data [base64::decode $enc]
    return $data
}

#****f* canvas.tcl/setImageZoomData
# NAME
#   setImageZoomData -- set image zoom data
# SYNOPSIS
#   setImageZoomData $img $path $zoom
# FUNCTION
#   Sets image zoom data.
# INPUTS
#   * img -- image variable
#   * path -- path to image file
#   * zoom -- zoom percentage
#****
proc setImageZoomData { img path zoom } {
    upvar 0 ::cf::[set ::curcfg]::$img $img
    
    set f [open $path]
    fconfigure $f -translation binary
    
    set data [read -nonewline $f]
    set enc_data [base64::encode $data]
    set enc_data [string map {"\n" "\n          "} $enc_data]
    set i [lsearch [set $img] "zoom_$zoom *"]
    if { $i >= 0 } {
	set $img [lreplace [set $img] $i $i "zoom_$zoom {$enc_data}"]
    } else {
	set $img [linsert [set $img] end "zoom_$zoom {$enc_data}"]
    }
}

#****f* canvas.tcl/getImageZoomData
# NAME
#   getImageZoomData -- get image zoom data
# SYNOPSIS
#   getImageZoomData $img $zoom
# FUNCTION
#   Returns image zoom data.
# INPUTS
#   * img -- image variable
#   * zoom -- zoom percentage
# RESULT
#   * data -- image zoom data
#****
proc getImageZoomData { img zoom } {
    upvar 0 ::cf::[set ::curcfg]::$img $img
    
    set entry [lrange [lsearch -inline [set $img] "zoom_$zoom *"] 1 end]
    set enc [string trim $entry \{\}]
    set enc [string trim $enc " "]
    set data [base64::decode $enc]
    return $data
}

#****f* canvas.tcl/setImageFile
# NAME
#   setImageFile -- set image file
# SYNOPSIS
#   setImageFile $img $file
# FUNCTION
#   Sets image filename.
# INPUTS
#   * img -- image variable
#   * file -- image filename
#****
proc setImageFile { img file } {
    upvar 0 ::cf::[set ::curcfg]::$img $img
    
    set i [lsearch [set $img] "file *"]
    if { $i >= 0 } {
	set $img [lreplace [set $img] $i $i "file {$file}"]
    } else {
	set $img [linsert [set $img] 0 "file {$file}"]
    }
}

#****f* canvas.tcl/getImageFile
# NAME
#   getImageFile -- get image file
# SYNOPSIS
#   getImageFile $img
# FUNCTION
#   Returns image filename.
# INPUTS
#   * img -- image variable
# RESULT
#   * file -- image filename
#****
proc getImageFile { img } {
    upvar 0 ::cf::[set ::curcfg]::$img $img
    
    set entry [lrange [lsearch -inline [set $img] "file *"] 1 end]
    return [string trim $entry \{\}]
}

#****f* canvas.tcl/loadImage
# NAME
#   loadImage -- load the image into running memory
# SYNOPSIS
#   loadImage $path $ref $type
# FUNCTION
#   Load the image from the position $path into memory
#   so that it can be used in the actual project.
# INPUTS
#   * path -- path to the image
#   * ref -- object that loads the image and references it
#   * type -- type of image (custom icon or canvas background)
#   * file -- image filename
# RESULT
#   * imageName -- name of the variable which now contains the image
#****
proc loadImage { path ref type file } {
    upvar 0 ::cf::[set ::curcfg]::image_list image_list
    
    if { [file exists $path] != 1 } {
	after idle {.dialog1.msg configure -wraplength 4i}
	tk_dialog .dialog1 "IMUNES error" \
	    "Couldn\'t find image file." \
	    info 0 Dismiss
	return 2
    }
    
    set i [lsearch -all -glob $image_list "img_*"]
    set i [lindex $i end]
    set count [string range [lindex $image_list $i] 4 end]
    if {$count != ""} {
	incr count
    } else {
	set count 0
    }
    
    set imgname "img_$count"
    upvar 0 ::cf::[set ::curcfg]::$imgname $imgname
    set $imgname {}

    lappend image_list $imgname
    
    setImageData $imgname $path
    setImageFile $imgname [relpath $file]
    if { $ref != "" } {
	setImageReference $imgname $ref
    }    
    setImageType $imgname $type
    
    return $imgname
}

#****f* canvas.tcl/random
# NAME
#   random -- random
# SYNOPSIS
#   random $range $start
# FUNCTION
#   Returns a random number between start and start+range.
# INPUTS
#   * range -- range of numbers
#   * start -- first number
# RESULT
#   * rnd -- random number
#****
proc random { range start } {
    return [expr {int(rand()*$range+$start)}]
}

#****f* canvas.tcl/changeBkgPopup
# NAME
#   changeBkgPopup -- popup dialog to manipulate canvas background
# SYNOPSIS
#   changeBkgPopup
# FUNCTION
#   Select image file and configure the current canvas background.
#****
proc changeBkgPopup {} {
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    global wi canvasBkgMode chbgdialog cc alignCanvasBkg bgsrcfile winOS hasIM
    
    set cc $curcanvas
    set chbgdialog .chbgDialog
    catch {destroy $chbgdialog}
    toplevel $chbgdialog
    wm transient $chbgdialog .
    wm resizable $chbgdialog 0 0
    wm title $chbgdialog "Change canvas background"
    wm iconname $chbgdialog "Change canvas background"

    set wi [ttk::frame $chbgdialog.changebgframe]
    
    ttk::panedwindow $wi.bgconf -orient horizontal
    pack $wi.bgconf -fill both
    
    #left and right pane
    ttk::frame $wi.bgconf.left -relief groove -borderwidth 3
    ttk::frame $wi.bgconf.right -relief groove -borderwidth 3
    
    #right pane definition
    set size [getCanvasSize $curcanvas]
    set sizex [lrange $size 0 0]
    set sizey [lrange $size 1 1]
    ttk::label $wi.bgconf.right.l -text "Canvas: $sizex*$sizey"
    pack $wi.bgconf.right.l
    
    set prevcanvas [canvas $wi.bgconf.right.pc -bd 0 -relief sunken -highlightthickness 0 \
    		-width 150 -height 150]
    pack $prevcanvas
    
    ttk::label $wi.bgconf.right.l2 -text "Image:"
    pack $wi.bgconf.right.l2
    
    #left pane definition
    #upper left frame with label
    ttk::frame $wi.bgconf.left.up
    pack $wi.bgconf.left.up -anchor w
    ttk::label $wi.bgconf.left.up.l -text "Choose background file:"
    
    #center left frame with entry and button
    ttk::frame $wi.bgconf.left.center
    ttk::frame $wi.bgconf.left.center.left
    ttk::frame $wi.bgconf.left.center.right
    pack $wi.bgconf.left.center -fill both -padx 10
    pack $wi.bgconf.left.center.left $wi.bgconf.left.center.right -side left -anchor n -padx 2
    
    
    ttk::entry $wi.bgconf.left.center.left.e -width 35 -textvariable bkgFile
    ttk::button $wi.bgconf.left.center.right.b -text "Browse" -width 8 \
	-command {
	    set fType {
		{{All Images} {.gif}  {}}
		{{All Images} {.png}  {}}
		{{Gif Images} {.gif}  {}}
		{{PNG Images} {.png} {}}
	    }
#		{{All Images} {.jpeg} {}}
#		{{All Images} {.jpg}  {}}
#		{{All Images} {.bmp}  {}}
#		{{All Images} {.tiff} {}}
#		{{Jpeg Images} {.jpg} {}}
#		{{Jpeg Images} {.jpeg} {}}
#		{{Bitmap Images} {.bmp} {}}
#		{{Tiff Images} {.tiff} {}}
	    global canvasBkgMode wi
	    set chbgdialog .chbgDialog
	    set prevcanvas $wi.bgconf.right.pc
	    set imgsize $wi.bgconf.right.l2
	    set bgsrcfile [tk_getOpenFile -parent $chbgdialog -filetypes $fType]
	    $wi.bgconf.left.center.left.e delete 0 end
	    $wi.bgconf.left.center.left.e insert 0 "$bgsrcfile"
	    if {$bgsrcfile != ""} {
		updateBkgPreview $prevcanvas $imgsize $bgsrcfile
	    }
    }
    
    if {$bgsrcfile != ""} {
	set prevcanvas $wi.bgconf.right.pc
	set imgsize $wi.bgconf.right.l2
	updateBkgPreview $prevcanvas $imgsize $bgsrcfile
    }
    
    ttk::frame $wi.bgconf.left.down
    pack $wi.bgconf.left.down -pady 5
    ttk::frame $wi.bgconf.left.down.r
    ttk::label $wi.bgconf.left.down.r.l -text "Image alignment:"
    pack $wi.bgconf.left.down.r.l -anchor w
    
    ttk::frame $wi.bgconf.left.down.r.align -relief groove -borderwidth 2
    pack $wi.bgconf.left.down.r.align
    #lower right frame with alignment options
    ###frame that contains NORTH alignment
    ttk::frame $wi.bgconf.left.down.r.align.n
    ttk::radiobutton $wi.bgconf.left.down.r.align.n.w \
    -variable alignCanvasBkg -value northwest -state enabled 
    ttk::radiobutton $wi.bgconf.left.down.r.align.n.c \
    -variable alignCanvasBkg -value north -state enabled 
    ttk::radiobutton $wi.bgconf.left.down.r.align.n.e \
    -variable alignCanvasBkg -value northeast -state enabled
    pack $wi.bgconf.left.down.r.align.n.w  $wi.bgconf.left.down.r.align.n.c \
      $wi.bgconf.left.down.r.align.n.e -padx 10 -side left
    pack $wi.bgconf.left.down.r.align.n -pady 3
    
    ###frame that contains CENTER alignment
    ttk::frame $wi.bgconf.left.down.r.align.c
    ttk::radiobutton $wi.bgconf.left.down.r.align.c.w \
    -variable alignCanvasBkg -value west -state enabled 
    ttk::radiobutton $wi.bgconf.left.down.r.align.c.c \
    -variable alignCanvasBkg -value center -state enabled 
    ttk::radiobutton $wi.bgconf.left.down.r.align.c.e \
    -variable alignCanvasBkg -value east -state enabled 
    pack $wi.bgconf.left.down.r.align.c.w  $wi.bgconf.left.down.r.align.c.c \
      $wi.bgconf.left.down.r.align.c.e -padx 10 -side left
    pack $wi.bgconf.left.down.r.align.c -pady 3
    
    ###frame that contains SOUTH alignment
    ttk::frame $wi.bgconf.left.down.r.align.s
    ttk::radiobutton $wi.bgconf.left.down.r.align.s.w \
    -variable alignCanvasBkg -value southwest -state enabled 
    ttk::radiobutton $wi.bgconf.left.down.r.align.s.c \
    -variable alignCanvasBkg -value south -state enabled 
    ttk::radiobutton $wi.bgconf.left.down.r.align.s.e \
    -variable alignCanvasBkg -value southeast -state enabled 
    pack $wi.bgconf.left.down.r.align.s.w  $wi.bgconf.left.down.r.align.s.c \
      $wi.bgconf.left.down.r.align.s.e -padx 10 -side left
    pack $wi.bgconf.left.down.r.align.s -pady 3
    
    
    #lower left frame with options
    ttk::frame $wi.bgconf.left.down.l
    
    ttk::radiobutton $wi.bgconf.left.down.l.original -text "Use original/cropped image" \
    -variable canvasBkgMode -value original
    pack $wi.bgconf.left.down.l.original -anchor w
    
    ttk::radiobutton $wi.bgconf.left.down.l.str_shr -text "Stretch/shrink image" \
    -variable canvasBkgMode -value str_shr
    pack $wi.bgconf.left.down.l.str_shr -anchor w
    
    ttk::radiobutton $wi.bgconf.left.down.l.adjust -text "Adjust canvas to image" \
    -variable canvasBkgMode -value adjustC2I 
    pack $wi.bgconf.left.down.l.adjust -anchor w
    
    ttk::radiobutton $wi.bgconf.left.down.l.adjust2 -text "Adjust image to canvas" \
    -variable canvasBkgMode -value adjustI2C 
    pack $wi.bgconf.left.down.l.adjust2 -anchor w
    
    #packing left side
    pack $wi.bgconf.left.up.l -anchor w
    pack $wi.bgconf.left.center.left.e -pady 2
    pack $wi.bgconf.left.center.right.b
    pack $wi.bgconf.left.down.l $wi.bgconf.left.down.r -pady 2 -padx 10 -anchor w -side left
    pack $wi -fill both
    
    #bottom frame with information about imagemagick
    ttk::frame $wi.bgconf.left.downdown
    if {!$hasIM} {
	set canvasBkgMode "adjustC2I"
	$wi.bgconf.left.down.l.original configure -state disabled
	$wi.bgconf.left.down.l.str_shr configure -state disabled
	$wi.bgconf.left.down.l.adjust2 configure -state disabled
	set warning "Package ImageMagick is required for additional background settings."
	ttk::label $wi.bgconf.left.downdown.l -text $warning -foreground red
	pack $wi.bgconf.left.downdown.l -anchor w
    }
    pack $wi.bgconf.left.downdown -side top -anchor w -expand 1
    
    #adding panes to paned window
    $wi.bgconf add $wi.bgconf.left
    $wi.bgconf add $wi.bgconf.right

    #lower frame that contains buttons
    ttk::frame $wi.buttons
    pack $wi.buttons -side bottom -fill x -pady 2m
    ttk::button $wi.buttons.apply -text "Apply" -command {
	    global canvasBkgMode cc chbgdialog
	    popupBkgApply $chbgdialog $cc
    }
    ttk::button $wi.buttons.cancel -text "Cancel" -command "destroy $chbgdialog"
    ttk::button $wi.buttons.remove -text "Remove background" -command \
	 "removeCanvasBkg $cc;
	  if {\"[getCanvasBkg $cc]\" != \"\"} {
	      removeImageReference [getCanvasBkg $cc] $cc
	  }
	  destroy $chbgdialog; redrawAll; set changed 1; updateUndoLog"
    pack $wi.buttons.remove $wi.buttons.cancel $wi.buttons.apply -side right -expand 1
    
    bind $chbgdialog <Key-Return> "popupBkgApply $chbgdialog $cc"
    bind $chbgdialog <Key-Escape> "destroy $chbgdialog"
}

#****f* canvas.tcl/updateBkgPreview
# NAME
#   updateBkgPreview -- function that refreshes the background preview
# SYNOPSIS
#   updateBkgPreview $pc $imgsize $prsrcfile
# FUNCTION
#   Select image file and configure the current canvas background.
# INPUTS
#   * pc -- path to the preview canvas
#   * imgsize -- path to the image size label
#   * prsrcfile -- path to the image that needs to be previewed
#****
proc updateBkgPreview { pc imgsize prsrcfile } {
    set image 0
    $pc delete "preview"

    image create photo $image -file $prsrcfile
    set image_h [image height $image]
    set image_w [image width $image]
    $imgsize configure -text "Image: $image_w*$image_h"

    if {$image_w > 150 || $image_h > 150} {
	set preview 0
	if {$image_w > $image_h} {
	    set x [expr {int($image_w/150.0)}]
	    set y [expr {int($image_h/((150.0/$image_w)*$image_h))}]
	    $preview copy $image -subsample $x $y

	    $preview configure -width 150 \
		-height [expr {int((150.0/$image_w)*$image_h)}]
	} else {
	    set x [expr {int($image_w/((150.0/$image_h)*$image_w))}]
	    set y [expr {int($image_h/150.0)}]
	    $preview copy $image -subsample $x $y

	    $preview configure -width [expr {int((150.0/$image_h)*$image_w)}] \
		-height 150
	}
    } else {
	set preview $image
    }

    $pc create image 0 0 -anchor nw -image $preview -tags "preview"
}

#****f* canvas.tcl/popupBkgApply
# NAME
#   popupBkgApply -- function that applies the changeBkgPopup properties
# SYNOPSIS
#   popupBkgApply $wi $c
# FUNCTION
#   Render and set the background image.
# INPUTS
#   * wi -- path to the changeBkgPopup frame
#   * c -- canvas on which the background is being modified
#****
proc popupBkgApply { wi c } {
    global changed bgsrcfile canvasBkgMode showBkgImage alignCanvasBkg hasIM winOS
    
    set showBkgImage 0
    $wi config -cursor watch
    update
    
    #OS detection (windows or unix) - needed to change the slash sign (/) into backslash (\)
    #in the path of the image file
    #also used to change the exec command because of portability problems
    if {$winOS} {
	set bgsrcfile [string map {/ \\} $bgsrcfile]
    }

    set pastBkg [getCanvasBkg $c]
    if { $pastBkg != ""} {
	removeImageReference $pastBkg $c
    }
    
    # if there is ImageMagick create a new image, load it and then remove it from the drive.
    if { $bgsrcfile != "" && $hasIM } {
	set randNum [random 899 100]
	set destImgFile "background_$c\_$randNum.gif"
	while {[file exists $destImgFile] == 1} {
	    set randNum [random 899 100]
	    set destImgFile "background_$c_$randNum.gif"
	}
	
	set size [getCanvasSize $c]
	set sizex [lrange $size 0 0]
	set sizey [lrange $size 1 1]

	image create photo bkg -file $bgsrcfile
	set image_x [image width bkg]
	set image_y [image height bkg]
	image delete bkg
	if {$image_x > $sizex || $image_y > $sizey} {
	    set crop 1
	} else {
	    set crop 0
	}
	
	if {$bgsrcfile != ""} { 
	    switch $canvasBkgMode {
		original {
		    if {$crop == 1} {
			if {!$winOS} {
			    exec convert $bgsrcfile -gravity $alignCanvasBkg -background white \
			      -extent $sizex\x$sizey $destImgFile
			} else {
			    exec cmd /c convert $bgsrcfile -gravity $alignCanvasBkg -background white \
			      -extent $sizex\x$sizey $destImgFile
			}
		    } else {
			if {!$winOS} {
			    exec convert $bgsrcfile -gravity $alignCanvasBkg -background white \
			      -extent $sizex\x$sizey $destImgFile
			} else {
			  exec cmd /c convert $bgsrcfile -gravity $alignCanvasBkg -background white \
			      -extent $sizex\x$sizey $destImgFile 
			}
		    }	    
		    
		    set bkgname [loadImage $destImgFile $c canvasBackground $bgsrcfile]
		    if {$bkgname == 2} {
			return 0
		    }
		    setCanvasBkg $c $bkgname
		    set showBkgImage 1
		    set changed 1
		    destroy $wi
		}
		str_shr {
		    if {!$winOS} {
			exec convert $bgsrcfile -resize $sizex\x$sizey \
			  -size $sizex\x$sizey xc:white +swap -gravity $alignCanvasBkg -composite $destImgFile
		    } else {
			exec cmd /c convert $bgsrcfile -resize $sizex\x$sizey \
			  -size $sizex\x$sizey xc:white +swap -gravity $alignCanvasBkg -composite $destImgFile
		    }
		    
		    set bkgname [loadImage $destImgFile $c canvasBackground $bgsrcfile]
		    if {$bkgname == 2} {
			return 0
		    }
		    setCanvasBkg $c $bkgname
		    set showBkgImage 1
		    set changed 1
		    destroy $wi
		}
		adjustC2I {
		    set ix [lindex [getMostDistantNodeCoordinates] 0]
		    set iy [lindex [getMostDistantNodeCoordinates] 1]
    
		    if { $image_x < $ix || $image_y < $iy} {
			$wi config -cursor arrow
			update
			set errmsg "Canvas cannot be set to this size: $image_x $image_y. \
			  The most distant icons are on $ix $iy."
			after idle {.dialog1.msg configure -wraplength 4i}
			tk_dialog .dialog1 "IMUNES error" \
			    $errmsg \
			    info 0 Dismiss
		    } else {
			setCanvasSize $c $image_x $image_y
			set changed 1
			switchCanvas none
			set bkgname [loadImage $bgsrcfile $c canvasBackground $bgsrcfile]
			if {$bkgname == 2} {
			    return 0
			}
			setCanvasBkg $c $bkgname
			set showBkgImage 1
			set changed 1
			destroy $wi
		    }
		}
		adjustI2C {
		    if {!$winOS} {
			exec convert $bgsrcfile -resize $sizex\x$sizey\! $destImgFile
		    } else {
			exec cmd /c convert $bgsrcfile -resize $sizex\x$sizey\! $destImgFile
		    }

		    set bkgname [loadImage $destImgFile $c canvasBackground $bgsrcfile]
		    if {$bkgname == 2} {
			return 0
		    }
		    setCanvasBkg $c $bkgname
		    set showBkgImage 1
		    set changed 1
		    destroy $wi
		}
	    }
	}
	
	if {!$winOS && $canvasBkgMode != "adjustC2I"} {
	    exec rm $destImgFile
	}
	if {$winOS && $canvasBkgMode != "adjustC2I"} {
	    catch { exec cmd /c del $destImgFile } err
	}
    }
    
    #if there is no IM then apply only the adjsut canvas to image option 
    if { $bgsrcfile != "" && !$hasIM && $canvasBkgMode == "adjustC2I" } {
	image create photo bkg -file $bgsrcfile
	set image_x [image width bkg]
	set image_y [image height bkg]
	image delete bkg

	set ix [lindex [getMostDistantNodeCoordinates] 0]
	set iy [lindex [getMostDistantNodeCoordinates] 1]
    
	if { $image_x < $ix || $image_y < $iy} {
	    $wi config -cursor arrow
	    update
	    set errmsg "Canvas cannot be set to this size: $image_x $image_y. \
	      The most distant icons are on $ix $iy."
	    after idle {.dialog1.msg configure -wraplength 4i}
	    tk_dialog .dialog1 "IMUNES error" \
		$errmsg \
		info 0 Dismiss
	} else {
	    setCanvasSize $c $image_x $image_y
	    set changed 1
	    switchCanvas none
	    set bkgname [loadImage $bgsrcfile $c canvasBackground $bgsrcfile]
	    if {$bkgname == 2} {
		return 0
	    }
	    setCanvasBkg $c $bkgname
	    set showBkgImage 1
	    set changed 1
	    destroy $wi
	}
    }
    
    if {$changed == 1} {
	redrawAll
	updateUndoLog
    }
}

#****f* editor.tcl/printCanvas
# NAME
#   printCanvas -- print canvas
# SYNOPSIS
#   printCanvas $w
# FUNCTION
#   This procedure is called when the print button in
#   print dialog box is pressed. 
# INPUTS
#   * w -- print dialog widget
#****
proc printCanvas { w } {
    global sizex sizey

    set prncmd [$w.printframe.e1 get]
    destroy $w
    set p [open "|$prncmd" WRONLY]
    puts $p [.panwin.f1.c postscript -height $sizey -width $sizex -x 0 -y 0 -rotate yes -pageheight 297m -pagewidth 210m]
    close $p
}

#****f* editor.tcl/printCanvasToFile
# NAME
#   printCanvasToFile -- print canvas to file
# SYNOPSIS
#   printCanvasToFile $w $entry
# FUNCTION
#   This procedure is called when the print to file
#   button in print to file dialog box is pressed. 
# INPUTS
#   * w -- print to file dialog widget
#   * entry -- file name
#****
proc printCanvasToFile { w entry } {    
    upvar 0 ::cf::[set ::curcfg]::canvas_list canvas_list
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    upvar 0 ::cf::[set ::curcfg]::zoom zoom
    global printFileType
    
    if { [string match -nocase *.* [$entry get]] != 1} {
	set box "[$entry get]\.$printFileType"
	$entry delete 0 end
	$entry insert 0 $box
    }
    
    set temp [$entry get]
    if { $temp == "" || [string match -nocase *.$printFileType $temp] != 1} {
	return
    }
    
    set start_canvas $curcanvas
    if { $printFileType == "ps" } {
	set psname [$entry get]
    } else {
	set pdfname [$entry get]
	set name [string range $pdfname 0 end-4]
	set psname "$name.ps"
    }

    foreach canvas $canvas_list {
	set p [open "$psname" a+]
	set curcanvas $canvas
	switchCanvas none
	set sizex [expr {[lindex [getCanvasSize $curcanvas] 0]*$zoom}]
	set sizey [expr {[lindex [getCanvasSize $curcanvas] 1]*$zoom}]
	puts $p [.panwin.f1.c postscript -height $sizey -width $sizex -x 0 -y 0 -rotate yes -pageheight 297m -pagewidth 210m]
	close $p
    }
    
    if { $printFileType == "pdf" } {
	exec ps2pdf -dPDFSETTINGS=/screen $psname $pdfname
	exec rm $psname
    }
    
    set curcanvas $start_canvas
    switchCanvas none
    destroy $w
}

#****f* editor.tcl/renameCanvasPopup 
# NAME
#   renameCanvasPopup -- rename canvas popup
# SYNOPSIS
#   renameCanvasPopup
# FUNCTION
#   Tk widget for renaming the canvas. 
#****
proc renameCanvasPopup {} {
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas

    set w .entry1
    catch {destroy $w}
    toplevel $w -takefocus 1
    wm transient $w .
    wm resizable $w 0 0

    #update
    #grab $w
    wm title $w "Canvas rename"
    wm iconname $w "Canvas rename"

    #dodan glavni frame "renameframe"
    ttk::frame $w.renameframe
    pack $w.renameframe -fill both -expand 1

    ttk::label $w.renameframe.msg -wraplength 5i -justify left -text "Canvas name:"
    pack $w.renameframe.msg -side top

    ttk::frame $w.renameframe.buttons
    pack $w.renameframe.buttons -side bottom -fill x -pady 2m
    ttk::button $w.renameframe.buttons.print -text "Apply" -command "renameCanvasApply $w"
    ttk::button $w.renameframe.buttons.cancel -text "Cancel" -command "destroy $w"
    pack $w.renameframe.buttons.print $w.renameframe.buttons.cancel -side left -expand 1

    bind $w <Key-Escape> "destroy $w"
    bind $w <Key-Return> "renameCanvasApply $w"

    ttk::entry $w.renameframe.e1
    $w.renameframe.e1 insert 0 [getCanvasName $curcanvas]
    pack $w.renameframe.e1 -side top -pady 5 -padx 10 -fill x
}

#****f* editor.tcl/resizeCanvasPopup
# NAME
#   resizeCanvasPopup -- resize canvas popup
# SYNOPSIS
#   resizeCanvasPopup
# FUNCTION
#   Creates a popup dialog box for resizing canvas.
#****
proc resizeCanvasPopup {} {
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas

    set w .entry1
    catch {destroy $w}
    toplevel $w -takefocus 1
    wm transient $w .
    wm resizable $w 0 0
    #update
    #grab $w
    wm title $w "Canvas resize"
    wm iconname $w "Canvas resize"

    set minWidth [lindex [getMostDistantNodeCoordinates] 0]
    set minHeight [lindex [getMostDistantNodeCoordinates] 1]

    #dodan glavni frame "resizeframe"
    ttk::frame $w.resizeframe
    pack $w.resizeframe -fill both -expand 1


    ttk::label $w.resizeframe.msg -wraplength 5i -justify left -text "Canvas size:"
    pack $w.resizeframe.msg -side top

    ttk::frame $w.resizeframe.buttons
    pack $w.resizeframe.buttons -side bottom -fill x -pady 2m
    ttk::button $w.resizeframe.buttons.print -text "Apply" -command "resizeCanvasApply $w"
    ttk::button $w.resizeframe.buttons.cancel -text "Cancel" -command "destroy $w"
    pack $w.resizeframe.buttons.print $w.resizeframe.buttons.cancel -side left -expand 1
    bind $w <Key-Escape> "destroy $w"
    bind $w <Key-Return> "resizeCanvasApply $w"

    ttk::frame $w.resizeframe.size
    pack $w.resizeframe.size -side top -fill x -pady 2m
    ttk::spinbox $w.resizeframe.size.x -width 4 \
	-validate focus -invalidcommand "focusAndFlash %W"
    $w.resizeframe.size.x insert 0 [lindex [getCanvasSize $curcanvas] 0]
    $w.resizeframe.size.x configure -from $minWidth -to 4096 -increment 2 \
	-validatecommand "checkIntRange %P $minWidth 4096"
    ttk::label $w.resizeframe.size.label -text "*"
    ttk::spinbox $w.resizeframe.size.y -width 4 \
	-validate focus -invalidcommand "focusAndFlash %W"
    $w.resizeframe.size.y insert 0 [lindex [getCanvasSize $curcanvas] 1]
    $w.resizeframe.size.y configure -from $minHeight -to 4096 -increment 2 \
	-validatecommand "checkIntRange %P $minHeight 4096"

    pack $w.resizeframe.size.x $w.resizeframe.size.label $w.resizeframe.size.y -side left -pady 5 -padx 2 -fill x
}

#****f* editor.tcl/renameCanvasApply
# NAME
#   renameCanvasApply -- rename canvas apply
# SYNOPSIS
#   renameCanvasApply $w 
# FUNCTION
#   This procedure is called by clicking on apply button in rename 
#   canvas popup dialog box. It renames the current canvas.
# INPUTS
#   * w -- tk widget (rename canvas popup dialog box)
#****
proc renameCanvasApply { w } {
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    global changed

    set newname [$w.renameframe.e1 get]
    destroy $w
    if { $newname != [getCanvasName $curcanvas] } {
	set changed 1
    }
    setCanvasName $curcanvas $newname
    switchCanvas none
    updateUndoLog
}

#****f* editor.tcl/resizeCanvasApply
# NAME
#   resizeCanvasApply -- resize canvas apply
# SYNOPSIS
#   resizeCanvasApply $w
# FUNCTION
#   This procedure is called by clicking on apply button in resize 
#   canvas popup dialog box. It resizes the current canvas.
# INPUTS
#   * w -- tk widget (resize canvas popup dialog box)
#****
proc resizeCanvasApply { w } {
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    global changed
    
    set x [$w.resizeframe.size.x get]
    set y [$w.resizeframe.size.y get]
    set ix [lindex [getMostDistantNodeCoordinates] 0]
    set iy [lindex [getMostDistantNodeCoordinates] 1]
    
    if { [getCanvasBkg $curcanvas] == "" && $ix <= $x && $iy <= $y} {
	destroy $w
	if { "$x $y" != [getCanvasSize $curcanvas] } {
	    set changed 1
	}
	setCanvasSize $curcanvas $x $y
	switchCanvas none
	updateUndoLog
    } 
}
