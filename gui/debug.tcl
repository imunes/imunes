# 2019-2020 Sorbonne University
# In this version of imunes we added a full integration of emulation of 
# Linux namespaces and CISCO routers, saving of parameters, VLANs, WiFi 
# emulation and other features
# This work was developed by Benadji Hanane and Oulad Said Chawki
# Supervised and maintained by Naceur Malouch - LIP6/SU
#
if {[.menubar.tools entrycget last -label] != "Debugger"} {
    .menubar.tools add separator
    .menubar.tools add command -label "Debugger" -underline 0 -command popupDebugger
}

#****f* debug.tcl/popupDebugger
# NAME
#   popupDebugger -- popup debugger
# SYNOPSIS
#   popupDebugger
# FUNCTION
#   Creates debugger window.
#****
proc popupDebugger {} {
    set wi .debug_window
    catch { destroy $wi }
    toplevel $wi

    wm transient $wi .
    wm resizable $wi 300 200
    wm title $wi "IMUNES Debugger"
   
    ttk::frame $wi.debug -borderwidth 2
    
    ttk::frame $wi.debug.top
    ttk::label $wi.debug.top.label \
		-text "Tcl/Tk script to be evaluated:"
		
	ttk::button $wi.debug.top.insert -text "upvar" -command {
		set wi .debug_window
		$wi.debug.editor.command insert end "upvar 0 ::cf::\[set ::curcfg\]::"
	}
	
	pack $wi.debug.top.label -anchor w -side left \
		-padx 4 -pady 4 -fill x
	pack $wi.debug.top.insert -anchor e -side right \
		-padx 4 -pady 4 -fill x
	
	pack $wi.debug.top -side top -expand 1 -fill x
	
	ttk::frame $wi.debug.editor -borderwidth 2
    text $wi.debug.editor.command -bg white -width 100 -height 5
    ttk::scrollbar $wi.debug.editor.vscroll -orient vertical \
    -command "$wi.debug.editor.command yview"
    
    pack $wi.debug.editor
    pack $wi.debug -side top
	
	grid $wi.debug.editor.command $wi.debug.editor.vscroll -in $wi.debug.editor -sticky nsew
    grid columnconfig $wi.debug.editor.vscroll 0 -weight 1
    grid rowconfigure $wi.debug.editor.vscroll 0 -weight 1
		
    ttk::frame $wi.buttons
    
    # evaluate debugging commands entered into the text box below
    ttk::button $wi.buttons.run -text "Run script" -command {
		set wi .debug_window
		set result $wi.result.r
		$result configure -state normal
		$result delete 0.0 end
		set i 1
		while { 1 } {
		    set cmd [$wi.debug.editor.command get $i.0 $i.end]
		    if { $cmd == "" } { break }
		    if { [string match *puts* $cmd] } {
				catch { eval set $cmd } output
				    if { $output != "" } {
						$result insert end $output
						$result insert end "\n"
				    }
			    incr i
			} else {
			    catch { eval $cmd } output
				    if { $output != "" } {
						$result insert end $output
						$result insert end "\n"
				    }
			    incr i
			}
		}
	    $result configure -state disabled
    }
    ttk::button $wi.buttons.close -text "Close" -command "destroy $wi"

    pack $wi.buttons.run $wi.buttons.close -side left -padx 4 -pady 4
    pack $wi.buttons -side top
    
    ttk::frame $wi.result -borderwidth 2
    ttk::label $wi.result.label \
		-text "Script output:"
    text $wi.result.r -bg black -fg white -width 100 \
		-height 12
	
	pack $wi.result.label $wi.result.r -side top -anchor w
	
	pack $wi.result
}

proc registerModule { module } {
    global all_modules_list
    if { $module ni $all_modules_list } {
	lappend all_modules_list $module
    }
}

proc logCaller {} {
    set r [catch {info level [expr [info level] - 1]} e]
    set r2 [catch {info level [expr [info level] - 2]} e2]
    if {$r} {
        puts "Called directly by the interpreter (e.g.: .tcl on the partyline)."
    } {
        puts "Called by ${e} ${e2}."
    }
}

bind . <F6> {
    global all_modules_list router_module_list
    set all_modules_list {}
    set router_modules_list {}

    source "$ROOTDIR/$LIBDIR/runtime/cfgparse.tcl"
    source "$ROOTDIR/$LIBDIR/runtime/eventsched.tcl"
    source "$ROOTDIR/$LIBDIR/runtime/exec.tcl"
    source "$ROOTDIR/$LIBDIR/runtime/filemgmt.tcl"
    source "$ROOTDIR/$LIBDIR/runtime/services.tcl"

    source "$ROOTDIR/$LIBDIR/config/annotationscfg.tcl"
    source "$ROOTDIR/$LIBDIR/config/ipsec.tcl"
    source "$ROOTDIR/$LIBDIR/config/ipv4.tcl"
    source "$ROOTDIR/$LIBDIR/config/ipv6.tcl"
    source "$ROOTDIR/$LIBDIR/config/linkcfg.tcl"
    source "$ROOTDIR/$LIBDIR/config/mac.tcl"
    source "$ROOTDIR/$LIBDIR/config/nodecfg.tcl"

    source "$ROOTDIR/$LIBDIR/nodes/hub.tcl"
    source "$ROOTDIR/$LIBDIR/nodes/lanswitch.tcl"
    source "$ROOTDIR/$LIBDIR/nodes/click_l2.tcl"
    source "$ROOTDIR/$LIBDIR/nodes/rj45.tcl"
    source "$ROOTDIR/$LIBDIR/nodes/genericrouter.tcl"
    source "$ROOTDIR/$LIBDIR/nodes/click_l3.tcl"
    source "$ROOTDIR/$LIBDIR/nodes/host.tcl"
    source "$ROOTDIR/$LIBDIR/nodes/pc.tcl"
    source "$ROOTDIR/$LIBDIR/nodes/localnodes.tcl"
    source "$ROOTDIR/$LIBDIR/nodes/annotations.tcl"
    source "$ROOTDIR/$LIBDIR/nodes/ext.tcl"
    source "$ROOTDIR/$LIBDIR/nodes/nouveauPc.tcl"
    source "$ROOTDIR/$LIBDIR/nodes/nouveauRouteur.tcl"

    source "$ROOTDIR/$LIBDIR/nodes/quagga.tcl"
    source "$ROOTDIR/$LIBDIR/nodes/xorp.tcl"
    source "$ROOTDIR/$LIBDIR/nodes/static.tcl"

    source "$ROOTDIR/$LIBDIR/gui/canvas.tcl"
    source "$ROOTDIR/$LIBDIR/gui/copypaste.tcl"
    source "$ROOTDIR/$LIBDIR/gui/drawing.tcl"
    source "$ROOTDIR/$LIBDIR/gui/editor.tcl"
    source "$ROOTDIR/$LIBDIR/gui/help.tcl"
    source "$ROOTDIR/$LIBDIR/gui/linkcfgGUI.tcl"
    source "$ROOTDIR/$LIBDIR/gui/mouse.tcl"
    source "$ROOTDIR/$LIBDIR/gui/nodecfgGUI.tcl"
    source "$ROOTDIR/$LIBDIR/gui/widgets.tcl"
    source "$ROOTDIR/$LIBDIR/gui/debug.tcl"

    puts "Reloaded all sources."
}
