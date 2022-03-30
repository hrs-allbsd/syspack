#
# diff.f.mk: Plugin for diff
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
.if !target(__<diff.f.mk>__)
__<diff.f.mk>__:
.endif

.for _tag _group _dir _file in ${_tag} ${_group} ${_dir} ${_file}
_DESTDIR_${_dir:hash}=${DESTDIR}${_dir}
. if !target(${_file:T})
#
# static file
#
#
# XXX: SUDO_CMD is expensive.  _exists is for caching the results.
#
diff-${_tag}::
	${_@_}\
	_dstdir="${_DESTDIR_${_dir:hash}:C,[/]+,/,g}"; \
	if [ ${.CURDIR} != ${.OBJDIR} ]; then \
	    if [ -r ${.OBJDIR}/${_file:T} ]; then \
		_label="${_FA}./${_file:T} (obj-dir)${_FE}"; \
		_src="${.OBJDIR}/${_file:T}"; \
	    elif [ -r ${.CURDIR}/${_file:T} ]; then \
		_label="${_FA}./${_file:T} (work-dir)${_FE}"; \
		_src="${.CURDIR}/${_file:T}"; \
	    else \
		_label="${_FD}./${_file:T} ${_FLW}(*** missing ***)${_FE}"; \
		_src="/dev/null"; \
	    fi; \
	else \
	    if [ -r ${.CURDIR}/${_file:T} ]; then \
		_label="${_FA}./${_file:T} (work-dir)${_FE}"; \
		_src="${.OBJDIR}/${_file:T}"; \
	    else \
		_label="${_FA}./${_file:T} ${_FLW}(*** missing ***)${_FE}"; \
		_src="/dev/null"; \
	    fi; \
	fi; \
	_exists=$$(${SUDO_CMD} ${SH_CMD} -c \
	    "if [ -e $${_dstdir}/${_file:T} -a \
	    -r $${_dstdir}/${_file:T} ]; then \
	      if ${CMP_CMD} $${_dstdir}/${_file:T} $${_src}; then \
	        echo 2; \
	      else \
	        echo 1; \
	      fi; \
	    fi"); \
	if   [ "$$_exists" = 2 ]; then \
	    :; \
	elif [ "$$_exists" = 1 ]; then \
	    ${_HEADING1} "diff $${_dstdir}/${_file:T} ${_file:T}:"; \
	    ${SUDO_CMD} ${CAT_CMD} $${_dstdir}/${_file:T} | ${_DIFF_CMD} \
	      -L "${_FD}$${_dstdir}/${_file:T} (stock)${_FE}" - \
	      -L "$${_label}" $${_src} | ${_DIFF_POST} || :; \
	elif ${SUDO_CMD} ${TEST_CMD} ! -e $${_dstdir}/${_file:T}; then \
	    ${_HEADING1} "diff $${_dstdir}/${_file:T} ${_file:T}:"; \
	    ${_DIFF_CMD} -L "${_FD}$${_dstdir}/${_file:T} ${_FLW}(*** missing ***)${_FE}" /dev/null \
	      -L "$${_label}" $${_src} | ${_DIFF_POST} || :; \
	elif ${SUDO_CMD} ${TEST_CMD} ! -r $${_dstdir}/${_file:T}; then \
	    ${_HEADING1} " *** $${_dstdir}/${_file:T} is not readable ***"; \
	fi
. else # !target(${_file:T})
#
# Plugin: stored
#
.  if defined(STOREDCMD_${_file:T})
.   for _F in ${TMPDIR}/${_file:T}.diff-new
diff-${_tag}:: ${_file:T}
	${_@_}\
	if [ -r ${.OBJDIR}/${_file:T} ]; then \
		_f=${.OBJDIR}/${_file:T}; \
	else \
		_f=${.CURDIR}/${_file:T}; \
	fi; \
	${STOREDCMD_${_file:T}} > ${_F} && \
	if ! ${_DIFF_CMD} ${_F} $$_f > /dev/null 2>&1; then \
		${_HEADING1} "diff -ruN (current) $$_f"; \
		${_DIFF_CMD} -L "(current) ${STOREDCMD_${_file:T}:Q}" ${_F} \
		    -L "(workdir) ${_file:T}" $$_f | ${_DIFF_POST} || :; \
	fi
.   endfor
#
.  else # defined(STOREDCMD_${_file:T})
#
# file with target
#
diff-${_tag}:: ${_file:T}
	${_@_}\
	_dstdir="${_DESTDIR_${_dir:hash}:C,[/]+,/,g}"; \
	if [ ${.CURDIR} != ${.OBJDIR} ]; then \
	    if [ -r ${.OBJDIR}/${_file:T} ]; then \
		_label="${_FA}./${_file:T} (obj-dir)${_FE}"; \
		_src="${.OBJDIR}/${_file:T}"; \
	    elif [ -r ${.CURDIR}/${_file:T} ]; then \
		_label="${_FA}./${_file:T} (work-dir)${_FE}"; \
		_src="${.CURDIR}/${_file:T}"; \
	    fi; \
	else \
	    _label="${_FA}./${_file:T} (work-dir)${_FE}"; \
	    _src="${.CURDIR}/${_file:T}"; \
	fi; \
	_exists=$$(${SUDO_CMD} ${SH_CMD} -c \
	    "if [ -e $${_dstdir}/${_file:T} -a \
	    -r $${_dstdir}/${_file:T} ]; then \
	      if ${CMP_CMD} $${_dstdir}/${_file:T} $${_src}; then \
	        echo 2; \
	      else \
	        echo 1; \
	      fi; \
	    fi"); \
	if [ "$$_exists" = 1 ]; then \
	    ${_HEADING1} "diff $${_dstdir}/${_file:T} ${_file:T}:"; \
	    ${SUDO_CMD} ${CAT_CMD} $${_dstdir}/${_file:T} | ${_DIFF_CMD} \
	      -L "${_FD}$${_dstdir}/${_file:T} (stock)${_FE}" - \
	      -L "$${_label}" $${_src} | ${_DIFF_POST} || :; \
	elif ${SUDO_CMD} ${TEST_CMD} ! -e $${_dstdir}/${_file:T}; then \
	    ${_HEADING1} "diff $${_dstdir}/${_file:T} ${_file:T}:"; \
	    ${_DIFF_CMD} -L "${_FD}$${_dstdir}/${_file:T} ${_FLW}(*** missing ***)${_FE}" /dev/null \
	      -L "$${_label}" $${_src} | ${_DIFF_POST} || :; \
	elif ${SUDO_CMD} ${TEST_CMD} ! -r $${_dstdir}/${_file:T}; then \
	    ${_HEADING1} " *** $${_dstdir}/${_file:T} is not readable ***"; \
	fi
.  endif # defined(STOREDCMD_${_file:T})
. endif # !target(${_file:T})
diff: diff-${_tag}
diff-single: diff-${_tag}
TARGETS.diff+=	diff-${_file:T}
diff-${_file:T}.DESC=	show diff delta of "${_file:T}" against ${${_group}DIR}/${_file:T}
diff-${_file:T}: diff-${_tag}
.endfor
