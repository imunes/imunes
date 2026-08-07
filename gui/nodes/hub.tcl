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
# This work was supported in part by Croatian Ministry of Science
# and Technology through the research contract #IP-2003-143.
#

# $Id: hub.tcl 129 2015-02-13 11:14:44Z valter $


#****h* imunes/hub.tcl
# NAME
#  hub.tcl -- defines hub specific procedures
# FUNCTION
#  This module is used to define all the hub specific procedures.
# NOTES
#  Procedures in this module start with the keyword hub and
#  end with function specific part that is the same for all the
#  node types that work on the same layer.
#****

set MODULE hub

namespace eval ${MODULE}::gui {
	namespace import ::genericL2::gui::*
	namespace export *

	#****f* hub.tcl/hub.toolbarIconDescr
	# NAME
	#   hub.toolbarIconDescr -- toolbar icon description
	# SYNOPSIS
	#   hub.toolbarIconDescr
	# FUNCTION
	#   Returns this module's toolbar icon description.
	# RESULT
	#   * descr -- string describing the toolbar icon
	#****
	proc toolbarIconDescr {} {
		return "Add new Hub"
	}

	#****f* hub.tcl/hub.icon
	# NAME
	#   hub.icon -- icon
	# SYNOPSIS
	#   hub.icon $size
	# FUNCTION
	#   Returns path to node icon, depending on the specified size.
	# INPUTS
	#   * size -- "normal", "small" or "toolbar"
	# RESULT
	#   * path -- path to icon
	#****
	proc icon { size } {
		global ROOTDIR LIBDIR

		switch $size {
			normal {
				return $ROOTDIR/$LIBDIR/icons/normal/hub.gif
			}
			small {
				return $ROOTDIR/$LIBDIR/icons/small/hub.gif
			}
			toolbar {
				return $ROOTDIR/$LIBDIR/icons/tiny/hub.gif
			}
		}
	}
}
