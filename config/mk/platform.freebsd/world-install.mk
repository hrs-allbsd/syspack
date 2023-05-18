#
# world-install.mk: Plugin for building FreeBSD world
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
.if !target(__<world-install.mk>__)
__<world-install.mk>__:
.endif

MERGEMASTER_CMD?=	/usr/sbin/mergemaster
MERGEMASTER_FLAGS?=	-U -i
ETCUPDATE_CMD?=		/usr/sbin/etcupdate

VARS.world+= \
	WORLD_DESTDIR

.if defined(WORLD_SRCDIR) && !empty(WORLD_SRCDIR) && \
    exists(${WORLD_SRCDIR}) && \
    defined(WORLD_DESTDIR) && !empty(WORLD_DESTDIR)

VARS.world+= \
	MERGEMASTER_FLAGS

_TARGETS.world-install=	\
		installworld \
		destroyworld \
		world-installworld \
		world-installkernel \
		mergemaster \
		etcupdate \
		etcupdate-diff \
		etcupdate-status

destroyworld.DESC=	destro the system in ${WORLD_DESTDIR}
#
# make installworld and installkernel.
# Populate ${ETCUPDATE_DBDIR} if not yet.
#
${WORLD_INSTALL_TARGETS}::
	@if [ -r ${WORLD_OBJDIR_${.TARGET:S/^world-install//:tu}_DONE} ]; then \
	    cd ${_SRCDIR} && \
	        _logbase="${.TARGET}-${WORLD_OBJDIR_REL}" && \
	        _log="$${_logbase}-$$(${DATE_CMD} "+%Y%m%d-%H%M%S").log" && \
		if ${WMAKE} ${.TARGET:S/^world-//} | \
		    (${LOG_PROGRESS} \
		     "logfile: $${_log}.tmp" \
		     "Running ${.TARGET:S/^world-//}..." \
		     "$${_logbase}*.log" \
		     "$${_log}.tmp" \
		     "^make.*: stopped in" \
		    ); then \
			tail -5 ${LOGDIR}/$${_log}.tmp; \
			mv ${LOGDIR}/$${_log}.tmp ${LOGDIR}/$${_log}; \
		else \
		    tail ${LOGDIR}/$${_log}.tmp && \
		    echo "==> Error.  See ${LOGDIR}/$${_log}.tmp:"; \
		    false; \
		fi && \
		if [ ${.TARGET} = "world-installworld" ]; then \
		    if [ ! -r ${ETCUPDATE_DBDIR} ]; then \
			cd ${.CURDIR} && ${MAKE} etcupdate-build && \
			mkdir -p ${ETCUPDATE_DBDIR}/current && \
			cd ${.CURDIR} && ${MAKE} etcupdate-run && \
			rmdir ${ETCUPDATE_DBDIR}/old && \
			rm -f ${ETCUPDATE_DBDIR}/old.files && \
			cd ${.CURDIR} && ${MAKE} etcupdate-extract; \
		    else \
			echo "===> Running 'etcupdate build'..."; \
			cd ${.CURDIR} && ${MAKE} etcupdate-build && \
			echo "===> Running 'etcupdate'..."; \
			cd ${.CURDIR} && ${MAKE} etcupdate-run; \
		    fi; \
		fi; \
	else \
		echo "Do 'make world{,-buildworld,-buildkernel}' first." && \
		false; \
	fi

installworld: root-check
	@( \
	_yes() { \
	${WORLD_INSTALL_TARGETS:C|(.+)|cd ${.CURDIR} \&\& ${MAKE} \1 \&\&|} true; \
	}; \
	${CHECKYESNO} \
	"The new world ${_KERN_MESSAGE} will be installed into ${WORLD_DESTDIR}."; \
	)
installkernel: root-check
	@( \
	_yes() { \
	${KERNEL_INSTALL_TARGETS:C|(.+)|cd ${.CURDIR} \&\& ${MAKE} \1 \&\&|} true; \
	}; \
	${CHECKYESNO} \
	"The ${WORLD_KERNCONF} kernel will be installed into ${WORLD_DESTDIR}."; \
	)
destroyworld: root-check
	@if [ -r ${WORLD_DESTDIR} ]; then \
	( \
	_yes() { \
		chflags -R noschg ${WORLD_DESTDIR} && \
		rm -rf ${WORLD_DESTDIR}; \
		echo "done."; \
	}; \
	${CHECKYESNO} \
	     "The installed world in ${WORLD_DESTDIR} will be removed."; \
	); \
	else \
		echo "There is no world to be destroyed in ${WORLD_DESTDIR}"; \
	fi
.endif
#
# etcupdate
# XXX: incomplete
#
ETCUPDATE_DBDIR=	${WORLD_DESTDIR:tA}/var/db/etcupdate
ETCUPDATE_TARBALL=	${ETCUPDATE_DBDIR}/current.tar.bz2

etcupdate-build:: root-check
	${ETCUPDATE_CMD} build \
	    -d ${WORLD_DESTDIR:tA}/var/db/etcupdate \
	    -s ${_SRCDIR:tA} \
	    ${ETCUPDATE_TARBALL}

etcupdate-extract:: root-check
	@${ETCUPDATE_CMD} extract \
	    -d ${WORLD_DESTDIR:tA}/var/db/etcupdate \
	    -t ${ETCUPDATE_TARBALL}

etcupdate-diff etcupdate-status etcupdate-resolve:: root-check
	@${ETCUPDATE_CMD} ${.TARGET:S/^etcupdate-//} \
	    -d ${WORLD_DESTDIR:tA}/var/db/etcupdate \
	    -D ${WORLD_DESTDIR:tA}

etcupdate: root-check
	@echo "etcupdate will run against ${WORLD_DESTDIR}."; \
	    echo -n "OK? [y/d(dry-run)/N]: "; \
	    read ans; \
	    case $$ans in \
	    [Yy]) \
		cd ${.CURDIR} && ${WMAKE} etcupdate-run; \
	    ;; \
	    [Dd]) \
		cd ${.CURDIR} && ${WMAKE} etcupdate-dry-run; \
	    ;; \
	    *) \
		echo "Abort."; \
	    esac

etcupdate-run: root-check
	${ETCUPDATE_CMD} \
	    -d ${WORLD_DESTDIR:tA}/var/db/etcupdate \
	    -D ${WORLD_DESTDIR:tA}

etcupdate-dry-run: root-check
	${ETCUPDATE_CMD} -n \
	    -d ${WORLD_DESTDIR:tA}/var/db/etcupdate \
	    -D ${WORLD_DESTDIR:tA}
#
# mergemaster
# XXX: incomplete
#
mergemaster: world-check root-check
	@${MERGEMASTER_CMD} \
	    -m ${_SRCDIR:tA} \
	    -D ${WORLD_DESTDIR:tA} \
	    -t ${WORLD_OBJDIR:tA}/.mergemaster \
	    -p \
	 && ${MERGEMASTER_CMD} ${MERGEMASTER_FLAGS} \
	    -m ${_SRCDIR:tA} \
	    -D ${WORLD_DESTDIR:tA} \
	    -t ${WORLD_OBJDIR:tA}/.mergemaster
