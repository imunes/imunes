function __fish_himage_nodes
	for i in (docker ps | grep imunes | cut -f 1 -d' ')
		docker inspect $i -f {{.Config.Hostname}}
	end
end

set -l flags_exclusive   b nt v n e i l ln d
set -l flags_no_cmd           v n e i l ln d
set -l flags_no_host                  l ln d

function __fish_intersperse
	for i in $argv[2..]
		printf '%s %s ' $argv[1] $i
	end
end

set -l base complete -c himage
set -l e $base -n "not __fish_seen_argument "(__fish_intersperse --old $flags_exclusive)
set -l h $base -n "not __fish_seen_argument "(__fish_intersperse --old $flags_no_host)
set -l c $base -n "not __fish_seen_argument "(__fish_intersperse --old $flags_no_cmd)

$base -f

# Autocomplete old style flags -- only one flag is allowed.
$e --old b  -d 'run in detached mode (background)'
$e --old nt -d 'run without pseudo-tty (no-tty)'
$e --old v  -d 'docker full name (eid.nodename)'
$e --old n  -d 'docker node name (nodename)'
$e --old e  -d 'experiment eid name (eid)'
$e --old i  -d 'docker container id'
$e --old l  -d 'running experiments eids with experiment data'
$e --old ln -d 'running experiments eids with node names'
$e --old d  -d 'dummy flag (used only on FreeBSD)'

# Autocomplete nodes -- only 1 node per command and only autocompleted if there are no flags which do not require them.
$h -n 'not test (__fish_number_of_cmd_args_wo_opts) -ge 2' --arguments '(__fish_himage_nodes)'

# Autocomplete commands after node -- this assumes that all nodes have the same commands as host.
# It would be nice if we could somehow use fish installed on nodes to aucomplete commands.
$c -n 'test (__fish_number_of_cmd_args_wo_opts) -ge 2' -d "Command to run" -xa '(__fish_complete_subcommand --fcs-skip=2)'
