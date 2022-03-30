#
# fetch.f.mk: plugin to get files from the destination
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
.if !target(__<fetch.f.mk>__)
__<fetch.f.mk>__:
.endif

.for _tag _group _dir _file in ${_tag} ${_group} ${_dir} ${_file}
.if !target(${_file:T})
fetch-${_tag}::
	@if [ ! -f ${.CURDIR}/${_file:T} ]; then \
	    echo "==> Copied: ${DESTDIR}${_dir}/${_file:T} -> ${_file:T}"; \
	    cp ${DESTDIR}${_dir}/${_file:T} ${.CURDIR}/${_file:T}; \
	else \
	    _done=; \
	    while [ -z "$$_done" ]; do \
		if cmp -s "${DESTDIR}${_dir}/${_file:T}" "${.CURDIR}/${_file:T}"; then \
			echo "==> [${_file:T}] is skipped because" \
			    "already staged."; \
			_done=1; \
			break; \
		fi; \
		echo -n "==> ${_file:T} is already staged but" \
		    "different from ${DESTDIR}${_dir}/${_file:T}." \
		    "Overwrite it? [y/N]: "; \
		read _ans; \
		case $$_ans in \
		[Yy][Ee][Ss]|[Yy]) \
		    echo "==> Copied: ${DESTDIR}${_dir}/${_file:T} -> ${_file:T}"; \
		    cp ${DESTDIR}${_dir}/${_file:T} ${.CURDIR}/${_file:T}; \
		    _done=1; \
		;; \
		""|[Nn][Oo]|[Nn]) \
		    echo "==> Skipped."; \
		    _done=1; \
		;; \
		*) \
		    echo "==> Please enter yes or no."; \
		;; \
		esac \
	    done; \
	fi
fetch: fetch-${_tag}
fetch-${_file:T}: fetch-${_tag}
TARGETS.fetch+= fetch-${_file:T}
fetch-${_file:T}.DESC=	get "${_file:T}" from ${${_group}DIR}
.endif
.endfor
