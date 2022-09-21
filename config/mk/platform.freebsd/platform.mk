#
LOCALBASE?=	/usr/local
ID_U?=		/usr/bin/id -u
ID_UN?=		/usr/bin/id -un
SETENV?=	/usr/bin/env
DIFF_CMD?=	/usr/bin/diff
SDIFF_CMD?=	/usr/bin/sdiff
TEST_CMD?=	/bin/test
ENV_CMD?=	/usr/bin/env
LESS_CMD?=	/usr/bin/less
GREP_CMD?=	/usr/bin/grep
WC_CMD?=	/usr/bin/wc
SED_CMD?=	/usr/bin/sed
CAT_CMD?=	/bin/cat
TPUT_CMD?=	/usr/bin/tput
SH_CMD?=	/bin/sh
CMP_CMD?=	/usr/bin/cmp -hsz
FIND_CMD?=	/usr/bin/find
HOSTNAME_CMD?=	/bin/hostname
AWK_CMD?=	/usr/bin/awk
TAIL_CMD?=	/usr/bin/tail
TAILF_CMD?=	/usr/bin/tail -F

SUDO_CMD?=	${LOCALBASE}/bin/sudo
DOAS_CMD?=	${LOCALBASE}/bin/doas
GIT_CMD?=	${LOCALBASE}/bin/git
SCREEN_CMD?=	${LOCALBASE}/bin/screen

# BSD stat
GETPERM_CMD?=	/usr/bin/stat -f "%Mp%Lp"
GETOWNER_CMD?=	/usr/bin/stat -f "%u:%g"

.if !defined(NCPU) && empty(NCPU)
NCPU!=		/sbin/sysctl -n hw.ncpu
.endif

# FACES
_COLS!=		${TPUT_CMD} cols 2>/dev/null || :
_FACE_REV!=	${TPUT_CMD} mr 2>/dev/null || :
_FACE_BOLD!=	${TPUT_CMD} md 2>/dev/null || :
_FACE_REV_GREEN!=	${TPUT_CMD} mr AF 2 2>/dev/null || :
_FACE_GREEN!=	${TPUT_CMD} AF 2 2>/dev/null || :
_FACE_REV_ORANGE!=	${TPUT_CMD} mr AF 9 2>/dev/null || :
_FACE_ORANGE!=	${TPUT_CMD} AF 9 2>/dev/null || :
_FACE_REV_PINK!=	${TPUT_CMD} mr AF 13 2>/dev/null || :
_FACE_PINK!=	${TPUT_CMD} AF 13 2>/dev/null || :
_FACE_EXIT!=	${TPUT_CMD} me 2>/dev/null || :
