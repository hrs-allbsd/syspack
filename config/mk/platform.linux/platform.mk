#
ID_U?=		/usr/bin/id -u
SETENV?=	/usr/bin/env
DIFF_CMD?=	/usr/bin/diff
SDIFF_CMD?=	/usr/bin/sdiff
TEST_CMD?=	/usr/bin/test
ENV_CMD?=	/usr/bin/env
LESS_CMD?=	/usr/bin/less
GREP_CMD?=	/usr/bin/grep
WC_CMD?=	/usr/bin/wc
SED_CMD?=	/usr/bin/sed
CAT_CMD?=	/bin/cat
TPUT_CMD?=	/usr/bin/tput
SH_CMD?=	/bin/sh
CMP_CMD?=	/usr/bin/cmp
FIND_CMD?=	/usr/bin/find
HOSTNAME_CMD?=	/bin/hostname
AWK_CMD?=	/usr/bin/awk
TAIL_CMD?=	/usr/bin/tail
TAILF_CMD?=	/usr/bin/tail -f

# GNU stat
GETPERM_CMD?=	/usr/bin/stat --printf "%a"
GETOWNER_CMD?=	/usr/bin/stat --printf "%u:%g"

SUDO_CMD?=	/usr/bin/sudo
DOAS_CMD?=	/usr/bin/doas
GIT_CMD?=	/usr/bin/git
SCREEN_CMD?=	/usr/bin/screen

# FIXME
.if !defined(NCPU) && empty(NCPU)
NCPU!=		${GREP_CMD} processor /proc/cpuinfo | ${WC_CMD} -l
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
