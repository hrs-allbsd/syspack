#
# world-patch.mk: Plugin for patching FreeBSD source
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
.if !target(__<world-patch.mk>__)
__<world-patch.mk>__:
.endif

VARS.world+= \
	WORLD_PATCHES
_TARGETS.world=		world-patch
world-patch.DESC=	patch the source files

.if defined(WORLD_PATCHES) && !empty(WORLD_PATCHES)
.  if ${.CURDIR} != ${.OBJDIR}
WORLD_PATCHES:=	${WORLD_PATCHES:M/*} ${WORLD_PATCHES:N/*:S,^,${.OBJDIR}/,}
.  else
WORLD_PATCHES:=	${WORLD_PATCHES:M/*} ${WORLD_PATCHES:N/*:S,^,${.CURDIR}/,}
.  endif
.  if !empty(WORLD_SRCDIR)
.    if exists(${WORLD_SRCDIR})
world-patch:
	cd ${WORLD_SRCDIR} && ${CAT_CMD} ${WORLD_PATCHES} | ${PATCH_CMD}
world-patch-dryrun:
	cd ${WORLD_SRCDIR} && ${CAT_CMD} ${WORLD_PATCHES} | ${PATCH_CMD} -C
.    else
world-patch world-patch-dryrun:
	@echo "WORLD_SRCDIR (${WORLD_SRCDIR}) is not found"
.    endif
.  endif
.else
world-patch world-patch-dryrun:
	# do nothing
.endif
.ORDER: world-fetch world-patch \
	world-patch-dryrun \
	world-buildworld \
	world-buildworld-noclean \
	world-buildkernel \
	world-buildkernel-noclean \
	${WORLD_INSTALL_TARGETS} \
	${KERNEL_INSTALL_TARGETS}
