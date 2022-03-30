#
ID_U?=		/usr/xpg4/bin/id -u
SETENV?=	/usr/bin/env
DIFF_CMD?=	/usr/local/bin/gdiff
SDIFF_CMD?=	/usr/local/bin/gsdiff
SUDO_CMD?=	/usr/local/bin/sudo
TEST_CMD?=	/usr/bin/test
ENV_CMD?=	/usr/bin/env
.if exists(/usr/bin/less)
LESS_CMD?=	/usr/bin/less
.elif exists(/usr/local/bin/less)
LESS_CMD?=	/usr/local/bin/less
.endif
GREP_CMD?=	/usr/bin/grep
WC_CMD?=	/usr/bin/wc
GIT_CMD?=	/usr/local/bin/git
SED_CMD?=	/usr/bin/sed
CAT_CMD?=	/bin/cat
TPUT_CMD?=	/usr/bin/tput
SH_CMD?=	/bin/sh
CMP_CMD?=	/usr/bin/cmp
FIND_CMD?=	/usr/bin/find
HOSTNAME_CMD?=	/usr/xpg4/bin/id -n
AWK_CMD?=	/usr/bin/awk

# BSD stat
GETPERM_CMD?=	/usr/local/bin/stat -f "%Mp%Lp"
GETOWNER_CMD?=	/usr/local/bin/stat -f "%u:%g"

#.if !exists(/usr/bsd/bin/install)
#. error BSD-compatible install(1) is required
#.endif
#INSTALL?=	/usr/bsd/bin/install-sh
INSTALL?=	/usr/ucb/install

.if !defined(NCPU) && empty(NCPU)
NCPU!=		/usr/sbin/psrinfo | ${WC_CMD} -l
.endif

# FACES
_COLS!=		${TPUT_CMD} cols || :
_FACE_REV!=	${TPUT_CMD} rev || :
_FACE_BOLD!=	${TPUT_CMD} bold || :
_FACE_REV_GREEN!=	${TPUT_CMD} rev setaf 2 || :
_FACE_GREEN!=	${TPUT_CMD} setaf 2 || :
_FACE_REV_ORANGE!=	${TPUT_CMD} rev setaf 9 || :
_FACE_ORANGE!=	${TPUT_CMD} setaf 9 || :
_FACE_REV_PINK!=	${TPUT_CMD} rev setaf 9 || :
_FACE_PINK!=	${TPUT_CMD} setaf 13 || :
_FACE_EXIT!=	${TPUT_CMD} sgr0 || :
