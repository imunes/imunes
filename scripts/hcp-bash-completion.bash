_hcp()
{
	COMP_WORDBREAKS="\"'><=;|&(	  "
	local cur=${COMP_WORDS[COMP_CWORD]}
	local prev=${COMP_WORDS[COMP_CWORD-1]}

	nodes=`himage -ln | tr -d '[],' | \
		awk '    { for(i=2;i<=NF;++i) {eid[$i]=eid[$i]" "$1; ++nexp[$i]}} \
			 END {for (k in eid) {\
					  if (nexp[k] > 1) {\
						  split(eid[k],eids," "); \
						  for (e in eids) printf "%s@%s: ",k,eids[e] \
					  } else { printf "%s: ", k }\
				 }}'`

	if test $COMP_CWORD -eq 1 || test $COMP_CWORD -eq 2; then
		if [[ "$cur" = *:* ]]; then
			node=`echo "$cur" | cut -d':' -f1`
			curpath=`echo "$cur" | cut -d':' -f2`
			files="$(echo compgen -f -- \"$curpath\" | himage ${node} bash -s)"
			newfiles=""
			for f in $files; do
				himage ${node} test -d $f
				if [[ $? -eq 0 ]]; then
					newfiles="$node:$f/ $newfiles"
				else
					newfiles="$node:$f $newfiles"
				fi
			done
			COMPREPLY=( $(compgen -W "$newfiles" -- "$node:$curpath"))
		elif [[ "$cur" != -* ]]; then
			COMPREPLY=( $(compgen -W "$nodes" -- $cur))
			COMPREPLY=(${COMPREPLY[@]:-} $(echo compgen -f -- "$cur" | bash -s))
		fi
		return 0
	fi

	COMPREPLY=(${COMPREPLY[@]:-} $(echo compgen -f -- "$cur" | himage ${host} bash -s))
	return 0
}

complete -o nospace -F _hcp hcp

