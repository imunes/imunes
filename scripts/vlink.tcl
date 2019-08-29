#!/usr/bin/env tclsh8.6
package require cmdline
package require platform

# check for uid
catch {exec id -u} uid
if { $uid != "0" } {
    puts stderr "Error: vlink must be executed with root privileges."
    exit 1
}

# procedure for parsing arguments
proc parseArgs { arg1 arg2 defValue } {
    global check
    if { $arg1 != "" } {
	incr check
	return $arg1
    } elseif { $arg2 != "" } {
	incr check
	return $arg2
    }
    return $defValue
}

# procedure that returns wheter an interface belongs to a virtual node (docker
# instance) or openvswitch
proc isNodeInterface { ifname } {
    if { [string match "eth\[0-9\]*" $ifname] } {
	return 1
    }
    return 0
}

proc getLossFromBer { ber } {
    # calculate loss % from ber assuming the average packet size is 576 bytes
    if { $ber != 0 } {
	set loss [expr (1 / double($ber)) * 576 * 8 * 100]
	if { $loss > 100 } {
	    set loss 100
	}
    } else {
	set loss 0
    }
    return $loss
}

proc getBerFromLoss { loss } {
    # calculate ber from loss % assuming the average packet size is 576 bytes
    set loss [string trimright $loss %]
    if { $loss != 0 } {
	set ber [expr round((1 / double($loss)) * 576 * 8 * 100)]
	if { $ber == 4608 } {
	    set ber 1
	}
    } else {
	set ber 0
    }
    return $ber
}

# transform bandwidth from netem output to bps
proc getNetemBandwidth { band } {
    return [expr round \
	([string map {bit "*1" Kbit "*1e3" Mbit "*1e6" Gbit "*1e9" Tbit "*1e12"} $band])]
}

# transform bandwidth from calling arguments to bps
proc getStandardBandwidth { band } {
    return [expr round \
	([string map {K "*1e3" M "*1e6" G "*1e9" T "*1e12"} $band])]
}

# transform both netem and calling arguments delay to us (microseconds)
proc getStandardDelay { delay } {
    return [expr round([string map {us "*1" ms "*1e3" s "*1e6"} $delay])]
}

# generic procedure that transforms from bps and us to units for nicer printing
proc getUnitForPrint { value units } {
    for {set i 0} { $i < [llength $units] } {incr i} {
	set head [expr double($value) / 10**(3*$i)]
	if { $head < 1 } {
	    return "[format %.6g [expr $head*10**3]][lindex $units $i-1]"
	}
    }
    return "[format %.6g $head][lindex $units end]"
}

# transform bandwidth for print
proc getBandwidthForPrint { band } {
    set units [list bps Kbps Mbps Gbps Tbps]
    return [getUnitForPrint $band $units]
}

# transform delay for print
proc getDelayForPrint { delay } {
    set units [list us ms s]
    return [getUnitForPrint $delay $units]
}

# get link settings into an ordered list on Linux
proc getLinuxLinkStatus { nodename eid ldata } {
    set node $nodename\@$eid
    set nodeid [lindex $ldata 0]
    set ifname [lindex $ldata 1]

    if { [isNodeInterface $ifname] } {
	catch {exec himage $node tc qdisc show dev $ifname} settings
    } else {
	catch {exec tc qdisc show dev $eid-$nodeid-$ifname} settings
    }

    foreach val {delay rate duplicate loss} {
	set $val -1
	if { $val in $settings } {
	    set $val [lindex $settings [lsearch $settings "$val*"]+1]
	}
    }

    set bandwidth [getNetemBandwidth $rate]
    set delay [getStandardDelay $delay]
    set duplicate [expr round ([string trimright $duplicate "%"])]

    set BER -1
    if { $loss > -1 } {
	# don't process loss if not set
	set BER [getBerFromLoss $loss]
    }

    # don't change this order, the rest of the script depends on it
    foreach val {bandwidth BER delay duplicate} {
	lappend curr_set [list $val [set $val]]
    }

    return $curr_set
}

# get link settings into an ordered list on FreeBSD
proc getFreeBSDLinkStatus { eid ldata } {
    catch {exec jexec $eid ngctl msg $ldata: getcfg} settings
    set settings [lindex [lindex [split $settings "\n"] 1] 1]
    set linkStatus ""
    foreach varname { bandwidth delay BER duplicate } {
	set index [lsearch $settings "$varname=*"]
	if { $index != -1 } {
	    lappend linkStatus "$varname [lindex [split [lindex $settings $index] "="] end]"
	}
    }
    return $linkStatus
}

# print current link settings to terminal
proc printLinkStatus { lname eid curr_set } {
    set check 0
    puts "$lname\@$eid:"
    foreach sett $curr_set {
	if { [lindex $sett 1] != -1 } {
	    switch [lindex $sett 0] {
		bandwidth {
		    puts "\t[lindex $sett 0] [getBandwidthForPrint [lindex $sett 1]]"
		}
		BER {
		    puts "\t[lindex $sett 0] [lindex $sett 1]"
		}
		delay {
		    puts "\t[lindex $sett 0] [getDelayForPrint [lindex $sett 1]]"
		}
		duplicate {
		    puts "\t[lindex $sett 0] [lindex $sett 1]%"
		}
	    }
	    incr check
	}
    }
    if { ! $check } {
	puts "\tNo currently applied settings."
    }
}

# apply settings on Linux
proc applyLinkSettingsLinux { bandwidth ber delay dup nodename eid ldata } {
    set node $nodename\@$eid

    set cfg ""
    if { $bandwidth != -1 } {
	lappend cfg "rate ${bandwidth}bit"
    }
    if { $ber != -1 } {
	set loss [getLossFromBer $ber]
	lappend cfg "loss random ${loss}%"
    }
    if { $delay != -1 } {
	lappend cfg "delay ${delay}us"
    }
    if { $dup != -1 } {
	lappend cfg "duplicate ${dup}%"
    }

    set nodeid [lindex $ldata 0]
    set ifname [lindex $ldata 1]

    # from the interface name deduct what type of node we're dealing with
    if { [isNodeInterface $ifname] } {
	# this is a docker image
	if { $cfg != "" } {
	    catch {eval "exec himage $node tc qdisc change dev $ifname root netem [join $cfg " "]"}
	}
    } else {
	# this is a switch (openvswitch)
	catch {eval "exec tc qdisc change dev $eid-$nodeid-$ifname root netem [join $cfg " "]"}
    }
}

# apply settings on FreeBSD 
proc applyLinkSettingsFreeBSD { bandwidth ber delay dup eid lname } {
    # build the config that should be applied
    append config "{ "
    if { $bandwidth != -1 } {
	if { $bandwidth == 0 } {
	    set bandwidth -1
	}
	append config "bandwidth=" $bandwidth " "
    }
    if { $delay != -1 } {
	if { $delay == 0 } {
	    set delay -1
	}
	append config "delay=" $delay " "
    }
    if { $dup != -1 && $ber != -1 } {
	if { $dup == 0 } {
	    set dup -1
	}
	if { $ber == 0 } {
	    set ber -1
	}
	append config "upstream={ duplicate=" $dup " BER=" $ber " }"
	append config "downstream={ duplicate=" $dup " BER=" $ber " }"
    } elseif { $dup != -1 } {
	if { $dup == 0 } {
	    set dup -1
	}
	append config "upstream={ duplicate=" $dup " }"
	append config "downstream={ duplicate=" $dup " }"
    } elseif { $ber != -1} {
	if { $ber == 0 } {
	    set ber -1
	}
	append config "upstream={ BER=" $ber " }"
	append config "downstream={ BER=" $ber " }"
    }
    append config " }"

    # apply config
    exec jexec $eid ngctl msg $lname: setcfg $config
}

# define possible call arguments
set options {
    {l		"print the list of all links"}
    {s		"print link status"}
    {r		"set link settings to default values"}
    {bw.arg	"" "set link bandwidth (bps)"}
    {b.arg	"" "set link bandwidth (bps)"}
    {BER.arg	"" "set link BER (1/value)"}
    {B.arg	"" "set link BER (1/value)"}
    {dly.arg	"" "set link delay (us)"}
    {d.arg	"" "set link delay (us)"}
    {dup.arg	"" "set link duplicate (%)"}
    {D.arg	"" "set link duplicate (%)"}
    {e.arg	"" "specify experiment ID"}
    {eid.arg	"" "specify experiment ID"}
}

set usage "\[options\] link_name\[@eid\]
options:"

# parse arguments
catch {array set params [::cmdline::getoptions argv $options $usage]} err
if { $err != "" } {
    puts stderr "Usage:"
    puts stderr $err
    exit 1
}

# something must be specified
if { $argc == 0 } {
    puts stderr "No arguments were specified."
    puts stderr "Usage:"
    puts stderr [::cmdline::usage $options $usage]
    exit 1
}

# link is the last argument
set link1 [lindex [split [lindex $argv 0] "@"] 0]

# eid can be specified through two cli options and as part of the link name
set eid1 [parseArgs $params(e) $params(eid) ""]
set eid2 [lindex [split [lindex $argv 0] "@"] 1]

# detect multiple eid usage
set selected_eid ""
if { $eid1 != "" && $eid2 != "" } {
    puts stderr "Only one eid option should be used."
    puts stderr "Usage:"
    puts stderr [::cmdline::usage $options $usage]
    exit 1
} else {
    set selected_eid [parseArgs $eid1 $eid2 ""]
}

set check 0
# get values from arguments, the first flag is preferred (b,B,d,D)
set ban [parseArgs $params(b) $params(bw) -1]
set BER [parseArgs $params(B) $params(BER) -1]
set del [parseArgs $params(d) $params(dly) -1]
set dup [parseArgs $params(D) $params(dup) -1]

# check if arguments are valid and transform them if needed
if { [regexp {^([[:digit:]]+)([KMGT])?$} $ban] } {
    set ban [getStandardBandwidth $ban]
} elseif { $ban != -1 } {
    puts stderr "Error: wrong bandwidth format (e.g. 1000, 10K, 5M, 2G, 1T)."
    exit 1
}
if { $BER != -1 && ! [regexp {^([[:digit:]]+)$} $BER] } {
    puts stderr "Error: wrong BER format, should be a number."
    exit 1
}
if { [regexp {^([[:digit:]]+)(([um])?s)?$} $del] } {
    set del [getStandardDelay $del]
} elseif { $del != -1 } {
    puts stderr "Error: wrong delay format (e.g. 100 == 100us, 100ms, 1s)."
    exit 1
}
if { [regexp {^([[:digit:]]+)(%)?$} $dup] } {
    set dup [string trimright $dup "%"]
} elseif { $dup != -1 } {
    puts stderr "Error: wrong duplicate format (e.g. 10, 10%)."
    exit 1
}

# reset values is the preferred option over setting new values
if { $params(r) } {
    set ban 0
    set del 0
    set BER 0
    set dup 0
    incr check    
}

set linkDelim ":"
# start parsing for nodes
set nodes [split $link1 $linkDelim]
set node0 [lindex $nodes 0]
set node1 [lindex $nodes 1]
set link2 "$node1$linkDelim$node0"

# get running experiments
set running_exps ""
catch {exec himage -l} himage
foreach line [split $himage "\n"] {
    set expid [lindex $line 0]
    lappend running_exps $expid
}

# if eid was specified see whether the experiment is running,
# if it's running trim down the running_exps list
if { $selected_eid != "" } {
    if { $selected_eid in $running_exps } {
	set running_exps $selected_eid
    } elseif {! $params(l)} {
	puts stderr "Error: Experiment with the specified eid ($selected_eid) is not running."
	exit 1
    }
}

# get experiments containing link
set containing_exps ""
foreach eid $running_exps {
    try {
	set f [open "/var/run/imunes/$eid/links" "r"]
	set ldata [read $f]
	close $f
    } on error { result options } {
	puts stderr "Could not open file \"/var/run/imunes/$eid/links\" for reading."
	puts stderr $result
	continue
    }

    set $eid ""
    foreach k [dict keys $ldata] {
	lappend $eid [lindex [dict get $ldata $k] end]
    }

    if { $link1 in [set $eid] } {
	lappend containing_exps $eid
    } elseif { $link2 in [set $eid] } {
	lappend containing_exps $eid
    }
}

# if list links was specified, output and exit
if { $params(l) } {
    foreach eid $running_exps {
	puts "$eid ([set $eid])"
    }
    exit 0
}

# exit if no link was specified and we don't list links
if { $link1 == "" } {
    puts stderr "No link was specified."
    puts stderr "Usage:"
    puts stderr [::cmdline::usage $options $usage]
    exit 1
}

# if the eid was specified but that experiment is not running print a custom
# error message
if { $selected_eid != "" && [llength $containing_exps] == 0 } {
    puts stderr "Error: The specified experiment ($selected_eid) does not have the \
	specified link ($link1)."
    exit 1
}

# if no link options were specified and link status is not requested, exit
if { $check == 0 && ! $params(s) } {
    puts stderr "No link options were specified."
    puts stderr "Usage:"
    puts stderr [::cmdline::usage $options $usage]
    exit 1
}

# finally check the number of valid experiments, if the number is different than
# 1 output the appropriate error message.
switch [llength $containing_exps] {
    0 {
	puts stderr "Error: There are no running experiments with link \"$link1\":"
	foreach eid $running_exps {
	    puts stderr "$eid ([set $eid])"
	}
	exit 1
    }
    1 {
	# read out link data
	set eid $containing_exps
	set f [open "/var/run/imunes/$eid/links" "r"]
	set ldata [read $f]
	close $f

	# check the real link name (n0:n1 or n1:n0) to enable proper dict usage
	set lname $link1
	if { $link2 in [set $eid] } {
	    set lname $link2
	}

	foreach lid [dict keys $ldata] {
	    set cur_name [lindex [dict get $ldata $lid] end]
	    if { $cur_name == $lname } {
		lappend lids $lid
	    }
	}

	switch [llength $lids] {
	    1 {
		set lid $lids
	    }
	    default {
		puts stderr "There are more links/nodes with the same name in the same experiment."
		puts stderr "    $eid ([set $eid])"
		puts stderr "For using vlink all nodes should be named differently."
		exit 1
	    }
	}

	# detect os
	set os [platform::identify]

	switch -glob -nocase $os {
	    "*freebsd*" {
		set node_data [lindex [dict get $ldata $lid] 0]

		if { $params(s) } {
		    set curr_set [getFreeBSDLinkStatus $eid $node_data]
		    printLinkStatus $lname $eid $curr_set
		    return 0
		}

		applyLinkSettingsFreeBSD $ban $BER $del $dup $eid $node_data
	    }
	    "*linux*" {
		set nodes [split $lname $linkDelim]
		set i 0
		# on linux we must apply settings on both sides of the link
		foreach node $nodes {
		    # get data for linux links
		    set node_data [lindex [lindex [dict get $ldata $lid] 1] $i]
		    
		    # get the current status
		    set curr_set [getLinuxLinkStatus $node $eid $node_data]
		    # if link status was specified, just output and exit
		    if { $params(s) } {
			printLinkStatus $lname $eid $curr_set
			return 0
		    }

		    set j 0
		    # apply unset settings from current status
		    # the settings are taken in the order forwarded from
		    # getLinuxLinkStatus and depend on it
		    foreach val {ban BER del dup} {
			if { [set $val] == -1 } {
			    set $val [lindex [lindex $curr_set $j] 1]
			}
			incr j
		    }

		    applyLinkSettingsLinux $ban $BER $del $dup $node $eid $node_data
		    incr i
		}
	    }
	}

	return 0
    }
    default {
	puts stderr "Error: There are multiple running experiments with link $link1."
	puts stderr "Choose one of the following experiment ID's using the '-e' \
	    or '-eid' option:"
	puts stderr " $containing_exps"
	exit 1
    }
}
