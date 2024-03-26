# Emulation of wifi for Linux Kernel Wifi modules

This imunes release additionally contains creation of an emulated wifi network 
using the kernel module [mac80211_hwsim] and separation of network namespaces.
The Linux kernel provides the mac80211_hwsim module. 
It is a software simulator for IEEE 802.11 radio networks.

## Requirements

    apt-get install wpasupplicant 
	apt-get install hostapd 
	apt-get install iw 
	apt-get install dnsmasq

## Usage

When you run an imunes experiment with one Wifi AP and two Wifi STAtions, then the ping between the two STA should work, otherwise you need to update your system or kernel. Make sure also that the previously mentioned required packages are well installed.
         
Also, if the ping does not work:
Make sure the IP forwarding rule is enabled:
	echo 1 > /proc/sys/net/ipv4/ip_forward
       	or 
	sysctl -w net.ipv4.ip_forward=1
To activate it permanently, you must edit the /etc/sysctl.conf file and activate the command:
	net.ipv4.ip_forward=1

# Copyright 

2020/2021 Sorbonne Université

Improvements and modifications to this version are permitted provided 
the copyright notice and this notice are retained. The Wi-Fi emulation 
under imunes allows you to study and improve the performance of cellular networks. 
You can add other features such as Ad hoc network emulation to improve certain protocols 
and study the vulnerability of systems, etc. 
(See https://wireless.wiki.kernel.org/en/users/documentation/iw/vif)


To better understand the parameters of AP and STA we recommend the following sites:

https://doc.ubuntu-fr.org/hostapd
https://code4pi.fr/2017/05/creer-hotspot-wifi-raspberry/

## Authors

Hanane BENADJI (hanane.benadji@etu.upmc.fr)
Chawki OULAD SAID (chawki.oulad_said@etu.upmc.fr)

Supervised and maintained by Naceur MALOUCH - LIP6/SU

