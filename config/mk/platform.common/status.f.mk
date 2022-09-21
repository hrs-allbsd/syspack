#
# status.f.mk: file status plugin
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
.if !target(__<status.f.mk>__)
__<status.f.mk>__:
.endif

# IMPLEMENTATION NOTES:
#
# - A zero-prefixed value "0${${_group}MODE}" is used
#   to force it be interpret as an octal value.
#
# - "while" is used just for short-cut when the file is not found.
#
#
# Shadowing these four parameters to expand them.  Do not remove this.
.for _tag _group _dir _file _filemode _fileown _filegrp in \
    ${_tag} ${_group} ${_dir} ${_file} ${_filemode} ${_fileown} ${_filegrp}
_DESTDIR_${_dir:hash}=${DESTDIR}${_dir}

. if !target(${_file:T})
status-${_tag}::
. else
status-${_tag}:: ${_file:T}
. endif
	${_@_}\
	_dstdir="${_DESTDIR_${_dir:hash}:C,[/]+,/,g}"; \
	while :; do \
	if [ ! -f "$${_dstdir}/${_file:T}" ]; then \
		_dtag="?"; \
		_dinfo="(not installed)"; \
		printf "%4s %s/%s %s\n" \
		    "$$_dtag" "$${_dstdir}" "${_file:T}" "$$_dinfo"; \
		break; \
	fi; \
	_dtag=; \
	_dinfo=; \
	_m=$$(${GETPERM_CMD} $${_dstdir}/${_file:T} || echo 0); \
	_M=$$(printf "%04o" 0${${_group}MODE_${_file:T}}); \
	_ug=$$(${GETOWNER_CMD} $${_dstdir}/${_file:T} || echo 0); \
	_u=$$(getent passwd ${${_group}OWN_${_file}} || echo ${${_group}OWN_${_file:T}}); \
	_uu=$${_u#${${_group}OWN_${_file:T}}:*:}; \
	_uuu=$${_uu%%:*}; \
	_g=$$(getent group ${${_group}GRP_${_file:T}} || echo ${${_group}GRP_${_file:T}}); \
	_gg=$${_g#${${_group}GRP_${_file:T}}:*:}; \
	_ggg=$${_gg%%:*}; \
	_UG=$${_uuu}:$${_ggg}; \
	if [ $$_m != $$_M ]; then \
		_dtag=M; \
		_dinfo="($$_m should be $$_M)"; \
		${DEBUG_ECHO} "$$_m != $$_M";\
	fi; \
	if [ $$_ug != $$_UG ]; then \
		_dtag=O; \
		_dinfo="$${_dinfo}($$_ug should be $$_UG)"; \
		${DEBUG_ECHO} "$$_ug != $$_UG";\
	fi; \
	if ! ${SUEXEC_CMD} ${_DIFF_CMD} $${_dstdir}/${_file:T} ${_file} \
	    > /dev/null 2>&1; then \
		_dtag=$${_dtag}C; \
	fi; \
	if [ "${_STATUS_TERSE}" != "yes" -o "$$_dtag" != "" ]; then \
		printf "%4s %s/%s %s\n" \
		    "$$_dtag" "$${_dstdir}" "${_file:T}" "$$_dinfo"; \
	fi; \
	break; \
	done
status status-single st sts: status-${_tag}
status-terse status-terse-single stt stts: status-${_tag}

.endfor
