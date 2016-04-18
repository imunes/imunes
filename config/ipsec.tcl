#
# Copyright 2007-2013 University of Zagreb.
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

# $Id: ipsec.tcl 60 2013-10-03 09:05:13Z denis $


#****f* ipsec.tcl/editIpsecCfg
# NAME
#   editIpsecCfg -- change or delete ipsec-config
# SYNOPSIS
#   editIpsecCfg $w $node $deleteid $edit
# FUNCTION
#   Change (if $edit == 1) or delete (if $edit == 0) 
#   particular ipsec-config defined by ipsec-config-id.
# INPUTS
#   * w -- ipsec config window
#   * node  -- node 
#   * deleteid -- ipsec-config-id that determines which ipsec-config to delete
#   * edit -- If $edit is set to "1", selected ipsec-config will be just
#     edited. If $edit is set to "0", selected ipsec-config will be deleted. 
#****
proc editIpsecCfg { w node deleteid edit phase } {
    global viewid badentry

#     $w config -cursor watch; update
    if { $phase == 0 } {
	set badentry 0
	focus .
	after 100 "editIpsecCfg $w $node $deleteid $edit 1"
	return
    } elseif { $badentry } {
	$w config -cursor left_ptr
	return
    }
    set ipsecCfgList [getIpsecConfig $node]
    set i 0
    foreach element $ipsecCfgList {
	set cid [lindex [lsearch -inline $element "ipsec-config-id *"] 1]
	if { $deleteid == $cid } {
	    set ipsecCfgList [lreplace $ipsecCfgList $i $i]
	}
	incr i
    }

    if { $edit == "1" } {
	set add "0"
	set ipsecCfg [ipsecConfigApply $w $node $add 0]
	set newid [getConfig $ipsecCfg "ipsec-config-id"]
	set viewid $newid
	lappend ipsecCfgList $ipsecCfg
    }

    removeIpsecConfig $node
    foreach ipsecCfg $ipsecCfgList {
	setIpsecConfig $node $ipsecCfg
    }
    if { $edit != "1" } {
	#sanja
	.popup.nbook.nfIPsec.ipseccfg forget $w
	destroy $w.ipsecframe
	.popup.nbook configure -height 90 -width 400
	#sanja
	set delete "1"
    } else {
	set delete "0"
    }
    set view "1"
    viewIpsecCfg $node $delete $view
    
    #sanja
    set idlist {}
    set ipsecCfgList [getIpsecConfig $node]
    foreach cfg $ipsecCfgList {
	set id [lindex [lsearch -inline $cfg "ipsec-config-id *"] 1]
	lappend idlist $id
    }
    .popup.nbook.nfIPsec.ipseccfg.f1.operations.edit configure \
	-values $idlist
    .popup.nbook.nfIPsec.ipseccfg.f1.operations.edit \
	set [lindex $idlist 0]
    #sanja

    return
}

#****f* ipsec.tcl/showIpsecErrors
# NAME
#   showIpsecErrors -- show window with errors 
#   related to ipsec-config information
# SYNOPSIS
#   showIpsecErrors $str
# FUNCTION
#   Forms window with information about error made when
#   manipulating ipsec-config information.
# INPUTS
#   * str -- information about ipsec error that will be
#     written in the error window. 
#****
proc showIpsecErrors { str } {
	
    set error ""
    set error $str
    tk_messageBox -message $error -type ok -icon error \
	-title "IPsec configuration error"
}

#****f* ipsec.tcl/showIPsecInfo
# NAME
#   showIPsecInfo -- show IPsec configuration information
# SYNOPSIS
#   showIPsecInfo $str
# FUNCTION
#   Forms window with information about IPsec configuration.
# INPUTS
#   * str -- information to show
#****
proc showIPsecInfo { str } {
    tk_messageBox -message $str -type ok -icon info \
	-title "IPsec configuration notice"
}

#****f* ipsec.tcl/viewIpsecCfg
# NAME
#   viewIpsecCfg -- form ipsec configuration window
# SYNOPSIS
#   viewIpsecCfg $node $delete $view
# FUNCTION
#   Form the ipsec configuration window, either for adding
#   new ipsec-config structure or for editing existing 
#   ipsec-config structures.
# INPUTS
#   * node  -- node
#   * delete -- If delete is "1", that means that viewIpsecCfg has been
#     invoked after deleting ipsec-config with defined ipsec-config-id
#     (determined by the global variable viewid). In that case, tk_optionmenu
#     variable will be set to show the first element of the ipsecCfgList.
#     If delete is "0", viewIpsecCfg has been invoked just to show existing
#     ipsec-configs.
#   * view -- If $view is set to "0", viewIpsecCfg is used to add new 
#     ipsec-config item. If view is set to "1" viewIpsecCfg is used to 
#     edit ipsec-config items.  
#****
proc viewIpsecCfg { node delete view } {
    #sanja
    set w .popup.nbook.nfIPsec.ipseccfg.f2
    if { [pack slaves $w] != "" && $view == 0} {
	return
    } elseif { [pack slaves $w] != "" && $view == 1} {
	.popup.nbook.nfIPsec.ipseccfg forget $w
	 destroy $w.ipsecframe
    }
    .popup.nbook.nfIPsec.ipseccfg add .popup.nbook.nfIPsec.ipseccfg.f2
    .popup.nbook configure -height 610 -width 400
    #sanja
    set idlist {}
    global viewid badentry
    set ipsecCfgList [getIpsecConfig $node]
    set len [llength $ipsecCfgList]
    foreach ipsecCfg $ipsecCfgList {
	set id [lindex [lsearch -inline $ipsecCfg "ipsec-config-id *"] 1]
	lappend idlist $id
    }
    if { $delete == "1" } {
	set viewid [lindex $idlist 0]
    }
    
    if { $view == "0" } {
	catch {unset viewid}
    }

    set ipsecCfg ""

    if { $view == "1" && $idlist == {} } {
	#sanja
	.popup.nbook.nfIPsec.ipseccfg forget $w
	destroy $w.ipsecframe
	.popup.nbook configure -height 90 -width 400
	#sanja
	set error "There are no ipsec-config entries with specified ipsec-config-id."
	showIpsecErrors $error

    } else {
        ttk::frame $w.ipsecframe -padding 4 -borderwidth 2 -relief groove
        pack $w.ipsecframe -fill both -expand 1 

	if { $view == "1" } {
	    if { $delete != "1" } {
		set viewid  [.popup.nbook.nfIPsec.ipseccfg.f1.operations.edit get]
	    }
  
	    foreach element $ipsecCfgList {
		set cid \
		    [lindex [lsearch -inline $element "ipsec-config-id *"] 1]
		if { $viewid == $cid } {
		    set ipsecCfg $element
		}
	    }
	}

	#
	# ipsec-config name
	#
	ttk::frame $w.ipsecframe.id -borderwidth 4
	ttk::label $w.ipsecframe.id.label -text "ipsec-config id:"
	pack $w.ipsecframe.id.label -side left -anchor w
	ttk::entry $w.ipsecframe.id.text -width 30
	if { $ipsecCfg != "" } {
		set id [ getConfig $ipsecCfg "ipsec-config-id"]
	} else {
		set id ""
	}
	$w.ipsecframe.id.text insert end $id
	pack $w.ipsecframe.id.text $w.ipsecframe.id.label -side left -padx 4 -pady 0
	pack $w.ipsecframe.id -side top -anchor w
	
	# SAD database:
	ttk::labelframe $w.ipsecframe.sad -text "SAD database (Security Associations)"
        pack $w.ipsecframe.sad -pady 6 -fill both -expand 1

	#
	# Source SA address
	#
	ttk::frame $w.ipsecframe.sad.sourceSA -borderwidth 4
	ttk::label $w.ipsecframe.sad.sourceSA.label -text "Src SA address:"
	pack $w.ipsecframe.sad.sourceSA.label -side left -anchor w
	ttk::entry $w.ipsecframe.sad.sourceSA.source -width 30 \
	    -validate focus -invalidcommand "focusAndFlash %W"
	if { $ipsecCfg != "" } {
	    set sourceSA [ getConfig $ipsecCfg "SA-source-address"]
	} else {
	    set sourceSA ""
	}
	$w.ipsecframe.sad.sourceSA.source insert end $sourceSA
	$w.ipsecframe.sad.sourceSA.source configure \
	    -validatecommand {checkSAaddress %P}
	pack $w.ipsecframe.sad.sourceSA.source $w.ipsecframe.sad.sourceSA.label \
	    -side left -padx 2 -pady 0
	pack $w.ipsecframe.sad.sourceSA -side top -anchor w

	#
	# Destination SA address
	#
	ttk::frame $w.ipsecframe.sad.destSA -borderwidth 4
	ttk::label $w.ipsecframe.sad.destSA.label -text "Dst SA address:"
	pack $w.ipsecframe.sad.destSA.label -side left -anchor w
	ttk::entry $w.ipsecframe.sad.destSA.dest -width 30 \
	    -validate focus -invalidcommand "focusAndFlash %W"
	if { $ipsecCfg != {} } {
	    set destSA [ getConfig $ipsecCfg "SA-destination-address"]
	} else {
	    set destSA ""
	}
	$w.ipsecframe.sad.destSA.dest insert end $destSA
	$w.ipsecframe.sad.destSA.dest configure \
	    -validatecommand {checkSAaddress %P}
	pack $w.ipsecframe.sad.destSA.dest $w.ipsecframe.sad.destSA.label \
	    -side left -padx 2 -pady 0
	pack $w.ipsecframe.sad.destSA -side top -anchor w

	#
	# Security Paramters Index (SPI), 16 bit number
	# (Both SAs and SPs exist in pairs: we need inbound
	# and outbound SPI.)
	#
	ttk::frame $w.ipsecframe.sad.spi -borderwidth 4
	ttk::label $w.ipsecframe.sad.spi.inboundl -text "Inbound SPI:"
	pack $w.ipsecframe.sad.spi.inboundl -side left -anchor w
	set inboundspi ""
	if { $ipsecCfg != {} } {
	    set inboundspi [ getConfig $ipsecCfg "inbound-spi"]
	} else {
	    set inboundspi ""
	}
	ttk::spinbox $w.ipsecframe.sad.spi.inboundv -width 5 \
	    -validate focus -invalidcommand "focusAndFlash %W"
	$w.ipsecframe.sad.spi.inboundv insert 0 $inboundspi
	$w.ipsecframe.sad.spi.inboundv configure \
	    -from 1366 -to 65535 -increment 1 \
	    -validatecommand {checkIntRange %P 1366 65535}
	pack $w.ipsecframe.sad.spi.inboundl $w.ipsecframe.sad.spi.inboundv \
	    -side left -padx 2 -anchor w

	# Outbound SPI:
        ttk::frame $w.ipsecframe.sad.spi.tab1
        pack $w.ipsecframe.sad.spi.tab1 -side left -anchor w -padx 4
	ttk::label $w.ipsecframe.sad.spi.outboundl -text "Outbound SPI:"
	pack $w.ipsecframe.sad.spi.outboundl -side left -anchor w
	if { $ipsecCfg != {} } {
	    set outboundspi [ getConfig $ipsecCfg "outbound-spi"]
	} else {
	    set outboundspi ""
	}
	ttk::spinbox $w.ipsecframe.sad.spi.outboundv -width 5 \
	    -validate focus -invalidcommand "focusAndFlash %W"
	$w.ipsecframe.sad.spi.outboundv insert 0 $outboundspi
	$w.ipsecframe.sad.spi.outboundv configure \
	    -from 1367 -to 65535 -increment 1 \
	    -validatecommand {checkIntRange %P 1366 65535 }
	pack $w.ipsecframe.sad.spi.outboundl $w.ipsecframe.sad.spi.outboundv \
	    -side left -anchor w
	pack $w.ipsecframe.sad.spi -side top -anchor w

	#
	# IPsec algorithm (ESP or AH)
	#
	ttk::frame $w.ipsecframe.sad.ipsecalg -borderwidth 4
	ttk::label $w.ipsecframe.sad.ipsecalg.label -text "IPsec algorithm:"
	pack $w.ipsecframe.sad.ipsecalg.label -side left -anchor w
	global ipsecalg
	if { $ipsecCfg != {} } {
	    set ipsecalg [ getConfig $ipsecCfg "ipsec-algorithm"]
	} else {
	    set ipsecalg esp
	}
	# TODO: Add ESP with authenticated payload
        ttk::combobox $w.ipsecframe.sad.ipsecalg.alg -width 4 -textvariable ipsecalg
        $w.ipsecframe.sad.ipsecalg.alg configure -values [list esp ah]
	#tk_optionMenu $w.ipsecframe.sad.ipsecalg.alg ipsecalg esp ah
	pack $w.ipsecframe.sad.ipsecalg.label $w.ipsecframe.sad.ipsecalg.alg \
	    -side left -padx 2 -anchor w

	# IP compression:
        ttk::frame $w.ipsecframe.sad.ipsecalg.tab2
        pack $w.ipsecframe.sad.ipsecalg.tab2 -side left -anchor w -padx 4
	ttk::label $w.ipsecframe.sad.ipsecalg.ipcomp -text "IPcomp: "
	pack $w.ipsecframe.sad.ipsecalg.ipcomp -side left -anchor w
	global ipcompalg
	if { $ipsecCfg != {} } {
	    set ipcompalg [ getConfig $ipsecCfg "IPcomp-algorithm"]
	} else {
	    set ipcompalg "no IPcomp"
	}
        ttk::combobox $w.ipsecframe.sad.ipsecalg.ipcompalg -width 10 -textvariable ipcompalg
        $w.ipsecframe.sad.ipsecalg.ipcompalg configure -values [list deflate lzs "no IPcomp"]
	#tk_optionMenu $w.ipsecframe.sad.ipsecalg.ipcompalg ipcompalg \
	    #deflate lzs "no IPcomp"
	pack $w.ipsecframe.sad.ipsecalg.ipcomp $w.ipsecframe.sad.ipsecalg.ipcompalg \
	    -side left -anchor w
	pack $w.ipsecframe.sad.ipsecalg -side top -anchor w

	#
	# Crypto algorithm for ESP / AH (rfc4305)
	#   For ESP: des, 3des, 3des-cbc, aes-cbc, aes-ctr, null
	#   For AH: hmac-sha1-96, aes-xcbc-mac-96, null
	#
	ttk::frame $w.ipsecframe.sad.cryptoalg -borderwidth 4
	ttk::label $w.ipsecframe.sad.cryptoalg.label -text "Crypto algorithm:"
	pack $w.ipsecframe.sad.cryptoalg.label -side left -anchor w
	global cryptoalgesp
	global cryptoalgah
	if { $ipsecCfg != {} } {
	    set caesp [ getConfig $ipsecCfg "esp-crypto-algorithm"]
	    set caah [ getConfig $ipsecCfg "ah-crypto-algorithm"]
	} else {
	    set caesp 3des-cbc
	    set caah hmac-md5
	}
	set cryptoalgesp $caesp
	set cryptoalgah $caah
        ttk::combobox $w.ipsecframe.sad.cryptoalg.esp -width 12 -textvariable cryptoalgesp
        $w.ipsecframe.sad.cryptoalg.esp configure -values [list des-cbc 3des-cbc simple \
            blowfish-cbc cast128-cbc rijndael-cbc null]
	#tk_optionMenu $w.ipsecframe.sad.cryptoalg.esp cryptoalgesp \
	    #des-cbc 3des-cbc simple blowfish-cbc cast128-cbc \
	    #rijndael-cbc null
        ttk::combobox $w.ipsecframe.sad.cryptoalg.ah -width 14 -textvariable cryptoalgah
        $w.ipsecframe.sad.cryptoalg.ah configure -values [list hmac-md5 hmac-sha1 keyed-md5 keyed-sha1 \
            hmac-sha2-256 hmac-sha2-384 hmac-sha2-512 null]
	#tk_optionMenu $w.ipsecframe.sad.cryptoalg.ah cryptoalgah \
	    #hmac-md5 hmac-sha1 keyed-md5 keyed-sha1 hmac-sha2-256 \
	    #hmac-sha2-384 hmac-sha2-512 null
	pack $w.ipsecframe.sad.cryptoalg.label $w.ipsecframe.sad.cryptoalg.esp $w.ipsecframe.sad.cryptoalg.ah \
	    -side left -padx 2 -anchor w
	pack $w.ipsecframe.sad.cryptoalg -side top -anchor w

	# Shared secret for key derivation
	#
	ttk::frame $w.ipsecframe.sad.psk -borderwidth 4
	ttk::label $w.ipsecframe.sad.psk.label -text "Shared secret:"
	ttk::entry $w.ipsecframe.sad.psk.text -width 30 \
	    -validate focus -invalidcommand "focusAndFlash %W"
	if { $ipsecCfg != {} } {
	    set psk [ getConfig $ipsecCfg "shared-secret"]
	} else {
	    set psk ""
	}
	$w.ipsecframe.sad.psk.text insert end $psk
	$w.ipsecframe.sad.psk.text configure -validatecommand {checkSharedSecret %P}
	pack $w.ipsecframe.sad.psk.text $w.ipsecframe.sad.psk.label -side right -padx 2 -pady 0
	pack $w.ipsecframe.sad.psk -side top -anchor w
	
	#
	# SPD database:
	#
	ttk::labelframe $w.ipsecframe.spd -text "SPD database (Security Policies)"
        pack $w.ipsecframe.spd -pady 6 -fill both -expand 1
	#frame $w.ipsecframe.spd.spddb -borderwidth 4
	#label $w.ipsecframe.spd.spddb.label -text "SPD database (Security Policies)"
	#pack $w.ipsecframe.spd.spddb.label -side right
	#pack $w.ipsecframe.spd.spddb -side top -anchor w

	#
	# Source SP address
	#
	ttk::frame $w.ipsecframe.spd.sourceSP -borderwidth 4
	ttk::label $w.ipsecframe.spd.sourceSP.label -text "Src SP address:"
	ttk::entry $w.ipsecframe.spd.sourceSP.source -width 30 \
	    -validate focus -invalidcommand "focusAndFlash %W"
	if { $ipsecCfg != "" } {
	    set sourceSP [ getConfig $ipsecCfg "SP-source-address"]
	} else {
	    set sourceSP ""
	}
	$w.ipsecframe.spd.sourceSP.source insert end $sourceSP
	$w.ipsecframe.spd.sourceSP.source configure \
	    -validatecommand {checkSPrange %P}
	pack $w.ipsecframe.spd.sourceSP.source $w.ipsecframe.spd.sourceSP.label \
	    -side right -padx 4 -pady 0
	pack $w.ipsecframe.spd.sourceSP -side top -anchor w

	#
	# Destination SP address
	#
	ttk::frame $w.ipsecframe.spd.destSP -borderwidth 4
	ttk::label $w.ipsecframe.spd.destSP.label -text "Dst SP address:"
	ttk::entry $w.ipsecframe.spd.destSP.dest -width 30 \
	    -validate focus -invalidcommand "focusAndFlash %W"
	if { $ipsecCfg != "" } {
	    set destSP [ getConfig $ipsecCfg "SP-destination-address"]
	} else {
	    set destSP ""
	}
	$w.ipsecframe.spd.destSP.dest insert end $destSP
	$w.ipsecframe.spd.destSP.dest configure -validatecommand {checkSPrange %P}
	pack $w.ipsecframe.spd.destSP.dest $w.ipsecframe.spd.destSP.label -side right -padx 4 -pady 0
	pack $w.ipsecframe.spd.destSP -side top -anchor w

	#
	# Source SGW address
	#
	ttk::frame $w.ipsecframe.spd.sourcesgw -borderwidth 4
	ttk::label $w.ipsecframe.spd.sourcesgw.label -text "Src SGW address:"
	ttk::entry $w.ipsecframe.spd.sourcesgw.source -width 30 \
	    -validate focus -invalidcommand "focusAndFlash %W"
	if { $ipsecCfg != "" } {
	    set sourcesgw [ getConfig $ipsecCfg "source-SGW-address"]
	} else {
	    set sourcesgw ""
	}
	$w.ipsecframe.spd.sourcesgw.source insert end $sourcesgw
	$w.ipsecframe.spd.sourcesgw.source configure -validatecommand {checkIPv4Addr %P}
	pack $w.ipsecframe.spd.sourcesgw.source $w.ipsecframe.spd.sourcesgw.label \
	    -side right -padx 4 -pady 0
	pack $w.ipsecframe.spd.sourcesgw -side top -anchor w

	#
	# Destination SGW address
	#
	ttk::frame $w.ipsecframe.spd.destsgw -borderwidth 4
	ttk::label $w.ipsecframe.spd.destsgw.label -text "Dst SGW address:"
	ttk::entry $w.ipsecframe.spd.destsgw.source -width 30 \
	    -validate focus -invalidcommand "focusAndFlash %W"
	if { $ipsecCfg != "" } {
	    set destsgw [ getConfig $ipsecCfg "destination-SGW-address"]
	} else {
	    set destsgw ""
	}
	$w.ipsecframe.spd.destsgw.source insert end $destsgw
	$w.ipsecframe.spd.destsgw.source configure -validatecommand {checkIPv4Addr %P}
	pack $w.ipsecframe.spd.destsgw.source $w.ipsecframe.spd.destsgw.label \
		-side right -padx 4 -pady 0
	pack $w.ipsecframe.spd.destsgw -side top -anchor w
	
	#
	# Traffic for protection:
	#
	ttk::frame $w.ipsecframe.spd.traffic -borderwidth 4
	ttk::label $w.ipsecframe.spd.traffic.label -text "Traffic:"
	pack $w.ipsecframe.spd.traffic.label -side left -anchor w
	global traffic
	if { $ipsecCfg != {} } {
	    set traffic [ getConfig $ipsecCfg "traffic-to-process"]
	} else {
	    set traffic icmp	
	}
        ttk::combobox $w.ipsecframe.spd.traffic.value -width 6 -textvariable traffic
        $w.ipsecframe.spd.traffic.value configure -values [list icmp tcp udp any]
	#tk_optionMenu $w.ipsecframe.spd.traffic.value traffic icmp tcp udp any
	pack $w.ipsecframe.spd.traffic.label $w.ipsecframe.spd.traffic.value -side left \
	    -anchor w -padx 2

	#
	# Action (ipsec, discrad, bypass, none, entrust):
	#
        ttk::frame $w.ipsecframe.spd.traffic.tab4
        pack $w.ipsecframe.spd.traffic.tab4 -side left -anchor w -padx 2
	ttk::label $w.ipsecframe.spd.traffic.action -text "Action:"
	pack $w.ipsecframe.spd.traffic.action -side left -anchor w
	global action
	if { $ipsecCfg != {} } {
	    set action [ getConfig $ipsecCfg "processing-action"]
	} else {
	    set action ipsec	
	}
        ttk::combobox $w.ipsecframe.spd.traffic.actionv -width 6 -textvariable action
        $w.ipsecframe.spd.traffic.actionv configure -values [list ipsec discard bypass]
	#tk_optionMenu $w.ipsecframe.spd.traffic.actionv action ipsec discard bypass
	pack  $w.ipsecframe.spd.traffic.action $w.ipsecframe.spd.traffic.actionv \
	    -side left -anchor w

	#
	# Processing level:
	#   require, default, use 
	#
        ttk::frame $w.ipsecframe.spd.traffic.tab5
        pack $w.ipsecframe.spd.traffic.tab5 -side left -anchor w -padx 2
	ttk::label $w.ipsecframe.spd.traffic.level -text "Level:"
	pack $w.ipsecframe.spd.traffic.level -side left -anchor w
	global level
	if { $ipsecCfg != {} } {
	    set level [ getConfig $ipsecCfg "processing-level"]
	} else {
	    set level require	
	}
        ttk::combobox $w.ipsecframe.spd.traffic.levelv -width 8 -textvariable level
        $w.ipsecframe.spd.traffic.levelv configure -values [list require default use]
	#tk_optionMenu $w.ipsecframe.spd.traffic.levelv level require default use
	pack $w.ipsecframe.spd.traffic.label $w.ipsecframe.spd.traffic.value \
	    $w.ipsecframe.spd.traffic.action $w.ipsecframe.spd.traffic.actionv \
	    $w.ipsecframe.spd.traffic.level $w.ipsecframe.spd.traffic.levelv \
	    -side left -anchor w
	pack $w.ipsecframe.spd.traffic -side top -anchor w

	#
	# SP ipsec algorithm (ESP or AH):
	#
	ttk::frame $w.ipsecframe.spd.algorithm -borderwidth 4
	ttk::label $w.ipsecframe.spd.algorithm.alg -text "IPsec algorithm:"
	pack $w.ipsecframe.spd.algorithm.alg -side left -padx 2 -anchor w
	global spipsecalg
	if { $ipsecCfg != {} } {
	    set spipsecalg [ getConfig $ipsecCfg "SP-ipsec-algorithm"]
	} else {
	    set spipsecalg esp
	}
	ttk::radiobutton $w.ipsecframe.spd.algorithm.esp -text "esp" \
	    -variable spipsecalg -value esp
	ttk::radiobutton $w.ipsecframe.spd.algorithm.ah -text "ah" \
	    -variable spipsecalg -value ah
	pack $w.ipsecframe.spd.algorithm.esp -side left -anchor w
	pack $w.ipsecframe.spd.algorithm.ah -side left -anchor w

	#
	# Mode:
	#   transport
	#   tunnel (TODO)
	#   BEET (not yet supported in FreeBSD)
	#
        ttk::frame $w.ipsecframe.spd.mode -borderwidth 4
	ttk::label $w.ipsecframe.spd.mode.label -text "Mode:"
	pack $w.ipsecframe.spd.mode.label -side left -padx 2
	global mode
	if { $ipsecCfg != {} } {
	    set mode [ getConfig $ipsecCfg "ipsec-mode"]
	} else {
	    set mode transport	
	}
	ttk::radiobutton $w.ipsecframe.spd.mode.transport -text "transport" \
	    -variable mode -value transport
	ttk::radiobutton $w.ipsecframe.spd.mode.tunnel -text "tunnel" \
	    -variable mode -value tunnel
	pack $w.ipsecframe.spd.mode.transport -side left -anchor w
	pack $w.ipsecframe.spd.mode.tunnel -side left -anchor w
        pack $w.ipsecframe.spd.algorithm -side top -anchor w
        pack $w.ipsecframe.spd.mode -anchor w

	#
	# Buttons
	#
	ttk::frame $w.ipsecframe.bottom 
	ttk::frame $w.ipsecframe.bottom.buttons -borderwidth 2
	pack $w.ipsecframe.bottom.buttons -expand 1
	pack $w.ipsecframe.bottom -side bottom -fill both
	#sanja
	ttk::button $w.ipsecframe.bottom.buttons.close -text Close -command \
	    "set badentry -1 ; .popup.nbook.nfIPsec.ipseccfg forget $w; \
		  destroy $w.ipsecframe; .popup.nbook configure -height 90 -width 400"
	if { $view == "1" } {
	    set edit "1"
	    ttk::button $w.ipsecframe.bottom.buttons.delete -text Delete \
		-command "deleteIpsecCfg $w $node $viewid $edit"
	    ttk::button $w.ipsecframe.bottom.buttons.apply -text Apply \
		-command "editIpsecCfg $w $node $viewid $edit 0"
	    focus $w.ipsecframe.bottom.buttons.apply
	    pack $w.ipsecframe.bottom.buttons.delete $w.ipsecframe.bottom.buttons.close \
		$w.ipsecframe.bottom.buttons.apply -side left -padx 2
	} else {
	    set add "1"
	    ttk::button $w.ipsecframe.bottom.buttons.apply -text "Apply" \
		-command "ipsecConfigApply $w $node $add 0"
	    focus $w.ipsecframe.bottom.buttons.apply
	    pack $w.ipsecframe.bottom.buttons.apply $w.ipsecframe.bottom.buttons.close \
		-side left -padx 2
	}
    }
}

#****f* ipsec.tcl/deleteIpsecCfg
# NAME
#   deleteIpsecCfg -- invoke editIpsecCfg to delete ipsec-config item defined
#       with ipsec-config-id viewid. 
# SYNOPSIS
#   deleteIpsecCfg $w $node $viewid $edit
# FUNCTION
#   Invoke editIpsecCfg to delete defined ipsec-config.
#   When deleting ipsec-config, $edit has to be set to "0".
# INPUTS
#   * w  -- ipsec configuration window
#   * node -- node id
#   * viewid -- current ipsec-config-id from the tk_optionmenu. viewIpsecCfg
#     always shows the ipsec-config determined by the global variable viewid.
#   * edit -- if edit is set to "0", editIpsecCfg will delete ipsec-config
#     defined by the ipsec-config-id viewid.
#****
proc deleteIpsecCfg { w node viewid edit } {
    set edit "0"
    editIpsecCfg $w $node $viewid $edit 0
}

#****f* ipsec.tcl/ipsecConfigApply
# NAME
#   ipsecConfigApply -- read ipsec configuration from the ipsec configuration
#       window. Check the ipsec configuration. 
# SYNOPSIS
#   ipsecConfigApply $w $node $add
# FUNCTION
#   Read ipsec configuration from the ipsec configuration window. Check the
#   ipsec configuration by invoking checkIpsecCfg.
# INPUTS
#   * w -- ipsec configuration window
#   * node -- node id
#   * add -- If add is set to "1", ipsecConfigApply has been invoked after
#     adding new ipsec-config element. If add is set to "0", ipsecConfigApply
#     has been invoked when editing ipsec configuration.
# RESULT
#   * ipsecCfg -- new ipsec-config structure
#****
proc ipsecConfigApply { w node add phase } {
    global ipsecalg spipsecalg mode ipcompalg
    global cryptoalgesp cryptoalgah action traffic level
    global badentry
    set ipsecCfg ""
    set error ""

    if { $add == 1 } {
	update
	if { $phase == 0 } {
	    set badentry 0
	    focus .
	    after 100 "ipsecConfigApply $w $node $add 1"
	    return
	} elseif { $badentry } {
	    $w config -cursor left_ptr
	    return
	}
    }

    set id [$w.ipsecframe.id.text get]
    set sourceSA [$w.ipsecframe.sad.sourceSA.source get]
    set destSA [$w.ipsecframe.sad.destSA.dest get]
    set inboundspi [$w.ipsecframe.sad.spi.inboundv get]
    set outboundspi [$w.ipsecframe.sad.spi.outboundv get]
    set psk [$w.ipsecframe.sad.psk.text get]
    set sourceSP [$w.ipsecframe.spd.sourceSP.source get]
    set destSP [$w.ipsecframe.spd.destSP.dest get]
    set sourcesgw [$w.ipsecframe.spd.sourcesgw.source get]
    set destsgw [$w.ipsecframe.spd.destsgw.source get]

    if { $add == "1" } {
	set error [checkIpsecCfg $node "ipsec-config-id" $id]
	if { $error != "" } {
	    #sanja
	    .popup.nbook.nfIPsec.ipseccfg forget $w
	     destroy $w.ipsecframe
	    .popup.nbook configure -height 90 -width 400
	    showIpsecErrors $error
	    return ""
	}
    }

    set ipsecCfg [setConfig $ipsecCfg $id "ipsec-config-id"]
    set ipsecCfg [setConfig $ipsecCfg $sourceSA "SA-source-address"]
    set ipsecCfg [setConfig $ipsecCfg $destSA "SA-destination-address"]
    set ipsecCfg [setConfig $ipsecCfg $ipsecalg "ipsec-algorithm"]
    set ipsecCfg [setConfig $ipsecCfg $ipcompalg "IPcomp-algorithm"]
    set ipsecCfg [setConfig $ipsecCfg $inboundspi "inbound-spi"]
    set ipsecCfg [setConfig $ipsecCfg $outboundspi "outbound-spi"]
    set ipsecCfg [setConfig $ipsecCfg $cryptoalgesp "esp-crypto-algorithm"]
    set ipsecCfg [setConfig $ipsecCfg $cryptoalgah "ah-crypto-algorithm"]
    set ipsecCfg [setConfig $ipsecCfg $psk "shared-secret"]
    set ipsecCfg [setConfig $ipsecCfg $sourceSP "SP-source-address"]
    set ipsecCfg [setConfig $ipsecCfg $destSP "SP-destination-address"]
    set ipsecCfg [setConfig $ipsecCfg $sourcesgw "source-SGW-address"]
    set ipsecCfg [setConfig $ipsecCfg $destsgw "destination-SGW-address"]
    set ipsecCfg [setConfig $ipsecCfg $traffic "traffic-to-process"]
    set ipsecCfg [setConfig $ipsecCfg $action "processing-action"]
    set ipsecCfg [setConfig $ipsecCfg $spipsecalg "SP-ipsec-algorithm"]
    set ipsecCfg [setConfig $ipsecCfg $mode "ipsec-mode"]
    set ipsecCfg [setConfig $ipsecCfg $level "processing-level"]

    setIpsecConfig $node $ipsecCfg

    #sanja
    set idlist {}
    set ipsecCfgList [getIpsecConfig $node]
    foreach cfg $ipsecCfgList {
	set id [lindex [lsearch -inline $cfg "ipsec-config-id *"] 1]
	lappend idlist $id
    }
    .popup.nbook.nfIPsec.ipseccfg.f1.operations.edit configure \
	-values $idlist
    .popup.nbook.nfIPsec.ipseccfg.f1.operations.edit \
	set [lindex $idlist 0]
    
    .popup.nbook.nfIPsec.ipseccfg forget $w
    destroy $w.ipsecframe
    .popup.nbook configure -height 90 -width 400
    #sanja
    
    return $ipsecCfg
}

# TODO: Add check for the IPv4/IPv6 addresses
# TODO: Add check for the shared secret field
#   Currently, if there are some errors in syntax 
#   od the setkey.conf, they will be shown after 
#   Experiment->Execute in error window.

#****f* ipsec.tcl/checkIpsecCfg
# NAME
#   checkIpsecCfg -- Check if there are errors in ipsec configuration input
#       fields in ipsec configuration window.
# SYNOPSIS
#   checkIpsecCfg $node $strd $str
# FUNCTION
#   This procedure will be invoked while doing ipsecConfigApply
#   to check new inputs in the ipsec configuration window.
# INPUTS
#   * node -- node id
#   * strd -- string description, that is i.e. "ipsec-config-id", 
#     "SA-source-address", etc.
#   * str -- string, that is value related to strd.
# RESULT
#   * valid -- valid is set to 0, if there is an error and otherwise 1.
#****
proc checkIpsecCfg { node strd str } {
	
    set error ""
    set ipsecCfgList [getIpsecConfig $node]
	
    switch $strd {
	ipsec-config-id {
	    if { $str == "" } {
		set error "Please, enter ipsec-config-id."
	    } else {
		foreach ipsecCfg $ipsecCfgList {
		    set currentid [getConfig $ipsecCfg "ipsec-config-id"]
		    if { $str == $currentid } {
			set error "Choose another ipsec-config-id."
		    }
		}
	    }
	}
    }
    return $error
}

#****f* ipsec.tcl/setConfig
# NAME
#   setConfig -- add an element to the ipsec-config structure
# SYNOPSIS
#   setConfig $strlist $str
# FUNCTION
#   Returns requested element that belongs to ipsec-config structure. 
# INPUTS
#   * strlist -- ipsec-config structure
#   * cfg -- current ipsec-config that will be extended with new elements
#   * str -- new element
# RESULT
#   * strlist -- new ipsec-config sructure
#****
proc setConfig { strlist cfg str } {

    set i [lsearch $strlist "$str *"]

    if { $i < 0 } {
	if { $cfg != {} } {
	    set newcfg [list $str $cfg]
	    lappend strlist $newcfg
	}
    } else {
	set oldval [lindex [lsearch -inline $strlist "$str *"] 1]
	if { $oldval != $cfg } {
	    set strlist [lreplace $strlist $i $i [list $str $cfg]]
	}
    }

    return $strlist
}

#****f* ipsec.tcl/getConfig
# NAME
#   getConfig -- get an element of the ipsec-config
# SYNOPSIS
#   getConfig $strlist $str
# FUNCTION
#   Returns requested element that belongs to ipsec-config structure. 
# INPUTS
#   * strlist -- ipsec-config structure
#   * str -- an element of the ipsec-config structure
# RESULT
#   * config -- ipsec configuration
#****
proc getConfig { strlist str } {
    return [lindex [lsearch -inline $strlist "$str *"] 1]
}

#****f* ipsec.tcl/setIpsecConfig
# NAME
#   setIpsecConfig -- set ipsec configuration
# SYNOPSIS
#   setIpsecConfig $node $cfg
# FUNCTION
#   This procedure adds ipsec-config structure to node.
# INPUTS
#   * node -- node id
#   * cfg -- current ipsec-config that will be extended with new elements
#****
proc setIpsecConfig { node cfg } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    if { $cfg != {} } {
	lappend $node [list ipsec-config $cfg]
    }
}

#****f* ipsec.tcl/getIpsecConfig
# NAME
#   getIpsecConfig -- get ipsec configuration
# SYNOPSIS
#   getIpsecConfig $node
# FUNCTION
#   This procedure returns list of ipsec-config structures.
# INPUTS
#   * node -- node id
# RESULT
#   * ipsecCfg -- list of ipsec-config structures
#****
proc getIpsecConfig { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set ipsecCfg {}

    set values [lsearch -all -inline [set $node] "ipsec-config *"]
    foreach val $values {
	lappend ipsecCfg [lindex $val 1]
    }

    return $ipsecCfg
}

#****f* ipsec.tcl/removeIpsecConfig
# NAME
#   removeIpsecConfig -- delete all ipsec configuration
# SYNOPSIS
#   removeIpsecConfig $node
# FUNCTION
#   Deletes all ipsec-config structures related to specified node.
# INPUTS
#   * node -- node id
#****
proc removeIpsecConfig { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set indices [lsearch -all [set $node] "ipsec-config *"]
    set cnt 0
    foreach i $indices {
	set j [expr $i - $cnt]
	set $node [lreplace [set $node] $j $j]
	incr cnt
    }
}

#****f* ipsec.tcl/getIpsecEnabled
# NAME
#   getIpsecEnabled -- get ipsec configuration enabled state
# SYNOPSIS
#   set enabled [getIpsecEnabled $node]
# FUNCTION
#   For input node this procedure returns true if ipsec configuration
#   is enabled for the specified node.
# INPUTS
#   * node -- node id
# RESULT
#   * enabled -- returns true if custom configuration is enabled
#****
proc getIpsecEnabled { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    if { [lindex [lsearch -inline [set $node] "ipsec-enabled *"] 1] == true } {
	return true
    } else {
	return false
    }
}

#****f* ipsec.tcl/setIpsecEnabled
# NAME
#   setIpsecEnabled -- set ipsec configuration enabled state
# SYNOPSIS
#   setIpsecEnabled $node $enabled
# FUNCTION
#   For input node this procedure enables or disables ipsec configuration.
# INPUTS
#   * node -- node id
#   * enabled -- true if enabling ipsec configuration, false if disabling
#****
proc setIpsecEnabled { node enabled } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set i [lsearch [set $node] "ipsec-enabled *"]
    if { $i >= 0 } {
	set $node [lreplace [set $node] $i $i]
    }
    if { $enabled == true } {
	lappend $node [list ipsec-enabled $enabled]
    }
}

#****f* ipsec.tcl/ipsecCfggen
# NAME
#   ipsecCfggen -- generate information for the setkey.conf
# SYNOPSIS
#   ipsecCfggen $node
# FUNCTION
#   Reads all ipsec-configuration and produces data that will be copied
#   directly in the setkey.conf while switching to Execute mode.
# INPUTS
#   * node -- node id
# RESULT
#   * cfg -- information that will be copied into setkey.conf
#****
proc ipsecCfggen { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set sourceSA "" 
    set destSA ""
    set ipsecalg ""
    set ipcompalg ""
    set inboundspi ""
    set outboundspi ""
    set cryptoalgesp ""
    set cryptoalgah ""
    set psk ""
    set sourceSP "" 
    set destSP ""
    set sourcesgw ""
    set destsgw ""
    set traffic ""
    set action ""
    set spipsecalg ""
    set mode ""
    set level ""
	
    set cfg {}
    set ipsecCfgList [getIpsecConfig $node]

    lappend cfg "#!/usr/sbin/setkey -f"
    lappend cfg "flush;"
    lappend cfg "spdflush;"

    foreach ipsecCfg $ipsecCfgList {
	set cryptoalg ""
		
	set sourceSA [getConfig $ipsecCfg "SA-source-address"]
	set destSA [getConfig $ipsecCfg "SA-destination-address"]
	set ipsecalg [getConfig $ipsecCfg "ipsec-algorithm"]
	set ipcompalg [getConfig $ipsecCfg "IPcomp-algorithm"]
	set inboundspi [getConfig $ipsecCfg "inbound-spi"]
	set outboundspi [getConfig $ipsecCfg "outbound-spi"]
	set cryptoalgesp [getConfig $ipsecCfg "esp-crypto-algorithm"]
	set cryptoalgah [getConfig $ipsecCfg "ah-crypto-algorithm"]
	set psk [getConfig $ipsecCfg "shared-secret"]
	if { $ipsecalg == "esp" } {
	    set ipsecalgorithm "esp"
	    set ipsecalgmark "-E"
	    append cryptoalg $ipsecalgmark " " $cryptoalgesp
	} elseif { $ipsecalg == "ah" } {
	    set ipsecalgorithm "ah"
	    set ipsecalgmark "-A"
	    append cryptoalg $ipsecalgmark " " $cryptoalgah
	#} elseif { $ipsecalg == "esp with auth" } {
	#   set ipsecalgorithm "esp"
	#   set ipsecalgmark "-E"
	#   set ipsecalgmark2 "-A"
	#   append cryptoalg $ipsecalgmark " " $cryptoalgesp " " \
	#   	$ipsecalgmark2 " " $cryptoalgah
	} else {
	    return ""
	}

	if { $ipcompalg == "defalte" || $ipcompalg == "lzs" } {
	    set ipcompalgorithm " -C $ipcompalg"
	    append cryptoalg $ipcompalgorithm 
	}

	if { $sourceSA != "" && $destSA != "" && \
	    $ipsecalg != "" && $cryptoalg != "" && \
	    $psk != "" && $inboundspi != "" && \
	    $outboundspi != "" } {
	    lappend cfg "add $sourceSA $destSA $ipsecalgorithm
	    $inboundspi $cryptoalg $psk;"
			
	    lappend cfg "add $destSA $sourceSA $ipsecalgorithm
	    $outboundspi $cryptoalg $psk;"
	}

	set sourceSP [getConfig $ipsecCfg "SP-source-address"]
	set destSP [getConfig $ipsecCfg "SP-destination-address"]
	set sourcesgw [getConfig $ipsecCfg "source-SGW-address"]
	set destsgw [getConfig $ipsecCfg "destination-SGW-address"]
	set traffic [getConfig $ipsecCfg "traffic-to-process"]
	set action [getConfig $ipsecCfg "processing-action"]
	set spipsecalg [getConfig $ipsecCfg "SP-ipsec-algorithm"]
	set mode [getConfig $ipsecCfg "ipsec-mode"]
	set level [getConfig $ipsecCfg "processing-level"]

	if { $sourceSP != "" && $destSP != "" && \
	    $traffic != "" && $action != "" && \
	    $spipsecalg != "" && $mode != "" && $level != ""} {
	    if { $mode == "transport" } {
		lappend cfg "spdadd $sourceSP $destSP $traffic -P out
		$action $spipsecalg/$mode//$level;"
		lappend cfg "spdadd $destSP $sourceSP $traffic -P in
		$action $spipsecalg/$mode//$level;"
	    } elseif { $mode == "tunnel" } {
		if { $sourcesgw != "" && $destsgw != "" } {
		    lappend cfg "spdadd $sourceSP $destSP $traffic -P out
		    $action $spipsecalg/$mode/$sourcesgw-$destsgw/$level;"
		    lappend cfg "spdadd $destSP $sourceSP $traffic -P in
		    $action $spipsecalg/$mode/$destsgw-$sourcesgw/$level;"
		}
	    }
	}
    }
    return $cfg
}

#****f* ipsec.tcl/setkeyError
# NAME
#   setkeyError -- set key error
# SYNOPSIS
#   setkeyError $setkeyerror
# FUNCTION
#   Adds an error string to setkey.conf file.
# INPUTS
#   * setkeyerror -- error to add
#****
proc setkeyError { setkeyerror } {
    set str "[lindex [split $setkeyerror "\."] 0]"
    set errorstr "Error in created setkey.conf: "
    append errorstr $str
    showIpsecErrors $errorstr
}

# TODO: SP range can be one of the following:
#   address
#   address/prefixlen
#   address[port]
#   address/prefixlen[port]
#

#****f* ipsec.tcl/checkSPrange
# NAME
#   checkSPrange -- check SP range
# SYNOPSIS
#   checkSPrange $SPrange
# FUNCTION
#   Checks whether the specified SP range is in form address[port]
#   or address/prefixlen[port].
# INPUTS
#   * SPrange -- SPrange to check
# RESULT
#   *check -- 1 for address[port] or address/prefixlen[port]
#    (Address is IPv4/IPv6 address.), otherwise 0
#****
proc checkSPrange { SPrange } {
    if { [checkSAaddress $SPrange] == 1 } {
	return 1
    } elseif { [checkSPnet $SPrange] == 1 } {
	return 1
    } elseif { [checkIPv46AddrPort $SPrange] == 1 } {
	return 1
    }
    return 0
}

#****f* ipsec.tcl/setConfig
# NAME
#   checkIPv46AddrPort -- check SP range for spdadd setkey command
# SYNOPSIS
#   checkIPv46AddrPort $addr
# FUNCTION
#   Check if str has the following form: 
#   address[port] or address/prefixlen[port].
#   (Address can be IPv4 or IPv6 address.)
# INPUTS
#   * str -- IPv4 or IPv6 address with port information
# RESULT
#   * check -- 1 if str has the form address[port] or
#     address/prefixlen[port], otherwise 0
#****
proc checkIPv46AddrPort { str } {
    if { $str == "" } {
	return 1
    }
    set addr [lindex [split $str "\["] 0]
    set SAaddress [checkSAaddress $addr]
    set SPnet [checkSPnet $addr]
    if { $SAaddress == 0 && $SPnet == 0 } {
	return 0
    } else {
	set tmp [lindex [split $str "\["] 1]
	set port [lindex [split $tmp "\]"] 0]
	if { $port != "" } {
	    return [checkIntRange $port 0 65535]
	} else {
	    return 0
	}
    }
}

#****f* ipsec.tcl/checkSAaddress
# NAME
#   checkSAaddress -- check SA address for add
#   	setkey command
# SYNOPSIS
#   checkSAaddress $str
# FUNCTION
#   Check if str is valid IPv4/IPv6 address, without /prefixlen.
# INPUTS
#   * str -- IPv4 or IPv6 address
# RESULT
#   * 1 -- if str is valid address 
#   * 0 -- otherwise 
#****
proc checkSAaddress { str } {
    if { $str == "" } {
	return 1
    }
    if { [checkIPv4Addr $str] == 1 } {
	return 1
    } elseif { [checkIPv6Addr $str] == 1 } {
	return 1
    }
    return 0
}

#****f* ipsec.tcl/checkSPnet
# NAME
#   checkSPnet -- check if CIDR address is valid
# SYNOPSIS
#   checkSAaddress $str
# FUNCTION
#   Check if str is valid IPv4/IPv6 address with /prefixlen.
# INPUTS
#   * str -- IPv4 or IPv6 address
# RESULT
#   * check -- 1 if str is valid address, otherwise 0
#****
proc checkSPnet { str } {
    if { $str == "" } {
	return 1
    }
    if { [checkIPv4Net $str] == 1 } {
	return 1
    } elseif { [checkIPv6Net $str] == 1 } {
	return 1
    }
    return 0
}

#****f* ipsec.tcl/checkSharedSecret
# NAME
#   checkSharedSecret -- check if the shared secret has the valid format
# SYNOPSIS
#   checkSharedSecret $str
# FUNCTION
#   Check if the shared secret has valid form. Allowed formats are:
#    -- double-quoted character string
#    -- series of hexadecimal digits
#   (TODO: Check the length of the shared secret (in relation with
#   choosen cryptographic algorithm)).
# INPUTS
#   * str -- shared secret
# RESULT
#   * check -- 1 if shared secret has valid format, otherwise 0
#****
proc checkSharedSecret { str } {
    if { $str == "" } {
	return 1
    }
    set hexmark ""
    set limiter1 ""
    set limiter2 ""
    set hexmark [string range $str 0 1]
    set limiter1 [string index $str 0]
    set limiter2 [string index $str end]
    if { $hexmark == "0x" } {
	set psk [string range $str 2 end]
	if { $psk != "" } {
	    if { [string is integer $psk] } {
		return 1
	    }
	}
    }elseif { $limiter1 == "\"" && $limiter2 == "\"" } {
	set psk [string replace $str 0 0]
	set pskonly [string replace $psk end end]
	if { $pskonly != "" } {
	    return 1
	}
    }
    return 0
}

###################################

#****f* ipsec.tcl/getNodeIPsec
# NAME
#   getNodeIPsec -- retreives IPsec configuration for selected node
# SYNOPSIS
#   getNodeIPsec $node
# FUNCTION
#   Retreives all IPsec connections for current node
# INPUTS
#   node - node id
#****
proc getNodeIPsec { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    return [lindex [lsearch -inline [set $node] "ipsec-config *"] 1]
}

proc setNodeIPsec { node newValue } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set ipsecCfgIndex [lsearch -index 0 [set $node] "ipsec-config"]

    if { $ipsecCfgIndex != -1 } {
	set $node [lreplace [set $node] $ipsecCfgIndex $ipsecCfgIndex "ipsec-config {$newValue}"]
    } else {
	set $node [linsert [set $node] end "ipsec-config {$newValue}"]
    }
}

proc delNodIPsec { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set ipsecCfgIndex [lsearch -index 0 [set $node] "ipsec-config"]

    if { $ipsecCfgIndex != -1 } {
	set $node [lreplace [set $node] $ipsecCfgIndex $ipsecCfgIndex]
    }
}

#****f* ipsec.tcl/getNodeIPsecItem
# NAME
#   getNodeIPsecItem -- get node IPsec item
# SYNOPSIS
#   getNodeIPsecItem $node $item
# FUNCTION
#   Retreives an item from IPsec configuration of given node
# INPUTS
#   node - node id
#   item - search item
proc getNodeIPsecItem { node item } {
    set cfg [getNodeIPsec $node]
    if { [lsearch $cfg "$item *"] != -1 } {
	return [lindex [lsearch -inline $cfg "$item *"] 1]
    }
    return ""
}

#****f* ipsec.tcl/setNodeIPsecItem
# NAME
#   setNodeIPsecItem -- set node IPsec item
# SYNOPSIS
#   setNodeIPsecItem $node $item
# FUNCTION
#   Sets an item from IPsec configuration of given node
# INPUTS
#   node - node id
#   item - search item
proc setNodeIPsecItem { node item newValue } {
    set ipsecCfg [getNodeIPsec $node]

    set itemIndex [lsearch -index 0 $ipsecCfg $item]
    if { $itemIndex != -1 } {
	set newIpsecCfg [lreplace $ipsecCfg $itemIndex $itemIndex "$item {$newValue}"]
    } else {
	set newIpsecCfg [linsert $ipsecCfg end "$item {$newValue}"]
    }

    setNodeIPsec $node $newIpsecCfg
}

proc delNodeIPsecItem { node item } {
    set ipsecCfg [getNodeIPsec $node]

    set itemIndex [lsearch -index 0 $ipsecCfg $item]
    if { $itemIndex != -1 } {
	set newIpsecCfg [lreplace $ipsecCfg $itemIndex $itemIndex]
    }

    setNodeIPsec $node $newIpsecCfg
}

#****f* ipsec.tcl/getNodeIPsecElement
# NAME
#   getNodeIPsecElement -- get node IPsec element item
# SYNOPSIS
#   getNodeIPsecElement $node $item
# FUNCTION
#   Retreives an element from IPsec configuration of given node from the
#   given item.
# INPUTS
#   node - node id
#   item - search item
#   element  - search element
proc getNodeIPsecElement { node item element } {
    set itemCfg [getNodeIPsecItem $node $item]

    if { [lsearch $itemCfg "{$element} *"] != -1 } {
	return [lindex [lsearch -inline $itemCfg "{$element} *"] 1]
    }
    return ""
}

proc setNodeIPsecElement { node item element newValue } {
    set itemCfg [getNodeIPsecItem $node $item]

    set elementIndex [lsearch -index 0 $itemCfg $element]
    if { $elementIndex != -1 } {
	set newItemCfg [lreplace $itemCfg $elementIndex $elementIndex "{$element} {$newValue}"]
    } else {
	set newItemCfg [linsert $itemCfg end "{$element} {$newValue}"]
    }

    setNodeIPsecItem $node $item $newItemCfg
}

proc delNodeIPsecElement { node item element } {
    set itemCfg [getNodeIPsecItem $node $item]

    set elementIndex [lsearch -index 0 $itemCfg $element]
    if { $elementIndex != -1 } {
	set newItemCfg [lreplace $itemCfg $elementIndex $elementIndex]
    } else {
	return
    }

    setNodeIPsecItem $node $item $newItemCfg

    if { [getNodeIPsecConnList $node] == "" } {
	delNodIPsec $node
    }
}

proc getNodeIPsecSetting { node item element setting } {
    set elementCfg [getNodeIPsecElement $node $item $element]

    if { [lsearch $elementCfg "$setting=*"] != -1 } {
	return [lindex [split [lsearch -inline $elementCfg "$setting=*"] =] 1]
    }
    return ""
}

proc setNodeIPsecSetting { node item element setting newValue } {
    set elementCfg [getNodeIPsecElement $node $item $element]

    set settingIndex [lsearch $elementCfg "$setting=*"]
    if { $newValue == "" } {
	if { $settingIndex != -1 } {
	    set newElementCfg [lreplace $elementCfg $settingIndex $settingIndex]
	} else {
	    return
	}
    } else {
	if { $settingIndex != -1 } {
	    set newElementCfg [lreplace $elementCfg $settingIndex $settingIndex "$setting=$newValue"]
	} else {
	    set newElementCfg [linsert $elementCfg end "$setting=$newValue"] 
	}
    }

    setNodeIPsecElement $node $item $element $newElementCfg
}

proc createEmptyIPsecCfg { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    setNodeIPsec $node ""
    setNodeIPsecItem $node "configuration" ""
    setNodeIPsecElement $node "configuration" "config setup" ""
}

proc getNodeIPsecConnList { node } {
    set cfg [getNodeIPsecItem $node "configuration"]
    set indices [lsearch -index 0 -all $cfg "conn *"]

    set connList ""
    if { $indices != -1 } {
	foreach ind $indices {
	    lappend connList [lindex [lindex [lindex $cfg $ind] 0] 1]
	}
    }

    return $connList
}

#****f* ipsec.tcl/nodeIPsecConnExists
# NAME
#   nodeIPsecConnExists -- checks if connection already exists
# SYNOPSIS
#   nodeIPsecConnExists $node $connection_name
# FUNCTION
#   Checks if given connection already exists in IPsec configuration of given node
# INPUTS
#   node - node id
#   connection_name - name of IPsec connection
#****
proc nodeIPsecConnExists { node connection_name } {
    set connList [getNodeIPsecConnList $node]
    if { [ lsearch $connList $connection_name ] != -1 } {
        return 1
    }
    return 0
}

#****f* ipsec.tcl/getListOfOtherNodes
# NAME
#   getListOfOtherNodes -- retreives list of all nodes
# SYNOPSIS
#   getListOfOtherNodes $node
# FUNCTION
#   Retreives list of all nodes created in current topology
# INPUTS
#   node - node id
#****
proc getListOfOtherNodes { node } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list

    set idx [lsearch -exact $node_list $node ]
    set listOfNodes [lreplace $node_list $idx $idx]

    set listOfNames ""
    foreach node $listOfNodes {
	lappend listOfNames "[getNodeName $node] - $node"
    }

    return $listOfNames
}

#****f* ipsec.tcl/getLocalIpAddress
# NAME
#   getLocalIpAddress -- retreives local IP addresses for current node
# SYNOPSIS
#   getLocalIpAddress $node
# FUNCTION
#   Retreives all local addresses (IPv4 and IPv6) for current node
# INPUTS
#   node - node id
#****
proc getAllIpAddresses { node } {
    set listOfInterfaces [ifcList $node]
    foreach logifc [logIfcList $node] {
	if { [string match "vlan*" $logifc]} {
	    lappend listOfInterfaces $logifc
	}
    }
    set listOfIP4s ""
    set listOfIP6s ""
    foreach item $listOfInterfaces {
	set ifcIP [getIfcIPv4addr $node $item]
	if { $ifcIP != "" } {
	    lappend listOfIP4s $ifcIP
	}
	set ifcIP [getIfcIPv6addr $node $item]
	if { $ifcIP != "" } {
	    lappend listOfIP6s $ifcIP
	}
    }

    return [concat $listOfIP4s $listOfIP6s]
}

#****f* ipsec.tcl/getIPAddressForPeer
# NAME
#   getIPAddressForPeer -- retreives list of IP addresses for peer
# SYNOPSIS
#   getIPAddressForPeer $node
# FUNCTION
#   Refreshes list of IP addresses for peer's dropdown selection list
# INPUTS
#   node - node id
#****
proc getIPAddressForPeer { node curIP } {
    set listOfInterfaces [ifcList $node]
    foreach logifc [logIfcList $node] {
	if { [string match "vlan*" $logifc]} {
	    lappend listOfInterfaces $logifc
	}
    }

    set listOfIPs ""
    if { $curIP == "" } {
	set IPversion 4
    } else {
	set IPversion [ ::ip::version $curIP ] 
    }
    if { $IPversion == 4 } {
	foreach item $listOfInterfaces {
	    set ifcIP [getIfcIPv4addr $node $item]
	    if { $ifcIP != "" } {
		lappend listOfIPs $ifcIP
	    }
	}
    } else {
	foreach item $listOfInterfaces {
	    set ifcIP [getIfcIPv6addr $node $item]
	    if { $ifcIP != "" } {
		lappend listOfIPs $ifcIP
	    }
	}
    }

    return $listOfIPs
}

proc getNodeFromHostname { hostname } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list

    foreach node $node_list {
	if { $hostname == [getNodeName $node] } {
	    return $node
	}
    }

    return ""
}

#****f* ipsec.tcl/getLocalSubnets
# NAME
#   getLocalSubnets -- creates and retreives local subnets
# SYNOPSIS
#   getLocalSubnets $listOfIPs
# FUNCTION
#   Creates and retreives local subnets from given list of IP addresses
# INPUTS
#   listOfIPs - list of IP addresses
#****
proc getSubnetsFromIPs { listOfIPs } {
    set total_string ""
    set total_list ""
    foreach item $listOfIPs {
	set total_string [ip::prefix $item]
	if { [::ip::version $item ] == 6 } {
	    set total_string [ip::contract $total_string]
	}
	append total_string "/"
	append total_string [::ip::mask $item]
	lappend total_list $total_string
    }
    return $total_list
}

proc checkIfPeerStartsSameConnection { peer local_ip local_subnet local_id } {
    set connList [getNodeIPsecConnList $peer]

    foreach conn $connList {
	set auto [getNodeIPsecSetting $peer "configuration" "conn $conn" "auto"]
	if { "$auto" == "start" } {
	    set right [getNodeIPsecSetting $peer "configuration" "conn $conn" "right"]
	    if { "$right" == "$local_ip"} {
		set rightsubnet [getNodeIPsecSetting $peer "configuration" "conn $conn" "rightsubnet"]
		if { "$rightsubnet" == "$local_subnet"} {
		    set rightid [getNodeIPsecSetting $peer "configuration" "conn $conn" "rightid"]
		    if { $rightid == "" || $local_id == "" } {
			return 1
		    } else {
			if { "$rightid" == "$local_id"} {
			    return 1
			}
		    }
		}
	    }
	}
    }

    return 0
}

#****f* ipsec.tcl/prepareNodeConfiguration
# NAME
#   prepareNodeConfiguration -- inserts extra values in IPsec connection configuration
# SYNOPSIS
#   prepareNodeConfiguration $node
# FUNCTION
#   Inserts extra values in IPsec connection configuration before it is written to ipsec.conf
# INPUTS
#   node - node id
#****
proc prepareNodeConfiguration { node } {
    set ipsecCfg [getNodeIPsec $node]
    set cfg [getNodeIPsecItem $node "configuration"]
    set connList [getNodeIPsecConnList $node]

    set new_cfg ""
    set help_item ""
    if { [llength $cfg] > 0 } {
	foreach item $cfg {
	    set elementCfg [lindex $cfg 0]
	    foreach element $elementCfg {
		puts $element

		puts "ITEM: $item"
		if { [llength $item] > 2 } {
		    set help_item $item

		    if { [lsearch $item "keyexchange=*"] == -1} {
			set help_item [linsert $help_item 2 "keyexchange=ikev2"]
		    } 
		    if { [lsearch $item "leftfirewall=*"] == -1} {
			set help_item [linsert $help_item 5 "leftfirewall=no"]
		    } 

		    if { [lsearch $cfg "local_cert *"] != -1 && [lsearch $item "authby=secret"] == -1 } {
			set local_cert_file [lindex [lsearch -inline $cfg "local_cert *"] 1]
			if { [string first "/" $local_cert_file] != -1 } {
			    set for_file [lindex [split $local_cert_file /] end]
			} else {
			    set for_file $local_cert_file
			}
			set help_item [linsert $help_item 3 "leftcert=$for_file"]
		    }	
		    lappend new_cfg $help_item

		} else {
		    lappend new_cfg $item
		}
	    }
	}
    }
    return $new_cfg
}
