#
# Copyright 2007-2010 Petra Schilhard.
# Copyright 2010-2013 University of Zagreb.
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

# $Id: gpgui.tcl 61 2013-10-03 10:19:50Z denis $


.menubar.tools add separator
.menubar.tools add command -label "Topologie partitioning" -underline 0 -command "dialog";

#****h* gpgui/weight_file
# NAME & FUNCTION
#  weight_file -- holds the name of the file where the node weights are saved
#  comp_file   -- holds the list of servers
#****
set WEIGHT_FILE "node_weights"
set COMP_FILE "comp_list"

namespace eval cf::clipboard {}
set cf::clipboard::node_weights {}

#****f* gpgui.tcl/dialog
# NAME
#   dialog -- dialog
# SYNOPSIS
#   dialog
# FUNCTION
#   Procedure opens a new dialog with a text field for entering the
#   number of parts in which the graph is to be partition, and with
#   the node and link weights, which can be changed.
#****
proc dialog {} {
    readNodeWeights;

    set wi .popup
    toplevel $wi
    wm transient $wi .
    wm resizable $wi 0 0
    wm title $wi "Graph partition settings"

    #number of partitions parameter
    ttk::frame $wi.pnum -borderwidth 4 -relief raised
     
    ttk::frame $wi.pnum.l -borderwidth 2
    ttk::label $wi.pnum.l.p -text "Number of partitions:" -anchor w
    ttk::spinbox $wi.pnum.l.e -width 10 -validate focus	
	$wi.pnum.l.e insert 0 2;
	$wi.pnum.l.e configure \
		-validatecommand {checkIntRange %P 1 10000} \
		-from 2 -to 100 -increment 1
    pack $wi.pnum.l.p $wi.pnum.l.e -side left -anchor w
	
    ttk::frame $wi.pnum.wl -borderwidth 2
    ttk::label $wi.pnum.wl.p -text "Detailed:" -anchor w
    ttk::button $wi.pnum.wl.lns -text "Link weight" -command \
    "displayAllLinkWeights $wi"
    ttk::button $wi.pnum.wl.nds -text "Nodes weight" -command \
    "displayAllNodeWeights $wi"
    pack $wi.pnum.wl.p $wi.pnum.wl.lns $wi.pnum.wl.nds -side left
    pack $wi.pnum.wl $wi.pnum.l -side bottom

    pack $wi.pnum -side top -anchor w -fill both

    #search for a network description file
    ttk::frame $wi.cfile -borderwidth 8 -padding 4 -relief raised
    
    ttk::frame $wi.cfile.l
    ttk::label $wi.cfile.l.p -text "Network:" -anchor w
    pack $wi.cfile.l.p -side top
    ttk::frame $wi.cfile.e -borderwidth 2
    ttk::entry $wi.cfile.e.p -width 20 -validate focus
    pack $wi.cfile.e.p -side top
    pack $wi.cfile.l $wi.cfile.e -side left
    pack $wi.cfile -side top -anchor w -fill both
    ttk::button $wi.cfile.wl -text "Browse" -command \
    "openCompFile $wi"
    pack $wi.cfile.wl -side left

    #buttons Ok & Cancel
	ttk::frame $wi.bottom
    ttk::frame $wi.bottom.buttons -borderwidth 6
    ttk::button $wi.bottom.buttons.repart -text "Repartition" -command \
	"getRepartitionSelected"
    ttk::button $wi.bottom.buttons.ok -text "OK" -command \
    "popupApply $wi"
    focus $wi.bottom.buttons.ok
    ttk::button $wi.bottom.buttons.cancel -text "Cancel" -command \
    "destroy $wi"
    
    pack $wi.bottom.buttons.ok $wi.bottom.buttons.cancel $wi.bottom.buttons.repart \
        -side left -padx 1
    pack $wi.bottom.buttons -expand 1
	pack $wi.bottom

    return
}

#****f* gpgui.tcl/openCompFile
# NAME
#   openCompFile -- open computer file
# SYNOPSIS
#   openCompFile $wi
# FUNCTION
#   Opens the file on the computer.
# INPUTS
#   * wi -- widget
#****
proc openCompFile { wi } {
    #browse for computer file
    set openFile [tk_getOpenFile]
    if { $openFile == ""} {
	return
    }
    upvar 0 ::cf::[set ::curcfg]::compFile compFile
    set compFile $openFile
    $wi.cfile.e.p insert 0 $compFile
    readCompFile compFile
}

#****f* gpgui.tcl/readCompFile
# NAME
#   readCompFile -- read computer file
# SYNOPSIS
#   readCompFile $compFile
# FUNCTION
#   Reads the opened computer file.
# INPUTS
#   * compFile -- computer file
#****
proc readCompFile { compFile } {
    upvar $compFile cFile
	
    set cFileId [open $cFile r]
    set cList ""
    foreach entry [read $cFileId] {
	lappend cList $entry
    }
    close $fileId
	parseCompList $cList
}

#****f* gpgui.tcl/parseCompList
# NAME
#   parseCompList -- parse computer list
# SYNOPSIS
#   parseCompList $compList
# FUNCTION
#   
# INPUTS
#   * compList -- 
#****
proc parseCompList { compList } {
	upvar $compList cList
}

#****f* gpgui.tcl/displayAllNodeWeights
# NAME
#   displayAllNodeWeights -- display all nodes' weights
# SYNOPSIS
#   displayAllNodeWeights wi
# FUNCTION
#   Procedure reads for each node its weight and writes it onto
#   new window. The weight is first search in the node_list, and
#   if not found, read from the default values.
# INPUTS
#   * wi -- parent window id
#****
proc displayAllNodeWeights { wi } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list

    set nw .pop
    toplevel $nw
    wm transient $nw .
    wm resizable $nw 0 0
    wm title $nw "Node weights"
    
    #weights settings
    ttk::labelframe $nw.more -text "Node Weights" -padding 4
    ttk::frame $nw.more.weights

    set i 1;
    set j 1;
    #weights from the file
    foreach node $node_list {
	#read for each node its weight
	set wgt [getNodeWeight $node];
	
	ttk::label $nw.more.weights.$node -text "$node" -anchor w
	ttk::spinbox $nw.more.weights.w$node -width 3 \
		-validate focus -invalidcommand "focusAndFlash %W"
	$nw.more.weights.w$node insert 0 $wgt;
	$nw.more.weights.w$node configure \
		-validatecommand {checkIntRange %P 0 100} \
		-from 0 -to 100 -increment 1
	
	grid $nw.more.weights.$node -row $i -column $j
	grid $nw.more.weights.w$node -row $i -column [expr {int($j+1)}];
	
	incr i;
	if {[expr {$i % 10}] == 0} then {
		set j [expr {$j + 2}];
		set i 1;
	}
    }
    pack $nw.more.weights -side top -anchor w
    pack $nw.more -side top -anchor w -fill x

    #buttons Apply & Cancel
    ttk::frame $nw.button -borderwidth 6
    pack $nw.button -fill both -expand 1
    ttk::button $nw.button.apply -text "Apply" -command "applyNodeWeights $nw"
    focus $nw.button.apply
    ttk::button $nw.button.cancel -text "Cancel" -command "destroy $nw"
    pack $nw.button.cancel -side right -expand 1 -anchor w
    pack $nw.button.apply -side right -expand 1 -anchor e
    pack $nw.button -side bottom 
}

#****f* gpgui.tcl/displayAllLinkWeights
# NAME
#   displayAllLinkWeights -- display all links' weights
# SYNOPSIS
#   displayAllLinkWeights wi
# FUNCTION
#   Procedure reads for each link its characteristics and writes them
#   on the new window.   
# INPUTS
#   * wi -- parent window id
#****
proc displayAllLinkWeights { wi } {
    upvar 0 ::cf::[set ::curcfg]::link_list link_list

    set lw .pop
    toplevel $lw
    wm transient $lw .
    wm resizable $lw 0 0
    wm title $lw "Link weights"
    
    #weights settings
    ttk::labelframe $lw.more -text "Link Weights" -padding 4
    ttk::frame $lw.more.weights

    set i 1;
    set j 1;
    foreach link $link_list {	
	ttk::label $lw.more.weights.$link -text "$link" -anchor w
	#bandwidth
	ttk::label $lw.more.weights.bl$link -text "Bandwidth:" -anchor w
	ttk::spinbox $lw.more.weights.b$link -width 9 \
		-validate focus -invalidcommand "focusAndFlash %W"
	$lw.more.weights.b$link insert 0 [getLinkBandwidth $link]
	$lw.more.weights.b$link configure \
		-validatecommand {checkIntRange %P 0 100000000} \
		-from 0 -to 100000000 -increment 1000
	#delay
	ttk::label $lw.more.weights.dl$link -text "Delay:" -anchor w
	ttk::spinbox $lw.more.weights.d$link -width 9 \
		-validate focus -invalidcommand "focusAndFlash %W"
	$lw.more.weights.d$link insert 0 [getLinkDelay $link]
	$lw.more.weights.d$link configure \
		-validatecommand {checkIntRange %P 0 100000000} \
		-from 0 -to 100000000 -increment 5
	#BER
	ttk::label $lw.more.weights.rl$link -text "BER (1/N):" -anchor w
	ttk::spinbox $lw.more.weights.r$link -width 9 \
		-validate focus -invalidcommand "focusAndFlash %W"
	$lw.more.weights.r$link insert 0 [getLinkBER $link]
	$lw.more.weights.r$link configure \
		-validatecommand {checkIntRange %P 0 10000000000000} \
		-from 0 -to 10000000000000 -increment 1000

	grid $lw.more.weights.$link -row $i -column 1;
	grid $lw.more.weights.bl$link -row $i -column 2;
	grid $lw.more.weights.b$link -row $i -column 3;
	grid $lw.more.weights.dl$link -row $i -column 4;
	grid $lw.more.weights.d$link -row $i -column 5;
	grid $lw.more.weights.rl$link -row $i -column 6;
	grid $lw.more.weights.r$link -row $i -column 7;
	
	incr i;
    }
    pack $lw.more.weights -side top -anchor w
    pack $lw.more -side top -anchor w -fill x

    #buttons Apply & Cancel
    ttk::frame $lw.button -borderwidth 6
    pack $lw.button -fill both -expand 1
    ttk::button $lw.button.apply -text "Apply" -command \
	"applyLinkWeights $lw"
    focus $lw.button.apply
    ttk::button $lw.button.cancel -text "Cancel" -command \
	"destroy $lw"
    pack $lw.button.apply -side left -anchor e -expand 1
    pack $lw.button.cancel -side right -anchor w -expand 1
    pack $lw.button -side bottom 
}

#****f* gpgui.tcl/readNodeWeights
# NAME
#   readNodeWeights -- read node weights
# SYNOPSIS
#   readNodeWeights
# FUNCTION
#   Procedure reads from a file node weights and saves them in array.
#****
proc readNodeWeights {} {
    upvar 0 ::cf::[set ::curcfg]::node_weights node_weights

    #get the weight settings out of the file
    set file [openWeightFile "r"]
    set n [gets $file line];

    set i 0;
    while {[gets $file line] >= 0} {
	set node_weights($i) $line
	incr i
    }
    close $file

    if {$i != 6} then {
	puts stdout "Bad file $file."
	return;
    }
}

#****f* gpgui.tcl/openWeightFile
# NAME
#   openWeightFile -- open weight file
# SYNOPSIS
#   openWeightFile $op
# FUNCTION
#   Function opens a file specified in WEIGHT_FILE constant,
#   and returns the file descriptor.
# INPUTS
#   * op -- operation "r" (for read) or "w" (for write)
# RESULT
#   * fileId -- file id
#****
proc openWeightFile { op } {
    global WEIGHT_FILE;
    if {[catch {open $WEIGHT_FILE $op} fileId]} then {
	puts "graph_partitioning: Cannot open $WEIGHT_FILE."
	return
    }
    return $fileId
}

#****f* gpgui.tcl/applyNodeWeights
# NAME
#   applyNodeWeights -- apply node weights
# SYNOPSIS
#   applyNodeWeights nw
# FUNCTION
#   Procedure reads for each node its weight from the
#   window, and save it to the node_list.
# INPUTS
#   * nw -- window id
#****
proc applyNodeWeights { nw } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list

    foreach node $node_list {
		writeWeightToNode $node [$nw.more.weights.w$node get];
    }
    destroy $nw;
}

#****f* gpgui.tcl/applyLinkWeights
# NAME
#   applyLinkWeights -- apply link weights
# SYNOPSIS
#   applyLinkWeights lw
# FUNCTION
#   Procedure reads for each link its characteristics from the
#   window, and change theirs values in program.
# INPUTS
#   * lw -- window id
#****
proc applyLinkWeights {lw} {
    upvar 0 ::cf::[set ::curcfg]::link_list link_list

    foreach link $link_list {
		setLinkBandwidth $link [$lw.more.weights.b$link get];
		setLinkDelay $link [$lw.more.weights.d$link get];
		setLinkBER $link [$lw.more.weights.r$link get];
    }
    destroy $lw;
}

#****f* gpgui.tcl/writeWeightToNode
# NAME
#   writeWeightToNode -- write weight to node
# SYNOPSIS
#   writeWeightToNode $node $weight
# FUNCTION
#   Procedure writes the weight to the node.
# INPUTS
#   * node -- node id
#   * weight -- weight of the node
#****
proc writeWeightToNode { node weight } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set p [lsearch [set $node] "weight *"];
    if { $p >= 0 } {
	set $node [lreplace [set $node] $p $p "weight $weight"];
    } else {
	set $node [linsert [set $node] end "weight $weight"];
    }
}


#****f* gpgui.tcl/getNodeWeight
# NAME
#   getNodeWeight -- get node weight
# SYNOPSIS
#   getNodeWeight $node
# FUNCTION
#   Function searches the node for the information about its weight.
#   If the weight is found, it is returned, and if it is not found,
#   an empty string is returned.
# INPUTS
#   * node -- node id
# RESULT
#   * wgt -- weight of the node
#****
proc getNodeWeight { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node
    upvar 0 ::cf::[set ::curcfg]::node_weights node_weights

    set wgt [lindex [lsearch -inline [set $node] "weight *"] 1];

    if {$wgt == ""} then {
	switch -exact -- [nodeType $node] {
	    pc {
		set wgt $node_weights(0);
		}
	    host {
		set wgt $node_weights(1);
	    	}
	    router {
		set wgt $node_weights(2);
	    	}
	    lanswitch {
		set wgt $node_weights(3);
	    	}
	    hub {
		set wgt $node_weights(4);
	    	}
	    rj45 {
		set wgt $node_weights(5);
	    	}
	    default {
		set wgt 0;
	    	}
	}
    }
    return $wgt;
}

#save node weights to the file

#****f* gpgui.tcl/changeDefaultWeights
# NAME
#   changeDefaultWeights -- change default weights
# SYNOPSIS
#   changeDefaultWeights wi
# FUNCTION
#   Procedure opens a file with node weights, and writes
#   in it the weight for each group of nodes (pc,router,...).
# INPUTS
#   * wi -- window id, parent window
#****
proc changeDefaultWeights { wi } {
    upvar 0 ::cf::[set ::curcfg]::node_weights node_weights

    set file [openWeightFile "w"];

    set node_weights(0) [$wi.weight.pcs get];
    set node_weights(1) [$wi.weight.hosts get];
    set node_weights(2) [$wi.weight.routers get];
    set node_weights(3) [$wi.weight.switchs get];
    set node_weights(4) [$wi.weight.hubs get];
    set node_weights(5) [$wi.weight.rj45s get];

    close $file;
    destroy $wi;
}

#****f* gpgui.tcl/popupApply
# NAME
#   popupApply -- popup apply
# SYNOPSIS
#   popupApply wi
# FUNCTION
#   Procedure saves for each node its weight in node_list.
# INPUTS
#   * wi -- window id
#****
proc popupApply { wi } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    set partNum [$wi.pnum.l.e get]

    foreach node $node_list {
	#read for each node its weight
	set wgt [getNodeWeight $node];
	#write it to the node_list
	writeWeightToNode $node $wgt
    }

    destroy $wi

    graphPartition $partNum;
}

#****f* gpgui.tcl/displayErrorMessage
# NAME
#   displayErrorMessage -- display error message
# SYNOPSIS
#   displayErrorMessage $message
# FUNCTION
#   Procedure writes a message to the screen as a popup dialog.
# INPUTS
#   * message -- message to be writen
#****
proc displayErrorMessage { message } {
    tk_dialog .dialog1 "Graph partitioning" $message info 0 Dismiss;
}

#****f* gpgui.tcl/getLinkWeight
# NAME
#   getLinkWeight -- calculate link weight
# SYNOPSIS
#   getLinkWeight $link
# FUNCTION
#   Function calculates for each link its weight from its characteristics.
# INPUTS
#   * link -- link id
# RESULT
#   * weight -- weight of the link
#****
proc getLinkWeight { link } {
    upvar 0 ::cf::[set ::curcfg]::$link $link

    set bndw [getLinkBandwidth $link]; #in bps
    set dly [getLinkDelay $link]; #in usec
    set ber [getLinkBER $link];
    set dup [getLinkDup $link];

    if {$bndw == 0 || $bndw == ""} then {
	set bndw 1000000000;
    }

    if {$dly == 0 || $dly == ""} then {
	set dly 1;
    }

    set weight [expr {(10000000 / $bndw) + ($dly / 10)}];

    return $weight;
}

#****f* gpgui.tcl/getRepartitionSelected
# NAME
#   getRepartitionSelected -- get repartition selected
# SYNOPSIS
#   getRepartitionSelected
# FUNCTION
#   Repartition selected nodes.
#****
proc getRepartitionSelected {} {
    set selected [selectedNodes]
	repartition $selected;
}
