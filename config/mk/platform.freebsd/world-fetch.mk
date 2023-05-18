#
# world-fetch.mk: Plugin for fetching FreeBSD world
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
.if !target(__<world-fetch.mk>__)
__<world-fetch.mk>__:
.endif

VARS.world+= \
	WORLD_FETCH_URL \
	WORLD_FETCH_CMD \
	WORLD_TAG

.if defined(WORLD_TAG) && !empty(WORLD_TAG)
.  if empty(WORLD_TAG:N*/*)
.error ${SPX_ERROR} WORLD_TAG is invalid
.  else
WORLD_FETCH_CMD_TAGOPT=	-b ${WORLD_TAG}
.  endif
.endif

WORLD_FETCH_URL?=	https://git.freebsd.org/src.git	
WORLD_FETCH_CMD?=${GIT_CMD} clone -o freebsd \
		--config remote.freebsd.fetch='+refs/notes/*:refs/notes/*' \
		${WORLD_FETCH_CMD_TAGOPT} \
		${WORLD_FETCH_URL}
WORLD_FULL_FETCH_CMD?=${WORLD_FETCH_CMD}
WORLD_SHALLOW_FETCH_CMD?=${WORLD_FETCH_CMD} --depth=1
#
# world-fetch target (will be added to TARGETS.world in -post.mk)
#
_TARGETS.world-fetch=	world-fetch \
			world-fetch-full \
			world-fetch-clean
world-fetch.DESC=	fetch source files for world (shallow clone)
world-fetch-full.DESC=	fetch source files for world (full clone)
world-fetch-clean.DESC=	clean source files for world in ${WORLD_SRCDIR:tA}

.if !empty(WORLD_SRCDIR)
.  if exists(${WORLD_SRCDIR})
world-fetch:
	@echo "[ERROR]" "WORLD_SRCDIR (${WORLD_SRCDIR}) is already populated."
world-fetch-clean:
	@( \
	_yes() { \
		rm -rf "${WORLD_SRCDIR}"; \
		echo "done."; \
	}; \
	${CHECKYESNO} "A source for the world in ${WORLD_SRCDIR}."; \
	)
.  else
world-fetch-full:
	${WORLD_FETCH_CMD} "${WORLD_SRCDIR}"
.    if defined(_WORLD_SRCDIR_README)
	echo "# ${WORLD_SRCDIR} is the source tree used for ${WORLD_ID}" \
	    > ${_WORLD_SRCDIR_README}
.    endif
world-fetch:
	${WORLD_SHALLOW_FETCH_CMD} "${WORLD_SRCDIR}"
.    if defined(_WORLD_SRCDIR_README)
	echo "# DO NOT REMOVE THIS FILE" > ${_WORLD_SRCDIR_README}
.    endif
world-fetch-clean:
	@echo "There is no source to be cleaned in ${WORLD_SRCDIR}"
.  endif
.endif
