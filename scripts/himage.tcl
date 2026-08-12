upvar 0 ::cf::[set ::curcfg]::dict_run dict_run
upvar 0 ::cf::[set ::curcfg]::dict_run_gui dict_run_gui
upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg
upvar 0 ::cf::[set ::curcfg]::execute_vars execute_vars

global LIBDIR
global ROOTDIR
global himage_args remote ttyrcmd isOSlinux isOSfreebsd

set dict_cfg [dict create]
set dict_run [dict create]
set dict_run_gui [dict create]
set execute_vars [dict create]

set do_eid_exec 0
set do_node_exec 0

set docker_exec_flags "-i -t"

global help_msg
set help_msg "This command can be used as an interface to the jail/docker/netns commands for
IMUNES virtual nodes.

Parameter 'node' can be given in any of the following forms:
 node_id
 hostname
 node_id@eid
 hostname@eid

Usage:
  himage node             ---> open shell in 'node'
  himage node command     ---> run 'command' in 'node'
  himage -b node command  ---> run 'command' in detached mode (background)
  himage -d node          ---> 'node' filesystem path
  himage -e node          ---> get experiment ID (eid) for 'node'
  himage -E eid           ---> open shell in experiment master jail/netns
  himage -E eid command   ---> execute 'command' in experiment master jail/netns
  himage -i/-j node       ---> get jail/container/netns ID for 'node'
  himage -l               ---> get running experiments eids with experiment data
  himage -ln              ---> get running experiments eids with node names/IDs
  himage -m node          ---> open shell in experiment master jail/netns (containing 'node')
  himage -m node command  ---> execute 'command' in experiment master jail/netns (containing 'node')
  himage -n node          ---> get 'node' ID (node_id)
  himage -nt node         ---> Linux only - open shell without pseudo-tty (no-tty)
  himage -nt node command ---> Linux only - run 'command' without pseudo-tty (no-tty)
  himage -v node          ---> get 'node' full name (eid.node_id)

For remote access, use:
himage -remote <remote_host> <regular_himage_arguments>"

proc himageShowHelp {} {
	global help_msg

	sputs $help_msg
}

if { [lindex $himage_args 0] in "\"\" -h -help --help" } {
	# show help
	himageShowHelp

	exit 0
}

#
# Internal flag used by completion/helper callers.
#
# When enabled, command arguments are transported to the remote host
# without passing the command itself through another shell quoting layer.
#
set raw_exec 0
if { [lindex $himage_args 0] == "-raw" } {
	set raw_exec 1
	set himage_args [lrange $himage_args 1 end]
}

if { [lindex $himage_args 0] in "-l -ln" } {
	# -l - list experiments with basic information
	# -ln - list experiments with node names/IDs
	set himage_args [lassign $himage_args himage_opt given_eid]

	set running_eids [lsort [getResumableExperiments]]
	if { $given_eid != "" } {
		if { $given_eid ni $running_eids } {
			sputs stderr "ERROR: Experiment with ID '$given_eid' not running! Running experiments:\n[join $running_eids "\n"]"

			exit 1
		}

		set running_eids $given_eid
	}

	# list experiments with node list
	set eids {}
	foreach eid $running_eids {
		if { $himage_opt == "-l" } {
			set name [getExperimentNameFromFile $eid]
			set timestamp [getExperimentTimestampFromFile $eid]
			lappend eids "$eid \[$name - $timestamp\]"
		} elseif { $himage_opt == "-ln" } {
			try {
				resumeSelectedExperiment $eid
			} on error err {
				continue
			}

			set node_list {}
			foreach node_id [getFromRunning "node_list"] {
				if { [isRunningNode $node_id] } {
					set node_running ""
				} else {
					set node_running "*"
				}

				lappend node_list "$node_id|[getNodeName $node_id]$node_running"
			}

			if { $node_list != {} } {
				lappend eids "$eid \[[join $node_list ", "]\]"
			} else {
				lappend eids "$eid \[\]"
			}
		}
	}

	if { $eids != {} } {
		sputs "[join $eids "\n"]"
	}

	exit 0
}

set check_args [lrange $himage_args 0 1]
while { "-b" in $check_args || "-nt" in $check_args } {
	if { "-nt" in $check_args } {
		# Linux only - don't use TTY when executing command
		# (ignored on FreeBSD)
		set himage_args [removeFromList $himage_args "-nt" "keep_doubles"]
		set check_args [lrange $himage_args 0 1]

		set docker_exec_flags [removeFromList $docker_exec_flags "-t"]
	}

	if { "-b" in $check_args } {
		# send command to background
		set himage_args [removeFromList $himage_args "-b" "keep_doubles"]
		set check_args [lrange $himage_args 0 1]

		set docker_exec_flags "-d"
	}
}

if { [lindex $himage_args 0] in "-E" } {
	# run command in experiment jail/netns <eid>
	set himage_args [lassign $himage_args himage_opt]
	set himage_cmd [lassign $himage_args given_eid]

	set running_eids [lsort [getResumableExperiments]]
	if { $given_eid == "" } {
		sputs stderr "ERROR: Experiment ID not given! Running experiments:\n[join $running_eids "\n"]"

		exit 1
	}

	if { $given_eid ni $running_eids } {
		sputs stderr "ERROR: Experiment with ID '$given_eid' not running! Running experiments:\n[join $running_eids "\n"]"

		exit 1
	}

	set do_eid_exec 1
} elseif { [lindex $himage_args 0] in "-d -e -i -j -m -n -v" } {
	# -d - get node path on filesystem
	# -e - get experiment id (eid) for node
	# -i/-j - get node docker/jail ID
	# -m - run command in experiment jail/netns of node <hostname[@eid]>
	# -n - get node ID (node_id)
	# -v - get full node name (eid.node_id)
	set himage_args [lassign $himage_args himage_opt]
	set himage_cmd [lassign $himage_args node_idname]
	if { $node_idname == "" } {
		sputs stderr "ERROR: Node not given."

		exit 1
	}

	try {
		getFullNodeFromIdName $node_idname 0
	} on ok retv {
		lassign $retv eid node_id -
	} on error err {
		# ignore 'multiple nodes in same experiment' error
		if { $himage_opt in "-m -e" && [string match "*Multiple nodes with name*" $err] } {
			set eid [lindex $err end]
		} else {
			sputs stderr "ERROR: $err"

			exit 1
		}
	}

	if { $himage_opt in "-m" } {
		set given_eid $eid
		set do_eid_exec 1
	} else {
		if { $himage_opt == "-e" } {
			set output "$eid"
		} elseif { $himage_opt == "-n" } {
			set output "$node_id"
		} elseif { $himage_opt == "-v" } {
			set output "$eid.$node_id"
		} elseif { $himage_opt in "-i -j -d" } {
			if { $himage_opt in "-i -j" } {
				if { $isOSlinux } {
					set cmds "docker inspect --format '{{.Id}}' $eid.$node_id"
				}

				if { $isOSfreebsd } {
					set cmds "jls -j $eid.$node_id jid"
				}
			} elseif { $himage_opt == "-d" } {
				if { $isOSlinux } {
					try {
						resumeSelectedExperiment $eid
					} on ok {} {
						sputs [getHostNodePath $node_id ""]
					}

					exit 0
				}

				if { $isOSfreebsd } {
					set cmds "jls -j $eid.$node_id path"
				}
			}

			try {
				rexec $cmds
			} on ok output {
			} on error err {
				sputs stderr "ERROR: '[string trim $err]'"

				exit 1
			}
		}

		sputs "$output"

		exit 0
	}
} else {
	# open shell or run command on node
	if { [string range [lindex $himage_args 0] 0 0] == "-" } {
		himageShowHelp

		set wrong_option [lindex $himage_args 0]
		if { $wrong_option == "-remote" } {
			sputs stderr "\nERROR: Use '-remote' as an argument for the 'imunes' command."
		} else {
			sputs stderr "\nERROR: Unknown option $wrong_option"
		}

		exit 1
	}

	set do_node_exec 1
}

# run command in master EID or enter interactive shell if no command given
if { $do_eid_exec } {
	if { [lindex $himage_cmd 0] == "@" } {
		# if first argument is @, we assume the rest of the commands are
		# not shell commands, but TCL/IMUNES commands as a list separated
		# with semicolon, for example:
		# himage -E i1234 @ redeployCfg
		# himage -E i1234 @ getFromRunning "node_list"
		# himage -E i1234 @ trigger_nodeReconfig n0 \; redeployCfg
		# himage -E i1234 @ 'trigger_nodeDestroy n0 ; trigger_nodeCreate n0 ; redeployCfg'
		try {
			resumeSelectedExperiment $given_eid
		} on error err {
			sputs stderr "ERROR: $err"

			exit 1
		}

		set himage_cmd [join [lrange $himage_cmd 1 end] " "]
		foreach cmd_line [split $himage_cmd ";"] {
			sputs "RUNNING: '$cmd_line'"
			try {
				{*}$cmd_line
			} on ok retv {
				sputs "OK: '$retv'"
			} on error err {
				sputs stderr "ERR: '$err'"

				exit 1
			}
		}

		exit 0
	}

	if { $isOSlinux } {
		if { $himage_cmd == "" } {
			set himage_cmd "bash"
		}

		set os_cmd "ip netns exec $given_eid $himage_cmd"
	} elseif { $isOSfreebsd } {
		if { $himage_cmd == "" } {
			set himage_cmd "csh"
		}

		set os_cmd "jexec $given_eid $himage_cmd"
	}

	try {
		if { "-d" in $docker_exec_flags } {
			set bkg "&"
			set idx [lsearch -exact $ttyrcmd "-t"]
			set remote_cmd [lreplace $ttyrcmd $idx $idx {*}[list -T -n]]
		} else {
			set bkg ""
			set remote_cmd $ttyrcmd
		}

		if { $remote != "" } {
			exec <@stdin >@stdout 2>@stderr {*}$remote_cmd "$os_cmd" {*}$bkg
		} else {
			exec <@stdin >@stdout 2>@stderr {*}$os_cmd {*}$bkg
		}

		exit 0
	} trap POSIX {msg opts} {
		sputs stderr "ERROR: himage to eid '$eid' failed: '$msg'"

		exit [lindex [dictGet $opts -errorcode] 2]
	} trap CHILDSTATUS {msg opts} {
		exit [lindex [dictGet $opts -errorcode] 2]
	} on error err {
		sputs stderr "ERROR: exec command to eid '$eid' failed: '$err'"

		exit 1
	}
}

# run command in node [hostname] or enter interactive shell if no command given
if { $do_node_exec } {
	set himage_cmd [lassign $himage_args node_idname]
	if { $node_idname == "" } {
		sputs stderr "ERROR: Node not given."

		exit 1
	}

	try {
		getFullNodeFromIdName $node_idname 1 $docker_exec_flags
	} on ok retv {
		lassign $retv eid node_id os_cmd
	} on error err {
		sputs stderr "ERROR: $err"

		exit 1
	}

	if { $os_cmd == "" } {
		puts stderr "ERROR: Cannot attach to '$node_idname' ($node_id@$eid)."

		exit 1
	}

	if { $himage_cmd == "" } {
		try {
			resumeSelectedExperiment $eid
		} on error err {
			sputs stderr "ERROR: $err"

			exit 1
		}

		set himage_cmd [existingShells [invokeNodeProc $node_id "shellcmds"] $node_id "first_only"]
	}

	try {
		if { "-d" in $docker_exec_flags } {
			set bkg "&"
			set idx [lsearch -exact $ttyrcmd "-t"]
			set remote_cmd [lreplace $ttyrcmd $idx $idx {*}[list -T -n]]
		} else {
			set bkg ""
			set remote_cmd $ttyrcmd
		}

		if { $remote == "" } {
			exec {*}$os_cmd {*}$himage_cmd <@stdin >@stdout 2>@stderr {*}$bkg
		} else {
			if { $raw_exec } {
				# encode every argument separately

				# the remote shell only has to decode opaque base64 strings:
				# it never has to parse the original command arguments
				set encoded_args {}

				foreach arg $himage_cmd {
					set encoded [binary encode base64 -maxlen 0 $arg]
					lappend encoded_args $encoded
				}

				# build a small POSIX shell program which reconstructs argv
				set remote_script {
					set --
					for encoded_arg do
						arg=$(printf '%s' "$encoded_arg" | base64 -d)
						set -- "$@" "$arg"
					done
					exec "$@"
				}

				# quote the decoder script itself once
				set quoted_script "'[string map {' '\''} $remote_script]'"

				# Quote base64 arguments. Base64 contains no shell
				# metacharacters that matter here, but keeping them quoted is
				# clearer and future-proof.
				set quoted_args {}
				foreach arg $encoded_args {
					lappend quoted_args "'$arg'"
				}

				set decoder_cmd "sh -c $quoted_script sh [join $quoted_args " "]"

				# the decoder reconstructs the exact original argv inside the node
				set full_cmd "$os_cmd $decoder_cmd"
			} else {
				# existing behaviour for normal himage calls
				set qcmds {}

				foreach arg $himage_cmd {
					# replace every ' with '\'' and wrap whole word in ''
					lappend qcmds "'[string map {' '\''} $arg]'"
				}

				set qcmds [join $qcmds " "]

				set full_cmd "$os_cmd $qcmds"
			}
			
			exec {*}$remote_cmd $full_cmd <@stdin >@stdout 2>@stderr {*}$bkg
		}

		exit 0
	} trap POSIX {msg opts} {
		sputs stderr "ERROR: himage to node '$node_idname' failed: '$msg'"

		exit [lindex [dictGet $opts -errorcode] 2]
	} trap CHILDSTATUS {msg opts} {
		exit [lindex [dictGet $opts -errorcode] 2]
	} on error err {
		sputs stderr "ERROR: exec command to node '$node_idname' failed: '$err'"

		exit 1
	}
}

exit 0
