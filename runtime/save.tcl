# 2019-2020 Sorbonne University
# In this version of imunes we added a full integration of emulation of 
# Linux namespaces and CISCO routers, saving of parameters, VLANs, WiFi 
# emulation and other features
# This work was developed by Benadji Hanane and Oulad Said Chawki
# Supervised and maintained by Naceur Malouch - LIP6/SU
#
#*****************************************************************************
# Appliquer les modifications du batch dans l'interface Pour la Sauvegarde 
#*****************************************************************************







#****f* save.tcl/ApplyBatchToGUI
# NAME
#   ApplyBatchToGUI
# SYNOPSIS
#   ApplyBatchToGUI
# FUNCTION
#   Procedure to save the batch modifications
#****


proc ApplyBatchToGUI { } {
   


   upvar 0 ::cf::[set ::curcfg]::node_list node_list
   upvar 0 ::cf::[set ::curcfg]::eid eid 
   upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
   
   # browse the nodes
   foreach node $node_list {
            



	    set type [nodeType $node]

            # Save the batch modifications for the PC docker
	    if { $type == "pc" && $oper_mode == "exec" } {

			# Get the id (pid) of docker pc namespaces
			catch {exec docker inspect -f "{{.State.Pid}}" $eid.$node} fast

		#**************************************		
		# Change the hostname
		#**************************************
			catch {set nomhote [ exec nsenter -u -t $fast hostname ]
					setNodeName $node $nomhote }
				
		#**************************************		
		# Change ip address in the interface
		#**************************************
			foreach ifc [ifcList $node] {			
				# retrive ip address

				set netconf ""

				catch { set netconf [exec nsenter -n -t $fast ifconfig $ifc | grep inet ] }

			
				if { $netconf != "" } {

					regexp { [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ } $netconf ip
					set ipx [string trim $ip]

				}
				
				#retrive mask address
				set mask ""
				catch { set mask [exec nsenter -n -t $fast ifconfig $ifc | grep netmask ] }


				if { $mask != "" } {
                                    set mask1 [lindex $mask 3]

				    set binairemask [dec2bin $mask1]
				   
			            set num [cidr $binairemask]
                                    
			         }
			     
			       #Show address on link
			       if {$netconf != 0 && $mask != "" } { 
					 set var "$ipx/$num"
					 setIfcIPv4addr $node $ifc "$var" 
				} 

                                # Add the MAC address in .imn file

			
				set macconf ""
				set MAC ""
				catch { set macconf [exec nsenter -n -t $fast ifconfig $ifc | grep ether | cut -c15-32 		     	  					] }							
				if { $macconf != "" } {
                              
					set MAC [string trim $macconf]

			        
					setIfcMACaddr $node $ifc $MAC
					
				}
 
				#Retrive and show ipv6 address on link
                set netconfpcd ""
				catch { set netconfpcd [exec nsenter -n -t $fast ifconfig $ifc | grep global ] }
				set listconfpcd [split $netconfpcd "\n"]
				set listconfpcd1 [split $listconfpcd " "]
				set ipv6pcd [lindex $listconfpcd1 9]
				set prefixpcd [lindex $listconfpcd1 12]
				set varpcd "$ipv6pcd/$prefixpcd"
				setIfcIPv6addr $node $ifc "$varpcd"

			}
				# Retrive the default route IPv4
			        set res ""
			        catch { set res [ exec nsenter -n -t $fast netstat -nr | grep  ^0.0.0.0] }
			        if { $res != "" } {
				catch {regexp { [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ } $res val}
			        #retirer les espaces
				set addr [string trim $val]
		         	#modifier la section de la route dans le fichier
				set section {}
				set defaut "0.0.0.0/0"
				set RouteDef "$defaut $addr"
			        #Ressembre à setStatIPv4routes $node $RouteDef
				netconfClearSection $node "ip route [lindex [getStatIPv4routes $node] 0]"
				lappend section "ip route $RouteDef"
				netconfInsertSection $node $section }	


				# Retrive the default route IPv6
			        set res ""
			        catch { set res [ exec nsenter -n -t $fast ip -6 r show | grep  default] }
			        if { $res != "" } {
				set default [lindex $res 2]
			        #retirer les espaces
				set addr [string trim $default]
		         	#modifier la section de la route dans le fichier
				set section {}
				set defaut "::/0"
				set RouteDef "$defaut $addr"
			        #Ressembre à setStatIPv6routes $node $RouteDef
				netconfClearSection $node "ipv6 route [lindex [getStatIPv6routes $node] 0]"
				lappend section "ipv6 route $RouteDef"
				netconfInsertSection $node $section }
		}



            # Save the batch modifications for the router CISCO
               if { $type == "routeur" && $oper_mode == "exec" } {
		     global dynacurdir addrIPv4 addrIPv6 nom_fichier
                     upvar 0 ::cf::[set ::curcfg]::eid eid
                 
		     #retrieve the name of the router  
		     set fp1 [open "$dynacurdir/Dynamips/$eid/node/$node.txt" r]
		     set records [read $fp1]
		     set lines [split $records "\n"]
		     set identi [lindex $lines 0]
		     set identi1 [split $identi " "]
		     set identi2 [lindex $identi1 1]
		     set identi3 [split $identi2 "]"]
		     set nom_cisco [lindex $identi3 0]
                     

		     set nom_fichier "c7200_$nom_cisco"
		     append nom_fichier "_nvram"

             catch "exec nvram_export $dynacurdir/Dynamips/$eid/lab/$nom_fichier $dynacurdir/Dynamips/$eid/lab/config_routeur_$nom_cisco"
	
	             set confCisco ""
						
                    # Open the configuration file 

            if {[file exist "$dynacurdir/Dynamips/$eid/lab/config_routeur_$nom_cisco"] == 1} {

 		    
	            set fp [open "$dynacurdir/Dynamips/$eid/lab/config_routeur_$nom_cisco" r]
	            set confCisco [read $fp]


       
	      if { $confCisco != "" } {
			set records [split $confCisco "\n"]
                        if { $records != "" } {
                                       netconfClearAllSectionNetwork $node 
                                      
                                       set Mylist ""
	                               foreach element $records {

                                              
						if { [lindex $element 0] == "interface"} {
                                                
                                                     if {[regexp {^[FastEthernet].+\d} [lindex $element 1]] !=0 } {

                                                         set NameInterface [lindex $element 1]
                                                         set NameInterface [regsub "FastEthernet" $NameInterface "f"]
                                                         lappend Mylist "interface $NameInterface"
                                                         
        						} else {

                                                        lappend Mylist $element
						     }
                                                } elseif {[lindex $element 0] == "ip" && [lindex $element 1] == "address"} {

                                                   set mask [lindex $element 3]
                                                   set binairemask [dec2bin $mask]   
						   set masque [cidr $binairemask]
                                                   set ipv4 [lindex $element 2]
                                                   set addr "$ipv4/$masque"
 						   lappend Mylist " ip address $addr"
						} elseif { [lindex $element 0] == "interface" && [lindex $element 1] == "lo0"} {

                                                   lappend Mylist "interface Loopback0"

			                       } else {

                                                   lappend Mylist $element
						}


						
					}
                               netconfInsertSection $node $Mylist

			}

                       
			     
                            
		





	}
} 
}
                        
            # Save Vlan configuration for the lanswitch
              if { $type == "lanswitch" } {
                  global listVlan
                  lappend listVlan ""

			# Parcourir la liste des Vlans
            


			foreach element $listVlan {
                set Mynode [lindex $element 0]
                set Mynode [split $Mynode "-"]
                set Myport [lindex $Mynode 1]
                set Mynode [lindex $Mynode 0]

          if {$node == $Mynode} {

                set section {}
			    netconfClearSection $node "interface $Myport"
                lappend section "interface $Myport"
                set enable [lindex $element 1]
                lappend section " vlan_enable=$enable"
				set Mytag [lindex $element 2]
                lappend section " vlan_tag=$Mytag"
                set Mymode [lindex $element 3]
                lappend section " vlan_mode=$Mymode"
				set Myinterface [lindex $element 4]
                lappend section " Interface_type=$Myinterface"
				set Myrange [lindex $$element 5]
                lappend section " vlan_range=$Myrange"
                lappend section "!" 
 
            #mettre à jour le fichier .imn
			netconfInsertSection $node $section                              

			
		  }
}






			}

            # Save the batch modifications for the PC Namespaces
              if { $type == "pcn" && $oper_mode == "exec"} {

		
				
		#**************************************		
		# changer l'adresse ip de l'interface
		#**************************************
			foreach ifc [ifcList $node] {			
				# retrive ipv4 address
				
				set netconf ""
				catch { set netconf [exec ip netns exec $eid.$node ifconfig $ifc | grep inet ] }	
				
				if { $netconf != "" } {

					regexp { [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ } $netconf ip
					set ipx [string trim $ip]

				}
				
				#retrive mask
				set mask ""
				catch { set mask [exec ip netns exec $eid.$node ifconfig $ifc | grep netmask ] }


				
				if { $mask != "" } {
                                    set mask1 [lindex $mask 3]

				    set binairemask [dec2bin $mask1]
				   
			            set num [cidr $binairemask]
                                    
			     }
			     
			     #change the ip address and show on link
			     if {$netconf != 0 && $mask != "" } { 
					 set var "$ipx/$num"
					 setIfcIPv4addr $node $ifc "$var" 
				}  

                        
                             # Add the MAC address in .imn file

			
				set macconf ""
				set MAC ""
				catch { set macconf [exec ip netns exec $eid.$node ifconfig $ifc | grep ether | cut -c15-32 		     	  					] }							
			      
				if { $macconf != "" } {
                               
					set MAC [string trim $macconf]

			        
					setIfcMACaddr $node $ifc $MAC
					
				}
			
			#retrive the ipv6 address and show on link
			set netconfpc [exec ip netns exec $eid.$node ip addr show $ifc | grep inet6 ] 
			set listconfpc [split $netconfpc "\n"]
			set listconfpc1 [split $listconfpc " "]
			set ipv6pc [lindex $listconfpc1 5]
			set varpc "$ipv6pc"
			setIfcIPv6addr $node $ifc "$varpc"
			}
			


		        # Retrive the default route
			set res ""
			catch { set res [ exec ip netns exec $eid.$node netstat -nr | grep ^0.0.0.0 ] }
			if { $res != "" } {
				catch {regexp { [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ } $res val}
			#retirer les espaces
				set addr [string trim $val]
			#modifier la section de la route dans le fichier
				set section {}
				set defaut "0.0.0.0/0"
				set RouteDef "$defaut $addr"
			#Ressembre à setStatIPv4routes $node $RouteDef
				netconfClearSection $node "ip route [lindex [getStatIPv4routes $node] 0]"
				lappend section "ip route $RouteDef"
				netconfInsertSection $node $section }	

				# Retrive the default route IPv6
			        set res ""
			        catch { set res [ exec ip netns exec $eid.$node ip -6 r show | grep  default] }
			        if { $res != "" } {
				set default [lindex $res 2]
			        #retirer les espaces
				set addr [string trim $default]
		         	#modifier la section de la route dans le fichier
				set section {}
				set defaut "::/0"
				set RouteDef "$defaut $addr"
			        #Ressembre à setStatIPv6routes $node $RouteDef
				netconfClearSection $node "ipv6 route [lindex [getStatIPv6routes $node] 0]"
				lappend section "ipv6 route $RouteDef"
				netconfInsertSection $node $section }
		}

            # Save the batch modifications for the router QUAGGA

		if { $type == "router" && $oper_mode == "exec" } {
			# Get the id (pid) of docker pc namespaces
			catch {exec docker inspect -f "{{.State.Pid}}" $eid.$node} fast	      

			# Retrive the configuration of the router
			set confQuagga ""
						
			catch {set confQuagga [ exec nsenter -m -t $fast \
			     cat /etc/quagga/Quagga.conf ]}

			set records [split $confQuagga "\n"]

			# save the all modifications in the .imn file
			if { $records != "" } {
				netconfClearAllSectionNetwork $node 
				netconfInsertSection $node $records
			}
                       

			set records2 [split $confQuagga "!"]
			# retrive the ipv4/ ipv6 address and show on link
			foreach liste $records2 { 
				set records1 [split $liste "\n"]
				set res3 [lindex $records1 1]
				set res4 [split $res3 " "]
	
				set nom_interface [lindex $res4 1]

				if { [regexp {^[eth].+\d} $nom_interface] != 0  } {
					set taille [llength $records1]
					set ntaille [incr taille -2]
					for {set x $ntaille } {$x > 0} {incr x -1} {
						set li [lindex $records1 $x]
						set ipv [split $li " "]
						set protocole [lindex $ipv 1]
							if { $protocole == "ipv6" } {
								set ipv6addr [lindex $ipv 3]

								set var1 "$ipv6addr"
								setIfcIPv6addr $node "$nom_interface" "$var1"
								break
							}
					}
					for {set x $ntaille} {$x > 0} {incr x -1} {
						set li [lindex $records1 $x]
						set ipv [split $li " "]
						set protocole1 [lindex $ipv 1]
							if { $protocole1 == "ip" } {
								set ipv4addr [lindex $ipv 3]

								set var "$ipv4addr"	
								setIfcIPv4addr $node "$nom_interface" "$var"

								#catch {exec nsenter -n -t $fast ifconfig $ifc $var}	
								
								break
							}
					}
	


				}
		}  

	
			
                        set confQuagga ""
				
                        # Add the hostname in .imn file
			catch {set nomhote [ exec nsenter -u -t $fast hostname ]
			setNodeName $node $nomhote }

                        # Add the MAC address in .imn file

			foreach ifc [ifcList $node] {
				set macconf ""
				set MAC ""
				catch { set macconf [exec nsenter -n -t $fast ifconfig $ifc | grep ether | cut -c15-32 					] }							
			    
				if { $macconf != "" } {
					set MAC [string trim $macconf]
			        
					setIfcMACaddr $node $ifc $MAC
					
				}
			}
	
		}
	}


	redrawAll
	fileSaveDialogBox        
}


#****f* save.tcl/netconfClearAllSectionNetwork
# NAME
#   netconfClearAllSectionNetwork
# SYNOPSIS
#   netconfClearAllSectionNetwork $node
# FUNCTION
#   Clear all configuration of the node
#****

proc netconfClearAllSectionNetwork { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node
    set i [lsearch [set $node] "network-config *"] 
    set $node [lreplace [set $node] $i $i [list network-config { }]]	
}


#SAVE AS

proc ApplyBatchToGUISaveAS { } {
   


   upvar 0 ::cf::[set ::curcfg]::node_list node_list
   upvar 0 ::cf::[set ::curcfg]::eid eid 
   upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
   
   # browse the nodes
   foreach node $node_list {
            



	    set type [nodeType $node]

            # Save the batch modifications for the PC docker
	    if { $type == "pc" && $oper_mode == "exec" } {
			# Get the id (pid) of docker pc namespaces
			catch {exec docker inspect -f "{{.State.Pid}}" $eid.$node} fast

		#**************************************		
		# Change the hostname
		#**************************************
			catch {set nomhote [ exec nsenter -u -t $fast hostname ]
					setNodeName $node $nomhote }
				
		#**************************************		
		# Change ip address in the interface
		#**************************************
			foreach ifc [ifcList $node] {			
				# retrive ip address

				set netconf ""




				catch { set netconf [exec nsenter -n -t $fast ifconfig $ifc | grep inet ] }

			
				if { $netconf != "" } {

					regexp { [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ } $netconf ip
					set ipx [string trim $ip]

				}
				
				#retrive mask address
				set mask ""
				catch { set mask [exec nsenter -n -t $fast ifconfig $ifc | grep netmask ] }


				if { $mask != "" } {
                                    set mask1 [lindex $mask 3]

				    set binairemask [dec2bin $mask1]
				   
			            set num [cidr $binairemask]
                                    
			         }
			     
			       #Show address on link
			       if {$netconf != 0 && $mask != "" } { 
					 set var "$ipx/$num"
					 setIfcIPv4addr $node $ifc "$var" 
				} 

                                # Add the MAC address in .imn file

			
				set macconf ""
				set MAC ""
				catch { set macconf [exec nsenter -n -t $fast ifconfig $ifc | grep ether | cut -c15-32 		     	  					] }							
				if { $macconf != "" } {
                              
					set MAC [string trim $macconf]

			        
					setIfcMACaddr $node $ifc $MAC
					
				}
 
				#Retrive and show ipv6 address on link
                set netconfpcd ""
				catch { set netconfpcd [exec nsenter -n -t $fast ifconfig $ifc | grep global ] }
				set listconfpcd [split $netconfpcd "\n"]
				set listconfpcd1 [split $listconfpcd " "]
				set ipv6pcd [lindex $listconfpcd1 9]
				set prefixpcd [lindex $listconfpcd1 12]
				set varpcd "$ipv6pcd/$prefixpcd"
				setIfcIPv6addr $node $ifc "$varpcd"

			}
				# Retrive the default route IPv4
			        set res ""
			        catch { set res [ exec nsenter -n -t $fast netstat -nr | grep  ^0.0.0.0] }
			        if { $res != "" } {
				catch {regexp { [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ } $res val}
			        #retirer les espaces
				set addr [string trim $val]
		         	#modifier la section de la route dans le fichier
				set section {}
				set defaut "0.0.0.0/0"
				set RouteDef "$defaut $addr"
			        #Ressembre à setStatIPv4routes $node $RouteDef
				netconfClearSection $node "ip route [lindex [getStatIPv4routes $node] 0]"
				lappend section "ip route $RouteDef"
				netconfInsertSection $node $section }	


				# Retrive the default route IPv6
			        set res ""
			        catch { set res [ exec nsenter -n -t $fast ip -6 r show | grep  default] }
			        if { $res != "" } {
				set default [lindex $res 2]
			        #retirer les espaces
				set addr [string trim $default]
		         	#modifier la section de la route dans le fichier
				set section {}
				set defaut "::/0"
				set RouteDef "$defaut $addr"
			        #Ressembre à setStatIPv6routes $node $RouteDef
				netconfClearSection $node "ipv6 route [lindex [getStatIPv6routes $node] 0]"
				lappend section "ipv6 route $RouteDef"
				netconfInsertSection $node $section }
		}



            # Save the batch modifications for the router CISCO
               if { $type == "routeur" && $oper_mode == "exec" } {
		     global dynacurdir addrIPv4 addrIPv6 nom_fichier
                     upvar 0 ::cf::[set ::curcfg]::eid eid
                 
		     #retrieve the name of the router  
		     set fp1 [open "$dynacurdir/Dynamips/$eid/node/$node.txt" r]
		     set records [read $fp1]
		     set lines [split $records "\n"]
		     set identi [lindex $lines 0]
		     set identi1 [split $identi " "]
		     set identi2 [lindex $identi1 1]
		     set identi3 [split $identi2 "]"]
		     set nom_cisco [lindex $identi3 0]
                     

		     set nom_fichier "c7200_$nom_cisco"
		     append nom_fichier "_nvram"

catch "exec nvram_export $dynacurdir/Dynamips/$eid/lab/$nom_fichier $dynacurdir/Dynamips/$eid/lab/config_routeur_$nom_cisco"
	
	             set confCisco ""
						
                    # Open the configuration file 

if {[file exist "$dynacurdir/Dynamips/$eid/lab/config_routeur_$nom_cisco"] == 1} {

 		    
	            set fp [open "$dynacurdir/Dynamips/$eid/lab/config_routeur_$nom_cisco" r]
	            set confCisco [read $fp]


       
	      if { $confCisco != "" } {
			set records [split $confCisco "\n"]
                        if { $records != "" } {
                                       netconfClearAllSectionNetwork $node 
                                      
                                       set Mylist ""
	                               foreach element $records {

                                              
						if { [lindex $element 0] == "interface"} {
                                                
                                                     if {[regexp {^[FastEthernet].+\d} [lindex $element 1]] !=0 } {

                                                         set NameInterface [lindex $element 1]
                                                         set NameInterface [regsub "FastEthernet" $NameInterface "f"]
                                                         lappend Mylist "interface $NameInterface"
                                                         
        						} else {

                                                        lappend Mylist $element
						     }
                                                } elseif {[lindex $element 0] == "ip" && [lindex $element 1] == "address"} {

                                                   set mask [lindex $element 3]
                                                   set binairemask [dec2bin $mask]   
						   set masque [cidr $binairemask]
                                                   set ipv4 [lindex $element 2]
                                                   set addr "$ipv4/$masque"
 						   lappend Mylist " ip address $addr"
						} elseif { [lindex $element 0] == "interface" && [lindex $element 1] == "lo0"} {

                                                   lappend Mylist "interface Loopback0"

			                       } else {

                                                   lappend Mylist $element
						}


						
					}
                               netconfInsertSection $node $Mylist

			}

                       
			     
                            
		





	}
} 
}
                        
            # Save Vlan configuration for the lanswitch
              if { $type == "lanswitch" } {
                  global listVlan
                  lappend listVlan ""

			# Parcourir la liste des Vlans
            


			foreach element $listVlan {
                set Mynode [lindex $element 0]
                set Mynode [split $Mynode "-"]
                set Myport [lindex $Mynode 1]
                set Mynode [lindex $Mynode 0]

          if {$node == $Mynode} {

                set section {}
			    netconfClearSection $node "interface $Myport"
                lappend section "interface $Myport"
                set enable [lindex $element 1]
                lappend section " vlan_enable=$enable"
				set Mytag [lindex $element 2]
                lappend section " vlan_tag=$Mytag"
                set Mymode [lindex $element 3]
                lappend section " vlan_mode=$Mymode"
				set Myinterface [lindex $element 4]
                lappend section " Interface_type=$Myinterface"
				set Myrange [lindex $$element 5]
                lappend section " vlan_range=$Myrange"
                lappend section "!" 
 
            #mettre à jour le fichier .imn
			netconfInsertSection $node $section                              

			
		  }
}






			}

            # Save the batch modifications for the PC Namespaces
              if { $type == "pcn" && $oper_mode == "exec" } {

		
				
		#**************************************		
		# changer l'adresse ip de l'interface
		#**************************************
			foreach ifc [ifcList $node] {			
				# retrive ipv4 address
				
				set netconf ""
				catch { set netconf [exec ip netns exec $eid.$node ifconfig $ifc | grep inet ] }	
				
				if { $netconf != "" } {

					regexp { [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ } $netconf ip
					set ipx [string trim $ip]

				}
				
				#retrive mask
				set mask ""
				catch { set mask [exec ip netns exec $eid.$node ifconfig $ifc | grep netmask ] }


				
				if { $mask != "" } {
                                    set mask1 [lindex $mask 3]

				    set binairemask [dec2bin $mask1]
				   
			            set num [cidr $binairemask]
                                    
			     }
			     
			     #change the ip address and show on link
			     if {$netconf != 0 && $mask != "" } { 
					 set var "$ipx/$num"
					 setIfcIPv4addr $node $ifc "$var" 
				}  

                        
                             # Add the MAC address in .imn file

			
				set macconf ""
				set MAC ""
				catch { set macconf [exec ip netns exec $eid.$node ifconfig $ifc | grep ether | cut -c15-32 		     	  					] }							
			      
				if { $macconf != "" } {
                               
					set MAC [string trim $macconf]

			        
					setIfcMACaddr $node $ifc $MAC
					
				}
			
			#retrive the ipv6 address and show on link
			set netconfpc [exec ip netns exec $eid.$node ip addr show $ifc | grep inet6 ] 
			set listconfpc [split $netconfpc "\n"]
			set listconfpc1 [split $listconfpc " "]
			set ipv6pc [lindex $listconfpc1 5]
			set varpc "$ipv6pc"
			setIfcIPv6addr $node $ifc "$varpc"
			}
			


		        # Retrive the default route
			set res ""
			catch { set res [ exec ip netns exec $eid.$node netstat -nr | grep ^0.0.0.0 ] }
			if { $res != "" } {
				catch {regexp { [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ } $res val}
			#retirer les espaces
				set addr [string trim $val]
			#modifier la section de la route dans le fichier
				set section {}
				set defaut "0.0.0.0/0"
				set RouteDef "$defaut $addr"
			#Ressembre à setStatIPv4routes $node $RouteDef
				netconfClearSection $node "ip route [lindex [getStatIPv4routes $node] 0]"
				lappend section "ip route $RouteDef"
				netconfInsertSection $node $section }	

				# Retrive the default route IPv6
			        set res ""
			        catch { set res [ exec ip netns exec $eid.$node ip -6 r show | grep  default] }
			        if { $res != "" } {
				set default [lindex $res 2]
			        #retirer les espaces
				set addr [string trim $default]
		         	#modifier la section de la route dans le fichier
				set section {}
				set defaut "::/0"
				set RouteDef "$defaut $addr"
			        #Ressembre à setStatIPv6routes $node $RouteDef
				netconfClearSection $node "ipv6 route [lindex [getStatIPv6routes $node] 0]"
				lappend section "ipv6 route $RouteDef"
				netconfInsertSection $node $section }
		}

            # Save the batch modifications for the router QUAGGA

		if { $type == "router" && $oper_mode == "exec" } {
			# Get the id (pid) of docker pc namespaces
			catch {exec docker inspect -f "{{.State.Pid}}" $eid.$node} fast	      

			# Retrive the configuration of the router
			set confQuagga ""
						
			catch {set confQuagga [ exec nsenter -m -t $fast \
			     cat /etc/quagga/Quagga.conf ]}

			set records [split $confQuagga "\n"]

			# save the all modifications in the .imn file
			if { $records != "" } {
				netconfClearAllSectionNetwork $node 
				netconfInsertSection $node $records
			}
                       

			set records2 [split $confQuagga "!"]
			# retrive the ipv4/ ipv6 address and show on link
			foreach liste $records2 { 
				set records1 [split $liste "\n"]
				set res3 [lindex $records1 1]
				set res4 [split $res3 " "]
	
				set nom_interface [lindex $res4 1]

				if { [regexp {^[eth].+\d} $nom_interface] != 0  } {
					set taille [llength $records1]
					set ntaille [incr taille -2]
					for {set x $ntaille } {$x > 0} {incr x -1} {
						set li [lindex $records1 $x]
						set ipv [split $li " "]
						set protocole [lindex $ipv 1]
							if { $protocole == "ipv6" } {
								set ipv6addr [lindex $ipv 3]

								set var1 "$ipv6addr"
								setIfcIPv6addr $node "$nom_interface" "$var1"
								break
							}
					}
					for {set x $ntaille} {$x > 0} {incr x -1} {
						set li [lindex $records1 $x]
						set ipv [split $li " "]
						set protocole1 [lindex $ipv 1]
							if { $protocole1 == "ip" } {
								set ipv4addr [lindex $ipv 3]

								set var "$ipv4addr"	
								setIfcIPv4addr $node "$nom_interface" "$var"

								#catch {exec nsenter -n -t $fast ifconfig $ifc $var}	
								
								break
							}
					}
	


				}
		}  

	
			
                        set confQuagga ""
				
                        # Add the hostname in .imn file
			catch {set nomhote [ exec nsenter -u -t $fast hostname ]
			setNodeName $node $nomhote }

                        # Add the MAC address in .imn file

			foreach ifc [ifcList $node] {
				set macconf ""
				set MAC ""
				catch { set macconf [exec nsenter -n -t $fast ifconfig $ifc | grep ether | cut -c15-32 					] }							
			    
				if { $macconf != "" } {
					set MAC [string trim $macconf]
			        
					setIfcMACaddr $node $ifc $MAC
					
				}
			}
	
		}
	}


	redrawAll
	fileSaveAsDialogBox        
}


    	
