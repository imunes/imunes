# 2019-2020 Sorbonne University
# In this version of imunes we added a full integration of emulation of 
# Linux namespaces and CISCO routers, saving of parameters, VLANs, WiFi 
# emulation and other features
# This work was developed by Benadji Hanane and Oulad Said Chawki
# Supervised and maintained by Naceur Malouch - LIP6/SU
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

global old_conn_name bridgeProtocol brguielements selectedFilterRule \
    selectedPackgenPacket router_ConfigModel

set old_conn_name ""
set bridgeProtocol rstp
set brguielements {}
set selectedFilterRule ""
set selectedPackgenPacket ""
set router_ConfigModel "quagga"

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
    global wi debug
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
	if { !$debug } {
	    grab $wi
	}
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
            #100 au lieu 155
            	set type [nodeType $node]
   			if {$type == "lanswitch"} {
    				$wi.panwin.f1.tree column [lindex $column 0] -width 155 \
					-minwidth 2 -anchor center -stretch 0
			} else {
	    			$wi.panwin.f1.tree column [lindex $column 0] -width 100 \
					-minwidth 2 -anchor center -stretch 0
		               }
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

#Modification for namespace
    if {( [[typemodel $node].virtlayer] == "VIMAGE" || [[typemodel $node].virtlayer] == "NAMESPACE" || [[typemodel $node].virtlayer] == "WIFIAP" ) && [nodeType $node] != "click_l2"} {
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
    if {[[typemodel $node].virtlayer] == "VIMAGE" || [[typemodel $node].virtlayer] == "NAMESPACE" || [[typemodel $node].virtlayer] == "WIFIAP" } {
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

    if {[[typemodel $node].virtlayer] == "VIMAGE" || [[typemodel $node].virtlayer] == "NAMESPACE" || [[typemodel $node].virtlayer] == "WIFIAP"} {

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

   # $wi tag bind interfaces <1> \
#	    "configGUI_showIfcInfo $wi_bind.panwin.f2 0 $node \"\""
 #   $wi tag bind interfaces <Key-Down> \
#	    "if {[llength [ifcList $node]] != 0} {

#		configGUI_showIfcInfo $wi_bind.panwin.f2 0 $node [lindex [lsort -ascii [ifcList $node]] 0]

#	    }"

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
# modification for VLAN
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

                 # modification for VLAN

		if {$type == "lanswitch"} {
		#logical interfaces
		configGUI_ifcMainFrame $wi $node $ifc
		logical.configInterfacesGUI $wi $node $ifc
		set wi1 [string trimright $wi ".f2"]
		set h [winfo height $wi1]
		set pos [expr $h-10]

		$wi1 sashpos 0 "130"

                } else {

		#logical interfaces
		configGUI_ifcMainFrame $wi $node $ifc
		logical.configInterfacesGUI $wi $node $ifc
		set wi1 [string trimright $wi ".f2"]
		set h [winfo height $wi1]
		set pos [expr $h-160]
		$wi1 sashpos 0 $pos

                }

	    } elseif { $ifc != "logIfcFrame" } {

                # modification for VLAN
		if {$type == "lanswitch"} {

             
		#physical interfaces
		configGUI_ifcMainFrame $wi $node $ifc
		$type.configInterfacesGUI $wi $node $ifc
		set wi1 [string trimright $wi ".f2"]
		set h [winfo height $wi1]
		set pos [expr $h-10]
                $wi1 sashpos 0 "130"

		} else {
		#physical interfaces
		configGUI_ifcMainFrame $wi $node $ifc
		$type.configInterfacesGUI $wi $node $ifc
		set wi1 [string trimright $wi ".f2"]
		set h [winfo height $wi1]
		set pos [expr $h-160]
		$wi1 sashpos 0 $pos
		}



	    } else {

		#manage logical interfaces

		configGUI_logicalInterfaces $wi $node $ifc
		set wi1 [string trimright $wi ".f2"]
		set h [winfo height $wi1]
		set pos [expr $h-100]
		$wi1 sashpos 0 $pos

	    }
	} else {
# modification for VLAN

		if {$type == "lanswitch"} {
		set wi1 [string trimright $wi ".f2"]
		set h [winfo height $wi1]
		set pos [expr $h-160]
		$wi1 sashpos 0 "130"

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
 #Modification for vlan
    global eidvlan modevlan

 #********************


#Modification for Vlan
             if {$eidvlan != "" && $modevlan == "exec"} {
	         set typelanswitch [nodeType $node]

		if {$typelanswitch =="lanswitch"} {

   			configureVlanSwitch $eidvlan $node 
		}
            }
#Modification for Wifi
 if {[[typemodel $node].virtlayer] == "WIFIAP"} {

configFichier_AP $node
}

 if {[[typemodel $node].virtlayer] == "WIFISTA"} {

configFichier_STA $node
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

	} elseif { $guielement == "configGUI_ipsec" } {

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
# modification for VLAN
proc configGUI_ifcQueueConfig { wi node ifc } {
    global guielements
    lappend guielements "configGUI_ifcQueueConfig $ifc"
    global ifqdisc$ifc ifqdrop$ifc 
    set ifqdisc$ifc [getIfcQDisc $node $ifc]
    set ifqdrop$ifc [getIfcQDrop $node $ifc]
    
    global enableVlan tagVlan modeVlan rangeVlan interfaceVlan treecolumns Vlancolumns 
    global listVlan applyVlan ShowVlan DeleteVlan
    set DeleteVlan 0
    set ShowVlan 0
    set applyVlan 0
    set deleteVlan 0
    set enableVlan 0
    set tagVlan ""
    set modeVlan ""
    set rangeVlan ""
    set interfaceVlan ""
   


    ttk::frame $wi.if$ifc.queuecfg -borderwidth 2 -padding 4
    ttk::label $wi.if$ifc.queuecfg.txt1 -text "Queue" -anchor w
    ttk::combobox $wi.if$ifc.queuecfg.disc -width 5 -textvariable ifqdisc$ifc
    $wi.if$ifc.queuecfg.disc configure -values [list FIFO DRR WFQ]
    ttk::combobox $wi.if$ifc.queuecfg.drop -width 8 -textvariable ifqdrop$ifc
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


  #VLAN Options
    set type [nodeType $node]

if { $type == "lanswitch"} {

    #ttk::frame $wi.if$ifc.queuecfg1 -borderwidth 2 -padding 4
   
    #ttk::button $wi.if$ifc.queuecfg1.beditor -width 14  -text "Advanced options" \
	#-command "VlanOptions $node $wi.if$ifc"


    #pack $wi.if$ifc.queuecfg1.beditor -side left
  
    #pack $wi.if$ifc.queuecfg1 -fill both


    ttk::frame $wi.if$ifc.queuecfg2 -borderwidth 2 -padding 4
    ttk::checkbutton $wi.if$ifc.queuecfg2.enable -text "Enable VLAN" -variable ::enableVlan \
    -command "VlanOptions $node $wi.if$ifc $ifc"
    
    pack $wi.if$ifc.queuecfg2.enable -side left
  
    pack $wi.if$ifc.queuecfg2 -fill both

    ttk::frame $wi.if$ifc.queuecfg3 -borderwidth 2 -padding 4
    ttk::label $wi.if$ifc.queuecfg3.tagtxt -text "VLAN Tag:"  
    ttk::spinbox $wi.if$ifc.queuecfg3.tag -width 6 -validate focus \
	-invalidcommand "focusAndFlash %W" 
    $wi.if$ifc.queuecfg3.tag configure \
	-validatecommand {checkIntRange %P 1 4094} \
	-from 1 -to 4094 -increment 1 -textvariable tagVlan \

    ttk::label $wi.if$ifc.queuecfg3.modetxt -text "VLAN mode:" 
    ttk::combobox $wi.if$ifc.queuecfg3.mode -width 13 -textvariable modeVlan
    $wi.if$ifc.queuecfg3.mode configure -values [list access trunk native-tagged native-untagged dot1q-tunnel] 

   # ttk::frame $wi.if$ifc.queuecfg4 -borderwidth 2 -padding 4
    ttk::label $wi.if$ifc.queuecfg3.interfacetxt -text "Interface type:" 
    ttk::combobox $wi.if$ifc.queuecfg3.interface -width 10 -textvariable interfaceVlan
    $wi.if$ifc.queuecfg3.interface configure -values [list system internal tap geneve gre ipsec-gre gre64 ipsec-gre64 vxlan lisp patch]     

    ttk::frame $wi.if$ifc.queuecfg5 -borderwidth 2 -padding 4
    ttk::label $wi.if$ifc.queuecfg5.rangetxt -text "Allowed VLAN range:" 
    ttk::entry $wi.if$ifc.queuecfg5.range -width 25 -textvariable rangeVlan

    ttk::frame $wi.if$ifc.queuecfg6 -borderwidth 2 -padding 4
    ttk::frame $wi.if$ifc.queuecfg6.button 
    ttk::button $wi.if$ifc.queuecfg6.button.apply -text "Add VLAN" -command \
        "set applyVlan 1; configVlan_Switch $node $ifc"
    ttk::button $wi.if$ifc.queuecfg6.button.delete -text "Delete All VLAN" -command \
        "set DeleteVlan 1; DeleteVlan_Switch $node $wi.if$ifc $ifc"
    ttk::button $wi.if$ifc.queuecfg6.button.cancel -text "Show All VLAN" -command \
        "set ShowVlan 1; ShowVlan_Switch $node $wi.if$ifc $ifc"

#Remplissage des champs

lappend listVlan ""
foreach element $listVlan {

               set name [lindex $element 0]
               set enable [lindex $element 1]
			if { "$node-$ifc" == $name && $enable == 1 } {
                                
				set enableVlan [lindex $element 1]
		        set modeVlan [lindex $element 3]
				set tagVlan [lindex $element 2]
				set interfaceVlan [lindex $element 4]
				set rangeVlan [lindex $$element 5]	
        
          			pack $wi.if$ifc.queuecfg3.tagtxt -side left -padx 2 
        			pack $wi.if$ifc.queuecfg3.tag -side left -padx 4 -pady 4
        			pack $wi.if$ifc.queuecfg3.modetxt -side left -padx 2
        			pack $wi.if$ifc.queuecfg3.mode -side left -padx 4 -pady 4
    				pack $wi.if$ifc.queuecfg3 -fill both

        			pack $wi.if$ifc.queuecfg5.rangetxt -side left -padx 2
        			pack $wi.if$ifc.queuecfg5.range -side left -padx 4 -pady 4
        			pack $wi.if$ifc.queuecfg5 -fill both

        			pack $wi.if$ifc.queuecfg3.interfacetxt -side left -padx 2
        			pack $wi.if$ifc.queuecfg3.interface -side left -padx 4 -pady 4
        			pack $wi.if$ifc.queuecfg3 -fill both

        			pack $wi.if$ifc.queuecfg6.button.apply \
        				$wi.if$ifc.queuecfg6.button.cancel -side left -padx 2

        			pack $wi.if$ifc.queuecfg6.button -pady 2 -expand 1
        			pack $wi.if$ifc.queuecfg6 -fill both -side bottom

			}

}

#TreeView 

  
    ttk::frame $wi.if$ifc.queuecfg7
    ttk::treeview $wi.if$ifc.tab -height 5 -selectmode browse \
	-xscrollcommand "$wi.if$ifc.hscroll set"\
	-yscrollcommand "$wi.if$ifc.vscroll set" \

    ttk::scrollbar $wi.if$ifc.hscroll -orient horizontal -command "$wi.if$ifc.tab xview"
    ttk::scrollbar $wi.if$ifc.vscroll -orient vertical -command "$wi.if$ifc.tab yview"

  set column_ids ""
   foreach column $Vlancolumns {
	lappend columns_ids [lindex $column 0]
    }

    #Creating columns 
    $wi.if$ifc.tab configure -columns $columns_ids
 

 $wi.if$ifc.tab column #0 -width 130 -minwidth 70 -stretch 0
    

       foreach column $columns_ids {
        
	if { [lindex $column 0] == "VlanTag" } {
	    $wi.if$ifc.tab column [lindex $column 0] -width 70 \
		-minwidth 2 -anchor center -stretch 0 
	} elseif { [lindex $column 0] == "VlanMode" || [lindex $column 0] == "InterfaceType" } {
            $wi.if$ifc.tab column [lindex $column 0] -width 110 \
		-minwidth 2 -anchor center -stretch 0
        } else {
	    $wi.if$ifc.tab column [lindex $column 0] -width 163 \
		-minwidth 2 -anchor center -stretch 0
	}
      	    $wi.if$ifc.tab heading [lindex $column 0] \
	    -text [lindex $column 0]
	
    }
   
   
 

}

      

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
    set addrs [string trim $addrs "; "]
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
    set addrs [string trim $addrs "; "]
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
    global guielements snapshot snapshotList isOSfreebsd
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

    if { $oper_mode != "edit" || !$isOSfreebsd } {
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
    set w $wi.routing
    ttk::frame $w.model -padding 2
    ttk::label $w.model.label -text "Model:"
    ttk::frame $w.protocols -padding 2
    ttk::label $w.protocols.label -text "Protocols:"

    ttk::checkbutton $w.protocols.rip -text "rip" -variable ripEnable
    ttk::checkbutton $w.protocols.ripng -text "ripng" -variable ripngEnable
    ttk::checkbutton $w.protocols.ospf -text "ospfv2" -variable ospfEnable
    ttk::checkbutton $w.protocols.ospf6 -text "ospfv3" -variable ospf6Enable
    ttk::radiobutton $w.model.quagga -text quagga \
	-variable router_ConfigModel -value quagga -command \
	"$w.protocols.rip configure -state normal;
	 $w.protocols.ripng configure -state normal;
	 $w.protocols.ospf configure -state normal;
	 $w.protocols.ospf6 configure -state normal"
    ttk::radiobutton $w.model.xorp -text xorp \
	-variable router_ConfigModel -value xorp -command \
	"$w.protocols.rip configure -state normal;
	 $w.protocols.ripng configure -state normal;
	 $w.protocols.ospf configure -state normal;
	 $w.protocols.ospf6 configure -state normal"
    ttk::radiobutton $w.model.static -text static \
	-variable router_ConfigModel -value static -command \
	"$w.protocols.rip configure -state disabled;
	 $w.protocols.ripng configure -state disabled;
	 $w.protocols.ospf configure -state disabled;
	 $w.protocols.ospf6 configure -state disabled"

    set router_ConfigModel [getNodeModel $node]
    if { $router_ConfigModel != "static" } {
        set ripEnable [getNodeProtocolRip $node]
	set ripngEnable [getNodeProtocolRipng $node]
	set ospfEnable [getNodeProtocolOspfv2 $node]
	set ospf6Enable [getNodeProtocolOspfv3 $node]
    } else {
        $w.protocols.rip configure -state disabled
	$w.protocols.ripng configure -state disabled
 	$w.protocols.ospf configure -state disabled
 	$w.protocols.ospf6 configure -state disabled
    }
    if { $oper_mode != "edit" } {
	$w.model.quagga configure -state disabled
	$w.model.xorp configure -state disabled
	$w.model.static configure -state disabled
	$w.protocols.rip configure -state disabled
	$w.protocols.ripng configure -state disabled
	$w.protocols.ospf configure -state disabled
	$w.protocols.ospf6 configure -state disabled
    }
    if {"xorp" ni $supp_router_models} {
	$w.model.xorp configure -state disabled
    }
    pack $w.model.label -side left -padx 2
    pack $w.model.quagga $w.model.xorp $w.model.static \
        -side left -padx 6
    pack $w.model -fill both -expand 1
    pack $w.protocols.label -side left -padx 2
    pack $w.protocols.rip $w.protocols.ripng \
	$w.protocols.ospf $w.protocols.ospf6 -side left -padx 6
    pack $w.protocols -fill both -expand 1
    pack $w -fill both
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

#****f* nodecfgGUI.tcl/configGUI_attachDockerToExt
# NAME
#   configGUI_attachDockerToExt -- configure GUI - attach external docker ifc
# SYNOPSIS
#   configGUI_attachDockerToExt $wi $node
# FUNCTION
#   Creating module for attaching external docker interface to virtual nodes on
#   Linux.
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_attachDockerToExt { wi node } {
    global isOSlinux

    if { !$isOSlinux } {
	return
    }

    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    global guielements docker_enable
    lappend guielements configGUI_attachDockerToExt

    set docker_enable [string map {true 1 false 0} [getNodeDockerAttach $node]]

    set w $wi.docker
    ttk::frame $w -relief groove -borderwidth 2 -padding 2
    ttk::label $w.label -text "Attach external docker interface:"

    pack $w.label -side left -padx 2

    if { $oper_mode == "edit" } {
	ttk::checkbutton $w.chkbox -text "Enabled" -variable docker_enable
    } else {
	ttk::checkbutton $w.chkbox -text "Enabled" -variable docker_enable \
	    -state disabled
    }
    pack $w.chkbox -side left -padx 7

    pack $w -fill both
}

#****f* nodecfgGUI.tcl/configGUI_dockerImage
# NAME
#   configGUI_dockerImage -- configure GUI - use different Docker image
# SYNOPSIS
#   configGUI_dockerImage $wi $node
# FUNCTION
#   Creating module for using different docker images for  virtual nodes
#   on Linux.
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_dockerImage { wi node } {
    global VROOT_MASTER isOSlinux

    if { !$isOSlinux } {
	return
    }

    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    global guielements
    lappend guielements configGUI_dockerImage

    set docker_image [getNodeDockerImage $node]
   
    set w $wi.dockerImg
    ttk::frame $w -relief groove -borderwidth 2 -padding 2
    ttk::label $w.label -text "Docker image:"

    pack $w.label -side left -padx 2

    ttk::entry $w.img -width 40
    $w.img insert 0 $docker_image
    pack $w.img -side left -padx 7

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
    ttk::label $wi.if$ifc.vlancfg.tagtxt -text "Vlan tag" 
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

#****f* nodecfgGUI.tcl/configGUI_externalIfcs
# NAME
#   configGUI_externalIfcs -- configure GUI - vlan for rj45 nodes
# SYNOPSIS
#   configGUI_externalIfcs $wi $node
# FUNCTION
#   Creating module for assigning vlan to rj45 nodes.
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_externalIfcs { wi node } {
    global guielements vlanEnable
    lappend guielements configGUI_externalIfcs
    set ifc [lindex [split [ifcList $node] .] 0]

    ttk::frame $wi.if$ifc -borderwidth 2 -relief groove
    ttk::frame $wi.if$ifc.mac
    ttk::frame $wi.if$ifc.ipv4
    ttk::frame $wi.if$ifc.ipv6

    ttk::label $wi.if$ifc.labelName -text "Interface $ifc"
    ttk::label $wi.if$ifc.labelMAC -text "MAC address:" -width 11
    ttk::entry $wi.if$ifc.mac.addr -width 24 -validate focus
    $wi.if$ifc.mac.addr insert 0 [getIfcMACaddr $node $ifc]
    ttk::label $wi.if$ifc.labelIPv4 -text "IPv4 address:" -width 11
    ttk::entry $wi.if$ifc.ipv4.addr -width 24 -validate focus
    $wi.if$ifc.ipv4.addr insert 0 [getIfcIPv4addr $node $ifc]
    ttk::label $wi.if$ifc.labelIPv6 -text "IPv6 address:" -width 11
    ttk::entry $wi.if$ifc.ipv6.addr -width 24 -validate focus
    $wi.if$ifc.ipv6.addr insert 0 [getIfcIPv6addr $node $ifc]

    pack $wi.if$ifc -expand 1 -padx 1 -pady 1
    grid $wi.if$ifc.labelName -in $wi.if$ifc -columnspan 2 -row 0 -pady 4 -padx 4
    grid $wi.if$ifc.labelMAC -in $wi.if$ifc -column 0 -row 1 -pady 4 -padx 4
    grid $wi.if$ifc.mac -in $wi.if$ifc -column 1 -row 1 -pady 4 -padx 4
    grid $wi.if$ifc.mac.addr -in $wi.if$ifc.mac -column 0 -row 0
    grid $wi.if$ifc.labelIPv4 -in $wi.if$ifc -column 0 -row 2 -pady 4 -padx 4
    grid $wi.if$ifc.ipv4 -in $wi.if$ifc -column 1 -row 2 -pady 4 -padx 4
    grid $wi.if$ifc.ipv4.addr -in $wi.if$ifc.ipv4 -column 0 -row 0
    grid $wi.if$ifc.labelIPv6 -in $wi.if$ifc -column 0 -row 3 -pady 4 -padx 4
    grid $wi.if$ifc.ipv6 -in $wi.if$ifc -column 1 -row 3 -pady 4 -padx 4
    grid $wi.if$ifc.ipv6.addr -in $wi.if$ifc.ipv6 -column 0 -row 0
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
    global changed badentry showTree eid_base isOSlinux

    set name [string trim [$wi.name.nodename get]]
    if { [regexp {^[A-Za-z_][0-9A-Za-z_-]*$} $name ] == 0 } {
	tk_dialog .dialog1 "IMUNES warning" \
	    "Hostname should contain only letters, digits, _, and -, and should not start with - (hyphen) or number." \
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
    global changed snapshot snapshotList isOSfreebsd
    if { [llength [lsearch -inline $snapshotList $snapshot]] == 0 &&
	$isOSfreebsd } {
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
	if { [nodeType $node] != "nat64" } {
	    setNodeModel $node $router_ConfigModel
	}
	if { $router_ConfigModel != "static" } {
	    setNodeProtocolRip $node $ripEnable
	    setNodeProtocolRipng $node $ripngEnable
	    setNodeProtocolOspfv2 $node $ospfEnable
	    setNodeProtocolOspfv3 $node $ospf6Enable
	    if { [nodeType $node] == "nat64" } {
		foreach proto { rip ripng ospf ospf6 bgp } {
		    set protocfg [netconfFetchSection $node "router $proto"]
		    if { $protocfg != "" } {
			set protocfg [linsert $protocfg 0 "router $proto"]
			set protocfg [linsert $protocfg end "!"]
			set protocfg [linsert $protocfg [lsearch $protocfg " network *"] " redistribute kernel" ]
			netconfClearSection $node "router $proto"
			netconfInsertSection $node $protocfg
		    }
		}
	    }
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
#   Saves changes in the module with services.
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

#****f* nodecfgGUI.tcl/configGUI_attachDockerToExtApply
# NAME
#   configGUI_attachDockerToExtApply -- configure GUI - attach docker ifc apply
# SYNOPSIS
#   configGUI_attachDockerToExtApply $wi $node
# FUNCTION
#   Saves changes in the module with attach docker to ext ifc
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_attachDockerToExtApply { wi node } {
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    global docker_enable
    set docker_enable_str [string map {0 false 1 true} $docker_enable]
    if { $oper_mode == "edit"} {
	if { [getNodeDockerAttach $node] != $docker_enable_str } {
	    setNodeDockerAttach $node $docker_enable_str
	    set changed 1
	}
    }
}

#****f* nodecfgGUI.tcl/configGUI_dockerImageApply
# NAME
#   configGUI_dockerImageApply -- configure GUI - docker image apply
# SYNOPSIS
#   configGUI_dockerImageApply $wi $node
# FUNCTION
#   Saves changes in the module with different dockerImage
# INPUTS
#   * wi -- widget
#   * node -- node id
#****
proc configGUI_dockerImageApply { wi node } {
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    set docker_image [$wi.dockerImg.img get]
    if { $oper_mode == "edit"} {
	if { [getNodeDockerImage $node] != $docker_image } {
	    setNodeDockerImage $node $docker_image
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

#****f* nodecfgGUI.tcl/configGUI_externalIfcsApply
# NAME
#   configGUI_externalIfcsApply -- configure GUI - external interface
#      configuration apply
# SYNOPSIS
#   configGUI_externalIfcsApply $wi $node $ifc
# FUNCTION
#   Saves changes in the module with Vlan configuration parameters.
# INPUTS
#   * wi -- widget
#   * node -- node id
#   * ifc -- interface name
#****
proc configGUI_externalIfcsApply { wi node } {
    set ifc [lindex [ifcList $node] 0]
    configGUI_ifcMACAddressApply $wi $node $ifc
    configGUI_ifcIPv4AddressApply $wi $node $ifc
    configGUI_ifcIPv6AddressApply $wi $node $ifc
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
    set x 0
    set numOfLines [llength $config]
    foreach data $config {
	incr x
	$w.editor insert end "$data"
	if { $x != $numOfLines } {
	    $w.editor insert end "\n"
	}
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
    set type [nodeType $node]
    
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
    if { $cfgName == "" } {
	set cfgName "default"
    }
    if {"$wi.nb.$cfgName" in [$wi.nb tabs]}  {
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

proc setIPsecLogging { node tab } {
    global ipsec_logging_on

    if { $ipsec_logging_on } {
	grid $tab.check_button -column 0 -row 3 -sticky ws -pady {0 0}
	grid $tab.logLevelLabel -column 1 -row 3 -columnspan 1 -sticky es
	grid $tab.logLevel -column 2 -row 3 -columnspan 3 -sticky es
	set ipsec_logging [getNodeIPsecItem $node "ipsec-logging"]
	if { $ipsec_logging == "" } {
	    set ipsec_logging 1
	}
	$tab.logLevel set $ipsec_logging
    } else {
	grid $tab.check_button -column 0 -row 3 -sticky ws -pady {4 0}
	grid remove $tab.logLevelLabel
	grid remove $tab.logLevel
    }
}

#################
#****f* nodecfgGUI.tcl/configGUI_ipsec
# NAME
#   configGUI_ipsecui -- configure GUI - GUI for IPsec tab
# SYNOPSIS
#   configGUI_ipsecui $tab $node
# FUNCTION
#   Creating GUI for IPsec configuration tab
# INPUTS
#   * tab -- tab widget where GUI will be placed
#   * node -- node id
#****
proc configGUI_ipsec { tab node } {
    global guielements ipsec_logging_on

    lappend guielements configGUI_ipsec
    set ipsec_logging [getNodeIPsecItem $node "ipsec-logging"]

    if { $ipsec_logging == "" } {
	set ipsec_logging_on 0
    } else {
	set ipsec_logging_on 1
    }

    $tab configure -padding "5 5 5 5"

    ttk::label $tab.headingLabel -text "List of IPsec connections"
    ttk::treeview $tab.tree -columns "Peers_IP_address" -yscrollcommand "$tab.scrollbar set"
    ttk::scrollbar $tab.scrollbar -command "$tab.tree yview" -orient vertical
    ttk::checkbutton $tab.check_button -text "Enable logging" -variable ipsec_logging_on \
	-onvalue 1 -offvalue 0 -command "setIPsecLogging $node $tab"
    ttk::label $tab.logLevelLabel -text "Logging level:" -padding {0 1}

    ttk::spinbox $tab.logLevel -width 5 \
	-validate focus -invalidcommand "focusAndFlash %W"
    $tab.logLevel configure \
	-from -1 -to 4 -increment 1 \
	-validatecommand {checkIntRange %P -1 4}
    grid $tab.headingLabel -column 0 -row 0 -padx 5 -pady 5 -columnspan 4
    grid $tab.tree -column 0 -row 1 -rowspan 2 -columnspan 3
    grid $tab.scrollbar -column 4 -row 1 -rowspan 2 -sticky ns
    setIPsecLogging $node $tab

    $tab.tree heading #0 -text "Connection name"
    $tab.tree column #0 -anchor center -width 195
    $tab.tree heading Peers_IP_address -text "Peers IP address"
    $tab.tree column Peers_IP_address -anchor center -width 195

    refreshIPsecTree $node $tab

    set tree_widget $tab.tree
    ttk::frame $tab.button_container
    ttk::button $tab.button_container.add_button -text "Add" -command "addIPsecConnWindow $node $tab"
    ttk::button $tab.button_container.modify_button -text "Modify" -command "modIPsecConnWindow $node $tab"
    ttk::button $tab.button_container.delete_button -text "Delete" -command "deleteIPsecConnection $node $tab "
    grid $tab.button_container -column 5 -row 1 -rowspan 2 -padx {8 0}
    grid $tab.button_container.add_button -column 0 -row 0 -pady 5 -padx 5
    grid $tab.button_container.modify_button -column 0 -row 1 -pady 5 -padx 5
    grid $tab.button_container.delete_button -column 0 -row 2 -pady 5 -padx 5
}

proc configGUI_ipsecApply { wi node } {
    global ipsec_logging_on

    if { $ipsec_logging_on } {
	setNodeIPsecItem $node "ipsec-logging" [lindex [$wi.logLevel get] 0]
    } else {
	if { [getNodeIPsecItem $node "ipsec-logging"] != "" } {
	    delNodeIPsecItem $node "ipsec-logging"
	}
    }
}

proc addIPsecConnWindow { node tab } {
    set mainFrame .d.mIPsecFrame
    set connParamsLframe $mainFrame.conn_params_lframe
    set espOptionsLframe $mainFrame.esp_options_lframe
    set ikeSALframe $mainFrame.ike_sa_lframe

    if { "[ifcList $node]" != "" } {
	createIPsecGUI $node $mainFrame $connParamsLframe $espOptionsLframe $ikeSALframe "Add"
	$mainFrame.buttons_container.apply configure -command "putIPsecConnectionInTree $node $tab add"
	setDefaultsForIPsec $node $connParamsLframe $espOptionsLframe
    } else {
	tk_messageBox -message "Selected node does not have any interfaces!" -title "Error" -icon error -type ok
	destroy .d
	return
    }
}

proc modIPsecConnWindow { node tab } {
    set mainFrame .d.mIPsecFrame
    set connParamsLframe $mainFrame.conn_params_lframe
    set espOptionsLframe $mainFrame.esp_options_lframe
    set ikeSALframe $mainFrame.ike_sa_lframe

    set selected [$tab.tree focus]
    if { $selected != "" } {
	createIPsecGUI $node $mainFrame $connParamsLframe $espOptionsLframe $ikeSALframe "Modify"
	$mainFrame.buttons_container.apply configure -command "putIPsecConnectionInTree $node $tab modify"
	populateValuesForUpdate $node $tab $connParamsLframe $espOptionsLframe
    } else {
	tk_messageBox -message "Please select item to modify!" -title "Error" -icon error -type ok
	destroy .d
	return
    }
}

proc deleteIPsecConnection { node tab } {
    global $tab.tree ipsec_enable
    set connection_name [$tab.tree focus]

    delNodeIPsecElement $node "configuration" "conn $connection_name"

    refreshIPsecTree $node $tab

    if { [$tab.tree children {}] == "" } {
	set ipsec_enable 0
    }
}

#****f* nodecfgGUI.tcl/putIPsecConnectionInTree
# NAME
#   putIPsecConnectionInTree -- configure GUI - performs data validation and adds (or modifies) connection
# SYNOPSIS
#   putIPsecConnectionInTree $tab $node $indicator
# FUNCTION
#   Performs data input validation and adds (or modifies) connection to list of all IPsec connections for node
# INPUTS
#   tab - tab widget that represents IPsec connection part od node config GUI
#   node - current node for which the procedure is invoked
#   indicator - variable that indicates wheter to add connection, or to modify it
#****
proc putIPsecConnectionInTree { node tab indicator } {
    global version instance_duration keying_duration negotiation_attempts
    global how_long_before ike_encr ike_auth ike_modp peers_ip peers_name peers_id start_connection
    global peers_subnet local_cert_file type method esp_suits authby psk_key
    global ah_suits modp_suits connection_name local_name local_ip_address local_subnet
    global tree_widget conn_time keying_time how_long_time
    global no_encryption secret_file old_conn_name ipsec_enable

    set cert_exists 0

    set total_value ""
    set changed "no"
    set trimmed_ip [lindex [split $local_ip_address /] 0]

    set peers_node [lindex $peers_name 2]

#    if { $old_conn_name != $connection_name } {
#	set changed "yes"
#    }

    set emptyCheckList { \
	{connection_name "Please specify connection name!"} \
	{ike_encr "Please specify IKE encryption algorithm!"} \
	{ike_auth "Please specify IKE integrity check algorithm!"} \
	{ike_modp "Please specify IKE modulo prime groups!"} \
	{peers_ip "Please specify peer's IP address!"} \
	{peers_name "Peer's name cannot be empty!"} \
	{peers_subnet "Please specify peer's subnet!"} \
	{local_ip_address "Please specify your IP address!"} \
	{local_subnet "Please specify your local subnet!"} \
	{esp_suits "Please specify ESP encryption algorithm!"} \
	{ah_suits "Please specify ESP integrity check algorithm!"} \
	{modp_suits "Please specify ESP modulo prime groups!"} \
	{peers_id "Please specify peer's unique name\n(e.g. @sun.strongswan.org)!"} \
	{secret_file "Please specify the file that contains private key!"} \
	{local_cert_file "Please specify your local certificate file"} \
	{local_name "Please specify local name/id!"} \
    }

    foreach item $emptyCheckList {
	if { ([lindex $item 0] == "peers_id" || [lindex $item 0] == "secret_file" \
	    || [lindex $item 0] == "local_cert_file" || [lindex $item 0] == "local_name") } {
	    if { $authby != "secret" } {
		if { [set [lindex $item 0]] == "" } {
		    tk_messageBox -message [lindex $item 1] -title "Error" -icon error -type ok
		    return
		}
	    }
	} elseif { [set [lindex $item 0]] == "" } {
	    tk_messageBox -message [lindex $item 1] -title "Error" -icon error -type ok
	    return
	}
    }

    if { $peers_name != "%any"} {
	set check [checkIfPeerStartsSameConnection $peers_node $trimmed_ip $local_subnet $local_name]
	if { $check == 1 && $start_connection == 1 } {
	    tk_messageBox -message "Peer is configured to start the same connection!" -title "Error" -icon error -type ok
	    return
	}
    }

    set cfg [getNodeIPsec $node]

    if { $indicator == "add"} {
	if { [nodeIPsecConnExists $node $connection_name] == 1 } {
	    tk_messageBox -message "Connection named '$connection_name' already exists" -title "Error" -icon error -type ok
	    return
	}
    } else {
	if { $changed == "yes"} {
	    if { [nodeIPsecConnExists $node $connection_name] == 1 } {
		tk_messageBox -message "Connection named '$connection_name' already exists" -title "Error" -icon error -type ok
		return
	    }
	}
    }

    set netNegCheckList { \
	    {instance_duration "Connection instance duration cannot be negative!"} \
	    {keying_duration "Keying channel duration cannot be negative!"} \
	    {how_long_before "Margin time for negotiation attempts cannot be negative!"} \
	    {negotiation_attempts "Negotiation attempts number cannot be negative!"} \
	}

    foreach item $netNegCheckList {
	if { [set [lindex $item 0]] < 0 } {
	    tk_messageBox -message [lindex $item 1] -title "Error" -icon error -type ok
	    return
	}
    }

    set timeCheckList {seconds minutes hours days}
    #validating connection instance_duration
    foreach item $timeCheckList {
	if { $item == "seconds" && $conn_time == "seconds" && ![string is integer -strict $instance_duration] } {
	    tk_messageBox -message "If in seconds, connection instance duration must be an integer!" -title "Error" -icon error -type ok
	    return
	} else {
	    if { $conn_time == $item && ![string is integer -strict $instance_duration] && ![string is double -strict $instance_duration]} {
		tk_messageBox -message "If in $item, connection instance duration must be an integer or double!" -title "Error" -icon error -type ok
		return
	    }
	}
    }

    #validating keying channel duration
    foreach item $timeCheckList {
        if { $item == "seconds" && $keying_time == "seconds" && ![string is integer -strict $keying_duration] } {
            tk_messageBox -message "If in seconds, keying duration must be an integer!" -title "Error" -icon error -type ok
            return
        } else {
            if { $keying_time == $item && ![string is integer -strict $keying_duration] && ![string is double -strict $keying_duration]} {
                tk_messageBox -message "If in $item, keying duration must be an integer or double!" -title "Error" -icon error -type ok
                return
            }
        }
    }

    #validating margintime values
    foreach item $timeCheckList {
        if { $item == "seconds" && $how_long_time == "seconds" && ![string is integer -strict $how_long_before] } {
            tk_messageBox -message "If in seconds, margin time for negotiation attempts must be an integer!" -title "Error" -icon error -type ok
            return
        } else {
            if { $how_long_time == $item && ![string is integer -strict $how_long_before] && ![string is double -strict $how_long_before] } {
                tk_messageBox -message "If in $item, margin time for negotiation attempts must be an integer or double!" -title "Error" -icon error -type ok
                return
            }
        }
    }

    #validating keyintgries (negotiation attempts)
    if { ![string is integer -strict $negotiation_attempts] || $negotiation_attempts < 0 } {
        tk_messageBox -message "Number of negotiation attempts cannot be negative and must be an integer!" -title "Error" -icon error -type ok
        return
    }

    if { $psk_key == "" && $authby == "secret" } {
        tk_messageBox -message "Please specify shared key!" -title "Error" -icon error -type ok
        return
    }

    set total_instance_duration "$instance_duration[string index $conn_time 0]"
    set total_keying_duration "$keying_duration[string index $keying_time 0]"
    set total_margintime "$how_long_before[string index $how_long_time 0]"


    set final_esp_encryption ""
    if { [string equal $method "ah"] } {
        set final_esp_encryption "null"
    } elseif { [string equal $method "esp"] } {
        set final_esp_encryption "$esp_suits"
    } else {
        set final_esp_encryption ""
    }

    set real_ip_local [lindex [split $local_ip_address /] 0]
    set real_ip_peer [lindex [split $peers_ip /] 0]

    set total_list ""

    set has_local_cert [getNodeIPsecItem $node "local_cert"]
    set has_local_key_file [getNodeIPsecItem $node "local_key_file"]

    if { $has_local_cert == "" && $authby != "secret" && $local_cert_file != "" && $secret_file != ""\
        && $has_local_key_file == ""} {
        setNodeIPsecItem $node "local_cert" $local_cert_file
        setNodeIPsecItem $node "local_key_file" $secret_file
    } else {
        if { $has_local_cert != $local_cert_file && $authby != "secret"} {
            set change [tk_messageBox -type "yesno" -message "Existing local cert file is different than current, proceed and replace?" -icon question -title "Cert file"]
            if { $change == "yes" } {
		setNodeIPsecItem $node "local_cert" $local_cert_file
            }
        }
        if { $has_local_key_file != $secret_file && $authby != "secret"} {
            set change [tk_messageBox -type "yesno" -message "Existing local cert file is different than current, proceed and replace?" -icon question -title "Secret file"]
            if { $change == "yes" } {
		setNodeIPsecItem $node "local_key_file" $secret_file
            }
        }
    }

    if { $indicator == "modify" } {
	delNodeIPsecElement $node "configuration" "conn $old_conn_name"
    }
    if { [getNodeIPsec $node] == "" } {
	createEmptyIPsecCfg $node
    }
    setNodeIPsecElement $node "configuration" "conn $connection_name" ""
    if { $total_keying_duration != "3h" } {
        setNodeIPsecSetting $node "configuration" "conn $connection_name" "ikelifetime" "$total_keying_duration"
    } else {
	setNodeIPsecSetting $node "configuration" "conn $connection_name" "ikelifetime" ""
    }
    if { $total_instance_duration != "1h" } {
        setNodeIPsecSetting $node "configuration" "conn $connection_name" "keylife" "$total_instance_duration"
    } else {
	setNodeIPsecSetting $node "configuration" "conn $connection_name" "keylife" ""
    }
    if { $total_margintime != "9m" } {
        setNodeIPsecSetting $node "configuration" "conn $connection_name" "rekeymargin" "$total_margintime"
    } else {
        setNodeIPsecSetting $node "configuration" "conn $connection_name" "rekeymargin" ""
    }
    if { $negotiation_attempts != "3" } {
        setNodeIPsecSetting $node "configuration" "conn $connection_name" "keyingtries" "$negotiation_attempts"
    } else {
        setNodeIPsecSetting $node "configuration" "conn $connection_name" "keyingtries" ""
    }
    if { $ike_encr != "aes128" || $ike_auth != "sha1" || $ike_modp != "modp2048"} {
        setNodeIPsecSetting $node "configuration" "conn $connection_name" "ike" "$ike_encr-$ike_auth-$ike_modp"
    } else {
        setNodeIPsecSetting $node "configuration" "conn $connection_name" "ike" ""
    }
    if { $final_esp_encryption != "aes128" || $ah_suits != "sha1" || $modp_suits != "modp2048" } {
        setNodeIPsecSetting $node "configuration" "conn $connection_name" "esp" "$final_esp_encryption-$ah_suits-$modp_suits"
    } else {
        setNodeIPsecSetting $node "configuration" "conn $connection_name" "esp" ""
    }
    if { $type != "tunnel"} {
        setNodeIPsecSetting $node "configuration" "conn $connection_name" "type" "$type"
    } else {
        setNodeIPsecSetting $node "configuration" "conn $connection_name" "type" ""
    }

    setNodeIPsecSetting $node "configuration" "conn $connection_name" "left" "$real_ip_local"
    setNodeIPsecSetting $node "configuration" "conn $connection_name" "leftsubnet" "$local_subnet"
    setNodeIPsecSetting $node "configuration" "conn $connection_name" "right" "$real_ip_peer"
    setNodeIPsecSetting $node "configuration" "conn $connection_name" "rightsubnet" "$peers_subnet"
    setNodeIPsecSetting $node "configuration" "conn $connection_name" "peersname" "[lindex $peers_name 0]"

    if { $authby == "secret" } {
        setNodeIPsecSetting $node "configuration" "conn $connection_name" "authby" "secret"
        setNodeIPsecSetting $node "configuration" "conn $connection_name" "sharedkey" "$psk_key"

        setNodeIPsecSetting $node "configuration" "conn $connection_name" "leftid" ""
        setNodeIPsecSetting $node "configuration" "conn $connection_name" "rightid" ""
#        checkAndClearCertificatesAndIds $node $connection_name
    } else {
        setNodeIPsecSetting $node "configuration" "conn $connection_name" "leftid" "$local_name"
        setNodeIPsecSetting $node "configuration" "conn $connection_name" "rightid" "$peers_id"

        setNodeIPsecSetting $node "configuration" "conn $connection_name" "authby" ""
        setNodeIPsecSetting $node "configuration" "conn $connection_name" "sharedkey" ""
#        checkAndClearSharedKeyAndAuthbySecret $node $connection_name
    }

    if { $start_connection == 1 } {
        setNodeIPsecSetting $node "configuration" "conn $connection_name" "auto" "start"
    } else {
        setNodeIPsecSetting $node "configuration" "conn $connection_name" "auto" "add"
    }

    if { $indicator == "add"} {
	if { [$tab.tree children {}] == "" } {
	    set ipsec_enable 1
	}
        $tab.tree insert {} end -id $connection_name -text "$connection_name"
        $tab.tree set $connection_name Peers_IP_address "$real_ip_peer"
    } else {
        refreshIPsecTree $node $tab
    }

    set old_conn_name ""
    destroy .d
}

#****f* nodecfgGUI.tcl/refreshIPsecTree
# NAME
#   refreshIPsecTree -- refreshes IPsec tree
# SYNOPSIS
#   refreshIPsecTree $node $tab
# FUNCTION
#   Refreshes tree widget that contains list of IPsec connections
# INPUTS
#   node - node id
#   tab - IPsec GUI tab widget
#****
proc refreshIPsecTree { node tab } {
    $tab.tree delete [$tab.tree children {}]
    foreach item [ getNodeIPsecConnList $node ] {
	set peerIp [ getNodeIPsecSetting $node "configuration" "conn $item" "right" ]
	if { $peerIp != "" } {
	    $tab.tree insert {} end -id $item -text "$item" -tags "$item"
	    $tab.tree set $item Peers_IP_address "$peerIp"
	    $tab.tree tag bind $item <Double-1> "modIPsecConnWindow $node $tab"
	}
    }
}

proc createIPsecGUI { node mainFrame connParamsLframe espOptionsLframe ikeSALframe indicator } {
    tk::toplevel .d
    wm title .d "$indicator IPsec connection"
    after 100 "grab .d"

    ttk::frame $mainFrame -padding 4
    grid $mainFrame -column 0 -row 0 -sticky nwes
    grid columnconfigure .d 0 -weight 1
    grid rowconfigure .d 0 -weight 1

#    setCurrentNode $node

    ttk::frame $mainFrame.con_name_container
    ttk::label $mainFrame.con_name_container.con_name -text "Connection name:"
    ttk::entry $mainFrame.con_name_container.conn_name_entry -width 14 -textvariable connection_name
    grid $mainFrame.con_name_container -column 0 -row 0 -columnspan 2
    grid $mainFrame.con_name_container.con_name -column 0 -row 0 -pady 5 -padx 5 -sticky e
    grid $mainFrame.con_name_container.conn_name_entry -column 1 -row 0 -pady 5 -padx 5

    # First label frame (Connection parameters)
    ttk::labelframe $connParamsLframe -text "Connection parameters"
    grid $connParamsLframe -column 0 -row 1 -sticky n -padx 5 -pady 5

    ttk::frame $connParamsLframe.authby_container -padding {95 0}
    ttk::label $connParamsLframe.authby_container.authby_type -text "Authentication type:"
    ttk::radiobutton $connParamsLframe.authby_container.cert -text "Certificates" -variable authby -value cert \
	-command "showCertificates $connParamsLframe"
    ttk::radiobutton $connParamsLframe.authby_container.secret -text "Shared key" -variable authby -value secret \
	-command "hideCertificates $connParamsLframe"

    grid $connParamsLframe.authby_container -column 0 -row 0 -pady 5 -padx 5 -columnspan 3
    grid $connParamsLframe.authby_container.authby_type -column 0 -row 0 -pady 5 -padx 5
    grid $connParamsLframe.authby_container.cert -column 1 -row 0 -pady 5 -padx 5 -sticky w
    grid $connParamsLframe.authby_container.secret -column 2 -row 0 -pady 5 -padx 5 -sticky w

    ttk::label $connParamsLframe.local_id -text "Local name/id:"
    ttk::entry $connParamsLframe.local_id_entry -width 15 -textvariable local_name
    grid $connParamsLframe.local_id -column 0 -row 1 -pady 5 -padx 5 -sticky e
    grid $connParamsLframe.local_id_entry -column 1 -row 1 -pady 5 -padx 5 -sticky w -columnspan 2

    ttk::label $connParamsLframe.local_ip -text "Local IP address:"
    ttk::combobox $connParamsLframe.local_ip_entry -width 14 -textvariable local_ip_address -state readonly
    grid $connParamsLframe.local_ip -column 0 -row 2 -pady 5 -padx 5 -sticky e
    grid $connParamsLframe.local_ip_entry -column 1 -row 2 -pady 5 -padx 5 -sticky w

    ttk::label $connParamsLframe.local_sub -text "Local subnet:"
    ttk::combobox $connParamsLframe.local_sub_entry -width 14 -textvariable local_subnet -state readonly
    grid $connParamsLframe.local_sub -column 0 -row 3 -pady 5 -padx 5 -sticky e
    grid $connParamsLframe.local_sub_entry -column 1 -row 3 -pady 5 -padx 5 -sticky w

    ttk::label $connParamsLframe.peer_name -text "Specify his name:"
    ttk::entry $connParamsLframe.peer_id -width 15 -textvariable peers_id
    grid $connParamsLframe.peer_name -column 0 -row 4 -pady 5 -padx 5 -sticky e
    grid $connParamsLframe.peer_id -column 1 -row 4 -pady 5 -padx 5 -sticky w -columnspan 2

    ttk::label $connParamsLframe.peer_ip -text "Peers IP address:"
    ttk::combobox $connParamsLframe.peer_name_entry -width 14 -textvariable peers_name -state readonly
    ttk::combobox $connParamsLframe.peer_ip_entry -width 24 -textvariable peers_ip -state readonly
    ttk::entry $connParamsLframe.peer_ip_entry_text -width 26 -textvariable peers_ip
    grid $connParamsLframe.peer_ip -column 0 -row 5 -pady 5 -padx 5 -sticky e
    grid $connParamsLframe.peer_name_entry -column 1 -row 5 -pady 5 -padx 5 -sticky w
    grid $connParamsLframe.peer_ip_entry -column 2 -row 5 -pady 5 -padx 4 -sticky w
    grid $connParamsLframe.peer_ip_entry_text -column 2 -row 5 -pady 5 -padx 4 -sticky w
    grid remove $connParamsLframe.peer_ip_entry_text

    ttk::label $connParamsLframe.peer_sub -text "Peers subnet:"
    ttk::combobox $connParamsLframe.peer_sub_entry -width 14 -textvariable peers_subnet -state readonly
    ttk::entry $connParamsLframe.peer_sub_entry_text -width 15 -textvariable peers_subnet
    grid $connParamsLframe.peer_sub -column 0 -row 6 -pady 5 -padx 5 -sticky e
    grid $connParamsLframe.peer_sub_entry -column 1 -row 6 -pady 5 -padx 5 -sticky w
    grid $connParamsLframe.peer_sub_entry_text -column 1 -row 6 -pady 5 -padx 5 -sticky w
    grid remove $connParamsLframe.peer_sub_entry_text

    ttk::frame $connParamsLframe.local_cert_container
    ttk::label $connParamsLframe.local_cert_container.local_cert -text "Local certificate file:"
    ttk::entry $connParamsLframe.local_cert_container.local_cert_entry -width 14 -textvariable local_cert_file
    ttk::button $connParamsLframe.local_cert_container.cert_chooser -text "Open" \
	-command "chooseFile cert"
    ttk::entry $connParamsLframe.local_cert_container.local_cert_directory -width 20 -textvariable local_cert_dir -state readonly
    grid $connParamsLframe.local_cert_container -column 0 -row 7 -columnspan 3 -sticky w
    grid $connParamsLframe.local_cert_container.local_cert -column 0 -row 0 -pady 5 -padx {11 5} -sticky e
    grid $connParamsLframe.local_cert_container.local_cert_entry -column 1 -row 0 -pady 5 -padx 5 -sticky w
    grid $connParamsLframe.local_cert_container.cert_chooser -column 2 -row 0
    grid $connParamsLframe.local_cert_container.local_cert_directory -column 3 -row 0 -pady 5 -padx 5 -sticky w

    ttk::frame $connParamsLframe.private_file_container
    ttk::label $connParamsLframe.private_file_container.secret -text "Private key file: "
    ttk::entry $connParamsLframe.private_file_container.secret_entry -width 14 -textvariable secret_file
    ttk::button $connParamsLframe.private_file_container.private_chooser -text "Open" \
	-command "chooseFile private"
    ttk::entry $connParamsLframe.private_file_container.secret_directory -width 22 -textvariable secret_dir -state readonly
    grid $connParamsLframe.private_file_container -column 0 -row 8 -columnspan 3 -sticky w
    grid $connParamsLframe.private_file_container.secret -column 0 -row 0 -pady 5 -padx {43 0} -sticky e
    grid $connParamsLframe.private_file_container.secret_entry -column 1 -row 0 -pady 5 -padx 5 -sticky w
    grid $connParamsLframe.private_file_container.private_chooser -column 2 -row 0
    grid $connParamsLframe.private_file_container.secret_directory -column 3 -row 0 -pady 5 -padx 5 -sticky w

    ttk::checkbutton $connParamsLframe.check_button -text "Start connection after executing experiment" -variable start_connection -onvalue 1 -offvalue 0
    grid $connParamsLframe.check_button -column 0 -row 9 -pady 5 -padx 5 -columnspan 2

    # hidden
    ttk::label $connParamsLframe.shared_key -text "Shared key:"
    ttk::entry $connParamsLframe.shared_key_entry -width 14 -textvariable psk_key

    # Second label frame (Authentication/Encryption)
    ttk::labelframe $espOptionsLframe -text "ESP options"
    grid $espOptionsLframe -column 1 -row 1 -sticky wens -padx 5 -pady 5

    ttk::frame $espOptionsLframe.method_container
    ttk::radiobutton $espOptionsLframe.method_container.ah -text "ESP Authentication only" -variable method -value ah \
	-command "showNullEncryption $espOptionsLframe"
    ttk::radiobutton $espOptionsLframe.method_container.esp -text "Full ESP" -variable method -value esp \
	-command "showFullEncryption $espOptionsLframe"
    grid $espOptionsLframe.method_container -column 0 -row 0 -sticky w
    grid $espOptionsLframe.method_container.ah -column 0 -row 0 -pady 5 -padx 5 -sticky w
    grid $espOptionsLframe.method_container.esp -column 1 -row 0 -pady 5 -padx 5 -sticky w

    ttk::frame $espOptionsLframe.type_container
    ttk::label $espOptionsLframe.type_container.conn-type -text "Connection type:"
    ttk::radiobutton $espOptionsLframe.type_container.tunnel -text "Tunnel" -variable type -value tunnel
    ttk::radiobutton $espOptionsLframe.type_container.transport -text "Transport" -variable type -value transport
    grid $espOptionsLframe.type_container -column 0 -row 1 -pady 5 -padx 5 -columnspan 2 -sticky w
    grid $espOptionsLframe.type_container.conn-type  -column 0 -row 0 -pady 5 -padx 5
    grid $espOptionsLframe.type_container.tunnel -column 1 -row 0 -pady 5 -padx 5
    grid $espOptionsLframe.type_container.transport -column 2 -row 0 -padx 5 -pady 5

    ttk::frame $espOptionsLframe.esp_container

    ttk::label $espOptionsLframe.esp_container.esp_suit -text "Encryption algorithm:"
    ttk::combobox $espOptionsLframe.esp_container.esp_combo -textvariable esp_suits -state readonly
    $espOptionsLframe.esp_container.esp_combo configure -values [list "3des" cast128 blowfish128 blowfish192 blowfish256 aes128 aes192 aes256]
    grid $espOptionsLframe.esp_container.esp_suit -column 0 -row 0 -pady 5 -padx 5 -sticky e
    grid $espOptionsLframe.esp_container.esp_combo -column 1 -row 0 -pady 5 -padx 5

    ttk::entry $espOptionsLframe.esp_container.null_encryption -width 7 -state readonly -textvariable no_encryption

    ttk::label $espOptionsLframe.esp_container.ah_suit -text "Integrity check algorithm:"
    ttk::combobox $espOptionsLframe.esp_container.ah_combo -textvariable ah_suits -state readonly
    grid $espOptionsLframe.esp_container.ah_suit -column 0 -row 1 -pady 5 -padx 5 -sticky e
    grid $espOptionsLframe.esp_container.ah_combo -column 1 -row 1 -pady 5 -padx 5
    $espOptionsLframe.esp_container.ah_combo configure -values [list md5 sha1 sha256 sha384 sha512]

    ttk::label $espOptionsLframe.esp_container.modp_suit -text "Modulo prime groups:"
    ttk::combobox $espOptionsLframe.esp_container.modp_combo -textvariable modp_suits -state readonly
    grid $espOptionsLframe.esp_container.modp_suit -column 0 -row 2 -pady 5 -padx 5 -sticky e
    grid $espOptionsLframe.esp_container.modp_combo -column 1 -row 2 -pady 5 -padx 5
    $espOptionsLframe.esp_container.modp_combo configure -values [list modp768 modp1024 modp1536 modp2048 modp3072 modp4096 modp6144 modp8192]

    ttk::button $espOptionsLframe.advance_button_esp -width 20 -text "Advanced options" \
	-command "showESPAdvancedOptions $node $espOptionsLframe"
    grid $espOptionsLframe.advance_button_esp -column 0 -row 2 -padx 105 -pady 5

    # Third label frame (security association establishment)
    ttk::labelframe $ikeSALframe -text "IKEv2 SA Establishment"
    grid $ikeSALframe -column 0 -row 2 -columnspan 2

    ttk::frame $ikeSALframe.ike_container
    ttk::label $ikeSALframe.ike_container.conn_instance -text "Connection instance duration:"
    ttk::spinbox $ikeSALframe.ike_container.conn_instance_entry -from 1 -to 1000 -textvariable instance_duration
    ttk::combobox $ikeSALframe.ike_container.connection_duration_combo -width 7 -textvariable conn_time -state readonly
    grid $ikeSALframe.ike_container.conn_instance -column 0 -row 0 -pady 5 -padx 5 -sticky e
    grid $ikeSALframe.ike_container.conn_instance -column 0 -row 0 -pady 5 -padx 5 -sticky e
    grid $ikeSALframe.ike_container.conn_instance_entry -column 1 -row 0 -pady 5 -padx 5
    grid $ikeSALframe.ike_container.connection_duration_combo -column 2 -row 0 -pady 5 -padx 5 -sticky w
    $ikeSALframe.ike_container.connection_duration_combo configure -values [list seconds minutes hours days]

    ttk::label $ikeSALframe.ike_container.keying_channel -text "Keying channel duration:"
    ttk::spinbox $ikeSALframe.ike_container.keying_channel_entry -from 1 -to 1000 -textvariable keying_duration
    ttk::combobox $ikeSALframe.ike_container.keying_duration_combo -width 7 -textvariable keying_time -state readonly
    grid $ikeSALframe.ike_container.keying_channel -column 0 -row 1 -pady 5 -padx 5 -sticky e
    grid $ikeSALframe.ike_container.keying_channel_entry -column 1 -row 1 -pady 5 -padx 5
    grid $ikeSALframe.ike_container.keying_duration_combo -column 2 -row 1 -pady 5 -padx 5 -sticky w
    $ikeSALframe.ike_container.keying_duration_combo configure -values [list seconds minutes hours days]

    ttk::label $ikeSALframe.ike_container.neg_attempts -text "Connection negotiation attempts:"
    ttk::spinbox $ikeSALframe.ike_container.neg_attempts_entry -from 1 -to 1000 -textvariable negotiation_attempts
    grid $ikeSALframe.ike_container.neg_attempts -column 0 -row 2 -pady 5 -padx 5 -sticky e
    grid $ikeSALframe.ike_container.neg_attempts_entry -column 1 -row 2 -pady 5 -padx 5

    ttk::label $ikeSALframe.ike_container.how_long -text "Rekeying margin time:"
    ttk::spinbox $ikeSALframe.ike_container.how_long_entry -from 1 -to 100 -textvariable how_long_before
    ttk::combobox $ikeSALframe.ike_container.how_long_combo -width 7 -textvariable how_long_time -state readonly
    grid $ikeSALframe.ike_container.how_long -column 0 -row 3 -sticky e -pady 5 -padx 5
    grid $ikeSALframe.ike_container.how_long_entry -column 1 -row 3 -pady 5 -padx 5
    grid $ikeSALframe.ike_container.how_long_combo -column 2 -row 3 -pady 5 -padx 5 -sticky w
    $ikeSALframe.ike_container.how_long_combo configure -values [list seconds minutes hours days]

    ttk::label $ikeSALframe.ike_container.ike_esp -text "IKE encryption algorithm"
    ttk::combobox $ikeSALframe.ike_container.ike_esp_combo -width 15 -textvariable ike_encr -state readonly
    grid $ikeSALframe.ike_container.ike_esp -column 0 -row 4 -pady 5 -padx 5 -sticky e
    grid $ikeSALframe.ike_container.ike_esp_combo -column 1 -row 4 -pady 5 -padx 5
    $ikeSALframe.ike_container.ike_esp_combo configure -values [list "3des" cast128 blowfish128 blowfish192 blowfish256 aes128 aes192 aes256]

    ttk::label $ikeSALframe.ike_container.ike_ah -text "IKE integrity check"
    ttk::combobox $ikeSALframe.ike_container.ike_ah_combo -width 15 -textvariable ike_auth -state readonly
    grid $ikeSALframe.ike_container.ike_ah -column 0 -row 5 -pady 5 -padx 5 -sticky e
    grid $ikeSALframe.ike_container.ike_ah_combo -column 1 -row 5 -pady 5 -padx 5
    $ikeSALframe.ike_container.ike_ah_combo configure -values [list md5 sha1 sha256 sha384 sha512]

    ttk::label $ikeSALframe.ike_container.ike_modp -text "IKE modulo prime groups"
    ttk::combobox $ikeSALframe.ike_container.ike_modp_combo -width 15 -textvariable ike_modp -state readonly
    grid $ikeSALframe.ike_container.ike_modp -column 0 -row 6 -pady 5 -padx 5 -sticky e
    grid $ikeSALframe.ike_container.ike_modp_combo -column 1 -row 6 -pady 5 -padx 5
    $ikeSALframe.ike_container.ike_modp_combo configure -values [list modp768 modp1024 modp1536 modp2048 modp3072 modp4096 modp6144 modp8192]

    ttk::button $ikeSALframe.advance_button_ike -width 20 -text "Advanced options" -command "showIKEAdvancedOptions $node $ikeSALframe"
    grid $ikeSALframe.advance_button_ike -column 0 -row 0 -padx 180 -pady 5

    # Buttons container
    ttk::frame $mainFrame.buttons_container
    grid $mainFrame.buttons_container -column 0 -row 3 -columnspan 2
    ttk::button $mainFrame.buttons_container.apply -text "$indicator"
    grid $mainFrame.buttons_container.apply -column 0 -row 0 -padx 5 -pady 5
    ttk::button $mainFrame.buttons_container.cancel -text "Cancel" -command {destroy .d}
    grid $mainFrame.buttons_container.cancel -column 1 -row 0 -padx 5 -pady 5

    if { [ winfo exists .d ] } {
	bind $connParamsLframe.local_ip_entry <<ComboboxSelected>> \
	    "updateLocalSubnetCombobox $connParamsLframe; \
	    updatePeerCombobox $connParamsLframe"
	bind $connParamsLframe.local_sub_entry <<ComboboxSelected>> \
	    "updatePeerSubnetCombobox $connParamsLframe"
	bind $connParamsLframe.peer_name_entry <<ComboboxSelected>> \
	    "updatePeerCombobox $connParamsLframe"
	bind $connParamsLframe.peer_ip_entry <<ComboboxSelected>> \
	    "updatePeerSubnetCombobox $connParamsLframe"
    }
}

# XXX
proc updatePeerCombobox { connParamsLframe } {
    global peers_name local_ip_address local_subnet peers_ip peers_subnet

    if { $peers_name == "%any" } {
	grid remove $connParamsLframe.peer_ip_entry
	grid remove $connParamsLframe.peer_sub_entry
	grid $connParamsLframe.peer_ip_entry_text
	grid $connParamsLframe.peer_sub_entry_text
	return
    } else {
	grid $connParamsLframe.peer_ip_entry
	grid $connParamsLframe.peer_sub_entry
	grid remove $connParamsLframe.peer_ip_entry_text
	grid remove $connParamsLframe.peer_sub_entry_text
    }

    set peers_node [lindex $peers_name 2]

    set peerIPs [getIPAddressForPeer $peers_node $local_ip_address]
    $connParamsLframe.peer_ip_entry configure -values $peerIPs
    if { [lsearch $peerIPs $peers_ip] == -1 } {
	set peers_ip [lindex $peerIPs 0]
    }

    set peersSubIPs [getIPAddressForPeer $peers_node $local_subnet]
    set peersSubs [getSubnetsFromIPs $peersSubIPs]
    $connParamsLframe.peer_sub_entry configure -values $peersSubs
    updatePeerSubnetCombobox $connParamsLframe
}

# XXX
proc updateLocalSubnetCombobox { connParamsLframe } {
    global local_ip_address local_subnet

    set IPs [$connParamsLframe.local_ip_entry cget -values]

    set idx [lsearch -exact $IPs $local_ip_address ]
    set IPs [lreplace $IPs $idx $idx]
    set subnets [getSubnetsFromIPs $IPs]

    if { $subnets != "" } {
	$connParamsLframe.local_sub_entry configure -values $subnets
	set local_subnet [lindex $subnets 0]
	updatePeerSubnetCombobox $connParamsLframe
    }
}

# XXX
proc updatePeerSubnetCombobox { connParamsLframe } {
    global local_ip_address local_subnet peers_name peers_ip peers_subnet
    if { $peers_name == "%any" } {
	return
    }
    set peers_node [lindex $peers_name 2]

    set subnetVersion [::ip::version $local_subnet]

    set peerIPs ""
    set allPeerIPs [getAllIpAddresses $peers_node]
    foreach ip $allPeerIPs {
	if { $subnetVersion == [::ip::version $ip] && $peers_ip != $ip} {
	    lappend peerIPs $ip
	}
    }
    set subnets [getSubnetsFromIPs $peerIPs]
    $connParamsLframe.peer_sub_entry configure -values $subnets
    set peers_subnet [lindex $subnets 0]
}

#****f* nodecfgGUI.tcl/setDefaultsForIPsec
# NAME
#   setDefaultsForIPsec -- populates input fields in IPsec GUI with defaults
# SYNOPSIS
#   setDefaultsForIPsec $node
# FUNCTION
#   When adding new IPsec connection, populates input fields with default values for IPsec configuration
# INPUTS
#   node - node id
#****
proc setDefaultsForIPsec { node connParamsLframe espOptionsLframe } {
    global version connection_name instance_duration keying_duration negotiation_attempts
    global conn_time keying_time how_long_time local_cert_dir secret_dir authby psk_key
    global how_long_before ike_encr ike_auth ike_modp peers_ip peers_name peers_id start_connection
    global peers_subnet local_cert_file local_name local_ip_address local_subnet type method esp_suits
    global ah_suits modp_suits secret_file no_encryption

    set connection_name "home"
    set version ikev2
    set authby cert
    set instance_duration "1"
    set conn_time hours
    set keying_duration "3"
    set keying_time hours
    set negotiation_attempts "3"
    set how_long_before "9"
    set how_long_time minutes
    set start_connection 0
    set ike_encr "aes128"
    set ike_auth "sha1"
    set ike_modp "modp2048"
    set secret_file [getNodeIPsecItem $node "local_key_file"]
    set peers_id ""
    set psk_key ""
    set no_encryption "null"
    set local_cert_dir "/usr/local/etc/ipsec.d/certs"
    set secret_dir "/usr/local/etc/ipsec.d/private"
    $espOptionsLframe.esp_container.null_encryption configure -state readonly

    set local_cert_file [getNodeIPsecItem $node "local_cert_file"]
    set local_name [getNodeName $node]

    set nodes [concat %any [getListOfOtherNodes $node]]
    $connParamsLframe.peer_name_entry configure -values $nodes

    set localIPs [getAllIpAddresses $node]
    $connParamsLframe.local_ip_entry configure -values $localIPs
    set local_ip_address [lindex $localIPs 0]

    set peerHasAddr 0
    set peerHasIfc 0
    foreach cnode $nodes {
	set peers_name $cnode
	if { $cnode == "%any"} {
	    continue
	}
	set peers_node [lindex $peers_name 2]

	if { $peers_name != ""} {
	    set peerHasIfc 1
	    set peerIPs [getIPAddressForPeer $peers_node $local_ip_address]
	    if { [llength $peerIPs] != 0 } {
		$connParamsLframe.peer_ip_entry configure -values $peerIPs
		set peers_ip [lindex $peerIPs 0]
		set peerHasAddr 1
		break
	    } else {
		set peerHasAddr 0
		continue
	    }
	} else {
	    set peerHasIfc 0
	}
    }

    if { ! $peerHasIfc } {
	tk_messageBox -message "Peers do not have any interfaces!" -title "Error" -icon error -type ok
	destroy .d
	return
    }

    if { ! $peerHasAddr } {
	tk_messageBox -message "Peers do not have any IP addresses!" -title "Error" -icon error -type ok
	destroy .d
	return
    }

    updateLocalSubnetCombobox $connParamsLframe
    updatePeerCombobox $connParamsLframe

    set type tunnel
    set method esp
    set esp_suits aes128
    set ah_suits sha1
    set modp_suits modp2048
}

#****f* nodecfgGUI.tcl/populateValuesForUpdate
# NAME
#   populateValuesForUpdate -- configure GUI - populates input fields in IPsec GUI with existing data
# SYNOPSIS
#   populateValuesForUpdate $node $tab
# FUNCTION
#   When modifying existing connection, populates input fields with data of selected IPsec connection
# INPUTS
#   node - current node for which the procedure is invoked
#   tab - tab widget that represents IPsec connection part od node config GUI
#****
proc populateValuesForUpdate { node tab connParamsLframe espOptionsLframe } {
    global version connection_name instance_duration keying_duration negotiation_attempts
    global conn_time keying_time how_long_time authby psk_key local_cert_dir secret_dir
    global how_long_before ike_encr ike_auth ike_modp peers_ip peers_name peers_id start_connection
    global peers_subnet local_cert_file local_name local_ip_address local_subnet type method esp_suits
    global ah_suits modp_suits secret_file no_encryption old_conn_name

    set selected [$tab.tree focus]
    set connection_name $selected
    set version "ikev2"

    set local_cert_file [getNodeIPsecSetting $node "configuration" "conn $selected" "local_cert"]
    set secret_file [getNodeIPsecSetting $node "configuration" "conn $selected" "local_key_file"]

    set var_list { \
	{type "type" "tunnel" } \
	{local_ip_address "left" ""} \
	{local_subnet "leftsubnet" ""} \
	{peers_ip "right" ""} \
	{peers_subnet "rightsubnet" ""} \
	{peers_name "peersname" ""} \
	{peers_id "rightid" ""} \
	{psk_key "sharedkey" ""} \
	{local_name "leftid" ""} \
	{keying_duration "ikelifetime" "3h"} \
	{instance_duration "keylife" "1h"} \
	{how_long_before "rekeymargin" "9m"} \
	{negotiation_attempts "keyingtries" "3"} \
	{ike_from_cfg "ike" "aes128-sha1-modp2048"} \
	{esp_from_cfg "esp" "aes128-sha1-modp2048"} \
    }

    foreach var $var_list {
	set [lindex $var 0] [getNodeIPsecSetting $node "configuration" "conn $selected" [lindex $var 1]]
	if { [set [lindex $var 0]] == "" } {
	    set [lindex $var 0] [lindex $var 2]
	}
    }

    set timeList { \
	    {s "seconds"} {m "minutes"} \
	    {h "hours"} {d "days"}
    }
    foreach item $timeList {
	if { [string index $instance_duration end] == [lindex $item 0] } {
	    set conn_time [lindex $item 1]
	}
	if { [string index $keying_duration end] == [lindex $item 0] } {
	    set keying_time [lindex $item 1]
	}
	if { [string index $how_long_before end] == [lindex $item 0] } {
	    set how_long_time [lindex $item 1]
	}
    }

    foreach item { instance_duration keying_duration how_long_before } {
	set $item [string trimright [set $item] smhd]
    }

    foreach item { encr auth modp } {
	set ike_$item [getIkeParam $ike_from_cfg $item]
    }

    foreach item { esp ah modp } {
	set $item\_suits [getEspParam $esp_from_cfg $item]
    }

    if { $esp_suits == "null" } {
	set method ah
	showNullEncryption $espOptionsLframe
    } else {
	set method esp
	showFullEncryption $espOptionsLframe
    }

    set auto [getNodeIPsecSetting $node "configuration" "conn $selected" "auto"]
    if { $auto == "start" } {
	set start_connection 1
    } else {
	set start_connection 0
    }

    set authby [getNodeIPsecSetting $node "configuration" "conn $selected" "authby"]
    if { $authby == "secret" } {
	hideCertificates $connParamsLframe
    } else {
	showCertificates $connParamsLframe
    }

    set nodes [getListOfOtherNodes $node]
    $connParamsLframe.peer_name_entry configure -values [concat %any $nodes]

    set local_ip_address [getNodeIPsecSetting $node "configuration" "conn $selected" "left"]
    set localIPs [getAllIpAddresses $node]
    $connParamsLframe.local_ip_entry configure -values $localIPs
    foreach localIp $localIPs {
	if { $local_ip_address == [lindex [split $localIp /] 0]} {
	    set local_ip_address $localIp
	    break
	}
    }

    if { $peers_name != "%any" } {
	if { $peers_name != ""} {
	    set peers_node [getNodeFromHostname $peers_name]
	    set peers_name "$peers_name - $peers_node"
	    set peerIPs [getIPAddressForPeer $peers_node $local_ip_address]
	    $connParamsLframe.peer_ip_entry configure -values $peerIPs
	    if { [llength $peerIPs] != 0 } {
		set peers_ip [getNodeIPsecSetting $node "configuration" "conn $selected" "right"]
		foreach peerIp $peerIPs {
		    if { $peers_ip == [lindex [split $peerIp /] 0]} {
			set peers_ip $peerIp
			break
		    }
		}
	    }
	} else {
	    tk_messageBox -message "Peer does not have any interfaces!" -title "Error" -icon error -type ok
	    destroy .d
	    return
	}
    }

    updateLocalSubnetCombobox $connParamsLframe
    updatePeerCombobox $connParamsLframe

    set local_subnet [getNodeIPsecSetting $node "configuration" "conn $selected" "leftsubnet"]
    set peers_subnet [getNodeIPsecSetting $node "configuration" "conn $selected" "rightsubnet"]

    set local_cert_dir "/usr/local/etc/ipsec.d/certs"
    set secret_dir "/usr/local/etc/ipsec.d/private"

    set old_conn_name $connection_name
}

# XXX
proc getEspParam { espCfg param } {
    switch -- $param {
        esp {
            return [lindex [split $espCfg -] 0]
        }
        ah {
            return [lindex [split $espCfg -] 1]
        }
        modp {
            return [lindex [split $espCfg -] 2]
        }
    }
}

# XXX
proc getIkeParam { ikeCfg param } {
    switch -- $param {
        encr {
            return [lindex [split $ikeCfg -] 0]
        }
        auth {
            return [lindex [split $ikeCfg -] 1]
        }
        modp {
            return [lindex [split $ikeCfg -] 2]
        }
    }
}

#****f* nodecfgGUI.tcl/showCertificates
# NAME
#   showCertificates -- show certificates
# SYNOPSIS
#   showCertificates
# FUNCTION
#   If user selects certificate authentication, this function displays
#   corresponding fields in the IPsec connection frame.
#****
proc showCertificates { lFrame } {
    global peers_name

    grid forget $lFrame.shared_key
    grid forget $lFrame.shared_key_entry

    grid $lFrame.local_id -column 0 -row 1 -pady 5 -padx 5 -sticky e
    grid $lFrame.local_id_entry -column 1 -row 1 -pady 5 -padx 5 -sticky w

    grid $lFrame.local_ip -column 0 -row 2 -pady 5 -padx 5 -sticky e
    grid $lFrame.local_ip_entry -column 1 -row 2 -pady 5 -padx 5 -sticky w

    grid $lFrame.local_sub -column 0 -row 3 -pady 5 -padx 5 -sticky e
    grid $lFrame.local_sub_entry -column 1 -row 3 -pady 5 -padx 5 -sticky w

    grid $lFrame.peer_name -column 0 -row 4 -pady 5 -padx 5 -sticky e
    grid $lFrame.peer_id -column 1 -row 4 -pady 5 -padx 5 -sticky w

    grid $lFrame.peer_ip -column 0 -row 5 -pady 5 -padx 5 -sticky e
    grid $lFrame.peer_name_entry -column 1 -row 5 -pady 5 -padx 5 -sticky w
    grid $lFrame.peer_ip_entry -column 2 -row 5 -pady 5 -padx 2 -sticky w

    grid $lFrame.peer_sub -column 0 -row 6 -pady 5 -padx 5 -sticky e
    grid $lFrame.peer_sub_entry -column 1 -row 6 -pady 5 -padx 5 -sticky w
    grid $lFrame.peer_ip_entry_text -column 2 -row 5 -pady 5 -padx 2 -sticky w
    grid $lFrame.peer_sub_entry_text -column 1 -row 6 -pady 5 -padx 5 -sticky w
    if { $peers_name == "%any" } {
	grid remove $lFrame.peer_ip_entry
	grid remove $lFrame.peer_sub_entry
    } else {
	grid remove $lFrame.peer_ip_entry_text
	grid remove $lFrame.peer_sub_entry_text
    }

    grid $lFrame.local_cert_container -column 0 -row 7 -columnspan 3 -sticky w

    grid $lFrame.private_file_container -column 0 -row 8 -columnspan 3 -sticky w

    grid $lFrame.check_button -column 0 -row 9 -pady 5 -padx 5 -columnspan 2
}

#****f* nodecfgGUI.tcl/hideCertificates
# NAME
#   hideCertificates -- hide certificates
# SYNOPSIS
#   hideCertificates
# FUNCTION
#   If user selects pre shared key authentication, this function hides
#   corresponding fields in the IPsec connection frame.
#****
proc hideCertificates { lFrame } {
    global peers_name
    set var_list { local_id local_id_entry peer_name peer_id local_cert_container private_file_container }

    foreach var $var_list {
	grid forget $lFrame.$var
    }

    grid $lFrame.local_ip -column 0 -row 1 -pady 5 -padx 5 -sticky e
    grid $lFrame.local_ip_entry -column 1 -row 1 -pady 5 -padx 5 -sticky w

    grid $lFrame.local_sub -column 0 -row 2 -pady 5 -padx 5 -sticky e
    grid $lFrame.local_sub_entry -column 1 -row 2 -pady 5 -padx 5 -sticky w

    grid $lFrame.peer_ip -column 0 -row 3 -pady 5 -padx 5 -sticky e
    grid $lFrame.peer_name_entry -column 1 -row 3 -pady 5 -padx 5 -sticky w
    grid $lFrame.peer_ip_entry -column 2 -row 3 -pady 5 -padx 5 -sticky w

    grid $lFrame.peer_sub -column 0 -row 4 -pady 5 -padx 5 -sticky e
    grid $lFrame.peer_sub_entry -column 1 -row 4 -pady 5 -padx 5 -sticky w
    grid $lFrame.peer_ip_entry_text -column 2 -row 3 -pady 5 -padx 5 -sticky w
    grid $lFrame.peer_sub_entry_text -column 1 -row 4 -pady 5 -padx 5 -sticky w
    if { $peers_name == "%any" } {
	grid remove $lFrame.peer_ip_entry
	grid remove $lFrame.peer_sub_entry
    } else {
	grid remove $lFrame.peer_ip_entry_text
	grid remove $lFrame.peer_sub_entry_text
    }

    grid $lFrame.shared_key -column 0 -row 5 -pady 5 -padx 5 -sticky e
    grid $lFrame.shared_key_entry -column 1 -row 5 -pady 5 -padx 5 -sticky w

    grid $lFrame.check_button -column 0 -row 6 -pady 5 -padx 5 -columnspan 2
}

#****f* nodecfgGUI.tcl/chooseFile
# NAME
#   chooseFile -- opens modal window for selecting file
# SYNOPSIS
#   chooseFile $mode
# FUNCTION
#   Opens modal window for selecting local certificate or key file
# INPUTS
#   mode - indicates wheter to open local certificate or local key file
#****
proc chooseFile { mode } {
    global local_cert_file secret_file
    if { $mode == "cert" } {
	set local_cert_file [tk_getOpenFile]
    } else {
	set secret_file [tk_getOpenFile]
    }
}

#****f* nodecfgGUI.tcl/showNullEncryption
# NAME
#   showNullEncryption -- displays field with null value
# SYNOPSIS
#   showNullEncryption
# FUNCTION
#   Displays special field with null value when ESP Authentication only is selected
# INPUTS
#
#****
proc showNullEncryption { lFrame } {
    global esp_suits no_encryption
    if { $esp_suits != "null" } {
	set esp_suits "null"
    }
    set no_encryption "null"
    grid forget $lFrame.esp_container.esp_combo

    grid $lFrame.esp_container.null_encryption -column 1 -row 0 -pady 5 -padx 5 -sticky w
}

#****f* nodecfgGUI.tcl/showFullEncryption
# NAME
#   showFullEncryption -- displays dropdown list for selecting encryption algorithm
# SYNOPSIS
#   showFullEncryption
# FUNCTION
#   Displays dropdown list for selecting encryption algorithm when Full ESP is selected
# INPUTS
#
#****
proc showFullEncryption { lFrame } {
    global esp_suits
    if { $esp_suits == "null" } {
	set esp_suits "aes128"
    }
    grid forget $lFrame.esp_container.null_encryption

    grid $lFrame.esp_container.esp_combo -column 1 -row 0 -pady 5 -padx 5
}

#****f* nodecfgGUI.tcl/hideESPAdvancedOptions
# NAME
#   hideESPAdvancedOptions -- hides advanced options in ESP label frame
# SYNOPSIS
#   hideESPAdvancedOptions $node
# FUNCTION
#   Hides advanced options in ESP options label frame in IPsec GUI
# INPUTS
#   node - node id
#****
proc hideESPAdvancedOptions { node lFrame } {
    grid forget $lFrame.esp_container
    $lFrame.advance_button_esp configure -text "Advanced options"
    $lFrame.advance_button_esp configure -command "showESPAdvancedOptions $node $lFrame"
}

#****f* nodecfgGUI.tcl/hideVlanOptions
# modification for VLAN
# NAME
#   hideVlanOptions
# SYNOPSIS
#   hideVlanOptions $node $lFrame $ifc
# FUNCTION
#   Delete Vlan and disable Vlan options


proc hideVlanOptions { node lFrame ifc } {
    global listVlan


    set wi1 ".popup.panwin"
    $wi1 sashpos 0 "250"
    pack forget $lFrame.queuecfg3
    pack forget $lFrame.queuecfg4
    pack forget $lFrame.queuecfg5
    pack forget $lFrame.queuecfg6.button 
    pack forget $lFrame.queuecfg6 

    foreach element $listVlan {
	
		set nom [lindex $element 0]
                set nom1 [lindex $nom 0]

			if { "$node-$ifc" == $nom1 } {

				set id [lsearch $listVlan $element]
                                
                                set ID [expr $id-1]

				set malist [lreplace $listVlan $id $id]
				set malist [lreplace $malist $ID $ID]
				set listVlan $malist

                #On rajoute l'information avec enable 0
                global enableVlan tagVlan modeVlan rangeVlan interfaceVlan listVlan
                set Mynode [lindex $element 0]
				set enableVlan 0
				set tagVlan [lindex $element 2]
                set modeVlan [lindex $element 3]
			    set interfaceVlan [lindex $element 4]
				set rangeVlan [lindex $element 5]
                lappend listVlan "$Mynode $enableVlan $tagVlan $modeVlan $interfaceVlan $rangeVlan"
			}


				}



    $lFrame.queuecfg2.enable configure -command "VlanOptions $node $lFrame $ifc"
    
    
}

#****f* nodecfgGUI.tcl/VlanOptions
# modification for VLAN
# NAME
#   VlanOptions
# SYNOPSIS
#   VlanOptions $node $lFrame $ifc
# FUNCTION
#  enable Vlan options, Add Vlan and Show All Vlan	

proc VlanOptions { node lFrame ifc} {
global enableVlan


if {$enableVlan == 0} {

    set wi1 ".popup.panwin"
    $wi1 sashpos 0 "250"
    global listVlan
    pack forget $lFrame.queuecfg3
   # pack forget $lFrame.queuecfg4
    pack forget $lFrame.queuecfg5
    pack forget $lFrame.queuecfg6.button 
    pack forget $lFrame.queuecfg6 

#je supprime l'ancienne information et je rajoute une nouvelle avec enable 0
    foreach element $listVlan {
	
		        set nom [lindex $element 0]
                set nom1 [lindex $nom 0]

			if { "$node-$ifc" == $nom1 } {

				set id [lsearch $listVlan $element]
                                
                set ID [expr $id-1]

				set malist [lreplace $listVlan $id $id]
				set malist [lreplace $malist $ID $ID]
				set listVlan $malist

#On rajoute l'information avec enable 0
                global enableVlan tagVlan modeVlan rangeVlan interfaceVlan listVlan
                set Mynode [lindex $element 0]
				set enableVlan 0
				set tagVlan [lindex $element 2]
                set modeVlan [lindex $element 3]
			    set interfaceVlan [lindex $element 4]
				set rangeVlan [lindex $element 5]
                lappend listVlan "$Mynode $enableVlan $tagVlan $modeVlan $interfaceVlan $rangeVlan"
                
			}


	}

} else { 
#Modification for vlan

        set wi1 ".popup.panwin"
	    $wi1 sashpos 0 "130"

        pack $lFrame.queuecfg2 -fill both
        pack $lFrame.queuecfg3.tagtxt -side left -padx 2 
        pack $lFrame.queuecfg3.tag -side left -padx 4 -pady 4
        pack $lFrame.queuecfg3.modetxt -side left -padx 2
        pack $lFrame.queuecfg3.mode -side left -padx 4 -pady 4
        pack $lFrame.queuecfg3.interfacetxt -side left -padx 2
        pack $lFrame.queuecfg3.interface -side left -padx 4 -pady 4
        pack $lFrame.queuecfg3 -fill both

        pack $lFrame.queuecfg5.rangetxt -side left -padx 2
        pack $lFrame.queuecfg5.range -side left -padx 4 -pady 4
        pack $lFrame.queuecfg5 -fill both

      #  pack $lFrame.queuecfg4.interfacetxt -side left -padx 2
       # pack $lFrame.queuecfg4.interface -side left -padx 4 -pady 4
       # pack $lFrame.queuecfg4 -fill both

        pack forget $lFrame.queuecfg6.button.apply \
        $lFrame.queuecfg6.button.cancel -side left -padx 2
        pack forget $lFrame.queuecfg6.button.delete 
       
        pack $lFrame.queuecfg6.button.apply \
        $lFrame.queuecfg6.button.cancel -side left -padx 2
        pack $lFrame.queuecfg6.button -pady 2 -expand 1
        pack $lFrame.queuecfg6 -fill both -side bottom



        $lFrame.queuecfg2.enable configure -command "hideVlanOptions $node $lFrame $ifc"

    
}

} 
#****f* nodecfgGUI.tcl/ShowVlan_Switch
# modification for VLAN
# NAME
#   ShowVlan_Switch
# SYNOPSIS
#   ShowVlan_Switch $node $lFrame $ifc
# FUNCTION
#  Display all active Vlan of a node
 
proc ShowVlan_Switch { node lFrame ifc } {
global ShowVlan listVlan Vlancolumns 
if { $ShowVlan == 1 } {
  pack forget $lFrame.queuecfg2
  pack forget $lFrame.queuecfg3
  pack forget $lFrame.queuecfg4
  pack forget $lFrame.queuecfg5
  pack forget $lFrame.queuecfg6.button.apply 
  pack forget $lFrame.queuecfg6.button.cancel 
  pack $lFrame.queuecfg6.button.delete \
        $lFrame.queuecfg6.button.cancel -side left -padx 2

  pack $lFrame.queuecfg6.button -pady 2 -expand 1
  pack $lFrame.queuecfg6 -fill both -side bottom

     
  $lFrame.tab insert {} end -id interfaces -text \
	"Physical Interfaces" -open true -tags interfaces
  $lFrame.tab focus interfaces
  $lFrame.tab selection set interfaces
   

     foreach ifc [lsort -dictionary [ifcList $node]] {
         
         $lFrame.tab insert interfaces end -id $ifc \
	        -text "$ifc" -tags $ifc

	foreach element $listVlan {
 	     
            set name [lindex $element 0]
            set enable [lindex $element 1]

            if { "$node-$ifc" == $name && $enable == 1} { 

                      set id 2
                     foreach myelement $Vlancolumns {

			 set valeur [lindex $element $id]
                         set id [expr $id+1]

	                 $lFrame.tab set $ifc [lindex $myelement 0] "$valeur"

	                  }
                }
           }
      }

               
    

  pack $lFrame.queuecfg7 -fill both -expand 1
  grid $lFrame.tab $lFrame.vscroll -in $lFrame.queuecfg7 -sticky nsew
  grid $lFrame.hscroll -in $lFrame.queuecfg7 -sticky nsew
  grid columnconfig $lFrame.queuecfg7 0 -weight 1
  grid rowconfigure $lFrame.queuecfg7 0 -weight 1 






 $lFrame.queuecfg6.button.cancel configure -text "VLAN options"
 $lFrame.queuecfg6.button.cancel configure -command "VlanOptions_Switch $node $lFrame $ifc"
}
}

#****f* nodecfgGUI.tcl/VlanOptions
# modification for VLAN
# NAME
#   VlanOptions_Switch
# SYNOPSIS
#   VlanOptions_Switch $node $lFrame $ifc
# FUNCTION
#  enable Vlan options, Add Vlan and Show All Vlan	


proc VlanOptions_Switch { node lFrame ifc} {

        global listVlan enableVlan modeVlan tagVlan interfaceVlan rangeVlan



        pack $lFrame.queuecfg2 -fill both
        pack $lFrame.queuecfg3.tagtxt -side left -padx 2 
        pack $lFrame.queuecfg3.tag -side left -padx 4 -pady 4
        pack $lFrame.queuecfg3.modetxt -side left -padx 2
        pack $lFrame.queuecfg3.mode -side left -padx 4 -pady 4
        pack $lFrame.queuecfg3.interfacetxt -side left -padx 2
        pack $lFrame.queuecfg3.interface -side left -padx 4 -pady 4
        pack $lFrame.queuecfg3 -fill both

        pack $lFrame.queuecfg5.rangetxt -side left -padx 2
        pack $lFrame.queuecfg5.range -side left -padx 4 -pady 4
        pack $lFrame.queuecfg5 -fill both
        
     
        
        $lFrame.tab delete [$lFrame.tab children {}]
        pack forget $lFrame.queuecfg7 
        pack forget $lFrame.tab

        pack forget $lFrame.queuecfg6.button.apply \
        $lFrame.queuecfg6.button.cancel -side left -padx 2
        pack forget $lFrame.queuecfg6.button.delete 
       
        pack $lFrame.queuecfg6.button.apply \
        $lFrame.queuecfg6.button.cancel -side left -padx 2
        pack $lFrame.queuecfg6.button -pady 2 -expand 1
        pack $lFrame.queuecfg6 -fill both -side bottom

        $lFrame.queuecfg6.button.cancel configure -text "Show All VLAN"
        $lFrame.queuecfg6.button.cancel configure -command "ShowVlan_Switch $node $lFrame $ifc"

}
#****f* nodecfgGUI.tcl/VlanOptions
# modification for VLAN
# NAME
#   DeleteVlan_Switch
# SYNOPSIS
#   DeleteVlan_Switch $node $lFrame $ifc
# FUNCTION
#  Delete All Vlan of a node

proc DeleteVlan_Switch { node lFrame ifc } {
global DeleteVlan listVlan

if {$DeleteVlan == 1} {

#set listVlan {}

 foreach element $listVlan {
	
                set Mynode [lindex $element 0]
                set Mynode [split $Mynode "-"]
                set Mynode [lindex $Mynode 0]

			if { $node == $Mynode } {

				set id [lsearch $listVlan $element]
                                
                                set ID [expr $id-1]

				set malist [lreplace $listVlan $id $id]
				set malist [lreplace $malist $ID $ID]
				set listVlan $malist

                #On rajoute l'information avec enable 0
                global enableVlan tagVlan modeVlan rangeVlan interfaceVlan listVlan
                set Mynode [lindex $element 0]
				set enableVlan 0
				set tagVlan [lindex $element 2]
                set modeVlan [lindex $element 3]
			    set interfaceVlan [lindex $element 4]
				set rangeVlan [lindex $element 5]
                lappend listVlan "$Mynode $enableVlan $tagVlan $modeVlan $interfaceVlan $rangeVlan"

				set enableVlan 0
				set tagVlan ""
                set modeVlan ""
			    set interfaceVlan ""
				set rangeVlan ""
				
			}

}



  $lFrame.tab delete [$lFrame.tab children {}]
  pack forget $lFrame.queuecfg7 
  pack forget $lFrame.tab

  pack forget $lFrame.queuecfg6.button.apply \
  $lFrame.queuecfg6.button.cancel -side left -padx 2
  pack forget $lFrame.queuecfg6.button.delete 

  pack $lFrame.queuecfg6.button.delete \
        $lFrame.queuecfg6.button.cancel -side left -padx 2

  pack $lFrame.queuecfg6.button -pady 2 -expand 1
  pack $lFrame.queuecfg6 -fill both -side bottom

     
  $lFrame.tab insert {} end -id interfaces -text \
	"Physical Interfaces" -open true -tags interfaces
  $lFrame.tab focus interfaces
  $lFrame.tab selection set interfaces
   

     foreach ifc [lsort -dictionary [ifcList $node]] {

         $lFrame.tab insert interfaces end -id $ifc \
	        -text "$ifc" -tags $ifc

	foreach element $listVlan {

            set Mynode [lindex $element 0]
            set Mynode [split $Mynode "-"]
            set Mynode [lindex $Mynode 0]
            set enable [lindex $element 1]

            if { $node == $Mynode && $enable == 1 } { 

                      set id 2
                     foreach myelement $Vlancolumns {

			 set valeur [lindex $element $id]
                         set id [expr $id+1]

	                 $lFrame.tab set $ifc [lindex $myelement 0] "$valeur"

	                  }
                }
           }
      }

               
    

  pack $lFrame.queuecfg7 -fill both -expand 1
  grid $lFrame.tab $lFrame.vscroll -in $lFrame.queuecfg7 -sticky nsew
  grid $lFrame.hscroll -in $lFrame.queuecfg7 -sticky nsew
  grid columnconfig $lFrame.queuecfg7 0 -weight 1
  grid rowconfigure $lFrame.queuecfg7 0 -weight 1 






 $lFrame.queuecfg6.button.cancel configure -text "VLAN options"
 $lFrame.queuecfg6.button.cancel configure -command "VlanOptions_Switch $node $lFrame $ifc"
       

}

}

#****f* nodecfgGUI.tcl/VlanOptions
# modification for VLAN
# NAME
#   configVlan_Switch
# SYNOPSIS
#   configVlan_Switch $node $ifc
# FUNCTION
#  The configuration of Vlan options

proc configVlan_Switch { node ifc } {

global enableVlan tagVlan modeVlan interfaceVlan rangeVlan 



global applyVlan listVlan


if { $applyVlan == 1 } {


lappend listVlan "!"

	foreach element $listVlan {


		set nom [lindex $element 0]
                set nom1 [lindex $nom 0]

			if { "$node-$ifc" == $nom1 } {

				set id [lsearch $listVlan $element]
                                
                                set ID [expr $id-1]

				set malist [lreplace $listVlan $id $id]
				set malist [lreplace $malist $ID $ID]
				set listVlan $malist

			}


				}
	
if {$tagVlan == ""} { 
set tagVlan "No-tag"
}
if {$modeVlan == ""} { 
set modeVlan "No-mode"
}
if {$interfaceVlan== ""} { 
set interfaceVlan "No-interface"
}
if {$rangeVlan== ""} { 
set rangeVlan "No-range"
}


lappend listVlan "$node-$ifc $enableVlan $tagVlan $modeVlan $interfaceVlan $rangeVlan"




} 

}
#end_modification

proc showESPAdvancedOptions { node lFrame } {
    grid $lFrame.esp_container -column 0 -row 3
    $lFrame.advance_button_esp configure -text "Hide advanced options"
    $lFrame.advance_button_esp configure -command "hideESPAdvancedOptions $node $lFrame"
}

#****f* nodecfgGUI.tcl/hideIKEAdvancedOptions
# NAME
#   hideIKEAdvancedOptions -- hide IKE advanced options
# SYNOPSIS
#   hideIKEAdvancedOptions $node
# FUNCTION
#   Hides advanced options in IKEv2 Establishment label frame in IPsec GUI.
# INPUTS
#   node - node id
#   lFrame - labelframe to hide
#****
proc hideIKEAdvancedOptions { node lFrame } {
    grid forget $lFrame.ike_container
    $lFrame.advance_button_ike configure -text "Advanced options"
    $lFrame.advance_button_ike configure -command "showIKEAdvancedOptions $node $lFrame"
}

#****f* nodecfgGUI.tcl/showIKEAdvancedOptions
# NAME
#   showIKEAdvancedOptions -- show IKE advanced options
# SYNOPSIS
#   showIKEAdvancedOptions $node
# FUNCTION
#   Displays advanced options in IKEv2 Establishment label frame in IPsec GUI.
# INPUTS
#   node - node id
#   lFrame - labelframe to show
#****
proc showIKEAdvancedOptions { node lFrame } {
    grid $lFrame.ike_container -column 0 -row 1 -padx 0 -pady { 5 10 }
    $lFrame.advance_button_ike configure -text "Hide advanced options"
    $lFrame.advance_button_ike configure -command "hideIKEAdvancedOptions $node $lFrame"
}


## stpswitch
proc configGUI_ifcBridgeAttributes { wi node ifc } {
    global guielements
    lappend guielements "configGUI_ifcBridgeAttributes $ifc"
    global brguielements
    lappend brguielements "configGUI_ifcBridgeAttributes $ifc"

    ttk::frame $wi.if$ifc.bridge -borderwidth 2

    global ifcBridgeDiscover$ifc
    set ifcBridgeDiscover$ifc [getBridgeIfcDiscover $node $ifc]
    ttk::checkbutton $wi.if$ifc.bridge.discover -text "discover" \
	-variable ifcBridgeDiscover$ifc

    global ifcBridgeLearn$ifc
    set ifcBridgeLearn$ifc [getBridgeIfcLearn $node $ifc]
    ttk::checkbutton $wi.if$ifc.bridge.learn -text "learn" \
	-variable ifcBridgeLearn$ifc

    global ifcBridgeSticky$ifc
    set ifcBridgeSticky$ifc [getBridgeIfcSticky $node $ifc]
    ttk::checkbutton $wi.if$ifc.bridge.sticky -text "sticky" \
	-variable ifcBridgeSticky$ifc

    global ifcBridgePrivate$ifc
    set ifcBridgePrivate$ifc [getBridgeIfcPrivate $node $ifc]
    ttk::checkbutton $wi.if$ifc.bridge.private -text "private" \
	-variable ifcBridgePrivate$ifc

    global ifcBridgeSnoop$ifc
    set ifcBridgeSnoop$ifc [getBridgeIfcSnoop $node $ifc]
    ttk::checkbutton $wi.if$ifc.bridge.snoop -text "snoop" \
	-variable ifcBridgeSnoop$ifc -command "snoopDisable $wi $ifc"

    global ifcBridgeStp$ifc
    set ifcBridgeStp$ifc [getBridgeIfcStp $node $ifc]
    ttk::checkbutton $wi.if$ifc.bridge.stp -text "stp" \
	-variable ifcBridgeStp$ifc

    global ifcBridgeEdge$ifc
    set ifcBridgeEdge$ifc [getBridgeIfcEdge $node $ifc]
    ttk::checkbutton $wi.if$ifc.bridge.edge -text "edge" \
	-variable ifcBridgeEdge$ifc

    global ifcBridgeAutoedge$ifc
    set ifcBridgeAutoedge$ifc [getBridgeIfcAutoedge $node $ifc]
    ttk::checkbutton $wi.if$ifc.bridge.autoedge -text "autoedge" \
	-variable ifcBridgeAutoedge$ifc

    global ifcBridgePtp$ifc
    set ifcBridgePtp$ifc [getBridgeIfcPtp $node $ifc]
    ttk::checkbutton $wi.if$ifc.bridge.ptp -text "ptp" \
	-variable ifcBridgePtp$ifc

    global ifcBridgeAutoptp$ifc
    set ifcBridgeAutoptp$ifc [getBridgeIfcAutoptp $node $ifc]
    ttk::checkbutton $wi.if$ifc.bridge.autoptp -text "autoptp" \
	-variable ifcBridgeAutoptp$ifc

    ttk::frame $wi.if$ifc.bridge.priority -padding 0
    ttk::label $wi.if$ifc.bridge.priority.label -text "Priority:" \
	-anchor w
    ttk::spinbox $wi.if$ifc.bridge.priority.box -width 3 \
	-from 0 -to 240 -increment 10 \
	-validatecommand {checkIntRange %P 0 240} \
	-invalidcommand "focusAndFlash %W"
    set bridgeIfcPriority [getBridgeIfcPriority $node $ifc]
    $wi.if$ifc.bridge.priority.box insert 0 $bridgeIfcPriority
    pack $wi.if$ifc.bridge.priority.label -side left -anchor w -expand 1 -fill x
    pack $wi.if$ifc.bridge.priority.box -side left -anchor e

    ttk::frame $wi.if$ifc.bridge.pathcost -padding 0
    ttk::label $wi.if$ifc.bridge.pathcost.label -text "Path cost:" -anchor w
    ttk::spinbox $wi.if$ifc.bridge.pathcost.box -width 9 \
	-from 0 -to 200000000 -increment 100 \
	-validatecommand {checkIntRange %P 0 200000000} \
	-invalidcommand "focusAndFlash %W"
    set bridgeIfcPathcost [getBridgeIfcPathcost $node $ifc]
    $wi.if$ifc.bridge.pathcost.box insert 0 $bridgeIfcPathcost
    pack $wi.if$ifc.bridge.pathcost.label -side left -anchor w -expand 1 -fill x
    pack $wi.if$ifc.bridge.pathcost.box -side left -anchor e

    ttk::frame $wi.if$ifc.bridge.maxaddr -padding 0
    ttk::label $wi.if$ifc.bridge.maxaddr.label -text "Max addresses:" -anchor w
    ttk::spinbox $wi.if$ifc.bridge.maxaddr.box -width 5 \
	-from 0 -to 10000 -increment 10 \
	-validatecommand {checkIntRange %P 0 10000} \
	-invalidcommand "focusAndFlash %W"
    set bridgeIfcMaxaddr [getBridgeIfcMaxaddr $node $ifc]
    $wi.if$ifc.bridge.maxaddr.box insert 0 $bridgeIfcMaxaddr
    pack $wi.if$ifc.bridge.maxaddr.label -side left -anchor w -expand 1 -fill x
    pack $wi.if$ifc.bridge.maxaddr.box -side left -anchor e

    pack $wi.if$ifc.bridge -anchor w -padx 10

    grid $wi.if$ifc.bridge.priority -in $wi.if$ifc.bridge \
	-column 0 -row 2 -columnspan 3 -sticky ew -pady 5
    grid $wi.if$ifc.bridge.maxaddr -in $wi.if$ifc.bridge \
	-column 0 -row 3 -columnspan 3 -sticky ew -pady 0
    grid $wi.if$ifc.bridge.pathcost -in $wi.if$ifc.bridge \
	-column 0 -row 4 -columnspan 3 -sticky ew -pady 5

    grid $wi.if$ifc.bridge.snoop -in $wi.if$ifc.bridge \
	-column 0 -row 1 -sticky nsew -padx 0
    grid $wi.if$ifc.bridge.stp -in $wi.if$ifc.bridge \
	-column 0 -row 0 -sticky nsew -padx 0
    grid $wi.if$ifc.bridge.discover -in $wi.if$ifc.bridge \
	-column 1 -row 0 -sticky nsew -padx 0
    grid $wi.if$ifc.bridge.learn -in $wi.if$ifc.bridge \
	-column 1 -row 1 -sticky nsew -padx 0
    grid $wi.if$ifc.bridge.sticky -in $wi.if$ifc.bridge \
	-column 2 -row 0 -sticky nsew -padx 5
    grid $wi.if$ifc.bridge.private -in $wi.if$ifc.bridge \
	-column 2 -row 1 -sticky nsew -padx 5
    grid $wi.if$ifc.bridge.edge -in $wi.if$ifc.bridge \
	-column 3 -row 0 -sticky nsew -padx 5
    grid $wi.if$ifc.bridge.autoedge -in $wi.if$ifc.bridge \
	-column 3 -row 1 -sticky nsew -padx 5
    grid $wi.if$ifc.bridge.ptp -in $wi.if$ifc.bridge \
	-column 4 -row 0 -sticky nsew -padx 0
    grid $wi.if$ifc.bridge.autoptp -in $wi.if$ifc.bridge \
	-column 4 -row 1 -sticky nsew -padx 0

    snoopDisable $wi $ifc
}

proc snoopDisable { wi ifc } {
	if { $ifc == "" } {
	    return
	}
	global ifcBridgeSnoop$ifc
	if { [set ifcBridgeSnoop$ifc] == 1 } {
	    $wi.if$ifc.bridge.discover configure -state disabled
	    $wi.if$ifc.bridge.sticky configure -state disabled
	    $wi.if$ifc.bridge.learn configure -state disabled
	    $wi.if$ifc.bridge.edge configure -state disabled
	    $wi.if$ifc.bridge.autoedge configure -state disabled
	    $wi.if$ifc.bridge.ptp configure -state disabled
	    $wi.if$ifc.bridge.autoptp configure -state disabled
	    $wi.if$ifc.bridge.stp configure -state disabled
	    $wi.if$ifc.bridge.private configure -state disabled
	    $wi.if$ifc.bridge.priority.box configure -state disabled
	    $wi.if$ifc.bridge.maxaddr.box configure -state disabled
	    $wi.if$ifc.bridge.pathcost.box configure -state disabled
	} else {
	    $wi.if$ifc.bridge.discover configure -state normal
	    $wi.if$ifc.bridge.sticky configure -state normal
	    $wi.if$ifc.bridge.learn configure -state normal
	    $wi.if$ifc.bridge.edge configure -state normal
	    $wi.if$ifc.bridge.autoedge configure -state normal
	    $wi.if$ifc.bridge.ptp configure -state normal
	    $wi.if$ifc.bridge.autoptp configure -state normal
	    $wi.if$ifc.bridge.stp configure -state normal
	    $wi.if$ifc.bridge.private configure -state normal
	    $wi.if$ifc.bridge.priority.box configure -state normal
	    $wi.if$ifc.bridge.maxaddr.box configure -state normal
	    $wi.if$ifc.bridge.pathcost.box configure -state normal
	}
}

proc configGUI_ifcBridgeAttributesApply { wi node ifc } {
    global changed apply

    global ifcBridgeSnoop$ifc
    set ifcBridgeSnoop [set ifcBridgeSnoop$ifc]
    set oldIfcBridgeSnoop [getBridgeIfcSnoop $node $ifc]
    if { $ifcBridgeSnoop != $oldIfcBridgeSnoop } {
	if { $apply == 1 } {
	    setBridgeIfcSnoop $node $ifc $ifcBridgeSnoop
	}
	set changed 1
    }

    if { $ifcBridgeSnoop == 1} {
	return
    }

    global ifcBridgeDiscover$ifc
    set ifcBridgeDiscover [set ifcBridgeDiscover$ifc]
    set oldIfcBridgeDiscover [getBridgeIfcDiscover $node $ifc]
    if { $ifcBridgeDiscover != $oldIfcBridgeDiscover } {
	if { $apply == 1 } {
	    setBridgeIfcDiscover $node $ifc $ifcBridgeDiscover
	}
	set changed 1
    }

    global ifcBridgeLearn$ifc
    set ifcBridgeLearn [set ifcBridgeLearn$ifc]
    set oldIfcBridgeLearn [getBridgeIfcLearn $node $ifc]
    if { $ifcBridgeLearn != $oldIfcBridgeLearn } {
	if { $apply == 1 } {
	    setBridgeIfcLearn $node $ifc $ifcBridgeLearn
	}
	set changed 1
    }

    global ifcBridgeSticky$ifc
    set ifcBridgeSticky [set ifcBridgeSticky$ifc]
    set oldIfcBridgeSticky [getBridgeIfcSticky $node $ifc]
    if { $ifcBridgeSticky != $oldIfcBridgeSticky } {
	if { $apply == 1 } {
	    setBridgeIfcSticky $node $ifc $ifcBridgeSticky
	}
	set changed 1
    }

    global ifcBridgePrivate$ifc
    set ifcBridgePrivate [set ifcBridgePrivate$ifc]
    set oldIfcBridgePrivate [getBridgeIfcPrivate $node $ifc]
    if { $ifcBridgePrivate != $oldIfcBridgePrivate } {
	if { $apply == 1 } {
	    setBridgeIfcPrivate $node $ifc $ifcBridgePrivate
	}
	set changed 1
    }

    global ifcBridgeStp$ifc
    set ifcBridgeStp [set ifcBridgeStp$ifc]
    set oldIfcBridgeStp [getBridgeIfcStp $node $ifc]
    if { $ifcBridgeStp != $oldIfcBridgeStp } {
	if { $apply == 1 } {
	    setBridgeIfcStp $node $ifc $ifcBridgeStp
	}
	set changed 1
    }

    global ifcBridgeEdge$ifc
    set ifcBridgeEdge [set ifcBridgeEdge$ifc]
    set oldIfcBridgeEdge [getBridgeIfcEdge $node $ifc]
    if { $ifcBridgeEdge != $oldIfcBridgeEdge } {
	if { $apply == 1 } {
	    setBridgeIfcEdge $node $ifc $ifcBridgeEdge
	}
	set changed 1
    }

    global ifcBridgeAutoedge$ifc
    set ifcBridgeAutoedge [set ifcBridgeAutoedge$ifc]
    set oldIfcBridgeAutoedge [getBridgeIfcAutoedge $node $ifc]
    if { $ifcBridgeAutoedge != $oldIfcBridgeAutoedge } {
	if { $apply == 1 } {
	    setBridgeIfcAutoedge $node $ifc $ifcBridgeAutoedge
	}
	set changed 1
    }

    global ifcBridgePtp$ifc
    set ifcBridgePtp [set ifcBridgePtp$ifc]
    set oldIfcBridgePtp [getBridgeIfcPtp $node $ifc]
    if { $ifcBridgePtp != $oldIfcBridgePtp } {
	if { $apply == 1 } {
	    setBridgeIfcPtp $node $ifc $ifcBridgePtp
	}
	set changed 1
    }

    global ifcBridgeAutoptp$ifc
    set ifcBridgeAutoptp [set ifcBridgeAutoptp$ifc]
    set oldIfcBridgeAutoptp [getBridgeIfcAutoptp $node $ifc]
    if { $ifcBridgeAutoptp != $oldIfcBridgeAutoptp } {
	if { $apply == 1 } {
	    setBridgeIfcAutoptp $node $ifc $ifcBridgeAutoptp
	}
	set changed 1
    }

    set ifcBridgePriority [$wi.if$ifc.bridge.priority.box get]
    set oldIfcBridgePriority [getBridgeIfcPriority $node $ifc]
    if { $ifcBridgePriority != $oldIfcBridgePriority } {
	if { $apply == 1 } {
	    setBridgeIfcPriority $node $ifc $ifcBridgePriority
	}
	set changed 1
    }

    set ifcBridgePathcost [$wi.if$ifc.bridge.pathcost.box get]
    set oldIfcBridgePathcost [getBridgeIfcPathcost $node $ifc]
    if { $ifcBridgePathcost != $oldIfcBridgePathcost } {
	if { $apply == 1 } {
	    setBridgeIfcPathcost $node $ifc $ifcBridgePathcost
	}
	set changed 1
    }

    set ifcBridgeMaxaddr [$wi.if$ifc.bridge.maxaddr.box get]
    set oldIfcBridgeMaxaddr [getBridgeIfcMaxaddr $node $ifc]
    if { $ifcBridgeMaxaddr != $oldIfcBridgeMaxaddr } {
	if { $apply == 1 } {
	    setBridgeIfcMaxaddr $node $ifc $ifcBridgeMaxaddr
	}
	set changed 1
    }
}

proc configGUI_bridgeConfig { wi node } {
    global guielements
    lappend guielements configGUI_bridgeConfig

    global bridgeProtocol
    ttk::frame $wi.bridge -relief groove -borderwidth 2 -padding 2

    set bridgeProtocol [getBridgeProtocol $node bridge0]

    ttk::frame $wi.bridge.protocols -padding 2
    ttk::label $wi.bridge.protocols.label -text "Protocol:"
    ttk::radiobutton $wi.bridge.protocols.rstp -text "rstp" \
	-variable bridgeProtocol -value rstp \
	-command "$wi.bridge.hellotime.box configure -state disabled"
    ttk::radiobutton $wi.bridge.protocols.stp -text "stp" \
	-variable bridgeProtocol -value stp \
	-command "$wi.bridge.hellotime.box configure -state normal"

    ttk::frame $wi.bridge.priority -padding 2
    ttk::label $wi.bridge.priority.label -text "Priority:"
    ttk::spinbox $wi.bridge.priority.box -width 6 \
	-from 0 -to 61440 -increment 4096 \
	-validatecommand {checkIntRange %P 0 61440} \
	-invalidcommand "focusAndFlash %W"
    set bridgePriority [getBridgePriority $node bridge0]
    if { $bridgePriority != "" } {
	$wi.bridge.priority.box insert 0 $bridgePriority
    } else {
	$wi.bridge.priority.box insert 0 32768
    }

    ttk::frame $wi.bridge.maxage -padding 2
    ttk::label $wi.bridge.maxage.label -text "Max age:"
    ttk::spinbox $wi.bridge.maxage.box -width 2 \
	-from 6 -to 40 -increment 2 \
	-validatecommand {checkIntRange %P 6 40} \
	-invalidcommand "focusAndFlash %W"
    set bridgeMaxAge [getBridgeMaxAge $node bridge0]
    if { $bridgeMaxAge != "" } {
	$wi.bridge.maxage.box insert 0 $bridgeMaxAge
    } else {
	$wi.bridge.maxage.box insert 0 20
    }

    ttk::frame $wi.bridge.fwddelay -padding 2
    ttk::label $wi.bridge.fwddelay.label -text "Forwarding delay:"
    ttk::spinbox $wi.bridge.fwddelay.box -width 2 \
	-from 4 -to 30 -increment 1 \
	-validatecommand {checkIntRange %P 4 30} \
	-invalidcommand "focusAndFlash %W"
    set bridgeFwdDelay [getBridgeFwdDelay $node bridge0]
    set bridgeMaxAge [getBridgeMaxAge $node bridge0]
    if { $bridgeFwdDelay != "" } {
	$wi.bridge.fwddelay.box insert 0 $bridgeFwdDelay
    } else {
	$wi.bridge.fwddelay.box insert 0 20
    }

    ttk::frame $wi.bridge.holdcnt -padding 2
    ttk::label $wi.bridge.holdcnt.label -text "Hold count:"
    ttk::spinbox $wi.bridge.holdcnt.box -width 2 \
	-from 1 -to 10 -increment 1 \
	-validatecommand {checkIntRange %P 1 10} \
	-invalidcommand "focusAndFlash %W"
    set bridgeHoldCnt [getBridgeHoldCount $node bridge0]
    if { $bridgeHoldCnt != "" } {
	$wi.bridge.holdcnt.box insert 0 $bridgeHoldCnt
    } else {
	$wi.bridge.holdcnt.box insert 0 20
    }

    ttk::frame $wi.bridge.hellotime -padding 2
    ttk::label $wi.bridge.hellotime.label -text "Hello time:"
    ttk::spinbox $wi.bridge.hellotime.box -width 2 \
	-from 1 -to 2 -increment 1 \
	-validatecommand {checkIntRange %P 1 2} \
	-invalidcommand "focusAndFlash %W"
    set bridgeHelloTime [getBridgeHelloTime $node bridge0]
    if { $bridgeHelloTime != "" } {
	$wi.bridge.hellotime.box insert 0 $bridgeHelloTime
    } else {
	$wi.bridge.hellotime.box insert 0 20
    }

    ttk::frame $wi.bridge.timeout -padding 2
    ttk::label $wi.bridge.timeout.label -text "Address timeout:     "
    ttk::spinbox $wi.bridge.timeout.box -width 4 \
	-from 0 -to 3600 -increment 20 \
	-validatecommand {checkIntRange %P 0 3600} \
	-invalidcommand "focusAndFlash %W"
    set bridgeTimeout [getBridgeTimeout $node bridge0]
    if { $bridgeTimeout != "" } {
	$wi.bridge.timeout.box insert 0 $bridgeTimeout
    } else {
	$wi.bridge.timeout.box insert 0 20
    }

    ttk::frame $wi.bridge.maxaddr -padding 2
    ttk::label $wi.bridge.maxaddr.label -text "Max addresses:     "
    ttk::spinbox $wi.bridge.maxaddr.box -width 4 \
	-from 0 -to 10000 -increment 10 \
	-validatecommand {checkIntRange %P 0 10000} \
	-invalidcommand "focusAndFlash %W"
    set bridgeMaxAddr [getBridgeMaxAddr $node bridge0]
    if { $bridgeMaxAddr != "" } {
	$wi.bridge.maxaddr.box insert 0 $bridgeMaxAddr
    } else {
	$wi.bridge.maxaddr.box insert 0 20
    }

    if {$bridgeProtocol != "stp"} {
	$wi.bridge.hellotime.box configure -state disabled
    }

    pack $wi.bridge.protocols.label -side left -anchor w -expand 1 -fill x
    pack $wi.bridge.protocols.rstp $wi.bridge.protocols.stp -side left -anchor e

    pack $wi.bridge.priority.label -side left -anchor w -expand 1 -fill x
    pack $wi.bridge.priority.box -side left -anchor e

    pack $wi.bridge.holdcnt.label -side left -anchor w -expand 1 -fill x
    pack $wi.bridge.holdcnt.box -side left -anchor e

    pack $wi.bridge.maxaddr.label -side left -anchor w -expand 1 -fill x
    pack $wi.bridge.maxaddr.box -side left -anchor e

    pack $wi.bridge.maxage.label -side left -anchor w -expand 1 -fill x
    pack $wi.bridge.maxage.box -side left -anchor e

    pack $wi.bridge.fwddelay.label -side left -anchor w -expand 1 -fill x
    pack $wi.bridge.fwddelay.box -side left -anchor e

    pack $wi.bridge.hellotime.label -side left -anchor w -expand 1 -fill x
    pack $wi.bridge.hellotime.box -side left -anchor e

    pack $wi.bridge.timeout.label -side left -anchor w -expand 1 -fill x
    pack $wi.bridge.timeout.box -side left -anchor e

    pack $wi.bridge -fill both
    grid $wi.bridge.protocols -in $wi.bridge -column 0 -row 0 -sticky nsew
    grid $wi.bridge.priority -in $wi.bridge -column 0 -row 1 -sticky nsew
    grid $wi.bridge.holdcnt -in $wi.bridge -column 0 -row 2 -sticky nsew
    grid $wi.bridge.maxaddr -in $wi.bridge -column 0 -row 3 -sticky nsew

    grid $wi.bridge.maxage -in $wi.bridge -column 1 -row 0 -sticky nsew \
	-padx 10
    grid $wi.bridge.fwddelay -in $wi.bridge -column 1 -row 1 -sticky nsew \
	-padx 10
    grid $wi.bridge.hellotime -in $wi.bridge -column 1 -row 2 -sticky nsew \
	-padx 10
    grid $wi.bridge.timeout -in $wi.bridge -column 1 -row 3 -sticky nsew \
	-padx 10
}

proc configGUI_bridgeConfigApply { wi node } {
    global changed

    global bridgeProtocol
    set oldProtocol [getBridgeProtocol $node bridge0]
    if { $oldProtocol != $bridgeProtocol } {
	setBridgeProtocol $node bridge0 $bridgeProtocol
	set changed 1
    }

    set newPriority [$wi.bridge.priority.box get]
    set oldPriority [getBridgePriority $node bridge0]
    if { $oldPriority != $newPriority } {
	setBridgePriority $node bridge0 $newPriority
	set changed 1
    }

    set newHoldCount [$wi.bridge.holdcnt.box get]
    set oldHoldCount [getBridgeHoldCount $node bridge0]
    if { $oldHoldCount != $newHoldCount } {
	setBridgeHoldCount $node bridge0 $newHoldCount
	set changed 1
    }

    set newMaxAge [$wi.bridge.maxage.box get]
    set oldMaxAge [getBridgeMaxAge $node bridge0]
    if { $oldMaxAge != $newMaxAge } {
	setBridgeMaxAge $node bridge0 $newMaxAge
	set changed 1
    }

    set newFwdDelay [$wi.bridge.fwddelay.box get]
    set oldFwdDelay [getBridgeFwdDelay $node bridge0]
    if { $oldFwdDelay != $newFwdDelay } {
	setBridgeFwdDelay $node bridge0 $newFwdDelay
	set changed 1
    }

    set newHelloTime [$wi.bridge.hellotime.box get]
    set oldHelloTime [getBridgeHelloTime $node bridge0]
    if { $oldHelloTime != $newHelloTime } {
	setBridgeHelloTime $node bridge0 $newHelloTime
	set changed 1
    }

    set newMaxAddr [$wi.bridge.maxaddr.box get]
    set oldMaxAddr [getBridgeMaxAddr $node bridge0]
    if { $oldMaxAddr != $newMaxAddr } {
	setBridgeMaxAddr $node bridge0 $newMaxAddr
	set changed 1
    }

    set newTimeout [$wi.bridge.timeout.box get]
    set oldTimeout [getBridgeTimeout $node bridge0]
    if { $oldTimeout != $newTimeout } {
	setBridgeTimeout $node bridge0 $newTimeout
	set changed 1
    }
}

#****f* nodecfgGUI.tcl/configGUI_addTree
# NAME
#   configGUI_addTree
# SYNOPSIS
#   configGUI_addTree $wi $node
# FUNCTION
#   Creates ttk::treeview widget with interface names and
#   their other parameters.
# INPUTS
#   * wi - widget
#   * node - node id
#****
proc configGUI_addBridgeTree { wi node } {

    global brtreecolumns cancel
    #
    #cancel - indicates if the user has clicked on Cancel in the popup window
    #	      about saving changes on the previously selected interface in the
    #	      list of interfaces, 1 for yes, 0 otherwise
    #
    set cancel 0

    ttk::frame $wi.panwin.f1.grid
    ttk::treeview $wi.panwin.f1.tree -height 5 -selectmode browse \
	-xscrollcommand "$wi.panwin.f1.hscroll set"\
	-yscrollcommand "$wi.panwin.f1.vscroll set"
    ttk::scrollbar $wi.panwin.f1.hscroll -orient horizontal \
	-command "$wi.panwin.f1.tree xview"
    ttk::scrollbar $wi.panwin.f1.vscroll -orient vertical \
	-command "$wi.panwin.f1.tree yview"
    focus $wi.panwin.f1.tree

    set column_ids ""
    foreach column $brtreecolumns {
	lappend columns_ids [lindex $column 0]
    }

    #Creating columns
    $wi.panwin.f1.tree configure -columns $columns_ids

    $wi.panwin.f1.tree column #0 -width 72 -minwidth 70 -stretch 0
    foreach column $brtreecolumns {
	if { [lindex $column 0] in {"Stp" "Ptp"} } {
	    $wi.panwin.f1.tree column [lindex $column 0] -width 40 -minwidth 2 \
		-anchor center -stretch 0
	} elseif { [lindex $column 0] in {"Edge"} } {
            $wi.panwin.f1.tree column [lindex $column 0] -width 45 -minwidth 2 \
		-anchor center -stretch 0
	} elseif { [lindex $column 0] in {"Snoop" "Learn" "Sticky"} } {
            $wi.panwin.f1.tree column [lindex $column 0] -width 50 -minwidth 2 \
		-anchor center -stretch 0
	} elseif { [lindex $column 0] in {"Priority" "Private"} } {
            $wi.panwin.f1.tree column [lindex $column 0] -width 60 -minwidth 2 \
		-anchor center -stretch 0
	} elseif { [lindex $column 0] in {"Discover" "Autoptp"} } {
            $wi.panwin.f1.tree column [lindex $column 0] -width 70 -minwidth 2 \
		-anchor center -stretch 0
        } else {
	    $wi.panwin.f1.tree column [lindex $column 0] -width 75 -minwidth 2 \
		-anchor center -stretch 0
	}
	$wi.panwin.f1.tree heading [lindex $column 0] \
	    -text [join [lrange $column 1 end]]
    }

    $wi.panwin.f1.tree heading #0 \
	-command "if { [lsearch [pack slaves .popup] .popup.nbook] != -1 } {
		      .popup.nbook configure -width 845
		  }"
    $wi.panwin.f1.tree heading #0 -text "(Expand)"

    #Creating new items
    $wi.panwin.f1.tree insert {} end -id interfaces -text "Bridge" -open true \
	-tags interfaces
    $wi.panwin.f1.tree focus interfaces
    $wi.panwin.f1.tree selection set interfaces

    foreach ifc [lsort -dictionary [ifcList $node]] {
	$wi.panwin.f1.tree insert interfaces end -id $ifc -text "$ifc" \
	    -tags $ifc
	foreach column $brtreecolumns {
	    $wi.panwin.f1.tree set $ifc [lindex $column 0] \
		[getBridgeIfc[lindex $column 0] $node $ifc]
	}
	foreach column $brtreecolumns {
	    if {[lindex $column 0] ni {"Pathcost" "Maxaddr" "Priority"}} {
		set setting [getBridgeIfc[lindex $column 0] $node $ifc]
		if {$setting == 0} {
		    $wi.panwin.f1.tree set $ifc [lindex $column 0] "-"
		}
		if {$setting == 1} {
		    $wi.panwin.f1.tree set $ifc [lindex $column 0] "+"
		}
	    }
	    if {[getBridgeIfcSnoop $node $ifc] == 1 && \
		[lindex $column 0] != "Snoop"} {
		$wi.panwin.f1.tree set $ifc [lindex $column 0] "-"
	    }
	}
    }

    #Setting focus and selection on the first interface in the list or on the
    #interface selected in the topology tree and calling procedure
    #configGUI_showIfcInfo with that interfaces as the second argument
    global selectedIfc
    if {[ifcList $node] != "" && $selectedIfc == ""} {
	$wi.panwin.f1.tree focus [lindex [lsort -ascii [ifcList $node]] 0]
	$wi.panwin.f1.tree selection set \
	    [lindex [lsort -ascii [ifcList $node]] 0]
	set cancel 0
	configGUI_showBridgeIfcInfo $wi.panwin.f2 0 $node \
	    [lindex [lsort -ascii [ifcList $node]] 0]
    }
    if {[ifcList $node] != "" && $selectedIfc != ""} {
	$wi.panwin.f1.tree focus $selectedIfc
	$wi.panwin.f1.tree selection set $selectedIfc
	set cancel 0
	configGUI_showBridgeIfcInfo $wi.panwin.f2 0 $node $selectedIfc
    }

    #binding for tag interfaces
    $wi.panwin.f1.tree tag bind interfaces <1> \
	    "configGUI_showBridgeIfcInfo $wi.panwin.f2 0 $node \"\""
    $wi.panwin.f1.tree tag bind interfaces <Key-Down> \
	    "if {[llength [ifcList $node]] != 0} {
		configGUI_showBridgeIfcInfo $wi.panwin.f2 0 $node \
		    [lindex [lsort -ascii [ifcList $node]] 0]
	    }"

    #binding for tags $ifc
    foreach ifc [lsort -dictionary [ifcList $node]] {
	$wi.panwin.f1.tree tag bind $ifc <1> \
	  "$wi.panwin.f1.tree focus $ifc
	   $wi.panwin.f1.tree selection set $ifc
           configGUI_showBridgeIfcInfo $wi.panwin.f2 0 $node $ifc"
	#pathname prev item:
	#Returns the identifier of item's previous sibling, or {} if item is the
	#first child of its parent. Ako sucelje $ifc nije prvo dijete svog
	#roditelja onda je zadnji argument procedure #configGUI_showIfcInfo
	#jednak prethodnom djetetu (prethodno sucelje). Inace se radi o itemu
	#Interfaces pa je zadnji argument procedure configGUI_showIfcInfo
	#jednak "" i u tom slucaju se iz donjeg panea brise frame s
	#informacijama o prethodnom sucelju.
	$wi.panwin.f1.tree tag bind $ifc <Key-Up> \
	    "if {![string equal {} [$wi.panwin.f1.tree prev $ifc]]} {
		configGUI_showBridgeIfcInfo $wi.panwin.f2 0 $node \
		    [$wi.panwin.f1.tree prev $ifc]
	    } else {
		configGUI_showBridgeIfcInfo $wi.panwin.f2 0 $node \"\"
	    }"
	#pathname next item:
	#Returns the identifier of item's next sibling, or {} if item is the
	#last child of its parent. Ako sucelje $ifc nije zadnje dijete svog
	#roditelja onda je zadnji argument procedure configGUI_showIfcInfo
	#jednak iducem djetetu (iduce sucelje). Inace se ne poziva procedura
	#configGUI_showIfcInfo.
	$wi.panwin.f1.tree tag bind $ifc <Key-Down> \
	    "if {![string equal {} [$wi.panwin.f1.tree next $ifc]]} {
		configGUI_showBridgeIfcInfo $wi.panwin.f2 0 $node \
		    [$wi.panwin.f1.tree next $ifc]
	    }"
    }

    pack $wi.panwin.f1.grid -fill both -expand 1
    grid $wi.panwin.f1.tree $wi.panwin.f1.vscroll -in $wi.panwin.f1.grid \
	-sticky nsew
    grid  $wi.panwin.f1.hscroll -in $wi.panwin.f1.grid -sticky nsew
    grid columnconfig $wi.panwin.f1.grid 0 -weight 1
    grid rowconfigure $wi.panwin.f1.grid 0 -weight 1
}


#****f* nodecfgGUI.tcl/configGUI_refreshBridgeIfcsTree
# NAME
#   configGUI_refreshBridgeIfcsTree
# SYNOPSIS
#   configGUI_refreshBridgeIfcsTree $wi $node
# FUNCTION
#   Refreshes the tree with the list of interfaces.
# INPUTS
#   * wi - widget
#   * node - node id
#****
proc configGUI_refreshBridgeIfcsTree { wi node } {
    global brtreecolumns
    foreach ifc [lsort -dictionary [ifcList $node]] {
        foreach column $brtreecolumns {
	    $wi set $ifc [lindex $column 0] [getBridgeIfc[lindex $column 0] \
		$node $ifc]
	}
	foreach column $brtreecolumns {
	    if {[lindex $column 0] ni {"Pathcost" "Maxaddr" "Priority"}} {
		set setting [getBridgeIfc[lindex $column 0] $node $ifc]
		if {$setting == 0} {
		    $wi set $ifc [lindex $column 0] "-"
		}
		if {$setting == 1} {
		    $wi set $ifc [lindex $column 0] "+"
		}
	    }
	    if {[getBridgeIfcSnoop $node $ifc] == 1 && \
		[lindex $column 0] != "Snoop"} {
		$wi set $ifc [lindex $column 0] "-"
	    }
	}
    }
}


#****f* nodecfgGUI.tcl/configGUI_showIfcInfo
# NAME
#   configGUI_showIfcInfo
# SYNOPSIS
#   configGUI_showIfcInfo $wi $phase $node $ifc
# FUNCTION
#   Shows parameters of the interface selected in the
#   list of interfaces. Parameters are shown below that list.
# INPUTS
#   * wi - widget
#   * phase - This pocedure is invoked in two diffenet phases
#     to enable validation of the entry that was the last made.
#     When calling this function always use the phase parameter
#     set to 0.
#   * node - node id
#   * ifc - interface id
#****
proc configGUI_showBridgeIfcInfo { wi phase node ifc } {
    global guielements brguielements
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
		after 100 "configGUI_showBridgeIfcInfo $wi 1 $node $ifc"
	    } else {
		after 100 "configGUI_showBridgeIfcInfo $wi 1 $node \"\""
	    }
	    return
	} elseif { $badentry } {
	    [string trimright $wi .f2].f1.tree selection set $shownifc
	    [string trimright $wi .f2].f1.tree focus $shownifc
	    $wi config -cursor left_ptr
	    return
	}

	foreach guielement $brguielements {
            #calling "apply" procedures to check if some parameters of
	    #previously selected interface have been changed
            if { [llength $guielement] == 2 } {
		[lindex $guielement 0]\Apply $wi $node [lindex $guielement 1]
	    }
	}

	#creating popup window with warning about unsaved changes
	if { $changed == 1 && $apply == 0 } {
 	    configGUI_saveBridgeChangesPopup $wi $node $shownifc
	}

	#if user didn't select Cancel in the popup about saving changes on
	#previously selected interface.
	if { $cancel == 0 } {
	    foreach guielement $brguielements {
		set ind [lsearch $brguielements $guielement]
		#delete corresponding elements from thi list guielements
		if {[lsearch $guielement $shownifc] != -1} {
		    set brguielements [lreplace $brguielements $ind $ind]
		}
	    }
	    foreach guielement $guielements {
		set ind [lsearch $guielements $guielement]
		#delete corresponding elements from thi list guielements
		if {[lsearch $guielement $shownifc] != -1} {
		    set guielements [lreplace $guielements $ind $ind]
		}
	    }
	    #delete frame that is already shown below the list of interfaces
	    #(shownifcframe)
	    destroy $shownifcframe

        #if user selected Cancel the in popup about saving changes on previously
	#selected interface, set focus and selection on that interface whose
	#parameters are already shown below the list of interfaces
	} else {
	     [string trimright $wi .f2].f1.tree selection set $shownifc
	     [string trimright $wi .f2].f1.tree focus $shownifc
	}
    }

    #if user didn't select Cancel in the popup about saving changes on
    #previously selected interface
    if { $cancel == 0 } {
	set type [nodeType $node]
        #creating new frame below the list of interfaces and adding modules with
	#parameters of selected interface
	if {$ifc != "" && $ifc != $shownifc} {
	    configGUI_ifcBridgeMainFrame $wi $node $ifc
	    $type.configBridgeInterfacesGUI $wi $node $ifc
	}
    }
}


#****f* nodecfgGUI.tcl/configGUI_saveChangesPopup
# NAME
#   configGUI_saveChangesPopup
# SYNOPSIS
#   configGUI_saveChangesPopup $wi $node $ifc
# FUNCTION
#   Creates a popup window with the warning about
#   unsaved changes on previously selected interface.
# INPUTS
#   * wi - widget
#   * node - node id
#   * ifc - interface id
#****
proc configGUI_saveBridgeChangesPopup { wi node ifc } {
    global guielements brguielements brtreecolumns apply cancel changed
    set answer [tk_messageBox \
	-message "Do you want to save changes on interface $ifc?" \
        -icon question -type yesnocancel \
        -detail "Select \"Yes\" to save changes before choosing another interface"]

    switch -- $answer {
        #save changes
	yes {
	    set apply 1
	    set cancel 0
	    foreach guielement $brguielements {
		if { [llength $guielement] == 2 } {
		    [lindex $guielement 0]\Apply $wi $node [lindex $guielement 1]
		}
	    }
	    #nbook - da li prozor sadrzi notebook
	    set nbook [lsearch [pack slaves .popup] .popup.nbook]
	    if { $changed == 1 } {
                if { $nbook != -1 && $brtreecolumns != "" } {
		    configGUI_refreshBridgeIfcsTree \
			.popup.nbook.nfBridge.panwin.f1.tree $node
		} elseif { $nbook == -1 && $brtreecolumns != "" } {
		    configGUI_refreshBridgeIfcsTree .popup.panwin.f1.tree $node
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

proc configGUI_ifcBridgeMainFrame { wi node ifc } {
    global apply changed
    set apply 0
    set changed 0
    ttk::frame $wi.if$ifc -relief groove -borderwidth 2 -padding 4
    ttk::frame $wi.if$ifc.label -borderwidth 2
    ttk::label $wi.if$ifc.label.txt -text "Bridge interface $ifc:"
    pack $wi.if$ifc.label.txt -side left -anchor w
    pack $wi.if$ifc.label -anchor w
    pack $wi.if$ifc -anchor w -fill both -expand 1
}

## filter
proc configGUI_addNotebookFilter { wi node labels } {
    ttk::notebook $wi.nbook -height 200
    pack $wi.nbook -fill both -expand 1
    pack propagate $wi.nbook 0
    foreach label $labels {
        ttk::frame $wi.nbook.nf$label
        $wi.nbook add $wi.nbook.nf$label -text $label
	configGUI_addFilterPanedWin $wi.nbook.nf$label
    }

    bind $wi.nbook <<NotebookTabChanged>> \
	"notebookSize $wi $node"
#    vraca popis tabova

    set tabs [$wi.nbook tabs]
    return $tabs
}

proc configGUI_addFilterPanedWin { wi } {
    ttk::panedwindow $wi.panwin -orient vertical
    ttk::frame $wi.panwin.f1
    ttk::frame $wi.panwin.f2
    ttk::frame $wi.panwin.f2.buttons

    ttk::button $wi.panwin.f2.buttons.addnew -text "Add new rule" \
	-command {
	    global changed
	    set sel [configGUI_ifcRuleConfigApply 1 0]
	    if { $changed == 1 } {
		configGUI_refreshIfcRulesTree
		set ifc [.popup.nbook tab current -text]
		set wi .popup.nbook.nf$ifc
		if { $sel != "" } {
		    $wi.panwin.f1.tree focus $sel
		    $wi.panwin.f1.tree selection set $sel
		    global curnode
		    configGUI_showFilterIfcRuleInfo $wi.panwin.f2 0 $curnode $ifc $sel
		}
		set changed 0
	    }
	}
    ttk::button $wi.panwin.f2.buttons.duprul -text "Duplicate rule" \
	-command {
	    global changed
	    set sel [configGUI_ifcRuleConfigApply 1 1]
	    if { $changed == 1 } {
		configGUI_refreshIfcRulesTree
		set ifc [.popup.nbook tab current -text]
		set wi .popup.nbook.nf$ifc
		if { $sel != "" } {
		    $wi.panwin.f1.tree focus $sel
		    $wi.panwin.f1.tree selection set $sel
		    global curnode
		    configGUI_showFilterIfcRuleInfo $wi.panwin.f2 0 $curnode $ifc $sel
		}
		set changed 0
	    }
	}
    ttk::button $wi.panwin.f2.buttons.savrul -text "Save rule" \
	-command {
	    set sel [configGUI_ifcRuleConfigApply 0 0]
	    if { $changed == 1 } {
		configGUI_refreshIfcRulesTree
		set ifc [.popup.nbook tab current -text]
		set wi .popup.nbook.nf$ifc
		if { $sel != "" } {
		    $wi.panwin.f1.tree focus $sel
		    $wi.panwin.f1.tree selection set $sel
		    global curnode
		    configGUI_showFilterIfcRuleInfo $wi.panwin.f2 0 $curnode $ifc $sel
		}
		set changed 0
	    }
	}

    ttk::button $wi.panwin.f2.buttons.delrul -text "Delete rule" \
	-command {
	    set sel [configGUI_ifcRuleConfigDelete]
	    configGUI_refreshIfcRulesTree
	    set ifc [.popup.nbook tab current -text]
	    set wi .popup.nbook.nf$ifc
	    if { $sel != "" } {
		$wi.panwin.f1.tree focus $sel
		$wi.panwin.f1.tree selection set $sel
		global curnode
		configGUI_showFilterIfcRuleInfo $wi.panwin.f2 0 $curnode $ifc $sel
	    } else {
		configGUI_showFilterIfcRuleInfo $wi.panwin.f2 0 $curnode $ifc ""
	    }
	}

    grid $wi.panwin.f2 -sticky nsew
    grid $wi.panwin.f2.buttons -column 0

    grid $wi.panwin.f2.buttons.addnew -ipadx 15 -padx 10 -pady 7 -sticky ew
    grid $wi.panwin.f2.buttons.duprul -ipadx 15 -padx 10 -pady 7 -sticky ew
    grid $wi.panwin.f2.buttons.savrul -ipadx 15 -padx 10 -pady 7 -sticky ew
    grid $wi.panwin.f2.buttons.delrul -ipadx 15 -padx 10 -pady 7 -sticky ew

    $wi.panwin add $wi.panwin.f1 -weight 5
    $wi.panwin add $wi.panwin.f2 -weight 0
    pack $wi.panwin -fill both -expand 1
}

proc configGUI_buttonsACFilterNode { wi node } {
    global badentry close guielements
    set close 0
    ttk::frame $wi.bottom
    ttk::frame $wi.bottom.buttons -borderwidth 6
    ttk::button $wi.bottom.buttons.apply -text "Apply" \
	-command "configGUI_applyFilterNode"
    ttk::button $wi.bottom.buttons.applyclose -text "Apply and Close" -command \
        "configGUI_applyFilterNode;set badentry -1;destroy $wi"
    ttk::button $wi.bottom.buttons.cancel -text "Cancel" -command \
        "set badentry -1; destroy $wi"
    pack $wi.bottom.buttons.apply $wi.bottom.buttons.applyclose \
        $wi.bottom.buttons.cancel -side left -padx 2
    pack $wi.bottom.buttons -pady 2 -expand 1
    pack $wi.bottom -fill both -side bottom
    bind $wi <Key-Escape> "set badentry -1; destroy $wi"
}

proc configGUI_applyFilterNode { } {
    global curnode changed
    configGUI_nodeNameApply .popup $curnode
    set sel [configGUI_ifcRuleConfigApply 0 0]
    if { $changed == 1 } {
	configGUI_refreshIfcRulesTree
	set ifc [.popup.nbook tab current -text]
	set wi .popup.nbook.nf$ifc
	if { $sel != "" } {
	    $wi.panwin.f1.tree focus $sel
	    $wi.panwin.f1.tree selection set $sel
	    configGUI_showFilterIfcRuleInfo $wi.panwin.f2 0 $curnode $ifc $sel
	}
	set changed 0
    }
    redrawAll
}

proc configGUI_addTreeFilter { wi node } {
    global filtertreecolumns cancel
    #
    #cancel - indicates if the user has clicked on Cancel in the popup window about
    #         saving changes on the previously selected interface in the list of interfaces,
    #         1 for yes, 0 otherwise
    #
    set cancel 0

    ttk::frame $wi.panwin.f1.grid
    ttk::treeview $wi.panwin.f1.tree -height 8 -selectmode browse \
	-xscrollcommand "$wi.panwin.f1.hscroll set"\
	-yscrollcommand "$wi.panwin.f1.vscroll set"
    ttk::scrollbar $wi.panwin.f1.hscroll -orient horizontal -command "$wi.panwin.f1.tree xview"
    ttk::scrollbar $wi.panwin.f1.vscroll -orient vertical -command "$wi.panwin.f1.tree yview"
    focus $wi.panwin.f1.tree

    set ifc [string trimleft $wi ".popup.nbook.nf"]

    set column_ids ""
    foreach column $filtertreecolumns {
	lappend columns_ids [lindex $column 0]
    }

    #Creating columns
    $wi.panwin.f1.tree configure -columns $columns_ids

    $wi.panwin.f1.tree column #0 -width 60 -minwidth 70 -stretch 0
    foreach column $filtertreecolumns {
	if { [lindex $column 0] == "Pattern" || [lindex $column 0] == "Mask" } {
	    $wi.panwin.f1.tree column [lindex $column 0] -width 144 -minwidth 2 -anchor center -stretch 0
        } else {
	    $wi.panwin.f1.tree column [lindex $column 0] -width 100 -minwidth 2 -anchor center -stretch 0
	}
	$wi.panwin.f1.tree heading [lindex $column 0] -text [join [lrange $column 1 end]]
    }

    $wi.panwin.f1.tree heading #0 -text "Rule #"

    #Creating new items

    foreach rule [lsort -integer [ifcFilterRuleList $node $ifc]] {
	$wi.panwin.f1.tree insert {} end -id $rule -text "$rule" -tags $rule
	foreach column $filtertreecolumns {
	    $wi.panwin.f1.tree set $rule [lindex $column 0] [getFilterIfc[lindex $column 0] $node $ifc $rule]
	}
    }

    #Setting focus and selection on the first interface in the list or on the interface
    #selected in the topology tree and calling procedure configGUI_showIfcInfo with that
    #interfaces as the second argument
    global selectedFilterRule
    if {[llength [ifcFilterRuleList $node $ifc]] != 0 && $selectedFilterRule == ""} {
	set sorted [lsort -integer [ifcFilterRuleList $node $ifc]]
	if { $sorted != "" } {
	    $wi.panwin.f1.tree focus [lindex $sorted 0]
	    $wi.panwin.f1.tree selection set [lindex $sorted 0]
	    set cancel 0
	    configGUI_showFilterIfcRuleInfo $wi.panwin.f2 0 $node $ifc [lindex $sorted 0]
	}
    }
    #binding for tags $ifc
    foreach rule [lsort -integer [ifcFilterRuleList $node $ifc]] {
	$wi.panwin.f1.tree tag bind $rule <1> \
	  "$wi.panwin.f1.tree focus $rule
	   $wi.panwin.f1.tree selection set $rule
           configGUI_showFilterIfcRuleInfo $wi.panwin.f2 0 $node $ifc $rule"
	$wi.panwin.f1.tree tag bind $rule <Key-Up> \
	    "if {![string equal {} [$wi.panwin.f1.tree prev $rule]]} {
		configGUI_showFilterIfcRuleInfo $wi.panwin.f2 0 $node $ifc [$wi.panwin.f1.tree prev $rule]
	    }"
	$wi.panwin.f1.tree tag bind $rule <Key-Down> \
	    "if {![string equal {} [$wi.panwin.f1.tree next $rule]]} {
		configGUI_showFilterIfcRuleInfo $wi.panwin.f2 0 $node $ifc [$wi.panwin.f1.tree next $rule]
	     }"
    }

    pack $wi.panwin.f1.grid -fill both -expand 1
    grid $wi.panwin.f1.tree $wi.panwin.f1.vscroll -in $wi.panwin.f1.grid -sticky nsew
    grid $wi.panwin.f1.hscroll -in $wi.panwin.f1.grid -sticky nsew
    grid columnconfig $wi.panwin.f1.grid 0 -weight 1
    grid rowconfigure $wi.panwin.f1.grid 0 -weight 1
}

proc configGUI_refreshIfcRulesTree { } {
    global filtertreecolumns curnode
    set node $curnode
    set ifc [.popup.nbook tab current -text]
    set rule [.popup.nbook.nf$ifc.panwin.f1.tree selection]
    set wi .popup.nbook.nf$ifc
    $wi.panwin.f1.tree delete [$wi.panwin.f1.tree children {}]
    foreach rule [lsort -integer [ifcFilterRuleList $node $ifc]] {
	$wi.panwin.f1.tree insert {} end -id $rule -text "$rule" -tags $rule
	foreach column $filtertreecolumns {
	    $wi.panwin.f1.tree set $rule [lindex $column 0] [getFilterIfc[lindex $column 0] $node $ifc $rule]
	}
    }
    foreach rule [lsort -integer [ifcFilterRuleList $node $ifc]] {
	$wi.panwin.f1.tree tag bind $rule <1> \
	  "$wi.panwin.f1.tree focus $rule
	   $wi.panwin.f1.tree selection set $rule
           configGUI_showFilterIfcRuleInfo $wi.panwin.f2 0 $node $ifc $rule"
	$wi.panwin.f1.tree tag bind $rule <Key-Up> \
	    "if {![string equal {} [$wi.panwin.f1.tree prev $rule]]} {
		configGUI_showFilterIfcRuleInfo $wi.panwin.f2 0 $node $ifc [$wi.panwin.f1.tree prev $rule]
	    }"
	$wi.panwin.f1.tree tag bind $rule <Key-Down> \
	    "if {![string equal {} [$wi.panwin.f1.tree next $rule]]} {
		configGUI_showFilterIfcRuleInfo $wi.panwin.f2 0 $node $ifc [$wi.panwin.f1.tree next $rule]
	     }"
    }
    set sorted [lsort -integer [ifcFilterRuleList $node $ifc]]
    set first [lindex $sorted 0]
    if { $first != "" } {
	$wi.panwin.f1.tree focus $first
	$wi.panwin.f1.tree selection set $first
    }
}

proc configGUI_showFilterIfcRuleInfo { wi phase node ifc rule } {
    global filterguielements
    global changed apply cancel badentry
    #
    #shownruleframe - frame that is currently shown below the list o interfaces
    #
    if { $badentry == -1 } {
	return
    }
    set shownruleframe [grid slaves $wi]
    set i [lsearch $shownruleframe "*buttons*"]
    if { $i != -1 } {
	set shownruleframe [lreplace $shownruleframe $i $i]
    }
    #
    #shownrule - interface whose parameters are shown in shownruleframe
    #
    set shownrule [string trim [lindex [split $shownruleframe .] end] if]

    #if there is already some frame shown below the list of interfaces and
    #parameters shown in that frame are not parameters of selected interface
    if {$shownruleframe != "" && $rule != $shownrule } {
        if { $phase == 0 } {
	    set badentry 0
	    if { $rule != "" } {
		after 100 "configGUI_showFilterIfcRuleInfo $wi 1 $node $ifc $rule"
	    } else {
		after 100 "configGUI_showFilterIfcRuleInfo $wi 1 $node $ifc \"\""
	    }
	    return
	} elseif { $badentry } {
	    [string trimright $wi .f2].f1.tree selection set $shownrule
	    [string trimright $wi .f2].f1.tree focus $shownrule
	    $wi config -cursor left_ptr
	    return
	}

	foreach guielement $filterguielements {
            #calling "apply" procedures to check if some parameters of previously
	    #selected interface have been changed
            if { [llength $guielement] == 0 } {
		[lindex $guielement 0]\Apply 0
	    }
	}

	#creating popup window with warning about unsaved changes
	if { $changed == 1 && $apply == 0 } {
 	    configGUI_saveChangesPopup $wi $node $shownrule
	}

	#if user didn't select Cancel in the popup about saving changes on previously selected interface
	if { $cancel == 0 } {
	    foreach guielement $filterguielements {
		set ind [lsearch $filterguielements $guielement]
		#delete corresponding elements from thi list filterguielements
		if {[lsearch $guielement $shownrule] != -1} {
		    set filterguielements [lreplace $filterguielements $ind $ind]
		}
	    }
	    #delete frame that is already shown below the list of interfaces (shownruleframe)
	    destroy $shownruleframe

        #if user selected Cancel the in popup about saving changes on previously selected interface,
	#set focus and selection on that interface whose parameters are already shown
	#below the list of interfaces
	} else {
	     [string trimright $wi .f2].f1.tree selection set $shownrule
	     [string trimright $wi .f2].f1.tree focus $shownrule
	}
    }

    #if user didn't select Cancel in the popup about saving changes on previously selected interface
    if { $cancel == 0 } {
	set type [nodeType $node]
        #creating new frame below the list of interfaces and adding modules with
	#parameters of selected interface
	if {$rule != "" && $rule != $shownrule} {
	    configGUI_ruleMainFrame $wi $node $ifc $rule
	    $type.configIfcRulesGUI $wi $node $ifc $rule
	}
    }
}

proc configGUI_saveFilterChangesPopup { wi node ifc rule } {
    global filterguielements filtertreecolumns apply cancel changed
    set answer [tk_messageBox -message "Do you want to save changes on rule $rule?" \
        -icon question -type yesnocancel \
        -detail "Select \"Yes\" to save changes before choosing another rule."]

    switch -- $answer {
        #save changes
	yes {
	    set apply 1
	    set cancel 0
	    foreach filterguielement $guielements {
		if { [llength $guielement] == 2 } {
		    [lindex $guielement 0]\Apply $wi $node [lrange $guielement 1 end]
		}
	    }
	    #nbook - da li prozor sadrzi notebook
	    if { $changed == 1 } {
                if { $filtertreecolumns != "" } {
		    configGUI_refreshIfcRulesTree
		}
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

proc configGUI_ruleMainFrame { wi node ifc rule } {
    global apply changed
    set apply 0
    set changed 0
    ttk::frame $wi.if$rule -relief groove -borderwidth 2 -padding 4
    ttk::frame $wi.if$rule.label -borderwidth 2
    ttk::label $wi.if$rule.label.txt -text "Interface $ifc (Rule $rule):"

    grid $wi.if$rule -sticky nsew -column 1 -row 0 -columnspan 10 -ipadx 45

#    grid $wi.if$rule.label.txt
#    grid $wi.if$rule.label -sticky nsw
}

proc configGUI_ifcRuleConfig { wi node ifc rule } {
    global filterguielements ifcFilterAction$ifc$rule ifcFilterActionData$ifc$rule
    global curnode

    lappend filterguielements "configGUI_ifcRuleConfig $ifc $rule"
    ttk::frame $wi.if$rule.rconfig -borderwidth 2
    ttk::label $wi.if$rule.rconfig.rntxt -text "Rule Num: " -anchor w
    ttk::entry $wi.if$rule.rconfig.rnval -width 4 \
	-validate focus -invalidcommand "focusAndFlash %W"
    $wi.if$rule.rconfig.rnval configure -validatecommand {checkRuleNum %P}
    $wi.if$rule.rconfig.rnval insert 0 $rule

    set ifcFilterAction$ifc$rule [getFilterIfcAction $node $ifc $rule]
    set ifcFilterActionData$ifc$rule [getFilterIfcActionData $node $ifc $rule]
    set values [list match_hook match_dupto match_skipto match_drop nomatch_hook \
    nomatch_dupto nomatch_skipto nomatch_drop]
    set datavalues [refreshIfcActionDataValues $node 0]

    ttk::label $wi.if$rule.rconfig.atxt -text "Action: " -anchor w
    ttk::combobox $wi.if$rule.rconfig.aval -width 12 -textvariable \
	ifcFilterAction$ifc$rule -values $values -state readonly
    bind $wi.if$rule.rconfig.aval <<ComboboxSelected>> {
	set ifc [.popup.nbook tab current -text]
	set rule [.popup.nbook.nf$ifc.panwin.f1.tree selection]
	global curnode ifcFilterAction$ifc$rule
	.popup.nbook.nf$ifc.panwin.f2.if$rule.rconfig.adval \
	    configure -values [refreshIfcActionDataValues $curnode 1] \
	    -state [actionDataState [set ifcFilterAction$ifc$rule]]
    }

    ttk::label $wi.if$rule.rconfig.adtxt -text "ActData: " -anchor w
    ttk::combobox $wi.if$rule.rconfig.adval -width 5 -textvariable \
	ifcFilterActionData$ifc$rule -values $datavalues \
	-state [actionDataState [set ifcFilterAction$ifc$rule]]

    ttk::label $wi.if$rule.rconfig.ptxt -text "Pattern: " -anchor w
    ttk::entry $wi.if$rule.rconfig.pval -width 42 -font "Courier" \
	-validate focus -invalidcommand "focusAndFlash %W"
    $wi.if$rule.rconfig.pval configure -validatecommand {checkPatternMask %P}
    $wi.if$rule.rconfig.pval insert 0 [getFilterIfcPattern $node $ifc $rule]

    ttk::label $wi.if$rule.rconfig.mtxt -text "Mask: " -anchor w
    ttk::entry $wi.if$rule.rconfig.mval -width 42 -font "Courier" \
	-validate focus -invalidcommand "focusAndFlash %W"
    $wi.if$rule.rconfig.mval configure -validatecommand {checkPatternMask %P}
    $wi.if$rule.rconfig.mval insert 0 [getFilterIfcMask $node $ifc $rule]

    ttk::label $wi.if$rule.rconfig.otxt -text "Offset: " -anchor w
    ttk::entry $wi.if$rule.rconfig.oval -width 12 \
	-validate focus -invalidcommand "focusAndFlash %W"
    $wi.if$rule.rconfig.oval configure -validatecommand {checkOffset %P}
    $wi.if$rule.rconfig.oval insert 0 [getFilterIfcOffset $node $ifc $rule]

    grid $wi.if$rule.rconfig -sticky nsew -rowspan 5

    grid $wi.if$rule.rconfig.rntxt -in $wi.if$rule.rconfig -column 0 -row 0 \
	-sticky nsew -pady 2
    grid $wi.if$rule.rconfig.rnval -in $wi.if$rule.rconfig -column 1 -row 0 \
	-sticky nsw -pady 2
    grid $wi.if$rule.rconfig.atxt -in $wi.if$rule.rconfig -column 0 -row 1 \
	-sticky nsew -pady 2
    grid $wi.if$rule.rconfig.aval -in $wi.if$rule.rconfig -column 1 -row 1 \
	-sticky nsw -pady 2
    grid $wi.if$rule.rconfig.adtxt -in $wi.if$rule.rconfig -column 2 -row 1 \
	-sticky nsw -pady 2
    grid $wi.if$rule.rconfig.adval -in $wi.if$rule.rconfig -column 3 -row 1 \
	-sticky nsw -pady 2
    grid $wi.if$rule.rconfig.ptxt -in $wi.if$rule.rconfig -column 0 -row 2 \
	-sticky nsw -pady 2
    grid $wi.if$rule.rconfig.pval -in $wi.if$rule.rconfig -column 1 -row 2 \
	-sticky nsew -pady 2 -columnspan 5
    grid $wi.if$rule.rconfig.mtxt -in $wi.if$rule.rconfig -column 0 -row 3 \
	-sticky nsew -pady 2
    grid $wi.if$rule.rconfig.mval -in $wi.if$rule.rconfig -column 1 -row 3 \
	-sticky nsew -pady 2 -columnspan 5
    grid $wi.if$rule.rconfig.otxt -in $wi.if$rule.rconfig -column 0 -row 4 \
	-sticky nsew -pady 2
    grid $wi.if$rule.rconfig.oval -in $wi.if$rule.rconfig -column 1 -row 4 \
	-sticky nsw -pady 2
}

proc configGUI_ifcRuleConfigApply { add dup } {
    global changed apply curnode

    set ruleNumChanged 0
    set noPMO 0

    set ifc [.popup.nbook tab current -text]
    set rule [.popup.nbook.nf$ifc.panwin.f1.tree selection]
    set wi .popup.nbook.nf$ifc.panwin.f2

    if { $ifc == "" || $rule == "" } {
	if { $add != 0 && $dup == 0} {
	    set new_rule "10:match_drop::"
	    addFilterIfcRule $curnode $ifc 10 $new_rule
	    set changed 1
	    return 10
	} else {
	    return ""
	}
    }

    set rulnum [$wi.if$rule.rconfig.rnval get]
    set action [$wi.if$rule.rconfig.aval get]
    set adata [$wi.if$rule.rconfig.adval get]
    set pattern [$wi.if$rule.rconfig.pval get]
    set mask [$wi.if$rule.rconfig.mval get]
    set offset [$wi.if$rule.rconfig.oval get]

    set old_rulnum $rule

    if { [checkRuleNum $rulnum] != 1 } {
	tk_dialog .dialog1 "IMUNES warning" \
	    "Rule num irregular." \
	info 0 Dismiss
	return
    }
    if { $rulnum != $old_rulnum } {
	set ruleNumChanged 1
    } else {
	if { $add != 0 } {
	    set l [lsort -integer [ifcFilterRuleList $curnode $ifc]]
	    set rulnum [expr {[lindex $l end] + 10}]
	    if { $dup == 0 } {
		set action "match_drop"
		set adata ""
		set pattern ""
		set mask ""
		set offset ""
	    } else {
		if { [llength $l] == 0 } {
		    return
		}
	    }
	}
    }
    if { $ruleNumChanged == 1 } {
	set l [ifcFilterRuleList $curnode $ifc]
	set i [lsearch $l $old_rulnum]
	set l [lreplace $l $i $i]
	if { $rulnum in $l} {
	    tk_dialog .dialog1 "IMUNES warning" \
		"Rule number already exists." \
	    info 0 Dismiss
	    return
	}
    }

    if { [checkAction $action] != 1 } {
	tk_dialog .dialog1 "IMUNES warning" \
	    "Action irregular." \
	info 0 Dismiss
	return
    }

    switch -regexp $action {
	(no)?match_hook {
	    set vals [lsort [ifcList $curnode]]
	    set c [lsearch $vals $ifc]
	    set vals [lreplace $vals $c $c]
	    if { $adata ni $vals } {
		tk_dialog .dialog1 "IMUNES warning" \
		    "ActData: Select one of the existing hooks, but not the current one ($ifc)." \
		info 0 Dismiss
		return
	    }
	}
	(no)?match_dupto {
	    set vals [lsort [ifcList $curnode]]
	    set c [lsearch $vals $ifc]
	    set vals [lreplace $vals $c $c]
	    if { $adata ni $vals } {
		tk_dialog .dialog1 "IMUNES warning" \
		    "ActData: Select one of the existing hooks, but not the current one ($ifc)." \
		info 0 Dismiss
		return
	    }
	}
	(no)?match_skipto {
	    if { $adata < $rulnum } {
		tk_dialog .dialog1 "IMUNES warning" \
		    "ActData: number < skipto destination." \
		info 0 Dismiss
		return
	    }
	}
	(no)?match_drop {
	    if { $adata != "" } {
		tk_dialog .dialog1 "IMUNES warning" \
		    "ActData: drop doesn't need additional data." \
		info 0 Dismiss
		return
	    }
	}
    }

    set pattern [string map { " " "." ":" "." } $pattern]

    if { [checkPatternMask $pattern] != 1 } {
	tk_dialog .dialog1 "IMUNES warning" \
	    "Pattern irregular." \
	info 0 Dismiss
	return
    }
    $wi.if$rule.rconfig.pval delete 0 end
    $wi.if$rule.rconfig.pval insert 0 $pattern

    if { [checkPatternMask $mask] != 1 } {
	tk_dialog .dialog1 "IMUNES warning" \
	    "Mask irregular." \
	info 0 Dismiss
	return
    }

    if { $pattern != "" && $mask == "" && $add == 0 } {
	foreach e [split $pattern "."] {
	    lappend lmask "ff"
	}
	set mask [join $lmask "."]
	$wi.if$rule.rconfig.mval insert 0 $mask
    }

    if { [string length $pattern] != [string length $mask] } {
	tk_dialog .dialog1 "IMUNES warning" \
	    "Pattern length and Mask length must match." \
	info 0 Dismiss
	return
    }

    if { [checkOffset $offset] != 1 } {
	tk_dialog .dialog1 "IMUNES warning" \
	    "Offset irregular." \
	info 0 Dismiss
	return
    }

    if { $pattern != "" && $mask != "" && $offset == ""} {
	tk_dialog .dialog1 "IMUNES warning" \
	    "Offset must be specified." \
	info 0 Dismiss
	return
    }

    if { $pattern == "" && $mask == "" } {
	if { $offset != "" } {
	    tk_dialog .dialog1 "IMUNES warning" \
		"If Pattern and Mask are both empty the Offset\
		needs to be empty too." \
	    info 0 Dismiss
	    return
	} else {
	    set noPMO 1
	}
    }

    set old_ruleline [getFilterIfcRule $curnode $ifc $old_rulnum]
    if { $noPMO == 1 } {
	set new_ruleline "$rulnum:$action\::$adata"
    } else {
	set new_ruleline "$rulnum:$action:$pattern/$mask@$offset:$adata"
    }

    if { $new_ruleline != $old_ruleline } {
	set changed 1
#	if { $apply == 1} {
	    if { $add == 0 } {
		removeFilterIfcRule $curnode $ifc $old_rulnum
		addFilterIfcRule $curnode $ifc $rulnum $new_ruleline
		return $rulnum
	    } else {
		addFilterIfcRule $curnode $ifc $rulnum $new_ruleline
		return $rulnum
	    }
#	}
    }
}

proc configGUI_ifcRuleConfigDelete { } {
    global curnode

    set ifc [.popup.nbook tab current -text]
    set rule [.popup.nbook.nf$ifc.panwin.f1.tree selection]


    removeFilterIfcRule $curnode $ifc $rule
    set next [.popup.nbook.nf$ifc.panwin.f1.tree next $rule]
    set prev [.popup.nbook.nf$ifc.panwin.f1.tree prev $rule]
    if { $next != "" } {
	return $next
    } else {
	return $prev
    }
}

proc refreshIfcActionDataValues { node refresh } {
    set vals ""
    set ifc [.popup.nbook tab current -text]
    set rule [.popup.nbook.nf$ifc.panwin.f1.tree selection]
    if {$rule == ""} {
	return $vals
    }
    global ifcFilterAction$ifc$rule ifcFilterActionData$ifc$rule
    switch -regexp [set ifcFilterAction$ifc$rule] {
	(no)?match_hook {
	    set vals [lsort [ifcList $node]]
	    set c [lsearch $vals $ifc]
	    set vals [lreplace $vals $c $c]
	    if { [set ifcFilterActionData$ifc$rule] == "" || $refresh == 1 } {
		set ifcFilterActionData$ifc$rule [lindex $vals 0]
	    }
	}
	(no)?match_dupto {
	    set vals [lsort [ifcList $node]]
	    set c [lsearch $vals $ifc]
	    set vals [lreplace $vals $c $c]
	    if { [set ifcFilterActionData$ifc$rule] == "" || $refresh == 1 } {
		set ifcFilterActionData$ifc$rule [lindex $vals 0]
	    }
	}
	(no)?match_skipto {
	    set l [lsort -integer [ifcFilterRuleList $node $ifc]]
	    set i ""
	    foreach e $l {
		if { $e > $rule} {
		    set i [lsearch $l $e]
		    break
		}
	    }
	    if { $i < [llength $l] && $i != -1 && $i != "" } {
		set l [lrange $l $i end]
	    } else {
		set l {}
	    }
	    set vals $l
	    if { [set ifcFilterActionData$ifc$rule] == "" || $refresh == 1 } {
		set ifcFilterActionData$ifc$rule [lindex $vals 0]
	    }
	}
	(no)?match_drop {
	    set vals ""
	    set ifcFilterActionData$ifc$rule ""
	}
    }
    return $vals
}

proc actionDataState { actionValue } {
    switch -regexp $actionValue {
	(no)?match_skipto {
	    return normal
	}
	default {
	    return readonly
	}
    }
}

## packgen
proc configGUI_addNotebookPackgen { wi node } {
    ttk::notebook $wi.nbook -height 200
    pack $wi.nbook -fill both -expand 1
    pack propagate $wi.nbook 0

    ttk::frame $wi.nbook.nfConfiguration
    $wi.nbook add $wi.nbook.nfConfiguration -text Configuration
    configGUI_addPackgenPanedWin $wi.nbook.nfConfiguration

    bind $wi.nbook <<NotebookTabChanged>> \
	"notebookSize $wi $node"
#    vraca popis tabova

    set tabs [$wi.nbook tabs]
    return $tabs
}

proc configGUI_packetRate { wi node } {
    set wi $wi.panwin.f1

    ttk::frame $wi.packetRate
    ttk::label $wi.packetRate.label -text "Packet rate (pps):"
    ttk::spinbox $wi.packetRate.box -width 10 \
	-from 100 -to 1000000 -increment 100 \
	-validatecommand {checkIntRange %P 1 1000000} \
	-invalidcommand "focusAndFlash %W"

    $wi.packetRate.box insert 0 [getPackgenPacketRate $node]

    grid $wi.packetRate.label -in $wi.packetRate -row 0 -column 0
    grid $wi.packetRate.box -in $wi.packetRate -row 0 -column 1
    pack $wi.packetRate -fill both -expand 1 -padx 4 -pady 10
}

proc configGUI_packetRateApply { } {
    global curnode
    set wi .popup.nbook.nfConfiguration.panwin.f1

    set newPacketRate [$wi.packetRate.box get]
    set oldPacketRate [getPackgenPacketRate $curnode]
    if { $newPacketRate != $oldPacketRate } {
	setPackgenPacketRate $curnode $newPacketRate
    }
}

proc configGUI_addPackgenPanedWin { wi } {
    ttk::panedwindow $wi.panwin -orient vertical
    ttk::frame $wi.panwin.f1
    ttk::frame $wi.panwin.f2
    ttk::frame $wi.panwin.f2.buttons

    ttk::button $wi.panwin.f2.buttons.addpac -text "Add new packet" \
	-command {
	    global changed
	    set sel [configGUI_packetConfigApply 1 0]
	    if { $changed == 1 } {
		configGUI_refreshPacketsTree
		if { $sel != "" } {
		    set wi .popup.nbook.nfConfiguration
		    $wi.panwin.f1.tree focus $sel
		    $wi.panwin.f1.tree selection set $sel
		    global curnode
		    configGUI_showPacketInfo $wi.panwin.f2 0 $curnode $sel
		}
		set changed 0
	    }
	}
    ttk::button $wi.panwin.f2.buttons.duppac -text "Duplicate packet" \
	-command {
	    global changed
	    set sel [configGUI_packetConfigApply 1 1]
	    if { $changed == 1 } {
		configGUI_refreshPacketsTree
		if { $sel != "" } {
		    set wi .popup.nbook.nfConfiguration
		    $wi.panwin.f1.tree focus $sel
		    $wi.panwin.f1.tree selection set $sel
		    global curnode
		    configGUI_showPacketInfo $wi.panwin.f2 0 $curnode $sel
		}
		set changed 0
	    }
	}
    ttk::button $wi.panwin.f2.buttons.savpac -text "Save packet" \
	-command {
	    set sel [configGUI_packetConfigApply 0 0]
	    if { $changed == 1 } {
		configGUI_refreshPacketsTree
		if { $sel != "" } {
		    set wi .popup.nbook.nfConfiguration
		    $wi.panwin.f1.tree focus $sel
		    $wi.panwin.f1.tree selection set $sel
		    global curnode
		    configGUI_showPacketInfo $wi.panwin.f2 0 $curnode $sel
		}
		set changed 0
	    }
	}

    ttk::button $wi.panwin.f2.buttons.delpac -text "Delete packet" \
	-command {
	    set sel [configGUI_packetConfigDelete]
	    configGUI_refreshPacketsTree
	    set wi .popup.nbook.nfConfiguration
	    if { $sel != "" } {
		$wi.panwin.f1.tree focus $sel
		$wi.panwin.f1.tree selection set $sel
		global curnode
		configGUI_showPacketInfo $wi.panwin.f2 0 $curnode $sel
	    } else {
		configGUI_showPacketInfo $wi.panwin.f2 0 $curnode ""
	    }
	}

    grid $wi.panwin.f2 -sticky nsew
    grid $wi.panwin.f2.buttons -column 0

    grid $wi.panwin.f2.buttons.addpac -ipadx 15 -padx 10 -pady 10 -sticky ew
    grid $wi.panwin.f2.buttons.duppac -ipadx 15 -padx 10 -pady 10 -sticky ew
    grid $wi.panwin.f2.buttons.savpac -ipadx 15 -padx 10 -pady 10 -sticky ew
    grid $wi.panwin.f2.buttons.delpac -ipadx 15 -padx 10 -pady 10 -sticky ew

    $wi.panwin add $wi.panwin.f1 -weight 5
    $wi.panwin add $wi.panwin.f2 -weight 0
    pack $wi.panwin -fill both -expand 1
}

proc configGUI_buttonsACPackgenNode { wi node } {
    global badentry close guielements
    set close 0
    ttk::frame $wi.bottom
    ttk::frame $wi.bottom.buttons -borderwidth 6
    ttk::button $wi.bottom.buttons.apply -text "Apply" -command \
        {
	    configGUI_packetRateApply
	    set sel [configGUI_packetConfigApply 0 0]
	    if { $changed == 1 } {
		configGUI_refreshPacketsTree
		if { $sel != "" } {
		    set wi .popup.nbook.nfConfiguration
		    $wi.panwin.f1.tree focus $sel
		    $wi.panwin.f1.tree selection set $sel
		    global curnode
		    configGUI_showPacketInfo $wi.panwin.f2 0 $curnode $sel
		}
		set changed 0
	    }
	}
    ttk::button $wi.bottom.buttons.applyclose -text "Apply and Close" -command \
        "configGUI_packetRateApply; configGUI_packetConfigApply 0 0;set badentry -1;destroy $wi"
    ttk::button $wi.bottom.buttons.cancel -text "Cancel" -command \
        "set badentry -1; destroy $wi"
    pack $wi.bottom.buttons.apply $wi.bottom.buttons.applyclose \
        $wi.bottom.buttons.cancel -side left -padx 2
    pack $wi.bottom.buttons -pady 2 -expand 1
    pack $wi.bottom -fill both -side bottom
    bind $wi <Key-Escape> "set badentry -1; destroy $wi"
}

proc configGUI_addTreePackgen { wi node } {
    global packgentreecolumns cancel
    #
    #cancel - indicates if the user has clicked on Cancel in the popup window about
    #         saving changes on the previously selected interface in the list of interfaces,
    #         1 for yes, 0 otherwise
    #
    set cancel 0

    ttk::frame $wi.panwin.f1.grid
    ttk::treeview $wi.panwin.f1.tree -height 8 -selectmode browse \
	-xscrollcommand "$wi.panwin.f1.hscroll set"\
	-yscrollcommand "$wi.panwin.f1.vscroll set"
    ttk::scrollbar $wi.panwin.f1.hscroll -orient horizontal -command "$wi.panwin.f1.tree xview"
    ttk::scrollbar $wi.panwin.f1.vscroll -orient vertical -command "$wi.panwin.f1.tree yview"
    focus $wi.panwin.f1.tree

    set ifc [string trimleft $wi ".popup.nbook.nf"]

    set column_ids ""
    foreach column $packgentreecolumns {
	lappend columns_ids [lindex $column 0]
    }

    #Creating columns
    $wi.panwin.f1.tree configure -columns $columns_ids

    $wi.panwin.f1.tree column #0 -width 60 -minwidth 70 -stretch 0
    foreach column $packgentreecolumns {
	$wi.panwin.f1.tree column [lindex $column 0] -width 574 -minwidth 2 -anchor center -stretch 0
	$wi.panwin.f1.tree heading [lindex $column 0] -text [join [lrange $column 1 end]]
    }

    $wi.panwin.f1.tree heading #0 -text "ID"

    #Creating new items

    foreach packet [lsort -integer [packgenPackets $node]] {
	$wi.panwin.f1.tree insert {} end -id $packet -text "$packet" -tags $packet
	foreach column $packgentreecolumns {
	    $wi.panwin.f1.tree set $packet [lindex $column 0] [getPackgenPacket[lindex $column 0] $node $packet]
	}
    }

    #Setting focus and selection on the first interface in the list or on the interface
    #selected in the topology tree and calling procedure configGUI_showIfcInfo with that
    #interfaces as the second argument
    global selectedPackgenPacket
    if {[llength [packgenPackets $node]] != 0 && $selectedPackgenPacket == ""} {
	set sorted [lsort -integer [packgenPackets $node]]
	if { $sorted != "" } {
	    $wi.panwin.f1.tree focus [lindex $sorted 0]
	    $wi.panwin.f1.tree selection set [lindex $sorted 0]
	    set cancel 0
	    configGUI_showPacketInfo $wi.panwin.f2 0 $node [lindex $sorted 0]
	}
    }
    #binding for tags $ifc
    foreach packet [lsort -integer [packgenPackets $node]] {
	$wi.panwin.f1.tree tag bind $packet <1> \
	  "$wi.panwin.f1.tree focus $packet
	   $wi.panwin.f1.tree selection set $packet
           configGUI_showPacketInfo $wi.panwin.f2 0 $node $packet"
	$wi.panwin.f1.tree tag bind $packet <Key-Up> \
	    "if {![string equal {} [$wi.panwin.f1.tree prev $packet]]} {
		configGUI_showPacketInfo $wi.panwin.f2 0 $node [$wi.panwin.f1.tree prev $packet]
	    }"
	$wi.panwin.f1.tree tag bind $packet <Key-Down> \
	    "if {![string equal {} [$wi.panwin.f1.tree next $packet]]} {
		configGUI_showPacketInfo $wi.panwin.f2 0 $node [$wi.panwin.f1.tree next $packet]
	     }"
    }

    pack $wi.panwin.f1.grid -fill both -expand 1
    grid $wi.panwin.f1.tree $wi.panwin.f1.vscroll -in $wi.panwin.f1.grid -sticky nsew
    grid $wi.panwin.f1.hscroll -in $wi.panwin.f1.grid -sticky nsew
    grid columnconfig $wi.panwin.f1.grid 0 -weight 1
    grid rowconfigure $wi.panwin.f1.grid 0 -weight 1
}

proc configGUI_refreshPacketsTree { } {
    global packgentreecolumns curnode
    set node $curnode
    set tab [.popup.nbook tab current -text]
    set packet [.popup.nbook.nf$tab.panwin.f1.tree selection]
    set wi .popup.nbook.nf$tab
    $wi.panwin.f1.tree delete [$wi.panwin.f1.tree children {}]
    foreach pac [lsort -integer [packgenPackets $node]] {
	$wi.panwin.f1.tree insert {} end -id $pac -text "$pac" -tags $pac
	foreach column $packgentreecolumns {
	    $wi.panwin.f1.tree set $pac [lindex $column 0] [getPackgenPacket[lindex $column 0] $node $pac]
	}
    }
    foreach pac [lsort -integer [packgenPackets $node]] {
	$wi.panwin.f1.tree tag bind $pac <1> \
	  "$wi.panwin.f1.tree focus $pac
	   $wi.panwin.f1.tree selection set $pac
           configGUI_showPacketInfo $wi.panwin.f2 0 $node $pac"
	$wi.panwin.f1.tree tag bind $pac <Key-Up> \
	    "if {![string equal {} [$wi.panwin.f1.tree prev $pac]]} {
		configGUI_showPacketInfo $wi.panwin.f2 0 $node [$wi.panwin.f1.tree prev $pac]
	    }"
	$wi.panwin.f1.tree tag bind $pac <Key-Down> \
	    "if {![string equal {} [$wi.panwin.f1.tree next $pac]]} {
		configGUI_showPacketInfo $wi.panwin.f2 0 $node [$wi.panwin.f1.tree next $pac]
	     }"
    }
    set sorted [lsort -integer [packgenPackets $node]]
    set first [lindex $sorted 0]
    if { $first != "" } {
	$wi.panwin.f1.tree focus $first
	$wi.panwin.f1.tree selection set $first
    }
}

proc configGUI_showPacketInfo { wi phase node pac } {
    global packgenguielements
    global changed apply cancel badentry
    #
    #shownruleframe - frame that is currently shown below the list o interfaces
    #
    set shownpacframe [grid slaves $wi]
    set i [lsearch $shownpacframe "*buttons*"]
    if { $i != -1 } {
	set shownpacframe [lreplace $shownpacframe $i $i]
    }
    #
    #shownrule - interface whose parameters are shown in shownruleframe
    #
    set shownpac [string trim [lindex [split $shownpacframe .] end] if]

    #if there is already some frame shown below the list of interfaces and
    #parameters shown in that frame are not parameters of selected interface
    if {$shownpacframe != "" && $pac != $shownpac } {
        if { $phase == 0 } {
	    set badentry 0
	    if { $pac != "" } {
		after 100 "configGUI_showPacketInfo $wi 1 $node $pac"
	    } else {
		after 100 "configGUI_showPacketInfo $wi 1 $node \"\""
	    }
	    return
	} elseif { $badentry } {
	    [string trimright $wi .f2].f1.tree selection set $shownpac
	    [string trimright $wi .f2].f1.tree focus $shownpac
	    $wi config -cursor left_ptr
	    return
	}

	foreach guielement $packgenguielements {
            #calling "apply" procedures to check if some parameters of previously
	    #selected interface have been changed
            if { [llength $guielement] == 0 } {
		[lindex $guielement 0]\Apply 0
	    }
	}

	#creating popup window with warning about unsaved changes
	if { $changed == 1 && $apply == 0 } {
 	    configGUI_saveChangesPopup $wi $node $shownpac
	}

	#if user didn't select Cancel in the popup about saving changes on previously selected interface
	if { $cancel == 0 } {
	    foreach guielement $packgenguielements {
		set ind [lsearch $packgenguielements $guielement]
		#delete corresponding elements from thi list packgenguielements
		if {[lsearch $guielement $shownpac] != -1} {
		    set packgenguielements [lreplace $packgenguielements $ind $ind]
		}
	    }
	    #delete frame that is already shown below the list of interfaces (shownruleframe)
	    destroy $shownpacframe

        #if user selected Cancel the in popup about saving changes on previously selected interface,
	#set focus and selection on that interface whose parameters are already shown
	#below the list of interfaces
	} else {
	     [string trimright $wi .f2].f1.tree selection set $shownpac
	     [string trimright $wi .f2].f1.tree focus $shownpac
	}
    }

    #if user didn't select Cancel in the popup about saving changes on previously selected interface
    if { $cancel == 0 } {
	set type [nodeType $node]
        #creating new frame below the list of interfaces and adding modules with
	#parameters of selected interface
	if {$pac != "" && $pac != $shownpac} {
	    configGUI_packetMainFrame $wi $node $pac
	    $type.configPacketsGUI $wi $node $pac
	}
    }
}

proc configGUI_savePackgenChangesPopup { wi node pac } {
    global packgenguielements packgentreecolumns apply cancel changed
    set answer [tk_messageBox -message "Do you want to save changes of packet $pac?" \
        -icon question -type yesnocancel \
        -detail "Select \"Yes\" to save changes before choosing another rule."]

    switch -- $answer {
        #save changes
	yes {
	    set apply 1
	    set cancel 0
	    foreach packgenguielement $guielements {
		if { [llength $guielement] == 2 } {
		    [lindex $guielement 0]\Apply $wi $node [lrange $guielement 1 end]
		}
	    }
	    #nbook - da li prozor sadrzi notebook
	    if { $changed == 1 } {
                if { $packgentreecolumns != "" } {
		    configGUI_refreshPacketsTree
		}
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

proc configGUI_packetMainFrame { wi node pac } {
    global apply changed
    set apply 0
    set changed 0
    ttk::frame $wi.if$pac -relief groove -borderwidth 2 -padding 4
    ttk::frame $wi.if$pac.label -borderwidth 2
    ttk::label $wi.if$pac.label.txt -text "Packet $pac:"

    grid $wi.if$pac -sticky nsw -column 1 -row 0 -columnspan 10
}

proc configGUI_packetConfig { wi node pac } {
    global packgenguielements
    global curnode

    lappend packgenguielements "configGUI_packetConfig $pac"
    ttk::frame $wi.if$pac.rconfig -borderwidth 2
    ttk::label $wi.if$pac.rconfig.rntxt -text "Packet ID: " -anchor w
    ttk::entry $wi.if$pac.rconfig.rnval -width 4 \
	-validate focus -invalidcommand "focusAndFlash %W"
    $wi.if$pac.rconfig.rnval configure -validatecommand {checkRuleNum %P}
    $wi.if$pac.rconfig.rnval insert 0 $pac

    ttk::label $wi.if$pac.rconfig.ptxt -text "Packet data: " -anchor w
    text $wi.if$pac.rconfig.pval -width 48 -height 8 -font "Courier 10"

    set pdata [getPackgenPacketData $node $pac]
    set text ""
    for {set byte [string range $pdata 0 1]; set i 0} {$byte != ""} {} {
	incr i
	if {$i == 16} {
	    set i 0
	    set text "[set text]$byte\n"
	} else {
	    set text "[set text]$byte "
	}
	set pdata [string range $pdata 2 end]
	set byte [string range $pdata 0 1]
    }
    $wi.if$pac.rconfig.pval insert end $text

    grid $wi.if$pac.rconfig -sticky nsew -rowspan 5

    grid $wi.if$pac.rconfig.rntxt -in $wi.if$pac.rconfig -column 0 -row 0 \
	-sticky nsew -pady 2
    grid $wi.if$pac.rconfig.rnval -in $wi.if$pac.rconfig -column 1 -row 0 \
	-sticky nsw -pady 2
    grid $wi.if$pac.rconfig.ptxt -in $wi.if$pac.rconfig -column 0 -row 1 \
	-sticky nw -pady 2
    grid $wi.if$pac.rconfig.pval -in $wi.if$pac.rconfig -column 1 -row 1 \
	-sticky nsew -pady 2
}

proc configGUI_packetConfigApply { add dup } {
    global changed apply curnode

    set pacNumChanged 0

    set pac [.popup.nbook.nfConfiguration.panwin.f1.tree selection]
    set wi .popup.nbook.nfConfiguration.panwin.f2

    if { $pac == "" } {
	if { $add != 0 && $dup == 0} {
	    set new_pac "10:"
	    addPackgenPacket $curnode 10 $new_pac
	    set changed 1
	    return 10
	} else {
	    return ""
	}
    }

    set pacnum [$wi.if$pac.rconfig.rnval get]
    set text [$wi.if$pac.rconfig.pval get 1.0 end]

    set old_pacnum $pac

    if { [checkRuleNum $pacnum] != 1 } {
	tk_dialog .dialog1 "IMUNES warning" \
	    "Packet ID irregular." \
	info 0 Dismiss
	return
    }

    set pdata ""
    foreach line [split $text "\n"] {
	set line [string map {":" " " "." " "} [string trim $line]]

	# Attempt to detect & preprocess lines pasted from Wireshark
	if {[string is xdigit [string range $line 0 3]] &&
	  [string range $line 4 5] eq "  "} {
	    if {[string range $line 29 30] eq "  "} {
		set line [string replace $line 29 29]
	    }
	    set line [string range $line 6 end]
	}
	foreach byte [split $line " "] {
	    if {$byte == "" || ![string is xdigit $byte]} {
		break
	    }
	    set pdata "[set pdata]$byte"
	}
    }

# XXX fixme!
if {0} {
    if { [checkPacketData $pdata] != 1 } {
	tk_dialog .dialog1 "IMUNES warning" \
	    "Packet data irregular." \
	info 0 Dismiss
	return
    }
}

    if { $pacnum != $old_pacnum } {
	set pacNumChanged 1
    } else {
	if { $add != 0 } {
	    set l [lsort -integer [packgenPackets $curnode]]
	    set pacnum [expr {[lindex $l end] + 10}]
	    if { $dup == 0 } {
		set pdata ""
	    } else {
		if { [llength $l] == 0 } {
		    return
		}
	    }
	}
    }
    if { $pacNumChanged == 1 } {
	set l [packgenPackets $curnode]
	set i [lsearch $l $old_pacnum]
	set l [lreplace $l $i $i]
	if { $pacnum in $l} {
	    tk_dialog .dialog1 "IMUNES warning" \
		"Packet ID already exists." \
	    info 0 Dismiss
	    return
	}
    }

#    set pdata [string map { ":" " " "." " " } $pdata]
#
#    $wi.if$pac.rconfig.pval delete 1.0 end
#    $wi.if$pac.rconfig.pval insert end $pdata

    set old_packet [getPackgenPacket $curnode $old_pacnum]
    set new_packet "$pacnum:$pdata"

    if { $new_packet != $old_packet } {
	set changed 1
#	if { $apply == 1} {
	    if { $add == 0 } {
		removePackgenPacket $curnode $old_pacnum
		addPackgenPacket $curnode $pacnum $new_packet
		return $pacnum
	    } else {
		addPackgenPacket $curnode $pacnum $new_packet
		return $pacnum
	    }
#	}
    }
}

proc configGUI_packetConfigDelete { } {
    global curnode

    set pac [.popup.nbook.nfConfiguration.panwin.f1.tree selection]

    removePackgenPacket $curnode $pac
    set next [.popup.nbook.nfConfiguration.panwin.f1.tree next $pac]
    set prev [.popup.nbook.nfConfiguration.panwin.f1.tree prev $pac]
    if { $next != "" } {
	return $next
    } else {
	return $prev
    }
}

## nat64
## custom GUI procedures
proc configGUI_routingProtocols { wi node } {
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    global ripEnable ripngEnable ospfEnable ospf6Enable
    global guielements
    lappend guielements configGUI_routingModel
    ttk::frame $wi.routing -relief groove -borderwidth 2 -padding 2
    ttk::frame $wi.routing.protocols -padding 2
    ttk::label $wi.routing.protocols.label -text "Protocols:"

    ttk::checkbutton $wi.routing.protocols.rip -text "rip" -variable ripEnable
    ttk::checkbutton $wi.routing.protocols.ripng -text "ripng" -variable ripngEnable
    ttk::checkbutton $wi.routing.protocols.ospf -text "ospfv2" -variable ospfEnable
    ttk::checkbutton $wi.routing.protocols.ospf6 -text "ospfv3" -variable ospf6Enable

    set ripEnable [getNodeProtocolRip $node]
    set ripngEnable [getNodeProtocolRipng $node]
    set ospfEnable [getNodeProtocolOspfv2 $node]
    set ospf6Enable [getNodeProtocolOspfv3 $node]
    if { $oper_mode != "edit" } {
	$wi.routing.protocols.rip configure -state disabled
	$wi.routing.protocols.ripng configure -state disabled
	$wi.routing.protocols.ospf configure -state disabled
	$wi.routing.protocols.ospf6 configure -state disabled
    }
    pack $wi.routing.protocols.label -side left -padx 2
    pack $wi.routing.protocols.rip $wi.routing.protocols.ripng \
	$wi.routing.protocols.ospf $wi.routing.protocols.ospf6 -side left -padx 6
    pack $wi.routing.protocols -fill both -expand 1
    pack $wi.routing -fill both
}

proc configGUI_nat64Config { wi node } {
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    global guielements
    lappend guielements configGUI_nat64Config


#    ttk::frame $wi.tunconf -relief groove -borderwidth 2 -padding 2
#    ttk::label $wi.tunconf.label -text "tun interface:"
#    ttk::label $wi.tunconf.4label -text "IPv4 address:"
#    ttk::entry $wi.tunconf.4addr -width 30 -validate focus \
#     -invalidcommand "focusAndFlash %W"
#    $wi.tunconf.4addr configure -validatecommand {checkIPv4Addr %P}
#    $wi.tunconf.4addr insert 0 [getTunIPv4Addr $node]
#    ttk::label $wi.tunconf.6label -text "IPv6 address:"
#    ttk::entry $wi.tunconf.6addr -width 30 -validate focus \
#     -invalidcommand "focusAndFlash %W"
#    $wi.tunconf.6addr configure -validatecommand {checkIPv6Addr %P}
#    $wi.tunconf.6addr insert 0 [getTunIPv6Addr $node]
#    grid $wi.tunconf.label -in $wi.tunconf \
#	-column 0 -row 0 -sticky ew -pady 5
#    grid $wi.tunconf.4label -in $wi.tunconf \
#	-column 0 -row 1 -sticky ew -pady 5
#    grid $wi.tunconf.4addr -in $wi.tunconf \
#	-column 1 -row 1 -sticky ew -pady 5
#    grid $wi.tunconf.6label -in $wi.tunconf \
#	-column 0 -row 2 -sticky ew -pady 5
#    grid $wi.tunconf.6addr -in $wi.tunconf \
#	-column 1 -row 2 -sticky ew -pady 5


    ttk::frame $wi.taygaconf -relief groove -borderwidth 2 -padding 2
    ttk::label $wi.taygaconf.label -text "tayga.conf:"
#    ttk::label $wi.taygaconf.4label -text "IPv4 address:"
#    ttk::entry $wi.taygaconf.4addr -width 30 -validate focus \
#     -invalidcommand "focusAndFlash %W"
#    $wi.taygaconf.4addr configure -validatecommand {checkIPv4Addr %P}
#    $wi.taygaconf.4addr insert 0 [getTaygaIPv4Addr $node]
    ttk::label $wi.taygaconf.plabel -text "IPv6 translation prefix:"
    ttk::entry $wi.taygaconf.paddr -width 30 -validate focus \
     -invalidcommand "focusAndFlash %W"
    $wi.taygaconf.paddr configure -validatecommand {checkIPv6Net %P}
    $wi.taygaconf.paddr insert 0 [getTaygaIPv6Prefix $node]
    ttk::label $wi.taygaconf.dlabel -text "IPv4 dynamic pool:"
    ttk::entry $wi.taygaconf.daddr -width 30 -validate focus \
     -invalidcommand "focusAndFlash %W"
    $wi.taygaconf.daddr configure -validatecommand {checkIPv4Net %P}
    $wi.taygaconf.daddr insert 0 [getTaygaIPv4DynPool $node]
    grid $wi.taygaconf.label -in $wi.taygaconf \
	-column 0 -row 0 -sticky ew -pady 5
    grid $wi.taygaconf.dlabel -in $wi.taygaconf \
	-column 0 -row 1 -sticky ew -pady 5 -padx 5
    grid $wi.taygaconf.daddr -in $wi.taygaconf \
	-column 1 -row 1 -sticky ew -pady 5 -padx 5
    grid $wi.taygaconf.plabel -in $wi.taygaconf \
	-column 0 -row 2 -sticky ew -pady 5 -padx 5
    grid $wi.taygaconf.paddr -in $wi.taygaconf \
	-column 1 -row 2 -sticky ew -pady 5 -padx 5
#    grid $wi.taygaconf.4label -in $wi.taygaconf \
#	-column 0 -row 3 -sticky ew -pady 5
#    grid $wi.taygaconf.4addr -in $wi.taygaconf \
#	-column 1 -row 3 -sticky ew -pady 5


    ttk::frame $wi.mapconf -relief groove -borderwidth 2 -padding 2
    ttk::label $wi.mapconf.label -text "Fixed mappings:"
    text $wi.mapconf.mappings -bg white -width 42 -height 7
    set mps [getTaygaMappings $node]
    foreach map $mps {
	$wi.mapconf.mappings insert end "$map
"
    }
    pack $wi.mapconf.label -anchor w -pady 2
    pack $wi.mapconf.mappings -fill both -expand 1 -padx 4

    # if adding back tunconf, add it to pack
    pack $wi.taygaconf $wi.mapconf -anchor w -fill x
}

proc configGUI_nat64ConfigApply { wi node } {
    global changed

#    set newTun4addr [$wi.tunconf.4addr get]
#    set oldTun4addr [getTunIPv4Addr $node]
#    if { $oldTun4addr != $newTun4addr } {
#	setTunIPv4Addr $node $newTun4addr
#	set changed 1
#    }
#
#    set newTun6addr [$wi.tunconf.6addr get]
#    set oldTun6addr [getTunIPv6Addr $node]
#    if { $oldTun6addr != $newTun6addr } {
#	setTunIPv6Addr $node $newTun6addr
#	set changed 1
#    }
#
#    set newTayga4addr [$wi.taygaconf.4addr get]
#    set oldTayga4addr [getTaygaIPv4Addr $node]
#    if { $oldTayga4addr != $newTayga4addr } {
#	setTaygaIPv4Addr $node $newTayga4addr
#	set changed 1
#    }

    set newTayga6pAddr [$wi.taygaconf.paddr get]
    set oldTayga6pAddr [getTaygaIPv6Prefix $node]
    if { $oldTayga6pAddr != $newTayga6pAddr } {
	setTaygaIPv6Prefix $node $newTayga6pAddr
	set changed 1
    }

    set newTayga4dAddr [$wi.taygaconf.daddr get]
    set oldTayga4dAddr [getTaygaIPv4DynPool $node]
    if { $oldTayga4dAddr != $newTayga4dAddr } {
	setTaygaIPv4DynPool $node $newTayga4dAddr
	set changed 1
    }

    set oldTaygaMappings [lsort [getTaygaMappings $node]]
    set newTaygaMappings {}
    set i 1
    while { 1 } {
        set text [$wi.mapconf.mappings get $i.0 $i.end]
        set entry [lrange [split [string trim $text]] 0 2]
	if { $entry == "" } {
	    break
	}
	set addr4 [lindex $entry 0]
	set addr6 [lindex $entry 1]
	if { [checkIPv4Addr $addr4] == 1 } {
	    if { [checkIPv6Addr $addr6] == 1 } {
		lappend newTaygaMappings [string trim "$addr4 $addr6"]
	    } else {
		break
	    }
	} else {
	    break
	}
	incr i
    }
    set newTaygaMappings [lsort -unique $newTaygaMappings]
    if { $oldTaygaMappings != $newTaygaMappings } {
	setTaygaMappings $node $newTaygaMappings
	set changed 1
    }
}





#Modification for wifi
proc configGUI_WIFIAP { wi node } {
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    lappend guielements configGUI_WIFIAP
    global addresseNumber masque dhcpIp1 dhcpIp2
    global  close apply badentry
    global adapter ssid Ip Mask dhcp1 dhcp2 Wlanmode channel country check1 check2 check3 check4 check5 securite typesecurite typeencryption password beacon authentification listAP listAPIP
    set wlanID [split $node "n"]
    set wlanID [lindex $wlanID 1]


    set driver "nl80211"
    set ssid "network$node"
    set Ip "192.168.$wlanID.1"
    set Mask $masque
    set dhcp1 "192.168.$wlanID.2"
    set dhcp2 "192.168.$wlanID.254"
    set Wlanmode "g"
    set channel "6"
    set country "FR"
    set check1 1
    set check2 0
    set check3 0
    set check4 1
    set authentification "WPA"
    set securite "WPA"
    set typesecurite "WPA-PSK" 
    set typeencryption "TKIP CCMP"
    set password "MasterRES"
    set beacon "100"   
    set check5 0 

    if { [llength $listAP] > 0 } {

		foreach element $listAP {
	
		set nom [lindex $element 0] 
		if {$node ==$nom} {

		          set ssid [lindex $element 2]
 
     			  set Wlanmode [lindex $element 3]

                  set channel [lindex $element 4]

                  set check1 [lindex $element 5]
                  
                  set country [lindex $element 6]
                 
                  set check2 [lindex $element 7]
                 
				  set check3 [lindex $element 8]
                  
                  set check4 [lindex $element 9]
                 
                  set securite [lindex $element 11]
                
                 
								if {$securite == "0"} {

									set securite "NONE"
								} elseif {$securite == "1"} {
									set securite "WPA"
								} elseif {$securite == "2"} {
									set securite "WEP"
								} elseif {$securite == "3"} {
									set securite "BOTH"
								} 

                  set authentification [lindex $element 12]
               

						if {$authentification == "1"} {
								set authentification "WPA"
						} elseif {$authentification == "2"} {
								set authentification "WPA2"
						} 
                               
                  set typesecurite [lindex $element 13]
                  
                  set typesecurite [regsub -all "_" $typesecurite " "]
                  set typeencryption [lindex $element 14]
                  
                  set typeencryption [regsub -all "_" $typeencryption " "]
                  set password [lindex $element 15]
               
                  set beacon [lindex $element 16]
                 
				  set check5 [lindex $element 17]
             
				 foreach element $listAPIP {
						set nom [lindex $element 0] 
						if {$node ==$nom} {

             				set Ip [lindex $element 1]
    						set Mask [lindex $element 2]
    						set dhcp1 [lindex $element 3]
    						set dhcp2 [lindex $element 4]
						}
				}
				  
				  

		}



		}
	} 
 
    

    ttk::frame $wi.wlan2 -borderwidth 2 -padding 4
    ttk::label $wi.wlan2.ssidtxt -text "SSID:" 
    ttk::entry $wi.wlan2.ssid -width 20 -validate focus -textvariable ::ssid
    ttk::checkbutton $wi.wlan2.enable2 -text "Ignore Boroadcast SSID" -variable ::check5

    ttk::frame $wi.wlan -borderwidth 2 -padding 4
    ttk::label $wi.wlan.adressetxt -text "AP IP/MASK:" 
    ttk::entry $wi.wlan.adresseIP -width 15 -validate focus -textvariable ::Ip
    ttk::label $wi.wlan.adressetxt2 -text "/"  
    ttk::entry $wi.wlan.adresseMASK -width 5 -validate focus -textvariable ::Mask



    ttk::frame $wi.wlandhcp -borderwidth 2 -padding 4
    ttk::label $wi.wlandhcp.dhcptxt -text "DHCP server settings:" 
    ttk::entry $wi.wlandhcp.dhcp1 -width 15 -validate focus -textvariable ::dhcp1
    ttk::entry $wi.wlandhcp.dhcp2 -width 15 -validate focus -textvariable ::dhcp2


    ttk::frame $wi.wlan3 -borderwidth 2 -padding 4
    ttk::label $wi.wlan3.interfacetxt -text "Wireless Mode:" 
    ttk::combobox $wi.wlan3.interface -width 2 -textvariable Wlanmode
    $wi.wlan3.interface configure -values [list a b g n ac]  
   
    ttk::label $wi.wlan3.channeltxt -text "Channel:" 
    ttk::combobox $wi.wlan3.channel -width 2 -textvariable channel
    $wi.wlan3.channel configure -values [list 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14]    
    ttk::label $wi.wlan3.codetxt -text "Country Code:" 
    ttk::entry $wi.wlan3.code -width 10 -validate focus -textvariable ::country



    ttk::frame $wi.wlan4 -borderwidth 2 -padding 4
    ttk::checkbutton $wi.wlan4.enable1 -text "ieee80211d" -variable ::check1
    ttk::checkbutton $wi.wlan4.enable2 -text "ieee80211n" -variable ::check2
    ttk::checkbutton $wi.wlan4.enable3 -text "ieee80211ac" -variable ::check3
    ttk::checkbutton $wi.wlan4.enable4 -text "Qos Support" -variable ::check4

    ttk::frame $wi.wlan10 -borderwidth 2 -padding 4
    ttk::label $wi.wlan10.beacontxt -text "Beacon Interval:" 
    ttk::entry $wi.wlan10.beacon -width 10 -validate focus -textvariable ::beacon


    ttk::frame $wi.wlan6 -borderwidth 2 -padding 4
    ttk::label $wi.wlan6.securitetxt -text "Security algorithm:" 
    ttk::combobox $wi.wlan6.securite -width 4 -textvariable securite
    $wi.wlan6.securite configure -values [list NONE WPA WEP BOTH] 
    
    ttk::label $wi.wlan6.authtext -text "Authentification" 
    ttk::combobox $wi.wlan6.auth -width 4 -textvariable authentification
    $wi.wlan6.auth configure -values [list WPA WPA2] 
  

    ttk::frame $wi.wlan8 -borderwidth 2 -padding 4
    ttk::label $wi.wlan8.sectypetxt -text "Security type:" 
    ttk::entry $wi.wlan8.sectype -width 13 -validate focus -textvariable ::typesecurite 

    ttk::label $wi.wlan8.enctypetxt -text "Encryption type:" 
    ttk::entry $wi.wlan8.enctype -width 13 -validate focus -textvariable ::typeencryption


    ttk::frame $wi.wlan9 -borderwidth 2 -padding 4
    ttk::label $wi.wlan9.passtxt -text "Password:" 
    ttk::entry $wi.wlan9.pass -width 20 -validate focus -textvariable ::password
 

        pack $wi.wlan2.ssidtxt -side left -padx 2
        pack $wi.wlan2.ssid -side left -padx 4 -pady 4
        pack $wi.wlan2.enable2 -side left -padx 4 -pady 4
        pack $wi.wlan2 -fill both    

        pack $wi.wlan.adressetxt -side left -padx 2
        pack $wi.wlan.adresseIP -side left -padx 4 -pady 4
        pack $wi.wlan.adressetxt2 -side left -padx 4 -pady 4
        pack $wi.wlan.adresseMASK -side left -padx 4 -pady 4    
        pack $wi.wlan -fill both   

        pack $wi.wlandhcp.dhcptxt -side left -padx 2
        pack $wi.wlandhcp.dhcp1 -side left -padx 4 -pady 4
        pack $wi.wlandhcp.dhcp2 -side left -padx 4 -pady 4
        pack $wi.wlandhcp -fill both  


        pack $wi.wlan3 -fill both
        pack $wi.wlan3.interfacetxt -side left -padx 2
        pack $wi.wlan3.interface -side left -padx 4 -pady 4
        pack $wi.wlan3.channeltxt -side left -padx 2
        pack $wi.wlan3.channel -side left -padx 4 -pady 4
        pack $wi.wlan3.codetxt -side left -padx 4 -pady 4
        pack $wi.wlan3.code -side left -padx 4 -pady 4

        pack $wi.wlan4.enable1 -side left -padx 2
        pack $wi.wlan4.enable2 -side left -padx 4 -pady 4
        pack $wi.wlan4.enable3 -side left -padx 4 -pady 4
        pack $wi.wlan4.enable4 -side left -padx 4 -pady 4
        pack $wi.wlan4 -fill both

        pack $wi.wlan10.beacontxt -side left -padx 2
        pack $wi.wlan10.beacon -side left -padx 4 -pady 4
        pack $wi.wlan10 -fill both 


        pack $wi.wlan6.securitetxt -side left -padx 2
        pack $wi.wlan6.securite -side left -padx 4 -pady 4
        pack $wi.wlan6.authtext -side left -padx 4 -pady 4
        pack $wi.wlan6.auth  -side left -padx 4 -pady 4
        pack $wi.wlan6 -fill both

        pack $wi.wlan8.sectypetxt -side left -padx 4 -pady 4
        pack $wi.wlan8.sectype -side left -padx 4 -pady 4

        pack $wi.wlan8.enctypetxt -side left -padx 4 -pady 4
        pack $wi.wlan8.enctype -side left -padx 4 -pady 4
        pack $wi.wlan8 -fill both

        pack $wi.wlan9.passtxt -side left -padx 4 -pady 4
        pack $wi.wlan9.pass -side left -padx 4 -pady 4
        pack $wi.wlan9 -fill both       



}

proc configFichier_AP { node } {

global listAP listAPIP
global ssid Ip Mask dhcp1 dhcp2 Wlanmode channel country check1 check2 check3 check4 check5 securite typesecurite typeencryption password driver beacon authentification


foreach element $listAP {
	
		set nom [lindex $element 0]


			if { "$node" == $nom } {

				set id [lsearch -exact $listAP $element]
				set malist [lreplace $listAP $id $id]

				set listAP $malist

			
			}


	}

foreach element $listAPIP {
	
		set nom [lindex $element 0]


			if { "$node" == $nom } {

				set id [lsearch -exact $listAPIP $element]
				set malist [lreplace $listAPIP $id $id]

				set listAPIP $malist
			}


	}


if {$ssid != ""} {
 set SSID "$ssid"
} else {
 set SSID "No-info"
}
if { $Wlanmode!= ""} {
 set mode "$Wlanmode"
} else {
 set mode "No-info" 
}
if { $channel!= ""} {
set ch "$channel"
} else {
set ch "No-info"
}
if {$country != "" } {
set count "$country"
} else {
set count "No-info"
}

if {$securite == "NONE"} {

set auth "0"
} elseif {$securite == "WPA"} {
set auth "1"
} elseif {$securite == "WEP"} {
set auth "2"
} elseif {$securite == "BOTH"} {
set auth "3"
} else {
set auth "No-info"
}

if {$authentification == "WPA"} {
set wpa "1"
} elseif {$authentification == "WPA2"} {
set wpa "2"
} else {
set wpa "No-info"
}
if {$typesecurite != ""} {
set typesecurite1 [regsub -all " " $typesecurite "_"]

set typeS "$typesecurite1"
} else {
set typeS "No-info"
}
if {$typeencryption != ""} {
set typeencryption1 [regsub -all " " $typeencryption "_"]
set typeE "$typeencryption1"

} else {
set typeE "No-info"
}
if {$password != ""} {
set pass "$password"
} else {
set pass "No-info"
}
if {$beacon != ""} {
set beac "$beacon"
} else {
set beac "No-info"
}


    

lappend listAP "$node driver=nl80211 $SSID $mode $ch $check1 $count $check2 $check3 $check4 macaddr_acl=0 $auth $wpa $typeS $typeE $pass $beac $check5"

lappend listAPIP "$node $Ip $Mask $dhcp1 $dhcp2"


}




proc verifierconfiguration_AP { node } {

global dynacurdir     

upvar 0 ::cf::[set ::curcfg]::eid eid


if { [file exist "$dynacurdir/WIFI/$eid/AP/$node.conf"] != 1 } {

global masque dhcpIp1 dhcpIp2 listAPIP adapter wlanID

set wlanID [split $node "n"]
set wlanID [lindex $wlanID 1]

set Ip "192.168.$wlanID.1"
set Mask $masque
set dhcp1 "192.168.$wlanID.2"
set dhcp2 "192.168.$wlanID.254"

          	set fp [open "$dynacurdir/WIFI/$eid/AP/$node.conf" w+]
          	
          	puts $fp "interface=wlan$wlanID\ndriver=nl80211\nssid=network$node\nhw_mode=g\nchannel=6\nieee80211d=1\ncountry_code=FR\nieee80211n=0\nieee80211ac=0\nwmm_enabled=1\nmacaddr_acl=0\nauth_algs=1\nwpa=1\nwpa_key_mgmt=WPA-PSK\nwpa_pairwise=TKIP CCMP\nwpa_passphrase=MasterRES\nbeacon_int=100\nignore_broadcast_ssid=0\n"
          	close $fp
            
             lappend listAPIP "$node $Ip $Mask $dhcp1 $dhcp2"



}


}





proc configGUI_WIFISTA { wi node } {
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    lappend guielements configGUI_WIFISTA
    global listAP listSTA
    global adapterSTA ssidSTA scanssidSTA encryptionSTA protocoleSTA groupeSTA pairwiseSTA prioritySTA passwordSTA ssiddefault


    set ssiddefault "networkn0"
    set scanssidSTA 0
    set encryptionSTA "default"
    set protocoleSTA "default" 
    set groupeSTA "default"
    set pairwiseSTA "default"
    set passwordSTA "MasterRES" 
    set prioritySTA ""
    
foreach element $listSTA {


		set nom [lindex $element 0]

			if { "$node" == $nom } {

			set ssiddefault [lindex $element 1]
            
    		set scanssidSTA [lindex $element 5]
            
    		set encryptionSTA [lindex $element 2]
          
    		set protocoleSTA [lindex $element 3]
           
    		set groupeSTA [lindex $element 4]
           
    		set pairwiseSTA [lindex $element 6]
          
    		set passwordSTA [lindex $element 7]
           
    		set prioritySTA [lindex $element 8]
           

			}


	}

    
    ttk::frame $wi.wlanSTA -borderwidth 2 -padding 4
    ttk::label $wi.wlanSTA.ssidtxt -text "SSID:" 
    ttk::entry $wi.wlanSTA.ssid -width 15 -validate focus -textvariable ::ssiddefault
    ttk::checkbutton $wi.wlanSTA.scanssid -text "Scan SSID" -variable ::scanssidSTA

        pack $wi.wlanSTA.ssidtxt -side left -padx 2
        pack $wi.wlanSTA.ssid -side left -padx 4 -pady 4
        pack $wi.wlanSTA.scanssid -side left -padx 4 -pady 4
        pack $wi.wlanSTA -fill both 

   
    ttk::frame $wi.wlanSTA2 -borderwidth 2 -padding 4
    ttk::label $wi.wlanSTA2.encrytxt -text "Encryption:" 
    ttk::combobox $wi.wlanSTA2.encry -width 8 -textvariable encryptionSTA
    $wi.wlanSTA2.encry configure -values [list WPA-PSK WPA-EAP IEEE8021X NONE default]  

    ttk::label $wi.wlanSTA2.groutxt -text "Group:" 
    ttk::combobox $wi.wlanSTA2.grou -width 7 -textvariable groupeSTA
    $wi.wlanSTA2.grou configure -values [list CCMP TKIP WEP104 WEP40 default] 

    ttk::label $wi.wlanSTA2.pairtxt -text "Pairwise:" 
    ttk::combobox $wi.wlanSTA2.pair -width 7 -textvariable pairwiseSTA
    $wi.wlanSTA2.pair configure -values [list CCMP TKIP default] 

        pack $wi.wlanSTA2.encrytxt -side left -padx 2
        pack $wi.wlanSTA2.encry -side left -padx 4 -pady 4
        pack $wi.wlanSTA2.groutxt -side left -padx 4 -pady 4
        pack $wi.wlanSTA2.grou -side left -padx 4 -pady 4
        pack $wi.wlanSTA2.pairtxt -side left -padx 4 -pady 4
        pack $wi.wlanSTA2.pair -side left -padx 4 -pady 4
        pack $wi.wlanSTA2 -fill both

    ttk::frame $wi.wlanSTA3 -borderwidth 2 -padding 4
    ttk::label $wi.wlanSTA3.prototxt -text "Protocol:" 
    ttk::combobox $wi.wlanSTA3.proto -width 7 -textvariable protocoleSTA
    $wi.wlanSTA3.proto configure -values [list RSN WPA default]  
    ttk::label $wi.wlanSTA3.priotxt -text "Priority:" 
    ttk::entry $wi.wlanSTA3.prio -width 10 -validate focus -textvariable ::prioritySTA

        pack $wi.wlanSTA3.prototxt -side left -padx 2
        pack $wi.wlanSTA3.proto -side left -padx 4 -pady 4
        pack $wi.wlanSTA3.priotxt -side left -padx 4 -pady 4
        pack $wi.wlanSTA3.prio -side left -padx 4 -pady 4
        pack $wi.wlanSTA3 -fill both 

    ttk::frame $wi.wlanSTA7 -borderwidth 2 -padding 4
    ttk::label $wi.wlanSTA7.passtxt -text "Password:" 
    ttk::entry $wi.wlanSTA7.pass -width 20 -validate focus -textvariable ::passwordSTA
 
        pack $wi.wlanSTA7.passtxt -side left -padx 2
        pack $wi.wlanSTA7.pass -side left -padx 4 -pady 4
        pack $wi.wlanSTA7 -fill both 
global eidvlan modevlan


if {$modevlan == "exec" && $eidvlan != ""} {
ttk::frame $wi.scanresult -borderwidth 2 -padding 4
ttk::label $wi.scanresult.scantxt -text "Status:" 
set id [split $node "n"]
set id [lindex $id 1]
set node_id "$eidvlan.$node"
set result [exec ip netns exec $node_id wpa_cli -i wlan$id status]
ttk::frame $wi.scanresult2 -borderwidth 2 -padding 4
ttk::label $wi.scanresult2.scantxt2 -text "$result"
    
	pack $wi.scanresult.scantxt -side left -padx 2
	pack $wi.scanresult -fill both

	pack $wi.scanresult2.scantxt2 -side left -padx 2
	pack $wi.scanresult2 -fill both
}
           


}



proc configFichier_STA { node } {

    global listSTA
    global adapterSTA ssidSTA scanssidSTA encryptionSTA protocoleSTA groupeSTA pairwiseSTA prioritySTA passwordSTA ssiddefault
    

foreach element $listSTA {
	
		set nom [lindex $element 0]


			if { "$node" == $nom } {

				set id [lsearch -exact $listSTA $element]
				set malist [lreplace $listSTA $id $id]

				set listSTA $malist
			}


	}

 

if {$ssiddefault != ""} {
 set SSID "$ssiddefault"
} else {

set SSID "No-info"
}
if { $encryptionSTA != ""} {
set encryption "$encryptionSTA"
} else {
set encryption "No-info"
}
if { $protocoleSTA != ""} {
set protocole "$protocoleSTA"
} else {
set protocole "No-info"
}
if {$groupeSTA != "" } {
set group "$groupeSTA"
} else {
set group "No-info"
}

if {$pairwiseSTA != "" } {
set pairwise "$pairwiseSTA"
} else {
set pairwise "No-info"
}


if {$prioritySTA != "" } {
set priority "$prioritySTA"
} else {
set priority "No-info"
}

if {$passwordSTA != "" } {
set password "$passwordSTA"
} else {
set password "No-info"
}


lappend listSTA "$node $SSID $encryption $protocole $group $scanssidSTA $pairwise $password $priority"


}

proc verifierconfiguration_STA { node } {

 global dynacurdir 
    
upvar 0 ::cf::[set ::curcfg]::eid eid
set wlanID [split $node "n"]
set wlanID [lindex $wlanID 1]

if { [file exist "$dynacurdir/WIFI/$eid/STA/$node.conf"] != 1 } {

global listIfcSTA


	    

          	set fp [open "$dynacurdir/WIFI/$eid/STA/$node.conf" w+]
          	
          	puts $fp "country=FR\nctrl_interface=/var/run/wpa_supplicant\nupdate_config=1\nnetwork={\nssid=\"networkn0\"\nkey_mgmt=WPA-PSK WPA-EAP\nproto=RSN WPA\ngroup=TKIP CCMP WEP104 WEP40\nscan_ssid=0\npairwise=CCMP\npsk=\"MasterRES\"\n}\n"
          	close $fp
            
            lappend listIfcSTA "$node $wlanID wlan$wlanID"

}


}

