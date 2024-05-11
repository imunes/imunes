#!/bin/sh

run_dir='/run/frr'
mkdir -p $run_dir
chown -R frr:frr $run_dir

conf_dir='/usr/local/etc/frr'
chown -R frr:frr $conf_dir
chown frr:frrvty $conf_dir/vtysh.conf
for f in rip ripng ospf ospf6; do
	grep -q "router $f\$" $1 && sed -i '' "s/${f}d=no/${f}d=yes/" $conf_dir/daemons
done

for f in ldp bfd; do
        grep -q "mpls .*\$" $1 && sed -i '' "s/${f}d=no/${f}d=yes/" $conf_dir/daemons
done

for f in bgp isis; do
	grep -q "router $f .*\$" $1 && sed -i '' "s/${f}d=no/${f}d=yes/" $conf_dir/daemons
done

service frr restart

sed -i '' '/Disabling MPLS support/d' /terr.log

vtysh << __END__
conf term
`cat $1`
__END__
