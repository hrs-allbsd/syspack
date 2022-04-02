#!/bin/sh
#
# syspack update
#
. ${SPX_MODULESDIR}/common

create_file()
{
	_dir=`dirname $1`
	echo "===> Fixup $1"
	case $_dir in
	"")	# do nothing
	;;
	*)	mkdir -p $_dir || \
		    err 1 "creating $_dir directory failed"
	;;
	esac
	cat > $1
}
if ! type git > /dev/null 2>&1; then
	err 1 "git is not found.  You need to install git."
fi
if ! [ -d .spx/syspack ]; then
	err 1 "No syspack in .spx.  You need \"spx init\" first."
else
	echo "===> Updating .spx/syspack"
	( cd .spx/syspack && git pull ) || \
	    err 1 "git pull failed." 
fi
#
# Fixup Makefile.inc
#
cat <<EOT | create_file Makefile.inc
# DO NOT EDIT
.include "\${.PARSEDIR}/.spx/syspack/config/mk/bsd.config.mk"
EOT

echo "Done."
