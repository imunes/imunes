#
# Copyright 2026- University of Zagreb.
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

proc _getAnnotationType { annotation_cfg } {
	return [_cfgGet $annotation_cfg "type"]
}

proc _setAnnotationType { annotation_cfg type } {
	return [_cfgSet $annotation_cfg "type" $type]
}

proc _getAnnotationCanvas { annotation_cfg } {
	return [_cfgGet $annotation_cfg "canvas"]
}

proc _setAnnotationCanvas { annotation_cfg canvas_id } {
	return [_cfgSet $annotation_cfg "canvas" $canvas_id]
}

proc _getAnnotationColor { annotation_cfg } {
	return [_cfgGet $annotation_cfg "color"]
}

proc _setAnnotationColor { annotation_cfg color } {
	return [_cfgSet $annotation_cfg "color" $color]
}

proc _getAnnotationLabel { annotation_cfg } {
	return [_cfgGet $annotation_cfg "label"]
}

proc _setAnnotationLabel { annotation_cfg labeltext } {
	return [_cfgSet $annotation_cfg "label" $labeltext]
}

proc _getAnnotationLabelColor { annotation_cfg } {
	return [_cfgGet $annotation_cfg "labelcolor"]
}

proc _setAnnotationLabelColor { annotation_cfg labelcolor } {
	return [_cfgSet $annotation_cfg "labelcolor" $labelcolor]
}

proc _getAnnotationBorderColor { annotation_cfg } {
	return [_cfgGet $annotation_cfg "bordercolor"]
}

proc _setAnnotationBorderColor { annotation_cfg bordercolor } {
	return [_cfgSet $annotation_cfg "bordercolor" $bordercolor]
}

proc _getAnnotationWidth { annotation_cfg } {
	return [_cfgGet $annotation_cfg "width"]
}

proc _setAnnotationWidth { annotation_cfg width } {
	return [_cfgSet $annotation_cfg "width" $width]
}

proc _getAnnotationRad { annotation_cfg } {
	return [_cfgGet $annotation_cfg "rad"]
}

proc _setAnnotationRad { annotation_cfg rad } {
	return [_cfgSet $annotation_cfg "rad" $rad]
}

proc _getAnnotationFont { annotation_cfg } {
	return [_cfgGet $annotation_cfg "font"]
}

proc _setAnnotationFont { annotation_cfg font } {
	return [_cfgSet $annotation_cfg "font" $font]
}

proc _getAnnotationCoords { annotation_cfg } {
	return [_cfgGet $annotation_cfg "iconcoords"]
}

proc _setAnnotationCoords { annotation_cfg coords } {
	return [_cfgSet $annotation_cfg "iconcoords" $coords]
}
