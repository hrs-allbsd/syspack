FILESDIR=	/etc/syslog.d

FILES=	\
	host-ns.conf

SERVICES=	syslogd

SYSLOGCONF=	../etc/syslog.conf
check:
	@cat ${SYSLOGCONF} | while read D F; do \
	    case "$$D:$$F" in \
	    \#*)	;; \
	    +*:/*)	host=$${D#+} ;; \
	    *:"")	;; \
	    include:/*)	;; \
	    *:/*)	echo "$${host:-@}:$$F" ;; \
	    *)		;; \
	    esac; \
	done

beforeinstall:
	cat ${FILES} | awk '/\/var\/log/ { print $$2 }' | \
	    sort | uniq | while read F; do \
		mkdir -p $$(dirname $$F); \
		[ -r "$$F" ] || touch $$F; \
	done

.include <bsd.prog.mk>
