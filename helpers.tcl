proc getPrettyUsage { options } {
	lappend options {"help"	"Print this message"}

	set tabsize 4
	set tab_char "[string repeat " " $tabsize]"

	set usage    "Usage:\n"
	append usage "${tab_char}imunes \[OPTION...\] \[.imn FILE\]\n"
	append usage "\n"
	append usage "Options:\n"

	set no_secrets {}
	foreach opt $options {
		set vals [split [lindex $opt 0] "."]
		if { [lindex $vals end] == "secret" } {
			continue
		}

		set arg [lindex $vals 0]
		if { [lindex $vals 1] == "arg" } {
			lappend no_secrets [string length "-$arg.arg"]
		} else {
			lappend no_secrets [string length "-$arg"]
		}
	}

	set maxlen [tcl::mathfunc::max {*}$no_secrets]
	incr maxlen [expr $tabsize - ($maxlen % $tabsize)]

	foreach opt $options {
		set vals [split [lindex $opt 0] "."]
		if { [lindex $vals end] == "secret" } {
			continue
		}

		set arg [lindex $vals 0]
		if { [lindex $vals 1] == "arg" } {
			set arg "$arg.arg"
			set default_str " (default: '[lindex $opt end-1]')"
		} else {
			set default_str ""
		}

		append usage "${tab_char}-$arg"
		append usage "[string repeat " " [expr $maxlen - [string length $arg]]]"
		append usage "[lindex $opt end]${default_str}\n"
	}

	append usage "\nExamples:\n"
	append usage "${tab_char}imunes \[-e | -eid eid\] \[topology.imn\] - start IMUNES GUI\n"
	append usage "${tab_char}imunes -b \[-e | -eid eid\] \[topology.imn\] - start experiment (batch)\n"
	append usage "${tab_char}imunes -b -e | -eid eid - terminate experiment (batch)\n"

	return $usage
}

proc safePackageRequire { plist args } {
	foreach p $plist {
		try {
			package require $p
		} on error { result options } {
			puts stderr "Error loading package $p: $result"
			if { [llength $args] } {
				puts stderr [lindex $args 0]
			}
			exit 1
		}
	}
}

proc safeSourceFile { file } {
	global ROOTDIR LIBDIR all_modules_list
	global isOSfreebsd isOSlinux isOSwin
	try {
		source $file
	} on error { result options } {
		puts stderr "Error sourcing file $file: $result"
		exit 1
	}
}

proc parseCmdArgs { options usage } {
	global initMode execMode eid_base debug argv selected_experiment gui
	global printVersion prepareFlag forceFlag
	global max_jobs nodecreate_timeout ifacesconf_timeout nodeconf_timeout remote_factor
	global remote_error remote rcmd ttyrcmd remote_mux_path
	global escalation_comm rescalation_comm

	catch { array set params [::cmdline::getoptions argv $options $usage] } err
	if { $err != "" || $params(h) } {
		puts stderr $usage
		exit 1
	}

	set fileName [lindex $argv 0]
	if { ! [ string match "*.imn" $fileName ] && $fileName != "" } {
		puts stderr "File '$fileName' is not an IMUNES .imn file"
		exit 1
	}

	if { $params(i) } {
		set initMode 1
	}

	if { $params(c) || $params(cli) } {
		set gui 0
	}

	if { $params(r) != "" || $params(remote) != "" } {
		set remote $params(r)
		if { $params(remote) != "" } {
			set remote $params(remote)
		}

		if { $remote != "" } {
			set remote [string map {"+" " "} $remote]
			set escalation_comm ""
			if { [string match "*/*" $remote] } {
				lassign [split $remote "/"] escalation_comm remote
			}

			set rescalation_comm "sudo -i"
			if { [string match "*%*" $remote] } {
				lassign [split $remote "%"] remote rescalation_comm
			}

			set port_arg ""
			if { [string match "*:*" $remote] } {
				lassign [split $remote ":"] remote remote_port
				set port_arg "-p $remote_port"
			}

			set file_id [file tempfile tmp_path]
			close $file_id
			file delete $tmp_path
			set remote_mux_path "[file dirname $tmp_path]/.imunes-%r@%n"
			exec rm -f $remote_mux_path

			set ssh_args "-o ControlPersist=yes -o ControlMaster=auto"
			append ssh_args " $port_arg $remote $rescalation_comm"
			set rcmd "ssh -o ControlPath=$remote_mux_path $ssh_args"
			set ttyrcmd "ssh -t -o ControlPath=${remote_mux_path}_tty $ssh_args"

			set nodecreate_timeout [expr round($remote_factor * $nodecreate_timeout)]
			set nodeconf_timeout [expr round($remote_factor * $nodeconf_timeout)]
			set ifacesconf_timeout [expr round($remote_factor * $ifacesconf_timeout)]

			puts "Using remote host '$remote'"
		} else {
			puts stderr "Remote host not given."
			exit 1
		}
	}

	if { $params(j) != "" } {
		if { [string is integer $params(j)] } {
			set max_jobs $params(j)
		} else {
			puts stderr "Ignoring -j, dynamically calculate number of jobs as \[ncpus]"
		}
	}

	if { $params(b) || $params(batch) } {
		if { $params(e) == "" && $params(eid) == "" && $fileName == "" } {
			puts stderr $usage
			exit 1
		}

		set execMode batch
		set gui 0
	}

	if { $params(d) } {
		set debug 1
	}

	if { $params(e) != "" || $params(eid) != "" } {
		set eid_base $params(e)
		if { $params(eid) != "" } {
			set eid_base $params(eid)
		}
		if { $params(b) || $params(batch) } {
			puts "Using experiment ID '$eid_base'."
		}

		if { ! [regexp {^[[:alnum:]]+$} $eid_base] } {
			puts stderr "Experiment ID should only consists of alphanumeric characters."
			exit 1
		}
	}

	if { $params(v) || $params(version) } {
		set printVersion 1
	}

	if { $params(p) || $params(prepare) } {
		set prepareFlag 1
	}

	if { $params(f) || $params(force) } {
		set forceFlag 1
	}

	if { $execMode != "batch" && ($params(a) || $params(attach)) } {
		if { ! [info exists eid_base] } {
			puts stderr "Experiment ID not given (use -e or -eid)."
			exit 1
		}

		set selected_experiment $eid_base
	}

	if { $params(l) || $params(legacy) } {
		puts "Running in legacy mode"

		set nodecreate_timeout -1
		set nodeconf_timeout -1
		set ifacesconf_timeout -1
	}
}

proc fetchImunesVersion {} {
	global ROOTDIR LIBDIR imunesVersion imunesChangedDate
	global imunesLastYear imunesAdditions
	global CFG_VERSION

	set imunesCommit ""

	set verfile [open "$ROOTDIR/$LIBDIR/VERSION" r]
	set data [read $verfile]
	foreach line [split $data "\n"] {
		if { [string match "VERSION:*" $line] } {
			set imunesVersion [string range $line [expr [string first ":" $line] + 2] end]
		}
		if { [string match "CFG_VERSION:*" $line] } {
			set CFG_VERSION [string range $line [expr [string first ":" $line] + 2] end]
		}
		if { [string match "Commit:*" $line] } {
			set imunesCommit [string range $line [expr [string first ":" $line] + 2] end]
		}
		if { [string match "Last changed:*" $line] } {
			set imunesChangedDate [string range $line [expr [string first ":" $line] + 2] end]
		}
		if { [string match "Additions:*" $line] } {
			set imunesAdditions [string range $line [expr [string first ":" $line] + 2] end]
		}
	}

	if { [string match "*Format*" $imunesCommit] } {
		set imunesChangedDate ""
		set imunesLastYear ""
	} else {
		set imunesVersion "$imunesVersion (git: $imunesCommit)"
		set imunesLastYear [lindex [split $imunesChangedDate "-"] 0]
		set imunesChangedDate "Last changed: $imunesChangedDate"
	}
}

proc printImunesVersion {} {
	global baseTitle imunesVersion imunesChangedDate imunesAdditions

	puts "$baseTitle $imunesVersion"
	if { $imunesChangedDate != "" } {
		puts "$imunesChangedDate"
	}
	if { $imunesAdditions != "" } {
		puts "Additions: $imunesAdditions"
	}
}

proc setPlatformVariables {} {
	global isOSfreebsd isOSlinux isOSwin remote remote_error

	try {
		rexec uname -s
	} on error err {
		if { [string match "*Warning: Permanently added * to the list of known hosts.*" $err] == 1 } {
			set os [rexec uname -s]
			set remote_error ""
		} else {
			set remote_error "Cannot connect to remote '$remote':\n\n$err\n\nSwitching to local mode."
			puts stderr $remote_error
			set os [platform::identify]
			set remote ""
		}
	} on ok os {
		set remote_error ""
	}

	switch -glob -nocase $os {
		"*freebsd*" {
			set isOSfreebsd true
		}
		"*linux*" {
			set isOSlinux true
		}
		"*win*" {
			set isOSwin true
		}
	}
}

proc prepareVroot {} {
	global ROOTDIR LIBDIR
	global isOSfreebsd isOSlinux prepareFlag forceFlag

	if { $isOSfreebsd && $forceFlag } {
		catch { exec >@stdout umount /var/imunes/vroot/dev }
		catch { exec >@stdout chflags -R noschg /var/imunes/vroot }
		catch { exec >@stdout rm -fr /var/imunes/vroot }
	}

	if { $isOSlinux && $forceFlag } {
		catch { exec >@stdout docker rmi -f imunes/vroot }
	}

	set curdir [pwd]
	cd $ROOTDIR/$LIBDIR
	catch { exec >@stdout 2>@stdout sh scripts/prepare_vroot.sh }
	cd $curdir
}

proc removeFromList { list_values elements { keep_doubles "" } } {
	if { $elements == {} } {
		return $list_values
	}

	if { $keep_doubles != "" } {
		foreach element $elements {
			set idx [lsearch -exact $list_values $element]
			set list_values [lreplace $list_values $idx $idx]
		}

		return $list_values
	}

	foreach element $elements {
		set list_values [lsearch -not -all -inline -exact $list_values $element]
	}

	return $list_values
}

proc dputs { args } {
	global debug

	if { ! $debug } {
		return
	}

	set nonewline 0
	if { [lindex $args 0] == "-nonewline" } {
		set nonewline 1
		set args [lrange $args 1 end]
	}

	set fd "stdout"
	if { [llength $args] == 1 } {
		set args [list $fd [join $args]] ;
	}

	lassign $args channel s
	set cmd "puts"
	if { $nonewline } {
		lappend cmd "-nonewline"
	}

	lappend cmd $channel $s

	eval $cmd
	flush $fd
}

proc reloadSources {} {
	global ROOTDIR LIBDIR
	global all_modules_list node_types execMode
	global isOSlinux isOSfreebsd
	global debug gui

	set all_modules_list {}
	set runnable_node_types {}

	source "$ROOTDIR/$LIBDIR/helpers.tcl"

	# Runtime libriaries
	foreach file_path [glob -directory $ROOTDIR/$LIBDIR/runtime *.tcl] {
		if {
			[string match -nocase "*linux.tcl" $file_path] != 1 &&
			[string match -nocase "*freebsd.tcl" $file_path] != 1
		} {
			safeSourceFile $file_path
		}
	}

	if { $isOSlinux } {
		safeSourceFile $ROOTDIR/$LIBDIR/runtime/linux.tcl
	} elseif { $isOSfreebsd } {
		safeSourceFile $ROOTDIR/$LIBDIR/runtime/freebsd.tcl
	}

	# Configuration libraries
	foreach file_path [glob -nocomplain -directory $ROOTDIR/$LIBDIR/config *.tcl] {
		safeSourceFile $file_path
	}

	# Node base libraries
	foreach node_type $node_types {
		safeSourceFile "$ROOTDIR/$LIBDIR/nodes/$node_type.tcl"
	}

	# Node-specific configuration libraries
	foreach file_path [glob -nocomplain -directory $ROOTDIR/$LIBDIR/nodes/config *.tcl] {
		safeSourceFile $file_path
	}

	safeSourceFile "$ROOTDIR/$LIBDIR/nodes/localnodes.tcl"

	if { $execMode == "interactive" } {
		if { $gui } {
			safePackageRequire Tk "To run the IMUNES GUI, Tk must be installed."
		}

		# Node GUI base libraries
		foreach node_type $node_types {
			safeSourceFile "$ROOTDIR/$LIBDIR/gui/nodes/$node_type.tcl"
		}

		# Node-specific GUI configuration libraries
		foreach file_path [glob -nocomplain -directory $ROOTDIR/$LIBDIR/gui/nodes/config *.tcl] {
			safeSourceFile $file_path
		}

		set skip_files "theme.tcl initgui.tcl topogen.tcl debug.tcl"
		foreach file_path [glob -directory $ROOTDIR/$LIBDIR/gui *.tcl] {
			if { [file tail $file_path] ni $skip_files } {
				safeSourceFile $file_path
			}
		}
	}

	safeSourceFile "$ROOTDIR/$LIBDIR/gui/debug.tcl"

	applyOptions

	if { $gui } {
		redrawAll
		refreshToolBarNodes
	}

	dputs "Reloaded all sources."
}

proc rexec { args } {
	global rcmd remote max_jobs

	set cmd [list echo {*}$args | {*}$rcmd]

	dputs "CMD: '$cmd'"
	try {
		exec -- {*}$cmd
	} on ok retv {
		return $retv
	} on error err {
		if {
			$remote != ""  &&
			[string match "*mux_client_request_session: session request failed: Session open refused by peer*" $err]
		} {
			return -code error "Too many open connections: use -j flag to decrease max_jobs (current $max_jobs) or increase MaxSessions/MaxStartups on the remote server!"
		}

		return -code error $err
	}
}

proc invokeTypeProc { node_type proc_name args } {
	set retval ""
	if { [info procs $node_type.$proc_name] != "" } {
		set retval [$node_type.$proc_name {*}$args]
	} else {
		set retval ""
	}

	return $retval
}

proc invokeNodeProc { node_id proc_name args } {
	return [invokeTypeProc [getNodeType $node_id] $proc_name {*}$args]
}
