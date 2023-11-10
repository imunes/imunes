function __fish_vlink_links
	for i in /var/run/imunes/*/links
		cut -f1 -d' ' $i
	end
end

set -l flags_exclusive   l s r bw b BER B dly d dup D e eid - help ?
set -l flags_no_link     l                                  - help ?

function __fish_intersperse
	for i in $argv[2..]
		printf '%s %s ' $argv[1] $i
	end
end

set -l base complete -c vlink
set -l e $base -n "not __fish_seen_argument "(__fish_intersperse --old $flags_exclusive)
set -l h $base -n "not __fish_seen_argument "(__fish_intersperse --old $flags_no_link)
set -l r $e -x

$base -f

# Autocomplete old style flags -- only one flag is allowed.
$e --old l              -d 'print the list of all links'
$e --old s              -d 'print link status'
$e --old r              -d 'set link settings to default values'
$e --old '-'            -d 'Forcibly stop option processing'
$e --old '?' --old help -d 'Print this message'

$r -a '(seq 0  1    100)' --old b --old bw  -d 'set link bandwidth (bps) <>'
$r -a '(seq 0 10   1000)' --old B --old BER -d 'set link BER (1/value) <>'
$r -a '(seq 0 100 10000)' --old d --old dly -d 'set link delay (us) <>'
$r -a '(seq 0 1     100)' --old D --old dup -d 'set link duplicate (%) <>'

$r -a '(for i in /var/run/imunes/*; path basename $i; end)' --old e --old eid -d 'specify experiment ID <>'

# Autocomplete links -- only 1 link per command.
$h -n 'not test (__fish_number_of_cmd_args_wo_opts) -gt 1' --arguments '(__fish_vlink_links)'
