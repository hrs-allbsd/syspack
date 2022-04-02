SCRIPTSDIR=	/usr/local/libexec/spx/modules
SCRIPTS=	common \
		help \
		init \
		update
CLEANFILES=	${SCRIPTS}

beforeinstall:
	install -d -o root -g wheel -m 0555 ${DESTDIR}${SCRIPTSDIR}

.include <bsd.prog.mk>
