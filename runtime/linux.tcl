# 2019-2020 Sorbonne University
# In this version of imunes we added a full integration of emulation of 
# Linux namespaces and CISCO routers, saving of parameters, VLANs, WiFi 
# emulation and other features
# This work was developed by Benadji Hanane and Oulad Said Chawki
# Supervised and maintained by Naceur Malouch - LIP6/SU
#

global VROOT_MASTER ULIMIT_FILE ULIMIT_PROC
set VROOT_MASTER "imunes/template"
set ULIMIT_FILE "1024:16384"
set ULIMIT_PROC "512:1024"



#****f* linux.tcl/writeDataToNodeFile
# NAME
#   writeDataToNodeFile -- write data to virtual node
# SYNOPSIS
#   writeDataToNodeFile $node $path $data
# FUNCTION
#   Writes data to a file on the specified virtual node.
# INPUTS
#   * node -- virtual node id
#   * path -- path to file in node
#   * data -- data to write
#****
proc writeDataToNodeFile { node path data } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set node_id "$eid.$node"
    set node_dir [getVrootDir]/$eid/$node

    writeDataToFile $node_dir/$path $data
    exec docker exec -i $node_id sh -c "cat > $path" < $node_dir/$path
}

#****f* linux.tcl/execCmdNode
# NAME
#   execCmdNode -- execute command on virtual node
# SYNOPSIS
#   execCmdNode $node $cmd
# FUNCTION
#   Executes a command on a virtual node and returns the output.
# INPUTS
#   * node -- virtual node id
#   * cmd -- command to execute
# RESULT
#   * returns the execution output
#****

proc execCmdNode { node cmd } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    set node_id1 "$eid.$node"
    # modification for namespace
    # modification for wifi
    if {[[typemodel $node].virtlayer] == "NAMESPACE" || [[typemodel $node].virtlayer] == "WIFIAP" || [[typemodel $node].virtlayer] == "WIFISTA"  } {
    catch {eval [concat "nexec ip netns exec " $node_id1 $cmd] } output

    return $output
    } else {
    catch {eval [concat "nexec docker exec " $eid.$node $cmd] } output

    return $output
    }
}

#****f* linux.tcl/checkForExternalApps
# NAME
#   checkForExternalApps -- check whether external applications exist
# SYNOPSIS
#   checkForExternalApps $app_list
# FUNCTION
#   Checks whether a list of applications exist on the machine running IMUNES
#   by using the which command.
# INPUTS
#   * app_list -- list of applications
# RESULT
#   * returns 0 if the applications exist, otherwise it returns 1.
#****
proc checkForExternalApps { app_list } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    foreach app $app_list {
    set status [ catch { exec which $app } err ]
    if { $status } {
        return 1
    }
    }
    return 0
}

#****f* linux.tcl/checkForApplications
# NAME
#   checkForApplications -- check whether applications exist
# SYNOPSIS
#   checkForApplications $node $app_list
# FUNCTION
#   Checks whether a list of applications exist on the virtual node by using
#   the which command.
# INPUTS
#   * node -- virtual node id
#   * app_list -- list of applications
# RESULT
#   * returns 0 if the applications exist, otherwise it returns 1.
#****
proc checkForApplications { node app_list } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    foreach app $app_list {
    set status [ catch { exec docker exec $eid.$node which $app } err ]
        if { $status } {
            return 1
        }
    }
    return 0
}

#****f* linux.tcl/startWiresharkOnNodeIfc2
# NAME
#   startWiresharkOnNodeIfc -- start wireshark on an interface
# SYNOPSIS
#   startWiresharkOnNodeIfc $node $ifc
# FUNCTION
#   Start Wireshark on a virtual node on the specified interface.
# INPUTS
#   * node -- virtual node id
#   * ifc -- virtual node interface
#****
# modification for namespace and cisco router
# to add wireshark to namespace PC and cisco router
#modification for openvswitch
#**********
proc startWiresharkOnNodeIfc { node ifc } {
set curdir [pwd]
global dynacurdir

    upvar 0 ::cf::[set ::curcfg]::eid eid
    set node_id1 "$eid.$node"	


    if {[checkForExternalApps "startxcmd"] == 0 && \
    [checkForApplications $node "wireshark"] == 0} {
        startXappOnNode $node "wireshark -ki $ifc" 

    } else {


	        set wiresharkComm ""
                foreach wireshark "wireshark wireshark-gtk wireshark-qt" {
      			  if {[checkForExternalApps $wireshark] == 0} {
       			  set wiresharkComm $wireshark
       			   break
                           }
		}
    }



    if { $wiresharkComm != "" } {
                  if {[[typemodel $node].virtlayer] == "NETGRAPH"} { 
				catch "exec wireshark -ki $eid-$node-$ifc -o gui.window_title:$ifc@[getNodeName $node] &"
      		 } elseif {[[typemodel $node].virtlayer] == "NAMESPACE" || [[typemodel $node].virtlayer] == "WIFIAP" || [[typemodel $node].virtlayer] == "WIFISTA" } { 
                        if {([[typemodel $node].virtlayer] == "WIFIAP" || [[typemodel $node].virtlayer] == "WIFISTA") && $ifc == "hwsim0"} {
     			            catch "exec ip link set $ifc up"
      			            catch "exec wireshark -ki $ifc -o gui.window_title:$ifc@[getNodeName $node] &"
                        } else {
      			                catch "exec ip netns exec $node_id1 wireshark -ki $ifc -o gui.window_title:$ifc@[getNodeName $node] &"
						}
                  
                 } elseif { [[typemodel $node].virtlayer] == "DYNAMIPS" } {
                        if { $ifc == "lo" } { 
                        catch "exec wireshark -ki $ifc -o gui.window_title:$ifc@[getNodeName $node] &"
                        } else {
			set word $ifc
                        set s ""
			set f [open "$dynacurdir/Dynamips/$eid/node/$node.txt" r]
			while {[gets $f line] >= 0} {
    				if {[string match $word* $line]} {
						set s [string range $line 21 end]

   				 }
			}
			close $f
			
                        if {$s != ""} {
                       
      			 catch "exec wireshark -ki $s -o gui.window_title:$ifc@[getNodeName $node] &"
			}
			}
    		} else {
      		 exec docker exec $eid.$node tcpdump -s 0 -U -w - -i $ifc 2>/dev/null |\
     		 $wiresharkComm -o "gui.window_title:$ifc@[getNodeName $node] ($eid)" -k -i - &
      		}
    } else {
 
            tk_dialog .dialog1 "IMUNES error" \
    "IMUNES could not find an installation of Wireshark.\
    If you have Wireshark installed, submit a bug report." \
            info 0 Dismiss
    }
    

}

#****f* linux.tcl/startXappOnNode
# NAME
#   startXappOnNode -- start X application in a virtual node
# SYNOPSIS
#   startXappOnNode $node $app
# FUNCTION
#   Start X application on virtual node
# INPUTS
#   * node -- virtual node id
#   * app -- application to start
#****
proc startXappOnNode { node app } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global debug
    if {[checkForExternalApps "socat"] != 0 } {
        puts "To run X applications on the node, install socat on your host."
        return
    }

    set logfile "/dev/null"
    if {$debug} {
        set logfile "/tmp/startxcmd_$eid\_$node.log"
    }

    eval exec startxcmd [getNodeName $node]@$eid $app > $logfile 2>> $logfile &
}

#****f* linux.tcl/startTcpdumpOnNodeIfc
# NAME
#   startTcpdumpOnNodeIfc -- start tcpdump on an interface
# SYNOPSIS
#   startTcpdumpOnNodeIfc $node $ifc
# FUNCTION
#   Start tcpdump in xterm on a virtual node on the specified interface.
# INPUTS
#   * node -- virtual node id
#   * ifc -- virtual node interface
#****
# modification for namespace and cisco router
# to add Tcpdump to namespace PC and cisco router
proc startTcpdumpOnNodeIfc { node ifc } {

    upvar 0 ::cf::[set ::curcfg]::eid eid
    global dynacurdir

    if {[[typemodel $node].virtlayer] == "DYNAMIPS"} {
    if { $ifc == "lo" } {
       spawnShell $node "tcpdump -ni $ifc"
    } else {
    set word $ifc
    set s ""
    set f [open "$dynacurdir/Dynamips/$eid/node/$node.txt" r]
    while {[gets $f line] >= 0} {
    if {[string match $word* $line]} {
	set s [string range $line 21 end]
     }
   }
	close $f
      if {$s != ""} {
       spawnShell $node "tcpdump -ni $s" 
     }
      
}
          
    } elseif { [[typemodel $node].virtlayer] == "NAMESPACE" || [[typemodel $node].virtlayer] == "WIFIAP" || [[typemodel $node].virtlayer] == "WIFISTA"} {
        spawnShell $node "tcpdump -ni $ifc"
}

    if {[checkForApplications $node "tcpdump"] == 0} {
        spawnShell $node "tcpdump -ni $ifc"

    }
}

#****f* linux.tcl/existingShells
# NAME
#   existingShells -- check which shells exist in a node
# SYNOPSIS
#   existingShells $shells $node
# FUNCTION
#   This procedure checks which of the provided shells are available
#   in a running node.
# INPUTS
#   * shells -- list of shells.
#   * node -- node id of the node for which the check is performed.
#****
# modification for namespace and cisco router
proc existingShells { shells node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    set node_id1 "$eid.$node"
    set existing []
    foreach shell $shells {
         #Modification for wifi
        if {[[typemodel $node].virtlayer] == "NAMESPACE" || [[typemodel $node].virtlayer] == "WIFIAP" || [[typemodel $node].virtlayer] == "WIFISTA" } {
        set cmd "ip netns exec $node_id1 which $shell"

        } elseif { [[typemodel $node].virtlayer] == "DYNAMIPS" } {
        set cmd "which $shell"

} else {
        set cmd "docker exec $eid.$node which $shell"

        }
        set err [catch {eval exec $cmd} res]
        if  {!$err} {
            lappend existing $res
        }
    }
    return $existing
}
#****f* linux.tcl/spawnShell
# NAME
#   spawnShell -- spawn shell
# SYNOPSIS
#   spawnShell $node $cmd
# FUNCTION
#   This procedure spawns a new shell for a specified node.
#   The shell is specified in cmd parameter.
# INPUTS
#   * node -- node id of the node for which the shell is spawned.
#   * cmd -- the path to the shell.
#****
# modification for namespace and cisco router

proc spawnShell { node cmd } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
	set node_id1 "$eid.$node"
        set switchname "$eid-$node"
        set node_id $eid\.$node

    # FIXME make this modular
if {[[typemodel $node].virtlayer] == "DYNAMIPS"} {
 if {$cmd == "telnet"} {
	set name [getNodeName $node]
    	set name1 [split $name "_"]
    	set name2 [lindex $name1 1]
    	set rout [expr $name2-1+2000]

        


    nexec xterm -sb -rightbar \
    -T "IMUNES: [getNodeName $node] (console) [string trim [lindex [split $cmd /] end] ']" \
    -e "telnet localhost $rout" 2> /dev/null &
 } else {
     nexec xterm -sb -rightbar \
    -T "IMUNES: [getNodeName $node] (console) [string trim [lindex [split $cmd /] end] ']" \
    -e "$cmd" 2> /dev/null &
}
    } elseif { [[typemodel $node].virtlayer] == "NAMESPACE" || [[typemodel $node].virtlayer] == "WIFIAP" || [[typemodel $node].virtlayer] == "WIFISTA"} {
    set wifi [lindex $cmd 2]

    if {$wifi == "hwsim0"} {
    catch "exec ip link set $wifi up"
       nexec xterm -sb -rightbar \
    -T "IMUNES: [getNodeName $node] (console) [string trim [lindex [split $cmd /] end] ']" \
    -e "$cmd" 2> /dev/null &

   } else {
    nexec xterm -sb -rightbar \
    -T "IMUNES: [getNodeName $node] (console) [string trim [lindex [split $cmd /] end] ']" \
    -e "ip netns exec $node_id1 $cmd" 2> /dev/null &
   }
} elseif {[[typemodel $node].virtlayer] == "NETGRAPH"} {

     nexec xterm -sb -rightbar \
    -T "IMUNES: [getNodeName $node] -> $switchname" \
    -e "$cmd" 2> /dev/null &
} else {
    
    nexec xterm -sb -rightbar \
    -T "IMUNES: [getNodeName $node] (console) [string trim [lindex [split $cmd /] end] ']" \
    -e "docker exec -it $node_id $cmd" 2> /dev/null &
    }
}


#****f* linux.tcl/fetchRunningExperiments
# NAME
#   fetchRunningExperiments -- fetch running experiments
# SYNOPSIS
#   fetchRunningExperiments
# FUNCTION
#   Returns IDs of all running experiments as a list.
# RESULT
#   * exp_list -- experiment id list
#****
proc fetchRunningExperiments {} {
    catch {exec himage -l | cut -d " " -f 1} exp_list
    set exp_list [split $exp_list "
"]
    return "$exp_list"
}

#****f* linux.tcl/allSnapshotsAvailable
# NAME
#   allSnapshotsAvailable -- all snapshots available
# SYNOPSIS
#   allSnapshotsAvailable
# FUNCTION
#   Procedure that checks whether all node snapshots are available on the
#   current system.
#****
proc allSnapshotsAvailable {} {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    global VROOT_MASTER execMode

    set snapshots $VROOT_MASTER
    foreach node $node_list {
    set img [getNodeDockerImage $node]
    if {$img != ""} {
        lappend snapshots $img
    }
    }
    set snapshots [lsort -uniq $snapshots]
    set missing 0

    foreach template $snapshots {
    set search_template $template
    if {[string match "*:*" $template] != 1} {
        append search_template ":latest"
    }

    catch {exec docker images -q $search_template} images
    if {[llength $images] > 0} {
        continue
    } else {
        # be nice to the user and see whether there is an image id matching
        if {[string length $template] == 12} {
                catch {exec docker images -q} all_images
        if {[lsearch $all_images $template] == -1} {
            incr missing
        }
        } else {
        incr missing
        }
        if {$missing} {
                if {$execMode == "batch"} {
                    puts "Docker image for some virtual nodes:
    $template
is missing.
Run 'docker pull $template' to pull the template."
            } else {
                   tk_dialog .dialog1 "IMUNES error" \
        "Docker image for some virtual nodes:
    $template
is missing.
Run 'docker pull $template' to pull the template." \
                   info 0 Dismiss
            }
            return 0
        }
    }
    }
    return 1
}

proc prepareDevfs {} {}

#****f* linux.tcl/getHostIfcList
# NAME
#   getHostIfcList -- get interfaces list from host
# SYNOPSIS
#   getHostIfcList
# FUNCTION
#   Returns the list of all network interfaces on the host.
# RESULT
#   * extifcs -- list of all external interfaces
#****
proc getHostIfcList {} {
    # fetch interface list from the system
    set extifcs [exec ls /sys/class/net]
    # exclude loopback interface
    set ilo [lsearch $extifcs lo]
    set extifcs [lreplace $extifcs $ilo $ilo]

    return $extifcs
}

proc createExperimentContainer {} {}

proc loadKernelModules {} {
    global all_modules_list

    foreach module $all_modules_list {
        if {[info procs $module.prepareSystem] == "$module.prepareSystem"} {
            $module.prepareSystem
        }
    }
}

proc prepareVirtualFS {} {}

#****f* linux.tcl/prepareFilesystemForNode
# NAME
#   prepareFilesystemForNode -- prepare node filesystem
# SYNOPSIS
#   prepareFilesystemForNode $node
# FUNCTION
#   Prepares the node virtual filesystem.
# INPUTS
#   * node -- node id
#****
proc prepareFilesystemForNode { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set VROOTDIR /var/imunes
    set VROOT_RUNTIME $VROOTDIR/$eid/$node
    pipesExec "mkdir -p $VROOT_RUNTIME" "hold"
    pipesExec "mkdir -p /var/run/netns" "hold"
}

#****f* linux.tcl/createNodeContainer
# NAME
#   createNodeContainer -- creates a virtual node container
# SYNOPSIS
#   createNodeContainer $node
# FUNCTION
#   Creates a docker instance using the defined template and
#   assigns the hostname. Waits for the node to be up.
# INPUTS
#   * node -- node id
#****
proc createNodeContainer { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global VROOT_MASTER ULIMIT_FILE ULIMIT_PROC debug
    
    set node_id "$eid.$node"

    set network "none"

    if { [getNodeDockerAttach $node] } {
    set network "bridge"
    }

    set vroot [getNodeDockerImage $node]
    if { $vroot == "" } {
        set vroot $VROOT_MASTER

    }

    catch { exec docker run --detach --init --tty \
    --privileged --cap-add=ALL --net=$network \
    --name $node_id --hostname=[getNodeName $node] \
    --volume /tmp/.X11-unix:/tmp/.X11-unix \
    --sysctl net.ipv6.conf.all.disable_ipv6=0 \
    --ulimit nofile=$ULIMIT_FILE --ulimit nproc=$ULIMIT_PROC \
    $vroot 


} err
    if { $debug } {
        puts "'exec docker run' ($node_id) caught:\n$err"
    }

    if { [getNodeDockerAttach $node] } {
    catch "exec docker exec $node_id ip l set eth0 down"
    catch "exec docker exec $node_id ip l set eth0 name ext10"
    catch "exec docker exec $node_id ip l set ext10 up"
    
    
   }

    set status ""
    while { [string match 'true' $status] != 1 } {
        catch {exec docker inspect --format '{{.State.Running}}' $node_id} status

    }

}

proc createNodeContainerN { node } {

 upvar 0 ::cf::[set ::curcfg]::eid eid
    global VROOT_MASTER ULIMIT_FILE ULIMIT_PROC debug

    set node_id "$eid.$node"

catch "exec ip netns add $node_id" 

catch "exec rm -rf /etc/netns/$node_id"
catch "exec mkdir /etc/netns/"
catch "exec mkdir /etc/netns/$node_id"
catch "exec cp /etc/resolv.conf /etc/netns/$node_id/resolv.conf"
catch "exec cp /etc/hosts /etc/netns/$node_id/hosts"
catch "exec cp /etc/networks /etc/netns/$node_id/networks"
catch "exec cp /etc/host.conf /etc/netns/$node_id/host.conf"
catch "exec cp /etc/nsswitch.conf /etc/netns/$node_id/nsswitch.conf"
   
}

#Modification for wifi
proc createNodeContainerAP { node } {

    upvar 0 ::cf::[set ::curcfg]::eid eid
    set node_id "$eid.$node"
    catch "exec ip netns add $node_id" 


    global dynacurdir listAP
    upvar 0 ::cf::[set ::curcfg]::eid eid
 

    if {[llength $listAP] > 0} {

 	if { [file exist "$dynacurdir/WIFI/$eid"] != 1 } {
  		 exec mkdir "$dynacurdir/WIFI/$eid"
        }
    if {[file exist "$dynacurdir/WIFI/$eid/AP"] != 1} {
        exec mkdir "$dynacurdir/WIFI/$eid/AP"
    }
   

    if { [file exist "$dynacurdir/WIFI/$eid/AP/$node.conf"] != 1} {
		set id_file [open "$dynacurdir/WIFI/$eid/AP/$node.conf" w+]

        foreach element $listAP {
              
                set Mynode [lindex $element 0]

		if {$node == $Mynode} {

                        set driver [lindex $element 1]
						set wlanID [split $node "n"]
						set wlanID [lindex $wlanID 1]
						puts $id_file "interface=wlan$wlanID\n$driver\n"
                        set ssid [lindex $element 2]
                        if {$ssid != "No-info"} {
						puts $id_file "ssid=$ssid\n"
                        }
                        set mode [lindex $element 3]
                        if {$mode != "No-info"} {
						puts $id_file "hw_mode=$mode\n"
						}                       
				        set channel [lindex $element 4]
                        if {$channel != "No-info"} {
						puts $id_file "channel=$channel\n"
						} 
						set d [lindex $element 5]
                        if {$d != "No-info"} {
						puts $id_file "ieee80211d==$d\n"
						} 
						set country [lindex $element 6]
                        if {$country != "No-info"} {
						puts $id_file "country_code=$country\n"
						} 
						set n [lindex $element 7]
                        if {$n != "No-info"} {
						puts $id_file "ieee80211n=$n\n"
						} 
						set ac [lindex $element 8]
                        if {$ac!= "No-info"} {
						puts $id_file "ieee80211ac=$ac\n"
						}
						set qos [lindex $element 9]
                        if {$qos != "No-info"} {
						puts $id_file "wmm_enabled=$qos\n"
						}
                        set macaddr [lindex $element 10]
						puts $id_file "$macaddr\n"
						set authentification [lindex $element 11] 
                        if {$authentification != "No-info"} {
						puts $id_file "auth_algs=$authentification\n"
						}           
						set wpa [lindex $element 12]
                        if {$wpa != "No-info"} {
						puts $id_file "wpa=$wpa\n"
						} 
						set typesecurite [lindex $element 13]
                        set typesecurite [regsub -all "_" $typesecurite " "]
                        if {$typesecurite != "No-info"} {
						puts $id_file "wpa_key_mgmt=$typesecurite\n"
						} 
                        set typeencryption [lindex $element 14]
                        set typeencryption [regsub -all "_" $typeencryption " "]
                        if {$typeencryption != "No-info"} {
						puts $id_file "wpa_pairwise=$typeencryption\n"
						} 
						set password [lindex $element 15]
                        if {$password != "No-info"} {
						puts $id_file "wpa_passphrase=$password\n"
						} 
						set beacon [lindex $element 16]
                        if {$beacon != "No-info"} {
						puts $id_file "beacon_int=$beacon\n"
						} 
                        set broadcastssid [lindex $element 17]
						puts $id_file "ignore_broadcast_ssid=$broadcastssid\n"

         }			
				                 
		}
#Test 
#puts $id_file "ht_capab=\x5bHT40\x5d\x5bSHORT-GI-40\x5d\x5bDSSS_CCK-40\x5d\x5bMAX-AMSDU-3839\x5d\n"
close $id_file

       }
					

	

 }

if { [file exist "$dynacurdir/WIFI/$eid"] != 1 } {
  		 exec mkdir "$dynacurdir/WIFI/$eid"
        }
if {[file exist "$dynacurdir/WIFI/$eid/AP"] != 1} {
        exec mkdir "$dynacurdir/WIFI/$eid/AP"
}

   }

   

#Modification for wifi
proc createNodeContainerSTA { node } {

    upvar 0 ::cf::[set ::curcfg]::eid eid
    set node_id "$eid.$node"
    catch "exec ip netns add $node_id"


 global dynacurdir listSTA
 upvar 0 ::cf::[set ::curcfg]::eid eid
 




    if {[llength $listSTA] > 0} {

 		    if { [file exist "$dynacurdir/WIFI/$eid"] != 1 } {
  					 exec mkdir "$dynacurdir/WIFI/$eid"
        	}
   		    if { [file exist "$dynacurdir/WIFI/$eid/STA"] != 1 } {
 
     				 exec mkdir "$dynacurdir/WIFI/$eid/STA"
    		}

   

    		if { [file exist "$dynacurdir/WIFI/$eid/STA/$node.conf"] != 1} {
					
					set id_file [open "$dynacurdir/WIFI/$eid/STA/$node.conf" w+]

					        foreach element $listSTA {
              
					                set Mynode [lindex $element 0]

									if {$node == $Mynode} {

                                        puts $id_file "country=FR\n"
                                        puts $id_file "ctrl_interface=/var/run/wpa_supplicant\n"
                                        puts $id_file "update_config=1\n"
                                        puts $id_file "network={\n"

										set ssid [lindex $element 1]
                                        if {$ssid != "No-info"} {
                                        puts $id_file "ssid=\"$ssid\"\n"
						                }
				                        set encryption [lindex $element 2]
                                        if {$encryption != "No-info"} {
                                            if {$encryption == "default" } {
                                                  puts $id_file "key_mgmt=WPA-PSK WPA-EAP\n"
											} else {
                                                  puts $id_file "key_mgmt=$encryption\n"
											}
						                }									
								        set protocole [lindex $element 3]
                                        if {$protocole != "No-info"} {
                                            if {$protocole == "default" } {
                                                  puts $id_file "proto=RSN WPA\n"
											} else {
                                                  puts $id_file "proto=$protocole\n"
											}
						                }
										set groupe [lindex $element 4]
                                        if {$groupe != "No-info"} {
                                            if {$groupe == "default" } {
                                                  puts $id_file "group=TKIP CCMP WEP104 WEP40\n"
											} else {
                                                  puts $id_file "group=$groupe\n"
											}
						                }
										set scanssid [lindex $element 5]
                                   
                                        puts $id_file "scan_ssid=$scanssid\n"
								
										set pairwise [lindex $element 6]
                                        if {$pairwise != "No-info"} {
                                            if {$pairwise == "default" } {
                                                  puts $id_file "pairwise=TKIP CCMP\n"
											} else {
                                                  puts $id_file "pairwise=$pairwise\n"
											}
						                }
										set password [lindex $element 7]
                                        if {$password != "No-info"} {
                                          
                                                  puts $id_file "psk=\"$password\"\n"
											
						                }                	        
 										set priority [lindex $element 8]
                                        if {$priority != "No-info"} {
                                          
                                                  puts $id_file "priority=$priority"
											
						                } 
                                        puts $id_file "}\n"


		   					} 

 
    			  }
close $id_file
 		}

}  
if { [file exist "$dynacurdir/WIFI/$eid"] != 1 } {
  		 exec mkdir "$dynacurdir/WIFI/$eid"
        }
    if {[file exist "$dynacurdir/WIFI/$eid/STA"] != 1} {
        exec mkdir "$dynacurdir/WIFI/$eid/STA"
    }   
}

#Modification for wifi
proc cleanupAP { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    set node_id "$eid.$node"
    catch "exec rmmod mac80211_hwsim mac80211 cfg80211"
    #exec ip netns exec $node_id bash -c "killall hostapd" &

    #exec ip netns exec $node_id bash -c "killall dnsmasq" & 



    #exec ip netns exec $node_id bash -c "killall wpa_supplicant" &

   
}

proc cleanupSTA { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    set node_id "$eid.$node"
    set id [split $node "n"]
    set id [lindex $id 1]

    exec ip netns exec $node_id bash -c  "wpa_cli -i wlan$id terminate" &
    exec ip netns exec $node_id bash -c  "dhclient -r wlan$id" &  
    catch "exec rmmod mac80211_hwsim mac80211 cfg80211"

    #exec ip netns exec $node_id killall wpa_supplicant &
    #exec ip netns exec $node_id ifdown wlan$id &



   
}

#Modification for wifi
proc prepareAP { } {

upvar 0 ::cf::[set ::curcfg]::node_list node_list
catch "exec modprobe -r mac80211_hwsim" 
set nombreIfc [llength $node_list]
 
foreach node $node_list {
if {[nodeType $node] =="wifiAP" || [nodeType $node] == "wifiSTA"} {
    catch "exec modprobe mac80211_hwsim radios=$nombreIfc"
break 
}
}
  
}



#Modification for wifi
proc runConfOnNodeAP { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    
    global listAP dynacurdir listAPIP 


verifierconfiguration_AP $node
set node_id "$eid.$node"

if {[llength $listAPIP] > 0} {

 	
        foreach element $listAPIP {
              
                set Mynode [lindex $element 0]

		if {$node == $Mynode} {


                                set addresse [lindex $element 1]
				                set masque [lindex $element 2]
                                set dhcp1 [lindex $element 3]
                                set dhcp2 [lindex $element 4]
            
	                }
       }
}


    set wlanID [split $node "n"]
	set wlanID [lindex $wlanID 1]
    exec iw phy phy$wlanID set netns name $node_id
    # recupération de l'adresses ip 
     exec ip netns exec $node_id ip addr add $addresse/$masque dev wlan$wlanID
     exec ip netns exec $node_id ip link set wlan$wlanID up
   #dhcp


     exec ip netns exec $node_id bash -c "dnsmasq -i wlan$wlanID --no-ping --dhcp-authoritative --no-negcache --cache-size=0 --bind-interfaces --all-servers --dhcp-range=$dhcp1,$dhcp2" & 

    #j'active hostapd
        if { [file exist "$dynacurdir/WIFI/$eid/AP/$node.conf"] == 1} {



               exec ip netns exec $node_id bash -c "hostapd $dynacurdir/WIFI/$eid/AP/$node.conf" &

              
        }
   


#fin de la procedure
}


#Modification for wifi
proc runConfOnNodeSTA { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    
    global listAP dynacurdir

    set node_id "$eid.$node"

    verifierconfiguration_STA $node

    set wlanID [split $node "n"]
	set wlanID [lindex $wlanID 1]
    exec iw phy phy$wlanID set netns name $node_id


    #j'active wpa_supplicant
        if { [file exist "$dynacurdir/WIFI/$eid/STA/$node.conf"] == 1} {


               exec ip netns exec $node_id bash -c "wpa_supplicant -B -i wlan$wlanID -c $dynacurdir/WIFI/$eid/STA/$node.conf" &

        }

    #dhcp client 

      exec ip netns exec $node_id bash -c "dhclient -d wlan$wlanID" &


#fin de la procedure
}











#Modification for dyanmips
proc createNodeContainerR { node } {

    global dynacurdir listRouterCisco
    upvar 0 ::cf::[set ::curcfg]::eid eid
    set node_id "$eid.$node"
    catch "exec ip netns add $node_id" 

   if {[llength $listRouterCisco] > 0} {

 if { [file exist "$dynacurdir/Dynamips/$eid"] != 1 } {
   exec mkdir "$dynacurdir/Dynamips/$eid"
   exec mkdir "$dynacurdir/Dynamips/$eid/lab"
   exec mkdir "$dynacurdir/Dynamips/$eid/node"
   exec mkdir "$dynacurdir/Dynamips/$eid/configuration"

	if { [file exist "$dynacurdir/Dynamips/$eid/lab/topologie.net"] != 1} {
		set r "7200"
		set loc "localhost"    
		set id_file [open "$dynacurdir/Dynamips/$eid/lab/topologie.net" w+]
		puts $id_file \x5b$loc\x5d
		puts $id_file "\n"
		puts $id_file \x5b\x5b$r\x5d\x5d
		puts $id_file "\nghostios = true \nsparsemem = true \nautostart = true \nidlepc = 0x608a0264 \nimage = $dynacurdir/Dynamips/ios/c7200-a3jk91s-mz.122-31.SB16.image\n "

		close $id_file
	}
}

if { [file exist "$dynacurdir/Dynamips/$eid/node/$node.txt"] != 1} {
		   
set id_file [open "$dynacurdir/Dynamips/$eid/node/$node.txt" w+]

    foreach element $listRouterCisco {
              
                set Mynode [lindex $element 0]

		if {$node == $Mynode} {

                		set routeur [lindex $element 1]
                                set routeur1 [lindex $element 2]
				set config [lindex $element 3]
                                set config1 [lindex $element 4]
				set config2 [lindex $element 5]
				set config3 [lindex $element 6]
				set config4 [lindex $element 7]
				set config5 [lindex $element 8]
				set config6 [lindex $element 9]

				puts $id_file "$routeur $routeur1 \n$config\n$config1\n$config2\n$config3\n$config4\n$config5\n$config6\ncnfg=$dynacurdir/Dynamips/$eid/configuration/$node.txt\n"
			
				                 
		}

   }
					
close $id_file
}

   }

   if { [file exist "$dynacurdir/Dynamips/$eid"] != 1 } {
   exec mkdir "$dynacurdir/Dynamips/$eid"
   exec mkdir "$dynacurdir/Dynamips/$eid/lab"
   exec mkdir "$dynacurdir/Dynamips/$eid/node"
   exec mkdir "$dynacurdir/Dynamips/$eid/configuration"

	if { [file exist "$dynacurdir/Dynamips/$eid/lab/topologie.net"] != 1} {
		set r "7200"
		set loc "localhost"    
		set id_file [open "$dynacurdir/Dynamips/$eid/lab/topologie.net" w+]
		puts $id_file \x5b$loc\x5d
		puts $id_file "\n"
		puts $id_file \x5b\x5b$r\x5d\x5d
		puts $id_file "\nghostios = true \nsparsemem = true \nautostart = true \nidlepc = 0x608a0264 \nimage = $dynacurdir/Dynamips/ios/c7200-a3jk91s-mz.122-31.SB16.image\n "

		close $id_file
	}

}
}

#****f* linux.tcl/createNodePhysIfcs
# NAME
#   createNodePhysIfcs -- create node physical interfaces
# SYNOPSIS
#   createNodePhysIfcs $node
# FUNCTION
#   Creates physical interfaces for the given node.
# INPUTS
#   * node -- node id
#****
proc createNodePhysIfcs { node } {}

proc createNodeLogIfcs { node } {}

#****f* linux.tcl/configureICMPoptions
# NAME
#   configureICMPoptions -- configure ICMP options
# SYNOPSIS
#   configureICMPoptions $node
# FUNCTION
#  Configures the necessary ICMP sysctls in the given node.
# INPUTS
#   * node -- node id
#****
proc configureICMPoptions { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    array set sysctl_icmp {
    net.ipv4.icmp_ratelimit         0
    net.ipv4.icmp_echo_ignore_broadcasts    1
    }

    foreach {name val} [array get sysctl_icmp] {
    lappend cmd "sysctl $name=$val"
    }
    set cmds [join $cmd "; "]

    pipesExec "docker exec $eid.$node sh -c \'$cmds\'" "hold"
}
# modification for namespace and cisco router
proc createLinkBetween { lnode1 lnode2 ifname1 ifname2 } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    set node_id1 "$eid.$lnode1"
    set node_id2 "$eid.$lnode2"
    set curdir [pwd]
    global dynacurdir
    set adr1 [getIfcIPv4addr $lnode1 $ifname1]
    set adr2 [getIfcIPv4addr $lnode2 $ifname2]

    set type [nodeType $lnode1]
    set type2 [nodeType $lnode2]

   



    

    set ether1 [getIfcMACaddr $lnode1 $ifname1]

    if {$ether1 == ""} {
        autoMACaddr $lnode1 $ifname1
    }
    set ether1 [getIfcMACaddr $lnode1 $ifname1]
   

    set ether2 [getIfcMACaddr $lnode2 $ifname2]

    if {$ether2 == ""} {
        autoMACaddr $lnode2 $ifname2
    }
    set etherf2 [getIfcMACaddr $lnode2 $ifname2]

    set lname1 $lnode1
    set lname2 $lnode2

    switch -exact "[[typemodel $lnode1].virtlayer]-[[typemodel $lnode2].virtlayer]" {
    NETGRAPH-NETGRAPH {
        if { [nodeType $lnode1] == "ext" } {

        catch "exec ovs-vsctl add-br $eid-$lnode1"
        catch "exec ovs-vsctl set bridge $eid-$lnode1 stp_enable=true"
        }
        if { [nodeType $lnode2] == "ext" } {

        catch "exec ovs-vsctl add-br $eid-$lnode2"
        catch "exec ovs-vsctl set bridge $eid-$lnode2 stp_enable=true"
        }

        set hostIfc1 "$eid-$lname1-$ifname1"
        set hostIfc2 "$eid-$lname2-$ifname2"

        catch {exec ip link add name "$hostIfc1" type veth peer name "$hostIfc2"}

        catch "exec ovs-vsctl add-port $eid-$lname1 $hostIfc1"
        catch "exec ovs-vsctl add-port $eid-$lname2 $hostIfc2"
        # set bridge interfaces up
        exec ip link set dev $hostIfc1 up
        exec ip link set dev $hostIfc2 up
    }
    NAMESPACE-NAMESPACE {

       set hostIfc1 "$eid-$lname1-$ifname1"
       set hostIfc2 "$eid-$lname2-$ifname2"
     

        # connect two interface of two namespace node using ip link
        exec ip link add name "$hostIfc1" type veth peer name "$hostIfc2" 
        #assign interface to namespace nodes
        exec ip link set "$hostIfc1" netns $node_id1 
        exec ip link set "$hostIfc2" netns $node_id2 
        # change the name of interface
        catch "exec ip netns exec $node_id1 ip link set $hostIfc1 name $ifname1"
        catch "exec ip netns exec $node_id2 ip link set $hostIfc2 name $ifname2"
     

       # MAC address Namespace

       catch "exec ip netns exec $node_id1 ip link set $ifname1 address $ether1"
       catch "exec ip netns exec $node_id2 ip link set $ifname2 address $ether2"
	  # activate ethernet interface of namespace node
        catch "exec ip netns exec $node_id1 ip link set $ifname1 up"
        catch "exec ip netns exec $node_id2 ip link set $ifname2 up"
   



    }
    VIMAGE-VIMAGE {

        set lnode1Ns [createNetNs $lnode1]
        set lnode2Ns [createNetNs $lnode2]

        # generate temporary interface names
        set hostIfc1 "v${ifname1}pn${lnode1Ns}"
        set hostIfc2 "v${ifname2}pn${lnode2Ns}"
        exec ip link add name "$hostIfc1" type veth peer name "$hostIfc2"

        # move veth pair sides to node namespaces
        setIfcNetNs $lnode1 $hostIfc1 $ifname1
        setIfcNetNs $lnode2 $hostIfc2 $ifname2
        
        exec nsenter -n -t $lnode1Ns ip link set dev "$ifname1" \
        address "$ether1"
       
        exec nsenter -n -t $lnode2Ns ip link set dev "$ifname2" \
        address "$ether2"


        # delete net namespace reference files
        exec ip netns del $lnode1Ns
        exec ip netns del $lnode2Ns
     

    }

    NAMESPACE-VIMAGE {
    # the case of linux namespace with vimage        
        set lnode1Ns [createNetNs $lnode2]
       # set hostIfc1 "veth.$ifname1.$lnode1.$eid" 
        set hostIfc1 "$eid-$lname1-$ifname1" 
        set hostIfc2 "v${ifname2}pn${lnode1Ns}"
    #    exec ip link del $hostIfc1

        # connect two interface of namespace and vimage node using ip link
        exec ip link add name "$hostIfc2" type veth peer name "$hostIfc1"


	#assign interface to namespace node
        exec ip link set "$hostIfc1" netns $node_id1  
        setIfcNetNs $lnode2 $hostIfc2 $ifname2
        #docker pc
        exec nsenter -n -t $lnode1Ns ip link set dev "$ifname2" \
        address "$ether2"
       
        # change the name of interface
        
        catch "exec ip netns exec $node_id1 ip link set $hostIfc1 name $ifname1"
       # MAC address Namespace

       catch "exec ip netns exec $node_id1 ip link set $ifname1 address $ether1"
  	# activate ethernet interface of namespace node 
        catch "exec ip netns exec $node_id1 ip link set $ifname1 up"
       
        exec ip netns del $lnode1Ns

    
      }

    VIMAGE-NAMESPACE {
      # the case of vimage with linux namespace         
        set lnode1Ns [createNetNs $lnode1]
        set hostIfc1 "v${ifname1}pn${lnode1Ns}"
      #  set hostIfc2 "veth.$ifname2.$lnode2.$eid"
        set hostIfc2 "$eid-$lname2-$ifname2"
      #  exec ip link del $hostIfc2

        exec ip link add name "$hostIfc1" type veth peer name "$hostIfc2"
 
        exec ip link set "$hostIfc2" netns $node_id2  
        setIfcNetNs $lnode1 $hostIfc1 $ifname1
        #docker pc
        exec nsenter -n -t $lnode1Ns ip link set dev "$ifname1" \
        address "$ether1"
       
       # change the name of interface
        catch "exec ip netns exec $node_id2 ip link set $hostIfc2 name $ifname2"

       # MAC address Namespace

       catch "exec ip netns exec $node_id2 ip link set $ifname2 address $ether2"
       
	# activate ethernet interface of namespace node   
        catch "exec ip netns exec $node_id2 ip link set $ifname2 up"
    
        exec ip netns del $lnode1Ns
    
        }
 WIFIAP-VIMAGE {
    # the case of linux namespace with vimage        
        set lnode1Ns [createNetNs $lnode2]
       # set hostIfc1 "veth.$ifname1.$lnode1.$eid" 
        set hostIfc1 "$eid-$lname1-$ifname1" 
        set hostIfc2 "v${ifname2}pn${lnode1Ns}"
    #    exec ip link del $hostIfc1

        # connect two interface of WIFIAP and vimage node using ip link
        exec ip link add name "$hostIfc2" type veth peer name "$hostIfc1"


	#assign interface to wifiAP node
        exec ip link set "$hostIfc1" netns $node_id1  
        setIfcNetNs $lnode2 $hostIfc2 $ifname2
        #docker pc
        exec nsenter -n -t $lnode1Ns ip link set dev "$ifname2" \
        address "$ether2"
       
        # change the name of interface
        
        catch "exec ip netns exec $node_id1 ip link set $hostIfc1 name $ifname1"
       # MAC address WIFIAP

       catch "exec ip netns exec $node_id1 ip link set $ifname1 address $ether1"
  	# activate ethernet interface of WIFIAP node 
        catch "exec ip netns exec $node_id1 ip link set $ifname1 up"
       
        exec ip netns del $lnode1Ns

    
      }
 VIMAGE-WIFIAP {
      # the case of vimage with linux wifiAP        
        set lnode1Ns [createNetNs $lnode1]
        set hostIfc1 "v${ifname1}pn${lnode1Ns}"
      #  set hostIfc2 "veth.$ifname2.$lnode2.$eid"
        set hostIfc2 "$eid-$lname2-$ifname2"
      #  exec ip link del $hostIfc2

        exec ip link add name "$hostIfc1" type veth peer name "$hostIfc2"
 
        exec ip link set "$hostIfc2" netns $node_id2  
        setIfcNetNs $lnode1 $hostIfc1 $ifname1
        #docker pc
        exec nsenter -n -t $lnode1Ns ip link set dev "$ifname1" \
        address "$ether1"
       
       # change the name of interface
        catch "exec ip netns exec $node_id2 ip link set $hostIfc2 name $ifname2"

       # MAC address wifiAP

       catch "exec ip netns exec $node_id2 ip link set $ifname2 address $ether2"
       
	# activate ethernet interface of wifiAP node   
        catch "exec ip netns exec $node_id2 ip link set $ifname2 up"
    
        exec ip netns del $lnode1Ns
    
        }

WIFIAP-NAMESPACE {

     
       set hostIfc1 "$eid-$lname1-$ifname1"
       set hostIfc2 "$eid-$lname2-$ifname2"
      

        # connect two interface of wifiAP and namespace node using ip link
        exec ip link add name "$hostIfc1" type veth peer name "$hostIfc2" 
        #assign interface to WIFIAP node
        exec ip link set "$hostIfc1" netns $node_id1 
        #assign interface to namespace node
        exec ip link set "$hostIfc2" netns $node_id2 
        # change the name of interface
        catch "exec ip netns exec $node_id1 ip link set $hostIfc1 name $ifname1"
        catch "exec ip netns exec $node_id2 ip link set $hostIfc2 name $ifname2"
        #catch "exec ip netns exec $node ip addr add $adresse dev $ifname1"
	#catch "exec ip netns exec $node ip addr add $adresse dev $ifname1"

       # MAC address wifiAP

       catch "exec ip netns exec $node_id1 ip link set $ifname1 address $ether1"
      # MAC address namespace

       catch "exec ip netns exec $node_id2 ip link set $ifname2 address $ether2"
	# activate ethernet interface of namespace node
        catch "exec ip netns exec $node_id1 ip link set $ifname1 up"
        catch "exec ip netns exec $node_id2 ip link set $ifname2 up"
   



    }

NAMESPACE-WIFIAP {

     
       set hostIfc1 "$eid-$lname1-$ifname1"
       set hostIfc2 "$eid-$lname2-$ifname2"
      

        # connect two interface of wifiAP and namespace node using ip link
        exec ip link add name "$hostIfc1" type veth peer name "$hostIfc2" 
        #assign interface to namespace node
        exec ip link set "$hostIfc1" netns $node_id1 
        #assign interface to wifiap node
        exec ip link set "$hostIfc2" netns $node_id2 
        # change the name of interface
        catch "exec ip netns exec $node_id1 ip link set $hostIfc1 name $ifname1"
        catch "exec ip netns exec $node_id2 ip link set $hostIfc2 name $ifname2"
        #catch "exec ip netns exec $node ip addr add $adresse dev $ifname1"
	#catch "exec ip netns exec $node ip addr add $adresse dev $ifname1"

       # MAC address namespace

       catch "exec ip netns exec $node_id1 ip link set $ifname1 address $ether1"
      # MAC address wifiAP

       catch "exec ip netns exec $node_id2 ip link set $ifname2 address $ether2"
	# activate ethernet interface of namespace and wifi AP node
        catch "exec ip netns exec $node_id1 ip link set $ifname1 up"
        catch "exec ip netns exec $node_id2 ip link set $ifname2 up"
   



    }
WIFIAP-WIFIAP {

     
       set hostIfc1 "$eid-$lname1-$ifname1"
       set hostIfc2 "$eid-$lname2-$ifname2"
      

        # connect two interface of wifiAP  node using ip link
        exec ip link add name "$hostIfc1" type veth peer name "$hostIfc2" 
        #assign interface to WIFIAP node
        exec ip link set "$hostIfc1" netns $node_id1 
        #assign interface to WIFIAP node
        exec ip link set "$hostIfc2" netns $node_id2 
        # change the name of interface
        catch "exec ip netns exec $node_id1 ip link set $hostIfc1 name $ifname1"
        catch "exec ip netns exec $node_id2 ip link set $hostIfc2 name $ifname2"
        #catch "exec ip netns exec $node ip addr add $adresse dev $ifname1"
	#catch "exec ip netns exec $node ip addr add $adresse dev $ifname1"

       # MAC address wifiAP

       catch "exec ip netns exec $node_id1 ip link set $ifname1 address $ether1"
      # MAC address namespace

       catch "exec ip netns exec $node_id2 ip link set $ifname2 address $ether2"
	# activate ethernet interface of WIFIAP node
        catch "exec ip netns exec $node_id1 ip link set $ifname1 up"
        catch "exec ip netns exec $node_id2 ip link set $ifname2 up"
   



    }
 DYNAMIPS-WIFIAP {
    # the case of dynamips with wifiAP
        
      #  set hostIfc1 "veth.$lnode2.$lnode1.$eid"
      #  set hostIfc2 "veth.$ifname2.$lnode2.$eid"
      set hostIfc1 "$eid-$lnode2-$lnode1"
      set hostIfc2 "$eid-$ifname2-$lnode2"
    #    exec ip link del $hostIfc1
    #    exec ip link del $hostIfc2

        exec ip link add name "$hostIfc1" type veth peer name "$hostIfc2"
        exec ip link set dev $hostIfc1 up
       # edit cisco router configuration file
        verifierFichier_Dynamips $lnode1
        set fp [open "$dynacurdir/Dynamips/$eid/node/$lnode1.txt" a]
        puts $fp "$ifname1 = NIO_linux_eth:$hostIfc1"
        close $fp 

           
        #move interface to wifiap node
        exec ip link set "$hostIfc2" netns $node_id2  

        # change the name of interface
       
        catch "exec ip netns exec $node_id2 ip link set $hostIfc2 name $ifname2"

         # MAC address wifiap

       catch "exec ip netns exec $node_id2 ip link set $ifname2 address $ether2"
        
	# activate ethernet interface of wifiAP node 
       
        catch "exec ip netns exec $node_id2 ip link set $ifname2 up"
    
    }

WIFIAP-DYNAMIPS {


       # set hostIfc1 "veth.$ifname1.$lnode1.$eid"
       # set hostIfc2 "veth.$lnode1.$lnode2.$eid"
       set hostIfc1 "$eid-$ifname1-$lnode1"
       set hostIfc2 "$eid-$lnode1-$lnode2"
      
    

        exec ip link add name "$hostIfc1" type veth peer name "$hostIfc2"
	
        exec ip link set dev $hostIfc2 up
        
        verifierFichier_Dynamips $lnode2
        
        set fp [open "$dynacurdir/Dynamips/$eid/node/$lnode2.txt" a]
        puts $fp "$ifname2 = NIO_linux_eth:$hostIfc2"
        close $fp

        
    
        exec ip link set "$hostIfc1" netns $node_id1  
            
        # change the name of wifiap
        catch "exec ip netns exec $node_id1 ip link set $hostIfc1 name $ifname1"
        # MAC address wifiap

       catch "exec ip netns exec $node_id1 ip link set $ifname1 address $ether1"  
        # activate ethernet interface of wifiap node      
        catch "exec ip netns exec $node_id1 ip link set $ifname1 up"
    
    } 



    NETGRAPH-WIFIAP {
	# the case of netgraph with wifiap
    	# we call fonction which add node to bridge
        addNodeIfcToBridgeAP $lname1 $ifname1 $lnode2 $ifname2 $ether2
        }

    WIFIAP-NETGRAPH {
	# the case of  wifiap with netgraph 
    	# we call fonction which add node to bridge
        addNodeIfcToBridgeAP $lname2 $ifname2 $lnode1 $ifname1 $ether1
        }

    NETGRAPH-VIMAGE {

        addNodeIfcToBridge $lname1 $ifname1 $lnode2 $ifname2 $ether2
        }
    VIMAGE-NETGRAPH {
        addNodeIfcToBridge $lname2 $ifname2 $lnode1 $ifname1 $ether1
        }

    NETGRAPH-NAMESPACE {
	# the case of netgraph with namespace
    	# we call fonction which add node to bridge
        addNodeIfcToBridgeN $lname1 $ifname1 $lnode2 $ifname2 $ether2
        }

    NAMESPACE-NETGRAPH {
	# the case of  namespace with netgraph 
    	# we call fonction which add node to bridge
        addNodeIfcToBridgeN $lname2 $ifname2 $lnode1 $ifname1 $ether1
        }

    DYNAMIPS-DYNAMIPS {
        # the case of  dynamips with dynamips (cisco router)        
    verifierFichier_Dynamips $lnode1
    verifierFichier_Dynamips $lnode2 
      set hostIfc1 "$eid-$lnode1-$lnode2"
      set hostIfc2 "$eid-$lnode2-$lnode1"

      exec ip link add name "$hostIfc1" type veth peer name "$hostIfc2"
      exec ip link set dev $hostIfc1 up
      exec ip link set dev $hostIfc2 up
     
      # edit cisco router configuration file
        
        set fp [open "$dynacurdir/Dynamips/$eid/node/$lnode1.txt" a]
        puts $fp "$ifname1 = NIO_linux_eth:$hostIfc1"
        close $fp 


      	set fp [open "$dynacurdir/Dynamips/$eid/node/$lnode2.txt" a]
        puts $fp "$ifname2 = NIO_linux_eth:$hostIfc2"
        close $fp
        
    } 

    DYNAMIPS-VIMAGE {
        # the case of  dynamips with vimage      

        set lnode1Ns [createNetNs $lnode2]

       # set hostIfc1 "veth.$lnode2.$lnode1.$eid"
        set hostIfc1 "$eid-$lnode2-$lnode1"
        set hostIfc2 "v${ifname2}pn${lnode1Ns}"
     #   exec ip link del $hostIfc1

        exec ip link add name "$hostIfc1" type veth peer name "$hostIfc2"
        exec ip link set dev $hostIfc1 up

        verifierFichier_Dynamips $lnode1

	# edit cisco router configuration file
        set fp [open "$dynacurdir/Dynamips/$eid/node/$lnode1.txt" a]
        puts $fp "$ifname1 = NIO_linux_eth:$hostIfc1"
        close $fp

        setIfcNetNs $lnode2 $hostIfc2 $ifname2
        #docker pc
        exec nsenter -n -t $lnode1Ns ip link set dev "$ifname2" \
        address "$ether2"
       
       
        exec ip netns del $lnode1Ns


    }

    VIMAGE-DYNAMIPS {
 # the case of vimage with dynamips
     
        set lnode1Ns [createNetNs $lnode1]

       # set hostIfc1 "veth.$lnode1.$lnode2"
        set hostIfc1 "$eid-$lnode1-$lnode2"
        set hostIfc2 "v${ifname1}pn${lnode1Ns}"
      #  exec ip link del $hostIfc1
      
        exec ip link add name "$hostIfc1" type veth peer name "$hostIfc2"
        exec ip link set dev $hostIfc1 up

        verifierFichier_Dynamips $lnode2
        
        set fp [open "$dynacurdir/Dynamips/$eid/node/$lnode2.txt" a]
        puts $fp "$ifname2 = NIO_linux_eth:$hostIfc1"
        close $fp
        


        setIfcNetNs $lnode1 $hostIfc2 $ifname1
        #docker pc
        exec nsenter -n -t $lnode1Ns ip link set dev "$ifname1" \
        address "$ether1"
       
       
        exec ip netns del $lnode1Ns


    }

    DYNAMIPS-NAMESPACE {
    # the case of dynamips with namespace
        
      #  set hostIfc1 "veth.$lnode2.$lnode1.$eid"
      #  set hostIfc2 "veth.$ifname2.$lnode2.$eid"
      set hostIfc1 "$eid-$lnode2-$lnode1"
      set hostIfc2 "$eid-$ifname2-$lnode2"
    #    exec ip link del $hostIfc1
    #    exec ip link del $hostIfc2

        exec ip link add name "$hostIfc1" type veth peer name "$hostIfc2"
        exec ip link set dev $hostIfc1 up
       # edit cisco router configuration file
        verifierFichier_Dynamips $lnode1
        set fp [open "$dynacurdir/Dynamips/$eid/node/$lnode1.txt" a]
        puts $fp "$ifname1 = NIO_linux_eth:$hostIfc1"
        close $fp 

           
        #move interface to namespace node
        exec ip link set "$hostIfc2" netns $node_id2  

        # change the name of interface
       
        catch "exec ip netns exec $node_id2 ip link set $hostIfc2 name $ifname2"
         #MAC adresse 
        catch "exec ip netns exec $node_id2 ip link set $ifname2 address $ether2"
        
	# activate ethernet interface of namespace node 
       
        catch "exec ip netns exec $node_id2 ip link set $ifname2 up"
    
    }

    NAMESPACE-DYNAMIPS {


       # set hostIfc1 "veth.$ifname1.$lnode1.$eid"
       # set hostIfc2 "veth.$lnode1.$lnode2.$eid"
       set hostIfc1 "$eid-$ifname1-$lnode1"
       set hostIfc2 "$eid-$lnode1-$lnode2"
      
    

        exec ip link add name "$hostIfc1" type veth peer name "$hostIfc2"
	
        exec ip link set dev $hostIfc2 up
        
        verifierFichier_Dynamips $lnode2
        
        set fp [open "$dynacurdir/Dynamips/$eid/node/$lnode2.txt" a]
        puts $fp "$ifname2 = NIO_linux_eth:$hostIfc2"
        close $fp

        
    
        exec ip link set "$hostIfc1" netns $node_id1  
            
        # change the name of interface
        catch "exec ip netns exec $node_id1 ip link set $hostIfc1 name $ifname1" 
        #MAC adresse 
        catch "exec ip netns exec $node_id1 ip link set $ifname1 address $ether1"
        # activate ethernet interface of namespace node      
        catch "exec ip netns exec $node_id1 ip link set $ifname1 up"
    
    } 

    NETGRAPH-DYNAMIPS {
	# the case of netgraph with dynamips
	# we call fonction which add node to bridge
        addNodeIfcToBridgeR $lname1 $ifname1 $lnode2 $ifname2 
        }

    DYNAMIPS-NETGRAPH {
	# the case of dynamips with netgraph
	# we call fonction which add node to bridge
        addNodeIfcToBridgeR $lname2 $ifname2 $lnode1 $ifname1 
    }    
     

    }


}

proc configureLinkBetween { lnode1 lnode2 ifname1 ifname2 link } {


    upvar 0 ::cf::[set ::curcfg]::eid eid

    # FIXME: merge this with execSet* commands
    execSetLinkParams $eid $link

    # if {[nodeType $lnode1] != "rj45" && [nodeType $lnode2] != "rj45"} {
    #     set qdisc [getIfcQDisc $lnode1 $ifname1]
    #     if {$qdisc ne "FIFO"} {
    #         execSetIfcQDisc $eid $lnode1 $ifname2 $qdisc
    #     }

    #     set qdisc [getIfcQDisc $lnode2 $ifname2]
    #     if {$qdisc ne "FIFO"} {
    #         execSetIfcQDisc $eid $lnode2 $ifname2 $qdisc
    #     }
    #     set qdrop [getIfcQDrop $node $ifc]
    #     if {$qdrop ne "drop-tail"} {
    #         execSetIfcQDrop $eid $node $ifc $qdrop
    #     }
    #     set qlen [getIfcQLen $node $ifc]
    #     if {$qlen ne 50} {
    #         execSetIfcQLen $eid $node $ifc $qlen
    #     }
    # }
}

#****f* linux.tcl/startIfcsNode
# NAME
#   startIfcsNode -- start interfaces on node
# SYNOPSIS
#   startIfcsNode $node
# FUNCTION
#  Starts all interfaces on the given node.
# INPUTS
#   * node -- node id
#****
proc startIfcsNode { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set cmds ""
    set nodeNs [getNodeNamespace $node]
    foreach ifc [allIfcList $node] {
    set mtu [getIfcMTU $node $ifc]
    set tmpifc $ifc
    if { $ifc == "lo0" } {
        set tmpifc lo
    }
    if {[getIfcOperState $node $ifc] == "up"} {
        set cmds "$cmds\n nsenter -n -t $nodeNs ip link set dev $tmpifc up mtu $mtu"
    } else {
        set cmds "$cmds\n nsenter -n -t $nodeNs ip link set dev $tmpifc mtu $mtu"
    }
    }
    exec sh << $cmds
}
# modification for namespace by adding new function
# activate all interface and give a mtu to namespace node using ip netns
proc startIfcsNodeN { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    set node_id1 "$eid.$node"
    set cmds ""
    foreach ifc [allIfcList $node] {
    set mtu [getIfcMTU $node $ifc]
    set tmpifc $ifc
    if { $ifc == "lo0" } {
        set tmpifc lo
    }
    if {[getIfcOperState $node $ifc] == "up"} {
        set cmds "$cmds\n ip netns exec $node_id1 ip link set dev $tmpifc up mtu $mtu"
    } else {
        set cmds "$cmds\n ip netns exec $node_id1  ip link set dev $tmpifc mtu $mtu"
    }
    }

    exec sh << $cmds
}


proc removeExperimentContainer { eid widget } {}

proc removeNodeContainer { eid node } {
    set node_id $eid.$node

    catch "exec docker kill $node_id"
    catch "exec docker rm $node_id"
}

proc killAllNodeProcesses { eid node } {
    set node_id "$eid.$node"

    catch "exec docker exec $node_id killall5 -o 1 -9"
}

proc destroyVirtNodeIfcs { eid vimages } {}

proc runConfOnNode { node } {

    upvar 0 ::cf::[set ::curcfg]::eid eid
    global execMode

    set node_dir [getVrootDir]/$eid/$node
    set node_id "$eid.$node"

    catch {exec docker exec $node_id umount /etc/resolv.conf /etc/hosts}

    if { [getCustomEnabled $node] == true } {
        set selected [getCustomConfigSelected $node]

        set bootcmd [getCustomConfigCommand $node $selected]
        set bootcfg [getCustomConfig $node $selected]
        set confFile "custom.conf"
    } else {

        set bootcfg [[typemodel $node].cfggen $node]
        set bootcmd [[typemodel $node].bootcmd $node]
        set confFile "boot.conf"
        
    }
   

    # change all occurrences of "dev lo0" to "dev lo"
    regsub -all {dev lo0} $bootcfg {dev lo} bootcfg

    writeDataToFile $node_dir/$confFile [join "{ip a flush dev lo} $bootcfg" "\n"]

    exec docker exec -i $node_id sh -c "cat > /$confFile" < $node_dir/$confFile
    exec echo "LOG START" > $node_dir/out.log
    catch {exec docker exec --tty $node_id $bootcmd /$confFile >>& $node_dir/out.log} err
    if { $err != "" } {
    if { $execMode != "batch" } {
        after idle {.dialog1.msg configure -wraplength 4i}
        tk_dialog .dialog1 "IMUNES warning" \
        "There was a problem with configuring the node [getNodeName $node] ($node_id).\nCheck its /$confFile and /out.log files." \
        info 0 Dismiss
    } else {
        puts "IMUNES warning"
        puts "\nThere was a problem with configuring the node [getNodeName $node] ($node_id).\nCheck its /$confFile and /out.log files."
    }
    }
    exec docker exec -i $node_id sh -c "cat > /out.log" < $node_dir/out.log

    set nodeNs [getNodeNamespace $node]
    foreach ifc [allIfcList $node] {
    if {[getIfcOperState $node $ifc] == "down"} {
        set tmpifc $ifc
        if { $ifc == "lo0" } {
        set ifc lo
        }
        exec nsenter -n -t $nodeNs ip link set dev $ifc down
    }
    }

    generateHostsFile $node
}

# modification for namespace by adding new function
# run configuration on namespace node
proc runConfOnNodeN { node } {


    upvar 0 ::cf::[set ::curcfg]::eid eid
    global execMode
    set node_id1 "$eid.$node"
    catch "exec ip netns exec $node_id1 ip a flush dev lo"
    set bootcfg [[typemodel $node].cfggen $node]
    foreach {commande} $bootcfg {
     if {$commande != ""} {
		catch "exec ip netns exec $node_id1 $commande"
     } 
    }

}

# modification for cisco router by adding new function
# edit topologie.net file of dynamips
proc runConfOnNodeR { node } {
set curdir [pwd]
global dynacurdir RouterCisco
upvar 0 ::cf::[set ::curcfg]::eid eid

verifierFichier_Dynamips $node

#Configuration dynamips

if {[file exist "$dynacurdir/Dynamips/$eid/lab/topologie.net"] == 1} {
    set id_file1 [open "$dynacurdir/Dynamips/$eid/node/$node.txt"]
    set fileData [read $id_file1]
    set filelines [split $fileData "\n"]
    

    foreach line $filelines {
       set fp [open "$dynacurdir/Dynamips/$eid/lab/topologie.net" a]
       puts $fp "$line"
       close $fp

    }

}
#Configuration file routeur cisco
if { $RouterCisco != "" } {

# c'est à dire qu'on a fait un open file qui exist
# On crée le fichier de configuration
	if {[file exist "$dynacurdir/Dynamips/$eid/configuration/$node.txt"] != 1} {
                set fp [open "$dynacurdir/Dynamips/$eid/configuration/$node.txt" w+]
                upvar 0 ::cf::[set ::curcfg]::$node $node
                set netconf [lindex [lsearch -inline [set $node] "network-config *"] 1]
                foreach entry $netconf {
                # je vérifier si c'est une adresse ipv4 alors je convert cidr to subnet mask
                        if { [lindex $entry 0] == "ip" && [lindex $entry 1] == "address"} {
                                set address [lindex $entry 2]
                                set address [split $address "/"]
                                set ipv4 [lindex $address 0]
				set mask [lindex $address 1]
                                set mask [cidr2dec $mask]
                                set entry "ip address $ipv4 $mask"

			} 
                       if { [lindex $entry 0] == "interface" && [lindex $entry 1] == "lo0"} {

                                set entry "interface Loopback0"

			} 
                       
                      
			puts $fp $entry
                      
    		}
               close $fp
	}

} elseif {[file exist "$dynacurdir/Dynamips/$eid/configuration/$node.txt"] != 1} {
                set fp [open "$dynacurdir/Dynamips/$eid/configuration/$node.txt" w+]
                set name [getNodeName $node]
                puts $fp "hostname $name\n!\n"

		foreach ifc [allIfcList $node] {
		
			set ip [getIfcIPv4addr $node $ifc]
                        set ip [split $ip "/"]
                        set ip4 [lindex $ip 0]
                        set mask [lindex $ip 1]
                        puts $ip
                        set mask [cidr2dec $mask]
			set ip6 [getIfcIPv6addr $node $ifc]
                        if {$ifc == "lo0"} {
			set ifc "Loopback0"
			}
                        puts $fp "interface $ifc"
			#je rajoute apres mac
			puts $fp " ip address $ip4 $mask\n"
                        puts $fp " ipv6 address $ip6\n"
                        puts $fp " no shutdown\n!\n"
                        					
		}

               close $fp

}
# Modification for dynamips 

    prepareDynamips $eid  

}

#Modification for dynamips
proc prepareDynamips { eid } {

    global dynacurdir

    catch "exec pkill -9 dynamips"
    catch "exec pkill -9 dynagen"
    catch "exec /usr/bin/dynamips -H 7200 &"
    catch "exec /usr/bin/dynagen $dynacurdir/Dynamips/$eid/lab/topologie.net &"

}



proc destroyLinkBetween { eid lnode1 lnode2 } {
    set ifname1 [ifcByLogicalPeer $lnode1 $lnode2]
    catch {exec ip link del dev $eid-$lnode1-$ifname1}
}

#****f* linux.tcl/removeNodeIfcIPaddrs
# NAME
#   removeNodeIfcIPaddrs -- remove node iterfaces' IP addresses
# SYNOPSIS
#   removeNodeIfcIPaddrs $eid $node
# FUNCTION
#   Remove all IPv4 and IPv6 addresses from interfaces on the given node.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc removeNodeIfcIPaddrs { eid node } {
    set node_id "$eid.$node"
    foreach ifc [allIfcList $node] {
    catch "exec docker exec $node_id ip addr flush dev $ifc"
    }
}

proc removeExperimentContainer { eid widget } {
    set VROOT_BASE [getVrootDir]
    catch "exec rm -fr $VROOT_BASE/$eid &"
}

proc createNetgraphNode { eid node } {
    catch {exec ovs-vsctl add-br $eid-$node}
    catch {exec ovs-vsctl set bridge $eid-$node stp_enable=true}
}

proc destroyNetgraphNode { eid node } {
    catch {exec ovs-vsctl del-br $eid-$node}
}

proc destroyNetgraphNodes { eid switches widget } {
    global execMode

    # destroying openvswitch nodes
    if { $switches != "" } {
        statline "Shutting down netgraph nodes..."
        set i 0
        foreach node $switches {
            incr i
            # statline "Shutting down openvswitch node $node ([typemodel $node])"
            [typemodel $node].destroy $eid $node
            if {$execMode != "batch"} {
                $widget.p step -1
            }
            displayBatchProgress $i [ llength $switches ]
        }
        statline ""
    }
}

#****f* linux.tcl/getCpuCount
# NAME
#   getCpuCount -- get CPU count
# SYNOPSIS
#   getCpuCount
# FUNCTION
#   Gets a CPU count of the host machine.
# RESULT
#   * cpucount - CPU count
#****
proc getCpuCount {} {
    return [lindex [exec grep -c processor /proc/cpuinfo] 0]
}

#****f* linux.tcl/l2node.instantiate
# NAME
#   l2node.instantiate -- instantiate
# SYNOPSIS
#   l2node.instantiate $eid $node
# FUNCTION
#   Procedure l2node.instantiate creates a new netgraph node of the appropriate type.
# INPUTS
#   * eid -- experiment id
#   * node -- id of the node (type of the node is either lanswitch or hub)
#****
proc l2node.instantiate { eid node } {
    createNetgraphNode $eid $node
    #modification for openvswitch
    #catch "exec ip netns add $eid-$node"
}

#****f* linux.tcl/l2node.destroy
# NAME
#   l2node.destroy -- destroy
# SYNOPSIS
#   l2node.destroy $eid $node
# FUNCTION
#   Destroys a l2 node.
# INPUTS
#   * eid -- experiment id
#   * node -- id of the node
#****
proc l2node.destroy { eid node } {
    destroyNetgraphNode $eid $node
}

#****f* linux.tcl/enableIPforwarding
# NAME
#   enableIPforwarding -- enable IP forwarding
# SYNOPSIS
#   enableIPforwarding $eid $node
# FUNCTION
#   Enables IPv4 and IPv6 forwarding on the given node.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc enableIPforwarding { eid node } {
    array set sysctl_ipfwd {
    net.ipv6.conf.all.forwarding    1
    net.ipv4.conf.all.forwarding    1
    net.ipv4.conf.default.rp_filter 0
    net.ipv4.conf.all.rp_filter 0
    }

    foreach {name val} [array get sysctl_ipfwd] {
    lappend cmd "sysctl $name=$val"
    }
    set cmds [join $cmd "; "]

    pipesExec "docker exec $eid.$node sh -c \'$cmds\'" "hold"
}

#****f* linux.tcl/configDefaultLoIfc
# NAME
#   configDefaultLoIfc -- configure default logical interface
# SYNOPSIS
#   configDefaultLoIfc $eid $node
# FUNCTION
#   Configures the default logical interface address for the given node.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc configDefaultLoIfc { eid node } {
    pipesExec "docker exec $eid\.$node ifconfig lo 127.0.0.1/8" "hold"
}

#****f* linux.tcl/getExtIfcs
# NAME
#   getExtIfcs -- get external interfaces
# SYNOPSIS
#   getExtIfcs
# FUNCTION
#   Returns the list of all available external interfaces except those defined
#   in the ignore loop.
# RESULT
#   * ifsc - list of interfaces
#****
proc getExtIfcs { } {
    catch { exec ls /sys/class/net } ifcs
    foreach ignore "lo* ipfw* tun*" {
        set ifcs [ lsearch -all -inline -not $ifcs $ignore ]
    }
    return "$ifcs"
}

#****f* linux.tcl/captureExtIfc
# NAME
#   captureExtIfc -- capture external interfaces
# SYNOPSIS
#   captureExtIfc $eid $node
# FUNCTION
#   Captures the external interfaces given by the given rj45 node.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc captureExtIfc { eid node } {
    set ifname [getNodeName $node]
    createNetgraphNode $eid $node
    catch {exec ovs-vsctl add-port $eid-$node $ifname}
}

#****f* linux.tcl/releaseExtIfc
# NAME
#   releaseExtIfc -- release external interfaces
# SYNOPSIS
#   releaseExtIfc $eid $node
# FUNCTION
#   Releases the external interfaces captured by the given rj45 node.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc releaseExtIfc { eid node } {
    catch "destroyNetgraphNode $eid $node"
}

proc getIPv4RouteCmd { statrte } {
    set route [lindex $statrte 0]
    set addr [lindex $statrte 1]
    set cmd "ip route add $route via $addr"

    return $cmd
}

proc getIPv6RouteCmd { statrte } {
    set route [lindex $statrte 0]
    set addr [lindex $statrte 1]
    if {$route == "::/0"} {
        set cmd "ip -6 route add $route via $addr"
    } else {
        set cmd "ip -6 route add default via $addr"
    }
    return $cmd
}

proc getIPv4IfcCmd { ifc addr primary } {
    return "ip addr add $addr dev $ifc"
}

proc getIPv6IfcCmd { ifc addr primary } {
    return "ip -6 addr add $addr dev $ifc"
}

#****f* linux.tcl/getRunningNodeIfcList
# NAME
#   getRunningNodeIfcList -- get interfaces list from the node
# SYNOPSIS
#   getRunningNodeIfcList $node
# FUNCTION
#   Returns the list of all network interfaces for the given node.
# INPUTS
#   * node -- node id
# RESULT
#   * list -- list in the form of {netgraph_node_name hook}
#****
proc getRunningNodeIfcList { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    catch {exec docker exec $eid.$node ifconfig} full
    set lines [split $full "\n"]

    return $lines
}

proc hub.start { eid node } {
    set node_id "$eid-$node"
    catch {exec ovs-vsctl list-ports $node_id} ports
    foreach port $ports {
        catch {exec ovs-vsctl -- add bridge $node_id mirrors @m \
        -- --id=@p get port $port \
        -- --id=@m create mirror name=$port select-all=true output-port=@p}
    }
}

proc getNodeNamespace { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set node_id "$eid.$node"
    catch {exec docker inspect -f "{{.State.Pid}}" $node_id} ns
    return $ns
}

proc addNodeIfcToBridge { bridge brifc node ifc mac } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set nodeNs [createNetNs $node]

    # create bridge
    catch "exec ovs-vsctl add-br $eid-$bridge"
    catch "exec ovs-vsctl set bridge $eid-$bridge stp_enable=true"


    # generate interface names
    set hostIfc "$eid-$bridge-$brifc"
    set guestIfc "$eid-$node-$ifc"

    # create veth pair
    exec ip link add name "$hostIfc" type veth peer name "$guestIfc"

    # add host side of veth pair to bridge
    catch "exec ovs-vsctl add-port $eid-$bridge $hostIfc"

    exec ip link set "$hostIfc" up

    # move guest side of veth pair to node namespace
    setIfcNetNs $node $guestIfc $ifc
    # set mac address
    exec nsenter -n -t $nodeNs ip link set dev "$ifc" address "$mac"
    # delete net namespace reference file
    exec ip netns del $nodeNs
}


# modification for wifiap by adding new function
# this function connect wifiap node with bridge
proc addNodeIfcToBridgeAP { bridge brifc node ifc mac } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    set node_id1 "$eid.$node"
    set adresse [getIfcIPv4addr $node $ifc]

    # generate interface names
       set hostIfc "$eid-$bridge-$brifc"
     #  set hostIfc2 "veth.$ifc.$node.$eid"
       set hostIfc2 "$eid-$ifc-$node"
    # create veth pair  (delete it first if it exists)
    catch "exec ip link del $hostIfc"
    exec ip link add name "$hostIfc" type veth peer name "$hostIfc2"

   # create bridge

    catch "exec ovs-vsctl add-br $eid-$bridge"
    catch "exec ovs-vsctl set bridge $eid-$bridge stp_enable=true"

  # add host side of veth pair to bridge
    catch "exec ovs-vsctl add-port $eid-$bridge $hostIfc"

    exec ip link set "$hostIfc" up


    exec ip link set "$hostIfc2" netns $node_id1  
     #wifiap
        catch "exec ip netns exec $node_id1 ip link set $hostIfc2 name $ifc"

       # MAC address wifiap

        catch "exec ip netns exec $node_id1 ip link set $ifc address $mac"
      # catch "exec ip netns exec $node ip addr add $adresse dev $ifc"
        catch "exec ip netns exec $node_id1 ip link set $ifc up"       


}
# modification for namespace by adding new function
# this function connect namespace node with bridge
proc addNodeIfcToBridgeN { bridge brifc node ifc mac } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    set node_id1 "$eid.$node"
    set adresse [getIfcIPv4addr $node $ifc]

    # generate interface names
       set hostIfc "$eid-$bridge-$brifc"
     #  set hostIfc2 "veth.$ifc.$node.$eid"
       set hostIfc2 "$eid-$ifc-$node"
    # create veth pair  (delete it first if it exists)
    catch "exec ip link del $hostIfc"
    exec ip link add name "$hostIfc" type veth peer name "$hostIfc2"

   # create bridge

    catch "exec ovs-vsctl add-br $eid-$bridge"
    catch "exec ovs-vsctl set bridge $eid-$bridge stp_enable=true"

  # add host side of veth pair to bridge
    catch "exec ovs-vsctl add-port $eid-$bridge $hostIfc"

    exec ip link set "$hostIfc" up


    exec ip link set "$hostIfc2" netns $node_id1  
#nouveau pc
        catch "exec ip netns exec $node_id1 ip link set $hostIfc2 name $ifc"

       # MAC address Namespace

       catch "exec ip netns exec $node_id1 ip link set $ifc address $mac"
   #     catch "exec ip netns exec $node ip addr add $adresse dev $ifc"
        catch "exec ip netns exec $node_id1 ip link set $ifc up"       
    #    catch "exec ip netns exec $node ip -6 addr add ::1/128 dev lo"       
    #    catch "exec ip netns exec $node ip -6 addr add fc00:1::10/64 dev $ifc"










}

# modification for cisco router by adding new function
# this function connect cisco router with bridge

proc addNodeIfcToBridgeR { bridge brifc node ifc } {

   set curdir [pwd]
   global dynacurdir

    upvar 0 ::cf::[set ::curcfg]::eid eid

    set adresse [getIfcIPv4addr $node $ifc]

    # generate interface names
       set hostIfc "$eid-$bridge-$brifc"
    #interface dynamips   
       #set hostIfc2 "veth.$bridge.$node.$eid"
       set hostIfc2 "$eid-$bridge-$node"
    # create veth pair
        #exec ip link del $hostIfc2


catch "exec ip link add name $hostIfc type veth peer name $hostIfc2"

    exec ip link set dev $hostIfc2 up
    verifierFichier_Dynamips $node
    
    set fp [open "$dynacurdir/Dynamips/$eid/node/$node.txt" a]
    puts $fp "$ifc = NIO_linux_eth:$hostIfc2"
    close $fp

   # create bridge

    catch "exec ovs-vsctl add-br $eid-$bridge"
    catch "exec ovs-vsctl set bridge $eid-$bridge stp_enable=true"

  # add host side of veth pair to bridge
    catch "exec ovs-vsctl add-port $eid-$bridge $hostIfc"

    exec ip link set "$hostIfc" up


}



proc checkSysPrerequisites {} {
    set msg ""
    if { [catch {exec docker ps } err] } {
        set msg "Cannot start experiment. Is docker installed and running (check the output of 'docker ps')?\n"
    }

    if { [catch {exec pgrep ovs-vswitchd } err ] } {
        set msg "Cannot start experiment. Is ovs-vswitchd installed and running (check the output of 'pgrep ovs-vswitchd')?\n"
    }

    if { [catch {exec nsenter --version}] } {
        set msg "Cannot start experiment. Is nsenter installed (check the output of 'nsenter --version')?\n"
    }

    if { [catch {exec xterm -version}] } {
        set msg "Cannot start experiment. Is xterm installed (check the output of 'xterm -version')?\n"
    }

    if { $msg != "" } {
        return "$msg\nIMUNES needs docker and ovs-vswitchd services running and\
xterm and nsenter installed."
    }

    return ""
}

proc createNetNs { node } {
    set nodeNs [getNodeNamespace $node]
    exec rm -f "/var/run/netns/$nodeNs"
    exec ln -s "/proc/$nodeNs/ns/net" "/var/run/netns/$nodeNs"
    return $nodeNs
}

proc setIfcNetNs { node oldIfc newIfc } {
    set nodeNs [getNodeNamespace $node]
    exec ip link set "$oldIfc" netns "$nodeNs"
  
    exec nsenter -n -t $nodeNs ip link set "$oldIfc" name "$newIfc"

}

#****f* linux.tcl/execSetIfcQDisc
# NAME
#   execSetIfcQDisc -- in exec mode set interface queuing discipline
# SYNOPSIS
#   execSetIfcQDisc $eid $node $ifc $qdisc
# FUNCTION
#   Sets the queuing discipline during the simulation.
#   New queuing discipline is defined in qdisc parameter.
#   Queueing discipline can be set to fifo, wfq or drr.
# INPUTS
#   eid -- experiment id
#   node -- node id
#   ifc -- interface name
#   qdisc -- queuing discipline
#****
proc execSetIfcQDisc { eid node ifc qdisc } {
    set target [linkByIfc $node $ifc]
    set peers [linkPeers [lindex $target 0]]
    set dir [lindex $target 1]
    set lnode1 [lindex $peers 0]
    set lnode2 [lindex $peers 1]
    if { [nodeType $lnode2] == "pseudo" } {
        set mirror_link [getLinkMirror [lindex $target 0]]
        set lnode2 [lindex [linkPeers $mirror_link] 0]
    }
    switch -exact $qdisc {
        FIFO { set qdisc fifo_fast }
        WFQ { set qdisc wfq }
        DRR { set qdisc drr }
    }
    exec docker exec $eid.$node tc qdisc add dev $ifc root $qdisc
}

proc getNetemConfigLine { bandwidth delay loss dup } {
    array set netem {
    bandwidth "rate Xbit"
    loss      "loss random X%"
    delay     "delay Xus"
    dup       "duplicate X%"
    }
    set cmd ""

    foreach { val ctemplate } [array get netem] {
    if { [set $val] != 0 } {
        set confline "[lindex [split $ctemplate "X"] 0][set $val][lindex [split $ctemplate "X"] 1]"
        append cmd " $confline"
    }
    }

    return $cmd
}

proc configureIfcLinkParams { eid node ifname bandwidth delay ber dup } {
    global debug

    if {[nodeType $node] == "rj45"} {
        set lname [getNodeName $node]
    } else {
        set lname $node
    }

    # average packet size in the Internet is 576 bytes
    # XXX: maybe migrate to PER (packet error rate), on FreeBSD we calculate
    # BER with the magic number 576 and on Linux we take the value directly
    if { $ber != 0 } {
    set loss [expr (1 / double($ber)) * 576 * 8 * 100]
    if { $loss > 100 } {
        set loss 100
    }
    } else {
    set loss 0
    }

    if { [[typemodel $node].virtlayer] == "NETGRAPH" } {
        catch {exec tc qdisc del dev $eid-$lname-$ifname root}
    # XXX: currently we have loss, but we can easily have
    # corrupt, add a tickbox to GUI, default behaviour
    # should be loss because we don't do corrupt on FreeBSD
    # set confstring "netem corrupt ${loss}%"
    # corrupt ${loss}%
    set cmd "tc qdisc add dev $eid-$lname-$ifname root netem"
    catch {
        eval exec $cmd [getNetemConfigLine $bandwidth $delay $loss $dup]
    } err

    if { $debug && $err != "" } {
        puts stderr "tc ERROR: $eid-$lname-$ifname, $err"
        puts stderr "gui settings: bw $bandwidth loss $loss delay $delay dup $dup"
        catch { exec tc qdisc show dev $eid-$lname-$ifname } status
        puts stderr $status
    }
    }
    if { [[typemodel $node].virtlayer] == "VIMAGE" } {
        set nodeNs [getNodeNamespace $node]
        catch {exec nsenter -n -t $nodeNs tc qdisc del dev $ifname root}

    # XXX: same as the above
    set cmd "nsenter -n -t $nodeNs tc qdisc add dev $ifname root netem"
    eval exec $cmd [getNetemConfigLine $bandwidth $delay $loss $dup]
    }

    # XXX: Now on Linux we don't care about queue lengths and we don't limit
    # maximum data and burst size.
    # in the future we can use something like this: (based on the qlen
    # parameter)
    # set confstring "tbf rate ${bandwidth}bit limit 10mb burst 1540"
}

#****f* linux.tcl/execSetLinkParams
# NAME
#   execSetLinkParams -- in exec mode set link parameters
# SYNOPSIS
#   execSetLinkParams $eid $link
# FUNCTION
#   Sets the link parameters during the simulation.
#   All the parameters are set at the same time.
# INPUTS
#   eid -- experiment id
#   link -- link id
#****
proc execSetLinkParams { eid link } {
    global debug

    set lnode1 [lindex [linkPeers $link] 0]
    set lnode2 [lindex [linkPeers $link] 1]
    set ifname1 [ifcByLogicalPeer $lnode1 $lnode2]
    set ifname2 [ifcByLogicalPeer $lnode2 $lnode1]

    if { [getLinkMirror $link] != "" } {
    set mirror_link [getLinkMirror $link]
    if { [nodeType $lnode1] == "pseudo" } {
        set p_lnode1 $lnode1
        set lnode1 [lindex [linkPeers $mirror_link] 0]
        set ifname1 [ifcByPeer $lnode1 [getNodeMirror $p_lnode1]]
    } else {
        set p_lnode2 $lnode2
        set lnode2 [lindex [linkPeers $mirror_link] 0]
        set ifname2 [ifcByPeer $lnode2 [getNodeMirror $p_lnode2]]
    }
    }

    set bandwidth [expr [getLinkBandwidth $link] + 0]
    set delay [expr [getLinkDelay $link] + 0]
    set ber [expr [getLinkBER $link] + 0]
    set dup [expr [getLinkDup $link] + 0]

    configureIfcLinkParams $eid $lnode1 $ifname1 $bandwidth $delay $ber $dup
    configureIfcLinkParams $eid $lnode2 $ifname2 $bandwidth $delay $ber $dup
}

proc ipsecFilesToNode { node local_cert ipsecret_file } {
    global ipsecConf ipsecSecrets

    if { $local_cert != "" } {
    set trimmed_local_cert [lindex [split $local_cert /] end]
    set fileId [open $trimmed_local_cert "r"]
    set trimmed_local_cert_data [read $fileId]
    writeDataToNodeFile $node /etc/ipsec.d/certs/$trimmed_local_cert $trimmed_local_cert_data
    close $fileId
    }

    if { $ipsecret_file != "" } {
    set trimmed_local_key [lindex [split $ipsecret_file /] end]
    set fileId [open $trimmed_local_key "r"]
    set trimmed_local_key_data "# /etc/ipsec.secrets - strongSwan IPsec secrets file\n"
    set trimmed_local_key_data "$trimmed_local_key_data[read $fileId]\n"
    set trimmed_local_key_data "$trimmed_local_key_data: RSA $trimmed_local_key"
    writeDataToNodeFile $node /etc/ipsec.d/private/$trimmed_local_key $trimmed_local_key_data
    close $fileId
    }

    writeDataToNodeFile $node /etc/ipsec.conf $ipsecConf
    writeDataToNodeFile $node /etc/ipsec.secrets $ipsecSecrets
}

proc sshServiceStartCmds {} {
    lappend cmds "dpkg-reconfigure openssh-server"
    lappend cmds "service ssh start"
    return $cmds
}

proc sshServiceStopCmds {} {
    return {"service ssh stop"}
}

proc inetdServiceRestartCmds {} {
    return "service openbsd-inetd restart"
}

proc moveFileFromNode { node path ext_path } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    catch {exec hcp [getNodeName $node]@$eid:$path $ext_path}
    catch {exec docker exec $eid.$node rm -fr $path}
}

# XXX NAT64 procedures
proc createStartTunIfc { eid node } {
    # create and start tun interface and return its name
    exec docker exec -i $eid.$node ip tuntap add mode tun
    catch "exec docker exec $eid.$node ip l | grep tun | tail -n1 | cut -d: -f2" tun
    set tun [string trim $tun]
    exec docker exec -i $eid.$node ip l set $tun up

    return $tun
}

proc prepareTaygaConf { eid node data datadir } {
    exec docker exec -i $eid.$node mkdir -p $datadir
    writeDataToNodeFile $node "/etc/tayga.conf" $data
}

proc taygaShutdown { eid node } {
    catch "exec docker exec $eid.$node killall5 -9 tayga"
    exec docker exec $eid.$node rm -rf /var/db/tayga
}

proc taygaDestroy { eid node } {
    global nat64ifc_$eid.$node
    catch {exec docker exec $eid.$node ip l delete [set nat64ifc_$eid.$node]}
}

# XXX External connection procedures
proc extInstantiate { node } {
}

proc startExternalIfc { eid node } {
    set cmds ""
    set ifc [lindex [ifcList $node] 0]
    set outifc "$eid-$node"

    set ether [getIfcMACaddr $node $ifc]
    if {$ether == ""} {
       autoMACaddr $node $ifc
    }
    set ether [getIfcMACaddr $node $ifc]
    set cmds "ip l set $outifc address $ether"

    set cmds "$cmds\n ip a flush dev $outifc"

    set ipv4 [getIfcIPv4addr $node $ifc]
    if {$ipv4 == ""} {
       autoIPv4addr $node $ifc


    }
    set ipv4 [getIfcIPv4addr $node $ifc]
    set cmds "$cmds\n ip a add $ipv4 dev $outifc"
    

    set ipv6 [getIfcIPv6addr $node $ifc]
    if {$ipv6 == ""} {
       autoIPv6addr $node $ifc
    }
    set ipv6 [getIfcIPv6addr $node $ifc]
    set cmds "$cmds\n ip a add $ipv6 dev $outifc"

    set cmds "$cmds\n ip l set $outifc up"

    exec sh << $cmds &
}

proc  stopExternalIfc { eid node } {
    exec ip l set $eid-$node down
}

proc destroyExtInterface { eid node } {
    destroyNetgraphNode $eid $node
}

#****f* linux.tcl/configureVlanSwitch
# modification for VLAN
# NAME
#   configureVlanSwitch
# SYNOPSIS
#   configureVlanSwitch $eid $ifc
# FUNCTION
#  Configuration all Vlan 
proc configureVlanSwitch { eid node} {

global listVlan 
lappend listVlan ""


	foreach element $listVlan {

                set Mynode [lindex $element 0]
                set Mynode [split $Mynode "-"]
                set Mynode [lindex $Mynode 0]

if {$node == $Mynode} {
                set enable [lindex $element 1]

		if { $enable == 1 } {

                				set Mymode [lindex $element 3]
                                set Myport [lindex $element 0]
								set Mytag [lindex $element 2]
								set Myinterface [lindex $element 4]
								set Myrange [lindex $element 5]

                                if {$Mymode != "No-mode"} {

                                     catch "exec ovs-vsctl set port $eid-$Myport vlan_mode=$Mymode"

                                } 
                                if {$Mytag != "No-tag"} {

                                     catch "exec ovs-vsctl set port $eid-$Myport tag=$Mytag"				
				                }
                                if {$Myinterface != "No-interface"} {

                                     catch "exec ovs-vsctl set interface $eid-$Myport type=$Myinterface"				
				                  }
                                if {$Myrange != "No-range"} {
				                       if {$Mymode == "dot1q-tunnel"} {

                                     catch "exec ovs-vsctl set port $eid-$Myport cvlans=$Myrange"
					                    } else {

                                     catch "exec ovs-vsctl set port $eid-$Myport trunks=$Myrange"
				                        }				
				                 }
					
			                } elseif { $enable == 0 } {

                				set Mymode [lindex $element 3]
                                set Myport [lindex $element 0]
								set Mytag [lindex $element 2]
								set Myinterface [lindex $element 4]
								set Myrange [lindex $element 5]

                                if {$Mymode != "No-mode"} {

                                     catch "exec ovs-vsctl remove port $eid-$Myport vlan_mode $Mymode"

                                } 
                                if {$Mytag != "No-tag"} {

                                     catch "exec ovs-vsctl remove port $eid-$Myport tag $Mytag"				
				                }
                                if {$Myinterface != "No-interface"} {

                                     catch "exec ovs-vsctl set interface $eid-$Myport type=system"				
				                  }
                                if {$Myrange != "No-range"} {
				                       if {$Mymode == "dot1q-tunnel"} {

                                     catch "exec ovs-vsctl remove port $eid-$Myport cvlans $Myrange"
					                    } else {

                                     catch "exec ovs-vsctl remove port $eid-$Myport trunks $Myrange"
				                        }				
				                 }



					#fin if2
					}
					#fin if1
					}
		#fin foreach			
		}


}



