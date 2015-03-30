#!/usr/local/bin/tclsh8.6
package require cmdline

set command [exec basename $argv0]

set options {
    {l		"get experiment list"}
    {v.arg	"" "get vimage name"}
    {n.arg	"" "get vimage node name"}
    {e.arg	"" "get vimage eid name"}
    {j.arg	"" "get jail id"}
    {eid.arg	"" "choose experiment eid"}
}
catch {array set params [::cmdline::getoptions argv $options]} err
if { $err != "" } {
    puts $err
    exit
}

if { $params(v) != "" } {
    set output [exec jls -h name host.hostname]
    set output [split $output "\n"]
    foreach line $output {
	if {$params(v) in $line} {
	    set v [lindex [split $line " "] 0]
	    puts $v
	}
    }
    exit
}

if { $params(n) != "" } {
    set output [exec jls -h name host.hostname]
    set output [split $output "\n"]
    foreach line $output {
	if {$params(n) in $line} {
	    set n [lindex [split [lindex [split $line " "] 0] "."] 1]
	    puts $n
	}
    }
    exit
}

if { $params(e) != "" } {
    set output [exec jls -h name host.hostname]
    set output [split $output "\n"]
    foreach line $output {
	if {$params(e) in $line} {
	    set e [lindex [split [lindex [split $line " "] 0] "."] 0]
	    puts $e
	}
    }
    exit
}

if { $params(j) != "" } {
    set output [exec jls -h jid host.hostname]
    set output [split $output "\n"]
    foreach line $output {
	if {$params(j) in $line} {
	    set v [lindex [split $line " "] 0]
	    puts $v
	}
    }
    exit
}

if { $params(l) } {
    set output [exec jls -h name]
    set output [split $output "\n"]
    set eid_list ""
    foreach line $output {
	if {[string match "i*" $line] == 1} {
	    lappend eid_list [lindex [split $line "."] 0]
	}
    }
    set $eid_list [lsort -unique $eid_list]
    foreach eid $eid_list {
	puts $eid
    }
    exit
}

package require Expect
set node_name [lindex $argv 0]
set command [lrange $argv 1 end]
set eid $params(eid)

set output [exec jls -h jid name host.hostname]
set output [split $output "\n"]
set counter 0
if {$eid == ""} {
    foreach line $output {
	if {$node_name in $line} {
	    lappend jid_list [lindex [split $line " "] 0]
	    incr counter
	}
    }
} else {
    foreach line $output {
	if {$node_name in $line} {
	    if { [string match "* $eid.*" $line] == 1 } {
		lappend jid_list [lindex [split $line " "] 0]
		incr counter
	    }
	}
    }
}

switch $counter {
    0 {
	puts "Error: cannot find node named '$node_name'"
	exit
    }
    1 {
	if { $command == "" } {
	    set command "csh"
	}
	spawn -noecho csh -c "jexec $jid_list $command\n"
	exp_interact
	exit
    }
    default {
	puts "Error: '$node_name' is not a unique name."
	puts "It is used at least for nodes:"
	puts [exec jls | head -1]
	foreach jid $jid_list {
	    puts [exec jls | grep $jid]
	}
	puts "Choose one of the following experiment ID's using the '-e' \
	option:"
	set output [exec jls -h jid name]
	set output [split $output "\n"]
	foreach line $output {
	    foreach jid $jid_list {
		if {$jid in $line} {
		    set e [lindex [split [lindex [split $line " "] 1] "."] 0]
		    puts $e
		}
	    }
	}
    }
}
