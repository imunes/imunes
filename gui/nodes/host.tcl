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

# $Id: host.tcl 63 2013-10-03 12:17:50Z valter $


#****h* imunes/host.tcl
# NAME
#  host.tcl -- defines host specific procedures
# FUNCTION
#  This module is used to define all the host specific procedures.
# NOTES
#  Procedures in this module start with the keyword host and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE host

namespace eval ${MODULE}::gui {
	namespace import ::genericL3::gui::*
	namespace export *

	#****f* host.tcl/host.toolbarIconDescr
	# NAME
	#   host.toolbarIconDescr -- toolbar icon description
	# SYNOPSIS
	#   host.toolbarIconDescr
	# FUNCTION
	#   Returns this module's toolbar icon description.
	# RESULT
	#   * descr -- string describing the toolbar icon
	#****
	proc toolbarIconDescr {} {
		return "Add new Host"
	}

	#****f* host.tcl/host.icon
	# NAME
	#   host.icon -- icon
	# SYNOPSIS
	#   host.icon $size
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
				return $ROOTDIR/$LIBDIR/icons/normal/host.gif
			}
			small {
				return $ROOTDIR/$LIBDIR/icons/small/host.gif
			}
			toolbar {
				return $ROOTDIR/$LIBDIR/icons/tiny/host.gif
			}
		}
	}
}
