#!/bin/sh
#
# syspack init [site-name]
#
. ${SPX_MODULESDIR}/common

create_file()
{
	_dir=`dirname $1`
	if ! [ -r $1 ]; then
		echo "===> Create $1"
		case $_dir in
		"")	# do nothing
		;;
		*)	mkdir -p $_dir || \
			    err 1 "creating $_dir directory failed"
		;;
		esac
		cat > $1
	fi
}

if ! type git > /dev/null 2>&1; then
	err 1 "git is not found.  You need to install git."
fi

SITE=$1
DIRS=
FILES=
needsite=0
needexample=0
[ -d .spx ] || { DIRS="$DIRS .spx"; } 
[ -d templates ] || { DIRS="$DIRS templates"; } 
[ -d modules ] || { DIRS="$DIRS modules"; } 
FILES="$FILES Makefile.inc"
if [ "$SITE" != "" ]; then
	needsite=1
	[ -d "$SITE" ] || { DIRS="$DIRS $SITE"; needexample=1; }
	[ -f "$SITE/Makefile.inc" ]  || FILES="$FILES $SITE/Makefile.inc"
fi
if [ $needexample = 1 ]; then
	[ -d $SITE/example ] || DIRS="$DIRS $SITE/example"
	[ -d $SITE/templates ] || DIRS="$DIRS $SITE/templates"
	for f in \
	    $SITE/example/Makefile \
	    $SITE/example/Makefile.inc \
	    $SITE/example/root/Makefile \
	    $SITE/example/root/Makefile.inc \
	    $SITE/example/root/etc/Makefile \
	    $SITE/example/root/etc/Makefile.inc \
	    $SITE/example/root/etc/rc.conf; do
		[ -f $_f ]  || FILES="$FILES $_f"
	done
fi

case "$DIRS:$FILES" in
:)	doloop=false	;;
*)	doloop=true	;; 
esac
echo "Prepare $PWD for syspack:"

while $doloop; do
	echo ""
	echo "The following files or directories will be genarated:"
	echo ""
	echo $DIRS $FILES | tr " " "\n" | sed -e 's/^/	/'
	echo ""
	echo "to initialize the current directory for syspack."
	echo -n "OK? [y/N]"
	read ans
	case $ans in
	[Yy]) break ;;
	*) err 1 "Abort." ;;
	esac
done
case $DIRS in
"")	;;
*)	mkdir -p $DIRS ;;
esac
if ! [ -d .spx/syspack ]; then
	echo "===> Clone syspack from GitHub to .spx/syspack"
	mkdir -p .spx || err 1 "creating .spx directory failed"
	git clone https://github.com/hrs-allbsd/syspack.git .spx/syspack || \
	    err 1 "git clone failed." 
else
	echo "===> Updating .spx/syspack"
	( cd .spx/syspack && git pull ) || \
	    err 1 "git pull failed." 
fi

rm -f Makefile.inc
cat <<EOT | create_file Makefile.inc
# DO NOT EDIT
.include "\${.PARSEDIR}/.spx/syspack/config/Makefile.inc"
EOT
#
if [ $needsite = 0 ]; then
	echo "Done."
	exit
fi
#
cat <<EOT | create_file $SITE/Makefile.inc
# DO NOT EDIT
.for _TDIR in \${.PARSEDIR}/templates
TEMPLATESDIR+=	\${_TDIR}
.endfor
.include "\${.PARSEDIR}/../Makefile.inc"
EOT
#
if [ $needexample = 0 ]; then
	echo "Done."
	exit
fi
#
# $SITE/example
#
cat <<EOT | create_file $SITE/example/Makefile.inc
TARGETHOST=	example.$SITE

.include "\${.PARSEDIR}/../Makefile.inc"
EOT
#
cat <<EOT | create_file $SITE/example/Makefile
# This is an example for example.$SITE

SUBDIR=	etc

.include <bsd.subdir.mk>
EOT
#
cat <<EOT | create_file $SITE/example/etc/Makefile.inc
# DO NOT EDIT
.include "\${.PARSEDIR}/../Makefile.inc"
EOT
#
cat <<EOT | create_file $SITE/example/etc/Makefile
# This is an example for example.$SITE

FILESDIR=	/etc
FILES=	rc.conf

.include <bsd.prog.mk>
EOT
#
cat <<EOT | create_file $SITE/example/etc/rc.conf
# This is an example rc.conf for example.$SITE

hostname="example.$SITE"
EOT

echo "Done."
