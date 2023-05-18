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
.if !target(__<world-build.mk>__)
__<world-build.mk>__:
.endif

.if defined(WORLD_SRCDIR) && !empty(WORLD_SRCDIR) && exists(${WORLD_SRCDIR})

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
# targets (will be added to TARGETS.world in -post.mk)
#
_TARGETS.world-build=\
		world \
		world-noclean \
		world-buildworld \
		world-buildworld-noclean \
		world-buildkernel \
		world-buildkernel-noclean \
		world-status \
		world-show-params \
		world-build-clean \
		buildworld \
		buildkernel
world-buildworld.DESC=	build world
buildworld.DESC=	build world
world-buildkernel.DESC=	build kernel
buildkernel.DESC=	build kernel
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
	    _log0="$${_logbase}-$$(${DATE_CMD} "+%Y%m%d-%H%M%S")" && \
	    _log="$${_log0}.log" && \
	    _logfull="${LOGDIR}/$${_log}" && \
	    _logfulltmp="$${_logfull}.tmp" && \
	    _oldlogregex="${LOGDIR}/$${_logbase}-[0-9]*.log.tmp"; \
	    _oldlog="$$(echo $${_oldlogregex})"; \
	    if [ "$${_oldlog}" != "$${_oldlogregex}" ]; then \
	        echo "==> build of $${_logbase} seems in progress."; \
		echo "==>   if you are sure that no build is running, "; \
		echo "==>   remove the following temporary log files in ${LOGDIR:tA}: "; \
		realpath $${_oldlog} | while read IN; do \
		    echo "	$${IN#${LOGDIR:tA:Q}/}"; \
		done; \
		echo "==>   You can use 'make world-buildworld-logclean' " \
		    "to remove the stale log files"; \
		false; \
	    elif ${WMAKE} buildworld | ${_BUILDWORLD_LOGGING}; then \
		tail -5 $${_logfulltmp} && \
		${_CREATE_DONE_CMD} > ${.TARGET} && \
		mv $${_logfulltmp} $${_logfull}; \
	    else \
		tail $${_logfulltmp} && \
		echo "==> Error.  See $${_logfulltmp}."; \
		false; \
	    fi

world-buildworld-logclean:
	${_@_}cd ${_SRCDIR} && \
	    _logbase="world-buildworld-${WMAKE_ARGS:M-DNO_CLEAN:S/-DNO_CLEAN/noclean-/}${WORLD_OBJDIR_REL}" && \
	    _oldlogregex="${LOGDIR}/$${_logbase}-[0-9]*.log.tmp"; \
	    _oldlog="$$(echo $${_oldlogregex})"; \
	    if [ "$${_oldlog}" != "$${_oldlogregex}" ]; then \
		realpath $${_oldlog} | while read IN; do \
		    echo "Remove $${IN#${LOGDIR:tA:Q}/}"; \
		    rm -f $${_oldlog}; \
		done; \
	    fi

${WORLD_OBJDIR_KERNEL_DONE}: ${WORLD_OBJDIR}
	${_@_}cd ${_SRCDIR} && \
	    _logbase="world-buildkernel-${WMAKE_ARGS:M-DNO_KERNELCLEAN:S/-DNO_KERNELCLEAN/noclean-/}${WORLD_OBJDIR_REL}" && \
	    _log0="$${_logbase}-$$(${DATE_CMD} "+%Y%m%d-%H%M%S")" && \
	    _log="$${_log0}.log" && \
	    _logfull="${LOGDIR}/$${_log}" && \
	    _logfulltmp="$${_logfull}.tmp" && \
	    _oldlogregex="${LOGDIR}/$${_logbase}-[0-9]*.log.tmp"; \
	    _oldlog="$$(echo $${_oldlogregex})"; \
	    if [ "$${_oldlog}" != "$${_oldlogregex}" ]; then \
	        echo "==> build of $${_logbase} seems in progress."; \
		echo "==>   if you are sure that no build is running, "; \
		echo "==>   remove the following temporary log files in ${LOGDIR:tA}: "; \
		realpath $${_oldlog} | while read IN; do \
		    echo "	$${IN#${LOGDIR:tA:Q}/}"; \
		done; \
		echo "==>   You can use 'make world-buildkernel-logclean' " \
		    "to remove the stale log files"; \
		false; \
	    elif ${WMAKE} buildkernel | ${_BUILDKERNEL_LOGGING}; then \
		tail -5 $${_logfulltmp} && \
		${_CREATE_DONE_CMD} > ${.TARGET} && \
		mv $${_logfulltmp} $${_logfull}; \
	    else \
		tail $${_logfulltmp} && \
		echo "==> Error.  See $${_logfulltmp}."; \
		false; \
	    fi

world-buildkernel-logclean:
	${_@_}cd ${_SRCDIR} && \
	    _logbase="world-buildkernel-${WMAKE_ARGS:M-DNO_CLEAN:S/-DNO_CLEAN/noclean-/}${WORLD_OBJDIR_REL}" && \
	    _oldlogregex="${LOGDIR}/$${_logbase}-[0-9]*.log.tmp"; \
	    _oldlog="$$(echo $${_oldlogregex})"; \
	    if [ "$${_oldlog}" != "$${_oldlogregex}" ]; then \
		realpath $${_oldlog} | while read IN; do \
		    echo "Remove $${IN#${LOGDIR:tA:Q}/}"; \
		    rm -f $${_oldlog}; \
		done; \
	    fi

WORLD_OBJDIR_DONE=	${WORLD_OBJDIR_WORLD_DONE}
WORLD_INSTALL_TARGETS=	world-installworld
KERNEL_INSTALL_TARGETS=	world-installkernel
.if defined(WORLD_KERNCONF) && !empty(WORLD_KERNCONF)
WORLD_OBJDIR_DONE+=	${WORLD_OBJDIR_KERNEL_DONE}
WORLD_INSTALL_TARGETS+=	${KERNEL_INSTALL_TARGETS}
_KERN_MESSAGE=	(including ${WORLD_KERNCONF} kernel)
.endif

.ORDER: world-show-params ${WORLD_OBJDIR_DONE} world-status
world world-noclean: world-show-params ${WORLD_OBJDIR_DONE} world-status
world-buildworld world-buildworld-noclean buildworld buildworld-noclean: \
    world-show-params ${WORLD_OBJDIR_WORLD_DONE} world-status
.if defined(WORLD_KERNCONF)
world-buildkernel world-buildkernel-noclean buildkernel buildkernel-noclean: \
    world-show-params ${WORLD_OBJDIR_KERNEL_DONE} world-status
.else
world-buildkernel world-buildkernel-noclean buildkernel buildkernel-noclean:
	@echo "Define WORLD_KERNCONF first." && false
.endif
world-check:
	@[ -r ${WORLD_OBJDIR_WORLD_DONE} ] || \
	    (echo "Do 'make world{,-buildworld,-buildkernel}' first." && false)
world-status: world-status-build
world-status-build:
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
world-build-clean:
	@( \
	_yes() { \
		rm -rf ${WORLD_OBJDIR}; \
		echo "done."; \
	}; \
	${CHECKYESNO} "A build result of the world in ${WORLD_OBJDIR}."; \
	)
.else
world-build-clean:
	@echo "There is no build result to be cleaned in ${WORLD_OBJDIR}"
.endif

.endif
