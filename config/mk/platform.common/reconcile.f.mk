#
# reconcile.f.mk: reconcile plugin
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
.if !target(__<reconcile.f.mk>__)
__<reconcile.f.mk>__:
.endif

.for _tag _group _dir _file in ${_tag} ${_group} ${_dir} ${_file}

.if target(${_file:T})
reconcile-${_tag}:: ${_file:T}

.elif !exists(${.CURDIR}/${_file:T})
reconcile-${_tag}::
	@echo "==> ${_file:T}: not found.  Skipped."

.else
reconcile-${_file:T}: reconcile-${_tag}
reconcile-${_file:T}.DESC= \
	Merge changes in ${DESTDIR}${_dir}/${_file:T} into ${_file:T}
TARGETS.reconcile+=	reconcile-${_file:T}
reconcile-${_tag}::
	@if ! ${SUEXEC_CMD} ${TEST_CMD} -r "${DESTDIR}${_dir}/${_file:T}"; then \
		if [ -f ${_file} ]; then \
			echo "==> ${_file}: Skipped because of no ${DESTDIR}${_dir}/${_file:T}."; \
		else \
			echo "==> ${_file}: not found."; \
		fi; \
	elif ! ${SUEXEC_CMD} ${_DIFF_CMD} ${DESTDIR}${_dir}/${_file:T} ${_file} > /dev/null 2>&1; then \
	echo "==> reconcile ${DESTDIR}${_dir}/${_file:T} --> ${_file}"; \
	TMPDIR="${TMPDIR}/$$$$"; \
	RECONCILE_AGAIN=yes; \
	while [ "$$RECONCILE_AGAIN" = yes ]; do \
		mkdir -p "$${TMPDIR}/${DESTDIR}${_dir}"; \
		_TMPFILE="$${TMPDIR}/${DESTDIR}${_dir}/${_file:T}.reconciled"; \
		_TMPFILE_T="$${TMPDIR}/${DESTDIR}${_dir}/${_file:T}.target"; \
		${SUEXEC_CMD} cat ${DESTDIR}${_dir}/${_file:T} > "$${_TMPFILE_T}"; \
		${_RECONCILE_CMD} -o "$${_TMPFILE}" \
		    "$${_TMPFILE_T}" ${_file} || :; \
		INSTALL_RECONCILED=V; \
		while [ "$$INSTALL_RECONCILED" = v -o "$$INSTALL_RECONCILED" = V ]; do \
			echo ''; \
			echo "  Use 'i' to save the reconciled file to \"./${_file}\""; \
			echo "  Use 'd' to ignore the reconciled file"; \
			echo "  Use 'l' to leave the temporary reconciled file"; \
			echo "  Use 'r' to re-do the reconcile"; \
			echo "  Use 'v' to view the reconciled file"; \
			echo ''; \
			echo -n "    *** How should I deal with the reconciled " \
			    "file? [Leave it for later] "; \
			read INSTALL_RECONCILED; \
			case "$$INSTALL_RECONCILED" in \
			[iI]) \
			    cp "$${_TMPFILE}" ${_file}; \
			    unset RECONCILE_AGAIN ;; \
			[dD]) \
			    rm "$${_TMPFILE}"; \
			    unset RECONCILE_AGAIN ;; \
			[lL]) \
			    unset RECONCILE_AGAIN; \
			    cp "$${_TMPFILE}" ${_file}.reconcile.tmp; \
			    echo ""; \
			    echo "  => The temporary file is saved as" \
			        "\"${_file}.reconcile.tmp\"" ;; \
			[rR]) \
			    rm "$${_TMPFILE}" ;; \
			[vV]) \
			    ${LESS_CMD} "$${_TMPFILE}" ;; \
			*) \
			    INSTALL_RECONCILED=V ;; \
			esac; \
		done; \
	done; \
	rm -rf "$${TMPDIR}"; \
	fi
.endif

reconcile: reconcile-${_tag}
.endfor
