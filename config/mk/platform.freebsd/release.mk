#
# release.mk: Plugin for FreeBSD release
#
# Copyright (c) 2000-2021 Hiroki Sato <hrs@allbsd.org>
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
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#

# XXX
.if !target(__<release.mk>__)
__<release.mk>__:
.endif

## NEED TO WORK

.if defined(RELEASE) && !empty(RELEASE)
. if ${.CURDIR} == ${.OBJDIR}
.  error "Do 'make obj' first."
. endif
VARS.release=	RELEASE
UNAME_r!=	uname -r
UNAME_s!=	uname -s
RELEASEBASEDIR:=	${GLOBALBASE}/.spx/obj/release
. if !exists(${RELEASEBASEDIR})
.  error "${RELEASEBASEDIR} not found"
. endif
RELEASEROOT_REL:=	${UNAME_s}-${MACHINE}-${UNAME_r}

# Customization
RELEASE_SRCDIR?=	/usr/src
RELEASE_PARTITIONS?=	/:10G \
			/usr:25G \
			/tmp:10G \
			/var:25G

RELEASE_ROOTDIR=	`cat ${.OBJDIR}/.release_rootdir`/R
WMAKE_FLAGS=	-j${NCPU}
WMAKE_ARGS=	DESTDIR=${RELEASE_ROOTDIR} \
		-DNO_ROOT
WMAKE=		make ${WMAKE_FLAGS} ${WMAKE_ARGS}
WMAKE_NOMETA=	make ${WMAKE_FLAGS} ${WMAKE_ARGS} METALOG=/dev/null
MAKE_OBJDIR=	`make -V.OBJDIR || pwd`
# -D: duplicate entries emit warnings, not errors.
# -Z: generate a sparse file.
MAKEFS_CMD=	makefs -D -Z -M 64m -b 50% -f 50%

#
# Create temporary directory for release bits.
#
release: .release_rootdir
.ORDER: .release_rootdir
.release_rootdir:
	cd ${RELEASEBASEDIR} && \
	  make obj && \
	  mkdir -p ${MAKE_OBJDIR}/${RELEASEROOT_REL} && \
	  echo ${MAKE_OBJDIR}/${RELEASEROOT_REL} > ${.OBJDIR}/${.TARGET}
CLEANFILES+=	${.OBJDIR}/${.TARGET}
#
# Populate release image from RELEASE_SRCDIR.
# make buildworld and buildkernel are required in advance.
#
release:
	cd ${RELEASE_SRCDIR} && \
	    if [ ${MAKE_OBJDIR} = `pwd` ]; then \
		echo "World seems not ready in ${RELEASE_SRCDIR}." \
		    "Do 'make buildworld' first."; false; \
	    else \
		${WMAKE} installworld && \
		${WMAKE} installkernel && \
		${WMAKE_NOMETA} distrib-dirs && \
		make _obj SUBDIR_OVERRIDE=etc && \
		make everything SUBDIR_OVERRIDE=etc && \
		${WMAKE_NOMETA} distribution; \
	    fi
	echo `cat .release_rootdir` is ready.
#
# Split METALOG using RELEASE_PARTITIONS
#
.for M in ${RELEASE_PARTITIONS:C/:[^:]+//:S,/,.,g}
. if ${M} == "."
RELEASE_METALOGS+=	METALOG${M}root
METALOG${M}root:
	cat ${RELEASE_ROOTDIR}/METALOG | \
	    sed -e "s/tags=[^ ]*//" | \
	    grep -E "^\./?[^/]+ " \
	    > ${.TARGET}
. else
RELEASE_METALOGS+=	METALOG${M}
METALOG${M}:
	cat ${RELEASE_ROOTDIR}/METALOG | \
	    sed -e "s/tags=[^ ]*//" | \
	    grep "^\./${M:S/.//:S,.,/,g}[ /]" \
	    > ${.TARGET}
. endif
.endfor
CLEANFILES+=	${RELEASE_METALOGS}
metalog: ${RELEASE_METALOGS}
#
# Create UFS images
#
.for M in ${RELEASE_METALOGS}
RELEASE_FS+=	freebsd-${M:S/METALOG.//}.img
freebsd-${M:S/METALOG.//}.img: ${M}
	cd ${RELEASE_ROOTDIR} && \
	    ${MAKEFS_CMD} ${.OBJDIR}/${.TARGET} ${.OBJDIR}/${M}
.endfor
image: ${RELEASE_FS}
CLEANFILES+=	${RELEASE_FS}
.endif
