#!/bin/sh

zebra -dP0

for f in rip ripng ospf ospf6; do
    grep -q "router $f\$" $1 && ${f}d -dP0 
done

for f in bgp isis; do
grep -q "router $f .*\$" $1 && ${f}d -dP0
done

vtysh << __END__
conf term
`cat $1`
__END__

