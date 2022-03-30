#
# install.f.mk: Plugin for install
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
.if !target(__<install.f.mk>__)
__<install.f.mk>__:
.endif

.for _tag _group _dir _file _filemode _fileown _filegrp in \
    ${_tag} ${_group} ${_dir} ${_file} ${_filemode} ${_fileown} ${_filegrp}
#
# Single file installation
#  + Plugin: stored
.if !defined(STOREDCMD_${_file:T})
TARGETS.install+=	install-${_file:T}
install-${_file:T}.DESC=	install "${_file:T}" to ${${_group}DIR}
install-${_file:T}:
.for _f in ${${_group}:M${_file:T}}
	@cd ${.CURDIR} && ${MAKE} ${.MAKEFLAGS} \
	    ${FILESGROUPS:S/$/=/} \
	    ${_group}=${_f} \
	    ${_group}OWN_${_file:T}=${${_group}OWN_${_file:T}} \
	    ${_group}GRP_${_file:T}=${${_group}GRP_${_file:T}} \
	    ${_group}MODE_${_file:T}=${${_group}MODE_${_file:T}} \
	    ${_group}PREFIX_${_file:T}=${${_group}PREFIX_${_file:T}} \
	    install
.endfor
install-single: install-${_file:T}

# XXX: install(1) cares permission mismatch.  This fixup is no longer needed.
.if make(install) || make(install-single) || make(install-${_file:T})
fixup-${_tag}:
	@_m=$$(${GETPERM_CMD} ${_dir}/${_file:T}); \
	_M=$$(printf "%04o" 0${_filemode}); \
	if [ $$_m != $$_M ]; then \
		chmod $$_M ${_dir}/${_file:T}; \
	fi
# afterinstall: fixup-${_tag}
.  endif

.endif # STOREDCMD

.endfor
