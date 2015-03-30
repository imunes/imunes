PREFIX = /usr/local
LIBDIR = lib/imunes
IMUNESDIR = $(PREFIX)/$(LIBDIR)
ICONSDIR = $(IMUNESDIR)/icons
NORMAL_ICONSDIR = $(ICONSDIR)/normal
SMALL_ICONSDIR = $(ICONSDIR)/small
TINY_ICONSDIR = $(ICONSDIR)/tiny
BINDIR = $(PREFIX)/bin
IMUNESDATE = `date +"%Y%m%d"`
IMUNESVER = 1.0
TARBALL_DIR = imunes_$(IMUNESDATE)
RELEASE_DIR = imunes-$(IMUNESVER)

FILES =	gui/topogen.tcl gui/help.tcl gui/mouse.tcl gui/editor.tcl \
	gui/initgui.tcl gui/canvas.tcl gui/widgets.tcl gui/copypaste.tcl \
	gui/debug.tcl gui/theme.tcl gui/nodecfgGUI.tcl gui/drawing.tcl \
	gui/linkcfgGUI.tcl config/ipv6.tcl config/ipv4.tcl config/ipsec.tcl \
	config/linkcfg.tcl config/annotationscfg.tcl config/nodecfg.tcl \
	config/mac.tcl nodes/quagga.tcl nodes/rj45.tcl nodes/pc.tcl \
	nodes/ipfirewall.tcl nodes/localnodes.tcl nodes/genericrouter.tcl \
	nodes/static.tcl nodes/click_l3.tcl nodes/lanswitch.tcl nodes/xorp.tcl \
	nodes/click_l2.tcl nodes/host.tcl nodes/hub.tcl nodes/annotations.tcl \
	runtime/cfgparse.tcl runtime/eventsched.tcl runtime/filemgmt.tcl \
	runtime/exec.tcl README

BINARIES = scripts/himage scripts/cleanupAll scripts/hcp scripts/vlink \
	   scripts/pkg_add_imunes scripts/startxcmd

VROOT = scripts/prepare_vroot.sh scripts/prepare_vroot_8.sh \
	scripts/prepare_vroot_9.sh scripts/quaggaboot.sh

NODE_ICONS = frswitch.gif hub.gif lanswitch.gif rj45.gif cloud.gif host.gif \
	ipfirewall.gif pc.gif router.gif click_l2.gif click_l3.gif

NORMAL_ICONS = $(NODE_ICONS)

SMALL_ICONS = $(NODE_ICONS)

TINY_ICONS = $(NODE_ICONS) link.gif select.gif l2.gif l3.gif freeform.gif \
		oval.gif rectangle.gif text.gif
		  
ICONS = imunes_icon32.gif imunes_icon16.gif

info:
	@echo 	"To install the IMUNES GUI use: make install"
	@echo	"To install the files needed to execute experiments use: make vroot"
	@echo	"To install everything: make all"
	@echo	"To make tarball: make tarball"
	@echo   "$(FILES2)"

all: install

install:
	mkdir -p $(IMUNESDIR)
	mkdir -p $(BINDIR)

	sed -e "s,set LIBDIR \"\",set LIBDIR $(LIBDIR)," \
	    -e "s,set ROOTDIR \".\",set ROOTDIR $(PREFIX)," \
	    imunes.tcl > $(IMUNESDIR)/imunes.tcl

	sed -e "s,LIBDIR=\"\",LIBDIR=$(LIBDIR)," \
	    -e "s,ROOTDIR=\".\",ROOTDIR=$(PREFIX)," \
	    -e "s,BINDIR=\".\",BINDIR=$(BINDIR)," \
	    imunes > $(BINDIR)/imunes
	chmod 755 $(BINDIR)/imunes

	cp $(BINARIES) $(BINDIR)

	for file in $(BINARIES); do \
		chmod 755 $(BINDIR)/$${file}; \
	done ;	

	for file in $(VROOT); do \
	    sed -e "s,LIBDIR=\"\",LIBDIR=$(LIBDIR)," \
		-e "s,ROOTDIR=\".\",ROOTDIR=$(PREFIX)," \
		$${file} > $(IMUNESDIR)/$${file}; \
	    chmod 755 $(IMUNESDIR)/$${file}; \
	done ;

	cp $(FILES) $(IMUNESDIR)

	mkdir -p $(ICONSDIR)
	for file in $(ICONS); do \
		cp icons/$${file} $(ICONSDIR); \
	done ;

	mkdir -p $(NORMAL_ICONSDIR)
	for file in $(NORMAL_ICONS); do \
		cp icons/normal/$${file} $(NORMAL_ICONSDIR); \
	done ;

	mkdir -p $(SMALL_ICONSDIR)	
	for file in $(SMALL_ICONS); do \
		cp icons/small/$${file} $(SMALL_ICONSDIR); \
	done ;	

	mkdir -p $(TINY_ICONSDIR)
	for file in $(TINY_ICONS); do \
		cp icons/tiny/$${file} $(TINY_ICONSDIR); \
	done ;
	
vroot:
	sh prepare_vroot.sh

vroot_zfs:
	sh prepare_vroot.sh zfs

vroot_m:
	sh prepare_vroot.sh mini

vroot_m_zfs:
	sh prepare_vroot.sh zfs mini

tarball:
	rm -f ../$(TARBALL_DIR).tar.gz

	mkdir -p ../$(TARBALL_DIR)
	cp $(FILES) $(BINARIES) $(VROOT) Makefile imunes imunes.tcl ../$(TARBALL_DIR)

	mkdir -p ../$(TARBALL_DIR)/icons
	for file in $(ICONS); do \
		cp icons/$${file} ../$(TARBALL_DIR)/icons; \
	done ;

	mkdir -p ../$(TARBALL_DIR)/icons/normal
	for file in $(NORMAL_ICONS); do \
		cp icons/normal/$${file} ../$(TARBALL_DIR)/icons/normal; \
	done ;

	mkdir -p ../$(TARBALL_DIR)/icons/small
	for file in $(SMALL_ICONS); do \
		cp icons/small/$${file} ../$(TARBALL_DIR)/icons/small; \
	done ;
	
	mkdir -p ../$(TARBALL_DIR)/icons/tiny
	for file in $(TINY_ICONS); do \
		cp icons/tiny/$${file} ../$(TARBALL_DIR)/icons/tiny; \
	done ;

	cd .. && tar czfv $(TARBALL_DIR).tar.gz $(TARBALL_DIR)
	rm -r ../$(TARBALL_DIR) 

release:
	rm -f ../$(RELEASE_DIR).tar.gz

	mkdir -p ../$(RELEASE_DIR)
	cp $(FILES) $(BINARIES) $(VROOT) Makefile imunes imunes.tcl ../$(RELEASE_DIR)

	mkdir -p ../$(RELEASE_DIR)/icons
	for file in $(ICONS); do \
		cp icons/$${file} ../$(RELEASE_DIR)/icons; \
	done ;

	mkdir -p ../$(RELEASE_DIR)/icons/normal
	for file in $(NORMAL_ICONS); do \
		cp icons/normal/$${file} ../$(RELEASE_DIR)/icons/normal; \
	done ;

	mkdir -p ../$(RELEASE_DIR)/icons/small
	for file in $(SMALL_ICONS); do \
		cp icons/small/$${file} ../$(RELEASE_DIR)/icons/small; \
	done ;
	
	mkdir -p ../$(RELEASE_DIR)/icons/tiny
	for file in $(TINY_ICONS); do \
		cp icons/tiny/$${file} ../$(RELEASE_DIR)/icons/tiny; \
	done ;

	cd .. && tar czfv $(RELEASE_DIR).tar.gz $(RELEASE_DIR)
	rm -r ../$(RELEASE_DIR) 
