#
# world-tarballs.mk: Plugin for packaging FreeBSD world into tarballs
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
.if !target(__<world-tarballs.mk>__)
__<world-tarballs.mk>__:
.endif

#.if !targrt(obj)
#.include <bsd.obj.mk>
#.endif

.if !empty(WORLD_DISTRIBUTE:Mtarballs)
. if !make(obj) && ${.OBJDIR} == ${.CURDIR}
.  error "Do 'make obj' first."
. endif

VARS.world-tarballs=	WORLD_TARBALLS \
			WORLD_TARBALLS_DESTDIR \
			WORLD_WORLD_TARBALLS \
			WORLD_KERNEL_TARBALLS
TARGETS.world-tarballs=	world-tarballs \
			world-world-tarballs \
			world-kernel-tarballs

DESC.world-tarballs= \
	generates tarballs of the FreeBSD base system (base.txz). \
	This depends on "world" plugin.

WORLD_TARBALLS_DESTDIR?=	${.CURDIR}
#
# Use ${.CURDIR} even if DESTDIR is relative and ${.OBJDIR} != ${.CURDIR}.
#
.if empty(WORLD_TARBALLS_DESTDIR:M/*)
WORLD_TARBALLS_DESTDIR:=	${.CURDIR}/${WORLD_TARBALLS_DESTDIR}
.endif
#
#
#
WTMAKE=	${WMAKE:NDESTDIR=*} \
	DESTDIR=${.OBJDIR} \
	DISTDIR=dist \
	-DNO_ROOT
WTSRCMAKE=	cd ${_SRCDIR} && ${WTMAKE} -f Makefile.inc1

# workaround which does not work well actually...
#	DESTDIR=/ \
#	DISTDIR=${.OBJDIR}/dist \

# Import variables
# XXX: NO_INSTALL* and MK_DEBUG_FILES are not supported yet
#
.for V in EXTRA_DISTRIBUTIONS \
	DEBUG_DISTRIBUTIONS \
	BUILDKERNELS \
	MK_DEBUG_FILES \
	NO_INSTALLKERNEL \
	NO_INSTALLEXTRAKERNELS
_${V}!=	${WTSRCMAKE} -V${V}
.endfor

WORLD_WORLD_TARBALLS?=	${WORLD_WORLD_TARBALLS_ALL}
WORLD_KERNEL_TARBALLS?=	${WORLD_KERNEL_TARBALLS_ALL}
WORLD_TARBALLS?=	${WORLD_WORLD_TARBALLS} \
			${WORLD_KERNEL_TARBALLS}
WORLD_WORLD_TARBALLS_ALL= \
			base \
			${_EXTRA_DISTRIBUTIONS} \
			${_DEBUG_DISTRIBUTIONS:S/$/-dbg/}
WORLD_KERNEL_TARBALLS_ALL= \
			kernel \
			kernel-dbg
.if ${_BUILDKERNELS:[#]} > 1
WORLD_KERNEL_TARBALLS_ALL+=
			${_BUILDKERNELS:[2..-1]:S/^/kernel./} \
			${_BUILDKERNELS:[2..-1]:S/^/kernel./:S/$/-dbg/}
.endif
_WORLD_TARBALLS=	${WORLD_TARBALLS:S/$/.txz/}
_WORLD_WORLD_TARBALLS=	${WORLD_WORLD_TARBALLS:S/$/.txz/}
_WORLD_KERNEL_TARBALLS=	${WORLD_KERNEL_TARBALLS:S/$/.txz/}

# XXX: TODO: logging
_DISTRIBUTEWORLD_LOGGING= (${LOG_PROGRESS} "logfile: $${_log}.tmp" \
		"Running buildworld..." \
		"$${_logbase}*.log" "$${_log}.tmp" \
		"^make.*: stopped in")
#
# base and kernel are hard-coded distribution names
#
base.txz kernel.txz:
	${_@_}if [ ! -r ${WORLD_OBJDIR_WORLD_DONE} ]; then \
		echo "Do 'make world' first." && false; \
	else \
	    cd ${_SRCDIR} && \
		${WTMAKE} distribute${.TARGET:S/base/world/:S/.txz$//} && \
		${WTMAKE} package${.TARGET:S/base/world/:S/.txz$//} && \
		cp ${.OBJDIR}/dist/${.TARGET} \
		    ${WORLD_TARBALLS_DESTDIR}/${.TARGET}; \
	fi

${_WORLD_WORLD_TARBALLS:Nbase.txz}: base.txz
	cp ${.OBJDIR}/dist/${.TARGET} ${WORLD_TARBALLS_DESTDIR}/${.TARGET}
${_WORLD_KERNEL_TARBALLS:Nkernel.txz}: kernel.txz
	cp ${.OBJDIR}/dist/${.TARGET} ${WORLD_TARBALLS_DESTDIR}/${.TARGET}

world-tarballs: ${_WORLD_TARBALLS}
world-world-tarballs: ${_WORLD_WORLD_TARBALLS} 
world-kernel-tarballs:  ${_WORLD_KERNEL_TARBALLS}

CLEANFILES+=	${_WORLD_TARBALLS:S,^,${WORLD_TARBALLS_DESTDIR}/,}

.endif
