#!/bin/sh
#
# spx: syspack main command
#
# spx [subcommand]
#
: ${LOCALBASE:=/usr/local}
: ${SPX_LIBEXECDIR:="${LOCALBASE}/libexec/spx"}
: ${SPX_MODULESDIR:="${SPX_LIBEXECDIR}/modules"}
: ${SPX_SHELL:="/bin/sh"}
SETENV_CMD="/usr/bin/env"
REALPATH_CMD="/bin/realpath"

warn0() { echo "$@" 1>&2; }
warn() { warn0 WARNING: "$@"; }
echo_verbose() { [ $flag_verbose != 1 ] && return || echo "$@"; }
err() { _ret="$1"; shift; warn0 ERROR: "$@"; exit $_ret; }
usage() { echo "Usage: spx [-hnv] subcommand ..."; exit $1; }

DOTSPX=$(
	for i in 1 2 3 4 5 6 7 8 9; do
		test -d .spx && ${REALPATH_CMD} .spx && break
		cd ..
	done 
)
case "$DOTSPX" in
"")	needinit=:	;;
*)	needinit=false	;;
esac
: ${DOTSPX:=".spx"}
: ${SPX_DBDIR:="${DOTSPX}/var/db/spx"}
: ${SPX_CONF:="${DOTSPX}/spx.conf"}

if ! $needinit && [ -r "${SPX_CONF}" ]; then
	. "${SPX_CONF}"
fi
args=$(getopt hnv $*)
if [ $? -ne 0 ]; then
	usage 2
fi
flag_help=0
flag_verbose=0
flag_dryrun=0
set -- $args
while :; do
	case "$1" in
	-h)	flag_help=1; flag_verbose=1; shift ;;
	-n)	flag_dryrun=1; shift ;;
	-v)	flag_verbose=1; shift ;;
	--)	shift; break ;;
	esac
done

SETENV="${SETENV_CMD} \
  CWD=\"$(pwd)\"" \
  DOTSPX=\"${DOTSPX}\" \
  SPX_MODULESDIR=\"${SPX_MODULESDIR}\" \
  flag_help=$flag_help \
  flag_verbose=$flag_verbose \
  flag_dryrun=$flag_dryrun \
"
subcom=${1-"help"}

# XXX: sanity check
if [ ! -d "${SPX_MODULESDIR}" ]; then
	err 1 "Module directory (${SPX_MODULESDIR}) is not found."
fi
if $needinit && [ $subcom != "init" ]; then
	err 1 ".spx directory is not found." \
	    "You need \"spx init\" to make the current directory ready for spx."
fi
if [ -r "${SPX_MODULESDIR}/$subcom" ]; then
	echo_verbose "INFO: .spx directory: ${DOTSPX}"
	shift
	exec ${SETENV} ${SPX_SHELL} "${SPX_MODULESDIR}/$subcom" "$@"
else
	err 1 "$subcom: invalid subcommand"
fi
