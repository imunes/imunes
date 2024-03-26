# 2019-2020 Sorbonne University
# In this version of imunes we added a full integration of emulation of 
# Linux namespaces and CISCO routers, saving of parameters, VLANs, WiFi 
# emulation and other features
# This work was developed by Benadji Hanane and Oulad Said Chawki
# Supervised and maintained by Naceur Malouch - LIP6/SU
#
# Copyright 2005-2013 University of Zagreb.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#

# $Id: nouveauRouteur.tcl 63 2013-10-03 12:17:50Z valter $


#****h* imunes/nouveauRouteur.tcl
# NAME
#  nouveauRouteur.tcl -- defines nouveauRouteur specific procedures
# FUNCTION
#  This module is used to define all the nouveauRouteur specific procedures.
# NOTES
#  Procedures in this module start with the keyword nouveauRouteur and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****
# modification for cisco router 

set MODULE routeur

registerModule $MODULE

registerRouterModule $MODULE

set curdir [pwd]
global dynacurdir







#****f* nouveauRouteur.tcl/nouveauRouteur.icon
# NAME
#   nouveauRouteur.icon -- icon
# SYNOPSIS
#   nouveauRouteur.icon $size
# FUNCTION
#   Returns path to node icon, depending on the specified size.
# INPUTS
#   * size -- "normal", "small" or "toolbar"
# RESULT
#   * path -- path to icon
#****
# modification for cisco router 
proc $MODULE.icon { size } {
    global ROOTDIR LIBDIR
    switch $size {
      normal {
	return $ROOTDIR/$LIBDIR/icons/normal/nouveauRouteur.gif
      }
      small {
	return $ROOTDIR/$LIBDIR/icons/small/nouveauRouteur.gif
      }
      toolbar {
	return $ROOTDIR/$LIBDIR/icons/tiny/nouveauRouteur.gif
      }
    }
}

#****f* nouveauRouteur.tcl/nouveauRouteur.toolbarIconDescr
# NAME
#   nouveauRouteur.toolbarIconDescr -- toolbar icon description
# SYNOPSIS
#   nouveauRouteur.toolbarIconDescr
# FUNCTION
#   Returns this module's toolbar icon description.
# RESULT
#   * descr -- string describing the toolbar icon
#****
# modification for cisco router 
proc $MODULE.toolbarIconDescr {} {
    return "Add new c7200"
}

#****f* nouveauRouteur.tcl/nouveauRouteur.notebookDimensions
# NAME
#   nouveauRouteur.notebookDimensions -- notebook dimensions
# SYNOPSIS
#   nouveauRouteur.notebookDimensions $wi
# FUNCTION
#   Returns the specified notebook height and width.
# INPUTS
#   * wi -- widget
# RESULT
#   * size -- notebook size as {height width}
#****
proc $MODULE.notebookDimensions { wi } {
    set h 210
    set w 507

    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Configuration" } {
	set h 270
	set w 507
    }
    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Interfaces" } {
	set h 370
	set w 507
    }

    return [list $h $w]
}










#****f* nouveauRouteur.tcl/nouveauRouteur.confNewIfc
# NAME
#   nouveauRouteur.confNewIfc -- configure new interface
# SYNOPSIS
#   nouveauRouteur.confNewIfc $node $ifc
# FUNCTION
#   Configures new interface for the specified node.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
#****
proc $MODULE.confNewIfc { node ifc } {
    global changeAddressRange changeAddressRange6
    set changeAddressRange 0
    set changeAddressRange6 0
    autoIPv4addr $node $ifc
    autoIPv6addr $node $ifc
    autoMACaddr $node $ifc
    autoIPv4defaultroute $node $ifc
    autoIPv6defaultroute $node $ifc
}

#****f* nouveauRouteur.tcl/nouveauRouteur.confNewNode
# NAME
#   nouveauRouteur.confNewNode -- configure new node
# SYNOPSIS
#   nouveauRouteur.confNewNode $node
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node -- node id
#****
proc $MODULE.confNewNode { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node
    global nodeNamingBase

    set nconfig [list \
	"hostname [getNewNodeNameType routeur $nodeNamingBase(routeur)]" \
	! ]
    lappend $node "network-config [list $nconfig]"

    setLogIfcType $node lo0 lo
    setIfcIPv4addr $node lo0 "127.0.0.1/8"
    setIfcIPv6addr $node lo0 "::1/128"
}





#****f* nouveauRouteur.tcl/nouveauRouteur.ifcName
# NAME
#   nouveauRouteur.ifcName -- interface name
# SYNOPSIS
#   nouveauRouteur.ifcName
# FUNCTION
#   Returns nouveauRouteur interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifcName {l r} {
    set m [l3IfcName $l $r]
    return [l3IfcName $l $r]
}

#****f* nouveauRouteur.tcl/nouveauRouteur.IPAddrRange
# NAME
#   nouveauRouteur.IPAddrRange -- IP address range
# SYNOPSIS
#   nouveauRouteur.IPAddrRange
# FUNCTION
#   Returns nouveauRouteur IP address range
# RESULT
#   * range -- nouveauRouteur IP address range
#****
proc $MODULE.IPAddrRange {} {
    return 20
}

#****f* nouveauRouteur.tcl/nouveauRouteur.layer
# NAME
#   nouveauRouteur.layer -- layer
# SYNOPSIS
#   set layer [nouveauRouteur.layer]
# FUNCTION
#   Returns the layer on which the nouveauRouteur communicates, i.e. returns NETWORK.
# RESULT
#   * layer -- set to NETWORK
#****
proc $MODULE.layer {} {
    return NETWORK
}

#****f* nouveauRouteur.tcl/nouveauRouteur.virtlayer
# NAME
#   nouveauRouteur.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [nouveauRouteur.virtlayer]
# FUNCTION
#   Returns the layer on which the nouveauRouteur is instantiated i.e. returns VIMAGE.
# RESULT
#   * layer -- set to VIMAGE

# modification for cisco router 
proc $MODULE.virtlayer {} {
    # return type of cisco router node 
    return DYNAMIPS
}

#****f* nouveauRouteur.tcl/nouveauRouteur.cfggen
# NAME
#   nouveauRouteur.cfggen -- configuration generator
# SYNOPSIS
#   set config [nouveauRouteur.cfggen $node]
# FUNCTION
#   Returns the generated configuration. This configuration represents
#   the configuration loaded on the booting time of the virtual nodes
#   and it is closly related to the procedure nouveauRouteur.bootcmd.
#   For each interface in the interface list of the node, ip address is
#   configured and each static route from the simulator is added.
# INPUTS
#   * node -- node id (type of the node is dynamips)
# RESULT
#   * congif -- generated configuration
#****
proc $MODULE.cfggen { node } {
    
    set cfg {}

    set cfg [concat $cfg [nodeCfggenIfcIPv4 $node]]
    set cfg [concat $cfg [nodeCfggenIfcIPv6 $node]]
    lappend cfg ""

    set cfg [concat $cfg [nodeCfggenRouteIPv4 $node]]
    set cfg [concat $cfg [nodeCfggenRouteIPv6 $node]]

    return $cfg
}

#****f* nouveauRouteur.tcl/nouveauRouteur.bootcmd
# NAME
#   nouveauRouteur.bootcmd -- boot command
# SYNOPSIS
#   set appl [nouveauRouteur.bootcmd $node]
# FUNCTION
#   Procedure bootcmd returns the application that reads and employes the
#   configuration generated in nouveauRouteur.cfggen.
#   In this case (procedure nouveauRouteur.bootcmd) specific application is /bin/sh
# INPUTS
#   * node -- node id (type of the node is dynamips)
# RESULT
#   * appl -- application that reads the configuration (/bin/sh)
#****


proc $MODULE.shellcmds {} {

    return "csh sh tcsh"
}


#****f* nouveauRouteur.tcl/nouveauRouteur.instantiate
# NAME
#   nouveauRouteur.instantiate -- instantiate
# SYNOPSIS
#   nouveauRouteur.instantiate $eid $node
# FUNCTION
#   Procedure instantiate creates a new virtaul node
#   for a given node in imunes.
#   Procedure nouveauRouteur.instantiate cretaes a new virtual node with
#   all the interfaces and CPU parameters as defined in imunes.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is nouveauRouteur)
#****
# modification for cisco router 
proc $MODULE.instantiate { eid node } {
    l3node.instantiateR $eid $node

}

#****f* nouveauRouteur.tcl/nouveauRouteur.start
# NAME
#   nouveauRouteur.start -- start
# SYNOPSIS
#   nouveauRouteur.start $eid $node
# FUNCTION
#   Starts a new nouveauRouteur. The node can be started if it is instantiated.
#   Simulates the booting proces of a nouveauRouteur, by calling l3node.start procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is nouveauRouteur)

proc $MODULE.start { eid node } {
    l3node.start $eid $node
}

#****f* nouveauRouteur.tcl/nouveauRouteur.shutdown
# NAME
#   nouveauRouteur.shutdown -- shutdown
# SYNOPSIS
#   nouveauRouteur.shutdown $eid $node
# FUNCTION
#   Shutdowns a nouveauRouteur. Simulates the shutdown proces of a nouveauRouteur,
#   by calling the l3node.shutdown procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is dynamips)
#****
proc $MODULE.shutdown { eid node } {
    l3node.shutdown $eid $node
}

#****f* nouveauRouteur.tcl/nouveauRouteur.destroy
# NAME
#   nouveauRouteur.destroy -- destroy
# SYNOPSIS
#   nouveauRouteur.destroy $eid $node
# FUNCTION
#   Destroys a nouveauRouteur. Destroys all the interfaces of the nouveauRouteur
#   and the vimage itself by calling l3node.destroy procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is dynamips)
#****
proc $MODULE.destroy { eid node } {

    l3node.destroy $eid $node
}

#****f* nouveauRouteur.tcl/nouveauRouteur.nghook
# NAME
#   nouveauRouteur.nghook -- nghook
# SYNOPSIS
#   nouveauRouteur.nghook $eid $node $ifc
# FUNCTION
#   Returns the id of the netgraph node and the name of the netgraph hook
#   which is used for connecting two netgraph nodes. This procedure calls
#   l3node.hook procedure and passes the result of that procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#   * ifc -- interface name
# RESULT
#   * nghook -- the list containing netgraph node id and the
#     netgraph hook (ngNode ngHook).
#****
proc $MODULE.nghook { eid node ifc } {
    return [l3node.nghook $eid $node $ifc]
}

#****f* nouveauRouteur.tcl/nouveauRouteur.configGUI
# NAME
#   nouveauRouteur.configGUI -- configuration GUI
# SYNOPSIS
#   nouveauRouteur.configGUI $c $node
# FUNCTION
#   Defines the structure of the nouveauRouteur configuration window by calling
#   procedures for creating and organising the window, as well as
#   procedures for adding certain modules to that window.
# INPUTS
#   * c -- tk canvas
#   * node -- node id
#****

# modification for cisco router 
proc $MODULE.configGUI { c node } {

    global apply apply1 badentry close
    global mod ram1 nvram1 disk01 disk12 check1 check2 idle conf
    set apply1 0
    set apply 0
    set badentry 0
    set close 0
    set wi .cfgEditor
    set o $wi.options
    set b $wi.bottom.buttons

    set mod "7200"
    set ram1 "128"
    set nvram1 "128"
    set disk01 "64"
    set disk12 "64"
    set check1 "1"
    set check2 "1"
    set idle "0x608a0264"
    set conf "0x2102"


    tk::toplevel $wi


    wm title $wi "router cisco configurations"
    wm minsize $wi 584 445
    wm resizable $wi 0 1

    configGUI_nodeName $wi $node "Node name:"

    ttk::frame $wi.model -relief groove -borderwidth 10 -padding 10 
    ttk::label $wi.model.txt -text "Model: "

    ttk::entry $wi.model.modelname -width 14 -validate focus 
    $wi.model.modelname insert 0 $mod 

    
	pack $wi.model.txt -side left -padx 2
	pack $wi.model.modelname -side left -anchor w -expand 1 -padx 4 -pady 4
    pack $wi.model -fill both

    ttk::frame $wi.ram -relief groove -borderwidth 10 -padding 10
    ttk::label $wi.ram.txt -text "Ram:   "
    ttk::entry $wi.ram.ramname -width 14 -validate focus -textvariable ::ram1


    
	pack $wi.ram.txt -side left -padx 2
	pack $wi.ram.ramname -side left -anchor w -expand 1 -padx 4 -pady 4    
    pack $wi.ram -fill both


    ttk::frame $wi.nvram -relief groove -borderwidth 10 -padding 10
    ttk::label $wi.nvram.txt -text "Nvram:"
    ttk::entry $wi.nvram.nvramname -width 14 -validate focus -textvariable ::nvram1

    
	pack $wi.nvram.txt -side left -padx 2
	pack $wi.nvram.nvramname -side left -anchor w -expand 1 -padx 1 -pady 1    
	pack $wi.nvram -fill both


    ttk::frame $wi.service -relief groove -borderwidth 10 -padding 10
    ttk::label $wi.service.txt -text "Idlepc:" -state disabled 
    ttk::entry $wi.service.servicename1 -width 14 -validate focus -textvariable ::idle -state disabled 
    ttk::label $wi.service.txt2 -text "Confreg:"
    ttk::entry $wi.service.servicename2 -width 14 -validate focus -textvariable ::conf  

        
    pack $wi.service.txt $wi.service.servicename1  $wi.service.txt2 $wi.service.servicename2 -side left -padx 2
 
    pack $wi.service -fill both


    ttk::frame $wi.disk -relief groove -borderwidth 10 -padding 10
    ttk::label $wi.disk.txt -text "Disk 0:"
    ttk::entry $wi.disk.diskname1 -width 14 -validate focus -textvariable ::disk01 
    ttk::label $wi.disk.txt2 -text "Disk 1:  "
    ttk::entry $wi.disk.diskname2 -width 14 -validate focus -textvariable ::disk12   
        
    pack $wi.disk.txt $wi.disk.diskname1 $wi.disk.txt2 $wi.disk.diskname2 -side left -padx 2
    pack $wi.disk -fill both


    set w $wi.option

    ttk::frame $w -relief groove -borderwidth 10 -padding 10
    ttk::label $w.label -text "Options:"
    ttk::frame $w.list -padding 2

    pack $w.label -side left -padx 2
    pack $w.list -side left -padx 2

    ttk::checkbutton $w.list.autostart -text "Autostart" -variable  ::check1 -state disabled 
    ttk::checkbutton $w.list.mmap -text "Mmap" -variable ::check2

	pack $w.list.autostart -side left -padx 6
	pack $w.list.mmap -side left -padx 6

	pack $w -fill both

    ttk::frame $wi.bottom
    ttk::frame $wi.bottom.button -borderwidth 6
    ttk::button $wi.bottom.button.apply -text "Apply" -command \
        "set apply 1; configFichier_Dynamips $node"

    ttk::button $wi.bottom.button.applyclose -text "Apply and Close" -command \
        "set apply1 1; set close 1; destroy $wi; configFichier_Dynamips $node"
    ttk::button $wi.bottom.button.cancel -text "Cancel" -command \
        "set badentry -1; destroy $wi; configFichier_Dynamips $node"

    pack $wi.bottom.button.apply $wi.bottom.button.applyclose \
        $wi.bottom.button.cancel -side left -padx 2
    pack $wi.bottom.button -pady 2 -expand 1
    pack $wi.bottom -fill both -side bottom
    
    bind $wi <Key-Escape> "set badentry -1; destroy $wi"



}

# modification for cisco router by adding new function
# this function for cisco router settings

proc configFichier_Dynamips { node } {
upvar 0 ::cf::[set ::curcfg]::eid eid
global  close apply apply1 badentry listRouterCisco
global mod ram1 nvram1 disk01 disk12 check1 check2 conf



set curdir [pwd]
global dynacurdir 
if { $apply1 == 1 && $close == 1} {	

 foreach element $listRouterCisco {
	
		set nom [lindex $element 0]


			if { "$node" == $nom } {

				set id [lsearch -exact $listRouterCisco $element]
				set malist [lreplace $listRouterCisco $id $id]

				set listRouterCisco $malist
			}


	}


          if { $check2 == 1 } {
          	set true "true"
          } else {

          	set true "false"
          }

    set name [getNodeName $node]
    set name1 [split $name "n"]

    set name2 [lindex $name1 0]

       set router "router Routeur_CISCO_$name2"

       lappend listRouterCisco "$node \x5b\x5b$router\x5d\x5d model=$mod ram=$ram1 nvram=$nvram1 mmap=$true disk0=$disk01 disk1=$disk12 confreg=$conf"

        focus .


    }

if { $apply == 1 } { 

foreach element $listRouterCisco {
           
		set nom [lindex $element 0]
	             
			if { "$node" == $nom } {

				set id [lsearch -exact $listRouterCisco $element]


				set malist [lreplace $listRouterCisco $id $id]
				set listRouterCisco $malist
			}


				}


          if { $check2 == 1 } {
          	set true "true"
          } else {

          	set true "false"
          }

    set name [getNodeName $node]
    set name1 [split $name "n"]

    set name2 [lindex $name1 0]

          set router "router Routeur_CISCO_$name2"

          lappend listRouterCisco "$node \x5b\x5b$router\x5d\x5d model=$mod ram=$ram1 nvram=$nvram1 mmap=$true disk0=$disk01 disk1=$disk12 confreg=$conf"
  

} 

if { $badentry == -1} {

            focus .

}


	}
# modification for cisco router by adding new function

proc verifierFichier_Dynamips { node } {
set curdir [pwd]
global dynacurdir
upvar 0 ::cf::[set ::curcfg]::eid eid


if { [file exist "$dynacurdir/Dynamips/$eid/node/$node.txt"] != 1 } {
	    
    set name [getNodeName $node]
    set name1 [split $name "n"]

    set name2 [lindex $name1 0]

    set router "router Routeur_CISCO_$name2"

          	set fp [open "$dynacurdir/Dynamips/$eid/node/$node.txt" w+]
          	puts $fp \x5b\x5b$router\x5d\x5d
          	puts $fp "\nmodel=7200\nram=128\nnvram=128\nmmap=true\ndisk0=64\ndisk1=64\nconfreg=0x2102\ncnfg=$dynacurdir/Dynamips/$eid/configuration/$node.txt"
          	close $fp
           
}
}	
#****f* nouveauRouteur.tcl/nouveauRouteur.configInterfacesGUI
# NAME
#   nouveauRouteur.configInterfacesGUI -- configuration of interfaces GUI
# SYNOPSIS
#   nouveauRouteur.configInterfacesGUI $wi $node $ifc
# FUNCTION
#   Defines which modules for changing interfaces parameters are contained in
#   the nouveauRouteur configuration window. It is done by calling procedures for adding
#   certain modules to the window.
# INPUTS
#   * wi -- widget
#   * node -- node id
#   * ifc -- interface name
#****
proc $MODULE.configInterfacesGUI { wi node ifc } {
    global guielements

    configGUI_ifcEssentials $wi $node $ifc
    configGUI_ifcQueueConfig $wi $node $ifc
    configGUI_ifcMACAddress $wi $node $ifc
    configGUI_ifcIPv4Address $wi $node $ifc
    configGUI_ifcIPv6Address $wi $node $ifc
}
