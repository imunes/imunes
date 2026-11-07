_hcp()
{
	local cur prev
	local -a words
	local cword

	#
	# Keep node:path together for completion logic without changing
	# COMP_WORDBREAKS globally or locally.
	#
	if declare -F _get_comp_words_by_ref >/dev/null; then
		_get_comp_words_by_ref -n : cur prev words cword
	else
		words=("${COMP_WORDS[@]}")
		cword=$COMP_CWORD
		cur=${COMP_WORDS[COMP_CWORD]}
		prev=${COMP_WORDS[COMP_CWORD-1]}
	fi

	local remote=""
	local arg_base=1

	#
	# hcp -remote <remote_host> <regular_hcp_arguments>
	#
	if [[ ${words[1]} == "-remote" ]]; then
		remote=${words[2]}
		arg_base=3

		#
		# Complete remote host names.
		#
		if (( cword == 2 )); then
			if declare -F _known_hosts_real >/dev/null; then
				_known_hosts_real "$cur"
			else
				COMPREPLY=(
					$(compgen -A hostname -- "$cur")
				)
			fi

			return 0
		fi
	fi

	#
	# hcp itself only has one completable option:
	#
	#   -remote host
	#
	if [[ $cur == -* ]]; then
		if (( cword == 1 )) && [[ -z $remote ]]; then
			COMPREPLY=(
				$(compgen -W "-remote" -- "$cur")
			)
		fi

		return 0
	fi

	#
	# Build base himage command used to query nodes and node filesystems.
	#
	local -a himage_cmd
	himage_cmd=(himage)

	if [[ -n $remote ]]; then
		himage_cmd+=( -remote "$remote" )
	fi

	#
	# Query himage only once.
	#
	local himage_list
	himage_list=$(
		"${himage_cmd[@]}" -ln 2>/dev/null
	)

	#
	# Remote mode prints an informational banner before the actual list.
	#
	if [[ -n $remote ]]; then
		himage_list=$(
			printf '%s\n' "$himage_list" |
				sed "/^Using remote host '/d"
		)
	fi

	#
	# Get available nodes.
	#
	# himage -ln format:
	#
	#   eid [n0|pc1, n1|ext1, n2|switch1, n3|pc2*]
	#
	# Use the hostname on the right-hand side of '|'.
	#
	# A trailing '*' means the node is down, so ignore it.
	#
	# If a hostname occurs in multiple experiments:
	#
	#   pc1@eid1 pc1@eid2
	#
	local nodes
	nodes=$(
		printf '%s\n' "$himage_list" | awk '
		{
			eid = $1

			$1 = ""
			line = $0

			sub(/^[[:space:]]*\[/, "", line)
			sub(/\][[:space:]]*$/, "", line)

			n = split(line, entries, /,[[:space:]]*/)

			for (i = 1; i <= n; i++) {
				entry = entries[i]

				if (entry ~ /\*$/)
					continue

				split(entry, parts, /\|/)
				hostname = parts[2]

				if (hostname != "") {
					hosts[hostname] = hosts[hostname] " " eid
					++nexp[hostname]
				}
			}
		}

		END {
			for (host in hosts) {
				if (nexp[host] > 1) {
					split(hosts[host], eids, " ")

					for (i in eids)
						if (eids[i] != "")
							printf "%s@%s ", host, eids[i]
				} else {
					printf "%s ", host
				}
			}
		}'
	)

	#
	# Complete a path inside a node.
	#
	# Examples:
	#
	#   pc1:
	#   pc1:/etc/ho
	#   pc1@eid:/tmp/fi
	#
	if [[ $cur == *:* ]]; then
		local node
		local path
		local dir
		local base
		local query_dir

		node=${cur%%:*}
		path=${cur#*:}

		#
		# Split the node path into directory and basename.
		#
		if [[ $path == */* ]]; then
			dir=${path%/*}/
			base=${path##*/}
		else
			dir=""
			base=$path
		fi

		#
		# Empty node path means the node root.
		#
		if [[ -z $path ]]; then
			query_dir=/
			dir="/"
			base=""
		elif [[ -n $dir ]]; then
			query_dir=$dir
		else
			query_dir=.
		fi

		#
		# List the requested directory.
		#
		# -1: one entry per line
		# -A: include dot files except . and ..
		# -p: append '/' to directories
		#
		local entries
		entries=$(
			"${himage_cmd[@]}" -nt "$node" \
				ls -1Ap -- "$query_dir" 2>/dev/null |
				tr -d '\r'
		)

		if [[ -n $remote ]]; then
			entries=$(
				printf '%s\n' "$entries" |
					sed "/^Using remote host '/d"
			)
		fi

		local entry
		local -a replies

		replies=()

		while IFS= read -r entry; do
			[[ -n $entry ]] || continue
			[[ $entry == "$base"* ]] || continue

			#
			# Build the full logical completion first.
			#
			replies+=(
				"${node}:${dir}${entry}"
			)
		done <<< "$entries"

		COMPREPLY=( "${replies[@]}" )

		#
		# Strip node: because Readline is completing only the word
		# fragment after ':'.
		#
		__ltrim_colon_completions "$cur"

		#
		# Do not append a space after directories.
		#
		for entry in "${COMPREPLY[@]}"; do
			if [[ $entry == */ ]]; then
				compopt -o nospace 2>/dev/null
				break
			fi
		done

		return 0
	fi

	#
	# Build node candidates with ':' appended.
	#
	local node
	local -a node_candidates

	node_candidates=()

	for node in $nodes; do
		node_candidates+=( "${node}:" )
	done

	#
	# Normal operands can be either:
	#
	#   local_path
	#   node:path
	#
	local -a local_files
	local file

	local_files=()

	while IFS= read -r file; do
		[[ -n $file ]] || continue

		if [[ -d ${file/#\~/$HOME} ]]; then
			local_files+=( "${file%/}/" )
		else
			local_files+=( "$file" )
		fi
	done < <(compgen -f -- "$cur")

	COMPREPLY=( "${local_files[@]}" )

	#
	# Add matching node names.
	#
	local candidate

	for candidate in "${node_candidates[@]}"; do
		if [[ $candidate == "$cur"* ]]; then
			COMPREPLY+=( "$candidate" )
		fi
	done

	#
	# If completion resolves to a single node, do not append a space
	# because the pathname follows the ':'.
	#
	for candidate in "${COMPREPLY[@]}"; do
		if [[ $candidate == */ || $candidate == *: ]]; then
			compopt -o nospace 2>/dev/null
			break
		fi
	done

	return 0
}

complete -F _hcp hcp
