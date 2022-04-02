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

## Customization
WORLD_SRCDIR?=	/usr/src
.if empty(WORLD_SRCDIR:M/*) && ${.OBJDIR} != ${.CURDIR}
WORLD_SRCDIR:=	${.CURDIR}/${WORLD_SRCDIR}
.endif
WORLD_DESTDIR?=	${"${JAIL}" != "":?${JBASE}/${JAIL}:/} 
WORLD_KERNCONF?=	GENERIC
.if !defined(WORLD_LABEL) || empty(WORLD_LABEL)
#
# In case of a git repository, the leading 8 letters of the hash 
#
. if exists(${WORLD_SRCDIR}/.git)
WORLD_LABEL!=	cd ${WORLD_SRCDIR} && \
		    ${GIT_CMD} log -n 1 --pretty=format:"%H"
WORLD_LABEL:=	${WORLD_LABEL:C,^(........).*,\1,}
. endif
.endif

VARS.world+= \
	WORLD_SRCDIR \
	WORLD_DESTDIR \
	WORLD_KERNCONF \
	WORLD_TARGET \
	WORLD_TARGET_ARCH \
	WORLD_TAG \
	WORLD_LABEL \
	WORLD_MAKE_CONF \
	WORLD_SRCCONF \
	WORLD_SRC_ENV_CONF \
	MERGEMASTER_FLAGS

MERGEMASTER_CMD?=	/usr/sbin/mergemaster
MERGEMASTER_FLAGS?=	-U -i
WORLD_TARGET?=	${MACHINE}
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

.if !empty(WORLD:M[Yy][Ee][Ss])
VARS.world+=	WORLD_OBJDIR \
		WORLD_ID
_P=		${WORLD_TARGET}
.if ${WORLD_TARGET} != ${WORLD_TARGET_ARCH}
_P:=		${_P}-${WORLD_TARGET_ARCH}
.endif
WORLD_OBJDIRBASE:=	${GLOBALBASE}/.spx/obj/world
WORLD_ID:=	${UNAME_s}-${_P}-${UNAME_r}${"${WORLD_LABEL}" != "":?-${WORLD_LABEL}:}
WORLD_OBJDIR_REL:=	${WORLD_ID}
WORLD_OBJDIR?=		${WORLD_OBJDIRBASE:tA}/${WORLD_OBJDIR_REL}
.if !empty(WORLD_SRCDIR:M/*)	# relative
_SRCDIR=	${WORLD_SRCDIR}
.else
_SRCDIR=	${.CURDIR}/${WORLD_SRCDIR}
.endif
_SYSDIR=	${_SRCDIR}/sys

CHECK+=	world
check-world: .PHONY
	@echo "[WORLD]"; \
	 echo "  WORLD_ID: ${WORLD_ID}"; \
	 echo "  parameters: ${WMAKE_ARGS}"

world-show-params: .PHONY
	@echo "=> build params for ${WORLD_ID}: "; \
	 echo "=> ${WMAKE_ARGS}"

.if !exists(${_SRCDIR})
.error [Error]: ${_SRCDIR}: WORLD_SRCDIR is not found
.endif
UNAME_s!=uname -s
UNAME_r!=sh -c 'VARS_ONLY=1; \
	    SYSDIR=${_SYSDIR:tA}; \
	    . $${SYSDIR}/conf/newvers.sh; \
	    echo "$$RELEASE" \
	'
ETCUPDATE_CMD?=	/usr/sbin/etcupdate

WMAKE_FLAGS=	-j${NCPU}
WMAKE_ENV=	MAKEOBJDIRPREFIX=${WORLD_OBJDIR}
WMAKE_ARGS=	DESTDIR=${WORLD_DESTDIR} \
		__MAKE_CONF=${WORLD_MAKE_CONF} \
		SRCCONF=${WORLD_SRCCONF} \
		SRC_ENV_CONF=${WORLD_SRC_ENV_CONF}
.if ${WORLD_TARGET_ARCH} != ${MACHINE_ARCH} || \
    ${WORLD_TARGET} != ${MACHINE}
WMAKE_ARGS+=	TARGET_ARCH=${WORLD_TARGET_ARCH} \
		TARGET=${WORLD_TARGET}
.endif
.if make(world-noclean) || \
    make(world-buildworld-noclean) || \
    make(world-buildkernel-noclean)
WMAKE_ARGS+=	-DNO_CLEAN -DNO_KERNELCLEAN
.endif
.if defined(WORLD_KERNCONF) && !empty(WORLD_KERNCONF)
WMAKE_ARGS+=	KERNCONF="${WORLD_KERNCONF}"
.endif
WMAKE=		${SETENV} ${WMAKE_ENV} ${MAKE} ${WMAKE_FLAGS} ${WMAKE_ARGS}
M_OBJDIR=	`make -V.OBJDIR || pwd`
#
TARGETS.world=	world \
		world-noclean \
		world-buildworld \
		world-buildworld-noclean \
		world-buildkernel \
		world-buildkernel-noclean \
		world-status \
		world-show-params \
		world-cleanobj \
		destroyworld \
		installworld \
		world-installworld \
		world-installkernel \
		mergemaster \
		etcupdate \
		etcupdate-diff \
		etcupdate-status
#
# Create temporary directory for release bits.
#
${WORLD_OBJDIR}:
	mkdir -p ${.TARGET}
#
# world: buildworld and buildkernel
#
DATE_CMD=	env TZ=UTC /bin/date
WORLD_OBJDIR_WORLD_DONE=${WORLD_OBJDIR}/.world_done
WORLD_OBJDIR_KERNEL_DONE=${WORLD_OBJDIR}/.world_kernel_done
.ORDER: ${WORLD_OBJDIR_WORLD_DONE} ${WORLD_OBJDIR_KERNEL_DONE}

_CREATE_DONE_CMD=(${DATE_CMD} "+%s"; ${DATE_CMD} "+%Y-%m-%d %H:%M:%S")
_BUILDWORLD_LOGGING= (${LOG_PROGRESS} "logfile: $${_log}.tmp" \
		"Running buildworld..." \
		"$${_logbase}*.log" "$${_log}.tmp" \
		"^make.*: stopped in")
_BUILDKERNEL_LOGGING= (${LOG_PROGRESS} "logfile: $${_log}.tmp" \
		"Running buildkernel (${WORLD_KERNCONF})..." \
	 	"$${_logbase}*.log" "$${_log}.tmp" \
		"^make.*: stopped in")

${WORLD_OBJDIR_WORLD_DONE}: ${WORLD_OBJDIR}
	${_@_}cd ${_SRCDIR} && \
	    _logbase="world-buildworld-${WMAKE_ARGS:M-DNO_CLEAN:S/-DNO_CLEAN/noclean-/}${WORLD_OBJDIR_REL}" && \
	    _log="$${_logbase}-$$(${DATE_CMD} "+%Y%m%d-%H%M%S").log" && \
	    if ${WMAKE} buildworld | ${_BUILDWORLD_LOGGING}; then \
		tail -5 ${LOGDIR}/$${_log}.tmp && \
		${_CREATE_DONE_CMD} > ${.TARGET} && \
		mv ${LOGDIR}/$${_log}.tmp ${LOGDIR}/$${_log}; \
	    else \
		tail ${LOGDIR}/$${_log}.tmp && \
		echo "==> Error.  See ${LOGDIR}/$${_log}.tmp:"; \
		false; \
	    fi
${WORLD_OBJDIR_KERNEL_DONE}: ${WORLD_OBJDIR}
	${_@_}cd ${_SRCDIR} && \
	    _logbase="world-buildkernel-${WMAKE_ARGS:M-DNO_KERNELCLEAN:S/-DNO_KERNELCLEAN/noclean-/}${WORLD_OBJDIR_REL}" && \
	    _log="$${_logbase}-$$(${DATE_CMD} "+%Y%m%d-%H%M%S").log" && \
	    if ${WMAKE} buildkernel | ${_BUILDKERNEL_LOGGING}; then \
		tail -5 ${LOGDIR}/$${_log}.tmp && \
		${_CREATE_DONE_CMD} > ${.TARGET} && \
		mv ${LOGDIR}/$${_log}.tmp ${LOGDIR}/$${_log}; \
	    else \
		tail ${LOGDIR}/$${_log}.tmp && \
		echo "==> Error.  See ${LOGDIR}/$${_log}.tmp:"; \
		false; \
	    fi
WORLD_OBJDIR_DONE=	${WORLD_OBJDIR_WORLD_DONE}
WORLD_INSTALL_TARGETS=	world-installworld
.if defined(WORLD_KERNCONF) && !empty(WORLD_KERNCONF)
WORLD_OBJDIR_DONE+=	${WORLD_OBJDIR_KERNEL_DONE}
WORLD_INSTALL_TARGETS+=	world-installkernel
_KERN_MESSAGE=	(including ${WORLD_KERNCONF} kernel)
.endif

.ORDER: world-show-params ${WORLD_OBJDIR_DONE} world-status
world world-noclean: world-show-params ${WORLD_OBJDIR_DONE} world-status
world-buildworld world-buildworld-noclean: \
    world-show-params ${WORLD_OBJDIR_WORLD_DONE} world-status
.if defined(WORLD_KERNCONF)
world-buildkernel world-buildkernel-noclean: \
    world-show-params ${WORLD_OBJDIR_KERNEL_DONE} world-status
.else
world-buildkernel world-buildkernel-noclean:
	@echo "Define WORLD_KERNCONF first." && false
.endif
world-check:
	@[ -r ${WORLD_OBJDIR_WORLD_DONE} ] || \
	    (echo "Do 'make world' first." && false)
world-status:
	@if [ -r ${WORLD_OBJDIR_WORLD_DONE} ]; then \
		_epoch=$$(sed -e "1q" < ${WORLD_OBJDIR_WORLD_DONE}); \
		_time=$$(date -r $$_epoch "+%Y-%m-%d %H:%M:%S %Z"); \
		echo "World (${WORLD_OBJDIR_REL}) is ready. " \
		    "Built at $${_time}"; \
	else \
		echo "World (${WORLD_OBJDIR_REL}) is not ready."; \
	fi
.if defined(WORLD_KERNCONF)
	@if [ -r ${WORLD_OBJDIR_KERNEL_DONE} ]; then \
		_epoch=$$(sed -e "1q" < ${WORLD_OBJDIR_KERNEL_DONE}); \
		_time=$$(date -r $$_epoch "+%Y-%m-%d %H:%M:%S %Z"); \
		echo "Kernel (${WORLD_OBJDIR_REL}) is ready. " \
		    "Built at $${_time}"; \
	else \
		echo "Kernel (${WORLD_OBJDIR_REL}) is not ready."; \
	fi
.endif

.if exists(${WORLD_OBJDIR})
world-cleanobj:
	@( \
	_yes() { \
		rm -rf ${WORLD_OBJDIR}; \
		echo "done."; \
	}; \
	${CHECKYESNO} "A build result of the world in ${WORLD_OBJDIR}."; \
	)
.else
world-cleanobj:
	@echo "There is no build result to be cleaned in ${WORLD_OBJDIR}"
.endif

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
			cd ${.CURDIR} && ${WMAKE} etcupdate-build && \
			mkdir -p ${ETCUPDATE_DBDIR}/current && \
			cd ${.CURDIR} && ${WMAKE} etcupdate-run && \
			rmdir ${ETCUPDATE_DBDIR}/old && \
			rm -f ${ETCUPDATE_DBDIR}/old.files && \
			cd ${.CURDIR} && ${WMAKE} etcupdate-extract; \
		    else \
			echo "===> Running 'etcupdate build'..."; \
			cd ${.CURDIR} && ${WMAKE} etcupdate-build && \
			echo "===> Running 'etcupdate'..."; \
			cd ${.CURDIR} && ${WMAKE} etcupdate-run; \
		    fi; \
		fi; \
	else \
		echo "Do 'make world' first." && false; \
	fi

installworld: root-check
	@( \
	_yes() { \
	${WORLD_INSTALL_TARGETS:C|(.+)|cd ${.CURDIR} \&\& ${MAKE} \1 \&\&|} true; \
	}; \
	${CHECKYESNO} \
	"The new world ${_KERN_MESSAGE} will be installed into ${WORLD_DESTDIR}."; \
	)
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
.endif
