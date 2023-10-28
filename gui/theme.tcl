#
# Copyright 2010-2013 University of Zagreb.
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

# $Id: theme.tcl 114 2023-08-26 11:42 jromero17 $


#
# Imunes theme
#

global defaultFontSize
set defaultFontSize 9

ttk::style theme create imunes -parent clam

font create imnDefaultFont -family TkDefaultFont -size $defaultFontSize
option add *font imnDefaultFont

namespace eval ttk::theme::imunes {
    variable colors 
    array set colors {
	-disabledfg	"#999999"
	-frame  	"#d9d9d9"
	-gnome_frame  	"#edeceb"
	-window  	"#ffffff"
	-dark		"#cfcdc8"
	-darker 	"#bab5ab"
	-darkest	"#9e9a91"
	-lighter	"#eeebe7"
	-lightest 	"#ffffff"
	-selectbg	"#4a6984"
	-selectfg	"#ffffff"
	-menubg		"#d9d9d9"
	-menuabg	"#ececec"
	-menufg		"#000000"
    }

    ttk::style theme settings imunes {

	ttk::style configure "." \
	    -background $colors(-frame) \
	    -foreground black \
	    -bordercolor $colors(-darkest) \
	    -darkcolor $colors(-dark) \
	    -lightcolor $colors(-lighter) \
	    -troughcolor $colors(-darker) \
	    -selectbackground $colors(-selectbg) \
	    -selectforeground $colors(-selectfg) \
	    -selectborderwidth 0 \
	    -font imnDefaultFont \
	    ;

	ttk::style map "." \
	    -background [list disabled $colors(-frame) \
			     active $colors(-lighter)] \
	    -foreground [list disabled $colors(-disabledfg)] \
	    -selectbackground [list  !focus $colors(-darkest)] \
	    -selectforeground [list  !focus white] \
	    ;
	# -selectbackground [list  !focus "#847d73"]

	ttk::style configure TButton \
	    -anchor center -width -8 -padding "2 2" -relief raised
	ttk::style map TButton \
	    -background [list \
			     disabled $colors(-frame) \
			     pressed $colors(-darker) \
			     active $colors(-lighter)] \
	    -lightcolor [list pressed $colors(-darker)] \
	    -darkcolor [list pressed $colors(-darker)] \
	    -bordercolor [list alternate "#000000"] \
	    ;

	ttk::style configure Toolbutton \
	    -anchor center -padding 1 -relief flat -padx 2
	ttk::style map Toolbutton \
	    -relief [list \
		    disabled flat \
		    selected sunken \
		    pressed sunken \
		    active raised] \
	    -background [list \
		    disabled $colors(-frame) \
		    pressed $colors(-darker) \
		    active $colors(-lighter)] \
	    -lightcolor [list pressed $colors(-darker)] \
	    -darkcolor [list pressed $colors(-darker)] \
	    ;

	ttk::style configure TCheckbutton \
	    -indicatorbackground "#ffffff" \
	    -indicatormargin {1 1 4 1} \
	    -padding 2 ;
	ttk::style configure TRadiobutton \
	    -indicatorbackground "#ffffff" \
	    -indicatormargin {1 1 4 1} \
	    -padding 2 ;
	ttk::style map TCheckbutton -indicatorbackground \
	    [list  disabled $colors(-frame)  pressed $colors(-frame)]
	ttk::style map TRadiobutton -indicatorbackground \
	    [list  disabled $colors(-frame)  pressed $colors(-frame)]

	ttk::style configure TMenubutton \
	    -width -11 -padding 55 -relief raised

	ttk::style configure TEntry -padding 1 -insertwidth 1
	ttk::style map TEntry \
	    -background [list  readonly $colors(-frame)] \
	    -bordercolor [list  focus $colors(-selectbg)] \
	    -lightcolor [list  focus "#6f9dc6"] \
	    -darkcolor [list  focus "#6f9dc6"] \
	    ;

	ttk::style configure TCombobox -padding 1 -insertwidth 1
	ttk::style map TCombobox \
	    -background [list active $colors(-lighter) \
			     pressed $colors(-lighter)] \
	    -fieldbackground [list {readonly focus} $colors(-selectbg) \
				  readonly $colors(-frame)] \
	    -foreground [list {readonly focus} $colors(-selectfg)] \
	    ;
	ttk::style configure ComboboxPopdownFrame \
	    -relief solid -borderwidth 1

	ttk::style configure TSpinbox -arrowsize 10 -padding {2 0 10 0}
	ttk::style map TSpinbox \
	    -background [list  readonly $colors(-frame)] \
            -arrowcolor [list disabled $colors(-disabledfg)]

	ttk::style configure TNotebook.Tab -padding {6 2 6 2}
	ttk::style map TNotebook.Tab \
	    -padding [list selected {6 4 6 2}] \
	    -background [list selected $colors(-frame) {} $colors(-darker)] \
	    -lightcolor [list selected $colors(-lighter) {} $colors(-dark)] \
	    ;

	# Treeview:
	ttk::style configure Heading \
	    -font TkHeadingFont -relief raised -padding {3}
	ttk::style configure Treeview -background $colors(-window)
	ttk::style map Treeview \
	    -background [list selected $colors(-selectbg)] \
	    -foreground [list selected $colors(-selectfg)] ;

    	ttk::style configure TLabelframe \
	    -borderwidth 2 -relief groove

	ttk::style configure TProgressbar -background $colors(-frame)

	ttk::style configure Sash -sashthickness 6 -gripcount 10
    }
}

########### INI NEW THEME IMUNESDARK ##################

ttk::style theme create imunesdark -parent clam

font create imnDefaultFontdark -family TkDefaultFont -size $defaultFontSize
option add *font imnDefaultFontdark

# dark = color borde de selecciones y barras de desplazamiento
# darker = color fondo barras de desplazamiento
# darkest = color borde se selecciones y barras de desplazamiento completo
# lighter = border de formulario, select, barras de desplazamiento y fondo activo de botones

namespace eval ttk::theme::imunesdark {
    variable colors 
    array set colors {
	-disabledfg	"#999999"
	-frame  	"#33393b"
	-gnome_frame  	"#FF0000"
	-window  	"#ffffff"
	-dark		"#0F7FF2"
	-darker 	"#616161"
	-darkest	"#33393b"
	-lighter	"#0F7FF2"
	-lightest 	"#1b1f20"
	-selectbg	"#4a6984"
	-selectfg	"#1b1f20"
	-menu		"#343434"
	-canvas		"#444444"
	-colorcanvas "#bfc6da"
	-text		"#ffffff"
	-otrocolor	"#0F7FF2"
	-otrocolor1	"#FF32FF"
	-otrocolor2	"#FFA500"
	-otrocolor3	"#90EE90"
	-otrocolor4	"#1b1f20"
	-otrocolor5	"#0F7FF2"
	-arrow      "solid-bg"
    -checkbutton	"roundedrect-check"
    -menubutton   "solid"
    -radiobutton  "circle-circle-hlbg"
    -treeview     "solid"
    -bg.bg           "#33393b"
    -fg.fg           "#ffffff"
    -graphics.color  "#215d9c"
	-menubg		"#343434"
	-menuabg	"#474747"
	-menufg		"#a5a5a5"
    }
	##0F7FF2
	# #1DCAFF
    ttk::style theme settings imunesdark {

	ttk::style configure "." \
	    -background $colors(-frame) \
	    -foreground #F5F5F5 \
	    -bordercolor $colors(-darkest) \
	    -darkcolor $colors(-dark) \
	    -lightcolor $colors(-lighter) \
	    -troughcolor $colors(-darker) \
	    -selectbackground $colors(-selectbg) \
	    -selectforeground $colors(-selectfg) \
	    -selectborderwidth 0 \
	    -font imnDefaultFontdark \
	    -colorcanvas $colors(-colorcanvas) \
	    ;

	ttk::style map "." \
	    -background [list disabled $colors(-frame) \
			     active $colors(-lighter)] \
	    -foreground [list disabled $colors(-disabledfg)] \
	    -selectbackground [list  !focus $colors(-darkest)] \
	    -selectforeground [list  !focus white] \
	    ;
	# -selectbackground [list  !focus "#847d73"]

	ttk::style configure TButton \
	    -anchor center -width -8 -padding "2 2" -relief raised
	ttk::style map TButton \
	    -background [list \
			     disabled $colors(-frame) \
			     pressed $colors(-darker) \
			     active $colors(-lighter)] \
	    -lightcolor [list pressed $colors(-darker)] \
	    -darkcolor [list pressed $colors(-darker)] \
	    -bordercolor [list alternate "#000000"] \
	    ;

	ttk::style configure Toolbutton \
	    -anchor center -padding 1 -relief flat -padx 2
	ttk::style map Toolbutton \
	    -relief [list \
		    disabled flat \
		    selected sunken \
		    pressed sunken \
		    active raised] \
	    -background [list \
		    disabled $colors(-frame) \
		    pressed $colors(-darker) \
		    active $colors(-lighter)] \
	    -lightcolor [list pressed $colors(-darker)] \
	    -darkcolor [list pressed $colors(-darker)] \
	    ;

	ttk::style configure TCheckbutton \
	    -indicatorbackground "#ffffff" \
	    -indicatormargin {1 1 4 1} \
	    -padding 2 ;
	ttk::style configure TRadiobutton \
	    -indicatorbackground "#ffffff" \
	    -indicatormargin {1 1 4 1} \
	    -padding 2 ;
	ttk::style map TCheckbutton -indicatorbackground \
	    [list  disabled $colors(-frame)  pressed $colors(-frame)]
	ttk::style map TRadiobutton -indicatorbackground \
	    [list  disabled $colors(-frame)  pressed $colors(-frame)]

	ttk::style configure TMenubutton \
	    -width -11 -padding 5 -relief raised \
	    -fieldbackground #1b1f20 \
        -foreground #F5F5F5

	ttk::style configure TEntry -padding 1 -insertwidth 1 \
	    -fieldbackground #1b1f20 \
        -foreground #F5F5F5
	ttk::style map TEntry \
	    -background [list  readonly $colors(-frame)] \
	    -bordercolor [list  focus $colors(-selectbg)] \
	    -lightcolor [list  focus "#6f9dc6"] \
	    -darkcolor [list  focus "#6f9dc6"]
	    ;
	# Modifi aqui
	ttk::style configure TCombobox -padding 1 -insertwidth 1 -borderwidth 0 \
	    -fieldbackground #1b1f20 \
        -foreground #F5F5F5
	ttk::style map TCombobox \
	    -background [list active $colors(-lighter) \
			     pressed $colors(-lighter)] \
	    -fieldbackground [list {readonly focus} $colors(-selectbg) \
				  readonly $colors(-frame)] \
	    -foreground [list {readonly focus} $colors(-selectfg)] \
	    ;
	ttk::style configure ComboboxPopdownFrame \
	    -relief solid -borderwidth 0
	# modif aqui
	ttk::style configure TSpinbox -arrowsize 15 -padding {2 0 10 0} -borderwidth 0 \
		-fieldbackground #1b1f20 \
        -foreground #F5F5F5 \
        -background #ffffff
    ttk::style map TSpinbox -background [list  readonly $colors(-frame)] \
            -arrowcolor [list disabled $colors(-disabledfg)]

	ttk::style configure TNotebook.Tab -padding {6 2 6 2} -borderwidth 0
	ttk::style map TNotebook.Tab \
	    -padding [list selected {6 4 6 2}] \
	    -background [list selected $colors(-frame) {} $colors(-darker)] \
	    -lightcolor [list selected $colors(-lighter) {} $colors(-dark)] \
	    ;

	# Treeview:
	ttk::style configure Heading \
	    -font TkHeadingFont -relief raised -padding {3}
	ttk::style configure Treeview -background $colors(-otrocolor4) \
	-fieldbackground $colors(-otrocolor4);
	ttk::style map Treeview \
	    -background [list selected $colors(-selectbg)] \
	    -foreground [list selected $colors(-selectfg)] ;

	ttk::style configure TLabelframe \
	-borderwidth 2 -relief groove 

	ttk::style configure TProgressbar -background $colors(-frame)

	ttk::style configure Sash -sashthickness 6 -gripcount 10
	   
    # tk widgets.
    ttk::style map Menu \
        -background [list active $colors(-lighter)] \
        -foreground [list disabled $colors(-disabledfg)]
    
}

}

########### END NEW THEME IMUNESDARK ##################

namespace eval ttk::theme::black {
  variable version 0.0.1
  variable dir [file dirname [info script]]

  package provide ttk::theme::black $version

  # NB: These colors must be in sync with the ones in black.rdb

  variable colors
  array set colors {
      -disabledfg "#a9a9a9"
      -frame      "#424242"
      -dark       "#222222"
      -darker     "#121212"
      -darkest    "#000000"
      -lighter    "#626262"
      -lightest   "#ffffff"
      -selectbg   "#4a6984"
      -selectfg   "#ffffff"
	-menubg		"#343434"
	-menuabg	"#474747"
	-menufg		"#a5a5a5"
      }

  ttk::style theme create black -parent clam -settings {

    # -----------------------------------------------------------------
    # Theme defaults
    #
    ttk::style configure . \
        -background $colors(-frame) \
        -foreground #ffffff \
        -bordercolor $colors(-darkest) \
        -darkcolor $colors(-dark) \
        -lightcolor $colors(-lighter) \
        -troughcolor $colors(-darker) \
        -selectbackground $colors(-selectbg) \
        -selectforeground $colors(-selectfg) \
        -selectborderwidth 0 \
        -font TkDefaultFont

    ttk::style map "." \
        -background [list disabled $colors(-frame) \
        active $colors(-lighter)] \
        -foreground [list disabled $colors(-disabledfg)] \
        -selectbackground [list  !focus $colors(-darkest)] \
        -selectforeground [list  !focus #ffffff]

    # ttk widgets.
    ttk::style configure TButton \
        -width -8 -padding {5 1} -relief raised
		ttk::style configure TMenubutton \
        -width -11 -padding {5 1} -relief raised
    ttk::style configure TCheckbutton \
        -indicatorbackground "#ffffff" -indicatormargin {1 1 4 1}
    ttk::style configure TRadiobutton \
        -indicatorbackground "#ffffff" -indicatormargin {1 1 4 1}

    ttk::style configure TEntry \
        -fieldbackground #000000 \
        -foreground #ffffff \
        -padding {2 0}
    ttk::style configure TCombobox \
        -fieldbackground #000000 \
        -foreground #ffffff \
        -padding {2 0}
    ttk::style configure TSpinbox -arrowsize 15 -padding {2 0 10 0} -arrowcolor #35b7ff \
		-fieldbackground #000000 \
        -foreground #ffffff \
        -background #ffffff
	
	#ttk::style configure TSpinbox -arrowsize 10 -padding {2 0 10 0}
	#ttk::style map TSpinbox -fieldbackground \
	#    [list readonly $colors(-frame) disabled $colors(-frame)] \
	#    -arrowcolor [list disabled $colors(-disabledfg)]
		
    ttk::style configure TNotebook.Tab \
        -padding {6 2 6 2}

	# AGREGADO AQUI
	# Treeview:
	ttk::style configure Heading \
	    -font TkHeadingFont -relief raised -padding {3}
	ttk::style configure Treeview -background #000000 \
	-fieldbackground #000000;
	ttk::style map Treeview \
	    -background [list selected $colors(-selectbg)] \
	    -foreground [list selected $colors(-selectfg)] ;

    # tk widgets.
    ttk::style map Menu \
        -background [list active $colors(-lighter)] \
        -foreground [list disabled $colors(-disabledfg)]

    ttk::style configure TreeCtrl \
        -background gray30 -itembackground {gray60 gray50} \
        -itemfill #ffffff -itemaccentfill yellow
  }
}

# call with any arguments to skip redraw of canvas
proc switchTheme { args } {
	global currentTheme

	# set default menu colors to default theme, change if any of the dark
	# themes is selected
	option clear
	switch -exact -- $currentTheme {
		"alt" -
		"classic" -
		"default" -
		"clam" -
		"imunes" {
		    option add *font imnDefaultFont
		}
		"imunesdark" -
		"black" {
		    option add *font imnDefaultFontdark
		    option add *Menu.background \
		      [set ::ttk::theme::${currentTheme}::colors(-menubg)]
		    option add *Menu.activeBackground \
		      [set ::ttk::theme::${currentTheme}::colors(-menuabg)]
		    option add *Menu.foreground \
		      [set ::ttk::theme::${currentTheme}::colors(-menufg)]
		}
	}

	ttk::style theme use $currentTheme
	redrawMenu
	if { [llength $args] == 0 } {
	    redrawAll
	}
}
