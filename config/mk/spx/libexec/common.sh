#!/bin/sh
#
REALPATH_CMD=/bin/realpath

warn0() { echo "$@" 1>&2; }
warn() { warn0 WARNING: "$@"; }
echo_verbose() { [ $flag_verbose != 1 ] && return || echo "$@"; }
err() { _ret="$1"; shift; warn0 ERROR: "$@"; exit $_ret; }
usage() { echo "Usage: spx [-hnv] subcommand ..."; exit $1; }
