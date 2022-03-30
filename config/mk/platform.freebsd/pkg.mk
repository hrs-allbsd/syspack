#
# pkg.mk: Plugin for FreeBSD Package Management
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
.if !target(__<pkg.mk>__)
__<pkg.mk>__:
.endif

TARGETS.pkg=	pkg-list

.if defined(JAIL_DIR) && !empty(JAIL_DIR)
PKG_DIR?=	${JAIL_DIR}
.else
PKG_DIR?=	${TARGETHOST_DIR}
.endif
PKG_LIST?=	${PKG_DIR}/pkg-list.txt
PKG_CACHE_DIR?=	${PKG_DIR}/pkg

.if defined(PKG_DIR) && !empty(PKG_DIR)
VARS.pkg=	PKG_LIST PKG_CACHE
PKG_LIST.DESC=	package list
PKG_CACHE_DIR.DESC=	directory for package tarball cache
TARGETS.pkg+=	pkg-list-update \
		pkg-diff \
		pkg-fetch \
		pkg-install \
		pkg-upgrade
.endif

PKG_HOST_CMD=	${SUDO_CMD} /usr/sbin/pkg
PKG_CMD=	${SUDO_CMD} /usr/sbin/pkg
.if defined(JAIL) && !empty(JAIL)
PKG_CMD+=	-j ${JAIL}
.endif
PKG_QUERY_LIST_CMD=	${PKG_CMD} query %n-%v | sort

${PKG_LIST}:
	${PKG_QUERY_LIST_CMD} > ${.TARGET}
${PKG_CACHE_DIR}:
	mkdir ${PKG_CACHE_DIR}

.if empty(JAIL)
_HEADING1_JAIL=	${_HEADING1} "${.TARGET}"
.else
_HEADING1_JAIL=	${_HEADING1} "${.TARGET} (jid=${JAIL})"
.endif

pkg-list:
	@${_HEADING1_JAIL} "(current)"
	-@${PKG_QUERY_LIST_CMD}

.if empty(PKG_LIST)
pkg-diff pkg-fetch pkg-install pkg-upgrade pkg-list-update:
	@echo "No JAIL or TARGETHOST defined."

.else
.if make(pkg-list-update)
.PHONY: ${PKG_LIST}
.endif
pkg-list-update: ${PKG_LIST}

pkg-upgrade: ${PKG_LIST}
	@${_HEADING1_JAIL}
	${PKG_CMD} upgrade
	${MAKE} ${.MAKEFLAGS} pkg-list-update
	${MAKE} ${.MAKEFLAGS} pkg-fetch

pkg-diff: ${PKG_LIST}
	-@${PKG_QUERY_LIST_CMD} | \
	    ${_DIFF_CMD} -L "${_FD}${PKG_LIST:H}${_FE}" \
	    -L "${_FD}(current)${_FE}" ${PKG_LIST} - | ${_DIFF_POST} 

pkg-install: ${PKG_LIST} ${PKG_CACHE_DIR}
	@${_HEADING1_JAIL}
	@${CAT_CMD} ${PKG_LIST} | while read P; do \
	    ${CAT_CMD} ${PKG_CACHE_DIR}/All/$$P.pkg | \
		${PKG_CMD} add - || break; \
	done 

pkg-fetch: ${PKG_LIST} ${PKG_CACHE_DIR}
	@${_HEADING1_JAIL} "(package will be stored in ${PKG_CACHE_DIR:tA}"
	${PKG_HOST_CMD} fetch -q -o ${PKG_CACHE_DIR} $$(${CAT_CMD} ${PKG_LIST})

.endif
