_imunes()
{
	local cur prev
	cur=${COMP_WORDS[COMP_CWORD]}
	prev=${COMP_WORDS[COMP_CWORD-1]}

	#
	# Every known imunes option.
	#
	local -a allopts
	allopts=(
		-a -attach
		-b -batch
		-c -cli
		-convert
		-d
		-dd
		-e -eid
		-f -force
		-h -help
		-hcp
		-himage
		-i
		-j
		-l -legacy
		-p -prepare
		-r -remote
		-v -version
		-vlink
	)

	#
	# Return success if an option or one of its aliases is already
	# present on the command line.
	#
	_imunes_option_used()
	{
		local opt=$1
		local word alias
		local -a aliases

		case "$opt" in
			-a|-attach)
				aliases=( -a -attach )
				;;
			-b|-batch)
				aliases=( -b -batch )
				;;
			-c|-cli)
				aliases=( -c -cli )
				;;
			-e|-eid)
				aliases=( -e -eid )
				;;
			-f|-force)
				aliases=( -f -force )
				;;
			-h|-help)
				aliases=( -h -help )
				;;
			-l|-legacy)
				aliases=( -l -legacy )
				;;
			-p|-prepare)
				aliases=( -p -prepare )
				;;
			-r|-remote)
				aliases=( -r -remote )
				;;
			-v|-version)
				aliases=( -v -version )
				;;
			*)
				aliases=( "$opt" )
				;;
		esac

		for word in "${COMP_WORDS[@]:1:COMP_CWORD-1}"; do
			for alias in "${aliases[@]}"; do
				[[ $word == "$alias" ]] &&
					return 0
			done
		done

		return 1
	}

	#
	# Return success if VALUE exists in the supplied list.
	#
	_imunes_array_contains()
	{
		local value=$1
		shift

		local item

		for item in "$@"; do
			[[ $item == "$value" ]] &&
				return 0
		done

		return 1
	}

	#
	# Intersect the current allowed option list with another list.
	#
	_imunes_intersect_allowed()
	{
		local -a constraint=( "$@" )
		local -a result=()
		local opt

		for opt in "${allowed[@]}"; do
			if _imunes_array_contains "$opt" "${constraint[@]}"; then
				result+=( "$opt" )
			fi
		done

		allowed=( "${result[@]}" )
	}

	#
	# Remove already used options and their aliases.
	#
	_imunes_remove_used()
	{
		local -a result=()
		local opt

		for opt in "${allowed[@]}"; do
			if ! _imunes_option_used "$opt"; then
				result+=( "$opt" )
			fi
		done

		allowed=( "${result[@]}" )
	}

	#
	# Complete the current allowed option list.
	#
	_imunes_complete_allowed()
	{
		_imunes_remove_used

		COMPREPLY=(
			$(compgen -W "${allowed[*]}" -- "$cur")
		)
	}

	#
	# Complete .imn files and directories.
	#
	_imunes_files()
	{
		local f

		COMPREPLY=()

		while IFS= read -r f; do
			if [[ -d $f || $f == *.imn ]]; then
				COMPREPLY+=( "$f" )
			fi
		done < <(compgen -f -- "$cur")

		compopt -o filenames 2>/dev/null

		for f in "${COMPREPLY[@]}"; do
			if [[ -d $f ]]; then
				compopt -o nospace 2>/dev/null
				break
			fi
		done
	}

	#
	# Complete remote hosts.
	#
	_imunes_hosts()
	{
		if declare -F _known_hosts_real >/dev/null; then
			_known_hosts_real "$cur"
		else
			COMPREPLY=(
				$(compgen -A hostname -- "$cur")
			)
		fi
	}

	#
	# Complete experiment IDs.
	#
	_imunes_eids()
	{
		local remote=$1
		local list
		local -a cmd

		cmd=(himage)

		if [[ -n $remote ]]; then
			cmd+=( -remote "$remote" )
		fi

		list=$(
			"${cmd[@]}" -ln 2>/dev/null
		)

		if [[ -n $remote ]]; then
			list=$(
				printf '%s\n' "$list" |
					sed "/^Using remote host '/d"
			)
		fi

		COMPREPLY=(
			$(compgen -W "$(
				printf '%s\n' "$list" |
					awk '{print $1}' |
					sort -u
			)" -- "$cur")
		)
	}

	#
	# Return success if the final .imn positional argument has
	# already been supplied.
	#
	_imunes_have_final_arg()
	{
		local i
		local word

		for ((i = 1; i < COMP_CWORD; i++)); do
			word=${COMP_WORDS[i]}

			case "$word" in
				#
				# Options consuming one argument.
				#
				-dd|-e|-eid|-j|-r|-remote)
					((i++))
					;;

				#
				# Passthrough options consume everything following
				# their "--", so they cannot contain an .imn final
				# argument belonging to the main imunes command.
				#
				-himage|-hcp|-vlink)
					return 1
					;;

				#
				# Options.
				#
				-*)
					;;

				#
				# Any remaining word is the final .imn argument.
				#
				*)
					return 0
					;;
			esac
		done

		return 1
	}

	#
	# Delegate completion to himage/hcp/vlink.
	#
	# Main command:
	#
	#   imunes -himage -- ...
	#   imunes -hcp    -- ...
	#   imunes -vlink  -- ...
	#
	# Delegated command sees:
	#
	#   himage ...
	#   hcp    ...
	#   vlink  ...
	#
	_imunes_delegate()
	{
		local command=$1
		local function=$2
		local index=$3
		local delegated_remote=$4

		declare -F "$function" >/dev/null ||
			return 0

		local -a saved_words=( "${COMP_WORDS[@]}" )
		local saved_cword=$COMP_CWORD
		local saved_line=$COMP_LINE
		local saved_point=$COMP_POINT

		local -a delegated
		local start
		local effective_remote=""

		delegated=( "$command" )

		#
		# Remote mode can come either from:
		#
		#   imunes -remote host -hcp -- ...
		#
		# or:
		#
		#   imunes -hcp -remote host -- ...
		#
		if [[ -n $delegated_remote ]]; then
			effective_remote=$delegated_remote
		elif [[ -n $remote ]]; then
			effective_remote=$remote
		fi

		if [[ -n $effective_remote ]]; then
			delegated+=( -remote "$effective_remote" )
		fi

		#
		# First word after -himage/-hcp/-vlink.
		#
		start=$((index + 1))

		#
		# Skip optional:
		#
		#   -remote host
		#
		if [[ ${saved_words[start]} == "-remote" ]]; then
			start=$((start + 2))
		fi

		#
		# Skip:
		#
		#   --
		#
		if [[ ${saved_words[start]} == "--" ]]; then
			((start++))
		fi

		#
		# Append the delegated COMP_WORDS.
		#
		delegated+=( "${saved_words[@]:start}" )

		COMP_WORDS=( "${delegated[@]}" )

		if [[ -n $effective_remote ]]; then
			COMP_CWORD=$((saved_cword - start + 3))
		else
			COMP_CWORD=$((saved_cword - start + 1))
		fi

		#
		# Rebuild COMP_LINE.
		#
		# This is important for _hcp because it uses
		# _get_comp_words_by_ref -n : and therefore needs to see the raw
		# node:path text, not COMP_WORDS after Bash has split it at ':'.
		#
		local before_cursor
		local raw_cur
		local delegated_tail

		before_cursor=${saved_line:0:saved_point}

		#
		# Extract everything after the passthrough "--".
		#
		# Examples:
		#
		#   imunes -hcp -- pc2:/
		#                   ^^^^^
		#
		#   imunes -hcp -- pc2:/etc/ho
		#                   ^^^^^^^^^^^
		#
		if [[ $before_cursor == *" -- "* ]]; then
			delegated_tail=${before_cursor##*" -- "}
		else
			delegated_tail=""
		fi

		if [[ -n $effective_remote ]]; then
			COMP_LINE="$command -remote $effective_remote"
		else
			COMP_LINE="$command"
		fi

		if [[ -n $delegated_tail ]]; then
			COMP_LINE+=" $delegated_tail"
		else
			#
			# Preserve the empty current word after "--".
			#
			COMP_LINE+=" "
		fi

		COMP_POINT=${#COMP_LINE}

			"$function"

			#
			# -remote belongs to the wrappers and must not be offered inside
			# imunes passthrough completion.
			#
			local -a filtered=()
			local reply

			for reply in "${COMPREPLY[@]}"; do
				[[ $reply == "-remote" ]] ||
					filtered+=( "$reply" )
				done

				COMPREPLY=( "${filtered[@]}" )

				#
				# Restore the original completion context.
				#
				COMP_WORDS=( "${saved_words[@]}" )
				COMP_CWORD=$saved_cword
				COMP_LINE=$saved_line
				COMP_POINT=$saved_point

				return 0
	}

	#
	# Determine which important options are already present.
	#
	local have_attach=0
	local have_batch=0
	local have_convert=0
	local have_eid=0
	local have_legacy=0
	local have_prepare=0
	local have_remote=0
	local have_devfs=0
	local have_force=0

	local remote=""
	local i

	for ((i = 1; i < COMP_CWORD; i++)); do
		case "${COMP_WORDS[i]}" in
			-a|-attach)
				have_attach=1
				;;

			-b|-batch)
				have_batch=1
				;;

			-convert)
				have_convert=1
				;;

			-e|-eid)
				have_eid=1
				;;

			-l|-legacy)
				have_legacy=1
				;;

			-p|-prepare)
				have_prepare=1
				;;

			-i)
				have_devfs=1
				;;

			-f|-force)
				have_force=1
				;;

			-r|-remote)
				have_remote=1

				if ((i + 1 < COMP_CWORD)); then
					remote=${COMP_WORDS[i+1]}
					((i++))
				fi
				;;
		esac
	done

	#
	# Passthrough command modes.
	#
	for ((i = 1; i < COMP_CWORD; i++)); do
		case "${COMP_WORDS[i]}" in
			-himage|-hcp|-vlink)
				local passthrough=${COMP_WORDS[i]}
				local command
				local function
				local delegated_remote=""

				case "$passthrough" in
					-himage)
						command=himage
						function=_himage
						;;
					-hcp)
						command=hcp
						function=_hcp
						;;
					-vlink)
						command=vlink
						function=_vlink
						;;
				esac

				#
				# Immediately after the passthrough option:
				#
				#   imunes -himage <TAB>
				#
				# offer:
				#
				#   --
				#   -remote
				#
				if (( COMP_CWORD == i + 1 )); then
					if (( have_remote )); then
						COMPREPLY=(
							$(compgen -W "--" -- "$cur")
						)
					else
						COMPREPLY=(
							$(compgen -W "-- -remote" -- "$cur")
						)
					fi

					return 0
				fi

				#
				# Optional remote host:
				#
				#   imunes -himage -remote <TAB>
				#
				if [[ ${COMP_WORDS[i+1]} == "-remote" ]]; then
					#
					# Complete the remote host.
					#
					if (( COMP_CWORD == i + 2 )); then
						if declare -F _known_hosts_real >/dev/null; then
							_known_hosts_real "$cur"
						else
							COMPREPLY=(
								$(compgen -A hostname -- "$cur")
							)
						fi

						return 0
					fi

					delegated_remote=${COMP_WORDS[i+2]}

					#
					# After the host, require "--":
					#
					#   imunes -himage -remote host <TAB>
					#       -> --
					#
					if (( COMP_CWORD == i + 3 )); then
						COMPREPLY=(
							$(compgen -W "--" -- "$cur")
						)
						return 0
					fi

					#
					# Delegate only after "--".
					#
					if [[ ${COMP_WORDS[i+3]} == "--" ]]; then
						_imunes_delegate \
							"$command" \
							"$function" \
							"$i" \
							"$delegated_remote"

						return 0
					fi

					return 0
				fi

				#
				# Normal passthrough:
				#
				#   imunes -himage -- ...
				#
				if [[ ${COMP_WORDS[i+1]} == "--" ]]; then
					_imunes_delegate \
						"$command" \
						"$function" \
						"$i" \
						""

					return 0
				fi

				return 0
				;;
		esac
	done

	#
	# Terminal options.
	#
	for ((i = 1; i < COMP_CWORD; i++)); do
		case "${COMP_WORDS[i]}" in
			-h|-help|-v|-version)
				return 0
				;;
		esac
	done

	#
	# Some options consume an immediate argument.
	#
	case "$prev" in
		-r|-remote)
			_imunes_hosts
			return 0
			;;

		-j)
			COMPREPLY=(
				$(compgen -W "0 h" -- "$cur")
			)

			return 0
			;;

		-dd)
			#
			# -dd consumes one arbitrary argument.
			#
			return 0
			;;
	esac

	#
	# Start with every option, then successively constrain the list.
	#
	local -a allowed
	allowed=( "${allopts[@]}" )

	#
	# -attach
	#
	if ((have_attach)); then
		_imunes_intersect_allowed \
			-d \
			-dd \
			-l -legacy \
			-e -eid \
			-j \
			-r -remote \
			-c
	fi

	#
	# -convert
	#
	if ((have_convert)); then
		_imunes_intersect_allowed \
			-d \
			-dd
	fi

	#
	# -eid
	#
	if ((have_eid)); then
		_imunes_intersect_allowed \
			-a -attach \
			-b -batch \
			-c -cli \
			-d \
			-dd \
			-j \
			-l -legacy \
			-r -remote
	fi

	#
	# -batch
	#
	if ((have_batch)); then
		_imunes_intersect_allowed \
			-d \
			-dd \
			-e -eid \
			-j \
			-l -legacy \
			-r -remote
	fi

	#
	# -legacy
	#
	if ((have_legacy)); then
		_imunes_intersect_allowed \
			-a -attach \
			-b -batch \
			-d \
			-dd \
			-e -eid \
			-j \
			-r -remote
	fi

	#
	# -prepare
	#
	if ((have_prepare)); then
		_imunes_intersect_allowed \
			-f -force \
			-r -remote
	fi

	#
	# -i
	#
	if ((have_devfs)); then
		_imunes_intersect_allowed \
			-r -remote
	fi

	#
	# -force
	#
	if ((have_force)); then
		_imunes_intersect_allowed \
			-p -prepare \
			-r -remote
	fi

	#
	# Remote mode cannot be selected again and does not support
	# -convert.
	#
	if ((have_remote)); then
		local -a remote_allowed=()
		local opt

		for opt in "${allopts[@]}"; do
			case "$opt" in
				-r|-remote|-convert)
					;;
				*)
					remote_allowed+=( "$opt" )
					;;
			esac
		done

		_imunes_intersect_allowed "${remote_allowed[@]}"
	fi

	#
	# -e|-eid has a special immediate argument.
	#
	if [[ $prev == "-e" || $prev == "-eid" ]]; then
		if [[ $cur == -* ]]; then
			_imunes_complete_allowed
		else
			_imunes_eids "$remote"
		fi

		return 0
	fi

	#
	# The .imn file is always the final argument.
	#
	if _imunes_have_final_arg; then
		return 0
	fi

	#
	# If the current word starts with "-", perform constrained
	# option completion.
	#
	if [[ $cur == -* ]]; then
		_imunes_complete_allowed
		return 0
	fi

	#
	# -attach is option-only.
	#
	if ((have_attach)); then
		_imunes_complete_allowed
		return 0
	fi

	#
	# -prepare is option-only.
	#
	if ((have_prepare)); then
		_imunes_complete_allowed
		return 0
	fi

	#
	# -i is option-only.
	#
	if ((have_devfs)); then
		_imunes_complete_allowed
		return 0
	fi

	#
	# -force is option-only.
	#
	if ((have_force)); then
		_imunes_complete_allowed
		return 0
	fi

	#
	# Otherwise complete the final .imn argument.
	#
	_imunes_files
}

complete -F _imunes imunes
