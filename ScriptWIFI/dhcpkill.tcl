exec ip netns exec STA1 bash -c "dhclient -r wlan2" & 
exec ip netns del AP1
exec ip netns del AP2
exec ip netns del STA1
exec ip netns del STA2
exec modprobe -r mac80211_hwsim
exec killall hostapd
exec killall dnsmasq
exec killall wpa_supplicant 
exec killall dhclient

