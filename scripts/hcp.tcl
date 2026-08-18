upvar 0 ::cf::[set ::curcfg]::dict_run dict_run
upvar 0 ::cf::[set ::curcfg]::dict_run_gui dict_run_gui
upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg
upvar 0 ::cf::[set ::curcfg]::execute_vars execute_vars

global LIBDIR
global ROOTDIR
global hcp_args remote

set dict_cfg [dict create]
set dict_run [dict create]
set dict_run_gui [dict create]
set execute_vars [dict create]

global help_msg
set help_msg "This command can be used to copy files to/from virtual images.
Use a node ID or hostname to identify a virtual image.

Parameters 'node1/node2' can be given in any of the following forms:
  node_id
  hostname
  node_id@eid
  hostname@eid

Usage:
  hcp \[cp_options\] local_src       node:\[node_dst\]   ---> copy local files/directories to 'node'
  hcp \[cp_options\] node:node_src   \[local_dst\]       ---> copy files/directories from 'node' to the local host
  hcp \[cp_options\] node1:node1_src node2:\[node2_dst\] ---> copy files/directories from 'node1' to 'node2'

For remote access, use:
  hcp -remote <remote_host> <regular_hcp_arguments>

NOTE: With -remote, node specifications refer to nodes on <remote_host>.
By default, paths without a node specification refer to files on <this>
machine. For example:
  hcp -remote some_host some_file pc1:

copies 'some_file' from <this> machine to node 'pc1' on 'some_host'.

To refer instead to a file on <remote_host> itself, append '@' to
the path. For example:
  hcp -remote some_host /home/remote_user/some_file@ pc1:

copies '/home/remote_user/some_file' from 'some_host' to node 'pc1' on
'some_host'.

If a filename itself ends in any number of '@' characters, use double trailing
'@' characters to escape them.

Examples:
  test@      -> remote file 'test'
  test@@     -> local file 'test@'
  test@@@    -> remote file 'test@'
  test@@@@   -> local file 'test@@'"

proc hcpShowHelp {} {
	global help_msg

	sputs $help_msg
}

if { [lindex $hcp_args 0] in "\"\" -h -help --help" } {
	# show help
	hcpShowHelp

	exit 0
}

if { [lindex $hcp_args 0] == "-remote" } {
	hcpShowHelp

	sputs stderr "\nERROR: Use '-remote' as an argument for the 'imunes' command."

	exit 1
}

set hcp_dst [lindex $hcp_args end]

set hcp_args [lrange $hcp_args 0 end-1]
if { $hcp_args == {} } {
	hcpShowHelp

	sputs stderr "\nERROR: Too few arguments given."

	exit 1
}

set cp_args {}
foreach hcp_arg $hcp_args {
	if { [string index $hcp_arg 0] == "-" && $hcp_arg ni $cp_args } {
		lappend cp_args $hcp_arg
		set hcp_args [removeFromList $hcp_args $hcp_arg]
	}
}

if { $hcp_args == {} } {
	hcpShowHelp

	sputs stderr "\nERROR: Too few arguments given."

	exit 1
}

set dst_node_id ""
if { [string first ":" $hcp_dst] == -1 } {
	set dst_path $hcp_dst
} else {
	lassign [split $hcp_dst ":"] node_idname node_path

	if { $node_path == "" } {
		set node_path "/"
	}

	try {
		getFullNodeFromIdName $node_idname 0
	} on ok retv {
		lassign $retv eid dst_node_id -
	} on error err {
		sputs stderr "ERROR: $err"

		exit 1
	}

	try {
		resumeSelectedExperiment $eid
	} on error err {
		sputs stderr "ERROR: $err"

		exit 1
	}

	set node_dir [getHostNodePath $dst_node_id ""]
	if { $node_dir == "" } {
		sputs stderr "ERROR: node '[getNodeName $dst_node_id]' ($dst_node_id) has no filesystem."

		exit 1
	}

	set dst_path "[getHostNodePath $dst_node_id ""]$node_path"
}

set needs_scp 0
foreach hcp_src $hcp_args {
	# replace spaces with '\ '
	regsub -all " " $hcp_src "\\ " hcp_src

	if { [string first ":" $hcp_src] == -1 } {
		if { $remote != "" } {
			if { [regexp {(@+)$} $hcp_src -> match] } {
				set at_count [string length $match]
				if { $at_count % 2 == 0 } {
					# if even number of @, we use a local file
					set needs_scp 1
				}

				# replace last "@"s with half of them
				set hcp_src "[string range $hcp_src 0 end-$at_count][string repeat "@" [expr { $at_count / 2 }]]"
			} else {
				# if no @, we use a local file
				set needs_scp 1
			}
		}

		set src_path $hcp_src
	} else {
		lassign [split $hcp_src ":"] node_idname node_path

		if { $node_path == "" || $node_path == "/" } {
			sputs stderr "WARNING: skipping '$hcp_src', not a valid path"

			continue
		}

		try {
			getFullNodeFromIdName $node_idname 0
		} on ok retv {
			lassign $retv eid node_id -
		} on error err {
			sputs stderr "ERROR: $err"

			continue
		}

		try {
			resumeSelectedExperiment $eid
		} on error err {
			sputs stderr "ERROR: $err"

			continue
		}

		set node_dir [getHostNodePath $node_id ""]
		if { $node_dir == "" } {
			sputs stderr "ERROR: node '[getNodeName $node_id]' ($node_id) has no filesystem."

			continue
		}

		set src_path "$node_dir$node_path"
	}

	if { $needs_scp && $dst_node_id == "" } {
		sputs "WARNING: Skipping remote copying to local file."

		continue
	}

	sputs -nonewline "Copying '$hcp_src' to '$hcp_dst'... "
	flush stdout
	try {
		if { $needs_scp } {
			exec scp {*}$cp_args "$src_path" "$remote:/tmp/"
			set src_path "/tmp/[file tail $src_path]"
		}

		rexec cp {*}$cp_args "$src_path" "$dst_path"
	} on ok {} {
		sputs "done!"
	} on error err {
		sputs ""
		regsub -all "$src_path" $err "$hcp_src" err
		regsub -all "$dst_path" $err "$hcp_dst" err
		sputs stderr "ERROR: $err"

		continue
	}
}
