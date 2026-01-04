global debug execMode gui

if { ! $debug } {
	return
}

if { $gui && $execMode == "interactive" } {
	bind . <F6> reloadSources

	if { [.menubar.tools entrycget last -label] != "Debugger" } {
		.menubar.tools add separator
		.menubar.tools add command -label "Debugger" -underline 0 -command popupDebugger
	}
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
	ttk::label $wi.result.label -text "Script output:"
	text $wi.result.r -bg black -fg white -width 100 -height 12

	pack $wi.result.label $wi.result.r -side top -anchor w

	pack $wi.result
}

proc logCaller {} {
	set r1 [catch { info level [expr [info level] - 1] } e1]
	set r2 [catch { info level [expr [info level] - 2] } e2]
	set r3 [catch { info level [expr [info level] - 3] } e3]
	if { $r1 } {
		dputs "Called directly by the interpreter (e.g.: .tcl on the partyline)."
	} {
		dputs "Called by ${e3} --> ${e2} --> ${e1}."
	}
}
