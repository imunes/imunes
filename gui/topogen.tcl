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

# $Id: topogen.tcl 68 2013-10-04 11:17:13Z denis $


menu .menubar.t_g -tearoff 0

set m .menubar.t_g.chain
menu $m -tearoff 0
.menubar.t_g add cascade -label "Chain" -menu $m -underline 0 -state disabled
for { set i 2 } { $i <= 24 } { incr i } {
    $m add command -label "P($i)" -command "P \[newNodes $i\]"
}

set m .menubar.t_g.star
menu $m -tearoff 0
.menubar.t_g add cascade -label "Star" -menu $m -underline 0 -state disabled
for { set i 3 } { $i <= 25 } { incr i } {
    $m add command -label "S($i)" \
	-command "Kb \[newNodes 1\] \[newNodes [expr {$i - 1}]\]"
}

set m .menubar.t_g.cycle
menu $m -tearoff 0
.menubar.t_g add cascade -label "Cycle" -menu $m -underline 1 -state disabled
for { set i 3 } { $i <= 24 } { incr i } {
    $m add command -label "C($i)" -command "C \[newNodes $i\]"
}

set m .menubar.t_g.wheel
menu $m -tearoff 0
.menubar.t_g add cascade -label "Wheel" -menu $m -underline 0 -state disabled
for { set i 4 } { $i <= 25 } { incr i } {
    $m add command -label "W($i)" \
	-command "W \"\[newNodes 1\] \[newNodes [expr {$i - 1}]\]\""
}

set m .menubar.t_g.cube
menu $m -tearoff 0
.menubar.t_g add cascade -label "Cube" -menu $m -underline 1 -state disabled
for { set i 2 } { $i <= 6 } { incr i } {
    $m add command -label "Q($i)" \
	-command "Q \[newNodes [expr {int(pow(2,$i))}]\]"
}

set m .menubar.t_g.clique
menu $m -tearoff 0
.menubar.t_g add cascade -label "Clique" -menu $m -underline 3 -state disabled
for { set i 3 } { $i <= 24 } { incr i } {
    $m add command -label "K($i)" -command "K \[newNodes $i\]"
}

set m .menubar.t_g.bipartite
menu $m -tearoff 0
.menubar.t_g add cascade -label "Bipartite" -menu $m -underline 0 \
    -state disabled
for { set i 1 } { $i <= 12 } { incr i } {
    set n $m.$i
    menu $n -tearoff 0
    $m add cascade -label "K($i,N)" -menu $n -underline 0
    for { set j $i } { $j <= [expr {24 - $i}] } { incr j } {
	$n add command -label "K($i,$j)" -command "Kbhelper $i $j"
    }
}

set m .menubar.t_g.random
menu $m -tearoff 0
.menubar.t_g add cascade -label "Random" -menu $m -underline 0 -state disabled
for { set i 3 } { $i <= 24 } { incr i } {
    set n $m.$i
    menu $n -tearoff 0
    $m add cascade -label "R($i,m)" -menu $n -underline 0
    set l [expr $i - 1]
    for { set j $l } { $j < [expr { $i * $l / 2 }] } { incr j } {
	$n add command -label "R($i,$j)" -command "R \[newNodes $i\] $j"
	if { $j > [expr $i + 24] } {
	    break
	}
    }
}

#****f* topogen.tcl/newNodes
# NAME
#   newNodes -- new nodes
# SYNOPSIS
#   newNodes $node_num
# FUNCTION
#   Creates node_num new nodes.
# INPUTS
#   * node_num -- number of new nodes
# RESULT
#   * new_nodes -- created nodes
#****
proc newNodes { node_num } {
    global grid sizex sizey activetool

    set new_nodes {}
    set r [expr {($node_num - 1) * (1 + 4 / $node_num) * $grid / 2}]
    set x0 [expr {$sizex / 2}]
    set y0 [expr {$sizey / 2}]
    set twopidivn [expr {acos(0) * 4 / $node_num}]
    if { $activetool == "router" } {
	set dy 24
    } else {
	set dy 32
    }

    for { set i 0 } { $i < $node_num } { incr i } {
	set new_node_id [newNode $activetool]
	set x [expr {$x0 + $r * cos($twopidivn * $i)}]
	set y [expr {$y0 - $r * sin($twopidivn * $i)}]

	setNodeCoords $new_node_id "$x $y"
	setNodeLabelCoords $new_node_id "$x [expr {$y + $dy}]"
	setNodeCanvas $new_node_id [getFromRunning "curcanvas"]

	lappend new_nodes $new_node_id
    }

    return $new_nodes
}

#****f* topogen.tcl/topoGenDone
# NAME
#   topoGenDone -- topology generating done
# SYNOPSIS
#   topoGenDone $nodes
# FUNCTION
#   This procedure is called when topology generating is completed.
# INPUTS
#   * nodes -- generated nodes
#****
proc topoGenDone { nodes } {
    global changed

    set changed 1
    updateUndoLog
    redrawAll
    selectNodes $nodes
}

#
# Chain
#
#****f* topogen.tcl/P
# NAME
#   P -- chain topology
# SYNOPSIS
#   P $nodes
# FUNCTION
#   Creates chain topology.
# INPUTS
#   * nodes -- nodes
#****
proc P { nodes } {
    .panwin.f1.c config -cursor watch; update

    set node_num [llength $nodes]
    for { set i 0 } { $i < [expr {$node_num - 1}] } { incr i } {
	newLink [lindex $nodes $i] [lindex $nodes [expr {($i + 1) % $node_num}]]
    }

    topoGenDone $nodes
}

#
# Cycle
#
#****f* topogen.tcl/C
# NAME
#   C -- cycle topology
# SYNOPSIS
#   C $nodes
# FUNCTION
#   Creates cycle topology.
# INPUTS
#   * nodes -- nodes
#****
proc C { nodes } {
    .panwin.f1.c config -cursor watch; update

    set node_num [llength $nodes]
    for { set i 0 } { $i < $node_num } { incr i } {
	newLink [lindex $nodes $i] [lindex $nodes [expr {($i + 1) % $node_num}]]
    }

    topoGenDone $nodes
}

#
# Wheel
#
#****f* topogen.tcl/W
# NAME
#   W -- wheel topology
# SYNOPSIS
#   W $nodes
# FUNCTION
#   Creates wheel topology.
# INPUTS
#   * nodes -- nodes
#****
proc W { nodes } {
    .panwin.f1.c config -cursor watch; update

    set node_num [llength $nodes]
    set vr [lindex $nodes 0]
    set vt "$nodes [lindex $nodes 1]"
    for { set i 1 } { $i < $node_num } { incr i } {
	newLink $vr [lindex $nodes $i]
	newLink [lindex $nodes $i] [lindex $vt [expr {$i + 1}]]
    }

    topoGenDone $nodes
}

#
# Cube
#
#****f* topogen.tcl/Q
# NAME
#   Q -- cube topology
# SYNOPSIS
#   Q $nodes
# FUNCTION
#   Creates cube topology.
# INPUTS
#   * nodes -- nodes
#****
proc Q { nodes } {
    set node_num [llength $nodes]
    set order [expr int(log($node_num)/log(2))]
    for { set i 0 } { $i < $order } { incr i } {
	animateCursor
	set d [expr {int(pow(2, $i))}]
	for { set j 0 } { $j < $node_num } { incr j } {
	    if { [llength [ifcList [lindex $nodes $j]]] <= $i} {
		newLink [lindex $nodes $j] [lindex $nodes [expr {($j + $d) % $node_num}]]
	    }
	}
    }

    topoGenDone $nodes
}

#
# Clique
#
#****f* topogen.tcl/K
# NAME
#   K -- clique topology
# SYNOPSIS
#   K $nodes
# FUNCTION
#   Creates clique topology.
# INPUTS
#   * nodes -- nodes
#****
proc K { nodes } {
    set node_num [llength $nodes]
    for { set i 0 } { $i < [expr {$node_num - 1}] } { incr i } {
	animateCursor
	for { set j [expr {$i + 1}] } { $j < $node_num } {incr j } {
	    newLink [lindex $nodes $i] [lindex $nodes $j]
	}
    }

    topoGenDone $nodes
}

#
# Bipartite
#
#****f* topogen.tcl/Kb
# NAME
#   Kb -- bipartite topology
# SYNOPSIS
#   Kb $v1 $v2
# FUNCTION
#   Creates bipartite topology.
# INPUTS
#   * v1 -- nodes1
#   * v2 -- nodes2
#****
proc Kb { v1 v2 } {
    set n1 [llength $v1]
    set n2 [llength $v2]
    for { set i 0 } { $i < $n1 } { incr i } {
	animateCursor
	for { set j 0 } { $j < $n2 } {incr j } {
	    newLink [lindex $v1 $i] [lindex $v2 $j]
	}
    }

    topoGenDone "$v1 $v2"
}

#****f* topogen.tcl/Kbhelper
# NAME
#   Kbhelper -- bipartite topology helper
# SYNOPSIS
#   Kbhelper $node_num $m
# FUNCTION
#
# INPUTS
#   * node_num --
#   * m --
#****
proc Kbhelper { node_num m } {
    set nodes [newNodes [expr $node_num + $m]]
    Kb [lrange $nodes 0 [expr $node_num - 1]] [lrange $nodes $node_num end]
}

#
# Random
#
#****f* topogen.tcl/R
# NAME
#   R -- random topology
# SYNOPSIS
#   R $nodes $m
# FUNCTION
#   Creates random topology.
# INPUTS
#   * nodes -- nodes
#   * m --
#****
proc R { nodes m } {
    set cn [lindex $nodes 0]
    set dn [lrange $nodes 1 end]

    set i 0
    while { $i < $m } {
	if { [llength $dn] > 0 } {
	    set node_1 [expr int(rand() * [llength $cn])]
	    set node_2 [expr int(rand() * [llength $dn])]
	    newLink [lindex $cn $node_1] [lindex $dn $node_2]
	    lappend cn [lindex $dn $node_2]
	    set dn [lreplace $dn $node_2 $node_2]
	    incr i
	} else {
	    set node_1 [expr int(rand() * [llength $nodes])]
	    set node_2 [expr int(rand() * [llength $nodes])]
	    if { $node_1 != $node_2 &&
		[linkByPeers [lindex $nodes $node_1] [lindex $nodes $node_2]] == ""} {
		newLink [lindex $nodes $node_1] [lindex $nodes $node_2]
		incr i
	    }
	}
    }

    topoGenDone $nodes
}
