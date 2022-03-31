#
# pkg.mk: Plugin for FreeBSD Package Management
#
# Copyright (c) 2021-2022 Hiroki Sato <hrs@allbsd.org>
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
PKG_CACHE_DIR?=	${PKG_DIR}/pkg
PKG_LIST_TMP?=	${PKG_CACHE_DIR}/pkg-list.txt.tmp
PKG_DB_DIR?=	${PKG_CACHE_DIR}/db.tmp

.if defined(PKG_DIR) && !empty(PKG_DIR)
VARS.pkg=	PKG_LIST \
		PKG_CACHE_DIR
PKG_LIST.DESC=	package list
PKG_CACHE_DIR.DESC=	directory for package tarball cache
TARGETS.pkg+=	\
		pkg-install \
		pkg-diff \
		pkg-upgrade \
		pkg-fetch \
		pkg-trim
.endif

PKG_NONROOT_CMD=	/usr/sbin/pkg
PKG_HOST_CMD=	${SUDO_CMD} ${PKG_NONROOT_CMD}
PKG_HOST_NONROOT_CMD=	${SETENV} PKG_DBDIR=${PKG_DB_DIR} ${PKG_NONROOT_CMD}
PKG_CMD=	${SUDO_CMD} ${PKG_NONROOT_CMD}
.if defined(JAIL) && !empty(JAIL)
PKG_CMD+=	-j ${JAIL}
.endif
PKG_QUERY_SINGLE_CMD=	${PKG_CMD} query %n-%v
PKG_QUERY_LIST_CMD=	${PKG_QUERY_SINGLE_CMD} | sort
PKG_FETCH_CMD=	${SETENV} INSTALL_AS_USER=yes ${PKG_HOST_NONROOT_CMD} fetch
PKG_QUERY_LOCAL_CMD= \
	cd ${PKG_CACHE_DIR}/All && /bin/ls *.pkg | \
	  sed -e 's/.pkg$$//' | \
	  sort

${PKG_CACHE_DIR}:
	mkdir -p ${PKG_CACHE_DIR}/All ${PKG_DB_DIR}

.if empty(JAIL)
_HEADING1_JAIL=	${_HEADING1} "${.TARGET}"
.else
_HEADING1_JAIL=	${_HEADING1} "${.TARGET} (jid=${JAIL})"
.endif

.PHONY: ${PKG_LIST_TMP}
${PKG_LIST_TMP}:: ${PKG_CACHE_DIR}
	-@${PKG_QUERY_LIST_CMD} > ${.TARGET}
CLEANFILES+=	${PKG_LIST_TMP}

pkg-list.DESC=	show a list of the installed packages
pkg-list: ${PKG_CACHE_DIR}
.if !empty(PKG_LIST)
	@${_HEADING1_JAIL} "(PKG_LIST)"
	@echo ${PKG_LIST} | tr " " "\n"
.endif
	@${_HEADING1_JAIL} "(installed packages including the dependencies)"
	-@${PKG_QUERY_LIST_CMD} | tee ${PKG_LIST_TMP}

pkg-install.DESC=	fetch, install, and store packages specified in PKG_LIST
pkg-diff.DESC=	show a diff between packages in work-dir and the installed ones
pkg-upgrade.DESC=	do "pkg upgrade" and pkg-fetch
pkg-reinstall.DESC=	install package stored in work-dir
pkg-fetch.DESC=	fetch package files from the pkg server and store them into work-dir
pkg-trim.DESC=	remove old package files in work-dir

.if empty(PKG_DIR)
pkg-diff pkg-fetch pkg-install pkg-upgrade:
	@echo "No JAIL or TARGETHOST defined."

.else
pkg-upgrade: ${PKG_CACHE_DIR}
	@${_HEADING1_JAIL}
	@${PKG_CMD} upgrade
	@${MAKE} ${.MAKEFLAGS} ${PKG_LIST_TMP}
	@${MAKE} ${.MAKEFLAGS} pkg-fetch

pkg-diff: ${PKG_CACHE_DIR} ${PKG_LIST_TMP}
	@${_HEADING1_JAIL}
	-@${PKG_QUERY_LOCAL_CMD} | \
	    ${_DIFF_CMD} \
		-L "${_FD}(installed but not in work-dir)${_FE}" \
		-L "${_FA}(not installed)${_FE}" \
		${PKG_LIST_TMP} - | ${_DIFF_POST} 

pkg-install: ${PKG_CACHE_DIR}
	@${_HEADING1_JAIL} "(package will be stored in ${PKG_CACHE_DIR:tA}"
.if defined(PKG_LIST) && !empty(PKG_LIST)
	@${_HEADING1_JAIL} "fetch packages"
	@${PKG_FETCH_CMD} -y -d -o ${PKG_CACHE_DIR} ${PKG_LIST}
	@${_HEADING1_JAIL} "install packages"
	@${MAKE} ${.MAKEFLAGS} pkg-reinstall
	@${_HEADING1_JAIL} "update package list"
	@${MAKE} ${.MAKEFLAGS} ${PKG_LIST_TMP}
.endif

pkg-reinstall: ${PKG_CACHE_DIR}
	@${_HEADING1_JAIL}
	@${PKG_QUERY_LOCAL_CMD} | while read P; do \
	    ${CAT_CMD} ${PKG_CACHE_DIR}/All/$$P.pkg | \
		${PKG_CMD} add - || break; \
	done 

pkg-fetch: ${PKG_CACHE_DIR} ${PKG_LIST_TMP}
	@${_HEADING1_JAIL} "(package will be stored in ${PKG_CACHE_DIR:tA}"
	@${PKG_FETCH_CMD} -y -d -o ${PKG_CACHE_DIR} \
	    $$(${CAT_CMD} ${PKG_LIST_TMP})

pkg-trim: ${PKG_CACHE_DIR} ${PKG_LIST_TMP}
	@${PKG_QUERY_LOCAL_CMD} | \
	  diff -u ${PKG_LIST_TMP} - | while read IN; do \
		case "$$IN" in \
		+++*)	;; \
		+*)	echo "$${IN#+}" ;; \
		esac; \
	  done | xargs rm
.endif
