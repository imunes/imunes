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

# $Id: pc.tcl 63 2013-10-03 12:17:50Z valter $


#****h* imunes/pc.tcl
# NAME
#  pc.tcl -- defines pc specific procedures
# FUNCTION
#  This module is used to define all the pc specific procedures.
# NOTES
#  Procedures in this module start with the keyword pc and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE pc

namespace eval ${MODULE}::gui {
	namespace import ::genericL3::gui::*
	namespace export *

	#****f* pc.tcl/pc.toolbarIconDescr
	# NAME
	#   pc.toolbarIconDescr -- toolbar icon description
	# SYNOPSIS
	#   pc.toolbarIconDescr
	# FUNCTION
	#   Returns this module's toolbar icon description.
	# RESULT
	#   * descr -- string describing the toolbar icon
	#****
	proc toolbarIconDescr {} {
		return "Add new PC"
	}

	#****f* pc.tcl/pc.icon
	# NAME
	#   pc.icon -- icon
	# SYNOPSIS
	#   pc.icon $size
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
				return $ROOTDIR/$LIBDIR/icons/normal/pc.gif
			}
			small {
				return $ROOTDIR/$LIBDIR/icons/small/pc.gif
			}
			toolbar {
				return $ROOTDIR/$LIBDIR/icons/tiny/pc.gif
			}
		}
	}
}
