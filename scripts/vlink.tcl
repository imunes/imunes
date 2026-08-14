upvar 0 ::cf::[set ::curcfg]::dict_run dict_run
upvar 0 ::cf::[set ::curcfg]::dict_run_gui dict_run_gui
upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg
upvar 0 ::cf::[set ::curcfg]::execute_vars execute_vars

global LIBDIR
global ROOTDIR
global vlink_args remote ttyrcmd isOSlinux isOSfreebsd

set dict_cfg [dict create]
set dict_run [dict create]
set dict_run_gui [dict create]
set execute_vars [dict create]

global help_msg
set help_msg "This command is used as an interface to ng_pipe/tc commands for
IMUNES virtual links.

Parameter 'link' can be given in any of the following forms:
 link_id
 node1:node2
 link_id@eid
 node1:node2@eid

Parameters 'node1/node2' can be given in any of the following forms (in any
order):
 node_id
 node_id/iface_id
 node_id/iface_name
 hostname
 hostname/iface_id
 hostname/iface_name

Usage:
vlink \[options\] link

For remote access, use:
vlink -remote <remote_host> <regular_vlink_arguments>

Possible options:"

global options
set options {
	{l				"print the list of all links"}
	{s				"print link status"}
	{r				"set link settings to default values"}
	{bw.arg			"" "set link bandwidth (bps)"}
	{b.arg			"" "set link bandwidth (bps)"}
	{BER.arg		"" "set link BER (1/value)"}
	{B.arg			"" "set link BER (1/value)"}
	{loss.arg		"" "set link loss (%)"}
	{L.arg			"" "set link loss (%)"}
	{direct.arg		"" "set link direct"}
	{dly.arg		"" "set link delay (us)"}
	{d.arg			"" "set link delay (us)"}
	{dup.arg		"" "set link duplicate (%)"}
	{D.arg			"" "set link duplicate (%)"}
	{e.arg			"" "specify experiment ID"}
	{eid.arg		"" "specify experiment ID"}
	{E				"show links in more details (extended)"}
}

proc vlinkShowHelp {} {
	global options help_msg

	# remove first word
	set output [::cmdline::usage $options $help_msg]
	set output [regsub {^\S+ } $output ""]

	sputs $output
}

proc pickArg { arg_name arg_alt arg_list } {
	set retv ""

	if { $arg_alt != "" } {
		set arg_idx [lsearch $arg_list $arg_alt]
		if { $arg_idx != -1 } {
			set retv [lindex $arg_list $arg_idx+1]
			set arg_list [lreplace $arg_list $arg_idx $arg_idx+1]
		}
	}

	if { $arg_name != "" } {
		set arg_idx [lsearch $arg_list $arg_name]
		if { $arg_idx != -1 } {
			set retv [lindex $arg_list $arg_idx+1]
			set arg_list [lreplace $arg_list $arg_idx $arg_idx+1]
		}
	}

	return [list $retv $arg_list]
}

proc findLink { running_eids given_eid link_idname } {
	lassign [split $link_idname "@"] link_idname new_given_eid
	if { $new_given_eid != "" } {
		if { $given_eid != "" } {
			return -code error "Use only -e/-eid or @eid."
		}

		set given_eid $new_given_eid
	}

	if { $link_idname == "" } {
		return -code error "Link not given! Run `vlink -l` to check all links."
	}

	if { $given_eid != "" } {
		if { $given_eid ni $running_eids } {
			return -code error "Experiment with ID '$given_eid' not running! Running experiments:\n[join $running_eids "\n"]"
		}

		set running_eids $given_eid
	}

	lassign [split $link_idname ":"] given_left given_right
	if { $given_right == "" } {
		set link_id $given_left
	} else {
		set link_id ""
		lassign [split $given_left "/"] node1_idname iface1_idname
		lassign [split $given_right "/"] node2_idname iface2_idname
	}

	set eids {}
	set links {}
	foreach eid $running_eids {
		try {
			resumeSelectedExperiment $eid
		} on error err {
			sputs stderr "ERROR: cannot attach to experiment $eid: '$err'"

			continue
		}

		set cur_link_list [getFromRunning "link_list"]
		if { $link_id != "" } {
			if { $link_id ni $cur_link_list } {
				continue
			}

			set found_link_id $link_id
		} else {
			set node_list [getFromRunning "node_list"]

			set node1_id [getNodeIdFromHostname $node1_idname]
			if { $node1_id == "" } {
				# no such node!
				continue
			}

			if { [llength $node1_id] > 1 } {
				sputs stderr "WARNING: Multiple nodes with same name '$node1_idname' ([join $node1_id ", "]) were found in experiment $eid. Use 'link_id', or specify each endpoint using 'node_id'."
				continue
			}

			set node2_id [getNodeIdFromHostname $node2_idname]
			if { $node2_id == "" } {
				# no such node!
				continue
			}

			if { [llength $node2_id] > 1 } {
				sputs stderr "WARNING: Multiple nodes with same name '$node2_idname' ([join $node2_id ", "]) were found in experiment $eid. Use 'link_id', or specify each endpoint using 'node_id'."
			}

			set iface1_id ""
			if { $iface1_idname != "" } {
				set iface1_id [getIfcIdFromName $node1_id $iface1_idname]
				if { $iface1_id == "" } {
					continue
				}
			}

			set iface2_id ""
			if { $iface2_idname != "" } {
				set iface2_id [getIfcIdFromName $node2_id $iface2_idname]
				if { $iface2_id == "" } {
					continue
				}
			}

			set node_pairs {}
			foreach cur_link_id $cur_link_list {
				lassign [getLinkPeers $cur_link_id] cur_node1_id cur_node2_id
				if { "$node1_id $node2_id" != "$cur_node1_id $cur_node2_id" } {
					if { "$node2_id $node1_id" != "$cur_node1_id $cur_node2_id" } {
						continue
					}

					# reverse
					lassign "$cur_node1_id $cur_node2_id" cur_node2_id cur_node1_id
					lassign [getLinkPeersIfaces $cur_link_id] cur_iface2_id cur_iface1_id
				} else {
					lassign [getLinkPeersIfaces $cur_link_id] cur_iface1_id cur_iface2_id
				}

				if { $node1_id == $node2_id } {
					if {
						$iface1_id != "" &&
						$iface2_id != "" &&
						$iface1_id == $iface2_id
					} {
						# same node and same interface - skip this
						continue
					}

					if {
						$iface1_id != "" &&
						$iface1_id != $cur_iface1_id &&
						$iface1_id != $cur_iface2_id
					} {
						continue
					}

					if {
						$iface2_id != "" &&
						$iface2_id != $cur_iface1_id &&
						$iface2_id != $cur_iface2_id
					} {
						continue
					}
				} else {
					if {
						$iface1_id != "" &&
						$iface1_id != $cur_iface1_id
					} {
						continue
					}

					if {
						$iface2_id != "" &&
						$iface2_id != $cur_iface2_id
					} {
						continue
					}
				}

				lappend node_pairs "$cur_link_id $cur_node1_id/$cur_iface1_id:$cur_node2_id/$cur_iface2_id"
			}

			if { [llength $node_pairs] == 0 } {
				continue
			}

			if { [llength $node_pairs] > 1 } {
				sputs stderr "WARNING: Multiple links with same peers '$link_idname' ([join $node_pairs ", "]) were found in experiment $eid"
				continue
			}

			set found_link_id [lindex [lindex $node_pairs 0] 0]
		}

		lappend eids $eid
		lappend links $found_link_id
	}

	if { [llength $eids] > 1 } {
		return -code error "Link with name/ID '$link_idname' was found in multiple experiments:\n[join $eids "\n"]"
	}

	if { [llength $links] > 1 } {
		return -code error "Multiple links with same peers '$link_idname' ([join $links ", "]) were found in experiment [lindex $eids 0]"
	}

	if { $links == {} } {
		return -code error "Link '$link_idname' not found!"
	}

	return [list $eids $links]
}

set given_eid ""

if { [lindex $vlink_args 0] in "\"\" -h -help --help" } {
	# show help
	vlinkShowHelp

	exit 0
}

if { [lindex $vlink_args 0] == "-remote" } {
	vlinkShowHelp

	sputs stderr "ERROR: Use '-remote' as an argument for the 'imunes' command."

	exit 1
}

if { "-E" in $vlink_args } {
	set vlink_args [removeFromList $vlink_args "-E"]
	set show_extended_links 1
} else {
	set show_extended_links 0
}

lassign [pickArg "-eid" "-e" $vlink_args] given_eid vlink_args

set running_eids [lsort [getResumableExperiments]]
if { $given_eid != "" } {
	if { $given_eid ni $running_eids } {
		sputs stderr "ERROR: Experiment with ID '$given_eid' not running! Running experiments:\n[join $running_eids "\n"]"

		exit 1
	}

	set running_eids $given_eid
}

if { "-l" in $vlink_args } {
	lassign [pickArg "-l" "" $vlink_args] new_given_eid vlink_args
	if { $given_eid == "" && $new_given_eid != "" } {
		set running_eids $new_given_eid
	}

	if { $vlink_args != {} } {
		sputs stderr "ERROR: Too many arguments."

		exit 1
	}

	# list experiments with link list
	set eids {}
	set extended_eids {}
	foreach eid $running_eids {
		try {
			resumeSelectedExperiment $eid
		} on error err {
			sputs stderr "ERROR: cannot attach to experiment $eid: '$err'"

			continue
		}

		set link_list {}
		set extended_link_list {}
		foreach link_id [getFromRunning "link_list"] {
			if { [isRunningLink $link_id] } {
				set link_running ""
			} else {
				set link_running "*"
			}

			if { [getLinkDirect $link_id] } {
				set link_direct "(d)"
			} else {
				set link_direct ""
			}

			lassign [getLinkPeers $link_id] node1_id node2_id
			if { ! $show_extended_links } {
				lappend link_list "$link_id$link_direct|[getNodeName $node1_id]:[getNodeName $node2_id]$link_running"
			} else {
				lassign [getLinkPeersIfaces $link_id] iface1_id iface2_id
				lappend extended_link_list "$link_id$link_direct|[getNodeName $node1_id]($node1_id)/[getIfcName $node1_id $iface1_id]($iface1_id):[getNodeName $node2_id]($node2_id)/[getIfcName $node2_id $iface2_id]($iface2_id)$link_running"
			}
		}

		if { ! $show_extended_links } {
			if { $link_list != {} } {
				lappend eids "$eid \[[join $link_list ", "]\]"
			}
		} else {
			if { $extended_link_list != {} } {
				lappend extended_eids "$eid \[[join $extended_link_list ", "]\]"
			}
		}
	}

	if { ! $show_extended_links } {
		if { $eids != {} } {
			sputs "[join $eids "\n"]"
		}
	} else {
		if { $extended_eids != {} } {
			sputs "[join $extended_eids "\n"]"
		}
	}

	exit 0
}

if { "-s" in $vlink_args } {
	lassign [pickArg "-s" "" $vlink_args] link_idname vlink_args

	if { $vlink_args != {} } {
		sputs stderr "ERROR: too many arguments."

		exit 1
	}

	try {
		findLink $running_eids $given_eid $link_idname
	} on ok retv {
		lassign $retv eids links
	} on error err {
		sputs stderr "ERROR: $err"

		exit 1
	}

	set eid [lindex $eids 0]
	set link_id [lindex $links 0]

	try {
		resumeSelectedExperiment $eid
	} on error err {
		sputs stderr "ERROR: cannot attach to experiment $eid: '$err'"

		exit 1
	}

	if { [getLinkDirect $link_id] } {
		sputs "Link $link_idname\n  direct"

		exit 0
	}

	set label_str ""
	set bwstr "[getLinkBandwidthString $link_id]"
	set delstr [getLinkDelayString $link_id]
	set ber [getLinkBER $link_id]
	set loss [getLinkLoss $link_id]
	set dup [getLinkDup $link_id]
	if { "$bwstr" != "" } {
		lappend label_str "bandwidth: $bwstr"
	}
	if { "$delstr" != "" } {
		lappend label_str "delay: $delstr"
	}
	if { "$ber" != "" } {
		lappend label_str "ber: $ber"
	}
	if { "$loss" != "" } {
		lappend label_str "loss: $loss%"
	}
	if { "$dup" != "" } {
		lappend label_str "duplicate: $dup%"
	}

	set str ""
	foreach elem $label_str {
		if { $str == "" } {
			set str "$str  $elem"
		} else {
			set str "$str\n  $elem"
		}
	}

	if { $str == "" } {
		set str " No currently applied settings."
	}

	sputs "Link $link_idname\n$str"

	exit 0
}

if { "-r" in $vlink_args } {
	lassign [pickArg "-r" "" $vlink_args] link_idname vlink_args

	if { $vlink_args != {} } {
		sputs stderr "ERROR: too many arguments."

		exit 1
	}

	try {
		findLink $running_eids $given_eid $link_idname
	} on ok retv {
		lassign $retv eids links
	} on error err {
		sputs stderr "ERROR: $err"

		exit 1
	}

	set eid [lindex $eids 0]
	set link_id [lindex $links 0]

	try {
		resumeSelectedExperiment $eid
	} on error err {
		sputs stderr "ERROR: cannot attach to experiment $eid: '$err'"

		exit 1
	}

	try {
		createExperimentFiles $eid
	} on error err {
		sputs "ERROR: error writing to experiment directory: '$err'"

		exit 1
	}

	linkResetConfig $link_id

	sputs "\nLink $link_idname reset"

	if { [getLinkDirect $link_id] } {
		sputs stderr "\nWARNING: link '$link_id' is direct, changes not active."
	}

	exit 0
}

if { "-direct" in $vlink_args } {
	lassign [pickArg "-direct" "" $vlink_args] set_direct vlink_args
	if { $set_direct ni "0 1 true false" } {
		sputs stderr "ERROR: validation failed for direct '$set_direct'"
		sputs stderr " - 0 or false -> set to regular"
		sputs stderr " - 1 or true -> set to direct"

		exit 1
	}

	set link_idname [lindex $vlink_args end]
	try {
		findLink $running_eids $given_eid $link_idname
	} on ok retv {
		lassign $retv eids links
	} on error err {
		sputs stderr "ERROR: $err"

		exit 1
	}

	set eid [lindex $eids 0]
	set link_id [lindex $links 0]

	try {
		resumeSelectedExperiment $eid
	} on error err {
		sputs stderr "ERROR: cannot attach to experiment $eid: '$err'"

		exit 1
	}

	set is_direct [getLinkDirect $link_id]
	if { $is_direct && $set_direct } {
		sputs "Link '$link_idname' already direct"

		exit 0
	}

	if { ! $is_direct && ! $set_direct } {
		sputs "Link '$link_idname' already regular"

		exit 0
	}

	try {
		createExperimentFiles $eid
	} on error err {
		sputs "ERROR: error writing to experiment directory: '$err'"

		exit 1
	}

	setLinkDirect $link_id $set_direct

	if { $set_direct } {
		set str "direct"
	} else {
		set str "regular"
	}

	redeployCfg

	sputs "\nLink '$link_idname' set to $str"

	exit 0
}

foreach arg "{bw b} {BER B} {loss L} {dly d} {dup D}" {
	lassign $arg arg_name arg_alt
	lassign [pickArg "-$arg_name" "-$arg_alt" $vlink_args] ${arg_name}_value vlink_args
}

# validate units and values
if { $bw_value != "" } {
	set err 0
	if { ! [regexp {^[0-9]+(?:\.[0-9]+)?(?:[KMGT](?:bit)?|bit)?$} $bw_value ] } {
		set err 1
	} else {
		regsub "bit" $bw_value "" bw_value
		set bw_value [expr round ([string map {"K" "*1e3" "M" "*1e6" "G" "*1e9" "T" "*1e12"} $bw_value])]
		if { $bw_value < 0 || $bw_value > 1000000000000 } {
			set err 1
		}
	}

	if { $err } {
		sputs stderr "ERROR: validation failed for bandwidth '$bw_value'"
		sputs stderr " - \[0-1000000000000]"
		sputs stderr " - no units or bit -> bit/s"
		sputs stderr " - K or Kbit -> Kbit/s"
		sputs stderr " - M or Mbit -> Mbit/s"
		sputs stderr " - G or Gbit -> Gbit/s"
		sputs stderr " - T or Tbit -> Tbit/s"

		exit 1
	}
}

if { $dly_value != "" } {
	set err 0
	if { ! [regexp {^[0-9]+(?:\.[0-9]+)?(?:us|ms|s)?$} $dly_value ] } {
		set err 1
	} else {
		set dly_value [expr round ([string map {"us" "*1" "ms" "*1e3" "s" "*1e6"} $dly_value])]
		if { $dly_value < 0 || $dly_value > 10000000 } {
			set err 1
		}
	}

	if { $err } {
		sputs stderr "ERROR: validation failed for delay '$dly_value'"
		sputs stderr " - \[0-10000000]"
		sputs stderr " - no units or us -> microseconds"
		sputs stderr " - ms -> miliseconds"
		sputs stderr " - s -> seconds"

		exit 1
	}
}

if { $BER_value != "" } {
	set err 0
	if { ! [regexp {^[0-9]+$} $BER_value ] } {
		set err 1
	} else {
		set BER_value [expr round ($BER_value)]
		if { $BER_value < 0 || $BER_value > 10000000000000 } {
			set err 1
		}
	}

	if { $err } {
		sputs stderr "ERROR: validation failed for BER '$BER_value'"
		sputs stderr " - \[0-10000000000000]"
		sputs stderr " - no units"

		exit 1
	}
}

if { $loss_value != "" } {
	set err 0
	if { ! [regexp {^[0-9]+(?:\.[0-9]+)?%?$} $loss_value ] } {
		set err 1
	} else {
		regsub "%" $loss_value "" loss_value
		if { $loss_value < 0 || $loss_value > 100 } {
			set err 1
		}
	}

	if { $err } {
		sputs stderr "ERROR: validation failed for loss '$loss_value'"
		sputs stderr " - \[0-100]"
		sputs stderr " - no units or % -> percentage"

		exit 1
	}
}

if { $dup_value != "" } {
	set err 0
	if { ! [regexp {^[0-9]+(?:\.[0-9]+)?%?$} $dup_value ] } {
		set err 1
	} else {
		regsub "%" $dup_value "" dup_value
		if { $dup_value < 0 || $dup_value > 50 } {
			set err 1
		}
	}

	if { $err } {
		sputs stderr "ERROR: validation failed for duplicate '$dup_value'"
		sputs stderr " - \[0-50]"
		sputs stderr " - no units or % -> percentage"

		exit 1
	}
}

if { "$bw_value$BER_value$loss_value$dly_value$dup_value" == "" } {
	vlinkShowHelp

	sputs stderr "No arguments given."

	exit 1
}
# /validate units and values

set link_idname [lindex $vlink_args end]
try {
	findLink $running_eids $given_eid $link_idname
} on ok retv {
	lassign $retv eids links
} on error err {
	sputs stderr "ERROR: $err"

	exit 1
}

set eid [lindex $eids 0]
set link_id [lindex $links 0]

try {
	resumeSelectedExperiment $eid
} on error err {
	sputs stderr "ERROR: cannot attach to experiment $eid: '$err'"

	exit 1
}

try {
	createExperimentFiles $eid
} on error err {
	sputs "ERROR: error writing to experiment directory: '$err'"

	exit 1
}

if { $bw_value != "" } {
	setLinkBandwidth $link_id $bw_value
}

if { $BER_value != "" } {
	setLinkBER $link_id $BER_value
}

if { $loss_value != "" } {
	setLinkLoss $link_id $loss_value
}

if { $dly_value != "" } {
	setLinkDelay $link_id $dly_value
}

if { $dup_value != "" } {
	setLinkDup $link_id $dup_value
}

redeployCfg

sputs "\nLink '$link_id'"

if { $bw_value != "" } {
	sputs " - bandwidth set to $bw_value bit/s"
}

if { $BER_value != "" } {
	sputs " - BER set to $BER_value"
}

if { $loss_value != "" } {
	sputs " - loss set to $loss_value %"
}

if { $dly_value != "" } {
	sputs " - delay set to $dly_value us"
}

if { $dup_value != "" } {
	sputs " - duplicate set to $dup_value %"
}

if { [getLinkDirect $link_id] } {
	sputs stderr "\nWARNING: link '$link_id' is direct, changes not active."
}

exit 0
