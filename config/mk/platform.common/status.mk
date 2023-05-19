#
# status.mk: file status plugin
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
.if !target(__<status.mk>__)
__<status.mk>__:
.endif

# Prerequisite
.for _V in GETPERM_CMD GETOWNER_CMD
. if !defined(${_V})
. error status plugin requires ${_V}
. endif
.endfor

TARGETS.status=	st status \
		sts status-single
# not yet
XXX= \
		stt status-terse \
		stts status-terse-single
status.DESC=	show file status, including the sub-directories
st.DESC=	synonym of "status"
status-single.DESC=	show file status, only in the current directory
sts.DESC=	synonym of "status-single"
status-terse.DESC=	show file status in detail
status-terse-single.DESC=	show file status in detail
SUBDIR_TARGETS.status=	st status stt status-terse stts status-terse-single

.if make(status-single) || make(sts) || \
    make(status-terse-single) || make(stts)
.undef SUBDIR
.endif
.if make(status-terse) || make(stt) || \
    make(status-terse-single) || make(stts)
_STATUS_TERSE=yes
.endif

.PHONY: ${TARGETS.status}
${TARGETS.status}:

status st:
status-single sts:
status-terse stt:
status-terse-single stts:
