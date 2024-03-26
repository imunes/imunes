exec modprobe mac80211_hwsim radios=4
exec ip netns add AP1
exec ip netns add AP2
exec ip netns add STA1
exec ip netns add STA2
exec iw phy phy0 set netns name AP1
exec iw phy phy1 set netns name AP2
exec iw phy phy2 set netns name STA1
exec iw phy phy3 set netns name STA2

exec ip netns exec AP1 ip addr add 10.0.1.1/24 dev wlan0
exec ip netns exec AP1 ip link set wlan0 up

exec ip netns exec AP1 bash -c "dnsmasq -i wlan0 --no-ping --dhcp-authoritative --no-negcache --cache-size=0 --bind-interfaces --all-servers --dhcp-range=10.0.1.2,10.0.1.254" &
#exec ip netns exec AP1 bash -c "iwconfig wlan0 rate 54M" &
#exec ip netns exec AP1 bash -c "iptables -A INPUT -i wlan0 -p udp -m udp --dport 53 -j ACCEPT" &
exec ip netns exec AP1 hostapd -B /usr/local/lib/imunesV10/imunes/hostapd.conf & 


#exec ip netns exec AP2 ip addr add 10.0.2.1/24 dev wlan1
#exec ip netns exec AP2 ip link set wlan1 up
#exec ip netns exec AP2 bash -c "dnsmasq -i wlan1 --no-ping --dhcp-authoritative --no-negcache --cache-size=0 --bind-interfaces --all-servers --dhcp-range=10.0.2.2,10.0.2.254" &
#exec ip netns exec AP1 bash -c "iptables -A INPUT -i wlan1 -p udp -m udp --dport 53 -j ACCEPT" &

#exec ip netns exec AP2 hostapd /usr/local/lib/imunesV10/imunes/hostapd2.conf & 

exec ip netns exec STA1 bash -c "wpa_supplicant -B -Dnl80211 -i wlan2 -c /usr/local/lib/imunesV10/imunes/wpa_supplicant.conf" &
exec ip netns exec STA1 ip link set wlan2 up
#exec ip netns exec STA1 bash -c "iwconfig wlan2 rate 54M" &
exec ip netns exec STA1 bash -c "dhclient -d wlan2" &

#exec ip netns exec STA2 bash -c "wpa_supplicant -B -i wlan3 -c /usr/local/lib/imunesV10/imunes/wpa_supplicant2.conf" &

#exec ip netns exec STA2 bash -c "dhclient -d wlan3" &


