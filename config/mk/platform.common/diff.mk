#
# diff.mk: Plugin for diff
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
.if !target(__<diff.mk>__)
__<diff.mk>__:
.endif

TARGETS.diff=	diff diff-single
diff.DESC=	show diff deltas, including the sub-directories
diff-single.DESC=show diff deltas in the current directory only
.if make(diff-single)
.undef SUBDIR
.else
SUBDIR_TARGETS.diff=	diff
.endif
VARS.diff=	DIFF_FLAGS
DIFF_FLAGS=	-ruN -I\$$FreeBSD -I\$$hrs
_DIFF_CMD=	${DIFF_CMD} ${DIFF_FLAGS}

_FACE_DIFF_ADDED_ENTER?=	${_FACE_GREEN}
_FACE_DIFF_DELETED_ENTER?=	${_FACE_PINK}
_FACE_DIFF_LABEL_ENTER?=${_FACE_GREEN}
_FACE_DIFF_LABEL_WARN_ENTER?=${_FACE_REV_PINK}
_FACE_DIFF_WARN_ENTER?=	${_FACE_PINK}
_FACE_DIFF_EXIT?=	${_FACE_EXIT}

# Alises
_FA=	${_FACE_DIFF_ADDED_ENTER}
_FD=	${_FACE_DIFF_DELETED_ENTER}
_FL=	${_FACE_DIFF_LABEL_ENTER}
_FLW=	${_FACE_DIFF_LABEL_WARN_ENTER}
_FW=	${_FACE_DIFF_WARN_ENTER}
_FE=	${_FACE_DIFF_EXIT}

.if exists(${AWK_CMD})
_DIFF_POST=	${AWK_CMD} ' \
	    (NR > 3) && /^\+/ { printf("${_FA}%s${_FE}\n", $$0) } \
	    (NR > 3) && /^\-/ { printf("${_FD}%s${_FE}\n", $$0) } \
	    (NR < 3) || (!/^\+/ && !/^\-/) { print } \
	'
.else
_DIFF_POST=	${CAT_CMD}
.endif
# XXX: diff-single is not optimal...
.PHONY: diff diff-single
diff:
diff-single:
