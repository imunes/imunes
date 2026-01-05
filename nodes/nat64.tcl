#
# Copyright 2005-2010 University of Zagreb, Croatia.
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

set MODULE nat64
registerModule $MODULE

namespace eval $MODULE {
	# Define all node-specific procedures. All non-defined procedures will call
	# router::* procedures from nodes/router.tcl
	namespace import ::router::*
	namespace export *

	################################################################################
	########################### CONFIGURATION PROCEDURES ###########################
	################################################################################

	proc namingBase {} {
		return "nat64-"
	}

	proc confNewNode { node_id } {
		invokeTypeProc "router" "confNewNode" $node_id

		setTaygaIPv4DynPool $node_id "192.168.64.0/24"
		setTaygaIPv6Prefix $node_id "2001::/96"
	}

	proc generateConfig { node_id } {
		set cfg [invokeTypeProc "router" "generateConfig" $node_id]

		lappend cfg ""

		set tayga4pool [getTaygaIPv4DynPool $node_id]
		setToRunning "${node_id}_old_tayga_ipv4_pool" $tayga4pool
		set tayga6prefix [getTaygaIPv6Prefix $node_id]
		setToRunning "${node_id}_old_tayga_ipv6_prefix" $tayga6prefix

		set tayga4addr [lindex [split [getTaygaIPv4DynPool $node_id] "/"] 0]
		set tayga4pool [getTaygaIPv4DynPool $node_id]
		set tayga6prefix [getTaygaIPv6Prefix $node_id]

		set conf_file "/usr/local/etc/tayga.conf"
		set datadir "/var/db/tayga"

		lappend cfg "mkdir -p $datadir"
		lappend cfg "cat << __EOF__ > $conf_file"
		lappend cfg "tun-device\ttun64"
		lappend cfg " ipv4-addr\t$tayga4addr"
		lappend cfg " dynamic-pool\t$tayga4pool"
		lappend cfg " prefix\t\t$tayga6prefix"
		lappend cfg " data-dir\t$datadir"
		lappend cfg ""
		foreach map [getTaygaMappings $node_id] {
			lappend cfg " map\t\t$map"
		}
		lappend cfg "__EOF__"

		lappend cfg ""

		set cfg "[concat $cfg [configureTunIface $tayga4pool $tayga6prefix]]"

		lappend cfg "tayga -c $conf_file"

		return $cfg
	}

	proc generateUnconfig { node_id } {
		set tayga4pool [getFromRunning "${node_id}_old_tayga_ipv4_pool"]
		set tayga6prefix [getFromRunning "${node_id}_old_tayga_ipv6_prefix"]

		set cfg ""

		set conf_file "/usr/local/etc/tayga.conf"
		set datadir "/var/db/tayga"

		lappend cfg "killall tayga >/dev/null 2>&1"

		set cfg "[concat $cfg [unconfigureTunIface $tayga4pool $tayga6prefix]]"

		lappend cfg "tayga -c $conf_file --rmtun"
		lappend cfg "rm -f $conf_file"
		lappend cfg "rm -rf $datadir"

		set cfg [concat $cfg [invokeTypeProc "router" "generateUnconfig" $node_id]]

		return $cfg
	}

	################################################################################
	############################ INSTANTIATE PROCEDURES ############################
	################################################################################

	################################################################################
	############################# TERMINATE PROCEDURES #############################
	################################################################################
}
