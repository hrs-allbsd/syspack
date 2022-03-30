FILESDIR=	/var/db/namedb
FILESDIR_GRP=	bind
FILESDIR_MODE=	0775

FILES=		named.common.10.conf \
		named.common.172.conf \
		named.common.192.conf \
		named.common.conf \
		named.common.root-forward.conf \
		named.common.root-slave.conf \
		named.conf \
		named.root \
		rndc.conf \
		named.acl \
		rndc.key
.for F in \
	rndc.key \
	tsig-public.example.org
FILESGRP_${F}=		bind	
FILESMODE_${F}=		0640
.endfor

SERVICES=	named

SUBDIR=		master

beforeinstall:
	install -d -m 0775 -o root -g bind ${DESTDIR}/${FILESDIR}/slave
	install -d -m 0775 -o root -g bind ${DESTDIR}/${FILESDIR}/dynamic

afterinstall:
	${JEXEC} sh -c "cd /usr/local/etc/namedb && \
	    ln -fs /var/db/namedb/rndc.conf rndc.conf"

.include <bsd.prog.mk>
