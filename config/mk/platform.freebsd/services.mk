#
# services.mk: plugin for SERVICES.
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
.if !target(__<services.mk>__)
__<services.mk>__:
.endif

TARGETS.services=	services

.if defined(SERVICES) && !empty(SERVICES)
VARS.services=	SERVICES \
		EXTRACOMMANDS
services:
	@echo "services (plugin):" "${SERVICES}"
.else
services:
	@echo "services (plugin):" "(not defined)"
.endif

SERVICE_CMD?=	${SUDO_CMD} /usr/sbin/service
.if defined(JAIL) && !empty(JAIL)
_JAIL_IS_DOWN!=	jls -j ${JAIL} >/dev/null 2>&1 || echo YES
SERVICE?=	${SERVICE_CMD} -j ${JAIL}
.else
SERVICE?=	${SERVICE_CMD}
.endif
#
# Targets: {start,stop,restart,reload,status}-{SERVICES}
#
.for S in ${SERVICES}
. if defined(EXTRACOMMANDS.${S})
VARS.services+=	EXTRACOMMANDS.${S}
. endif
. for A in start stop restart reload status \
    ${EXTRACOMMANDS} ${EXTRACOMMANDS.${S}}
TARGETS.services+=	${S}-${A}
${S}-${A}:
.  if !empty(_JAIL_IS_DOWN)
	@${_HEADING1} "${S}: ${A} (ignored because ${JAIL} is down)"
.  else
	@${_HEADING1} "${S}: ${A}"
	-@${SERVICE} ${S} ${A}
.  endif
${A}: ${S}-${A}
# alias: status = st
.  if ${A} == "status"
st: ${S}-${A}
.  endif
${S}-${A}: pre-${S}-${A}
post-${S}-${A}: ${S}-${A}
.  for P in pre post
.   if !target(${P}-${S}-${A})
${P}-${S}-${A}:
.   endif
.  endfor
.ORDER: pre-${S}-${A} ${S}-${A} post-${S}-${A}
. endfor
.endfor
