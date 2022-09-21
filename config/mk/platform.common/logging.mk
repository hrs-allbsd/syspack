#
# logging.mk: Plugin for logging
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
.if !target(__<logging.mk>__)
__<logging.mk>__:
.endif

# XXX: not yet
#TARGETS.logging=	log
#log.DESC=	show pathnames of the log files
VARS.logging=		LOGDIR

#
#
#
LOGDIR?=${GLOBALBASE}/.spx/log

#
# Helpers
#
# LOG_PROGRESS: progress report using log file
#
# $1: HEADER
# $2: MSG
# $3: LOGFILE_PATTERN
# $4: LOGFILE (can be empty string)
# $5: ERROR KEYWORD (can be empty string.  If so, it will be ^\000\000)
LOG_PROGRESS= _log_progress() { \
	echo "=> $$1"; \
	_total_lines=$$(${_LOG_TOTALLINES} $$3); \
	stdbuf -o L -i L tee ${LOGDIR}/$${4:-/dev/null} | stdbuf -o L -i L awk "\
	BEGIN { \
	    n=$$_total_lines; \
	    l=0; \
	} \
	(n > 0 && l % 10 == 0) { \
	    printf \"=\> $$2 (%d %%, %d)\r\",( l / n) * 100, l; \
	} \
	(n == 0) { \
	    printf \"=\> $$2 (%d)\r\", l; \
	} \
	/$${5:-^\\000\\000}/ { \
	    exit 1; \
	} \
	{ \
	    l++; \
	} \
	END { \
	    printf \"\n\"; \
	}"; \
	}; _log_progress
#
# _LOG_TOTALLINES: Calculate average lines of the log files
#
# FIXME: Is _logpattern fallback really safe?
#
_AVG=	awk 'BEGIN {l=0;n=0} \
	    {l += $$1; n++} \
	    END {if (n) printf "%d\n", l/n; else print 0; }'
# Trim logfiles and keep the newest 10 files.
_LOG_TOTALLINES=	_lines() { \
	mkdir -p ${LOGDIR}; \
	_logpattern="${LOGDIR}/$$1"; \
	_r="$${_logpattern\#\#*\*}"; \
	for i in 0 1 2 3 4 5 6 7 8 9; do \
		if _l=$$(/bin/ls -tr $${_logpattern} 2>/dev/null); then \
			break; \
		else \
			_logpattern="$${_logpattern%-*\**}*$${_r}"; \
			${DEBUG_ECHO} "Trying $$_logpattern" > /dev/stderr; \
		fi; \
	done; \
	while [ $$\# -gt 3 ]; do rm $$1; shift; done; \
	wc -l $$(echo $${_logpattern}) 2>/dev/null | \
	    grep -v total 2> /dev/null | \
	    ${_AVG}; \
	}; _lines
#
# _LOGTAIL_CMD: Command to show the log file
# $0: header
# $1: log file pathname
#
_SCREEN_CMD=${_USER_CMD} ${SCREEN_CMD}
#
# FIXME: 2022.9.22 by hrs:
#   The "screen -X screen" requires more escaping of the shell commands.
#   It is confusing.  And "sudo make start" in a screen shows
#   an extra hardstatus line ($h).
#
_LOGTAIL_CMD= \
	if [ -n "$${STY}" ]; then \
	logtail() { \
	  ${_SCREEN_CMD} -X screen -dm -t "$$1" ${SH_CMD} -c ' \
	    h="\$$0 (\$$1) [Ctrl-C to close]"; \
	    ${_HEADING1} "\$$h"; \
	    printf "${ESC_TITLE_ENTER}\$$h${ESC_TITLE_EXIT}"; \
	    ${TAILF_CMD} "\$$1"; \
	  ' "$$@"; \
	}; \
	else \
	logtail() { \
	  ${_SCREEN_CMD} -m -t "$$1" ${SH_CMD} -c ' \
	    h="$$0 ($$1) [Ctrl-C to close]"; \
	    ${_HEADING1} "$$h"; \
	    printf "${ESC_TITLE_ENTER}$$h${ESC_TITLE_EXIT}"; \
	    ${TAILF_CMD} "$$1"; \
	  ' "$$@"; \
	}; \
	fi; \
	logtail
_LOGTAIL_POSTCMD= \
        logtail_post() { \
	if [ -n "$${STY}" ]; then \
		${_SCREEN_CMD} -X title "$$1"; \
	fi; \
        }; logtail_post
