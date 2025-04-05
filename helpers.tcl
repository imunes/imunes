proc getPrettyUsage { options } {
    global config_path

    set usage "Usage:
    imunes \[OPTION...\] \[.imn FILE\]

Options:
"
    foreach opt $options {
	set vals [split [lindex $opt 0] "."]
	set description [lindex $opt end]
	set arg [lindex $vals 0]
	if { [lindex $vals 1] != "secret" } {
	    append usage "    "
	}
	if { [lindex $vals 1] == "arg" } {
	    append usage "-$arg value\t$description\n"
	}
	if { [lindex $vals 1] == "" } {
	    if { [string length $arg] < 4 } {
		append usage "-$arg\t\t$description\n"
	    } else {
		append usage "-$arg\t$description\n"
	    }
	}
    }
    append usage "    -help\tPrint this message\n"
    append usage "\nExamples:
    imunes \[-e | -eid eid\] \[topology.imn\] - start IMUNES GUI
    imunes -b \[-e | -eid eid\] \[topology.imn\] - start experiment (batch)
    imunes -b -e | -eid eid - terminate experiment (batch)"

    append usage "\n\nCheck /etc/imunes/config.examples for configuration options."

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
    global initMode execMode eid_base debug argv
    global printVersion prepareFlag forceFlag

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

    if { $params(b) || $params(batch) } {
	if { $params(e) == "" && $params(eid) == "" && $fileName == "" } {
	    puts stderr $usage
	    exit 1
	}
	catch { exec id -u } uid
	if { $uid != "0" } {
	    puts stderr "Error: To execute experiment, run IMUNES with root permissions."
	    exit 1
	}
	set execMode batch
    } else {
	if { $params(d) } {
	    set debug 1
	}
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
    global isOSfreebsd isOSlinux isOSwin

    set os [platform::identify]
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
