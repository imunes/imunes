# $FreeBSD:

PORTNAME=		imunes
DISTVERSIONPREFIX=	v
DISTVERSION=		3.0.0b
CATEGORIES=		net

MAINTAINER=		denis.sale@gmail.com
COMMENT=		Integrated MUltiprotocol Network Emulator/Simulator

NO_CHECKSUM=		yes # use distfiles file for checksums when not using master

BUILD_DEPENDS=		git:${PORTSDIR}/devel/git
RUN_DEPENDS=		tclsh8.6:${PORTSDIR}/x11-toolkits/tk86 \
			wish8.6:${PORTSDIR}/x11-toolkits/tk86 \
			convert:${PORTSDIR}/graphics/ImageMagick7 \
			wireshark:${PORTSDIR}/net/wireshark \
			socat:${PORTSDIR}/net/socat \
			dtplite:${PORTSDIR}/devel/tcllib

WRKSRC=			${WRKDIR}/imunes-${DISTVERSION}
USE_GITHUB=		yes
GH_ACCOUNT=		imunes
GH_PROJECT=		imunes
DISTFILES=		imunes-${DISTVERSION}.tar.gz

USES=			kmod

do-build:
	mkdir -p ${STAGEDIR}${KMODDIR}
	cd ${WRKSRC} && make PREFIX=${STAGEDIR}/usr/local KMODDIR=${STAGEDIR}${KMODDIR} install
	find ${STAGEDIR} -type f -iname '*' | xargs sed -i '' 's#''${STAGEDIR}''##g'

do-install:

.include <bsd.port.mk>
