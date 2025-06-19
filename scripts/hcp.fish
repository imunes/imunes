function __fish_hcp_nodes
    himage -ln | sed -r 's/.*\((.*)\)/\1/' | tr ' ' '\n'
end

function __fish_hcp_hosts
	for i in (__fish_hcp_nodes)
		printf '%s:\n' $i
	end
end

complete -c hcp --arguments '(__fish_hcp_hosts)'

# This does not complete node filesystems correctly, only nodes.
# We should do something like scp or rsync and use nodes filesystem for completion.
