#
# Copyright 2004-2013 University of Zagreb.
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
# This work was supported in part by Croatian Ministry of Science
# and Technology through the research contracts #IP-2003-143 and #IP-2004-154.
#

# $Id: help.tcl 109 2014-09-29 08:13:54Z denis $

#****h* imunes/help.tcl
# NAME
#  help.tcl -- file used for help infromation
# FUNCTION
#  This file is considered to contain all the help information.
#  Currently it contains only copyright information.
#****

set copyright {

Copyright 2004- University of Zagreb.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.

IMUNES manual (pdf and html):
  http://imunes.net/dl/imunes_user_guide.pdf
  http://imunes.net/dl/guide/
}

global help_strings
array set help_strings {
    "Custom image" "If enabled, IMUNES will use the given virtual root (vroot) instead of the default one when running the node.\n\nThe default vroot on FreeBSD is /var/imunes/vroot directory, and on Linux it is imunes/template Docker image."
    "External Docker interface" "(Linux only)\n\nIf enabled, IMUNES will create a Docker interface inside a node (dext0) connected to the imunes-bridge Docker network.\n\nThis interface is primarily used to enable internet connection on a node in a quick and easy way - the default route is automatically added on its creation. Users should configure /etc/resolv.conf by themselves as DNS resolver is not set automatically."
    "Services" "For each enabled service, the node will start its daemon on node startup."
    "Routes" "Custom static routes - add defined routes on node startup. Set one route per line in the format\na.b.c.d/prefix x.y.z.w\n-> for example: 0.0.0.0/0 10.0.0.1\n\nAutomatic default routes - if enabled, IMUNES will dynamically generate default routes for this node and automatically add them on node startup. You can see the default routes that will be generated in the 'Automatic default routes' tab."
    "Custom config" "If enabled, custom configuration(s) will be run instead of default behaviour. There are currently two custom configuration options: interfaces config and node config."
    "Custom interfaces config" "If enabled, custom interfaces configuration will be run instead of default behaviour from the 'Interfaces' tab. More information is available inside the custom config editor."
    "Custom node config" "If enabled, custom node configuration will be run instead of default commands. More information is available inside the custom config editor."
    "Force node" "When applying the configuration, the node (or its interfaces) will be forcefully recreated/reconfigured with the currently configured values."
	"Configure External interface" "'Steal' an interface from the host OS.\nDepending on the type of link it connects to, the interface is handled differently.\n\nFreeBSD\n - 'normal' link: the interface is moved to the experiment jail and connected with the nodes interface over a bridge\n - 'direct' link: the interface is moved to the experiment jail and connected with the nodes interface without a bridge\n\nLinux\n - 'normal' link: the interface is moved to the experiment namespace and connected with the nodes interface over a bridge\n - 'direct' link: a new macvlan (or ipvlan if wireless) interface is created, and moved to the nodes namespace"
}

proc getHelpLabel { parent title } {
	global help_strings

	# make the parent change cursor on hover
	bind $parent <Enter> "$parent config -cursor question_arrow"
	bind $parent <Leave> "$parent config -cursor arrow"

	# on button1 click, open a help menu so that the cursor is inside of it
	set child $parent.help
	menu $child -tearoff 0
	$child add command \
		-label "See help for '$title'" \
		-command "helpPopup {$title} {$help_strings($title)}"

	bind $parent <3> "tk_popup $child \
		\[expr %X - \[winfo width $parent]/2] \
		\[expr %Y - \[winfo height $parent]/2]"

	# destroy the help menu when leaving it with the cursor
	bind $child <Leave> "catch { unset $child }"
}

proc helpPopup { title content } {
	global ROOTDIR LIBDIR

	set help_popup .help_popup

	catch { destroy $help_popup }
	toplevel $help_popup

	try {
		grab $help_popup
	} on error {} {
		catch { destroy $help_popup }
		return
	}

	wm title $help_popup "IMUNES Help - $title"
	wm minsize $help_popup 454 0

	set main_frame $help_popup.main
	ttk::frame $main_frame -padding 4
	grid $main_frame -column 0 -row 0 -sticky n
	grid columnconfigure $help_popup 0 -weight 1
	grid rowconfigure $help_popup 0 -weight 1

	set image_obj [image create photo -file $ROOTDIR/$LIBDIR/icons/imunes_icon64.png]
	set image_label $main_frame.image_label
	ttk::label $image_label
	$image_label configure -image $image_obj

	set content_label $main_frame.content_label
	ttk::label $content_label -wraplength 434 -text "$content"

	set close_button $main_frame.close_button
	ttk::button $close_button -text "Close" -command "destroy $help_popup"

	grid $image_label -column 0 -row 0 -pady 1 -padx 10 -pady 10
	grid $content_label -column 1 -row 0 -pady 1 -padx 10 -pady 10
	grid $close_button -column 0 -row 1 -pady 1 -padx 10 -columnspan 2
}
