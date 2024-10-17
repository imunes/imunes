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
#   newNodes $n
# FUNCTION
#   Creates n new nodes.
# INPUTS
#   * n -- number of new nodes
# RESULT
#   * v -- created nodes
#****
proc newNodes { n } {
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    global grid sizex sizey activetool

    set v {}
    set r [expr {($n - 1) * (1 + 4 / $n) * $grid / 2}]
    set x0 [expr {$sizex / 2}]
    set y0 [expr {$sizey / 2}]
    set twopidivn [expr {acos(0) * 4 / $n}]
    if { $activetool == "router" } {
	set dy 24
    } else {
	set dy 32
    }

    for { set i 0 } { $i < $n } { incr i } {
	set new_node [newNode $activetool]
	set x [expr {$x0 + $r * cos($twopidivn * $i)}]
	set y [expr {$y0 - $r * sin($twopidivn * $i)}]
	setNodeCoords $new_node "$x $y"
	setNodeLabelCoords $new_node "$x [expr {$y + $dy}]"
	setNodeCanvas $new_node $curcanvas
	lappend v $new_node
    }

    return $v
}

#****f* topogen.tcl/topoGenDone
# NAME
#   topoGenDone -- topology generating done
# SYNOPSIS
#   topoGenDone $v
# FUNCTION
#   This procedure is called when topology generating is completed.
# INPUTS
#   * v -- nodes
#****
proc topoGenDone { v } {
    global changed

    set changed 1
    updateUndoLog
    redrawAll
    selectNodes $v
}

#
# Chain
#
#****f* topogen.tcl/P
# NAME
#   P -- chain topology
# SYNOPSIS
#   P $v
# FUNCTION
#   Creates chain topology.
# INPUTS
#   * v -- nodes
#****
proc P { v } {
    .panwin.f1.c config -cursor watch; update
    set n [llength $v]
    for { set i 0 } { $i < [expr {$n - 1}] } { incr i } {
	newLink [lindex $v $i] [lindex $v [expr {($i + 1) % $n}]]
    }
    topoGenDone $v
}

#
# Cycle
#
#****f* topogen.tcl/C
# NAME
#   C -- cycle topology
# SYNOPSIS
#   C $v
# FUNCTION
#   Creates cycle topology.
# INPUTS
#   * v -- nodes
#****
proc C { v } {
    .panwin.f1.c config -cursor watch; update
    set n [llength $v]
    for { set i 0 } { $i < $n } { incr i } {
	newLink [lindex $v $i] [lindex $v [expr {($i + 1) % $n}]]
    }
    topoGenDone $v
}

#
# Wheel 
#
#****f* topogen.tcl/W
# NAME
#   W -- wheel topology
# SYNOPSIS
#   W $v
# FUNCTION
#   Creates wheel topology.
# INPUTS
#   * v -- nodes
#****
proc W { v } {
    .panwin.f1.c config -cursor watch; update
    set n [llength $v]
    set vr [lindex $v 0]
    set vt "$v [lindex $v 1]"
    for { set i 1 } { $i < $n } { incr i } {
	newLink $vr [lindex $v $i]
	newLink [lindex $v $i] [lindex $vt [expr {$i + 1}]]
    }
    topoGenDone $v
}

#
# Cube
#
#****f* topogen.tcl/Q
# NAME
#   Q -- cube topology
# SYNOPSIS
#   Q $v
# FUNCTION
#   Creates cube topology.
# INPUTS
#   * v -- nodes
#****
proc Q { v } {
    set n [llength $v]
    set order [expr int(log($n)/log(2))]
    for { set i 0 } { $i < $order } { incr i } {
	animateCursor
	set d [expr {int(pow(2, $i))}]
	for { set j 0 } { $j < $n } { incr j } {
	    if { [llength [ifcList [lindex $v $j]]] <= $i} {
		newLink [lindex $v $j] [lindex $v [expr {($j + $d) % $n}]]
	    }
	}
    }
    topoGenDone $v
}

#
# Clique
#
#****f* topogen.tcl/K
# NAME
#   K -- clique topology
# SYNOPSIS
#   K $v
# FUNCTION
#   Creates clique topology.
# INPUTS
#   * v -- nodes
#****
proc K { v } {
    set n [llength $v]
    for { set i 0 } { $i < [expr {$n - 1}] } { incr i } {
	animateCursor
	for { set j [expr {$i + 1}] } { $j < $n } {incr j } {
	    newLink [lindex $v $i] [lindex $v $j]
	}
    }
    topoGenDone $v
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
#   Kbhelper $n $m
# FUNCTION
#   
# INPUTS
#   * n -- 
#   * m -- 
#****
proc Kbhelper { n m } {
    set v [newNodes [expr $n + $m]]
    Kb [lrange $v 0 [expr $n - 1]] [lrange $v $n end]
}

#
# Random
#
#****f* topogen.tcl/R
# NAME
#   R -- random topology
# SYNOPSIS
#   R $v $m
# FUNCTION
#   Creates random topology.
# INPUTS
#   * v -- nodes
#   * m -- 
#****
proc R { v m } {
    set cn [lindex $v 0]
    set dn [lrange $v 1 end]
    
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
	    set node_1 [expr int(rand() * [llength $v])]
	    set node_2 [expr int(rand() * [llength $v])]
	    if { $node_1 != $node_2 &&
		[linkByPeers [lindex $v $node_1] [lindex $v $node_2]] == ""} {
		newLink [lindex $v $node_1] [lindex $v $node_2]
		incr i
	    }
	}
    }
    topoGenDone $v
}
