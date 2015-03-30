#
# Copyright 2008-2013 University of Zagreb.
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

# $Id: eventedit.tcl 68 2013-10-04 11:17:13Z denis $

foreach b {select const ramp square rand} {
    global eventedit_img

    set eventedit_img($b) \
	[image create photo -file $ROOTDIR/$LIBDIR/icons/tiny/$b.gif]
}

#****f* eventedit.tcl/eventedit
# NAME
#   eventedit -- event edit
# SYNOPSIS
#   eventedit $type $object $param
# FUNCTION
#   
# INPUTS
#   * type -- 
#   * object -- 
#   * param -- 
#****
proc eventedit { type object param } {
    global eventedit_img

    set wi ".event_[set ::curcfg]_$type\_$object\_$param"
    catch {destroy $wi}
    toplevel $wi

    wm transient $wi .
    wm resizable $wi 300 400
    wm geometry $wi 800x280
    wm minsize $wi 200 100

    # Left-side toolbar
    frame $wi.left -width 32 
    pack $wi.left -side left -fill y

    foreach b {select const ramp square rand} {
	radiobutton $wi.left.$b -indicatoron 0 \
	    -variable $wi.activetool -value $b \
	    -selectcolor [$wi.left cget -bg] \
            -width 32 -height 32 -activebackground gray \
	    -image $eventedit_img($b)
	pack $wi.left.$b -side top
    }

    # Scrollbars
    frame $wi.grid
    frame $wi.hframe
    frame $wi.vframe
    set ec [canvas $wi.c -bd 0 -relief sunken -highlightthickness 0 \
        -background gray]
puts $ec

    canvas $wi.hframe.t -width 300 -height 18 -bd 0 -highlightthickness 0 \
        -background gray -xscrollcommand "$wi.hframe.scroll set" \
	-yscrollcommand "$wi.vframe.scroll set"

    scrollbar $wi.hframe.scroll -orient horiz -bd 1 -width 14 \
	-command "$wi.c xview"
    scrollbar $wi.vframe.scroll -bd 1 -width 14 \
	-command "$wi.c yview"

    # Scrolling and panning support
    bind $wi.c <2> "$wi.c scan mark %x %y"
    bind $wi.c <B2-Motion> "$wi.c scan dragto %x %y 1"
    bind $wi.c <4> "$wi.c yview scroll 1 units"
    bind $wi.c <5> "$wi.c yview scroll -1 units"
    bind $wi <Right> "$wi.c xview scroll 1 units"
    bind $wi <Left> "$wi.c xview scroll -1 units"
    bind $wi <Down> "$wi.c yview scroll 1 units"
    bind $wi <Up> "$wi.c yview scroll -1 units"

    pack $wi.hframe.t -side left -padx 0 -pady 0
    pack $wi.hframe.scroll -side left -padx 0 -pady 0 -fill both -expand true
    pack $wi.vframe.scroll -side top -padx 0 -pady 0 -fill both -expand true
    pack $wi.grid -expand yes -fill both -padx 1 -pady 1

    grid rowconfig $wi.grid 0 -weight 1 -minsize 0
    grid columnconfig $wi.grid 0 -weight 1 -minsize 0
    grid $wi.c -in $wi.grid -row 0 -column 0 \
	-rowspan 1 -columnspan 1 -sticky news
    grid $wi.vframe -in $wi.grid -row 0 -column 1 \
        -rowspan 1 -columnspan 1 -sticky news
    grid $wi.hframe -in $wi.grid -row 1 -column 0 \
        -rowspan 1 -columnspan 1 -sticky news

    frame $wi.bottom
    pack $wi.bottom -side bottom -fill x
    label $wi.bottom.textbox -relief sunken -bd 1 -anchor w -width 999
    pack $wi.bottom.textbox -side right -padx 0 -fill both

    eventredraw $wi $type $object $param
}

#****f* eventedit.tcl/eventredraw
# NAME
#   eventredraw -- event redraw
# SYNOPSIS
#   eventredraw $wi $type $obj $param
# FUNCTION
#   
# INPUTS
#   * wi -- 
#   * type -- 
#   * obj -- 
#   * param -- 
#****
proc eventredraw { wi type obj param } {

    set border 4
    set zoomx 8
    set zoomy 2

    set events [lsearch -all -inline [getLinkEvents $obj] "* $param *"]
    set t_infinity [expr [lindex [lindex $events end] 0] * 1.5]
    if { $t_infinity < 180 } {
	set t_infinity 180
    }

    set sizex $t_infinity
    set sizey 100
    set e_sizex [expr {int($sizex * $zoomx)}]
    set e_sizey [expr {int($sizey * $zoomy)}]

    set scalewidthx 24
    set scalewidthy [expr 12 + log10($sizey) * 8]

    $wi.c configure -scrollregion \
        "-$border -$border [expr {$e_sizex + $border + $scalewidthy}] \
        [expr {$e_sizey + $border + $scalewidthx}]"

    $wi.c delete all

    # background and scale boxes
    $wi.c create rectangle $scalewidthy 0 [expr $e_sizex + $scalewidthy] \
	$e_sizey -fill white -tags "background"
    $wi.c create rectangle $scalewidthy $e_sizey \
	[expr $e_sizex + $scalewidthy] \
	[expr $e_sizey + $scalewidthx] -fill white -tags "x_scale"
    $wi.c create rectangle 0 0 $scalewidthy $e_sizey \
	 -fill white -tags "y_scale"
    $wi.c lower -withtags background

    # grid X
    set step 5
    for { set i $step } { $i < $sizex } { incr i $step } {
	if { [expr $i % 60] == 0 } {
	    set dash "4 4"
	    set ll 6
	    $wi.c create text [expr $scalewidthy + $zoomx * $i] \
		[expr $e_sizey + $scalewidthx / 2] \
		-text "[expr $i / 60]m"
	} elseif { [expr $i % 10] == 0 } {
	    set dash "1 3"
	    set ll 4
	    $wi.c create text [expr $scalewidthy + $zoomx * $i] \
		[expr $e_sizey + $scalewidthx / 2] \
		-text "[expr $i / 60]m[expr $i % 60]s" -fill gray48
        } else {
	    set ll 2
	    set dash "1 7"
	}
	$wi.c create line [expr $scalewidthy + $zoomx * $i] \
	    1 [expr $scalewidthy + $zoomx * $i] $e_sizey \
	    -fill gray -dash $dash -tags "grid"
	$wi.c create line [expr $scalewidthy + $zoomx * $i] \
	    $e_sizey [expr $scalewidthy + $zoomx * $i] \
	    [expr $e_sizey + $ll] -fill black -tags "grid"
    }

    # grid Y
    set step [expr $sizey / 10]
    for { set i $step } { $i < $sizey } { incr i $step } {
	if { [expr $i % ($sizey / 5)] == 0 } {
	    set ll 4
	    set dash "1 3"
	    $wi.c create text [expr $scalewidthy / 2] \
		[expr $e_sizey - $zoomy * $i] \
		-text "$i" -fill gray48
	} else {
	    set ll 2
	    set dash "1 7"
	}
	$wi.c create line [expr $scalewidthy + 1] \
	    [expr $e_sizey - $zoomy * $i] \
	    [expr $scalewidthy + $e_sizex - 2] \
	    [expr $e_sizey - $zoomy * $i] \
	    -fill gray -dash $dash -tags "grid"
	$wi.c create line [expr $scalewidthy - $ll] \
	    [expr $e_sizey - $zoomy * $i] \
	    $scalewidthy [expr $e_sizey - $zoomy * $i] \
	    -fill black -tags "grid"
    }

    # insert the GUI default value as event #0
    switch -exact -- $param {
	bandwidth {
	    set value [getLinkBandwidth $obj]
	}
	delay {
	    set value [getLinkDelay $obj]
	}
	ber {
	    set value [getLinkBER $obj]
	}
	duplicate {
	    set value [getLinkDup $obj]
	}
	width {
	    set value [getLinkWidth $obj]
	}
	color {
	    set value [getLinkColor $obj]
	}
    }
    set events "{0 $param const $value} $events"
puts $events

    for { set i 0} { $i < [llength $events] } { incr i } {
	set ev [lindex $events $i]
	set t [lindex $ev 0]
	set fn [lindex $ev 2]
	set lo [lindex $ev 3]
	set hi [lindex $ev 4]
	if { $hi == "" } {
	    set hi $lo
	}

	# we need to know a bit about the next event as well
	set i_next [expr $i + 1]
	if { $i_next < [llength $events] } {
	    set ev_next [lindex $events $i_next]
	    set t_next [lindex $ev_next 0]
	    # discard all but the last event scheduled for the same t
	    if { $t == $t_next } {
		continue
	    }
	} else {
	    set t_next $t_infinity
	}
	
	$wi.c create rectangle [expr ($t * $zoomx) + $scalewidthy] \
	    [expr ($sizey - $lo) * $zoomy] \
	    [expr ($t_next * $zoomx) + $scalewidthy] \
	    [expr ($sizey - $hi) * $zoomy] -fill gray -outline black
puts $fn
	if { $hi != $lo } {
	    $wi.c create text \
		[expr (($t + $t_next) * $zoomx * .5) + $scalewidthy] \
		[expr ($sizey - ($hi + $lo) * .5) * $zoomy] \
		-text "$fn $lo $hi"
	}
    }
}
