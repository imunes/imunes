#
# Copyright 2008-2013 University of Zagreb.
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

# $Id: eventsched.tcl 77 2013-11-28 14:52:41Z denis $

#****f* eventsched.tcl/startEventScheduling
# NAME
#   startEventScheduling -- start event scheduling
# SYNOPSIS
#   startEventScheduling
# FUNCTION
#   Starts event scheduling.
#****
proc startEventScheduling {} {
	setToRunning "sched_init_done" 0
	setToRunning "stop_sched" false

	.menubar.events entryconfigure "Start scheduling" -state disabled
	.menubar.events entryconfigure "Stop scheduling" -state normal
	.bottom.cpu_load config -text "0"
	evsched
}

#****f* eventsched.tcl/stopEventScheduling
# NAME
#   stopEventScheduling -- stop event scheduling
# SYNOPSIS
#   stopEventScheduling
# FUNCTION
#   Stops event scheduling.
#****
proc stopEventScheduling {} {
	setToRunning "stop_sched" true

	.menubar.events entryconfigure "Start scheduling" -state normal
	.menubar.events entryconfigure "Stop scheduling" -state disabled
}

#****f* eventsched.tcl/evsched
# NAME
#   evsched -- event scheduler
# SYNOPSIS
#   evsched
# FUNCTION
#   Function that start scheduling events accoring to scheduling data.
#****
proc evsched {} {
	global evlogfile

	# XXX eid should be arg to evsched()
	set eid [getFromRunning "eid"]
	set oper_mode [getFromRunning "oper_mode"]
	set eventqueue [getFromRunning "eventqueue"]

	# XXX temp hack, init should be called when experiment is started

	if { [getFromRunning "stop_sched"] } {
		return
	}

	if { $oper_mode == "exec" && [getFromRunning "cfg_deployed"] } {
		if { [getFromRunning "sched_init_done"] == 0 } {
			sched_init
			after 1000 evsched
			return
		}
	} else {
		setToRunning "sched_init_done" 0
		after 1000 evsched
		return
	}

	set curtime [expr [clock seconds] - [getFromRunning "event_t0"]]
	set changed 0
	set need_sort 1

	if { $oper_mode == "exec" } {
		.bottom.cpu_load config -text "$curtime"
	} else {
		.bottom.cpu_load config -text ""
	}

	foreach event $eventqueue {
		set deadline [lindex $event 0]
		if { $deadline > $curtime } {
			break
		}

		# Dequeue the current event
		set eventqueue [lrange $eventqueue 1 end]

		set class [lindex $event 1]
		set object [lindex $event 2]
		set target [lindex $event 3]
		set params [lrange $event 4 end]

		if { $class == "node" } {
			# XXX nothing implemented yet
		} elseif { $class == "link" } {
			if { [lindex $params 0] == "rand" } {
				set lo [lindex $params 1]
				set hi [lindex $params 2]
				set next [expr $deadline + [lindex $params 3]]
				set value [expr round($lo + ($hi - $lo) * rand())]
				if { $next > $deadline } {
					set nextev \
						[lsearch $eventqueue "* $class $object $target *"]
					if {
						$nextev == -1 ||
						[lindex [lindex $eventqueue $nextev] 0] > $next
					} {
						lappend eventqueue "$next [lrange $event 1 end]"
						set need_sort 1
					}
				}
			} elseif { [lindex $params 0] == "ramp" } {
				set start [lindex $params 1]
				set step [lindex $params 2]
				set next [expr $deadline + [lindex $params 3]]
				set value [expr round($start + $step)]
				if { $next > $deadline } {
					set nextev \
						[lsearch $eventqueue "* $class $object $target *"]
					if {
						$nextev == -1 ||
						[lindex [lindex $eventqueue $nextev] 0] > $next
					} {
						lappend eventqueue \
							"$next [lrange $event 1 4] $value [lrange $params 2 end]"
						set need_sort 1
					}
				}
			} elseif { [lindex $params 0] == "square" } {
				set lo [lindex $params 1]
				set hi [lindex $params 2]
				set next [expr $deadline + [lindex $params 3]]
				set value $hi
				if { $next > $deadline } {
					set nextev \
						[lsearch $eventqueue "* $class $object $target *"]
					if {
						$nextev == -1 ||
						[lindex [lindex $eventqueue $nextev] 0] > $next
					} {
						lappend eventqueue "$next [lrange $event 1 4] $hi $lo [lindex $params 3]"
						set need_sort 1
					}
				}
			} elseif { [lindex $params 0] == "const" } {
				set value [lindex $params 1]
			} else {
				puts stderr "bogus event line: $event"
			}

			switch -exact -- $target {
				bandwidth {
					setLinkBandwidth $object $value
					execSetLinkParams $eid $object
				}
				delay {
					setLinkDelay $object $value
					execSetLinkParams $eid $object
				}
				ber {
					setLinkBER $object $value
					execSetLinkParams $eid $object
				}
				loss {
					setLinkLoss $object $value
					execSetLinkParams $eid $object
				}
				duplicate {
					setLinkDup $object $value
					execSetLinkParams $eid $object
				}
				width {
					setLinkWidth $object $value
				}
				color {
					if { [string is integer $value] == 1 } {
						setLinkColor $object [format #%06x $value]
					} else {
						setLinkColor $object $value
					}
				}
			}

			set changed 1

			if { $evlogfile != 0 } {
				lassign [getLinkPeers $object] node1_id node2_id
				lassign [getLinkPeersIfaces $object] iface1 iface2

				set delay [getLinkDelay $object]
				if { $delay == "" } {
					set delay 0
				}

				set ber [getLinkBER $object]
				if { $ber == "" } {
					set ber 0
				}

				set loss [getLinkLoss $object]
				if { $loss == "" } {
					set loss 0
				}

				set dup [getLinkDup $object]
				if { $dup == "" } {
					set dup 0
				}

				set bw [getLinkBandwidth $object]
				if { $bw == "" } {
					set bw 0
				}

				set cfg "$delay $ber $loss $dup $bw"
				puts $evlogfile \
					"[clock seconds] $object $node1_id:$iface1 $node2_id:$iface2 $cfg"
				flush $evlogfile
			}
		}
	}

	if { $changed == 1 } {
		redrawAll
	}

	if { $need_sort == 1 } {
		set eventqueue [lsort -index 0 -integer $eventqueue]
	}

	setToRunning "eventqueue" $eventqueue
	after 1000 evsched
}

#****f* eventsched.tcl/sched_init
# NAME
#   sched_init -- scheduling initialisation
# SYNOPSIS
#   sched_init
# FUNCTION
#   Scheduler initialization procedure.
#****
proc sched_init {} {
	global evlogfile env

	set eventqueue {}

	foreach link [getFromRunning "link_list"] {
		set evlist [getLinkEvents $link]
		foreach event $evlist {
			lappend eventqueue \
				"[lindex $event 0] link $link [lrange $event 1 end]"
		}
	}

	foreach node_id [getFromRunning "node_list"] {
		set evlist [getLinkEvents $node_id]
		foreach event $evlist {
			lappend eventqueue \
				"[lindex $event 0] node $node_id [lrange $event 1 end]"
		}
	}

	setToRunning "eventqueue" [lsort -index 0 -integer $eventqueue]

	if { [info exists env(IMUNES_EVENTLOG)] } {
		set evlogfile [open $env(IMUNES_EVENTLOG) a]
	} else {
		set evlogfile 0
	}

	setToRunning "sched_init_done" 1
	setToRunning "event_t0" [clock seconds]
}

#****f* eventsched.tcl/getLinkEvents
# NAME
#   getLinkEvents -- get link events
# SYNOPSIS
#   getLinkEvents $link_id
# FUNCTION
#   Returns link's events.
# INPUTS
#   * link_id -- link id
# RESULT
#   * events -- list of events
#****
proc getLinkEvents { link_id } {
	return [cfgGet "links" $link_id "events"]
}

#####################

#****f* eventsched.tcl/getElementEvents
# NAME
#   getElementEvents -- get element's events
# SYNOPSIS
#   getElementEvents $element
# FUNCTION
#   Returns the specified element's events.
# INPUTS
#   * element -- element name
# RESULT
#   * events -- list of events
#****
proc getElementEvents { element } {
	set group ""
	if { $element in [getFromRunning "node_list"] } {
		set group "nodes"
	} elseif { $element in [getFromRunning "link_list"] } {
		set group "links"
	}

	return [formatForDisp [cfgGet $group $element "events"]]
}

#****f* eventsched.tcl/setElementEvents
# NAME
#   setElementEvents -- set element's events
# SYNOPSIS
#   setElementEvents $element $events
# FUNCTION
#   Sets the specified element's events.
# INPUTS
#   * element -- element name
#   * events -- list of events
#****
proc setElementEvents { element events } {
	set group ""
	if { $element in [getFromRunning "node_list"] } {
		set group "nodes"
	} elseif { $element in [getFromRunning "link_list"] } {
		set group "links"
	}

	cfgSet $group $element "events" [formatForExec $events]
}

#****f* eventsched.tcl/formatForExec
# NAME
#   formatForExec -- format for exec mode
# SYNOPSIS
#   formatForExec $events
# FUNCTION
#   Formats the events' names for exec mode.
# INPUTS
#   * events -- list of events
# RESULT
#   * result -- list of formatted events
#****
proc formatForExec { events } {
	set result {}
	foreach zline [split $events "\n"] {
		set zline [string trim $zline]
		if { [string length $zline] != 0 } {
			lappend result $zline
		}
	}
	return $result
}

#****f* eventsched.tcl/formatForDisp
# NAME
#   formatForDisp -- format for display
# SYNOPSIS
#   formatForDisp $events
# FUNCTION
#   Formats the events' names for display.
# INPUTS
#   * events -- list of events
# RESULT
#   * result -- list of formatted events
#****
proc formatForDisp { events } {
	set result [join $events "\n"]
	return $result
}

#****f* eventsched.tcl/elementsEventsEditor
# NAME
#   elementsEventsEditor -- elements' events editor
# SYNOPSIS
#   elementsEventsEditor
# FUNCTION
#   Creates a window for editing elements' events.
#****
proc elementsEventsEditor {} {
	global shownElement
	set shownElement links

	set eventsPopup .eventspopup
	catch { destroy $eventsPopup }

	toplevel $eventsPopup
	wm transient $eventsPopup .
	wm title $eventsPopup "Events editor"
	wm iconname $eventsPopup "Events editor"

	ttk::frame $eventsPopup.events
	pack $eventsPopup.events -fill both -expand 1

	set pwi [ttk::panedwindow $eventsPopup.events.eventconf -orient horizontal]

	pack $pwi -fill both -expand 1

	#left and right pane
	ttk::frame $pwi.left -relief groove -borderwidth 3
	ttk::frame $pwi.right -relief groove -borderwidth 3

	$pwi add $pwi.left -weight 0
	$pwi add $pwi.right -weight 5

	ttk::frame $pwi.left.treegrid
	ttk::treeview $pwi.left.tree -selectmode browse \
		-height 15 -show tree \
		-yscrollcommand "$pwi.left.vscroll set"
	ttk::scrollbar $pwi.left.vscroll -orient vertical -command "$pwi.left.tree yview"

	focus $pwi.left.tree

	pack $pwi.left.treegrid -side right -fill y
	grid $pwi.left.tree $pwi.left.vscroll -in $pwi.left.treegrid -sticky nsew
	grid columnconfig $pwi.left.treegrid 0 -weight 1
	grid rowconfigure $pwi.left.treegrid 0 -weight 1

	$pwi.left.tree column #0 -width 220 -stretch 0

	global eventlinktags
	set eventlinktags ""
	$pwi.left.tree insert {} end -id links -text "Links" -open true -tags links
	$pwi.left.tree focus links
	$pwi.left.tree selection set links
	foreach link [lsort -dictionary [getFromRunning "link_list"]] {
		lassign [lmap n [getLinkPeers $link] { getNodeName $n }] name0 name1
		$pwi.left.tree insert links end -id $link -text "$link ($name0 to $name1)" -tags $link
		lappend eventlinktags $link
	}

	#set node_list [getFromRunning "node_list"]
	#global eventnodetags
	#set eventnodetags ""
	#$pwi.left.tree insert {} end -id nodes -text "Nodes" -open true -tags nodes
	#foreach node_id [lsort -dictionary $node_list] {
	#	set type [getNodeType $node_id]
	#	if { $type != "pseudo" && [[getNodeType $node_id].netlayer] == "NETWORK" } {
	#		$pwi.left.tree insert nodes end -id $node_id -text "[getNodeName $node_id]" -open false -tags $node_id
	#		lappend eventnodetags $node_id
	#	}
	#}

	text $pwi.right.text -bg white -width 42 -height 15 -takefocus 0 -state disabled
	pack $pwi.right.text -expand 1 -fill both

	bindEventsToEventEditor $pwi $pwi.right.text

	set eventButtons [ttk::frame $eventsPopup.events.buttons]
	ttk::button $eventButtons.apply -text "Apply" \
		-command "saveElementEvents .eventspopup.events.eventconf.right.text"
	ttk::button $eventButtons.close -text "Close" -command "destroy $eventsPopup"

	set startText "Start scheduling"
	set stopText "Stop scheduling"

	if { [getFromRunning "stop_sched"] } {
		set tmp_command {
			startStopEvent
			set eventButtons .eventspopup.events.buttons
			$eventButtons.start_stop configure -text [startStopText $eventButtons.start_stop]
		}
		ttk::button $eventButtons.start_stop \
			-text $startText -command $tmp_command
	} else {
		set tmp_command {
			startStopEvent
			set eventButtons .eventspopup.events.buttons
			$eventButtons.start_stop configure -text [startStopText $eventButtons.start_stop]
		}
		ttk::button $eventButtons.start_stop \
			-text $stopText -command $tmp_command
	}

	pack $eventButtons.apply $eventButtons.close \
		$eventButtons.start_stop -side left -pady 4 -padx 5
	pack $eventButtons
}

#****f* eventsched.tcl/startStopText
# NAME
#   startStopText -- "start" or "stop" text
# SYNOPSIS
#   startStopText $widget
# FUNCTION
#   Returns the text to display depending on
#   whether scheduling is started or stopped.
# INPUTS
#   * widget -- widget
# RESULT
#   * result -- string to return
#****
proc startStopText { widget } {
	set actual [$widget cget -text]
	if { [string match "Start*" $actual] } {
		return "Stop scheduling"
	} else {
		return "Start scheduling"
	}
}

#****f* eventsched.tcl/startStopEvent
# NAME
#   startStopEvent -- start or stop event
# SYNOPSIS
#   startStopEvent
# FUNCTION
#   Calls a start or stop procedure depending
#   on whether scheduling is started or stopped.
#****
proc startStopEvent {} {
	if { [getFromRunning "stop_sched"] } {
		startEventScheduling
	} else {
		stopEventScheduling
	}
}

#****f* eventsched.tcl/loadElementEvents
# NAME
#   loadElementEvents -- load element's events
# SYNOPSIS
#   loadElementEvents $element $text
# FUNCTION
#   Shows element event configuration on the right pane window.
#   This procedure is invoked on list click and manages saving
#   data so that no data is lost.
# INPUTS
#   * element -- element identifier
#   * text -- text widget on the right side of the window
#****
proc loadElementEvents { element text } {
	global shownElement

	set modified 0
	if { $shownElement != "links" && $shownElement != "nodes" } {
		if { [string trim [$text get 0.0 end]] == [string trim [getElementEvents $shownElement]] != 1 } {
			set modified 1
		}
	}

	if {
		$modified == 1 &&
		$shownElement != "links" &&
		$shownElement != "nodes" &&
		$shownElement != $element
	} {
		set answer [tk_messageBox -message "Do you want to save changes on element $shownElement?" \
			-icon question -type yesnocancel \
			-detail "Select \"Yes\" to save changes before choosing another element"]

		switch -- $answer {
			#save changes
			yes {
				.eventspopup.events.eventconf.left.tree selection set $shownElement
				saveElementEvents $text
				.eventspopup.events.eventconf.left.tree selection set $element
				$text configure -state normal
				$text delete 0.0 end
				$text insert 0.0 [getElementEvents $element]
				set shownElement $element
			}
			#discard changes
			no {
				$text configure -state normal
				$text delete 0.0 end
				$text insert 0.0 [getElementEvents $element]
				set shownElement $element
			}
			#get back on editing that interface
			cancel {
				.eventspopup.events.eventconf.left.tree selection set $shownElement
			}
		}
	} else {
		$text configure -state normal
		$text delete 0.0 end
		$text insert 0.0 [getElementEvents $element]
		set shownElement $element
	}
}

#****f* eventsched.tcl/saveElementEvents
# NAME
#   saveElementEvents -- save elements' events
# SYNOPSIS
#   saveElementEvents $text
# FUNCTION
#   Saves element data and checks for syntax errors. Won't
#   save data if errors are present.
# INPUTS
#   * text -- text widget on the right side of the window
#****
proc saveElementEvents { text } {
	set selected [.eventspopup.events.eventconf.left.tree selection]
	set events [$text get 0.0 end]

	set checkFailed 0
	if { [string match -nocase "*l*" $selected] } {
		set checkFailed [checkEventsSyntax $events link]
	} elseif { [string match -nocase "*n*" $selected] } {
		set checkFailed [checkEventsSyntax $events node]
	}

	set errline [$text get $checkFailed.0 $checkFailed.end]

	if { $checkFailed != 0 } {
		tk_dialog .dialog1 "IMUNES warning" \
			"Syntax error in line $checkFailed:\n'$errline'" \
			info 0 OK

		return
	}

	if { $selected != "nodes" && $selected != "links" } {
		setElementEvents $selected $events
	}
}

#****f* eventsched.tcl/bindEventsToEventEditor
# NAME
#   bindEventsToEventEditor -- bind events to event editor
# SYNOPSIS
#   bindEventsToEventEditor $pwi $text
# FUNCTION
#   Binds on key-up/down events to elements in the list on the
#   left side of the window.
# INPUTS
#   * pwi -- list widget
#   * text -- text widget that is on the right side
#****
proc bindEventsToEventEditor { pwi text } {
	global eventnodetags eventlinktags

	set f $pwi.left
	$f.tree tag bind links <1> \
		"$text configure -state disabled"
	$f.tree tag bind links <Key-Down> \
		"loadElementEvents [lindex $eventlinktags 0] $text"

	foreach l $eventlinktags {
		$f.tree tag bind $l <1> \
			"loadElementEvents $l $text"

		set tmp_command [list apply {
			{ text_elem l } {
				if { $l != "" } {
					loadElementEvents $l $text_elem
				} else {
					$text_elem configure -state disabled
				}
			}
		} \
			$text \
			""
		]
		$f.tree tag bind $l <Key-Up> \
			[lreplace $tmp_command end end [$f.tree prev $l]]

		$f.tree tag bind $l <Key-Down> \
			[lreplace $tmp_command end end [$f.tree next $l]]
	}

	#$f.tree tag bind nodes <1> \
	#	"$text configure -state disabled"
	#$f.tree tag bind nodes <Key-Up> \
	#	"loadElementEvents [lindex $eventlinktags 0] $text"
	#$f.tree tag bind nodes <Key-Down> \
	#	"loadElementEvents [lindex $eventlinktags 0] $text"
	#
	#foreach n $eventnodetags {
	#	set type [getNodeType $n]
	#	global selectedIfc
	#	$f.tree tag bind $n <1> \
	#		"loadElementEvents $n $text"
	#	$f.tree tag bind $n <Key-Up> \
	#		"if { ! [string equal {} [$f.tree prev $n]] } {
	#			loadElementEvents [$f.tree prev $n] $text
	#		} else {
	#			$text configure -state disabled
	#		}"
	#	$f.tree tag bind $n <Key-Down> \
	#	"if { ! [string equal {} [$f.tree next $n]] } {
	#		loadElementEvents [$f.tree next $n] $text
	#	} else {
	#		$text configure -state disabled
	#	}"
	#}
}

#****f* eventsched.tcl/checkEventsSyntax
# NAME
#   checkEventsSyntax -- check events syntax
# SYNOPSIS
#   checkEventsSyntax $text $type
# FUNCTION
#   Checks the syntax of events.
# INPUTS
#   * text -- text containing events
#   * type -- type of node (link/node)
#****
proc checkEventsSyntax { text type } {
	set text [split $text "\n"]
	switch -exact $type {
		link {
			set regularExpressions [list bandwidth delay ber loss width duplicate color]
			set functions [list ramp rand square]
			set colors [list Red Green Blue Yellow Magenta Cyan Black]
		}
		node {
			set regularExpressions [list ]
		}
	}

	set i 0
	foreach line $text {
		incr i
		if { $line == "" } {
			continue
		}

		set splitLine [split $line " "]
		if { [llength $line] == 4 } {
			if { ! [string is integer [lindex $splitLine 0]] } {
				return $i
			}

			if { [lindex $splitLine 1] ni $regularExpressions } {
				return $i
			}
			if { [lindex $splitLine 2] != "const" } {
				return $i
			}
			if {
				! [string is integer [lindex $splitLine 3]] &&
				[lindex $splitLine 3] ni $colors
			} {
				return $i
			}
		} elseif { [llength $line] == 6 } {
			if { ! [string is integer [lindex $splitLine 0]] } {
				return $i
			}

			if { [lindex $splitLine 1] ni $regularExpressions } {
				return $i
			}

			if { [lindex $splitLine 2] ni $functions } {
				return $i
			}

			if { ! [string is integer [lindex $splitLine 3]] } {
				return $i
			}

			if { ! [string is integer [lindex $splitLine 4]] } {
				return $i
			}

			if { ! [string is integer [lindex $splitLine 5]] } {
				return $i
			}
		} else {
			return $i
		}
	}

	return 0
}
