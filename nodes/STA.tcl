
set MODULE wifiSTA

registerModule $MODULE



proc $MODULE.layer {} {
    return NETWORK
}


proc $MODULE.virtlayer {} {
    return WIFISTA
}



proc $MODULE.cfggen { node } {
      set cfg {}
    set cfg [concat $cfg [nodeCfggenIfcIPv4 $node]]
    set cfg [concat $cfg [nodeCfggenIfcIPv6 $node]]
    lappend cfg ""

    set cfg [concat $cfg [nodeCfggenRouteIPv4 $node]]
    set cfg [concat $cfg [nodeCfggenRouteIPv6 $node]]

    return $cfg
}



proc $MODULE.bootcmd { node } { 

	
    return "/bin/sh"
}


proc $MODULE.shellcmds {} {
    return "csh bash sh tcsh"
}


proc $MODULE.instantiate { eid node } {


    l3node.instantiateSTA $eid $node


}


proc $MODULE.start { eid node } {
    l3node.start $eid $node
}


proc $MODULE.shutdown { eid node } {
    l3node.shutdown $eid $node
}


proc $MODULE.destroy { eid node } {
    l3node.destroy $eid $node
}


proc $MODULE.nghook { eid node ifc } {
    return [l3node.nghook $eid $node $ifc]
}


proc $MODULE.configGUI { c node } {
    global wi
    global guielements treecolumns
    set guielements {}
 if {[[typemodel $node].virtlayer] == "WIFISTA"} {
   		 configGUI_createConfigPopupWin $c
   		 wm title $wi "STA configuration"
   		 configGUI_nodeName $wi $node "Node name:"



   		 configGUI_WIFISTA $wi $node

     
   		 configGUI_buttonsACNode $wi $node

       
}
}



proc $MODULE.icon { size } {
    global ROOTDIR LIBDIR
    switch $size {
      normal {
	return $ROOTDIR/$LIBDIR/icons/normal/wifiSTA.png
      }
      small {
	return $ROOTDIR/$LIBDIR/icons/small/wifiSTA.png
      }
      toolbar {
	return $ROOTDIR/$LIBDIR/icons/tiny/wifiSTA.png
      }
    }
}

 
proc $MODULE.toolbarIconDescr {} {
    return "Add new STA"
}

proc $MODULE.confNewNode { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node
    global nodeNamingBase

    set nconfig [list \
	"hostname [getNewNodeNameType wifiSTA $nodeNamingBase(wifiSTA)]" \
	! ]
    lappend $node "network-config [list $nconfig]"

}

proc $MODULE.ifcName {l r} {
    return 
}


proc $MODULE.notebookDimensions { wi } {
    set h 390
    set w 507

    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Configuration" } {
	set h 420
	set w 507
    }
    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Interfaces" } {
	set h 370
	set w 507
    }

    return [list $h $w]
}
