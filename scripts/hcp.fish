function __fish_hcp_nodes
	for i in (docker ps | grep imunes | cut -f 1 -d' ')
		docker inspect $i -f {{.Config.Hostname}}
	end
end

function __fish_hcp_hosts
	for i in (__fish_hcp_nodes)
		printf '%s:\n' $i
	end
end

complete -c hcp --arguments '(__fish_hcp_hosts)'

# This does not complete node filesystems correctly, only nodes.
# We should do something like scp or rsync and use nodes filesystem for completion.
