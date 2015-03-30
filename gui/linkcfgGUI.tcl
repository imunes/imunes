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
#   linkConfigGUI $c $link
# FUNCTION
#   Calls procedure link.configGUI. 
# INPUTS
#   * c - tk canvas
#   * link - link id
#****
proc linkConfigGUI { c link } {
    if {$link == ""} {
	set link [lindex [$c gettags current] 1]
    }
    link.configGUI $c $link
}

#****f* linkcfgGUI.tcl/link.configGUI
# NAME
#   link.configGUI -- configuration GUI
# SYNOPSIS
#   link.configGUI $c $link
# FUNCTION
#   Defines the structure of the link configuration window by calling
#   procedures for creating and organising the window, as well as
#   procedures for adding certain modules to that window.
# INPUTS
#   * c - tk canvas
#   * link - link id
#****
proc link.configGUI { c link } {
    global wi
    #
    #guielements - the list of link configuration parameters (except Color parameter)
    #              (this list is used when calling configGUI_linkConfigApply procedure)
    #
    global configelements
    set configelements {}

    set n0 [lindex [linkPeers $link] 0]
    set n1 [lindex [linkPeers $link] 1]
    set name0 [getNodeName $n0]
    set name1 [getNodeName $n1]

    configGUI_createConfigPopupWin $c
    wm title $wi "link configuration"

    configGUI_linkFromTo $wi $link
    configGUI_linkConfig $wi $link "Bandwidth" "Bandwidth (bps):"
    configGUI_linkConfig $wi $link "Delay" "Delay (us):"
    configGUI_linkConfig $wi $link "BER" "BER (1/N):"
    configGUI_linkConfig $wi $link "Dup" "Duplicate (%):"
    configGUI_linkConfig $wi $link "Width" "Width:"
    configGUI_linkColor $wi $link

    configGUI_buttonsACLink $wi $link
}

#****f* linkcfgGUI.tcl/configGUI_buttonsACLink
# NAME
#   configGUI_buttonsACLink -- configuration GUI - buttons apply/close link
# SYNOPSIS
#  configGUI_buttonsACLink $wi $link
# FUNCTION
#   Creates module with options for saving/discarding changes (Apply, Cancel).
# INPUTS
#   * wi - widget
#   * link - link id
#****
proc configGUI_buttonsACLink { wi link } {
    global badentry configelements
    ttk::frame $wi.buttons -borderwidth 6
    ttk::button $wi.buttons.apply -text "Apply" -command \
        "configGUI_applyButtonLink $wi $link 0"
    focus $wi.buttons.apply
    ttk::button $wi.buttons.cancel -text "Cancel" -command \
        "set badentry -1; destroy $wi"
    pack $wi.buttons.apply -side left -anchor e -expand 1 -pady 2
    pack $wi.buttons.cancel -side right -anchor w -expand 1 -pady 2
    pack $wi.buttons -fill both -expand 1 -side bottom
    
    bind $wi <Key-Return> \
        "configGUI_applyButtonLink $wi $link 0"
    bind $wi <Key-Escape> "set badentry -1; destroy $wi"
}

#****f* linkcfgGUI.tcl/configGUI_applyButtonLink
# NAME
#   configGUI_applyButtonLink -- configuration GUI - apply button link
# SYNOPSIS
#   configGUI_applyButtonLink $wi $link $phase
# FUNCTION
#   Calles procedures for saving changes to the link.
# INPUTS
#   * wi -- widget
#   * link -- link id
#   * phase -- 
#****
proc configGUI_applyButtonLink { wi link phase } {
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global changed badentry

    $wi config -cursor watch
    update
    if { $phase == 0 } {
	set badentry 0
	focus .
	after 100 "configGUI_applyButtonLink $wi $link 1"
	return
    } elseif { $badentry } {
	$wi config -cursor left_ptr
	return
    }

    configGUI_linkConfigApply $wi $link
    configGUI_linkColorApply $wi $link

    if { $changed == 1 && $oper_mode == "exec" } {
	saveRunningConfigurationInteractive $eid
	execSetLinkParams $eid $link
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
#  configGUI_linkFromTo $wi $link
# FUNCTION
#   Creates module with information about link endpoints.
# INPUTS
#   * wi - widget
#   * link - link id
#****
proc configGUI_linkFromTo { wi link } {
    set n0 [lindex [linkPeers $link] 0]
    set n1 [lindex [linkPeers $link] 1]
    set name0 [getNodeName $n0]
    set name1 [getNodeName $n1]

    ttk::frame $wi.name -borderwidth 6
    ttk::label $wi.name.txt -text "Link from $name0 to $name1"
    pack $wi.name.txt
    pack $wi.name -fill both -expand 1
}

#****f* linkcfgGUI.tcl/configGUI_linkConfig
# NAME
#   configGUI_linkConfig -- configuration GUI - link configuration
# SYNOPSIS
#  configGUI_linkConfig $wi $link $param $label
# FUNCTION
#   Creates module for changing specific parameter.
# INPUTS
#   * wi - widget
#   * link - link id
#   * param - link parameter
#   * label - link parameter label
#****
proc configGUI_linkConfig { wi link param label } {
    global configelements
    lappend configelements $param
    if { $param == "Bandwidth" } {
        set from 0; set to 1000000000; set inc 1000
    } elseif { $param == "Delay" } {
        set from 0; set to 10000000; set inc 5
    } elseif { $param == "BER" } {
        set from 0; set to 10000000000000; set inc 1000
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
    set value [getLink$param $link]
    if {$value == ""} {
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
#  configGUI_linkColor $wi $link
# FUNCTION
#   Creates module for changing link color.
# INPUTS
#   * wi - widget
#   * link - link id
#****
proc configGUI_linkColor { wi link } {
    global link_color 
    ttk::frame $wi.color -borderwidth 4
    ttk::label $wi.color.txt -text "Color:"
    set link_color [getLinkColor $link]
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
#   linkJitterConfigGUI $c $link
# FUNCTION XXX
#   Defines the structure of the link configuration window by calling
#   procedures for creating and organising the window, as well as
#   procedures for adding certain modules to that window.
# INPUTS
#   * c - tk canvas
#   * link - link id
#****
proc linkJitterConfigGUI { c link } {
    global wi badentry up_jitmode down_jitmode

    set n0 [lindex [linkPeers $link] 0]
    set n1 [lindex [linkPeers $link] 1]
    set name0 [getNodeName $n0]
    set name1 [getNodeName $n1]

    configGUI_createConfigPopupWin $c
    wm title $wi "link $name0-$name1 jitter configuration"

    ttk::frame $wi.up
    ttk::frame $wi.down
    ttk::separator $wi.s -orient vertical

    ttk::label $wi.up.label -text "Upstream ($name1->$name0):"
    ttk::label $wi.down.label -text "Downstream ($name0->$name1):"

    ttk::label $wi.up.modelab -text "Jitter mode:"
    ttk::label $wi.down.modelab -text "Jitter mode:"
    ttk::combobox $wi.up.jitmode -justify right -width 10 \
	-textvariable up_jitmode -state readonly
    $wi.up.jitmode configure -values {sequential random}
    ttk::combobox $wi.down.jitmode -justify right -width 10 \
	-textvariable down_jitmode -state readonly
    $wi.down.jitmode configure -values {sequential random}

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
        "applyJitterLink $wi $link"
    ttk::button $wi.buttons.applyclose -text "Apply & Close" -command \
        "applyJitterLink $wi $link; destroy $wi"
    ttk::button $wi.buttons.cancel -text "Cancel" -command \
        "destroy $wi"
    bind $wi <Key-Escape> "destroy $wi"

    set up_jitmode [getLinkJitterModeUpstream $link]
    if { $up_jitmode == "" } { set up_jitmode sequential}
    set down_jitmode [getLinkJitterModeDownstream $link]
    if { $down_jitmode == "" } { set down_jitmode sequential}

    $wi.up.editor insert end [join [getLinkJitterUpstream $link] "\n"]
    $wi.down.editor insert end [join [getLinkJitterDownstream $link] "\n"]

    set val [getLinkJitterHoldUpstream $link]
    if {$val == ""} { set val 0 }
    $wi.up.holdval insert 0 $val
    set val [getLinkJitterHoldDownstream $link]
    if {$val == ""} { set val 0 }
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
#   applyJitterLink $wi $link
# FUNCTION
#   Applies jitter upstream and downstream to the specified link.
# INPUTS
#   * wi -- widget
#   * link -- link id
#****
proc applyJitterLink { wi link } {
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global up_jitmode down_jitmode

    setLinkJitterModeUpstream $link $up_jitmode
    setLinkJitterModeDownstream $link $down_jitmode

    setLinkJitterHoldUpstream $link [$wi.up.holdval get]
    setLinkJitterHoldDownstream $link [$wi.down.holdval get]

    set jitt_up [$wi.up.editor get 1.0 {end -1c}]
    set jitt_down [$wi.down.editor get 1.0 {end -1c}]

    set jup ""
    set jdown ""

    foreach line $jitt_up {
	if {[string is double $line] && $line != "" && $line < 10000} {
	    lappend jup [expr round($line*1000)/1000.0]
	}
    }

    foreach line $jitt_down {
	if {[string is double $line] && $line != "" && $line < 10000} {
	    lappend jdown [expr round($line*1000)/1000.0]
	}
    }

    if {$jup != ""} {
	setLinkJitterUpstream $link $jup
    }
    if {$jdown != ""} {
	setLinkJitterDownstream $link $jdown
    }

    $wi.up.editor delete 1.0 end
    $wi.up.editor insert end [join $jup "\n"]
    $wi.down.editor delete 1.0 end
    $wi.down.editor insert end [join $jdown "\n"]

    if { $oper_mode == "exec" } {
	saveRunningConfigurationInteractive $eid
	execSetLinkJitter $eid $link
    }

    updateUndoLog
    redrawAll
}

#****f* linkcfgGUI.tcl/linkJitterReset
# NAME
#   linkJitterReset -- reset jitter link
# SYNOPSIS
#   linkJitterReset $link
# FUNCTION
#   Resets upstream and downstream inputs for a specified link.
# INPUTS
#   * link -- link id
#****
proc linkJitterReset { link } {
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    upvar 0 ::cf::[set ::curcfg]::eid eid

    setLinkJitterModeUpstream $link "" 
    setLinkJitterModeDownstream $link "" 

    setLinkJitterHoldUpstream $link ""
    setLinkJitterHoldDownstream $link ""

    setLinkJitterUpstream $link ""
    setLinkJitterDownstream $link ""

    if { $oper_mode == "exec" } {
	saveRunningConfigurationInteractive $eid
	execResetLinkJitter $eid $link
    }

    updateUndoLog
}

###############"Apply" procedures################

#****f* linkcfgGUI.tcl/configGUI_linkConfigApply
# NAME
#   configGUI_linkConfigApply -- configuration GUI - link configuration apply
# SYNOPSIS
#  configGUI_linkConfigApply $wi $link
# FUNCTION
#   Saves changes in the module with specific parameter
#   (except Color parameter).
# INPUTS
#   * wi - widget
#   * link - link id
#****
proc configGUI_linkConfigApply { wi link } {
    global changed configelements
    foreach element $configelements {
	set mirror [getLinkMirror $link]
	set fr [string tolower $element ]
	set value [$wi.$fr.value get]
	if { $value != [getLink$element $link] } {
	    setLink$element $link $value
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
#  configGUI_linkColorApply $wi $link
# FUNCTION
#   Saves changes in the module with link color.
# INPUTS
#   * wi - widget
#   * link - link id
#****
proc configGUI_linkColorApply { wi link } {
    global changed link_color
    set mirror [getLinkMirror $link]
    if { $link_color != [getLinkColor $link] } {
        setLinkColor $link $link_color
	if { $mirror != "" } {
	    setLinkColor $mirror $link_color
	}
    set changed 1
    }
}
