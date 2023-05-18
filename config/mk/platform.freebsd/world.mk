#
# world.mk: Plugin for building FreeBSD world
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
.if !target(__<world.mk>__)
__<world.mk>__:
.endif

.if defined(WORLD_SRCDIR) && !empty(WORLD_SRCDIR)
#
# Replace @ with GLOBALBASE
#
WORLD_SRCDIR:=	${WORLD_SRCDIR:C,^@,${GLOBALBASE:tA}/world,}
.  if empty(WORLD_SRCDIR:M/*)
.    if ${.OBJDIR} != ${.CURDIR}
WORLD_SRCDIR:=	${.CURDIR}/world/${WORLD_SRCDIR}
_WORLD_SRCDIR_README=	${.CURDIR}/world/README
.    else
WORLD_SRCDIR:=	world/${WORLD_SRCDIR}
_WORLD_SRCDIR_README=	world/README
.    endif
.  endif
.endif
#
# Normalize WORLD_DESTDIR using ${JAIL_BASE}/${JAIL} if any 
#
WORLD_DESTDIR:=	${"${JAIL}" != "":?${JAIL_BASE}/${JAIL}:}${WORLD_DESTDIR}

WORLD_KERNCONF?=	GENERIC

VARS.world+= \
	WORLD_SRCDIR

.if defined(WORLD_SRCDIR) && !empty(WORLD_SRCDIR)
VARS.world+=	\
	WORLD_DESTDIR \
	WORLD_OBJDIR \
	WORLD_ID \
	WORLD_KERNCONF \
	WORLD_TARGET \
	WORLD_TARGET_ARCH \
	WORLD_LABEL \
	WORLD_MAKE_CONF \
	WORLD_SRCCONF \
	WORLD_SRC_ENV_CONF

WORLD_TARGET?=		${MACHINE}
WORLD_TARGET_ARCH?=	${MACHINE_ARCH}
# /etc/make.conf
WORLD_MAKE_CONF?=	/dev/null
# /etc/src.conf
WORLD_SRCCONF?=		/dev/null
# /etc/src-env.conf
WORLD_SRC_ENV_CONF?=	/dev/null

# Normalize pathnames for the config files.  Use ${.CURDIR}.
.if empty(WORLD_MAKE_CONF:M/*)
WORLD_MAKE_CONF:=	${.CURDIR}/${WORLD_MAKE_CONF}
.endif
.if empty(WORLD_SRCCONF:M/*)
WORLD_SRCCONF:=		${.CURDIR}/${WORLD_SRCCONF}
.endif
.if empty(WORLD_SRC_ENV_CONF:M/*)
WORLD_SRC_ENV_CONF:=	${.CURDIR}/${WORLD_SRC_ENV_CONF}
.endif

_P=		${WORLD_TARGET}
.if ${WORLD_TARGET} != ${WORLD_TARGET_ARCH}
_P:=		${_P}-${WORLD_TARGET_ARCH}
.endif

.if !empty(WORLD_SRCDIR:M/*)	# relative
_SRCDIR=	${WORLD_SRCDIR}
.else
_SRCDIR=	${.CURDIR}/${WORLD_SRCDIR}
.endif
_SYSDIR=	${_SRCDIR}/sys

M_OBJDIR=	`make -V.OBJDIR || pwd`

.if (!defined(WORLD_LABEL) || empty(WORLD_LABEL)) && \
    exists(${WORLD_SRCDIR}/.git)
#
# In case of a git repository, the leading 8 letters of the hash 
#
WORLD_LABEL!=	cd ${WORLD_SRCDIR} && \
		    ${GIT_CMD} log -n 1 --pretty=format:"%H" 2>/dev/null
WORLD_LABEL:=	${WORLD_LABEL:C,^(........).*,\1,}
UNAME_r!=sh -c 'VARS_ONLY=1; \
	    SYSDIR=${_SYSDIR:tA}; \
	    . $${SYSDIR}/conf/newvers.sh; \
	    echo "$$RELEASE" \
	'
.endif

WORLD_ID:=	${UNAME_s}-${_P}-${UNAME_r}${"${WORLD_LABEL}" != "":?-${WORLD_LABEL}:}
WORLD_OBJDIR_REL:=	${WORLD_ID}
WORLD_OBJDIRBASE:=	${GLOBALBASE}/.spx/obj/world
WORLD_OBJDIR?=		${WORLD_OBJDIRBASE:tA}/${WORLD_OBJDIR_REL}

CHECK+=	world
check-world: .PHONY
	@echo "[WORLD]"; \
	 echo "  WORLD_ID: ${WORLD_ID}"; \
	 echo "  parameters: ${WMAKE_ARGS}"

world-show-params: .PHONY
	@echo "=> build params for ${WORLD_ID}: "; \
	 echo "=> ${WMAKE_ARGS}"

world-status:
.if defined(WORLD_SRCDIR)
	@echo "WORLD_SRCDIR: ${WORLD_SRCDIR:tA}"
.endif
.if defined(WORLD_DESTDIR)
	@echo "WORLD_DESTDIR: ${DESTDIR}${WORLD_DESTDIR:tA}"
.endif

.endif
