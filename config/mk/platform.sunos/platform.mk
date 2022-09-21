#
LOCALBASE?=	/usr/local
ID_U?=		/usr/xpg4/bin/id -u
SETENV?=	/usr/bin/env
DIFF_CMD?=	${LOCALBASE}/bin/gdiff
SDIFF_CMD?=	${LOCALBASE}/bin/gsdiff
TEST_CMD?=	/usr/bin/test
ENV_CMD?=	/usr/bin/env
.if exists(/usr/bin/less)
LESS_CMD?=	/usr/bin/less
.elif exists(${LOCALBASE}/bin/less)
LESS_CMD?=	${LOCALBASE}/bin/less
.endif
GREP_CMD?=	/usr/bin/grep
WC_CMD?=	/usr/bin/wc
SED_CMD?=	/usr/bin/sed
CAT_CMD?=	/bin/cat
TPUT_CMD?=	/usr/bin/tput
SH_CMD?=	/bin/sh
CMP_CMD?=	/usr/bin/cmp
FIND_CMD?=	/usr/bin/find
HOSTNAME_CMD?=	/usr/xpg4/bin/id -n
AWK_CMD?=	/usr/bin/awk
TAIL_CMD?=	/usr/bin/tail
TAILF_CMD?=	/usr/bin/tail -f

# BSD stat
GETPERM_CMD?=	${LOCALBASE}/bin/stat -f "%Mp%Lp"
GETOWNER_CMD?=	${LOCALBASE}/bin/stat -f "%u:%g"

GIT_CMD?=	${LOCALBASE}/bin/git
SCREEN_CMD?=	${LOCALBASE}/bin/screen
SUDO_CMD?=	${LOCALBASE}/bin/sudo
DOAS_CMD?=	${LOCALBASE}/bin/doas

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
