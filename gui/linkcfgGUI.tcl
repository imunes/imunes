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

# $Id: linkcfgGUI.tcl 67 2013-10-04 08:31:52Z denis $


#****f* linkcfgGUI.tcl/linkConfigGUI
# NAME
#   linkConfigGUI -- link configuration GUI
# SYNOPSIS
#   linkConfigGUI $c $link_id
# FUNCTION
#   Calls procedure link.configGUI.
# INPUTS
#   * c - tk canvas
#   * link_id - link id
#****
proc linkConfigGUI { c link_id } {
    if { $link_id == "" } {
	set link_id [lindex [$c gettags current] 1]
    }

    link.configGUI $c $link_id
}

#****f* linkcfgGUI.tcl/toggleDirectLink
# NAME
#   toggleDirectLink -- link configuration GUI
# SYNOPSIS
#   toggleDirectLink $c $link_id
# FUNCTION
#   Toggles link 'direct' option.
# INPUTS
#   * c - tk canvas
#   * link_id - link id
#****
proc toggleDirectLink { c link_id } {
    if { $link_id == "" } {
	set link_id [lindex [$c gettags current] 1]
    }

    set new_value [expr [getLinkDirect $link_id] ^ 1]
    setLinkDirect $link_id $new_value

    set mirror_link_id [getLinkMirror $link_id]
    if { $mirror_link_id != "" } {
	setLinkDirect $mirror_link_id $new_value
    }
}

#****f* linkcfgGUI.tcl/link.configGUI
# NAME
#   link.configGUI -- configuration GUI
# SYNOPSIS
#   link.configGUI $c $link_id
# FUNCTION
#   Defines the structure of the link configuration window by calling
#   procedures for creating and organising the window, as well as
#   procedures for adding certain modules to that window.
# INPUTS
#   * c - tk canvas
#   * link_id - link id
#****
proc link.configGUI { c link_id } {
    global wi
    #
    #guielements - the list of link configuration parameters (except Color parameter)
    #              (this list is used when calling configGUI_linkConfigApply procedure)
    #
    global configelements
    set configelements {}

    configGUI_createConfigPopupWin $c
    wm title $wi "link configuration"

    configGUI_linkFromTo $wi $link_id
    configGUI_linkConfig $wi $link_id "Bandwidth" "Bandwidth (bps):"
    configGUI_linkConfig $wi $link_id "Delay" "Delay (us):"
    configGUI_linkConfig $wi $link_id "BER" "BER (1/N):"
    configGUI_linkConfig $wi $link_id "Loss" "Loss (%):"
    configGUI_linkConfig $wi $link_id "Dup" "Duplicate (%):"
    configGUI_linkConfig $wi $link_id "Width" "Width:"
    configGUI_linkColor $wi $link_id

    configGUI_buttonsACLink $wi $link_id
}

#****f* linkcfgGUI.tcl/configGUI_buttonsACLink
# NAME
#   configGUI_buttonsACLink -- configuration GUI - buttons apply/close link
# SYNOPSIS
#  configGUI_buttonsACLink $wi $link_id
# FUNCTION
#   Creates module with options for saving/discarding changes (Apply, Cancel).
# INPUTS
#   * wi - widget
#   * link_id - link id
#****
proc configGUI_buttonsACLink { wi link_id } {
    global badentry configelements

    ttk::frame $wi.buttons -borderwidth 6
    ttk::button $wi.buttons.apply -text "Apply" -command \
        "configGUI_applyButtonLink $wi $link_id 0"
    focus $wi.buttons.apply

    ttk::button $wi.buttons.cancel -text "Cancel" -command \
        "set badentry -1; destroy $wi"

    pack $wi.buttons.apply -side left -anchor e -expand 1 -pady 2
    pack $wi.buttons.cancel -side right -anchor w -expand 1 -pady 2
    pack $wi.buttons -fill both -expand 1 -side bottom

    bind $wi <Key-Return> \
        "configGUI_applyButtonLink $wi $link_id 0"
    bind $wi <Key-Escape> "set badentry -1; destroy $wi"
}

#****f* linkcfgGUI.tcl/configGUI_applyButtonLink
# NAME
#   configGUI_applyButtonLink -- configuration GUI - apply button link
# SYNOPSIS
#   configGUI_applyButtonLink $wi $link_id $phase
# FUNCTION
#   Calles procedures for saving changes to the link.
# INPUTS
#   * wi -- widget
#   * link_id -- link id
#   * phase --
#****
proc configGUI_applyButtonLink { wi link_id phase } {
    global changed badentry

    $wi config -cursor watch
    update
    if { $phase == 0 } {
	set badentry 0
	focus .
	after 100 "configGUI_applyButtonLink $wi $link_id 1"
	return
    } elseif { $badentry } {
	$wi config -cursor left_ptr
	return
    }

    configGUI_linkConfigApply $wi $link_id
    configGUI_linkColorApply $wi $link_id

    if { $changed == 1 && [getFromRunning "oper_mode"] == "exec" } {
	set eid [getFromRunning "eid"]
	saveRunningConfigurationInteractive $eid
	execSetLinkParams $eid $link_id
    }

    if { $changed == 1 } {
	redrawAll
	updateUndoLog
    }

    destroy .popup
}

#****f* linkcfgGUI.tcl/configGUI_linkFromTo
# NAME
#   configGUI_linkFromTo -- configuration GUI - link from node1 to node2
# SYNOPSIS
#  configGUI_linkFromTo $wi $link_id
# FUNCTION
#   Creates module with information about link endpoints.
# INPUTS
#   * wi - widget
#   * link_id - link id
#****
proc configGUI_linkFromTo { wi link_id } {
    lassign [getLinkPeers $link_id] node1 node2

    ttk::frame $wi.name -borderwidth 6
    ttk::label $wi.name.txt -text "Link from [getNodeName $node1] to [getNodeName $node2]"

    pack $wi.name.txt
    pack $wi.name -fill both -expand 1
}

#****f* linkcfgGUI.tcl/configGUI_linkConfig
# NAME
#   configGUI_linkConfig -- configuration GUI - link configuration
# SYNOPSIS
#  configGUI_linkConfig $wi $link_id $param $label
# FUNCTION
#   Creates module for changing specific parameter.
# INPUTS
#   * wi - widget
#   * link_id - link id
#   * param - link parameter
#   * label - link parameter label
#****
proc configGUI_linkConfig { wi link_id param label } {
    global configelements

    lappend configelements $param
    if { $param == "Bandwidth" } {
        set from 0; set to 1000000000000; set inc 1000
    } elseif { $param == "Delay" } {
        set from 0; set to 10000000; set inc 5
    } elseif { $param == "BER" } {
        set from 0; set to 10000000000000; set inc 1000
    } elseif { $param == "Loss" } {
        set from 0; set to 100; set inc 1
    } elseif { $param == "Dup" } {
        set from 0; set to 50; set inc 1
    } elseif { $param == "Width" } {
        set from 1; set to 8; set inc 1
    } else {
	return
    }

    set fr [string tolower $param ]
    ttk::frame $wi.$fr -borderwidth 4
    ttk::label $wi.$fr.txt -text $label
    ttk::spinbox $wi.$fr.value -justify right -width 10 \
	    -validate focus -invalidcommand "focusAndFlash %W"
    set value [getLink$param $link_id]
    if { $value == "" } {
        set value 0
    }

    $wi.$fr.value insert 0 $value

    $wi.$fr.value configure \
	    -validatecommand "checkIntRange %P $from $to" \
	    -from $from -to $to -increment $inc

    pack $wi.$fr.txt -side left
    pack $wi.$fr.value -side right
    pack $wi.$fr -fill both -expand 1
}

#****f* linkcfgGUI.tcl/configGUI_linkColor
# NAME
#   configGUI_linkColor -- configuration GUI - link color
# SYNOPSIS
#  configGUI_linkColor $wi $link_id
# FUNCTION
#   Creates module for changing link color.
# INPUTS
#   * wi - widget
#   * link_id - link id
#****
proc configGUI_linkColor { wi link_id } {
    global link_color

    ttk::frame $wi.color -borderwidth 4
    ttk::label $wi.color.txt -text "Color:"

    set link_color [getLinkColor $link_id]
    ttk::combobox $wi.color.value -justify right -width 11 -textvariable link_color
    $wi.color.value configure -values [list Red Green Blue Yellow Magenta Cyan Black]

    pack $wi.color.txt -side left
    pack $wi.color.value -side right
    pack $wi.color -fill both -expand 1
}

#****f* linkcfgGUI.tcl/linkJitterConfigGUI
# NAME
#   linkJitterConfigGUI -- link jitter configuration GUI
# SYNOPSIS
#   linkJitterConfigGUI $c $link_id
# FUNCTION XXX
#   Defines the structure of the link configuration window by calling
#   procedures for creating and organising the window, as well as
#   procedures for adding certain modules to that window.
# INPUTS
#   * c - tk canvas
#   * link_id - link id
#****
proc linkJitterConfigGUI { c link_id } {
    global wi badentry up_jitmode down_jitmode

    lassign [getLinkPeers $link_id] node1 node2
    set node1_name [getNodeName $node1]
    set node2_name [getNodeName $node2]

    configGUI_createConfigPopupWin $c
    wm title $wi "link $node1_name-$node2_name jitter configuration"

    ttk::frame $wi.up
    ttk::frame $wi.down
    ttk::separator $wi.s -orient vertical

    ttk::label $wi.up.label -text "Upstream ($node2_name->$node1_name):"
    ttk::label $wi.down.label -text "Downstream ($node1_name->$node2_name):"

    ttk::label $wi.up.modelab -text "Jitter mode:"
    ttk::label $wi.down.modelab -text "Jitter mode:"
    ttk::combobox $wi.up.jitmode -justify right -width 10 \
	-textvariable up_jitmode -state readonly
    $wi.up.jitmode configure -values "sequential random"
    ttk::combobox $wi.down.jitmode -justify right -width 10 \
	-textvariable down_jitmode -state readonly
    $wi.down.jitmode configure -values "sequential random"

    ttk::label $wi.up.holdlab -text "Jitter hold (ms):"
    ttk::label $wi.down.holdlab -text "Jitter hold (ms):"

    ttk::spinbox $wi.up.holdval -width 9 -increment 10 -from 0 -to 10000000 \
	-justify right
    ttk::spinbox $wi.down.holdval -width 9 -increment 10 -from 0 -to 10000000 \
	-justify right

    ttk::label $wi.up.elab -text "Jitter values (ms):"
    ttk::label $wi.down.elab -text "Jitter values (ms):"

    ttk::scrollbar $wi.up.vsb -orient vertical \
	-command [list $wi.up.editor yview]
    ttk::scrollbar $wi.down.vsb -orient vertical \
	-command [list $wi.down.editor yview]

    text $wi.up.editor -width 30 -height 20 -bg white -wrap none \
	-yscrollcommand [list $wi.up.vsb set]
    text $wi.down.editor -width 30 -height 20 -bg white -wrap none \
	-yscrollcommand [list $wi.down.vsb set]

    ttk::frame $wi.buttons -borderwidth 3
    ttk::button $wi.buttons.apply -text "Apply" -command \
        "applyJitterLink $wi $link_id"
    ttk::button $wi.buttons.applyclose -text "Apply & Close" -command \
        "applyJitterLink $wi $link_id; destroy $wi"
    ttk::button $wi.buttons.cancel -text "Cancel" -command \
        "destroy $wi"
    bind $wi <Key-Escape> "destroy $wi"

    set up_jitmode [getLinkJitterModeUpstream $link_id]
    if { $up_jitmode == "" } { set up_jitmode sequential }
    set down_jitmode [getLinkJitterModeDownstream $link_id]
    if { $down_jitmode == "" } { set down_jitmode sequential }

    $wi.up.editor insert end [join [getLinkJitterUpstream $link_id] "\n"]
    $wi.down.editor insert end [join [getLinkJitterDownstream $link_id] "\n"]

    set val [getLinkJitterHoldUpstream $link_id]
    if { $val == "" } { set val 0 }
    $wi.up.holdval insert 0 $val
    set val [getLinkJitterHoldDownstream $link_id]
    if { $val == "" } { set val 0 }
    $wi.down.holdval insert 0 $val

    grid $wi.up.label -row 0 -column 0 -in $wi.up -sticky w -pady 3
    grid $wi.up.modelab -row 1 -column 0 -in $wi.up -sticky w
    grid $wi.up.jitmode -row 1 -column 0 -in $wi.up -sticky e
    grid $wi.up.holdlab -row 2 -column 0 -in $wi.up -sticky w -pady 2
    grid $wi.up.holdval -row 2 -column 0 -in $wi.up -sticky e -pady 2
    grid $wi.up.elab -row 3 -column 0 -in $wi.up -sticky w
    grid $wi.up.editor -row 4 -column 0 -sticky nsew -in $wi.up
    grid $wi.up.vsb -row 4 -column 1 -sticky nsew -in $wi.up

    grid $wi.down.label -row 0 -column 0 -in $wi.down -sticky w -pady 3
    grid $wi.down.modelab -row 1 -column 0 -in $wi.down -sticky w
    grid $wi.down.jitmode -row 1 -column 0 -in $wi.down -sticky e
    grid $wi.down.holdlab -row 2 -column 0 -in $wi.down -sticky w -pady 2
    grid $wi.down.holdval -row 2 -column 0 -in $wi.down -sticky e -pady 2
    grid $wi.down.elab -row 3 -column 0 -in $wi.down -sticky w
    grid $wi.down.editor -row 4 -column 0 -sticky nsew -in $wi.down
    grid $wi.down.vsb -row 4 -column 1 -sticky nsew -in $wi.down

    grid $wi.buttons.apply -row 0 -column 0 -in $wi.buttons -padx 1
    grid $wi.buttons.applyclose -row 0 -column 2 -in $wi.buttons -padx 2
    grid $wi.buttons.cancel -row 0 -column 3 -in $wi.buttons -padx 1

    grid $wi.down -row 0 -column 0 -sticky nsew -in $wi
    grid $wi.s -row 0 -column 1 -sticky ns -in $wi -padx 2
    grid $wi.up -row 0 -column 2 -sticky nsew -in $wi
    grid $wi.buttons -row 1 -column 0 -columnspan 3 -sticky ns -in $wi -padx 1 -pady 1
}

#****f* linkcfgGUI.tcl/applyJitterLink
# NAME
#   applyJitterLink -- apply jitter link
# SYNOPSIS
#   applyJitterLink $wi $link_id
# FUNCTION
#   Applies jitter upstream and downstream to the specified link.
# INPUTS
#   * wi -- widget
#   * link_id -- link id
#****
proc applyJitterLink { wi link_id } {
    global up_jitmode down_jitmode

    setLinkJitterModeUpstream $link_id $up_jitmode
    setLinkJitterModeDownstream $link_id $down_jitmode

    setLinkJitterHoldUpstream $link_id [$wi.up.holdval get]
    setLinkJitterHoldDownstream $link_id [$wi.down.holdval get]

    set jitt_up [$wi.up.editor get 1.0 "end -1c"]
    set jitt_down [$wi.down.editor get 1.0 "end -1c"]

    set jup ""
    set jdown ""

    foreach line $jitt_up {
	if { [string is double $line] && $line != "" && $line < 10000 } {
	    lappend jup [expr round($line*1000)/1000.0]
	}
    }

    foreach line $jitt_down {
	if { [string is double $line] && $line != "" && $line < 10000 } {
	    lappend jdown [expr round($line*1000)/1000.0]
	}
    }

    if { $jup != "" } {
	setLinkJitterUpstream $link_id $jup
    }
    if { $jdown != "" } {
	setLinkJitterDownstream $link_id $jdown
    }

    $wi.up.editor delete 1.0 end
    $wi.up.editor insert end [join $jup "\n"]
    $wi.down.editor delete 1.0 end
    $wi.down.editor insert end [join $jdown "\n"]

    if { [getFromRunning "oper_mode"] == "exec" } {
	set eid [getFromRunning "eid"]
	saveRunningConfigurationInteractive $eid
	execSetLinkJitter $eid $link_id
    }

    updateUndoLog
    redrawAll
}

#****f* linkcfgGUI.tcl/linkJitterReset
# NAME
#   linkJitterReset -- reset jitter link
# SYNOPSIS
#   linkJitterReset $link_id
# FUNCTION
#   Resets upstream and downstream inputs for a specified link.
# INPUTS
#   * link_id -- link id
#****
proc linkJitterReset { link_id } {
    setLinkJitterModeUpstream $link_id ""
    setLinkJitterModeDownstream $link_id ""

    setLinkJitterHoldUpstream $link_id ""
    setLinkJitterHoldDownstream $link_id ""

    setLinkJitterUpstream $link_id ""
    setLinkJitterDownstream $link_id ""

    if { [getFromRunning "oper_mode"] == "exec" } {
	set eid [getFromRunning "eid"]
	saveRunningConfigurationInteractive $eid
	execResetLinkJitter $eid $link_id
    }

    updateUndoLog
}

###############"Apply" procedures################

#****f* linkcfgGUI.tcl/configGUI_linkConfigApply
# NAME
#   configGUI_linkConfigApply -- configuration GUI - link configuration apply
# SYNOPSIS
#  configGUI_linkConfigApply $wi $link_id
# FUNCTION
#   Saves changes in the module with specific parameter
#   (except Color parameter).
# INPUTS
#   * wi - widget
#   * link_id - link id
#****
proc configGUI_linkConfigApply { wi link_id } {
    global changed configelements

    foreach element $configelements {
	set value [$wi.[string tolower $element].value get]
	if { $value == 0 } {
	    set value ""
	}

	if { $value != [getLink$element $link_id] } {
	    set mirror [getLinkMirror $link_id]
	    setLink$element $link_id $value
	    if { $mirror != "" } {
		setLink$element $mirror $value
	    }

	    set changed 1
	}
    }
}

#****f* linkcfgGUI.tcl/configGUI_linkColorApply
# NAME
#   configGUI_linkColorApply-- configuration GUI - link color apply
# SYNOPSIS
#  configGUI_linkColorApply $wi $link_id
# FUNCTION
#   Saves changes in the module with link color.
# INPUTS
#   * wi - widget
#   * link_id - link id
#****
proc configGUI_linkColorApply { wi link_id } {
    global changed link_color

    set mirror [getLinkMirror $link_id]
    if { $link_color != [getLinkColor $link_id] } {
	setLinkColor $link_id $link_color
	if { $mirror != "" } {
	    setLinkColor $mirror $link_color
	}

	set changed 1
    }
}

#****f* linkcfg.tcl/getLinkDirect
# NAME
#   getLinkDirect -- get if link is direct
# SYNOPSIS
#   set link_direct [getLinkDirect $link_id]
# FUNCTION
#   Returns boolean - link is direct.
# INPUTS
#   * link_id -- link id
# RESULT
#   * link_direct -- returns 0 if link is not a direct link and 1 if it is
#****
proc _getLinkDirect { link_cfg } {
    return [_cfgGetWithDefault 0 $link_cfg "direct"]
}

#****f* linkcfg.tcl/setLinkDirect
# NAME
#   setLinkDirect -- set link bandwidth
# SYNOPSIS
#   setLinkDirect $link_id $direct
# FUNCTION
#   Sets the link bandwidth in a bits per second.
# INPUTS
#   * link_id -- link id
#   * direct -- link bandwidth in bits per second.
#****
proc _setLinkDirect { link_cfg direct } {
    return [_cfgSet $link_cfg "direct" $direct]
}

#****f* linkcfg.tcl/getLinkBandwidth
# NAME
#   getLinkBandwidth -- get link bandwidth
# SYNOPSIS
#   set bandwidth [getLinkBandwidth $link_id]
# FUNCTION
#   Returns the link bandwidth expressed in bits per second.
# INPUTS
#   * link_id -- link id
# RESULT
#   * bandwidth -- The value of link bandwidth in bits per second.
#****
proc _getLinkBandwidth { link_cfg } {
    return [_cfgGet $link_cfg "bandwidth"]
}

#****f* linkcfg.tcl/setLinkBandwidth
# NAME
#   setLinkBandwidth -- set link bandwidth
# SYNOPSIS
#   setLinkBandwidth $link_id $bandwidth
# FUNCTION
#   Sets the link bandwidth in a bits per second.
# INPUTS
#   * link_id -- link id
#   * bandwidth -- link bandwidth in bits per second.
#****
proc _setLinkBandwidth { link_cfg bandwidth } {
    if { $bandwidth == 0 } {
	set bandwidth ""
    }

    return [_cfgSet $link_cfg "bandwidth" $bandwidth]
}

#****f* linkcfg.tcl/getLinkColor
# NAME
#   getLinkColor -- get link color
# SYNOPSIS
#   getLinkColor $link
# FUNCTION
#   Returns the color of the link.
# INPUTS
#   * link -- link id
# RESULT
#   * color -- link color
#****
proc _getLinkColor { link_cfg } {
    global defLinkColor

    return [_cfgGetWithDefault $defLinkColor $link_cfg "color"]
}

#****f* linkcfg.tcl/setLinkColor
# NAME
#   setLinkColor -- set link color
# SYNOPSIS
#   setLinkColor $link_id $color
# FUNCTION
#   Sets the color of the link.
# INPUTS
#   * link_id -- link id
#   * color -- link color
#****
proc _setLinkColor { link_cfg color } {
    if { $color == "Red" } {
	set color ""
    }

    return [_cfgSet $link_cfg "color" $color]
}

#****f* linkcfg.tcl/getLinkWidth
# NAME
#   getLinkWidth -- get link width
# SYNOPSIS
#   getLinkWidth $link
# FUNCTION
#   Returns the link width on canvas.
# INPUTS
#   * link -- link id
#****
proc _getLinkWidth { link_cfg } {
    global defLinkWidth

    return [_cfgGetWithDefault $defLinkWidth $link_cfg "width"]
}

#****f* linkcfg.tcl/setLinkWidth
# NAME
#   setLinkWidth -- set link width
# SYNOPSIS
#   setLinkWidth $link_id $width
# FUNCTION
#   Sets the link width on canvas.
# INPUTS
#   * link_id -- link id
#   * width -- link width
#****
proc _setLinkWidth { link_cfg width } {
    global defLinkWidth

    if { $width == $defLinkWidth } {
	set width ""
    }

    return [_cfgSet $link_cfg "width" $width]
}

#****f* linkcfg.tcl/getLinkDelay
# NAME
#   getLinkDelay -- get link delay
# SYNOPSIS
#   set delay [getLinkDelay $link_id]
# FUNCTION
#   Returns the link delay expressed in microseconds.
# INPUTS
#   * link_id -- link id
# RESULT
#   * delay -- The value of link delay in microseconds.
#****
proc _getLinkDelay { link_cfg } {
    return [_cfgGet $link_cfg "delay"]
}

#****f* linkcfg.tcl/setLinkDelay
# NAME
#   setLinkDelay -- set link delay
# SYNOPSIS
#   setLinkDelay $link_id $delay
# FUNCTION
#   Sets the link delay in microseconds.
# INPUTS
#   * link_id -- link id
#   * delay -- link delay delay in microseconds.
#****
proc _setLinkDelay { link_cfg delay } {
    if { $delay == 0 } {
	set delay ""
    }

    return [_cfgSet $link_cfg "delay" $delay]
}

#****f* linkcfg.tcl/getLinkJitterUpstream
# NAME
#   getLinkJitterUpstream -- get link upstream Jitter
# SYNOPSIS
#   set delay [getLinkJitterUpstream $link_id]
# FUNCTION
#   Returns the list of upstream link jitter values expressed in microseconds.
# INPUTS
#   * link_id -- link id
# RESULT
#   * jitter -- the list of values for jitter in microseconds
#****
proc _getLinkJitterUpstream { link_cfg } {
    return [_cfgGet $link_cfg "jitter_upstream"]
}

#****f* linkcfg.tcl/setLinkJitterUpstream
# NAME
#   setLinkJitterUpstream -- set link upstream jitter
# SYNOPSIS
#   setLinkJitterUpstream $link_id $jitter_upstream
# FUNCTION
#   Sets the link upstream jitter in microseconds.
# INPUTS
#   * link_id -- link id
#   * jitter_upstream -- link upstream jitter values in microseconds.
#****
proc _setLinkJitterUpstream { link_cfg jitter_upstream } {
    if { $jitter_upstream == 0 } {
	set jitter_upstream ""
    }

    return [_cfgSet $link_cfg "jitter_upstream" $jitter_upstream]
}

#****f* linkcfg.tcl/getLinkJitterModeUpstream
# NAME
#   getLinkJitterModeUpstream -- get link upstream jitter mode
# SYNOPSIS
#   set delay [getLinkJitterModeUpstream $link_id]
# FUNCTION
#   Returns the upstream link jitter mode.
# INPUTS
#   * link_id -- link id
# RESULT
#   * jitter_mode -- The jitter mode for upstream direction.
#****
proc _getLinkJitterModeUpstream { link_cfg } {
    return [_cfgGet $link_cfg "jitter_upstream_mode"]
}

#****f* linkcfg.tcl/setLinkJitterModeUpstream
# NAME
#   setLinkJitterModeUpstream -- set link upstream jitter mode
# SYNOPSIS
#   setLinkJitterModeUpstream $link_id $jitter_upstream_mode
# FUNCTION
#   Sets the link upstream jitter mode.
# INPUTS
#   * link_id -- link id
#   * jitter_upstream_mode -- link upstream jitter mode.
#****
proc _setLinkJitterModeUpstream { link_cfg jitter_upstream_mode } {
    if { $jitter_upstream_mode == 0 } {
	set jitter_upstream_mode ""
    }

    return [_cfgSet $link_cfg "jitter_upstream_mode" $jitter_upstream_mode]
}

#****f* linkcfg.tcl/getLinkJitterHoldUpstream
# NAME
#   getLinkJitterHoldUpstream -- get link upstream jitter hold
# SYNOPSIS
#   set delay [getLinkJitterHoldUpstream $link_id]
# FUNCTION
#   Returns the upstream link jitter hold.
# INPUTS
#   * link_id -- link id
# RESULT
#   * jitter_hold -- The jitter hold for upstream direction.
#****
proc _getLinkJitterHoldUpstream { link_cfg } {
    return [_cfgGet $link_cfg "jitter_upstream_hold"]
}

#****f* linkcfg.tcl/setLinkJitterHoldUpstream
# NAME
#   setLinkJitterHoldUpstream -- set link upstream jitter hold
# SYNOPSIS
#   setLinkJitterHoldUpstream $link_id $jitter_upstream_hold
# FUNCTION
#   Sets the link upstream jitter hold.
# INPUTS
#   * link_id -- link id
#   * jitter_upstream_hold -- link upstream jitter hold.
#****
proc _setLinkJitterHoldUpstream { link_cfg jitter_upstream_hold } {
    if { $jitter_upstream_hold == 0 } {
	set jitter_upstream_hold ""
    }

    return [_cfgSet $link_cfg "jitter_upstream_hold" $jitter_upstream_hold]
}

#****f* linkcfg.tcl/getLinkJitterDownstream
# NAME
#   getLinkJitterDownstream -- get link downstream Jitter
# SYNOPSIS
#   set delay [getLinkJitterDownstream $link_id]
# FUNCTION
#   Returns the downstream link jitter values expressed in microseconds in a
#   list.
# INPUTS
#   * link_id -- link id
# RESULT
#   * jitter -- The list of values for jitter in microseconds.
#****
proc _getLinkJitterDownstream { link_cfg } {
    return [_cfgGet $link_cfg "jitter_downstream"]
}

#****f* linkcfg.tcl/setLinkJitterDownstream
# NAME
#   setLinkJitterDownstream -- set link downstream jitter
# SYNOPSIS
#   setLinkJitterDownstream $link_id $jitter_downstream
# FUNCTION
#   Sets the link downstream jitter in microseconds.
# INPUTS
#   * link_id -- link id
#   * jitter_downstream -- link downstream jitter values in microseconds.
#****
proc _setLinkJitterDownstream { link_cfg jitter_downstream } {
    if { $jitter_downstream == 0 } {
	set jitter_downstream ""
    }

    return [_cfgSet $link_cfg "jitter_downstream" $jitter_downstream]
}

#****f* linkcfg.tcl/getLinkJitterModeDownstream
# NAME
#   getLinkJitterModeDownstream -- get link downstream jitter mode
# SYNOPSIS
#   set delay [getLinkJitterModeDownstream $link_id]
# FUNCTION
#   Returns the downstream link jitter mode.
# INPUTS
#   * link_id -- link id
# RESULT
#   * jitter_mode -- The jitter mode for downstream direction.
#****
proc _getLinkJitterModeDownstream { link_cfg } {
    return [_cfgGet $link_cfg "jitter_downstream_mode"]
}

#****f* linkcfg.tcl/setLinkJitterModeDownstream
# NAME
#   setLinkJitterModeDownstream -- set link downstream jitter mode
# SYNOPSIS
#   setLinkJitterModeDownstream $link_id $jitter_downstream_mode
# FUNCTION
#   Sets the link downstream jitter mode.
# INPUTS
#   * link_id -- link id
#   * jitter_downstream_mode -- link downstream jitter mode.
#****
proc _setLinkJitterModeDownstream { link_cfg jitter_downstream_mode } {
    if { $jitter_downstream_mode == 0 } {
	set jitter_downstream_mode ""
    }

    return [_cfgSet $link_cfg "jitter_downstream_mode" $jitter_downstream_mode]
}

#****f* linkcfg.tcl/getLinkJitterHoldDownstream
# NAME
#   getLinkJitterHoldDownstream -- get link downstream jitter hold
# SYNOPSIS
#   set delay [getLinkJitterHoldDownstream $link_id]
# FUNCTION
#   Returns the downstream link jitter hold.
# INPUTS
#   * link_id -- link id
# RESULT
#   * jitter_hold -- The jitter hold for downstream direction.
#****
proc _getLinkJitterHoldDownstream { link_cfg } {
    return [_cfgGet $link_cfg "jitter_downstream_hold"]
}

#****f* linkcfg.tcl/setLinkJitterHoldDownstream
# NAME
#   setLinkJitterHoldDownstream -- set link downstream jitter hold
# SYNOPSIS
#   setLinkJitterHoldDownstream $link_id $jitter_downstream_hold
# FUNCTION
#   Sets the link downstream jitter hold.
# INPUTS
#   * link_id -- link id
#   * jitter_downstream_hold -- link downstream jitter hold.
#****
proc _setLinkJitterHoldDownstream { link_cfg jitter_downstream_hold } {
    if { $jitter_downstream_hold == 0 } {
	set jitter_downstream_hold ""
    }

    return [_cfgSet $link_cfg "jitter_downstream_hold" $jitter_downstream_hold]
}

#****f* linkcfg.tcl/getLinkBER
# NAME
#   getLinkBER -- get link BER
# SYNOPSIS
#   set BER [getLinkBER $link_id]
# FUNCTION
#   Returns 1/BER value of the link.
# INPUTS
#   * link_id -- link id
# RESULT
#   * BER -- The value of 1/BER of the link.
#****
proc _getLinkBER { link_cfg } {
    return [_cfgGet $link_cfg "ber"]
}

#****f* linkcfg.tcl/setLinkBER
# NAME
#   setLinkBER -- set link BER
# SYNOPSIS
#   setLinkBER $link_id ber
# FUNCTION
#   Sets the BER value of the link.
# INPUTS
#   * link_id -- link id
#   * ber -- The value of 1/BER of the link.
#****
proc _setLinkBER { link_cfg ber } {
    if { $ber == 0 } {
	set ber ""
    }

    return [_cfgSet $link_cfg "ber" $ber]
}

#****f* linkcfg.tcl/getLinkLoss
# NAME
#   getLinkLoss -- get link loss
# SYNOPSIS
#   set loss [getLinkLoss $link_id]
# FUNCTION
#   Returns loss percentage of the link.
# INPUTS
#   * link_id -- link id
# RESULT
#   * loss -- The loss percentage of the link.
#****
proc _getLinkLoss { link_cfg } {
    return [_cfgGet $link_cfg "loss"]
}

#****f* linkcfg.tcl/setLinkLoss
# NAME
#   setLinkLoss -- set link loss
# SYNOPSIS
#   setLinkLoss $link_id loss
# FUNCTION
#   Sets the loss percentage of the link.
# INPUTS
#   * link_id -- link id
#   * loss -- The loss percentage of the link.
#****
proc _setLinkLoss { link_cfg loss } {
    if { $loss == 0 } {
	set loss ""
    }

    return [_cfgSet $link_cfg "loss" $loss]
}

#****f* linkcfg.tcl/getLinkDup
# NAME
#   getLinkDup -- get link packet duplicate value
# SYNOPSIS
#   set duplicate [getLinkDup $link_id]
# FUNCTION
#   Returns the value of the link duplicate percentage.
# INPUTS
#   * link_id -- link id
# RESULT
#   * duplicate -- The percentage of the link packet duplicate value.
#****
proc _getLinkDup { link_cfg } {
    return [_cfgGet $link_cfg "duplicate"]
}

#****f* linkcfg.tcl/setLinkDup
# NAME
#   setLinkDup -- set link packet duplicate value
# SYNOPSIS
#   setLinkDup $link_id $duplicate
# FUNCTION
#   Set link packet duplicate percentage.
# INPUTS
#   * link_id -- link id
#   * duplicate -- The percentage of the link packet duplicate value.
#****
proc _setLinkDup { link_cfg duplicate } {
    if { $duplicate == 0 } {
	set duplicate ""
    }

    return [_cfgSet $link_cfg "duplicate" $duplicate]
}

#****f* linkcfg.tcl/getLinkMirror
# NAME
#   getLinkMirror -- get link's mirror link
# SYNOPSIS
#   set mirror_link_id [getLinkMirror $link_id]
# FUNCTION
#   Returns the value of the link's mirror link. Mirror link is the other part
#   of the link connecting node to a pseudo node. Two mirror links present
#   only one physical link.
# INPUTS
#   * link_id -- link id
# RESULT
#   * mirror_link_id -- mirror link id
#****
proc _getLinkMirror { link_cfg } {
    return [_cfgGet $link_cfg "mirror"]
}

#****f* linkcfg.tcl/setLinkMirror
# NAME
#   setLinkMirror -- set link's mirror link
# SYNOPSIS
#   setLinkMirror $link_id $mirror
# FUNCTION
#   Sets the value of the link's mirror link. Mirror link is the other part of
#   the link connecting node to a pseudo node. Two mirror links present only
#   one physical link.
# INPUTS
#   * link_id -- link id
#   * mirror -- mirror link's id
#****
proc _setLinkMirror { link_cfg mirror } {
    return [_cfgSet $link_cfg "mirror" $mirror]
}

proc _getLinkPeers { link_cfg } {
    return [_cfgGet $link_cfg "peers"]
}

proc _setLinkPeers { link_cfg peers } {
    return [_cfgSet $link_cfg "peers" $peers]
}

proc _getLinkPeersIfaces { link_cfg } {
    return [_cfgGet $link_cfg "peers_ifaces"]
}

proc _setLinkPeersIfaces { link_cfg peers_ifaces } {
    return [_cfgSet $link_cfg "peers_ifaces" $peers_ifaces]
}
