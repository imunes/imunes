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

# $Id: nodecfgGUI.tcl 149 2015-03-27 15:50:14Z valter $


#****f* nodecfgGUI.tcl/nodeConfigGUI
# NAME
#   nodeConfigGUI -- node configure GUI
# SYNOPSIS
#   nodeConfigGUI $c $node
# FUNCTION
#   Depending on the type of node calls the corresponding procedure
#   $type.configGUI or, in the case of pseudo node, calls the procedure for
#   switching canvas.  
# INPUTS
#   * c -- tk canvas
#   * node -- node id
#****
proc nodeConfigGUI { c node } {
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    global badentry
    
    if {$node == ""} {
        set node [lindex [$c gettags current] 1]
    }
    set type [nodeType $node]
    if { $type == "pseudo" } {
        #
	# Hyperlink to another canvas
        #
	set curcanvas [getNodeCanvas [getNodeMirror $node]]
	switchCanvas none
	return
    } else {
        set badentry 0
        $type.configGUI $c $node
    }
}

#****f* nodecfgGUI.tcl/configGUI_createConfigPopupWin
# NAME
#   configGUI_createConfigPopupWin -- configure GUI - create configuration
#      popup window
# SYNOPSIS
#   configGUI_createConfigPopupWin $c
# FUNCTION
#   Creates toplevel tk widget.
# INPUTS
#   * c -- tk canvas
#****
proc configGUI_createConfigPopupWin { c } {
    global wi
    set wi .popup
    catch {destroy $wi}
    toplevel $wi

    wm transient $wi .

    $c dtag node selected
    $c delete -withtags selectmark

    #buduci da se naredbom grab dogadjaji s tipkovnice i misa ogranicavaju na ovaj prozor,
    #u slucaju greske nece se moci vidjeti detalji niti zatvoriti prozor upozorenjem na gresku
    #u tom je slucaju potrebno zakomentirati naredbu grab
    after 100 {
	grab $wi
    }
}

#****f* nodecfgGUI.tcl/configGUI_addNotebook
# NAME
#   configGUI_addNotebook -- configure GUI - add notebook
# SYNOPSIS
#   configGUI_addNotebook $c $node $labels
# FUNCTION
#   Creates and manipulates ttk::notebook widget.
# INPUTS
#   * wi - widget
#   * node - node id
#   * labels - list of tab names
# RESULT
#   * tabs - the list containing tab identifiers.
#****
proc configGUI_addNotebook { wi node labels } {
    ttk::notebook $wi.nbook -height 200
    pack $wi.nbook -fill both -expand 1
    pack propagate $wi.nbook 0
    foreach label $labels {
        ttk::frame $wi.nbook.nf$label
        $wi.nbook add $wi.nbook.nf$label -text $label
    }

    configGUI_addPanedWin [lindex [$wi.nbook tabs] 1]

    if { "Bridge" in $labels } {
	configGUI_addPanedWin [lindex [$wi.nbook tabs] 2]
    }

    global selectedIfc
    if { $selectedIfc != "" } {
        $wi.nbook select [lindex [$wi.nbook tabs] 1]
    }
    bind $wi.nbook <<NotebookTabChanged>> \
 	"notebookSize $wi $node"
    #vraca popis tabova
    set tabs [$wi.nbook tabs]
    return $tabs
}

#****f* nodecfgGUI.tcl/notebookSize
# NAME
#   notebookSize -- notebook size
# SYNOPSIS
#   notebookSize $wi $node
# FUNCTION
#   Manipulates with the height and width of ttk::notebook pane area.
# INPUTS
#   * wi - widget
#   * node - node id
#****
proc notebookSize { wi node } {
    set type [nodeType $node]

    set dim [$type.notebookDimensions $wi]
    set configh [lindex $dim 0]
    set configw [lindex $dim 1]
        
    $wi.nbook configure -height $configh -width $configw
}

#****f* nodecfgGUI.tcl/configGUI_addPanedWin
# NAME
#   configGUI_addPanedWin -- configure GUI - add paned window
# SYNOPSIS
#   configGUI_addPanedWin $wi
# FUNCTION
#   Creates vertical ttk::panedwindow widget with two panes.
# INPUTS
#   * wi - widget
#****
proc configGUI_addPanedWin { wi } {
    ttk::panedwindow $wi.panwin -orient vertical
    ttk::frame $wi.panwin.f1
    ttk::frame $wi.panwin.f2
    $wi.panwin add $wi.panwin.f1 -weight 5
    $wi.panwin add $wi.panwin.f2 -weight 0
    pack $wi.panwin -fill both -expand 1
}

#****f* nodecfgGUI.tcl/configGUI_addTree
# NAME
#   configGUI_addTree -- configure GUI - add tree
# SYNOPSIS
#   configGUI_addTree $wi $node
# FUNCTION
#   Creates ttk::treeview widget with interface names and their other
#   parameters.
# INPUTS
#   * wi - widget
#   * node - node id
#****
proc configGUI_addTree { wi node } {
    global treecolumns cancel curnode
    set curnode $node
    #
    #cancel - indicates if the user has clicked on Cancel in the popup window about
    #         saving changes on the previously selected interface in the list of interfaces,
    #         1 for yes, 0 otherwise
    #
    set cancel 0

    ttk::frame $wi.panwin.f1.grid
    ttk::treeview $wi.panwin.f1.tree -height 5 -selectmode browse \
	-xscrollcommand "$wi.panwin.f1.hscroll set"\
	-yscrollcommand "$wi.panwin.f1.vscroll set"
    ttk::scrollbar $wi.panwin.f1.hscroll -orient horizontal -command "$wi.panwin.f1.tree xview"
    ttk::scrollbar $wi.panwin.f1.vscroll -orient vertical -command "$wi.panwin.f1.tree yview"
    focus $wi.panwin.f1.tree

    set column_ids ""
    foreach column $treecolumns {
	lappend columns_ids [lindex $column 0]
    }
    
    #Creating columns    
    $wi.panwin.f1.tree configure -columns $columns_ids

    $wi.panwin.f1.tree column #0 -width 130 -minwidth 70 -stretch 0
    foreach column $treecolumns {
	if { [lindex $column 0] == "OperState" || [lindex $column 0] == "MTU" } {
	    $wi.panwin.f1.tree column [lindex $column 0] -width 45 \
		-minwidth 2 -anchor center -stretch 0
	} elseif { [lindex $column 0] == "MACaddr" } {
            $wi.panwin.f1.tree column [lindex $column 0] -width 120 \
		-minwidth 2 -anchor center -stretch 0
        } else {
	    $wi.panwin.f1.tree column [lindex $column 0] -width 100 \
		-minwidth 2 -anchor center -stretch 0
	}
	$wi.panwin.f1.tree heading [lindex $column 0] \
	    -text [join [lrange $column 1 end]]
    }

    $wi.panwin.f1.tree heading #0 \
	-command "if { [lsearch [pack slaves .popup] .popup.nbook] != -1 } {
		      .popup.nbook configure -width 808
		  }"
    $wi.panwin.f1.tree heading #0 -text "(Expand)"

    #Creating new items
    $wi.panwin.f1.tree insert {} end -id interfaces -text \
	"Physical Interfaces" -open true -tags interfaces
    $wi.panwin.f1.tree focus interfaces
    $wi.panwin.f1.tree selection set interfaces

    foreach ifc [lsort -dictionary [ifcList $node]] {
	$wi.panwin.f1.tree insert interfaces end -id $ifc \
	    -text "$ifc" -tags $ifc
	foreach column $treecolumns {
	    $wi.panwin.f1.tree set $ifc [lindex $column 0] \
		[getIfc[lindex $column 0] $node $ifc]
	}
    }
    
    if {[[typemodel $node].virtlayer] == "VIMAGE" && [nodeType $node] != "click_l2"} {
	$wi.panwin.f1.tree insert {} end -id logIfcFrame -text \
	    "Logical Interfaces" -open true -tags logIfcFrame

	foreach ifc [lsort -dictionary [logIfcList $node]] {
	    $wi.panwin.f1.tree insert logIfcFrame end -id $ifc \
		-text "$ifc" -tags $ifc
	    foreach column { "OperState" "MTU" "IPv4addr" "IPv6addr"} {
		$wi.panwin.f1.tree set $ifc [lindex $column 0] \
		    [getIfc[lindex $column 0] $node $ifc]
	    }
	}
    }

    
    #Setting focus and selection on the first interface in the list or on the interface
    #selected in the topology tree and calling procedure configGUI_showIfcInfo with that 
    #interfaces as the second argument
    global selectedIfc
    if {[ifcList $node] != "" && $selectedIfc == ""} {
	$wi.panwin.f1.tree focus [lindex [lsort -ascii [ifcList $node]] 0]
	$wi.panwin.f1.tree selection set [lindex [lsort -ascii [ifcList $node]] 0]
	set cancel 0
	configGUI_showIfcInfo $wi.panwin.f2 0 $node [lindex [lsort -ascii [ifcList $node]] 0]
    } elseif {[allIfcList $node] != "" && $selectedIfc == ""} {
	$wi.panwin.f1.tree focus [lindex [lsort -ascii [allIfcList $node]] 0]
	$wi.panwin.f1.tree selection set [lindex [lsort -ascii [allIfcList $node]] 0]
	set cancel 0
	configGUI_showIfcInfo $wi.panwin.f2 0 $node [lindex [lsort -ascii [allIfcList $node]] 0]
    }
    if {[ifcList $node] != "" && $selectedIfc != ""} {
	$wi.panwin.f1.tree focus $selectedIfc
	$wi.panwin.f1.tree selection set $selectedIfc
	set cancel 0
	configGUI_showIfcInfo $wi.panwin.f2 0 $node $selectedIfc
    }    
    
    #binding for tag interfaces
    $wi.panwin.f1.tree tag bind interfaces <1> \
	    "configGUI_showIfcInfo $wi.panwin.f2 0 $node \"\""
    $wi.panwin.f1.tree tag bind interfaces <Key-Down> \
	    "if {[llength [ifcList $node]] != 0} {
		configGUI_showIfcInfo $wi.panwin.f2 0 $node [lindex [lsort -ascii [ifcList $node]] 0]
	    }"
	    
    #binding for tags $ifc
    foreach ifc [lsort -dictionary [ifcList $node]] {
	$wi.panwin.f1.tree tag bind $ifc <1> \
	  "$wi.panwin.f1.tree focus $ifc
	   $wi.panwin.f1.tree selection set $ifc
           configGUI_showIfcInfo $wi.panwin.f2 0 $node $ifc"
	#pathname prev item:
	#Returns the identifier of item's previous sibling, or {} if item is the first child of its parent.
	#Ako sucelje $ifc nije prvo dijete svog roditelja onda je zadnji argument procedure
	#configGUI_showIfcInfo jednak prethodnom djetetu (prethodno sucelje)
	#Inace se radi o itemu Interfaces pa je zadnji argument procedure configGUI_showIfcInfo jednak "" i
	#u tom slucaju se iz donjeg panea brise frame s informacijama o prethodnom sucelju
	$wi.panwin.f1.tree tag bind $ifc <Key-Up> \
	    "if {![string equal {} [$wi.panwin.f1.tree prev $ifc]]} {
		configGUI_showIfcInfo $wi.panwin.f2 0 $node [$wi.panwin.f1.tree prev $ifc]
	    } else {
		configGUI_showIfcInfo $wi.panwin.f2 0 $node \"\" 
	    }"
	#pathname next item:
	#Returns the identifier of item's next sibling, or {} if item is the last child of its parent.
	#Ako sucelje $ifc nije zadnje dijete svog roditelja onda je zadnji argument procedure
	#configGUI_showIfcInfo jednak iducem djetetu (iduce sucelje)
	#Inace se ne poziva procedura configGUI_showIfcInfo
	$wi.panwin.f1.tree tag bind $ifc <Key-Down> \
	    "if {![string equal {} [$wi.panwin.f1.tree next $ifc]]} {
		configGUI_showIfcInfo $wi.panwin.f2 0 $node [$wi.panwin.f1.tree next $ifc]
	    }"
    }
    if {[[typemodel $node].virtlayer] == "VIMAGE"} {
	$wi.panwin.f1.tree tag bind [lindex [lsort -ascii [ifcList $node]] end] <Key-Down> \
		"configGUI_showIfcInfo $wi.panwin.f2 0 $node logIfcFrame"

	$wi.panwin.f1.tree tag bind logIfcFrame <1> \
		"configGUI_showIfcInfo $wi.panwin.f2 0 $node logIfcFrame"
	$wi.panwin.f1.tree tag bind logIfcFrame <Key-Up> \
		"configGUI_showIfcInfo $wi.panwin.f2 0 $node [lindex [lsort -ascii [ifcList $node]] end]"
	$wi.panwin.f1.tree tag bind logIfcFrame <Key-Down> \
		"configGUI_showIfcInfo $wi.panwin.f2 0 $node [lindex [lsort -ascii [logIfcList $node]] 0]"

	foreach ifc [lsort -ascii [logIfcList $node]] {
	    $wi.panwin.f1.tree tag bind $ifc <1> \
	      "$wi.panwin.f1.tree focus $ifc
	       $wi.panwin.f1.tree selection set $ifc
	       configGUI_showIfcInfo $wi.panwin.f2 0 $node $ifc"

	    $wi.panwin.f1.tree tag bind $ifc <3> \
		"showLogIfcMenu $ifc"
	    
	    $wi.panwin.f1.tree tag bind $ifc <Key-Up> \
		"if {![string equal {} [$wi.panwin.f1.tree prev $ifc]]} {
		    configGUI_showIfcInfo $wi.panwin.f2 0 $node [$wi.panwin.f1.tree prev $ifc]
		} else {
		    configGUI_showIfcInfo $wi.panwin.f2 0 $node logIfcFrame 
		}"
	    $wi.panwin.f1.tree tag bind $ifc <Key-Down> \
		"if {![string equal {} [$wi.panwin.f1.tree next $ifc]]} {
		    configGUI_showIfcInfo $wi.panwin.f2 0 $node [$wi.panwin.f1.tree next $ifc]
		}"
	}
    }
    
    pack $wi.panwin.f1.grid -fill both -expand 1
    grid $wi.panwin.f1.tree $wi.panwin.f1.vscroll -in $wi.panwin.f1.grid -sticky nsew
    grid  $wi.panwin.f1.hscroll -in $wi.panwin.f1.grid -sticky nsew
    grid columnconfig $wi.panwin.f1.grid 0 -weight 1
    grid rowconfigure $wi.panwin.f1.grid 0 -weight 1
}

#****f* nodecfgGUI.tcl/showLogIfcMenu
# NAME
#   showLogIfcMenu -- show logical interface menu
# SYNOPSIS
#   showLogIfcMenu $ifc
# FUNCTION
#   Creates and shows a dialog for a logical interface.
# INPUTS
#   * ifc -- interface name
#****
proc showLogIfcMenu { ifc } {
    global button3logifc_ifc
    set button3logifc_ifc $ifc
    .button3logifc delete 0 end
    .button3logifc add command -label "Remove interface $ifc" \
	-command {
	    global curnode logIfcs button3logifc_ifc changed
	    set changed 0
	    set ifc $button3logifc_ifc
	    if { $ifc != "lo0" } {
		netconfClearSection $curnode "interface $ifc"

		set wi .popup.nbook.nfInterfaces.panwin
		set logIfcs [lsort [logIfcList $curnode]]
		configGUI_refreshIfcsTree $wi.f1.tree $curnode
		configGUI_showIfcInfo $wi.f2 0 $curnode logIfcFrame
		$wi.f1.tree selection set logIfcFrame
	    } else {
		tk_dialog .dialog1 "IMUNES warning" \
		    "The loopback interface lo0 cannot be deleted!" \
		info 0 Dismiss
	    }
	}

    set x [winfo pointerx .]
    set y [winfo pointery .]
    tk_popup .button3logifc $x $y
}

#****f* nodecfgGUI.tcl/configGUI_refreshIfcsTree
# NAME
#   configGUI_refreshIfcsTree -- configure GUI - refresh interfaces tree
# SYNOPSIS
#   configGUI_refreshIfcsTree $wi $node
# FUNCTION
#   Refreshes the tree with the list of interfaces.
# INPUTS
#   * wi - widget
#   * node - node id
#****
proc configGUI_refreshIfcsTree { wi node } {
    global treecolumns

    $wi delete [$wi children {}]
    #Creating new items
    $wi insert {} end -id interfaces -text \
	"Physical Interfaces" -open true -tags interfaces
    $wi focus interfaces
    $wi selection set interfaces

    foreach ifc [lsort -dictionary [ifcList $node]] {
	$wi insert interfaces end -id $ifc \
	    -text "$ifc" -tags $ifc
	foreach column $treecolumns {
	    $wi set $ifc [lindex $column 0] \
		[getIfc[lindex $column 0] $node $ifc]
	}
    }
    
    if {[[typemodel $node].virtlayer] == "VIMAGE"} {
	$wi insert {} end -id logIfcFrame -text \
	    "Logical Interfaces" -open true -tags logIfcFrame
	
	foreach ifc [lsort -dictionary [logIfcList $node]] {
	    $wi insert logIfcFrame end -id $ifc \
		-text "$ifc" -tags $ifc
	    foreach column { "OperState" "MTU" "IPv4addr" "IPv6addr"} {
		$wi set $ifc [lindex $column 0] \
		    [getIfc[lindex $column 0] $node $ifc]
	    }
	}
    }

    set wi_bind [string trimright $wi ".panwin.f1.tree"]

    $wi tag bind interfaces <1> \
	    "configGUI_showIfcInfo $wi_bind.panwin.f2 0 $node \"\""
    $wi tag bind interfaces <Key-Down> \
	    "if {[llength [ifcList $node]] != 0} {
		configGUI_showIfcInfo $wi_bind.panwin.f2 0 $node [lindex [lsort -ascii [ifcList $node]] 0]
	    }"
	    
    foreach ifc [lsort -dictionary [ifcList $node]] {
	$wi tag bind $ifc <1> \
	  "$wi focus $ifc
	   $wi selection set $ifc
           configGUI_showIfcInfo $wi_bind.panwin.f2 0 $node $ifc"
	$wi tag bind $ifc <Key-Up> \
	    "if {![string equal {} [$wi prev $ifc]]} {
		configGUI_showIfcInfo $wi_bind.panwin.f2 0 $node [$wi prev $ifc]
	    } else {
		configGUI_showIfcInfo $wi_bind.panwin.f2 0 $node \"\" 
	    }"
	$wi tag bind $ifc <Key-Down> \
	    "if {![string equal {} [$wi next $ifc]]} {
		configGUI_showIfcInfo $wi_bind.panwin.f2 0 $node [$wi next $ifc]
	    }"
    }
    if {[[typemodel $node].virtlayer] == "VIMAGE"} {
	$wi tag bind [lindex [lsort -ascii [ifcList $node]] end] <Key-Down> \
		"configGUI_showIfcInfo $wi_bind.panwin.f2 0 $node logIfcFrame"
	
	$wi tag bind logIfcFrame <1> \
		"configGUI_showIfcInfo $wi_bind.panwin.f2 0 $node logIfcFrame"
	$wi tag bind logIfcFrame <Key-Up> \
		"configGUI_showIfcInfo $wi_bind.panwin.f2 0 $node [lindex [lsort -ascii [ifcList $node]] end]"
	$wi tag bind logIfcFrame <Key-Down> \
		"configGUI_showIfcInfo $wi_bind.panwin.f2 0 $node [lindex [lsort -ascii [logIfcList $node]] 0]"
	
	foreach ifc [lsort -ascii [logIfcList $node]] {
	    $wi tag bind $ifc <1> \
	      "$wi focus $ifc
	       $wi selection set $ifc
	       configGUI_showIfcInfo $wi_bind.panwin.f2 0 $node $ifc"
	    
	    $wi tag bind $ifc <3> \
		"showLogIfcMenu $ifc"
	    
	    $wi tag bind $ifc <Key-Up> \
		"if {![string equal {} [$wi prev $ifc]]} {
		    configGUI_showIfcInfo $wi_bind.panwin.f2 0 $node [$wi prev $ifc]
		} else {
		    configGUI_showIfcInfo $wi_bind.panwin.f2 0 $node logIfcFrame 
		}"
	    $wi tag bind $ifc <Key-Down> \
		"if {![string equal {} [$wi next $ifc]]} {
		    configGUI_showIfcInfo $wi_bind.panwin.f2 0 $node [$wi next $ifc]
		}"
	}
    }
    
}

#****f* nodecfgGUI.tcl/configGUI_showIfcInfo
# NAME
#   configGUI_showIfcInfo -- configure GUI - show interfaces information
# SYNOPSIS
#   configGUI_showIfcInfo $wi $phase $node $ifc
# FUNCTION
#   Shows parameters of the interface selected in the list of interfaces.
#   Parameters are shown below that list.
# INPUTS
#   * wi - widget
#   * phase - This pocedure is invoked in two diffenet phases to enable
#     validation of the entry that was the last made. When calling this
#     function always use the phase parameter set to 0.
#   * node - node id
#   * ifc - interface id
#****
proc configGUI_showIfcInfo { wi phase node ifc } {
    global guielements 
    global changed apply cancel badentry

    #
    #shownifcframe - frame that is currently shown below the list o interfaces
    #
    set shownifcframe [pack slaves $wi]
    #
    #shownifc - interface whose parameters are shown in shownifcframe
    #
    set shownifc [string trim [lindex [split $shownifcframe .] end] if]
    
    #if there is already some frame shown below the list of interfaces and
    #parameters shown in that frame are not parameters of selected interface
    if {$shownifcframe != "" && $ifc != $shownifc } {	
        if { $phase == 0 } {
	    set badentry 0
	    if { $ifc != "" } {
		after 100 "configGUI_showIfcInfo $wi 1 $node $ifc"
	    } else {
		after 100 "configGUI_showIfcInfo $wi 1 $node \"\""
	    }
	    return
	} elseif { $badentry } {
	    [string trimright $wi .f2].f1.tree selection set $shownifc
	    [string trimright $wi .f2].f1.tree focus $shownifc
	    $wi config -cursor left_ptr
	    return
	}   

	foreach guielement $guielements {
            #calling "apply" procedures to check if some parameters of previously 
	    #selected interface have been changed
            if { [llength $guielement] == 2 } {
		global brguielements
		if {$guielement ni $brguielements} {
		    [lindex $guielement 0]\Apply $wi $node [lindex $guielement 1]
		}
	    }
	}    

	#creating popup window with warning about unsaved changes
	if { $changed == 1 && $apply == 0 } {
 	    configGUI_saveChangesPopup $wi $node $shownifc
	}
	
	#if user didn't select Cancel in the popup about saving changes on previously selected interface
	if { $cancel == 0 } {
	    foreach guielement $guielements {
		set ind [lsearch $guielements $guielement]
		#delete corresponding elements from thi list guielements
		if {[lsearch $guielement $shownifc] != -1} {
		    set guielements [lreplace $guielements $ind $ind]
		}
	    }
	    #delete frame that is already shown below the list of interfaces (shownifcframe)
	    destroy $shownifcframe
	
        #if user selected Cancel the in popup about saving changes on previously selected interface, 
	#set focus and selection on that interface whose parameters are already shown
	#below the list of interfaces
	} else {
	     [string trimright $wi .f2].f1.tree selection set $shownifc
	     [string trimright $wi .f2].f1.tree focus $shownifc
	}
    }
    
    #if user didn't select Cancel in the popup about saving changes on previously selected interface
    if { $cancel == 0 } {
	set type [nodeType $node]
        #creating new frame below the list of interfaces and adding modules with 
	#parameters of selected interface
	if {$ifc != "" && $ifc != $shownifc} {
	    if { [isIfcLogical $node $ifc] } {
		#logical interfaces
		configGUI_ifcMainFrame $wi $node $ifc
		logical.configInterfacesGUI $wi $node $ifc
		set wi1 [string trimright $wi ".f2"]
		set h [winfo height $wi1]
		set pos [expr $h-160]
		$wi1 sashpos 0 $pos 
	    } elseif { $ifc != "logIfcFrame" } {
		#physical interfaces
		configGUI_ifcMainFrame $wi $node $ifc
		$type.configInterfacesGUI $wi $node $ifc
		set wi1 [string trimright $wi ".f2"]
		set h [winfo height $wi1]
		set pos [expr $h-160]
		$wi1 sashpos 0 $pos 
	    } else {
		#manage logical interfaces
		configGUI_logicalInterfaces $wi $node $ifc
		set wi1 [string trimright $wi ".f2"]
		set h [winfo height $wi1]
		set pos [expr $h-100]
		$wi1 sashpos 0 $pos 
	    }
	}
    }
}

#****f* nodecfgGUI.tcl/logical.configInterfacesGUI
# NAME
#   logical.configInterfacesGUI -- configure logical interfaces GUI
# SYNOPSIS
#   logical.configInterfacesGUI $wi $node $ifc
# FUNCTION
#   Configures logical interface.
# INPUTS
#   * wi -- widget
#   * node -- node id
#   * ifc -- interface name
#****
proc logical.configInterfacesGUI { wi node ifc } {
    switch -exact [getLogIfcType $node $ifc] {
	lo {
	    configGUI_ifcEssentials $wi $node $ifc
	    configGUI_ifcIPv4Address $wi $node $ifc
	    configGUI_ifcIPv6Address $wi $node $ifc
	    #nothing for now
	}
	bridge {
	    configGUI_ifcEssentials $wi $node $ifc
	    
	}
	gif {
	    configGUI_ifcEssentials $wi $node $ifc
	    #tunnel iface - source
	    #tunnel destination
	}
	gre {
	    configGUI_ifcEssentials $wi $node $ifc
	}
	tap {
	    configGUI_ifcEssentials $wi $node $ifc
	}
	tun {
	    configGUI_ifcEssentials $wi $node $ifc
	}
	vlan {
	    configGUI_ifcEssentials $wi $node $ifc
	    configGUI_ifcVlanConfig $wi $node $ifc
	    configGUI_ifcIPv4Address $wi $node $ifc
	    configGUI_ifcIPv6Address $wi $node $ifc
	}
    }
}

#****f* nodecfgGUI.tcl/configGUI_logicalInterfaces
# NAME
#   configGUI_logicalInterfaces -- configure GUI - logical interfaces
# SYNOPSIS
#   configGUI_logicalInterfaces $wi $node $ifc
# FUNCTION
#   Creates menu for configuring logical interface.
# INPUTS
#   * wi -- widget
#   * node -- node id
#   * ifc -- interface name
#****
proc configGUI_logicalInterfaces { wi node ifc } {
    global logIfcs curnode
    set curnode $node
    ttk::frame $wi.if$ifc -relief groove -borderwidth 2 -padding 4
    ttk::label $wi.if$ifc.txt -text "Manage logical interfaces:"

    set logIfcs [lsort [logIfcList $node]]
    listbox $wi.if$ifc.list -height 7 -width 10 -listvariable logIfcs
    
    ttk::label $wi.if$ifc.addtxt -text "Add new interface:"
    #set types [list lo gif gre vlan bridge tun tap]
    set types [list lo vlan]
    ttk::combobox $wi.if$ifc.addbox -width 10 -values [lsort $types] \
	-state readonly
    $wi.if$ifc.addbox set [lindex [lsort $types] 0]
    ttk::button $wi.if$ifc.addbtn -text "Add" -command {
	global curnode logIfcs
	set wi .popup.nbook.nfInterfaces.panwin.f2.iflogIfcFrame
	set ifctype [$wi.addbox get]
	set newIfcName [newLogIfc $ifctype $curnode]
	setLogIfcType $curnode $newIfcName $ifctype 
	set logIfcs [lsort [logIfcList $curnode]]
	$wi.rmvbox configure -values $logIfcs 
	$wi.list configure -listvariable logIfcs
	configGUI_refreshIfcsTree .popup.nbook.nfInterfaces.panwin.f1.tree $curnode
	configGUI_showIfcInfo .popup.nbook.nfInterfaces.panwin.f2 0 $curnode $newIfcName 
	.popup.nbook.nfInterfaces.panwin.f1.tree selection set $newIfcName 
    }
    
    ttk::label $wi.if$ifc.rmvtxt -text "Remove interface:"
    ttk::combobox $wi.if$ifc.rmvbox -width 10 -values $logIfcs \
	-state readonly

    ttk::button $wi.if$ifc.rmvbtn -text "Remove" -command {
	global curnode logIfcs
	set wi .popup.nbook.nfInterfaces.panwin.f2.iflogIfcFrame
	set ifc [$wi.rmvbox get]
	if { $ifc == "" } {
	    return
	}
	if { $ifc == "lo0" } { 
	    tk_dialog .dialog1 "IMUNES warning" \
		"The loopback interface lo0 cannot be deleted!" \
	    info 0 Dismiss
	    return
	} 
	$wi.rmvbox set ""
	netconfClearSection $curnode "interface $ifc"
	set logIfcs [lsort [logIfcList $curnode]]
	$wi.rmvbox configure -values $logIfcs 
	$wi.list configure -listvariable logIfcs
	configGUI_refreshIfcsTree .popup.nbook.nfInterfaces.panwin.f1.tree $curnode
	configGUI_showIfcInfo .popup.nbook.nfInterfaces.panwin.f2 0 $curnode logIfcFrame
	.popup.nbook.nfInterfaces.panwin.f1.tree selection set logIfcFrame
    }

    pack $wi.if$ifc -anchor w -fill both -expand 1

    grid $wi.if$ifc.txt -in $wi.if$ifc -column 0 -row 0 -sticky w \
	-columnspan 3 -pady 5
    #grid $wi.if$ifc.list -in $wi.if$ifc -column 0 -row 1 -padx 3 -rowspan 6 -sticky w

    grid $wi.if$ifc.addtxt -in $wi.if$ifc -column 1 -row 1 -sticky w -padx 8
    grid $wi.if$ifc.addbox -in $wi.if$ifc -column 2 -row 1 -padx 5
    grid $wi.if$ifc.addbtn -in $wi.if$ifc -column 3 -row 1

    grid $wi.if$ifc.rmvtxt -in $wi.if$ifc -column 1 -row 2 -sticky w -padx 8 
    grid $wi.if$ifc.rmvbox -in $wi.if$ifc -column 2 -row 2 -padx 5
    grid $wi.if$ifc.rmvbtn -in $wi.if$ifc -column 3 -row 2
    
#    pack $wi.if$ifc.list -anchor w
}

#****f* nodecfgGUI.tcl/configGUI_saveChangesPopup
# NAME
#   configGUI_saveChangesPopup -- configure GUI - save changes popup
# SYNOPSIS
#   configGUI_saveChangesPopup $wi $node $ifc
# FUNCTION
#   Creates a popup window with the warning about unsaved changes on
#   previously selected interface.
# INPUTS
#   * wi - widget
#   * node - node id
#   * ifc - interface name
#****
proc configGUI_saveChangesPopup { wi node ifc } {
    global guielements treecolumns apply cancel changed
    set answer [tk_messageBox -message "Do you want to save changes on interface $ifc?" \
        -icon question -type yesnocancel \
        -detail "Select \"Yes\" to save changes before choosing another interface"]
    
    switch -- $answer {
        #save changes
	yes {
	    set apply 1
	    set cancel 0
	    foreach guielement $guielements {
		if { [llength $guielement] == 2 } {
		    [lindex $guielement 0]\Apply $wi $node [lindex $guielement 1]
		}
	    }
	    #nbook - da li prozor sadrzi notebook
	    set nbook [lsearch [pack slaves .popup] .popup.nbook]
	    if { $changed == 1 } {
                if { $nbook != -1 && $treecolumns != "" } {
		    configGUI_refreshIfcsTree .popup.nbook.nfInterfaces.panwin.f1.tree $node
		} elseif { $nbook == -1 && $treecolumns != "" } {
		    configGUI_refreshIfcsTree .popup.panwin.f1.tree $node
		}
	        redrawAll
	        updateUndoLog
            }
	}
        #discard changes
	no {
	    set cancel 0
	}
        #get back on editing that interface
        cancel {
	    set cancel 1
	}
    }
}

#****f* nodecfgGUI.tcl/configGUI_buttonsACNode
# NAME
#   configGUI_buttonsACNode -- configure GUI - buttons apply/close/cancel node
# SYNOPSIS
#   configGUI_buttonsACNode $wi $node
# FUNCTION
#   Creates module with options for saving or discarding changes (Apply, Apply
#   and Close, Cancel).
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_buttonsACNode { wi node } {
    global badentry close guielements
    set close 0
    ttk::frame $wi.bottom
    ttk::frame $wi.bottom.buttons -borderwidth 6
    ttk::button $wi.bottom.buttons.apply -text "Apply" -command \
        "set apply 1; configGUI_applyButtonNode $wi $node 0"
    ttk::button $wi.bottom.buttons.applyclose -text "Apply and Close" -command \
        "set apply 1; set close 1; configGUI_applyButtonNode $wi $node 0"
    ttk::button $wi.bottom.buttons.cancel -text "Cancel" -command \
        "set badentry -1; destroy $wi"
    pack $wi.bottom.buttons.apply $wi.bottom.buttons.applyclose \
        $wi.bottom.buttons.cancel -side left -padx 2
    pack $wi.bottom.buttons -pady 2 -expand 1
    pack $wi.bottom -fill both -side bottom
#     ovo je zakomentirano zbog prelaska u novi red kod upisivanja statickih ruta
#     bind $wi <Key-Return> \
# 	"set apply 1; set close 1; configGUI_applyButtonNode $wi $node 0"
    bind $wi <Key-Escape> "set badentry -1; destroy $wi"
}

#****f* nodecfgGUI.tcl/configGUI_applyButtonNode
# NAME
#   configGUI_applyButtonNode -- configure GUI - apply button node
# SYNOPSIS
#   configGUI_applyButtonNode $wi $node
# FUNCTION
#   Calles procedures for saving changes, depending on the modules of the
#   configuration window.
# INPUTS
#   * wi -- widget
#   * node -- node id
#   * phase --
#****
proc configGUI_applyButtonNode { wi node phase } {
    global changed badentry close apply treecolumns	
    #
    #guielements - the list of modules contained in the configuration window
    #              (each element represents the name of the procedure which creates
    #               that module)
    #
    global guielements cancel

    #
    #close - indicates if Apply (0) or Apply and Close (1) button is pressed
    #
    if { $close == 1 } {
        $wi config -cursor watch
        update
    }
    if { $phase == 0 } {
	set badentry 0
        if { $close == 1 } {
	    focus .
        }
	after 100 "configGUI_applyButtonNode $wi $node 1"
	return
    } elseif { $badentry } {
	$wi config -cursor left_ptr
	return
    }

    foreach guielement $guielements {
	#1)Ako se radi o modulu s nazivom cvora onda je prvi argument u pozivu
	#"apply" procedure jednak $wi (konfiguracijski popup prozor). (SVI ELEMENTI)

	#2)Ako konfiguracijski prozor ne sadrzi widget notebook, a radi se
        #o modulu koji nema veze sa suceljima onda je prvi argument u pozivu
	#"apply" procedure jednak $wi (konfiguracijski popup prozor). (CLOUD)

        #3)Ako konfiguracijski prozor ne sadrzi widget notebook, 
        #a radi se o modulu koji ima veze sa suceljima 
        #(element guielement se sastoji od naziva procedure + naziva sucelja) onda je 
        #prvi argument u pozivu "apply" procedure jednak $wi.panwin.f2 (donji pane) 
	#(HUB, SWITCH)

	#4)Ako prozor sadrzi notebook, a radi se o dijelu prozora koji ima veze
	#sa suceljima (element guielement se sastoji od naziva procedure + naziva sucelja) 
        #onda je prvi argument u pozivu "apply" procedure jednak [lindex [$wi.nbook tabs] 1].panwin.f2 
        #(drugi tab u notebooku, donji pane), a treci argument je naziv sucelja [lindex $guielement 1] 
	#(PC, HOST, ROUTER, IP FIREWALL)
	
	#5) Inace (konfiguracijski prozor sadrzi notebook, a radi se o dijelu prozora koji 
        #nema veze sa suceljima) je prvi argument u pozivu "apply" procedure 
	#jednak [lindex [$wi.nbook tabs] 0] (prvi tab u notebooku). (PC, HOST, ROUTER, IP FIREWALL)
	if { $guielement == "configGUI_nodeName"} {
	    $guielement\Apply $wi $node
	} elseif { [lsearch [pack slaves .popup] .popup.nbook] == -1 && [llength $guielement] != 2 } {
	    $guielement\Apply $wi $node
	} elseif { [lsearch [pack slaves .popup] .popup.nbook] == -1 && [llength $guielement] == 2 } {
	    [lindex $guielement 0]\Apply $wi.panwin.f2 $node [lindex $guielement 1]
	} elseif { [lsearch [pack slaves .popup] .popup.nbook] != -1 && [llength $guielement] == 2 } {
	    if {[lindex $guielement 0] != "configGUI_ifcBridgeAttributes" } {
		[lindex $guielement 0]\Apply [lindex [.popup.nbook tabs] 1].panwin.f2 $node [lindex $guielement 1]
	    } else {
		[lindex $guielement 0]\Apply [lindex [.popup.nbook tabs] 2].panwin.f2 $node [lindex $guielement 1]
	    }
	} elseif { $guielement == "configGUI_nat64Config" } {
            $guielement\Apply [lindex [$wi.nbook tabs] 2] $node
        } else {  
	    $guielement\Apply [lindex [$wi.nbook tabs] 0] $node
	}
    }
    
    if { $changed == 1 } {
	set nbook [lsearch [pack slaves .popup] .popup.nbook]
	if { $nbook != -1 && $treecolumns != "" } {
	    configGUI_refreshIfcsTree .popup.nbook.nfInterfaces.panwin.f1.tree $node
	    set shownifcframe [pack slaves [lindex [.popup.nbook tabs] 1].panwin.f2]
	    set shownifc [string trim [lindex [split $shownifcframe .] end] if]
	    [lindex [.popup.nbook tabs] 1].panwin.f1.tree selection set $shownifc

	    if { ".popup.nbook.nfBridge" in [.popup.nbook tabs] } {
		configGUI_refreshBridgeIfcsTree .popup.nbook.nfBridge.panwin.f1.tree $node
	    }
	} elseif { $nbook == -1 && $treecolumns != "" } {
	    configGUI_refreshIfcsTree .popup.panwin.f1.tree $node
	} else {
	}
	redrawAll
	updateUndoLog
    }

    set apply 0
    
    if { $close == 1 } {
       destroy .popup
    } else {
	$wi config -cursor left_ptr
	update
    }
}

#****f* nodecfgGUI.tcl/configGUI_nodeName
# NAME
#   configGUI_nodeName -- configure GUI - node name
# SYNOPSIS
#   configGUI_nodeName $wi $node $label
# FUNCTION
#   Creating module with node name.
# INPUTS
#   * wi -- widget
#   * node -- node id
#   * label -- text shown before the entry with node name
#****
proc configGUI_nodeName { wi node label } {
    global guielements
    lappend guielements configGUI_nodeName
    ttk::frame $wi.name -borderwidth 6
    ttk::label $wi.name.txt -text $label

    if { [typemodel $node] == "rj45" } {
	ttk::combobox $wi.name.nodename -width 14 -textvariable extIfc$node
	set ifcs [getExtIfcs]
	$wi.name.nodename configure -values [concat UNASSIGNED $ifcs]
	$wi.name.nodename set [lindex [split [getNodeName $node] .] 0 ]
    } else {
	ttk::entry $wi.name.nodename -width 14 -validate focus
	$wi.name.nodename insert 0 [lindex [split [getNodeName $node] .] 0]
    }
    pack $wi.name.txt -side left -anchor e -expand 1 -padx 4 -pady 4
    pack $wi.name.nodename -side left -anchor w -expand 1 -padx 4 -pady 4
    pack $wi.name -fill both
}

#****f* nodecfgGUI.tcl/configGUI_ifcMainFrame
# NAME
#   configGUI_ifcMainFrame -- configure GUI - interface main frame
# SYNOPSIS
#   configGUI_ifcMainFrame $wi $node $ifc
# FUNCTION
#   Creating frame which will be used for adding modules for changing
#   interface parameters. For now it contains only the label with the interface
#   name.
# INPUTS
#   * wi -- widget
#   * node -- node id
#   * ifc -- interface name
#****
proc configGUI_ifcMainFrame { wi node ifc } {
    global apply changed
    set apply 0
    set changed 0
    ttk::frame $wi.if$ifc -relief groove -borderwidth 2 -padding 4
    ttk::frame $wi.if$ifc.label -borderwidth 2 
    ttk::label $wi.if$ifc.label.txt -text "Interface $ifc:" -width 13
    pack $wi.if$ifc.label.txt -side left -anchor w
    pack $wi.if$ifc.label -anchor w
    pack $wi.if$ifc -anchor w -fill both -expand 1
}

#****f* nodecfgGUI.tcl/configGUI_ifcEssentials
# NAME
#   configGUI_ifcEssentials -- configure GUI - interface essentials
# SYNOPSIS
#   configGUI_ifcEssentials $wi $node $ifc
# FUNCTION
#   Creating module for changing basic interface parameters: state (up or
#   down) and MTU.
# INPUTS
#   * wi -- widget
#   * node -- node id
#   * ifc -- interface id
#****
proc configGUI_ifcEssentials { wi node ifc } {
    global guielements
    lappend guielements "configGUI_ifcEssentials $ifc"
    global ifoper$ifc
    set ifoper$ifc [getIfcOperState $node $ifc]
    ttk::radiobutton $wi.if$ifc.label.up -text "up" \
	-variable ifoper$ifc -value up -padding 4
    ttk::radiobutton $wi.if$ifc.label.down -text "down" \
	-variable ifoper$ifc -value down -padding 4
    ttk::label $wi.if$ifc.label.mtul -text "MTU" -anchor e -width 5 -padding 2
    ttk::spinbox $wi.if$ifc.label.mtuv -width 5 \
	-validate focus -invalidcommand "focusAndFlash %W"
    $wi.if$ifc.label.mtuv insert 0 [getIfcMTU $node $ifc]

    $wi.if$ifc.label.mtuv configure \
	-from 256 -to 9018 -increment 2 \
	-validatecommand {checkIntRange %P 256 9018}

    pack $wi.if$ifc.label.up -side left -anchor w -padx 5
    pack $wi.if$ifc.label.down \
	$wi.if$ifc.label.mtul -side left -anchor w
    pack $wi.if$ifc.label.mtuv -side left -anchor w -padx 1
}

#****f* nodecfgGUI.tcl/configGUI_ifcQueueConfig
# NAME
#   configGUI_ifcQueueConfig -- configure GUI - interface queue configuration
# SYNOPSIS
#   configGUI_ifcQueueConfig $wi $node $ifc
# FUNCTION
#   Creating module for queue configuration.
# INPUTS
#   * wi -- widget
#   * node -- node id
#   * ifc -- interface name
#****
proc configGUI_ifcQueueConfig { wi node ifc } {
    global guielements
    lappend guielements "configGUI_ifcQueueConfig $ifc"
    global ifqdisc$ifc ifqdrop$ifc
    set ifqdisc$ifc [getIfcQDisc $node $ifc]
    set ifqdrop$ifc [getIfcQDrop $node $ifc]
    ttk::frame $wi.if$ifc.queuecfg -borderwidth 2
    ttk::label $wi.if$ifc.queuecfg.txt1 -text "Queue" -anchor w
    ttk::combobox $wi.if$ifc.queuecfg.disc -width 6 -textvariable ifqdisc$ifc
    $wi.if$ifc.queuecfg.disc configure -values [list FIFO DRR WFQ]
    ttk::combobox $wi.if$ifc.queuecfg.drop -width 9 -textvariable ifqdrop$ifc
    $wi.if$ifc.queuecfg.drop configure -values [list drop-tail drop-head]
    ttk::label $wi.if$ifc.queuecfg.txt2 -text "len" -anchor e -width 3 -padding 2
    ttk::spinbox $wi.if$ifc.queuecfg.len -width 4 \
	-validate focus -invalidcommand "focusAndFlash %W"
    $wi.if$ifc.queuecfg.len insert 0 [getIfcQLen $node $ifc]
    $wi.if$ifc.queuecfg.len configure \
	-from 5 -to 4096 -increment 1 \
	-validatecommand {checkIntRange %P 5 4096}
    pack $wi.if$ifc.queuecfg.txt1 -side left -anchor w
    pack $wi.if$ifc.queuecfg.disc $wi.if$ifc.queuecfg.drop \
	-side left -anchor w -padx 2
    pack $wi.if$ifc.queuecfg.txt2 $wi.if$ifc.queuecfg.len -side left -anchor e
    pack $wi.if$ifc.queuecfg -anchor w -padx 10
}

#****f* nodecfgGUI.tcl/configGUI_ifcMACAddress
# NAME
#   configGUI_ifcMACAddress -- configure GUI - interface MAC address
# SYNOPSIS
#   configGUI_ifcMACAddress $wi $node $ifc
# FUNCTION
#   Creating module for changing MAC address.
# INPUTS
#   * wi -- widget
#   * node -- node id
#   * ifc -- interface name
#****
proc configGUI_ifcMACAddress { wi node ifc } {
    global guielements
    lappend guielements "configGUI_ifcMACAddress $ifc"
    ttk::frame $wi.if$ifc.mac -borderwidth 2
    ttk::label $wi.if$ifc.mac.txt -text "MAC address " -anchor w
    ttk::entry $wi.if$ifc.mac.addr -width 30 \
	-validate focus -invalidcommand "focusAndFlash %W"
    $wi.if$ifc.mac.addr insert 0 [getIfcMACaddr $node $ifc]
    $wi.if$ifc.mac.addr configure -validatecommand {checkMACAddr %P}
    pack $wi.if$ifc.mac.txt $wi.if$ifc.mac.addr -side left
    pack $wi.if$ifc.mac -anchor w -padx 10
}

#****f* nodecfgGUI.tcl/configGUI_ifcIPv4Address
# NAME
#   configGUI_ifcIPv4Address -- configure GUI - interface IPv4 address
# SYNOPSIS
#   configGUI_ifcIPv4Address $wi $node $ifc
# FUNCTION
#   Creating module for changing IPv4 address.
# INPUTS
#   * wi -- widget
#   * node -- node id
#   * ifc -- interface name
#****
proc configGUI_ifcIPv4Address { wi node ifc } {
    global guielements
    lappend guielements "configGUI_ifcIPv4Address $ifc"
    ttk::frame $wi.if$ifc.ipv4 -borderwidth 2
    ttk::label $wi.if$ifc.ipv4.txt -text "IPv4 addresses " -anchor w
    ttk::entry $wi.if$ifc.ipv4.addr -width 45 \
	-validate focus -invalidcommand "focusAndFlash %W"
    set addrs ""
    foreach addr [getIfcIPv4addrs $node $ifc] {
	append addrs "$addr" "; "
    }
    $wi.if$ifc.ipv4.addr insert 0 $addrs
    $wi.if$ifc.ipv4.addr configure -validatecommand {checkIPv4Nets %P}
    pack $wi.if$ifc.ipv4.txt $wi.if$ifc.ipv4.addr -side left
    pack $wi.if$ifc.ipv4 -anchor w -padx 10
}

#****f* nodecfgGUI.tcl/configGUI_ifcIPv6Address
# NAME
#   configGUI_ifcIPv6Address -- configure GUI - interface IPv6 address
# SYNOPSIS
#   configGUI_ifcIPv6Address $wi $node $ifc
# FUNCTION
#   Creating module for changing IPv6 address.
# INPUTS
#   * wi -- widget
#   * node -- node id
#   * ifc -- interface name
#****
proc configGUI_ifcIPv6Address { wi node ifc } {
    global guielements
    lappend guielements "configGUI_ifcIPv6Address $ifc"
    ttk::frame $wi.if$ifc.ipv6 -borderwidth 2
    ttk::label $wi.if$ifc.ipv6.txt -text "IPv6 addresses " -anchor w
    ttk::entry $wi.if$ifc.ipv6.addr -width 45 \
	-validate focus -invalidcommand "focusAndFlash %W"
    set addrs ""
    foreach addr [getIfcIPv6addrs $node $ifc] {
	append addrs "$addr" "; "
    }
    $wi.if$ifc.ipv6.addr insert 0 $addrs
    $wi.if$ifc.ipv6.addr configure -validatecommand {checkIPv6Nets %P}
    pack $wi.if$ifc.ipv6.txt $wi.if$ifc.ipv6.addr -side left
    pack $wi.if$ifc.ipv6 -anchor w -padx 10
}

#****f* nodecfgGUI.tcl/configGUI_ifcDirection
# NAME
#   configGUI_ifcDirection -- configure GUI - interface direction
# SYNOPSIS
#   configGUI_ifcDirection $wi $node $ifc
# FUNCTION
#   Creating module for changing direction of the interface (internal or
#   external).
# INPUTS
#   * wi -- widget
#   * node -- node id
#   * ifc -- interface id
#****
proc configGUI_ifcDirection { wi node ifc } {
    global guielements externalifc
    lappend guielements "configGUI_ifcDirection $ifc"
    set external 0
    set externalifc ""
    ttk::frame $wi.if$ifc.direct -borderwidth 2
    ttk::label $wi.if$ifc.direct.txt -text "Direction " -anchor w
    global ifdirect$ifc
    set ifdirect$ifc [getIfcDirect $node $ifc]
    foreach interface [ifcList $node] {
 	if { [string equal [getIfcDirect $node $interface] "external"] } {
 	    set external 1
            set externalifc $interface
 	}
     }
    ttk::radiobutton $wi.if$ifc.direct.int -text "internal" \
	-variable ifdirect$ifc -value internal -padding 2
    ttk::radiobutton $wi.if$ifc.direct.ext -text "external" \
	    -variable ifdirect$ifc -value external -padding 2
    pack $wi.if$ifc.direct.txt -side left
    pack $wi.if$ifc.direct.int $wi.if$ifc.direct.ext -side left -anchor w
    pack $wi.if$ifc.direct -anchor w -padx 10
}

#****f* nodecfgGUI.tcl/configGUI_ipfirewallRuleset
# NAME
#   configGUI_ipfirewallRuleset -- configure GUI - ipfirewall ruleset
# SYNOPSIS
#   configGUI_ipfirewallRuleset $wi $node
# FUNCTION
#   Creating module for adding rules for packet filtering (ipfw rules).
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_ipfirewallRuleset { wi node } {
    global guielements
    lappend guielements configGUI_ipfirewallRuleset
    ttk::frame $wi.rules -borderwidth 2 -relief groove -padding 4
    ttk::label $wi.rules.label -text "Add rules:"
    text $wi.rules.text -bg white -width 42 -height 4 -takefocus 0  
    pack $wi.rules.label -anchor w -pady 2
    pack $wi.rules.text -fill both -expand 1 -padx 4 -expand 1
    pack $wi.rules -anchor w -fill both -expand 1
}

#****f* nodecfgGUI.tcl/configGUI_staticRoutes
# NAME
#   configGUI_staticRoutes -- configure GUI - static routes
# SYNOPSIS
#   configGUI_staticRoutes $wi $node
# FUNCTION
#   Creating module for adding static routes.
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_staticRoutes { wi node } {
    global guielements
    lappend guielements configGUI_staticRoutes
    set routes [concat [getStatIPv4routes $node] [getStatIPv6routes $node]]
    ttk::frame $wi.statrts -borderwidth 2 -relief groove -padding 4
    ttk::label $wi.statrts.label -text "Static routes:"
    set h [expr {[llength $routes] + 1}]
    if { $h < 2 } {
	set h 2	    
    }
    text $wi.statrts.text -bg white -width 42 -height $h -takefocus 0
    foreach route $routes {
	$wi.statrts.text insert end "$route
"
    } 
    pack $wi.statrts.label -anchor w -pady 2
    pack $wi.statrts.text -fill both -expand 1 -padx 4 -expand 1
    pack $wi.statrts -anchor w -fill both -expand 1
}

#****f* nodecfgGUI.tcl/configGUI_etherVlan
# NAME
#   configGUI_etherVlan -- configure GUI - vlan for rj45 nodes
# SYNOPSIS
#   configGUI_etherVlan $wi $node
# FUNCTION
#   Creating module for assigning vlan to rj45 nodes.
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_etherVlan { wi node } {
    global guielements vlanEnable
    lappend guielements configGUI_etherVlan

    ttk::frame $wi.vlancfg -borderwidth 2 -relief groove
    ttk::label $wi.vlancfg.label -text "Vlan:" -anchor w
    ttk::checkbutton $wi.vlancfg.enabled -text "enabled" -variable vlanEnable \
	-command { 
	    global vlanEnable
	    if { $vlanEnable } {
		.popup.vlancfg.tag configure -state enabled
	    } else {
		.popup.vlancfg.tag configure -state disabled
	    }
	}
    ttk::label $wi.vlancfg.tagtxt -text "Vlan tag:" -anchor w
    ttk::spinbox $wi.vlancfg.tag -width 6 -validate focus \
	-invalidcommand "focusAndFlash %W"
    $wi.vlancfg.tag configure \
	-validatecommand {checkIntRange %P 1 4094} \
	-from 1 -to 4094 -increment 1

    $wi.vlancfg.tag insert 0 [getEtherVlanTag $node]
    set vlanEnable [getEtherVlanEnabled $node]
    if { ! $vlanEnable } {
	.popup.vlancfg.tag configure -state disabled
    }

    pack $wi.vlancfg -expand 1 -padx 1 -pady 1
    grid $wi.vlancfg.label -in $wi.vlancfg -column 0 -row 0 -pady 4
    grid $wi.vlancfg.enabled -in $wi.vlancfg -column 1 -row 0 -pady 4
    grid $wi.vlancfg.tagtxt -in $wi.vlancfg -column 0 -row 1 \
	-padx 3 -pady 4
    grid $wi.vlancfg.tag -in $wi.vlancfg -column 1 -row 1 \
	-padx 3 -pady 4
}

#****f* nodecfgGUI.tcl/configGUI_customConfig
# NAME
#   configGUI_customConfig -- configure GUI - custom configuration
# SYNOPSIS
#   configGUI_customConfig $wi $node
# FUNCTION
#   Creating module for custom startup coniguration.
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_customConfig { wi node } {
    global customEnabled guielements selectedConfig
    lappend guielements configGUI_customConfig

    ttk::frame $wi.custcfg -borderwidth 2 -relief groove -padding 4
    ttk::label $wi.custcfg.etxt -text "Custom startup config:"
    set customEnabled [getCustomEnabled $node]
    ttk::checkbutton $wi.custcfg.echeckOnOff -text "Enabled" \
	-variable customEnabled -onvalue true -offvalue false
 
    ttk::label $wi.custcfg.dtxt -text "Selected custom config:"
    ttk::combobox $wi.custcfg.dcomboDefault -height 10 -width 15 \
	-state readonly -textvariable selectedConfig
    $wi.custcfg.dcomboDefault configure -values [getCustomConfigIDs $node]
    $wi.custcfg.dcomboDefault set [getCustomConfigSelected $node]

    ttk::button $wi.custcfg.beditor -text "Editor" -command "customConfigGUI $node"

    grid $wi.custcfg.etxt -in $wi.custcfg -sticky w -column 0 -row 0
    grid $wi.custcfg.echeckOnOff -in $wi.custcfg -sticky w -column 1 \
	-row 0 -padx 5 -pady 3
    grid $wi.custcfg.dtxt -in $wi.custcfg -sticky w -column 0 -row 1
    grid $wi.custcfg.dcomboDefault -in $wi.custcfg -sticky w -column 1 \
	-row 1 -padx 7 -pady 3
    grid $wi.custcfg.beditor -in $wi.custcfg -column 2 -row 0 \
	-rowspan 2 -pady 3 -padx 50 -sticky e
    pack $wi.custcfg -anchor w -fill both
}

#****f* nodecfgGUI.tcl/configGUI_snapshots
# NAME
#   configGUI_snapshots -- configure GUI - snapshots
# SYNOPSIS
#   configGUI_snapshots $wi $node
# FUNCTION
#   Creating module for selecting ZFS snapshots.
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_snapshots { wi node } {
    global showZFSsnapshots
    if {$showZFSsnapshots != 1} {
	return
    }
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    set os [platform::identify]
    global guielements snapshot snapshotList
    lappend guielements configGUI_snapshots
    
    ttk::frame $wi.snapshot -borderwidth 2 -relief groove -padding 4 
    ttk::label $wi.snapshot.label -text "Select ZFS snapshot:"
    catch { exec zfs list -t snapshot | awk {{print $1}} | sed "1 d" } out
	set snapshotList [ split $out {
}]
    set snapshot [getNodeSnapshot $node]
    if { [llength $snapshot] == 0 } {
    	set snapshot {vroot/vroot@clean}
    }
    
    ttk::combobox $wi.snapshot.text -width 25 -state readonly -textvariable snapshot
    $wi.snapshot.text configure -values $snapshotList
    
    if { $oper_mode != "edit" || [string match -nocase "*freebsd*" $os] != 1 } {
    	$wi.snapshot.text configure -state disabled
    }
    
    pack $wi.snapshot.label -side left -pady 2 -anchor w
    pack $wi.snapshot.text -side left -pady 4 -anchor w
    pack $wi.snapshot -fill both -expand 1 -anchor w
    
}

#****f* nodecfgGUI.tcl/configGUI_stp
# NAME
#   configGUI_stp -- configure GUI - STP
# SYNOPSIS
#   configGUI_stp $wi $node
# FUNCTION
#   Creating module for enabling STP.
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_stp { wi node } {
    global stpEnabled guielements
    lappend guielements configGUI_stp
    
    ttk::frame $wi.stp -borderwidth 2 -relief groove -padding 4
    ttk::label $wi.stp.label -text "Spanning Tree Protocol:"
    set stpEnabled [getStpEnabled $node]
    ttk::checkbutton $wi.stp.echeckOnOff -text "Enabled" \
	-variable stpEnabled -onvalue true -offvalue false
    
    grid $wi.stp.label -in $wi.stp -sticky w -column 0 -row 0
    grid $wi.stp.echeckOnOff -in $wi.stp -sticky w -column 1 -row 0
    pack $wi.stp -anchor w -fill both
}

#****f* nodecfgGUI.tcl/configGUI_routingModel
# NAME
#   configGUI_routingModel -- configure GUI - routing model
# SYNOPSIS
#   configGUI_routingModel $wi $node
# FUNCTION
#   Creating module for changing routing model and protocols.
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_routingModel { wi node } {
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    global ripEnable ripngEnable ospfEnable ospf6Enable supp_router_models
    global router_ConfigModel guielements
    lappend guielements configGUI_routingModel
    ttk::frame $wi.routing -relief groove -borderwidth 2 -padding 2
    ttk::frame $wi.routing.model -padding 2
    ttk::label $wi.routing.model.label -text "Model:" 
    ttk::frame $wi.routing.protocols -padding 2
    ttk::label $wi.routing.protocols.label -text "Protocols:"

    ttk::checkbutton $wi.routing.protocols.rip -text "rip" -variable ripEnable
    ttk::checkbutton $wi.routing.protocols.ripng -text "ripng" -variable ripngEnable
    ttk::checkbutton $wi.routing.protocols.ospf -text "ospfv2" -variable ospfEnable
    ttk::checkbutton $wi.routing.protocols.ospf6 -text "ospfv3" -variable ospf6Enable
    ttk::radiobutton $wi.routing.model.quagga -text quagga \
	-variable router_ConfigModel -value quagga -command \
	"$wi.routing.protocols.rip configure -state normal;
	 $wi.routing.protocols.ripng configure -state normal;
	 $wi.routing.protocols.ospf configure -state normal;
	 $wi.routing.protocols.ospf6 configure -state normal"
    ttk::radiobutton $wi.routing.model.xorp -text xorp \
	-variable router_ConfigModel -value xorp -command \
	"$wi.routing.protocols.rip configure -state normal;
	 $wi.routing.protocols.ripng configure -state normal;
	 $wi.routing.protocols.ospf configure -state normal;
	 $wi.routing.protocols.ospf6 configure -state normal"
    ttk::radiobutton $wi.routing.model.static -text static \
	-variable router_ConfigModel -value static -command \
	"$wi.routing.protocols.rip configure -state disabled;
	 $wi.routing.protocols.ripng configure -state disabled;
	 $wi.routing.protocols.ospf configure -state disabled;
	 $wi.routing.protocols.ospf6 configure -state disabled"
	
    set router_ConfigModel [getNodeModel $node]
    if { $router_ConfigModel != "static" } {
        set ripEnable [getNodeProtocolRip $node]
	set ripngEnable [getNodeProtocolRipng $node]
	set ospfEnable [getNodeProtocolOspfv2 $node]
	set ospf6Enable [getNodeProtocolOspfv3 $node]
    } else {
        $wi.routing.protocols.rip configure -state disabled
	$wi.routing.protocols.ripng configure -state disabled
 	$wi.routing.protocols.ospf configure -state disabled
 	$wi.routing.protocols.ospf6 configure -state disabled
    }
    if { $oper_mode != "edit" } {
	$wi.routing.model.quagga configure -state disabled
	$wi.routing.model.xorp configure -state disabled
	$wi.routing.model.static configure -state disabled
	$wi.routing.protocols.rip configure -state disabled
	$wi.routing.protocols.ripng configure -state disabled
	$wi.routing.protocols.ospf configure -state disabled
	$wi.routing.protocols.ospf6 configure -state disabled
    }
    if {"xorp" ni $supp_router_models} {
	$w.model.xorp configure -state disabled
    }
    pack $wi.routing.model.label -side left -padx 2
    pack $wi.routing.model.quagga $wi.routing.model.xorp $wi.routing.model.static \
        -side left -padx 6
    pack $wi.routing.model -fill both -expand 1
    pack $wi.routing.protocols.label -side left -padx 2
    pack $wi.routing.protocols.rip $wi.routing.protocols.ripng \
	$wi.routing.protocols.ospf $wi.routing.protocols.ospf6 -side left -padx 6
    pack $wi.routing.protocols -fill both -expand 1
    pack $wi.routing -fill both
}

#****f* nodecfgGUI.tcl/configGUI_servicesConfig
# NAME
#   configGUI_servicesConfig -- configure GUI - services configuration
# SYNOPSIS
#   configGUI_servicesConfig $wi $node
# FUNCTION
#   Creating module for changing services started on node.
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_servicesConfig { wi node } {
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    global guielements all_services_list
    lappend guielements configGUI_servicesConfig
    set w $wi.services
    ttk::frame $w -relief groove -borderwidth 2 -padding 2
    ttk::label $w.label -text "Services:" 
    ttk::frame $w.list -padding 2

    pack $w.label -side left -padx 2
    pack $w.list -side left -padx 2

    foreach srv $all_services_list {
	global $srv\_enable
	set $srv\_enable 0
	if { $oper_mode == "edit" } {
	    ttk::checkbutton $w.list.$srv -text "$srv" -variable $srv\_enable
	} else {
	    ttk::checkbutton $w.list.$srv -text "$srv" -variable $srv\_enable \
		-state disabled
	}
	pack $w.list.$srv -side left -padx 6
    }

    foreach srv [getNodeServices $node] {
	global $srv\_enable
	set $srv\_enable 1
    }

    pack $w -fill both
}

#****f* nodecfgGUI.tcl/configGUI_cpuConfig
# NAME
#   configGUI_cpuConfig -- configure GUI - CPU configuration
# SYNOPSIS
#   configGUI_cpuConfig $wi $node
# FUNCTION
#   Creating module for CPU configuration.
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_cpuConfig { wi node } {
    global guielements
    lappend guielements configGUI_cpuConfig
    ttk::frame $wi.cpucfg -borderwidth 2 -relief groove -padding 4
    ttk::label $wi.cpucfg.minlabel -text "CPU  min%"
    ttk::spinbox $wi.cpucfg.minvalue -width 3 \
        -validate focus -invalidcommand "focusAndFlash %W"
    set cpumin [lindex [lsearch -inline [getNodeCPUConf $node] {min *}] 1]
    if { $cpumin == "" } {
	set cpumin 0
    }
    $wi.cpucfg.minvalue insert 0 $cpumin
    $wi.cpucfg.minvalue configure \
        -validatecommand {checkIntRange %P 1 90} \
        -from 0 -to 90 -increment 1
    ttk::label $wi.cpucfg.maxlabel -text "  max%"
    ttk::spinbox $wi.cpucfg.maxvalue -width 3 \
        -validate focus -invalidcommand "focusAndFlash %W"
    set cpumax [lindex [lsearch -inline [getNodeCPUConf $node] {max *}] 1]
    if { $cpumax == "" } {
	set cpumax 100
    }
    $wi.cpucfg.maxvalue insert 0 $cpumax
    $wi.cpucfg.maxvalue configure \
        -validatecommand {checkIntRange %P 1 100} \
	-from 1 -to 100 -increment 1
    ttk::label $wi.cpucfg.weightlabel -text "  weight"
    ttk::spinbox $wi.cpucfg.weightvalue -width 2  \
        -validate focus -invalidcommand "focusAndFlash %W"
    set cpuweight [lindex [lsearch -inline [getNodeCPUConf $node] {weight *}] 1]
    if { $cpuweight == "" } {
	set cpuweight 1
    }
    $wi.cpucfg.weightvalue insert 0 $cpuweight
    $wi.cpucfg.weightvalue configure \
	-validatecommand {checkIntRange %P 1 10} \
	-from 1 -to 10 -increment 1
    pack $wi.cpucfg.minlabel $wi.cpucfg.minvalue $wi.cpucfg.maxlabel \
        $wi.cpucfg.maxvalue $wi.cpucfg.weightlabel $wi.cpucfg.weightvalue \
	-side left -anchor w
    pack $wi.cpucfg -anchor w -fill both
}

#****f* nodecfgGUI.tcl/configGUI_cloudConfig
# NAME
#   configGUI_cloudConfig -- configure GUI - cloud configuration
# SYNOPSIS
#   configGUI_cloudConfig $wi $node
# FUNCTION
#   Creating module for cloud configuration.
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_cloudConfig { wi node } {
    global guielements
    lappend guielements configGUI_cloudConfig
    ttk::frame $wi.cloudpart -borderwidth 2 -relief groove -padding 6
    ttk::frame $wi.cloudpart.label
    ttk::label $wi.cloudpart.label.txt -text "Number of hosts:"
    ttk::spinbox $wi.cloudpart.label.num -width 10 -validate focus \
        -invalidcommand "focusAndFlash %W"	
    $wi.cloudpart.label.num insert 0 1;
    $wi.cloudpart.label.num configure \
        -validatecommand {checkIntRange %P 1 1000000} \
        -from 1 -to 1000000 -increment 1
    pack $wi.cloudpart.label.txt -side left -anchor w -padx 4
    pack $wi.cloudpart.label.num
    pack $wi.cloudpart.label -expand 1 -fill both
    pack $wi.cloudpart -expand 1 -fill both
}

#****f* nodecfgGUI.tcl/configGUI_ifcVlanConfig
# NAME
#   configGUI_ifcVlanConfig -- configure GUI - interface vlan configuration
# SYNOPSIS
#   configGUI_ifcVlanConfig $wi $node $ifc
# FUNCTION
#   Creating module for Vlan configuration
# INPUTS
#   * wi -- widget
#   * node -- node id
#   * ifc -- interface name
#****
proc configGUI_ifcVlanConfig { wi node ifc } {
    global guielements
    lappend guielements "configGUI_ifcVlanConfig $ifc"
    global ifvdev$ifc

    ttk::frame $wi.if$ifc.vlancfg -borderwidth 2
    ttk::label $wi.if$ifc.vlancfg.tagtxt -text "Vlan tag" -anchor w
    ttk::spinbox $wi.if$ifc.vlancfg.tag -width 6 -validate focus \
	-invalidcommand "focusAndFlash %W"
    $wi.if$ifc.vlancfg.tag insert 0 [getIfcVlanTag $node $ifc] 
    $wi.if$ifc.vlancfg.tag configure \
	-validatecommand {checkIntRange %P 1 4094} \
	-from 1 -to 4094 -increment 1
    
    set ifvdev$ifc [getIfcVlanDev $node $ifc]
    ttk::label $wi.if$ifc.vlancfg.devtxt -text "Vlan dev" -anchor w
    ttk::combobox $wi.if$ifc.vlancfg.dev -width 6 -textvariable ifvdev$ifc
    $wi.if$ifc.vlancfg.dev configure -values [ifcList $node] -state readonly

    pack $wi.if$ifc.vlancfg -anchor w -padx 10
    grid $wi.if$ifc.vlancfg.devtxt -in $wi.if$ifc.vlancfg -column 0 -row 0 \
	-padx 3 -pady 4 -padx 2
    grid $wi.if$ifc.vlancfg.dev -in $wi.if$ifc.vlancfg -column 1 -row 0 \
	-sticky w -padx 3
    grid $wi.if$ifc.vlancfg.tagtxt -in $wi.if$ifc.vlancfg -column 2 -row 0 \
	-padx 3 -pady 4 -padx 2
    grid $wi.if$ifc.vlancfg.tag -in $wi.if$ifc.vlancfg -column 3 -row 0 \
	-sticky w -padx 3
}

###############"Apply" procedures################
#names of these procedures are formed as follows:
#name of the procedure that creates the module + "Apply" suffix
#for example, name of the procedure that saves changes in module with IPv4 address: 
#configGUI_ifcIPv4Address + "Apply" --> configGUI_ifcIPv4AddressApply

#****f* nodecfgGUI.tcl/configGUI_nodeNameApply
# NAME
#   configGUI_nodeNameApply -- configure GUI - node name apply
# SYNOPSIS
#   configGUI_nodeNameApply $wi $node
# FUNCTION
#   Saves changes in the module with node name.
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_nodeNameApply { wi node } {
    global changed badentry showTree
    
    set name [string trim [$wi.name.nodename get]]
    if { [regexp {^[0-9A-Za-z][0-9A-Za-z-]*$} $name ] == 0 } {
	tk_dialog .dialog1 "IMUNES warning" \
	    "Hostname should contain only letters, digits, and -, and should not start with - (hyphen)." \
	    info 0 Dismiss
    } elseif {$name != [getNodeName $node]} {
        setNodeName $node $name
        if { $showTree == 1 } {
	    refreshTopologyTree
	}
	set changed 1
    }
}

#****f* nodecfgGUI.tcl/configGUI_ifcEssentialsApply
# NAME
#   configGUI_ifcEssentialsApply -- configure GUI - interface essentials apply
# SYNOPSIS
#   configGUI_ifcEssentialsApply $wi $node $ifc
# FUNCTION
#   Saves changes in the module with basic interface parameters.
# INPUTS
#   * wi -- widget
#   * node -- node id
#   * ifc -- interface name
#****
proc configGUI_ifcEssentialsApply { wi node ifc } {
    global changed apply
    #
    #apply - indicates if this procedure needs to save changes (1)
    #        or just to check if some interface parameters have been changed (0)
    #        
    global [subst ifoper$ifc]
    set ifoperstate [subst $[subst ifoper$ifc]]
    set oldifoperstate [getIfcOperState $node $ifc]
    if { $ifoperstate != $oldifoperstate } {
	if {$apply == 1} {
	    setIfcOperState $node $ifc $ifoperstate
	}
	set changed 1
    }
    set mtu [$wi.if$ifc.label.mtuv get]
    set oldmtu [getIfcMTU $node $ifc]
    if {![string first vlan $ifc]} {
	set par_ifc [getIfcVlanDev $node $ifc]
	set par_mtu [getIfcMTU $node $par_ifc]
	if { $par_mtu < $mtu } {
	    if { $apply == 1} {
		tk_dialog .dialog1 "IMUNES warning" \
		    "Vlan interface can't have MTU bigger than the parent interface $par_ifc (MTU = $par_mtu)" \
		info 0 Dismiss
	    }
	    return
	}
    }
    if { $mtu != $oldmtu } {
        if {$apply == 1} {
	    setIfcMTU $node $ifc $mtu
	}
	set changed 1
    }
}

#****f* nodecfgGUI.tcl/configGUI_ifcQueueConfigApply
# NAME
#   configGUI_ifcQueueConfigApply -- configure GUI - interface queue
#      configuration apply
# SYNOPSIS
#   configGUI_ifcQueueConfigApply $wi $node $ifc
# FUNCTION
#   Saves changes in the module with queue configuration parameters.
# INPUTS
#   * wi -- widget
#   * node -- node id
#   * ifc -- interface name
#****
proc configGUI_ifcQueueConfigApply { wi node ifc } {
    global changed apply
    if { [nodeType [peerByIfc $node $ifc]] != "rj45" } {
	set qdisc [string trim [$wi.if$ifc.queuecfg.disc get]]
	set oldqdisc [getIfcQDisc $node $ifc]
	if { $qdisc != $oldqdisc } {
	    if {$apply == 1} {
		setIfcQDisc $node $ifc $qdisc
	    }
	    set changed 1
	}
	set qdrop [string trim [$wi.if$ifc.queuecfg.drop get]]
	set oldqdrop [getIfcQDrop $node $ifc]
	if { $qdrop != $oldqdrop } {
	    if {$apply == 1} {
		setIfcQDrop $node $ifc $qdrop
	    }
	    set changed 1
	}
	set len [$wi.if$ifc.queuecfg.len get]
	set oldlen [getIfcQLen $node $ifc]
	if { $len != $oldlen } {
	    if {$apply == 1} {
		setIfcQLen $node $ifc $len
	    }
	    set changed 1
	}
    }
}

#****f* nodecfgGUI.tcl/configGUI_ifcMACAddressApply
# NAME
#   configGUI_ifcMACAddressApply -- configure GUI - interface MAC address apply
# SYNOPSIS
#   configGUI_ifcMACAddressApply $wi $node $ifc
# FUNCTION
#   Saves changes in the module with MAC address.
# INPUTS
#   * wi -- widget
#   * node -- node id
#   * ifc -- interface name
#****
proc configGUI_ifcMACAddressApply { wi node ifc } {
    upvar 0 ::cf::[set ::curcfg]::MACUsedList MACUsedList
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    global changed apply close
    set entry [$wi.if$ifc.mac.addr get]
    if { $entry != "" } {
        set macaddr [MACaddrAddZeros $entry]
    } else {
        set macaddr $entry
    }
    if { [checkMACAddr $macaddr] == 0 } {
	return
    }
    if { $macaddr in $MACUsedList } {
	foreach n $node_list {
	    foreach i [ifcList $n] {
		if { $n != $node || $i != $ifc } {
		    if { $macaddr != "" && $macaddr == [getIfcMACaddr $n $i] } {
			set dup "$n $i"
		    }
		}
	    }
	}
    } else {
	set dup 1
    }
    set oldmacaddr [getIfcMACaddr $node $ifc]
    if { $macaddr != $oldmacaddr } {
        if { $apply == 1 && $dup != 1 && $macaddr != "" } {
            tk_dialog .dialog1 "IMUNES warning" \
	        "Provided MAC address already exists on node's [lindex $dup 0] interface [lindex $dup 1]" \
	    info 0 Dismiss
        }
	if {$apply == 1} {
	    setIfcMACaddr $node $ifc $macaddr
	 }
	set changed 1
    }
}

#****f* nodecfgGUI.tcl/configGUI_ifcIPv4AddressApply
# NAME
#   configGUI_ifcIPv4AddressApply -- configure GUI - interface IPv4 address
#      apply
# SYNOPSIS
#   configGUI_ifcIPv4AddressApply $wi $node $ifc
# FUNCTION
#   Saves changes in the module with IPv4 address.
# INPUTS
#   * wi -- widget
#   * node -- node id
#   * ifc -- interface name
#****
proc configGUI_ifcIPv4AddressApply { wi node ifc } {
    global changed apply
    set ipaddrs [formatIPaddrList [$wi.if$ifc.ipv4.addr get]]
    foreach ipaddr $ipaddrs {
	if { [checkIPv4Net $ipaddr] == 0 } {
	    return
	}
    }
    set oldipaddrs [getIfcIPv4addrs $node $ifc]
    if { $ipaddrs != $oldipaddrs } {
	if {$apply == 1} {
	    setIfcIPv4addrs $node $ifc $ipaddrs
	}
	set changed 1
    }		
}

#****f* nodecfgGUI.tcl/configGUI_ifcIPv6AddressApply
# NAME
#   configGUI_ifcIPv6AddressApply -- configure GUI - interface IPv6 address
#      apply
# SYNOPSIS
#   configGUI_ifcIPv6AddressApply $wi $node $ifc
# FUNCTION
#   Saves changes in the module with IPv6 address.
# INPUTS
#   * wi -- widget
#   * node -- node id
#   * ifc -- interface name
#****
proc configGUI_ifcIPv6AddressApply { wi node ifc } {
    global changed apply
    set ipaddrs [formatIPaddrList [$wi.if$ifc.ipv6.addr get]]
    foreach ipaddr $ipaddrs {
	if { [checkIPv6Net $ipaddr] == 0 } {
	    return
	}
    }
    set oldipaddrs [getIfcIPv6addrs $node $ifc]
    if { $ipaddrs != $oldipaddrs } {
	if {$apply == 1} {
	    setIfcIPv6addrs $node $ifc $ipaddrs
	}
	set changed 1
    }		
}

#****f* nodecfgGUI.tcl/configGUI_ifcDirectionApply
# NAME
#   configGUI_ifcDirectionApply -- configure GUI - interface direction apply
# SYNOPSIS
#   configGUI_ifcDirectionApply $wi $node $ifc
# FUNCTION
#   Saves changes in the module with direction of the interface .
# INPUTS
#   * wi -- widget
#   * node -- node id
#   * ifc -- interface name
#****
proc configGUI_ifcDirectionApply { wi node ifc } {
    global changed apply externalifc
    global [subst ifdirect$ifc]
    set ifdirectstate [subst $[subst ifdirect$ifc]]
    set oldifdirectstate [getIfcDirect $node $ifc]
    if { $ifdirectstate != $oldifdirectstate } {
	if { $ifdirectstate == "external" } {
	    setIfcDirect $node $externalifc "internal"
	}
	set externalifc $ifc
	if {$apply == 1} {
	    setIfcDirect $node $ifc $ifdirectstate
	}
	set changed 1
    }  
}

#****f* nodecfgGUI.tcl/configGUI_ipfirewallRulesetApply
# NAME
#   configGUI_ipfirewallRulesetApply -- configure GUI - ipfirewall rulset apply
# SYNOPSIS
#   configGUI_ipfirewallRulesetApply $wi $node
# FUNCTION
#   Saves changes in the module with ipfw rules.
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_ipfirewallRulesetApply { wi node } {
    global changed
    set i 1
    set error 0
    
    while { 1 } {
      set text [$wi.rules.text get $i.0 $i.end]
      if { $text == "" } {
	  break
      }
      set rule [string range $text 0 end]
      catch { eval exec "ipfw -n $rule" } msg
      if { [string range $msg 0 4] == "ipfw:" } {
	  set error 1
	  set warning "The rule syntax is wrong."
	  tk_messageBox -message $warning -type ok -icon warning \
	      -title "Rule syntax error"
      }
      if { $error == 1 } {
	  break
      }
      incr i
    }
}

#****f* nodecfgGUI.tcl/configGUI_staticRoutesApply
# NAME
#   configGUI_staticRoutesApply -- configure GUI - static routes apply
# SYNOPSIS
#   configGUI_staticRoutesApply $wi $node
# FUNCTION
#   Saves changes in the module with static routes.
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_staticRoutesApply { wi node } {
    global changed 
    set oldIPv4statrts [lsort [getStatIPv4routes $node]]
    set oldIPv6statrts [lsort [getStatIPv6routes $node]]
    set newIPv4statrts {}
    set newIPv6statrts {}

    set routes [$wi.statrts.text get 0.0 end]

    set checkFailed 0
    set checkFailed [checkStaticRoutesSyntax $routes]

    set errline [$wi.statrts.text get $checkFailed.0 $checkFailed.end]

    if { $checkFailed != 0} {
	tk_dialog .dialog1 "IMUNES warning" \
	    "Syntax error in line $checkFailed:
'$errline'" \
	info 0 OK
	return
    }

    set splitRoutes [split $routes "\n"]
    foreach line $splitRoutes {
        set rtentry [split $line " "]
	if { $rtentry == "" } {
	    continue
	}
	set dst [lindex $rtentry 0]
	set gw [lindex $rtentry 1]
	set metric [lindex $rtentry 2]

	if { [checkIPv4Net $dst] == 1 } {
	    lappend newIPv4statrts [string trim "$dst $gw $metric"]
	} else {
	    lappend newIPv6statrts [string trim "$dst $gw $metric"]
	}
    }

    set newIPv4statrts [lsort $newIPv4statrts]
    if { $oldIPv4statrts != $newIPv4statrts } {
	setStatIPv4routes $node $newIPv4statrts
	set changed 1
     }
    set newIPv6statrts [lsort $newIPv6statrts]
    if { $oldIPv6statrts != $newIPv6statrts } {
	setStatIPv6routes $node $newIPv6statrts
	set changed 1
    }
}

#****f* nodecfgGUI.tcl/checkStaticRoutesSyntax 
# NAME
#   checkStaticRoutesSyntax -- check static routes syntax
# SYNOPSIS
#   checkStaticRoutesSyntax $text
# FUNCTION
#   Checks the syntax of a static route.
# INPUTS
#   * text -- routes to check
#****
proc checkStaticRoutesSyntax { text } {
    set text [split $text "\n"]

    set i 0
    foreach line $text {
	incr i
	if {$line == ""} {
	    continue
	}
	set splitLine [split $line " "]
	if {[llength $line] == 3} {
	    set dst [lindex $splitLine 0]
	    set gw [lindex $splitLine 1]
	    set metric [lindex $splitLine 2]
	    if { [string is integer $metric] != 1 || $metric > 65535 } {
		return $i
	    }
	    if { [checkIPv4Net $dst] == 1 } {
		if { [checkIPv4Addr $gw] != 1 } {
		    return $i
		}
	    } elseif { [checkIPv6Net $dst] == 1 } {
		if { [checkIPv6Addr $gw] != 1 } {
		    return $i
		}
	    } else {
		return $i
	    }
	} elseif {[llength $line] == 2} {
	    set dst [lindex $splitLine 0]
	    set gw [lindex $splitLine 1]
	    if { [checkIPv4Net $dst] == 1 } {
		if { [checkIPv4Addr $gw] != 1 } {
		    return $i
		}
	    } elseif { [checkIPv6Net $dst] == 1 } {
		if { [checkIPv6Addr $gw] != 1 } {
		    return $i
		}
	    } else {
		return $i
	    }
	} else {
	    return $i
	}
    }

    return 0
}


#****f* nodecfgGUI.tcl/configGUI_etherVlanApply
# NAME
#   configGUI_etherVlan -- configure GUI - vlan for rj45 nodes
# SYNOPSIS
#   configGUI_etherVlan $wi $node
# FUNCTION
#   Creating module for assigning vlan to rj45 nodes.
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_etherVlanApply { wi node } {
    global changed vlanEnable
    set oldEnabled [getEtherVlanEnabled $node]
    if { $vlanEnable != $oldEnabled } {
	setEtherVlanEnabled $node $vlanEnable
	set changed 1
    }
    set tag [$wi.vlancfg.tag get]
    set oldTag [getEtherVlanTag $node]
    if { $tag != $oldTag } {
	setEtherVlanTag $node $tag
	if { $tag == "" } {
	    set vlanEnable 0
	    setEtherVlanEnabled $node $vlanEnable
	    $wi.vlancfg.tag configure -state disabled
	}
	set changed 1
    }
    if { [getEtherVlanEnabled $node]  && [getEtherVlanTag $node] != "" } {
	set name [getNodeName $node].[getEtherVlanTag $node]
    } else {
	set name [lindex [split [getNodeName $node] .] 0]
    }
    setNodeName $node $name
}

#****f* nodecfgGUI.tcl/configGUI_customConfigApply
# NAME
#   configGUI_customConfigApply -- configure GUI - custom config apply
# SYNOPSIS
#   configGUI_customConfigApply $wi $node
# FUNCTION
#   Saves changes in the module with custom config parameters.
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_customConfigApply { wi node } {
    global changed 
    global customEnabled selectedConfig
    set oldcustomenabled [getCustomEnabled $node]
    if {$oldcustomenabled != $customEnabled} {
        setCustomEnabled $node $customEnabled
	set changed 1
    }
    set oldselectedconfig [getCustomConfigSelected $node]
    if {$oldselectedconfig != $selectedConfig} {
	setCustomConfigSelected $node $selectedConfig
	set changed 1
    }
}

#****f* nodecfgGUI.tcl/configGUI_snapshotsApply
# NAME
#   configGUI_snapshotsApply -- configure GUI - snapshots apply
# SYNOPSIS
#   configGUI_snapshotsApply $wi $node
# FUNCTION
#   Saves changes in the module with ZFS snapshots.
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_snapshotsApply { wi node } {
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    set os [platform::identify]
    global changed snapshot snapshotList
    if { [string match -nocase "*freebsd*" $os] == 1 && \
	[llength [lsearch -inline $snapshotList $snapshot]] == 0} {
    	after idle {.dialog1.msg configure -wraplength 4i}
	tk_dialog .dialog1 "IMUNES error" \
	"Error: ZFS snapshot image \"$snapshot\" for node \"$node\" is missing." \
	info 0 Dismiss
	return
    }
    if { $oper_mode == "edit" && $snapshot != ""} {
        setNodeSnapshot $node $snapshot
    	set changed 1
    }
}

#****f* nodecfgGUI.tcl/configGUI_stpApply
# NAME
#   configGUI_stpApply -- configure GUI - stp apply
# SYNOPSIS
#   configGUI_stpApply $wi $node
# FUNCTION
#   Saves changes in the module with STP.
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_stpApply { wi node } {
    global changed 
    global stpEnabled
    
    set oldStpEnabled [getStpEnabled $node]
    if {$oldStpEnabled != $stpEnabled} {
	setStpEnabled $node $stpEnabled
	set changed 1
    }
}

#****f* nodecfgGUI.tcl/configGUI_routingModelApply
# NAME
#   configGUI_routingModelApply -- configure GUI - routing model apply
# SYNOPSIS
#   configGUI_routingModelApply $wi $node
# FUNCTION
#   Saves changes in the module with routing model and protocols.
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_routingModelApply { wi node } {
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    global router_ConfigModel
    global ripEnable ripngEnable ospfEnable ospf6Enable
    if { $oper_mode == "edit"} {
        setNodeModel $node $router_ConfigModel	    
	if { $router_ConfigModel != "static" } {
	    setNodeProtocolRip $node $ripEnable
	    setNodeProtocolRipng $node $ripngEnable
	    setNodeProtocolOspfv2 $node $ospfEnable
	    setNodeProtocolOspfv3 $node $ospf6Enable
	} else {
	    $wi.routing.protocols.rip configure -state disabled
	    $wi.routing.protocols.ripng configure -state disabled
	    $wi.routing.protocols.ospf configure -state disabled
            $wi.routing.protocols.ospf6 configure -state disabled
	}
    set changed 1
    } 
}

#****f* nodecfgGUI.tcl/configGUI_servicesConfigApply
# NAME
#   configGUI_servicesConfigApply -- configure GUI - services config apply
# SYNOPSIS
#   configGUI_servicesConfigApply $wi $node
# FUNCTION
#   Saves changes in the module with setvices.
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_servicesConfigApply { wi node } {
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    global all_services_list
    if { $oper_mode == "edit"} {
	set serviceList ""
	foreach srv $all_services_list {
	    global $srv\_enable
	    if { [set $srv\_enable] } {
		lappend serviceList $srv
	    }
	}
	if { [getNodeServices $node] != $serviceList } {
	    setNodeServices $node $serviceList
	    set changed 1
	}
    } 
}

#****f* nodecfgGUI.tcl/configGUI_cpuConfigApply
# NAME
#   configGUI_cpuConfigApply -- configure GUI - CPU configuration apply
# SYNOPSIS
#   configGUI_cpuConfigApply $wi $node
# FUNCTION
#   Saves changes in the module with CPU configuration parameters.
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_cpuConfigApply { wi node } {
    set oldcpuconf [getNodeCPUConf $node]
    set newcpuconf {}
    set cpumin [$wi.cpucfg.minvalue get]
    set cpumax [$wi.cpucfg.maxvalue get]
    set cpuweight [$wi.cpucfg.weightvalue get]
    if { $cpumin != "" } {
	lappend newcpuconf "min $cpumin"
    }
    if { $cpumax != "" } {
	lappend newcpuconf "max $cpumax"
    }
    if { $cpuweight != "" } {
        lappend newcpuconf "weight $cpuweight"
    }
    if { $oldcpuconf != $newcpuconf } {
	setNodeCPUConf $node [list $newcpuconf]
	set changed 1
    }
}

#****f* nodecfgGUI.tcl/configGUI_cloudConfigApply
# NAME
#   configGUI_cloudConfigApply -- configure GUI - cloud configuration apply
# SYNOPSIS
#   configGUI_cloudConfigApply $wi $node
# FUNCTION
#   Saves changes in the module with cloud configuration parameters.
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_cloudConfigApply { wi node } {
    set cloud_parts [$wi.cloudpart.label.num get]
    puts $cloud_parts 
    setCloudParts $node $cloud_parts
}

#****f* nodecfgGUI.tcl/configGUI_ifcVlanConfigApply
# NAME
#   configGUI_ifcVlanConfigApply -- configure GUI - interface Vlan
#      configuration apply
# SYNOPSIS
#   configGUI_ifcVlanConfigApply $wi $node $ifc
# FUNCTION
#   Saves changes in the module with Vlan configuration parameters.
# INPUTS
#   * wi -- widget
#   * node -- node id
#   * ifc -- interface name
#****
proc configGUI_ifcVlanConfigApply { wi node ifc } {
    global changed apply
    set vlandev [string trim [$wi.if$ifc.vlancfg.dev get]]
    set oldvlandev [getIfcVlanDev $node $ifc]
    if { $vlandev != $oldvlandev } {
	if {$apply == 1} {
	    setIfcVlanDev $node $ifc $vlandev
	}
	set changed 1
    }
    set vlantag [string trim [$wi.if$ifc.vlancfg.tag get]]
    set oldvlantag [getIfcVlanTag $node $ifc]
    if { $vlantag != $oldvlantag } {
	if {$apply == 1} {
	    setIfcVlanTag $node $ifc $vlantag
	}
	set changed 1
    }
}

#############Custom startup configuration#############

#****f* nodecfgGUI.tcl/customConfigGUI
# NAME
#   customConfigGUI -- custom config GUI
# SYNOPSIS
#   customConfigGUI $node
# FUNCTION
#   For input node this procedure opens a new window and editor for editing
#   custom configurations
# INPUTS
#   * node -- node id
#****
proc customConfigGUI { node } {
    set wi .cfgEditor
    set o $wi.options
    set b $wi.bottom.buttons

    tk::toplevel $wi
    grab $wi
    wm title $wi "Custom configurations $node"
    wm minsize $wi 584 445
    wm resizable $wi 0 1

    ttk::frame $wi.options -height 50 -borderwidth 3
    ttk::notebook $wi.nb -height 200
    ttk::frame $wi.bottom
    ttk::frame $wi.bottom.buttons -borderwidth 2

    ttk::label $o.l -text "Create new configuration:"
    ttk::entry $o.e -width 24
    ttk::button $o.b -text "Create" \
	-command "createNewConfiguration $wi $node"
    ttk::label $o.ld -text "Default configuration:"
    ttk::combobox $o.cb -height 10 -width 22 -state readonly \
	-textvariable defaultConfig
    $o.cb configure -values [getCustomConfigIDs $node]
    $o.cb set [getCustomConfigSelected $node]
    
    ttk::button $b.apply -text "Apply" \
	-command "customConfigGUI_Apply $wi $node"
    ttk::button $b.applyClose -text "Apply and Close" \
	-command "customConfigGUI_Apply $wi $node; destroy $wi"
    ttk::button $b.cancel -text "Cancel" -command "destroy $wi"

    pack $wi.options -side top -fill both
    pack $wi.nb -fill both -expand 1
    pack $wi.bottom.buttons -pady 2
    pack $wi.bottom -fill both -side bottom

    grid $o.l -row 0 -column 0 -sticky w
    grid $o.e -row 0 -column 1 -sticky w -padx 5 -sticky we
    grid $o.b -row 0 -column 2 -padx 5
    grid $o.ld -row 1 -column 0 -sticky w
    grid $o.cb -row 1 -column 1 -sticky we -padx 5

    grid $b.apply -row 0 -column 1 -sticky swe -padx 2
    grid $b.applyClose -row 0 -column 2 -sticky swe -padx 2
    grid $b.cancel -row 0 -column 4 -sticky swe -padx 2
    
    foreach cfgID [lsort [getCustomConfigIDs $node]] {
	createTab $node $cfgID
    }
}

#****f* nodecfgGUI.tcl/customConfigGUI_Apply
# NAME
#   customConfigGUI_Apply -- custom config GUI apply
# SYNOPSIS
#   customConfigGUI node
# FUNCTION
#   For input node this procedure opens a new window and editor for editing
#   custom configurations
# INPUTS
#   * node -- node id
#****
proc customConfigGUI_Apply { wi node } {
    set o $wi.options
    if { [$wi.nb tabs] != "" } {
	set t $wi.nb.[$wi.nb tab current -text]
	set cfgID [$t.confid_e get]
	if {[$t.confid_e get] != [$wi.nb tab current -text]} {
	    removeCustomConfig $node [$wi.nb tab current -text]
	    setCustomConfig $node [$t.confid_e get] \
		[$t.bootcmd_e get] [$t.editor get 1.0 {end -1c}]
	    destroy $t
	    createTab $node $cfgID
	} else {		
	    setCustomConfig $node [$t.confid_e get] \
		[$t.bootcmd_e get] [$t.editor get 1.0 {end -1c}]
	}
	if {[getCustomConfigSelected $node] ni \
	    [getCustomConfigIDs $node]} {
	    setCustomConfigSelected $node "" 
	}
	set defaultConfig [$wi.options.cb get]
	if { [llength [getCustomConfigIDs $node]] == 1 && \
		$defaultConfig == "" } {
	    set config [lindex [getCustomConfigIDs $node] 0] 
	    setCustomConfigSelected $node $config
	    $wi.options.cb set $config
	    .popup.nbook.nfConfiguration.custcfg.dcomboDefault set \
		$config
	} else {
	    setCustomConfigSelected $node $defaultConfig
	    .popup.nbook.nfConfiguration.custcfg.dcomboDefault set \
		$defaultConfig
	}
	$o.cb configure -values [getCustomConfigIDs $node]
	.popup.nbook.nfConfiguration.custcfg.dcomboDefault \
	    configure -values [getCustomConfigIDs $node]
    }
}
	
#****f* nodecfgGUI.tcl/createTab
# NAME
#   createTab -- create custom config tab in GUI
# SYNOPSIS
#   createTab $node $cfgID
# FUNCTION
#   For input node and custom configuration ID this procedure opens a new tab
#   in editor for editing custom configuration.
# INPUTS
#   * node -- node id
#   * cfgID -- configuration id
#****
proc createTab { node cfgID } {
    set wi .cfgEditor
    set o $wi.options
    set w $wi.nb.$cfgID
    set node_id $node

    ttk::frame $wi.nb.$cfgID 
    ttk::label $w.confid_l -text "Configuration ID:" -width 15
    ttk::entry $w.confid_e -width 25
    ttk::label $w.bootcmd_l -text "Boot command:" -width 15
    ttk::entry $w.bootcmd_e -width 25
    ttk::button $w.delete -text "Delete config" \
	-command "deleteConfig $wi $node"
    ttk::button $w.generate -text "Fill defaults" \
	-command "customConfigGUIFillDefaults $wi $node"
    ttk::scrollbar $w.vsb -orient vertical -command [list $w.editor yview]
    ttk::scrollbar $w.hsb -orient horizontal -command [list $w.editor xview]
    text $w.editor  -width 80 -height 20 -bg white -wrap none \
	-yscrollcommand [list $w.vsb set] -xscrollcommand [list $w.hsb set]

    $o.cb configure -values [getCustomConfigIDs $node]
    .popup.nbook.nfConfiguration.custcfg.dcomboDefault \
	configure -values [getCustomConfigIDs $node]
    $wi.nb add $wi.nb.$cfgID -text $cfgID
    $w.confid_e insert 0 $cfgID
    $w.bootcmd_e insert 0 [getCustomConfigCommand $node $cfgID]
    set config [getCustomConfig $node $cfgID]
    foreach data $config {
	$w.editor insert end "$data\n"
    }
    
    grid $w.confid_l -row 0 -column 0 -in $w -sticky w -pady 3
    grid $w.confid_e -row 0 -column 1 -in $w -sticky w -pady 3
    grid $w.generate -row 0 -column 2 -rowspan 2 -in $w
    grid $w.delete -row 0 -column 3 -rowspan 2 -in $w
    grid $w.bootcmd_l -row 1 -column 0 -in $w  -sticky w -pady 2
    grid $w.bootcmd_e -row 1 -column 1 -in $w -sticky w -pady 2
    grid $w.editor $w.vsb -in $w -columnspan 5 \
	-sticky nsew
    grid $w.hsb -in $w -sticky nsew -columnspan 5
    grid rowconfigure $w $w.editor -weight 10
    grid columnconfigure $w $w.editor -weight 10
    $wi.nb select $wi.nb.$cfgID
}

#****f* nodecfgGUI.tcl/customConfigGUIFillDefaults
# NAME
#   customConfigGUIFillDefaults -- custom config GUI fill default values
# SYNOPSIS
#   customConfigGUIFillDefaults $wi $node
# FUNCTION
#   For the current node and custom configuration fills in the default values
#   that are generated with cfggen and bootcmd commands for nodes.
# INPUTS
#   * wi -- current widget
#   * node -- node id
#****
proc customConfigGUIFillDefaults { wi node } {
    set cfgID [$wi.nb tab current -text]
    set cmd [[typemodel $node].bootcmd $node]
    set cfg [[typemodel $node].cfggen $node]
    set w $wi.nb.$cfgID

    if { [$w.bootcmd_e get] != "" || [$w.editor get 1.0 {end -1c}] != "" } {
	set answer [tk_messageBox -message \
	    "Do you want to overwrite current values?" \
	    -icon warning -type yesno ]
	switch -- $answer {
	    yes {
		$w.editor delete 0.0 end
		foreach line $cfg {
		    $w.editor insert end "$line\n"
		}
		$w.bootcmd_e delete 0 end
		$w.bootcmd_e insert 0 $cmd
	    }
	    no {}
	}
    } else {
	$w.editor delete 0.0 end
	foreach line $cfg {
	    $w.editor insert end "$line\n"
	}
	$w.bootcmd_e delete 0 end
	$w.bootcmd_e insert 0 $cmd
    }
}

#****f* nodecfgGUI.tcl/deleteConfig
# NAME
#   deleteConfig -- delete custom config and destroys tab from editor
# SYNOPSIS
#   deleteConfig $node $cfgID
# FUNCTION
#   For input node and custom configuration ID this procedure deletes custom
#   configuration and destroys a tab in editor for editing custom
#   configuration.
# INPUTS
#   * node -- node id
#   * cfgID -- configuration id
#****
proc deleteConfig { wi node } {
    set cfgID [$wi.nb tab current -text]
    set answer [tk_messageBox -message \
	"Are you sure you want to delete custom config '$cfgID'?" \
	-icon warning -type yesno ]
    switch -- $answer {
	yes {
	    destroy $wi.nb.$cfgID 
	    removeCustomConfig $node $cfgID
	    if { $cfgID == [getCustomConfigSelected $node]} {
		setCustomConfigSelected $node ""
		$wi.options.cb set ""
		.popup.nbook.nfConfiguration.custcfg.dcomboDefault set ""
	    }
	    $wi.options.cb configure -values \
		[getCustomConfigIDs $node]
	    .popup.nbook.nfConfiguration.custcfg.dcomboDefault \
		configure -values [getCustomConfigIDs $node]
	    if {!([getCustomConfigSelected $node] in \
		[getCustomConfigIDs $node])} {
		setCustomConfigSelected $node \
		    [lindex [getCustomConfigIDs $node] 0]
	    }
	}
	no {}
    }
}

#****f* nodecfgGUI.tcl/createNewConfiguration
# NAME
#   createNewConfiguration -- create new custom config and tab
# SYNOPSIS
#   createNewConfiguration $node $cfgID
# FUNCTION
#   For input node and custom configuration ID this procedure, if possible,
#   creates a new tab in editor for editing custom configuration.
# INPUTS
#   * node -- node id
#   * cfgName -- configuration id
#****
proc createNewConfiguration { wi node } {
    set cfgName [string trim [$wi.options.e get]]
    if {"$wi.nb.$cfgName" in [$wi.nb tabs] || $cfgName == ""}  {
	return
    }
    set cfgName [string tolower $cfgName 0 0]
    if {$cfgName in [getCustomConfigIDs $node]} {
	tk_messageBox -message "Configuration already exits, use another name!"\
	    -icon warning
	focus $wi.options.e
    } else {
	createTab $node $cfgName
	$wi.options.e delete 0 end
    }
}

#****f* nodecfgGUI.tcl/formatIPaddrList
# NAME
#   formatIPaddrList -- change the IP address list format
# SYNOPSIS
#   formatIPaddrList $addrList
# FUNCTION
#   Change the IP address list format from the one displayed in the GUI to a
#   list format that is used internally.
# INPUTS
#   * addrList -- address list in GUI format
# RESULT
#   * value -- address list in internal format.
#****
proc formatIPaddrList { addrList } {
    set newList {}
    foreach addr [split $addrList ";"] {
	set ipaddr [string trim $addr]
	if { $ipaddr != "" } {
	    lappend newList $ipaddr
	}
    }
    return $newList
}
